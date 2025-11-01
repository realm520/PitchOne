package rewards

import (
	"context"
	"database/sql"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

// RewardType 奖励类型
type RewardType string

const (
	RewardTypeReferral RewardType = "referral" // 推荐返佣
	RewardTypeTrading  RewardType = "trading"  // 交易奖励
	RewardTypeCampaign RewardType = "campaign" // 活动奖励
)

// UserReward 用户奖励汇总
type UserReward struct {
	User            common.Address
	ReferralRewards *big.Int
	TradingRewards  *big.Int
	CampaignRewards *big.Int
	TotalRewards    *big.Int
}

// Aggregator 奖励聚合器
type Aggregator struct {
	db *sql.DB
}

// NewAggregator 创建聚合器
func NewAggregator(db *sql.DB) *Aggregator {
	return &Aggregator{db: db}
}

// AggregateWeeklyRewards 聚合指定周的所有奖励
func (a *Aggregator) AggregateWeeklyRewards(ctx context.Context, week uint64) ([]RewardEntry, error) {
	// 计算周时间范围
	weekStart, weekEnd := GetWeekRange(week)

	// 1. 聚合推荐返佣
	referralRewards, err := a.aggregateReferralRewards(ctx, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to aggregate referral rewards: %w", err)
	}

	// 2. 聚合交易奖励（基于交易量）
	tradingRewards, err := a.aggregateTradingRewards(ctx, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to aggregate trading rewards: %w", err)
	}

	// 3. 聚合活动奖励
	campaignRewards, err := a.aggregateCampaignRewards(ctx, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to aggregate campaign rewards: %w", err)
	}

	// 合并所有奖励
	userRewards := mergeRewards(referralRewards, tradingRewards, campaignRewards)

	// 转换为 RewardEntry
	entries := make([]RewardEntry, 0, len(userRewards))
	for user, reward := range userRewards {
		if reward.TotalRewards.Cmp(big.NewInt(0)) > 0 {
			entries = append(entries, RewardEntry{
				User:   user,
				Week:   week,
				Amount: reward.TotalRewards.String(),
			})
		}
	}

	return entries, nil
}

// aggregateReferralRewards 聚合推荐返佣
func (a *Aggregator) aggregateReferralRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	query := `
		SELECT
			o.referrer,
			SUM(o.fee * 0.08) as total_rewards  -- 假设8%返佣率
		FROM orders o
		WHERE o.referrer IS NOT NULL
			AND o.timestamp >= $1
			AND o.timestamp < $2
		GROUP BY o.referrer
	`

	rows, err := a.db.QueryContext(ctx, query, weekStart.Unix(), weekEnd.Unix())
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rewards := make(map[common.Address]*big.Int)

	for rows.Next() {
		var referrerHex string
		var rewardStr string

		if err := rows.Scan(&referrerHex, &rewardStr); err != nil {
			return nil, err
		}

		referrer := common.HexToAddress(referrerHex)
		reward, ok := new(big.Int).SetString(rewardStr, 10)
		if !ok {
			return nil, fmt.Errorf("invalid reward amount: %s", rewardStr)
		}

		rewards[referrer] = reward
	}

	return rewards, rows.Err()
}

// aggregateTradingRewards 聚合交易奖励（基于交易量）
func (a *Aggregator) aggregateTradingRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	query := `
		SELECT
			user_address,
			SUM(stake) as total_volume
		FROM orders
		WHERE timestamp >= $1
			AND timestamp < $2
		GROUP BY user_address
		HAVING SUM(stake) >= 1000000000  -- 最小交易量（1000 USDC with 6 decimals）
	`

	rows, err := a.db.QueryContext(ctx, query, weekStart.Unix(), weekEnd.Unix())
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rewards := make(map[common.Address]*big.Int)

	for rows.Next() {
		var userHex string
		var volumeStr string

		if err := rows.Scan(&userHex, &volumeStr); err != nil {
			return nil, err
		}

		user := common.HexToAddress(userHex)
		volume, ok := new(big.Int).SetString(volumeStr, 10)
		if !ok {
			return nil, fmt.Errorf("invalid volume: %s", volumeStr)
		}

		// 奖励 = 交易量 * 0.1% (示例)
		reward := new(big.Int).Div(volume, big.NewInt(1000))
		rewards[user] = reward
	}

	return rewards, rows.Err()
}

// aggregateCampaignRewards 聚合活动奖励
func (a *Aggregator) aggregateCampaignRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	// TODO: 实现活动奖励逻辑
	// 这里简化处理，返回空
	return make(map[common.Address]*big.Int), nil
}

// mergeRewards 合并多个奖励映射
func mergeRewards(rewardMaps ...map[common.Address]*big.Int) map[common.Address]*UserReward {
	result := make(map[common.Address]*UserReward)

	for _, rewardMap := range rewardMaps {
		for user, amount := range rewardMap {
			if _, exists := result[user]; !exists {
				result[user] = &UserReward{
					User:            user,
					ReferralRewards: big.NewInt(0),
					TradingRewards:  big.NewInt(0),
					CampaignRewards: big.NewInt(0),
					TotalRewards:    big.NewInt(0),
				}
			}

			result[user].TotalRewards.Add(result[user].TotalRewards, amount)
		}
	}

	return result
}

// GetWeekRange 计算周时间范围
// week 0 = 从 2024-01-01 00:00:00 UTC 开始
func GetWeekRange(week uint64) (start, end time.Time) {
	epoch := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
	start = epoch.Add(time.Duration(week) * 7 * 24 * time.Hour)
	end = start.Add(7 * 24 * time.Hour)
	return start, end
}

// GetCurrentWeek 获取当前周编号
func GetCurrentWeek() uint64 {
	epoch := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
	duration := time.Since(epoch)
	return uint64(duration.Hours() / (7 * 24))
}

// CalculateScaleBps 根据可用预算计算缩放比例
func CalculateScaleBps(totalRewards *big.Int, availableBudget *big.Int) uint64 {
	if totalRewards.Cmp(big.NewInt(0)) == 0 {
		return 10000 // 100%
	}

	if availableBudget.Cmp(totalRewards) >= 0 {
		return 10000 // 足够预算，100%
	}

	// 计算缩放比例: (availableBudget * 10000) / totalRewards
	scale := new(big.Int).Mul(availableBudget, big.NewInt(10000))
	scale.Div(scale, totalRewards)

	scaleUint64 := scale.Uint64()

	// 确保不低于10%
	if scaleUint64 < 1000 {
		scaleUint64 = 1000
	}

	return scaleUint64
}

// SaveDistribution 保存分配数据到数据库
func (a *Aggregator) SaveDistribution(ctx context.Context, dist *MerkleDistribution) error {
	query := `
		INSERT INTO reward_distributions (
			week, merkle_root, total_amount, recipients,
			scale_bps, created_at
		) VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (week) DO UPDATE SET
			merkle_root = EXCLUDED.merkle_root,
			total_amount = EXCLUDED.total_amount,
			recipients = EXCLUDED.recipients,
			scale_bps = EXCLUDED.scale_bps,
			updated_at = EXCLUDED.created_at
	`

	_, err := a.db.ExecContext(ctx, query,
		dist.Week,
		dist.Root,
		dist.TotalAmount,
		dist.Recipients,
		dist.ScaleBps,
		dist.CreatedAt,
	)

	return err
}

// GetDistribution 从数据库获取分配数据
func (a *Aggregator) GetDistribution(ctx context.Context, week uint64) (*MerkleDistribution, error) {
	query := `
		SELECT week, merkle_root, total_amount, recipients, scale_bps, created_at
		FROM reward_distributions
		WHERE week = $1
	`

	var dist MerkleDistribution
	err := a.db.QueryRowContext(ctx, query, week).Scan(
		&dist.Week,
		&dist.Root,
		&dist.TotalAmount,
		&dist.Recipients,
		&dist.ScaleBps,
		&dist.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("distribution not found for week %d", week)
	}

	if err != nil {
		return nil, err
	}

	return &dist, nil
}
