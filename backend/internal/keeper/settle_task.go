package keeper

import (
	"context"
	"encoding/json"
	"fmt"
	"math/big"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/pitchone/sportsbook/internal/datasource"
	"github.com/pitchone/sportsbook/pkg/bindings"
	"go.uber.org/zap"
)

// SettleTask handles the task of settling markets after match completion
type SettleTask struct {
	keeper     *Keeper
	dataSource datasource.ResultProvider
}

// MarketToSettle represents a market that needs to be settled
type MarketToSettle struct {
	MarketAddress common.Address
	EventID       string
	MatchStart    time.Time
	MatchEnd      time.Time
	OracleAddress common.Address
	MarketParams  map[string]interface{} // OU/AH 模板参数 (从 JSONB 解析)
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
func NewSettleTask(keeper *Keeper, dataSource datasource.ResultProvider) *SettleTask {
	return &SettleTask{
		keeper:     keeper,
		dataSource: dataSource,
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

	// Process markets using worker pool for parallel execution
	if err := t.processMarketsParallel(ctx, markets); err != nil {
		t.keeper.logger.Error("parallel settlement completed with errors", zap.Error(err))
		// Don't return error - parallel processing already logged individual failures
	}

	return nil
}

// getMarketsToSettle queries the database for markets that need settling
func (t *SettleTask) getMarketsToSettle(ctx context.Context) ([]*MarketToSettle, error) {
	// Calculate settle window: match ended + finalize delay (Unix timestamp)
	settleTime := time.Now().Unix() - int64(t.keeper.config.FinalizeDelay)

	query := `
		SELECT
			market_address,
			event_id,
			match_start,
			match_end,
			oracle_address,
			COALESCE(market_params, '{}'::jsonb)
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

	markets := make([]*MarketToSettle, 0)
	for rows.Next() {
		var market MarketToSettle
		var marketAddrHex, oracleAddrHex string
		var matchStartUnix, matchEndUnix int64
		var paramsJSON []byte

		err := rows.Scan(&marketAddrHex, &market.EventID, &matchStartUnix, &matchEndUnix, &oracleAddrHex, &paramsJSON)
		if err != nil {
			return nil, fmt.Errorf("failed to scan market row: %w", err)
		}

		// Parse addresses
		market.MarketAddress = common.HexToAddress(marketAddrHex)
		market.OracleAddress = common.HexToAddress(oracleAddrHex)

		// Convert Unix timestamps to time.Time
		market.MatchStart = time.Unix(matchStartUnix, 0)
		market.MatchEnd = time.Unix(matchEndUnix, 0)

		// Parse market_params JSONB
		market.MarketParams = make(map[string]interface{})
		if len(paramsJSON) > 0 && string(paramsJSON) != "{}" {
			if err := json.Unmarshal(paramsJSON, &market.MarketParams); err != nil {
				t.keeper.logger.Warn("failed to parse market_params, using empty map",
					zap.String("market", marketAddrHex),
					zap.Error(err),
				)
			}
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

	// Check if this is an OU market and calculate outcome
	// TODO: Use ouOutcome when OU market settlement is implemented
	var ouOutcome *uint8
	_ = ouOutcome // Suppress unused variable warning for now
	if marketType, ok := market.MarketParams["type"].(string); ok && marketType == "OU" {
		line, isHalfLine, err := parseOUParams(market.MarketParams)
		if err != nil {
			t.keeper.logger.Warn("failed to parse OU params, treating as WDL",
				zap.String("market", market.MarketAddress.Hex()),
				zap.Error(err),
			)
		} else {
			outcome, err := calculateOUOutcome(result.HomeGoals, result.AwayGoals, line, isHalfLine)
			if err != nil {
				return fmt.Errorf("failed to calculate OU outcome: %w", err)
			}
			ouOutcome = &outcome

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
func (t *SettleTask) fetchMatchResult(ctx context.Context, eventID string) (*MatchResult, error) {
	startTime := time.Now()

	t.keeper.logger.Debug("fetching match result",
		zap.String("eventID", eventID),
	)

	// Call data source provider (Sportradar or Mock)
	dsResult, err := t.dataSource.GetMatchResult(ctx, eventID)
	if err != nil {
		return nil, fmt.Errorf("data source error: %w", err)
	}

	duration := time.Since(startTime)

	// Convert datasource.MatchResult to keeper.MatchResult
	result := &MatchResult{
		HomeGoals: dsResult.HomeGoals,
		AwayGoals: dsResult.AwayGoals,
		ExtraTime: dsResult.ExtraTime,
		HomeWin:   dsResult.HomeWin,
		AwayWin:   dsResult.AwayWin,
		Draw:      dsResult.Draw,
	}

	t.keeper.logger.Info("match result fetched",
		zap.String("eventID", eventID),
		zap.Uint8("home_goals", result.HomeGoals),
		zap.Uint8("away_goals", result.AwayGoals),
		zap.Duration("fetch_duration", duration),
	)

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
	now := time.Now().Unix()

	query := `
		UPDATE markets
		SET
			status = $1,
			settle_tx_hash = $2,
			home_goals = $3,
			away_goals = $4,
			settled_at = $5,
			updated_at = $6
		WHERE market_address = $7
	`

	execResult, err := t.keeper.db.ExecContext(ctx, query, status, txHash.Hex(), result.HomeGoals, result.AwayGoals, now, now, marketAddr.Hex())
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

// ======================================
// Worker Pool Implementation
// ======================================

// SettleJob represents a single settle operation job
type SettleJob struct {
	Market *MarketToSettle
	Result chan error
}

// SettleWorkerPool manages concurrent settlement operations
type SettleWorkerPool struct {
	jobs       chan *SettleJob
	numWorkers int
	wg         *sync.WaitGroup
	task       *SettleTask
}

// processMarketsParallel processes multiple markets using a worker pool
func (t *SettleTask) processMarketsParallel(ctx context.Context, markets []*MarketToSettle) error {
	if len(markets) == 0 {
		return nil
	}

	// Determine number of workers (min of config.MaxConcurrent and number of markets)
	numWorkers := t.keeper.config.MaxConcurrent
	if numWorkers <= 0 {
		numWorkers = 3 // Default to 3 workers
	}
	if len(markets) < numWorkers {
		numWorkers = len(markets)
	}

	t.keeper.logger.Info("starting worker pool for parallel settlement",
		zap.Int("num_workers", numWorkers),
		zap.Int("num_markets", len(markets)),
	)

	// Create worker pool
	pool := &SettleWorkerPool{
		jobs:       make(chan *SettleJob, len(markets)),
		numWorkers: numWorkers,
		wg:         &sync.WaitGroup{},
		task:       t,
	}

	// Start workers
	for i := 0; i < numWorkers; i++ {
		pool.wg.Add(1)
		go pool.worker(ctx, i)
	}

	// Create jobs and collect results
	resultChan := make(chan error, len(markets))
	for _, market := range markets {
		job := &SettleJob{
			Market: market,
			Result: make(chan error, 1),
		}

		// Send job to worker pool
		select {
		case pool.jobs <- job:
			// Job sent successfully, start result collector
			go func(j *SettleJob) {
				err := <-j.Result
				resultChan <- err
			}(job)
		case <-ctx.Done():
			close(pool.jobs)
			pool.wg.Wait()
			return ctx.Err()
		}
	}

	// Close jobs channel (no more jobs)
	close(pool.jobs)

	// Wait for all workers to finish
	pool.wg.Wait()

	// Collect all results
	var errors []error
	for i := 0; i < len(markets); i++ {
		if err := <-resultChan; err != nil {
			errors = append(errors, err)
		}
	}

	t.keeper.logger.Info("worker pool completed",
		zap.Int("total_markets", len(markets)),
		zap.Int("failed", len(errors)),
		zap.Int("succeeded", len(markets)-len(errors)),
	)

	// Return first error if any (or could aggregate all errors)
	if len(errors) > 0 {
		return fmt.Errorf("settlement failed for %d markets (first error: %w)", len(errors), errors[0])
	}

	return nil
}

// ========================================
// OU Market Settlement Helpers
// ========================================

// calculateOUOutcome calculates the winning outcome for OU (Over/Under) markets
// Returns:
// - 0 (Over): totalGoals > line
// - 1 (Under): totalGoals < line
// - 2 (Push): totalGoals == line (only for whole number lines like 2.0)
func calculateOUOutcome(homeGoals, awayGoals uint8, line float64, isHalfLine bool) (uint8, error) {
	totalGoals := float64(homeGoals + awayGoals)

	// For half lines (e.g., 2.5), Push is impossible
	if isHalfLine {
		if totalGoals > line {
			return 0, nil // Over
		}
		return 1, nil // Under
	}

	// For whole number lines (e.g., 2.0), Push is possible
	if totalGoals > line {
		return 0, nil // Over
	} else if totalGoals < line {
		return 1, nil // Under
	}
	return 2, nil // Push
}

// parseOUParams extracts OU market parameters from market_params JSONB
func parseOUParams(params map[string]interface{}) (line float64, isHalfLine bool, err error) {
	// Check if this is an OU market
	marketType, ok := params["type"].(string)
	if !ok || marketType != "OU" {
		return 0, false, fmt.Errorf("not an OU market")
	}

	// Parse line (千分位表示，如 2500 = 2.5)
	lineValue, ok := params["line"]
	if !ok {
		return 0, false, fmt.Errorf("missing 'line' parameter")
	}

	// Handle both float64 and int representations
	switch v := lineValue.(type) {
	case float64:
		line = v / 1000.0 // 2500 -> 2.5
	case int:
		line = float64(v) / 1000.0
	default:
		return 0, false, fmt.Errorf("invalid 'line' type: %T", lineValue)
	}

	// Parse isHalfLine
	isHalfLineValue, ok := params["isHalfLine"]
	if !ok {
		return 0, false, fmt.Errorf("missing 'isHalfLine' parameter")
	}

	isHalfLine, ok = isHalfLineValue.(bool)
	if !ok {
		return 0, false, fmt.Errorf("invalid 'isHalfLine' type: %T", isHalfLineValue)
	}

	return line, isHalfLine, nil
}

// worker processes settle jobs from the job channel
func (p *SettleWorkerPool) worker(ctx context.Context, workerID int) {
	defer p.wg.Done()

	p.task.keeper.logger.Debug("worker started",
		zap.Int("worker_id", workerID),
	)

	processed := 0
	for job := range p.jobs {
		select {
		case <-ctx.Done():
			job.Result <- ctx.Err()
			p.task.keeper.logger.Warn("worker cancelled",
				zap.Int("worker_id", workerID),
				zap.Int("processed", processed),
			)
			return
		default:
			p.task.keeper.logger.Debug("worker processing market",
				zap.Int("worker_id", workerID),
				zap.String("market", job.Market.MarketAddress.Hex()),
				zap.String("event_id", job.Market.EventID),
			)

			// Process the settlement
			err := p.task.settleMarket(ctx, job.Market)
			job.Result <- err
			processed++

			if err != nil {
				p.task.keeper.logger.Error("worker settlement failed",
					zap.Int("worker_id", workerID),
					zap.String("market", job.Market.MarketAddress.Hex()),
					zap.Error(err),
				)
			} else {
				p.task.keeper.logger.Info("worker settlement succeeded",
					zap.Int("worker_id", workerID),
					zap.String("market", job.Market.MarketAddress.Hex()),
				)
			}
		}
	}

	p.task.keeper.logger.Debug("worker finished",
		zap.Int("worker_id", workerID),
		zap.Int("processed", processed),
	)
}
