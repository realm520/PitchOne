// Package graphql 提供 Subgraph GraphQL API 的客户端
package graphql

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// Market 表示 Subgraph 中的 Market 实体
type Market struct {
	ID            string `json:"id"`            // 市场地址
	MatchID       string `json:"matchId"`       // 赛事 ID
	TemplateID    string `json:"templateId"`    // 模板 ID (WDL, OU, AH 等)
	HomeTeam      string `json:"homeTeam"`      // 主队名称
	AwayTeam      string `json:"awayTeam"`      // 客队名称
	State         string `json:"state"`         // 市场状态: Open, Locked, Resolved, Finalized
	KickoffTime   string `json:"kickoffTime"`   // 开赛时间 (Unix 时间戳字符串)
	LockTime      string `json:"lockTime"`      // 锁盘时间 (Unix 时间戳字符串)
	MatchEndTime  string `json:"matchEndTime"`  // 比赛结束时间 (Unix 时间戳字符串)
	Oracle        string `json:"oracle"`        // 预言机地址
	PricingEngine string `json:"pricingEngine"` // 定价引擎地址
	Version       string `json:"version"`       // 市场版本: v2, v3
	Line          string `json:"line"`          // 盘口线 (OU/AH 市场)
	IsHalfLine    bool   `json:"isHalfLine"`    // 是否半球盘
	LockedAt      string `json:"lockedAt"`      // 锁盘时间戳
	ResolvedAt    string `json:"resolvedAt"`    // 结算时间戳
	LockTxHash    string `json:"lockTxHash"`    // 锁盘交易哈希
	SettleTxHash  string `json:"settleTxHash"`  // 结算交易哈希
	HomeScore     *int   `json:"homeScore"`     // 主队进球数
	AwayScore     *int   `json:"awayScore"`     // 客队进球数
	WinnerOutcome *int   `json:"winnerOutcome"` // 获胜结果
}

// Address 返回市场地址
func (m *Market) Address() common.Address {
	return common.HexToAddress(m.ID)
}

// OracleAddress 返回预言机地址
func (m *Market) OracleAddress() common.Address {
	if m.Oracle == "" {
		return common.Address{}
	}
	return common.HexToAddress(m.Oracle)
}

// Order 表示 Subgraph 中的 Order 实体
type Order struct {
	ID        string `json:"id"`        // 订单 ID
	Market    string `json:"market"`    // 市场地址
	User      User   `json:"user"`      // 用户
	Outcome   int    `json:"outcome"`   // 下注方向
	Amount    string `json:"amount"`    // 下注金额 (USDC)
	Shares    string `json:"shares"`    // 获得份额
	Fee       string `json:"fee"`       // 手续费
	Referrer  string `json:"referrer"`  // 推荐人地址
	Timestamp string `json:"timestamp"` // 下注时间戳
}

// User 表示 Subgraph 中的 User 实体
type User struct {
	ID             string `json:"id"`             // 用户地址
	TotalBetAmount string `json:"totalBetAmount"` // 总下注金额
	TotalRedeemed  string `json:"totalRedeemed"`  // 总赎回金额
	TotalBets      int    `json:"totalBets"`      // 下注次数
	Referrer       string `json:"referrer"`       // 推荐人地址
}

// Address 返回用户地址
func (u *User) Address() common.Address {
	return common.HexToAddress(u.ID)
}

// ReferralReward 表示推荐返佣记录
type ReferralReward struct {
	ID        string `json:"id"`        // 记录 ID
	Referrer  User   `json:"referrer"`  // 推荐人
	Referee   User   `json:"referee"`   // 被推荐人
	Amount    string `json:"amount"`    // 返佣金额
	Timestamp string `json:"timestamp"` // 时间戳
}

// QuestRewardClaim 表示任务奖励领取记录
type QuestRewardClaim struct {
	ID           string `json:"id"`           // 记录 ID
	User         User   `json:"user"`         // 用户
	RewardAmount string `json:"rewardAmount"` // 奖励金额
	Timestamp    string `json:"timestamp"`    // 时间戳
}

// GraphQL 查询响应结构

// MarketsResponse 表示市场查询响应
type MarketsResponse struct {
	Data struct {
		Markets []Market `json:"markets"`
	} `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// MarketResponse 表示单个市场查询响应
type MarketResponse struct {
	Data struct {
		Market *Market `json:"market"`
	} `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// OrdersResponse 表示订单查询响应
type OrdersResponse struct {
	Data struct {
		Orders []Order `json:"orders"`
	} `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// ReferralRewardsResponse 表示推荐奖励查询响应
type ReferralRewardsResponse struct {
	Data struct {
		ReferralRewards []ReferralReward `json:"referralRewards"`
	} `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// QuestRewardClaimsResponse 表示任务奖励查询响应
type QuestRewardClaimsResponse struct {
	Data struct {
		QuestRewardClaims []QuestRewardClaim `json:"questRewardClaims"`
	} `json:"data"`
	Errors []GraphQLError `json:"errors,omitempty"`
}

// GraphQLError 表示 GraphQL 错误
type GraphQLError struct {
	Message   string `json:"message"`
	Locations []struct {
		Line   int `json:"line"`
		Column int `json:"column"`
	} `json:"locations,omitempty"`
	Path []interface{} `json:"path,omitempty"`
}

// ParseBigInt 将字符串解析为 *big.Int
func ParseBigInt(s string) *big.Int {
	if s == "" {
		return big.NewInt(0)
	}
	n := new(big.Int)
	n.SetString(s, 10)
	return n
}
