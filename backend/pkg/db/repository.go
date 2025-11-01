package db

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/pitchone/sportsbook/pkg/models"
	"go.uber.org/zap"
)

// Repository 数据访问层
type Repository struct {
	client *Client
	logger *zap.Logger
}

// NewRepository 创建数据仓库
func NewRepository(client *Client, logger *zap.Logger) *Repository {
	return &Repository{
		client: client,
		logger: logger,
	}
}

// SaveMarket 保存市场数据
func (r *Repository) SaveMarket(ctx context.Context, event *models.MarketCreatedEvent) error {
	// 序列化 MarketParams 为 JSONB
	var paramsJSON []byte
	var err error
	if event.MarketParams != nil && len(event.MarketParams) > 0 {
		paramsJSON, err = json.Marshal(event.MarketParams)
		if err != nil {
			return fmt.Errorf("failed to marshal market_params: %w", err)
		}
	} else {
		paramsJSON = []byte("{}") // 空 JSONB
	}

	query := `
		INSERT INTO markets (
			id, template_id, match_id, home_team, away_team,
			kickoff_time, status, market_params, created_at, block_number, tx_hash, log_index
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (tx_hash, log_index) DO NOTHING
	`

	_, err = r.client.DB().ExecContext(ctx, query,
		event.MarketAddress.Hex(),
		event.TemplateID.Hex(),
		event.MatchID,
		event.HomeTeam,
		event.AwayTeam,
		event.KickoffTime,
		"open",
		paramsJSON, // ← 新增 market_params
		event.BlockTime,
		event.BlockNumber,
		event.TxHash,
		event.LogIndex,
	)

	if err != nil {
		return fmt.Errorf("failed to save market: %w", err)
	}

	r.logger.Debug("market saved",
		zap.String("market", event.MarketAddress.Hex()),
		zap.String("match_id", event.MatchID),
		zap.String("template_type", event.TemplateType),
	)

	return nil
}

// SaveOrder 保存订单数据
func (r *Repository) SaveOrder(ctx context.Context, event *models.BetPlacedEvent) error {
	query := `
		INSERT INTO orders (
			market_id, user_address, outcome, amount, shares,
			new_price, placed_at, block_number, tx_hash, log_index
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (tx_hash, log_index) DO NOTHING
	`

	_, err := r.client.DB().ExecContext(ctx, query,
		event.MarketAddress.Hex(),
		event.User.Hex(),
		event.Outcome,
		event.Amount.String(),
		event.Shares.String(),
		event.NewPrice.String(),
		event.BlockTime,
		event.BlockNumber,
		event.TxHash,
		event.LogIndex,
	)

	if err != nil {
		return fmt.Errorf("failed to save order: %w", err)
	}

	// 更新或创建 position 记录
	if err := r.upsertPosition(ctx, event); err != nil {
		return err
	}

	r.logger.Debug("order saved",
		zap.String("market", event.MarketAddress.Hex()),
		zap.String("user", event.User.Hex()),
		zap.Uint8("outcome", event.Outcome),
	)

	return nil
}

// upsertPosition 更新用户头寸
func (r *Repository) upsertPosition(ctx context.Context, event *models.BetPlacedEvent) error {
	query := `
		INSERT INTO positions (market_id, user_address, outcome, balance, updated_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (market_id, user_address, outcome) DO UPDATE
		SET balance = positions.balance + EXCLUDED.balance,
		    updated_at = EXCLUDED.updated_at
	`

	_, err := r.client.DB().ExecContext(ctx, query,
		event.MarketAddress.Hex(),
		event.User.Hex(),
		event.Outcome,
		event.Shares.String(),
		event.BlockTime,
	)

	if err != nil {
		return fmt.Errorf("failed to upsert position: %w", err)
	}

	return nil
}

// UpdateMarketStatus 更新市场状态
func (r *Repository) UpdateMarketStatus(ctx context.Context, marketID string, status string, updatedAt int64) error {
	query := `
		UPDATE markets
		SET status = $1, updated_at = to_timestamp($2)
		WHERE id = $3
	`

	_, err := r.client.DB().ExecContext(ctx, query, status, updatedAt, marketID)
	if err != nil {
		return fmt.Errorf("failed to update market status: %w", err)
	}

	r.logger.Debug("market status updated",
		zap.String("market", marketID),
		zap.String("status", status),
	)

	return nil
}

// SavePayout 保存兑付记录
func (r *Repository) SavePayout(ctx context.Context, event *models.RedeemedEvent) error {
	query := `
		INSERT INTO payouts (
			market_id, user_address, outcome, shares, payout_amount,
			paid_at, block_number, tx_hash, log_index
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (tx_hash, log_index) DO NOTHING
	`

	_, err := r.client.DB().ExecContext(ctx, query,
		event.MarketAddress.Hex(),
		event.User.Hex(),
		event.Outcome,
		event.Shares.String(),
		event.Payout.String(),
		event.BlockTime,
		event.BlockNumber,
		event.TxHash,
		event.LogIndex,
	)

	if err != nil {
		return fmt.Errorf("failed to save payout: %w", err)
	}

	// 更新 position 余额
	if err := r.updatePositionAfterRedeem(ctx, event); err != nil {
		return err
	}

	r.logger.Debug("payout saved",
		zap.String("market", event.MarketAddress.Hex()),
		zap.String("user", event.User.Hex()),
	)

	return nil
}

// updatePositionAfterRedeem 兑付后更新头寸
func (r *Repository) updatePositionAfterRedeem(ctx context.Context, event *models.RedeemedEvent) error {
	query := `
		UPDATE positions
		SET balance = GREATEST(balance::numeric - $1::numeric, 0),
		    updated_at = $2
		WHERE market_id = $3 AND user_address = $4 AND outcome = $5
	`

	_, err := r.client.DB().ExecContext(ctx, query,
		event.Shares.String(),
		event.BlockTime,
		event.MarketAddress.Hex(),
		event.User.Hex(),
		event.Outcome,
	)

	if err != nil {
		return fmt.Errorf("failed to update position after redeem: %w", err)
	}

	return nil
}

// SaveMarketResolution 保存市场结算结果
func (r *Repository) SaveMarketResolution(ctx context.Context, event *models.ResolvedEvent) error {
	query := `
		UPDATE markets
		SET status = 'resolved',
		    winning_outcome = $1,
		    result_hash = $2,
		    resolved_at = to_timestamp($3),
		    updated_at = to_timestamp($3)
		WHERE id = $4
	`

	_, err := r.client.DB().ExecContext(ctx, query,
		event.WinningOutcome,
		event.ResultHash.Hex(),
		event.ResolveTime,
		event.MarketAddress.Hex(),
	)

	if err != nil {
		return fmt.Errorf("failed to save market resolution: %w", err)
	}

	r.logger.Info("market resolved",
		zap.String("market", event.MarketAddress.Hex()),
		zap.Uint8("winning_outcome", event.WinningOutcome),
	)

	return nil
}

// BatchSaveEvents 批量保存事件（事务）
func (r *Repository) BatchSaveEvents(ctx context.Context, events []interface{}) error {
	tx, err := r.client.BeginTx(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	for _, event := range events {
		switch e := event.(type) {
		case *models.MarketCreatedEvent:
			if err := r.SaveMarket(ctx, e); err != nil {
				return err
			}
		case *models.BetPlacedEvent:
			if err := r.SaveOrder(ctx, e); err != nil {
				return err
			}
		case *models.LockedEvent:
			if err := r.UpdateMarketStatus(ctx, e.MarketAddress.Hex(), "locked", int64(e.LockTime)); err != nil {
				return err
			}
		case *models.ResolvedEvent:
			if err := r.SaveMarketResolution(ctx, e); err != nil {
				return err
			}
		case *models.RedeemedEvent:
			if err := r.SavePayout(ctx, e); err != nil {
				return err
			}
		case *models.FinalizedEvent:
			if err := r.UpdateMarketStatus(ctx, e.MarketAddress.Hex(), "finalized", int64(e.FinalizeTime)); err != nil {
				return err
			}
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	r.logger.Debug("batch events saved", zap.Int("count", len(events)))
	return nil
}

// GetLastProcessedBlock 获取最后处理的区块
func (r *Repository) GetLastProcessedBlock(ctx context.Context) (uint64, error) {
	return r.client.GetLastProcessedBlock(ctx)
}

// UpdateLastProcessedBlock 更新最后处理的区块
func (r *Repository) UpdateLastProcessedBlock(ctx context.Context, blockNumber uint64) error {
	return r.client.UpdateLastProcessedBlock(ctx, blockNumber)
}
