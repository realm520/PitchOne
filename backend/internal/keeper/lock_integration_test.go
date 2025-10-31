package keeper_test

import (
	"context"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"

	"github.com/pitchone/sportsbook/internal/keeper"
	"github.com/pitchone/sportsbook/internal/keeper/testutil"
)

// TestIntegration_LockFlow tests the complete lock flow:
// 1. Deploy a new market
// 2. Insert market into database
// 3. Start Keeper service
// 4. Advance time to kickoff
// 5. Verify market is locked on-chain
// 6. Verify database status is updated
func TestIntegration_LockFlow(t *testing.T) {
	// Skip if not running integration tests
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	// Setup: Start Anvil
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	anvil, err := testutil.StartAnvil(ctx)
	require.NoError(t, err, "Failed to start Anvil")
	defer anvil.Stop()

	// Get Anvil client
	client, err := anvil.GetClient()
	require.NoError(t, err, "Failed to get Anvil client")
	defer client.Close()

	// Setup: Database
	db := testutil.SetupTestDatabase(t)
	defer db.Close()
	defer testutil.CleanupTestData(db)

	// Deploy a new market with kickoff time in 5 seconds
	now := time.Now().Unix()
	kickoffTime := now + 5

	t.Logf("Deploying market with kickoff time: %d (current: %d)", kickoffTime, now)
	marketAddr, oracleAddr, err := testutil.DeployMarketViaScript(kickoffTime)
	require.NoError(t, err, "Failed to deploy market")
	t.Logf("Market deployed at: %s", marketAddr.Hex())

	// Insert market into database
	market := testutil.CreateTestMarketData(marketAddr.Hex(), oracleAddr.Hex(), 5)
	market.LockTime = kickoffTime
	_, err = testutil.InsertTestMarket(db, market)
	require.NoError(t, err, "Failed to insert test market")

	// Verify market is Open on-chain
	status, err := testutil.GetMarketStatusOnChain(client, marketAddr)
	require.NoError(t, err, "Failed to get market status")
	require.Equal(t, uint8(0), status, "Market should be Open initially")

	// Create Keeper configuration
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // Anvil default key
		ChainID:      31337,                                                              // Anvil chain ID
		TaskInterval: 1,                                                                  // Check every 1 second
		LockLeadTime: 3,                                                                  // Lock 3 seconds before kickoff
	}

	// Start Keeper service in background
	k, err := keeper.NewKeeper(cfg)
	require.NoError(t, err, "Failed to create Keeper")

	// Start Keeper
	keeperCtx, keeperCancel := context.WithCancel(context.Background())
	defer keeperCancel()

	keeperDone := make(chan error, 1)
	go func() {
		keeperDone <- k.Start(keeperCtx)
	}()

	// Wait for Keeper to initialize
	time.Sleep(2 * time.Second)

	// Advance blockchain time to kickoff
	t.Log("Advancing blockchain time to kickoff")
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err, "Failed to advance time")

	// Wait for Keeper to process the lock task (max 30 seconds)
	t.Log("Waiting for Keeper to lock the market")
	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err, "Market should be locked by Keeper")

	// Verify market is locked on-chain and in database
	testutil.AssertMarketLocked(t, client, db, marketAddr)

	// Verify lock_tx_hash is set
	testutil.AssertFieldSet(t, db, marketAddr, "lock_tx_hash")

	// Verify locked_at timestamp is reasonable
	updatedMarket, err := testutil.GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market")
	require.Greater(t, updatedMarket.LockedAt, kickoffTime-10, "locked_at should be close to kickoff time")
	require.Less(t, updatedMarket.LockedAt, kickoffTime+30, "locked_at should not be too far in the future")

	t.Log("✅ Lock flow test passed")

	// Cleanup: Stop Keeper
	keeperCancel()
	select {
	case err := <-keeperDone:
		require.NoError(t, err, "Keeper should shut down cleanly")
	case <-time.After(5 * time.Second):
		t.Fatal("Keeper did not shut down in time")
	}
}

// TestIntegration_LockFlow_MultipleMarkets tests concurrent locking of multiple markets
func TestIntegration_LockFlow_MultipleMarkets(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	// Setup: Start Anvil
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	anvil, err := testutil.StartAnvil(ctx)
	require.NoError(t, err, "Failed to start Anvil")
	defer anvil.Stop()

	client, err := anvil.GetClient()
	require.NoError(t, err, "Failed to get Anvil client")
	defer client.Close()

	// Setup: Database
	db := testutil.SetupTestDatabase(t)
	defer db.Close()
	defer testutil.CleanupTestData(db)

	// Deploy 3 markets with different kickoff times
	now := time.Now().Unix()
	markets := []struct {
		kickoffDelta int64
		addr         string
	}{
		{kickoffDelta: 5},
		{kickoffDelta: 10},
		{kickoffDelta: 15},
	}

	for i := range markets {
		kickoffTime := now + markets[i].kickoffDelta
		marketAddr, oracleAddr, err := testutil.DeployMarketViaScript(kickoffTime)
		require.NoError(t, err, "Failed to deploy market %d", i)

		markets[i].addr = marketAddr.Hex()
		t.Logf("Market %d deployed at: %s (kickoff: %d)", i, marketAddr.Hex(), kickoffTime)

		market := testutil.CreateTestMarketData(marketAddr.Hex(), oracleAddr.Hex(), markets[i].kickoffDelta)
		market.LockTime = kickoffTime
		_, err = testutil.InsertTestMarket(db, market)
		require.NoError(t, err, "Failed to insert market %d", i)
	}

	// Start Keeper
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
	}

	k, err := keeper.NewKeeper(cfg)
	require.NoError(t, err, "Failed to create Keeper")

	keeperCtx, keeperCancel := context.WithCancel(context.Background())
	defer keeperCancel()

	go k.Start(keeperCtx)
	time.Sleep(2 * time.Second)

	// Advance time to lock all markets
	finalKickoff := now + 15
	err = testutil.AdvanceToTime(client, uint64(finalKickoff))
	require.NoError(t, err, "Failed to advance time")

	// Wait for all markets to be locked
	for i, market := range markets {
		t.Logf("Waiting for market %d to be locked", i)
		err = testutil.WaitForDatabaseUpdate(db, market.addr, "Locked", 30*time.Second)
		require.NoError(t, err, "Market %d should be locked", i)
	}

	// Verify all markets are locked
	for i, market := range markets {
		marketAddr := common.HexToAddress(market.addr)
		testutil.AssertMarketLocked(t, client, db, marketAddr)
		t.Logf("✅ Market %d locked successfully", i)
	}

	t.Log("✅ Multiple markets lock flow test passed")

	// Cleanup
	keeperCancel()
}

// TestIntegration_LockFlow_Idempotency verifies that re-running lock on an already-locked market is safe
func TestIntegration_LockFlow_Idempotency(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	// Setup
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	anvil, err := testutil.StartAnvil(ctx)
	require.NoError(t, err)
	defer anvil.Stop()

	client, err := anvil.GetClient()
	require.NoError(t, err)
	defer client.Close()

	db := testutil.SetupTestDatabase(t)
	defer db.Close()
	defer testutil.CleanupTestData(db)

	// Deploy market
	now := time.Now().Unix()
	kickoffTime := now + 5
	marketAddr, oracleAddr, err := testutil.DeployMarketViaScript(kickoffTime)
	require.NoError(t, err)

	market := testutil.CreateTestMarketData(marketAddr.Hex(), oracleAddr.Hex(), 5)
	market.LockTime = kickoffTime
	_, err = testutil.InsertTestMarket(db, market)
	require.NoError(t, err)

	// Start Keeper
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
	}

	k, err := keeper.NewKeeper(cfg)
	require.NoError(t, err)

	keeperCtx, keeperCancel := context.WithCancel(context.Background())
	defer keeperCancel()

	go k.Start(keeperCtx)
	time.Sleep(2 * time.Second)

	// Advance time and wait for lock
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err)

	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err)

	// Get initial lock state
	market1, err := testutil.GetMarket(db, marketAddr.Hex())
	require.NoError(t, err)

	// Wait a bit more and check that state hasn't changed
	time.Sleep(5 * time.Second)

	market2, err := testutil.GetMarket(db, marketAddr.Hex())
	require.NoError(t, err)

	// Verify idempotency: state should not have changed
	require.Equal(t, market1.LockTxHash, market2.LockTxHash, "lock_tx_hash should not change")
	require.Equal(t, market1.LockedAt, market2.LockedAt, "locked_at should not change")
	require.Equal(t, "Locked", market2.Status, "Status should remain Locked")

	t.Log("✅ Idempotency test passed - market was not re-locked")

	// Cleanup
	keeperCancel()
}
