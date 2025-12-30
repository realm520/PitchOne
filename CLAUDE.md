# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个**去中心化链上体育预测平台**（Decentralized Sportsbook），基于区块链实现非托管博彩市场，提供胜平负（WDL）、大小球（OU）、让球（AH）、精确比分、球员道具等多种玩法。

**核心特性**：
- 全链透明、非托管资产、自动化结算（乐观式预言机）
- 模板化市场扩展、AMM/LMSR 做市、串关（Parlay）组合
- 内置增长机制：推荐返佣、任务活动、周度 Merkle 奖励分发

**技术栈**：
- **合约层**：Solidity + Foundry（ERC-1155 头寸、ERC-4626 LP 金库、UMA OO 预言机适配）
- **链下服务**：Go（Indexer、Keeper、Rewards Builder、Risk Worker）
- **数据层**：The Graph Subgraph + Postgres/Timescale + Grafana
- **基础设施**：Docker Compose + K8s + Terraform

## SSH 配置（首次使用远程操作）

远程操作命令（如 `make remote-subgraph`）需要 SSH 免密登录。在 `~/.ssh/config` 中添加：

```
Host pitchone-server
    HostName 42.60.109.87
    Port 10021
    User harry
    IdentityFile ~/.ssh/你的私钥文件名
    IdentitiesOnly yes
```

**注意**：需要先将公钥添加到服务器的 `~/.ssh/authorized_keys` 中。

## 生产环境端点

| 服务 | 地址 |
|------|------|
| **RPC** | `https://pitchone-rpc.ngrok-free.app` |
| **Subgraph GraphQL** | `https://pitchone-graph.ngrok-free.app/subgraphs/name/pitchone-sportsbook` |

这些是通过 ngrok 暴露的生产环境公开端点，用于前端连接和数据查询。

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
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook

# 部署到 The Graph Studio
graph deploy --studio sportsbook
```

## 开发测试完整流程

### 🚀 快速启动（一键式）

**标准测试环境准备** - 按顺序执行以下命令：

#### 1. 启动本地测试链
```bash
# 启动 Anvil（在单独终端窗口运行）
cd contracts/
anvil --host 0.0.0.0

# 或使用后台运行
pkill anvil && sleep 2 && anvil --host 0.0.0.0 &
```

#### 2. 部署全部合约
```bash
# 部署所有核心合约和 7 种市场模板
cd contracts/
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 部署完成后会输出：
# - USDC、Vault、FeeRouter、Factory 等核心合约地址
# - 7 种市场模板地址和 Template ID
# - 这些地址需要更新到 subgraph/subgraph.yaml
```

**重要提示**：部署完成后，需要将输出的合约地址更新到：
- `contracts/deployments/localhost.json` - 自动生成
- `subgraph/subgraph.yaml` - 手动更新 Factory 和 FeeRouter 地址

#### 3. 创建测试市场
```bash
# 创建所有 7 种类型的测试市场（每种 3 个，共 21 个市场）
cd contracts/
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 创建的市场类型：
# - WDL (胜平负): 3 个
# - OU (大小球): 3 个
# - AH (让球): 3 个
# - OddEven (单双): 3 个
# - Score (精确比分): 3 个
# - OU_MultiLine (多线大小球): 3 个
# - PlayerProps (球员道具): 3 个
```

#### 4. 模拟下注数据
```bash
# 使用多个测试账户模拟下注，生成测试数据
cd contracts/
NUM_BETTORS=5 \
  MIN_BET_AMOUNT=10 \
  MAX_BET_AMOUNT=100 \
  BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 环境变量说明：
# - NUM_BETTORS: 下注用户数（默认 10，最多 10）
# - MIN_BET_AMOUNT: 最小下注金额（USDC）
# - MAX_BET_AMOUNT: 最大下注金额（USDC）
# - BETS_PER_USER: 每个用户下注次数
# - OUTCOME_DISTRIBUTION: 下注分布策略
#   - balanced: 均匀分布
#   - skewed: 倾斜分布（热门选项占比高）
#   - random: 完全随机
```

#### 5. 部署/重建 Subgraph
```bash
# 方式 1: 完整重建（清理旧数据）
cd subgraph/
./deploy.sh -c -u -y

# 方式 2: 初次部署（自动启动 Graph Node）
cd subgraph/
./deploy.sh

# 方式 3: 仅重新部署（Graph Node 已运行）
cd subgraph/
graph codegen
graph build
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook
```

#### 6. 验证数据流
```bash
# 查询 Subgraph 数据
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets { id status } users { id totalBets } globalStats { totalMarkets totalVolume } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-sportsbook

# 或访问 GraphQL Playground
# http://localhost:8010/subgraphs/name/pitchone-sportsbook/graphql
```

### 📋 一键式完整流程

按以下顺序在不同终端执行命令，或复制以下命令块到脚本中运行：

```bash
# ========================================
# 终端 1: 启动 Anvil
# ========================================
cd contracts/
anvil --host 0.0.0.0

# ========================================
# 终端 2: 部署和初始化
# ========================================

# 1. 部署合约
cd contracts/
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2. 创建测试市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 3. 模拟下注
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 部署 Subgraph（使用现有脚本）
cd ../subgraph/
./deploy.sh -c -u -y
# 或使用: ./deploy.sh

echo "环境启动完成！"
echo "GraphQL Playground: http://localhost:8010/subgraphs/name/pitchone-sportsbook/graphql"
```

**现有脚本说明**：
- `subgraph/deploy.sh -c -u -y` - 清理并重建 Subgraph（推荐用于完全重置）
- `subgraph/deploy.sh` - 首次部署 Subgraph（包含完整检查和启动流程）
- `contracts/test_e2e.sh` - 端到端测试脚本（查询链上状态）

### 🔄 日常开发流程

#### 场景 1：仅修改合约，重新部署
```bash
# 1. 清理并重启 Anvil
pkill anvil && sleep 2 && anvil --host 0.0.0.0 &

# 2. 重新部署
cd contracts/
forge build
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 3. 重新创建市场和数据
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes --rpc-url http://localhost:8545 --broadcast

# 4. 重建 Subgraph
cd ../subgraph/
./deploy.sh -c -u -y
```

#### 场景 2：仅修改 Subgraph Schema
```bash
cd subgraph/

# 1. 修改 schema.graphql 或 mapping.ts
# 2. 重新生成代码
graph codegen

# 3. 重新构建
graph build

# 4. 重新部署
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook

# 5. 验证
curl -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ _meta { block { number } } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-sportsbook
```

#### 场景 3：添加新的市场类型
```bash
# 1. 开发新模板合约（如 NewTemplate.sol）
cd contracts/src/templates/
# ... 编写合约代码

# 2. 运行单元测试
cd ../../
forge test --match-contract NewTemplateTest -vvv

# 3. 更新 Deploy.s.sol，添加新模板注册逻辑
# 4. 更新 CreateAllMarketTypes.s.sol，添加创建函数
# 5. 重新部署
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 6. 创建测试市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes --rpc-url http://localhost:8545 --broadcast

# 7. 更新 Subgraph（如果需要新的事件处理）
cd ../subgraph/
# 修改 schema.graphql 和 src/mappings/*.ts
graph codegen && graph build
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook
```

### 🛠️ 常用调试命令

#### 查看链上状态
```bash
# 查询市场数量
cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getMarketCount()" --rpc-url http://localhost:8545

# 查询某个市场地址
cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getMarket(uint256)" 0 --rpc-url http://localhost:8545

# 查询市场状态
cast call <MARKET_ADDRESS> "status()" --rpc-url http://localhost:8545

# 查询 Vault 总资产
cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "totalAssets()" --rpc-url http://localhost:8545
```

#### 查看 Subgraph 状态
```bash
# 查看索引进度
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ indexingStatusForCurrentVersion(subgraphName: \"pitchone-sportsbook\") { synced health chains { latestBlock { number } } } }"}' \
  http://localhost:8030/graphql

# 查看 Graph Node 日志
docker logs -f graph-node

# 查看 PostgreSQL 数据
docker exec -it graph-postgres psql -U graph-node -d graph-node -c "SELECT * FROM subgraphs.subgraph;"
```

### 📝 注意事项

1. **合约地址更新**：每次重新部署合约后，必须更新 `subgraph/subgraph.yaml` 中的地址
2. **Anvil 状态重置**：重启 Anvil 会清空所有链上数据，需要重新部署
3. **Subgraph 同步延迟**：部署 Subgraph 后，需要等待几秒钟进行区块同步
4. **私钥安全**：示例中使用的是 Anvil 默认私钥（仅限本地测试）
5. **市场授权**：CreateAllMarketTypes.s.sol 会自动将所有市场授权到 Vault
6. **并发限制**：SimulateBets.s.sol 使用的测试账户数量限制为 10 个（Anvil 默认账户数）

### 🐛 常见问题排查

#### 问题 1：Subgraph 无法索引市场
**原因**：未通过 Factory 创建市场，或 subgraph.yaml 中的 Factory 地址不正确

**解决**：
```bash
# 1. 检查 Factory 地址
grep "address:" subgraph/subgraph.yaml

# 2. 确认所有市场都通过 Factory 创建
cast call <FACTORY_ADDRESS> "getMarketCount()" --rpc-url http://localhost:8545
```

#### 问题 2：下注失败（Insufficient liquidity）
**原因**：Vault 中没有足够的流动性

**解决**：
```bash
# 检查 Vault 余额
cast call <VAULT_ADDRESS> "totalAssets()" --rpc-url http://localhost:8545

# Deploy.s.sol 默认会初始化 1M USDC，如果不够可以手动添加
```

#### 问题 3：Graph Node 无法启动
**原因**：端口被占用或 Docker 服务未启动

**解决**：
```bash
# 检查端口占用
lsof -i :8020
lsof -i :8000
lsof -i :5001

# 清理并重启
cd subgraph/
docker-compose down -v
docker-compose up -d
```

## 核心架构

### 📊 项目进度：100% 核心开发完成（19/19 合约，912 测试全部通过）

**最新进展（2025-11-11, Week 8）**：
- ✅ 19 个核心合约全部完成（100% 完成度）
- ✅ 7 种市场模板全部完成（WDL、OU、OU_MultiLine、AH、OddEven、Score、PlayerProps）
- ✅ 4 种定价引擎（SimpleCPMM、LMSR、LinkedLinesController、ParimutuelPricing）
- ✅ 串关系统完成（Basket + CorrelationGuard，51 测试）
- ✅ 运营工具完成（CreditToken、Coupon、PayoutScaler，54 测试）
- ✅ 预言机集成（MockOracle + UMA OO Adapter，43 测试）
- ✅ Subgraph v0.3.0 完整部署，端到端数据流打通
- ✅ 912 个测试全部通过（100% 通过率）
- 🔄 前端开发进行中（用户端基础框架完成）
- 📋 待完成：前端功能完善、测试网部署、安全审计

### 1. 合约层架构（contracts/src/）

#### V3 架构（新）- 推荐用于新项目

**分层设计**：
```
Market_V3 (容器) ─── IPricingStrategy (定价策略)
       │                 ├── CPMMStrategy
       │                 ├── LMSRStrategy
       │                 └── ParimutuelStrategy
       │
       └──────────── IResultMapper (赛果映射)
                          ├── WDL_Mapper
                          ├── OU_Mapper
                          ├── AH_Mapper
                          ├── Score_Mapper
                          └── OddEven_Mapper
```

**核心组件**：
- **Market_V3.sol**：轻量级市场容器（~300 行），负责状态机管理和组件编排
- **IPricingStrategy**：可插拔的定价策略接口（CPMM/LMSR/Parimutuel）
- **IResultMapper**：可插拔的赛果映射接口，将比分映射到 outcome ID
- **详细文档**：`contracts/docs/Architecture_V3.md`

**V3 优势**：
- 新增玩法只需实现 IResultMapper（~50 行），无需继承整个市场合约
- 支持半输半赢（通过 weights 数组）
- 1012 个测试全部通过

#### V2 架构（当前生产）- 仍在使用

**模块组织**：
- **✅ MarketBase_V2.sol**：市场基础合约，定义市场生命周期（Open → Locked → Resolved → Finalized）
  - **注意**：此合约将在未来版本中废弃，新项目请使用 Market_V3
- **✅ MarketTemplateRegistry.sol**：市场模板注册表，管理 WDL/OU/AH/比分等玩法模板
- **✅ BettingRouter.sol**：统一投注入口合约（用户仅需授权一次即可投注所有市场）
  - **核心功能**：单笔下注、批量下注、滑点保护
  - **安全机制**：市场验证（工厂注册 + 状态检查 + trustedRouter 检查）
  - **MarketBase_V2 集成**：通过 `trustedRouter` 机制，Router 调用 `placeBetFor()` 代理下注
  - **强制要求**：所有市场创建后必须设置 `trustedRouter`，否则无法下注
  - **详细文档**：`contracts/docs/BettingRouter_Usage.md`
- **定价引擎**：
  - **✅ SimpleCPMM.sol**：二/三向 Constant Product Market Maker（23 测试，97.5% 覆盖率）
    - 用于 WDL、OU、AH、OddEven 等二/三向市场
  - **✅ LMSR.sol**：Logarithmic Market Scoring Rule（已完成，用于多结果市场）
    - 用于 ScoreTemplate（精确比分）和 PlayerProps（首位进球者）
    - 支持 3-100 个结果的多向市场
    - 动态流动性参数 b（影响价格敏感度）
  - **✅ LinkedLinesController.sol**：相邻线联动控制器（450 行，19 个测试，92.45% 覆盖率）
    - 线组管理、联动系数、套利检测、储备量调整
    - 用于 OU_MultiLine 多线市场
    - 完整使用文档：`contracts/docs/LinkedLinesController_Usage.md`
  - **✅ ParimutuelPricing.sol**：彩池/奖池定价引擎（225 行）
    - Pari-mutuel 模式：所有投注进入池子，1:1 兑换份额
    - 赔率在结算时计算：`payout = (总池子 / 胜方池子) * 用户份额`
    - 不需要初始流动性（初始储备为零）
    - 配套 `ParimutuelLiquidityProvider.sol`（280 行）提供流动性管理
    - 适用场景：传统彩票玩法、想要赔率完全反映市场投注分布
- **串关**：
  - **✅ Basket.sol**：Parlay 组合下注合约（537 行，25 个测试，100% 完成）
    - 支持 2-10 腿串关组合
    - 池化资金管理
    - 组合赔率计算与滑点保护
  - **✅ CorrelationGuard.sol**：相关性惩罚/阻断（386 行，25 个测试，100% 完成）
    - 同场同向限制检测
    - Discount/Block 策略
    - 动态相关性矩阵
- **预言机**：
  - **✅ MockOracle.sol**：测试预言机（220 行，19 个单元测试）
  - **✅ UMAOptimisticOracleAdapter.sol**：UMA OO 适配器（410 行，24 个测试，完整集成）
- **市场模板**（7/7 已完成，100% 核心玩法覆盖）：
  - **✅ WDL_Template.sol / WDL_Template_V2.sol**：胜平负市场（305 行，51 个测试，100% 覆盖率）
    - V2 支持 Clone 模式部署（initialize 替代 constructor）
  - **✅ OU_Template.sol**：大小球单线市场（328 行，47 个测试，97.96% 覆盖率）
    - 含 Push 退款机制（整数盘口线退款处理）
    - 支持 Clone 模式部署
  - **✅ OU_MultiLine.sol**：大小球多线市场（469 行，23 个测试，83.62% 覆盖率）
    - 支持多条盘口线（如 2.0、2.5、3.0 球）
    - 集成 LinkedLinesController 联动定价
    - Outcome ID 编码：lineIndex * 2 + direction
    - 仅支持半球盘（避免 Push 退款复杂性）
  - **✅ AH_Template.sol**：让球市场（418 行，28 个测试，100% 通过）
    - 半球盘（-0.5）：二向市场（主队赢盘/客队赢盘）
    - 整球盘（-1.0）：三向市场（含 Push 退款）
    - 支持主队让球/客队让球双向
    - 支持 Clone 模式部署
  - **✅ OddEven_Template.sol**：进球数单双市场（307 行，34 个测试，100% 通过）
    - 二向市场（奇数/偶数），判断总进球数奇偶性
    - 支持 Clone 模式部署
  - **✅ ScoreTemplate.sol**：精确比分市场（34 个测试，100% 通过）
    - 使用 LMSR 定价引擎（支持 25-100 个结果）
    - Outcome ID 编码：homeGoals * 10 + awayGoals（如 2-1 = 21）
    - 包含 "Other" 选项（outcomeId 999）用于超出范围的比分
    - 可配置比分范围（默认 0-5）
  - **✅ PlayerProps_Template.sol**：球员道具市场（14 个测试，100% 通过）
    - 支持 7 种道具类型：进球数 O/U、助攻数 O/U、射门次数 O/U、黄牌 Y/N、红牌 Y/N、任意时间进球 Y/N、首位进球者
    - O/U 市场使用 SimpleCPMM，首位进球者使用 LMSR
    - 支持半球盘和整球盘
- **运营基建**：
  - **✅ FeeRouter.sol**：费用路由（LP/Promo/Insurance/Treasury 分成，29 个测试）
  - **✅ RewardsDistributor.sol**：周度 Merkle 奖励分发（42 个测试）
  - **✅ ReferralRegistry.sol**：推荐关系注册与返佣计算（41 个测试）
  - **✅ Campaign.sol**：活动工厂（356 行，26 个测试 + 12 个集成测试，100% 通过）
    - 活动创建、预算管理、参与追踪、活动状态控制
  - **✅ Quest.sol**：任务系统（403 行，32 个测试，100% 通过）
    - 5 种任务类型（下注、推荐、串关、连续登录、社交）
    - 进度追踪、自动完成检测、奖励领取
  - **✅ CreditToken.sol**：免佣券（442 行，33 个测试，100% 完成）
    - 多种免佣券类型管理
    - 有效期和使用限制
    - 转让和销毁机制
  - **✅ Coupon.sol**：赔率加成券（599 行，10 个测试，100% 完成）
    - 加成券类型配置
    - 使用次数和有效期管理
    - 与市场集成
  - **✅ PayoutScaler.sol**：预算缩放策略（534 行，11 个测试，100% 完成）
    - 预算池管理
    - 动态缩放算法
    - 奖励分配优化
- **治理**：
  - **✅ ParamController.sol**：参数控制器（335 行，35 个测试，90.10% 行覆盖率，100% 函数覆盖率）
    - 完整的 Timelock 机制（提案创建/执行/取消）
    - 参数验证器支持（范围/白名单/黑名单）
    - 紧急暂停功能
    - 完整使用文档：`contracts/docs/ParamController_Usage.md`
  - 集成 Safe 多签 + Timelock

**关键设计模式**：
- **模板化扩展**：所有玩法通过 `IMarketTemplate` 接口标准化，支持热插拔
- **事件驱动**：所有状态变更发出标准化事件（参见各合约接口定义）
- **不变量保护**：AMM 守恒、LP 金库安全、串关赔率上限等通过 Scribble 断言 + Echidna 模糊测试验证
- **乐观式结算**：质押 → 争议窗口 → 最终确认，减少链上交互成本

### 2. 链下服务架构（backend/）

**服务组件**（均为独立 Go 进程）：
1. **✅ Indexer**（`cmd/indexer/`）- 已完成
   - 订阅合约事件（通过 WebSocket 或 HTTP 轮询）
   - 解析并写入 Postgres/Timescale（市场、订单、结算、奖励等表）
   - 支持重放和容错（记录最后处理的区块高度）
   - 代码量：~1,100 行，6 种核心事件支持

2. **✅ Keeper Service**（`cmd/keeper/`）- 基本完成
   - 定时任务执行：
     - ✅ 锁盘：开赛前 5 分钟调用 `market.lock()`
     - ✅ 结算：赛后调用 UMA OO 的 `proposeResult()`（308 行 UMA 集成）
     - ⏳ 发布 Merkle 根：周度调用 `RewardsDistributor.publishRoot()`
   - 冗余执行：本地 + Gelato/Chainlink Automation 双保险
   - 代码量：~1,500 行核心 + 1,200 行测试，19/20 测试通过（95%）

3. **✅ Rewards Builder**（`cmd/rewards/`）- 基础完成
   - 周度任务：
     - 从数据库聚合所有待发放奖励（推荐返佣、任务奖励、活动奖金）
     - 生成 Merkle 树并上链 Root
     - 用户凭 Merkle Proof 自行领取
   - 代码量：~800 行核心 + 400 行测试
   - 状态：基础框架完成，待完整集成测试

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

**✅ 部署状态**：完整部署成功（v0.3.0）
**✅ 基础设施**：Graph Node v0.34.1 + PostgreSQL 14 + IPFS Kubo v0.22.0
**✅ 验证状态**：端到端数据流打通，GraphQL 查询正常响应

**Schema 实体**（`schema.graphql`）：
- `Market`：市场实体（映射合约 MarketBase）
- `Position`：头寸实体（映射 ERC-1155 Transfer 事件）
- `Order`：订单实体（映射 BetPlaced 事件）
- `User`：用户聚合统计
- `Referral`：推荐关系（映射 ReferralBound 事件）
- `RewardClaim`：奖励领取记录（映射 RewardClaimed 事件）
- `OracleProposal`：预言机提案（映射 ResultProposed / ResultDisputed 事件）
- `FeeDistribution`：费用分配记录
- `GlobalStats`：全局聚合统计

**Event Handlers**（15+ handlers 已实现）：
- `handleMarketCreated` - 创建 Market 实体
- `handleBetPlaced` - 创建 Order 和 Position 实体
- `handleResultProposed` - 创建 OracleProposal 实体
- `handleFeeRouted` - 创建 FeeDistribution 实体

**查询示例**（已验证）：
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

**实际查询结果**（2025-11-01 验证）：
- Orders: 1 笔（1 USDC, outcome 0）
- Users: 1 个（总下注 1 USDC）
- Positions: 1 个（2,793,000 shares）
- Markets: 1 个（EPL_2024_MUN_vs_MCI, 状态: Open）
- GlobalStats: 总交易量 1 USDC, 手续费 0.02 USDC

### 4. 关键业务流程

#### 🚨 重要原则：市场创建

**所有市场必须通过 MarketFactory/MarketTemplateRegistry 创建，禁止直接部署市场合约！**

**原因**：
1. **Subgraph 索引依赖** - Subgraph 使用动态数据源模式，仅监听 Factory 的 `MarketCreated` 事件来自动索引新市场
2. **统一管理** - Factory 提供市场注册表、模板管理、权限控制等统一治理能力
3. **数据一致性** - 确保所有市场都被正确记录和跟踪，避免数据孤岛

**正确做法**：
```solidity
// ✅ 正确：通过 Factory 创建
MarketFactory.createMarket(templateId, initData);

// ❌ 错误：直接部署合约（Subgraph 无法索引）
new OddEven_Template(...);
```

**开发/测试脚本示例**：
```bash
# 正确：使用 Factory 创建市场的脚本
forge script script/CreateMarketsViaFactory.s.sol --broadcast
```

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
- **事件契约**：所有状态变更必须发出标准化事件（参见各合约接口定义）
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
- **M0（第 1 周）**：✅ 完成 - 脚手架（合约骨架、Indexer、Subgraph、CI/CD）
- **M1（第 3-4 周）**：✅ 完成 - 主流程闭环（WDL + OU 单线、AMM、结算、奖励/推荐）
- **M2（第 5-7 周）**：✅ 完成 - 运营闭环（活动/任务、周度 Merkle、OU 多线联动、AH、运营工具）
- **M3（第 8 周）**：✅ 完成 - 扩玩法与串关（精确比分 LMSR、球员道具、Basket 串关、CorrelationGuard）
- **M4（第 9-12 周）**：🔄 进行中 - 前端开发、测试网部署、安全审计

## 文档资源

- **技术详细设计**：`docs/design/` - 10 份模块设计文档
- **架构思维导图**：`docs/project_mind.md`
- **Subgraph Schema**：`subgraph/schema.graphql`

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
- [ ] 运行 `forge coverage` ���覆盖率 ≥80%
- [ ] 所有公开/外部函数都有 NatSpec 注释
- [ ] 敏感操作（转账、状态变更）有权限控制和事件记录
- [ ] 新增合约已添加对应的单元测试和不变量测试
- [ ] 链下服务的数据库操作使用了事务保护
- [ ] Subgraph 的事件处理器经过本地 Graph Node 测试
