绝对要支持，而且要**从第一天**把“运营与增长”的可编排能力写进链上设计里。下面是一份**技术—运营一体化**清单：不写代码，只讲你在合约层需要预埋哪些模块、事件、参数与运行钩子，保证后续推广/返利/活动可以**低成本快速上线**，且全链上可验证。

# 1) 协议金流与预算闸门：为“推广/活动”留专用通道

* **FeeRouter / Treasury**

  * 交易费拆分比例（LP/协议/保险/Promo Pool）作为**可参数化**常量（由 ParamController 修改，Timelock 生效）。
  * **Promo Pool（推广池）**独立账户：支持“按周上限释放”“结转”“按比例缩放发放”。
  * 事件：`FeeRouted(marketId, lpShare, promoShare, insuranceShare, treasuryShare)`、`PromoBudgetSet(week, cap)`

> 价值：以后任何返佣、任务奖励、赛季空投都走 Promo Pool，**预算自带上限与透明度**。

# 2) 引荐与返佣：一次绑定、长期分成、按预算缩放

* **ReferralRegistry**

  * 首交互绑定 `referrer`（不可更改）；
  * 返佣窗口（如 90 天）、分层比例（8–12%）参数化。
* **PayoutScaler**

  * 当周 Promo Pool 余额不足时，对所有返佣/返利按权重**统一缩放**（写入叶子权重，见 §5）。
* 事件：`ReferralBound(user, referrer, campaignId?)`、`ReferralAccrued(user, referrer, fee, grossRebate, scaledRebate)`

> 价值：**可验证拉新**与**可控成本**两者兼得；推广侧无需改合约即可调配比例/周期。

# 3) 活动/任务可编排：Campaign & Quest 两层模型

* **CampaignFactory（活动工厂）**

  * 创建活动（起止时间、资格规则哈希、奖励类型与上限、预算来源=Promo Pool）；
  * **资格规则上链存 content hash**（实际判定可在链下计算，链上验证 Merkle）。
* **QuestHub（任务中心）**

  * 内置通用任务：首次下注、7日连续、首次 LP、串关等；
  * 每类任务的**计量口径**（下注额/有效天数/串关场次）参数化，配事件打点（见 §6）。
* 事件：`CampaignCreated(id, ruleHash, budgetCap)`、`QuestProgress(addr, questId, metric, value)`、`QuestCompleted(addr, questId)`

> 价值：市场运营可以**频繁开活动**而不改核心下注/AMM 合约。

# 4) 可转化且不可套现的奖励形态：Credit Token + Coupon

* **CreditToken（手续费抵扣额度）**

  * 仅能抵扣手续费/点差，不可提现；支持有效期、单笔抵扣上限。
* **Coupon（NFT/1155 优惠券）**

  * 串关加成券、免佣券、门票券（绑定活动 id）；
  * 与 Campaign 绑定发放与核销。
* 事件：`CreditGranted(addr, amount, expiry)`、`CouponRedeemed(addr, couponId, refMarket)`

> 价值：用“不可直接变现”的奖励，**降低套利风险**，提升真实参与度。

# 5) 统一发奖与结算：Merkle Distributor（周度根）

* **RewardsDistributor**

  * 每周将“返佣/返利/任务/赛季奖励”**聚合成一个 Merkle root**；
  * 叶子结构包含（addr, rewardType, amount, scaleFactor, campaignId, proofSalt）；
  * 用户自证领取；未领额度支持 N 周结转（可参数化）。
* 事件：`RewardsRootPublished(week, root, total, scale)`、`RewardClaimed(addr, week, amount)`

> 价值：把**所有运营奖励**统一在一套、安全且省 gas 的发放管道里，天然对账与透明。

# 6) 可观测与归因：从第一天就打点

* **最小埋点事件**（Subgraph/数据仓库可直接订阅）

  * `MarketCreated(marketId, league, ruleVer, startAt)`
  * `BetPlaced(user, marketId, outcome, stake, fee, referrer?, campaignId?)`
  * `LiquidityChanged(user, marketId, delta, side)`
  * `Locked(marketId)` / `ResultProposed/Challenged/Resolved`
  * `ReferralBound/Accrued`（见 §2）
  * `QuestProgress/Completed`（见 §3）
  * `RewardsRootPublished/Claimed`（见 §5）
* **Cohort & A/B 实验**

  * `ExperimentSalt`（周更），前端用 `cohort = keccak(addr, Salt) % N`；
  * `ExperimentAssigned(addr, expId, cohort)` 事件上链或由索引器生成。

> 价值：精准算 CAC/LTV、漏斗转化、活动 ROI；**A/B 实验**无需改合约逻辑，仅凭参数/前端分流即可。

# 7) 增长权限与信誉：SBT 做“门”，质押做“刹车”

* **PromoterSBT（不可转移）**

  * 分层权限：创建活动页、申请额外分成、获得上报收益分润等；
  * 叠加**信誉分**（依据历史有效拉新、违规记录、挑战胜率）。
* **Promoter Staking**

  * 高等级推广人需质押；若被判定“洗量/对敲”，从质押扣罚（仲裁走现有法庭）。
* 事件：`PromoterUpgraded(addr, tier)`、`PromoterSlashed(addr, amount, reason)`

> 价值：用**不可转移身份 + 质押**，把裂变推广的“动力”和“约束”都链上化。

# 8) 反作弊信号与灰度开关：让风控与运营可调

* **RiskScorer（只读评分合约/控制器）**

  * 标准输入：地址图谱特征（对手盘重合度、资金互转、同批次券互用等）+ 可选外部人机分；
  * 输出：`score ∈ [0,100]` 与标签；
  * **PayoutScaler**/Campaign 可读取分值，低分地址奖励打折或延迟释放。
* **灰度开关**

  * 针对新玩法/新联赛：`FeatureFlagSet(flagId, enabled, allowlist?)`，仅白名单可见/可用。

> 价值：**先放小流量灰度**，运营可控迭代；风险可“边发边降权”。

# 9) 自动化钩子：让活动自然启动/结束

* **Keepers/Automations**

  * 活动开始/结束、锁盘、结果确认、周度根发布、过期券清理、线性释放 Tick。
* 事件：`KeeperExecuted(taskId, ok, gasUsed)`
* **ParamController + Timelock**

  * 所有关键比率、窗口期、额度上限都由 ParamController 管，提案 → Timelock → 生效，**避免人工紧急改表**。

# 10) 面向“增长仪表盘”的数据契约（最小指标字典）

* **获客**：`new_users`, `ref_bound_rate`, `cost_per_acquisition`（从 RewardsRoot 聚合）
* **转化**：`first_bet_conv`, `first_lp_conv`, `retention_d7/d30`
* **收入**：`gtv`, `fee_gross`, `promo_spend`, `lp_apr`
* **风控**：`oracle_tta_median`, `challenge_rate`, `invalid_rate`, `fraud_suppression_ratio`
* **活动**：`campaign_roi`, `coupon_redeem_rate`, `quest_completion_rate`

> 价值：这些都能由上述事件直接衍生，**无需额外埋点**。

---

## 决策建议（TL;DR）

* **是的**，链上部分必须为运营/推广预埋：**预算池、返佣绑定、活动工厂、统一发奖、可观测事件**这五件套。
* 采用**参数化 + Timelock**来支撑“快调参、慢生效”的增长节奏，避免频繁改合约。
* 奖励统一走**Merkle Distributor**与**Credit/Coupon**，既省 gas 又抗套利。
* 从第一天就输出数据契约（事件/字段），保证增长与风控能“看得见、调得动”。

如果你愿意，我可以把以上模块整理成一张**合约—事件—参数对照表**（可直接给研发）和**增长运营 SOP 甘特图**，用于你们的 0→1 实施。

