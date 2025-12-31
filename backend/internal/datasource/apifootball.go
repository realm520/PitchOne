package datasource

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"strings"
	"time"

	"go.uber.org/zap"
	"golang.org/x/time/rate"
)

// Fixture represents a match from API-Football
type Fixture struct {
	FixtureID    int64
	LeagueID     int
	LeagueName   string
	LeagueCode   string
	Season       int
	RoundNumber  int
	HomeTeamID   int
	HomeTeamName string
	HomeTeamCode string
	AwayTeamID   int
	AwayTeamName string
	AwayTeamCode string
	KickoffTime  int64
	Status       string
	HomeScore    *int
	AwayScore    *int
	VenueName    string
	MatchIDWDL   string
	MatchIDOU    string
}

// FixturesProvider defines the interface for fetching fixtures
type FixturesProvider interface {
	GetFixtures(ctx context.Context, leagueID, season int) ([]Fixture, error)
}

// APIFootballClient implements FixturesProvider for API-Football
type APIFootballClient struct {
	apiKey      string
	baseURL     string
	httpClient  *http.Client
	rateLimiter *rate.Limiter
	logger      *zap.Logger
	teamCodeMap map[string]string
	leagueCodeMap map[int]string
}

// APIFootballConfig holds configuration for API-Football client
type APIFootballConfig struct {
	APIKey         string
	BaseURL        string
	Timeout        time.Duration
	RequestsPerSec float64
}

// NewAPIFootballClient creates a new API-Football client
func NewAPIFootballClient(config APIFootballConfig, logger *zap.Logger) *APIFootballClient {
	if config.BaseURL == "" {
		config.BaseURL = "https://v3.football.api-sports.io"
	}
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Second
	}
	if config.RequestsPerSec == 0 {
		config.RequestsPerSec = 0.15 // Conservative: ~1 req per 6-7 seconds
	}

	return &APIFootballClient{
		apiKey: config.APIKey,
		baseURL: config.BaseURL,
		httpClient: &http.Client{
			Timeout: config.Timeout,
		},
		rateLimiter:   rate.NewLimiter(rate.Limit(config.RequestsPerSec), 1),
		logger:        logger,
		teamCodeMap:   defaultTeamCodeMap(),
		leagueCodeMap: defaultLeagueCodeMap(),
	}
}

// API-Football response structures
type apiFootballResponse struct {
	Get      string          `json:"get"`
	Errors   json.RawMessage `json:"errors"`
	Results  int             `json:"results"`
	Response []apiFixture    `json:"response"`
}

type apiFixture struct {
	Fixture struct {
		ID        int64  `json:"id"`
		Timestamp int64  `json:"timestamp"`
		Venue     struct {
			Name string `json:"name"`
			City string `json:"city"`
		} `json:"venue"`
		Status struct {
			Short string `json:"short"`
		} `json:"status"`
	} `json:"fixture"`
	League struct {
		ID     int    `json:"id"`
		Name   string `json:"name"`
		Round  string `json:"round"`
		Season int    `json:"season"`
	} `json:"league"`
	Teams struct {
		Home struct {
			ID   int    `json:"id"`
			Name string `json:"name"`
		} `json:"home"`
		Away struct {
			ID   int    `json:"id"`
			Name string `json:"name"`
		} `json:"away"`
	} `json:"teams"`
	Goals struct {
		Home *int `json:"home"`
		Away *int `json:"away"`
	} `json:"goals"`
}

// GetFixtures fetches fixtures for a league and season
func (c *APIFootballClient) GetFixtures(ctx context.Context, leagueID, season int) ([]Fixture, error) {
	// Wait for rate limiter
	if err := c.rateLimiter.Wait(ctx); err != nil {
		return nil, fmt.Errorf("rate limiter error: %w", err)
	}

	c.logger.Debug("fetching fixtures from API-Football",
		zap.Int("league_id", leagueID),
		zap.Int("season", season),
	)

	// Construct API URL
	url := fmt.Sprintf("%s/fixtures?league=%d&season=%d", c.baseURL, leagueID, season)

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Add headers
	req.Header.Set("x-rapidapi-host", "v3.football.api-sports.io")
	req.Header.Set("x-rapidapi-key", c.apiKey)

	startTime := time.Now()

	// Execute request
	resp, err := c.httpClient.Do(req)
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
	var apiResp apiFootballResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Check for API errors
	if len(apiResp.Errors) > 2 && string(apiResp.Errors) != "[]" && string(apiResp.Errors) != "{}" {
		return nil, fmt.Errorf("API returned errors: %s", string(apiResp.Errors))
	}

	c.logger.Info("API-Football request completed",
		zap.Int("league_id", leagueID),
		zap.Int("season", season),
		zap.Int("results", apiResp.Results),
		zap.Duration("duration", duration),
	)

	// Convert to internal Fixture format
	leagueCode := c.getLeagueCode(leagueID)
	fixtures := make([]Fixture, 0, len(apiResp.Response))

	for _, af := range apiResp.Response {
		homeCode := c.getTeamCode(af.Teams.Home.Name)
		awayCode := c.getTeamCode(af.Teams.Away.Name)
		roundNum := extractRoundNumber(af.League.Round)

		fixture := Fixture{
			FixtureID:    af.Fixture.ID,
			LeagueID:     af.League.ID,
			LeagueName:   af.League.Name,
			LeagueCode:   leagueCode,
			Season:       af.League.Season,
			RoundNumber:  roundNum,
			HomeTeamID:   af.Teams.Home.ID,
			HomeTeamName: af.Teams.Home.Name,
			HomeTeamCode: homeCode,
			AwayTeamID:   af.Teams.Away.ID,
			AwayTeamName: af.Teams.Away.Name,
			AwayTeamCode: awayCode,
			KickoffTime:  af.Fixture.Timestamp,
			Status:       af.Fixture.Status.Short,
			HomeScore:    af.Goals.Home,
			AwayScore:    af.Goals.Away,
			VenueName:    af.Fixture.Venue.Name,
			MatchIDWDL:   fmt.Sprintf("%s_%d_R%d_%s_vs_%s_WDL", leagueCode, season, roundNum, homeCode, awayCode),
			MatchIDOU:    fmt.Sprintf("%s_%d_R%d_%s_vs_%s_OU", leagueCode, season, roundNum, homeCode, awayCode),
		}
		fixtures = append(fixtures, fixture)
	}

	return fixtures, nil
}

// getTeamCode returns the team code for a team name
func (c *APIFootballClient) getTeamCode(teamName string) string {
	if code, ok := c.teamCodeMap[teamName]; ok {
		return code
	}
	// Fallback: remove non-letters and take first 3 chars uppercase
	re := regexp.MustCompile(`[^a-zA-Z]`)
	cleaned := re.ReplaceAllString(teamName, "")
	if len(cleaned) > 3 {
		cleaned = cleaned[:3]
	}
	return strings.ToUpper(cleaned)
}

// getLeagueCode returns the league code for a league ID
func (c *APIFootballClient) getLeagueCode(leagueID int) string {
	if code, ok := c.leagueCodeMap[leagueID]; ok {
		return code
	}
	return fmt.Sprintf("L%d", leagueID)
}

// extractRoundNumber extracts the round number from a round string
func extractRoundNumber(round string) int {
	re := regexp.MustCompile(`(\d+)`)
	matches := re.FindStringSubmatch(round)
	if len(matches) > 1 {
		var num int
		fmt.Sscanf(matches[1], "%d", &num)
		return num
	}
	return 0
}

// defaultTeamCodeMap returns the default team code mapping
func defaultTeamCodeMap() map[string]string {
	return map[string]string{
		// Serie A (Italy)
		"AC Milan":       "MIL",
		"Inter":          "INT",
		"Juventus":       "JUV",
		"Napoli":         "NAP",
		"AS Roma":        "ROM",
		"Lazio":          "LAZ",
		"Atalanta":       "ATA",
		"Fiorentina":     "FIO",
		"Bologna":        "BOL",
		"Torino":         "TOR",
		"Udinese":        "UDI",
		"Sassuolo":       "SAS",
		"Empoli":         "EMP",
		"Cagliari":       "CAG",
		"Verona":         "VER",
		"Hellas Verona":  "VER",
		"Lecce":          "LEC",
		"Genoa":          "GEN",
		"Monza":          "MON",
		"Salernitana":    "SAL",
		"Frosinone":      "FRO",
		"Parma":          "PAR",
		"Venezia":        "VEN",
		"Como":           "COM",

		// Premier League (England)
		"Manchester United": "MUN",
		"Manchester City":   "MCI",
		"Liverpool":         "LIV",
		"Arsenal":           "ARS",
		"Chelsea":           "CHE",
		"Tottenham":         "TOT",
		"Newcastle":         "NEW",
		"Aston Villa":       "AVL",
		"Brighton":          "BHA",
		"West Ham":          "WHU",
		"Everton":           "EVE",
		"Nottingham Forest": "NFO",
		"Fulham":            "FUL",
		"Brentford":         "BRE",
		"Crystal Palace":    "CRY",
		"Bournemouth":       "BOU",
		"Wolves":            "WOL",
		"Wolverhampton":     "WOL",
		"Leicester":         "LEI",
		"Southampton":       "SOU",
		"Ipswich":           "IPS",

		// La Liga (Spain)
		"Real Madrid":     "RMA",
		"Barcelona":       "BAR",
		"Atletico Madrid": "ATM",
		"Sevilla":         "SEV",
		"Real Sociedad":   "RSO",
		"Real Betis":      "BET",
		"Villarreal":      "VIL",
		"Athletic Club":   "ATH",
		"Valencia":        "VAL",
		"Osasuna":         "OSA",
		"Celta Vigo":      "CEL",
		"Rayo Vallecano":  "RAY",
		"Mallorca":        "MLL",
		"Getafe":          "GET",
		"Girona":          "GIR",
		"Las Palmas":      "LPA",
		"Alaves":          "ALA",
		"Cadiz":           "CAD",
		"Granada":         "GRA",
		"Almeria":         "ALM",

		// Bundesliga (Germany)
		"Bayern Munich":      "BAY",
		"Borussia Dortmund":  "BVB",
		"RB Leipzig":         "RBL",
		"Bayer Leverkusen":   "LEV",
		"Eintracht Frankfurt": "SGE",
		"Wolfsburg":          "WOB",
		"Borussia Monchengladbach": "BMG",
		"Union Berlin":       "UNB",
		"Freiburg":           "SCF",
		"Hoffenheim":         "TSG",
		"Mainz":              "M05",
		"Augsburg":           "FCA",
		"Werder Bremen":      "SVW",
		"VfB Stuttgart":      "VFB",
		"Cologne":            "KOE",
		"Heidenheim":         "HDH",
		"Darmstadt":          "D98",
		"Bochum":             "BOC",

		// Ligue 1 (France)
		"Paris Saint Germain": "PSG",
		"PSG":                 "PSG",
		"Monaco":              "ASM",
		"Marseille":           "OM",
		"Lyon":                "OL",
		"Lille":               "LOS",
		"Nice":                "OGC",
		"Rennes":              "REN",
		"Lens":                "RCL",
		"Strasbourg":          "RCS",
		"Nantes":              "NAN",
		"Montpellier":         "MHS",
		"Toulouse":            "TFC",
		"Reims":               "SDR",
		"Brest":               "SB29",
		"Le Havre":            "HAC",
		"Lorient":             "FCL",
		"Clermont":            "CF63",
		"Metz":                "FCM",
	}
}

// defaultLeagueCodeMap returns the default league code mapping
func defaultLeagueCodeMap() map[int]string {
	return map[int]string{
		39:  "EPL",    // Premier League
		140: "LaLiga", // La Liga
		78:  "BL",     // Bundesliga
		135: "SerieA", // Serie A
		61:  "L1",     // Ligue 1
		2:   "UCL",    // UEFA Champions League
		3:   "UEL",    // UEFA Europa League
	}
}
