package keeper

import (
	"context"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestNewWeb3Client tests Web3 client initialization
func TestNewWeb3Client(t *testing.T) {
	t.Run("successful initialization", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err, "NewWeb3Client should not return error")
		require.NotNil(t, client, "Client should not be nil")

		assert.NotNil(t, client.client, "Ethereum client should be initialized")
		assert.NotNil(t, client.account, "Account should be initialized")
		assert.Equal(t, big.NewInt(31337), client.chainID, "Chain ID should match")
	})

	t.Run("invalid RPC URL", func(t *testing.T) {
		client, err := NewWeb3Client(
			"invalid-url",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		assert.Error(t, err, "Should return error for invalid RPC")
		assert.Nil(t, client, "Client should be nil on error")
	})

	t.Run("invalid private key", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"invalid-key",
			big.NewInt(31337),
		)
		assert.Error(t, err, "Should return error for invalid private key")
		assert.Nil(t, client, "Client should be nil on error")
	})

	t.Run("empty private key", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"",
			big.NewInt(31337),
		)
		assert.Error(t, err, "Should return error for empty private key")
		assert.Nil(t, client, "Client should be nil on error")
	})
}

// TestWeb3ClientGetAccount tests account retrieval
func TestWeb3ClientGetAccount(t *testing.T) {
	t.Run("returns correct account", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		account := client.GetAccount()
		assert.NotEqual(t, common.Address{}, account, "Account should not be zero address")

		// Anvil default account is 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
		expectedAccount := common.HexToAddress("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
		assert.Equal(t, expectedAccount, account, "Account should match expected address")
	})
}

// TestWeb3ClientGetBalance tests balance query
func TestWeb3ClientGetBalance(t *testing.T) {
	t.Run("query balance successfully", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		account := client.GetAccount()

		balance, err := client.GetBalance(ctx, account)
		// Note: This test requires Anvil to be running
		// We'll accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.NotNil(t, balance, "Balance should not be nil")
			// Anvil default account starts with 10000 ETH
			assert.True(t, balance.Cmp(big.NewInt(0)) > 0, "Balance should be positive")
		}
	})
}

// TestWeb3ClientGetBlockNumber tests block number query
func TestWeb3ClientGetBlockNumber(t *testing.T) {
	t.Run("query block number", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		blockNumber, err := client.GetBlockNumber(ctx)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.NotNil(t, blockNumber, "Block number should not be nil")
		}
	})
}

// TestWeb3ClientGetGasPrice tests gas price query
func TestWeb3ClientGetGasPrice(t *testing.T) {
	t.Run("query gas price", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		gasPrice, err := client.GetGasPrice(ctx)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.NotNil(t, gasPrice, "Gas price should not be nil")
			assert.True(t, gasPrice.Cmp(big.NewInt(0)) > 0, "Gas price should be positive")
		}
	})
}

// TestWeb3ClientCalculateGasPrice tests gas price calculation with limit
func TestWeb3ClientCalculateGasPrice(t *testing.T) {
	t.Run("returns current price when below limit", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		maxGasPrice := big.NewInt(1000000000000) // 1000 Gwei

		gasPrice, err := client.CalculateGasPrice(ctx, maxGasPrice)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.NotNil(t, gasPrice, "Gas price should not be nil")
			assert.True(t, gasPrice.Cmp(maxGasPrice) <= 0, "Gas price should not exceed max")
		}
	})

	t.Run("returns max when current price exceeds limit", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		maxGasPrice := big.NewInt(1) // Very low limit

		gasPrice, err := client.CalculateGasPrice(ctx, maxGasPrice)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.NotNil(t, gasPrice, "Gas price should not be nil")
			assert.Equal(t, maxGasPrice, gasPrice, "Should return max gas price")
		}
	})
}

// TestWeb3ClientEstimateGas tests gas estimation
func TestWeb3ClientEstimateGas(t *testing.T) {
	t.Run("estimate gas for simple transfer", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		to := common.HexToAddress("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")
		value := big.NewInt(1000000000000000000) // 1 ETH
		data := []byte{}

		gasLimit, err := client.EstimateGas(ctx, to, value, data)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.Greater(t, gasLimit, uint64(0), "Gas limit should be positive")
			assert.Less(t, gasLimit, uint64(100000), "Gas limit should be reasonable for transfer")
		}
	})
}

// TestWeb3ClientNonce tests nonce management
func TestWeb3ClientNonce(t *testing.T) {
	t.Run("get nonce for account", func(t *testing.T) {
		client, err := NewWeb3Client(
			"http://localhost:8545",
			"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
			big.NewInt(31337),
		)
		require.NoError(t, err)

		ctx := context.Background()
		account := client.GetAccount()

		nonce, err := client.GetNonce(ctx, account)

		// Accept either success or connection error
		if err != nil {
			assert.Contains(t, err.Error(), "connection", "Error should be connection-related")
		} else {
			assert.GreaterOrEqual(t, nonce, uint64(0), "Nonce should be non-negative")
		}
	})
}
