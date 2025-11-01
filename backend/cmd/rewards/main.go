package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/pitchone/sportsbook/internal/rewards"
	_ "github.com/lib/pq"
)

// Config 配置
type Config struct {
	DatabaseURL     string
	RPCURL          string
	DistributorAddr string
	PrivateKey      string
	Week            uint64
	DryRun          bool
	OutputFile      string
}

func main() {
	// 解析命令行参数
	config := parseFlags()

	// 连接数据库
	db, err := sql.Open("postgres", config.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	log.Printf("Connected to database successfully")

	// 创建聚合器
	aggregator := rewards.NewAggregator(db)

	// 确定要处理的周
	week := config.Week
	if week == 0 {
		week = rewards.GetCurrentWeek() - 1 // 默认处理上一周
		log.Printf("Auto-detected previous week: %d", week)
	}

	log.Printf("Building rewards distribution for week %d", week)

	// 聚合奖励数据
	ctx := context.Background()
	entries, err := aggregator.AggregateWeeklyRewards(ctx, week)
	if err != nil {
		log.Fatalf("Failed to aggregate rewards: %v", err)
	}

	log.Printf("Aggregated %d reward entries", len(entries))

	if len(entries) == 0 {
		log.Printf("No rewards to distribute for week %d", week)
		return
	}

	// 计算缩放比例（这里简化，默认100%）
	scaleBps := uint64(10000)
	// TODO: 从合约查询可用预算并计算实际缩放比例

	// 构建 Merkle 分配
	distribution, err := rewards.BuildDistribution(week, entries, scaleBps)
	if err != nil {
		log.Fatalf("Failed to build distribution: %v", err)
	}

	distribution.CreatedAt = time.Now().Unix()

	log.Printf("Merkle Root: %s", distribution.Root)
	log.Printf("Total Recipients: %d", distribution.Recipients)
	log.Printf("Scale: %d bps (%.2f%%)", distribution.ScaleBps, float64(distribution.ScaleBps)/100)
	log.Printf("Checksum: %s", distribution.Checksum())

	// 保存分配数据到数据库
	if err := aggregator.SaveDistribution(ctx, distribution); err != nil {
		log.Fatalf("Failed to save distribution: %v", err)
	}

	log.Printf("Distribution saved to database")

	// 导出到文件
	if config.OutputFile != "" {
		if err := exportDistribution(distribution, config.OutputFile); err != nil {
			log.Fatalf("Failed to export distribution: %v", err)
		}
		log.Printf("Distribution exported to %s", config.OutputFile)
	}

	// Dry run 模式，不发布到链上
	if config.DryRun {
		log.Printf("Dry run mode - skipping on-chain publication")
		log.Printf("✅ Dry run completed successfully")
		return
	}

	// 发布到链上
	if config.RPCURL == "" || config.DistributorAddr == "" || config.PrivateKey == "" {
		log.Printf("Missing RPC/Distributor/PrivateKey config - skipping on-chain publication")
		log.Printf("Use --rpc-url, --distributor, --private-key to enable on-chain publication")
		return
	}

	log.Printf("Publishing to chain...")

	publisher, err := rewards.NewPublisher(config.RPCURL, common.HexToAddress(config.DistributorAddr), config.PrivateKey)
	if err != nil {
		log.Fatalf("Failed to create publisher: %v", err)
	}
	defer publisher.Close()

	tx, err := publisher.PublishRoot(ctx, distribution)
	if err != nil {
		log.Fatalf("Failed to publish root: %v", err)
	}

	log.Printf("Transaction sent: %s", tx.Hash().Hex())

	// 等待确认
	log.Printf("Waiting for confirmation...")
	receipt, err := publisher.WaitForConfirmation(ctx, tx, 3) // 等待3个确认
	if err != nil {
		log.Fatalf("Transaction failed: %v", err)
	}

	log.Printf("✅ Transaction confirmed in block %d", receipt.BlockNumber.Uint64())
	log.Printf("Gas used: %d", receipt.GasUsed)

	// 验证链上数据
	publishedRoot, err := publisher.GetPublishedRoot(ctx, week)
	if err != nil {
		log.Printf("Warning: Failed to verify published root: %v", err)
	} else if publishedRoot.Hex() != distribution.Root {
		log.Fatalf("❌ Root mismatch! Expected %s, got %s", distribution.Root, publishedRoot.Hex())
	} else {
		log.Printf("✅ Root verified on-chain: %s", publishedRoot.Hex())
	}

	log.Printf("🎉 Rewards distribution for week %d completed successfully!", week)
}

func parseFlags() *Config {
	config := &Config{}

	flag.StringVar(&config.DatabaseURL, "db", os.Getenv("DATABASE_URL"), "Database URL (env: DATABASE_URL)")
	flag.StringVar(&config.RPCURL, "rpc-url", os.Getenv("RPC_URL"), "Ethereum RPC URL (env: RPC_URL)")
	flag.StringVar(&config.DistributorAddr, "distributor", os.Getenv("REWARDS_DISTRIBUTOR_ADDR"), "RewardsDistributor contract address")
	flag.StringVar(&config.PrivateKey, "private-key", os.Getenv("PRIVATE_KEY"), "Private key for signing transactions")
	flag.Uint64Var(&config.Week, "week", 0, "Week number (default: current week - 1)")
	flag.BoolVar(&config.DryRun, "dry-run", false, "Dry run mode (don't publish to chain)")
	flag.StringVar(&config.OutputFile, "output", "", "Output file for distribution JSON")

	flag.Parse()

	if config.DatabaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	return config
}

func exportDistribution(dist *rewards.MerkleDistribution, filename string) error {
	data, err := json.MarshalIndent(dist, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal distribution: %w", err)
	}

	return os.WriteFile(filename, data, 0644)
}
