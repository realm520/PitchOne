# Subgraph Mapping 实现指南

## 概述

本文档指导如何为新增的 CreditToken、Coupon、PayoutScaler、Campaign 和 Quest 合约实现 Subgraph 事件处理器（Mapping）。

---

## 📋 实施检查清单

### ✅ 已完成
- [x] Schema 实体定义（CreditToken/Coupon/PayoutScaler）
- [x] Campaign/Quest 实体定义（已完成）

### ⏳ 待实现
- [ ] 创建 Mapping 文件
- [ ] 更新 subgraph.yaml 配置
- [ ] 生成 TypeScript 代码
- [ ] 编译和测试

---

## 1. Campaign Mapping 实现

### 文件：`subgraph/src/campaign.ts`

**需要处理的事件**:
1. `CampaignCreated` - 活动创建
2. `CampaignParticipated` - 用户参与活动
3. `CampaignBudgetUpdated` - 预算更新
4. `CampaignStatusUpdated` - 状态变更

**核心处理器示例**:

```typescript
import { CampaignCreated } from "../generated/Campaign/Campaign";
import { Campaign, CampaignStats, User } from "../generated/schema";

export function handleCampaignCreated(event: CampaignCreated): void {
  const campaignId = event.params.campaignId.toHexString();

  // 创建 Campaign 实体
  let campaign = new Campaign(campaignId);
  campaign.name = event.params.name;
  campaign.ruleHash = event.params.ruleHash;
  campaign.budgetCap = toDecimal(event.params.budgetCap, 6); // USDC 6 decimals
  campaign.spentAmount = ZERO_BD;
  campaign.remainingBudget = campaign.budgetCap;
  campaign.startTime = event.params.startTime;
  campaign.endTime = event.params.endTime;
  campaign.status = "Active";
  campaign.participantCount = 0;
  campaign.createdAt = event.block.timestamp;
  campaign.updatedAt = event.block.timestamp;
  campaign.creator = event.params.creator;
  campaign.blockNumber = event.block.number;
  campaign.transactionHash = event.transaction.hash;
  campaign.save();

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();
  stats.totalCampaigns += 1;
  stats.activeCampaigns += 1;
  stats.totalBudget = stats.totalBudget.plus(campaign.budgetCap);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}
```

---

## 2. Quest Mapping 实现

### 文件：`subgraph/src/quest.ts`

**需要处理的事件**:
1. `QuestCreated` - 任务创建
2. `QuestProgressUpdated` - 任务进度更新
3. `QuestCompleted` - 任务完成
4. `QuestRewardClaimed` - 奖励领取
5. `QuestStatusUpdated` - 状态变更

**核心处理器示例**:

```typescript
export function handleQuestProgressUpdated(event: QuestProgressUpdated): void {
  const questId = event.params.questId.toHexString();
  const user = event.params.user;
  const progressId = questId + "-" + user.toHexString();

  // 加载或创建进度实体
  let progress = QuestProgress.load(progressId);
  if (progress === null) {
    progress = new QuestProgress(progressId);
    progress.quest = questId;
    progress.user = user.toHexString();
    progress.targetValue = loadQuest(questId).targetValue;
    progress.currentValue = ZERO_BD;
    progress.completionPercentage = ZERO_BD;
    progress.completed = false;
    progress.rewardClaimed = false;
    progress.createdAt = event.block.timestamp;
  }

  // 更新进度
  const oldValue = progress.currentValue;
  progress.currentValue = toDecimal(event.params.newProgress, 18);
  progress.completionPercentage = progress.currentValue
    .div(progress.targetValue)
    .times(BigDecimal.fromString("100"));
  progress.lastUpdateTime = event.block.timestamp;
  progress.save();

  // 创建进度更新记录
  const updateId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let update = new QuestProgressUpdate(updateId);
  update.progress = progressId;
  update.quest = questId;
  update.user = user.toHexString();
  update.incrementValue = progress.currentValue.minus(oldValue);
  update.oldValue = oldValue;
  update.newValue = progress.currentValue;
  update.completedInThisUpdate = false;
  update.timestamp = event.block.timestamp;
  update.blockNumber = event.block.number;
  update.transactionHash = event.transaction.hash;
  update.save();
}
```

---

## 3. CreditToken Mapping 实现

### 文件：`subgraph/src/credit.ts`

**需要处理的事件**:
1. `CreditTypeCreated` - 券种创建
2. `CreditTypeStatusUpdated` - 券种状态更新
3. `CreditUsed` - 券使用
4. `CreditBatchMinted` - 批量发放
5. `TransferSingle` / `TransferBatch` (ERC-1155) - 券转移

**核心处理器示例**:

```typescript
export function handleCreditTypeCreated(event: CreditTypeCreated): void {
  const creditTypeId = event.params.creditTypeId.toString();

  let creditType = new CreditType(creditTypeId);
  creditType.value = toDecimal(event.params.value, 6); // USDC 6 decimals
  creditType.discountBps = event.params.discountBps;
  creditType.expiresAt = event.params.expiresAt;
  creditType.maxUses = event.params.maxUses;
  creditType.isActive = true;
  creditType.metadata = "";
  creditType.totalSupply = ZERO_BI;
  creditType.totalUsed = ZERO_BI;
  creditType.createdAt = event.block.timestamp;
  creditType.blockNumber = event.block.number;
  creditType.transactionHash = event.transaction.hash;
  creditType.save();
}

export function handleCreditUsed(event: CreditUsed): void {
  const creditTypeId = event.params.creditTypeId.toString();
  const usageId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 创建使用记录
  let usage = new CreditUsage(usageId);
  usage.creditType = creditTypeId;
  usage.user = event.params.user.toHexString();
  usage.amount = event.params.amount;
  usage.discountValue = toDecimal(event.params.discountValue, 6);
  usage.timestamp = event.block.timestamp;
  usage.blockNumber = event.block.number;
  usage.transactionHash = event.transaction.hash;
  usage.save();

  // 更新券种统计
  let creditType = CreditType.load(creditTypeId);
  if (creditType !== null) {
    creditType.totalUsed = creditType.totalUsed.plus(BigInt.fromI32(event.params.amount));
    creditType.save();
  }

  // 更新用户余额
  const balanceId = creditTypeId + "-" + event.params.user.toHexString();
  let balance = CreditBalance.load(balanceId);
  if (balance !== null) {
    balance.usedCount += event.params.amount;
    balance.lastUpdatedAt = event.block.timestamp;
    balance.save();
  }
}
```

---

## 4. Coupon Mapping 实现

### 文件：`subgraph/src/coupon.ts`

**需要处理的事件**:
1. `CouponTypeCreated` - 券种创建
2. `CouponUsed` - 券使用
3. `TransferSingle` / `TransferBatch` (ERC-1155) - 券转移

**核心处理器示例**:

```typescript
export function handleCouponUsed(event: CouponUsed): void {
  const couponTypeId = event.params.couponTypeId.toString();
  const usageId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 创建使用记录
  let usage = new CouponUsage(usageId);
  usage.couponType = couponTypeId;
  usage.user = event.params.user.toHexString();
  usage.market = event.params.market;
  usage.betAmount = toDecimal(event.params.betAmount, 6);
  usage.originalOdds = toDecimal(event.params.originalOdds, 18);
  usage.boostedOdds = toDecimal(event.params.boostedOdds, 18);
  usage.timestamp = event.block.timestamp;
  usage.blockNumber = event.block.number;
  usage.transactionHash = event.transaction.hash;
  usage.save();

  // 更新券种统计
  let couponType = CouponType.load(couponTypeId);
  if (couponType !== null) {
    couponType.totalUsed = couponType.totalUsed.plus(ONE_BI);
    couponType.save();
  }
}
```

---

## 5. PayoutScaler Mapping 实现

### 文件：`subgraph/src/scaler.ts`

**需要处理的事件**:
1. `BudgetRefilled` - 预算充值
2. `ScalingCalculated` - 缩放计算
3. `BudgetUsed` - 预算使用
4. `AutoScaleUpdated` - 自动缩放配置更新

**核心处理器示例**:

```typescript
export function handleBudgetRefilled(event: BudgetRefilled): void {
  const poolId = getPoolIdString(event.params.pool); // "PROMO", "CAMPAIGN", etc.

  // 加载或创建预算池
  let pool = BudgetPool.load(poolId);
  if (pool === null) {
    pool = new BudgetPool(poolId);
    pool.totalBudget = ZERO_BD;
    pool.usedBudget = ZERO_BD;
    pool.pendingPayout = ZERO_BD;
    pool.availableBudget = ZERO_BD;
    pool.autoScaleEnabled = true;
  }

  pool.totalBudget = toDecimal(event.params.newTotal, 6);
  pool.availableBudget = pool.totalBudget.minus(pool.usedBudget);
  pool.lastRefillAt = event.block.timestamp;
  pool.lastUpdatedAt = event.block.timestamp;
  pool.save();

  // 创建充值记录
  const refillId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let refill = new BudgetRefill(refillId);
  refill.pool = poolId;
  refill.amount = toDecimal(event.params.amount, 6);
  refill.newTotal = toDecimal(event.params.newTotal, 6);
  refill.timestamp = event.block.timestamp;
  refill.blockNumber = event.block.number;
  refill.transactionHash = event.transaction.hash;
  refill.save();
}

export function handleScalingCalculated(event: ScalingCalculated): void {
  const poolId = getPoolIdString(event.params.pool);
  const recordId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 创建缩放记录
  let record = new ScalingRecord(recordId);
  record.pool = poolId;
  record.period = event.params.period;
  record.requestedAmount = toDecimal(event.params.requestedAmount, 6);
  record.availableBudget = toDecimal(event.params.availableBudget, 6);
  record.scaleBps = event.params.scaleBps;
  record.scaledAmount = toDecimal(event.params.scaledAmount, 6);
  record.timestamp = event.block.timestamp;
  record.blockNumber = event.block.number;
  record.transactionHash = event.transaction.hash;
  record.save();
}

// Helper function
function getPoolIdString(pool: i32): string {
  if (pool == 0) return "PROMO";
  if (pool == 1) return "CAMPAIGN";
  if (pool == 2) return "QUEST";
  if (pool == 3) return "INSURANCE";
  return "UNKNOWN";
}
```

---

## 6. 更新 subgraph.yaml

需要添加新的数据源配置：

```yaml
# CreditToken 数据源
dataSources:
  - kind: ethereum/contract
    name: CreditToken
    network: mainnet
    source:
      address: "{{CreditToken_ADDRESS}}"
      abi: CreditToken
      startBlock: {{CreditToken_START_BLOCK}}
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - CreditType
        - CreditUsage
        - CreditBalance
      abis:
        - name: CreditToken
          file: ./abis/CreditToken.json
      eventHandlers:
        - event: CreditTypeCreated(indexed uint256,uint256,uint256,uint256,uint256)
          handler: handleCreditTypeCreated
        - event: CreditUsed(indexed address,indexed uint256,uint256,uint256)
          handler: handleCreditUsed
        - event: TransferSingle(indexed address,indexed address,indexed address,uint256,uint256)
          handler: handleCreditTransferSingle
      file: ./src/credit.ts

# Coupon 数据源
  - kind: ethereum/contract
    name: Coupon
    network: mainnet
    source:
      address: "{{Coupon_ADDRESS}}"
      abi: Coupon
      startBlock: {{Coupon_START_BLOCK}}
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - CouponType
        - CouponUsage
        - CouponBalance
      abis:
        - name: Coupon
          file: ./abis/Coupon.json
      eventHandlers:
        - event: CouponTypeCreated(indexed uint256,uint256,uint8,uint256,uint256,uint256,uint256)
          handler: handleCouponTypeCreated
        - event: CouponUsed(indexed address,indexed uint256,indexed address,uint256,uint256,uint256,uint256)
          handler: handleCouponUsed
      file: ./src/coupon.ts

# PayoutScaler 数据源
  - kind: ethereum/contract
    name: PayoutScaler
    network: mainnet
    source:
      address: "{{PayoutScaler_ADDRESS}}"
      abi: PayoutScaler
      startBlock: {{PayoutScaler_START_BLOCK}}
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - BudgetPool
        - BudgetRefill
        - ScalingRecord
        - BudgetUsage
      abis:
        - name: PayoutScaler
          file: ./abis/PayoutScaler.json
      eventHandlers:
        - event: BudgetRefilled(indexed uint8,uint256,uint256)
          handler: handleBudgetRefilled
        - event: ScalingCalculated(indexed uint8,indexed uint256,uint256,uint256,uint256,uint256,uint256)
          handler: handleScalingCalculated
        - event: BudgetUsed(indexed uint8,indexed uint256,uint256,uint256)
          handler: handleBudgetUsed
      file: ./src/scaler.ts

# Campaign 数据源
  - kind: ethereum/contract
    name: Campaign
    network: mainnet
    source:
      address: "{{Campaign_ADDRESS}}"
      abi: Campaign
      startBlock: {{Campaign_START_BLOCK}}
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Campaign
        - CampaignParticipation
        - CampaignStats
      abis:
        - name: Campaign
          file: ./abis/Campaign.json
      eventHandlers:
        - event: CampaignCreated(indexed bytes32,string,bytes32,uint256,uint256,uint256,address)
          handler: handleCampaignCreated
        - event: CampaignParticipated(indexed bytes32,indexed address)
          handler: handleCampaignParticipated
      file: ./src/campaign.ts

# Quest 数据源
  - kind: ethereum/contract
    name: Quest
    network: mainnet
    source:
      address: "{{Quest_ADDRESS}}"
      abi: Quest
      startBlock: {{Quest_START_BLOCK}}
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Quest
        - QuestProgress
        - QuestRewardClaim
        - QuestStats
      abis:
        - name: Quest
          file: ./abis/Quest.json
      eventHandlers:
        - event: QuestCreated(indexed bytes32,indexed bytes32,uint8,string,uint256,uint256,uint256,uint256,address)
          handler: handleQuestCreated
        - event: QuestProgressUpdated(indexed bytes32,indexed address,uint256,uint256)
          handler: handleQuestProgressUpdated
        - event: QuestCompleted(indexed bytes32,indexed address)
          handler: handleQuestCompleted
        - event: QuestRewardClaimed(indexed bytes32,indexed address,uint256)
          handler: handleQuestRewardClaimed
      file: ./src/quest.ts
```

---

## 7. 生成和编译

```bash
# 1. 复制 ABI 文件
cp contracts/out/CreditToken.sol/CreditToken.json subgraph/abis/
cp contracts/out/Coupon.sol/Coupon.json subgraph/abis/
cp contracts/out/PayoutScaler.sol/PayoutScaler.json subgraph/abis/
cp contracts/out/Campaign.sol/Campaign.json subgraph/abis/
cp contracts/out/Quest.sol/Quest.json subgraph/abis/

# 2. 生成 TypeScript 类型
cd subgraph
graph codegen

# 3. 编译 Subgraph
graph build

# 4. 部署到本地节点
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-local

# 5. 部署到 The Graph Studio
graph deploy --studio pitchone
```

---

## 8. 测试查询示例

### 查询用户的券余额
```graphql
{
  creditBalances(where: { user: "0x..." }) {
    id
    creditType {
      value
      discountBps
      expiresAt
    }
    balance
    usedCount
  }
}
```

### 查询活动参与情况
```graphql
{
  campaign(id: "0x...") {
    name
    budgetCap
    spentAmount
    participantCount
    quests {
      name
      questType
      rewardAmount
      completionCount
    }
  }
}
```

### 查询预算池状态
```graphql
{
  budgetPools {
    id
    totalBudget
    usedBudget
    availableBudget
    scalings(first: 10, orderBy: timestamp, orderDirection: desc) {
      requestedAmount
      scaleBps
      scaledAmount
    }
  }
}
```

---

## 9. 实施优先级

**高优先级**（立即实施）:
1. ✅ Schema 更新（已完成）
2. Campaign Mapping（M2 核心功能）
3. Quest Mapping（M2 核心功能）

**中优先级**（1周内）:
4. CreditToken Mapping
5. Coupon Mapping
6. PayoutScaler Mapping

**低优先级**（后续优化）:
7. 性能优化
8. 复杂查询支持
9. 实时统计聚合

---

## 10. 注意事项

1. **精度处理**: USDC 使用 6 decimals，赔率使用 18 decimals
2. **ID 生成**: 使用 `txHash-logIndex` 确保唯一性
3. **关系维护**: 使用 `@derivedFrom` 避免手动维护反向关系
4. **统计更新**: 每个事件处理器都应更新相关的全局统计
5. **错误处理**: 使用 `entity.load()` 检查 null 值
6. **Gas 优化**: 避免重复加载相同实体

---

## 11. 后续工作

- [ ] 编写完整的 Mapping 代码
- [ ] 添加单元测试（使用 matchstick）
- [ ] 性能测试和优化
- [ ] 文档完善
- [ ] 部署到生产环境

---

**文档维护**: 随着实施进展更新此文档
**最后更新**: 2025-12-10
**作者**: Claude Code
