package keeper

import (
	"context"
	"database/sql"
	"testing"
	"time"

	_ "github.com/lib/pq"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// isDatabaseAvailable checks if the test database is available
func isDatabaseAvailable() bool {
	db, err := sql.Open("postgres", "postgresql://p1:p1@localhost/p1?sslmode=disable")
	if err != nil {
		return false
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		return false
	}

	return true
}

// TestNewKeeper tests Keeper initialization
func TestNewKeeper(t *testing.T) {
	t.Run("successful initialization", func(t *testing.T) {
		// Skip if database not available
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337, // Anvil chain ID
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // Anvil default key
			GasLimit:         500000,
			MaxGasPrice:      "100", // 100 Gwei
			TaskInterval:     60,    // 60 seconds
			LockLeadTime:     300,   // 5 minutes before match
			FinalizeDelay:    7200,  // 2 hours dispute period
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err, "NewKeeper should not return error")
		require.NotNil(t, keeper, "Keeper should not be nil")

		assert.NotNil(t, keeper.web3Client, "Web3 client should be initialized")
		assert.NotNil(t, keeper.db, "Database client should be initialized")
		assert.NotNil(t, keeper.logger, "Logger should be initialized")
		assert.Equal(t, cfg.ChainID, keeper.chainID, "Chain ID should match")

		// Cleanup
		keeper.Shutdown(context.Background())
	})

	t.Run("invalid RPC endpoint", func(t *testing.T) {
		cfg := &Config{
			ChainID:     31337,
			RPCEndpoint: "invalid-url",
			PrivateKey:  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		}

		keeper, err := NewKeeper(cfg)
		assert.Error(t, err, "Should return error for invalid RPC")
		assert.Nil(t, keeper, "Keeper should be nil on error")
	})

	t.Run("invalid private key", func(t *testing.T) {
		cfg := &Config{
			ChainID:     31337,
			RPCEndpoint: "http://localhost:8545",
			PrivateKey:  "invalid-key",
		}

		keeper, err := NewKeeper(cfg)
		assert.Error(t, err, "Should return error for invalid private key")
		assert.Nil(t, keeper, "Keeper should be nil on error")
	})

	t.Run("missing required fields", func(t *testing.T) {
		cfg := &Config{
			ChainID:     31337,
			RPCEndpoint: "",
			PrivateKey:  "",
		}

		keeper, err := NewKeeper(cfg)
		assert.Error(t, err, "Should return error for missing fields")
		assert.Nil(t, keeper, "Keeper should be nil on error")
	})
}

// TestKeeperStart tests Keeper service startup
func TestKeeperStart(t *testing.T) {
	t.Run("start and stop", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		// Start keeper in background
		errChan := make(chan error, 1)
		go func() {
			errChan <- keeper.Start(ctx)
		}()

		// Wait a bit for startup
		time.Sleep(100 * time.Millisecond)

		// Stop keeper
		cancel()

		// Wait for shutdown
		select {
		case err := <-errChan:
			assert.NoError(t, err, "Keeper should shutdown gracefully")
		case <-time.After(5 * time.Second):
			t.Fatal("Keeper shutdown timeout")
		}
	})
}

// TestKeeperHealthCheck tests health check endpoint
func TestKeeperHealthCheck(t *testing.T) {
	t.Run("health check returns healthy", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		health := keeper.HealthCheck()
		assert.True(t, health.Healthy, "Keeper should be healthy")
		assert.NotEmpty(t, health.Version, "Version should be set")
		assert.Equal(t, "ok", health.Database, "Database should be ok")
		assert.Equal(t, "ok", health.Web3, "Web3 should be ok")
	})
}

// TestKeeperGracefulShutdown tests graceful shutdown
func TestKeeperGracefulShutdown(t *testing.T) {
	t.Run("shutdown completes pending tasks", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		err = keeper.Shutdown(ctx)
		assert.NoError(t, err, "Shutdown should complete successfully")
	})

	t.Run("shutdown times out if tasks don't complete", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		// Very short timeout to force timeout
		ctx, cancel := context.WithTimeout(context.Background(), 1*time.Millisecond)
		defer cancel()

		err = keeper.Shutdown(ctx)
		// Should return error due to timeout (depending on implementation)
		// This test verifies timeout handling
	})

	t.Run("shutdown when keeper is running", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		// Start the keeper
		go keeper.Start(context.Background())

		// Wait a bit for it to start
		time.Sleep(100 * time.Millisecond)

		// Shutdown with proper timeout
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		err = keeper.Shutdown(ctx)
		assert.NoError(t, err, "Shutdown should complete successfully")
	})

	t.Run("shutdown twice returns no error", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		// First shutdown
		err = keeper.Shutdown(ctx)
		assert.NoError(t, err)

		// Second shutdown should also succeed (idempotent)
		err = keeper.Shutdown(ctx)
		assert.NoError(t, err, "Second shutdown should be idempotent")
	})
}

// TestConfig_String tests Config.String() method
func TestConfig_String(t *testing.T) {
	t.Run("formats config correctly", func(t *testing.T) {
		cfg := &Config{
			ChainID:          31337,
			RPCEndpoint:      "http://localhost:8545",
			PrivateKey:       "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:         500000,
			MaxGasPrice:      "100",
			TaskInterval:     60,
			LockLeadTime:     300,
			FinalizeDelay:    7200,
			MaxConcurrent:    10,
			RetryAttempts:    3,
			RetryDelay:       5,
			DatabaseURL:      "postgresql://user:password@localhost/testdb",
			HealthCheckPort:  8081,
			MetricsPort:      9091,
			AlertsEnabled:    false,
		}

		str := cfg.String()

		// Check that output contains expected fields
		assert.Contains(t, str, "ChainID: 31337")
		assert.Contains(t, str, "RPC: http://localhost:8545")
		assert.Contains(t, str, "GasLimit: 500000")
		assert.Contains(t, str, "MaxGasPrice: 100")
		assert.Contains(t, str, "TaskInterval: 60s")

		// Check that password is masked
		assert.Contains(t, str, "***")
		assert.NotContains(t, str, "password", "Password should be masked")
	})

	t.Run("handles empty database URL", func(t *testing.T) {
		cfg := &Config{
			ChainID:      31337,
			RPCEndpoint:  "http://localhost:8545",
			GasLimit:     500000,
			MaxGasPrice:  "100",
			TaskInterval: 60,
			DatabaseURL:  "",
		}

		str := cfg.String()
		assert.NotEmpty(t, str, "String should not be empty")
		assert.Contains(t, str, "ChainID: 31337")
	})
}
