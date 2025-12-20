# PitchOne 合约脚本使用指南

## 📋 脚本概览

本目录包含 4 个 Forge 脚本：

| 脚本 | 功能 | 说明 |
|------|------|------|
| **Deploy.s.sol** | 部署所有合约 | 部署 USDC、Vault、Factory、7 种市场模板，生成 `deployments/localhost.json` |
| **CreateAllMarketTypes.s.sol** | 创建测试市场 | 创建 7 种类型（WDL、OU、OU_MultiLine、AH、OddEven、Score、PlayerProps）共 21 个测试市场 |
| **SimulateBets.s.sol** | 模拟用户下注 | 多用户、多市场模拟下注，通过 BettingRouter 统一投注 |
| **SetupReferrals.s.sol** | 建立推荐关系 | 为测试用户建立推荐关系（账户 #0 为推荐人，#1-9 为被推荐人） |

---

## 🚀 快速开始

### 完整测试流程

```bash
cd contracts/

# 1. 启动 Anvil（新终端）
anvil --host 0.0.0.0

# 2. 部署所有合约
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 3. 创建所有类型测试市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast

# 4. 建立推荐关系（可选）
forge script script/SetupReferrals.s.sol:SetupReferrals \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 模拟多用户下注
NUM_BETTORS=5 \
MIN_BET_AMOUNT=10 \
MAX_BET_AMOUNT=100 \
BETS_PER_USER=2 \
OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

## 📖 脚本详细说明

### 1. Deploy.s.sol - 部署所有合约

**功能**：
- 部署 Mock USDC（测试代币）
- 部署 LiquidityVault（LP 金库）
- 部署定价引擎（SimpleCPMM、LMSR、LinkedLinesController）
- 部署运营工具（FeeRouter、ReferralRegistry、BettingRouter 等）
- 部署 MarketFactory_v2（市场工厂）
- 注册 7 种市场模板（WDL_V2、OU、OU_MultiLine、AH、OddEven、Score、PlayerProps）
- **输出** `deployments/localhost.json`（所有地址和模板 ID）

**使用方法**：
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**输出文件**（`deployments/localhost.json`）包含：
- `contracts`: 所有部署的合约地址（包括 `bettingRouter`）
- `templates`: 7 种市场模板的 Template ID（bytes32）
- `deployedAt`: 部署所在区块号
- `chainId`: 链 ID

---

### 2. CreateAllMarketTypes.s.sol - 创建所有类型测试市场

**功能**：
- 自动从 `deployments/localhost.json` 读取合约地址和模板 ID
- 创建 7 种市场类型，每种 3 个市场，总共 21 个市场
- 自动授权所有市场到 LiquidityVault
- **自动设置每个市场的 `trustedRouter`**（用户才能通过 Router 下注）

**创建的市场类型**：
1. **WDL（胜平负）** × 3：MUN vs LIV, ARS vs CHE, MCI vs TOT
2. **OU（大小球单线）** × 3：2.5 球、1.5 球、3.5 球
3. **OU_MultiLine（大小球多线）** × 3：多条盘口线（2.0/2.5/3.0 球）
4. **AH（让球）** × 3：-1.5、-1.0、-0.5 让球
5. **OddEven（进球数单双）** × 3：总进球数奇偶判断
6. **Score（精确比分）** × 3：使用 LMSR 定价
7. **PlayerProps（球员道具）** × 3：进球数 O/U、首位进球者等

**使用方法**：
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**重要提示**：
- ⚠️ 必须先运行 `Deploy.s.sol` 生成 `deployments/localhost.json`
- ⚠️ 所有市场会自动授权并设置 trustedRouter
- ✅ 脚本会打印所有创建的市场地址

---

### 3. SimulateBets.s.sol - 模拟用户下注

**功能**：
- 自动从 `deployments/localhost.json` 读取 Factory、USDC、BettingRouter 地址
- 使用 Anvil 默认 10 个账户模拟多用户下注
- **通过 BettingRouter 统一投注**（用户仅需授权 Router 一次）
- 从 Factory 自动获取所有市场
- 支持多种下注分布策略（均匀/倾斜/随机）
- 自动跳过已锁定的市场

**使用方法**：

```bash
# 默认配置（5 用户，每人 2 次，10-100 USDC，均匀分布）
forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 自定义配置
NUM_BETTORS=10 \
MIN_BET_AMOUNT=50 \
MAX_BET_AMOUNT=200 \
BETS_PER_USER=5 \
OUTCOME_DISTRIBUTION=skewed \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**环境变量选项**：
| 变量 | 说明 | 默认值 |
|------|------|--------|
| `NUM_BETTORS` | 参与下注的用户数量（最多 10） | 5 |
| `MIN_BET_AMOUNT` | 最小下注金额（USDC） | 10 |
| `MAX_BET_AMOUNT` | 最大下注金额（USDC） | 100 |
| `BETS_PER_USER` | 每个用户平均下注次数 | 2 |
| `OUTCOME_DISTRIBUTION` | 下注分布策略 | balanced |

**下注分布策略**：
- **balanced**: 各选项均匀分布（50% / 50% 或 33% / 33% / 33%）
- **skewed**: 热门选项占比高（70% / 20% / 10%）
- **random**: 完全随机分布

---

### 4. SetupReferrals.s.sol - 建立推荐关系

**功能**：
- 自动从 `deployments/localhost.json` 读取 ReferralRegistry 地址
- 账户 #0 作为推荐人
- 账户 #1-9 作为被推荐人，绑定到账户 #0
- 跳过已绑定的账户

**使用方法**：
```bash
forge script script/SetupReferrals.s.sol:SetupReferrals \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**推荐关系结构**：
```
账户 #0 (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) - 推荐人
  ├── 账户 #1 - 被推荐人
  ├── 账户 #2 - 被推荐人
  ├── ...
  └── 账户 #9 - 被推荐人
```

---

## 💡 使用场景

### 场景 1：全新环境初始化
```bash
# 1. 启动 Anvil（新终端）
anvil --host 0.0.0.0

# 2. 按顺序执行所有脚本
cd contracts/

# 部署
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 创建市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes --rpc-url http://localhost:8545 --broadcast

# 建立推荐关系
forge script script/SetupReferrals.s.sol:SetupReferrals --rpc-url http://localhost:8545 --broadcast

# 模拟下注
forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast

# 3. 重新索引 Subgraph（如需要）
cd ../subgraph && ./deploy.sh -c -u -y
```

### 场景 2：仅创建更多测试数据
```bash
# 假设已部署合约和市场，仅增加下注数据
NUM_BETTORS=10 BETS_PER_USER=10 \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 场景 3：重新部署（清理旧环境）
```bash
# 1. 重启 Anvil（清空链状态）
pkill anvil && sleep 2 && anvil --host 0.0.0.0 &

# 2. 执行完整流程
cd contracts/
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes --rpc-url http://localhost:8545 --broadcast
forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast

# 3. 重新部署 Subgraph
cd ../subgraph && ./deploy.sh -c -u -y
```

---

## ⚙️ 配置要求

### 必需环境
- ✅ Anvil 运行在 `http://localhost:8545`
- ✅ Foundry 已安装（`forge`, `cast`）

### Foundry 配置
在 `foundry.toml` 中必须添加：
```toml
[profile.default]
fs_permissions = [
    { access = "read-write", path = "./deployments" }
]
```

### 检查环境
```bash
# 检查 Anvil
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 检查 Forge 版本
forge --version
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
    { access = "read-write", path = "./deployments" }
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

### 问题 3：`UnauthorizedMarket` 错误
**原因**：市场未授权到 LiquidityVault

**解决方案**：
- `CreateAllMarketTypes.s.sol` 会自动授权所有市场
- 如果手动创建市场，需调用 `vault.authorizeMarket(marketAddress)`

### 问题 4：`RouterNotTrusted` 错误
**原因**：市场未设置 trustedRouter

**解决方案**：
- `CreateAllMarketTypes.s.sol` 会自动设置 trustedRouter
- 如果手动创建市场，需调用 `market.setTrustedRouter(routerAddress)`

### 问题 5：SimulateBets 失败
**原因**：市场已锁定或结算

**解决方案**：
- 脚本会自动跳过已锁定市场
- 重新运行 `CreateAllMarketTypes.s.sol` 创建新市场

---

## 📊 验证结果

### 查询市场数量
```bash
# 从 deployments/localhost.json 读取 Factory 地址
FACTORY=$(cat deployments/localhost.json | jq -r '.contracts.factory')
cast call $FACTORY "getMarketCount()(uint256)" --rpc-url http://localhost:8545
```

### 查询 Vault 总资产
```bash
VAULT=$(cat deployments/localhost.json | jq -r '.contracts.vault')
cast call $VAULT "totalAssets()(uint256)" --rpc-url http://localhost:8545
```

### 查询用户 USDC 余额
```bash
USDC=$(cat deployments/localhost.json | jq -r '.contracts.usdc')
cast call $USDC "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
```

### 查询推荐关系
```bash
REGISTRY=$(cat deployments/localhost.json | jq -r '.contracts.referralRegistry')
# 查询账户 #1 的推荐人
cast call $REGISTRY "referrer(address)(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url http://localhost:8545
```

---

## 📚 相关文档

- **BettingRouter 使用指南**：`docs/BettingRouter_Usage.md`
- **Subgraph 文档**：`../subgraph/README.md`
- **合约设计文档**：`../docs/design/`
- **项目开发指南**：`../CLAUDE.md`

---

## 🔑 快速参考

### Anvil 默认账户（前 5 个）
```bash
# Account #0 (部署者/推荐人)
Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Account #1-9 (测试用户/被推荐人)
# 参见 SimulateBets.s.sol 和 SetupReferrals.s.sol 中的 testPrivateKeys 数组
```

### 获取合约地址
```bash
# 所有地址都在部署时动态生成，从配置文件读取
cat deployments/localhost.json | jq '.contracts'
```

---

**最后更新**：2025-12-15
**维护者**：PitchOne 开发团队
