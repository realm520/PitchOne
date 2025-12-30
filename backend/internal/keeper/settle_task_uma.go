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

// SettleTaskUMA handles the task of proposing results to UMA Optimistic Oracle
// This replaces the direct oracle resolution with UMA OO's optimistic assertion flow
type SettleTaskUMA struct {
	*SettleTask // Embed original SettleTask for reusing data fetching logic
}

// NewSettleTaskUMA creates a new UMA-based settle task instance
func NewSettleTaskUMA(settleTask *SettleTask) *SettleTaskUMA {
	return &SettleTaskUMA{
		SettleTask: settleTask,
	}
}

// Execute runs the UMA settle task
func (t *SettleTaskUMA) Execute(ctx context.Context) error {
	t.keeper.logger.Info("executing UMA settle task (propose results)")

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

	t.keeper.logger.Info("found markets to settle (UMA propose)", zap.Int("count", len(markets)))

	// Process markets using worker pool for parallel execution
	if err := t.processMarketsParallelUMA(ctx, markets); err != nil {
		t.keeper.logger.Error("parallel UMA proposal completed with errors", zap.Error(err))
		// Don't return error - parallel processing already logged individual failures
	}

	return nil
}

// proposeResultToUMA proposes the match result to UMA Optimistic Oracle
func (t *SettleTaskUMA) proposeResultToUMA(ctx context.Context, market *MarketToSettle) error {
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

	// Log OU outcome if applicable
	if marketType, ok := market.MarketParams["type"].(string); ok && marketType == "OU" {
		line, isHalfLine, err := parseOUParams(market.MarketParams)
		if err != nil {
			t.keeper.logger.Warn("failed to parse OU params",
				zap.String("market", market.MarketAddress.Hex()),
				zap.Error(err),
			)
		} else {
			outcome, _ := calculateOUOutcome(result.HomeGoals, result.AwayGoals, line, isHalfLine)
			t.keeper.logger.Info("calculated OU outcome",
				zap.String("market", market.MarketAddress.Hex()),
				zap.Uint8("home_goals", result.HomeGoals),
				zap.Uint8("away_goals", result.AwayGoals),
				zap.Float64("line", line),
				zap.Bool("is_half_line", isHalfLine),
				zap.Uint8("outcome", outcome),
				zap.String("outcome_name", []string{"Over", "Under", "Push"}[outcome]),
			)
		}
	}

	// Create UMA adapter contract instance
	umaAdapter, err := bindings.NewUMAAdapter(market.OracleAddress, t.keeper.web3Client.client)
	if err != nil {
		return fmt.Errorf("failed to create UMA adapter contract instance: %w", err)
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

	// Construct marketId (use market address as bytes32)
	var marketIdBytes [32]byte
	copy(marketIdBytes[:], market.MarketAddress.Bytes())

	// Convert scope string to bytes32
	var scopeBytes [32]byte
	scope := "FT_90" // Full Time 90 minutes
	if result.ExtraTime {
		scope = "FT_120" // Full Time 120 minutes (with extra time)
	}
	copy(scopeBytes[:], []byte(scope))

	// Construct MatchFacts struct for UMA
	facts := bindings.IResultOracleMatchFacts{
		Scope:         scopeBytes,
		HomeGoals:     result.HomeGoals,
		AwayGoals:     result.AwayGoals,
		ExtraTime:     result.ExtraTime,
		PenaltiesHome: 0, // TODO: Add penalty support if needed
		PenaltiesAway: 0,
		ReportedAt:    big.NewInt(time.Now().Unix()),
	}

	t.keeper.logger.Info("proposing result to UMA",
		zap.String("market", market.MarketAddress.Hex()),
		zap.String("oracle", market.OracleAddress.Hex()),
		zap.String("scope", scope),
		zap.Uint8("home_goals", facts.HomeGoals),
		zap.Uint8("away_goals", facts.AwayGoals),
		zap.Bool("extra_time", facts.ExtraTime),
	)

	// Call proposeResult() on UMA adapter
	tx, err := umaAdapter.ProposeResult(auth, marketIdBytes, facts)
	if err != nil {
		return fmt.Errorf("failed to send UMA propose transaction: %w", err)
	}

	t.keeper.logger.Info("UMA propose transaction sent",
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
		return fmt.Errorf("UMA propose transaction failed: status %d", receipt.Status)
	}

	t.keeper.logger.Info("UMA propose transaction confirmed",
		zap.String("market", market.MarketAddress.Hex()),
		zap.String("txHash", tx.Hash().Hex()),
		zap.Uint64("blockNumber", receipt.BlockNumber.Uint64()),
		zap.Uint64("gasUsed", receipt.GasUsed),
	)

	// 状态由链上事件自动更新到 Subgraph，无需手动更新数据库

	return nil
}

// processMarketsParallelUMA processes multiple markets using a worker pool for UMA proposals
func (t *SettleTaskUMA) processMarketsParallelUMA(ctx context.Context, markets []*MarketToSettle) error {
	if len(markets) == 0 {
		return nil
	}

	// Determine number of workers
	numWorkers := t.keeper.config.MaxConcurrent
	if numWorkers <= 0 {
		numWorkers = 3 // Default to 3 workers
	}
	if len(markets) < numWorkers {
		numWorkers = len(markets)
	}

	t.keeper.logger.Info("starting worker pool for parallel UMA proposals",
		zap.Int("num_workers", numWorkers),
		zap.Int("num_markets", len(markets)),
	)

	// Reuse the existing worker pool structure
	type Job struct {
		Market *MarketToSettle
		Result chan error
	}

	jobs := make(chan *Job, len(markets))
	resultChan := make(chan error, len(markets))

	// Start workers
	for i := 0; i < numWorkers; i++ {
		go func(workerID int) {
			for job := range jobs {
				select {
				case <-ctx.Done():
					job.Result <- ctx.Err()
				default:
					t.keeper.logger.Debug("worker processing UMA proposal",
						zap.Int("worker_id", workerID),
						zap.String("market", job.Market.MarketAddress.Hex()),
						zap.String("event_id", job.Market.EventID),
					)

					// Propose to UMA
					err := t.proposeResultToUMA(ctx, job.Market)
					job.Result <- err

					if err != nil {
						t.keeper.logger.Error("worker UMA proposal failed",
							zap.Int("worker_id", workerID),
							zap.String("market", job.Market.MarketAddress.Hex()),
							zap.Error(err),
						)
					} else {
						t.keeper.logger.Info("worker UMA proposal succeeded",
							zap.Int("worker_id", workerID),
							zap.String("market", job.Market.MarketAddress.Hex()),
						)
					}
				}
			}
		}(i)
	}

	// Create jobs and collect results
	for _, market := range markets {
		job := &Job{
			Market: market,
			Result: make(chan error, 1),
		}

		select {
		case jobs <- job:
			// Job sent successfully, start result collector
			go func(j *Job) {
				err := <-j.Result
				resultChan <- err
			}(job)
		case <-ctx.Done():
			close(jobs)
			return ctx.Err()
		}
	}

	// Close jobs channel
	close(jobs)

	// Collect all results
	var errors []error
	for i := 0; i < len(markets); i++ {
		if err := <-resultChan; err != nil {
			errors = append(errors, err)
		}
	}

	t.keeper.logger.Info("worker pool completed (UMA)",
		zap.Int("total_markets", len(markets)),
		zap.Int("failed", len(errors)),
		zap.Int("succeeded", len(markets)-len(errors)),
	)

	// Return first error if any
	if len(errors) > 0 {
		return fmt.Errorf("UMA proposal failed for %d markets (first error: %w)", len(errors), errors[0])
	}

	return nil
}
