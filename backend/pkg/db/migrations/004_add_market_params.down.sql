-- Rollback Migration 004: Remove market_params JSONB field
-- Version: 004

-- Drop index
DROP INDEX IF EXISTS idx_markets_market_params;

-- Drop column
ALTER TABLE markets
  DROP COLUMN IF EXISTS market_params;

-- Remove from schema version tracking
DELETE FROM schema_migrations WHERE version = 4;
