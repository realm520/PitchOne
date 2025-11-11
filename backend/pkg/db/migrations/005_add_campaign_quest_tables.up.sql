-- Migration 005: 添加 Campaign 和 Quest 相关表
-- Week 6-7: M2 运营闭环功能

-- ============================================
-- Campaign (活动) 相关表
-- ============================================

-- 活动主表
CREATE TABLE IF NOT EXISTS campaigns (
    id BIGINT PRIMARY KEY,                         -- 活动ID（来自链上）
    name VARCHAR(200) NOT NULL,                    -- 活动名称
    description TEXT,                              -- 活动描述
    campaign_type VARCHAR(50) NOT NULL,            -- 活动类型（deposit_bonus, trading_contest等）
    budget NUMERIC(78, 0) NOT NULL,                -- 预算（USDC, 6 decimals）
    spent NUMERIC(78, 0) DEFAULT 0,                -- 已花费
    start_time BIGINT NOT NULL,                    -- 开始时间（Unix timestamp）
    end_time BIGINT NOT NULL,                      -- 结束时间
    status VARCHAR(20) NOT NULL DEFAULT 'active',  -- active/paused/ended
    creator VARCHAR(42) NOT NULL,                  -- 创建者地址
    created_at BIGINT NOT NULL,                    -- 创建时间
    created_block BIGINT NOT NULL,                 -- 创建区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 创建交易哈希
    log_index INT NOT NULL,                        -- 日志索引
    updated_at BIGINT,                             -- 最后更新时间

    CONSTRAINT valid_budget CHECK (budget > 0),
    CONSTRAINT valid_time CHECK (end_time > start_time),
    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_time ON campaigns(start_time, end_time);
CREATE INDEX idx_campaigns_creator ON campaigns(creator);

-- 活动参与记录表
CREATE TABLE IF NOT EXISTS campaign_participations (
    id SERIAL PRIMARY KEY,
    campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    participant_address VARCHAR(42) NOT NULL,      -- 参与者地址
    action VARCHAR(50) NOT NULL,                   -- 参与动作（bet, refer等）
    reward_amount NUMERIC(78, 0) NOT NULL,         -- 获得奖励
    metadata JSONB,                                -- 额外元数据（如下注ID等）
    participated_at BIGINT NOT NULL,               -- 参与时间
    reward_claimed BOOLEAN DEFAULT false,          -- 是否已领取奖励
    claimed_at BIGINT,                             -- 领取时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_campaign_participations_campaign ON campaign_participations(campaign_id);
CREATE INDEX idx_campaign_participations_participant ON campaign_participations(participant_address);
CREATE INDEX idx_campaign_participations_time ON campaign_participations(participated_at DESC);
CREATE INDEX idx_campaign_participations_claimed ON campaign_participations(reward_claimed) WHERE reward_claimed = false;

-- ============================================
-- Quest (任务) 相关表
-- ============================================

-- 任务主表
CREATE TABLE IF NOT EXISTS quests (
    id BIGINT PRIMARY KEY,                         -- 任务ID（来自链上）
    name VARCHAR(200) NOT NULL,                    -- 任务名称
    description TEXT,                              -- 任务描述
    quest_type VARCHAR(50) NOT NULL,               -- 任务类型（bet, refer, parlay, streak, social）
    target BIGINT NOT NULL,                        -- 目标值（如下注10次）
    reward_amount NUMERIC(78, 0) NOT NULL,         -- 奖励金额
    max_completions INT DEFAULT 0,                 -- 最大完成次数（0=无限）
    current_completions INT DEFAULT 0,             -- 当前完成次数
    start_time BIGINT NOT NULL,                    -- 开始时间
    end_time BIGINT NOT NULL,                      -- 结束时间
    status VARCHAR(20) NOT NULL DEFAULT 'active',  -- active/paused/ended
    creator VARCHAR(42) NOT NULL,                  -- 创建者地址
    created_at BIGINT NOT NULL,                    -- 创建时间
    created_block BIGINT NOT NULL,                 -- 创建区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 创建交易哈希
    log_index INT NOT NULL,                        -- 日志索引
    updated_at BIGINT,                             -- 最后更新时间

    CONSTRAINT valid_reward CHECK (reward_amount > 0),
    CONSTRAINT valid_quest_time CHECK (end_time > start_time),
    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_quests_status ON quests(status);
CREATE INDEX idx_quests_type ON quests(quest_type);
CREATE INDEX idx_quests_time ON quests(start_time, end_time);

-- 用户任务进度表
CREATE TABLE IF NOT EXISTS user_quest_progress (
    id SERIAL PRIMARY KEY,
    quest_id BIGINT NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,             -- 用户地址
    current_progress BIGINT DEFAULT 0,             -- 当前进度
    completed BOOLEAN DEFAULT false,               -- 是否已完成
    completed_at BIGINT,                           -- 完成时间
    reward_claimed BOOLEAN DEFAULT false,          -- 是否已领取奖励
    claimed_at BIGINT,                             -- 领取时间
    last_updated BIGINT NOT NULL,                  -- 最后更新时间

    UNIQUE(quest_id, user_address)
);

-- 索引
CREATE INDEX idx_user_quest_progress_user ON user_quest_progress(user_address);
CREATE INDEX idx_user_quest_progress_quest ON user_quest_progress(quest_id);
CREATE INDEX idx_user_quest_progress_completed ON user_quest_progress(completed) WHERE completed = true;
CREATE INDEX idx_user_quest_progress_unclaimed ON user_quest_progress(reward_claimed) WHERE reward_claimed = false;

-- 任务完成记录表（用于奖励聚合）
CREATE TABLE IF NOT EXISTS quest_completions (
    id SERIAL PRIMARY KEY,
    quest_id BIGINT NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,             -- 用户地址
    reward_amount NUMERIC(78, 0) NOT NULL,         -- 获得奖励
    completed_at BIGINT NOT NULL,                  -- 完成时间
    reward_claimed BOOLEAN DEFAULT false,          -- 是否已领取（用于 Rewards Builder 聚合）
    claimed_at BIGINT,                             -- 领取时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_quest_completions_quest ON quest_completions(quest_id);
CREATE INDEX idx_quest_completions_user ON quest_completions(user_address);
CREATE INDEX idx_quest_completions_time ON quest_completions(completed_at DESC);
CREATE INDEX idx_quest_completions_claimed ON quest_completions(reward_claimed) WHERE reward_claimed = false;

-- ============================================
-- 推荐关系表
-- ============================================

-- 推荐关系绑定表
CREATE TABLE IF NOT EXISTS referrals (
    id SERIAL PRIMARY KEY,
    referrer VARCHAR(42) NOT NULL,                 -- 推荐人地址
    referee VARCHAR(42) NOT NULL,                  -- 被推荐人地址
    bound_at BIGINT NOT NULL,                      -- 绑定时间
    referral_code VARCHAR(50),                     -- 推荐码（可选）
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(referee),                               -- 一个用户只能被推荐一次
    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_referrals_referrer ON referrals(referrer);
CREATE INDEX idx_referrals_referee ON referrals(referee);
CREATE INDEX idx_referrals_time ON referrals(bound_at DESC);

-- 推荐返佣统计表（可选，用于快速查询）
CREATE TABLE IF NOT EXISTS referral_earnings (
    referrer VARCHAR(42) PRIMARY KEY,              -- 推荐人地址
    total_referrals INT DEFAULT 0,                 -- 总推荐人数
    total_earnings NUMERIC(78, 0) DEFAULT 0,       -- 总返佣收益
    last_updated BIGINT NOT NULL                   -- 最后更新时间
);

-- 索引
CREATE INDEX idx_referral_earnings_total ON referral_earnings(total_earnings DESC);

-- ============================================
-- 添加注释
-- ============================================

COMMENT ON TABLE campaigns IS 'M2: 活动主表 - 存储所有运营活动';
COMMENT ON TABLE campaign_participations IS 'M2: 活动参与记录 - 用于奖励聚合';
COMMENT ON TABLE quests IS 'M2: 任务主表 - 存储所有用户任务';
COMMENT ON TABLE user_quest_progress IS 'M2: 用户任务进度 - 实时追踪任务完成情况';
COMMENT ON TABLE quest_completions IS 'M2: 任务完成记录 - 用于奖励聚合和审计';
COMMENT ON TABLE referrals IS 'M2: 推荐关系绑定 - 记录用户推荐关系';
COMMENT ON TABLE referral_earnings IS 'M2: 推荐返佣统计 - 聚合视图，加速查询';

-- 版本信息
INSERT INTO schema_version (version, description)
VALUES (5, 'M2: Campaign, Quest, Referral tables - 运营闭环')
ON CONFLICT (version) DO NOTHING;
