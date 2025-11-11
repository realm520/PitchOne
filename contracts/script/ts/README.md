# TypeScript 市场创建脚本

## 📁 文件说明

- **`createMarkets.ts`** - 市场创建脚本，**支持全部 7 种市场类型**
- **`package.json`** - 依赖配置和快捷脚本
- **`tsconfig.json`** - TypeScript 配置

## ✨ 功能特性

### ✅ 支持的市场类型（7/7 完整覆盖）

| 类型 | 参数 ID | 说明 | Solidity 脚本支持 |
|------|---------|------|-------------------|
| `wdl` | WDL | 胜平负市场 | ✅ |
| `ou` | OU | 大小球单线市场 | ✅ |
| `ou_multiline` | OU_MultiLine | 大小球多线市场 | ❌ **仅 TS 支持** |
| `ah` | AH | 让球市场 | ✅ |
| `oddeven` | OddEven | 单双球市场 | ✅ |
| `score` | ScoreTemplate | 精确比分市场 | ✅ |
| `playerprops` | PlayerProps | 球员道具市场 | ✅ |

### 🎯 核心优势

1. **OU_MultiLine 独家支持** - Foundry 的 `abi.encodeWithSelector()` 无法正确编码包含动态数组的结构体，只能用 ethers.js 创建
2. **随机数据生成** - 自动生成真实的球队对阵和球员信息
3. **灵活的命令行参数** - 精确控制市场数量和类型
4. **快速迭代** - 适合本地开发和测试

---

## ⚡ 快速开始

### 1. 前置条件

确保已运行部署脚本并生成 `deployments/localhost.json`：

```bash
# 在 contracts 目录下运行
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

### 2. 安装依赖

```bash
cd script/ts
pnpm install
```

### 3. 创建市场

#### 方式 1：使用快捷脚本（推荐）

**随机数据模式（默认）**：
```bash
# 创建所有类型的市场各 3 个（共 21 个市场）
pnpm run create:all

# 创建 WDL 市场 5 个
pnpm run create:wdl

# 创建 OU_MultiLine 市场 3 个（⚠️ Solidity 脚本无法创建）
pnpm run create:ou-multiline

# 创建精确比分市场 3 个
pnpm run create:score

# 创建球员道具市场 5 个
pnpm run create:playerprops
```

**预定义数据模式（与 Solidity 脚本相同）**：
```bash
# 创建所有预定义市场（36 个固定市场）
pnpm run create:preset

# 创建预定义的 WDL 市场（5 个）
pnpm run create:preset:wdl

# 创建预定义的 OU 市场（6 个）
pnpm run create:preset:ou

# 创建预定义的 OU_MultiLine 市场（3 个）⭐
pnpm run create:preset:ou-multiline

# 创建预定义的其他市场类型
pnpm run create:preset:ah              # 5 个 AH 市场
pnpm run create:preset:oddeven         # 5 个 OddEven 市场
pnpm run create:preset:score           # 3 个 Score 市场
pnpm run create:preset:playerprops     # 9 个 PlayerProps 市场
```

#### 方式 2：使用命令行参数

**随机数据模式**：
```bash
# 创建所有类型的市场各 3 个
pnpm tsx createMarkets.ts --all --count 3

# 创建指定类型的市场
pnpm tsx createMarkets.ts --type wdl --count 5
pnpm tsx createMarkets.ts --type ou_multiline --count 3
pnpm tsx createMarkets.ts --type score --count 2
```

**预定义数据模式**：
```bash
# 创建所有预定义市场（完全替代 CreateAllMarketTypes.s.sol）
pnpm tsx createMarkets.ts --preset --all

# 创建特定类型的预定义市场
pnpm tsx createMarkets.ts --preset --type wdl --count 5
pnpm tsx createMarkets.ts --preset --type ou --count 6
pnpm tsx createMarkets.ts --preset --type playerprops --count 9
```

---

## 📋 命令行参数详解

### 参数列表

| 参数 | 说明 | 示例 |
|------|------|------|
| `--all` | 创建所有 7 种类型的市场 | `--all --count 3` |
| `--type <类型>` | 指定市场类型 | `--type wdl` |
| `--count <数量>` | 每种类型的数量（默认 1） | `--count 5` |
| `--preset` | 使用预定义数据（与 Solidity 脚本相同） | `--preset --all` |

### 市场类型参数值

- `wdl` - 胜平负
- `ou` - 大小球单线
- `ou_multiline` - 大小球多线 ⭐
- `ah` - 让球
- `oddeven` - 单双号
- `score` - 精确比分 ⭐
- `playerprops` - 球员道具

---

## 🔧 环境配置

### 环境变量

```bash
# RPC URL（默认本地 Anvil）
export RPC_URL=http://127.0.0.1:8545

# 部署账户私钥（默认 Anvil 账户 #0）
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 部署配置文件

脚本需要 `../../deployments/localhost.json` 文件，包含以下合约地址：

```json
{
  "contracts": {
    "factory": "0x...",
    "vault": "0x...",
    "usdc": "0x...",
    "cpmm": "0x...",
    "feeRouter": "0x..."
  },
  "templates": {
    "wdl": "0x...",
    "ou": "0x...",
    "ouMultiLine": "0x...",
    "ah": "0x...",
    "oddEven": "0x...",
    "score": "0x...",
    "playerProps": "0x..."
  }
}
```

---

## 🎮 使用场景

### 场景 1：完全替代 Solidity 脚本（预定义数据）

```bash
# 创建与 CreateAllMarketTypes.s.sol 相同的 36 个市场（含 OU_MultiLine）
pnpm run create:preset
# 等价于
pnpm tsx createMarkets.ts --preset --all
```

**优势**：
- ✅ 包含 Solidity 无法创建的 OU_MultiLine 市场
- ✅ 可复现的固定测试场景
- ✅ 36 个市场 vs Solidity 的 33 个（多 3 个 OU_MultiLine）

### 场景 2：快速开发迭代（随机数据）

```bash
# 创建 5 个随机 WDL 市场用于测试胜平负功能
pnpm tsx createMarkets.ts --type wdl --count 5

# 创建所有类型各 3 个，用于 Subgraph 集成测试
pnpm tsx createMarkets.ts --all --count 3
```

### 场景 3：创建 Solidity 无法创建的市场

```bash
# OU_MultiLine 市场（仅 TS 支持）
pnpm run create:ou-multiline
# 或使用预定义数据
pnpm run create:preset:ou-multiline
```

---

## 🔄 与 Solidity 脚本对比

### createMarkets.ts vs CreateAllMarketTypes.s.sol

| 特性 | createMarkets.ts | CreateAllMarketTypes.s.sol |
|------|------------------|----------------------------|
| **预定义市场数量** | 36 个（--preset 模式） | 33 个 |
| **OU_MultiLine 支持** | ✅ 完全支持 | ❌ 已注释（编码问题） |
| **数据模式** | 双模式（预定义/随机） | 仅预定义 |
| **命令行灵活性** | ✅ 参数化控制 | ❌ 需修改代码 |
| **环境依赖** | Node.js + pnpm | Foundry |
| **CI/CD 集成** | 需 Node.js | 更简单 |
| **可复现性** | ✅（预定义模式） | ✅ |

### 替代策略

**推荐方案 A：完全使用 TypeScript（推荐）**
```bash
# 预定义测试场景（替代 Solidity 脚本）
pnpm run create:preset

# 随机开发数据
pnpm run create:all
```

**优势**：
- 单一技术栈
- 支持全部 7 种市场（包括 OU_MultiLine）
- 双模式灵活切换

**方案 B：保持共存**
- Solidity 脚本：CI/CD 和简单集成测试（33 个市场）
- TypeScript 脚本：OU_MultiLine + 灵活开发 + 完整测试（36 个市场）

---

## 🚨 重要说明

### OU_MultiLine 市场创建

**⚠️ 为什么必须用 TypeScript 创建？**

由于 Foundry 的 `abi.encodeWithSelector()` 在处理包含动态数组的结构体时存在编码问题，
**OU_MultiLine 市场无法通过 Solidity 脚本创建**。

**OU_MultiLine 的 initialize 函数签名**：
```solidity
struct InitializeParams {
    string matchId;
    string homeTeam;
    string awayTeam;
    uint256 kickoffTime;
    uint256[] lines;        // ⚠️ 动态数组导致编码问题
    address settlementToken;
    // ...其他参数
}

function initialize(InitializeParams memory params) public initializer
```

**解决方案**：
- ✅ 使用本 TS 脚本创建（ethers.js 正确处理结构体编码）
- ❌ Solidity 脚本已注释掉相关代码（见 `CreateAllMarketTypes.s.sol:97`）

相关 Issue: [Foundry struct encoding](https://github.com/foundry-rs/foundry/issues/...)

---

## 🐛 故障排查

### 问题 1：`Deployment config not found`

**原因**：未运行部署脚本或配置文件路径错误

**解决**：
```bash
# 在 contracts 目录下运行部署脚本
cd /home/harry/code/PitchOne/contracts
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

### 问题 2：`Nonce too low`

**原因**：Anvil 链状态与脚本 nonce 不同步

**解决**：
```bash
# 重启 Anvil 链
pkill anvil
anvil &

# 重新部署
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

### 问题 3：`Template not found`

**原因**：Deploy.s.sol 未部署对应的模板

**解决**：
```bash
# 检查部署配置
cat deployments/localhost.json | jq '.templates'

# 确保包含 ouMultiLine 和 score 模板
```

---

## 📚 代码结构

### MarketCreator 类

- **`createWdlMarket()`**: 创建胜平负市场
- **`createOuMarket()`**: 创建大小球单线市场
- **`createOuMultiLineMarket()`**: 创建大小球多线市场 ⭐
- **`createAhMarket()`**: 创建让球市场
- **`createOddEvenMarket()`**: 创建单双号市场
- **`createScoreMarket()`**: 创建精确比分市场 ⭐
- **`createPlayerPropsMarket()`**: 创建球员道具市场

### 辅助函数

- **`loadDeploymentConfig()`**: 加载部署配置
- **`randomTeamPair()`**: 随机生成球队对阵
- **`randomItem()`**: 从数组中随机选择
- **`generateMatchId()`**: 生成唯一的赛事 ID
- **`getFutureTimestamp()`**: 生成未来时间戳

---

## 🔗 相关文档

- **Solidity 部署脚本**: `../Deploy.s.sol`
- **Solidity 市场创建脚本**: `../CreateAllMarketTypes.s.sol`
- **市场模板文档**: `../../docs/MARKET_TYPES_OVERVIEW.md`
- **OU_MultiLine 使用指南**: `../../docs/OU_MultiLine_Usage.md`

---

## 📝 更新日志

### v2.1.0 (2025-11-11)

- ✅ 添加预定义数据模式（--preset 参数）
- ✅ 完全替代 CreateAllMarketTypes.s.sol（36 个预定义市场）
- ✅ 支持双模式切换：预定义 vs 随机
- ✅ 添加预定义快捷脚本（create:preset:*）
- ✅ 更新文档说明预定义模式

### v2.0.0 (2025-11-11)

- ✅ 添加 ScoreTemplate 市场支持
- ✅ 添加 OU_MultiLine 市场支持（独家）
- ✅ 支持全部 7 种市场类型
- ✅ 添加快捷脚本（package.json）
- ✅ 更新文档和示例
- ❌ 移除 deploy.ts（使用 Deploy.s.sol 替代）

### v1.0.0 (2025-11-06)

- 初始版本
- 支持 5 种市场类型（WDL, OU, AH, OddEven, PlayerProps）

---

## ⚠️ 注意事项

1. **仅用于本地开发和测试** - 不要在主网使用
2. **使用 Anvil 默认账户私钥** - 切勿在生产环境使用
3. **WDL 市场需要 Vault 授权** - 脚本会自动调用 `vault.authorizeMarket()`
4. **时间戳都是未来时间** - 1-7 天内随机
5. **OU_MultiLine 每次创建都会部署新的 LinkedLinesController**

---

## 💡 贡献

如需添加新市场类型：

1. 在 `MarketCreator` 类中添加 `create<Type>Market()` 方法
2. 在 `createMarket()` switch 语句中添加对应 case
3. 更新 `MarketType` 类型定义
4. 更新 main 函数中的 `types` 数组
5. 添加对应的 package.json 快捷脚本
