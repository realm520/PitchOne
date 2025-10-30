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

// SettleTask handles the task of settling markets after match completion
type SettleTask struct {
	keeper *Keeper
}

// MarketToSettle represents a market that needs to be settled
type MarketToSettle struct {
	MarketAddress common.Address
	EventID       string
	MatchStart    time.Time
	MatchEnd      time.Time
	OracleAddress common.Address
}

// MatchResult represents the result of a match
type MatchResult struct {
	HomeGoals uint8
	AwayGoals uint8
	ExtraTime bool
	HomeWin   bool
	AwayWin   bool
	Draw      bool
}

// NewSettleTask creates a new SettleTask instance
func NewSettleTask(keeper *Keeper) *SettleTask {
	return &SettleTask{
		keeper: keeper,
	}
}

// Execute runs the settle task
func (t *SettleTask) Execute(ctx context.Context) error {
	t.keeper.logger.Info("executing settle task")

	// Get markets that need settling
	markets, err := t.getMarketsToSettle(ctx)
	if err != nil {
		t.keeper.logger.Error("failed to get markets to settle", zap.Error(err))
		return fmt.Errorf("failed to get markets to settle: %w", err)
	}

	if len(markets) == 0 {
		t.keeper.logger.Debug("no markets to settle")
		return nil
	}

	t.keeper.logger.Info("found markets to settle", zap.Int("count", len(markets)))

	// Process each market
	for _, market := range markets {
		select {
		case <-ctx.Done():
			t.keeper.logger.Info("settle task cancelled")
			return ctx.Err()
		default:
			// Settle the market
			if err := t.settleMarket(ctx, market); err != nil {
				t.keeper.logger.Error("failed to settle market",
					zap.String("market", market.MarketAddress.Hex()),
					zap.String("eventID", market.EventID),
					zap.Error(err),
				)
				// Continue with other markets even if one fails
				continue
			}

			t.keeper.logger.Info("successfully settled market",
				zap.String("market", market.MarketAddress.Hex()),
				zap.String("eventID", market.EventID),
			)
		}
	}

	return nil
}

// getMarketsToSettle queries the database for markets that need settling
func (t *SettleTask) getMarketsToSettle(ctx context.Context) ([]*MarketToSettle, error) {
	// Calculate settle window: match ended + finalize delay
	settleTime := time.Now().Add(-time.Duration(t.keeper.config.FinalizeDelay) * time.Second)

	query := `
		SELECT
			market_address,
			event_id,
			match_start,
			match_end,
			oracle_address
		FROM markets
		WHERE status = 'Locked'
		AND match_end <= $1
		AND match_end IS NOT NULL
		ORDER BY match_end ASC
	`

	rows, err := t.keeper.db.QueryContext(ctx, query, settleTime)
	if err != nil {
		return nil, fmt.Errorf("failed to query markets: %w", err)
	}
	defer rows.Close()

	var markets []*MarketToSettle
	for rows.Next() {
		var market MarketToSettle
		var marketAddrHex, oracleAddrHex string
		var matchStartStr, matchEndStr string

		err := rows.Scan(&marketAddrHex, &market.EventID, &matchStartStr, &matchEndStr, &oracleAddrHex)
		if err != nil {
			return nil, fmt.Errorf("failed to scan market row: %w", err)
		}

		// Parse addresses
		market.MarketAddress = common.HexToAddress(marketAddrHex)
		market.OracleAddress = common.HexToAddress(oracleAddrHex)

		// Parse timestamps
		market.MatchStart, err = time.Parse(time.RFC3339, matchStartStr)
		if err != nil {
			return nil, fmt.Errorf("failed to parse match_start: %w", err)
		}

		market.MatchEnd, err = time.Parse(time.RFC3339, matchEndStr)
		if err != nil {
			return nil, fmt.Errorf("failed to parse match_end: %w", err)
		}

		markets = append(markets, &market)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating market rows: %w", err)
	}

	return markets, nil
}

// settleMarket proposes the result to the oracle and settles the market
func (t *SettleTask) settleMarket(ctx context.Context, market *MarketToSettle) error {
	// Validate addresses
	if market.MarketAddress == (common.Address{}) {
		return fmt.Errorf("invalid market address: zero address")
	}
	if market.OracleAddress == (common.Address{}) {
		return fmt.Errorf("invalid oracle address: zero address")
	}

	// Get match result from data source
	result, err := t.fetchMatchResult(ctx, market.EventID)
	if err != nil {
		return fmt.Errorf("failed to fetch match result: %w", err)
	}

	// Create oracle contract instance
	oracle, err := bindings.NewMockOracle(market.OracleAddress, t.keeper.web3Client.client)
	if err != nil {
		return fmt.Errorf("failed to create oracle contract instance: %w", err)
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

	// Construct MatchFacts struct
	var marketIdBytes [32]byte
	copy(marketIdBytes[:], market.MarketAddress.Bytes())

	// Convert scope string to bytes32
	var scopeBytes [32]byte
	scope := "FT_90" // Full Time 90 minutes
	copy(scopeBytes[:], []byte(scope))

	facts := bindings.IResultOracleMatchFacts{
		Scope:         scopeBytes,
		HomeGoals:     result.HomeGoals,
		AwayGoals:     result.AwayGoals,
		ExtraTime:     result.ExtraTime,
		PenaltiesHome: 0,
		PenaltiesAway: 0,
		ReportedAt:    big.NewInt(time.Now().Unix()),
	}

	// Call proposeResult() method
	tx, err := oracle.ProposeResult(auth, marketIdBytes, facts)
	if err != nil {
		return fmt.Errorf("failed to send propose transaction: %w", err)
	}

	t.keeper.logger.Info("propose transaction sent",
		zap.String("market", market.MarketAddress.Hex()),
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
		return fmt.Errorf("propose transaction failed: status %d", receipt.Status)
	}

	t.keeper.logger.Info("propose transaction confirmed",
		zap.String("market", market.MarketAddress.Hex()),
		zap.String("txHash", tx.Hash().Hex()),
		zap.Uint64("blockNumber", receipt.BlockNumber.Uint64()),
		zap.Uint64("gasUsed", receipt.GasUsed),
	)

	// Update market status in database
	if err := t.updateMarketStatus(ctx, market.MarketAddress, "Proposed", tx.Hash(), result); err != nil {
		t.keeper.logger.Error("failed to update market status in database",
			zap.String("market", market.MarketAddress.Hex()),
			zap.Error(err),
		)
		// Don't return error as the on-chain propose succeeded
	}

	return nil
}

// fetchMatchResult fetches the match result from external data source
// In a real implementation, this would call a sports data API
func (t *SettleTask) fetchMatchResult(ctx context.Context, eventID string) (*MatchResult, error) {
	// TODO: Implement real data source integration
	// For now, return mock data
	t.keeper.logger.Debug("fetching match result",
		zap.String("eventID", eventID),
	)

	// Mock result: simulate fetching from API
	result := &MatchResult{
		HomeGoals: 2,
		AwayGoals: 1,
		ExtraTime: false,
		HomeWin:   true,
		AwayWin:   false,
		Draw:      false,
	}

	return result, nil
}

// createSigner creates a transaction signer function
func (t *SettleTask) createSigner() bind.SignerFn {
	return func(address common.Address, tx *types.Transaction) (*types.Transaction, error) {
		return t.keeper.web3Client.SignTransaction(tx)
	}
}

// waitForTransaction waits for a transaction to be mined
func (t *SettleTask) waitForTransaction(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
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
func (t *SettleTask) updateMarketStatus(ctx context.Context, marketAddr common.Address, status string, txHash common.Hash, result *MatchResult) error {
	query := `
		UPDATE markets
		SET
			status = $1,
			settle_tx_hash = $2,
			home_goals = $3,
			away_goals = $4,
			settled_at = NOW(),
			updated_at = NOW()
		WHERE market_address = $5
	`

	execResult, err := t.keeper.db.ExecContext(ctx, query, status, txHash.Hex(), result.HomeGoals, result.AwayGoals, marketAddr.Hex())
	if err != nil {
		return fmt.Errorf("failed to update market status: %w", err)
	}

	rowsAffected, err := execResult.RowsAffected()
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
