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
  matchId: string;
  templateId: string;
  state: MarketStatus;
  totalVolume: string;
  feeAccrued: string;
  lpLiquidity: string;
  uniqueBettors: number;
  createdAt: string;
  lockedAt?: string;
  resolvedAt?: string;
  finalizedAt?: string;
  winnerOutcome?: number;
  // 辅助字段用于显示
  _displayInfo?: {
    homeTeam: string;
    awayTeam: string;
    league: string;
    templateType: string;
  };
}

export interface Position {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
    state: MarketStatus;
    winnerOutcome?: number;
  };
  outcome: number;
  balance: string;
  owner: string;
  createdAt: string;
}

export interface Order {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
  };
  user: string;
  outcome: number;
  amount: string;
  shares: string;
  timestamp: string;
  transactionHash: string;
}

/**
 * 解析 matchId 生成显示信息
 */
function parseMatchId(matchId: string, templateId: string): Market['_displayInfo'] {
  // matchId 格式: "EPL_2024_MUN_vs_MCI" 或类似
  const parts = matchId.split('_');

  if (parts.length >= 4) {
    const league = parts[0]; // EPL
    const homeTeam = parts[2]; // MUN
    const awayTeam = parts[4] || parts[parts.length - 1]; // MCI

    // 模板类型映射
    const templateTypeMap: Record<string, string> = {
      WDL: '胜平负',
      OU: '大小球',
      AH: '让球',
      Score: '精确比分',
    };

    // 从 templateId 中提取模板类型（如果可能）
    const templateType = templateTypeMap[templateId.split('_')[0]] || '未知玩法';

    return {
      league,
      homeTeam,
      awayTeam,
      templateType,
    };
  }

  // 如果无法解析，返回默认值
  return {
    league: 'Unknown',
    homeTeam: matchId.slice(0, 8) + '...',
    awayTeam: matchId.slice(-8),
    templateType: '未知玩法',
  };
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
      // 为每个市场添加显示信息
      return data.markets.map(market => ({
        ...market,
        _displayInfo: parseMatchId(market.matchId, market.templateId),
      }));
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
      // 为市场添加显示信息
      return {
        ...data.market,
        _displayInfo: parseMatchId(data.market.matchId, data.market.templateId),
      };
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
