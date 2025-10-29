# ResultOracle（乐观式预言机/UMA OO 适配）详细设计

## 1. 概述
- 以乐观式流程采集比赛事实（MatchFacts）：`propose → dispute → resolve`；
- 市场读取最终事实进行结算，避免中心化人工判定。

## 2. 数据与状态
- `bond`（质押）、`liveness`（争议窗口 Δ2）、`sourceBundleHash`（事实来源证明）
- MatchFacts 结构：`scope("FT_90")`、`homeGoals`、`awayGoals`、`extra_time`、`penalties{home,away}`、`reportedAt`。

## 3. 接口
- `propose(bytes32 marketId, MatchFacts facts, uint256 bond)`
- `dispute(bytes32 marketId)`
- `finalize(bytes32 marketId)` → 写入 `factsHash` 并通知 MarketBase。

## 4. 事件
- `ResultProposed(marketId, factsHash, proposer, bond)`
- `ResultDisputed(marketId, challenger)`
- `ResultResolved(marketId, factsHash, accepted)`

## 5. 参数
- `bond = max(基准, 奖池 * ratio)`；`liveness 30–120m`；仲裁治理地址。

## 6. 安全/仲裁
- 反女巫/博弈：足额质押 + 双向质押；
- 多源对账：预留 `sourceBundleHash`；
- 仲裁终局：Governor 多签 + Timelock 执行 `resolve`。

## 7. 测试计划
- 正常：无人异议直接生效；
- 对抗：错误 propose 被 dispute → 仲裁；
- 边界：延期/腰斩 → Refundable 流程。

## 8. 运维要点
- Keeper 编排 propose/dispute；
- 监控挑战率、上报延迟、仲裁平均时长。
