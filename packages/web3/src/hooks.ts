import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKETS_QUERY, MARKET_QUERY, USER_POSITIONS_QUERY, USER_ORDERS_QUERY } from './graphql';

// 市场状态枚举
export enum MarketStatus {
  Open = 'Open',
  Locked = 'Locked',
  Resolved = 'Resolved',
  Finalized = 'Finalized',
}

// 类型定义
export interface Market {
  id: string;
  event: string;
  homeTeam: string;
  awayTeam: string;
  kickoffTime: string;
  status: MarketStatus;
  template: {
    type: string;
  };
  totalVolume: string;
  createdAt: string;
  winningOutcome?: number;
  outcomeCount?: number;
  resolvedAt?: string;
}

export interface Position {
  id: string;
  market: {
    id: string;
    event: string;
    homeTeam: string;
    awayTeam: string;
    status: MarketStatus;
    winningOutcome?: number;
  };
  outcome: number;
  balance: string;
  createdAt: string;
}

export interface Order {
  id: string;
  market: {
    id: string;
    event: string;
  };
  outcome: number;
  amount: string;
  shares: string;
  timestamp: string;
  transactionHash: string;
}

/**
 * 查询市场列表
 */
export function useMarkets(status?: MarketStatus[], first = 20, skip = 0) {
  return useQuery({
    queryKey: ['markets', status, first, skip],
    queryFn: async () => {
      const data = await graphqlClient.request<{ markets: Market[] }>(
        MARKETS_QUERY,
        { status, first, skip }
      );
      return data.markets;
    },
    staleTime: 30 * 1000, // 30 秒
  });
}

/**
 * 查询单个市场详情
 */
export function useMarket(id: string | undefined) {
  return useQuery({
    queryKey: ['market', id],
    queryFn: async () => {
      if (!id) return null;
      const data = await graphqlClient.request<{ market: Market }>(
        MARKET_QUERY,
        { id }
      );
      return data.market;
    },
    enabled: !!id,
    staleTime: 10 * 1000, // 10 秒
  });
}

/**
 * 查询用户头寸
 */
export function useUserPositions(userAddress: string | undefined) {
  return useQuery({
    queryKey: ['positions', userAddress],
    queryFn: async () => {
      if (!userAddress) return [];
      const data = await graphqlClient.request<{ positions: Position[] }>(
        USER_POSITIONS_QUERY,
        { user: userAddress.toLowerCase() }
      );
      return data.positions;
    },
    enabled: !!userAddress,
    staleTime: 15 * 1000, // 15 秒
  });
}

/**
 * 查询用户订单历史
 */
export function useUserOrders(userAddress: string | undefined, first = 50) {
  return useQuery({
    queryKey: ['orders', userAddress, first],
    queryFn: async () => {
      if (!userAddress) return [];
      const data = await graphqlClient.request<{ orders: Order[] }>(
        USER_ORDERS_QUERY,
        { user: userAddress.toLowerCase(), first }
      );
      return data.orders;
    },
    enabled: !!userAddress,
    staleTime: 30 * 1000, // 30 秒
  });
}
