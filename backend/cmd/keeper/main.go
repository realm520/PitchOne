package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/spf13/viper"
	"go.uber.org/zap"

	"github.com/pitchone/sportsbook/internal/datasource"
	"github.com/pitchone/sportsbook/internal/keeper"
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

	// 创建 Keeper 配置
	cfg, err := buildKeeperConfig()
	if err != nil {
		logger.Fatal("failed to build keeper config", zap.Error(err))
	}

	// 创建 Keeper 实例
	k, err := keeper.NewKeeper(cfg)
	if err != nil {
		logger.Fatal("failed to create keeper", zap.Error(err))
	}
	defer k.Shutdown(context.Background())

	// 创建 ResultProvider (Sportradar API)
	sportradarConfig := datasource.SportradarConfig{
		APIKey:         viper.GetString("sportradar.api_key"),
		BaseURL:        viper.GetString("sportradar.base_url"),
		Timeout:        time.Duration(viper.GetInt("sportradar.timeout")) * time.Second,
		RequestsPerSec: viper.GetFloat64("sportradar.requests_per_sec"),
	}
	resultProvider := datasource.NewSportradarClient(sportradarConfig, logger)

	// 创建调度器
	scheduler := keeper.NewScheduler(k)

	// 注册任务
	taskInterval := time.Duration(cfg.TaskInterval) * time.Second

	// 注册锁盘任务
	lockTask := keeper.NewLockTask(k)
	scheduler.RegisterTask("lock", lockTask, taskInterval)

	// 注册结算任务
	settleTask := keeper.NewSettleTask(k, resultProvider)
	scheduler.RegisterTask("settle", settleTask, taskInterval)

	logger.Info("keeper initialized successfully",
		zap.Int64("chain_id", cfg.ChainID),
		zap.Duration("task_interval", taskInterval),
	)

	// 创建上下文和信号处理
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 捕获信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 在单独的 goroutine 中启动调度器
	errChan := make(chan error, 1)
	go func() {
		if err := scheduler.Start(ctx); err != nil {
			errChan <- err
		}
	}()

	logger.Info("keeper started successfully")

	// 等待信号或错误
	select {
	case <-sigChan:
		logger.Info("received shutdown signal")
		cancel()
	case err := <-errChan:
		logger.Error("keeper error", zap.Error(err))
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
	default:
		config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
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
	viper.AddConfigPath("../../..")

	// 环境变量绑定
	viper.AutomaticEnv()
	viper.SetEnvPrefix("SPORTSBOOK")

	// 设置环境变量键名替换规则（将 . 替换为 _）
	replacer := strings.NewReplacer(".", "_")
	viper.SetEnvKeyReplacer(replacer)

	// 显式绑定必需的环境变量（解决嵌套配置问题）
	// keeper.* 配置项
	viper.BindEnv("keeper.chain_id")
	viper.BindEnv("keeper.rpc_endpoint")
	viper.BindEnv("keeper.private_key")
	viper.BindEnv("keeper.gas_limit")
	viper.BindEnv("keeper.max_gas_price")
	viper.BindEnv("keeper.task_interval")
	viper.BindEnv("keeper.lock_lead_time")
	viper.BindEnv("keeper.finalize_delay")
	viper.BindEnv("keeper.max_concurrent")
	viper.BindEnv("keeper.retry_attempts")
	viper.BindEnv("keeper.retry_delay")
	viper.BindEnv("keeper.database_url")
	viper.BindEnv("keeper.health_check_port")
	viper.BindEnv("keeper.metrics_port")
	viper.BindEnv("keeper.alerts_enabled")

	// sportradar.* 配置项
	viper.BindEnv("sportradar.api_key")
	viper.BindEnv("sportradar.base_url")
	viper.BindEnv("sportradar.timeout")
	viper.BindEnv("sportradar.requests_per_sec")

	// logging.* 配置项
	viper.BindEnv("logging.level")
	viper.BindEnv("logging.format")

	// 其他配置项
	viper.BindEnv("environment")

	if err := viper.ReadInConfig(); err != nil {
		// 配置文件不存在不是致命错误，可以完全依赖环境变量
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return fmt.Errorf("failed to read config: %w", err)
		}
	}

	return nil
}

// buildKeeperConfig 构建 Keeper 配置
func buildKeeperConfig() (*keeper.Config, error) {
	cfg := &keeper.Config{
		ChainID:         int64(viper.GetInt("keeper.chain_id")),
		RPCEndpoint:     viper.GetString("keeper.rpc_endpoint"),
		PrivateKey:      viper.GetString("keeper.private_key"),
		GasLimit:        viper.GetUint64("keeper.gas_limit"),
		MaxGasPrice:     viper.GetString("keeper.max_gas_price"),
		TaskInterval:    viper.GetInt("keeper.task_interval"),
		LockLeadTime:    viper.GetInt("keeper.lock_lead_time"),
		FinalizeDelay:   viper.GetInt("keeper.finalize_delay"),
		MaxConcurrent:   viper.GetInt("keeper.max_concurrent"),
		RetryAttempts:   viper.GetInt("keeper.retry_attempts"),
		RetryDelay:      viper.GetInt("keeper.retry_delay"),
		DatabaseURL:     viper.GetString("keeper.database_url"),
		HealthCheckPort: viper.GetInt("keeper.health_check_port"),
		MetricsPort:     viper.GetInt("keeper.metrics_port"),
		AlertsEnabled:   viper.GetBool("keeper.alerts_enabled"),
	}

	// 验证必需配置
	if cfg.ChainID == 0 {
		return nil, fmt.Errorf("chain_id is required")
	}
	if cfg.RPCEndpoint == "" {
		return nil, fmt.Errorf("rpc_endpoint is required")
	}
	if cfg.PrivateKey == "" {
		return nil, fmt.Errorf("private_key is required")
	}
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("database_url is required")
	}

	// 设置默认值
	if cfg.GasLimit == 0 {
		cfg.GasLimit = 500000
	}
	if cfg.MaxGasPrice == "" {
		cfg.MaxGasPrice = "100" // 100 Gwei
	}
	if cfg.TaskInterval == 0 {
		cfg.TaskInterval = 60 // 60 seconds
	}
	if cfg.LockLeadTime == 0 {
		cfg.LockLeadTime = 300 // 5 minutes
	}
	if cfg.FinalizeDelay == 0 {
		cfg.FinalizeDelay = 7200 // 2 hours
	}
	if cfg.MaxConcurrent == 0 {
		cfg.MaxConcurrent = 10
	}
	if cfg.RetryAttempts == 0 {
		cfg.RetryAttempts = 3
	}
	if cfg.RetryDelay == 0 {
		cfg.RetryDelay = 5 // 5 seconds
	}
	if cfg.HealthCheckPort == 0 {
		cfg.HealthCheckPort = 8080
	}
	if cfg.MetricsPort == 0 {
		cfg.MetricsPort = 9090
	}

	return cfg, nil
}
