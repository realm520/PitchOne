import { GraphQLClient } from 'graphql-request';

// Subgraph IPFS Hash（最新部署版本 v0.4.0）
const SUBGRAPH_HASH = 'QmZFaPpEi8H6uAsDxWfENn87X4jV5tWNSfLJN8svMSkCdY';

// Subgraph Name（使用名称更稳定，不依赖 IPFS hash）
const SUBGRAPH_NAME = 'pitchone-local';

// 获取 Subgraph URL（支持环境检测）
function getSubgraphURL(): string {
  // 优先使用环境变量
  if (process.env.NEXT_PUBLIC_SUBGRAPH_URL) {
    return process.env.NEXT_PUBLIC_SUBGRAPH_URL;
  }

  // 浏览器环境：使用 Subgraph Name 更稳定
  if (typeof window !== 'undefined') {
    const url = `${window.location.origin}/api/subgraph/subgraphs/name/${SUBGRAPH_NAME}`;
    console.log('[GraphQL Client] 浏览器环境，使用代理 URL:', url);
    return url;
  }

  // 服务端环境：直接访问 Graph Node（无 CORS 限制）
  const url = `http://localhost:8000/subgraphs/name/${SUBGRAPH_NAME}`;
  console.log('[GraphQL Client] 服务端环境，直接访问:', url);
  return url;
}

// 创建 GraphQL Client（延迟初始化以确保在正确环境中获取 URL）
let _client: GraphQLClient | null = null;

function getGraphQLClient(): GraphQLClient {
  if (!_client) {
    const url = getSubgraphURL();
    console.log('[GraphQL Client] 初始化 GraphQL Client，URL:', url);
    _client = new GraphQLClient(url, {
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }
  return _client;
}

// 导出 client（使用 getter 以支持延迟初始化）
export const graphqlClient = new Proxy({} as GraphQLClient, {
  get(target, prop) {
    const client = getGraphQLClient();
    const value = (client as any)[prop];
    return typeof value === 'function' ? value.bind(client) : value;
  }
});

// GraphQL 查询定义（带状态过滤）
export const MARKETS_QUERY_FILTERED = `
  query Markets($first: Int, $skip: Int, $status: [MarketState!]!) {
    markets(
      first: $first
      skip: $skip
      where: { state_in: $status }
      orderBy: createdAt
      orderDirection: desc
    ) {
      id
      templateId
      matchId
      homeTeam
      awayTeam
      kickoffTime
      state
      totalVolume
      feeAccrued
      lpLiquidity
      uniqueBettors
      createdAt
      lockedAt
      resolvedAt
      line
      lines
    }
  }
`;

// GraphQL 查询定义（不带状态过滤）
export const MARKETS_QUERY = `
  query Markets($first: Int, $skip: Int) {
    markets(
      first: $first
      skip: $skip
      orderBy: createdAt
      orderDirection: desc
    ) {
      id
      templateId
      matchId
      homeTeam
      awayTeam
      kickoffTime
      state
      totalVolume
      feeAccrued
      lpLiquidity
      uniqueBettors
      createdAt
      lockedAt
      resolvedAt
      line
      lines
    }
  }
`;

export const MARKET_QUERY = `
  query Market($id: ID!) {
    market(id: $id) {
      id
      templateId
      matchId
      homeTeam
      awayTeam
      kickoffTime
      state
      winnerOutcome
      totalVolume
      feeAccrued
      lpLiquidity
      uniqueBettors
      createdAt
      lockedAt
      resolvedAt
      finalizedAt
      line
      lines
    }
  }
`;

export const USER_POSITIONS_QUERY = `
  query UserPositions($userId: ID!) {
    positions(
      where: { owner: $userId, balance_gt: "0" }
      orderBy: lastUpdatedAt
      orderDirection: desc
    ) {
      id
      owner {
        id
      }
      market {
        id
        templateId
        matchId
        state
        winnerOutcome
      }
      outcome
      balance
      averageCost
      totalInvested
      lastUpdatedAt
    }
  }
`;

export const USER_ORDERS_QUERY = `
  query UserOrders($userId: ID!, $first: Int) {
    orders(
      where: { user: $userId }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      user {
        id
      }
      market {
        id
        templateId
        matchId
        state
      }
      outcome
      amount
      shares
      fee
      price
      timestamp
      transactionHash
    }
  }
`;

export const MARKET_ORDERS_QUERY = `
  query MarketOrders($userId: ID!, $marketId: ID!, $first: Int) {
    orders(
      where: { user: $userId, market: $marketId }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      user {
        id
      }
      market {
        id
        templateId
        matchId
        state
      }
      outcome
      amount
      shares
      fee
      price
      timestamp
      transactionHash
    }
  }
`;

export const MARKET_ALL_ORDERS_QUERY = `
  query MarketAllOrders($marketId: ID!, $first: Int) {
    orders(
      where: { market: $marketId }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      user {
        id
      }
      outcome
      amount
      shares
      fee
      price
      timestamp
      transactionHash
    }
  }
`;

// ============================================
// 管理端查询（Dashboard Statistics）
// ============================================

export const GLOBAL_STATS_QUERY = `
  query GlobalStats {
    globalStats(id: "global") {
      id
      totalMarkets
      totalUsers
      totalVolume
      totalFees
      totalRedeemed
      activeMarkets
    }
  }
`;

export const RECENT_ORDERS_QUERY = `
  query RecentOrders($first: Int) {
    orders(
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      user {
        id
      }
      market {
        id
        templateId
        matchId
        state
      }
      outcome
      amount
      shares
      fee
      price
      timestamp
      transactionHash
    }
  }
`;

export const MARKET_STATS_QUERY = `
  query MarketStats {
    markets(first: 1000, orderBy: createdAt, orderDirection: desc) {
      id
      state
      totalVolume
      createdAt
    }
  }
`;

export const DAILY_VOLUME_QUERY = `
  query DailyVolume($startTime: BigInt!) {
    orders(
      where: { timestamp_gte: $startTime }
      orderBy: timestamp
      orderDirection: asc
    ) {
      amount
      timestamp
    }
  }
`;

// ============================================
// Oracle 提案查询
// ============================================

export const ORACLE_PROPOSALS_QUERY = `
  query OracleProposals($first: Int, $skip: Int) {
    oracleProposals(
      first: $first
      skip: $skip
      orderBy: proposedAt
      orderDirection: desc
    ) {
      id
      oracle
      market {
        id
        templateId
        matchId
        state
      }
      proposer
      result
      bond
      proposedAt
      disputed
      disputer
      disputedAt
      finalized
      finalizedAt
      finalResult
    }
  }
`;

export const ORACLE_PROPOSAL_QUERY = `
  query OracleProposal($id: ID!) {
    oracleProposal(id: $id) {
      id
      oracle
      market {
        id
        templateId
        matchId
        state
        createdAt
      }
      proposer
      result
      bond
      proposedAt
      disputed
      disputer
      disputedAt
      finalized
      finalizedAt
      finalResult
    }
  }
`;

// ============================================
// Campaign/Quest 查询
// ============================================

export const CAMPAIGNS_QUERY = `
  query Campaigns($first: Int, $skip: Int) {
    campaigns(
      first: $first
      skip: $skip
      orderBy: createdAt
      orderDirection: desc
    ) {
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
    }
  }
`;

export const QUESTS_QUERY = `
  query Quests($first: Int, $skip: Int) {
    quests(
      first: $first
      skip: $skip
      orderBy: createdAt
      orderDirection: desc
    ) {
      id
      campaign {
        id
        name
        status
      }
      questType
      name
      rewardAmount
      targetValue
      startTime
      endTime
      status
      completionCount
      createdAt
      updatedAt
      creator
    }
  }
`;

export const CAMPAIGN_STATS_QUERY = `
  query CampaignStats {
    campaignStats(id: "campaign-stats") {
      id
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
`;

export const QUEST_STATS_QUERY = `
  query QuestStats {
    questStats(id: "quest-stats") {
      id
      totalQuests
      activeQuests
      pausedQuests
      endedQuests
      totalRewards
      totalRewardsClaimed
      totalCompletions
      uniqueCompletors
      firstBetQuests
      consecutiveBetsQuests
      referralQuests
      volumeQuests
      winStreakQuests
      lastUpdatedAt
    }
  }
`;
