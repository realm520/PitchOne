# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个**去中心化链上足球博彩平台**（Decentralized Sportsbook），基于区块链实现非托管博彩市场，提供胜平负（WDL）、大小球（OU）、让球（AH）、精确比分、球员道具等多种玩法。

**核心特性**：
- 全链透明、非托管资产、自动化结算（乐观式预言机）
- 模板化市场扩展、AMM/LMSR 做市、串关（Parlay）组合
- 内置增长机制：推荐返佣、任务活动、周度 Merkle 奖励分发

**技术栈**：
- **合约层**：Solidity + Foundry（ERC-1155 头寸、ERC-4626 LP 金库、UMA OO 预言机适配）
- **链下服务**：Go（Indexer、Keeper、Rewards Builder、Risk Worker）
- **数据层**：The Graph Subgraph + Postgres/Timescale + Grafana
- **基础设施**：Docker Compose + K8s + Terraform

## 常用命令

### 开发环境启动
```bash
# 启动本地基础设施（数据库、缓存等）
make up

# 启动本地测试链（Anvil）
make chain

# 启动所有后端服务（Indexer + Keeper + Rewards）
make backend
```

### 合约开发
```bash
cd contracts/

# 编译合约
forge build

# 运行测试
forge test

# 运行单个测试（带详细输出）
forge test --match-test testSpecificFunction -vvv

# 查看测试覆盖率
forge coverage

# 运行静态分析（Slither）
slither src/

# 运行模糊测试（Echidna）
echidna . --contract ContractName --config echidna.yaml

# 部署合约（需设置 RPC_URL 环境变量）
make contracts-deploy
# 或直接使用 forge
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vvvv

# 格式化代码
forge fmt
```

### 后端开发（Go）
```bash
cd backend/

# 运行 Indexer（订阅合约事件并索引）
go run ./cmd/indexer

# 运行 Keeper（自动化任务：锁盘、发布 Merkle 根等）
go run ./cmd/keeper

# 运行 Rewards Builder（生成周度 Merkle 树）
go run ./cmd/rewards

# 运行测试
go test ./...

# 运行单个包的测试
go test ./internal/indexer -v

# 构建二进制
go build -o bin/indexer ./cmd/indexer
go build -o bin/keeper ./cmd/keeper
go build -o bin/rewards ./cmd/rewards
```

### Subgraph 开发
```bash
cd subgraph/

# 生成代码（从 schema.graphql 和 subgraph.yaml）
graph codegen

# 构建 Subgraph
graph build

# 部署到本地 Graph Node
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 sportsbook-local

# 部署到 The Graph Studio
graph deploy --studio sportsbook
```

## 核心架构

### 1. 合约层架构（contracts/src/）

**模块组织**：
- **MarketBase.sol**：市场基础合约，定义市场生命周期（Open → Locked → Resolved → Finalized）
- **MarketTemplateRegistry.sol**：市场模板注册表，管理 WDL/OU/AH/比分等玩法模板
- **定价引擎**：
  - `CPMM.sol`：二/三向 Constant Product Market Maker
  - `LMSR.sol`：Logarithmic Market Scoring Rule（用于多结果市场，如精确比分）
  - `LinkedLinesController.sol`：相邻线联动控制器（OU 多线、AH 联动定价）
- **串关**：
  - `Basket.sol`：Parlay 组合下注合约
  - `CorrelationGuard.sol`：相关性惩罚/阻断（同场同向限制）
- **预言机**：
  - `ResultOracle.sol`：结算预言机接口
  - `UMAOptimisticOracleAdapter.sol`：UMA OO 适配器（Propose → Dispute → Resolve）
- **运营基建**：
  - `FeeRouter.sol`：费用路由（LP/Promo/Insurance/Treasury 分成）
  - `RewardsDistributor.sol`：周度 Merkle 奖励分发
  - `ReferralRegistry.sol`：推荐关系注册与返佣计算
  - `Campaign.sol` / `Quest.sol`：活动/任务工厂
  - `CreditToken.sol` / `Coupon.sol`：免佣券/加成券
- **治理**：
  - `ParamController.sol`：参数控制器（费率、限额、联动系数等）
  - 集成 Safe 多签 + Timelock

**关键设计模式**：
- **模板化扩展**：所有玩法通过 `IMarketTemplate` 接口标准化，支持热插拔
- **事件驱动**：所有状态变更发出标准化事件（参见 `docs/模块接口事件参数/EVENT_DICTIONARY.md`）
- **不变量保护**：AMM 守恒、LP 金库安全、串关赔率上限等通过 Scribble 断言 + Echidna 模糊测试验证
- **乐观式结算**：质押 → 争议窗口 → 最终确认，减少链上交互成本

### 2. 链下服务架构（backend/）

**服务组件**（均为独立 Go 进程）：
1. **Indexer**（`cmd/indexer/`）
   - 订阅合约事件（通过 WebSocket 或 HTTP 轮询）
   - 解析并写入 Postgres/Timescale（市场、订单、结算、奖励等表）
   - 支持重放和容错（记录最后处理的区块高度）

2. **Keeper Service**（`cmd/keeper/`）
   - 定时任务执行：
     - 锁盘：开赛前 N 分钟调用 `market.lock()`
     - 发起结算：赛后调用 UMA OO 的 `proposeResult()`
     - 发布 Merkle 根：周度调用 `RewardsDistributor.publishRoot()`
   - 冗余执行：本地 + Gelato/Chainlink Automation 双保险

3. **Rewards Builder**（`cmd/rewards/`）
   - 周度任务：
     - 从数据库聚合所有待发放奖励（推荐返佣、任务奖励、活动奖金）
     - 生成 Merkle 树并上链 Root
     - 用户凭 Merkle Proof 自行领取

4. **Risk & Pricing Worker**（未来实现）
   - 实时计算：
     - OU/AH 相邻线联动参数
     - 串关相关性矩阵
     - 单地址/同场敞口限额
   - 更新 `ParamController` 参数（通过治理或自动化）

**数据库 Schema**（关键表）：
- `markets`：市场元数据（赛事、玩法类型、状态、锁盘时间、结算结果）
- `positions`：用户头寸（ERC-1155 Token ID、数量、市场引用）
- `orders`：下注订单（用户、金额、方向、时间戳、交易哈希）
- `referrals`：推荐关系（推荐人、被推荐人、绑定时间）
- `rewards`：待发放奖励（用户、类型、金额、周期、Merkle Proof）
- `oracle_proposals`：预言机提案记录（提案者、结果、质押、争议状态）

### 3. Subgraph 数据层（subgraph/）

**Schema 实体**（`schema.graphql`）：
- `Market`：市场实体（映射合约 MarketBase）
- `Position`：头寸实体（映射 ERC-1155 Transfer 事件）
- `Order`：订单实体（映射 BetPlaced 事件）
- `Referral`：推荐关系（映射 ReferralBound 事件）
- `RewardClaim`：奖励领取记录（映射 RewardClaimed 事件）
- `OracleProposal`：预言机提案（映射 ResultProposed / ResultDisputed 事件）

**查询示例**：
```graphql
# 查询某用户的所有活跃头寸
query UserPositions($user: Bytes!) {
  positions(where: { owner: $user, balance_gt: "0" }) {
    id
    market { id, event, status }
    outcome
    balance
  }
}

# 查询某市场的所有订单
query MarketOrders($marketId: Bytes!) {
  orders(where: { market: $marketId }, orderBy: timestamp, orderDirection: desc) {
    id
    user
    amount
    outcome
    timestamp
  }
}
```

### 4. 关键业务流程

#### 4.1 市场创建与下注流程
```
1. 链下调度 → 调用 MarketTemplateRegistry.createMarket()
   - 输入：赛事信息、玩法类型（WDL/OU/AH）、初始参数
   - 输出：Market 合约地址、MarketCreated 事件

2. 用户下注 → 调用 Market.placeBet(outcome, amount)
   - AMM 计算实时赔率和滑点
   - 铸造 ERC-1155 头寸 Token 给用户
   - 扣除费用并路由至 FeeRouter
   - 发出 BetPlaced 事件

3. 开赛前 N 分钟 → Keeper 调用 Market.lock()
   - 市场状态：Open → Locked
   - 禁止新下注，仅允许卖出头寸或撤 LP

4. 赛后结算 → Keeper 调用 UMAAdapter.proposeResult(matchFacts)
   - 质押 BOND，提交结构化赛果（进球数、加时、点球等）
   - 开启争议窗口（默认 2 小时）

5. 争议窗口结束 → 预言机 Finalize
   - 市场状态：Locked → Resolved
   - 用户可调用 Market.redeem() 兑付赢得的头寸

6. 周度奖励发放 → Rewards Builder 生成 Merkle 树
   - 聚合推荐返佣、任务奖励、活动奖金
   - 发布 Root 到 RewardsDistributor
   - 用户凭 Proof 调用 claimReward()
```

#### 4.2 串关（Parlay）流程
```
1. 用户选择多个市场 → 调用 Basket.createParlay([market1, market2], [outcome1, outcome2], amount)
   - CorrelationGuard 检查相关性（同场同向 → 惩罚或阻断）
   - 计算组合赔率（各市场赔率相乘 × 相关性折扣）
   - 锁定用户资金至 Basket 合约

2. 所有市场结算完成 → 用户调用 Basket.redeem(parlayId)
   - 检查所有结果是否正确
   - 全中 → 按组合赔率发放奖金
   - 任一错误 → 资金归 LP
```

### 5. 测试策略

**合约测试**（`contracts/test/`）：
- **单元测试**：每个合约的核心逻辑（Foundry Test）
  ```solidity
  // 示例：测试 AMM 不变量
  function testCPMM_Invariant() public {
      uint256 k_before = market.reserveA() * market.reserveB();
      market.placeBet(0, 100 ether);
      uint256 k_after = market.reserveA() * market.reserveB();
      assertApproxEqRel(k_after, k_before, 0.001e18); // 允许 0.1% 误差（费用）
  }
  ```
- **不变量测试**：Echidna 模糊测试 + Scribble 断言
  - AMM 守恒：`k_after >= k_before`
  - LP 金库安全：`totalAssets() >= sum(userShares)`
  - 赔率合理性：`1.01 <= odds <= 100`
- **集成测试**：完整业务流程（创建市场 → 下注 → 锁盘 → 结算 → 兑付）

**链下测试**（`backend/`）：
- **单元测试**：Go 标准 `testing` 包
- **集成测试**：使用 Anvil 本地链 + 测试合约
- **E2E 测试**：完整流程验证（Indexer 订阅 → 写入数据库 → Keeper 触发结算）

### 6. 开发注意事项

#### 合约开发
- **Gas 优化**：
  - 使用 `uint256` 而非 `uint8`（EVM 字长对齐）
  - 批量操作时使用 `calldata` 而非 `memory`
  - 避免在循环中读写存储（先加载到内存）
- **事件契约**：所有状态变更必须发出标准化事件（参见 `docs/模块接口事件参数/EVENT_DICTIONARY.md`）
- **错误处理**：使用自定义 Error（节省 Gas）
  ```solidity
  error MarketAlreadyLocked(uint256 lockTime);
  if (status == Status.Locked) revert MarketAlreadyLocked(block.timestamp);
  ```
- **权限控制**：
  - 使用 OpenZeppelin AccessControl
  - 敏感操作（如参数调整、紧急暂停）必须经过 Timelock + 多签

#### 链下开发
- **事件订阅**：
  - 使用 WebSocket 订阅实时事件（`eth_subscribe`）
  - 定期轮询 `eth_getLogs` 作为备份
  - 记录最后处理的区块高度（支持重启后续传）
- **数据库事务**：
  - 同一事件的多表写入必须在同一事务中
  - 使用乐观锁或行锁避免并发冲突
- **Keeper 冗余**：
  - 本地 Keeper + Gelato/Chainlink 双保险
  - 任务执行前检查链上状态（避免重复执行）

#### Subgraph 开发
- **事件处理顺序**：同一交易内的多个事件按 logIndex 顺序处理
- **大数处理**：使用 `BigInt` 类型，避免 JavaScript Number 精度丢失
- **查询优化**：
  - 合理设计实体关系（`@derivedFrom`）
  - 为常用查询字段添加索引（`indexed: true`）

## 项目里程碑

详见 `docs/任务追踪.md`：
- **M0（第 1 周）**：脚手架 - 合约骨架、Indexer、Subgraph、CI/CD
- **M1（第 3-4 周）**：主流程闭环 - WDL + OU 单线、AMM、结算、奖励/推荐
- **M2（第 5-8 周）**：运营闭环 - 活动/任务、周度 Merkle、OU 多线联动、AH
- **M3（第 9-12 周）**：扩玩法 - 精确比分（LMSR）、球员道具、CLOB 插槽

## 文档资源

- **技术详细设计**：`docs/design/` - 10 份模块设计文档
- **接口与事件规范**：`docs/模块接口事件参数/EVENT_DICTIONARY.md`
- **架构思维导图**：`docs/project_mind.md`
- **项目介绍**：`docs/intro.md`（面向技术受众）
- **Subgraph Schema**：`docs/模块接口事件参数/SUBGRAPH_SCHEMA.graphql`

## 环境变量

```bash
# 必需
export RPC_URL=https://...                    # 以太坊 RPC 节点
export PRIVATE_KEY=0x...                       # 部署账户私钥
export DATABASE_URL=postgresql://...           # Postgres 连接串

# 可选
export UMA_OO_ADDRESS=0x...                    # UMA Optimistic Oracle 地址
export GRAPH_NODE_URL=http://localhost:8020/   # Graph Node URL
export GELATO_API_KEY=...                      # Gelato 自动化 API Key
```

## 安全检查清单

提交代码前确保：
- [ ] 运行 `forge test` 且所有测试通过
- [ ] 运行 `slither src/` 且无高危/中危问题
- [ ] 运行 `forge coverage` 且覆盖率 ≥80%
- [ ] 所有公开/外部函数都有 NatSpec 注释
- [ ] 敏感操作（转账、状态变更）有权限控制和事件记录
- [ ] 新增合约已添加对应的单元测试和不变量测试
- [ ] 链下服务的数据库操作使用了事务保护
- [ ] Subgraph 的事件处理器经过本地 Graph Node 测试
