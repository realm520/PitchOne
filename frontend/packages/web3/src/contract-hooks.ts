'use client';

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { parseUnits, type Address } from 'viem';
import { Market_V3_ABI, BettingRouter_V3_ABI, ERC20ABI, getContractAddresses } from '@pitchone/contracts';
import { TOKEN_DECIMALS } from './constants';

/**
 * 使用 USDC Approve hook
 * @param spender 被授权地址（通常是市场合约地址）
 * @param amount 授权金额（USDC，6 位小数）- 如果为 'max' 则授权最大值
 */
export function useApproveUSDC() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  const approve = async (spender: Address, amount: string | 'max' = 'max') => {
    if (!addresses) throw new Error('Chain not supported');

    // 默认授权最大值，避免用户反复授权（DeFi 标准做法）
    const amountInWei = amount === 'max'
      ? BigInt('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff') // type(uint256).max
      : parseUnits(amount, TOKEN_DECIMALS.USDC);

    return writeContract({
      address: addresses.usdc,
      abi: ERC20ABI,
      functionName: 'approve',
      args: [spender, amountInWei],
    });
  };

  return {
    approve,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 检查 USDC 授权额度
 * @param owner 代币所有者地址
 * @param spender 被授权地址
 */
export function useUSDCAllowance(owner?: Address, spender?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const result = useReadContract({
    address: addresses?.usdc,
    abi: ERC20ABI,
    functionName: 'allowance',
    args: owner && spender ? [owner, spender] : undefined,
    query: {
      enabled: !!owner && !!spender && !!addresses,
      // 添加重试和刷新配置
      retry: 3,
      retryDelay: 1000,
    },
  });

  // 调试日志
  console.log('[useUSDCAllowance] 查询参数:', {
    owner,
    spender,
    chainId,
    usdcAddress: addresses?.usdc,
    hasAddresses: !!addresses,
    enabled: !!owner && !!spender && !!addresses,
  });

  console.log('[useUSDCAllowance] 查询结果:', {
    hasData: result.data !== undefined,
    data: result.data?.toString(),
    isLoading: result.isLoading,
    isError: result.isError,
    error: result.error?.message,
    status: result.status,
  });

  return result;
}

/**
 * 查询 USDC 余额
 * @param address 用户地址
 */
export function useUSDCBalance(address?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  return useReadContract({
    address: addresses?.usdc,
    abi: ERC20ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address && !!addresses,
    },
  });
}

/**
 * 下注 hook (V3 架构通过 BettingRouter)
 * @param marketAddress 市场合约地址
 */
export function usePlaceBet(marketAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError,
    data: receipt
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  // 调试日志
  console.log('[usePlaceBet]:', {
    chainId,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    receiptStatus: receipt?.status,
    writeError: writeError?.message,
    receiptError: receiptError?.message
  });

  const placeBet = async (outcomeId: number, amount: string, minShares?: bigint) => {
    if (!marketAddress) throw new Error('Market address required');
    if (!addresses) throw new Error('Chain not supported');

    const amountInWei = parseUnits(amount, TOKEN_DECIMALS.USDC);
    // 默认最小份额为 0（无滑点保护），或使用传入的值
    const minSharesValue = minShares ?? 0n;

    console.log('[usePlaceBet] 发起下注:', {
      router: addresses.bettingRouter,
      marketAddress,
      outcomeId,
      amount,
      amountInWei: amountInWei.toString(),
      minShares: minSharesValue.toString()
    });

    // V3: 通过 BettingRouter 下注
    return writeContract({
      address: addresses.bettingRouter,
      abi: BettingRouter_V3_ABI,
      functionName: 'placeBet',
      args: [marketAddress, BigInt(outcomeId), amountInWei, minSharesValue],
    });
  };

  return {
    placeBet,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 赎回赢得的份额 hook (V3)
 * @param marketAddress 市场合约地址
 */
export function useRedeem(marketAddress?: Address) {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 赎回份额
   * @param outcomeId 结果 ID
   * @param shares 份额数量（字符串格式的原始 wei 值，从 Subgraph position.balance 获取）
   */
  const redeem = async (outcomeId: number, shares: string) => {
    if (!marketAddress) throw new Error('Market address required');

    // position.balance 从 Subgraph 返回的已经是原始 wei 值（BigInt 类型存储）
    // 不需要再用 parseUnits 转换，直接使用 BigInt 即可
    const sharesInWei = BigInt(shares);

    console.log('[useRedeem] 发起赎回:', {
      marketAddress,
      outcomeId,
      shares,
      sharesInWei: sharesInWei.toString(),
    });

    // V3: 直接调用 Market_V3.redeem
    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'redeem',
      args: [BigInt(outcomeId), sharesInWei],
    });
  };

  return {
    redeem,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 退款 hook（用于市场取消时）
 * @param marketAddress 市场合约地址
 */
export function useRefund(marketAddress?: Address) {
  const { address: userAddress, chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 申请退款
   * @param outcomeId 结果 ID
   * @param shares 份额数量（字符串格式的原始 wei 值，从 Subgraph position.balance 获取）
   */
  const refund = async (outcomeId: number, shares: string) => {
    if (!marketAddress) throw new Error('Market address required');
    if (!userAddress) throw new Error('Wallet not connected');

    const sharesInWei = BigInt(shares);

    console.log('[useRefund] 发起退款:', {
      marketAddress,
      userAddress,
      outcomeId,
      shares,
      sharesInWei: sharesInWei.toString(),
    });

    // V3: 调用 Market_V3.refundFor
    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'refundFor',
      args: [userAddress, BigInt(outcomeId), sharesInWei],
    });
  };

  return {
    refund,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 批量赎回多个市场的份额 hook
 * @description 用于一次性领取多个市场的奖励
 */
export function useRedeemBatch() {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 批量赎回同一市场的多个 outcome
   * @param marketAddress 市场地址
   * @param outcomeIds 结果 ID 数组
   * @param sharesArray 对应的份额数组
   */
  const redeemBatch = async (
    marketAddress: Address,
    outcomeIds: number[],
    sharesArray: string[]
  ) => {
    if (!marketAddress) throw new Error('Market address required');
    if (outcomeIds.length !== sharesArray.length) throw new Error('Arrays length mismatch');

    console.log('[useRedeemBatch] 发起批量赎回:', {
      marketAddress,
      outcomeIds,
      sharesArray,
    });

    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'redeemBatch',
      args: [
        outcomeIds.map(id => BigInt(id)),
        sharesArray.map(s => BigInt(s)),
      ],
    });
  };

  return {
    redeemBatch,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 查询用户在特定市场的头寸余额 (V3)
 * @param marketAddress 市场合约地址
 * @param userAddress 用户地址
 * @param outcomeId 结果 ID
 */
export function usePositionBalance(
  marketAddress?: Address,
  userAddress?: Address,
  outcomeId?: number
) {
  return useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'balanceOf',
    args: userAddress && outcomeId !== undefined ? [userAddress, BigInt(outcomeId)] : undefined,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress && !!userAddress && outcomeId !== undefined,
    },
  });
}

/**
 * 查询市场状态 (V3)
 * @param marketAddress 市场合约地址
 */
export function useMarketStatus(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'status',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
    },
  });
}

/**
 * 查询市场结果数量 (V3)
 * @param marketAddress 市场合约地址
 */
export function useOutcomeCount(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'outcomeCount',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
    },
  });
}

/**
 * 查询市场统计信息 (V3)
 * 替代旧的 outcomeLiquidity，返回完整的市场统计
 * @param marketAddress 市场合约地址
 */
export function useMarketStats(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'getStats',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
    },
  });
}

/**
 * 获取下注报价 (V3 通过 BettingRouter.previewBet)
 * @param marketAddress 市场合约地址
 * @param outcomeId 结果 ID
 * @param amount 下注金额（USDC，6 位小数）
 */
export function useQuote(marketAddress?: Address, outcomeId?: number, amount?: string) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const amountInWei = amount ? parseUnits(amount, TOKEN_DECIMALS.USDC) : BigInt(0);

  return useReadContract({
    address: addresses?.bettingRouter,
    abi: BettingRouter_V3_ABI,
    functionName: 'previewBet',
    args: marketAddress && outcomeId !== undefined && amount
      ? [marketAddress, BigInt(outcomeId), amountInWei]
      : undefined,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!addresses && !!marketAddress && outcomeId !== undefined && !!amount && parseFloat(amount) > 0,
      // 报价数据实时性要求高，缓存时间短
      staleTime: 5000, // 5 秒
    },
  });
}

/**
 * 获取市场所有结果的价格 (V3)
 * @param marketAddress 市场合约地址
 */
export function useAllPrices(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'getAllPrices',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
      staleTime: 5000, // 5 秒
    },
  });
}

/**
 * 检查市场是否已锁定 (V3)
 * V3 通过比较 kickoffTime 和当前时间判断
 * @param marketAddress 市场合约地址
 */
export function useIsMarketLocked(marketAddress?: Address) {
  const { data: kickoffTimeData } = useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'kickoffTime',
    chainId: 31337,
    query: {
      enabled: !!marketAddress,
    },
  });
  const kickoffTime = kickoffTimeData as bigint | undefined;

  const { data: statusData } = useReadContract({
    address: marketAddress,
    abi: Market_V3_ABI,
    functionName: 'status',
    chainId: 31337,
    query: {
      enabled: !!marketAddress,
      staleTime: 5000,
      refetchInterval: 10000,
    },
  });
  const status = statusData as number | undefined;

  // V3 状态枚举：0=Created, 1=Open, 2=Locked, 3=Resolved, 4=Finalized
  // 市场锁定条件：状态不是 Open(1) 或 当前时间 >= kickoffTime
  const isLocked = (status !== undefined && status !== 1) ||
    (kickoffTime !== undefined && BigInt(Math.floor(Date.now() / 1000)) >= kickoffTime);

  return {
    data: isLocked,
    isLoading: status === undefined,
  };
}
