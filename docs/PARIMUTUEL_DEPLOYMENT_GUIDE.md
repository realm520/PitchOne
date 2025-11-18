# Parimutuel 市场完整部署指南

## 📋 概述

本指南说明如何在现有 Anvil 链上完整部署 PitchOne Parimutuel（彩票池）类型市场，包括：
- 部署所有核心合约
- 创建 7 个 Parimutuel 市场
- 模拟多用户投注
- 重建 Subgraph 索引数据

## 🎯 Parimutuel 市场特点

**Parimutuel（奖池式）定价**是一种与传统 AMM 不同的机制：

| 特性 | Parimutuel | 传统 AMM (SimpleCPMM) |
|------|-----------|---------------------|
| **虚拟储备** | 0（零初始化） | 100,000 USDC |
| **份额计算** | 1:1 兑换 | AMM 公式 (x*y=k) |
| **赔率变化** | 显著（反映真实市场） | 平缓（约 0.12%/笔） |
| **初始流动性** | 无需借款 | 需从 Vault 借出 10% |
| **适用场景** | 传统博彩、彩票池体验 | 稳定深度流动性市场 |
| **赔付机制** | 输家资金按比例分给赢家 | AMM 公式计算 |

**核心区别**：
- **Parimutuel**：所有投注进入一个池子，赛后按比例分配，类似赛马彩票
- **AMM**：使用虚拟储备提供即时流动性和稳定赔率

## 🚀 快速开始

### 前提条件

1. **Anvil 必须正在运行**：
```bash
# 在单独的终端运行
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0
```

2. **已安装依赖**：
- Foundry (forge, cast)
- Graph CLI
- Docker / Docker Compose
- jq (JSON 解析工具)

### 一键部署

```bash
cd /home/harry/code/PitchOne

# 确保脚本可执行
chmod +x deploy-parimutuel-full.sh

# 运行完整部署流程
./deploy-parimutuel-full.sh
```

## 📊 部署流程详解

### 步骤 0: 验证前提条件

脚本会自动检查：
- ✅ Anvil 是否运行（检查区块高度）
- ✅ Foundry 工具是否安装
- ✅ Graph CLI 是否安装
- ✅ Docker 是否可用

### 步骤 1: 部署所有合约

执行 `Deploy.s.sol`，部署：
- 核心合约（USDC, Vault, Factory, FeeRouter 等）
- 3 种定价引擎（SimpleCPMM, LMSR, **Parimutuel**）
- 7 种市场模板（WDL, OU, AH, OddEven, Score, OU_MultiLine, PlayerProps）

**输出文件**：
```
contracts/deployments/localhost.json
```

**示例内容**：
```json
{
  "contracts": {
    "factory": "0x5FC8...",
    "usdc": "0x5FbD...",
    "vault": "0xe7f1...",
    "parimutuel": "0xCf7E..."  ← Parimutuel 引擎地址
  },
  "templates": {
    "oddEven": "0xf1d7..."  ← OddEven 模板 ID
  }
}
```

### 步骤 2: 创建 Parimutuel 市场

执行 `CreateParimutuelMarketsAuto.s.sol`，自动：
1. 从 `localhost.json` 读取合约地址
2. 创建 7 个 Parimutuel OddEven 市场
3. 每个市场配置：
   - `virtualReservePerSide = 0`（零虚拟储备）
   - `pricingEngine = Parimutuel`（使用 Parimutuel 引擎）
   - `lockTime = 7 days`（锁盘时间）

**创建的市场**：
```
1. EPL_2024_PM_OE_1: Manchester United vs Manchester City
2. EPL_2024_PM_OE_2: Arsenal vs Chelsea
3. EPL_2024_PM_OE_3: Liverpool vs Tottenham
4. EPL_2024_PM_OE_4: Chelsea vs Brighton
5. EPL_2024_PM_OE_5: Tottenham vs Aston Villa
6. EPL_2024_PM_OE_6: Manchester City vs West Ham
7. EPL_2024_PM_OE_7: Newcastle vs Everton
```

### 步骤 3: 模拟投注

执行 `SimulateBets.s.sol`，模拟：
- **5 个测试用户**
- 每个用户对**每个市场**下 **2 笔注**
- 随机金额（10-100 USDC）
- 随机 outcome（0 或 1）
- 投注分布策略：**balanced**（均匀分布）

**预期结果**：
- 约 **70 笔投注**（7 市场 × 5 用户 × 2 笔）
- 总投注额约 **3,500 USDC**

### 步骤 4: 重建 Subgraph

执行 `reset-subgraph.sh`，自动：
1. 停止并清理旧的 Graph Node 数据
2. 重启 Graph Node Docker 容器
3. 生成 Subgraph 代码（`graph codegen`）
4. 构建 Subgraph（`graph build`）
5. 部署到本地 Graph Node

**输出**：
```
GraphQL Endpoint: http://localhost:8010/subgraphs/name/pitchone-local
GraphiQL UI: http://localhost:8010/subgraphs/name/pitchone-local/graphql
```

### 步骤 5: 验证数据流

脚本会自动查询 Subgraph 并显示前 5 个市场的数据：

```json
{
  "data": {
    "markets": [
      {
        "id": "0x...",
        "state": "Open",
        "marketType": "OddEven",
        "pricingEngine": "0xCf7E...",
        "totalVolume": "1250000000"
      }
    ]
  }
}
```

## 🔍 验证 Parimutuel 特性

### 1. 检查虚拟储备

Parimutuel 市场的虚拟储备应该等于实际投注额（不是固定的 100,000）：

```bash
# 获取第一个市场地址
FACTORY=$(cat contracts/deployments/localhost.json | jq -r '.contracts.factory')
MARKET=$(cast call $FACTORY "getMarket(uint256)" 0 --rpc-url http://localhost:8545 | sed 's/^0x000000000000000000000000/0x/')

# 查询虚拟储备
echo "Outcome 0 储备量："
cast call $MARKET "virtualReserves(uint256)" 0 --rpc-url http://localhost:8545

echo "Outcome 1 储备量："
cast call $MARKET "virtualReserves(uint256)" 1 --rpc-url http://localhost:8545
```

**预期结果**（Parimutuel 市场）：
```
Outcome 0 储备量: 600000000  (600 USDC) ← 实际投注额
Outcome 1 储备量: 500000000  (500 USDC) ← 实际投注额
```

**对比 SimpleCPMM 市场**：
```
Outcome 0 储备量: 99800000000  (约 100,000 USDC) ← 虚拟储备
Outcome 1 储备量: 100200000000  (约 100,000 USDC) ← 虚拟储备
```

### 2. 检查定价引擎

```bash
# 查询市场使用的定价引擎
PRICING_ENGINE=$(cast call $MARKET "pricingEngine()" --rpc-url http://localhost:8545)
echo "定价引擎地址: $PRICING_ENGINE"

# 对比 localhost.json 中的 Parimutuel 地址
PARIMUTUEL=$(cat contracts/deployments/localhost.json | jq -r '.contracts.parimutuel')
echo "Parimutuel 地址: $PARIMUTUEL"

# 应该相等
if [ "$PRICING_ENGINE" = "$PARIMUTUEL" ]; then
  echo "✓ 确认使用 Parimutuel 引擎"
fi
```

### 3. 测试赔率变化

Parimutuel 市场的赔率应该随投注显著变化：

```bash
# 第 1 笔投注：23 USDC on Outcome 1
# 赔率: ∞ (无对手盘)

# 第 2 笔投注：123 USDC on Outcome 0
# 赔率: Outcome 0 = 1.19x, Outcome 1 = 6.0x
# 池子比例: 84% vs 16%

# 第 3 笔投注：1 USDC on Outcome 1
# 赔率: Outcome 1 从 6.0x → 5.8x
```

**对比 SimpleCPMM**（虚拟储备 100,000）：
```bash
# 第 1 笔投注：23 USDC
# 价格变化: +0.01%

# 第 2 笔投注：123 USDC
# 价格变化: +0.12%
```

## 📝 使用说明

### 手动执行各步骤

如果你想分步执行而不是一键运行：

```bash
cd /home/harry/code/PitchOne/contracts

# 步骤 1: 部署合约
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 步骤 2: 创建 Parimutuel 市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateParimutuelMarketsAuto.s.sol:CreateParimutuelMarketsAuto \
  --rpc-url http://localhost:8545 \
  --broadcast

# 步骤 3: 模拟投注
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 步骤 4: 重建 Subgraph
cd ../subgraph
./reset-subgraph.sh
```

### 环境变量配置

| 变量 | 默认值 | 说明 |
|------|-------|------|
| `RPC_URL` | `http://localhost:8545` | Anvil RPC URL |
| `PRIVATE_KEY` | `0xac0974...` | 部署账户私钥（Anvil 默认账户 0） |
| `NUM_BETTORS` | `5` | 模拟下注用户数（最多 10） |
| `MIN_BET_AMOUNT` | `10` | 最小下注金额（USDC） |
| `MAX_BET_AMOUNT` | `100` | 最大下注金额（USDC） |
| `BETS_PER_USER` | `2` | 每个用户对每个市场的下注次数 |
| `OUTCOME_DISTRIBUTION` | `balanced` | 投注分布策略（balanced/skewed/random） |

### 常见问题排查

#### 问题 1: Anvil 未运行

**错误信息**：
```
✗ Anvil 未运行
请先启动 Anvil
```

**解决方法**：
```bash
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0
```

#### 问题 2: localhost.json 未生成

**错误信息**：
```
✗ localhost.json 未生成
```

**解决方法**：
```bash
# 手动运行 Deploy.s.sol
cd contracts
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast \
  -vvv
```

#### 问题 3: Subgraph 索引失败

**错误信息**：
```
Subgraph 重建失败
```

**解决方法**：
```bash
# 检查 Graph Node 日志
docker logs -f graph-node

# 重启 Graph Node
cd subgraph
docker-compose down -v
docker-compose up -d
sleep 15

# 重新部署
./reset-subgraph.sh
```

## 🎓 相关文档

- **自动化数据流文档**：`docs/design/AUTOMATED_DATA_FLOW.md`
- **Parimutuel 实现文档**：`contracts/docs/PARIMUTUEL_IMPLEMENTATION.md`
- **Parimutuel 引擎源码**：`contracts/src/pricing/ParimutuelPricing.sol`
- **OddEven V2 模板源码**：`contracts/src/templates/OddEven_Template_V2.sol`
- **部署脚本源码**：
  - `contracts/script/Deploy.s.sol`
  - `contracts/script/CreateParimutuelMarketsAuto.s.sol`
  - `contracts/script/SimulateBets.s.sol`

## 📊 预期输出

完整运行后，你应该看到：

```
========================================
  部署完成！
========================================

✓ 合约部署完成
✓ Parimutuel 市场创建完成 (7 个市场)
✓ 投注模拟完成
✓ Subgraph 索引完成

关键信息：
  - 合约配置文件: contracts/deployments/localhost.json
  - Factory 地址: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
  - 市场总数: 7

访问 GraphQL Playground：
  http://localhost:8010/subgraphs/name/pitchone-local/graphql

测试查询：
  { markets { id state marketType pricingEngine } }

说明：Parimutuel 市场的特点
  - 零虚拟储备（virtualReservePerSide = 0）
  - 赔率由实际投注分布决定（类似传统彩票池）
  - 无需初始流动性借款
  - 适合传统博彩体验
```

---

**最后更新**: 2025-11-15
**作者**: PitchOne Team
**状态**: ✅ 完全自动化实现
