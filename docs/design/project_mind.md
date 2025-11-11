# 去中心化足球博彩 - 技术架构思维导图

```mermaid
mindmap
  root((去中心化足球博彩｜技术驱动交付))
    ["项目治理/PMO[Owner: Tech PM/架构委员会]"]
      ["节奏与里程碑: 0→1→扩玩法→放大期"]
      需求冻结与变更SOP
      风险台账与上线准入标准
    ["链上内核(核心合约)[Owner: Solidity Team]"]
      ["市场模板总线(MarketTemplateRegistry)"]
        ["胜平负(WDL)"]
        ["大小球(OU 多线)"]
        ["让球(AH 四分之一球拆分)"]
        ["精确比分/Props(阶段二)"]
      资产标准
        ["ERC-1155 头寸/或CTF"]
        ERC-4626 LP金库
      ["定价/做市(AMM)"]
        ["CPMM(二/三向)"]
        ["LMSR(多Outcome/比分网格)"]
      串关/组合
        ["Basket(Parlay)"]
        ["CorrelationGuard(相关性惩罚/阻断)"]
      费用路由
        ["FeeRouter: LP/Promo/Insurance/Treasury"]
      参数控制
        ParamController + Timelock + FeatureFlag
      事件契约
        ["BetPlaced/Locked/Resolved/Referral/Rewards…"]
    ["预言机与结算[Owner: Oracle/Protocol Team]"]
      ["MatchFacts Schema(结构化赛事实体)"]
      乐观式上报
        ["Propose(质押)→Dispute→Resolve"]
        UMA OO 适配器/或自建仲裁层
      结算函数库
        ["f(facts)→WDL/OU/AH/比分/Props"]
      Keeper自动化
        锁盘/开启争议窗口/Finalize
    ["运营与增长基建[Owner: Growth Infra]"]
      ["ReferralRegistry(一次绑定/长期分成)"]
      ["RewardsDistributor(Merkle周度根)"]
      ["Campaign/Quest Factory(活动/任务)"]
      ["CreditToken/Coupon(免佣/串关加成)"]
      ["PayoutScaler(预算不足统一缩放)"]
      ["Promoter SBT + Staking(权限与约束)"]
    ["风控引擎[Owner: Risk & Quant]"]
      ["曝险限额(同场/同向合并限额)"]
      ["线联动控制器(OU/AH 相邻线联动)"]
      ["风险评分(RiskScorer: 图谱+护照分)"]
      ["紧急刹车(只读暂停/停止新建)"]
    ["链下服务(Go为主)[Owner: Backend]"]
      ["Indexer(订阅合约→Postgres/Timescale)"]
      ["Keeper Service(Gelato/自建冗余)"]
      ["Rewards Builder(周度Merkle生成/上链)"]
      ["Risk & Pricing Worker(参数拟合/联动)"]
      ["API Gateway(只读查询/签名组装)"]
    ["数据与可观测[Owner: Data/Analytics]"]
      ["Subgraph(公开查询与生态对接)"]
      ["实时指标(Grafana/Prom/OTel)"]
      ["BI仓库(Postgres/Metabase 或 ClickHouse)"]
      ["异常告警(Tenderly/Forta/自定义Agent)"]
      ["KPI字典(GTV/Fees/PromoSpend/LP APR/D7留存)"]
    ["DevOps/SRE[Owner: SRE]"]
      ["环境: dev→testnet→staging→prod"]
      ["CI/CD: GitHub Actions + Foundry/Echidna/Slither"]
      ["IaC: Terraform + Helm + K8s"]
      ["秘钥与金库: Vault/KMS + Safe"]
      ["回滚与演练(锁盘失败/无人上报/争议风暴)"]
    ["安全与审计[Owner: Security]"]
      ["静态/模糊/断言: Slither/Echidna/Scribble"]
      ["符号/形式化(选配): Mythril/Certora"]
      ["外部审计与Bug Bounty(Immunefi)"]
      权限模型复核与变更Timelock
    ["前端与集成(最小必要)[Owner: Web/Wallet]"]
      ["钱包与签名(EIP-712/可选4337赞助)"]
      市场浏览/下单/串关/锁盘提示
      ["账户中心(奖励/返利/领取)"]
      ["运营后台(活动发布/参数灰度/分流)"]
    ["文档与规范[Owner: Docs/DevRel]"]
      ["合约接口/事件手册(ABI/错误码/示例)"]
      运维Runbook/应急手册
      ["风控与赔率白皮书(版本化/IPFS哈希)"]
    ["里程碑(M0→M3)[Owner: 全体按域自验收]"]
      M0 脚手架
        Foundry合约骨架/事件契约
        Go Indexer/初版Subgraph/CI
      M1 主流程闭环
        WDL + OU单线/AMM/锁盘/结算/兑付
        UMA OO接入/Rewards/Referral
      M2 运营闭环
        活动/任务/周度Merkle/仪表盘
        ["OU多线+联动/AH(-0.5)"]
      M3 扩玩法与可插槽
        ["精确比分/LMSR/Props(1-2项)"]
        ["CLOB撮合插槽(选配) + 风控进阶"]
```

## 说明

本思维导图展示了去中心化足球博彩平台的完整技术架构，包含：

- **项目治理**：PMO、里程碑规划、风险管理
- **链上内核**：核心合约、市场模板、AMM、串关逻辑
- **预言机与结算**：乐观式上报、结算函数库、Keeper自动化
- **运营增长**：推荐系统、奖励分发、活动管理
- **风控引擎**：曝险管理、联动控制、风险评分
- **链下服务**：索引器、API网关、定价工作器
- **数据可观测**：Subgraph、监控告警、BI分析
- **DevOps/SRE**：CI/CD、基础设施、密钥管理
- **安全审计**：静态分析、模糊测试、外部审计
- **前端集成**：钱包、市场界面、运营后台
- **文档规范**：接口文档、运维手册、白皮书
- **里程碑**：M0-M3 分阶段交付计划

各模块负责团队已在节点名称后用圆括号标注。
