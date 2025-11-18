# 自动化部署故障排查指南

本文档提供完整的故障排查流程，帮助快速定位和解决部署过程中的问题。

## 🚨 常见问题速查表

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| 脚本在步骤 2.5 停止 | 调用了错误的合约函数 | 检查函数名是否正确（`status()` vs `state()`） |
| Subgraph 显示旧市场 | 未重新部署 Subgraph | 运行 `cd subgraph && ./reset-subgraph.sh` |
| 前端数据未更新 | Subgraph 未索引新数据 | 检查 Factory 地址是否正确配置 |
| 市场创建失败 | localhost.json 不存在或格式错误 | 重新运行 `Deploy.s.sol` |
| Graph Node 未启动 | Docker 服务问题 | 运行 `docker compose up -d` |

---

## 🔍 诊断流程

### 步骤 1: 验证 Anvil 是否运行

```bash
cast block-number --rpc-url http://localhost:8545
```

**预期输出**: 当前区块高度（如 `105`）

**如果失败**:
```bash
# 启动 Anvil
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0 &
```

---

### 步骤 2: 检查合约部署状态

```bash
# 检查 localhost.json 是否存在
cat contracts/deployments/localhost.json | jq '.contracts.factory'

# 验证 Factory 合约是否部署到链上
FACTORY=$(jq -r '.contracts.factory' contracts/deployments/localhost.json)
cast code $FACTORY --rpc-url http://localhost:8545 | wc -c
```

**预期输出**:
- `localhost.json` 包含 Factory 地址（如 `0x1780bC...`）
- `cast code` 返回 > 100 字节的合约代码

**如果失败**:
```bash
# 重新部署合约
cd contracts
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

### 步骤 3: 验证市场是否创建

```bash
FACTORY=$(jq -r '.contracts.factory' contracts/deployments/localhost.json)

# 查询市场数量
MARKET_COUNT=$(cast call $FACTORY "getMarketCount()" --rpc-url http://localhost:8545)
echo "Market count: $(cast --to-dec $MARKET_COUNT)"

# 查询第一个市场地址
MARKET_0=$(cast call $FACTORY "getMarket(uint256)" 0 --rpc-url http://localhost:8545 | sed 's/^0x000000000000000000000000/0x/')
echo "Market 0: $MARKET_0"

# 验证市场合约存在
cast code $MARKET_0 --rpc-url http://localhost:8545 | wc -c
```

**预期输出**:
- 市场数量 > 0
- 市场地址有效（42 字符）
- 市场合约代码 > 100 字节

**如果失败**:
```bash
# 重新创建市场
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateParimutuelMarketsAuto.s.sol:CreateParimutuelMarketsAuto \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

### 步骤 4: 检查 Subgraph 配置

```bash
# 检查 subgraph.yaml 中的 Factory 地址
cd subgraph
SUBGRAPH_FACTORY=$(grep -A2 "name: MarketFactory" subgraph.yaml | grep "address:" | sed 's/.*address: "\(.*\)".*/\1/')
ACTUAL_FACTORY=$(jq -r '.contracts.factory' ../contracts/deployments/localhost.json)

echo "Subgraph Factory: $SUBGRAPH_FACTORY"
echo "Actual Factory:   $ACTUAL_FACTORY"

if [ "$SUBGRAPH_FACTORY" != "$ACTUAL_FACTORY" ]; then
  echo "❌ 地址不匹配！需要更新 Subgraph 配置"
else
  echo "✓ 地址匹配"
fi
```

**如果地址不匹配**:
```bash
# 更新 Subgraph 配置并重新部署
cd subgraph
sed -i "0,/address: \"0x[a-fA-F0-9]\{40\}\"/s//address: \"$ACTUAL_FACTORY\"/" subgraph.yaml
./reset-subgraph.sh
```

---

### 步骤 5: 验证 Graph Node 状态

```bash
# 检查 Docker 服务状态
cd subgraph
docker compose ps

# 查询 Subgraph 索引状态
curl -s -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ indexingStatusForCurrentVersion(subgraphName: \"pitchone-local\") { synced health fatalError { message } chains { latestBlock { number } } } }"}' \
  http://localhost:8030/graphql | jq '.'
```

**预期输出**:
```json
{
  "data": {
    "indexingStatusForCurrentVersion": {
      "synced": true,
      "health": "healthy",
      "fatalError": null,
      "chains": [
        {
          "latestBlock": {
            "number": "105"
          }
        }
      ]
    }
  }
}
```

**如果 Graph Node 未运行**:
```bash
cd subgraph
docker compose down -v
docker compose up -d
sleep 10
./reset-subgraph.sh
```

**如果有 fatalError**:
```bash
# 查看详细错误日志
docker compose logs graph-node --tail 100 | grep -i error
```

---

### 步骤 6: 验证数据流

```bash
# 查询 Subgraph 数据
curl -s -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 5, orderBy: createdAtBlockNumber, orderDirection: desc) { id marketType createdAtBlockNumber } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq '.data.markets'
```

**预期输出**: 返回最近创建的市场列表

**如果返回 null 或空数组**:
```bash
# 1. 检查 Subgraph 是否订阅了正确的 Factory 地址
grep "address:" subgraph/subgraph.yaml

# 2. 检查 Factory 的 MarketCreated 事件是否触发
FACTORY=$(jq -r '.contracts.factory' contracts/deployments/localhost.json)
cast logs --address $FACTORY --from-block 0 --rpc-url http://localhost:8545 | grep MarketCreated

# 3. 重新部署 Subgraph
cd subgraph
./reset-subgraph.sh
```

---

## 🐛 具体错误修复

### 错误 1: `state()` 函数不存在

**症状**: 脚本在步骤 2.5 停止，无后续输出

**原因**: `scripts/deploy-parimutuel-full.sh:493` 调用了错误的函数名

**修复**:
```bash
# 编辑脚本
vim scripts/deploy-parimutuel-full.sh

# 将第 493 行从：
MARKET_STATE=$(cast call "$MARKET_0_ADDR" "state()" ...)

# 改为：
MARKET_STATE=$(cast call "$MARKET_0_ADDR" "status()" ...)
```

**验证修复**:
```bash
# 重新运行脚本
./scripts/deploy-parimutuel-full.sh
```

---

### 错误 2: Subgraph 索引旧市场

**症状**: 前端显示旧市场地址，与链上数据不一致

**原因**: Subgraph 配置的 Factory 地址未更新

**修复**:
```bash
# 1. 获取正确的 Factory 地址
FACTORY=$(jq -r '.contracts.factory' contracts/deployments/localhost.json)
echo "Factory: $FACTORY"

# 2. 更新 subgraph.yaml
cd subgraph
sed -i "0,/address: \"0x[a-fA-F0-9]\{40\}\"/s//address: \"$FACTORY\"/" subgraph.yaml

# 3. 重新部署 Subgraph
graph codegen
graph build
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 --version-label "v$(date +%s)" pitchone-local

# 4. 等待索引完成
sleep 10

# 5. 验证数据
curl -s -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 5) { id } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq '.data.markets'
```

---

### 错误 3: Graph Node 端口冲突

**症状**: Graph Node 启动失败，端口被占用

**原因**: 端口 8000/8001 被其他进程（如 Nexor）占用

**修复**:
```bash
# 1. 检查端口占用
lsof -i :8000
lsof -i :8001

# 2. 修改 Subgraph 环境变量
cd subgraph
cat > .env << 'EOF'
GRAPH_NODE_HTTP_PORT=8010
GRAPH_NODE_WS_PORT=8011
EOF

# 3. 更新 docker-compose.yml
# 确保端口映射为 8010:8000 和 8011:8001

# 4. 重启服务
docker compose down -v
docker compose up -d

# 5. 更新前端 API 路由
# 将 localhost:8000 改为 localhost:8010
```

---

### 错误 4: 合约大小超限

**症状**: `forge script` 返回非零退出码，提示合约超过 24KB

**原因**: `ScoreTemplate_V2` 合约超过以太坊主网的 24KB 限制

**临时方案** (Anvil 测试环境允许超大合约):
```bash
# 脚本已自动处理此情况
# Deploy.s.sol 会检查 broadcast JSON 是否生成成功
# 即使退出码非零，只要合约已部署即可继续
```

**长期方案**:
```solidity
// 1. 使用 Proxy 模式（ERC-1967）
// 2. 拆分大合约为多个小合约
// 3. 移除未使用的代码
// 4. 优化数据结构
```

---

## 🛠️ 完整重置流程

如果遇到无法解决的问题，执行完整重置：

```bash
#!/bin/bash

echo "=== 完整重置开始 ==="

# 1. 停止所有服务
echo "停止 Anvil 和 Graph Node..."
pkill anvil
cd /home/harry/code/PitchOne/subgraph
docker compose down -v

# 2. 清理数据
echo "清理旧数据..."
rm -f /home/harry/code/PitchOne/contracts/deployments/localhost.json
rm -rf /home/harry/code/PitchOne/subgraph/build
rm -rf /home/harry/code/PitchOne/subgraph/generated

# 3. 重启 Anvil
echo "启动 Anvil..."
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0 > /tmp/anvil.log 2>&1 &
sleep 3

# 4. 部署合约
echo "部署合约..."
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 5. 创建市场
echo "创建市场..."
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateParimutuelMarketsAuto.s.sol:CreateParimutuelMarketsAuto \
  --rpc-url http://localhost:8545 \
  --broadcast

# 6. 模拟投注（可选）
# NUM_BETTORS=5 ... forge script script/SimulateBets.s.sol:SimulateBets ...

# 7. 重建 Subgraph
echo "重建 Subgraph..."
cd /home/harry/code/PitchOne/subgraph
docker compose up -d
sleep 10
./reset-subgraph.sh

echo "=== 完整重置完成 ==="
echo "GraphQL Playground: http://localhost:8010/subgraphs/name/pitchone-local/graphql"
```

---

## 📊 验证检查清单

在每个关键步骤后运行以下检查：

### ✅ 部署合约后

- [ ] `localhost.json` 文件已生成
- [ ] Factory 地址有效（42 字符）
- [ ] Factory 合约代码存在（`cast code` > 100 字节）
- [ ] 模板 ID 已注册（非零值）

### ✅ 创建市场后

- [ ] 市场数量 > 0
- [ ] 第一个市场地址有效
- [ ] 市场合约 `status()` 返回 0 (Open)
- [ ] 市场定价引擎地址正确

### ✅ Subgraph 部署后

- [ ] Graph Node 状态为 "healthy"
- [ ] `synced` 为 true
- [ ] `fatalError` 为 null
- [ ] `latestBlock` 与 Anvil 区块高度一致

### ✅ 数据流验证

- [ ] Subgraph 查询返回市场列表
- [ ] 市场地址与链上一致
- [ ] 前端能正确显示市场数据

---

## 🔗 相关资源

- **主文档**: `docs/design/AUTOMATED_DATA_FLOW.md`
- **脚本源码**: `scripts/deploy-parimutuel-full.sh`
- **Subgraph 重置脚本**: `subgraph/reset-subgraph.sh`
- **合约部署脚本**: `contracts/script/Deploy.s.sol`

---

**最后更新**: 2025-11-17
**维护人**: PitchOne Team
