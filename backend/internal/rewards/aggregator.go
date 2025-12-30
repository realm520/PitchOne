package rewards

import (
	"context"
	"database/sql"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/pitchone/sportsbook/internal/graphql"
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
	graphClient *graphql.Client // 用于查询 orders/quests/campaigns
	db          *sql.DB         // 仅用于 reward_distributions
}

// NewAggregator 创建聚合器
func NewAggregator(graphClient *graphql.Client, db *sql.DB) *Aggregator {
	return &Aggregator{
		graphClient: graphClient,
		db:          db,
	}
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

// aggregateReferralRewards 聚合推荐返佣（从 Subgraph 查询）
func (a *Aggregator) aggregateReferralRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	// 从 Subgraph 查询推荐奖励
	referralRewards, err := a.graphClient.GetReferralRewardsByTimeRange(ctx, weekStart.Unix(), weekEnd.Unix())
	if err != nil {
		return nil, fmt.Errorf("failed to query Subgraph for referral rewards: %w", err)
	}

	rewards := make(map[common.Address]*big.Int)

	for _, r := range referralRewards {
		referrer := r.Referrer.Address()
		amount := graphql.ParseBigInt(r.Amount)

		if existing, ok := rewards[referrer]; ok {
			rewards[referrer] = new(big.Int).Add(existing, amount)
		} else {
			rewards[referrer] = amount
		}
	}

	return rewards, nil
}

// aggregateTradingRewards 聚合交易奖励（基于交易量，从 Subgraph 查询）
func (a *Aggregator) aggregateTradingRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	// 从 Subgraph 分页查询订单
	userVolumes := make(map[common.Address]*big.Int)

	first := 1000
	skip := 0

	for {
		orders, err := a.graphClient.GetOrdersByTimeRange(ctx, weekStart.Unix(), weekEnd.Unix(), first, skip)
		if err != nil {
			return nil, fmt.Errorf("failed to query Subgraph for orders: %w", err)
		}

		if len(orders) == 0 {
			break
		}

		// 聚合用户交易量
		for _, order := range orders {
			user := order.User.Address()
			amount := graphql.ParseBigInt(order.Amount)

			if existing, ok := userVolumes[user]; ok {
				userVolumes[user] = new(big.Int).Add(existing, amount)
			} else {
				userVolumes[user] = amount
			}
		}

		skip += first

		// 如果返回数量少于请求数量，说明已经没有更多数据
		if len(orders) < first {
			break
		}
	}

	// 计算奖励：只有交易量 >= 1000 USDC（1000000000 with 6 decimals）的用户才有奖励
	rewards := make(map[common.Address]*big.Int)
	minVolume := big.NewInt(1000000000) // 1000 USDC

	for user, volume := range userVolumes {
		if volume.Cmp(minVolume) >= 0 {
			// 奖励 = 交易量 * 0.1% (示例)
			reward := new(big.Int).Div(volume, big.NewInt(1000))
			rewards[user] = reward
		}
	}

	return rewards, nil
}

// aggregateCampaignRewards 聚合活动奖励（Campaign + Quest）
func (a *Aggregator) aggregateCampaignRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	rewards := make(map[common.Address]*big.Int)

	// 1. 聚合 Quest 完成奖励
	questRewards, err := a.aggregateQuestRewards(ctx, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to aggregate quest rewards: %w", err)
	}
	for user, amount := range questRewards {
		rewards[user] = amount
	}

	// 2. 聚合 Campaign 参与奖励
	campaignRewards, err := a.aggregateCampaignParticipationRewards(ctx, weekStart, weekEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to aggregate campaign rewards: %w", err)
	}
	for user, amount := range campaignRewards {
		if existing, ok := rewards[user]; ok {
			rewards[user] = new(big.Int).Add(existing, amount)
		} else {
			rewards[user] = amount
		}
	}

	return rewards, nil
}

// aggregateQuestRewards 聚合任务完成奖励（从 Subgraph 查询）
func (a *Aggregator) aggregateQuestRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	// 从 Subgraph 查询任务奖励领取记录
	questClaims, err := a.graphClient.GetQuestRewardClaimsByTimeRange(ctx, weekStart.Unix(), weekEnd.Unix())
	if err != nil {
		return nil, fmt.Errorf("failed to query Subgraph for quest rewards: %w", err)
	}

	rewards := make(map[common.Address]*big.Int)

	for _, claim := range questClaims {
		user := claim.User.Address()
		amount := graphql.ParseBigInt(claim.RewardAmount)

		if existing, ok := rewards[user]; ok {
			rewards[user] = new(big.Int).Add(existing, amount)
		} else {
			rewards[user] = amount
		}
	}

	return rewards, nil
}

// aggregateCampaignParticipationRewards 聚合活动参与奖励
// TODO: 当 Subgraph 支持 Campaign 参与索引时，添加相应的 GraphQL 查询
// 目前返回空，活动奖励通过 Quest 系统领取
func (a *Aggregator) aggregateCampaignParticipationRewards(ctx context.Context, weekStart, weekEnd time.Time) (map[common.Address]*big.Int, error) {
	// Campaign 参与奖励目前由 Quest 系统处理
	// 如果需要独立的 Campaign 奖励追踪，需要扩展 Subgraph schema
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
