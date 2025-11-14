# PitchOne 本地开发环境部署 SOP

本文档提供完整的本地测试环境部署流程，从合约部署到 Subgraph 索引的端到端操作指南。

## 📋 前置条件

- Anvil（Foundry 本地测试链）
- Graph Node（Docker）
- PostgreSQL 14
- IPFS Kubo
- Node.js 18+

## 🚀 完整部署流程

### 步骤 1: 启动 Anvil 本地测试链

```bash
# 在独立终端窗口运行（保持运行状态）
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0
```

**验证**：
```bash
cast block-number --rpc-url http://localhost:8545
# 应返回：0 或更高的区块号
```

---

### 步骤 2: 部署核心合约

```bash
cd /home/harry/code/PitchOne/contracts

# 部署所有核心合约（USDC、Vault、FeeRouter、Factory、7种模板）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**输出文件**：
- `deployments/localhost.json` - 自动生成的合约地址配置文件

**关键合约地址**（示例）：
```json
{
  "contracts": {
    "usdc": "0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00",
    "vault": "0x36C02dA8a0983159322a80FFE9F24b1acfF8B570",
    "feeRouter": "0x1291Be112d480055DaFd8a610b7d1e203891C274",
    "factory": "0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154"
  }
}
```

**验证**：
```bash
# 检查 Factory 是否部署成功
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "getMarketCount()" --rpc-url http://localhost:8545
# 应返回：0x0000000000000000000000000000000000000000000000000000000000000000
```

---

### 步骤 3: 创建测试市场

```bash
cd /home/harry/code/PitchOne/contracts

# 创建 15 个市场（WDL×3 + OU×3 + AH×3 + OddEven×3 + Score×3）
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets_NoMultiLine.s.sol:CreateMarkets_NoMultiLine \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**输出示例**：
```
========================================
  Creating 15 Markets (5 types x 3 each)
========================================

1. Creating WDL Markets...
   Created 3 WDL markets

2. Creating OU Markets...
   Created 3 OU markets

3. Creating AH Markets...
   Created 3 AH markets

4. Creating OddEven Markets...
   Created 3 OddEven markets

5. Creating Score Markets...
   Created 3 Score markets

6. Authorizing all markets...
   All markets authorized

========================================
  Success! Created 15 markets
========================================
```

**验证**：
```bash
# 检查市场数量
MARKET_COUNT=$(cast --to-dec $(cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "getMarketCount()" --rpc-url http://localhost:8545))
echo "市场数量: $MARKET_COUNT"
# 应返回：市场数量: 15

# 获取第一个市场地址
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "getMarket(uint256)" 0 --rpc-url http://localhost:8545
```

---

### 步骤 4: 模拟投注数据

```bash
cd /home/harry/code/PitchOne/contracts

# 5个用户，每个市场2笔注，金额10-100 USDC，均匀分布
NUM_BETTORS=5 \
  MIN_BET_AMOUNT=10 \
  MAX_BET_AMOUNT=100 \
  BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

**参数说明**：
- `NUM_BETTORS`: 下注用户数（1-10，对应 Anvil 默认账户）
- `MIN_BET_AMOUNT`: 最小下注金额（USDC）
- `MAX_BET_AMOUNT`: 最大下注金额（USDC）
- `BETS_PER_USER`: 每个用户在每个市场的下注次数
- `OUTCOME_DISTRIBUTION`: 下注分布策略
  - `balanced`: 均匀分布到所有 outcome
  - `skewed`: 倾斜分布（热门选项占比高）
  - `random`: 完全随机

**输出示例**：
```
========================================
  Bet Simulation Complete
========================================
✅ Total Bets: 83
✅ Total Volume: 2,587.02 USDC
✅ Success Rate: 100%
✅ Markets Covered: 15/15
```

**验证**：
```bash
# 检查某个市场的投注情况
MARKET_0=$(cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "getMarket(uint256)" 0 --rpc-url http://localhost:8545 | sed 's/^0x000000000000000000000000/0x/')
echo "市场 0: $MARKET_0"

# 查询市场的 reserveA 和 reserveB（CPMM 储备量）
cast call $MARKET_0 "reserveA()" --rpc-url http://localhost:8545
cast call $MARKET_0 "reserveB()" --rpc-url http://localhost:8545
```

---

### 步骤 5: 更新 Subgraph 配置

**重要**：每次重新部署合约后，必须更新 Subgraph 中的合约地址！

```bash
cd /home/harry/code/PitchOne/subgraph
```

**方法 1：手动编辑**（推荐用于生产环境）
```bash
# 编辑 subgraph.yaml
nano subgraph.yaml

# 更新以下地址（从 deployments/localhost.json 获取）：
# - MarketFactory 的 source.address
# - FeeRouter 的 source.address
```

**方法 2：自动化脚本**（快速开发）
```bash
# 从 deployments/localhost.json 自动提取地址并更新
FACTORY_ADDRESS=$(jq -r '.contracts.factory' ../contracts/deployments/localhost.json)
FEE_ROUTER_ADDRESS=$(jq -r '.contracts.feeRouter' ../contracts/deployments/localhost.json)

echo "Factory: $FACTORY_ADDRESS"
echo "FeeRouter: $FEE_ROUTER_ADDRESS"

# 使用 sed 更新 subgraph.yaml（需要谨慎使用）
```

**验证**：
```bash
# 检查 subgraph.yaml 中的地址是否正确
grep "address:" subgraph.yaml
```

---

### 步骤 6: 部署 Subgraph

#### 方案 A：完整重建（推荐）

```bash
cd /home/harry/code/PitchOne/subgraph

# 使用 reset-subgraph.sh 自动化脚本
./reset-subgraph.sh
```

**脚本执行流程**：
1. 停止并清理现有的 Graph Node 容器
2. 删除所有 PostgreSQL 数据（完全重置）
3. 启动 Graph Node、PostgreSQL、IPFS
4. 生成代码（`graph codegen`）
5. 构建 Subgraph（`graph build`）
6. 部署到本地节点

**等待时间**：约 30-60 秒

#### 方案 B：手动部署（更细粒度控制）

```bash
cd /home/harry/code/PitchOne/subgraph

# 1. 启动 Graph Node（如果尚未运行）
docker-compose up -d

# 2. 等待服务启动（约 10 秒）
sleep 10

# 3. 生成 TypeScript 代码
graph codegen

# 4. 构建 Subgraph
graph build

# 5. 部署到本地节点
graph deploy \
  --node http://localhost:8020/ \
  --ipfs http://localhost:5001 \
  pitchone-local
```

**验证**：
```bash
# 检查部署状态
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ _meta { block { number } } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local

# 应返回当前索引的区块号
```

---

### 步骤 7: 等待 Subgraph 同步

```bash
# 持续监控索引进度
watch -n 2 'curl -s -X POST \
  -H "Content-Type: application/json" \
  --data "{\"query\": \"{ _meta { block { number } } }\"}" \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .'
```

**预期同步时间**：
- 15 个市场 + 83 笔投注 ≈ 5-15 秒
- 取决于区块数量和事件复杂度

**同步完成标志**：
- `_meta.block.number` 达到当前区块高度
- 停止快速增长

---

### 步骤 8: 验证数据完整性

#### 8.1 验证市场数据

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 20) { id state homeTeam awayTeam totalVolume uniqueBettors } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .
```

**预期结果**：
- 返回 15 个市场
- 每个市场的 `totalVolume` > 0
- `uniqueBettors` 符合预期（通常 1-5）

#### 8.2 验证用户数据

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ users(first: 10) { id totalBetAmount totalBets marketsParticipated } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .
```

**预期结果**：
- 返回 5 个用户
- `totalBets` 总和 ≈ 83
- `totalBetAmount` 总和 ≈ 2,587 USDC

#### 8.3 验证订单数据

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ orders(first: 10, orderBy: timestamp, orderDirection: desc) { id outcome amount timestamp user { id } market { homeTeam awayTeam } } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .
```

**预期结果**：
- 返回最新的 10 笔订单
- 包含用户地址、市场信息、下注金额等

#### 8.4 验证全局统计

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ globalStats(id: \"global\") { totalMarkets totalUsers totalVolume totalFees activeMarkets } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .
```

**预期结果**：
```json
{
  "data": {
    "globalStats": {
      "totalMarkets": 15,
      "totalUsers": 5,
      "totalVolume": "2587.023228",
      "totalFees": "51.740453",
      "activeMarkets": 15
    }
  }
}
```

---

## 🔧 常见问题排查

### 问题 1：Subgraph 无法索引市场

**症状**：
```bash
curl ... | jq .
# 返回：{ "data": { "markets": [] } }
```

**原因**：
- subgraph.yaml 中的 Factory 地址不正确
- 市场未通过 Factory 创建

**解决**：
```bash
# 1. 检查 subgraph.yaml 中的地址
grep "address:" /home/harry/code/PitchOne/subgraph/subgraph.yaml

# 2. 检查 deployments/localhost.json 中的实际地址
cat /home/harry/code/PitchOne/contracts/deployments/localhost.json | jq '.contracts.factory'

# 3. 如果不一致，更新 subgraph.yaml 并重新部署
cd /home/harry/code/PitchOne/subgraph
./reset-subgraph.sh
```

---

### 问题 2：投注失败（Insufficient liquidity）

**症状**：
```
SimulateBets 脚本报错：Insufficient liquidity
```

**原因**：
- Vault 中流动性不足
- Deploy.s.sol 默认初始化 1M USDC

**解决**：
```bash
# 检查 Vault 总资产
VAULT_ADDRESS=$(jq -r '.contracts.vault' /home/harry/code/PitchOne/contracts/deployments/localhost.json)
cast call $VAULT_ADDRESS "totalAssets()" --rpc-url http://localhost:8545

# 如果不足，可以手动添加流动性（需要合约支持）
```

---

### 问题 3：Graph Node 无法启动

**症状**：
```bash
docker-compose up -d
# 报错：Error starting userland proxy: listen tcp4 0.0.0.0:8020: bind: address already in use
```

**原因**：
- 端口被占用（8020/8010/8030/5001）

**解决**：
```bash
# 检查端口占用
lsof -i :8020
lsof -i :8010
lsof -i :5001

# 停止占用进程或清理 Docker
docker-compose down -v
pkill -f graph-node

# 重新启动
docker-compose up -d
```

---

### 问题 4：Anvil 状态丢失

**症状**：
- 重启 Anvil 后，`getMarketCount()` 返回 0

**原因**：
- Anvil 默认不持久化状态，每次重启都是全新链

**解决**：
```bash
# 方案 1：使用 --state 参数持久化状态
anvil --host 0.0.0.0 --state /tmp/anvil-state.json

# 方案 2：完整重新部署（推荐用于开发）
# 按照本 SOP 重新执行步骤 2-6
```

---

## 📊 性能基准

**硬件配置**：
- CPU: 8 Core
- RAM: 16GB
- SSD: 256GB

**部署时间**（完整流程）：
- 步骤 2（合约部署）：~10 秒
- 步骤 3（市场创建）：~15 秒
- 步骤 4（模拟投注）：~20 秒
- 步骤 6（Subgraph 部署）：~30 秒
- 步骤 7（数据同步）：~10 秒
- **总计**：~85 秒

**数据规模**：
- 15 个市场
- 5 个用户
- 83 笔订单
- 总交易量：2,587 USDC

---

## 🎯 快速命令速查

### 一键式完整部署

```bash
#!/bin/bash
# 文件路径: /home/harry/code/PitchOne/scripts/quick-deploy.sh

set -e

cd /home/harry/code/PitchOne/contracts

echo "========================================="
echo "  PitchOne 本地环境一键部署"
echo "========================================="

# 1. 部署合约
echo "📦 [1/4] 部署核心合约..."
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast > /dev/null 2>&1

# 2. 创建市场
echo "🏟️  [2/4] 创建测试市场..."
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateMarkets_NoMultiLine.s.sol:CreateMarkets_NoMultiLine \
  --rpc-url http://localhost:8545 \
  --broadcast > /dev/null 2>&1

# 3. 模拟投注
echo "💰 [3/4] 模拟投注数据..."
NUM_BETTORS=5 MIN_BET_AMOUNT=10 MAX_BET_AMOUNT=100 BETS_PER_USER=2 \
  OUTCOME_DISTRIBUTION=balanced \
  forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast > /dev/null 2>&1

# 4. 部署 Subgraph
echo "📊 [4/4] 部署 Subgraph..."
cd ../subgraph
./reset-subgraph.sh > /dev/null 2>&1

echo ""
echo "========================================="
echo "  ✅ 部署完成！"
echo "========================================="
echo "GraphQL Playground:"
echo "  http://localhost:8010/subgraphs/name/pitchone-local/graphql"
echo ""
echo "验证命令："
echo "  curl -X POST -H 'Content-Type: application/json' \\"
echo "    --data '{\"query\": \"{ globalStats(id: \\\"global\\\") { totalMarkets totalUsers totalVolume } }\"}' \\"
echo "    http://localhost:8010/subgraphs/name/pitchone-local | jq ."
```

**使用方法**：
```bash
chmod +x /home/harry/code/PitchOne/scripts/quick-deploy.sh
/home/harry/code/PitchOne/scripts/quick-deploy.sh
```

---

## 📚 相关文档

- [Subgraph Schema 定义](../schema.graphql)
- [事件字典](../../docs/模块接口事件参数/EVENT_DICTIONARY.md)
- [合约部署文档](../../contracts/README.md)
- [前端集成指南](../../frontend/README.md)

---

## 🔄 更新记录

- **2025-11-14**：初始版本，基于实际部署验证
- 合约地址：Factory `0x5f3f...9154`，FeeRouter `0x1291...1274`
- Subgraph 版本：v0.1.4
- 测试数据：15 市场，5 用户，83 订单，2,587 USDC 交易量
