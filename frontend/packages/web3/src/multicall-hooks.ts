'use client';

import { useReadContracts, useAccount as useWagmiAccount } from 'wagmi';
import { MarketBaseABI, getContractAddresses } from '@pitchone/contracts';
import type { Address } from 'viem';
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
  isParimutel: boolean; // 是否为 Parimutuel（奖池）模式
  line?: bigint; // 盘口线（OU/AH 市场的球数线，千分位表示）
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

  // 获取当前链 ID，用于读取合约地址
  const { chain } = useWagmiAccount();
  const chainId = chain?.id || 31337; // 默认 Anvil

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
      },
      {
        address: marketAddress,
        // pricingEngine 是模板合约的公共变量，需要手动定义 ABI
        abi: [
          {
            inputs: [],
            name: 'pricingEngine',
            outputs: [{ internalType: 'address', name: '', type: 'address' }],
            stateMutability: 'view',
            type: 'function',
          },
        ],
        functionName: 'pricingEngine',
      },
      {
        address: marketAddress,
        // line 是 OU/AH 模板的公共变量（千分位表示的盘口线）
        abi: [
          {
            inputs: [],
            name: 'line',
            outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
            stateMutability: 'view',
            type: 'function',
          },
        ],
        functionName: 'line',
      }
    );

    // 为每个结果查询虚拟储备（V2 模板使用 virtualReserves）
    if (outcomeCountNumber > 0) {
      for (let i = 0; i < outcomeCountNumber; i++) {
        contracts.push({
          address: marketAddress,
          abi: MarketBaseABI,
          functionName: 'virtualReserves',
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
    contracts: contracts.map(c => ({ ...c, chainId: 31337 })) as any,
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
  const pricingEngine = (data[3]?.result as string)?.toLowerCase();
  // line 可能在非 OU/AH 市场中不存在，所以需要处理错误情况
  const lineResult = data[4]?.result;
  const line = lineResult !== undefined && lineResult !== null ? (lineResult as bigint) : undefined;

  // 提取流动性数据（索引从5开始，因为添加了 line 查询）
  const outcomeLiquidity: bigint[] = [];
  for (let i = 0; i < outcomeCountNumber; i++) {
    outcomeLiquidity.push((data[5 + i]?.result as bigint) || 0n);
  }

  // 提取用户头寸数据
  let userBalances: bigint[] | undefined;
  if (userAddress && data.length > 5 + outcomeCountNumber) {
    userBalances = [];
    for (let i = 0; i < outcomeCountNumber; i++) {
      userBalances.push((data[5 + outcomeCountNumber + i]?.result as bigint) || 0n);
    }
  }

  // 判断是否为 Parimutuel 模式
  // 通过对比定价引擎地址来判断（最可靠的方法）
  // 从配置中读取 Parimutuel 引擎地址（支持多链）
  const parimutuelAddress = getContractAddresses(chainId).parimutuel.toLowerCase();
  const isParimutel = pricingEngine === parimutuelAddress;

  const fullData: MarketFullData = {
    status,
    outcomeCount: BigInt(outcomeCountNumber),
    totalLiquidity,
    outcomeLiquidity,
    feeRate,
    userBalances,
    isParimutel,
    line,
  };

  console.log('[useMarketFullData] 解析完成:', {
    status,
    totalLiquidity: totalLiquidity.toString(),
    pricingEngine,
    parimutuelAddress,
    isParimutel,
    line: line?.toString(),
    outcomeLiquidity: outcomeLiquidity.map(r => r.toString()),
  });

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
    contracts: contracts.map(c => ({ ...c, chainId: 31337 })) as any,
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
  const { chain } = useWagmiAccount();
  const chainId = chain?.id;
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
    contracts: contracts.map(c => ({ ...c, chainId: 31337 })) as any,
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
 * @param line 盘口线（可选，用于 OU/AH 市场显示完整名称，如 "2.5 球"）
 */
export function useMarketOutcomes(marketAddress?: Address, templateType?: string, line?: string) {
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
    const reserve = outcomeLiquidity[i];

    let probability = 0;
    let directOdds: number | null = null; // Parimutuel 直接计算的赔率

    // 根据定价模式使用不同的公式
    if (marketData.isParimutel) {
      // ===== Parimutuel 奖池模式 =====
      // 直接计算赔率：odds = (totalPool * (1 - fee)) / myBets
      // 不使用概率转换，避免误导性的赔率
      const totalPool = Number(totalLiquidity);
      const myBets = Number(reserve);
      const feeRate = Number(marketData.feeRate) / 10000;

      if (totalPool > 0 && myBets > 0) {
        // 赔率 = 扣费后的总奖池 / 该结果投注额
        directOdds = (totalPool * (1 - feeRate)) / myBets;
      } else if (totalPool > 0 && myBets === 0) {
        // 该结果没有投注，赔率为上限（99.99）
        directOdds = 99.99;
      } else {
        // 初始状态：默认赔率
        directOdds = 1 / outcomeCount;
      }

      // 为了后续逻辑兼容，也计算一个"等效概率"
      // 但这个概率仅用于显示，不影响赔率计算
      probability = directOdds > 0 ? 1 / directOdds : 0;
    } else {
      // ===== CPMM 做市商模式 =====
      // 使用虚拟储备计算隐含概率
      // 对于二向市场：price_i = reserves[1-i] / (reserves[0] + reserves[1])
      // 对于三向市场：price_i = (reserves[j] * reserves[k]) / (r0*r1 + r0*r2 + r1*r2)

      if (outcomeCount === 2) {
        // 二向市场
        const opponentReserve = outcomeLiquidity[1 - i];
        const sumReserves = Number(outcomeLiquidity[0]) + Number(outcomeLiquidity[1]);

        if (sumReserves > 0) {
          probability = Number(opponentReserve) / sumReserves;
        } else {
          // 初始状态：平均概率
          probability = 0.5;
        }
      } else if (outcomeCount === 3) {
        // 三向市场
        const [r0, r1, r2] = outcomeLiquidity;
        let numerator = 0n;
        let denominator = r0 * r1 + r0 * r2 + r1 * r2;

        if (i === 0) {
          numerator = r1 * r2;
        } else if (i === 1) {
          numerator = r0 * r2;
        } else {
          numerator = r0 * r1;
        }

        if (denominator > 0n) {
          probability = Number(numerator) / Number(denominator);
        } else {
          // 初始状态：平均概率
          probability = 1 / 3;
        }
      } else {
        // 多结果市场（如 Score、PlayerProps）：使用简化的倒数求和法
        // price_i = (1/r_i) / Σ(1/r_j)
        let sumInverse = 0;
        for (let j = 0; j < outcomeCount; j++) {
          const r = Number(outcomeLiquidity[j]);
          if (r > 0) {
            sumInverse += 1 / r;
          }
        }

        const currentReserve = Number(reserve);
        if (currentReserve > 0 && sumInverse > 0) {
          probability = (1 / currentReserve) / sumInverse;
        } else {
          // 初始状态或储备为0：平均概率
          probability = 1 / outcomeCount;
        }
      }
    }

    // 计算赔率
    let odds: number;

    if (directOdds !== null) {
      // Parimutuel 模式：使用直接计算的赔率
      odds = directOdds;
    } else {
      // CPMM 模式：从概率计算赔率（考虑手续费）
      const feeRate = Number(marketData.feeRate) / 10000; // feeRate 是基点（如 200 = 2%）
      const effectiveProbability = probability * (1 - feeRate);
      odds = effectiveProbability > 0 ? 1 / effectiveProbability : 99.99;
    }

    // 根据模板类型获取 outcome 名称
    // 优先使用从合约获取的 line 值，如果没有则使用传入的参数
    const effectiveLine = marketData.line !== undefined
      ? marketData.line.toString()
      : line;
    const name = getOutcomeName(i, templateType || 'WDL', effectiveLine);

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
      liquidity: reserve,
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
 * 将千分位表示的盘口线转换为显示数字
 * 例如：2500 -> 2.5, 3000 -> 3.0
 */
function parseLineValue(lineStr?: string): number | null {
  if (!lineStr) return null;
  try {
    return parseFloat(lineStr) / 1000;
  } catch {
    return null;
  }
}

/**
 * 根据模板类型和 outcome ID 获取名称
 * @param outcomeId 结果 ID
 * @param templateType 模板类型
 * @param line 盘口线（千分位表示，如 "2500" = 2.5 球）
 */
function getOutcomeName(outcomeId: number, templateType: string, line?: string): string {
  // OU_MULTI 特殊处理：outcomeId = lineIndex * 2 + direction（仅半球盘）
  if (templateType === 'OU_MULTI') {
    const lineIndex = Math.floor(outcomeId / 2);
    const direction = outcomeId % 2; // 0=OVER, 1=UNDER

    // 常见的线配置（2.5, 3.5, 4.5）
    const lines = [2.5, 3.5, 4.5];
    const lineValue = lines[lineIndex] || lineIndex;

    if (direction === 0) {
      return `大于 ${lineValue} 球`;
    } else {
      return `小于 ${lineValue} 球`;
    }
  }

  // OU（单线大小球）：显示完整的盘口线信息
  if (templateType === 'OU') {
    const lineValue = parseLineValue(line);
    if (lineValue !== null) {
      const lineDisplay = lineValue % 1 === 0 ? lineValue.toFixed(1) : lineValue.toString();
      if (outcomeId === 0) {
        return `大于 ${lineDisplay} 球`;
      } else {
        return `小于 ${lineDisplay} 球`;
      }
    }
    // 如果没有盘口线信息，使用默认名称
    return outcomeId === 0 ? '大球' : '小球';
  }

  // AH（让球）：显示让球数
  if (templateType === 'AH') {
    const lineValue = parseLineValue(line);
    if (lineValue !== null) {
      const absValue = Math.abs(lineValue);
      const lineDisplay = absValue % 1 === 0 ? absValue.toFixed(1) : absValue.toString();
      // 让球市场：outcomeId 0 = 主队赢盘, 1 = 客队赢盘, 2 = 走盘（整球盘）
      if (outcomeId === 0) {
        return `主队让 ${lineDisplay} 球赢盘`;
      } else if (outcomeId === 1) {
        return `客队受让 ${lineDisplay} 球赢盘`;
      } else {
        return '走盘（退款）';
      }
    }
    // 没有盘口线信息时的默认名称
    const ahNames = ['主队赢盘', '客队赢盘', '走盘'];
    return ahNames[outcomeId] || `结果 ${outcomeId}`;
  }

  const nameMap: Record<string, string[]> = {
    WDL: ['主胜', '平局', '客胜'],
    OddEven: ['单数', '双数'],
    Score: [], // 精确比分需要特殊处理
  };

  const names = nameMap[templateType] || [];
  return names[outcomeId] || `结果 ${outcomeId}`;
}
