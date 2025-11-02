import { GraphQLClient } from 'graphql-request';

// Subgraph URL (本地开发环境)
const SUBGRAPH_URL = process.env.NEXT_PUBLIC_SUBGRAPH_URL || 'http://localhost:8000/subgraphs/name/pitchone';

// 创建 GraphQL Client
export const graphqlClient = new GraphQLClient(SUBGRAPH_URL, {
  headers: {
    'Content-Type': 'application/json',
  },
});

// GraphQL 查询定义
export const MARKETS_QUERY = `
  query Markets($status: [MarketStatus!], $first: Int, $skip: Int) {
    markets(
      where: { status_in: $status }
      first: $first
      skip: $skip
      orderBy: kickoffTime
      orderDirection: desc
    ) {
      id
      event
      homeTeam
      awayTeam
      kickoffTime
      status
      template {
        type
      }
      totalVolume
      createdAt
    }
  }
`;

export const MARKET_QUERY = `
  query Market($id: ID!) {
    market(id: $id) {
      id
      event
      homeTeam
      awayTeam
      kickoffTime
      status
      template {
        type
      }
      winningOutcome
      totalVolume
      outcomeCount
      createdAt
      resolvedAt
    }
  }
`;

export const USER_POSITIONS_QUERY = `
  query UserPositions($user: Bytes!) {
    positions(
      where: { owner: $user, balance_gt: "0" }
      orderBy: createdAt
      orderDirection: desc
    ) {
      id
      market {
        id
        event
        homeTeam
        awayTeam
        status
        winningOutcome
      }
      outcome
      balance
      createdAt
    }
  }
`;

export const USER_ORDERS_QUERY = `
  query UserOrders($user: Bytes!, $first: Int) {
    orders(
      where: { user: $user }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      market {
        id
        event
      }
      outcome
      amount
      shares
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
      totalOrders
      totalUsers
      totalVolume
      totalFees
      updatedAt
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
      user
      market {
        id
        event
        homeTeam
        awayTeam
      }
      outcome
      amount
      shares
      timestamp
      transactionHash
    }
  }
`;

export const MARKET_STATS_QUERY = `
  query MarketStats {
    markets(first: 1000, orderBy: createdAt, orderDirection: desc) {
      id
      status
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
        event
        homeTeam
        awayTeam
        status
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
        event
        homeTeam
        awayTeam
        status
        kickoffTime
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
