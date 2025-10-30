-- Migration rollback: 001_initial_schema
-- Description: 回滚初始数据库结构

-- 删除触发器
DROP TRIGGER IF EXISTS update_keeper_tasks_updated_at ON keeper_tasks;
DROP FUNCTION IF EXISTS update_updated_at_column();

-- 删除视图
DROP VIEW IF EXISTS market_statistics;
DROP VIEW IF EXISTS user_positions_summary;
DROP VIEW IF EXISTS active_markets;

-- 删除表 (按依赖顺序逆序删除)
DROP TABLE IF EXISTS alert_logs;
DROP TABLE IF EXISTS keeper_tasks;
DROP TABLE IF EXISTS indexer_state;
DROP TABLE IF EXISTS payouts;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS markets;
DROP TABLE IF EXISTS schema_version;
