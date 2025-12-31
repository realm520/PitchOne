package keeper

import (
	"context"
	"fmt"
	"time"

	"github.com/pitchone/sportsbook/internal/datasource"
	"github.com/pitchone/sportsbook/internal/repository"
	"go.uber.org/zap"
)

// FixturesTask fetches fixtures from API-Football and stores them in the database
type FixturesTask struct {
	keeper    *Keeper
	apiClient *datasource.APIFootballClient
	repo      *repository.FixturesRepository
	config    APIFootballConfig
}

// NewFixturesTask creates a new FixturesTask
func NewFixturesTask(
	keeper *Keeper,
	apiClient *datasource.APIFootballClient,
	repo *repository.FixturesRepository,
	config APIFootballConfig,
) *FixturesTask {
	return &FixturesTask{
		keeper:    keeper,
		apiClient: apiClient,
		repo:      repo,
		config:    config,
	}
}

// Execute implements the Task interface
func (t *FixturesTask) Execute(ctx context.Context) error {
	t.keeper.logger.Info("executing fixtures fetch task",
		zap.Int("leagues_count", len(t.config.Leagues)),
		zap.Int("days_ahead", t.config.DaysAhead),
	)

	startTime := time.Now()
	var totalInserted, totalUpdated int
	var failedLeagues []string

	for _, league := range t.config.Leagues {
		select {
		case <-ctx.Done():
			t.keeper.logger.Warn("fixtures task cancelled")
			return ctx.Err()
		default:
		}

		inserted, updated, err := t.fetchLeagueFixtures(ctx, league)
		if err != nil {
			t.keeper.logger.Error("failed to fetch league fixtures",
				zap.Int("league_id", league.ID),
				zap.String("league_code", league.Code),
				zap.Error(err),
			)
			failedLeagues = append(failedLeagues, league.Code)
			continue
		}

		totalInserted += inserted
		totalUpdated += updated

		t.keeper.logger.Info("league fixtures fetched",
			zap.Int("league_id", league.ID),
			zap.String("league_code", league.Code),
			zap.Int("season", league.Season),
			zap.Int("inserted", inserted),
			zap.Int("updated", updated),
		)
	}

	duration := time.Since(startTime)

	t.keeper.logger.Info("fixtures fetch task completed",
		zap.Duration("duration", duration),
		zap.Int("total_inserted", totalInserted),
		zap.Int("total_updated", totalUpdated),
		zap.Int("failed_leagues", len(failedLeagues)),
	)

	if len(failedLeagues) > 0 {
		return fmt.Errorf("failed to fetch %d leagues: %v", len(failedLeagues), failedLeagues)
	}

	return nil
}

// fetchLeagueFixtures fetches fixtures for a single league
func (t *FixturesTask) fetchLeagueFixtures(ctx context.Context, league LeagueConfig) (int, int, error) {
	// Fetch from API
	fixtures, err := t.apiClient.GetFixtures(ctx, league.ID, league.Season)
	if err != nil {
		return 0, 0, fmt.Errorf("API request failed: %w", err)
	}

	t.keeper.logger.Debug("API returned fixtures",
		zap.Int("league_id", league.ID),
		zap.Int("total", len(fixtures)),
	)

	// Filter to upcoming fixtures only
	now := time.Now().Unix()
	deadline := now + int64(t.config.DaysAhead*24*3600)

	var filtered []datasource.Fixture
	for _, f := range fixtures {
		// Only include future fixtures that haven't finished
		if f.KickoffTime > now && f.KickoffTime <= deadline {
			if f.Status != "FT" && f.Status != "AET" && f.Status != "PEN" {
				filtered = append(filtered, f)
			}
		}
	}

	t.keeper.logger.Debug("filtered to upcoming fixtures",
		zap.Int("league_id", league.ID),
		zap.Int("filtered", len(filtered)),
	)

	if len(filtered) == 0 {
		return 0, 0, nil
	}

	// Upsert to database
	inserted, updated, err := t.repo.UpsertFixtures(ctx, filtered)
	if err != nil {
		return 0, 0, fmt.Errorf("database upsert failed: %w", err)
	}

	return inserted, updated, nil
}
