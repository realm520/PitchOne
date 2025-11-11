# M3 Subgraph GraphQL 查询示例

本文档提供 M3 新增功能（Basket 串关、PlayerProps 球员道具市场）的 GraphQL 查询示例。

## 目录
- [Basket 串关查询](#basket-串关查询)
- [PlayerProps 球员道具市场查询](#playerprops-球员道具市场查询)
- [组合查询](#组合查询)
- [实时统计查询](#实时统计查询)

---

## Basket 串关查询

### 1. 查询所有串关

```graphql
query AllBaskets {
  baskets(first: 10, orderBy: createdAt, orderDirection: desc) {
    id
    creator {
      id
      totalBetAmount
    }
    markets
    outcomes
    marketCount
    totalStake
    potentialPayout
    combinedOdds
    correlationDiscount
    adjustedOdds
    status
    actualPayout
    createdAt
    settledAt
    blockNumber
    transactionHash
  }
}
```

**说明**：
- `markets`: 串关包含的市场地址数组
- `outcomes`: 每个市场对应的投注结果
- `marketCount`: 串关腿数（2-8）
- `combinedOdds`: 组合赔率（基点，10000 = 1.0）
- `correlationDiscount`: 相关性折扣（基点，100 = 1%）
- `adjustedOdds`: 调整后赔率（考虑相关性惩罚）
- `status`: 串关状态（Pending, Won, Lost, Refunded）

### 2. 查询用户的串关历史

```graphql
query UserBaskets($userAddress: Bytes!) {
  baskets(
    where: { creator: $userAddress }
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    markets
    outcomes
    totalStake
    potentialPayout
    adjustedOdds
    status
    actualPayout
    createdAt
    settledAt
  }
}
```

**变量示例**：
```json
{
  "userAddress": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
}
```

### 3. 查询特定状态的串关

```graphql
query BasketsByStatus($status: String!) {
  baskets(
    where: { status: $status }
    first: 20
    orderBy: totalStake
    orderDirection: desc
  ) {
    id
    creator {
      id
    }
    marketCount
    totalStake
    potentialPayout
    adjustedOdds
    createdAt
  }
}
```

**变量示例** (查询待结算的串关):
```json
{
  "status": "Pending"
}
```

### 4. 查询包含特定市场的串关

```graphql
query BasketsContainingMarket($marketAddress: Bytes!) {
  baskets(where: { markets_contains: [$marketAddress] }) {
    id
    creator {
      id
    }
    markets
    outcomes
    totalStake
    potentialPayout
    status
  }
}
```

### 5. 查询高倍率串关（潜在收益 > 10x）

```graphql
query HighOddsBaskets {
  baskets(
    where: { adjustedOdds_gt: "100000" }  # 10.0 = 100000 基点
    orderBy: adjustedOdds
    orderDirection: desc
  ) {
    id
    creator {
      id
    }
    marketCount
    totalStake
    potentialPayout
    combinedOdds
    correlationDiscount
    adjustedOdds
    status
  }
}
```

### 6. 查询串关统计（聚合查询）

```graphql
query BasketStats {
  globalStats(id: "global") {
    totalVolume
    totalRedeemed
  }

  # 计算串关相关统计需要在客户端聚合
  baskets(first: 1000) {
    id
    totalStake
    actualPayout
    status
  }
}
```

---

## PlayerProps 球员道具市场查询

### 1. 查询所有球员道具市场

```graphql
query AllPlayerPropsMarkets {
  markets(
    where: { templateId: "PLAYER_PROPS" }
    first: 20
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    matchId
    playerId
    playerName
    propType
    line
    state
    totalVolume
    uniqueBettors
    kickoffTime
    createdAt
  }
}
```

**说明**：
- `propType`: 道具类型（GOALS_OU, ASSISTS_OU, SHOTS_OU, YELLOW_CARD, RED_CARD, ANYTIME_SCORER, FIRST_SCORER）
- `line`: 盘口线（如进球数 O/U 0.5、1.5 等）
- `playerId`: 球员唯一标识符
- `playerName`: 球员姓名

### 2. 查询特定球员的所有市场

```graphql
query PlayerMarkets($playerId: String!) {
  markets(
    where: {
      templateId: "PLAYER_PROPS"
      playerId: $playerId
    }
    orderBy: kickoffTime
    orderDirection: desc
  ) {
    id
    matchId
    playerName
    propType
    line
    state
    totalVolume
    uniqueBettors
    kickoffTime
  }
}
```

**变量示例**：
```json
{
  "playerId": "player_123_haaland"
}
```

### 3. 查询特定道具类型的市场

```graphql
query PropTypeMarkets($propType: String!) {
  markets(
    where: {
      templateId: "PLAYER_PROPS"
      propType: $propType
      state: "Open"
    }
    first: 50
  ) {
    id
    matchId
    playerId
    playerName
    line
    totalVolume
    kickoffTime
  }
}
```

**变量示例** (查询进球数 O/U 市场):
```json
{
  "propType": "GOALS_OU"
}
```

### 4. 查询用户在球员道具市场的头寸

```graphql
query UserPlayerPropsPositions($userAddress: Bytes!) {
  positions(
    where: {
      owner: $userAddress
      balance_gt: "0"
    }
  ) {
    id
    market {
      id
      templateId
      playerId
      playerName
      propType
      line
      state
    }
    outcome
    balance
    averageCost
    lastUpdatedAt
  }
}
```

### 5. 查询热门球员道具市场（按交易量排序）

```graphql
query TopPlayerPropsMarkets {
  markets(
    where: { templateId: "PLAYER_PROPS" }
    first: 10
    orderBy: totalVolume
    orderDirection: desc
  ) {
    id
    playerId
    playerName
    propType
    line
    totalVolume
    uniqueBettors
    feeAccrued
    state
  }
}
```

### 6. 查询 First Scorer 市场（含球员列表）

```graphql
query FirstScorerMarkets {
  markets(
    where: {
      templateId: "PLAYER_PROPS"
      propType: "FIRST_SCORER"
      state: "Open"
    }
  ) {
    id
    matchId
    playerName  # 主选球员
    firstScorerPlayerIds
    firstScorerPlayerNames
    totalVolume
    kickoffTime
  }
}
```

**说明**：
- `firstScorerPlayerIds`: 所有候选首发球员的 ID 数组
- `firstScorerPlayerNames`: 对应的球员姓名数组
- 注意：目前这两个字段为 null（合约未提供 getter 方法）

---

## 组合查询

### 1. 查询用户的完整投注画像

```graphql
query UserProfile($userAddress: Bytes!) {
  user(id: $userAddress) {
    id
    totalBetAmount
    totalRedeemed
    netProfit
    totalBets
    marketsParticipated
    firstBetAt
    lastBetAt
  }

  # 用户的串关
  userBaskets: baskets(
    where: { creator: $userAddress }
    first: 5
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    totalStake
    potentialPayout
    status
    createdAt
  }

  # 用户的头寸（包括球员道具）
  positions(
    where: {
      owner: $userAddress
      balance_gt: "0"
    }
    first: 10
  ) {
    id
    market {
      id
      templateId
      playerId
      playerName
      state
    }
    outcome
    balance
  }

  # 用户的订单历史
  orders(
    where: { user: $userAddress }
    first: 10
    orderBy: timestamp
    orderDirection: desc
  ) {
    id
    market {
      id
      templateId
    }
    amount
    outcome
    timestamp
  }
}
```

### 2. 查询赛事的所有市场（含球员道具）

```graphql
query MatchAllMarkets($matchId: String!) {
  # 主市场（WDL, OU, OddEven 等）
  mainMarkets: markets(
    where: { matchId: $matchId, templateId_not: "PLAYER_PROPS" }
  ) {
    id
    templateId
    homeTeam
    awayTeam
    line
    state
    totalVolume
  }

  # 球员道具市场
  playerPropsMarkets: markets(
    where: {
      matchId: $matchId
      templateId: "PLAYER_PROPS"
    }
  ) {
    id
    playerId
    playerName
    propType
    line
    totalVolume
  }
}
```

---

## 实时统计查询

### 1. 全局统计（含 M3 数据）

```graphql
query GlobalStatistics {
  globalStats(id: "global") {
    totalMarkets
    activeMarkets
    resolvedMarkets
    totalVolume
    totalFees
    totalRedeemed
    lastUpdatedAt
  }

  # 串关数量统计（需客户端聚合）
  pendingBaskets: baskets(where: { status: "Pending" }) {
    id
  }
  wonBaskets: baskets(where: { status: "Won" }) {
    id
  }
  lostBaskets: baskets(where: { status: "Lost" }) {
    id
  }

  # 球员道具市场数量
  playerPropsMarkets: markets(where: { templateId: "PLAYER_PROPS" }) {
    id
  }
}
```

### 2. 市场类型分布

```graphql
query MarketTypeDistribution {
  wdlMarkets: markets(where: { templateId: "WDL" }) {
    id
    totalVolume
  }
  ouMarkets: markets(where: { templateId_in: ["OU", "OU_MULTI"] }) {
    id
    totalVolume
  }
  oddEvenMarkets: markets(where: { templateId: "OddEven" }) {
    id
    totalVolume
  }
  playerPropsMarkets: markets(where: { templateId: "PLAYER_PROPS" }) {
    id
    totalVolume
  }
}
```

### 3. 最近 24 小时活跃度

```graphql
query Recent24HoursActivity($timestamp24hAgo: BigInt!) {
  # 最近创建的市场
  recentMarkets: markets(
    where: { createdAt_gt: $timestamp24hAgo }
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    templateId
    totalVolume
    createdAt
  }

  # 最近的串关
  recentBaskets: baskets(
    where: { createdAt_gt: $timestamp24hAgo }
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    totalStake
    marketCount
    createdAt
  }

  # 最近的订单
  recentOrders: orders(
    where: { timestamp_gt: $timestamp24hAgo }
    orderBy: timestamp
    orderDirection: desc
    first: 100
  ) {
    id
    amount
    timestamp
  }
}
```

**变量示例**：
```json
{
  "timestamp24hAgo": "1699200000"
}
```

---

## 高级查询技巧

### 1. 分页查询

```graphql
query PaginatedBaskets($first: Int!, $skip: Int!) {
  baskets(
    first: $first
    skip: $skip
    orderBy: createdAt
    orderDirection: desc
  ) {
    id
    totalStake
    status
    createdAt
  }
}
```

### 2. 过滤条件组合

```graphql
query AdvancedBasketFilter(
  $minStake: BigDecimal!
  $minMarketCount: Int!
  $status: String!
) {
  baskets(
    where: {
      totalStake_gte: $minStake
      marketCount_gte: $minMarketCount
      status: $status
    }
    orderBy: potentialPayout
    orderDirection: desc
  ) {
    id
    totalStake
    potentialPayout
    marketCount
    adjustedOdds
  }
}
```

### 3. 全文搜索（球员姓名）

```graphql
query SearchPlayerByName($nameFragment: String!) {
  markets(
    where: {
      templateId: "PLAYER_PROPS"
      playerName_contains: $nameFragment
    }
  ) {
    id
    playerName
    propType
    totalVolume
  }
}
```

---

## 查询性能优化建议

1. **使用 `first` 限制返回数量**：避免一次查询过多数据
2. **按索引字段过滤**：优先使用 `id`, `creator`, `market` 等索引字段
3. **避免深层嵌套**：减少关联查询深度
4. **使用 `skip` + `first` 分页**：大数据集分批查询
5. **缓存结果**：客户端缓存不常变的数据（如已结算的串关）

---

## GraphQL Playground 访问

本地开发环境访问：
```
http://localhost:8000/subgraphs/name/pitchone-local/graphql
```

测试网/主网访问（部署后）：
```
https://api.thegraph.com/subgraphs/name/<github-username>/pitchone
```

---

## 相关文档

- [Subgraph Schema](./schema.graphql)
- [Event Dictionary](../docs/模块接口事件参数/EVENT_DICTIONARY.md)
- [M3 Subgraph Status](./M3_SUBGRAPH_STATUS.md)
- [The Graph Query API 文档](https://thegraph.com/docs/en/querying/graphql-api/)
