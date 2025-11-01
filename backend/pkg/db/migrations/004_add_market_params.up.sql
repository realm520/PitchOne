-- Migration: Add market_params JSONB field for template-specific parameters
-- Version: 004
-- Description: Add JSONB field to store template-specific market parameters
--              (e.g., OU line, AH handicap, etc.) without schema changes

-- Add market_params column
ALTER TABLE markets
  ADD COLUMN IF NOT EXISTS market_params JSONB DEFAULT '{}'::jsonb;

-- Create GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_markets_market_params
  ON markets USING GIN (market_params);

-- Add comment for documentation
COMMENT ON COLUMN markets.market_params IS 'Template-specific market parameters in JSON format (e.g., {"line": 2500, "isHalfLine": true} for OU markets)';

-- Update schema version tracking
INSERT INTO schema_migrations (version, description)
VALUES (4, 'Add market_params JSONB field for template-specific parameters')
ON CONFLICT (version) DO NOTHING;

-- Example usage:
-- OU Market: {"line": 2500, "isHalfLine": true, "type": "OU"}
-- AH Market: {"handicap": 1500, "isHalfLine": false, "type": "AH"}
-- WDL Market: {"type": "WDL"}
