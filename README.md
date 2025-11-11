# PitchOne - 去中心化链上足球博彩平台

**全链透明 · 非托管资产 · 自动化结算 · 乐观式预言机**

## 项目概述

PitchOne 是一个基于区块链的去中心化足球博彩平台，提供胜平负、大小球、让球、精确比分等多种玩法。

**核心特性**：
- 🔗 全链透明、非托管资产
- 🤖 UMA 乐观式预言机自动结算
- 📊 AMM/LMSR 自动做市
- 🎯 串关组合投注
- 💰 推荐返佣、任务活动系统

## 技术栈

- **智能合约**: Solidity + Foundry（ERC-1155、ERC-4626、UMA OO）
- **前端应用**: Next.js 15 + React 19 + wagmi 2 + TailwindCSS
- **链下服务**: Go（Indexer、Keeper、Rewards）
- **数据索引**: The Graph Subgraph
- **数据库**: PostgreSQL + Timescale
- **基础设施**: Docker Compose + K8s

## 项目结构

```
PitchOne/
├── frontend/           # 前端 Monorepo
│   ├── apps/
│   │   ├── user/      # 用户端 Next.js 应用
│   │   └── admin/     # 管理端 Next.js 应用
│   └── packages/
│       ├── ui/        # 共享组件库
│       ├── web3/      # Web3 hooks
│       ├── utils/     # 工具函数
│       └── contracts/ # 合约 ABI 和类型
├── backend/           # Go 后端服务
│   ├── cmd/          # 服务入口（indexer, keeper, rewards）
│   ├── internal/     # 内部业务逻辑
│   └── pkg/          # 可复用包
├── contracts/        # Solidity 智能合约
│   ├── src/          # 合约源码
│   ├── test/         # 合约测试
│   └── script/       # 部署脚本
├── subgraph/         # The Graph 数据索引
│   ├── schema.graphql
│   ├── subgraph.yaml
│   └── src/          # Event handlers
├── docs/             # 项目文档
└── ops/              # 运维脚本
```

## 快速开始

### 前置要求

- Node.js >= 18
- pnpm >= 9
- Go >= 1.21
- Foundry
- Docker & Docker Compose

### 1. 启动本地环境

```bash
# 启动基础设施（Postgres、IPFS、Graph Node 等）
make up

# 启动本地测试链（Anvil）
make chain
```

### 2. 部署合约

```bash
cd contracts
forge build
make deploy  # 或 forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

### 3. 启动后端服务

```bash
cd backend

# 启动 Indexer（订阅链上事件）
go run ./cmd/indexer

# 启动 Keeper（自动化任务）
go run ./cmd/keeper

# 启动 Rewards Builder（周度奖励）
go run ./cmd/rewards
```

### 4. 启动前端应用

```bash
cd frontend

# 安装依赖
pnpm install

# 启动用户端（http://localhost:3000）
pnpm dev:user

# 启动管理端（http://localhost:3001）
pnpm dev:admin

# 同时启动两个应用
pnpm dev
```

### 5. 部署 Subgraph

```bash
cd subgraph
graph codegen
graph build
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 sportsbook-local
```

## 核心模块

### 智能合约（19/19 完成 ✅，491 测试全部通过）

**核心基础设施**:
- ✅ **MarketBase** - 市场基础合约（Open → Locked → Resolved → Finalized）
- ✅ **MarketTemplateRegistry** - 玩法模板注册表
- ✅ **SimpleCPMM** - 恒定乘积做市商（21 测试，二/三向市场）
- ✅ **LMSR** - 对数做市商（多结果市场定价引擎）
- ✅ **LinkedLinesController** - 相邻线联动控制器（19 测试）

**市场模板（7/7）**:
- ✅ **WDL_Template** - 胜平负市场（51 测试，100% 覆盖率）
- ✅ **OU_Template** - 大小球单线市场（含 Push 退款机制）
- ✅ **OU_MultiLine** - 大小球多线市场（23 测试）
- ✅ **AH_Template** - 让球市场（28 测试，支持半球盘/整球盘）
- ✅ **OddEven_Template** - 进球数单双市场（34 测试）
- ✅ **ScoreTemplate** - 精确比分市场（34 测试，LMSR 定价）
- ✅ **PlayerProps_Template** - 球员道具市场（14 测试，7 种道具类型）

**预言机系统**:
- ✅ **MockOracle** - 测试预言机（19 测试）
- ✅ **UMAOptimisticOracleAdapter** - UMA OO 集成（24 测试）

**串关系统**:
- ✅ **Basket** - 串关组合下注（6 个集成测试）
- ✅ **CorrelationGuard** - 相关性风控（20+ 测试）

**运营基建**:
- ✅ **FeeRouter** - 费用路由（29 测试）
- ✅ **RewardsDistributor** - Merkle 奖励分发（42 测试）
- ✅ **ReferralRegistry** - 推荐系统（41 测试）
- ✅ **Campaign** - 活动工厂（26 测试 + 12 集成测试）
- ✅ **Quest** - 任务系统（32 测试，5 种任务类型）
- ✅ **CreditToken** - 免佣券（33 测试）
- ✅ **Coupon** - 赔率加成券（10 测试）
- ✅ **PayoutScaler** - 预算缩放（11 测试）

**治理系统**:
- ✅ **ParamController** - 参数控制器 + Timelock（35 测试）

### 前端应用

**用户端（apps/user）**:
- ✅ 首页 - 平台介绍、钱包连接
- ✅ 市场列表 - 筛选、搜索、赛事展示
- ✅ 市场详情 - 下注表单、赔率显示、订单历史
- ✅ 个人头寸 - 持仓管理、盈亏统计
- ⏳ 串关组合 - 多市场组合投注

**管理端（apps/admin）**:
- ⏳ 市场管理 - 创建市场、参数配置
- ⏳ Oracle 提案 - 提交赛果、争议处理
- ⏳ 数据看板 - 交易量、手续费、用户统计
- ⏳ 参数配置 - 治理提案、Timelock 执行

**共享组件库（packages/ui）** - 11 个组件:
- ✅ Button, Card, Badge, Input, Modal
- ✅ Header, Footer, Container
- ✅ LoadingSpinner, EmptyState, ErrorState

### 后端服务

- ✅ **Indexer** - 订阅合约事件，写入 Postgres（~1,100 行，6 种核心事件）
- ✅ **Keeper** - 自动锁盘、结算、UMA OO 集成（~1,500 行，19/20 测试通过）
- ✅ **Rewards Builder** - 周度奖励聚合和 Merkle 树生成（基础框架完成）

### Subgraph

- ✅ Schema 定义（Market, Position, Order, User, Referral, OracleProposal 等）
- ✅ Event Handlers（15+ handlers）
- ✅ 完整部署成功（v0.3.0）
- ✅ GraphQL 查询验证通过

## 常用命令

### 合约开发

```bash
cd contracts
forge build                  # 编译合约
forge test                   # 运行所有测试
forge test --match-test xxx -vvv  # 运行单个测试并显示详细日志
forge coverage              # 查看测试覆盖率
slither src/                # 静态分析
make deploy                 # 部署合约
```

### 前端开发

```bash
cd frontend
pnpm install                # 安装依赖
pnpm dev                    # 启动所有应用
pnpm dev:user               # 只启动用户端
pnpm dev:admin              # 只启动管理端
pnpm build                  # 构建生产版本
```

### 后端开发

```bash
cd backend
go test ./...               # 运行所有测试
go run ./cmd/indexer        # 启动 Indexer
go run ./cmd/keeper         # 启动 Keeper
go build -o bin/indexer ./cmd/indexer  # 构建二进制
```

### Subgraph

```bash
cd subgraph
graph codegen               # 生成类型定义
graph build                 # 构建 Subgraph
graph deploy                # 部署到 Graph Node
```

## 文档

- **技术设计**: `docs/design/` - 10 份模块设计文档
- **接口规范**: `docs/模块接口事件参数/EVENT_DICTIONARY.md`
- **开发指南**: `CLAUDE.md` - Claude Code 使用指南
- **项目介绍**: `docs/intro.md`
- **进度追踪**: `docs/任务追踪.md`

## 测试

### 合约测试

```bash
cd contracts
forge test                   # 单元测试
forge test --gas-report      # Gas 报告
forge coverage               # 覆盖率报告
echidna . --contract xxx     # 模糊测试
```

**当前测试状态**: 491/491 测试通过 ✅

### 后端测试

```bash
cd backend
go test ./... -v             # 详细输出
go test -cover ./...         # 覆盖率
```

**当前测试状态**: 19/20 测试通过（95%）

## 环境变量

```bash
# 必需
export RPC_URL=https://...                    # RPC 节点
export PRIVATE_KEY=0x...                      # 部署私钥
export DATABASE_URL=postgresql://...          # 数据库连接

# 可选
export UMA_OO_ADDRESS=0x...                   # UMA Oracle 地址
export GRAPH_NODE_URL=http://localhost:8020/  # Graph Node
export NEXT_PUBLIC_SUBGRAPH_URL=http://...    # Subgraph endpoint
```

## 部署

详见各模块的部署文档：
- 合约部署: `docs/deployment/contracts.md`
- 后端服务: `docs/deployment/backend.md`
- 前端应用: `docs/deployment/frontend.md`
- Subgraph: `docs/deployment/subgraph.md`

## 贡献

欢迎贡献代码、报告问题或提出建议！

## 许可证

MIT License

---

**开发状态**: 🎉 核心功能完成（100% M1-M3 里程碑达成）

**最后更新**: 2025-11-11

**项目进度**:
- ✅ M1（主流程闭环）: 100% 完成
- ✅ M2（运营闭环）: 100% 完成
- ✅ M3（扩玩法与串关）: 100% 完成
- 🔄 前端开发：进行中
- 📋 测试网部署：准备中
