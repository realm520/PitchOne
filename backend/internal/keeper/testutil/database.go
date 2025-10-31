package testutil

import (
	"context"
	"database/sql"
	"fmt"
	"testing"
	"time"

	_ "github.com/lib/pq"
)

const (
	// DefaultDatabaseURL is the default PostgreSQL connection string for tests
	DefaultDatabaseURL = "postgresql://p1:p1@localhost/p1?sslmode=disable"
)

// TestMarket represents a test market record
type TestMarket struct {
	Address     string
	EventID     string
	Status      string
	LockTime    int64
	MatchStart  int64
	MatchEnd    int64
	OracleAddr  string
	HomeGoals   int
	AwayGoals   int
	LockTxHash  string
	SettleTxHash string
	LockedAt    int64
	SettledAt   int64
}

// SetupTestDatabase creates a database connection for testing
func SetupTestDatabase(t *testing.T) *sql.DB {
	t.Helper()

	db, err := sql.Open("postgres", DefaultDatabaseURL)
	if err != nil {
		t.Fatalf("Failed to connect to database: %v", err)
	}

	if err := db.Ping(); err != nil {
		t.Fatalf("Failed to ping database: %v", err)
	}

	return db
}

// CleanupTestData removes all test data from the database
// This should be called after each test to ensure a clean state
func CleanupTestData(db *sql.DB) error {
	queries := []string{
		"DELETE FROM keeper_tasks WHERE task_name LIKE 'TEST_%'",
		"DELETE FROM alert_logs WHERE source LIKE 'TEST_%'",
		"DELETE FROM markets WHERE event_id LIKE 'TEST_%'",
	}

	for _, query := range queries {
		if _, err := db.Exec(query); err != nil {
			return fmt.Errorf("failed to cleanup data: %w", err)
		}
	}

	return nil
}

// InsertTestMarket inserts a test market into the database
func InsertTestMarket(db *sql.DB, market *TestMarket) (int64, error) {
	query := `
		INSERT INTO markets (
			id, market_address, event_id, status,
			lock_time, match_start, match_end, oracle_address,
			created_at, created_block, tx_hash, log_index
		) VALUES (
			$1, $2, $3, $4,
			$5, $6, $7, $8,
			$9, 0, $10, 0
		)
		RETURNING id
	`

	marketID := market.Address
	createdAt := time.Now().Unix()
	txHash := "0x0000000000000000000000000000000000000000000000000000000000000000" // Placeholder

	var id int64
	err := db.QueryRow(
		query,
		marketID,
		market.Address,
		market.EventID,
		market.Status,
		market.LockTime,
		market.MatchStart,
		market.MatchEnd,
		market.OracleAddr,
		createdAt,
		txHash,
	).Scan(&id)

	if err != nil {
		return 0, fmt.Errorf("failed to insert test market: %w", err)
	}

	return id, nil
}

// GetMarketStatus returns the status of a market by address
func GetMarketStatus(db *sql.DB, marketAddr string) (string, error) {
	var status string
	err := db.QueryRow(
		"SELECT status FROM markets WHERE market_address = $1",
		marketAddr,
	).Scan(&status)

	if err != nil {
		return "", fmt.Errorf("failed to get market status: %w", err)
	}

	return status, nil
}

// GetMarket retrieves a market record by address
func GetMarket(db *sql.DB, marketAddr string) (*TestMarket, error) {
	market := &TestMarket{}

	err := db.QueryRow(`
		SELECT market_address, event_id, status, lock_time, match_start, match_end,
		       oracle_address, COALESCE(home_goals, 0), COALESCE(away_goals, 0),
		       COALESCE(lock_tx_hash, ''), COALESCE(settle_tx_hash, ''),
		       COALESCE(locked_at, 0), COALESCE(settled_at, 0)
		FROM markets
		WHERE market_address = $1
	`, marketAddr).Scan(
		&market.Address,
		&market.EventID,
		&market.Status,
		&market.LockTime,
		&market.MatchStart,
		&market.MatchEnd,
		&market.OracleAddr,
		&market.HomeGoals,
		&market.AwayGoals,
		&market.LockTxHash,
		&market.SettleTxHash,
		&market.LockedAt,
		&market.SettledAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get market: %w", err)
	}

	return market, nil
}

// WaitForDatabaseUpdate waits for a market's status to change to the expected status
// This is useful for integration tests where we need to wait for the Keeper to process a market
func WaitForDatabaseUpdate(db *sql.DB, marketAddr string, expectedStatus string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			// Get current status for error message
			currentStatus, _ := GetMarketStatus(db, marketAddr)
			return fmt.Errorf("timeout waiting for market %s to reach status %s (current: %s)", marketAddr, expectedStatus, currentStatus)
		case <-ticker.C:
			status, err := GetMarketStatus(db, marketAddr)
			if err != nil {
				// Market might not exist yet, continue waiting
				continue
			}
			if status == expectedStatus {
				return nil
			}
		}
	}
}

// WaitForFieldUpdate waits for a specific field to be set (non-null and non-empty)
func WaitForFieldUpdate(db *sql.DB, marketAddr string, fieldName string, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for market %s field %s to be set", marketAddr, fieldName)
		case <-ticker.C:
			var fieldValue sql.NullString
			query := fmt.Sprintf("SELECT %s FROM markets WHERE market_address = $1", fieldName)
			err := db.QueryRow(query, marketAddr).Scan(&fieldValue)
			if err != nil {
				continue
			}
			if fieldValue.Valid && fieldValue.String != "" && fieldValue.String != "0" {
				return nil
			}
		}
	}
}

// CountMarkets returns the number of markets with a specific status
func CountMarkets(db *sql.DB, status string) (int, error) {
	var count int
	err := db.QueryRow(
		"SELECT COUNT(*) FROM markets WHERE status = $1",
		status,
	).Scan(&count)

	if err != nil {
		return 0, fmt.Errorf("failed to count markets: %w", err)
	}

	return count, nil
}

// CreateTestMarketData creates a TestMarket struct with default values
// kickoffDelta is the number of seconds from now until kickoff
func CreateTestMarketData(marketAddr, oracleAddr string, kickoffDelta int64) *TestMarket {
	now := time.Now().Unix()
	eventID := fmt.Sprintf("TEST_EVENT_%d", now)

	return &TestMarket{
		Address:    marketAddr,
		EventID:    eventID,
		Status:     "Open",
		LockTime:   now + kickoffDelta,
		MatchStart: now + kickoffDelta + 300,    // 5 minutes after kickoff
		MatchEnd:   now + kickoffDelta + 7500,   // 2 hours after kickoff
		OracleAddr: oracleAddr,
	}
}
