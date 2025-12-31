package keeper

import (
	"context"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/pitchone/sportsbook/internal/rewards"
	"go.uber.org/zap"
)

// RewardsTask handles weekly rewards distribution
type RewardsTask struct {
	keeper     *Keeper
	aggregator *rewards.Aggregator
	publisher  *rewards.Publisher
	config     RewardsConfig
}

// NewRewardsTask creates a new RewardsTask
func NewRewardsTask(
	keeper *Keeper,
	aggregator *rewards.Aggregator,
	publisher *rewards.Publisher,
	config RewardsConfig,
) *RewardsTask {
	return &RewardsTask{
		keeper:     keeper,
		aggregator: aggregator,
		publisher:  publisher,
		config:     config,
	}
}

// Execute implements the Task interface
func (t *RewardsTask) Execute(ctx context.Context) error {
	// Check if it's time to run (Sunday 23:59 UTC)
	if !t.shouldRunNow() {
		t.keeper.logger.Debug("rewards task: not time to run yet")
		return nil
	}

	week := rewards.GetCurrentWeek() - 1 // Process previous week
	t.keeper.logger.Info("executing rewards distribution task",
		zap.Uint64("week", week),
	)

	startTime := time.Now()

	// 1. Check if already processed
	existing, _ := t.aggregator.GetDistribution(ctx, week)
	if existing != nil {
		t.keeper.logger.Info("week already processed, skipping",
			zap.Uint64("week", week),
			zap.String("root", existing.Root),
		)
		return nil
	}

	// 2. Aggregate rewards
	t.keeper.logger.Info("aggregating rewards...", zap.Uint64("week", week))
	entries, err := t.aggregator.AggregateWeeklyRewards(ctx, week)
	if err != nil {
		t.keeper.logger.Error("failed to aggregate rewards",
			zap.Uint64("week", week),
			zap.Error(err),
		)
		return err
	}

	t.keeper.logger.Info("rewards aggregated",
		zap.Uint64("week", week),
		zap.Int("entries", len(entries)),
	)

	if len(entries) == 0 {
		t.keeper.logger.Info("no rewards to distribute",
			zap.Uint64("week", week),
		)
		return nil
	}

	// 3. Build Merkle distribution
	t.keeper.logger.Info("building Merkle tree...")
	scaleBps := uint64(10000) // TODO: Query available budget from contract
	distribution, err := rewards.BuildDistribution(week, entries, scaleBps)
	if err != nil {
		t.keeper.logger.Error("failed to build distribution",
			zap.Uint64("week", week),
			zap.Error(err),
		)
		return err
	}

	distribution.CreatedAt = time.Now().Unix()

	t.keeper.logger.Info("Merkle tree built",
		zap.String("root", distribution.Root),
		zap.Int("recipients", distribution.Recipients),
		zap.String("totalAmount", distribution.TotalAmount),
		zap.Uint64("scaleBps", distribution.ScaleBps),
	)

	// 4. Save to database
	if err := t.aggregator.SaveDistribution(ctx, distribution); err != nil {
		t.keeper.logger.Error("failed to save distribution",
			zap.Uint64("week", week),
			zap.Error(err),
		)
		return err
	}

	t.keeper.logger.Info("distribution saved to database")

	// 5. Publish to chain (if publisher is configured)
	if t.publisher != nil {
		t.keeper.logger.Info("publishing to blockchain...")

		tx, err := t.publisher.PublishRoot(ctx, distribution)
		if err != nil {
			t.keeper.logger.Error("failed to publish root",
				zap.Uint64("week", week),
				zap.Error(err),
			)
			// Don't return error - distribution is saved, can retry publish later
			t.sendAlert("RewardsPublishFailed", map[string]interface{}{
				"week":  week,
				"error": err.Error(),
			})
			return nil
		}

		t.keeper.logger.Info("transaction sent",
			zap.String("txHash", tx.Hash().Hex()),
		)

		// Wait for confirmation
		t.keeper.logger.Info("waiting for confirmation...")
		receipt, err := t.publisher.WaitForConfirmation(ctx, tx, 3)
		if err != nil {
			t.keeper.logger.Error("transaction failed",
				zap.Uint64("week", week),
				zap.Error(err),
			)
			t.sendAlert("RewardsTransactionFailed", map[string]interface{}{
				"week":   week,
				"txHash": tx.Hash().Hex(),
				"error":  err.Error(),
			})
			return nil
		}

		t.keeper.logger.Info("transaction confirmed",
			zap.Uint64("block", receipt.BlockNumber.Uint64()),
			zap.Uint64("gasUsed", receipt.GasUsed),
		)

		// Verify on-chain
		publishedRoot, err := t.publisher.GetPublishedRoot(ctx, week)
		if err != nil {
			t.keeper.logger.Warn("failed to verify published root", zap.Error(err))
		} else if publishedRoot.Hex() != distribution.Root {
			t.keeper.logger.Error("root mismatch!",
				zap.String("expected", distribution.Root),
				zap.String("actual", publishedRoot.Hex()),
			)
		} else {
			t.keeper.logger.Info("root verified on-chain",
				zap.String("root", publishedRoot.Hex()),
			)
		}
	} else {
		t.keeper.logger.Warn("skipping on-chain publication (no publisher configured)")
	}

	duration := time.Since(startTime)
	t.keeper.logger.Info("rewards distribution completed",
		zap.Uint64("week", week),
		zap.Duration("duration", duration),
	)

	// Send success alert
	t.sendAlert("RewardsDistributionCompleted", map[string]interface{}{
		"week":        week,
		"recipients":  distribution.Recipients,
		"totalAmount": distribution.TotalAmount,
		"root":        distribution.Root,
	})

	return nil
}

// shouldRunNow checks if rewards task should run now
// Runs at Sunday 23:59 UTC (or whenever task interval triggers near that time)
func (t *RewardsTask) shouldRunNow() bool {
	now := time.Now().UTC()

	// Check if it's Sunday
	if now.Weekday() != time.Sunday {
		return false
	}

	// Check if it's between 23:00 and 23:59
	hour := now.Hour()
	if hour != 23 {
		return false
	}

	return true
}

// sendAlert sends an alert through the alert manager
func (t *RewardsTask) sendAlert(title string, alertContext map[string]interface{}) {
	if t.keeper.alertManager == nil || !t.keeper.config.AlertsEnabled {
		return
	}

	alert := &Alert{
		Severity: AlertSeverityInfo,
		Type:     AlertTypeTaskExecutionFailure, // Reuse existing type
		Title:    title,
		Message:  "Weekly rewards distribution event",
		Context:  alertContext,
	}

	ctx := context.Background()
	if err := t.keeper.alertManager.Notify(ctx, alert); err != nil {
		t.keeper.logger.Warn("failed to send alert",
			zap.String("title", title),
			zap.Error(err),
		)
	}
}

// CreateRewardsPublisher creates a rewards publisher if configured
func CreateRewardsPublisher(config RewardsConfig, logger *zap.Logger) (*rewards.Publisher, error) {
	if config.DistributorAddress == "" || config.PrivateKey == "" || config.RPCEndpoint == "" {
		logger.Warn("rewards publisher not configured (missing distributor/privateKey/rpc)")
		return nil, nil
	}

	publisher, err := rewards.NewPublisher(
		config.RPCEndpoint,
		common.HexToAddress(config.DistributorAddress),
		config.PrivateKey,
	)
	if err != nil {
		return nil, err
	}

	logger.Info("rewards publisher initialized",
		zap.String("distributor", config.DistributorAddress),
	)

	return publisher, nil
}
