-- Migration: Add Keeper service required fields to markets table
-- Version: 002
-- Description: Add fields for market address, event tracking, oracle integration,
--              timing information, transaction hashes, and match results

-- Add new fields to markets table
ALTER TABLE markets
  -- Market identification and external references
  ADD COLUMN IF NOT EXISTS market_address VARCHAR(42),     -- Market contract address (e.g., 0x1234...)
  ADD COLUMN IF NOT EXISTS event_id VARCHAR(100),          -- External event ID for result fetching

  -- Oracle integration
  ADD COLUMN IF NOT EXISTS oracle_address VARCHAR(42),     -- Oracle contract address

  -- Timing fields (using BIGINT for Unix timestamps to match existing schema)
  ADD COLUMN IF NOT EXISTS lock_time BIGINT,               -- Planned lock time (N minutes before match_start)
  ADD COLUMN IF NOT EXISTS match_start BIGINT,             -- Match start timestamp
  ADD COLUMN IF NOT EXISTS match_end BIGINT,               -- Match end timestamp

  -- Transaction tracking
  ADD COLUMN IF NOT EXISTS lock_tx_hash VARCHAR(66),       -- Lock transaction hash
  ADD COLUMN IF NOT EXISTS settle_tx_hash VARCHAR(66),     -- Settle transaction hash
  ADD COLUMN IF NOT EXISTS locked_at BIGINT,               -- Actual lock timestamp
  ADD COLUMN IF NOT EXISTS settled_at BIGINT,              -- Actual settlement timestamp

  -- Match results
  ADD COLUMN IF NOT EXISTS home_goals SMALLINT,            -- Home team goals
  ADD COLUMN IF NOT EXISTS away_goals SMALLINT,            -- Away team goals

  -- Metadata
  ADD COLUMN IF NOT EXISTS updated_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT;  -- Last update timestamp

-- Create indexes for query optimization
CREATE INDEX IF NOT EXISTS idx_markets_market_address
  ON markets(market_address);

CREATE INDEX IF NOT EXISTS idx_markets_lock_time
  ON markets(lock_time)
  WHERE status = 'Open';  -- Partial index for lock task queries

CREATE INDEX IF NOT EXISTS idx_markets_match_end
  ON markets(match_end)
  WHERE status = 'Locked';  -- Partial index for settle task queries

CREATE INDEX IF NOT EXISTS idx_markets_oracle
  ON markets(oracle_address);

-- Create trigger function for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_markets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = EXTRACT(EPOCH FROM NOW())::BIGINT;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_markets_updated_at ON markets;
CREATE TRIGGER trigger_update_markets_updated_at
    BEFORE UPDATE ON markets
    FOR EACH ROW
    EXECUTE FUNCTION update_markets_updated_at();

-- Update schema version tracking
CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at BIGINT DEFAULT EXTRACT(EPOCH FROM NOW())::BIGINT
);

INSERT INTO schema_migrations (version, description)
VALUES (2, 'Add Keeper required fields: market_address, timestamps, oracle, match results')
ON CONFLICT (version) DO NOTHING;

-- Add comments for documentation
COMMENT ON COLUMN markets.market_address IS 'Market contract address (Ethereum address format)';
COMMENT ON COLUMN markets.event_id IS 'External event ID for fetching match results from data provider';
COMMENT ON COLUMN markets.oracle_address IS 'Oracle contract address for result submission';
COMMENT ON COLUMN markets.lock_time IS 'Unix timestamp when market should be locked (before match start)';
COMMENT ON COLUMN markets.match_start IS 'Unix timestamp of match start time';
COMMENT ON COLUMN markets.match_end IS 'Unix timestamp of match end time';
COMMENT ON COLUMN markets.lock_tx_hash IS 'Transaction hash of market lock operation';
COMMENT ON COLUMN markets.settle_tx_hash IS 'Transaction hash of market settlement operation';
COMMENT ON COLUMN markets.home_goals IS 'Home team goals (final result)';
COMMENT ON COLUMN markets.away_goals IS 'Away team goals (final result)';
COMMENT ON COLUMN markets.updated_at IS 'Unix timestamp of last update';
