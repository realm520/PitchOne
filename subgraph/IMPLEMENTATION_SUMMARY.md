# 动态 Subgraph Templates 实现总结

## 实现日期
2025-11-03

## 实现内容

### 1. 核心文件

#### 新增文件：
- `subgraph-dynamic.yaml` - 动态模板配置文件
- `USAGE_DYNAMIC.md` - 使用指南
- `IMPLEMENTATION_SUMMARY.md` - 本文档

#### 修改文件：
- `src/registry.ts` - 实现动态市场索引逻辑

#### 备份文件：
- `subgraph-static.yaml.bak` - 静态配置备份

### 2. 架构变更

#### 之前（静态配置）：
```yaml
dataSources:
  - Market1 (0x4A679...)
  - Market2 (0x0165...)
  - Market3 (0xa513...)
  - Market4 (0x4A679...)
  # ... 每个市场都要硬编码
```

**问题**：
- 每次新增市场都要修改配置
- 需要重新部署 Subgraph
- 不可扩展

#### 之后（动态模板）：
```yaml
dataSources:
  - MarketTemplateRegistry (0x1613...) # 监听工厂合约
  - FeeRouter (0xc6e7...)

templates:
  - WDLMarket      # 胜平负市场模板
  - OUMarket       # 大小球单线模板
  - OUMultiMarket  # 大小球多线模板
```

**优势**：
- ✅ 新市场自动索引
- ✅ 一次部署，永久使用
- ✅ 无限扩展

### 3. 实现细节

#### 3.1 Registry 事件处理

```typescript
// src/registry.ts
export function handleMarketCreatedFromRegistry(event: MarketCreatedFromRegistryEvent): void {
  const marketAddress = event.params.market;
  const templateId = event.params.templateId;
  
  // 加载模板信息
  let template = Template.load(templateId.toHexString());
  
  // 根据模板名称动态创建 data source
  if (templateName === 'WDL') {
    WDLMarket.create(marketAddress); // 🚀 动态创建
  } else if (templateName === 'OU') {
    OUMarket.create(marketAddress);
  } else if (templateName === 'OU_MultiLine') {
    OUMultiMarket.create(marketAddress);
  }
}
```

#### 3.2 模板注册处理

```typescript
export function handleTemplateRegistered(event: TemplateRegisteredEvent): void {
  const templateId = event.params.templateId;
  const name = event.params.name;
  
  // 创建模板实体
  let template = new Template(templateId.toHexString());
  template.templateId = templateId;
  template.name = name;
  template.active = true;
  template.registeredAt = event.block.timestamp;
  template.save();
}
```

### 4. 部署信息

#### Subgraph 版本
- **版本号**: v0.4.0-dynamic
- **IPFS Hash**: QmWjrUgaUc2u5QEaYRRy3EwqVGz6ArkrNLpi2LB3BtK9Hu
- **GraphQL 端点**: http://localhost:8000/subgraphs/name/sportsbook-local/graphql

#### 合约地址
- **MarketTemplateRegistry**: 0x1613beb3b2c4f22ee086b2b38c1476a3ce7f78e8
- **FeeRouter**: 0xc6e7DF5E7b4f2A278906862b61205850344D4e7d

### 5. 如何使用

#### 开发环境（当前）

保留两个配置文件：
- `subgraph.yaml` - 静态配置（开发测试用）
- `subgraph-dynamic.yaml` - 动态配置（生产环境用）

#### 生产环境

1. **确保所有新市场通过 Registry 创建**：
   ```solidity
   // ✅ 正确方式
   registry.createMarket(templateId, initData);
   
   // ❌ 错误方式（需要手动注册）
   new WDL_Template(...);
   ```

2. **新市场会自动被索引**，无需任何操作

3. **监控 Graph Node 日志**：
   ```bash
   docker-compose logs -f graph-node | grep "Registry: Market created"
   ```

### 6. 测试验证

#### 验证步骤：

1. **查询模板注册情况**：
   ```graphql
   query {
     templates {
       id
       name
       active
       registeredAt
     }
   }
   ```

2. **创建新市场**（通过 Registry）：
   ```bash
   forge script script/CreateMarketViaRegistry.s.sol --broadcast
   ```

3. **查询新市场是否出现**：
   ```graphql
   query {
     markets(orderBy: createdAt, orderDirection: desc, first: 1) {
       id
       homeTeam
       awayTeam
       createdAt
     }
   }
   ```

4. **验证市场数据是否正常索引**：
   ```graphql
   query {
     orders(where: { market: "0x新市场地址" }) {
       id
       amount
       outcome
     }
   }
   ```

### 7. 已知问题和解决方案

#### 问题 1: AssemblyScript 类型错误

**错误**:
```
Error: Type '~lib/string/String | null' is not assignable to type '~lib/string/String'
```

**解决方案**:
```typescript
// ❌ 错误
templateName || 'null'

// ✅ 正确
templateName !== null ? templateName : 'null'
```

#### 问题 2: 历史市场没有数据

**原因**: Subgraph 部署时已有的市场不会自动索引

**解决方案**: 在 `registerExistingMarkets()` 中手动注册：
```typescript
export function registerExistingMarkets(): void {
  WDLMarket.create(Address.fromString('0x4A679253410272dd5232B3Ff7cF5dbB88f295319'));
  OUMarket.create(Address.fromString('0x7a2088a1bFc9d81c55368AE168C2C02570cB814F'));
  OUMultiMarket.create(Address.fromString('0x09635F643e140090A9A8Dcd712eD6285858ceBef'));
}
```

### 8. 性能优化建议

#### 8.1 使用 Immutable Entities
根据 Graph CLI 的警告，考虑将不可变实体标记为 `@entity(immutable: true)`：

```graphql
type Order @entity(immutable: true) {
  # 订单创建后不会修改
}

type Redemption @entity(immutable: true) {
  # 赎回记录不会修改
}
```

#### 8.2 优化 Template 编译
三个 templates 使用相同的 handler 文件（market.ts），编译器已优化为共享 WASM：
```
Compile data source template: OUMarket => build/templates/WDLMarket/WDLMarket.wasm (already compiled)
```

### 9. 下一步计划

#### 短期（1-2 周）
- [ ] 测试动态索引的端到端流程
- [ ] 添加更多市场类型模板（AH、ScoreTemplate）
- [ ] 优化 Schema（添加 immutable entities）

#### 中期（3-4 周）
- [ ] 创建通过 Registry 创建市场的 Foundry 脚本
- [ ] 更新前端，使用动态索引的 GraphQL 查询
- [ ] 添加市场创建监控和告警

#### 长期（主网部署前）
- [ ] 完整的生产环境测试
- [ ] 性能压测（1000+ 市场）
- [ ] 文档完善和团队培训

### 10. 相关资源

#### 代码库
- Subgraph 配置: `/home/harry/code/PitchOne/subgraph/`
- 合约代码: `/home/harry/code/PitchOne/contracts/src/core/MarketTemplateRegistry.sol`

#### 文档
- [使用指南](./USAGE_DYNAMIC.md)
- [设计文档](./DYNAMIC_INDEXING.md)
- [The Graph Templates 官方文档](https://thegraph.com/docs/en/developing/creating-a-subgraph/#data-source-templates)

#### 示例项目
- [Uniswap V2 Subgraph](https://github.com/Uniswap/v2-subgraph) - 使用 templates 的经典案例
- [Aave V3 Subgraph](https://github.com/aave/aave-v3-subgraph) - 另一个大规模使用 templates 的项目

### 11. 贡献者

- 实现者: Claude Code
- 审核者: (待补充)
- 测试者: (待补充)

### 12. 更新日志

#### v0.4.0-dynamic (2025-11-03)
- ✅ 添加 MarketTemplateRegistry data source
- ✅ 实现三种市场模板（WDL、OU、OU_MultiLine）
- ✅ 完成动态市场索引逻辑
- ✅ 编写完整文档
- ✅ 成功部署到本地 Graph Node

---

## 快速开始

### 使用动态配置

```bash
# 1. 生成代码
graph codegen subgraph-dynamic.yaml

# 2. 构建
graph build subgraph-dynamic.yaml

# 3. 部署
graph deploy sportsbook-local \
  --node http://localhost:8020 \
  --ipfs http://localhost:5001 \
  --version-label v0.4.0-dynamic \
  subgraph-dynamic.yaml
```

### 创建新市场（会自动索引）

```bash
# 通过 Registry 创建
forge script script/CreateMarketViaRegistry.s.sol --broadcast

# 查询验证
curl -X POST http://localhost:8000/subgraphs/name/sportsbook-local/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ markets(first: 1, orderBy: createdAt, orderDirection: desc) { id homeTeam awayTeam } }"}'
```

---

**状态**: ✅ 实现完成，已部署，待测试
**优先级**: 高（生产环境必需）
**风险评估**: 低（基于成熟的 The Graph Templates 机制）
