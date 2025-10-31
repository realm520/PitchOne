# PitchOne Subgraph

PitchOne 去中心化足球博彩平台的 The Graph Subgraph 实现。

## 功能概述

本 Subgraph 索引以下合约事件：

### 核心事件

- **MarketCreated**: 市场创建
- **BetPlaced**: 用户下注
- **Locked**: 市场锁盘
- **Resolved**: 市场结算
- **Finalized**: 最终确认
- **Redeemed**: 用户赎回奖金

### 预言机事件

- **ResultProposed**: 结果提案
- **ResultDisputed**: 结果争议
- **ResultFinalized**: 结果最终确认

### 费用事件

- **FeeReceived**: 费用接收
- **FeeDistributed**: 费用分发

## 实体 Schema

### 核心实体

- **Market**: 博彩市场
- **User**: 用户
- **Order**: 下注订单
- **Position**: 用户头寸
- **Redemption**: 赎回记录

### 辅助实体

- **OracleProposal**: 预言机提案
- **FeeDistribution**: 费用分发
- **Template**: 市场模板
- **GlobalStats**: 全局统计

## 开发指南

### 安装依赖

```bash
cd subgraph
npm install
```

### 代码生成

根据 schema.graphql 和 subgraph.yaml 生成 TypeScript 类型：

```bash
npm run codegen
```

### 构建

```bash
npm run build
```

### 本地部署

1. 启动本地 Graph Node（需要 Docker）：

```bash
cd ../infra
docker-compose up graph-node ipfs postgres
```

2. 创建本地 Subgraph：

```bash
npm run create-local
```

3. 部署：

```bash
npm run deploy-local
```

### 测试

运行单元测试：

```bash
npm test
```

## 查询示例

### 查询用户的所有订单

```graphql
query UserOrders($userAddress: String!) {
  orders(
    where: { user: $userAddress }
    orderBy: timestamp
    orderDirection: desc
  ) {
    id
    market {
      id
      state
      winnerOutcome
    }
    outcome
    amount
    shares
    timestamp
  }
}
```

### 查询市场详情

```graphql
query MarketDetails($marketAddress: String!) {
  market(id: $marketAddress) {
    id
    templateId
    state
    totalVolume
    feeAccrued
    uniqueBettors
    winnerOutcome
    orders(orderBy: timestamp, orderDirection: desc, first: 10) {
      id
      user {
        id
      }
      outcome
      amount
    }
  }
}
```

### 查询全局统计

```graphql
query GlobalStats {
  globalStats(id: "global") {
    totalMarkets
    totalUsers
    totalVolume
    totalFees
    activeMarkets
    resolvedMarkets
  }
}
```

## 配置文件

### 更新合约地址

部署合约后，需要更新 `subgraph.yaml` 中的合约地址：

```yaml
dataSources:
  - name: MarketTemplateRegistry
    source:
      address: "YOUR_REGISTRY_ADDRESS"
      startBlock: DEPLOYMENT_BLOCK_NUMBER
```

### 网络配置

本地开发使用 `localhost` 网络。部署到测试网或主网时，需要修改 `network` 字段：

```yaml
network: mainnet # 或 sepolia, arbitrum, etc.
```

## 目录结构

```
subgraph/
├── schema.graphql          # GraphQL Schema 定义
├── subgraph.yaml          # Subgraph 配置文件
├── package.json           # 依赖管理
├── src/                   # 事件处理器源代码
│   ├── helpers.ts         # 辅助工具函数
│   ├── market.ts          # 市场事件处理
│   ├── registry.ts        # 注册表事件处理
│   ├── oracle.ts          # 预言机事件处理
│   └── fee.ts             # 费用事件处理
├── tests/                 # 单元测试
│   ├── market.test.ts
│   └── registry.test.ts
├── generated/             # 自动生成的代码（codegen）
└── README.md              # 本文件
```

## 注意事项

1. **BigInt vs BigDecimal**:
   - 链上金额使用 `BigInt` (wei)
   - 显示金额使用 `BigDecimal` (USDC with 6 decimals)

2. **实体 ID 设计**:
   - Market: 合约地址
   - User: 用户地址
   - Order: `txHash-logIndex`
   - Position: `market-user-outcome`

3. **事件顺序**:
   - 同一交易内的事件按 logIndex 顺序处理
   - 务必保证 MarketCreated 在其他市场事件之前处理

4. **性能优化**:
   - 避免在 handler 中进行复杂计算
   - 使用 `@derivedFrom` 减少冗余存储
   - 合理设计索引提升查询性能

## 部署到 The Graph Studio

1. 创建 Subgraph：

```bash
graph init --studio pitchone
```

2. 认证：

```bash
graph auth --studio YOUR_DEPLOY_KEY
```

3. 部署：

```bash
graph deploy --studio pitchone
```

## 相关链接

- [The Graph 文档](https://thegraph.com/docs/)
- [AssemblyScript 文档](https://www.assemblyscript.org/)
- [Matchstick 测试框架](https://github.com/LimeChain/matchstick)

## License

MIT
