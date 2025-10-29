# 项目简介（技术驱动版）

## 1. 项目介绍

**项目名称**：去中心化链上足球博彩（Sportsbook / Prediction Markets）
**核心定位**：基于区块链的非托管博彩市场，围绕足球赛事提供“胜平负、大小球、让球、精确比分、球员道具”等多玩法，做到**上链可验证、结算自动化、运营可编排、低人工干预**。
**目标人群**：加密原生用户、体育爱好者、量化玩家/LP 供给侧、海外社群与 KOL。
**核心卖点**：

* **全链透明**：市场创建、下注、赔率、赛果、结算与发奖均上链留痕；
* **非托管资产**：用户资金以代币化头寸形式自持，可随时流动/套现；
* **自动化结算**：乐观式预言机 + 仲裁层，绝大多数场景零人工；
* **可扩展玩法**：通过“模板化市场”快速扩展 OU/AH/比分/球员道具；
* **增长内生**：返佣、任务、活动、赛季榜等全部链上治理与发放。

---

## 2. 技术方案（Architecture）

### 2.1 合约与资产

* **MarketTemplateRegistry / MatchFactory**：基于联赛/赛事创建市场；模板化支持

  * 模板：**WDL（胜平负）**、**OU（大小球多线）**、**AH（让球/四分之一球）**、**Correct Score**、**BTTS**、**Player Props** 等；
* **头寸标准**：ERC-1155（或 CTF 风格）表示 Outcome 头寸；**LP 金库**采用 ERC-4626；
* **做市/定价**：

  * V1：**CPMM**（二/三向） + **LMSR**（多 Outcome/比分网格）；
  * 线型玩法引入**相邻线联动控制器**与**共享抵押池**（提升资金效率）；
  * V2：预留**混合 CLOB 插槽**（签名订单链上结算）与 AMM 并存路由；
* **串关（Parlay）**：Basket 合约 + **CorrelationGuard**（同场同向惩罚/阻断），并设**同场合并限额**；
* **预言机/结算**：

  * **乐观式预言机**（对接 UMA OO 或自建 OO）：Propose(质押) → Dispute → Resolve；
  * 统一结构化 `MatchFacts`（进球数/是否含加时点球…），各玩法以 `payout = f(facts)` 结算；
* **费用与金库**：FeeRouter 将费用拆分至 LP / **Promo Pool**（推广池）/ 保险 / 国库；
* **运营基建**：ReferralRegistry（一次绑定长期分成）、RewardsDistributor（周度 Merkle）、Campaign/Quest（活动/任务）、Credit/Coupon（免佣/串关加成券）、**PayoutScaler**（预算不足按权重缩放）；
* **参数与治理**：ParamController + Timelock + 多签（Safe），**内核尽量免升级**，策略可插拔；
* **自动化**：Keeper（Gelato/Chainlink + 自建冗余）执行锁盘、开启争议、发布周度根等。

### 2.2 链下与数据

* **后端（Go 为主）**：Indexer（事件入库）、Keeper Service、Rewards Builder、Risk & Pricing Worker（线联动/相关性）、只读 API 网关；
* **索引与可观测**：The Graph Subgraph + Postgres/Timescale + Grafana/Prometheus + OpenTelemetry；
* **安全与质量**：Foundry（单测/不变量/覆盖率）、Slither、Echidna、Scribble 断言、Tenderly 回放；外审与漏洞赏金。

### 2.3 关键规则与风控

* **锁盘策略**：开赛前 N 分钟（默认 10 分钟）禁新买，仅允许卖出或撤 LP；球员类更早锁盘；
* **赛果边界**：明确 90 分钟口径/加时/点球、延期/腰斩退款路径；
* **风控**：单地址敞口、同场同向合并限额、临近开赛费率阶梯、反对敲与返佣灰度（基于 RiskScorer）；
* **清算与发奖**：Resolved 后可直接兑付或走 **Merkle Payout**；运营奖励统一走 RewardsDistributor。

---

## 3. 业务推广与增长机制

### 3.1 引荐与返佣（Referral）

* **一次绑定，长期分成**：推荐人获被推荐人净费率 **8%–12%**（90 天滚动），被推荐人返利 **2%–5%**；
* **Promo Pool 预算闸门**：当周费用抽成的 20% 注入推广池，所有返佣/返利/活动支出从此池扣减；不足自动缩放（PayoutScaler）；

### 3.2 任务 / 活动 / 赛季

* **On-chain Quests**：首单、7 日连续、首次 LP、串关等任务发放 **Credit/Coupon**；
* **赛季榜**：按有效投注额（对数缩放）× 活跃天数计分；Top 区间空投/纪念 NFT；
* **战队与 KOL 主题页**：SBT 赋权的推广者可创建主题页，来源成交额外 +1% 返佣（从 Promo Pool）；

### 3.3 反作弊（不涉合规，仅经济机制）

* 有效用户判定（笔数/金额阈值 + 关系图谱 + 可选人机分）；
* 对手盘重合度/资金互转检测，返佣不计入或降权；
* 返佣 **T+7 线性释放** 与申诉仲裁通道；高等级推广人需质押，恶意洗量可罚没。

### 3.4 冷启动策略（90 天）

* **M0–M1（0–4 周）**：只做一条联赛 + WDL/OU(2.5)；集中流动性与体验；UMA OO 接入；
* **M2（5–8 周）**：OU 多线 + 联动、AH(-0.5)；任务/活动/周度 Merkle 跑通；
* **M3（9–12 周）**：扩精确比分（LMSR）与 1–2 个球员道具；灰度 CLOB 插槽；
* KPI：WAU、GTV、D7 留存、预言机上报时延、挑战率、Promo Spend/LTV、LP APR 等。

---

## 4. 里程碑与排期（摘要）

* **M0 脚手架（第 1 周）**：Foundry 合约骨架、事件契约；Go Indexer；Subgraph 首版；CI/CD
* **M1 主流程闭环（第 3–4 周）**：WDL + OU(单线)、AMM、锁盘→结算→兑付；UMA OO 接入；Rewards/Referral
* **M2 运营闭环（第 5–8 周）**：活动/任务/周度 Merkle、仪表盘；OU 多线 + 联动；AH(-0.5)
* **M3 扩玩法与插槽（第 9–12 周）**：精确比分（LMSR）、Props（1–2）、CLOB 插槽灰度、风控进阶

---

## 5. 成本与收益（高层）

* **主要成本**：合约审计与运行（L2 Gas/预言机质押/保守 Keeper）、增长预算（Promo Pool）、后端与监控运维；
* **收益来源**：交易费（对 LP/国库/推广池分成）、活动资源流转、潜在做市收益（LP 侧）；
* **财务护栏**：预算池上限 + 统一缩放；费率临近锁盘阶梯上调；风险敞口限额与相关性惩罚。

---

## 6. 风险与对策

* **预言机失灵**：多源备援 + 乐观式挑战 + 保险金库；
* **流动性碎片化**：共享抵押池 + 相邻线联动 + 热线优先；
* **增长刷量**：有效用户规则 + 关系图谱 + 线性释放与质押惩罚；
* **合约风险**：不变量/断言、Echidna 模糊、外审 + Bounty、最小可升级面。

---

## 7. 交付物与工程化

* **合约**：Market* 模板、FeeRouter、ParamController、RewardsDistributor、ReferralRegistry、Basket、Oracle 适配器；
* **后端**：Indexer/Keeper/Rewards/Risk Workers（Go），只读 API；
* **数据**：Subgraph、Postgres 指标表、Grafana 看板与告警；
* **DevOps**：K8s + Helm + Terraform；CI（Foundry/Slither/Echidna/Tenderly）；Safe/Timelock 权限；
* **文档**：ABI/事件/错误码手册、Runbook、风控白皮书（IPFS 指纹）、版本发布日志。

---

## 8. 一句话总结

以**“可验证资金安全的内核 + 可插拔策略层 + 乐观式结算 + 运营五件套”**为主干，先用 **AMM** 冷启动，再按模板扩玩法、按插槽演进撮合；所有增长与风控可链上配置与灰度，确保**可持续的拉新—留存—复投闭环**。

