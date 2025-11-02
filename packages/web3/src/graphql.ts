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
