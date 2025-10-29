# AMM（CPMM/LMSR）与线联动控制器详细设计

## 1. 概述
- 提供 WDL/OU/AH/比分等玩法的即时报价、滑点与成交；
- CPMM 用于二/三向；LMSR 用于多 Outcome（如比分网格）；
- 线联动控制器：对 OU/AH 相邻线价格进行联动与平滑，避免资金效率下降与被套利。

## 2. 数据与状态
- CPMM：`reserves[outcome]`；费率曲线/阶梯；
- LMSR：参数 `b`（流动度），持仓向量 `q`；成本函数 `C(q)=b*log(∑exp(q_i/b))`；
- 联动：`linkCoeff`、`rebalanceThreshold`、`spreadGuard`。

## 3. 接口（只读 + 写）
- `quote(outcome, stake) -> (price, fee, slippageBps)`（CPMM/LMSR 均实现）
- `applyTrade(outcome, stake) -> (deltaReserves)`（由 MarketBase 调用）
- 联动：`quoteLinked(line)`、`setLinkCoeff(coeff)`（治理）

## 4. 事件
- 使用 MarketBase 的 `BetPlaced/LiquidityChanged` 作为统一数据契约；
- 联动参数事件：`LinkParamUpdated(coeff)`。

## 5. 参数
- `feeBps_base/cap`、`b`、`linkCoeff`、`spreadGuard`、`rebalanceThreshold`。

## 6. 算法与不变量
- CPMM：`k = ∏ reserves_i` 不变量（考虑费率与滑点）；
- LMSR：无套利价格 `p_i = exp(q_i/b) / ∑exp(q/b)`；
- 联动：对 OU 多线以高斯核/线性核作价格平滑；对 AH 以盘口对称关系联动（-0.5 与 +0.5）；
- 数值稳定性：指数/对数域运算；上溢/下溢保护。

## 7. 权限与安全
- 仅 ParamController 改联动与做市参数；
- 对外只读接口不可改变状态；所有状态改变通过 MarketBase。

## 8. 测试计划
- 单测：价差/滑点与理论一致；大单后回归；
- 不变量：CPMM 守恒，LMSR 成本函数单调；
- 反套利：相邻线跨线对敲收益 < 阈值。

## 9. 运维要点
- 监控：价格漂移、价差过宽、异常成交笔数；
- 调参灰度：通过 FeatureFlag 与 ParamController 分阶段放量。
