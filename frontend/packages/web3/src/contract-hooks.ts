'use client';

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { parseUnits, type Address } from 'viem';
import { MarketBaseABI, ERC20ABI, getContractAddresses } from '@pitchone/contracts';
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
 * 下注 hook
 * @param marketAddress 市场合约地址
 */
export function usePlaceBet(marketAddress?: Address) {
  const { chainId } = useAccount();
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

  const placeBet = async (outcomeId: number, amount: string) => {
    if (!marketAddress) throw new Error('Market address required');

    const amountInWei = parseUnits(amount, TOKEN_DECIMALS.USDC);

    console.log('[usePlaceBet] 发起下注:', {
      marketAddress,
      outcomeId,
      amount,
      amountInWei: amountInWei.toString()
    });

    return writeContract({
      address: marketAddress,
      abi: MarketBaseABI,
      functionName: 'placeBet',
      args: [BigInt(outcomeId), amountInWei],
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
 * 赎回赢得的份额 hook
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

  const redeem = async (outcomeId: number, shares: string) => {
    if (!marketAddress) throw new Error('Market address required');

    const sharesInWei = parseUnits(shares, TOKEN_DECIMALS.SHARES);

    return writeContract({
      address: marketAddress,
      abi: MarketBaseABI,
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
 * 查询用户在特定市场的头寸余额
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
    abi: MarketBaseABI,
    functionName: 'balanceOf',
    args: userAddress && outcomeId !== undefined ? [userAddress, BigInt(outcomeId)] : undefined,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress && !!userAddress && outcomeId !== undefined,
    },
  });
}

/**
 * 查询市场状态
 * @param marketAddress 市场合约地址
 */
export function useMarketStatus(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: MarketBaseABI,
    functionName: 'status',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
    },
  });
}

/**
 * 查询市场结果数量
 * @param marketAddress 市场合约地址
 */
export function useOutcomeCount(marketAddress?: Address) {
  return useReadContract({
    address: marketAddress,
    abi: MarketBaseABI,
    functionName: 'outcomeCount',
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress,
    },
  });
}

/**
 * 查询市场流动性
 * @param marketAddress 市场合约地址
 * @param outcomeId 结果 ID
 */
export function useOutcomeLiquidity(marketAddress?: Address, outcomeId?: number) {
  return useReadContract({
    address: marketAddress,
    abi: MarketBaseABI,
    functionName: 'outcomeLiquidity',
    args: outcomeId !== undefined ? [BigInt(outcomeId)] : undefined,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress && outcomeId !== undefined,
    },
  });
}

/**
 * 获取下注报价（shares）
 * @param marketAddress 市场合约地址
 * @param outcomeId 结果 ID
 * @param amount 下注金额（USDC，6 位小数）
 */
export function useQuote(marketAddress?: Address, outcomeId?: number, amount?: string) {
  const amountInWei = amount ? parseUnits(amount, TOKEN_DECIMALS.USDC) : BigInt(0);

  return useReadContract({
    address: marketAddress,
    abi: MarketBaseABI,
    functionName: 'getQuote',
    args: outcomeId !== undefined && amount ? [BigInt(outcomeId), amountInWei] : undefined,
    chainId: 31337, // Anvil 本地链
    query: {
      enabled: !!marketAddress && outcomeId !== undefined && !!amount && parseFloat(amount) > 0,
      // 报价数据实时性要求高，缓存时间短
      staleTime: 5000, // 5 秒
    },
  });
}
