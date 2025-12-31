-- PitchOne Database Schema (V1)
-- Consolidated initialization script
-- Date: 2025-12-31

-- ============================================
-- Core Tables
-- ============================================

-- Markets table
CREATE TABLE IF NOT EXISTS markets (
    id VARCHAR(66) PRIMARY KEY,
    template_id VARCHAR(66) NOT NULL,
    match_id VARCHAR(100) NOT NULL,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    kickoff_time BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    resolved_at BIGINT,
    finalized_at BIGINT,
    winner_outcome INT,
    result_hash BYTEA,
    created_at BIGINT NOT NULL,
    created_block BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,

    -- Keeper service fields
    market_address VARCHAR(42),
    event_id VARCHAR(100),
    oracle_address VARCHAR(42),
    lock_time BIGINT,
    match_start BIGINT,
    match_end BIGINT,
    lock_tx_hash VARCHAR(66),
    settle_tx_hash VARCHAR(66),
    locked_at BIGINT,
    settled_at BIGINT,
    home_goals SMALLINT,
    away_goals SMALLINT,
    updated_at BIGINT,
    version VARCHAR(10) DEFAULT 'v2',
    market_params JSONB DEFAULT '{}'::jsonb,

    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_markets_status ON markets(status);
CREATE INDEX idx_markets_kickoff ON markets(kickoff_time);
CREATE INDEX idx_markets_created_block ON markets(created_block);
CREATE INDEX idx_markets_market_address ON markets(market_address);
CREATE INDEX idx_markets_lock_time ON markets(lock_time) WHERE status = 'Open';
CREATE INDEX idx_markets_match_end ON markets(match_end) WHERE status = 'Locked';
CREATE INDEX idx_markets_oracle ON markets(oracle_address);
CREATE INDEX idx_markets_version ON markets(version);
CREATE INDEX idx_markets_market_params ON markets USING GIN (market_params);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    outcome INT NOT NULL,
    stake NUMERIC(78, 0) NOT NULL,
    shares NUMERIC(78, 0) NOT NULL,
    fee NUMERIC(78, 0) NOT NULL,
    referrer VARCHAR(42),
    campaign_id VARCHAR(66),
    timestamp BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_orders_market ON orders(market_id);
CREATE INDEX idx_orders_user ON orders(user_address);
CREATE INDEX idx_orders_timestamp ON orders(timestamp DESC);
CREATE INDEX idx_orders_block ON orders(block_number);
CREATE INDEX idx_orders_referrer ON orders(referrer) WHERE referrer IS NOT NULL;

-- Positions table
CREATE TABLE IF NOT EXISTS positions (
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    outcome INT NOT NULL,
    balance NUMERIC(78, 0) NOT NULL DEFAULT 0,
    last_updated BIGINT NOT NULL,
    last_updated_block BIGINT NOT NULL,
    PRIMARY KEY (market_id, user_address, outcome)
);

CREATE INDEX idx_positions_user ON positions(user_address);
CREATE INDEX idx_positions_market ON positions(market_id);
CREATE INDEX idx_positions_balance ON positions(balance) WHERE balance > 0;

-- Payouts table
CREATE TABLE IF NOT EXISTS payouts (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    amount NUMERIC(78, 0) NOT NULL,
    timestamp BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_payouts_market ON payouts(market_id);
CREATE INDEX idx_payouts_user ON payouts(user_address);
CREATE INDEX idx_payouts_timestamp ON payouts(timestamp DESC);

-- ============================================
-- Indexer & Keeper Tables
-- ============================================

-- Indexer state
CREATE TABLE IF NOT EXISTS indexer_state (
    key VARCHAR(50) PRIMARY KEY,
    value BIGINT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO indexer_state (key, value) VALUES ('last_processed_block', 0) ON CONFLICT DO NOTHING;

-- Keeper tasks
CREATE TABLE IF NOT EXISTS keeper_tasks (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    task_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    scheduled_at BIGINT NOT NULL,
    executed_at BIGINT,
    tx_hash VARCHAR(66),
    error_message TEXT,
    retry_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_keeper_tasks_market ON keeper_tasks(market_id);
CREATE INDEX idx_keeper_tasks_status ON keeper_tasks(status);
CREATE INDEX idx_keeper_tasks_scheduled ON keeper_tasks(scheduled_at) WHERE status = 'pending';

-- Alert logs
CREATE TABLE IF NOT EXISTS alert_logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    context JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alert_logs_level ON alert_logs(level);
CREATE INDEX idx_alert_logs_created ON alert_logs(created_at DESC);

-- ============================================
-- Rewards Tables
-- ============================================

CREATE TABLE IF NOT EXISTS reward_distributions (
    week BIGINT PRIMARY KEY,
    merkle_root VARCHAR(66) NOT NULL,
    total_amount NUMERIC(78, 0) NOT NULL,
    recipients INT NOT NULL,
    scale_bps INT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT,
    tx_hash VARCHAR(66),
    block_number BIGINT,
    published_at BIGINT,
    status VARCHAR(20) DEFAULT 'pending',
    CONSTRAINT valid_scale CHECK (scale_bps >= 1000 AND scale_bps <= 10000),
    CONSTRAINT valid_recipients CHECK (recipients > 0)
);

CREATE INDEX idx_reward_distributions_status ON reward_distributions(status);
CREATE INDEX idx_reward_distributions_created ON reward_distributions(created_at DESC);

CREATE TABLE IF NOT EXISTS reward_entries (
    id SERIAL PRIMARY KEY,
    week BIGINT NOT NULL REFERENCES reward_distributions(week),
    user_address VARCHAR(42) NOT NULL,
    amount NUMERIC(78, 0) NOT NULL,
    reward_type VARCHAR(20) NOT NULL,
    created_at BIGINT NOT NULL,
    UNIQUE(week, user_address, reward_type)
);

CREATE INDEX idx_reward_entries_week ON reward_entries(week);
CREATE INDEX idx_reward_entries_user ON reward_entries(user_address);
CREATE INDEX idx_reward_entries_type ON reward_entries(reward_type);

CREATE TABLE IF NOT EXISTS merkle_proofs (
    week BIGINT NOT NULL REFERENCES reward_distributions(week),
    user_address VARCHAR(42) NOT NULL,
    proof JSONB NOT NULL,
    created_at BIGINT NOT NULL,
    PRIMARY KEY (week, user_address)
);

CREATE INDEX idx_merkle_proofs_user ON merkle_proofs(user_address);

-- ============================================
-- Campaign & Quest Tables
-- ============================================

CREATE TABLE IF NOT EXISTS campaigns (
    id BIGINT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    campaign_type VARCHAR(50) NOT NULL,
    budget NUMERIC(78, 0) NOT NULL,
    spent NUMERIC(78, 0) DEFAULT 0,
    start_time BIGINT NOT NULL,
    end_time BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    creator VARCHAR(42) NOT NULL,
    created_at BIGINT NOT NULL,
    created_block BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    updated_at BIGINT,
    CONSTRAINT valid_budget CHECK (budget > 0),
    CONSTRAINT valid_time CHECK (end_time > start_time),
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_time ON campaigns(start_time, end_time);
CREATE INDEX idx_campaigns_creator ON campaigns(creator);

CREATE TABLE IF NOT EXISTS campaign_participations (
    id SERIAL PRIMARY KEY,
    campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    participant_address VARCHAR(42) NOT NULL,
    action VARCHAR(50) NOT NULL,
    reward_amount NUMERIC(78, 0) NOT NULL,
    metadata JSONB,
    participated_at BIGINT NOT NULL,
    reward_claimed BOOLEAN DEFAULT false,
    claimed_at BIGINT,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_campaign_participations_campaign ON campaign_participations(campaign_id);
CREATE INDEX idx_campaign_participations_participant ON campaign_participations(participant_address);
CREATE INDEX idx_campaign_participations_time ON campaign_participations(participated_at DESC);
CREATE INDEX idx_campaign_participations_claimed ON campaign_participations(reward_claimed) WHERE reward_claimed = false;

CREATE TABLE IF NOT EXISTS quests (
    id BIGINT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    quest_type VARCHAR(50) NOT NULL,
    target BIGINT NOT NULL,
    reward_amount NUMERIC(78, 0) NOT NULL,
    max_completions INT DEFAULT 0,
    current_completions INT DEFAULT 0,
    start_time BIGINT NOT NULL,
    end_time BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    creator VARCHAR(42) NOT NULL,
    created_at BIGINT NOT NULL,
    created_block BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    updated_at BIGINT,
    CONSTRAINT valid_reward CHECK (reward_amount > 0),
    CONSTRAINT valid_quest_time CHECK (end_time > start_time),
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_quests_status ON quests(status);
CREATE INDEX idx_quests_type ON quests(quest_type);
CREATE INDEX idx_quests_time ON quests(start_time, end_time);

CREATE TABLE IF NOT EXISTS user_quest_progress (
    id SERIAL PRIMARY KEY,
    quest_id BIGINT NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    current_progress BIGINT DEFAULT 0,
    completed BOOLEAN DEFAULT false,
    completed_at BIGINT,
    reward_claimed BOOLEAN DEFAULT false,
    claimed_at BIGINT,
    last_updated BIGINT NOT NULL,
    UNIQUE(quest_id, user_address)
);

CREATE INDEX idx_user_quest_progress_user ON user_quest_progress(user_address);
CREATE INDEX idx_user_quest_progress_quest ON user_quest_progress(quest_id);
CREATE INDEX idx_user_quest_progress_completed ON user_quest_progress(completed) WHERE completed = true;
CREATE INDEX idx_user_quest_progress_unclaimed ON user_quest_progress(reward_claimed) WHERE reward_claimed = false;

CREATE TABLE IF NOT EXISTS quest_completions (
    id SERIAL PRIMARY KEY,
    quest_id BIGINT NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    reward_amount NUMERIC(78, 0) NOT NULL,
    completed_at BIGINT NOT NULL,
    reward_claimed BOOLEAN DEFAULT false,
    claimed_at BIGINT,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_quest_completions_quest ON quest_completions(quest_id);
CREATE INDEX idx_quest_completions_user ON quest_completions(user_address);
CREATE INDEX idx_quest_completions_time ON quest_completions(completed_at DESC);
CREATE INDEX idx_quest_completions_claimed ON quest_completions(reward_claimed) WHERE reward_claimed = false;

-- Referrals
CREATE TABLE IF NOT EXISTS referrals (
    id SERIAL PRIMARY KEY,
    referrer VARCHAR(42) NOT NULL,
    referee VARCHAR(42) NOT NULL,
    bound_at BIGINT NOT NULL,
    referral_code VARCHAR(50),
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(referee),
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_referrals_referrer ON referrals(referrer);
CREATE INDEX idx_referrals_referee ON referrals(referee);
CREATE INDEX idx_referrals_time ON referrals(bound_at DESC);

CREATE TABLE IF NOT EXISTS referral_earnings (
    referrer VARCHAR(42) PRIMARY KEY,
    total_referrals INT DEFAULT 0,
    total_earnings NUMERIC(78, 0) DEFAULT 0,
    last_updated BIGINT NOT NULL
);

CREATE INDEX idx_referral_earnings_total ON referral_earnings(total_earnings DESC);

-- ============================================
-- Parlay & PlayerProps Tables
-- ============================================

CREATE TABLE IF NOT EXISTS parlays (
    id BIGINT PRIMARY KEY,
    creator VARCHAR(42) NOT NULL,
    leg_count INT NOT NULL,
    total_stake NUMERIC(78, 0) NOT NULL,
    combined_odds NUMERIC(78, 0) NOT NULL,
    correlation_penalty_bps INT NOT NULL,
    adjusted_odds NUMERIC(78, 0) NOT NULL,
    potential_payout NUMERIC(78, 0) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    actual_payout NUMERIC(78, 0),
    created_at BIGINT NOT NULL,
    settled_at BIGINT,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    CONSTRAINT valid_leg_count CHECK (leg_count >= 2 AND leg_count <= 8),
    CONSTRAINT valid_stake CHECK (total_stake > 0),
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_parlays_creator ON parlays(creator);
CREATE INDEX idx_parlays_status ON parlays(status);
CREATE INDEX idx_parlays_created ON parlays(created_at DESC);

CREATE TABLE IF NOT EXISTS parlay_legs (
    id SERIAL PRIMARY KEY,
    parlay_id BIGINT NOT NULL REFERENCES parlays(id) ON DELETE CASCADE,
    leg_index INT NOT NULL,
    market_id VARCHAR(66) NOT NULL,
    market_address VARCHAR(42) NOT NULL,
    outcome INT NOT NULL,
    odds NUMERIC(78, 0) NOT NULL,
    result VARCHAR(20),
    settled_at BIGINT,
    UNIQUE(parlay_id, leg_index)
);

CREATE INDEX idx_parlay_legs_parlay ON parlay_legs(parlay_id);
CREATE INDEX idx_parlay_legs_market ON parlay_legs(market_id);
CREATE INDEX idx_parlay_legs_result ON parlay_legs(result);

CREATE TABLE IF NOT EXISTS player_props_markets (
    market_id VARCHAR(66) PRIMARY KEY REFERENCES markets(id) ON DELETE CASCADE,
    player_id VARCHAR(100) NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    prop_type VARCHAR(50) NOT NULL,
    line NUMERIC(18, 18),
    created_at BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_player_props_player ON player_props_markets(player_id);
CREATE INDEX idx_player_props_type ON player_props_markets(prop_type);
CREATE INDEX idx_player_props_market ON player_props_markets(market_id);

CREATE TABLE IF NOT EXISTS first_scorer_players (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES player_props_markets(market_id) ON DELETE CASCADE,
    player_index INT NOT NULL,
    player_id VARCHAR(100) NOT NULL,
    player_name VARCHAR(100) NOT NULL,
    team VARCHAR(50) NOT NULL,
    UNIQUE(market_id, player_index)
);

CREATE INDEX idx_first_scorer_market ON first_scorer_players(market_id);
CREATE INDEX idx_first_scorer_player ON first_scorer_players(player_id);

CREATE TABLE IF NOT EXISTS player_props_bets (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES player_props_markets(market_id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    outcome INT NOT NULL,
    stake NUMERIC(78, 0) NOT NULL,
    shares NUMERIC(78, 0) NOT NULL,
    timestamp BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_player_props_bets_market ON player_props_bets(market_id);
CREATE INDEX idx_player_props_bets_user ON player_props_bets(user_address);
CREATE INDEX idx_player_props_bets_time ON player_props_bets(timestamp DESC);

CREATE TABLE IF NOT EXISTS score_markets (
    market_id VARCHAR(66) PRIMARY KEY REFERENCES markets(id) ON DELETE CASCADE,
    liquidity_param NUMERIC(78, 0) NOT NULL,
    outcome_count INT NOT NULL DEFAULT 36,
    created_at BIGINT NOT NULL,
    block_number BIGINT NOT NULL,
    tx_hash VARCHAR(66) NOT NULL,
    log_index INT NOT NULL,
    UNIQUE(tx_hash, log_index)
);

CREATE INDEX idx_score_markets_market ON score_markets(market_id);

-- ============================================
-- Fixtures Table (API-Football data)
-- ============================================

CREATE TABLE IF NOT EXISTS fixtures (
    id SERIAL PRIMARY KEY,
    fixture_id BIGINT NOT NULL UNIQUE,
    league_id INT NOT NULL,
    league_name VARCHAR(100) NOT NULL,
    league_code VARCHAR(20) NOT NULL,
    season INT NOT NULL,
    round_number INT,
    home_team_id INT NOT NULL,
    home_team_name VARCHAR(100) NOT NULL,
    home_team_code VARCHAR(10) NOT NULL,
    away_team_id INT NOT NULL,
    away_team_name VARCHAR(100) NOT NULL,
    away_team_code VARCHAR(10) NOT NULL,
    kickoff_time BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'NS',
    home_score INT,
    away_score INT,
    venue_name VARCHAR(200),
    match_id_wdl VARCHAR(200) NOT NULL,
    match_id_ou VARCHAR(200) NOT NULL,
    market_created_wdl BOOLEAN DEFAULT FALSE,
    market_created_ou BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fixtures_kickoff ON fixtures(kickoff_time);
CREATE INDEX idx_fixtures_status ON fixtures(status);
CREATE INDEX idx_fixtures_league ON fixtures(league_id, season);
CREATE INDEX idx_fixtures_match_id_wdl ON fixtures(match_id_wdl);
CREATE INDEX idx_fixtures_match_id_ou ON fixtures(match_id_ou);
CREATE INDEX idx_fixtures_pending_wdl ON fixtures(kickoff_time) WHERE status = 'NS' AND NOT market_created_wdl;
CREATE INDEX idx_fixtures_pending_ou ON fixtures(kickoff_time) WHERE status = 'NS' AND NOT market_created_ou;

-- ============================================
-- Trigger Functions
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION update_markets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = EXTRACT(EPOCH FROM NOW())::BIGINT;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_keeper_tasks_updated_at
    BEFORE UPDATE ON keeper_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_markets_updated_at
    BEFORE UPDATE ON markets
    FOR EACH ROW
    EXECUTE FUNCTION update_markets_updated_at();

CREATE TRIGGER trigger_update_fixtures_updated_at
    BEFORE UPDATE ON fixtures
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Views
-- ============================================

CREATE OR REPLACE VIEW active_markets AS
SELECT
    m.*,
    COUNT(DISTINCT o.user_address) as unique_bettors,
    SUM(o.stake) as total_volume,
    SUM(o.fee) as total_fees
FROM markets m
LEFT JOIN orders o ON m.id = o.market_id
WHERE m.status IN ('Open', 'Locked')
GROUP BY m.id;

CREATE OR REPLACE VIEW user_positions_summary AS
SELECT
    p.user_address,
    COUNT(DISTINCT p.market_id) as active_markets,
    SUM(CASE WHEN p.balance > 0 THEN 1 ELSE 0 END) as active_positions,
    COUNT(*) as total_positions
FROM positions p
GROUP BY p.user_address;

CREATE OR REPLACE VIEW market_statistics AS
SELECT
    m.id as market_id,
    m.home_team,
    m.away_team,
    m.status,
    COUNT(DISTINCT o.user_address) as unique_bettors,
    COUNT(o.id) as total_orders,
    SUM(o.stake) as total_volume,
    SUM(o.fee) as total_fees,
    SUM(CASE WHEN o.outcome = 0 THEN o.stake ELSE 0 END) as home_volume,
    SUM(CASE WHEN o.outcome = 1 THEN o.stake ELSE 0 END) as draw_volume,
    SUM(CASE WHEN o.outcome = 2 THEN o.stake ELSE 0 END) as away_volume
FROM markets m
LEFT JOIN orders o ON m.id = o.market_id
GROUP BY m.id, m.home_team, m.away_team, m.status;

-- ============================================
-- Schema Version
-- ============================================

CREATE TABLE IF NOT EXISTS schema_version (
    version INT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO schema_version (version, description) VALUES (1, 'Consolidated V1 schema') ON CONFLICT DO NOTHING;
