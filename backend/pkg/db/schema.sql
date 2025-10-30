-- PitchOne Database Schema
-- Week 3-4: Core tables for Indexer and Keeper

-- Markets table - 存储所有市场的元数据
CREATE TABLE IF NOT EXISTS markets (
    id VARCHAR(66) PRIMARY KEY,                -- bytes32 marketId (0x...)
    template_id VARCHAR(66) NOT NULL,          -- 模板ID
    match_id VARCHAR(100) NOT NULL,            -- 比赛ID (外部数据源)
    home_team VARCHAR(100),                    -- 主队名称
    away_team VARCHAR(100),                    -- 客队名称
    kickoff_time BIGINT NOT NULL,              -- 开赛时间 (Unix timestamp)
    status VARCHAR(20) NOT NULL,               -- Open/Locked/Resolved/Finalized/Refundable
    locked_at BIGINT,                          -- 锁盘时间
    resolved_at BIGINT,                        -- 结算时间
    finalized_at BIGINT,                       -- 终结时间
    winner_outcome INT,                        -- 赢家结果 (0=主胜, 1=平, 2=客胜, -1=取消)
    result_hash BYTEA,                         -- 赛果哈希 (MatchFacts的keccak256)
    created_at BIGINT NOT NULL,                -- 创建时间
    created_block BIGINT NOT NULL,             -- 创建区块号
    tx_hash VARCHAR(66) NOT NULL,              -- 创建交易哈希
    log_index INT NOT NULL,                    -- 日志索引

    -- Keeper service fields (added in migration 002)
    market_address VARCHAR(42),                -- 市场合约地址 (Ethereum address)
    event_id VARCHAR(100),                     -- 外部赛事ID (用于获取比赛结果)
    oracle_address VARCHAR(42),                -- 预言机合约地址
    lock_time BIGINT,                          -- 计划锁盘时间 (开赛前N分钟)
    match_start BIGINT,                        -- 比赛开始时间
    match_end BIGINT,                          -- 比赛结束时间
    lock_tx_hash VARCHAR(66),                  -- 锁盘交易哈希
    settle_tx_hash VARCHAR(66),                -- 结算交易哈希
    locked_at BIGINT,                          -- 实际锁盘时间
    settled_at BIGINT,                         -- 实际结算时间
    home_goals SMALLINT,                       -- 主队进球数 (比赛结果)
    away_goals SMALLINT,                       -- 客队进球数 (比赛结果)
    updated_at BIGINT,                         -- 最后更新时间

    UNIQUE(tx_hash, log_index)                 -- 防重复插入
);

-- 索引优化
CREATE INDEX idx_markets_status ON markets(status);
CREATE INDEX idx_markets_kickoff ON markets(kickoff_time);
CREATE INDEX idx_markets_created_block ON markets(created_block);

-- Keeper service indexes (added in migration 002)
CREATE INDEX idx_markets_market_address ON markets(market_address);
CREATE INDEX idx_markets_lock_time ON markets(lock_time) WHERE status = 'Open';
CREATE INDEX idx_markets_match_end ON markets(match_end) WHERE status = 'Locked';
CREATE INDEX idx_markets_oracle ON markets(oracle_address);

-- Orders table - 下注订单记录
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,         -- 用户地址
    outcome INT NOT NULL,                      -- 下注方向 (0/1/2)
    stake NUMERIC(78, 0) NOT NULL,             -- 下注金额 (uint256, wei)
    shares NUMERIC(78, 0) NOT NULL,            -- 获得份额 (uint256)
    fee NUMERIC(78, 0) NOT NULL,               -- 手续费 (uint256, wei)
    referrer VARCHAR(42),                      -- 推荐人地址 (可为NULL)
    campaign_id VARCHAR(66),                   -- 活动ID (可为NULL)
    timestamp BIGINT NOT NULL,                 -- 下注时间
    block_number BIGINT NOT NULL,              -- 区块号
    tx_hash VARCHAR(66) NOT NULL,              -- 交易哈希
    log_index INT NOT NULL,                    -- 日志索引
    UNIQUE(tx_hash, log_index)                 -- 防重复插入
);

-- 索引优化
CREATE INDEX idx_orders_market ON orders(market_id);
CREATE INDEX idx_orders_user ON orders(user_address);
CREATE INDEX idx_orders_timestamp ON orders(timestamp DESC);
CREATE INDEX idx_orders_block ON orders(block_number);
CREATE INDEX idx_orders_referrer ON orders(referrer) WHERE referrer IS NOT NULL;

-- Positions table - ERC-1155 持仓状态
CREATE TABLE IF NOT EXISTS positions (
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,         -- 持仓用户
    outcome INT NOT NULL,                      -- 持仓方向
    balance NUMERIC(78, 0) NOT NULL DEFAULT 0, -- 当前余额 (uint256)
    last_updated BIGINT NOT NULL,              -- 最后更新时间
    last_updated_block BIGINT NOT NULL,        -- 最后更新区块号
    PRIMARY KEY (market_id, user_address, outcome)
);

-- 索引优化
CREATE INDEX idx_positions_user ON positions(user_address);
CREATE INDEX idx_positions_market ON positions(market_id);
CREATE INDEX idx_positions_balance ON positions(balance) WHERE balance > 0;

-- Payouts table - 兑付记录
CREATE TABLE IF NOT EXISTS payouts (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,         -- 兑付用户
    amount NUMERIC(78, 0) NOT NULL,            -- 兑付金额 (uint256, wei)
    timestamp BIGINT NOT NULL,                 -- 兑付时间
    block_number BIGINT NOT NULL,              -- 区块号
    tx_hash VARCHAR(66) NOT NULL,              -- 交易哈希
    log_index INT NOT NULL,                    -- 日志索引
    UNIQUE(tx_hash, log_index)                 -- 防重复插入
);

-- 索引优化
CREATE INDEX idx_payouts_market ON payouts(market_id);
CREATE INDEX idx_payouts_user ON payouts(user_address);
CREATE INDEX idx_payouts_timestamp ON payouts(timestamp DESC);

-- Indexer state table - 存储Indexer状态（支持断点续传）
CREATE TABLE IF NOT EXISTS indexer_state (
    key VARCHAR(50) PRIMARY KEY,
    value BIGINT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 初始化 last_processed_block
INSERT INTO indexer_state (key, value)
VALUES ('last_processed_block', 0)
ON CONFLICT (key) DO NOTHING;

-- Keeper tasks table - 存储Keeper任务状态
CREATE TABLE IF NOT EXISTS keeper_tasks (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES markets(id) ON DELETE CASCADE,
    task_type VARCHAR(20) NOT NULL,            -- 'lock' / 'resolve' / 'finalize'
    status VARCHAR(20) NOT NULL,               -- 'pending' / 'processing' / 'completed' / 'failed'
    scheduled_at BIGINT NOT NULL,              -- 计划执行时间
    executed_at BIGINT,                        -- 实际执行时间
    tx_hash VARCHAR(66),                       -- 执行交易哈希
    error_message TEXT,                        -- 错误信息（失败时）
    retry_count INT DEFAULT 0,                 -- 重试次数
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引优化
CREATE INDEX idx_keeper_tasks_market ON keeper_tasks(market_id);
CREATE INDEX idx_keeper_tasks_status ON keeper_tasks(status);
CREATE INDEX idx_keeper_tasks_scheduled ON keeper_tasks(scheduled_at) WHERE status = 'pending';

-- Alert logs table - 告警日志
CREATE TABLE IF NOT EXISTS alert_logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,                -- 'info' / 'warning' / 'error' / 'critical'
    title VARCHAR(200) NOT NULL,               -- 告警标题
    message TEXT NOT NULL,                     -- 告警详情
    context JSONB,                             -- 上下文信息 (JSON)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 索引优化
CREATE INDEX idx_alert_logs_level ON alert_logs(level);
CREATE INDEX idx_alert_logs_created ON alert_logs(created_at DESC);

-- 创建更新时间触发器函数 (通用版本)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- markets 表 updated_at 触发器函数 (BIGINT 版本)
CREATE OR REPLACE FUNCTION update_markets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = EXTRACT(EPOCH FROM NOW())::BIGINT;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为 keeper_tasks 表添加自动更新触发器
CREATE TRIGGER update_keeper_tasks_updated_at
    BEFORE UPDATE ON keeper_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 为 markets 表添加自动更新触发器 (added in migration 002)
CREATE TRIGGER trigger_update_markets_updated_at
    BEFORE UPDATE ON markets
    FOR EACH ROW
    EXECUTE FUNCTION update_markets_updated_at();

-- 数据库版本信息
CREATE TABLE IF NOT EXISTS schema_version (
    version INT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

INSERT INTO schema_version (version, description)
VALUES
    (1, 'Initial schema - Week 3-4 core tables'),
    (2, 'Add Keeper required fields: market_address, timestamps, oracle, match results')
ON CONFLICT (version) DO NOTHING;

-- 添加有用的视图

-- View: Active markets (未结算的市场)
CREATE OR REPLACE VIEW active_markets AS
SELECT
    m.*,
    COUNT(DISTINCT o.user_address) as unique_bettors,
    SUM(o.stake) as total_volume,
    SUM(o.fee) as total_fees
FROM markets m
LEFT JOIN orders o ON m.id = o.market_id
WHERE m.status IN ('Open', 'Locked')
GROUP BY m.id;

-- View: User positions summary (用户持仓汇总)
CREATE OR REPLACE VIEW user_positions_summary AS
SELECT
    p.user_address,
    COUNT(DISTINCT p.market_id) as active_markets,
    SUM(CASE WHEN p.balance > 0 THEN 1 ELSE 0 END) as active_positions,
    COUNT(*) as total_positions
FROM positions p
GROUP BY p.user_address;

-- View: Market statistics (市场统计)
CREATE OR REPLACE VIEW market_statistics AS
SELECT
    m.id as market_id,
    m.home_team,
    m.away_team,
    m.status,
    COUNT(DISTINCT o.user_address) as unique_bettors,
    COUNT(o.id) as total_orders,
    SUM(o.stake) as total_volume,
    SUM(o.fee) as total_fees,
    SUM(CASE WHEN o.outcome = 0 THEN o.stake ELSE 0 END) as home_volume,
    SUM(CASE WHEN o.outcome = 1 THEN o.stake ELSE 0 END) as draw_volume,
    SUM(CASE WHEN o.outcome = 2 THEN o.stake ELSE 0 END) as away_volume
FROM markets m
LEFT JOIN orders o ON m.id = o.market_id
GROUP BY m.id, m.home_team, m.away_team, m.status;

-- 添加注释
COMMENT ON TABLE markets IS '市场元数据表，记录所有创建的博彩市场';
COMMENT ON TABLE orders IS '下注订单表，记录所有用户下注行为';
COMMENT ON TABLE positions IS 'ERC-1155持仓表，记录用户当前持仓状态';
COMMENT ON TABLE payouts IS '兑付记录表，记录用户成功兑付的订单';
COMMENT ON TABLE indexer_state IS 'Indexer状态表，支持断点续传和重放';
COMMENT ON TABLE keeper_tasks IS 'Keeper任务表，管理自动化任务调度';
COMMENT ON TABLE alert_logs IS '告警日志表，记录系统告警和异常';
