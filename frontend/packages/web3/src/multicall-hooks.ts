import { useReadContracts } from 'wagmi';
import { MarketBaseABI, getContractAddresses } from '@pitchone/contracts';
import type { Address } from 'viem';
import { useAccount } from 'wagmi';

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
  const { data: outcomeCount } = useReadContracts({
    contracts: [
      {
        address: marketAddress,
        abi: MarketBaseABI,
        functionName: 'outcomeCount',
      },
    ],
    query: {
      enabled: !!marketAddress,
      staleTime: 60000, // 1 分钟
    },
  });

  const count = outcomeCount?.[0]?.result as bigint | undefined;
  const outcomeCountNumber = count ? Number(count) : 0;

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

  const { data, isLoading, error, refetch } = useReadContracts({
    contracts: contracts as any,
    query: {
      enabled: !!marketAddress && outcomeCountNumber > 0,
      staleTime: 10000, // 10 秒
    },
  });

  // 解析数据
  if (!data || !outcomeCountNumber) {
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
