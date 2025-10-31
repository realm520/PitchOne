package keeper_test

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"github.com/pitchone/sportsbook/internal/keeper"
	"github.com/pitchone/sportsbook/internal/keeper/testutil"
)

// TestIntegration_SettleFlow tests the complete settle flow:
// 1. Deploy and lock a market
// 2. Advance time past match end
// 3. Simulate external oracle submitting result
// 4. Start Keeper service
// 5. Verify Keeper proposes result to UMA
// 6. Verify database status is updated to "Proposed"
func TestIntegration_SettleFlow(t *testing.T) {
	// Skip if not running integration tests
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("⚠️  Note: This test requires UMA Optimistic Oracle integration")
	t.Log("⚠️  Currently using MockOracle for testing purposes")

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

	// Deploy market with kickoff in 5 seconds, match duration 10 seconds
	now := time.Now().Unix()
	kickoffTime := now + 5
	matchEnd := kickoffTime + 10

	t.Logf("Deploying market: kickoff=%d, matchEnd=%d", kickoffTime, matchEnd)
	marketAddr, oracleAddr, err := testutil.DeployMarketViaScript(kickoffTime)
	require.NoError(t, err, "Failed to deploy market")
	t.Logf("Market deployed at: %s", marketAddr.Hex())

	// Insert market into database
	market := testutil.CreateTestMarketData(marketAddr.Hex(), oracleAddr.Hex(), 5)
	market.LockTime = kickoffTime
	market.MatchStart = kickoffTime + 5
	market.MatchEnd = matchEnd
	_, err = testutil.InsertTestMarket(db, market)
	require.NoError(t, err, "Failed to insert test market")

	// Phase 1: Lock the market
	t.Log("=== Phase 1: Locking market ===")

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

	// Advance to kickoff
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err, "Failed to advance to kickoff")

	// Wait for lock
	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err, "Market should be locked")
	t.Log("✅ Market locked successfully")

	// Phase 2: Simulate match completion and external oracle result
	t.Log("=== Phase 2: Match completion ===")

	// Advance time past match end
	err = testutil.AdvanceToTime(client, uint64(matchEnd+10))
	require.NoError(t, err, "Failed to advance past match end")
	t.Logf("Time advanced to: %d (match ended at %d)", matchEnd+10, matchEnd)

	// Simulate external oracle submitting result (2-1, home team wins)
	// In a real scenario, this would be done by an external service watching the match
	// For testing, we'll update the database directly to simulate the oracle result being available
	t.Log("Simulating external oracle result: Home 2 - 1 Away")
	_, err = db.Exec(`
		UPDATE markets
		SET home_goals = $1, away_goals = $2
		WHERE market_address = $3
	`, 2, 1, marketAddr.Hex())
	require.NoError(t, err, "Failed to update match result")

	// Phase 3: Keeper should detect settled match and propose result
	t.Log("=== Phase 3: Keeper proposes result ===")

	// Note: In the real implementation, Keeper's SettleTask would:
	// 1. Detect market is Locked and match_end has passed
	// 2. Check if result is available (home_goals, away_goals set)
	// 3. Call UMA OO's proposeResult() with the result data
	// 4. Update database status to "Proposed"

	// For now, we'll wait a bit to give Keeper time to process
	// In阶段 4.3, we'll implement the actual SettleTask logic
	time.Sleep(5 * time.Second)

	// Check if Keeper has processed the settlement
	// Note: This will likely fail until SettleTask is fully implemented
	updatedMarket, err := testutil.GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get updated market")

	t.Logf("Current market status: %s", updatedMarket.Status)
	t.Logf("Home goals: %d, Away goals: %d", updatedMarket.HomeGoals, updatedMarket.AwayGoals)

	// Verify SettleTask has processed the settlement
	testutil.AssertMarketProposed(t, db, marketAddr)
	require.Equal(t, 2, updatedMarket.HomeGoals, "Home goals should be 2")
	require.Equal(t, 1, updatedMarket.AwayGoals, "Away goals should be 1")

	t.Log("✅ Settle flow test completed: market locked → result proposed → database updated")

	// Cleanup
	keeperCancel()
}

// TestIntegration_SettleFlow_Timing tests that Keeper respects timing constraints:
// - Should NOT settle before match_end
// - SHOULD settle after match_end + buffer time
func TestIntegration_SettleFlow_Timing(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("⚠️  This test verifies SettleTask timing constraints")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
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

	now := time.Now().Unix()
	kickoffTime := now + 5
	matchEnd := kickoffTime + 10

	marketAddr, oracleAddr, err := testutil.DeployMarketViaScript(kickoffTime)
	require.NoError(t, err)

	market := testutil.CreateTestMarketData(marketAddr.Hex(), oracleAddr.Hex(), 5)
	market.LockTime = kickoffTime
	market.MatchStart = kickoffTime + 5
	market.MatchEnd = matchEnd
	_, err = testutil.InsertTestMarket(db, market)
	require.NoError(t, err)

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

	// Lock the market
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err)

	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err)

	// Set match result
	_, err = db.Exec(`
		UPDATE markets
		SET home_goals = $1, away_goals = $2
		WHERE market_address = $3
	`, 1, 1, marketAddr.Hex())
	require.NoError(t, err)

	// Test 1: Advance to just before match_end - should NOT settle
	t.Log("Test 1: Before match_end - should NOT settle")
	err = testutil.AdvanceToTime(client, uint64(matchEnd-5))
	require.NoError(t, err)
	time.Sleep(3 * time.Second)

	status, _ := testutil.GetMarketStatus(db, marketAddr.Hex())
	require.Equal(t, "Locked", status, "Should still be Locked before match_end")
	t.Log("✅ Correctly remained Locked before match_end")

	// Test 2: Advance past match_end - SHOULD settle (once implemented)
	t.Log("Test 2: After match_end - should settle (when SettleTask implemented)")
	err = testutil.AdvanceToTime(client, uint64(matchEnd+10))
	require.NoError(t, err)
	time.Sleep(5 * time.Second)

	status, _ = testutil.GetMarketStatus(db, marketAddr.Hex())
	t.Logf("Status after match_end: %s", status)

	// Verify SettleTask has processed the settlement after match_end
	require.Equal(t, "Proposed", status, "Should be Proposed after match_end")

	t.Log("✅ SettleTask timing test completed: correctly settled after match_end")

	keeperCancel()
}

// TestIntegration_ErrorRecovery_DatabaseFailure tests Keeper's behavior when database is unavailable
func TestIntegration_ErrorRecovery_DatabaseFailure(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("⚠️  Testing error recovery with invalid database URL")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	anvil, err := testutil.StartAnvil(ctx)
	require.NoError(t, err)
	defer anvil.Stop()

	// Create Keeper with invalid database URL
	cfg := &keeper.Config{
		DatabaseURL:  "postgresql://invalid:invalid@localhost:9999/invalid",
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
	}

	// Keeper should fail to initialize with invalid database
	_, err = keeper.NewKeeper(cfg)
	require.Error(t, err, "Should fail with invalid database URL")
	t.Logf("✅ Correctly failed with error: %v", err)

	t.Log("✅ Error recovery test passed: Keeper fails fast with invalid database")
}

// TestIntegration_ErrorRecovery_RPCFailure tests Keeper's behavior when RPC is unavailable
func TestIntegration_ErrorRecovery_RPCFailure(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("⚠️  Testing error recovery with invalid RPC endpoint")

	db := testutil.SetupTestDatabase(t)
	defer db.Close()

	// Create Keeper with invalid RPC URL
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:9999", // Invalid port
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
	}

	// Keeper should fail to initialize with invalid RPC
	_, err := keeper.NewKeeper(cfg)
	require.Error(t, err, "Should fail with invalid RPC URL")
	t.Logf("✅ Correctly failed with error: %v", err)

	t.Log("✅ Error recovery test passed: Keeper fails fast with invalid RPC")
}
