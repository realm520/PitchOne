# Parlay Basket 与 CorrelationGuard 详细设计

## 1. 概述
- 支持多场串关；通过 CorrelationGuard 阻断同场同向或给予相关性惩罚。
- Basket 只聚合定价与份额，不改变底层市场结算逻辑。

## 2. 数据与状态
- `Basket {legs[], shares, price, penaltyBps}`
- 相关性矩阵由链下 Worker 计算，写入 ParamController（只读）。

## 3. 接口
- `addLeg(basketId, marketId, outcome)`（临时构建，不上链或上临时池）
- `quote(basketId, stake) -> (price, penaltyBps)`
- `purchase(basketId, stake, minOut)` → `BasketPurchased`

## 4. 事件
- `LegAdded`、`BasketQuoted(basketId, price, penaltyBps)`、`BasketPurchased(...)`

## 5. 参数
- `correlationPolicy = STRICT_BLOCK | PENALTY`
- `penaltyMatrix`、`maxLegs`、`minOdds`。

## 6. 安全与不变量
- 不串同场同向（STRICT_BLOCK）；或 PENALTY 下总边际收益受限；
- 边界：若某腿锁盘/退款，按剩余腿与规则处理（退款或按规则重算）。

## 7. 测试计划
- 相关性阻断/惩罚生效；极端组合的价格合理性。

## 8. 运维要点
- 相关性矩阵每日/每赛程刷新；灰度发布与回滚。
