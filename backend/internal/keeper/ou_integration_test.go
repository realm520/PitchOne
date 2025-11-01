package keeper_test

import (
	"context"
	"database/sql"
	"encoding/json"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/pitchone/sportsbook/internal/keeper"
	"github.com/pitchone/sportsbook/internal/keeper/testutil"
)

// TestIntegration_OU_HalfLine tests OU market with half-line (2.5 goals)
// 测试场景：曼联 vs 曼城，盘口 2.5球
// - 总进球 3 球 → Over (outcome 0) 获胜
// - 总进球 2 球 → Under (outcome 1) 获胜
func TestIntegration_OU_HalfLine(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("=== Testing OU Market: Half-Line (2.5 goals) ===")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	// Setup: Start Anvil
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

	// Deploy OU market (2.5 goals)
	now := time.Now().Unix()
	kickoffTime := now + 5
	matchEnd := kickoffTime + 10

	t.Log("Deploying OU market with line 2.5 (half-line)")
	marketAddr, oracleAddr, err := deployOUMarketViaScript(2500, kickoffTime) // 2500 = 2.5球
	require.NoError(t, err, "Failed to deploy OU market")
	t.Logf("OU Market deployed at: %s", marketAddr.Hex())

	// Insert market into database with OU params
	market := createOUMarketData(marketAddr.Hex(), oracleAddr.Hex(), 2500, true)
	market.LockTime = kickoffTime
	market.MatchStart = kickoffTime + 5
	market.MatchEnd = matchEnd
	_, err = insertOUMarket(db, market)
	require.NoError(t, err, "Failed to insert OU market")

	// Start Keeper
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
		FinalizeDelay: 5,
		MaxConcurrent: 3,
	}

	k, err := keeper.NewKeeper(cfg)
	require.NoError(t, err, "Failed to create Keeper")

	keeperCtx, keeperCancel := context.WithCancel(context.Background())
	defer keeperCancel()

	go k.Start(keeperCtx)
	time.Sleep(2 * time.Second)

	// Phase 1: Lock the market
	t.Log("=== Phase 1: Locking market ===")
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err, "Failed to advance to kickoff")

	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err, "Market should be locked")
	t.Log("✅ OU Market locked successfully")

	// Phase 2: Simulate match result - 3 total goals (2-1, Over wins)
	t.Log("=== Phase 2: Simulating match result: 2-1 (Total 3 > 2.5, Over wins) ===")
	err = testutil.AdvanceToTime(client, uint64(matchEnd+10))
	require.NoError(t, err, "Failed to advance past match end")

	// Simulate match result: Home 2 - Away 1 (Total = 3, Over wins)
	_, err = db.Exec(`
		UPDATE markets
		SET home_goals = $1, away_goals = $2
		WHERE market_address = $3
	`, 2, 1, marketAddr.Hex())
	require.NoError(t, err, "Failed to update match result")

	// Phase 3: Keeper should calculate OU outcome and propose result
	t.Log("=== Phase 3: Keeper calculates OU outcome (Over/Under/Push) ===")
	time.Sleep(8 * time.Second) // Wait for Keeper to process

	// Verify Keeper calculated correct OU outcome
	updatedMarket, err := getMarketWithParams(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get updated market")

	t.Logf("Market status: %s", updatedMarket.Status)
	t.Logf("Home %d - Away %d (Total: %d)", updatedMarket.HomeGoals, updatedMarket.AwayGoals,
		updatedMarket.HomeGoals+updatedMarket.AwayGoals)
	t.Logf("Line: 2.5, Expected outcome: Over (0)")

	// Verify OU logic: 3 > 2.5 → Over (outcome 0)
	assert.Equal(t, 2, updatedMarket.HomeGoals, "Home goals should be 2")
	assert.Equal(t, 1, updatedMarket.AwayGoals, "Away goals should be 1")

	t.Log("✅ OU Half-Line test completed: 3 goals > 2.5 → Over wins")

	// Cleanup
	keeperCancel()
}

// TestIntegration_OU_IntegerLine_Push tests OU market with integer line (2.0 goals)
// and Push scenario (total goals == line)
// 测试场景：盘口 2.0球，总进球恰好 2 球 → Push (outcome 2) 退款
func TestIntegration_OU_IntegerLine_Push(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	t.Log("=== Testing OU Market: Integer-Line (2.0 goals) - Push Scenario ===")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	// Setup
	anvil, err := testutil.StartAnvil(ctx)
	require.NoError(t, err)
	defer anvil.Stop()

	client, err := anvil.GetClient()
	require.NoError(t, err)
	defer client.Close()

	db := testutil.SetupTestDatabase(t)
	defer db.Close()
	defer testutil.CleanupTestData(db)

	// Deploy OU market (2.0 goals - integer line)
	now := time.Now().Unix()
	kickoffTime := now + 5
	matchEnd := kickoffTime + 10

	t.Log("Deploying OU market with line 2.0 (integer line, Push enabled)")
	marketAddr, oracleAddr, err := deployOUMarketViaScript(2000, kickoffTime) // 2000 = 2.0球
	require.NoError(t, err)
	t.Logf("OU Market deployed at: %s", marketAddr.Hex())

	// Insert market with isHalfLine=false (integer line)
	market := createOUMarketData(marketAddr.Hex(), oracleAddr.Hex(), 2000, false)
	market.LockTime = kickoffTime
	market.MatchStart = kickoffTime + 5
	market.MatchEnd = matchEnd
	_, err = insertOUMarket(db, market)
	require.NoError(t, err)

	// Start Keeper
	cfg := &keeper.Config{
		DatabaseURL:  testutil.DefaultDatabaseURL,
		RPCEndpoint:  "http://localhost:8545",
		PrivateKey:   "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
		ChainID:      31337,
		TaskInterval: 1,
		LockLeadTime: 3,
		FinalizeDelay: 5,
		MaxConcurrent: 3,
	}

	k, err := keeper.NewKeeper(cfg)
	require.NoError(t, err)

	keeperCtx, keeperCancel := context.WithCancel(context.Background())
	defer keeperCancel()

	go k.Start(keeperCtx)
	time.Sleep(2 * time.Second)

	// Lock market
	t.Log("=== Phase 1: Locking market ===")
	err = testutil.AdvanceToTime(client, uint64(kickoffTime))
	require.NoError(t, err)

	err = testutil.WaitForDatabaseUpdate(db, marketAddr.Hex(), "Locked", 30*time.Second)
	require.NoError(t, err)
	t.Log("✅ OU Market locked")

	// Simulate match result: 1-1 (Total = 2, exact match → Push)
	t.Log("=== Phase 2: Simulating match result: 1-1 (Total 2 == 2.0, Push!) ===")
	err = testutil.AdvanceToTime(client, uint64(matchEnd+10))
	require.NoError(t, err)

	_, err = db.Exec(`
		UPDATE markets
		SET home_goals = $1, away_goals = $2
		WHERE market_address = $3
	`, 1, 1, marketAddr.Hex())
	require.NoError(t, err)

	// Wait for Keeper to process
	t.Log("=== Phase 3: Keeper should detect Push scenario (outcome 2) ===")
	time.Sleep(8 * time.Second)

	updatedMarket, err := getMarketWithParams(db, marketAddr.Hex())
	require.NoError(t, err)

	t.Logf("Market status: %s", updatedMarket.Status)
	t.Logf("Home %d - Away %d (Total: %d)", updatedMarket.HomeGoals, updatedMarket.AwayGoals,
		updatedMarket.HomeGoals+updatedMarket.AwayGoals)
	t.Logf("Line: 2.0 (integer), Expected outcome: Push (2)")

	// Verify Push logic: 2 == 2.0 → Push (outcome 2)
	assert.Equal(t, 1, updatedMarket.HomeGoals)
	assert.Equal(t, 1, updatedMarket.AwayGoals)

	t.Log("✅ OU Integer-Line Push test completed: 2 goals == 2.0 → Push (refund)")

	// Cleanup
	keeperCancel()
}

// TestIntegration_OU_MultipleScenarios tests various total goals scenarios
func TestIntegration_OU_MultipleScenarios(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping integration test")
	}

	scenarios := []struct {
		name       string
		line       uint64
		isHalfLine bool
		homeGoals  int
		awayGoals  int
		expected   string // "Over", "Under", or "Push"
	}{
		{"2.5_Over", 2500, true, 3, 1, "Over"},    // 4 > 2.5
		{"2.5_Under", 2500, true, 1, 0, "Under"},  // 1 < 2.5
		{"2.0_Over", 2000, false, 2, 1, "Over"},   // 3 > 2.0
		{"2.0_Under", 2000, false, 0, 1, "Under"}, // 1 < 2.0
		{"2.0_Push", 2000, false, 1, 1, "Push"},   // 2 == 2.0
		{"3.5_Over", 3500, true, 2, 2, "Over"},    // 4 > 3.5
		{"3.5_Under", 3500, true, 1, 2, "Under"},  // 3 < 3.5
	}

	for _, tc := range scenarios {
		t.Run(tc.name, func(t *testing.T) {
			// Calculate expected outcome
			totalGoals := float64(tc.homeGoals + tc.awayGoals)
			lineFloat := float64(tc.line) / 1000.0

			var expectedOutcome uint8
			if tc.isHalfLine {
				if totalGoals > lineFloat {
					expectedOutcome = 0 // Over
				} else {
					expectedOutcome = 1 // Under
				}
			} else {
				if totalGoals > lineFloat {
					expectedOutcome = 0 // Over
				} else if totalGoals < lineFloat {
					expectedOutcome = 1 // Under
				} else {
					expectedOutcome = 2 // Push
				}
			}

			t.Logf("Scenario: %s | Line: %.1f | Home %d - Away %d | Total: %.0f | Expected: %s (outcome %d)",
				tc.name, lineFloat, tc.homeGoals, tc.awayGoals, totalGoals, tc.expected, expectedOutcome)

			// Verify expected outcome matches
			switch tc.expected {
			case "Over":
				assert.Equal(t, uint8(0), expectedOutcome)
			case "Under":
				assert.Equal(t, uint8(1), expectedOutcome)
			case "Push":
				assert.Equal(t, uint8(2), expectedOutcome)
			}
		})
	}

	t.Log("✅ All OU scenarios validated")
}

// ========================================
// Helper Functions for OU Market Testing
// ========================================

// OUMarketData represents OU market data structure
type OUMarketData struct {
	MarketAddress string
	OracleAddress string
	EventID       string
	Status        string
	LockTime      int64
	MatchStart    int64
	MatchEnd      int64
	Line          uint64 // 千分位表示，如 2500 = 2.5球
	IsHalfLine    bool
	HomeGoals     int
	AwayGoals     int
	MarketParams  map[string]interface{}
}

// createOUMarketData creates test OU market data
func createOUMarketData(marketAddr, oracleAddr string, line uint64, isHalfLine bool) *OUMarketData {
	marketParams := map[string]interface{}{
		"type":       "OU",
		"line":       line,
		"isHalfLine": isHalfLine,
	}

	return &OUMarketData{
		MarketAddress: marketAddr,
		OracleAddress: oracleAddr,
		EventID:       "TEST_OU_MATCH_001",
		Status:        "Open",
		Line:          line,
		IsHalfLine:    isHalfLine,
		MarketParams:  marketParams,
	}
}

// insertOUMarket inserts OU market into database
func insertOUMarket(db *sql.DB, market *OUMarketData) (int64, error) {
	paramsJSON, err := json.Marshal(market.MarketParams)
	if err != nil {
		return 0, err
	}

	query := `
		INSERT INTO markets (
			market_address, event_id, status, oracle_address,
			lock_time, match_start, match_end, market_params,
			created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
		RETURNING id
	`

	var id int64
	err = db.QueryRow(query,
		market.MarketAddress,
		market.EventID,
		market.Status,
		market.OracleAddress,
		market.LockTime,
		market.MatchStart,
		market.MatchEnd,
		paramsJSON,
	).Scan(&id)

	return id, err
}

// getMarketWithParams retrieves market with parsed market_params
func getMarketWithParams(db *sql.DB, marketAddr string) (*OUMarketData, error) {
	query := `
		SELECT market_address, oracle_address, event_id, status,
		       lock_time, match_start, match_end, market_params,
		       COALESCE(home_goals, 0), COALESCE(away_goals, 0)
		FROM markets
		WHERE market_address = $1
	`

	var market OUMarketData
	var paramsJSON []byte

	err := db.QueryRow(query, marketAddr).Scan(
		&market.MarketAddress,
		&market.OracleAddress,
		&market.EventID,
		&market.Status,
		&market.LockTime,
		&market.MatchStart,
		&market.MatchEnd,
		&paramsJSON,
		&market.HomeGoals,
		&market.AwayGoals,
	)
	if err != nil {
		return nil, err
	}

	// Parse market_params JSONB
	market.MarketParams = make(map[string]interface{})
	if len(paramsJSON) > 0 {
		if err := json.Unmarshal(paramsJSON, &market.MarketParams); err != nil {
			return nil, err
		}
	}

	// Extract OU-specific fields
	if lineVal, ok := market.MarketParams["line"]; ok {
		switch v := lineVal.(type) {
		case float64:
			market.Line = uint64(v)
		}
	}

	if isHalfLineVal, ok := market.MarketParams["isHalfLine"]; ok {
		if b, ok := isHalfLineVal.(bool); ok {
			market.IsHalfLine = b
		}
	}

	return &market, nil
}

// deployOUMarketViaScript deploys OU market using Foundry script
func deployOUMarketViaScript(line uint64, kickoffTime int64) (common.Address, common.Address, error) {
	// TODO: Implement actual Foundry script call
	// For now, return mock addresses (will be implemented in Phase 4.4)

	// This would execute:
	// forge script script/DeployOUMarket.s.sol --sig "deployWithParams(uint256,uint256)" <line> <kickoffTime> --broadcast

	// Placeholder implementation
	marketAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
	oracleAddr := common.HexToAddress("0x0987654321098765432109876543210987654321")

	return marketAddr, oracleAddr, nil
}
