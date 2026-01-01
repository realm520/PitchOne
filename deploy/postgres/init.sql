-- PitchOne Backend PostgreSQL 初始化脚本
-- 此脚本在容器首次启动时自动执行

-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- 设置时区
SET timezone = 'UTC';

-- 创建基础表结构（根据 backend 需求调整）

-- 市场表
CREATE TABLE IF NOT EXISTS markets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_address VARCHAR(42) NOT NULL UNIQUE,
    template_type VARCHAR(50) NOT NULL,
    event_name VARCHAR(255),
    event_metadata JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'Open',
    lock_time TIMESTAMP WITH TIME ZONE,
    settle_time TIMESTAMP WITH TIME ZONE,
    result JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_markets_status ON markets(status);
CREATE INDEX IF NOT EXISTS idx_markets_lock_time ON markets(lock_time);
CREATE INDEX IF NOT EXISTS idx_markets_template_type ON markets(template_type);

-- 订单表
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    market_id UUID REFERENCES markets(id),
    user_address VARCHAR(42) NOT NULL,
    outcome INTEGER NOT NULL,
    amount NUMERIC(78, 0) NOT NULL,
    shares NUMERIC(78, 0) NOT NULL,
    tx_hash VARCHAR(66) NOT NULL UNIQUE,
    block_number BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_market_id ON orders(market_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_address ON orders(user_address);
CREATE INDEX IF NOT EXISTS idx_orders_block_number ON orders(block_number);

-- 推荐关系表
CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    referrer_address VARCHAR(42) NOT NULL,
    referee_address VARCHAR(42) NOT NULL UNIQUE,
    tx_hash VARCHAR(66) NOT NULL,
    block_number BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_address);

-- 奖励表
CREATE TABLE IF NOT EXISTS rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_address VARCHAR(42) NOT NULL,
    reward_type VARCHAR(50) NOT NULL,
    amount NUMERIC(78, 0) NOT NULL,
    epoch INTEGER NOT NULL,
    merkle_proof JSONB,
    claimed BOOLEAN DEFAULT FALSE,
    claimed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rewards_user_address ON rewards(user_address);
CREATE INDEX IF NOT EXISTS idx_rewards_epoch ON rewards(epoch);
CREATE INDEX IF NOT EXISTS idx_rewards_claimed ON rewards(claimed);

-- 预言机提案表
CREATE TABLE IF NOT EXISTS oracle_proposals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    market_id UUID REFERENCES markets(id),
    proposer_address VARCHAR(42) NOT NULL,
    result JSONB NOT NULL,
    bond_amount NUMERIC(78, 0) NOT NULL,
    disputed BOOLEAN DEFAULT FALSE,
    finalized BOOLEAN DEFAULT FALSE,
    tx_hash VARCHAR(66) NOT NULL,
    block_number BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    finalized_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_oracle_proposals_market_id ON oracle_proposals(market_id);
CREATE INDEX IF NOT EXISTS idx_oracle_proposals_finalized ON oracle_proposals(finalized);

-- Keeper 任务日志表
CREATE TABLE IF NOT EXISTS keeper_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_type VARCHAR(50) NOT NULL,
    target_address VARCHAR(42),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    tx_hash VARCHAR(66),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_keeper_tasks_status ON keeper_tasks(status);
CREATE INDEX IF NOT EXISTS idx_keeper_tasks_scheduled ON keeper_tasks(scheduled_at);

-- 索引器状态表
CREATE TABLE IF NOT EXISTS indexer_state (
    id INTEGER PRIMARY KEY DEFAULT 1,
    last_processed_block BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO indexer_state (id, last_processed_block)
VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

-- 授予权限（如果有额外用户）
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pitchone;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pitchone;

-- 输出完成信息
DO $$
BEGIN
    RAISE NOTICE 'PitchOne database initialization completed successfully!';
END $$;
