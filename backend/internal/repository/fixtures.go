package repository

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/pitchone/sportsbook/internal/datasource"
)

// FixturesRepository handles database operations for fixtures
type FixturesRepository struct {
	db *sql.DB
}

// NewFixturesRepository creates a new FixturesRepository
func NewFixturesRepository(db *sql.DB) *FixturesRepository {
	return &FixturesRepository{db: db}
}

// UpsertFixtures inserts or updates fixtures in bulk
// Returns the number of inserted and updated records
func (r *FixturesRepository) UpsertFixtures(ctx context.Context, fixtures []datasource.Fixture) (int, int, error) {
	if len(fixtures) == 0 {
		return 0, 0, nil
	}

	// Build bulk insert query with ON CONFLICT
	query := `
		INSERT INTO fixtures (
			fixture_id, league_id, league_name, league_code, season, round_number,
			home_team_id, home_team_name, home_team_code,
			away_team_id, away_team_name, away_team_code,
			kickoff_time, status, home_score, away_score, venue_name,
			match_id_wdl, match_id_ou, updated_at
		) VALUES `

	var values []string
	var args []interface{}
	argIdx := 1

	for _, f := range fixtures {
		placeholders := make([]string, 20)
		for i := 0; i < 20; i++ {
			placeholders[i] = fmt.Sprintf("$%d", argIdx+i)
		}
		values = append(values, "("+strings.Join(placeholders, ",")+")")

		args = append(args,
			f.FixtureID, f.LeagueID, f.LeagueName, f.LeagueCode, f.Season, f.RoundNumber,
			f.HomeTeamID, f.HomeTeamName, f.HomeTeamCode,
			f.AwayTeamID, f.AwayTeamName, f.AwayTeamCode,
			f.KickoffTime, f.Status, f.HomeScore, f.AwayScore, f.VenueName,
			f.MatchIDWDL, f.MatchIDOU, time.Now(),
		)
		argIdx += 20
	}

	query += strings.Join(values, ",")
	query += `
		ON CONFLICT (fixture_id) DO UPDATE SET
			status = EXCLUDED.status,
			home_score = EXCLUDED.home_score,
			away_score = EXCLUDED.away_score,
			updated_at = EXCLUDED.updated_at
		RETURNING (xmax = 0) AS inserted`

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to upsert fixtures: %w", err)
	}
	defer rows.Close()

	var inserted, updated int
	for rows.Next() {
		var wasInserted bool
		if err := rows.Scan(&wasInserted); err != nil {
			return 0, 0, fmt.Errorf("failed to scan result: %w", err)
		}
		if wasInserted {
			inserted++
		} else {
			updated++
		}
	}

	if err := rows.Err(); err != nil {
		return 0, 0, fmt.Errorf("rows iteration error: %w", err)
	}

	return inserted, updated, nil
}

// GetPendingForMarketCreation returns fixtures that need market creation
func (r *FixturesRepository) GetPendingForMarketCreation(ctx context.Context, marketType string, hoursAhead int) ([]datasource.Fixture, error) {
	now := time.Now().Unix()
	deadline := now + int64(hoursAhead*3600)

	var marketCreatedCol string
	switch marketType {
	case "WDL":
		marketCreatedCol = "market_created_wdl"
	case "OU":
		marketCreatedCol = "market_created_ou"
	default:
		return nil, fmt.Errorf("invalid market type: %s", marketType)
	}

	query := fmt.Sprintf(`
		SELECT fixture_id, league_id, league_name, league_code, season, round_number,
			   home_team_id, home_team_name, home_team_code,
			   away_team_id, away_team_name, away_team_code,
			   kickoff_time, status, home_score, away_score, venue_name,
			   match_id_wdl, match_id_ou
		FROM fixtures
		WHERE status = 'NS'
		  AND NOT %s
		  AND kickoff_time > $1
		  AND kickoff_time <= $2
		ORDER BY kickoff_time ASC
		LIMIT 100
	`, marketCreatedCol)

	rows, err := r.db.QueryContext(ctx, query, now, deadline)
	if err != nil {
		return nil, fmt.Errorf("failed to query pending fixtures: %w", err)
	}
	defer rows.Close()

	var fixtures []datasource.Fixture
	for rows.Next() {
		var f datasource.Fixture
		if err := rows.Scan(
			&f.FixtureID, &f.LeagueID, &f.LeagueName, &f.LeagueCode, &f.Season, &f.RoundNumber,
			&f.HomeTeamID, &f.HomeTeamName, &f.HomeTeamCode,
			&f.AwayTeamID, &f.AwayTeamName, &f.AwayTeamCode,
			&f.KickoffTime, &f.Status, &f.HomeScore, &f.AwayScore, &f.VenueName,
			&f.MatchIDWDL, &f.MatchIDOU,
		); err != nil {
			return nil, fmt.Errorf("failed to scan fixture: %w", err)
		}
		fixtures = append(fixtures, f)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration error: %w", err)
	}

	return fixtures, nil
}

// MarkMarketCreated marks a fixture's market as created
func (r *FixturesRepository) MarkMarketCreated(ctx context.Context, fixtureID int64, marketType string) error {
	var query string
	switch marketType {
	case "WDL":
		query = `UPDATE fixtures SET market_created_wdl = TRUE, updated_at = $2 WHERE fixture_id = $1`
	case "OU":
		query = `UPDATE fixtures SET market_created_ou = TRUE, updated_at = $2 WHERE fixture_id = $1`
	default:
		return fmt.Errorf("invalid market type: %s", marketType)
	}

	result, err := r.db.ExecContext(ctx, query, fixtureID, time.Now())
	if err != nil {
		return fmt.Errorf("failed to update fixture: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("fixture not found: %d", fixtureID)
	}

	return nil
}

// GetFixtureByID returns a fixture by its API fixture ID
func (r *FixturesRepository) GetFixtureByID(ctx context.Context, fixtureID int64) (*datasource.Fixture, error) {
	query := `
		SELECT fixture_id, league_id, league_name, league_code, season, round_number,
			   home_team_id, home_team_name, home_team_code,
			   away_team_id, away_team_name, away_team_code,
			   kickoff_time, status, home_score, away_score, venue_name,
			   match_id_wdl, match_id_ou
		FROM fixtures
		WHERE fixture_id = $1
	`

	var f datasource.Fixture
	err := r.db.QueryRowContext(ctx, query, fixtureID).Scan(
		&f.FixtureID, &f.LeagueID, &f.LeagueName, &f.LeagueCode, &f.Season, &f.RoundNumber,
		&f.HomeTeamID, &f.HomeTeamName, &f.HomeTeamCode,
		&f.AwayTeamID, &f.AwayTeamName, &f.AwayTeamCode,
		&f.KickoffTime, &f.Status, &f.HomeScore, &f.AwayScore, &f.VenueName,
		&f.MatchIDWDL, &f.MatchIDOU,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to get fixture: %w", err)
	}

	return &f, nil
}

// GetUpcomingFixtures returns upcoming fixtures within a time window
func (r *FixturesRepository) GetUpcomingFixtures(ctx context.Context, hoursAhead int) ([]datasource.Fixture, error) {
	now := time.Now().Unix()
	deadline := now + int64(hoursAhead*3600)

	query := `
		SELECT fixture_id, league_id, league_name, league_code, season, round_number,
			   home_team_id, home_team_name, home_team_code,
			   away_team_id, away_team_name, away_team_code,
			   kickoff_time, status, home_score, away_score, venue_name,
			   match_id_wdl, match_id_ou
		FROM fixtures
		WHERE status = 'NS'
		  AND kickoff_time > $1
		  AND kickoff_time <= $2
		ORDER BY kickoff_time ASC
	`

	rows, err := r.db.QueryContext(ctx, query, now, deadline)
	if err != nil {
		return nil, fmt.Errorf("failed to query upcoming fixtures: %w", err)
	}
	defer rows.Close()

	var fixtures []datasource.Fixture
	for rows.Next() {
		var f datasource.Fixture
		if err := rows.Scan(
			&f.FixtureID, &f.LeagueID, &f.LeagueName, &f.LeagueCode, &f.Season, &f.RoundNumber,
			&f.HomeTeamID, &f.HomeTeamName, &f.HomeTeamCode,
			&f.AwayTeamID, &f.AwayTeamName, &f.AwayTeamCode,
			&f.KickoffTime, &f.Status, &f.HomeScore, &f.AwayScore, &f.VenueName,
			&f.MatchIDWDL, &f.MatchIDOU,
		); err != nil {
			return nil, fmt.Errorf("failed to scan fixture: %w", err)
		}
		fixtures = append(fixtures, f)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("rows iteration error: %w", err)
	}

	return fixtures, nil
}

// CountFixturesByLeague returns the count of fixtures by league
func (r *FixturesRepository) CountFixturesByLeague(ctx context.Context, leagueID, season int) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM fixtures WHERE league_id = $1 AND season = $2`
	err := r.db.QueryRowContext(ctx, query, leagueID, season).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count fixtures: %w", err)
	}
	return count, nil
}
