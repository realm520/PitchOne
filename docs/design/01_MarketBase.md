# MarketBase 详细设计（含 WDL/OU/AH 模板基底）

## 1. 概述
- **职责**：管理市场生命周期（Open/Locked/Resolved/Refundable）、下注/卖出/兑付资金路径、ERC-1155 头寸发行与销毁；为各模板（WDL/OU/AH/比分）提供统一基底。
- **外部依赖**：AMM 定价器（CPMM/LMSR）、FeeRouter、ParamController、ResultOracle、Vault（ERC-4626）、Growth（Referral/Rewards）。
- **边界**：不直接持久化运营/风控规则，仅调用只读/返回系数的策略合约；**资金只经 MarketBase 与 FeeRouter**。

## 2. 数据与状态
- **状态机**：`Pending → Open → Locked → Resolved | Refundable`
- **核心存储**
  - `mapping(outcome => Reserve)`：做市储备/净头寸
  - `ERC1155 balances(user, outcome)`：用户持仓份额（shares）
  - `marketId, templateId, matchId, ruleVer(bytes32)`
  - `lockedAt(uint64), resolvedAt(uint64), winnerOutcome(int)`
  - `accFee(uint256)`：累计手续费（只读统计）
- **精度**：内部统一 1e18 定点；支持多 collateral 需在 Router 统一小数。

## 3. 接口定义（核心）
- `quoteBuy(uint256 outcome, uint256 stake) -> (uint256 price, uint256 fee, uint256 slippageBps)`  
  只读；从 AMM + 联动控制器获取即时报价与预估滑点与费率。
- `buy(uint256 outcome, uint256 stake, uint256 minOut, address referrer, bytes32 campaignId) -> (uint256 shares)`  
  前置：`state==Open`、`now < kickoff - lockAheadSecs`、`slippageBps <= max`、`exposure <= limit`。成功后：铸造 ERC-1155；触发 `BetPlaced`；将 `fee` 路由到 FeeRouter。
- `sell(uint256 outcome, uint256 shares, uint256 minOut) -> (uint256 collateralOut)`  
  允许 `Open/Locked`（Locked 时可能更高费/折价）；销毁头寸；触发 `LiquidityChanged`。
- `claim(uint256[] outcomes, uint256[] shares, address to) -> uint256 paid`  
  前置：`state==Resolved`；仅赢家可兑付；一次或多次均可；触发 `PayoutClaimed`。
- `lock()`：仅 Keeper 角色；写 `lockedAt`，触发 `Locked`。
- `resolve(MatchFacts facts)`：仅 Oracle 最终态；设置 `winnerOutcome`，触发 `Resolved`。

## 4. 事件契约
- `BetPlaced(user, marketId, outcome, stake, fee, referrer, campaignId)`
- `LiquidityChanged(user, marketId, int256 delta)`
- `Locked(marketId, ts)` · `Resolved(marketId, winnerOutcome, factsHash)`
- `PayoutClaimed(user, marketId, amount)` · `RefundableOpened(marketId, reason)`

## 5. 参数（ParamController 键）
- `feeBps_base/cap`（锁盘前阶梯上调）、`lockAheadSecs`、`slippageMaxBps`、`maxExposurePerAddrBps`、`ou.linkCoeff`、`ah.linkCoeff`。

## 6. 算法/不变量
- **守恒**：总抵押 = 各 outcome 储备 + 待分配费用 + 可提取余额；
- **一次性结算**：`Resolved` 后赢家集合确定且不可再变；
- **价格保护**：`slippageBps` 与 `spreadGuard` 边界校验；
- **四分之一球**：内部等权拆分两条线（如 -0.25 = -0.5 与 0），份额/结算按比例聚合。

## 7. 权限与安全
- 角色：`KEEPER`（lock）、`ORACLE`（resolve）、`GOV`（参数/模板）、`PAUSER`（只读暂停）。
- 最小权限：外部策略合约只读；FeeRouter/ParamController 白名单；不可重入（Checks-Effects-Interactions）。

## 8. 测试计划
- 单测：正常下单/卖出/兑付、锁盘窗口、滑点保护、四分之一球拆分、退款路径；
- 不变量（Echidna）：随机 buy/sell/lock/resolve 序列下资金守恒、赢家唯一；
- 断言（Scribble）：事件与状态一致性、费率非负、claim 幂等；
- 回放（Tenderly）：极端滑点/临界锁盘/小数精度。

## 9. 运维要点
- Keeper 提前量与失败重试；锁盘失败的兜底（手工 lock）；
- 监控：`BetPlaced/Locked/Resolved` 速率、失败 tx、Gas 异常；
- 风险开关：只读暂停 = 停新建/卖出，兑付不影响。
