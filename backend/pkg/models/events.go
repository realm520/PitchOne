package models

import (
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
)

// Event 通用事件结构
type Event struct {
	TxHash      string
	LogIndex    uint
	BlockNumber uint64
	BlockTime   time.Time
	EventType   string
}

// MarketCreatedEvent 市场创建事件
type MarketCreatedEvent struct {
	Event
	MarketAddress common.Address
	TemplateID    common.Address
	MatchID       string
	HomeTeam      string
	AwayTeam      string
	KickoffTime   uint64

	// 模板特定参数 (用于 OU/AH 等模板)
	// 将被序列化为 JSONB 存入 market_params 字段
	TemplateType  string                 // "WDL" / "OU" / "AH"
	MarketParams  map[string]interface{} // 模板参数 (如 OU 的 line, isHalfLine)
}

// BetPlacedEvent 下注事件
type BetPlacedEvent struct {
	Event
	MarketAddress common.Address
	User          common.Address
	Outcome       uint8
	Amount        *big.Int
	Shares        *big.Int
	NewPrice      *big.Int
}

// LockedEvent 锁盘事件
type LockedEvent struct {
	Event
	MarketAddress common.Address
	LockTime      uint64
}

// ResolvedEvent 结算事件
type ResolvedEvent struct {
	Event
	MarketAddress  common.Address
	WinningOutcome uint8
	ResolveTime    uint64
	ResultHash     common.Hash
}

// RedeemedEvent 兑付事件
type RedeemedEvent struct {
	Event
	MarketAddress common.Address
	User          common.Address
	Outcome       uint8
	Shares        *big.Int
	Payout        *big.Int
}

// FinalizedEvent 最终确认事件
type FinalizedEvent struct {
	Event
	MarketAddress common.Address
	FinalizeTime  uint64
}
