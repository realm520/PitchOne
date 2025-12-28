'use client';

import { useReadContracts, useAccount as useWagmiAccount } from 'wagmi';
import { Market_V3_ABI, getContractAddresses } from '@pitchone/contracts';
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
        abi: Market_V3_ABI,
        functionName: 'status',
      },
      {
        address: marketAddress,
        abi: Market_V3_ABI,
        functionName: 'totalLiquidity',
      },
      {
        address: marketAddress,
        abi: Market_V3_ABI,
        functionName: 'feeRate',
      },
      {
        address: marketAddress,
        // pricingStrategy 是 Market_V3 的公共变量
        abi: [
          {
            inputs: [],
            name: 'pricingStrategy',
            outputs: [{ internalType: 'address', name: '', type: 'address' }],
            stateMutability: 'view',
            type: 'function',
          },
        ],
        functionName: 'pricingStrategy',
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

    // 为每个结果查询投注份额（V3 使用 totalSharesPerOutcome）
    if (outcomeCountNumber > 0) {
      for (let i = 0; i < outcomeCountNumber; i++) {
        contracts.push({
          address: marketAddress,
          abi: Market_V3_ABI,
          functionName: 'totalSharesPerOutcome',
          args: [BigInt(i)],
        });
      }

      // 如果提供了用户地址，查询用户在每个结果的头寸
      if (userAddress) {
        for (let i = 0; i < outcomeCountNumber; i++) {
          contracts.push({
            address: marketAddress,
            abi: Market_V3_ABI,
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
  const pricingStrategy = (data[3]?.result as string)?.toLowerCase();
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
  const parimutuelAddress = getContractAddresses(chainId).strategies.parimutuel.toLowerCase();
  const isParimutel = pricingStrategy === parimutuelAddress;

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
    pricingStrategy,
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
      abi: Market_V3_ABI,
      functionName: 'status',
    },
    {
      address,
      abi: Market_V3_ABI,
      functionName: 'outcomeCount',
    },
    {
      address,
      abi: Market_V3_ABI,
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
 * 根据市场类型获取预期的 outcome 数量
 * 用于限制显示的结果数量，防止合约返回异常数据时显示过多按钮
 *
 * @param templateType 市场模板类型
 * @returns 预期的 outcome 数量，null 表示不限制
 */
function getExpectedOutcomeCount(templateType: string): number | null {
  switch (templateType) {
    case 'WDL': return 3;      // 胜平负：主胜、平局、客胜
    case 'OU': return 2;       // 大小球：大、小
    case 'OU_MULTI': return null; // 多线大小球：由线数决定
    case 'AH': return 3;       // 让球：主队赢盘、客队赢盘、走盘（整球盘）
    case 'OddEven': return 2;  // 单双：单、双
    case 'Score': return null; // 精确比分：不限制
    case 'PlayerProps': return null; // 球员道具：不限制
    default: return 3;         // 默认返回 3（WDL 最常见）
  }
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

  const rawOutcomeCount = Number(marketData.outcomeCount);
  const outcomeLiquidity = marketData.outcomeLiquidity;
  const totalLiquidity = marketData.totalLiquidity;

  // 根据市场类型限制显示的 outcome 数量
  // 防止合约返回异常数据时显示过多按钮
  const expectedCount = getExpectedOutcomeCount(templateType || 'WDL');
  const outcomeCount = expectedCount !== null
    ? Math.min(rawOutcomeCount, expectedCount)
    : rawOutcomeCount;

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
        // 确保赔率有效
        if (!isFinite(directOdds) || isNaN(directOdds)) {
          directOdds = null; // 标记为无效，后续显示 "-"
        }
      } else if (myBets === 0) {
        // 该结果没有投注，赔率为 null（显示 "-"）
        directOdds = null;
      } else {
        // 初始状态（总池为0）：赔率为 null
        directOdds = null;
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
    let odds: number | null;

    if (marketData.isParimutel) {
      // Parimutuel 模式：使用直接计算的赔率（可能为 null）
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
      odds: odds !== null ? odds.toFixed(2) : '-',
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
 * 根据模板类型和 outcome ID 获取 i18n key
 * @param outcomeId 结果 ID
 * @param templateType 模板类型
 * @param line 盘口线（千分位表示，如 "2500" = 2.5 球）
 * @returns i18n key（如 "outcomes.wdl.homeWin"）
 */
function getOutcomeName(outcomeId: number, templateType: string, line?: string): string {
  // OU_MULTI 特殊处理：outcomeId = lineIndex * 2 + direction（仅半球盘）
  if (templateType === 'OU_MULTI') {
    const direction = outcomeId % 2; // 0=OVER, 1=UNDER
    return direction === 0 ? 'outcomes.ou.over' : 'outcomes.ou.under';
  }

  // OU（单线大小球）
  if (templateType === 'OU') {
    return outcomeId === 0 ? 'outcomes.ou.over' : 'outcomes.ou.under';
  }

  // AH（让球）
  if (templateType === 'AH') {
    if (outcomeId === 0) {
      return 'outcomes.ah.homeCover';
    } else if (outcomeId === 1) {
      return 'outcomes.ah.awayCover';
    } else {
      return 'outcomes.ah.push';
    }
  }

  // OddEven（单双）
  if (templateType === 'OddEven') {
    return outcomeId === 0 ? 'outcomes.oddEven.odd' : 'outcomes.oddEven.even';
  }

  // WDL（胜平负）- 包括 WDL 和 WDL_Pari
  if (templateType === 'WDL' || templateType === 'WDL_Pari') {
    const keys = ['outcomes.wdl.homeWin', 'outcomes.wdl.draw', 'outcomes.wdl.awayWin'];
    return keys[outcomeId] || 'outcomes.fallback';
  }

  // Score（精确比分）- 包括 Score 和 Score_Pari
  if (templateType === 'Score' || templateType === 'Score_Pari') {
    if (outcomeId === 999) {
      return 'outcomes.score.other';
    }
    // 比分格式不需要翻译，直接返回
    const homeGoals = Math.floor(outcomeId / 10);
    const awayGoals = outcomeId % 10;
    return `${homeGoals}-${awayGoals}`;
  }

  // 默认返回 fallback key
  return 'outcomes.fallback';
}
