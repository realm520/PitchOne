package testutil

import (
	"database/sql"
	"fmt"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// AssertMarketLocked verifies that a market is locked both on-chain and in the database
func AssertMarketLocked(t *testing.T, client *ethclient.Client, db *sql.DB, marketAddr common.Address) {
	t.Helper()

	// Check on-chain status
	status, err := GetMarketStatusOnChain(client, marketAddr)
	require.NoError(t, err, "Failed to get market status on-chain")
	assert.Equal(t, uint8(1), status, "Market should be Locked on-chain (status=1)")

	// Check database status
	dbStatus, err := GetMarketStatus(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market status from database")
	assert.Equal(t, "Locked", dbStatus, "Market should be Locked in database")

	// Check that lock_tx_hash is set
	market, err := GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market from database")
	assert.NotEmpty(t, market.LockTxHash, "lock_tx_hash should be set")
	assert.Greater(t, market.LockedAt, int64(0), "locked_at should be set")
}

// AssertMarketProposed verifies that a market has been proposed to the oracle
func AssertMarketProposed(t *testing.T, db *sql.DB, marketAddr common.Address) {
	t.Helper()

	// Check database status
	dbStatus, err := GetMarketStatus(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market status from database")
	assert.Equal(t, "Proposed", dbStatus, "Market should be Proposed in database")

	// Check that settle_tx_hash is set
	market, err := GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market from database")
	assert.NotEmpty(t, market.SettleTxHash, "settle_tx_hash should be set")
	assert.Greater(t, market.SettledAt, int64(0), "settled_at should be set")

	// Check that match results are recorded
	// Note: home_goals and away_goals should be set (can be 0)
	assert.GreaterOrEqual(t, market.HomeGoals, 0, "home_goals should be set")
	assert.GreaterOrEqual(t, market.AwayGoals, 0, "away_goals should be set")
}

// AssertDatabaseConsistent verifies that the database state matches the on-chain state
func AssertDatabaseConsistent(t *testing.T, client *ethclient.Client, db *sql.DB, marketAddr common.Address) {
	t.Helper()

	// Get on-chain status
	onChainStatus, err := GetMarketStatusOnChain(client, marketAddr)
	require.NoError(t, err, "Failed to get on-chain status")

	// Get database status
	dbStatus, err := GetMarketStatus(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get database status")

	// Map on-chain status to database status
	expectedDBStatus := map[uint8]string{
		0: "Open",
		1: "Locked",
		2: "Resolved",
		3: "Finalized",
	}[onChainStatus]

	assert.Equal(t, expectedDBStatus, dbStatus, "Database status should match on-chain status")
}

// AssertMarketExists checks that a market exists in the database
func AssertMarketExists(t *testing.T, db *sql.DB, marketAddr common.Address) {
	t.Helper()

	_, err := GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Market should exist in database")
}

// AssertMarketNotLocked verifies that a market is NOT locked (for idempotency tests)
func AssertMarketNotLocked(t *testing.T, client *ethclient.Client, marketAddr common.Address) {
	t.Helper()

	status, err := GetMarketStatusOnChain(client, marketAddr)
	require.NoError(t, err, "Failed to get market status on-chain")
	assert.NotEqual(t, uint8(1), status, "Market should NOT be Locked on-chain")
}

// AssertTransactionSuccess verifies that a transaction was successful
func AssertTransactionSuccess(t *testing.T, client *ethclient.Client, txHash common.Hash) {
	t.Helper()

	success, err := WaitForTransaction(client, txHash)
	require.NoError(t, err, "Failed to wait for transaction")
	assert.True(t, success, fmt.Sprintf("Transaction %s should be successful", txHash.Hex()))
}

// AssertFieldSet verifies that a database field has been set (non-null, non-empty)
func AssertFieldSet(t *testing.T, db *sql.DB, marketAddr common.Address, fieldName string) {
	t.Helper()

	market, err := GetMarket(db, marketAddr.Hex())
	require.NoError(t, err, "Failed to get market from database")

	var fieldValue string
	switch fieldName {
	case "lock_tx_hash":
		fieldValue = market.LockTxHash
	case "settle_tx_hash":
		fieldValue = market.SettleTxHash
	default:
		t.Fatalf("Unknown field: %s", fieldName)
	}

	assert.NotEmpty(t, fieldValue, fmt.Sprintf("%s should be set", fieldName))
}
