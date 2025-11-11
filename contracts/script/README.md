# PitchOne 部署脚本使用指南

## 📋 脚本概览

本目录包含 3 个核心脚本，用于完整的合约部署、市场创建和测试数据生成流程：

| 脚本 | 功能 | 说明 |
|------|------|------|
| **Deploy.s.sol** | 部署所有合约 | 部署 USDC、Vault、Factory、模板等，生成 `deployments/localhost.json` |
| **CreateMarkets.s.sol** | 批量创建市场 | 根据配置创建 WDL、OU、AH、OddEven 市场 |
| **SimulateBets.s.sol** | 模拟用户下注 | 多用户、多市场模拟下注，生成测试数据 |

**辅助脚本**：
- **PostDeploy.sh**: 部署后自动更新 Subgraph（清理旧数据 + 重新部署）

---

## 🚀 快速开始

### 完整部署流程（3 步）

```bash
cd /home/harry/code/PitchOne/contracts

# 1️⃣ 部署合约（生成 deployments/localhost.json）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2️⃣ 更新 Subgraph（自动清理旧数据）
./script/PostDeploy.sh localhost

# 3️⃣ 创建测试市场（3 WDL + 4 OU）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4️⃣ 模拟用户下注（10 个用户，每人 3 次下注）
forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**执行后效果**：
- ✅ 所有合约部署完成
- ✅ Subgraph 索引最新合约
- ✅ 7 个测试市场创建完成
- ✅ 30 笔下注记录（10 用户 × 3 次）
- ✅ 前端可查看市场和下注数据

---

## 📖 脚本详细说明

### 1. Deploy.s.sol - 部署合约

**功能**：
- 部署 Mock USDC（测试代币）
- 部署 LiquidityVault（LP 金库）
- 部署 SimpleCPMM（定价引擎）
- 部署 FeeRouter（费用路由）
- 部署 ReferralRegistry（推荐注册）
- 部署 MarketFactory_v2（市场工厂）
- 注册 WDL、OU、OddEven 模板
- **输出** `deployments/localhost.json`（所有地址和模板 ID）

**使用方法**：
```bash
# 方式 1：使用默认 Anvil 账户
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 方式 2：使用自定义私钥
PRIVATE_KEY=0x<your-private-key> \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**输出示例**（`deployments/localhost.json`）：
```json
{
  "network": "localhost",
  "chainId": 31337,
  "deployedAt": 591,
  "timestamp": 1762486579,
  "contracts": {
    "usdc": "0x2b639Cc84e1Ad3aA92D4Ee7d2755A6ABEf300D72",
    "vault": "0xF85895D097B2C25946BB95C4d11E2F3c035F8f0C",
    "cpmm": "0x0b27a79cb9C0B38eE06Ca3d94DAA68e0Ed17F953",
    "feeRouter": "0xB468647B04bF657C9ee2de65252037d781eABafD",
    "referralRegistry": "0x7bdd3b028C4796eF0EAf07d11394d0d9d8c24139",
    "factory": "0x47c05BCCA7d57c87083EB4e586007530eE4539e9"
  },
  "templates": {
    "wdl": "0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc",
    "ou": "0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f",
    "oddEven": "0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b"
  }
}
```

---

### 2. CreateMarkets.s.sol - 批量创建市场

**功能**：
- 自动从 `deployments/localhost.json` 读取合约地址
- 通过 Factory 创建市场（Clone 模式）
- 支持 4 种市场类型：WDL（胜平负）、OU（大小球）、AH（让球）、OddEven（单双）

**默认配置**：
- **3 个 WDL 市场**：MUN vs LIV, ARS vs CHE, MCI vs TOT
- **4 个 OU 市场**：2.5 球、1.5 球、3.5 球
- **3 个 AH 市场**：-1.5、-1.0、-0.5 让球
- **0 个 OddEven 市场**（默认禁用）

**使用方法**：

```bash
# 默认配置（3 WDL + 4 OU + 3 AH）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 自定义市场数量
NUM_WDL_MARKETS=5 \
NUM_OU_MARKETS=2 \
NUM_AH_MARKETS=0 \
NUM_ODDEVEN_MARKETS=3 \
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**环境变量选项**：
| 变量 | 说明 | 默认值 |
|------|------|--------|
| `NUM_WDL_MARKETS` | WDL 市场数量 | 3 |
| `NUM_OU_MARKETS` | OU 市场数量 | 4 |
| `NUM_AH_MARKETS` | AH 市场数量 | 3 |
| `NUM_ODDEVEN_MARKETS` | OddEven 市场数量 | 0 |
| `CREATE_DIFFERENT_STATES` | 创建不同状态的市场（Open/Locked/Resolved） | false |

**预设赛事数据**：
脚本内置了多个真实球队的赛事配置，会按顺序创建：
- WDL: Manchester United vs Liverpool, Arsenal vs Chelsea, Manchester City vs Tottenham
- OU: Chelsea vs Newcastle (2.5), Aston Villa vs Brighton (2.5), West Ham vs Wolves (1.5)
- AH: Liverpool vs Burnley (-1.5), Manchester City vs Southampton (-1.0)

---

### 3. SimulateBets.s.sol - 模拟用户下注

**功能**：
- 自动从 `deployments/localhost.json` 读取 Factory 和 USDC 地址
- 使用 Anvil 默认 10 个账户模拟多用户下注
- 从 Factory 自动获取所有市场
- 支持多种下注分布策略（均匀/倾斜/随机）
- 自动跳过已锁定的市场

**使用方法**：

```bash
# 默认配置（10 用户，每人 3 次，5-50 USDC，均匀分布）
forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 自定义配置
NUM_BETTORS=20 \
MIN_BET_AMOUNT=10 \
MAX_BET_AMOUNT=100 \
BETS_PER_USER=5 \
OUTCOME_DISTRIBUTION=skewed \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**环境变量选项**：
| 变量 | 说明 | 默认值 |
|------|------|--------|
| `NUM_BETTORS` | 参与下注的用户数量（最多 10） | 10 |
| `MIN_BET_AMOUNT` | 最小下注金额（USDC） | 5 |
| `MAX_BET_AMOUNT` | 最大下注金额（USDC） | 50 |
| `BETS_PER_USER` | 每个用户平均下注次数 | 3 |
| `OUTCOME_DISTRIBUTION` | 下注分布策略 | balanced |
| `SKIP_LOCKED_MARKETS` | 跳过已锁定的市场 | true |

**下注分布策略**：
- **balanced**: 各选项均匀分布（33.3% / 33.3% / 33.3%）
- **skewed**: 热门选项占比高（70% / 20% / 10%）
- **random**: 完全随机分布

**Anvil 测试账户**：
脚本使用 Anvil 默认 10 个账户（私钥硬编码在脚本中），每个账户初始有 10,000 ETH 和无限 USDC（通过 MockERC20.mint）

---

## 🔧 PostDeploy.sh - 部署后自动化

**功能**：
1. 验证 `deployments/localhost.json` 存在
2. 调用 `update-config.js` 更新 `subgraph.yaml`
3. **清理旧 Subgraph 数据**（`graph remove`）
4. 创建新 Subgraph 实例（`graph create`）
5. 生成代码、构建、部署 Subgraph
6. 验证同步状态

**使用方法**：
```bash
# 在 contracts/ 目录下执行
./script/PostDeploy.sh localhost

# 或者从其他目录
/home/harry/code/PitchOne/contracts/script/PostDeploy.sh localhost
```

**脚本流程**：
```
✅ Found deployment file: deployments/localhost.json
📋 Deployment Info:
  Factory: 0x47c05BCCA7d57c87083EB4e586007530eE4539e9
  Start Block: 591

🔧 Step 1: Updating Subgraph configuration...
✅ Subgraph config updated successfully!

🗑️  Step 2: Cleaning old Subgraph data...
✅ Removed subgraph: pitchone-sportsbook
✅ Created subgraph: pitchone-sportsbook

🔨 Step 3: Building Subgraph...
✅ Build complete

📤 Step 4: Deploying Subgraph...
✅ Deployed to http://localhost:8010/subgraphs/name/pitchone-sportsbook

⏳ Step 5: Waiting for Subgraph to sync...
  Subgraph synced to block: 591
```

---

## 📊 数据流示意图

```
┌─────────────────┐
│  Deploy.s.sol   │ 部署合约
└────────┬────────┘
         │ 生成
         ▼
┌─────────────────────────┐
│ deployments/localhost.json │ ← 单一数据源（SSOT）
└────┬──────────┬─────────┘
     │          │
     │          │ 读取
     │          ▼
     │    ┌──────────────────┐
     │    │ CreateMarkets.s.sol│ 创建市场
     │    └──────────────────┘
     │          │
     │          ▼
     │    ┌──────────────────┐
     │    │ SimulateBets.s.sol │ 模拟下注
     │    └──────────────────┘
     │
     │ 读取
     ▼
┌──────────────┐
│ PostDeploy.sh│ 更新 Subgraph
└──────┬───────┘
       │
       ▼
┌────────────────┐
│ subgraph.yaml  │ Subgraph 配置
└────────────────┘
       │
       ▼
┌────────────────┐
│  Graph Node    │ 索引数据
└────────────────┘
       │
       ▼
┌────────────────┐
│   Frontend     │ 查询展示
└────────────────┘
```

---

## 💡 使用场景

### 场景 1：全新环境初始化
```bash
# 启动 Anvil
anvil

# 部署合约 + Subgraph + 市场 + 下注
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

./script/PostDeploy.sh localhost

PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets --rpc-url http://localhost:8545 --broadcast

forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast
```

### 场景 2：仅创建更多市场
```bash
# 创建 5 个 WDL 市场
NUM_WDL_MARKETS=5 NUM_OU_MARKETS=0 NUM_AH_MARKETS=0 \
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets --rpc-url http://localhost:8545 --broadcast
```

### 场景 3：生成大量测试数据
```bash
# 20 个用户，每人 10 次下注，倾斜分布
NUM_BETTORS=10 BETS_PER_USER=10 OUTCOME_DISTRIBUTION=skewed \
  forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast
```

### 场景 4：重新部署合约（清理旧数据）
```bash
# 1. 重新部署
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 2. 清理并重新部署 Subgraph（自动删除旧数据）
./script/PostDeploy.sh localhost

# 3. 创建新市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets.s.sol:CreateMarkets --rpc-url http://localhost:8545 --broadcast
```

---

## ⚙️ 配置要求

### 必需环境
- ✅ Anvil 运行在 `http://localhost:8545`
- ✅ Graph Node 运行在 `http://localhost:8020`
- ✅ IPFS 运行在 `http://localhost:5001`

### Foundry 配置
在 `foundry.toml` 中必须添加：
```toml
[profile.default]
fs_permissions = [
    { access = "read", path = "./deployments" }
]
```

### 检查环境
```bash
# 检查 Anvil
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 检查 Graph Node
curl http://localhost:8020

# 检查 IPFS
curl http://localhost:5001/api/v0/version
```

---

## 🐛 故障排查

### 问题 1：`vm.readFile: path not allowed`
**原因**：`foundry.toml` 没有配置文件系统权限

**解决方案**：
```toml
# 添加到 foundry.toml
[profile.default]
fs_permissions = [
    { access = "read", path = "./deployments" }
]
```

### 问题 2：`Deployment file not found`
**原因**：未运行 `Deploy.s.sol` 或 JSON 文件被删除

**解决方案**：
```bash
# 重新运行部署
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

### 问题 3：Subgraph 仍显示旧数据
**原因**：未清理旧 Subgraph

**解决方案**：
```bash
# 运行 PostDeploy.sh（会自动清理）
./script/PostDeploy.sh localhost
```

### 问题 4：SimulateBets 失败 `Insufficient allowance`
**原因**：用户未批准市场使用 USDC

**解决方案**：脚本已自动处理。如果仍报错，检查 USDC 合约地址是否正确。

### 问题 5：CreateMarkets 失败 `Template not registered`
**原因**：Deploy.s.sol 未正确注册模板

**解决方案**：
```bash
# 检查 deployments/localhost.json 中 templates 是否存在
cat deployments/localhost.json | jq '.templates'

# 如果为空，重新运行 Deploy.s.sol
```

---

## 📚 相关文档

- **统一地址管理方案**：`README_DEPLOYMENT.md`（详细架构说明）
- **Subgraph 文档**：`../../subgraph/README.md`
- **合约文档**：`../../docs/`
- **CLAUDE.md**：项目整体架构和开发指南

---

## 🔑 快速参考

### Anvil 默认账户
```bash
# Account #0 (部署者账户)
Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Account #1-9 (测试用户)
# 参见 SimulateBets.s.sol 中的 testPrivateKeys 数组
```

### 常用命令
```bash
# 查看部署信息
cat deployments/localhost.json | jq

# 查看 Factory 创建的市场数量
cast call <FACTORY_ADDRESS> "getMarketCount()(uint256)" --rpc-url http://localhost:8545

# 查看 Subgraph 同步状态
curl -X POST http://localhost:8010/subgraphs/name/pitchone-sportsbook \
  -H "Content-Type: application/json" \
  -d '{"query":"{ _meta { block { number } } }"}'
```

---

**最后更新**：2025-11-08
**维护者**：PitchOne 开发团队
