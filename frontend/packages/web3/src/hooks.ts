'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKETS_QUERY, MARKETS_QUERY_FILTERED, MARKET_QUERY, USER_POSITIONS_QUERY, USER_POSITIONS_PAGINATED_QUERY, USER_POSITIONS_COUNT_QUERY, USER_ORDERS_QUERY, MARKET_ORDERS_QUERY, MARKET_ALL_ORDERS_QUERY, MARKETS_COUNT_QUERY, MARKETS_COUNT_BY_STATUS_QUERY, USER_REDEMPTIONS_QUERY } from './graphql';

// Redemption 类型定义
interface RedemptionRaw {
  id: string;
  market: { id: string };
  user: { id: string };
  outcome: number;
  shares: string;
  payout: string;
  isRefund?: boolean;
  timestamp: string;
  blockNumber: string;
  transactionHash: string;
}

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
  line?: string; // 大小球盘口线（单线市场，如 "2500000000000000000" = 2.5 球）
  lines?: string[]; // 大小球盘口线数组（多线市场，如 ["2000000000000000000", "2500000000000000000", "3000000000000000000"]）
  // 辅助字段用于显示
  _displayInfo?: {
    homeTeam: string;
    awayTeam: string;
    league: string;
    templateType: string; // 英文类型代码（WDL、OU等）
    templateTypeDisplay: string; // 中文显示名称（胜平负、大小球等）
    lineDisplay?: string; // 格式化的球数显示（如 "2.5 球"）
  };
}

export interface Position {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
    homeTeam: string;
    awayTeam: string;
    kickoffTime: string;
    state: MarketStatus;
    winnerOutcome?: number;
    line?: string;
    lines?: string[];
  };
  outcome: number;
  balance: string;
  owner: string;
  averageCost?: string;
  totalInvested?: string;
  createdTxHash?: string;
  createdAt: string;
  lastUpdatedAt?: string;
  // 前端填充的 claim hash（从 redemptions 查询获取）
  claimTxHash?: string;
}

// GraphQL 返回的原始 Position 类型（嵌套结构）
interface PositionRaw {
  id: string;
  market: {
    id: string;
    matchId: string;
    templateId: string;
    homeTeam: string;
    awayTeam: string;
    kickoffTime: string;
    state: MarketStatus;
    winnerOutcome?: number;
    line?: string;
    lines?: string[];
  };
  outcome: number;
  balance: string;
  owner: {
    id: string;
  };
  averageCost?: string;
  totalInvested?: string;
  createdTxHash?: string;
  createdAt?: string;
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
 * 将千分位表示的球数转换为显示（如 2500 -> "2.5"）
 */
function formatLineDisplay(lineStr: string): string {
  try {
    // 将千分位表示转换为数字（除以 1000）
    // 例如：2500 = 2.5 球，3500 = 3.5 球
    const lineNumber = parseFloat(lineStr) / 1000;
    return lineNumber.toFixed(1);
  } catch {
    return lineStr;
  }
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
    OddEven: 'OddEven',
  };

  // 类型代码 -> i18n key
  const typeDisplayKeyMap: Record<string, string> = {
    WDL: 'markets.type.wdl',
    OU: 'markets.type.ou',
    OU_MULTI: 'markets.type.ou',
    AH: 'markets.type.ah',
    Score: 'markets.type.score',
    OddEven: 'markets.type.oddEven',
  };

  // 从 templateId 提取类型代码
  const templateType = templateIdToTypeMap[market.templateId] || 'WDL';
  const templateTypeDisplay = typeDisplayKeyMap[templateType] || 'markets.unknown';

  // 格式化球数显示
  let lineDisplay: string | undefined = undefined;
  if (market.line) {
    // 单线市场（OU 或 AH）
    if (templateType === 'AH') {
      // 让球市场：handicap 是千分位表示的整数，可能为负
      // -500 = -0.5 球，+500 = +0.5 球
      const handicapValue = Number(market.line) / 1000;
      const absValue = Math.abs(handicapValue);
      const sign = handicapValue >= 0 ? '+' : '';
      lineDisplay = `${sign}${handicapValue.toFixed(absValue % 1 === 0 ? 1 : 1)} 球`;
    } else {
      // OU 市场：正数，18 位小数
      lineDisplay = formatLineDisplay(market.line) + ' 球';
    }
  } else if (market.lines && market.lines.length > 0) {
    // 多线市场，显示第一条线或所有线
    const formattedLines = market.lines.map(l => formatLineDisplay(l));
    lineDisplay = formattedLines.join('、') + ' 球';
  }

  // 从 matchId 解析联赛 ID（如 "EPL_2024_MUN_vs_MCI" -> "EPL"）
  const matchIdParts = market.matchId.split('_');
  const league = matchIdParts[0] || 'UNKNOWN';

  return {
    homeTeam: market.homeTeam,
    awayTeam: market.awayTeam,
    league, // 从 matchId 解析的联赛 ID
    templateType, // 英文类型代码，用于内部逻辑
    templateTypeDisplay, // 中文显示名称，用于 UI 展示
    lineDisplay, // 格式化的球数显示
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
 * 查询市场总数
 */
export function useMarketsCount(status?: MarketStatus[]) {
  return useQuery({
    queryKey: ['marketsCount', status],
    queryFn: async () => {
      try {
        if (status && status.length > 0) {
          // 按状态过滤的数量
          const data = await graphqlClient.request<{ markets: { id: string }[] }>(
            MARKETS_COUNT_BY_STATUS_QUERY,
            { status }
          );
          return data.markets.length;
        } else {
          // 所有市场数量
          const data = await graphqlClient.request<{ globalStats: { totalMarkets: number } }>(
            MARKETS_COUNT_QUERY
          );
          return data.globalStats?.totalMarkets ?? 0;
        }
      } catch (error) {
        console.error('[useMarketsCount] 查询失败:', error);
        throw error;
      }
    },
    staleTime: 60 * 1000, // 1 分钟
  });
}

/**
 * 分页信息接口
 */
export interface PaginationInfo {
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

/**
 * 分页市场查询结果
 */
export interface PaginatedMarketsResult {
  markets: Market[];
  pagination: PaginationInfo;
}

/**
 * 查询市场列表（带分页）
 */
export function useMarketsPaginated(
  status?: MarketStatus[],
  page = 1,
  pageSize = 20
) {
  const skip = (page - 1) * pageSize;

  // 查询当前页数据
  const marketsQuery = useMarkets(status, pageSize, skip);

  // 查询总数
  const countQuery = useMarketsCount(status);

  const totalItems = countQuery.data ?? 0;
  const totalPages = Math.ceil(totalItems / pageSize);

  return {
    data: marketsQuery.data,
    isLoading: marketsQuery.isLoading || countQuery.isLoading,
    error: marketsQuery.error || countQuery.error,
    refetch: () => {
      marketsQuery.refetch();
      countQuery.refetch();
    },
    pagination: {
      page,
      pageSize,
      totalItems,
      totalPages,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
    } as PaginationInfo,
  };
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
        // 并行查询：头寸数据 + redemptions
        const [positionsData, redemptionsData] = await Promise.all([
          graphqlClient.request<{ positions: PositionRaw[] }>(
            USER_POSITIONS_QUERY,
            { userId }
          ),
          graphqlClient.request<{ redemptions: RedemptionRaw[] }>(
            USER_REDEMPTIONS_QUERY,
            { userId, first: 100 }
          ),
        ]);
        console.log('[useUserPositions] 查询成功，返回', positionsData.positions.length, '个头寸');

        // 构建 redemption 查找表：market-outcome -> transactionHash
        const redemptionMap = new Map<string, string>();
        for (const r of redemptionsData.redemptions) {
          const key = `${r.market.id}-${r.outcome}`;
          if (!redemptionMap.has(key)) {
            redemptionMap.set(key, r.transactionHash);
          }
        }

        // 转换嵌套结构为扁平结构
        const positions: Position[] = positionsData.positions.map(pos => {
          const claimKey = `${pos.market.id}-${pos.outcome}`;
          return {
            ...pos,
            owner: pos.owner.id,
            createdAt: pos.createdAt || pos.lastUpdatedAt || '0',
            claimTxHash: redemptionMap.get(claimKey),
          };
        });

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
 * 分页查询用户头寸
 * @param userAddress 用户地址
 * @param page 页码（从1开始）
 * @param pageSize 每页条数
 */
export function useUserPositionsPaginated(
  userAddress: string | undefined,
  page: number = 1,
  pageSize: number = 10
) {
  const skip = (page - 1) * pageSize;

  return useQuery({
    queryKey: ['positions', userAddress, 'paginated', page, pageSize],
    queryFn: async () => {
      if (!userAddress) {
        console.log('[useUserPositionsPaginated] 地址为空，返回空数组');
        return { positions: [], total: 0 };
      }

      const userId = userAddress.toLowerCase();
      console.log('[useUserPositionsPaginated] 查询用户头寸:', { userId, page, pageSize, skip });

      try {
        // 并行查询：头寸数据 + 总数 + redemptions
        const [positionsData, countData, redemptionsData] = await Promise.all([
          graphqlClient.request<{ positions: PositionRaw[] }>(
            USER_POSITIONS_PAGINATED_QUERY,
            { userId, first: pageSize, skip }
          ),
          graphqlClient.request<{ user: { totalBets: number } | null }>(
            USER_POSITIONS_COUNT_QUERY,
            { userId }
          ),
          graphqlClient.request<{ redemptions: RedemptionRaw[] }>(
            USER_REDEMPTIONS_QUERY,
            { userId, first: 100 }
          ),
        ]);

        console.log('[useUserPositionsPaginated] 查询成功，返回', positionsData.positions.length, '个头寸');

        // 构建 redemption 查找表：market-outcome -> transactionHash
        const redemptionMap = new Map<string, string>();
        for (const r of redemptionsData.redemptions) {
          const key = `${r.market.id}-${r.outcome}`;
          if (!redemptionMap.has(key)) {
            redemptionMap.set(key, r.transactionHash);
          }
        }

        // 转换嵌套结构为扁平结构
        const positions: Position[] = positionsData.positions.map(pos => {
          const claimKey = `${pos.market.id}-${pos.outcome}`;
          return {
            ...pos,
            owner: pos.owner.id,
            createdAt: pos.createdAt || pos.lastUpdatedAt || '0',
            claimTxHash: redemptionMap.get(claimKey),
          };
        });

        // 总数从 user.totalBets 获取，如果用户不存在则为 0
        const total = countData.user?.totalBets || 0;

        return { positions, total };
      } catch (error) {
        console.error('[useUserPositionsPaginated] 查询失败:', error);
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

/**
 * 查询市场所有订单（不限用户）
 */
export function useMarketAllOrders(
  marketId: string | undefined,
  first = 50
) {
  return useQuery({
    queryKey: ['allOrders', marketId, first],
    queryFn: async () => {
      if (!marketId) {
        console.log('[useMarketAllOrders] 市场ID为空，返回空数组');
        return [];
      }

      const normalizedMarketId = marketId.toLowerCase();
      console.log('[useMarketAllOrders] 查询市场所有订单:', { marketId: normalizedMarketId, first });

      try {
        const data = await graphqlClient.request<{ orders: OrderRaw[] }>(
          MARKET_ALL_ORDERS_QUERY,
          {
            marketId: normalizedMarketId,
            first,
          }
        );
        console.log('[useMarketAllOrders] 查询成功，返回', data.orders.length, '个订单');

        // 转换嵌套结构为扁平结构
        const orders: Order[] = data.orders.map(order => ({
          ...order,
          user: order.user.id,
        }));

        return orders;
      } catch (error) {
        console.error('[useMarketAllOrders] 查询失败:', error);
        throw error;
      }
    },
    enabled: !!marketId,
    staleTime: 10 * 1000, // 10 秒
  });
}
