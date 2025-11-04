'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKETS_QUERY, MARKETS_QUERY_FILTERED, MARKET_QUERY, USER_POSITIONS_QUERY, USER_ORDERS_QUERY, MARKET_ORDERS_QUERY } from './graphql';

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
  homeTeam: string;
  awayTeam: string;
  kickoffTime: string;
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
    templateType: string; // 英文类型代码（WDL、OU等）
    templateTypeDisplay: string; // 中文显示名称（胜平负、大小球等）
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
  averageCost?: string;
  totalInvested?: string;
  createdAt: string;
  lastUpdatedAt?: string;
}

// GraphQL 返回的原始 Position 类型（嵌套结构）
interface PositionRaw {
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
  owner: {
    id: string;
  };
  averageCost?: string;
  totalInvested?: string;
  lastUpdatedAt?: string;
}

export interface Order {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
    state?: MarketStatus;
  };
  user: string;
  outcome: number;
  amount: string;
  shares: string;
  fee?: string;
  price?: string;
  timestamp: string;
  transactionHash: string;
}

// GraphQL 返回的原始 Order 类型（嵌套结构）
interface OrderRaw {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
    state?: MarketStatus;
  };
  user: {
    id: string;
  };
  outcome: number;
  amount: string;
  shares: string;
  fee?: string;
  price?: string;
  timestamp: string;
  transactionHash: string;
}

/**
 * 生成显示信息（使用 Subgraph 返回的字段）
 */
function generateDisplayInfo(market: Market): Market['_displayInfo'] {
  // 模板类型映射 - templateId -> 类型代码
  const templateIdToTypeMap: Record<string, string> = {
    '0x00000000': 'WDL',
    WDL: 'WDL',
    OU: 'OU',
    OU_MULTI: 'OU_MULTI',
    AH: 'AH',
    Score: 'Score',
  };

  // 类型代码 -> 中文显示名称
  const typeDisplayMap: Record<string, string> = {
    WDL: '胜平负',
    OU: '大小球',
    OU_MULTI: '大小球（多线）',
    AH: '让球',
    Score: '精确比分',
  };

  // 从 templateId 提取类型代码
  const templateType = templateIdToTypeMap[market.templateId] || 'WDL';
  const templateTypeDisplay = typeDisplayMap[templateType] || '未知玩法';

  return {
    homeTeam: market.homeTeam,
    awayTeam: market.awayTeam,
    league: 'EPL', // TODO: 从 matchId 或其他字段解析
    templateType, // 英文类型代码，用于内部逻辑
    templateTypeDisplay, // 中文显示名称，用于 UI 展示
  };
}

/**
 * 查询市场列表
 */
export function useMarkets(status?: MarketStatus[], first = 20, skip = 0) {
  return useQuery({
    queryKey: ['markets', status, first, skip],
    queryFn: async () => {
      console.log('[useMarkets] 查询市场列表:', { status, first, skip });

      try {
        // 根据是否有 status 过滤条件选择不同的查询
        const hasStatusFilter = status && status.length > 0;
        const query = hasStatusFilter ? MARKETS_QUERY_FILTERED : MARKETS_QUERY;
        const variables: Record<string, any> = { first, skip };

        if (hasStatusFilter) {
          variables.status = status;
        }

        const data = await graphqlClient.request<{ markets: Market[] }>(
          query,
          variables
        );

        console.log('[useMarkets] 查询成功，返回', data.markets.length, '个市场');

        // 为每个市场添加显示信息
        return data.markets.map(market => ({
          ...market,
          _displayInfo: generateDisplayInfo(market),
        }));
      } catch (error) {
        console.error('[useMarkets] 查询失败:', error);
        throw error;
      }
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
      if (!id) {
        console.log('[useMarket] ID 为空，返回 null');
        return null;
      }

      // 确保地址格式正确（统一为小写，Subgraph 通常存储小写）
      const normalizedId = id.toLowerCase();
      console.log('[useMarket] 查询市场:', {
        originalId: id,
        normalizedId
      });

      try {
        const data = await graphqlClient.request<{ market: Market }>(
          MARKET_QUERY,
          { id: normalizedId }
        );

        console.log('[useMarket] GraphQL 响应:', data);

        // 添加空值检查
        if (!data.market) {
          console.error('[useMarket] 市场不存在:', normalizedId);
          throw new Error(`Market ${id} not found in Subgraph`);
        }

        // 为市场添加显示信息
        const result = {
          ...data.market,
          _displayInfo: generateDisplayInfo(data.market),
        };

        console.log('[useMarket] 查询成功，返回数据:', result);
        return result;
      } catch (error) {
        console.error('[useMarket] 查询失败:', error);
        throw error;
      }
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
      if (!userAddress) {
        console.log('[useUserPositions] 地址为空，返回空数组');
        return [];
      }

      const userId = userAddress.toLowerCase();
      console.log('[useUserPositions] 查询用户头寸:', { userId });

      try {
        const data = await graphqlClient.request<{ positions: PositionRaw[] }>(
          USER_POSITIONS_QUERY,
          { userId } // 修复：参数名从 user 改为 userId
        );
        console.log('[useUserPositions] 查询成功，返回', data.positions.length, '个头寸');

        // 转换嵌套结构为扁平结构
        const positions: Position[] = data.positions.map(pos => ({
          ...pos,
          owner: pos.owner.id,
          createdAt: pos.lastUpdatedAt || '0', // 使用 lastUpdatedAt 作为 createdAt
        }));

        return positions;
      } catch (error) {
        console.error('[useUserPositions] 查询失败:', error);
        throw error;
      }
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
      if (!userAddress) {
        console.log('[useUserOrders] 地址为空，返回空数组');
        return [];
      }

      const userId = userAddress.toLowerCase();
      console.log('[useUserOrders] 查询用户订单:', { userId, first });

      try {
        const data = await graphqlClient.request<{ orders: OrderRaw[] }>(
          USER_ORDERS_QUERY,
          { userId, first } // 修复：参数名从 user 改为 userId
        );
        console.log('[useUserOrders] 查询成功，返回', data.orders.length, '个订单');

        // 转换嵌套结构为扁平结构
        const orders: Order[] = data.orders.map(order => ({
          ...order,
          user: order.user.id,
        }));

        return orders;
      } catch (error) {
        console.error('[useUserOrders] 查询失败:', error);
        throw error;
      }
    },
    enabled: !!userAddress,
    staleTime: 30 * 1000, // 30 秒
  });
}

/**
 * 查询用户在特定市场的订单历史
 */
export function useMarketOrders(
  userAddress: string | undefined,
  marketId: string | undefined,
  first = 50
) {
  return useQuery({
    queryKey: ['orders', userAddress, marketId, first],
    queryFn: async () => {
      if (!userAddress || !marketId) {
        console.log('[useMarketOrders] 地址或市场ID为空，返回空数组');
        return [];
      }

      const userId = userAddress.toLowerCase();
      const normalizedMarketId = marketId.toLowerCase();
      console.log('[useMarketOrders] 查询市场订单:', { userId, marketId: normalizedMarketId, first });

      try {
        const data = await graphqlClient.request<{ orders: OrderRaw[] }>(
          MARKET_ORDERS_QUERY,
          {
            userId,
            marketId: normalizedMarketId,
            first,
          }
        );
        console.log('[useMarketOrders] 查询成功，返回', data.orders.length, '个订单');

        // 转换嵌套结构为扁平结构
        const orders: Order[] = data.orders.map(order => ({
          ...order,
          user: order.user.id,
        }));

        return orders;
      } catch (error) {
        console.error('[useMarketOrders] 查询失败:', error);
        throw error;
      }
    },
    enabled: !!userAddress && !!marketId,
    staleTime: 15 * 1000, // 15 秒
  });
}
