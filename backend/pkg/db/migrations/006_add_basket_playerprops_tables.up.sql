-- Migration 006: 添加 Basket (串关) 和 PlayerProps (球员道具) 相关表
-- Week 8: M3 扩玩法与串关

-- ============================================
-- Basket (串关) 相关表
-- ============================================

-- 串关主表
CREATE TABLE IF NOT EXISTS parlays (
    id BIGINT PRIMARY KEY,                         -- Parlay ID（来自链上）
    creator VARCHAR(42) NOT NULL,                  -- 创建者地址
    leg_count INT NOT NULL,                        -- 串关腿数（2-8）
    total_stake NUMERIC(78, 0) NOT NULL,           -- 总下注金额
    combined_odds NUMERIC(78, 0) NOT NULL,         -- 组合赔率（18 decimals, WAD）
    correlation_penalty_bps INT NOT NULL,          -- 相关性惩罚（基点）
    adjusted_odds NUMERIC(78, 0) NOT NULL,         -- 调整后赔率
    potential_payout NUMERIC(78, 0) NOT NULL,      -- 潜在赔付
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending/won/lost/refunded
    actual_payout NUMERIC(78, 0),                  -- 实际赔付（结算后）
    created_at BIGINT NOT NULL,                    -- 创建时间
    settled_at BIGINT,                             -- 结算时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    CONSTRAINT valid_leg_count CHECK (leg_count >= 2 AND leg_count <= 8),
    CONSTRAINT valid_stake CHECK (total_stake > 0),
    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_parlays_creator ON parlays(creator);
CREATE INDEX idx_parlays_status ON parlays(status);
CREATE INDEX idx_parlays_created ON parlays(created_at DESC);

-- 串关腿详情表
CREATE TABLE IF NOT EXISTS parlay_legs (
    id SERIAL PRIMARY KEY,
    parlay_id BIGINT NOT NULL REFERENCES parlays(id) ON DELETE CASCADE,
    leg_index INT NOT NULL,                        -- 腿序号（0-based）
    market_id VARCHAR(66) NOT NULL,                -- 市场ID
    market_address VARCHAR(42) NOT NULL,           -- 市场合约地址
    outcome INT NOT NULL,                          -- 下注方向
    odds NUMERIC(78, 0) NOT NULL,                  -- 该腿的赔率
    result VARCHAR(20),                            -- won/lost/pending/refunded
    settled_at BIGINT,                             -- 结算时间

    UNIQUE(parlay_id, leg_index)
);

-- 索引
CREATE INDEX idx_parlay_legs_parlay ON parlay_legs(parlay_id);
CREATE INDEX idx_parlay_legs_market ON parlay_legs(market_id);
CREATE INDEX idx_parlay_legs_result ON parlay_legs(result);

-- ============================================
-- PlayerProps (球员道具) 相关表
-- ============================================

-- 球员道具市场扩展表
-- 注意：基础市场信息仍存储在 markets 表中
CREATE TABLE IF NOT EXISTS player_props_markets (
    market_id VARCHAR(66) PRIMARY KEY REFERENCES markets(id) ON DELETE CASCADE,
    player_id VARCHAR(100) NOT NULL,               -- 球员ID（外部数据源）
    player_name VARCHAR(100) NOT NULL,             -- 球员名称
    prop_type VARCHAR(50) NOT NULL,                -- 道具类型（GOALS_OU, ASSISTS_OU, YELLOW_CARD等）
    line NUMERIC(18, 18),                          -- 盘口线（如 1.5 球，仅 O/U 类型）
    created_at BIGINT NOT NULL,                    -- 创建时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_player_props_player ON player_props_markets(player_id);
CREATE INDEX idx_player_props_type ON player_props_markets(prop_type);
CREATE INDEX idx_player_props_market ON player_props_markets(market_id);

-- FirstScorer 球员列表表（用于 FIRST_SCORER 类型市场）
CREATE TABLE IF NOT EXISTS first_scorer_players (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES player_props_markets(market_id) ON DELETE CASCADE,
    player_index INT NOT NULL,                     -- 球员序号（对应 outcome）
    player_id VARCHAR(100) NOT NULL,               -- 球员ID
    player_name VARCHAR(100) NOT NULL,             -- 球员名称
    team VARCHAR(50) NOT NULL,                     -- home/away

    UNIQUE(market_id, player_index)
);

-- 索引
CREATE INDEX idx_first_scorer_market ON first_scorer_players(market_id);
CREATE INDEX idx_first_scorer_player ON first_scorer_players(player_id);

-- 球员道具下注记录（可选，用于统计分析）
CREATE TABLE IF NOT EXISTS player_props_bets (
    id SERIAL PRIMARY KEY,
    market_id VARCHAR(66) NOT NULL REFERENCES player_props_markets(market_id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,             -- 用户地址
    outcome INT NOT NULL,                          -- 下注方向
    stake NUMERIC(78, 0) NOT NULL,                 -- 下注金额
    shares NUMERIC(78, 0) NOT NULL,                -- 获得份额
    timestamp BIGINT NOT NULL,                     -- 下注时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_player_props_bets_market ON player_props_bets(market_id);
CREATE INDEX idx_player_props_bets_user ON player_props_bets(user_address);
CREATE INDEX idx_player_props_bets_time ON player_props_bets(timestamp DESC);

-- ============================================
-- ScoreTemplate (精确比分) 相关表
-- ============================================

-- 精确比分市场扩展表
CREATE TABLE IF NOT EXISTS score_markets (
    market_id VARCHAR(66) PRIMARY KEY REFERENCES markets(id) ON DELETE CASCADE,
    liquidity_param NUMERIC(78, 0) NOT NULL,       -- LMSR b 参数
    outcome_count INT NOT NULL DEFAULT 36,         -- 结果数量（36 = 6x6）
    created_at BIGINT NOT NULL,                    -- 创建时间
    block_number BIGINT NOT NULL,                  -- 区块号
    tx_hash VARCHAR(66) NOT NULL,                  -- 交易哈希
    log_index INT NOT NULL,                        -- 日志索引

    UNIQUE(tx_hash, log_index)
);

-- 索引
CREATE INDEX idx_score_markets_market ON score_markets(market_id);

-- ============================================
-- 添加注释
-- ============================================

COMMENT ON TABLE parlays IS 'M3: 串关主表 - 存储所有串关组合';
COMMENT ON TABLE parlay_legs IS 'M3: 串关腿详情 - 记录每个串关的各个腿';
COMMENT ON TABLE player_props_markets IS 'M3: 球员道具市场 - 扩展 markets 表';
COMMENT ON TABLE first_scorer_players IS 'M3: 首个进球者候选球员列表';
COMMENT ON TABLE player_props_bets IS 'M3: 球员道具下注记录 - 用于统计分析';
COMMENT ON TABLE score_markets IS 'M3: 精确比分市场 - LMSR 参数';

COMMENT ON COLUMN parlays.correlation_penalty_bps IS '相关性惩罚（基点），如 2000 = -20%';
COMMENT ON COLUMN parlays.adjusted_odds IS '调整后赔率 = combined_odds * (1 - penalty)';
COMMENT ON COLUMN player_props_markets.prop_type IS '道具类型: GOALS_OU/ASSISTS_OU/YELLOW_CARD/FIRST_SCORER等';
COMMENT ON COLUMN score_markets.liquidity_param IS 'LMSR b 参数，控制市场流动性和价格敏感度';

-- 版本信息
INSERT INTO schema_version (version, description)
VALUES (6, 'M3: Basket, PlayerProps, ScoreTemplate tables - 扩玩法与串关')
ON CONFLICT (version) DO NOTHING;
