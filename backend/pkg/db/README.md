# PitchOne Database Schema

## 数据库初始化

**最后更新**: 2025-12-31
**数据库版本**: PostgreSQL 14

---

## 快速开始

```bash
# 设置环境变量
export DATABASE_URL="postgresql://user:password@localhost:5432/pitchone"

# 初始化数据库
psql $DATABASE_URL -f backend/pkg/db/init.sql
```

---

## 文件结构

| 文件 | 说明 |
|------|------|
| `init.sql` | 完整的数据库初始化脚本（第一版） |
| `test_crud.sql` | CRUD 操作测试脚本 |
| `test_constraints.sql` | 约束和关联验证测试 |
| `client.go` | 数据库连接客户端 |

---

## 数据库表一览

`init.sql` 包含 24 张表：

### 核心业务表
- `markets` - 市场元数据
- `orders` - 下注订单
- `positions` - ERC-1155 持仓
- `payouts` - 兑付记录

### Keeper 服务表
- `keeper_tasks` - 自动化任务
- `alert_logs` - 告警日志
- `fixtures` - 比赛赛程（API-Football 数据）

### 奖励与推荐
- `rewards` - 奖励记录
- `referrals` - 推荐关系
- `referral_earnings` - 推荐收益
- `reward_entries` - 奖励条目
- `reward_distributions` - 奖励分发
- `merkle_proofs` - Merkle 证明

### 活动与任务
- `campaigns` - 活动
- `campaign_participations` - 活动参与
- `quests` - 任务
- `quest_completions` - 任务完成
- `user_quest_progress` - 用户进度

### 串关与道具
- `parlays` - 串关投注
- `parlay_legs` - 串关腿
- `player_props_markets` - 球员道具市场
- `player_props_bets` - 球员道具下注
- `first_scorer_players` - 首位进球者

### 扩展市场
- `score_markets` - 精确比分市场

### 系统表
- `indexer_state` - Indexer 状态
- `schema_version` - Schema 版本

---

## 测试

```bash
# 运行 CRUD 测试
psql $DATABASE_URL -f backend/pkg/db/test_crud.sql

# 运行约束测试
psql $DATABASE_URL -f backend/pkg/db/test_constraints.sql
```

---

**版本**: v1.0
