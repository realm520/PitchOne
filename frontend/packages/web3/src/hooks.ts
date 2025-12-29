'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKETS_QUERY, MARKETS_QUERY_FILTERED, MARKET_QUERY, MARKET_WITH_ODDS_QUERY, USER_POSITIONS_QUERY, USER_POSITIONS_PAGINATED_QUERY, USER_POSITIONS_COUNT_QUERY, USER_ORDERS_QUERY, MARKET_ORDERS_QUERY, MARKET_ALL_ORDERS_QUERY, MARKETS_COUNT_QUERY, MARKETS_COUNT_BY_STATUS_QUERY, USER_REDEMPTIONS_QUERY } from './graphql';
import { calculateOddsFromSubgraph, type OutcomeVolume, type OutcomeOdds } from './odds-calculator';

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

// Outcome 数据类型（用于 UI 显示）
export interface OutcomeData {
  id: number;
  name: string;  // i18n key 或显示文本
  odds: string;  // 格式化的赔率（如 "1.85"）或 "-"
  color: string;
  liquidity: bigint;
  probability: number;
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
  paused?: boolean; // 是否暂停（临时锁盘）
  pausedAt?: string;
  pausedBy?: string;
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
  // 赔率相关字段（从 Subgraph 获取，用于本地计算赔率）
  pricingType?: string;
  initialLiquidity?: string;
  lmsrB?: string;
  outcomeVolumes?: OutcomeVolume[];
  // 计算后的赔率数据（直接用于 UI 显示）
  outcomes?: OutcomeData[];
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
  // 包括 Pari（彩池模式）变体
  const templateIdToTypeMap: Record<string, string> = {
    '0x00000000': 'WDL',
    WDL: 'WDL',
    WDL_Pari: 'WDL_Pari',
    OU: 'OU',
    OU_Pari: 'OU_Pari',
    OU_MULTI: 'OU_MULTI',
    AH: 'AH',
    AH_Pari: 'AH_Pari',
    Score: 'Score',
    Score_Pari: 'Score_Pari',
    OddEven: 'OddEven',
    OddEven_Pari: 'OddEven_Pari',
  };

  // 类型代码 -> i18n key
  // Pari 变体使用相同的显示名称
  const typeDisplayKeyMap: Record<string, string> = {
    WDL: 'markets.type.wdl',
    WDL_Pari: 'markets.type.wdl',
    OU: 'markets.type.ou',
    OU_Pari: 'markets.type.ou',
    OU_MULTI: 'markets.type.ou',
    AH: 'markets.type.ah',
    AH_Pari: 'markets.type.ah',
    Score: 'markets.type.score',
    Score_Pari: 'markets.type.score',
    OddEven: 'markets.type.oddEven',
    OddEven_Pari: 'markets.type.oddEven',
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
 * 根据市场类型获取预期的 outcome 数量
 */
function getExpectedOutcomeCount(templateType: string): number | null {
  switch (templateType) {
    case 'WDL':
    case 'WDL_Pari':
      return 3;      // 胜平负：主胜、平局、客胜
    case 'OU':
    case 'OU_Pari':
      return 2;       // 大小球：大、小
    case 'OU_MULTI': return null; // 多线大小球：由线数决定
    case 'AH':
    case 'AH_Pari':
      return 3;       // 让球：主队赢盘、客队赢盘、走盘
    case 'OddEven':
    case 'OddEven_Pari':
      return 2;  // 单双：单、双
    case 'Score':
    case 'Score_Pari':
      return null; // 精确比分：不限制
    case 'PlayerProps': return null; // 球员道具：不限制
    default: return 3;         // 默认返回 3（WDL 最常见）
  }
}

/**
 * 根据模板类型和 outcome ID 获取 i18n key
 */
function getOutcomeName(outcomeId: number, templateType: string): string {
  // OU_MULTI 特殊处理
  if (templateType === 'OU_MULTI') {
    const direction = outcomeId % 2;
    return direction === 0 ? 'outcomes.ou.over' : 'outcomes.ou.under';
  }

  // OU
  if (templateType === 'OU' || templateType === 'OU_Pari') {
    return outcomeId === 0 ? 'outcomes.ou.over' : 'outcomes.ou.under';
  }

  // AH
  if (templateType === 'AH' || templateType === 'AH_Pari') {
    if (outcomeId === 0) return 'outcomes.ah.homeCover';
    if (outcomeId === 1) return 'outcomes.ah.awayCover';
    return 'outcomes.ah.push';
  }

  // OddEven
  if (templateType === 'OddEven' || templateType === 'OddEven_Pari') {
    return outcomeId === 0 ? 'outcomes.oddEven.odd' : 'outcomes.oddEven.even';
  }

  // WDL
  if (templateType === 'WDL' || templateType === 'WDL_Pari') {
    const keys = ['outcomes.wdl.homeWin', 'outcomes.wdl.draw', 'outcomes.wdl.awayWin'];
    return keys[outcomeId] || 'outcomes.fallback';
  }

  // Score
  if (templateType === 'Score' || templateType === 'Score_Pari') {
    if (outcomeId === 999) return 'outcomes.score.other';
    const homeGoals = Math.floor(outcomeId / 10);
    const awayGoals = outcomeId % 10;
    return `${homeGoals}-${awayGoals}`;
  }

  return 'outcomes.fallback';
}

/**
 * 为市场计算赔率数据
 */
function calculateMarketOutcomes(market: Market): OutcomeData[] {
  const templateType = market.templateId || 'WDL';
  const expectedCount = getExpectedOutcomeCount(templateType);

  // 使用 Subgraph 数据计算赔率
  const odds = calculateOddsFromSubgraph({
    pricingType: market.pricingType || null,
    initialLiquidity: market.initialLiquidity || null,
    lmsrB: market.lmsrB || null,
    totalVolume: market.totalVolume,
    outcomeVolumes: market.outcomeVolumes || [],
    feeRate: 0.02,
    expectedOutcomeCount: expectedCount || 3,
  });

  // 限制显示数量
  const displayOdds = expectedCount !== null ? odds.slice(0, expectedCount) : odds;

  // 转换为 OutcomeData 格式
  const colors = [
    'from-green-600 to-green-800',
    'from-yellow-600 to-yellow-800',
    'from-blue-600 to-blue-800',
    'from-purple-600 to-purple-800',
    'from-red-600 to-red-800',
  ];

  return displayOdds.map((o) => ({
    id: o.outcomeId,
    name: getOutcomeName(o.outcomeId, templateType),
    odds: o.odds !== null ? o.odds.toFixed(2) : '-',
    color: colors[o.outcomeId] || 'from-gray-600 to-gray-800',
    liquidity: o.shares,
    probability: o.probability,
  }));
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

        // 为每个市场添加显示信息和计算赔率
        return data.markets.map(market => ({
          ...market,
          _displayInfo: generateDisplayInfo(market),
          outcomes: calculateMarketOutcomes(market),
        }));
      } catch (error) {
        console.error('[useMarkets] 查询失败:', error);
        throw error;
      }
    },
    staleTime: 5 * 1000, // 5 秒（赔率需要更实时）
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
          return data.markets?.length ?? 0;
        } else {
          // 所有市场数量 - 使用 markets 查询作为备选
          try {
            const data = await graphqlClient.request<{ globalStats: { totalMarkets: number } | null }>(
              MARKETS_COUNT_QUERY
            );
            if (data.globalStats?.totalMarkets !== undefined) {
              return data.globalStats.totalMarkets;
            }
          } catch {
            // globalStats 查询失败，使用备选方案
          }

          // 备选方案：查询所有市场 ID 来计数
          const marketsData = await graphqlClient.request<{ markets: { id: string }[] }>(
            `query { markets(first: 1000) { id } }`
          );
          return marketsData.markets?.length ?? 0;
        }
      } catch (error) {
        console.error('[useMarketsCount] 查询失败:', error);
        return 0; // 返回 0 而不是抛出错误
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

// ============================================================================
// 基于 Subgraph 的赔率计算 Hook
// ============================================================================

/**
 * 市场赔率数据接口（从 Subgraph 返回）
 */
export interface MarketWithOddsData {
  id: string;
  templateId: string;
  matchId: string;
  homeTeam: string;
  awayTeam: string;
  kickoffTime: string;
  state: MarketStatus;
  totalVolume: string;
  feeAccrued: string;
  line?: string;
  lines?: string[];
  pricingType: string | null;
  initialLiquidity: string | null;
  lmsrB: string | null;
  outcomeVolumes: OutcomeVolume[];
}

/**
 * 从 Subgraph 获取市场数据并计算赔率
 * 完全不依赖合约调用，所有数据来自 Subgraph
 *
 * @param marketId 市场地址
 * @param feeRate 手续费率（默认 2%）
 */
export function useMarketOddsFromSubgraph(
  marketId: string | undefined,
  feeRate = 0.02
) {
  return useQuery({
    queryKey: ['marketOdds', marketId, feeRate],
    queryFn: async () => {
      if (!marketId) {
        return null;
      }

      const normalizedId = marketId.toLowerCase();
      console.log('[useMarketOddsFromSubgraph] 查询市场赔率:', normalizedId);

      try {
        const data = await graphqlClient.request<{ market: MarketWithOddsData }>(
          MARKET_WITH_ODDS_QUERY,
          { id: normalizedId }
        );

        if (!data.market) {
          console.error('[useMarketOddsFromSubgraph] 市场不存在:', normalizedId);
          return null;
        }

        const market = data.market;

        // 使用 Subgraph 数据计算赔率
        const odds = calculateOddsFromSubgraph({
          pricingType: market.pricingType,
          initialLiquidity: market.initialLiquidity,
          lmsrB: market.lmsrB,
          totalVolume: market.totalVolume,
          outcomeVolumes: market.outcomeVolumes,
          feeRate,
        });

        console.log('[useMarketOddsFromSubgraph] 计算完成:', {
          pricingType: market.pricingType,
          outcomeCount: odds.length,
          odds: odds.map(o => ({ id: o.outcomeId, odds: o.odds?.toFixed(2) })),
        });

        return {
          market,
          odds,
        };
      } catch (error) {
        console.error('[useMarketOddsFromSubgraph] 查询失败:', error);
        throw error;
      }
    },
    enabled: !!marketId,
    staleTime: 5 * 1000, // 5 秒，赔率需要较实时
  });
}

// 导出赔率相关类型
export type { OutcomeOdds };
