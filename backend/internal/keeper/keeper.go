package keeper

import (
	"context"
	"database/sql"
	"fmt"
	"math/big"
	"os"
	"sync"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
	"github.com/pitchone/sportsbook/internal/datasource"
	"go.uber.org/zap"
)

const version = "0.1.0"

// Keeper manages automated tasks for the sportsbook
type Keeper struct {
	config       *Config
	web3Client   *Web3Client
	db           *sql.DB
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
	Database string `json:"database"`
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

	logger.Info("Web3 client initialized",
		zap.String("account", web3Client.GetAccount().Hex()),
		zap.Int64("chainID", cfg.ChainID),
	)

	// Initialize database connection
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test database connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	logger.Info("database connected",
		zap.String("url", maskDatabaseURL(cfg.DatabaseURL)),
	)

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
		db:           db,
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

	if k.db != nil {
		k.db.Close()
	}

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

	// Check database
	if err := k.db.Ping(); err != nil {
		status.Database = "error: " + err.Error()
		status.Healthy = false
	} else {
		status.Database = "ok"
	}

	// Check Web3 connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

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
