'use client';

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { parseUnits, type Address, formatUnits } from 'viem';
import { BasketABI, getContractAddresses } from '@pitchone/contracts';
import { useMemo } from 'react';

// ============================================================================
// 类型定义
// ============================================================================

/**
 * 串关腿（Parlay Leg）数据结构
 */
export interface ParlayLeg {
  marketAddress: Address;
  outcomeId: number;
}

/**
 * 串关状态枚举
 */
export enum ParlayStatus {
  Pending = 0,
  Won = 1,
  Lost = 2,
  Cancelled = 3,
}

/**
 * 串关数据结构
 */
export interface Parlay {
  user: Address;
  legs: ParlayLeg[];
  stake: bigint;
  potentialPayout: bigint;
  combinedOdds: bigint;
  penaltyBps: bigint;
  status: ParlayStatus;
  createdAt: bigint;
  settledAt: bigint;
}

/**
 * 串关报价（Quote）结果
 */
export interface ParlayQuote {
  combinedOdds: bigint;      // 组合赔率（基点，10000 = 1.0x）
  penaltyBps: bigint;        // 相关性惩罚基点
  potentialPayout: bigint;   // 潜在赔付金额
}

// ============================================================================
// 只读 Hooks
// ============================================================================

/**
 * 获取串关报价（组合赔率和潜在赔付）
 * @param legs 串关腿数组
 * @param stake 下注金额（USDC，单位：元）
 * @returns 报价信息（组合赔率、惩罚、潜在赔付）
 */
export function useParlayQuote(legs?: ParlayLeg[], stake?: string) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const stakeInWei = stake ? parseUnits(stake, 6) : 0n;

  const { data, isLoading, isError, error, refetch } = useReadContract({
    address: addresses?.basket,
    abi: BasketABI,
    functionName: 'quote',
    args: legs && stake ? [legs, stakeInWei] : undefined,
    query: {
      enabled: !!legs && legs.length >= 2 && !!stake && !!addresses,
    },
  });

  const quote = useMemo<ParlayQuote | null>(() => {
    if (!data) return null;
    const [combinedOdds, penaltyBps, potentialPayout] = data as [bigint, bigint, bigint];
    return {
      combinedOdds,
      penaltyBps,
      potentialPayout,
    };
  }, [data]);

  // 格式化的赔率（如 3.5x）
  const formattedOdds = quote
    ? Number(formatUnits(quote.combinedOdds, 4)).toFixed(2) + 'x'
    : null;

  // 格式化的潜在赔付（USDC）
  const formattedPayout = quote
    ? formatUnits(quote.potentialPayout, 6)
    : null;

  // 相关性惩罚百分比（如 -5%）
  const penaltyPercentage = quote
    ? Number(formatUnits(quote.penaltyBps, 2)).toFixed(2) + '%'
    : null;

  return {
    quote,
    formattedOdds,
    formattedPayout,
    penaltyPercentage,
    isLoading,
    isError,
    error,
    refetch,
  };
}

/**
 * 获取串关详情
 * @param parlayId 串关ID
 * @returns 串关完整信息
 */
export function useParlayDetails(parlayId?: number) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isLoading, isError, error, refetch } = useReadContract({
    address: addresses?.basket,
    abi: BasketABI,
    functionName: 'getParlay',
    args: parlayId !== undefined ? [BigInt(parlayId)] : undefined,
    query: {
      enabled: parlayId !== undefined && !!addresses,
    },
  });

  const parlay = data as Parlay | undefined;

  return {
    parlay,
    isLoading,
    isError,
    error,
    refetch,
  };
}

/**
 * 获取用户的所有串关ID
 * @param userAddress 用户地址
 * @returns 串关ID数组
 */
export function useUserParlays(userAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isLoading, isError, error, refetch } = useReadContract({
    address: addresses?.basket,
    abi: BasketABI,
    functionName: 'getUserParlays',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!userAddress && !!addresses,
    },
  });

  const parlayIds = data as bigint[] | undefined;

  return {
    parlayIds: parlayIds?.map(id => Number(id)) || [],
    isLoading,
    isError,
    error,
    refetch,
  };
}

/**
 * 检查串关是否可结算
 * @param parlayId 串关ID
 * @returns 是否可结算以及预期状态
 */
export function useCanSettle(parlayId?: number) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isLoading, isError, error, refetch } = useReadContract({
    address: addresses?.basket,
    abi: BasketABI,
    functionName: 'canSettle',
    args: parlayId !== undefined ? [BigInt(parlayId)] : undefined,
    query: {
      enabled: parlayId !== undefined && !!addresses,
    },
  });

  const [canSettle, status] = (data as [boolean, ParlayStatus] | undefined) || [false, ParlayStatus.Pending];

  return {
    canSettle,
    status,
    isLoading,
    isError,
    error,
    refetch,
  };
}

/**
 * 获取 Basket 池状态
 * @returns reserveFund, totalLockedStake, totalPotentialPayout
 */
export function usePoolStatus() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isLoading, isError, error, refetch } = useReadContract({
    address: addresses?.basket,
    abi: BasketABI,
    functionName: 'getPoolStatus',
    query: {
      enabled: !!addresses,
    },
  });

  const [reserveFund, totalLockedStake, totalPotentialPayout] = (data as [bigint, bigint, bigint] | undefined) || [
    0n,
    0n,
    0n,
  ];

  return {
    reserveFund,
    totalLockedStake,
    totalPotentialPayout,
    formattedReserve: formatUnits(reserveFund, 6),
    formattedLocked: formatUnits(totalLockedStake, 6),
    formattedPotential: formatUnits(totalPotentialPayout, 6),
    isLoading,
    isError,
    error,
    refetch,
  };
}

// ============================================================================
// 写入 Hooks
// ============================================================================

/**
 * 创建串关 Hook
 * @returns createParlay 函数和交易状态
 */
export function useCreateParlay() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError,
    data: receipt,
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    },
  });

  // 调试日志
  console.log('[useCreateParlay]:', {
    chainId,
    hash,
    isPending,
    isConfirming,
    isSuccess,
    receiptStatus: receipt?.status,
    writeError: writeError?.message,
    receiptError: receiptError?.message,
  });

  /**
   * 创建串关
   * @param legs 串关腿数组（市场地址 + 结果ID）
   * @param stake 下注金额（USDC，单位：元）
   */
  const createParlay = async (legs: ParlayLeg[], stake: string) => {
    if (!addresses) throw new Error('Chain not supported');
    if (legs.length < 2) throw new Error('At least 2 legs required for parlay');
    if (legs.length > 10) throw new Error('Maximum 10 legs allowed');

    const stakeInWei = parseUnits(stake, 6); // USDC 使用 6 位小数

    console.log('[useCreateParlay] 发起串关:', {
      basketAddress: addresses.basket,
      legs,
      stake,
      stakeInWei: stakeInWei.toString(),
    });

    return writeContract({
      address: addresses.basket,
      abi: BasketABI,
      functionName: 'createParlay',
      args: [legs, stakeInWei],
    });
  };

  return {
    createParlay,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
    receipt,
  };
}

/**
 * 结算串关 Hook
 * @returns settle 函数和交易状态
 */
export function useSettleParlay() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError,
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    },
  });

  /**
   * 结算串关
   * @param parlayId 串关ID
   */
  const settle = async (parlayId: number) => {
    if (!addresses) throw new Error('Chain not supported');

    console.log('[useSettleParlay] 发起结算:', {
      basketAddress: addresses.basket,
      parlayId,
    });

    return writeContract({
      address: addresses.basket,
      abi: BasketABI,
      functionName: 'settle',
      args: [BigInt(parlayId)],
    });
  };

  return {
    settle,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 批量结算串关 Hook
 * @returns batchSettle 函数和交易状态
 */
export function useBatchSettleParlays() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError,
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    },
  });

  /**
   * 批量结算串关
   * @param parlayIds 串关ID数组
   */
  const batchSettle = async (parlayIds: number[]) => {
    if (!addresses) throw new Error('Chain not supported');

    const parlayIdsBigInt = parlayIds.map(id => BigInt(id));

    console.log('[useBatchSettleParlays] 发起批量结算:', {
      basketAddress: addresses.basket,
      parlayIds,
    });

    return writeContract({
      address: addresses.basket,
      abi: BasketABI,
      functionName: 'batchSettle',
      args: [parlayIdsBigInt],
    });
  };

  return {
    batchSettle,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}
