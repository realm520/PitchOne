# 事件字典（最小必要集）

本文档记录 PitchOne 合约系统中所有关键事件的定义、参数说明和使用场景。

## 目录

- [Campaign 事件](#campaign-事件)
- [Quest 事件](#quest-事件)
- [Subgraph 映射说明](#subgraph-映射说明)

---

## Campaign 事件

### 1. CampaignCreated

**事件签名**：
```solidity
event CampaignCreated(
    bytes32 indexed campaignId,
    string name,
    bytes32 ruleHash,
    uint256 budgetCap,
    uint256 startTime,
    uint256 endTime
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `campaignId` | `bytes32` | ✅ | 活动唯一标识符 |
| `name` | `string` | ❌ | 活动名称 |
| `ruleHash` | `bytes32` | ❌ | 活动规则哈希（用于验证规则未被篡改） |
| `budgetCap` | `uint256` | ❌ | 活动预算上限（wei） |
| `startTime` | `uint256` | ❌ | 活动开始时间（Unix 时间戳） |
| `endTime` | `uint256` | ❌ | 活动结束时间（Unix 时间戳） |

**触发时机**：
- 调用 `Campaign.createCampaign()` 成功时
- 仅限 ADMIN_ROLE 权限

**Subgraph 映射**：
- 创建新的 `Campaign` 实体
- 初始化 `status = Active`
- 初始化 `spentAmount = 0`
- 计算 `remainingBudget = budgetCap`
- 初始化 `participantCount = 0`

**示例值**：
```json
{
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "name": "New Year Bonus Campaign",
  "ruleHash": "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
  "budgetCap": "10000000000000000000000",
  "startTime": "1704067200",
  "endTime": "1706745600"
}
```

---

### 2. CampaignParticipated

**事件签名**：
```solidity
event CampaignParticipated(
    bytes32 indexed campaignId,
    address indexed user,
    uint256 timestamp
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `campaignId` | `bytes32` | ✅ | 活动唯一标识符 |
| `user` | `address` | ✅ | 参与用户地址 |
| `timestamp` | `uint256` | ❌ | 参与时间戳 |

**触发时机**：
- 用户首次调用 `Campaign.participate()` 成功时
- 同一用户重复参与不会触发（幂等性保护）
- 必须在活动时间范围内且状态为 Active

**Subgraph 映射**：
- 创建新的 `CampaignParticipation` 实体
  - `id = campaignId-userAddress`
  - 关联 `campaign` 和 `user`
- 更新 `Campaign.participantCount += 1`
- 更新 `User.campaignParticipations` 列表

**示例值**：
```json
{
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "user": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "timestamp": "1704153600"
}
```

---

### 3. CampaignBudgetSpent

**事件签名**：
```solidity
event CampaignBudgetSpent(
    bytes32 indexed campaignId,
    uint256 amount,
    uint256 totalSpent
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `campaignId` | `bytes32` | ✅ | 活动唯一标识符 |
| `amount` | `uint256` | ❌ | 本次支出金额（wei） |
| `totalSpent` | `uint256` | ❌ | 累计总支出（wei） |

**触发时机**：
- Quest 合约调用 `Campaign.recordSpending()` 时
- 用户领取任务奖励时自动触发
- 仅限 OPERATOR_ROLE 权限

**Subgraph 映射**：
- 创建新的 `CampaignBudgetChange` 实体
  - `changeType = Spent`
  - `amount = amount`
  - `oldValue = totalSpent - amount`
  - `newValue = totalSpent`
- 更新 `Campaign.spentAmount = totalSpent`
- 更新 `Campaign.remainingBudget = budgetCap - totalSpent`

**示例值**：
```json
{
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "amount": "1000000000000000000",
  "totalSpent": "5000000000000000000"
}
```

---

### 4. CampaignStatusChanged

**事件签名**：
```solidity
event CampaignStatusChanged(
    bytes32 indexed campaignId,
    CampaignStatus oldStatus,
    CampaignStatus newStatus
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `campaignId` | `bytes32` | ✅ | 活动唯一标识符 |
| `oldStatus` | `CampaignStatus` | ❌ | 变更前状态（0=Active, 1=Paused, 2=Ended） |
| `newStatus` | `CampaignStatus` | ❌ | 变更后状态（0=Active, 1=Paused, 2=Ended） |

**触发时机**：
- 调用 `pauseCampaign()` 时：Active → Paused
- 调用 `resumeCampaign()` 时：Paused → Active
- 调用 `endCampaign()` 时：Active/Paused → Ended
- 仅限 ADMIN_ROLE 权限

**Subgraph 映射**：
- 创建新的 `CampaignStatusChange` 实体
  - `id = campaignId-timestamp-txHash`
  - `oldStatus` 和 `newStatus` 枚举值
- 更新 `Campaign.status = newStatus`
- 更新全局统计：
  - `CampaignStats.activeCampaigns` ±1
  - `CampaignStats.pausedCampaigns` ±1
  - `CampaignStats.endedCampaigns` ±1

**示例值**：
```json
{
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "oldStatus": 0,
  "newStatus": 1
}
```

**状态转换规则**：
```
Active (0) → Paused (1)  [pauseCampaign]
Paused (1) → Active (0)  [resumeCampaign]
Active (0) → Ended (2)   [endCampaign]
Paused (1) → Ended (2)   [endCampaign]
```

---

### 5. CampaignBudgetIncreased

**事件签名**：
```solidity
event CampaignBudgetIncreased(
    bytes32 indexed campaignId,
    uint256 oldCap,
    uint256 newCap
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `campaignId` | `bytes32` | ✅ | 活动唯一标识符 |
| `oldCap` | `uint256` | ❌ | 变更前预算上限（wei） |
| `newCap` | `uint256` | ❌ | 变更后预算上限（wei） |

**触发时机**：
- 调用 `Campaign.increaseBudget()` 成功时
- 仅限 ADMIN_ROLE 权限
- `newCap` 必须大于 `oldCap`

**Subgraph 映射**：
- 创建新的 `CampaignBudgetChange` 实体
  - `changeType = Increased`
  - `amount = newCap - oldCap`
  - `oldValue = oldCap`
  - `newValue = newCap`
- 更新 `Campaign.budgetCap = newCap`
- 更新 `Campaign.remainingBudget = newCap - spentAmount`
- 更新 `CampaignStats.totalBudget += (newCap - oldCap)`

**示例值**：
```json
{
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "oldCap": "10000000000000000000000",
  "newCap": "15000000000000000000000"
}
```

---

## Quest 事件

### 6. QuestCreated

**事件签名**：
```solidity
event QuestCreated(
    bytes32 indexed questId,
    bytes32 indexed campaignId,
    QuestType questType,
    string name,
    uint256 rewardAmount,
    uint256 targetValue,
    uint256 startTime,
    uint256 endTime
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `questId` | `bytes32` | ✅ | 任务唯一标识符 |
| `campaignId` | `bytes32` | ✅ | 所属活动 ID |
| `questType` | `QuestType` | ❌ | 任务类型（0-4，见下方说明） |
| `name` | `string` | ❌ | 任务名称 |
| `rewardAmount` | `uint256` | ❌ | 单个用户奖励金额（wei） |
| `targetValue` | `uint256` | ❌ | 目标值（具体含义取决于任务类型） |
| `startTime` | `uint256` | ❌ | 任务开始时间（Unix 时间戳） |
| `endTime` | `uint256` | ❌ | 任务结束时间（Unix 时间戳） |

**QuestType 枚举**：
- `0 = FIRST_BET`：首次下注（targetValue = 1）
- `1 = CONSECUTIVE_BETS`：连续下注天数（targetValue = 连续天数）
- `2 = REFERRAL`：推荐人数（targetValue = 推荐人数）
- `3 = VOLUME`：累计投注额（targetValue = 目标金额 wei）
- `4 = WIN_STREAK`：连胜场数（targetValue = 连胜场数）

**触发时机**：
- 调用 `Quest.createQuest()` 成功时
- 仅限 ADMIN_ROLE 权限
- 关联的 Campaign 必须存在且为 Active 状态

**Subgraph 映射**：
- 创建新的 `Quest` 实体
  - 关联 `campaign`
  - 初始化 `status = Active`
  - 初始化 `completionCount = 0`
- 更新 `Campaign.quests` 列表
- 更新全局统计：
  - `QuestStats.totalQuests += 1`
  - `QuestStats.activeQuests += 1`
  - 根据 `questType` 更新对应计数器（如 `firstBetQuests += 1`）

**示例值**：
```json
{
  "questId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "campaignId": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "questType": 0,
  "name": "First Bet Bonus",
  "rewardAmount": "1000000000000000000",
  "targetValue": "1",
  "startTime": "1704067200",
  "endTime": "1706745600"
}
```

---

### 7. QuestProgressUpdated

**事件签名**：
```solidity
event QuestProgressUpdated(
    bytes32 indexed questId,
    address indexed user,
    uint256 currentValue,
    uint256 targetValue
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `questId` | `bytes32` | ✅ | 任务唯一标识符 |
| `user` | `address` | ✅ | 用户地址 |
| `currentValue` | `uint256` | ❌ | 更新后的当前进度值 |
| `targetValue` | `uint256` | ❌ | 目标值（不变） |

**触发时机**：
- 调用 `Quest.updateProgress()` 成功时
- 仅限 OPERATOR_ROLE 权限
- 任务必须为 Active 状态且在有效时间范围内
- 用户必须已参与对应的 Campaign

**Subgraph 映射**：
- 如果 `QuestProgress` 不存在，创建新实体：
  - `id = questId-userAddress`
  - `currentValue = 0`
  - `completed = false`
  - `rewardClaimed = false`
- 创建 `QuestProgressUpdate` 实体记录本次更新：
  - `incrementValue = 新增的进度值`
  - `oldValue = 更新前的值`
  - `newValue = currentValue`
  - `completedInThisUpdate = (currentValue >= targetValue && oldValue < targetValue)`
- 更新 `QuestProgress`：
  - `currentValue = currentValue`
  - `completionPercentage = (currentValue / targetValue) * 100`
  - `lastUpdateTime = timestamp`

**示例值**：
```json
{
  "questId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "user": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "currentValue": "3",
  "targetValue": "7"
}
```

---

### 8. QuestCompleted

**事件签名**：
```solidity
event QuestCompleted(
    bytes32 indexed questId,
    address indexed user,
    uint256 timestamp
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `questId` | `bytes32` | ✅ | 任务唯一标识符 |
| `user` | `address` | ✅ | 完成任务的用户地址 |
| `timestamp` | `uint256` | ❌ | 完成时间戳 |

**触发时机**：
- 当用户进度达到 `targetValue` 时自动触发
- 发生在 `updateProgress()` 调用中
- 每个用户每个任务只触发一次

**Subgraph 映射**：
- 更新 `QuestProgress`：
  - `completed = true`
  - `completedAt = timestamp`
  - `completionPercentage = 100`
- 更新 `Quest.completionCount += 1`
- 更新 `QuestStats.totalCompletions += 1`

**示例值**：
```json
{
  "questId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "user": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "timestamp": "1704240000"
}
```

---

### 9. QuestRewardClaimed

**事件签名**：
```solidity
event QuestRewardClaimed(
    bytes32 indexed questId,
    address indexed user,
    uint256 rewardAmount
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `questId` | `bytes32` | ✅ | 任务唯一标识符 |
| `user` | `address` | ✅ | 领取奖励的用户地址 |
| `rewardAmount` | `uint256` | ❌ | 奖励金额（wei） |

**触发时机**：
- 用户调用 `Quest.claimReward()` 成功时
- 前提条件：
  - 任务已完成（`completed = true`）
  - 尚未领取（`rewardClaimed = false`）
  - Campaign 预算充足
  - 用户余额足够支付 Gas

**Subgraph 映射**：
- 创建新的 `QuestRewardClaim` 实体：
  - `id = questId-userAddress-txHash`
  - 关联 `quest` 和 `user`
  - `rewardAmount = rewardAmount`
  - `timestamp = block.timestamp`
  - `transactionHash = tx.hash`
- 更新 `QuestProgress`：
  - `rewardClaimed = true`
  - `rewardClaimedAt = timestamp`
- 更新 `User.questRewardsClaimed` 列表
- 更新 `QuestStats.totalRewardsClaimed += rewardAmount`
- **同时触发 `CampaignBudgetSpent` 事件**（自动调用 Campaign.recordSpending）

**示例值**：
```json
{
  "questId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "user": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
  "rewardAmount": "1000000000000000000"
}
```

---

### 10. QuestStatusChanged

**事件签名**：
```solidity
event QuestStatusChanged(
    bytes32 indexed questId,
    QuestStatus oldStatus,
    QuestStatus newStatus
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `questId` | `bytes32` | ✅ | 任务唯一标识符 |
| `oldStatus` | `QuestStatus` | ❌ | 变更前状态（0=Active, 1=Paused, 2=Ended） |
| `newStatus` | `QuestStatus` | ❌ | 变更后状态（0=Active, 1=Paused, 2=Ended） |

**触发时机**：
- 调用 `pauseQuest()` 时：Active → Paused
- 调用 `resumeQuest()` 时：Paused → Active
- 调用 `endQuest()` 时：Active/Paused → Ended
- 仅限 ADMIN_ROLE 权限

**Subgraph 映射**：
- 创建新的 `QuestStatusChange` 实体：
  - `id = questId-timestamp-txHash`
  - `oldStatus` 和 `newStatus` 枚举值
- 更新 `Quest.status = newStatus`
- 更新全局统计：
  - `QuestStats.activeQuests` ±1
  - `QuestStats.pausedQuests` ±1
  - `QuestStats.endedQuests` ±1

**示例值**：
```json
{
  "questId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "oldStatus": 0,
  "newStatus": 1
}
```

**状态转换规则**：
```
Active (0) → Paused (1)  [pauseQuest]
Paused (1) → Active (0)  [resumeQuest]
Active (0) → Ended (2)   [endQuest]
Paused (1) → Ended (2)   [endQuest]
```

---

## Subgraph 映射说明

### 事件处理器命名规范

建议的事件处理函数命名（在 `mapping.ts` 中）：

**Campaign 事件**：
- `handleCampaignCreated(event: CampaignCreatedEvent)`
- `handleCampaignParticipated(event: CampaignParticipatedEvent)`
- `handleCampaignBudgetSpent(event: CampaignBudgetSpentEvent)`
- `handleCampaignStatusChanged(event: CampaignStatusChangedEvent)`
- `handleCampaignBudgetIncreased(event: CampaignBudgetIncreasedEvent)`

**Quest 事件**：
- `handleQuestCreated(event: QuestCreatedEvent)`
- `handleQuestProgressUpdated(event: QuestProgressUpdatedEvent)`
- `handleQuestCompleted(event: QuestCompletedEvent)`
- `handleQuestRewardClaimed(event: QuestRewardClaimedEvent)`
- `handleQuestStatusChanged(event: QuestStatusChangedEvent)`

### 关键映射逻辑

#### 1. 用户参与活动（CampaignParticipated）
```typescript
export function handleCampaignParticipated(event: CampaignParticipatedEvent): void {
  let campaign = Campaign.load(event.params.campaignId.toHex());
  let user = loadOrCreateUser(event.params.user);

  // 创建参与记录（幂等性检查）
  let participationId = event.params.campaignId.toHex() + "-" + event.params.user.toHex();
  let participation = CampaignParticipation.load(participationId);

  if (participation == null) {
    participation = new CampaignParticipation(participationId);
    participation.campaign = campaign.id;
    participation.user = user.id;
    participation.timestamp = event.params.timestamp;
    participation.save();

    // 更新计数器
    campaign.participantCount += 1;
    campaign.save();
  }
}
```

#### 2. 任务进度更新（QuestProgressUpdated）
```typescript
export function handleQuestProgressUpdated(event: QuestProgressUpdatedEvent): void {
  let quest = Quest.load(event.params.questId.toHex());
  let user = loadOrCreateUser(event.params.user);

  // 加载或创建进度记录
  let progressId = event.params.questId.toHex() + "-" + event.params.user.toHex();
  let progress = QuestProgress.load(progressId);

  let oldValue = BigDecimal.fromString("0");
  if (progress == null) {
    progress = new QuestProgress(progressId);
    progress.quest = quest.id;
    progress.user = user.id;
    progress.targetValue = BigDecimal.fromString(event.params.targetValue.toString());
    progress.completed = false;
    progress.rewardClaimed = false;
  } else {
    oldValue = progress.currentValue;
  }

  // 更新进度
  progress.currentValue = BigDecimal.fromString(event.params.currentValue.toString());
  progress.completionPercentage = progress.currentValue
    .div(progress.targetValue)
    .times(BigDecimal.fromString("100"));
  progress.lastUpdateTime = event.block.timestamp;
  progress.save();

  // 创建更新记录
  let updateId = progressId + "-" + event.block.timestamp.toString() + "-" + event.transaction.hash.toHex();
  let update = new QuestProgressUpdate(updateId);
  update.progress = progress.id;
  update.incrementValue = progress.currentValue.minus(oldValue);
  update.oldValue = oldValue;
  update.newValue = progress.currentValue;
  update.completedInThisUpdate = !progress.completed && progress.currentValue.ge(progress.targetValue);
  update.timestamp = event.block.timestamp;
  update.blockNumber = event.block.number;
  update.transactionHash = event.transaction.hash;
  update.save();
}
```

#### 3. 全局统计更新

在每个相关事件处理器中更新全局统计实体：

```typescript
// CampaignCreated 中
let stats = loadOrCreateCampaignStats();
stats.totalCampaigns += 1;
stats.activeCampaigns += 1;
stats.totalBudget = stats.totalBudget.plus(event.params.budgetCap);
stats.lastUpdatedAt = event.block.timestamp;
stats.save();

// QuestRewardClaimed 中
let stats = loadOrCreateQuestStats();
stats.totalRewardsClaimed = stats.totalRewardsClaimed.plus(event.params.rewardAmount);
stats.lastUpdatedAt = event.block.timestamp;
stats.save();
```

### 实体 ID 设计规范

| 实体 | ID 格式 | 示例 |
|------|---------|------|
| `Campaign` | `campaignId.toHex()` | `0x1234...` |
| `Quest` | `questId.toHex()` | `0xabcd...` |
| `CampaignParticipation` | `campaignId-userAddress` | `0x1234...-0x742d...` |
| `QuestProgress` | `questId-userAddress` | `0xabcd...-0x742d...` |
| `QuestProgressUpdate` | `progressId-timestamp-txHash` | `0xabcd...-0x742d...-1704240000-0xef12...` |
| `QuestRewardClaim` | `questId-userAddress-txHash` | `0xabcd...-0x742d...-0xef12...` |
| `CampaignBudgetChange` | `campaignId-timestamp-txHash` | `0x1234...-1704240000-0xef12...` |
| `CampaignStatusChange` | `campaignId-timestamp-txHash` | `0x1234...-1704240000-0xef12...` |
| `QuestStatusChange` | `questId-timestamp-txHash` | `0xabcd...-1704240000-0xef12...` |
| `CampaignStats` | `"campaign-stats"` | 固定值 |
| `QuestStats` | `"quest-stats"` | 固定值 |

### 数据类型转换

**Solidity → GraphQL 类型映射**：
- `uint256`（金额）→ `BigDecimal`：`BigDecimal.fromString(value.toString())`
- `uint256`（时间戳/计数）→ `BigInt`：`value`
- `address` → `Bytes`：`user.toHex()`
- `bytes32` → `Bytes`：`id.toHex()`
- `enum` → `String`：使用枚举字符串值

### 查询优化建议

1. **使用复合索引**：为常用查询字段添加索引
   ```graphql
   type Quest @entity {
     status: QuestStatus! @index
     questType: QuestType! @index
   }
   ```

2. **分页查询**：所有列表查询使用 `first` 和 `skip`
   ```graphql
   quests(first: 20, skip: 0, orderBy: createdAt, orderDirection: desc)
   ```

3. **避免深层嵌套**：限制关联查询深度 ≤ 3 层

4. **使用 @derivedFrom**：反向关系使用 `@derivedFrom` 避免数据重复存储

---

## 相关文档

- **Subgraph Schema 定义**：`/subgraph/schema.graphql`
- **GraphQL 查询示例**：`/subgraph/CAMPAIGN_QUEST_QUERIES.md`
- **合约接口定义**：
  - `/contracts/src/interfaces/ICampaign.sol`
  - `/contracts/src/interfaces/IQuest.sol`
- **合约实现**：
  - `/contracts/src/growth/Campaign.sol`
  - `/contracts/src/growth/Quest.sol`
- **测试用例**：
  - `/contracts/test/unit/Campaign.t.sol`
  - `/contracts/test/unit/Quest.t.sol`
  - `/contracts/test/integration/CampaignQuest.t.sol`

---

## Basket 串关事件

### 1. ParlayCreated

**事件签名**：
```solidity
event ParlayCreated(
    uint256 indexed parlayId,
    address indexed user,
    ParlayLeg[] legs,
    uint256 stake,
    uint256 potentialPayout,
    uint256 combinedOdds,
    uint256 penaltyBps
);

struct ParlayLeg {
    address market;
    uint256 outcomeId;
}
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `parlayId` | `uint256` | ✅ | 串关唯一标识符（自增 ID） |
| `user` | `address` | ✅ | 创建串关的用户地址 |
| `legs` | `ParlayLeg[]` | ❌ | 串关腿数组（市场地址 + 投注结果） |
| `stake` | `uint256` | ❌ | 用户投注金额（USDC，6 decimals） |
| `potentialPayout` | `uint256` | ❌ | 潜在赔付金额（USDC，6 decimals） |
| `combinedOdds` | `uint256` | ❌ | 组合赔率（基点，10000 = 1.0） |
| `penaltyBps` | `uint256` | ❌ | 相关性惩罚（基点，100 = 1%） |

**触发时机**：
- 调用 `Basket.createParlay()` 成功时
- 满足条件：
  - 腿数在 2-8 之间
  - 所有市场状态为 Open
  - 用户 USDC 余额充足
  - 通过 CorrelationGuard 验证

**Subgraph 映射**：
- 创建新的 `Basket` 实体
  - `id = parlayId.toString()`
  - `creator = user`
  - `markets = legs.map(leg => leg.market)`
  - `outcomes = legs.map(leg => leg.outcomeId)`
  - `marketCount = legs.length`
  - `totalStake = toDecimal(stake, 6)`
  - `potentialPayout = toDecimal(potentialPayout, 6)`
  - `combinedOdds = toDecimal(combinedOdds, 4)`
  - `correlationDiscount = penaltyBps`
  - `adjustedOdds = combinedOdds * (1 - penaltyBps/10000)`
  - `status = "Pending"`
  - `createdAt = block.timestamp`
- 更新用户统计

**示例值**：
```json
{
  "parlayId": "1",
  "user": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "legs": [
    {"market": "0xMarket1", "outcomeId": "0"},
    {"market": "0xMarket2", "outcomeId": "1"}
  ],
  "stake": "100000000",
  "potentialPayout": "400000000",
  "combinedOdds": "40000",
  "penaltyBps": "0"
}
```

---

### 2. ParlaySettled

**事件签名**：
```solidity
event ParlaySettled(
    uint256 indexed parlayId,
    address indexed user,
    ParlayStatus status,
    uint256 payout
);

enum ParlayStatus {
    Pending,   // 0
    Won,       // 1
    Lost,      // 2
    Cancelled  // 3 (Refunded)
}
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `parlayId` | `uint256` | ✅ | 串关唯一标识符 |
| `user` | `address` | ✅ | 串关创建者地址 |
| `status` | `ParlayStatus` | ❌ | 结算状态（0=Pending, 1=Won, 2=Lost, 3=Cancelled） |
| `payout` | `uint256` | ❌ | 实际赔付金额（USDC，6 decimals） |

**触发时机**：
- 调用 `Basket.settleParlay()` 成功时
- 前置条件：
  - 所有关联市场已 Finalized
  - 串关状态为 Pending

**Subgraph 映射**：
- 更新 `Basket` 实体
  - `status = getStatusString(status)`（Pending → Won/Lost/Refunded）
  - `actualPayout = toDecimal(payout, 6)`
  - `settledAt = block.timestamp`
- 如果赢了（status = 1）：
  - 更新 `User.totalRedeemed += actualPayout`
  - 更新 `User.netProfit = totalRedeemed - totalBetAmount`

**示例值**：
```json
{
  "parlayId": "1",
  "user": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "status": "1",
  "payout": "400000000"
}
```

---

## PlayerProps 球员道具市场事件

### 1. PlayerPropsMarketCreated

**事件签名**：
```solidity
event PlayerPropsMarketCreated(
    string indexed matchId,
    string indexed playerId,
    PropType indexed propType,
    uint256 line,
    uint256 kickoffTime
);

enum PropType {
    GOALS_OU,       // 0: 进球数 O/U
    ASSISTS_OU,     // 1: 助攻数 O/U
    SHOTS_OU,       // 2: 射门数 O/U
    YELLOW_CARD,    // 3: 是否得黄牌
    RED_CARD,       // 4: 是否得红牌
    ANYTIME_SCORER, // 5: 是否进球
    FIRST_SCORER    // 6: 首个进球者
}
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `matchId` | `string` | ✅ | 赛事唯一标识符（keccak256 哈希） |
| `playerId` | `string` | ✅ | 球员唯一标识符（keccak256 哈希） |
| `propType` | `PropType` | ✅ | 道具类型枚举 |
| `line` | `uint256` | ❌ | 盘口线（如进球数 1.5，18 decimals） |
| `kickoffTime` | `uint256` | ❌ | 开赛时间（Unix 时间戳） |

**触发时机**：
- 调用 `PlayerProps_Template.initialize()` 成功时
- 仅限 MARKET_CREATOR_ROLE 权限
- 必须在开赛前创建

**Subgraph 映射**：
- 创建新的 `Market` 实体
  - `templateId = "PLAYER_PROPS"`
  - `matchId = contract.matchId()`（从合约读取原始值）
  - `playerId = contract.playerId()`
  - `playerName = contract.playerName()`
  - `propType = getPropTypeString(propType)`
  - `line = contract.line()`
  - `homeTeam = ""` （PlayerProps 无主客队）
  - `awayTeam = ""`
  - `kickoffTime = kickoffTime`
  - `state = "Open"`
- 更新 `GlobalStats.totalMarkets += 1`

**PropType 映射表**：
| 枚举值 | 字符串 | 说明 |
|--------|--------|------|
| 0 | GOALS_OU | 进球数 O/U |
| 1 | ASSISTS_OU | 助攻数 O/U |
| 2 | SHOTS_OU | 射门数 O/U |
| 3 | YELLOW_CARD | 是否得黄牌 |
| 4 | RED_CARD | 是否得红牌 |
| 5 | ANYTIME_SCORER | 是否进球 |
| 6 | FIRST_SCORER | 首个进球者 |

**示例值**：
```json
{
  "matchId": "0x..." (keccak256 of "EPL_2024_MUN_vs_MCI"),
  "playerId": "0x..." (keccak256 of "player_haaland"),
  "propType": "0",
  "line": "1500000000000000000",
  "kickoffTime": "1731340800"
}
```

---

### 2. PlayerPropsBetPlaced

**事件签名**：
```solidity
event PlayerPropsBetPlaced(
    address indexed user,
    uint256 indexed outcomeId,
    string playerName,
    uint256 amount,
    uint256 shares
);
```

**参数说明**：
| 参数名 | 类型 | 索引 | 说明 |
|--------|------|------|------|
| `user` | `address` | ✅ | 下注用户地址 |
| `outcomeId` | `uint256` | ✅ | 投注结果 ID（0/1 或更多） |
| `playerName` | `string` | ❌ | 球员姓名（便于前端显示） |
| `amount` | `uint256` | ❌ | 下注金额（USDC，6 decimals） |
| `shares` | `uint256` | ❌ | 获得的 shares（ERC-1155 Token 数量） |

**触发时机**：
- 调用 `PlayerProps_Template.placeBet()` 成功时
- 同时会触发标准的 `BetPlaced` 事件

**Subgraph 映射**：
- 与标准 `BetPlaced` 事件处理相同
- 额外记录 `playerName` 便于前端查询
- 创建/更新 `Order` 和 `Position` 实体
- 更新市场和用户统计

**示例值**：
```json
{
  "user": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "outcomeId": "0",
  "playerName": "Erling Haaland",
  "amount": "50000000",
  "shares": "49500000"
}
```

---

## ScoreTemplate 精确比分市场事件

**注意**：ScoreTemplate 使用标准的 `MarketCreated` 和 `BetPlaced` 事件，无自定义事件。

**特殊字段**：
- `outcomeId` 编码：`HomeScore * 6 + AwayScore`
  - 例如：1-1 = 1*6+1 = 7
  - 例如：3-2 = 3*6+2 = 20
  - 5+ (AnyOtherScore) = 35

**Subgraph 处理**：
- 在 `handleMarketCreated` 中识别 `templateId = "SCORE"`
- 解码 `outcomeId` 获取实际比分
- 支持 36 个结果（0-0 到 5+）

---

## Subgraph 映射说明（M3 更新）

### 新增实体

**Basket**：
- `id`: String! (parlayId)
- `creator`: User!
- `markets`: [Bytes!]!
- `outcomes`: [Int!]!
- `marketCount`: Int!
- `totalStake`: BigDecimal!
- `potentialPayout`: BigDecimal!
- `combinedOdds`: BigDecimal!
- `correlationDiscount`: Int!
- `adjustedOdds`: BigDecimal!
- `status`: String! (Pending/Won/Lost/Refunded)
- `actualPayout`: BigDecimal
- `createdAt`: BigInt!
- `settledAt`: BigInt

### Market 实体扩展

**PlayerProps 扩展字段**：
- `playerId`: String
- `playerName`: String
- `propType`: String (GOALS_OU, ASSISTS_OU, ...)
- `firstScorerPlayerIds`: [String!]
- `firstScorerPlayerNames`: [String!]

### 事件处理器映射

| 合约 | 事件 | 处理器函数 | 文件 |
|------|------|------------|------|
| Basket | ParlayCreated | handleBasketCreated | basket.ts |
| Basket | ParlaySettled | handleBasketSettled | basket.ts |
| PlayerProps | PlayerPropsMarketCreated | handlePlayerPropsMarketCreated | market.ts |
| PlayerProps | PlayerPropsBetPlaced | handleBetPlaced (复用) | market.ts |

---

## 相关文档

- **合约源码**：
  - `/contracts/src/parlay/Basket.sol`
  - `/contracts/src/parlay/CorrelationGuard.sol`
  - `/contracts/src/templates/PlayerProps_Template.sol`
  - `/contracts/src/templates/ScoreTemplate.sol`
  - `/contracts/src/pricing/LMSR.sol`
- **测试用例**：
  - `/contracts/test/integration/BasketIntegration.t.sol`
  - `/contracts/test/unit/PlayerProps.t.sol`
  - `/contracts/test/integration/ScoreTemplate_LMSR_Integration.t.sol`
- **Subgraph**：
  - `/subgraph/src/basket.ts`
  - `/subgraph/src/market.ts`
  - `/subgraph/schema.graphql`
  - `/subgraph/M3_GRAPHQL_QUERIES.md`

---

**最后更新时间**：2025-11-08
**维护者**：PitchOne 开发团队