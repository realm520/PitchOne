package indexer

import (
	"context"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"go.uber.org/zap"

	"github.com/pitchone/sportsbook/pkg/db"
	"github.com/pitchone/sportsbook/pkg/models"
)

// EventListener 事件监听器
type EventListener struct {
	client     *ethclient.Client
	wsClient   *ethclient.Client
	repository *db.Repository
	logger     *zap.Logger
	config     *Config
	eventSigs  map[string]common.Hash
}

// Config 监听器配置
type Config struct {
	RPCURL          string
	WSURL           string
	ContractAddress common.Address
	StartBlock      uint64
	BatchSize       uint64
	FinalityBlocks  uint64
	PollingInterval time.Duration
}

// NewEventListener 创建事件监听器
func NewEventListener(cfg *Config, repo *db.Repository, logger *zap.Logger) (*EventListener, error) {
	// HTTP 客户端（用于轮询和历史查询）
	client, err := ethclient.Dial(cfg.RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RPC: %w", err)
	}

	// WebSocket 客户端（用于实时订阅）
	var wsClient *ethclient.Client
	if cfg.WSURL != "" {
		wsClient, err = ethclient.Dial(cfg.WSURL)
		if err != nil {
			logger.Warn("failed to connect to WebSocket, will use polling fallback", zap.Error(err))
		}
	}

	// 预计算事件签名
	eventSigs := map[string]common.Hash{
		"BetPlaced":          crypto.Keccak256Hash([]byte("BetPlaced(address,uint8,uint256,uint256,uint256)")),
		"Locked":             crypto.Keccak256Hash([]byte("Locked(uint256)")),
		"Resolved":           crypto.Keccak256Hash([]byte("Resolved(uint256,uint256)")),
		"ResolvedWithOracle": crypto.Keccak256Hash([]byte("ResolvedWithOracle(uint256,bytes32,uint256)")),
		"Redeemed":           crypto.Keccak256Hash([]byte("Redeemed(address,uint8,uint256,uint256)")),
		"Finalized":          crypto.Keccak256Hash([]byte("Finalized(uint256)")),
	}

	return &EventListener{
		client:     client,
		wsClient:   wsClient,
		repository: repo,
		logger:     logger,
		config:     cfg,
		eventSigs:  eventSigs,
	}, nil
}

// Start 启动监听器
func (l *EventListener) Start(ctx context.Context) error {
	l.logger.Info("starting event listener",
		zap.String("contract", l.config.ContractAddress.Hex()),
		zap.Uint64("start_block", l.config.StartBlock),
	)

	// 获取最后处理的区块
	lastBlock, err := l.repository.GetLastProcessedBlock(ctx)
	if err != nil {
		return fmt.Errorf("failed to get last processed block: %w", err)
	}

	startBlock := l.config.StartBlock
	if lastBlock > startBlock {
		startBlock = lastBlock + 1
	}

	// 先处理历史数据（从 startBlock 到 current - finality）
	if err := l.processHistoricalEvents(ctx, startBlock); err != nil {
		l.logger.Error("failed to process historical events", zap.Error(err))
		// 不返回错误，继续尝试订阅
	}

	// 尝试 WebSocket 订阅
	if l.wsClient != nil {
		l.logger.Info("attempting WebSocket subscription")
		if err := l.subscribeToEvents(ctx); err != nil {
			l.logger.Error("WebSocket subscription failed, falling back to polling", zap.Error(err))
			return l.pollEvents(ctx)
		}
		return nil
	}

	// 回退到轮询模式
	l.logger.Info("using polling mode")
	return l.pollEvents(ctx)
}

// processHistoricalEvents 处理历史事件
func (l *EventListener) processHistoricalEvents(ctx context.Context, fromBlock uint64) error {
	// 获取当前区块号
	currentBlock, err := l.client.BlockNumber(ctx)
	if err != nil {
		return fmt.Errorf("failed to get current block: %w", err)
	}

	// 只处理到 current - finality 的区块（避免重组）
	toBlock := currentBlock - l.config.FinalityBlocks
	if fromBlock >= toBlock {
		l.logger.Info("no historical blocks to process")
		return nil
	}

	l.logger.Info("processing historical events",
		zap.Uint64("from", fromBlock),
		zap.Uint64("to", toBlock),
	)

	// 分批处理
	for start := fromBlock; start <= toBlock; start += l.config.BatchSize {
		end := start + l.config.BatchSize - 1
		if end > toBlock {
			end = toBlock
		}

		if err := l.processBatch(ctx, start, end); err != nil {
			return fmt.Errorf("failed to process batch [%d, %d]: %w", start, end, err)
		}

		l.logger.Debug("batch processed",
			zap.Uint64("from", start),
			zap.Uint64("to", end),
		)

		// 更新检查点
		if err := l.repository.UpdateLastProcessedBlock(ctx, end); err != nil {
			return fmt.Errorf("failed to update checkpoint: %w", err)
		}
	}

	return nil
}

// processBatch 处理一批区块
func (l *EventListener) processBatch(ctx context.Context, fromBlock, toBlock uint64) error {
	query := ethereum.FilterQuery{
		FromBlock: big.NewInt(int64(fromBlock)),
		ToBlock:   big.NewInt(int64(toBlock)),
		Addresses: []common.Address{l.config.ContractAddress},
	}

	logs, err := l.client.FilterLogs(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to filter logs: %w", err)
	}

	if len(logs) == 0 {
		return nil
	}

	var events []interface{}
	for _, vLog := range logs {
		event, err := l.parseLog(ctx, vLog)
		if err != nil {
			l.logger.Warn("failed to parse log",
				zap.String("tx", vLog.TxHash.Hex()),
				zap.Uint("log_index", vLog.Index),
				zap.Error(err),
			)
			continue
		}
		if event != nil {
			events = append(events, event)
		}
	}

	if len(events) > 0 {
		if err := l.repository.BatchSaveEvents(ctx, events); err != nil {
			return fmt.Errorf("failed to save events: %w", err)
		}
		l.logger.Info("events saved", zap.Int("count", len(events)))
	}

	return nil
}

// parseLog 解析日志为事件
func (l *EventListener) parseLog(ctx context.Context, vLog types.Log) (interface{}, error) {
	if len(vLog.Topics) == 0 {
		return nil, nil
	}

	eventSig := vLog.Topics[0]

	// 获取区块时间
	block, err := l.client.BlockByNumber(ctx, big.NewInt(int64(vLog.BlockNumber)))
	if err != nil {
		return nil, fmt.Errorf("failed to get block: %w", err)
	}

	baseEvent := models.Event{
		TxHash:      vLog.TxHash.Hex(),
		LogIndex:    vLog.Index,
		BlockNumber: vLog.BlockNumber,
		BlockTime:   time.Unix(int64(block.Time()), 0),
	}

	switch eventSig {
	case l.eventSigs["BetPlaced"]:
		return l.parseBetPlaced(vLog, baseEvent)
	case l.eventSigs["Locked"]:
		return l.parseLocked(vLog, baseEvent)
	case l.eventSigs["Resolved"], l.eventSigs["ResolvedWithOracle"]:
		return l.parseResolved(vLog, baseEvent)
	case l.eventSigs["Redeemed"]:
		return l.parseRedeemed(vLog, baseEvent)
	case l.eventSigs["Finalized"]:
		return l.parseFinalized(vLog, baseEvent)
	default:
		// 未知事件，忽略
		return nil, nil
	}
}

// parseBetPlaced 解析 BetPlaced 事件
func (l *EventListener) parseBetPlaced(vLog types.Log, base models.Event) (*models.BetPlacedEvent, error) {
	if len(vLog.Topics) < 3 {
		return nil, fmt.Errorf("invalid BetPlaced log")
	}

	// event BetPlaced(address indexed user, uint8 indexed outcome, uint256 amount, uint256 shares, uint256 newPrice)
	user := common.BytesToAddress(vLog.Topics[1].Bytes())
	outcome := uint8(vLog.Topics[2].Big().Uint64())

	if len(vLog.Data) < 96 {
		return nil, fmt.Errorf("invalid BetPlaced data length")
	}

	amount := new(big.Int).SetBytes(vLog.Data[0:32])
	shares := new(big.Int).SetBytes(vLog.Data[32:64])
	newPrice := new(big.Int).SetBytes(vLog.Data[64:96])

	return &models.BetPlacedEvent{
		Event:         base,
		MarketAddress: vLog.Address,
		User:          user,
		Outcome:       outcome,
		Amount:        amount,
		Shares:        shares,
		NewPrice:      newPrice,
	}, nil
}

// parseLocked 解析 Locked 事件
func (l *EventListener) parseLocked(vLog types.Log, base models.Event) (*models.LockedEvent, error) {
	if len(vLog.Data) < 32 {
		return nil, fmt.Errorf("invalid Locked data length")
	}

	lockTime := new(big.Int).SetBytes(vLog.Data[0:32]).Uint64()

	return &models.LockedEvent{
		Event:         base,
		MarketAddress: vLog.Address,
		LockTime:      lockTime,
	}, nil
}

// parseResolved 解析 Resolved 事件
func (l *EventListener) parseResolved(vLog types.Log, base models.Event) (*models.ResolvedEvent, error) {
	if len(vLog.Topics) < 2 {
		return nil, fmt.Errorf("invalid Resolved log")
	}

	// event Resolved(uint256 indexed winningOutcome, uint256 timestamp)
	// 或 event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp)
	winningOutcome := uint8(vLog.Topics[1].Big().Uint64())

	var resultHash common.Hash
	var resolveTime uint64

	if len(vLog.Topics) >= 3 {
		// ResolvedWithOracle
		resultHash = vLog.Topics[2]
		if len(vLog.Data) >= 32 {
			resolveTime = new(big.Int).SetBytes(vLog.Data[0:32]).Uint64()
		}
	} else {
		// Resolved
		if len(vLog.Data) >= 32 {
			resolveTime = new(big.Int).SetBytes(vLog.Data[0:32]).Uint64()
		}
	}

	return &models.ResolvedEvent{
		Event:          base,
		MarketAddress:  vLog.Address,
		WinningOutcome: winningOutcome,
		ResolveTime:    resolveTime,
		ResultHash:     resultHash,
	}, nil
}

// parseRedeemed 解析 Redeemed 事件
func (l *EventListener) parseRedeemed(vLog types.Log, base models.Event) (*models.RedeemedEvent, error) {
	if len(vLog.Topics) < 3 {
		return nil, fmt.Errorf("invalid Redeemed log")
	}

	// event Redeemed(address indexed user, uint8 indexed outcome, uint256 shares, uint256 payout)
	user := common.BytesToAddress(vLog.Topics[1].Bytes())
	outcome := uint8(vLog.Topics[2].Big().Uint64())

	if len(vLog.Data) < 64 {
		return nil, fmt.Errorf("invalid Redeemed data length")
	}

	shares := new(big.Int).SetBytes(vLog.Data[0:32])
	payout := new(big.Int).SetBytes(vLog.Data[32:64])

	return &models.RedeemedEvent{
		Event:         base,
		MarketAddress: vLog.Address,
		User:          user,
		Outcome:       outcome,
		Shares:        shares,
		Payout:        payout,
	}, nil
}

// parseFinalized 解析 Finalized 事件
func (l *EventListener) parseFinalized(vLog types.Log, base models.Event) (*models.FinalizedEvent, error) {
	if len(vLog.Data) < 32 {
		return nil, fmt.Errorf("invalid Finalized data length")
	}

	finalizeTime := new(big.Int).SetBytes(vLog.Data[0:32]).Uint64()

	return &models.FinalizedEvent{
		Event:         base,
		MarketAddress: vLog.Address,
		FinalizeTime:  finalizeTime,
	}, nil
}

// subscribeToEvents 订阅实时事件（WebSocket）
func (l *EventListener) subscribeToEvents(ctx context.Context) error {
	query := ethereum.FilterQuery{
		Addresses: []common.Address{l.config.ContractAddress},
	}

	logs := make(chan types.Log)
	sub, err := l.wsClient.SubscribeFilterLogs(ctx, query, logs)
	if err != nil {
		return fmt.Errorf("failed to subscribe to logs: %w", err)
	}

	l.logger.Info("WebSocket subscription established")

	go func() {
		for {
			select {
			case err := <-sub.Err():
				l.logger.Error("subscription error", zap.Error(err))
				// 重连逻辑（TODO）
				return
			case vLog := <-logs:
				event, err := l.parseLog(ctx, vLog)
				if err != nil {
					l.logger.Warn("failed to parse log", zap.Error(err))
					continue
				}
				if event != nil {
					if err := l.repository.BatchSaveEvents(ctx, []interface{}{event}); err != nil {
						l.logger.Error("failed to save event", zap.Error(err))
					}
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	return nil
}

// pollEvents 轮询模式
func (l *EventListener) pollEvents(ctx context.Context) error {
	ticker := time.NewTicker(l.config.PollingInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			lastBlock, err := l.repository.GetLastProcessedBlock(ctx)
			if err != nil {
				l.logger.Error("failed to get last processed block", zap.Error(err))
				continue
			}

			currentBlock, err := l.client.BlockNumber(ctx)
			if err != nil {
				l.logger.Error("failed to get current block", zap.Error(err))
				continue
			}

			// 保留 finality 区块
			toBlock := currentBlock - l.config.FinalityBlocks
			if lastBlock >= toBlock {
				continue
			}

			if err := l.processBatch(ctx, lastBlock+1, toBlock); err != nil {
				l.logger.Error("failed to process batch", zap.Error(err))
				continue
			}

			if err := l.repository.UpdateLastProcessedBlock(ctx, toBlock); err != nil {
				l.logger.Error("failed to update checkpoint", zap.Error(err))
			}
		}
	}
}

// Close 关闭监听器
func (l *EventListener) Close() {
	if l.client != nil {
		l.client.Close()
	}
	if l.wsClient != nil {
		l.wsClient.Close()
	}
}
