-- Migration: 007_add_market_version
-- Description: 添加 version 字段以区分 V2 和 V3 市场
-- Date: 2025-12-25

-- 添加 version 字段到 markets 表
ALTER TABLE markets ADD COLUMN IF NOT EXISTS version VARCHAR(10) DEFAULT 'v2';

-- 添加注释
COMMENT ON COLUMN markets.version IS '市场版本: v2 (V2架构) 或 v3 (V3架构)';

-- 添加索引以优化版本过滤查询
CREATE INDEX IF NOT EXISTS idx_markets_version ON markets(version);
