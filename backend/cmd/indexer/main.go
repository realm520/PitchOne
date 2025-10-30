package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/spf13/viper"
	"go.uber.org/zap"

	"github.com/pitchone/sportsbook/internal/indexer"
	"github.com/pitchone/sportsbook/pkg/db"
)

func main() {
	// 初始化日志
	logger, err := initLogger()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync()

	// 加载配置
	if err := loadConfig(); err != nil {
		logger.Fatal("failed to load config", zap.Error(err))
	}

	// 初始化数据库
	dbClient, err := initDatabase(logger)
	if err != nil {
		logger.Fatal("failed to initialize database", zap.Error(err))
	}
	defer dbClient.Close()

	// 创建数据仓库
	repo := db.NewRepository(dbClient, logger)

	// 创建事件监听器
	listener, err := initListener(repo, logger)
	if err != nil {
		logger.Fatal("failed to initialize listener", zap.Error(err))
	}
	defer listener.Close()

	// 启动监听器
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 捕获信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 在单独的 goroutine 中启动监听器
	errChan := make(chan error, 1)
	go func() {
		if err := listener.Start(ctx); err != nil {
			errChan <- err
		}
	}()

	logger.Info("indexer started successfully")

	// 等待信号或错误
	select {
	case <-sigChan:
		logger.Info("received shutdown signal")
		cancel()
	case err := <-errChan:
		logger.Error("indexer error", zap.Error(err))
		cancel()
	}

	// 优雅关闭
	logger.Info("shutting down...")
	time.Sleep(2 * time.Second)
	logger.Info("shutdown complete")
}

// initLogger 初始化日志器
func initLogger() (*zap.Logger, error) {
	env := viper.GetString("environment")
	level := viper.GetString("logging.level")
	format := viper.GetString("logging.format")

	var config zap.Config
	if env == "production" {
		config = zap.NewProductionConfig()
	} else {
		config = zap.NewDevelopmentConfig()
	}

	// 设置日志级别
	switch level {
	case "debug":
		config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
	case "info":
		config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
	case "warn":
		config.Level = zap.NewAtomicLevelAt(zap.WarnLevel)
	case "error":
		config.Level = zap.NewAtomicLevelAt(zap.ErrorLevel)
	}

	// 设置输出格式
	if format == "json" {
		config.Encoding = "json"
	} else {
		config.Encoding = "console"
	}

	return config.Build()
}

// loadConfig 加载配置文件
func loadConfig() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("../")
	viper.AddConfigPath("../../")

	// 环境变量绑定
	viper.AutomaticEnv()
	viper.SetEnvPrefix("SPORTSBOOK")

	if err := viper.ReadInConfig(); err != nil {
		return fmt.Errorf("failed to read config: %w", err)
	}

	return nil
}

// initDatabase 初始化数据库
func initDatabase(logger *zap.Logger) (*db.Client, error) {
	cfg := db.Config{
		Host:            viper.GetString("database.host"),
		Port:            viper.GetInt("database.port"),
		User:            viper.GetString("database.user"),
		Password:        viper.GetString("database.password"),
		DBName:          viper.GetString("database.dbname"),
		SSLMode:         viper.GetString("database.sslmode"),
		MaxOpenConns:    viper.GetInt("database.max_open_conns"),
		MaxIdleConns:    viper.GetInt("database.max_idle_conns"),
		ConnMaxLifetime: viper.GetDuration("database.conn_max_lifetime"),
		QueryTimeout:    viper.GetDuration("database.query_timeout"),
	}

	client, err := db.NewClient(cfg, logger)
	if err != nil {
		return nil, err
	}

	// 健康检查
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Health(ctx); err != nil {
		client.Close()
		return nil, fmt.Errorf("database health check failed: %w", err)
	}

	logger.Info("database initialized successfully")
	return client, nil
}

// initListener 初始化事件监听器
func initListener(repo *db.Repository, logger *zap.Logger) (*indexer.EventListener, error) {
	cfg := &indexer.Config{
		RPCURL:          viper.GetString("indexer.rpc_url"),
		WSURL:           viper.GetString("indexer.ws_url"),
		ContractAddress: common.HexToAddress(viper.GetString("indexer.contracts.market_base")),
		StartBlock:      viper.GetUint64("indexer.start_block"),
		BatchSize:       viper.GetUint64("indexer.batch_size"),
		FinalityBlocks:  viper.GetUint64("indexer.finality_blocks"),
		PollingInterval: viper.GetDuration("indexer.polling_interval"),
	}

	listener, err := indexer.NewEventListener(cfg, repo, logger)
	if err != nil {
		return nil, err
	}

	logger.Info("event listener initialized",
		zap.String("contract", cfg.ContractAddress.Hex()),
		zap.Uint64("start_block", cfg.StartBlock),
	)

	return listener, nil
}
