-- Migration 006 Rollback: 删除 Basket 和 PlayerProps 相关表

DROP TABLE IF EXISTS score_markets CASCADE;
DROP TABLE IF EXISTS player_props_bets CASCADE;
DROP TABLE IF EXISTS first_scorer_players CASCADE;
DROP TABLE IF EXISTS player_props_markets CASCADE;
DROP TABLE IF EXISTS parlay_legs CASCADE;
DROP TABLE IF EXISTS parlays CASCADE;

-- 删除版本记录
DELETE FROM schema_version WHERE version = 6;
