import { GraphQLClient } from 'graphql-request';

// Subgraph URL (本地开发环境)
const SUBGRAPH_URL = process.env.NEXT_PUBLIC_SUBGRAPH_URL || 'http://localhost:8010/subgraphs/name/pitchone-local';

// 创建 GraphQL Client
export const graphqlClient = new GraphQLClient(SUBGRAPH_URL, {
  headers: {
    'Content-Type': 'application/json',
  },
});

// GraphQL 查询定义
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
      state
      totalVolume
      feeAccrued
      lpLiquidity
      uniqueBettors
      createdAt
      lockedAt
      resolvedAt
    }
  }
`;

export const MARKET_QUERY = `
  query Market($id: ID!) {
    market(id: $id) {
      id
      templateId
      matchId
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
