# 动态 Subgraph 使用指南

## 概述

该 Subgraph 使用了 The Graph 的 **Data Source Templates** 功能，实现了动态市场索引。这意味着：

✅ **新创建的市场会自动被索引，无需重新部署 Subgraph**
✅ 支持无限数量的市场
✅ 生产就绪，可扩展

## 架构

```
MarketTemplateRegistry (0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8)
         |
         | emit MarketCreated(address market, bytes32 templateId, address creator)
         |
         v
   Subgraph Handler (handleMarketCreatedFromRegistry)
         |
         | 根据 templateId 判断市场类型
         |
         v
    动态创建对应的 Template 实例
         |
         ├─> WDLMarket.create(marketAddress)    // 胜平负市场
         ├─> OUMarket.create(marketAddress)      // 大小球单线市场
         └─> OUMultiMarket.create(marketAddress) // 大小球多线市场
```

## 已部署配置

- **Subgraph 版本**: v0.4.0-dynamic
- **GraphQL 端点**: http://localhost:8000/subgraphs/name/sportsbook-local/graphql
- **Registry 地址**: 0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8
- **配置文件**: `subgraph-dynamic.yaml`

## 如何创建新市场（自动索引）

### 方法 1: 通过 MarketTemplateRegistry 创建（推荐）

当通过 Registry 创建市场时，Subgraph 会自动开始索引：

```solidity
// 示例：创建一个 WDL 市场
MarketTemplateRegistry registry = MarketTemplateRegistry(0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8);

// 1. 确保模板已注册
bytes32 templateId = registry.calculateTemplateId("WDL", "1.0.0");

// 2. 通过 Registry 创建市场
bytes memory initData = abi.encode(...); // 根据市场类型编码初始化数据
address newMarket = registry.createMarket(templateId, initData);

// ✅ Subgraph 会自动检测 MarketCreated 事件并开始索引该市场
```

### 方法 2: 直接部署市场合约（需要手动注册）

如果你直接部署了市场合约（不通过 Registry），需要在 Registry 中注册：

```typescript
// 在 src/registry.ts 的 registerExistingMarkets() 函数中添加
WDLMarket.create(Address.fromString('0x你的市场地址'));
```

然后重新部署 Subgraph。

## 支持的市场模板

### 1. WDL 市场（胜平负）

- **模板 ID**: keccak256(abi.encode("WDL", "1.0.0"))
- **模板名称**: "WDL"
- **Data Source**: WDLMarket
- **合约**: WDL_Template

### 2. OU 单线市场（大小球）

- **模板 ID**: keccak256(abi.encode("OU", "1.0.0"))
- **模板名称**: "OU"
- **Data Source**: OUMarket
- **合约**: OU_Template

### 3. OU 多线市场（大小球多盘口）

- **模板 ID**: keccak256(abi.encode("OU_MultiLine", "1.0.0"))
- **模板名称**: "OU_MultiLine"
- **Data Source**: OUMultiMarket
- **合约**: OU_MultiLine

## 工作流程

### 1. 注册模板（一次性操作）

```bash
# 使用 Foundry 脚本注册模板
cd contracts
forge script script/RegisterTemplates.s.sol --rpc-url http://localhost:8545 --broadcast
```

### 2. 创建市场（自动索引）

```bash
# 方式 A: 通过 Registry 创建（自动索引）
forge script script/CreateMarketViaRegistry.s.sol --rpc-url http://localhost:8545 --broadcast

# 方式 B: 直接部署合约（需要手动注册到 Template）
forge script script/DeployDiverseMarkets.s.sol --rpc-url http://localhost:8545 --broadcast
```

### 3. 查询市场数据

```graphql
# 查询所有市场
query AllMarkets {
  markets(first: 100, orderBy: createdAt, orderDirection: desc) {
    id
    homeTeam
    awayTeam
    kickoffTime
    state
    totalVolume
    uniqueBettors
  }
}

# 查询特定市场的订单
query MarketOrders($marketId: ID!) {
  orders(where: { market: $marketId }) {
    id
    user
    outcome
    amount
    shares
    timestamp
  }
}

# 查询已注册的模板
query Templates {
  templates {
    id
    name
    active
    registeredAt
  }
}
```

## 验证动态索引是否工作

### 1. 查看 Graph Node 日志

```bash
docker-compose logs -f graph-node | grep "MarketCreated"
```

你应该看到类似的日志：
```
Registry: Market created at 0x... with template 0x...
Registry: Creating WDL market data source for 0x...
```

### 2. 查询市场数量

```bash
curl -X POST http://localhost:8000/subgraphs/name/sportsbook-local/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ markets(first: 1000) { id } }"}'
```

每次通过 Registry 创建新市场后，市场数量应该自动增加。

## 故障排查

### 问题 1: 新市场没有被索引

**检查清单**：
1. 市场是否通过 Registry 的 `createMarket()` 创建？
2. 模板是否已在 Registry 中注册？
3. 模板名称是否匹配（WDL / OU / OU_MultiLine）？
4. Graph Node 是否正常运行？

**调试步骤**：
```bash
# 1. 检查 Registry 事件
cast logs --address 0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8 --rpc-url http://localhost:8545

# 2. 检查模板注册
cast call 0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8 "getTemplateInfo(bytes32)" $(cast keccak "WDL1.0.0") --rpc-url http://localhost:8545

# 3. 检查 Graph Node 日志
docker-compose logs graph-node | tail -100
```

### 问题 2: 编译错误

如果修改了 `src/registry.ts` 后编译失败：

```bash
# 重新生成类型
graph codegen subgraph-dynamic.yaml

# 重新构建
graph build subgraph-dynamic.yaml
```

### 问题 3: 历史市场没有数据

如果 Subgraph 部署时已有市场存在，需要手动注册：

```typescript
// 在 src/registry.ts 的 registerExistingMarkets() 中添加
export function registerExistingMarkets(): void {
  WDLMarket.create(Address.fromString('0x4A679253410272dd5232B3Ff7cF5dbB88f295319'));
  OUMarket.create(Address.fromString('0x7a2088a1bFc9d81c55368AE168C2C02570cB814F'));
  OUMultiMarket.create(Address.fromString('0x09635F643e140090A9A8Dcd712eD6285858ceBef'));
}
```

然后在 `handleTemplateRegistered` 的第一次调用时触发：

```typescript
export function handleTemplateRegistered(event: TemplateRegisteredEvent): void {
  // ... 现有代码

  // 首次初始化时注册历史市场
  let stats = GlobalStats.load('global');
  if (stats === null) {
    registerExistingMarkets();
    // ... 创建 stats
  }
}
```

## 对比：静态 vs 动态索引

| 特性 | 静态索引 (subgraph.yaml) | 动态索引 (subgraph-dynamic.yaml) |
|------|------------------------|----------------------------------|
| 新增市场 | 需修改配置并重新部署 | 自动索引，无需操作 |
| 扩展性 | 有限（配置文件大小） | 无限制 |
| 生产就绪 | ❌ 不适合 | ✅ 适合 |
| 初期设置 | 简单 | 稍复杂 |
| 适用场景 | 开发测试 | 生产环境 |

## 相关文档

- [完整设计文档](./DYNAMIC_INDEXING.md)
- [The Graph Templates 文档](https://thegraph.com/docs/en/developing/creating-a-subgraph/#data-source-templates)
- [合约架构](../docs/design/)

## 下一步

1. 在生产环境中，确保所有新市场都通过 Registry 创建
2. 监控 Graph Node 日志，确保动态索引正常工作
3. 考虑添加更多市场模板（AH、ScoreTemplate 等）
