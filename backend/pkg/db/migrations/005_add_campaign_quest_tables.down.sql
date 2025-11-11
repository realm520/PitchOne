-- Migration 005 Rollback: 删除 Campaign 和 Quest 相关表

DROP TABLE IF EXISTS referral_earnings CASCADE;
DROP TABLE IF EXISTS referrals CASCADE;
DROP TABLE IF EXISTS quest_completions CASCADE;
DROP TABLE IF EXISTS user_quest_progress CASCADE;
DROP TABLE IF EXISTS quests CASCADE;
DROP TABLE IF EXISTS campaign_participations CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;

-- 删除版本记录
DELETE FROM schema_version WHERE version = 5;
