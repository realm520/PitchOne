-- Rollback Migration: Remove Keeper service fields from markets table
-- Version: 002
-- Description: Remove all fields added in migration 002

-- Drop trigger first
DROP TRIGGER IF EXISTS trigger_update_markets_updated_at ON markets;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_markets_updated_at();

-- Drop indexes
DROP INDEX IF EXISTS idx_markets_oracle;
DROP INDEX IF EXISTS idx_markets_match_end;
DROP INDEX IF EXISTS idx_markets_lock_time;
DROP INDEX IF EXISTS idx_markets_market_address;

-- Remove fields from markets table (in reverse order of addition)
ALTER TABLE markets
  DROP COLUMN IF EXISTS updated_at,
  DROP COLUMN IF EXISTS away_goals,
  DROP COLUMN IF EXISTS home_goals,
  DROP COLUMN IF EXISTS settle_tx_hash,
  DROP COLUMN IF EXISTS lock_tx_hash,
  DROP COLUMN IF EXISTS match_end,
  DROP COLUMN IF EXISTS match_start,
  DROP COLUMN IF EXISTS lock_time,
  DROP COLUMN IF EXISTS oracle_address,
  DROP COLUMN IF EXISTS event_id,
  DROP COLUMN IF EXISTS market_address;

-- Remove schema version record
DELETE FROM schema_migrations WHERE version = 2;
