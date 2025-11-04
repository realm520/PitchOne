# Subgraph 动态市场索引方案

## 问题
当前每次新增市场都需要：
1. 修改 `subgraph.yaml` 添加新市场地址
2. 重新编译：`graph codegen && graph build`
3. 重新部署：`graph deploy`

这在生产环境中不可扩展。

## 解决方案对比

### 方案 1: 当前方案（静态配置）✅ 已实现

**优点**：
- 简单直接
- 适合开发测试阶段
- 每个市场独立，便于调试

**缺点**：
- 每次新增市场都要重新部署 Subgraph
- 不适合生产环境
- 无法自动索引新创建的市场

**适用场景**：开发和测试阶段

---

### 方案 2: 动态数据源（Templates）⭐ 推荐

使用 The Graph 的 **Templates** 功能，监听工厂合约事件自动索引新市场。

#### 架构设计

```
MarketTemplateRegistry (工厂合约)
         |
         | emit MarketCreated(address newMarket, string marketType)
         |
         v
   Subgraph Handler
         |
         | Template.create(marketAddress)
         |
         v
  自动开始索引新市场
```

#### 实现步骤

##### 1. 更新合约部署脚本

修改 `DeployDiverseMarkets.s.sol`，使用 Registry 创建市场：

```solidity
// 不要直接 new WDL_Template(...)
// 而是通过 Registry 创建
marketTemplateRegistry.createMarket(
    "WDL",
    abi.encode(
        matchId,
        homeTeam,
        awayTeam,
        kickoffTime,
        usdc,
        feeRouter,
        feeRate,
        disputePeriod,
        cpmm,
        uri
    )
);
```

##### 2. 更新 `subgraph.yaml`

```yaml
dataSources:
  # 监听 MarketTemplateRegistry
  - kind: ethereum/contract
    name: MarketTemplateRegistry
    network: mainnet
    source:
      address: "0x你的Registry地址"
      abi: MarketTemplateRegistry
      startBlock: 0
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Market
      abis:
        - name: MarketTemplateRegistry
          file: ../contracts/out/MarketTemplateRegistry.sol/MarketTemplateRegistry.json
      eventHandlers:
        # 监听市场创建事件
        - event: MarketCreated(indexed address,string,string)
          handler: handleRegistryMarketCreated
      file: ./src/registry.ts

# 动态模板：新市场会自动使用这些模板
templates:
  - kind: ethereum/contract
    name: WDLMarket
    network: mainnet
    source:
      abi: WDL_Template
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Market
        - Order
        - Position
      abis:
        - name: WDL_Template
          file: ../contracts/out/WDL_Template.sol/WDL_Template.json
      eventHandlers:
        - event: MarketCreated(indexed string,string,string,uint256,address)
          handler: handleMarketCreated
        - event: BetPlaced(indexed address,indexed uint256,uint256,uint256,uint256)
          handler: handleBetPlaced
        # ... 其他事件
      file: ./src/market.ts

  # OU_Template 和 OU_MultiLine 的模板类似...
```

##### 3. 创建 Registry 事件处理器

```typescript
// src/registry.ts
import { MarketCreated } from '../generated/MarketTemplateRegistry/MarketTemplateRegistry';
import { WDLMarket, OUMarket, OUMultiMarket } from '../generated/templates';
import { Address } from '@graphprotocol/graph-ts';

export function handleRegistryMarketCreated(event: MarketCreated): void {
  const marketAddress = event.params.marketAddress;
  const marketType = event.params.marketType; // "WDL" | "OU" | "OU_MULTI"

  // 根据市场类型动态创建对应的 data source
  if (marketType == "WDL") {
    WDLMarket.create(marketAddress);
  } else if (marketType == "OU") {
    OUMarket.create(marketAddress);
  } else if (marketType == "OU_MULTI") {
    OUMultiMarket.create(marketAddress);
  }

  // Template.create() 后，Subgraph 会自动开始索引该市场的所有事件
}
```

##### 4. 处理已部署的市场

对于 Subgraph 部署**之前**已经创建的市场，需要手动注册：

```typescript
// src/registry.ts
export function handleRegistryMarketCreated(event: MarketCreated): void {
  // ... 动态创建逻辑

  // 首次事件触发时，注册历史市场
  let globalStats = GlobalStats.load('1');
  if (globalStats == null) {
    // 首次初始化，注册已部署的市场
    registerHistoricalMarkets();
    globalStats = new GlobalStats('1');
    globalStats.save();
  }
}

function registerHistoricalMarkets(): void {
  // 注册在 Subgraph 部署前创建的市场
  WDLMarket.create(Address.fromString('0x4A679253410272dd5232B3Ff7cF5dbB88f295319'));
  OUMarket.create(Address.fromString('0x7a2088a1bFc9d81c55368AE168C2C02570cB814F'));
  OUMultiMarket.create(Address.fromString('0x09635F643e140090A9A8Dcd712eD6285858ceBef'));
}
```

#### 优点

✅ **一次部署，永久使用**：新市场自动索引，无需重新部署 Subgraph
✅ **可扩展**：支持无限数量的市场
✅ **生产就绪**：适合主网环境
✅ **类型安全**：每种市场类型有独立的 template

#### 缺点

⚠️ 需要修改合约部署流程，使用 Registry
⚠️ 初期设置稍复杂

---

### 方案 3: 混合方案（过渡期）

如果暂时不想修改合约部署流程，可以使用混合方案：

1. 保留当前的静态配置用于已部署的市场
2. 同时添加 templates，为未来的动态市场做准备
3. 逐步迁移到完全动态的方式

---

## 推荐实施路线

### 阶段 1：当前（开发测试） - 静态配置
```bash
# 新增市场时
1. 修改 subgraph.yaml 添加新的 dataSource
2. graph codegen && graph build
3. graph deploy
```

### 阶段 2：过渡期 - 添加 Templates
```yaml
# 保留现有的 dataSources
# 添加 templates 准备未来使用
```

### 阶段 3：生产环境 - 完全动态
```solidity
// 所有市场通过 Registry 创建
marketTemplateRegistry.createMarket(...)

// Subgraph 自动索引，无需重新部署
```

---

## 快速迁移指南

### 1. 检查 MarketTemplateRegistry 是否已部署

```bash
# 查看当前部署的 Registry 地址
grep "marketTemplateRegistry" frontend/packages/contracts/src/addresses/index.ts
```

### 2. 如果没有，部署 Registry

```bash
# 创建部署脚本
cd contracts
forge script script/DeployRegistry.s.sol:DeployRegistry --rpc-url http://localhost:8545 --broadcast
```

### 3. 更新 Subgraph 配置

```bash
cd subgraph
# 使用 subgraph-dynamic.yaml 作为模板
cp subgraph-dynamic.yaml subgraph.yaml
# 修改 Registry 地址
```

### 4. 重新部署 Subgraph（最后一次）

```bash
graph codegen
graph build
graph deploy sportsbook-local --node http://localhost:8020 --ipfs http://localhost:5001 --version-label v1.0.0
```

### 5. 以后创建市场

```bash
# 通过 Registry 创建（自动被 Subgraph 索引）
# 不再需要修改 subgraph.yaml ✅
```

---

## 常见问题

**Q: 我现在必须切换到动态索引吗？**
A: 不必。如果你还在开发测试阶段，静态配置完全够用。等到准备上主网时再切换。

**Q: 切换到动态索引会丢失已有数据吗？**
A: 不会。通过 `registerHistoricalMarkets()` 函数可以重新索引历史市场。

**Q: 如果 Registry 合约没有 MarketCreated 事件怎么办？**
A: 需要在 Registry 合约中添加该事件。查看 `contracts/src/core/MarketTemplateRegistry.sol`。

**Q: Templates 有性能问题吗？**
A: 没有。The Graph 的 templates 机制在生产环境中被广泛使用（Uniswap、Aave 等）。

---

## 相关资源

- [The Graph Templates 文档](https://thegraph.com/docs/en/developing/creating-a-subgraph/#data-source-templates)
- [Uniswap V2 Subgraph 示例](https://github.com/Uniswap/v2-subgraph) - 使用 templates 的经典案例
- [项目架构文档](../docs/design/)
