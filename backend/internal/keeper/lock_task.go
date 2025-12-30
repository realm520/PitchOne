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
	Version       string // "v2" or "v3"
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
			// Lock the market based on version
			var err error
			if market.Version == "v3" {
				err = t.lockMarketV3(ctx, market.MarketAddress)
			} else {
				err = t.lockMarketV2(ctx, market.MarketAddress)
			}

			if err != nil {
				t.keeper.logger.Error("failed to lock market",
					zap.String("market", market.MarketAddress.Hex()),
					zap.String("eventID", market.EventID),
					zap.String("version", market.Version),
					zap.Error(err),
				)
				// Continue with other markets even if one fails
				continue
			}

			t.keeper.logger.Info("successfully locked market",
				zap.String("market", market.MarketAddress.Hex()),
				zap.String("eventID", market.EventID),
				zap.String("version", market.Version),
			)
		}
	}

	return nil
}

// getMarketsToLock queries the Subgraph for markets that need locking
func (t *LockTask) getMarketsToLock(ctx context.Context) ([]*MarketToLock, error) {
	// Calculate lock window: current time + lock lead time (Unix timestamp)
	now := time.Now().Unix()
	lockWindow := now + int64(t.keeper.config.LockLeadTime)

	// 从 Subgraph 查询需要锁盘的市场
	subgraphMarkets, err := t.keeper.graphClient.GetMarketsToLock(ctx, now, lockWindow)
	if err != nil {
		return nil, fmt.Errorf("failed to query Subgraph: %w", err)
	}

	markets := make([]*MarketToLock, 0, len(subgraphMarkets))
	for _, m := range subgraphMarkets {
		// 解析时间戳
		var lockTimeUnix, kickoffTimeUnix int64
		if m.LockTime != "" {
			fmt.Sscanf(m.LockTime, "%d", &lockTimeUnix)
		}
		if m.KickoffTime != "" {
			fmt.Sscanf(m.KickoffTime, "%d", &kickoffTimeUnix)
		}

		// 确定版本（默认 v3，Subgraph 的市场都是 V3 Factory 创建的）
		version := m.Version
		if version == "" {
			version = "v3"
		}

		markets = append(markets, &MarketToLock{
			MarketAddress: common.HexToAddress(m.ID),
			EventID:       m.MatchID,
			LockTime:      time.Unix(lockTimeUnix, 0),
			MatchStart:    time.Unix(kickoffTimeUnix, 0),
			Version:       version,
		})
	}

	return markets, nil
}

// lockMarketV2 calls the V2 contract's lock() method
func (t *LockTask) lockMarketV2(ctx context.Context, marketAddr common.Address) error {
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

	// 状态由链上事件自动更新到 Subgraph，无需手动更新数据库

	return nil
}

// lockMarketV3 calls the V3 contract's lock() method
func (t *LockTask) lockMarketV3(ctx context.Context, marketAddr common.Address) error {
	// Validate market address
	if marketAddr == (common.Address{}) {
		return fmt.Errorf("invalid market address: zero address")
	}

	// Create V3 market contract instance
	market, err := bindings.NewMarketV3(marketAddr, t.keeper.web3Client.client)
	if err != nil {
		return fmt.Errorf("failed to create V3 market contract instance: %w", err)
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

	// Call lock() method on V3 market
	tx, err := market.Lock(auth)
	if err != nil {
		return fmt.Errorf("failed to send lock transaction: %w", err)
	}

	t.keeper.logger.Info("V3 lock transaction sent",
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

	t.keeper.logger.Info("V3 lock transaction confirmed",
		zap.String("market", marketAddr.Hex()),
		zap.String("txHash", tx.Hash().Hex()),
		zap.Uint64("blockNumber", receipt.BlockNumber.Uint64()),
		zap.Uint64("gasUsed", receipt.GasUsed),
	)

	// 状态由链上事件自动更新到 Subgraph，无需手动更新数据库

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

