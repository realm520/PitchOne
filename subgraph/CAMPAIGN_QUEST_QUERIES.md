# Campaign & Quest GraphQL 查询示例

本文档提供 Campaign 和 Quest 相关的 GraphQL 查询示例。

## 📋 目录

- [Campaign 查询](#campaign-查询)
- [Quest 查询](#quest-查询)
- [用户相关查询](#用户相关查询)
- [统计查询](#统计查询)
- [复杂组合查询](#复杂组合查询)

## Campaign 查询

### 1. 查询所有活跃的 Campaign

```graphql
query ActiveCampaigns {
  campaigns(
    where: { status: Active }
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    name
    budgetCap
    spentAmount
    remainingBudget
    startTime
    endTime
    participantCount
    status
    quests {
      id
      name
      questType
    }
  }
}
```

### 2. 查询特定 Campaign 的详细信息

```graphql
query CampaignDetails($campaignId: ID!) {
  campaign(id: $campaignId) {
    id
    name
    ruleHash
    budgetCap
    spentAmount
    remainingBudget
    startTime
    endTime
    status
    participantCount
    createdAt
    updatedAt
    creator

    # 关联的任务
    quests {
      id
      name
      questType
      rewardAmount
      targetValue
      completionCount
      status
    }

    # 参与记录
    participations(first: 100, orderBy: timestamp, orderDirection: desc) {
      user {
        id
      }
      timestamp
    }

    # 预算变更历史
    budgetChanges(orderBy: timestamp, orderDirection: desc) {
      changeType
      amount
      oldValue
      newValue
      timestamp
    }

    # 状态变更历史
    statusChanges(orderBy: timestamp, orderDirection: desc) {
      oldStatus
      newStatus
      timestamp
    }
  }
}
```

### 3. 查询即将结束的 Campaign

```graphql
query EndingSoonCampaigns($currentTime: BigInt!) {
  campaigns(
    where: {
      status: Active
      endTime_gt: $currentTime
      endTime_lt: "1735689600" # currentTime + 7 days
    }
    orderBy: endTime
    orderDirection: asc
    first: 10
  ) {
    id
    name
    endTime
    remainingBudget
    participantCount
  }
}
```

### 4. 查询预算即将耗尽的 Campaign

```graphql
query LowBudgetCampaigns {
  campaigns(
    where: { status: Active }
  ) {
    id
    name
    budgetCap
    spentAmount
    remainingBudget
    participantCount
  }
}
```

## Quest 查询

### 1. 查询所有活跃的 Quest

```graphql
query ActiveQuests {
  quests(
    where: { status: Active }
    orderBy: rewardAmount
    orderDirection: desc
  ) {
    id
    name
    questType
    rewardAmount
    targetValue
    startTime
    endTime
    completionCount
    campaign {
      id
      name
      status
    }
  }
}
```

### 2. 按任务类型查询 Quest

```graphql
query QuestsByType($questType: QuestType!) {
  quests(
    where: {
      questType: $questType
      status: Active
    }
    orderBy: rewardAmount
    orderDirection: desc
  ) {
    id
    name
    rewardAmount
    targetValue
    completionCount
    campaign {
      id
      name
    }
  }
}
```

示例变量:
```json
{
  "questType": "FIRST_BET"
}
```

可用的 questType: `FIRST_BET`, `CONSECUTIVE_BETS`, `REFERRAL`, `VOLUME`, `WIN_STREAK`

### 3. 查询特定 Quest 的详细信息

```graphql
query QuestDetails($questId: ID!) {
  quest(id: $questId) {
    id
    name
    questType
    rewardAmount
    targetValue
    startTime
    endTime
    status
    completionCount
    createdAt
    updatedAt

    campaign {
      id
      name
      status
      remainingBudget
    }

    # 用户进度（前100名）
    progresses(
      first: 100
      orderBy: completionPercentage
      orderDirection: desc
    ) {
      user {
        id
      }
      currentValue
      targetValue
      completionPercentage
      completed
      rewardClaimed
      lastUpdateTime
    }

    # 奖励领取记录
    rewardClaims(first: 100, orderBy: timestamp, orderDirection: desc) {
      user {
        id
      }
      rewardAmount
      timestamp
    }

    # 状态变更历史
    statusChanges(orderBy: timestamp, orderDirection: desc) {
      oldStatus
      newStatus
      timestamp
    }
  }
}
```

### 4. 查询高奖励的 Quest

```graphql
query HighRewardQuests($minReward: BigDecimal!) {
  quests(
    where: {
      status: Active
      rewardAmount_gte: $minReward
    }
    orderBy: rewardAmount
    orderDirection: desc
    first: 20
  ) {
    id
    name
    questType
    rewardAmount
    targetValue
    completionCount
    campaign {
      name
    }
  }
}
```

## 用户相关查询

### 1. 查询用户参与的所有 Campaign

```graphql
query UserCampaigns($userAddress: ID!) {
  user(id: $userAddress) {
    id
    campaignParticipations {
      campaign {
        id
        name
        status
        budgetCap
        remainingBudget
        endTime
      }
      timestamp
    }
  }
}
```

### 2. 查询用户的所有 Quest 进度

```graphql
query UserQuestProgresses($userAddress: ID!) {
  user(id: $userAddress) {
    id
    questProgresses(orderBy: lastUpdateTime, orderDirection: desc) {
      quest {
        id
        name
        questType
        rewardAmount
        targetValue
        status
      }
      currentValue
      targetValue
      completionPercentage
      completed
      completedAt
      rewardClaimed
      rewardClaimedAt
      lastUpdateTime

      # 进度更新历史
      updates(first: 10, orderBy: timestamp, orderDirection: desc) {
        incrementValue
        oldValue
        newValue
        completedInThisUpdate
        timestamp
      }
    }
  }
}
```

### 3. 查询用户已完成但未领取的 Quest

```graphql
query UserUnclaimedQuests($userAddress: ID!) {
  questProgresses(
    where: {
      user: $userAddress
      completed: true
      rewardClaimed: false
    }
  ) {
    quest {
      id
      name
      questType
      rewardAmount
      status
      endTime
      campaign {
        name
        status
        remainingBudget
      }
    }
    currentValue
    completedAt
  }
}
```

### 4. 查询用户已领取的所有 Quest 奖励

```graphql
query UserQuestRewards($userAddress: ID!) {
  user(id: $userAddress) {
    id
    questRewardsClaimed(orderBy: timestamp, orderDirection: desc) {
      quest {
        id
        name
        questType
      }
      rewardAmount
      timestamp
      transactionHash
    }
  }
}
```

### 5. 查询用户的 Quest 进度详情（包含更新历史）

```graphql
query UserQuestProgressDetails($userAddress: ID!, $questId: ID!) {
  questProgress(id: $questId) {
    quest {
      id
      name
      questType
      rewardAmount
      targetValue
    }
    user {
      id
    }
    currentValue
    targetValue
    completionPercentage
    completed
    completedAt
    rewardClaimed
    rewardClaimedAt

    # 所有进度更新记录
    updates(orderBy: timestamp, orderDirection: desc) {
      incrementValue
      oldValue
      newValue
      completedInThisUpdate
      timestamp
      blockNumber
      transactionHash
    }
  }
}
```

## 统计查询

### 1. 查询 Campaign 全局统计

```graphql
query CampaignGlobalStats {
  campaignStats(id: "campaign-stats") {
    totalCampaigns
    activeCampaigns
    pausedCampaigns
    endedCampaigns
    totalBudget
    totalSpent
    totalParticipations
    uniqueParticipants
    lastUpdatedAt
  }
}
```

### 2. 查询 Quest 全局统计

```graphql
query QuestGlobalStats {
  questStats(id: "quest-stats") {
    totalQuests
    activeQuests
    pausedQuests
    endedQuests
    totalRewards
    totalRewardsClaimed
    totalCompletions
    uniqueCompletors

    # 各类型任务统计
    firstBetQuests
    consecutiveBetsQuests
    referralQuests
    volumeQuests
    winStreakQuests

    lastUpdatedAt
  }
}
```

### 3. 查询 Campaign 排行榜（按参与人数）

```graphql
query TopCampaignsByParticipants {
  campaigns(
    orderBy: participantCount
    orderDirection: desc
    first: 10
  ) {
    id
    name
    participantCount
    budgetCap
    spentAmount
    status
  }
}
```

### 4. 查询 Quest 排行榜（按完成人数）

```graphql
query TopQuestsByCompletions {
  quests(
    orderBy: completionCount
    orderDirection: desc
    first: 10
  ) {
    id
    name
    questType
    completionCount
    rewardAmount
    campaign {
      name
    }
  }
}
```

## 复杂组合查询

### 1. Campaign 完整概览（带统计）

```graphql
query CampaignOverview($campaignId: ID!) {
  campaign(id: $campaignId) {
    id
    name
    ruleHash
    budgetCap
    spentAmount
    remainingBudget
    startTime
    endTime
    status
    participantCount

    quests {
      id
      name
      questType
      rewardAmount
      completionCount
      status

      # Quest 完成率最高的前10名用户
      progresses(
        first: 10
        where: { completed: true }
        orderBy: completedAt
        orderDirection: asc
      ) {
        user {
          id
        }
        completedAt
        rewardClaimed
      }
    }

    # 最近的参与者
    participations(first: 20, orderBy: timestamp, orderDirection: desc) {
      user {
        id
      }
      timestamp
    }
  }
}
```

### 2. 用户活动总览

```graphql
query UserActivityOverview($userAddress: ID!) {
  user(id: $userAddress) {
    id

    # Campaign 参与
    campaignParticipations {
      campaign {
        id
        name
        status
        endTime
      }
      timestamp
    }

    # Quest 进度汇总
    questProgresses {
      quest {
        id
        name
        questType
        rewardAmount
        status
      }
      currentValue
      targetValue
      completionPercentage
      completed
      rewardClaimed
    }

    # 已领取的 Quest 奖励总额
    questRewardsClaimed {
      rewardAmount
      timestamp
    }
  }
}
```

### 3. 实时活动仪表盘

```graphql
query DashboardData($currentTime: BigInt!) {
  # 活跃 Campaign
  activeCampaigns: campaigns(
    where: { status: Active }
    first: 5
    orderBy: participantCount
    orderDirection: desc
  ) {
    id
    name
    participantCount
    remainingBudget
    endTime
  }

  # 活跃 Quest
  activeQuests: quests(
    where: { status: Active }
    first: 5
    orderBy: completionCount
    orderDirection: desc
  ) {
    id
    name
    questType
    completionCount
    rewardAmount
  }

  # 全局统计
  campaignStats(id: "campaign-stats") {
    totalCampaigns
    activeCampaigns
    totalParticipations
  }

  questStats(id: "quest-stats") {
    totalQuests
    activeQuests
    totalCompletions
    totalRewardsClaimed
  }
}
```

### 4. 热门 Quest 和用户参与度

```graphql
query TrendingQuests {
  quests(
    where: { status: Active }
    first: 20
    orderBy: completionCount
    orderDirection: desc
  ) {
    id
    name
    questType
    rewardAmount
    targetValue
    completionCount

    campaign {
      id
      name
      remainingBudget
    }

    # 最近完成的用户
    progresses(
      first: 5
      where: { completed: true }
      orderBy: completedAt
      orderDirection: desc
    ) {
      user {
        id
      }
      completedAt
      rewardClaimed
    }
  }
}
```

## 分页查询示例

### 1. Campaign 列表分页

```graphql
query CampaignsPaginated($first: Int!, $skip: Int!) {
  campaigns(
    first: $first
    skip: $skip
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    name
    status
    participantCount
    remainingBudget
    createdAt
  }
}
```

示例变量:
```json
{
  "first": 10,
  "skip": 0
}
```

### 2. Quest 进度列表分页

```graphql
query QuestProgressesPaginated($questId: ID!, $first: Int!, $skip: Int!) {
  quest(id: $questId) {
    progresses(
      first: $first
      skip: $skip
      orderBy: currentValue
      orderDirection: desc
    ) {
      user {
        id
      }
      currentValue
      completionPercentage
      completed
      lastUpdateTime
    }
  }
}
```

## 筛选器示例

### 1. 按预算范围筛选 Campaign

```graphql
query CampaignsByBudgetRange($minBudget: BigDecimal!, $maxBudget: BigDecimal!) {
  campaigns(
    where: {
      budgetCap_gte: $minBudget
      budgetCap_lte: $maxBudget
      status: Active
    }
  ) {
    id
    name
    budgetCap
    spentAmount
    participantCount
  }
}
```

### 2. 按奖励金额筛选 Quest

```graphql
query QuestsByRewardRange($minReward: BigDecimal!, $maxReward: BigDecimal!) {
  quests(
    where: {
      rewardAmount_gte: $minReward
      rewardAmount_lte: $maxReward
      status: Active
    }
    orderBy: rewardAmount
    orderDirection: desc
  ) {
    id
    name
    questType
    rewardAmount
    completionCount
  }
}
```

### 3. 按时间范围筛选

```graphql
query CampaignsInTimeRange($startAfter: BigInt!, $endBefore: BigInt!) {
  campaigns(
    where: {
      startTime_gte: $startAfter
      endTime_lte: $endBefore
    }
    orderBy: startTime
  ) {
    id
    name
    startTime
    endTime
    status
  }
}
```

## 聚合查询示例

### 1. 计算用户的总 Quest 奖励

```graphql
query UserTotalQuestRewards($userAddress: ID!) {
  user(id: $userAddress) {
    questRewardsClaimed {
      rewardAmount
    }
  }
}
```

前端计算总和:
```javascript
const total = data.user.questRewardsClaimed.reduce(
  (sum, claim) => sum + parseFloat(claim.rewardAmount),
  0
);
```

### 2. 统计 Campaign 的总支出

```graphql
query CampaignTotalSpending {
  campaigns {
    id
    name
    spentAmount
  }
}
```

## 实时订阅（Subscription）

如果 Subgraph 支持订阅，可以使用以下查询:

### 1. 订阅新的 Quest 完成

```graphql
subscription OnQuestCompleted {
  questProgresses(
    where: { completed: true }
    orderBy: completedAt
    orderDirection: desc
  ) {
    quest {
      id
      name
    }
    user {
      id
    }
    completedAt
  }
}
```

### 2. 订阅 Campaign 状态变更

```graphql
subscription OnCampaignStatusChange {
  campaignStatusChanges(orderBy: timestamp, orderDirection: desc) {
    campaign {
      id
      name
    }
    oldStatus
    newStatus
    timestamp
  }
}
```
