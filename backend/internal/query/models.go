package query

import (
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

// USDCInfo USDC 合约信息
type USDCInfo struct {
	TotalSupply *big.Int `json:"totalSupply"`
	Decimals    uint8    `json:"decimals"`
	Symbol      string   `json:"symbol"`
	Name        string   `json:"name"`
}

// VaultInfo Vault 状态信息
type VaultInfo struct {
	TotalAssets        *big.Int `json:"totalAssets"`
	TotalShares        *big.Int `json:"totalShares"`
	AvailableLiquidity *big.Int `json:"availableLiquidity"`
	Utilization        float64  `json:"utilization"`
}

// FeeRouterConfig 费用路由配置
type FeeRouterConfig struct {
	LpBps        *big.Int       `json:"lpBps"`
	PromoBps     *big.Int       `json:"promoBps"`
	InsuranceBps *big.Int       `json:"insuranceBps"`
	TreasuryBps  *big.Int       `json:"treasuryBps"`
	LpVault      common.Address `json:"lpVault"`
	PromoPool    common.Address `json:"promoPool"`
	Insurance    common.Address `json:"insurance"`
	Treasury     common.Address `json:"treasury"`
}

// FeeRouterStats 费用路由统计
type FeeRouterStats struct {
	TotalFeesReceived *big.Int `json:"totalFeesReceived"`
	LpFeesDistributed *big.Int `json:"lpFeesDistributed"`
}

// ReferralInfo 用户推荐信息
type ReferralInfo struct {
	User          common.Address `json:"user"`
	Referrer      common.Address `json:"referrer"`
	HasReferrer   bool           `json:"hasReferrer"`
	ReferralCount uint64         `json:"referralCount"`
	TotalRewards  *big.Int       `json:"totalRewards"`
	BoundAt       time.Time      `json:"boundAt"`
}

// ReferralStats 推荐系统统计
type ReferralStats struct {
	TotalReferrals      uint64   `json:"totalReferrals"`
	TotalRewardsEarned  *big.Int `json:"totalRewardsEarned"`
	ActiveReferrers     uint64   `json:"activeReferrers"`
}

// FactoryInfo 工厂信息
type FactoryInfo struct {
	Address       common.Address `json:"address"`
	MarketCount   uint64         `json:"marketCount"`
	TemplateCount uint64         `json:"templateCount"`
}

// TemplateInfo 模板信息
type TemplateInfo struct {
	ID             [32]byte       `json:"id"`
	Name           string         `json:"name"`
	Implementation common.Address `json:"implementation"`
	Active         bool           `json:"active"`
	MarketCount    uint64         `json:"marketCount"`
}

// MarketSummary 市场摘要
type MarketSummary struct {
	Address      common.Address `json:"address"`
	TemplateID   [32]byte       `json:"templateId"`
	TemplateName string         `json:"templateName"`
	Status       uint8          `json:"status"`
	StatusName   string         `json:"statusName"`
	MatchID      string         `json:"matchId"`
	HomeTeam     string         `json:"homeTeam"`
	AwayTeam     string         `json:"awayTeam"`
	KickoffTime  time.Time      `json:"kickoffTime"`
}

// MarketInfo 市场详细信息
type MarketInfo struct {
	Address        common.Address `json:"address"`
	TemplateID     [32]byte       `json:"templateId"`
	TemplateName   string         `json:"templateName"`
	MatchID        string         `json:"matchId"`
	HomeTeam       string         `json:"homeTeam"`
	AwayTeam       string         `json:"awayTeam"`
	KickoffTime    time.Time      `json:"kickoffTime"`
	Status         uint8          `json:"status"`
	StatusName     string         `json:"statusName"`
	OutcomeCount   uint64         `json:"outcomeCount"`
	WinningOutcome int64          `json:"winningOutcome"` // -1 表示未结算
	TotalLiquidity *big.Int       `json:"totalLiquidity"`
	FeeRate        uint64         `json:"feeRate"`
}

// OutcomePrice 结果赔率
type OutcomePrice struct {
	OutcomeID    uint64   `json:"outcomeId"`
	OutcomeName  string   `json:"outcomeName"`
	Price        *big.Int `json:"price"`        // 概率 (1e18 精度)
	Odds         float64  `json:"odds"`         // 赔率
	ImpliedProb  float64  `json:"impliedProb"`  // 隐含概率
	Reserve      *big.Int `json:"reserve"`
}

// Position 头寸信息
type Position struct {
	Owner     common.Address `json:"owner"`
	OutcomeID uint64         `json:"outcomeId"`
	Balance   *big.Int       `json:"balance"`
	CostBasis *big.Int       `json:"costBasis"`
}

// UserPosition 用户头寸（跨市场）
type UserPosition struct {
	Market       common.Address `json:"market"`
	MarketInfo   *MarketSummary `json:"marketInfo"`
	OutcomeID    uint64         `json:"outcomeId"`
	OutcomeName  string         `json:"outcomeName"`
	Balance      *big.Int       `json:"balance"`
}

// Order 订单记录
type Order struct {
	ID          string         `json:"id"`
	Market      common.Address `json:"market"`
	User        common.Address `json:"user"`
	OutcomeID   uint64         `json:"outcomeId"`
	Amount      *big.Int       `json:"amount"`
	Shares      *big.Int       `json:"shares"`
	Price       *big.Int       `json:"price"`
	Timestamp   time.Time      `json:"timestamp"`
	TxHash      common.Hash    `json:"txHash"`
}

// PlatformStats 平台统计
type PlatformStats struct {
	TotalMarkets       uint64   `json:"totalMarkets"`
	ActiveMarkets      uint64   `json:"activeMarkets"`
	TotalVolume        *big.Int `json:"totalVolume"`
	TotalFees          *big.Int `json:"totalFees"`
	TotalUsers         uint64   `json:"totalUsers"`
	TotalLiquidity     *big.Int `json:"totalLiquidity"`
}

// VolumeData 交易量数据
type VolumeData struct {
	Period    string   `json:"period"`
	Volume    *big.Int `json:"volume"`
	OrderCount uint64  `json:"orderCount"`
	UniqueUsers uint64 `json:"uniqueUsers"`
}

// ListMarketsOptions 市场列表选项
type ListMarketsOptions struct {
	Status     *uint8    // 筛选状态
	TemplateID *[32]byte // 筛选模板
	Offset     uint64    // 分页偏移
	Limit      uint64    // 分页大小
}
