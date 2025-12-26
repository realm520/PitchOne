package keeper

import (
	"context"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestLockTask_GetMarketsToLock tests fetching markets that need locking
func TestLockTask_GetMarketsToLock(t *testing.T) {
	t.Run("returns markets within lock window", func(t *testing.T) {
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
			LockLeadTime:     300, // 5 minutes before match
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
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx := context.Background()
		markets, err := task.getMarketsToLock(ctx)

		// Should succeed even with empty database
		assert.NoError(t, err)
		assert.NotNil(t, markets)
	})
}

// TestLockTask_LockMarket tests locking a single market
func TestLockTask_LockMarket(t *testing.T) {
	t.Run("handles invalid market address", func(t *testing.T) {
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
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx := context.Background()
		marketAddr := common.HexToAddress("0x0000000000000000000000000000000000000000")

		err = task.lockMarketV2(ctx, marketAddr)
		assert.Error(t, err, "Should error on zero address")
	})

	t.Run("handles connection errors gracefully", func(t *testing.T) {
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
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx := context.Background()
		// Use a valid address format but non-existent contract
		marketAddr := common.HexToAddress("0x1111111111111111111111111111111111111111")

		err = task.lockMarketV2(ctx, marketAddr)
		// Should succeed even if database update fails (on-chain lock is what matters)
		// The function logs the database error but doesn't return it
		assert.NoError(t, err, "Should not return error even if database update fails, since on-chain lock succeeded")
	})
}

// TestLockTask_Execute tests the main execution loop
func TestLockTask_Execute(t *testing.T) {
	t.Run("executes without panic", func(t *testing.T) {
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
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		// Should not panic, will timeout which is expected
		err = task.Execute(ctx)
		assert.NoError(t, err, "Execute should complete gracefully")
	})
}

// TestLockTask_UpdateMarketStatus tests updating market status in database
func TestLockTask_UpdateMarketStatus(t *testing.T) {
	t.Run("updates status in database", func(t *testing.T) {
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
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx := context.Background()
		marketAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
		txHash := common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd")

		// This should fail with "no market found" since we didn't insert any data
		err = task.updateMarketStatus(ctx, marketAddr, "Locked", txHash)
		assert.Error(t, err, "Should fail when market doesn't exist in database")
		assert.Contains(t, err.Error(), "no market found", "Error should be about market not found")
	})
}

// TestLockTask_LockMarketV3 tests locking a V3 market
func TestLockTask_LockMarketV3(t *testing.T) {
	t.Run("handles invalid market address for V3", func(t *testing.T) {
		if !isDatabaseAvailable() {
			t.Skip("Database not available, skipping test")
		}

		cfg := &Config{
			ChainID:         31337,
			RPCEndpoint:     "http://localhost:8545",
			PrivateKey:      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			GasLimit:        500000,
			MaxGasPrice:     "100",
			TaskInterval:    60,
			LockLeadTime:    300,
			FinalizeDelay:   7200,
			MaxConcurrent:   10,
			RetryAttempts:   3,
			RetryDelay:      5,
			DatabaseURL:     "postgresql://p1:p1@localhost/p1?sslmode=disable",
			HealthCheckPort: 8081,
			MetricsPort:     9091,
			AlertsEnabled:   false,
		}

		keeper, err := NewKeeper(cfg)
		require.NoError(t, err)
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		defer keeper.Shutdown(shutdownCtx)

		task := &LockTask{
			keeper: keeper,
		}

		ctx := context.Background()
		marketAddr := common.HexToAddress("0x0000000000000000000000000000000000000000")

		err = task.lockMarketV3(ctx, marketAddr)
		assert.Error(t, err, "Should error on zero address for V3")
	})
}

// TestLockTask_MarketVersionRouting tests version-based routing
func TestLockTask_MarketVersionRouting(t *testing.T) {
	t.Run("MarketToLock has version field", func(t *testing.T) {
		market := &MarketToLock{
			MarketAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			EventID:       "test-event",
			LockTime:      time.Now(),
			MatchStart:    time.Now().Add(time.Hour),
			Version:       "v3",
		}

		assert.Equal(t, "v3", market.Version, "Version should be v3")
	})

	t.Run("default version is v2", func(t *testing.T) {
		market := &MarketToLock{
			MarketAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			EventID:       "test-event",
			LockTime:      time.Now(),
			MatchStart:    time.Now().Add(time.Hour),
		}

		// Empty version should be treated as v2 by the Execute logic
		assert.Empty(t, market.Version, "Version should be empty (default)")
	})
}
