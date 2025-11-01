# Subgraph 部署状态和问题追踪

## ✅ 已完成的工作

### 1. 事件签名修复
- **问题**: `subgraph.yaml` 中 `FeeDistributed` 事件签名与实际合约 ABI 不匹配
- **解决**: 修改为正确的 `FeeRouted` 事件
  - 事件签名: `FeeRouted(indexed address,uint256,indexed address,uint256,uint256,uint256,uint256,uint256)`
  - 更新了 `src/fee.ts` 中的 handler 逻辑,正确解析所有费用分配字段

### 2. 代码生成和构建
- ✅ `npm run codegen` 成功
- ✅ `npm run build` 成功
- ✅ 所有 TypeScript handlers 编译为 WASM 模块
  - `MarketTemplateRegistry/MarketTemplateRegistry.wasm`
  - `WDL_Template/WDL_Template.wasm`
  - `MockOracle/MockOracle.wasm`
  - `FeeRouter/FeeRouter.wasm`

### 3. IPFS 上传
- ✅ 所有文件成功上传到本地 IPFS 节点
- ✅ Subgraph manifest 上传完成: `QmdRgEAuotYnUd3wUBqe5XFn7SJQH26Rnz5Cmr26t5ioT4`

## ⚠️ 当前问题

### Graph Node Admin 端口连接问题

**问题描述**:
- Graph Node 的 8020 (Admin JSON-RPC) 端口在接受连接后立即重置 (`ECONNRESET`)
- 部署命令失败: `graph deploy --node http://localhost:8020/`

**错误信息**:
```
✖ HTTP error deploying the subgraph ECONNRESET
```

**已排查**:
1. ✅ Graph Node 进程正在运行 (PID 2227183)
2. ✅ 端口 8020 处于 LISTEN 状态
3. ✅ IPFS 节点运行正常 (5001 端口)
4. ⚠️  8020 端口拒绝请求或立即关闭连接

**Graph Node 配置** (来自 `/home/harry/code/subgraph/.env`):
```bash
GRAPH_NODE_HTTP_PORT=8010      # GraphQL HTTP
GRAPH_NODE_WS_PORT=8011        # GraphQL WebSocket
GRAPH_NODE_ADMIN_PORT=8020     # JSON-RPC Admin
GRAPH_NODE_INDEX_PORT=8030     # Indexing Status
GRAPH_NODE_METRICS_PORT=8040   # Prometheus Metrics
```

**Graph Node 启动命令** (来自 `ps` 输出):
```bash
graph-node --node-id default \
  --postgres-url postgresql://graph-node:testgraph@postgres:5432/graph-node?sslmode=prefer \
  --ethereum-rpc mainnet:http://127.0.0.1:8545 \
  --ipfs ipfs:5001
```

## 🔍 可能的原因

1. **Graph Node 版本不兼容**:
   - 运行的 graph-node 可能是旧版本,不完全支持 JSON-RPC admin 接口
   - 建议检查版本: `graph-node --version`

2. **网络或防火墙**:
   - Docker 容器内部网络配置问题
   - `extra_hosts` 配置可能影响连接

3. **TLS/SSL 问题**:
   - Graph CLI 可能尝试使用 HTTPS,但 Graph Node 只监听 HTTP

4. **Postgres 连接问题**:
   - 数据库连接字符串中的 `sslmode=prefer` 可能导致问题
   - 需要确认 postgres 服务健康状态

## 📋 推荐的解决步骤

### 步骤 1: 检查 Graph Node 日志
```bash
# 如果使用 Docker Compose
docker logs graph-node -f

# 如果是独立进程
journalctl -u graph-node -f
```

### 步骤 2: 验证端口连接
```bash
# 测试 TCP 连接
nc -zv localhost 8020

# 测试 JSON-RPC 调用
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"subgraph_deploy","params":[],"id":1}' \
  http://localhost:8020
```

### 步骤 3: 尝试替代部署方法

**选项 A: 使用 Graph Node 的 HTTP 端口**
某些 Graph Node 版本在 HTTP 端口 (8010) 也接受部署请求:
```bash
npx graph deploy --node http://localhost:8010/ \
  --ipfs http://localhost:5001 \
  --version-label v0.1.0 \
  pitchone-local
```

**选项 B: 直接使用 IPFS hash 部署**
```bash
# 使用已上传的 IPFS hash
curl -X POST -H "Content-Type: application/json" \
  --data '{
    "jsonrpc": "2.0",
    "method": "subgraph_create",
    "params": {
      "name": "pitchone-local"
    },
    "id": 1
  }' \
  http://localhost:8020
```

**选项 C: 重启 Graph Node 服务**
```bash
# 如果使用 Docker Compose
cd /home/harry/code/subgraph
docker compose restart graph-node

# 等待服务启动
sleep 10

# 重试部署
cd /home/harry/code/PitchOne/subgraph
npx graph deploy --node http://localhost:8020/ \
  --ipfs http://localhost:5001 \
  --version-label v0.1.0 \
  pitchone-local
```

### 步骤 4: 更新 Graph Node 配置

编辑 `/home/harry/code/subgraph/docker-compose.yml`,添加调试选项:
```yaml
environment:
  GRAPH_LOG: debug  # 改为 debug 级别
  RUST_LOG: debug
  GRAPH_ALLOW_NON_DETERMINISTIC_IPFS: 'true'
```

## 📝 下一步行动

1. **立即执行**:
   - [ ] 检查 Graph Node 日志,查找连接被拒绝的具体原因
   - [ ] 验证 PostgreSQL 数据库连接是否正常
   - [ ] 尝试重启 Graph Node 服务

2. **调试部署**:
   - [ ] 使用 `curl` 直接测试 JSON-RPC 接口
   - [ ] 尝试使用 8010 端口部署
   - [ ] 确认 IPFS 文件是否可访问

3. **成功部署后**:
   - [ ] 验证 Subgraph 索引状态
   - [ ] 测试 GraphQL 查询
   - [ ] 编写示例查询和文档

## 📊 当前项目文件状态

### Subgraph 源代码
- ✅ `schema.graphql` - 完整的实体定义
- ✅ `subgraph.yaml` - 正确的事件签名和数据源配置
- ✅ `src/registry.ts` - 市场注册事件处理
- ✅ `src/market.ts` - 市场生命周期事件处理
- ✅ `src/oracle.ts` - 预言机事件处理
- ✅ `src/fee.ts` - 费用路由事件处理 (已修复)
- ✅ `src/helpers.ts` - 辅助函数

### 生成的文件
- ✅ `generated/schema.ts` - GraphQL schema 类型定义
- ✅ `generated/*/` - 合约 ABI 类型绑定
- ✅ `build/*.wasm` - 编译后的 AssemblyScript 模块

### 部署工具
- ✅ `deploy-local.sh` - 自动化部署脚本
- ✅ `scripts/deploy.sh` - 简化部署流程
- ✅ `docker-compose.yml` - Graph Node 开发环境 (已创建)

## 🔗 相关资源

- [The Graph 官方文档](https://thegraph.com/docs/)
- [Graph Node 故障排查](https://github.com/graphprotocol/graph-node/blob/master/docs/getting-started.md)
- [Subgraph 部署指南](https://thegraph.com/docs/en/deploying/deploying-a-subgraph-to-hosted/)
