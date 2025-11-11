package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/pitchone/sportsbook/internal/rewards"
	"github.com/robfig/cron/v3"
	_ "github.com/lib/pq"
)

// Config 调度器配置
type Config struct {
	DatabaseURL     string
	RPCURL          string
	DistributorAddr string
	PrivateKey      string
	TestMode        bool  // 测试模式：立即执行一次
	CronSchedule    string // Cron 表达式
}

// Scheduler 定时任务调度器
type Scheduler struct {
	config     *Config
	db         *sql.DB
	aggregator *rewards.Aggregator
	publisher  *rewards.Publisher
	cron       *cron.Cron
}

func main() {
	// 解析配置
	config := parseFlags()

	// 创建调度器
	scheduler, err := NewScheduler(config)
	if err != nil {
		log.Fatalf("Failed to create scheduler: %v", err)
	}
	defer scheduler.Close()

	// 测试模式：立即执行一次
	if config.TestMode {
		log.Println("🧪 Test mode: running weekly rewards task once")
		if err := scheduler.runWeeklyRewards(); err != nil {
			log.Fatalf("Test run failed: %v", err)
		}
		log.Println("✅ Test run completed successfully")
		return
	}

	// 启动定时任务
	scheduler.Start()

	log.Printf("🚀 Scheduler started (cron: %s)", config.CronSchedule)
	log.Println("Press Ctrl+C to stop")

	// 优雅退出
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down scheduler...")
	scheduler.Stop()
	log.Println("✅ Scheduler stopped")
}

// NewScheduler 创建调度器
func NewScheduler(config *Config) (*Scheduler, error) {
	// 连接数据库
	db, err := sql.Open("postgres", config.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("✅ Connected to database")

	// 创建聚合器
	aggregator := rewards.NewAggregator(db)

	// 创建发布器（如果配置了 RPC）
	var publisher *rewards.Publisher
	if config.RPCURL != "" && config.DistributorAddr != "" && config.PrivateKey != "" {
		publisher, err = rewards.NewPublisher(
			config.RPCURL,
			common.HexToAddress(config.DistributorAddr),
			config.PrivateKey,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to create publisher: %w", err)
		}
		log.Println("✅ Connected to blockchain")
	} else {
		log.Println("⚠️  No RPC config - rewards will be aggregated but not published to chain")
	}

	// 创建 Cron 调度器
	c := cron.New(cron.WithSeconds()) // 支持秒级精度（用于测试）

	return &Scheduler{
		config:     config,
		db:         db,
		aggregator: aggregator,
		publisher:  publisher,
		cron:       c,
	}, nil
}

// Start 启动定时任务
func (s *Scheduler) Start() {
	// 添加周度奖励任务
	// 默认：每周日 23:59:00 执行
	_, err := s.cron.AddFunc(s.config.CronSchedule, s.runWeeklyRewardsWithRecover)
	if err != nil {
		log.Fatalf("Failed to add cron job: %v", err)
	}

	// 添加健康检查任务（每天 00:05:00 检查失败的任务）
	_, err = s.cron.AddFunc("0 5 0 * * *", s.checkFailedTasks)
	if err != nil {
		log.Printf("Failed to add health check job: %v", err)
	}

	s.cron.Start()
}

// Stop 停止定时任务
func (s *Scheduler) Stop() {
	s.cron.Stop()
}

// Close 关闭连接
func (s *Scheduler) Close() {
	if s.db != nil {
		s.db.Close()
	}
	if s.publisher != nil {
		s.publisher.Close()
	}
}

// runWeeklyRewardsWithRecover 执行周度奖励任务（带恢复）
func (s *Scheduler) runWeeklyRewardsWithRecover() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("❌ Panic recovered: %v", r)
			// TODO: 发送告警通知
		}
	}()

	if err := s.runWeeklyRewards(); err != nil {
		log.Printf("❌ Weekly rewards task failed: %v", err)
		// TODO: 发送告警通知
	}
}

// runWeeklyRewards 执行周度奖励任务
func (s *Scheduler) runWeeklyRewards() error {
	ctx := context.Background()

	// 确定要处理的周
	week := rewards.GetCurrentWeek() - 1 // 处理上一周
	log.Printf("🕒 Starting weekly rewards task for week %d", week)

	// 1. 检查是否已发布
	existing, _ := s.aggregator.GetDistribution(ctx, week)
	if existing != nil {
		log.Printf("⚠️  Week %d already processed (root: %s), skipping", week, existing.Root)
		return nil
	}

	// 2. 聚合奖励数据
	log.Printf("📊 Aggregating rewards for week %d...", week)
	startTime := time.Now()

	entries, err := s.aggregator.AggregateWeeklyRewards(ctx, week)
	if err != nil {
		return fmt.Errorf("failed to aggregate rewards: %w", err)
	}

	log.Printf("✅ Aggregated %d reward entries in %v", len(entries), time.Since(startTime))

	if len(entries) == 0 {
		log.Printf("⚠️  No rewards to distribute for week %d", week)
		return nil
	}

	// 3. 生成 Merkle 分配
	log.Printf("🌳 Building Merkle tree...")
	scaleBps := uint64(10000) // TODO: 从合约查询可用预算并计算缩放比例
	distribution, err := rewards.BuildDistribution(week, entries, scaleBps)
	if err != nil {
		return fmt.Errorf("failed to build distribution: %w", err)
	}

	distribution.CreatedAt = time.Now().Unix()

	log.Printf("✅ Merkle Root: %s", distribution.Root)
	log.Printf("   Recipients: %d", distribution.Recipients)
	log.Printf("   Total Amount: %s", distribution.TotalAmount)
	log.Printf("   Scale: %d bps (%.2f%%)", distribution.ScaleBps, float64(distribution.ScaleBps)/100)

	// 4. 保存到数据库
	if err := s.aggregator.SaveDistribution(ctx, distribution); err != nil {
		return fmt.Errorf("failed to save distribution: %w", err)
	}

	log.Printf("✅ Distribution saved to database")

	// 5. 发布到链上（如果配置了 Publisher）
	if s.publisher != nil {
		log.Printf("📤 Publishing to blockchain...")

		tx, err := s.publisher.PublishRoot(ctx, distribution)
		if err != nil {
			return fmt.Errorf("failed to publish root: %w", err)
		}

		log.Printf("✅ Transaction sent: %s", tx.Hash().Hex())

		// 等待确认
		log.Printf("⏳ Waiting for confirmation...")
		receipt, err := s.publisher.WaitForConfirmation(ctx, tx, 3)
		if err != nil {
			return fmt.Errorf("transaction failed: %w", err)
		}

		log.Printf("✅ Transaction confirmed in block %d", receipt.BlockNumber.Uint64())
		log.Printf("   Gas used: %d", receipt.GasUsed)

		// 验证链上数据
		publishedRoot, err := s.publisher.GetPublishedRoot(ctx, week)
		if err != nil {
			log.Printf("⚠️  Failed to verify published root: %v", err)
		} else if publishedRoot.Hex() != distribution.Root {
			return fmt.Errorf("root mismatch! Expected %s, got %s", distribution.Root, publishedRoot.Hex())
		} else {
			log.Printf("✅ Root verified on-chain")
		}
	} else {
		log.Printf("⚠️  Skipping on-chain publication (no RPC config)")
	}

	log.Printf("🎉 Weekly rewards for week %d completed successfully!", week)
	// TODO: 发送成功通知（Slack/Discord）

	return nil
}

// checkFailedTasks 检查失败的任务
func (s *Scheduler) checkFailedTasks() {
	log.Println("🔍 Checking for failed tasks...")

	ctx := context.Background()
	currentWeek := rewards.GetCurrentWeek()

	// 检查最近 4 周是否有未发布的周
	for i := uint64(1); i <= 4; i++ {
		week := currentWeek - i
		dist, err := s.aggregator.GetDistribution(ctx, week)
		if err != nil || dist == nil {
			log.Printf("⚠️  Week %d appears to be missing - consider manual intervention", week)
			// TODO: 发送告警通知
		}
	}
}

func parseFlags() *Config {
	config := &Config{}

	flag.StringVar(&config.DatabaseURL, "db", os.Getenv("DATABASE_URL"), "Database URL (env: DATABASE_URL)")
	flag.StringVar(&config.RPCURL, "rpc-url", os.Getenv("RPC_URL"), "Ethereum RPC URL (env: RPC_URL)")
	flag.StringVar(&config.DistributorAddr, "distributor", os.Getenv("REWARDS_DISTRIBUTOR_ADDR"), "RewardsDistributor contract address")
	flag.StringVar(&config.PrivateKey, "private-key", os.Getenv("PRIVATE_KEY"), "Private key for signing transactions")
	flag.BoolVar(&config.TestMode, "test", false, "Test mode: run once and exit")
	flag.StringVar(&config.CronSchedule, "cron", "0 59 23 * * 0", "Cron schedule (default: every Sunday 23:59:00)")

	flag.Parse()

	if config.DatabaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	return config
}
