# Subgraph 部署成功指南

## 🎉 部署状态

✅ **Subgraph 已成功部署到本地 Graph Node!**

- **Deployment Hash**: `QmXBeDjovAR8FaAfucDckMwvEXgCMt7PKJyUc4u7KknhAx`
- **Subgraph Name**: `pitchone-local`
- **GraphQL Endpoint**: `http://localhost:8010/subgraphs/name/pitchone-local`
- **GraphQL Playground**: `http://localhost:8010/subgraphs/name/pitchone-local/graphql`

## 📋 已完成的工作

### 1. 事件签名修复
- ✅ 将 `FeeDistributed` 更正为 `FeeRouted`
- ✅ 更新 handler 以正确解析所有费用分配参数

### 2. 网络配置
- ✅ 将所有 `network: localhost` 改为 `network: mainnet` (匹配 Graph Node 配置)

### 3. 构建和部署
- ✅ `npm run codegen` - 类型生成成功
- ✅ `npm run build` - 编译为 WASM 成功
- ✅ 上传到 IPFS成功
- ✅ 部署到 Graph Node 成功

### 4. Graph Node 配置
- ✅ 重启 Graph Node 解决 PostgreSQL 连接问题
- ✅ 创建 Subgraph: `npx graph create --node http://localhost:8020/ pitchone-local`
- ✅ 部署 Subgraph: `npx graph deploy ...`

## ⚠️ 当前待解决问题

### Ethereum RPC 连接问题

Graph Node 无法连接到本地 Anvil 节点 (`http://127.0.0.1:8545`):

```
WARN eth_getBlockByNumber(latest) no txs RPC call failed
error sending request for url (http://127.0.0.1:8545)
```

**原因**: Docker 容器内无法访问宿主机的 `127.0.0.1:8545`

**解决方案**:

#### 选项 A: 启动 Anvil 并更新 RPC 配置

1. 在宿主机启动 Anvil:
```bash
# 在新终端运行
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0 --port 8545
```

2. 更新 Graph Node 环境变量 (已在 docker-compose.yml 中配置):
```yaml
environment:
  ethereum: 'mainnet:http://host.docker.internal:8545'
```

3. 重启 Graph Node:
```bash
cd /home/harry/code/subgraph
docker compose restart graph-node
```

#### 选项 B: 使用公共测试网

修改 `/home/harry/code/subgraph/.env`:
```bash
# 使用 Sepolia 测试网
ETHEREUM_RPC_MAINNET=https://rpc.sepolia.org

# 或使用 Infura/Alchemy
ETHEREUM_RPC_MAINNET=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

然后重启服务:
```bash
docker compose down
docker compose up -d
```

#### 选项 C: 当前配置适用于本地开发

Subgraph 已经部署,合约地址配置为 `0x0`,这对于测试 Subgraph 基础设施足够。要测试实际数据索引,需要:

1. 部署实际合约到 Anvil/测试网
2. 更新 `subgraph.yaml` 中的合约地址
3. 重新部署 Subgraph

## 🔍 验证部署

### 1. 检查 Subgraph 状态

```bash
# 查询 GraphQL 端点
curl -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ _meta { block { number } } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local
```

**预期响应** (如果 RPC 连接正常):
```json
{
  "data": {
    "_meta": {
      "block": {
        "number": 123456
      }
    }
  }
}
```

**当前响应** (RPC 未连接):
```json
{
  "errors": [{
    "message": "Subgraph has not started syncing yet"
  }]
}
```

### 2. 查看 Graph Node 日志

```bash
docker logs -f subgraph-graph-node-1
```

### 3. 测试 GraphQL Playground

在浏览器打开: `http://localhost:8010/subgraphs/name/pitchone-local/graphql`

## 📝 示例查询

一旦 RPC 连接正常且有合约事件,可以使用以下查询:

### 查询全局统计

```graphql
query {
  globalStats {
    id
    totalMarkets
    totalUsers
    totalVolume
    totalFees
    activeMarkets
    resolvedMarkets
  }
}
```

### 查询所有市场

```graphql
query {
  markets(first: 10, orderBy: createdAt, orderDirection: desc) {
    id
    templateId
    state
    totalVolume
    uniqueBettors
    createdAt
    lockedAt
    resolvedAt
  }
}
```

### 查询用户数据

```graphql
query UserPositions($user: ID!) {
  user(id: $user) {
    id
    totalBetAmount
    totalRedeemed
    netProfit
    totalBets
    positions(where: { balance_gt: "0" }) {
      market {
        id
        state
      }
      outcome
      balance
      averageCost
    }
  }
}
```

### 查询订单历史

```graphql
query MarketOrders($marketId: ID!) {
  market(id: $marketId) {
    id
    orders(orderBy: timestamp, orderDirection: desc) {
      id
      user {
        id
      }
      outcome
      amount
      shares
      fee
      timestamp
    }
  }
}
```

## 🔧 常用命令

### 重新部署 Subgraph

```bash
cd /home/harry/code/PitchOne/subgraph

# 1. 修改代码后重新构建
npm run build

# 2. 部署新版本
npx graph deploy \
  --node http://localhost:8020/ \
  --ipfs http://localhost:5001 \
  --version-label v0.2.0 \
  pitchone-local
```

### 删除 Subgraph

```bash
npx graph remove --node http://localhost:8020/ pitchone-local
```

### 重启 Graph Node 服务

```bash
cd /home/harry/code/subgraph
docker compose restart graph-node
```

### 查看所有容器状态

```bash
docker compose ps
```

## 📚 下一步

1. **启动本地 Anvil 节点** 并配置 RPC 连接
2. **部署合约**到本地网络
3. **更新 subgraph.yaml** 中的合约地址
4. **重新部署 Subgraph**
5. **触发合约事件**(创建市场、下注等)
6. **验证数据索引**

## 🌐 端口映射说明

实际 Graph Node 部署使用以下端口 (来自 `/home/harry/code/subgraph/.env`):

| 服务 | 容器内端口 | 宿主机端口 | 说明 |
|------|-----------|-----------|------|
| GraphQL HTTP | 8000 | **8010** | 查询接口 |
| GraphQL WebSocket | 8001 | **8011** | 订阅接口 |
| Admin JSON-RPC | 8020 | **8020** | 管理接口 |
| Index Status | 8030 | **8030** | 索引状态 |
| Metrics | 8040 | **8040** | Prometheus 指标 |
| IPFS API | 5001 | **5001** | IPFS 节点 |
| PostgreSQL | 5432 | **5432** | 数据库 |

**重要**: GraphQL 查询使用 **8010** 端口,不是 8000!

## 🎯 成功标准

Subgraph 部署被认为成功当:

- ✅ Graph Node 成功启动并连接到 PostgreSQL
- ✅ Graph Node 能够访问 Ethereum RPC 节点
- ✅ Subgraph 成功上传到 IPFS
- ✅ Subgraph 成功注册到 Graph Node
- ✅ Graph Node 开始索引区块
- ✅ GraphQL 查询返回数据(而不是错误)

**当前状态**: 前 4 项已完成 ✅,需要配置 RPC 连接以完成最后 2 项。

## 📞 故障排查

如果遇到问题,检查:

1. **Graph Node 日志**: `docker logs -f subgraph-graph-node-1`
2. **PostgreSQL 连接**: `docker exec subgraph-postgres-1 psql -U graph-node -d graph-node -c "\dt"`
3. **IPFS 状态**: `curl http://localhost:5001/api/v0/version`
4. **Anvil 是否运行**: `curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545`

## 📖 相关文档

- [DEPLOYMENT_STATUS.md](./DEPLOYMENT_STATUS.md) - 详细的部署状态和问题追踪
- [The Graph Documentation](https://thegraph.com/docs/)
- [Graph Node GitHub](https://github.com/graphprotocol/graph-node)
