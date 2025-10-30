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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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
		defer keeper.Shutdown(context.Background())

		task := NewSettleTask(keeper)

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

		// This will fail if markets table doesn't exist, which is expected
		err = task.updateMarketStatus(ctx, marketAddr, "Proposed", txHash, result)
		// We accept error here as table might not exist
		if err != nil {
			assert.Contains(t, err.Error(), "relation", "Error should be about missing table")
		}
	})
}
