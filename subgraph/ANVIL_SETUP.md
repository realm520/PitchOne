# Anvil + Graph Node 集成方案

## 问题说明

Graph Node 在 Docker 容器中运行,当前配置的 RPC 地址是 `http://127.0.0.1:8545`。

**问题**: 容器内的 `127.0.0.1` 指向容器自己,无法访问宿主机的 Anvil。

## 解决方案对比

### ✅ 方案 1: 使用 host.docker.internal (推荐)

**优点**:
- 配置简单,无需修改 docker-compose
- Anvil 在宿主机运行,方便开发调试
- 可以直接用 `cast` 等工具与 Anvil 交互

**步骤**:

1. **修改 .env 文件**:
```bash
cd /home/harry/code/subgraph
nano .env
```

将这一行:
```bash
ETHEREUM_RPC_MAINNET=http://127.0.0.1:8545
```

改为:
```bash
ETHEREUM_RPC_MAINNET=http://host.docker.internal:8545
```

2. **启动 Anvil** (在宿主机):
```bash
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0 --port 8545
```

> **注意**: `--host 0.0.0.0` 很重要,让 Anvil 监听所有网络接口

3. **重启 Graph Node**:
```bash
cd /home/harry/code/subgraph
docker compose restart graph-node
```

4. **验证连接**:
```bash
# 从容器内测试 RPC
docker exec subgraph-graph-node-1 wget -O- http://host.docker.internal:8545 2>&1 | grep -i "anvil"
```

---

### 🐳 方案 2: Anvil 也放到 Docker 容器

**优点**:
- 所有服务都在容器中,环境一致
- 不依赖宿主机的 Foundry 安装

**缺点**:
- 需要维护额外的容器
- 开发时与 Anvil 交互稍微复杂(需要用 docker exec)

**步骤**:

1. **创建 Anvil 服务配置**:

编辑 `/home/harry/code/subgraph/docker-compose.yml`,添加 Anvil 服务:

```yaml
services:
  # ... 现有服务 ...

  # 添加 Anvil 服务
  anvil:
    image: ghcr.io/foundry-rs/foundry:latest
    container_name: local-anvil
    command: >
      anvil
      --host 0.0.0.0
      --port 8545
      --chain-id 31337
      --block-time 2
      --accounts 10
      --balance 10000
    ports:
      - "8545:8545"
    networks:
      - graph-net
    restart: unless-stopped
```

2. **修改 Graph Node 配置**:

在 `docker-compose.yml` 中,将 Graph Node 的 `ethereum` 环境变量改为:

```yaml
graph-node:
  environment:
    ethereum: 'mainnet:http://anvil:8545'  # 使用服务名,不是 IP
  depends_on:
    - anvil  # 添加依赖
```

3. **启动所有服务**:
```bash
cd /home/harry/code/subgraph
docker compose up -d
```

4. **验证 Anvil**:
```bash
# 检查 Anvil 日志
docker logs local-anvil

# 测试 RPC
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545
```

5. **从宿主机与 Anvil 交互**:
```bash
# 部署合约到容器中的 Anvil
cd /home/harry/code/PitchOne/contracts
forge script script/DeployNewMarket.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

## 推荐配置: 方案 1

**理由**:
1. **开发效率高**: Anvil 在宿主机,可以直接看日志、重启、调试
2. **工具链方便**: `cast`, `forge script` 等命令直接可用
3. **配置简单**: 只需改 1 行环境变量

**完整配置文件** (`/home/harry/code/subgraph/.env`):

```bash
# PostgreSQL 数据库配置
POSTGRES_USER=graph-node
POSTGRES_PASSWORD=testgraph
POSTGRES_DB=graph-node
POSTGRES_PORT=5432

# 应用数据库配置
APP_POSTGRES_USER=p1
APP_POSTGRES_PASSWORD=p1
APP_POSTGRES_DB=p1

# Graph Node 服务端口
GRAPH_NODE_HTTP_PORT=8010
GRAPH_NODE_WS_PORT=8011
GRAPH_NODE_ADMIN_PORT=8020
GRAPH_NODE_INDEX_PORT=8030
GRAPH_NODE_METRICS_PORT=8040

# IPFS 节点端口
IPFS_API_PORT=5001

# 以太坊 JSON-RPC 端点 (使用 host.docker.internal 访问宿主机)
ETHEREUM_RPC_MAINNET=http://host.docker.internal:8545
```

## 快速启动指南

### 使用方案 1 (推荐)

```bash
# 1. 更新 .env
cd /home/harry/code/subgraph
sed -i 's|http://127.0.0.1:8545|http://host.docker.internal:8545|' .env

# 2. 启动 Anvil (新终端)
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0

# 3. 重启 Graph Node
cd /home/harry/code/subgraph
docker compose restart graph-node

# 4. 查看日志,确认连接成功
docker logs -f subgraph-graph-node-1 | grep -i "latest block"
```

### 使用方案 2 (容器化 Anvil)

```bash
# 1. 添加 Anvil 服务到 docker-compose.yml (见上文)

# 2. 启动所有服务
cd /home/harry/code/subgraph
docker compose up -d

# 3. 验证
docker logs local-anvil
docker logs subgraph-graph-node-1 | grep -i ethereum
```

## 验证 RPC 连接成功

成功连接后,Graph Node 日志应该显示:

```
INFO Successfully connected to Ethereum node
INFO Latest block from Ethereum: 123
INFO Block ingestor started for network: mainnet
```

而不是:
```
WARN eth_getBlockByNumber(latest) failed
ERROR could not get latest block from Ethereum
```

## 下一步

连接成功后:

1. 部署合约到 Anvil
2. 更新 `subgraph.yaml` 中的合约地址
3. 重新部署 Subgraph
4. 触发合约事件
5. 查询 GraphQL 验证数据索引

---

**当前建议**: 使用方案 1,修改 `.env` 文件中的 RPC 地址为 `http://host.docker.internal:8545`
