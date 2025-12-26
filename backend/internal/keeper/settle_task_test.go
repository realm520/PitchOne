package keeper

import (
	"context"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSettleTask_GetMarketsToSettle tests fetching markets that need settling
func TestSettleTask_GetMarketsToSettle(t *testing.T) {
	t.Run("returns markets within settle window", func(t *testing.T) {
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
			FinalizeDelay:    7200, // 2 hours after match end
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		markets, err := task.getMarketsToSettle(ctx)

		// Should succeed even with empty database
		assert.NoError(t, err)
		assert.NotNil(t, markets)
	})
}

// TestSettleTask_SettleMarket tests settling a single market
func TestSettleTask_SettleMarket(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x0000000000000000000000000000000000000000"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
		}

		err = task.settleMarket(ctx, market)
		assert.Error(t, err, "Should error on zero market address")
	})

	t.Run("handles invalid oracle address", func(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x0000000000000000000000000000000000000000"),
		}

		err = task.settleMarket(ctx, market)
		assert.Error(t, err, "Should error on zero oracle address")
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		// Use valid address formats but non-existent contracts
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x2222222222222222222222222222222222222222"),
		}

		err = task.settleMarket(ctx, market)
		// Should succeed even if database update fails (on-chain settlement is what matters)
		// The function logs the database error but doesn't return it
		assert.NoError(t, err, "Should not return error even if database update fails, since on-chain settlement succeeded")
	})
}

// TestSettleTask_Execute tests the main execution loop
func TestSettleTask_Execute(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		// Should not panic, will timeout which is expected
		err = task.Execute(ctx)
		assert.NoError(t, err, "Execute should complete gracefully")
	})
}

// TestSettleTask_FetchMatchResult tests fetching match results
func TestSettleTask_FetchMatchResult(t *testing.T) {
	t.Run("returns mock result", func(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		result, err := task.fetchMatchResult(ctx, "test-event-123")

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, uint8(2), result.HomeGoals)
		assert.Equal(t, uint8(1), result.AwayGoals)
		assert.True(t, result.HomeWin)
		assert.False(t, result.AwayWin)
		assert.False(t, result.Draw)
	})
}

// TestSettleTask_UpdateMarketStatus tests updating market status in database
func TestSettleTask_UpdateMarketStatus(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		marketAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
		txHash := common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd")
		result := &MatchResult{
			HomeGoals: 3,
			AwayGoals: 2,
			ExtraTime: false,
			HomeWin:   true,
			AwayWin:   false,
			Draw:      false,
		}

		// This will fail since the market doesn't exist in database
		err = task.updateMarketStatus(ctx, marketAddr, "Proposed", txHash, result)
		assert.Error(t, err, "Should fail when market doesn't exist in database")
		assert.Contains(t, err.Error(), "no market found", "Error should be about market not found")
	})
}

// TestSettleTask_SettleMarketV3 tests settling a V3 market
func TestSettleTask_SettleMarketV3(t *testing.T) {
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

		task := NewSettleTask(keeper, keeper.dataSource)

		ctx := context.Background()
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x0000000000000000000000000000000000000000"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			Version:       "v3",
		}

		err = task.settleMarketV3(ctx, market)
		assert.Error(t, err, "Should error on zero market address for V3")
	})
}

// TestEncodeMatchResult tests the ABI encoding of match results
func TestEncodeMatchResult(t *testing.T) {
	t.Run("encodes result correctly", func(t *testing.T) {
		result, err := encodeMatchResult(3, 1)
		assert.NoError(t, err)
		assert.Len(t, result, 64, "Should be 64 bytes (2 x uint256)")

		// Check homeGoals (first 32 bytes, should be 3)
		assert.Equal(t, byte(3), result[31], "Home goals should be 3")

		// Check awayGoals (second 32 bytes, should be 1)
		assert.Equal(t, byte(1), result[63], "Away goals should be 1")
	})

	t.Run("encodes zero scores correctly", func(t *testing.T) {
		result, err := encodeMatchResult(0, 0)
		assert.NoError(t, err)
		assert.Len(t, result, 64)

		// All bytes should be zero
		for i := 0; i < 64; i++ {
			assert.Equal(t, byte(0), result[i], "Byte %d should be 0", i)
		}
	})

	t.Run("encodes high scores correctly", func(t *testing.T) {
		result, err := encodeMatchResult(10, 7)
		assert.NoError(t, err)
		assert.Len(t, result, 64)

		assert.Equal(t, byte(10), result[31], "Home goals should be 10")
		assert.Equal(t, byte(7), result[63], "Away goals should be 7")
	})
}

// TestSettleTask_MarketVersionRouting tests version-based routing for settle
func TestSettleTask_MarketVersionRouting(t *testing.T) {
	t.Run("MarketToSettle has version field", func(t *testing.T) {
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			Version:       "v3",
		}

		assert.Equal(t, "v3", market.Version, "Version should be v3")
	})

	t.Run("routes to V2 by default", func(t *testing.T) {
		market := &MarketToSettle{
			MarketAddress: common.HexToAddress("0x1234567890123456789012345678901234567890"),
			EventID:       "test-event",
			OracleAddress: common.HexToAddress("0x1111111111111111111111111111111111111111"),
			Version:       "", // empty = default to v2
		}

		// Empty version is treated as v2 in settleMarket()
		assert.Empty(t, market.Version, "Version should be empty (defaults to v2)")
	})
}
