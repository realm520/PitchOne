# PitchOne_权限与角色矩阵.md

> 目的：明确**谁**能在**什么条件**下对**哪些合约/函数**进行操作；配套紧急策略、最小权限与审计要点。
> 原则：**最小权限** · **可追责** · **可回滚** · **资金路径与参数路径分离**。

## 1. 角色定义（链上）

| 角色                    | 说明          | 载体/实现                | 典型权限                                    |
| --------------------- | ----------- | -------------------- | --------------------------------------- |
| **GOVERNOR**          | 治理合约（提案/投票） | Governor（veP1 权重或多签） | 提案参数/模板变更、授权 Timelock 队列                |
| **TIMELOCK**          | 延时执行器       | Timelock 合约          | 执行已通过的参数/升级/权限变更                        |
| **SAFE_MULTISIG**     | 金库与应急多签     | Gnosis Safe 多签       | 国库转账、应急暂停开关、审计后小范围变更                    |
| **PAUSER**            | 只读暂停        | 受限角色（可由多签托管）         | 触发/解除只读暂停（不停兑付）                         |
| **KEEPER**            | 自动化执行       | Gelato/自建 Keeper 地址  | `lock()`、`finalize()`、`publish()` 等周期任务 |
| **ORACLE**            | 赛果上报/挑战     | 受控地址（可多签/白名单）        | `propose/dispute/finalize`（OO 适配）       |
| **REWARDS_PUBLISHER** | 周度根发布       | CI 服务/多签             | `publish(week,root,scaleBps)`           |
| **PARAM_SETTER**      | 参数写入端       | 仅 TIMELOCK           | `apply(key)` 最终生效                       |
| **MARKET_CREATOR**    | 市场创建权限（可选）  | 白名单+押注门槛             | `createMarket(templateId,...)`          |
| **PROMOTER**          | 推广者身份       | SBT+Staking          | 参与联名活动预算申请、返佣提升                         |
| **USER/LP**           | 普通用户/流动性提供者 | EOA/合约钱包             | `buy/sell/claim`、`deposit/withdraw`     |

> 建议：**治理与资金多签分离**（Governor 负责策略，Safe 负责金库/应急），**参数更改必须走 Timelock**，Keeper/Oracle 使用**独立专用地址**。

## 2. 合约 × 功能 × 角色矩阵（核心）

> 说明：R=只读、C=可调用（含状态改动）、A=仅治理/多签；`→` 表示通过 Timelock 间接生效。

| 合约 / 模块                | 函数/能力                      |       USER/LP | KEEPER | ORACLE | REWARDS_PUBLISHER | PAUSER | SAFE_MULTISIG |     GOVERNOR |     TIMELOCK |
| ---------------------- | -------------------------- | ------------: | -----: | -----: | ----------------: | -----: | ------------: | -----------: | -----------: |
| **MarketBase**         | `quoteBuy/quote`           |             R |      R |      R |                 R |      R |             R |            R |            R |
|                        | `buy/sell/claim`           |         **C** |        |        |                   |        |               |              |              |
|                        | `lock()`                   |               |  **C** |        |                   |        |               |              |              |
|                        | `resolve(facts)`           |               |        |  **C** |                   |        |               |              |              |
|                        | `pause/unpause`（只读暂停）      |               |        |        |                   |  **C** |         **C** |              |              |
| **MarketFactory**      | `createMarket`             |         C/白名单 |        |        |                   |        |               |              |              |
| **AMM(LMSR/CPMM)**     | 报价/成交                      | 透过 MarketBase |        |        |                   |        |               |              |              |
| **Parlay/Basket**      | `quote/purchase`           |         **C** |        |        |                   |        |               |              |              |
| **CorrelationGuard**   | 参数                         |             R |        |        |                   |        |               |      `queue` |      `apply` |
| **ResultOracle(OO)**   | `propose/dispute/finalize` |               |        |  **C** |                   |        |               |              |              |
| **FeeRouter**          | `route`                    |               |        |        |                   |        |               |              |              |
| **Vault(ERC-4626)**    | `deposit/withdraw`         |         **C** |        |        |                   |        |               |              |              |
| **RewardsDistributor** | `publish/claim`            |               |        |        |       **C**/**R** |        |               |              |              |
| **ReferralRegistry**   | `bind/getReferrer`         |       **C/R** |        |        |                   |        |               |              |              |
| **Campaign/Quest**     | `create`                   |               |        |        |     **C**/**GOV** |        |               |      `queue` |      `apply` |
| **ParamController**    | `queue/apply/get`          |             R |        |        |                   |        |               | **C(queue)** | **C(apply)** |
| **Governance**         | 提案/投票/执行                   |               |        |        |                   |        |               |        **C** |        **C** |
| **P1 / veP1**          | `mint/burn`、`create_lock`  |               |        |        |                   |        |         **A** |      `queue` |      `apply` |
| **Gauge/Emissions**    | `vote/distribute`          |   **C**（veP1） |        |        |                   |        |               |              |              |
| **Buyback**            | `buyback/burn`             |               |        |        |                   |        |         **C** |      `queue` |      `apply` |

## 3. 最小权限清单（落地用）

* **MarketBase** 仅允许：`KEEPER.lock()`、`ORACLE.resolve()`、`PAUSER.pause()`；其余皆公开/只读。
* **ParamController** 对**所有可调参数**唯一写口：`GOVERNOR.queue → TIMELOCK.apply`；外部模块**只读**。
* **FeeRouter** 不暴露改变分账的外部写口，改动同样走 `queue/apply`。
* **RewardsDistributor** 的 `publish` 由 **REWARDS_PUBLISHER**（CI/多签）持有，方便周度运营；如预算异常由 Timelock 调参。
* **Buyback** 的资金来源与阈值由治理提案，不允许任意账户调用造成资金风险。

## 4. 紧急流程与回滚

* **只读暂停（Soft Pause）**：停止 `buy/sell`、停止新市场创建，**不影响 `claim` 与资金赎回**。
* **强制退款（Refundable）**：预言机异常/赛事取消触发；`RefundableOpened(marketId, reason)`。
* **热修复/回滚**：新合约以 `Proxy` 升级（强烈建议最小化使用），所有升级必须 `queue → apply`；如升级失败回滚到前一实现。
* **密钥轮换**：`KEEPER、ORACLE、REWARDS_PUBLISHER、PAUSER` 均可在 Timelock 保护下轮换。

## 5. 审计要点（速查）

* 参数更改路径唯一、Timelock 生效延时**大于等于**质押/争议窗口；
* `pause` 不影响兑付；
* 资金路径：仅 **MarketBase ↔ FeeRouter ↔ Vault**；
* 事件作为**数据契约**与审计痕迹；
* 断言与不变量（见各模块详细设计）。

---

# PitchOne_错误码字典.md

> 目的：统一自定义错误（Solidity `error`），便于前端提示、后端监控、审计回溯。
> 规范：`模块前缀_语义`，必要时附带参数；**尽量短小**、**语义明确**、**分层清晰**。

## 0. 命名规范与返回方式

* Solidity 自定义错误：`error Market_InvalidState(uint8 expected, uint8 actual);`
* 组合校验先后：**权限 → 状态 → 参数 → 业务约束 → 外部依赖**
* 前端映射：将错误码 → 人类可读中文；后端记录 `txHash + errorSelector` 生成统计。

---

## 1. MarketBase / 模板（WDL/OU/AH/比分）

| 错误码                                     | 触发条件（摘要）                      | 修复/提示               |
| --------------------------------------- | ----------------------------- | ------------------- |
| `Market_InvalidState(expected, actual)` | 非法状态调用（如 `sell` 在 `Resolved`） | 重试前检查状态             |
| `Market_Locked()`                       | 距开赛已锁盘/已锁                     | 选择其他盘口/等待结算         |
| `Market_SlippageTooHigh(max, got)`      | `quote`/`buy` 价格变动超过限制        | 调整 `minOut`/金额      |
| `Market_ExposureExceeded(limit, want)`  | 地址敞口超过限制                      | 降低下单额/提高权限等级        |
| `Market_InsufficientShares(want, have)` | 卖出/兑付份额不足                     | 检查持仓                |
| `Market_AlreadyResolved()`              | 重复结算                          | 忽略重复操作              |
| `Market_NotWinner(outcome)`             | 兑付非赢家                         | 选择正确的 outcome       |
| `Market_Paused()`                       | 只读暂停期                         | 等待恢复                |
| `Market_Forbidden()`                    | 非白名单/无权限调用（如 `lock`）          | 使用 Keeper/Oracle 地址 |
| `Market_RefundOnly()`                   | 进入退款态仅支持退款路径                  | 执行退款                |

---

## 2. AMM（CPMM/LMSR/联动）

| 错误码                           | 触发条件             | 修复/提示         |
| ----------------------------- | ---------------- | ------------- |
| `AMM_BadOutcome()`            | 非法 outcome 索引    | 检查传参          |
| `AMM_InsufficientLiquidity()` | 流动性不足导致无法成交/价格爆炸 | 降低交易量/等待补充 LP |
| `AMM_KInvariantViolation()`   | CPMM 不变量破坏（内部保护） | 报告并回溯交易       |
| `AMM_NumberOverflow()`        | LMSR 指数/对数域溢出保护  | 降低输入/拆单       |
| `AMM_SpreadGuard()`           | 联动价差超过限制         | 等待回补/调整参数     |

---

## 3. Parlay / CorrelationGuard

| 错误码                                  | 触发条件         | 修复/提示       |
| ------------------------------------ | ------------ | ----------- |
| `Parlay_TooManyLegs(max)`            | 超过最大串关腿数     | 减少组合数       |
| `Parlay_BlockSameMatch()`            | 同场同向被阻断策略    | 选择不同场次或相反方向 |
| `Parlay_CorrelationHigh(penaltyBps)` | 相关性过高（惩罚或阻断） | 接受惩罚或更换组合   |
| `Parlay_LegLockedOrRefund()`         | 其中一腿已锁盘/退款   | 替换该腿或重新组合   |

---

## 4. ResultOracle（OO 适配）

| 错误码                            | 触发条件                    | 修复/提示       |
| ------------------------------ | ----------------------- | ----------- |
| `Oracle_BondTooLow(min, got)`  | 质押不足                    | 增加质押后重试     |
| `Oracle_LivenessOngoing()`     | 仍在争议窗口内                 | 等待窗口结束      |
| `Oracle_NoPropose()`           | 未上报直接 finalize          | 先 `propose` |
| `Oracle_AlreadyFinalized()`    | 重复 finalize             | 忽略          |
| `Oracle_InvalidFacts()`        | MatchFacts 不合法（范围/口径不符） | 修正事实结构      |
| `Oracle_Unauthorized()`        | 非 Oracle 白名单            | 使用授权地址      |
| `Oracle_DisputeWindowClosed()` | 过期争议                    | 下个周期处理      |

---

## 5. FeeRouter / Treasury / Insurance

| 错误码                           | 触发条件              | 修复/提示       |
| ----------------------------- | ----------------- | ----------- |
| `FeeRouter_InvalidSplitSum()` | 分账权重不等于 10000 bps | 通过治理修正      |
| `FeeRouter_Forbidden()`       | 非白名单调用 `route`    | 仅 Market 调用 |
| `Treasury_OnlySafe()`         | 非多签提取/回购          | 走 Safe 流程   |
| `Insurance_ConditionNotMet()` | 不满足赔付条件           | 走治理提案       |

---

## 6. Vault（ERC-4626）

| 错误码                          | 触发条件   | 修复/提示 |
| ---------------------------- | ------ | ----- |
| `Vault_InsufficientAssets()` | 提取超出资产 | 降低提取量 |
| `Vault_ExceedsCap()`         | 超出金库上限 | 等待扩容  |
| `Vault_Paused()`             | 暂停期间   | 等待恢复  |

---

## 7. Rewards / Referral / Campaign

| 错误码                            | 触发条件         | 修复/提示     |
| ------------------------------ | ------------ | --------- |
| `Rewards_AlreadyClaimed()`     | 重复领取         | 无需操作      |
| `Rewards_InvalidProof()`       | Merkle 证明不通过 | 检查输入/等待下期 |
| `Rewards_ScaledDown(scaleBps)` | 预算缩放提示（非错误）  | 仅 UI 提示   |
| `Referral_AlreadyBound()`      | 已绑定推荐人       | 不可更改      |
| `Referral_InvalidReferrer()`   | 推荐人无效        | 更换有效地址    |
| `Campaign_BudgetExceeded()`    | 超出活动预算上限     | 等待补充/下期   |
| `Campaign_Expired()`           | 活动过期         | 选择有效活动    |
| `Coupon_Expired()`             | 券过期          | 重新领取      |

---

## 8. ParamController / Governance / Flags

| 错误码                        | 触发条件             | 修复/提示       |
| -------------------------- | ---------------- | ----------- |
| `Param_NotQueued()`        | 未 queue 直接 apply | 先提案排队       |
| `Param_NotReady(eta, now)` | 未到延迟时间           | 等待 ETA      |
| `Param_ForbiddenKey()`     | 非法/受限键写入         | 审核键名白名单     |
| `Flag_NotAllowed()`        | 灰度白名单拒绝          | 加入白名单或等全量放开 |

---

## 9. Tokenomics（P1 / veP1 / Gauge / Emissions / Bribe / Buyback / OracleStaking）

| 错误码                            | 触发条件           | 修复/提示           |
| ------------------------------ | -------------- | --------------- |
| `P1_MintDisabled()`            | 非治理铸币          | 走治理             |
| `P1_BurnDisabled()`            | 非治理销毁          | 走治理             |
| `veP1_LockTooShort()`          | 低于最小锁期         | 延长锁期            |
| `veP1_LockTooLong()`           | 超过最大锁期         | 缩短时长            |
| `veP1_NoIncreaseAfterExpiry()` | 锁已到期不能加仓       | 先延长到期时间         |
| `Gauge_VoteCapExceeded()`      | 单 Gauge 超过投票上限 | 调整权重            |
| `Gauge_NotWhitelisted()`       | 非白名单 Gauge     | 申请白名单           |
| `Emissions_NotDistributor()`   | 非排放控制器地址       | 通过控制器调用         |
| `Bribe_TokenNotAllowed()`      | 非允许代币          | 使用 P1/USDC 等白名单 |
| `Buyback_OnlySafe()`           | 非多签发起回购        | 走 Safe          |
| `Staking_InsufficientStake()`  | 质押不足参与上报/仲裁    | 增加 P1 质押        |
| `Staking_Slashed()`            | 被罚没状态限制操作      | 等待治理/申诉         |

---

## 10. Risk / Exposure / Correlation

| 错误码                                       | 触发条件               | 修复/提示   |
| ----------------------------------------- | ------------------ | ------- |
| `Risk_AddrExposureExceeded(scope, limit)` | 地址在 scope（联赛/比赛）超限 | 降低下单额   |
| `Risk_GlobalGuard()`                      | 风险总闸触发             | 等待恢复/降温 |
| `Correlation_MatrixMissing()`             | 缺少相关性矩阵            | 等待刷新后重试 |

---

## 11. 前端提示映射（建议）

* 将上述错误映射为用户可读文案；同时保留 `selector` 与 `params` 以便埋点与数据分析（识别高频失败原因）。
* 重要：**对 `ScaledDown` 等“提醒型”非致命状态**，只提示不报错，保证流程连续性。

---

### 备注

* 错误码覆盖最小必要集，具体合约可在此基础上扩展专有错误（例如 OU/AH/比分专有校验）。
* 建议在 `design_docs/` 中与模块详细设计放在同级，以便联动更新；CI 中可校验“设计文档中的错误码”与“合约实现的 `error` 声明”一致性。

---


