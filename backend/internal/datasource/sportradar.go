package datasource

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"go.uber.org/zap"
	"golang.org/x/time/rate"
)

// MatchResult represents the result of a match
// This is defined here to avoid circular dependencies
type MatchResult struct {
	HomeGoals uint8
	AwayGoals uint8
	ExtraTime bool
	HomeWin   bool
	AwayWin   bool
	Draw      bool
}

// ResultProvider defines the interface for fetching match results
type ResultProvider interface {
	GetMatchResult(ctx context.Context, eventID string) (*MatchResult, error)
}

// SportradarClient implements ResultProvider for Sportradar API
type SportradarClient struct {
	apiKey      string
	baseURL     string
	client      *http.Client
	rateLimiter *rate.Limiter
	logger      *zap.Logger
}

// SportradarConfig holds configuration for Sportradar client
type SportradarConfig struct {
	APIKey        string
	BaseURL       string
	Timeout       time.Duration
	RequestsPerSec float64 // Rate limit: requests per second
}

// NewSportradarClient creates a new Sportradar API client
func NewSportradarClient(config SportradarConfig, logger *zap.Logger) *SportradarClient {
	// Default values
	if config.BaseURL == "" {
		config.BaseURL = "https://api.sportradar.com/soccer/trial/v4/en"
	}
	if config.Timeout == 0 {
		config.Timeout = 10 * time.Second
	}
	if config.RequestsPerSec == 0 {
		config.RequestsPerSec = 1.0 // Free tier: 1 request per second
	}

	return &SportradarClient{
		apiKey: config.APIKey,
		baseURL: config.BaseURL,
		client: &http.Client{
			Timeout: config.Timeout,
		},
		rateLimiter: rate.NewLimiter(rate.Limit(config.RequestsPerSec), 1),
		logger:      logger,
	}
}

// Sportradar API response structures
type sportEventStatus struct {
	Status       string `json:"status"`        // "closed", "live", "not_started"
	MatchStatus  string `json:"match_status"`  // "ended", "extra_time", "penalties"
	HomeScore    int    `json:"home_score"`
	AwayScore    int    `json:"away_score"`
	WinnerCode   string `json:"winner_code"`   // "home", "away", "draw"
	PeriodScores []struct {
		HomeScore int    `json:"home_score"`
		AwayScore int    `json:"away_score"`
		Type      string `json:"type"` // "regular_period", "overtime", "penalties"
	} `json:"period_scores,omitempty"`
}

type sportEvent struct {
	ID     string `json:"id"`
	Status sportEventStatus `json:"sport_event_status"`
}

type matchSummaryResponse struct {
	SportEvent sportEvent `json:"sport_event"`
}

// GetMatchResult fetches match result from Sportradar API
func (c *SportradarClient) GetMatchResult(ctx context.Context, eventID string) (*MatchResult, error) {
	startTime := time.Now()

	// Wait for rate limiter
	if err := c.rateLimiter.Wait(ctx); err != nil {
		return nil, fmt.Errorf("rate limiter error: %w", err)
	}

	c.logger.Debug("fetching match result from Sportradar",
		zap.String("event_id", eventID),
	)

	// Construct API URL
	url := fmt.Sprintf("%s/sport_events/%s/summary.json?api_key=%s",
		c.baseURL, eventID, c.apiKey)

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Add headers
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "PitchOne-Keeper/1.0")

	// Execute request
	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to execute request: %w", err)
	}
	defer resp.Body.Close()

	duration := time.Since(startTime)

	// Check HTTP status
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d: %s", resp.StatusCode, resp.Status)
	}

	// Parse JSON response
	var summary matchSummaryResponse
	if err := json.NewDecoder(resp.Body).Decode(&summary); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	c.logger.Debug("Sportradar API request completed",
		zap.String("event_id", eventID),
		zap.Duration("duration", duration),
		zap.String("status", summary.SportEvent.Status.Status),
		zap.String("match_status", summary.SportEvent.Status.MatchStatus),
	)

	// Validate match is closed
	if summary.SportEvent.Status.Status != "closed" {
		return nil, fmt.Errorf("match not yet closed, status: %s", summary.SportEvent.Status.Status)
	}

	// Convert to standard MatchResult format
	result := c.convertToMatchResult(&summary.SportEvent.Status)

	c.logger.Info("match result fetched successfully",
		zap.String("event_id", eventID),
		zap.Uint8("home_goals", result.HomeGoals),
		zap.Uint8("away_goals", result.AwayGoals),
		zap.Bool("extra_time", result.ExtraTime),
		zap.Duration("api_duration", duration),
	)

	return result, nil
}

// convertToMatchResult converts Sportradar response to standard MatchResult
func (c *SportradarClient) convertToMatchResult(status *sportEventStatus) *MatchResult {
	result := &MatchResult{
		HomeGoals: uint8(status.HomeScore),
		AwayGoals: uint8(status.AwayScore),
		ExtraTime: status.MatchStatus == "extra_time" || status.MatchStatus == "penalties",
	}

	// Determine winner
	switch status.WinnerCode {
	case "home":
		result.HomeWin = true
		result.AwayWin = false
		result.Draw = false
	case "away":
		result.HomeWin = false
		result.AwayWin = true
		result.Draw = false
	case "draw":
		result.HomeWin = false
		result.AwayWin = false
		result.Draw = true
	default:
		// Fallback: determine by score
		if status.HomeScore > status.AwayScore {
			result.HomeWin = true
		} else if status.AwayScore > status.HomeScore {
			result.AwayWin = true
		} else {
			result.Draw = true
		}
	}

	return result
}

// MockResultProvider implements ResultProvider for testing
type MockResultProvider struct {
	Results map[string]*MatchResult
	Delay   time.Duration
	Error   error
}

// NewMockResultProvider creates a mock result provider
func NewMockResultProvider() *MockResultProvider {
	return &MockResultProvider{
		Results: make(map[string]*MatchResult),
		Delay:   0,
		Error:   nil,
	}
}

// GetMatchResult returns mock match results
func (m *MockResultProvider) GetMatchResult(ctx context.Context, eventID string) (*MatchResult, error) {
	// Simulate API delay
	if m.Delay > 0 {
		select {
		case <-time.After(m.Delay):
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	// Return configured error if any
	if m.Error != nil {
		return nil, m.Error
	}

	// Return configured result
	if result, ok := m.Results[eventID]; ok {
		return result, nil
	}

	// Default mock result
	return &MatchResult{
		HomeGoals: 2,
		AwayGoals: 1,
		ExtraTime: false,
		HomeWin:   true,
		AwayWin:   false,
		Draw:      false,
	}, nil
}

// AddResult adds a mock result for a specific event
func (m *MockResultProvider) AddResult(eventID string, result *MatchResult) {
	m.Results[eventID] = result
}

// SetError sets an error to be returned by GetMatchResult
func (m *MockResultProvider) SetError(err error) {
	m.Error = err
}

// SetDelay sets a delay to simulate slow API responses
func (m *MockResultProvider) SetDelay(delay time.Duration) {
	m.Delay = delay
}
