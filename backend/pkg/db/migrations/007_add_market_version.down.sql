-- Migration: 007_add_market_version (rollback)
-- Description: 移除 version 字段
-- Date: 2025-12-25

-- 删除索引
DROP INDEX IF EXISTS idx_markets_version;

-- 移除 version 字段
ALTER TABLE markets DROP COLUMN IF EXISTS version;
