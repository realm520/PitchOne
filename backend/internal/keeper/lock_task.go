package keeper

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/pitchone/sportsbook/pkg/bindings"
	"go.uber.org/zap"
)

// LockTask handles the task of locking markets before match start
type LockTask struct {
	keeper *Keeper
}

// MarketToLock represents a market that needs to be locked
type MarketToLock struct {
	MarketAddress common.Address
	EventID       string
	LockTime      time.Time
	MatchStart    time.Time
}

// NewLockTask creates a new LockTask instance
func NewLockTask(keeper *Keeper) *LockTask {
	return &LockTask{
		keeper: keeper,
	}
}

// Execute runs the lock task
func (t *LockTask) Execute(ctx context.Context) error {
	t.keeper.logger.Info("executing lock task")

	// Get markets that need locking
	markets, err := t.getMarketsToLock(ctx)
	if err != nil {
		t.keeper.logger.Error("failed to get markets to lock", zap.Error(err))
		return fmt.Errorf("failed to get markets to lock: %w", err)
	}

	if len(markets) == 0 {
		t.keeper.logger.Debug("no markets to lock")
		return nil
	}

	t.keeper.logger.Info("found markets to lock", zap.Int("count", len(markets)))

	// Process each market
	for _, market := range markets {
		select {
		case <-ctx.Done():
			t.keeper.logger.Info("lock task cancelled")
			return ctx.Err()
		default:
			// Lock the market
			if err := t.lockMarket(ctx, market.MarketAddress); err != nil {
				t.keeper.logger.Error("failed to lock market",
					zap.String("market", market.MarketAddress.Hex()),
					zap.String("eventID", market.EventID),
					zap.Error(err),
				)
				// Continue with other markets even if one fails
				continue
			}

			t.keeper.logger.Info("successfully locked market",
				zap.String("market", market.MarketAddress.Hex()),
				zap.String("eventID", market.EventID),
			)
		}
	}

	return nil
}

// getMarketsToLock queries the database for markets that need locking
func (t *LockTask) getMarketsToLock(ctx context.Context) ([]*MarketToLock, error) {
	// Calculate lock window: current time + lock lead time (Unix timestamp)
	now := time.Now().Unix()
	lockTime := now + int64(t.keeper.config.LockLeadTime)

	query := `
		SELECT
			market_address,
			event_id,
			lock_time,
			match_start
		FROM markets
		WHERE status = 'Open'
		AND lock_time <= $1
		AND lock_time > $2
		ORDER BY lock_time ASC
	`

	rows, err := t.keeper.db.QueryContext(ctx, query, lockTime, now)
	if err != nil {
		return nil, fmt.Errorf("failed to query markets: %w", err)
	}
	defer rows.Close()

	markets := make([]*MarketToLock, 0)
	for rows.Next() {
		var market MarketToLock
		var marketAddrHex string
		var lockTimeUnix, matchStartUnix int64

		err := rows.Scan(&marketAddrHex, &market.EventID, &lockTimeUnix, &matchStartUnix)
		if err != nil {
			return nil, fmt.Errorf("failed to scan market row: %w", err)
		}

		// Parse market address
		market.MarketAddress = common.HexToAddress(marketAddrHex)

		// Convert Unix timestamps to time.Time
		market.LockTime = time.Unix(lockTimeUnix, 0)
		market.MatchStart = time.Unix(matchStartUnix, 0)

		markets = append(markets, &market)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating market rows: %w", err)
	}

	return markets, nil
}

// lockMarket calls the contract's lock() method
func (t *LockTask) lockMarket(ctx context.Context, marketAddr common.Address) error {
	// Validate market address
	if marketAddr == (common.Address{}) {
		return fmt.Errorf("invalid market address: zero address")
	}

	// Create market contract instance
	market, err := bindings.NewMarketBase(marketAddr, t.keeper.web3Client.client)
	if err != nil {
		return fmt.Errorf("failed to create market contract instance: %w", err)
	}

	// Get current gas price
	gasPrice, err := t.keeper.web3Client.CalculateGasPrice(ctx, t.keeper.maxGasPrice)
	if err != nil {
		return fmt.Errorf("failed to calculate gas price: %w", err)
	}

	// Get nonce
	nonce, err := t.keeper.web3Client.GetNonce(ctx, t.keeper.web3Client.account)
	if err != nil {
		return fmt.Errorf("failed to get nonce: %w", err)
	}

	// Build transaction opts
	auth := &bind.TransactOpts{
		From:     t.keeper.web3Client.account,
		Nonce:    big.NewInt(int64(nonce)),
		Signer:   t.createSigner(),
		Value:    big.NewInt(0),
		GasPrice: gasPrice,
		GasLimit: t.keeper.config.GasLimit,
		Context:  ctx,
	}

	// Call lock() method
	tx, err := market.Lock(auth)
	if err != nil {
		return fmt.Errorf("failed to send lock transaction: %w", err)
	}

	t.keeper.logger.Info("lock transaction sent",
		zap.String("market", marketAddr.Hex()),
		zap.String("txHash", tx.Hash().Hex()),
		zap.Uint64("nonce", nonce),
		zap.String("gasPrice", gasPrice.String()),
	)

	// Wait for transaction to be mined (with timeout)
	receiptCtx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	defer cancel()

	receipt, err := t.waitForTransaction(receiptCtx, tx.Hash())
	if err != nil {
		return fmt.Errorf("failed to wait for transaction: %w", err)
	}

	// Check transaction status
	if receipt.Status != types.ReceiptStatusSuccessful {
		return fmt.Errorf("lock transaction failed: status %d", receipt.Status)
	}

	t.keeper.logger.Info("lock transaction confirmed",
		zap.String("market", marketAddr.Hex()),
		zap.String("txHash", tx.Hash().Hex()),
		zap.Uint64("blockNumber", receipt.BlockNumber.Uint64()),
		zap.Uint64("gasUsed", receipt.GasUsed),
	)

	// Update market status in database
	if err := t.updateMarketStatus(ctx, marketAddr, "Locked", tx.Hash()); err != nil {
		t.keeper.logger.Error("failed to update market status in database",
			zap.String("market", marketAddr.Hex()),
			zap.Error(err),
		)
		// Don't return error as the on-chain lock succeeded
	}

	return nil
}

// createSigner creates a transaction signer function
func (t *LockTask) createSigner() bind.SignerFn {
	return func(address common.Address, tx *types.Transaction) (*types.Transaction, error) {
		return t.keeper.web3Client.SignTransaction(tx)
	}
}

// waitForTransaction waits for a transaction to be mined
func (t *LockTask) waitForTransaction(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-ticker.C:
			receipt, err := t.keeper.web3Client.WaitForTransaction(ctx, txHash)
			if err != nil {
				// Transaction not mined yet, continue waiting
				continue
			}
			return receipt, nil
		}
	}
}

// updateMarketStatus updates the market status in the database
func (t *LockTask) updateMarketStatus(ctx context.Context, marketAddr common.Address, status string, txHash common.Hash) error {
	now := time.Now().Unix()

	query := `
		UPDATE markets
		SET
			status = $1,
			lock_tx_hash = $2,
			locked_at = $3,
			updated_at = $4
		WHERE market_address = $5
	`

	result, err := t.keeper.db.ExecContext(ctx, query, status, txHash.Hex(), now, now, marketAddr.Hex())
	if err != nil {
		return fmt.Errorf("failed to update market status: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("no market found with address %s", marketAddr.Hex())
	}

	t.keeper.logger.Debug("updated market status in database",
		zap.String("market", marketAddr.Hex()),
		zap.String("status", status),
		zap.String("txHash", txHash.Hex()),
	)

	return nil
}
