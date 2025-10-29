下面给一套**“可落地、工程化、偏后端/合约”**的技术栈与开发工具选型（附带我给的**意见化默认方案**），兼顾你们之前偏好的 Go 开发生态、Foundry 测试流，以及后续扩玩法、做增长/风控的可扩展性。

---

# 一、链层与代币/治理

* **主部署网络（L2）**：Arbitrum One 或 Optimism（低 gas、生态成熟）

  * *理由*：赛事类应用交互频繁、需要低费与较快最终性；生态工具齐全。

* **资产与权限**

  * 头寸代币：`ERC-1155`（或 CTF 风格条件代币）
  * LP 金库：`ERC-4626`
  * 治理：`OpenZeppelin Governor + Timelock`
  * 风险/运营参数：单独 `ParamController` 受 Timelock 控制
  * 升级：对“资金安全内核”尽量**免升级**；非关键策略走可插拔地址 + Timelock

* **多签**：Safe（Gnosis Safe）管理金库与紧急开关（仅只读暂停/停止新建）

**意见化默认**：先上 **Arbitrum One**；ERC-1155 持仓、4626 金库；Governor + Timelock + Safe。

---

# 二、智能合约开发与安全

* **语言/框架**：Solidity + **Foundry**（forge/anvil/cast）

  * 单元测试、属性与模糊：`forge test -vvv` + `invariant` 测试
  * 覆盖率：`forge coverage`
* **静态/形式化**

  * 静态分析：**Slither**
  * 符号执行：**Mythril**（选配）
  * 模糊测试：**Echidna**（对 AMM 边界、资金不变量）
  * 规范注释：**Scribble** 编写运行时断言（钱不丢、池子守恒）
* **依赖与库**

  * OpenZeppelin（ERC 标准、Governor、Timelock、AccessControl）
  * PRBMath / Solmate（定点数与轻量库）
  * UMA OO 接口（若接乐观式预言机）
* **审计/监控**

  * **Tenderly**：模拟、回放、警报
  * **Forta** 代理（可写自定义 Agent：大额下注、异常上报、参数变更预警）

**意见化默认**：Foundry 为主；Slither + Echidna 必配；Scribble 为关键路径加断言；Tenderly 上线前后都开。

---

# 三、预言机与结算

* **赛果上报**：**UMA Optimistic Oracle**（OO）或自建“乐观式 + 仲裁”层

  * 流程：Propose（质押）→ Dispute（质押）→ Resolve（DVM 或治理）
  * 我们的 Market 读取“结构化事实”（进球数、是否含加时等），各玩法按 `payout=f(facts)` 结算
* **Keepers/自动化**

  * **Chainlink Automation** 或 **Gelato**：锁盘、开启争议窗口、发布周度 Merkle、清理过期券
  * 自建 Keeper（Go）：作为冗余通道，读取链上事件触发交易

**意见化默认**：先对接 **UMA OO**；自动化用 **Gelato** + 自建 Go Keeper 双轨。

---

# 四、定价/撮合与风控

* **V1 做市层**：AMM

  * 胜/平/负、二元类：**CPMM**
  * 多 Outcome/比分网格：**LMSR**（信息市场型）
  * 线型玩法（OU/AH）：共享池 + 相邻线联动控制器（避免碎片化）
* **V2 扩展**：可插拔 **混合 CLOB**（签名订单链上结算），与 AMM 并存路由
* **风控组件（链上/链下）**

  * 同场合并限额、单地址敞口、临近锁盘费率阶梯
  * 串关相关性惩罚/阻断（同场同向腿）
  * 预算闸门（Promo Pool）+ 统一缩放（PayoutScaler）

**意见化默认**：先 AMM（CPMM+LMSR 组合）→ 路线成熟后再接 CLOB 插槽。

---

# 五、链下服务（Go 主力，Python 辅助）

* **语言**：**Go** 为主（你们优势），Python 做数据科学/定价实验
* **服务划分**

  1. **Indexer**：订阅合约事件 → Postgres（或 Timescale）
  2. **Relayer**（可选）：代付/批处理（4337 AA 或普通 relayer）
  3. **Keeper**：定时/条件任务（锁盘、发布 Merkle、回收超时）
  4. **Risk & Pricing Worker**：线联动、风控阈值、LMSR 参数拟合（Go；需要时用 Python 模型离线训练）
  5. **Rewards Builder**：每周生成 Merkle 树（返佣/返利/任务/赛季），上链 root
  6. **Campaign Engine**：活动规则链下计算 + 生成可校验结果（Merkle/ZK 可选）
* **框架/库（Go）**：

  * Web：Gin/Fiber；任务调度：robfig/cron 或 go-co-op/gocron
  * 以太坊：go-ethereum（`bind`, `ethclient`）、Foundry 的 `cast` 调试
  * 队列：**NATS** 或 **Kafka**（高吞吐）
  * 配置/FeatureFlag：go-chi/httprate、sp13/viper、开关表用 Postgres

**意见化默认**：Go 微服务：indexer、keeper、rewards、risk 四大件；队列用 **NATS** 先行，足够轻。

---

# 六、数据与分析

* **索引**：**The Graph(Subgraph)** 做公开查询层；内部实时指标走自建 Indexer
* **数据库**：**Postgres**（主） + **TimescaleDB**（时序）
* **数据仓**（可选）：ClickHouse（事件明细高并发）
* **可视化**：Grafana（运营/风控实时盘）+ Metabase（BI）
* **外部分析**：上 Dune/Flipside（社区分析）
* **埋点标准**：所有合约事件已设计好（BetPlaced/Locked/Resolved/Referral/Rewards/Basket…），Subgraph 同步

**意见化默认**：Subgraph + Postgres + Grafana；大盘先不引入 ClickHouse。

---

# 七、运维与交付

* **容器与编排**：Docker + **Kubernetes**（或先 Docker Compose）
* **基础设施即代码**：Terraform + Helm
* **CI/CD**：GitHub Actions

  * 合约：lint（solhint）、Slither、Foundry 测试/覆盖率、testnet 部署、E2E
  * 后端：Go 单测 + 集成测 + 镜像构建 + Helm 部署
* **日志/可观测性**：OpenTelemetry（Go/Node 全链路）+ Prometheus + Grafana

  * *可选*：eBPF（Cilium/Tetragon）对关键进程与网络可观测
* **密钥管理**：HashiCorp Vault 或 AWS KMS；部署签名用临时会话密钥
* **合约部署管理**：Foundry `broadcast`，部署清单（chainId/addr/abi-hash/commit）入库

**意见化默认**：K8s + Actions + Helm；OTel + Prom/Grafana；Vault 管理私钥。

---

# 八、钱包与账户体验

* **钱包**：EVM 生态常见钱包（Rabby、MetaMask 等）
* **Account Abstraction（可选）**：ERC-4337（Biconomy/ZeroDev），做免 gas/券补贴
* **签名**：EIP-712（市场下单、活动绑定）
* **风控**：交易前置提示（锁盘倒计时、滑点上限），失败回滚友好

**意见化默认**：V1 不上 4337，后续针对新手再接 4337 做 gas 赞助。

---

# 九、安全与应急预案

* **权限**：分权（治理、参数、金库、暂停）；暂停仅停新建与路由，不影响兑付/提款
* **保险金库**：手续费按比例注入；预言机/仲裁错误补偿
* **Bug Bounty**：Immunefi 等平台
* **演练**：Testnet 上做“锁盘失败/无人上报/争议风暴/预算透支”等演习脚本（Foundry 脚本）

---

# 十、环境与分支策略

* **环境**：`dev (Anvil) → testnet (Arb/OP test) → staging (L2 测试) → prod`
* **版本**：语义化版本；合约版本 + 参数快照上 IPFS，Subgraph 记录版本切换事件
* **灰度**：FeatureFlag（按地址白名单/百分比分流），新模板/新参数先灰度

---

# 十一、代码库结构（示例）

```
/contracts
  /core        // MarketBase, FeeRouter, ParamController, Treasury
  /templates   // WDL, OU, AH, Basket
  /oracle      // ResultOracle adapters (UMA OO)
  /ops         // RewardsDistributor, ReferralRegistry, CampaignFactory
  /lib         // OZ, PRBMath...
  foundry.toml

/backend
  /indexer     // Go：订阅事件写库
  /keeper      // Go：锁盘/发布root/清理
  /rewards     // Go：周度 Merkle 生成/发布
  /risk        // Go：线联动/阈值/相关性计算API
  /pkg         // 共享SDK（abi、client、types）

/subgraph
  schema.graphql
  subgraph.yaml
  src/...

/infra
  /helm
  /terraform

/.github/workflows
```

---

# 十二、最小落地路线（4 周冲刺）

1. **Week 1**：Foundry 合约骨架（WDL+OU 单线）+ 基础事件；Go Indexer 模版；Grafana 初盘
2. **Week 2**：Echidna/Scribble 不变量；Gelato/Keeper 锁盘；Subgraph 首版；Testnet 部署
3. **Week 3**：Rewards Merkle 流水线；Referral/PromoPool 路由；LMSR/线联动 PoC
4. **Week 4**：Tenderly 回放/E2E；灰度参数/FeatureFlag；预发布（staging）压测与演练

---

## 总结（一句话）

**意见化选择**：*Arbitrum + Solidity/Foundry + Go 后端四件套（indexer/keeper/rewards/risk）+ Subgraph + Postgres/Grafana + Slither/Echidna/Tenderly + K8s/Actions/Helm*。
这套在**性能、可观测、安全、可增长**之间比较均衡，能平滑从“胜平负”扩展到“OU/AH/比分/串关/道具”，且与我们前面讨论的运营与参数化设计无缝衔接。

如果你愿意，我可以把 **Foundry + Go indexer 的最小可运行脚手架**（含示例合约、事件、Go 订阅代码、Docker Compose、Grafana 仪表盘 JSON）直接打成一份工程化模板，拷贝就能起。

