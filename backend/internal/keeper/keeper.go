package keeper

import (
	"context"
	"fmt"
	"math/big"
	"os"
	"sync"
	"time"

	"github.com/pitchone/sportsbook/internal/datasource"
	"github.com/pitchone/sportsbook/internal/graphql"
	"go.uber.org/zap"
)

const version = "0.1.0"

// Keeper manages automated tasks for the sportsbook
type Keeper struct {
	config       *Config
	web3Client   *Web3Client
	graphClient  *graphql.Client // 使用 Subgraph 替代数据库
	logger       *zap.Logger
	chainID      int64
	maxGasPrice  *big.Int
	dataSource   datasource.ResultProvider
	alertManager *AlertManager

	// Internal state
	running      bool
	runningMutex sync.RWMutex
	stopChan     chan struct{}
	doneChan     chan struct{}
	wg           sync.WaitGroup
}

// HealthStatus represents the health status of the Keeper
type HealthStatus struct {
	Healthy  bool   `json:"healthy"`
	Version  string `json:"version"`
	Subgraph string `json:"subgraph"` // 替代 Database
	Web3     string `json:"web3"`
	Uptime   string `json:"uptime"`
}

// NewKeeper creates a new Keeper instance
func NewKeeper(cfg *Config) (*Keeper, error) {
	// Validate configuration
	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize logger: %w", err)
	}

	logger.Info("initializing Keeper service", zap.String("version", version))

	// Parse max gas price (convert Gwei to Wei)
	maxGasPriceGwei, ok := new(big.Int).SetString(cfg.MaxGasPrice, 10)
	if !ok {
		return nil, fmt.Errorf("invalid max gas price: %s", cfg.MaxGasPrice)
	}
	maxGasPrice := new(big.Int).Mul(maxGasPriceGwei, big.NewInt(1e9)) // Convert Gwei to Wei

	// Initialize Web3 client
	web3Client, err := NewWeb3Client(
		cfg.RPCEndpoint,
		cfg.PrivateKey,
		big.NewInt(cfg.ChainID),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Web3 client: %w", err)
	}

	// Verify RPC connection is working
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := web3Client.GetBlockNumber(ctx); err != nil {
		return nil, fmt.Errorf("failed to verify RPC connection: %w", err)
	}

	logger.Info("Web3 client initialized",
		zap.String("account", web3Client.GetAccount().Hex()),
		zap.Int64("chainID", cfg.ChainID),
	)

	// Initialize GraphQL client (替代数据库连接)
	graphClient := graphql.NewClient(cfg.SubgraphEndpoint)

	// Test Subgraph connection
	ctx2, cancel2 := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel2()
	if err := graphClient.HealthCheck(ctx2); err != nil {
		return nil, fmt.Errorf("failed to connect to Subgraph: %w", err)
	}

	logger.Info("Subgraph client initialized",
		zap.String("endpoint", cfg.SubgraphEndpoint),
	)

	// 如果设置了旧的 DatabaseURL，打印警告
	if cfg.DatabaseURL != "" {
		logger.Warn("DatabaseURL is deprecated, using SubgraphEndpoint instead",
			zap.String("deprecated_url", maskDatabaseURL(cfg.DatabaseURL)),
		)
	}

	// Initialize data source (Sportradar or Mock)
	var dataSource datasource.ResultProvider
	sportsAPIKey := os.Getenv("SPORTRADAR_API_KEY")
	if sportsAPIKey != "" {
		// Use Sportradar for production
		logger.Info("initializing Sportradar data source")
		dataSource = datasource.NewSportradarClient(datasource.SportradarConfig{
			APIKey:        sportsAPIKey,
			BaseURL:       os.Getenv("SPORTRADAR_BASE_URL"), // Optional, uses default if empty
			Timeout:       10 * time.Second,
			RequestsPerSec: 1.0, // Free tier rate limit
		}, logger)
	} else {
		// Use Mock for development/testing
		logger.Warn("SPORTRADAR_API_KEY not set, using mock data source")
		dataSource = datasource.NewMockResultProvider()
	}

	// Initialize alert manager with notifiers from environment
	alertManager := NewAlertManagerFromEnv(logger)

	keeper := &Keeper{
		config:       cfg,
		web3Client:   web3Client,
		graphClient:  graphClient, // 使用 Subgraph 替代数据库
		logger:       logger,
		chainID:      cfg.ChainID,
		maxGasPrice:  maxGasPrice,
		dataSource:   dataSource,
		alertManager: alertManager,
		stopChan:     make(chan struct{}),
		doneChan:     make(chan struct{}),
	}

	return keeper, nil
}

// Start starts the Keeper service
func (k *Keeper) Start(ctx context.Context) error {
	k.runningMutex.Lock()
	if k.running {
		k.runningMutex.Unlock()
		return fmt.Errorf("keeper is already running")
	}
	k.running = true
	k.runningMutex.Unlock()

	k.logger.Info("starting Keeper service")

	// Start health check server (async)
	k.wg.Add(1)
	go k.runHealthCheckServer(ctx)

	// Start metrics server if enabled (async)
	if k.config.MetricsPort > 0 {
		k.wg.Add(1)
		go k.runMetricsServer(ctx)
	}

	// Start task scheduler
	k.wg.Add(1)
	go k.runTaskScheduler(ctx)

	// Wait for shutdown signal
	select {
	case <-ctx.Done():
		k.logger.Info("received shutdown signal")
	case <-k.stopChan:
		k.logger.Info("received stop signal")
	}

	// Wait for all goroutines to finish
	k.wg.Wait()

	// Reset running flag
	k.runningMutex.Lock()
	k.running = false
	k.runningMutex.Unlock()

	close(k.doneChan)
	k.logger.Info("Keeper service stopped")

	return nil
}

// Shutdown gracefully shuts down the Keeper service
func (k *Keeper) Shutdown(ctx context.Context) error {
	k.logger.Info("shutting down Keeper service")

	// Check if keeper is running
	k.runningMutex.RLock()
	isRunning := k.running
	k.runningMutex.RUnlock()

	if !isRunning {
		k.logger.Info("keeper not running, nothing to shutdown")
		return nil
	}

	// Signal all goroutines to stop (use select to avoid panic if already closed)
	select {
	case <-k.stopChan:
		// Already closed
	default:
		close(k.stopChan)
	}

	// Wait for shutdown with timeout
	select {
	case <-k.doneChan:
		k.logger.Info("graceful shutdown completed")
	case <-ctx.Done():
		k.logger.Warn("shutdown timeout reached, forcing shutdown")
		return fmt.Errorf("shutdown timeout")
	}

	// Close connections
	if k.alertManager != nil {
		if err := k.alertManager.Close(); err != nil {
			k.logger.Error("failed to close alert manager", zap.Error(err))
		}
	}

	if k.web3Client != nil {
		k.web3Client.Close()
	}

	// GraphQL 客户端不需要显式关闭（使用 HTTP 连接池）

	if k.logger != nil {
		k.logger.Sync()
	}

	return nil
}

// HealthCheck returns the current health status
func (k *Keeper) HealthCheck() *HealthStatus {
	status := &HealthStatus{
		Healthy: true,
		Version: version,
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check Subgraph connection (替代数据库检查)
	if err := k.graphClient.HealthCheck(ctx); err != nil {
		status.Subgraph = "error: " + err.Error()
		status.Healthy = false
	} else {
		status.Subgraph = "ok"
	}

	// Check Web3 connection
	if _, err := k.web3Client.GetBlockNumber(ctx); err != nil {
		status.Web3 = "error: " + err.Error()
		status.Healthy = false
	} else {
		status.Web3 = "ok"
	}

	return status
}

// runHealthCheckServer runs the health check HTTP server
func (k *Keeper) runHealthCheckServer(ctx context.Context) {
	defer k.wg.Done()

	k.logger.Info("health check server started",
		zap.Int("port", k.config.HealthCheckPort),
	)

	// TODO: Implement actual HTTP server
	// For now, just simulate running
	select {
	case <-ctx.Done():
		k.logger.Info("health check server stopping (context done)")
	case <-k.stopChan:
		k.logger.Info("health check server stopping (stop signal)")
	}
	k.logger.Info("health check server stopped")
}

// runMetricsServer runs the Prometheus metrics HTTP server
func (k *Keeper) runMetricsServer(ctx context.Context) {
	defer k.wg.Done()

	k.logger.Info("metrics server started",
		zap.Int("port", k.config.MetricsPort),
	)

	// TODO: Implement actual HTTP server with Prometheus metrics
	// For now, just simulate running
	select {
	case <-ctx.Done():
		k.logger.Info("metrics server stopping (context done)")
	case <-k.stopChan:
		k.logger.Info("metrics server stopping (stop signal)")
	}
	k.logger.Info("metrics server stopped")
}

// runTaskScheduler runs the main task scheduling loop
func (k *Keeper) runTaskScheduler(ctx context.Context) {
	defer k.wg.Done()

	k.logger.Info("task scheduler started",
		zap.Int("interval", k.config.TaskInterval),
	)

	// Create scheduler
	scheduler := NewScheduler(k)

	// Register LockTask
	lockTask := NewLockTask(k)
	scheduler.RegisterTask("lock", lockTask, time.Duration(k.config.TaskInterval)*time.Second)

	// Register SettleTask
	settleTask := NewSettleTask(k, k.dataSource)
	scheduler.RegisterTask("settle", settleTask, time.Duration(k.config.TaskInterval)*time.Second)

	// Start scheduler
	if err := scheduler.Start(ctx); err != nil {
		k.logger.Error("scheduler failed to start", zap.Error(err))
		return
	}

	// Wait for cancellation
	<-ctx.Done()
	k.logger.Info("task scheduler stopping")

	// Stop scheduler gracefully
	scheduler.Stop()
}
