# PitchOne 自动化数据流文档

本文档说明如何实现完全自动化的合约地址数据流，从部署到 Subgraph 索引无需手动干预。

## 🎯 目标

确保每个步骤都能自动使用上一步产生的数据（特别是合约地址），消除手动复制粘贴的需求。

## 📋 数据流概览

```
Deploy.s.sol
  ↓
deployments/localhost.json (✅ 自动生成)
  ↓
  ├── CreateAllMarketTypes.s.sol (✅ 自动读取 - 支持全部 7 种市场类型)
  ├── SimulateBets.s.sol (✅ 自动读取)
  └── reset-subgraph.sh (✅ 自动读取并部署)
       ↓
     subgraph.yaml (✅ 自动生成)
       ↓
     Graph Node 索引 (✅ 自动同步)
```

## ✅ 实现的自动化步骤

### 步骤 1: Deploy.s.sol → localhost.json

**实现方式**: Deploy 脚本自动生成 JSON 配置文件

**位置**: `contracts/deployments/localhost.json`

**包含数据**:
- 所有合约地址（usdc, vault, feeRouter, factory, cpmm, lmsr, parimutuel, referralRegistry）
- 所有模板 ID（wdl, ou, ouMultiLine, ah, oddEven, score, playerProps）
- 所有实现地址
- 部署元数据（chainId, timestamp, deployedAt）

**示例**:
```json
{
  "contracts": {
    "factory": "0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154",
    "usdc": "0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00",
    ...
  },
  "templates": {
    "wdl": "0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc",
    ...
  }
}
```

---

### 步骤 2: localhost.json → CreateAllMarketTypes.s.sol

**实现方式**: Solidity 脚本使用 `vm.readFile()` 和 `vm.parseJson()` 读取配置

**支持的市场类型**: 全部 7 种
- ✅ WDL (胜平负) - 3 个市场
- ✅ OU (大小球单线) - 3 个市场
- ✅ AH (让球) - 3 个市场
- ✅ OddEven (单双) - 3 个市场
- ✅ Score (精确比分) - 3 个市场
- ✅ OU_MultiLine (多线大小球) - 3 个市场
- ✅ PlayerProps (球员道具) - 3 个市场
- **总计**: 21 个市场

**关键代码** (`CreateAllMarketTypes.s.sol`):
```solidity
string constant DEPLOYMENT_FILE = "deployments/localhost.json";

function _loadDeploymentConfig() internal {
    string memory deploymentData = vm.readFile(DEPLOYMENT_FILE);

    // 自动读取合约地址
    FACTORY = vm.parseJsonAddress(deploymentData, ".contracts.factory");
    USDC = vm.parseJsonAddress(deploymentData, ".contracts.usdc");
    VAULT = vm.parseJsonAddress(deploymentData, ".contracts.vault");
    FEE_ROUTER = vm.parseJsonAddress(deploymentData, ".contracts.feeRouter");
    SIMPLE_CPMM = vm.parseJsonAddress(deploymentData, ".contracts.cpmm");
    LMSR = vm.parseJsonAddress(deploymentData, ".contracts.lmsr");
    PARIMUTUEL = vm.parseJsonAddress(deploymentData, ".contracts.parimutuel");

    // 自动读取所有 7 种 Template IDs
    WDL_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.wdl");
    OU_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ou");
    OU_MULTILINE_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ouMultiLine");
    AH_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ah");
    ODD_EVEN_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.oddEven");
    SCORE_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.score");
    PLAYER_PROPS_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.playerProps");
}
```

**优势**:
- ✅ 支持全部 7 种市场类型（包括 LMSR 和多线市场）
- ✅ 无需手动更新地址
- ✅ 每次部署后自动使用最新地址
- ✅ 消除人为错误

---

### 步骤 3: localhost.json → SimulateBets.s.sol

**实现方式**: 与步骤 2 相同，使用 Foundry 的 JSON 解析功能

**关键代码** (`SimulateBets.s.sol`):
```solidity
string constant DEPLOYMENT_FILE = "deployments/localhost.json";

function _loadConfig() internal {
    string memory json = vm.readFile(DEPLOYMENT_FILE);
    factory = vm.parseJsonAddress(json, ".contracts.factory");
    usdc = vm.parseJsonAddress(json, ".contracts.usdc");
}
```

---

### 步骤 4: localhost.json → subgraph.yaml → Graph Node

**实现方式**: `reset-subgraph.sh` 一键完成配置更新和部署

**脚本**: `subgraph/reset-subgraph.sh`

**功能**:
1. 清理旧的 Graph Node 数据
2. 重启 Graph Node 服务（Docker Compose）
3. 生成 Subgraph 代码（graph codegen）
4. 构建 Subgraph（graph build）
5. 部署到本地 Graph Node（graph deploy）

**⚠️ 首次部署注意事项**:
如果是首次部署 Subgraph，需要先创建 Subgraph 名称：
```bash
cd subgraph
graph create --node http://localhost:8020/ pitchone-local
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 --version-label v0.1.0 pitchone-local
```

**支持的数据源**:
- ✅ MarketFactory（监听 MarketCreated 事件）
- ✅ FeeRouter（监听 FeeRouted 事件）
- ✅ 7 种市场模板的动态数据源（WDL, OU, AH, OddEven, Score, OU_MultiLine, PlayerProps）

**使用方法**:
```bash
cd subgraph
./reset-subgraph.sh

# 输出:
# ========================================
#   Subgraph 重置和重新部署
# ========================================
# 1. 清理 Graph Node... ✅
# 2. 启动 Graph Node... ✅
# 3. 生成 Subgraph 代码... ✅
# 4. 部署 Subgraph... ✅
#
# GraphQL: http://localhost:8010/subgraphs/name/pitchone-local
```

---

### 步骤 5: 一键式完整流程

**完整部署流程**（手动执行每个步骤）:
```bash
# 1. 启动 Anvil（在单独终端）
cd contracts/
anvil --host 0.0.0.0

# 2. 部署合约 → 生成 localhost.json
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 3. 创建所有 7 种类型的市场（自动从 localhost.json 读取）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 模拟投注（自动从 localhost.json 读取）
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 重建 Subgraph（一键完成配置和部署）
cd ../subgraph/
./reset-subgraph.sh
```

**预期结果**:
- ✅ 部署 19 个核心合约
- ✅ 注册 7 种市场模板
- ✅ 创建 21 个测试市场（7 种类型 × 3 个）
- ✅ 生成约 45 笔测试投注（5 个用户，90% 成功率）
- ✅ Subgraph 索引所有市场和投注数据
- ✅ GraphQL 查询端点：http://localhost:8010/subgraphs/name/pitchone-local

---

## 📊 数据流验证

### 1. 验证 localhost.json 生成

```bash
cat contracts/deployments/localhost.json | jq '.contracts'

# 预期输出:
# {
#   "usdc": "0x5eb3...",
#   "vault": "0x36C0...",
#   "factory": "0x5f3f...",
#   ...
# }
```

### 2. 验证脚本读取正确地址

```bash
cd contracts
PRIVATE_KEY=0xac0... \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  -vv

# 输出应包含:
# Creating All Market Types (7 types)
# Total Markets Created: 21
# Breakdown by Type:
#   - WDL: 3
#   - OU: 3
#   - AH: 3
#   - OddEven: 3
#   - Score: 3
#   - OU_MultiLine: 3
#   - PlayerProps: 3
```

### 3. 验证 Subgraph 部署

```bash
cd subgraph
./reset-subgraph.sh

# 输出应包含:
# ========================================
#   Subgraph 重置和重新部署
# ========================================
# 1. 清理 Graph Node... ✅
# 2. 启动 Graph Node... ✅
# 3. 生成 Subgraph 代码... ✅
# 4. 部署 Subgraph... ✅
#
# GraphQL: http://localhost:8010/subgraphs/name/pitchone-local
```

### 4. 验证 Subgraph 索引

```bash
# 查询 Subgraph
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 5) { id state } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .

# 应返回 21 个市场（7 种类型 × 3 个）
# 示例输出:
# {
#   "data": {
#     "markets": [
#       { "id": "0x043422...", "state": "Open" },
#       { "id": "0x07bec4...", "state": "Open" },
#       ...
#     ]
#   }
# }
```

---

## 🔄 部署策略选择

根据测试需求选择不同的部署策略：

### 策略 1: 全新环境部署（推荐用于功能测试）

**适用场景**：
- 初次部署
- 需要干净的测试环境
- 验证完整的部署流程

```bash
# 1. 重启 Anvil（清空所有链上数据）
pkill anvil && sleep 2
cd contracts && anvil --host 0.0.0.0 &

# 2. 等待 Anvil 启动
sleep 3

# 3. 部署合约
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 创建市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 模拟投注
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 6. 重建 Subgraph
cd ../subgraph && ./reset-subgraph.sh
```

### 策略 2: 增量部署（推荐用于集成测试）

**适用场景**：
- 测试旧数据是否会干扰新部署
- 验证数据兼容性和迁移逻辑
- 调试合约升级问题
- 快速迭代开发（无需等待 Anvil 重启）

**优势**：
- ✅ 保留链上历史数据，测试数据兼容性
- ✅ 无需重启 Anvil，节省时间
- ✅ 可以验证多版本合约共存情况
- ✅ 模拟真实环境的升级场景

```bash
# 1. 确认 Anvil 正在运行
cast block-number --rpc-url http://localhost:8545

# 如果 Anvil 未运行，启动它（仅首次）
# cd contracts && anvil --host 0.0.0.0 &

# 2. 直接部署合约（旧合约和数据仍在链上）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 3. 创建市场（使用新部署的 Factory）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 模拟投注
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 重建 Subgraph（会索引所有历史 + 新数据）
cd ../subgraph && ./reset-subgraph.sh
```

**注意事项**：
- 新部署会生成新的合约地址（存储在 `localhost.json`）
- 旧合约的数据仍然存在，但不会被新的 Subgraph 索引（Subgraph 只监听 `localhost.json` 中的地址）
- 如果需要完全清空旧数据，使用策略 1

### 数据流自动执行

两种策略的数据流都是自动的：
```
Deploy.s.sol → localhost.json ✅
localhost.json → CreateAllMarketTypes.s.sol ✅
localhost.json → SimulateBets.s.sol ✅
reset-subgraph.sh → Graph Node ✅
```

---

## 🛠️ 手动更新（仅用于调试）

如果需要手动更新某个步骤：

### 仅更新 Subgraph 配置

```bash
cd subgraph
node config/update-config.js ../contracts/deployments/localhost.json
```

### 仅重新部署 Subgraph

```bash
cd subgraph
./reset-subgraph.sh
```

---

## 📁 文件清单

### 自动生成的文件（不要手动编辑）

- ✅ `contracts/deployments/localhost.json` - 自动生成
- ✅ `subgraph/subgraph.yaml` - 自动生成
- ❌ 不要直接编辑这些文件！

### 需要维护的文件

- ✅ `contracts/script/Deploy.s.sol` - 部署逻辑（部署所有核心合约和 7 种模板）
- ✅ `contracts/script/CreateAllMarketTypes.s.sol` - 市场创建逻辑（创建全部 7 种类型的市场）
- ✅ `contracts/script/SimulateBets.s.sol` - 投注模拟逻辑（支持所有市场类型）
- ✅ `subgraph/subgraph.yaml` - Subgraph 配置（监听 Factory 和 7 种模板）
- ✅ `subgraph/reset-subgraph.sh` - Subgraph 重建脚本（一键清理、配置、部署）
- ✅ `subgraph/src/mappings/*.ts` - Event handlers（处理 7 种市场类型的事件）

---

## ❌ 反模式（避免这些做法）

### ❌ 错误做法 1: 硬编码地址

```solidity
// ❌ 不要这样做
address constant FACTORY = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;
```

**正确做法**:
```solidity
// ✅ 从 JSON 读取
address FACTORY;
function run() external {
    string memory json = vm.readFile("deployments/localhost.json");
    FACTORY = vm.parseJsonAddress(json, ".contracts.factory");
}
```

---

### ❌ 错误做法 2: 手动编辑 subgraph.yaml

```yaml
# ❌ 不要手动编辑 subgraph.yaml
source:
  address: "0x5f3f..."  # 每次重新部署都要改
```

**正确做法**:
```bash
# ✅ 使用自动化脚本
cd subgraph
node config/update-config.js ../contracts/deployments/localhost.json  # 自动读取
```

---

### ❌ 错误做法 3: 复制粘贴地址

```bash
# ❌ 不要这样做
FACTORY="0x5f3f..."  # 从终端输出复制
```

**正确做法**:
```bash
# ✅ 使用 jq 自动提取
FACTORY=$(jq -r '.contracts.factory' deployments/localhost.json)
```

---

## 🎯 关键要点

1. **单一数据源**: `localhost.json` 是所有合约地址的唯一来源
2. **自动化优先**: 所有步骤都通过脚本自动化，避免手动操作
3. **模板化配置**: `subgraph.template.yaml` 使用占位符，运行时替换
4. **Foundry 集成**: 使用 `vm.readFile()` 和 `vm.parseJson()` 读取配置
5. **验证机制**: 每个步骤都有输出验证，确保正确性

---

## 📚 相关文档

- [完整 SOP 文档](./subgraph/SOP_LOCAL_DEPLOYMENT.md)
- [快速部署脚本](./scripts/quick-deploy.sh)
- [自动化流程图](./subgraph/DEPLOYMENT_FLOW.md)
- [合约部署说明](./contracts/README.md)

---

## 🎰 Parimutuel 定价引擎集成

### 概述

Parimutuel（奖池式）定价引擎已集成到自动化数据流中，支持创建零虚拟储备的市场。与传统 AMM (SimpleCPMM) 相比，Parimutuel 模式的赔率完全由实际投注分布决定，提供更接近传统博彩的体验。

### 定价引擎对比

| 特性 | Parimutuel | SimpleCPMM | LMSR |
|------|-----------|------------|------|
| **虚拟储备** | 0（零初始化） | 100,000 USDC | 可配置参数 b |
| **份额计算** | 1:1 兑换 | AMM 公式 | 对数市场评分 |
| **赔率变化** | 显著（反映真实市场） | 平缓（0.12%/笔） | 适度（取决于 b） |
| **初始流动性** | 无需借款 | 借出 10% | 借出 10% |
| **适用场景** | 传统博彩、二向市场 | 稳定深度流动性 | 多结果市场 |
| **使用模板** | OddEven_V2 | WDL, OU, AH | Score, PlayerProps |

### 部署流程集成

Parimutuel 引擎已自动集成到 Deploy.s.sol 中：

```solidity
// Deploy.s.sol 自动部署所有定价引擎
SimpleCPMM cpmm = new SimpleCPMM();
LMSR lmsr = new LMSR();
ParimutuelPricing parimutuel = new ParimutuelPricing();  // ← 新增

// 自动写入 localhost.json
deploymentData = vm.serializeAddress("contracts", "cpmm", address(cpmm));
deploymentData = vm.serializeAddress("contracts", "lmsr", address(lmsr));
deploymentData = vm.serializeAddress("contracts", "parimutuel", address(parimutuel));  // ← 新增
```

### 创建 Parimutuel 市场

#### 方式 1: 使用 CreateAllMarketTypes.s.sol

脚本已支持创建 Parimutuel 市场（通过 OddEven_V2 模板）：

```solidity
// CreateAllMarketTypes.s.sol 自动读取 Parimutuel 地址
PARIMUTUEL = vm.parseJsonAddress(deploymentData, ".contracts.parimutuel");

// 创建 Parimutuel 模式的 OddEven 市场
function createOddEvenMarkets() internal {
    // ...
    market.initialize(
        // ... 其他参数
        address(PARIMUTUEL),  // 使用 Parimutuel 引擎
        address(VAULT),
        "",
        0  // ← virtualReservePerSide = 0 = Parimutuel 模式
    );
}
```

**一键部署**：
```bash
cd contracts/

# 1. 部署合约（包含 Parimutuel 引擎）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2. 创建市场（自动包含 Parimutuel 市场）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast
```

#### 方式 2: 使用专用部署脚本

使用 `DeployParimutuel.s.sol` 单独部署和测试：

```bash
cd contracts/

# 部署 Parimutuel 引擎并创建测试市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/DeployParimutuel.s.sol:DeployParimutuel \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 测试 Parimutuel 市场

使用 `TestParimutuel.s.sol` 验证赔率变化：

```bash
cd contracts/

# 模拟投注并对比 Parimutuel vs SimpleCPMM
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/TestParimutuel.s.sol:TestParimutuel \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**预期输出示例**：
```
=== Parimutuel 模式（零虚拟储备）===
第 1 笔：23 USDC on Outcome 1
  - 赔率: ∞ → 需要对手盘
  - 获得份额: 22.54 USDC

第 2 笔：123 USDC on Outcome 0
  - 赔率: 1.19x (Outcome 0)
  - 池子比例: 84% vs 16%

第 3 笔：1 USDC on Outcome 1
  - 赔率: Outcome 1 从 6.0x → 5.8x
  - 总池子: 144.06 USDC

=== SimpleCPMM 模式（100,000 虚拟储备）===
第 1 笔：23 USDC on Outcome 1
  - 价格变化: +0.01%
  - 收益率: 97.97%

第 2 笔：123 USDC on Outcome 0
  - 价格变化: +0.12%
  - 收益率: 97.92%
```

### 验证数据流

#### 1. 验证 Parimutuel 引擎已部署

```bash
# 检查 localhost.json 是否包含 parimutuel 地址
cat contracts/deployments/localhost.json | jq '.contracts.parimutuel'

# 预期输出：
# "0x..."
```

#### 2. 查询 Parimutuel 市场状态

```bash
# 获取市场地址（假设第 4 个市场是 OddEven Parimutuel）
MARKET=$(cast call <FACTORY_ADDRESS> "getMarket(uint256)" 3 --rpc-url http://localhost:8545 | sed 's/^0x000000000000000000000000/0x/')

# 查询虚拟储备（应为实际投注池）
cast call $MARKET "virtualReserves(uint256)" 0 --rpc-url http://localhost:8545
cast call $MARKET "virtualReserves(uint256)" 1 --rpc-url http://localhost:8545

# 查询定价引擎地址
cast call $MARKET "pricingEngine()" --rpc-url http://localhost:8545

# 应返回 Parimutuel 引擎地址
```

#### 3. 验证 Subgraph 索引

```bash
# Parimutuel 市场的投注同样会被 Subgraph 索引
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(where: { pricingEngine: \"<PARIMUTUEL_ADDRESS>\" }) { id totalVolume outcomeReserves } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .
```

### 关键差异和注意事项

#### 1. 零初始流动性

Parimutuel 市场无需从 Vault 借出初始流动性：
- **SimpleCPMM**: 借出 10,000 USDC (10%)
- **Parimutuel**: 借出 0 USDC（启动成本为零）

#### 2. 虚拟储备的语义变化

- **SimpleCPMM**: `virtualReserves` 是定价参数（可能远大于实际资金）
- **Parimutuel**: `virtualReserves` 是实际投注累计额（1:1 映射）

```solidity
// Parimutuel 模式下的储备更新
virtualReserves[outcomeId] += netAmount;  // 直接累加投注额

// SimpleCPMM 模式下的储备更新
virtualReserves[outcomeId] -= shares;     // AMM 公式计算
virtualReserves[opponentId] += netAmount;
```

#### 3. 赔付公式（两种模式通用）

MarketBase_V2 的赔付公式同时支持两种模式：

```solidity
payout = (shares * distributableLiquidity) / totalWinningShares;
```

- **Parimutuel**: shares = 投入金额, distributableLiquidity = 总池子
- **SimpleCPMM**: shares = AMM 份额, distributableLiquidity = 可分配流动性

### 潜在问题和解决方案

#### 问题 1: 初始赔率不稳定

**现象**: 第一笔投注后赔率为∞，用户体验差

**解决方案**:
- 方案 A: 平台提供初始种子流动性（10 USDC 均等分布）
- 方案 B: 前端显示"等待对手盘"提示
- 方案 C: 使用小额虚拟储备（如 1,000 USDC）平滑初期赔率

#### 问题 2: 单边市场风险

**现象**: 所有投注都在同一边，无法结算

**解决方案**:
- 限制单边投注比例（如最多 95:5）
- 单边市场视为"无对手盘"并退款

#### 问题 3: 滑点保护失效

**现象**: 赔率剧烈波动导致大量交易失败

**解决方案**:
- 调整滑点容忍度（5% → 20%）
- 前端显示实时赔率并要求用户确认

### 完整示例：创建并测试 Parimutuel 市场

```bash
# ========================================
# 一键式完整流程（包含 Parimutuel）
# ========================================

# 1. 启动 Anvil
pkill anvil && sleep 2
cd contracts && anvil --host 0.0.0.0 &
sleep 3

# 2. 部署合约（包含 Parimutuel 引擎）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 3. 创建所有市场（包含 Parimutuel OddEven 市场）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 模拟投注（包含 Parimutuel 市场）
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 验证 Parimutuel 赔率变化（可选）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/TestParimutuel.s.sol:TestParimutuel \
  --rpc-url http://localhost:8545 \
  --broadcast

# 6. 部署 Subgraph（索引所有市场包括 Parimutuel）
cd ../subgraph && ./reset-subgraph.sh
```

### 相关文档

- **实现文档**: `contracts/docs/PARIMUTUEL_IMPLEMENTATION.md`
- **定价引擎源码**: `contracts/src/pricing/ParimutuelPricing.sol`
- **部署脚本**: `contracts/script/DeployParimutuel.s.sol`
- **测试脚本**: `contracts/script/TestParimutuel.s.sol`
- **OddEven V2 模板**: `contracts/src/templates/OddEven_Template_V2.sol`

---

**最后更新**: 2025-11-15
**作者**: PitchOne Team
**状态**: ✅ 完全自动化实现（包含 Parimutuel 引擎）
