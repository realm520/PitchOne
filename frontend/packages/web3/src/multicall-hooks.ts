'use client';

import { useReadContracts } from 'wagmi';
import { MarketBaseABI, getContractAddresses } from '@pitchone/contracts';
import type { Address } from 'viem';
import { useAccount } from 'wagmi';
import { useOutcomeCount } from './contract-hooks';

/**
 * 市场完整数据接口
 */
export interface MarketFullData {
  status: number;
  outcomeCount: bigint;
  totalLiquidity: bigint;
  outcomeLiquidity: bigint[];
  feeRate: bigint;
  userBalances?: bigint[]; // 用户在每个结果的头寸
}

/**
 * 批量查询单个市场的完整数据
 * 使用 multicall 一次性获取所有数据，减少 RPC 调用
 *
 * @param marketAddress 市场合约地址
 * @param userAddress 用户地址（可选，用于查询用户头寸）
 */
export function useMarketFullData(marketAddress?: Address, userAddress?: Address) {
  console.log('[useMarketFullData] 开始查询:', { marketAddress, userAddress });

  const {
    data: count,
    isLoading: isLoadingOutcomeCount,
    error: outcomeCountError
  } = useOutcomeCount(marketAddress);

  const outcomeCountNumber = count ? Number(count) : 0;

  console.log('[useMarketFullData] outcomeCount 查询结果:', {
    isLoading: isLoadingOutcomeCount,
    hasError: !!outcomeCountError,
    error: outcomeCountError,
    count,
    outcomeCountNumber
  });

  // 构建批量查询合约配置
  const contracts = [];

  if (marketAddress) {
    // 基础数据查询
    contracts.push(
      {
        address: marketAddress,
        abi: MarketBaseABI,
        functionName: 'status',
      },
      {
        address: marketAddress,
        abi: MarketBaseABI,
        functionName: 'totalLiquidity',
      },
      {
        address: marketAddress,
        abi: MarketBaseABI,
        functionName: 'feeRate',
      }
    );

    // 为每个结果查询流动性
    if (outcomeCountNumber > 0) {
      for (let i = 0; i < outcomeCountNumber; i++) {
        contracts.push({
          address: marketAddress,
          abi: MarketBaseABI,
          functionName: 'outcomeLiquidity',
          args: [BigInt(i)],
        });
      }

      // 如果提供了用户地址，查询用户在每个结果的头寸
      if (userAddress) {
        for (let i = 0; i < outcomeCountNumber; i++) {
          contracts.push({
            address: marketAddress,
            abi: MarketBaseABI,
            functionName: 'balanceOf',
            args: [userAddress, BigInt(i)],
          });
        }
      }
    }
  }

  console.log('[useMarketFullData] 构建的合约查询数组:', {
    contractsLength: contracts.length,
    enabled: !!marketAddress && outcomeCountNumber > 0
  });

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: contracts as any,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress && outcomeCountNumber > 0 && !isLoadingOutcomeCount,
      staleTime: 10000, // 10 秒
    },
  });

  console.log('[useMarketFullData] 合约查询结果:', {
    hasData: !!data,
    dataLength: data?.length,
    isLoading,
    hasError: !!error,
    error
  });

  // 解析数据
  if (!data || !outcomeCountNumber) {
    console.log('[useMarketFullData] 返回 null，原因:', {
      hasData: !!data,
      outcomeCountNumber
    });
    return { data: null, isLoading, error, refetch };
  }

  const status = data[0]?.result as number;
  const totalLiquidity = data[1]?.result as bigint;
  const feeRate = data[2]?.result as bigint;

  // 提取流动性数据
  const outcomeLiquidity: bigint[] = [];
  for (let i = 0; i < outcomeCountNumber; i++) {
    outcomeLiquidity.push((data[3 + i]?.result as bigint) || 0n);
  }

  // 提取用户头寸数据
  let userBalances: bigint[] | undefined;
  if (userAddress && data.length > 3 + outcomeCountNumber) {
    userBalances = [];
    for (let i = 0; i < outcomeCountNumber; i++) {
      userBalances.push((data[3 + outcomeCountNumber + i]?.result as bigint) || 0n);
    }
  }

  const fullData: MarketFullData = {
    status,
    outcomeCount: BigInt(outcomeCountNumber),
    totalLiquidity,
    outcomeLiquidity,
    feeRate,
    userBalances,
  };

  return { data: fullData, isLoading, error, refetch };
}

/**
 * 批量查询多个市场的基础数据
 *
 * @param marketAddresses 市场合约地址数组
 */
export function useMultipleMarketsData(marketAddresses: Address[]) {
  const contracts = marketAddresses.flatMap((address) => [
    {
      address,
      abi: MarketBaseABI,
      functionName: 'status',
    },
    {
      address,
      abi: MarketBaseABI,
      functionName: 'outcomeCount',
    },
    {
      address,
      abi: MarketBaseABI,
      functionName: 'totalLiquidity',
    },
  ]);

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: contracts as any,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: marketAddresses.length > 0,
      staleTime: 30000, // 30 秒
    },
  });

  if (!data) {
    return { data: null, isLoading, error, refetch };
  }

  // 将数据按市场分组
  const marketsData = [];
  for (let i = 0; i < marketAddresses.length; i++) {
    const baseIndex = i * 3;
    marketsData.push({
      address: marketAddresses[i],
      status: data[baseIndex]?.result as number,
      outcomeCount: data[baseIndex + 1]?.result as bigint,
      totalLiquidity: data[baseIndex + 2]?.result as bigint,
    });
  }

  return { data: marketsData, isLoading, error, refetch };
}

/**
 * 批量查询用户在多个市场的 USDC 授权额度和余额
 *
 * @param marketAddresses 市场地址数组
 * @param userAddress 用户地址
 */
export function useUserUSDCDataForMarkets(
  marketAddresses: Address[],
  userAddress?: Address
) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const contracts = marketAddresses.flatMap((marketAddress) => [
    {
      address: addresses?.usdc,
      abi: [
        {
          name: 'allowance',
          type: 'function',
          stateMutability: 'view',
          inputs: [
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
          ],
          outputs: [{ name: '', type: 'uint256' }],
        },
      ],
      functionName: 'allowance',
      args: userAddress ? [userAddress, marketAddress] : undefined,
    },
  ]);

  // 额外添加用户 USDC 余额查询（只需要一次）
  if (userAddress && addresses?.usdc) {
    contracts.push({
      address: addresses.usdc,
      abi: [
        {
          name: 'balanceOf',
          type: 'function',
          stateMutability: 'view',
          inputs: [{ name: 'account', type: 'address' }],
          outputs: [{ name: '', type: 'uint256' }],
        },
      ],
      functionName: 'balanceOf',
      args: [userAddress],
    });
  }

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: contracts as any,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!userAddress && !!addresses && marketAddresses.length > 0,
      staleTime: 15000, // 15 秒
    },
  });

  if (!data) {
    return { data: null, isLoading, error, refetch };
  }

  // 解析数据
  const allowances = new Map<Address, bigint>();
  for (let i = 0; i < marketAddresses.length; i++) {
    allowances.set(marketAddresses[i], (data[i]?.result as bigint) || 0n);
  }

  const balance = data[marketAddresses.length]?.result as bigint | undefined;

  return {
    data: {
      allowances,
      balance: balance || 0n,
    },
    isLoading,
    error,
    refetch,
  };
}

/**
 * Outcome 数据接口
 */
export interface OutcomeData {
  id: number;
  name: string;
  odds: string; // 格式化的赔率字符串，如 "2.15"
  color: string; // 渐变色类名
  liquidity: bigint; // 原始流动性
  probability: number; // 隐含概率（0-1）
}

/**
 * 获取格式化的 Outcome 数据（包括名称和实时赔率）
 *
 * @param marketAddress 市场合约地址
 * @param templateType 市场模板类型（WDL, OU, AH等）
 */
export function useMarketOutcomes(marketAddress?: Address, templateType?: string) {
  console.log('[useMarketOutcomes] 开始查询:', { marketAddress, templateType });

  const { data: marketData, isLoading, error, refetch } = useMarketFullData(marketAddress);

  console.log('[useMarketOutcomes] useMarketFullData 返回:', {
    hasMarketData: !!marketData,
    isLoading,
    hasError: !!error
  });

  if (!marketData || isLoading) {
    console.log('[useMarketOutcomes] 返回 null，原因:', {
      hasMarketData: !!marketData,
      isLoading
    });
    return { data: null, isLoading, error, refetch };
  }

  const outcomeCount = Number(marketData.outcomeCount);
  const outcomeLiquidity = marketData.outcomeLiquidity;
  const totalLiquidity = marketData.totalLiquidity;

  // 计算每个 outcome 的数据
  const outcomes: OutcomeData[] = [];

  for (let i = 0; i < outcomeCount; i++) {
    const liquidity = outcomeLiquidity[i];

    // 跳过流动性为 0 的结果（如半球盘的退款、未注入流动性的选项）
    if (liquidity === 0n) {
      continue;
    }

    // 计算隐含概率（流动性占比）
    const probability = totalLiquidity > 0n
      ? Number(liquidity) / Number(totalLiquidity)
      : 0;

    // 计算赔率（1 / 概率，考虑手续费）
    const feeRate = Number(marketData.feeRate) / 10000; // feeRate 是基点（如 200 = 2%）
    const effectiveProbability = probability * (1 - feeRate);
    const odds = effectiveProbability > 0 ? 1 / effectiveProbability : 99.99;

    // 根据模板类型获取 outcome 名称
    const name = getOutcomeName(i, templateType || 'WDL');

    // 根据 outcome ID 设置颜色
    const colors = [
      'from-green-600 to-green-800',
      'from-yellow-600 to-yellow-800',
      'from-blue-600 to-blue-800',
      'from-purple-600 to-purple-800',
      'from-red-600 to-red-800',
    ];
    const color = colors[i] || 'from-gray-600 to-gray-800';

    outcomes.push({
      id: i,
      name,
      odds: odds.toFixed(2),
      color,
      liquidity,
      probability,
    });
  }

  console.log('[useMarketOutcomes] 查询成功，返回 outcomes:', {
    outcomeCount,
    outcomes
  });

  return { data: outcomes, isLoading: false, error, refetch };
}

/**
 * 根据模板类型和 outcome ID 获取名称
 */
function getOutcomeName(outcomeId: number, templateType: string): string {
  // OU_MULTI 特殊处理：outcomeId = lineIndex * 2 + direction（仅半球盘）
  if (templateType === 'OU_MULTI') {
    const lineIndex = Math.floor(outcomeId / 2);
    const direction = outcomeId % 2; // 0=OVER, 1=UNDER

    // 常见的线配置（2.5, 3.5, 4.5）
    const lines = [2.5, 3.5, 4.5];
    const lineName = lines[lineIndex] || lineIndex;

    const directionNames = ['大', '小'];
    const directionName = directionNames[direction] || '?';

    return `${lineName}球 ${directionName}`;
  }

  const nameMap: Record<string, string[]> = {
    WDL: ['主胜', '平局', '客胜'],
    OU: ['大球', '小球'],
    AH: ['主队让球', '客队让球'],
    OddEven: ['奇数', '偶数'],
    Score: [], // 精确比分需要特殊处理
  };

  const names = nameMap[templateType] || [];
  return names[outcomeId] || `结果 ${outcomeId}`;
}
