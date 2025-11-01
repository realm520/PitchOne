-- Migration 003: 添加奖励分发相关表
-- Week 5: Rewards Builder 服务

-- 奖励分发记录表
CREATE TABLE IF NOT EXISTS reward_distributions (
    week BIGINT PRIMARY KEY,                       -- 周编号
    merkle_root VARCHAR(66) NOT NULL,              -- Merkle Root (0x...)
    total_amount NUMERIC(78, 0) NOT NULL,          -- 总奖励金额（未缩放）
    recipients INT NOT NULL,                       -- 收益人数量
    scale_bps INT NOT NULL,                        -- 缩放比例（基点）
    created_at BIGINT NOT NULL,                    -- 创建时间
    updated_at BIGINT,                             -- 更新时间
    tx_hash VARCHAR(66),                           -- 发布交易哈希
    block_number BIGINT,                           -- 发布区块号
    published_at BIGINT,                           -- 链上发布时间
    status VARCHAR(20) DEFAULT 'pending',          -- pending/published/verified

    CONSTRAINT valid_scale CHECK (scale_bps >= 1000 AND scale_bps <= 10000),
    CONSTRAINT valid_recipients CHECK (recipients > 0)
);

-- 索引
CREATE INDEX idx_reward_distributions_status ON reward_distributions(status);
CREATE INDEX idx_reward_distributions_created ON reward_distributions(created_at DESC);

-- 用户奖励详情表（可选，用于快速查询）
CREATE TABLE IF NOT EXISTS reward_entries (
    id SERIAL PRIMARY KEY,
    week BIGINT NOT NULL REFERENCES reward_distributions(week),
    user_address VARCHAR(42) NOT NULL,             -- 用户地址
    amount NUMERIC(78, 0) NOT NULL,                -- 奖励金额
    reward_type VARCHAR(20) NOT NULL,              -- referral/trading/campaign
    created_at BIGINT NOT NULL,

    UNIQUE(week, user_address, reward_type)
);

-- 索引
CREATE INDEX idx_reward_entries_week ON reward_entries(week);
CREATE INDEX idx_reward_entries_user ON reward_entries(user_address);
CREATE INDEX idx_reward_entries_type ON reward_entries(reward_type);

-- Merkle 证明缓存表（可选，用于加速 API 查询）
CREATE TABLE IF NOT EXISTS merkle_proofs (
    week BIGINT NOT NULL REFERENCES reward_distributions(week),
    user_address VARCHAR(42) NOT NULL,
    proof JSONB NOT NULL,                          -- Merkle 证明数组
    created_at BIGINT NOT NULL,

    PRIMARY KEY (week, user_address)
);

-- 索引
CREATE INDEX idx_merkle_proofs_user ON merkle_proofs(user_address);

-- 添加注释
COMMENT ON TABLE reward_distributions IS '周度奖励分发记录 - 存储 Merkle Root 和元数据';
COMMENT ON TABLE reward_entries IS '用户奖励明细 - 用于审计和查询';
COMMENT ON TABLE merkle_proofs IS 'Merkle 证明缓存 - 加速前端查询';

COMMENT ON COLUMN reward_distributions.scale_bps IS '缩放比例（基点），10000=100%, 5000=50%';
COMMENT ON COLUMN reward_distributions.status IS '状态: pending=待发布, published=已发布, verified=已验证';
