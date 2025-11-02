# Subgraph / Data & Analytics 详细设计

## 🎯 实现状态

**Subgraph 部署**: ✅ 已完成（v0.3.0，本地 Graph Node 部署成功）
**基础设施**: ✅ 已完成（PostgreSQL 14 + IPFS Kubo v0.22.0 + Graph Node v0.34.1）
**Schema**: ✅ 已完成（10+ 实体类型，完整关系定义）
**Event Handlers**: ✅ 已实现（15+ handlers，支持 MarketCreated/BetPlaced/ResultProposed/FeeRouted 等）
**GraphQL API**: ✅ 可用（端到端数据流验证通过）
**内部 DB (Postgres)**: ✅ 已完成（7张表，11个索引，完整 Schema）

**验证状态**: ✅ 成功查询市场、订单、用户、头寸等数据

---

## 1. 概述
- The Graph Subgraph 提供公开查询；内部 DB 提供实时与历史 BI 分析。
- **✅ 完整的数据索引和查询层已部署并验证**

## 2. Schema 与实体（摘要）
- `Market/Bet/LiquidityEvent/Resolution/ReferralBinding/ReferralAccrual/RewardsRoot/RewardClaim/BasketPurchase` 等。

## 3. 映射规则
- 来源：合约事件（统一数据契约）；
- 聚合：DailyMetrics（volume/fees/activeUsers/promoSpend/lpAprEst）。

## 4. 查询与性能
- 常用查询：市场列表、盘口价格、用户头寸、奖励可领取；
- 性能：避免在 handler 中复杂派生；改为离线聚合。

## 5. 数据治理
- 版本化 schema；变更需兼容；Dune/Flipside 可选对外分析。

## 6. 监控
- 索引高度、延迟、实体增长速率；handler 失败报警。
