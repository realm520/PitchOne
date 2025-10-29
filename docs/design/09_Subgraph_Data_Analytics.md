# Subgraph / Data & Analytics 详细设计

## 1. 概述
- The Graph Subgraph 提供公开查询；内部 DB 提供实时与历史 BI 分析。

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
