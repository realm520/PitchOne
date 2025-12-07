'use client';

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { type Address } from 'viem';
import { ReferralRegistryABI, getContractAddresses } from '@pitchone/contracts';
import { useEffect, useState } from 'react';
import {
  graphqlClient,
  REFERRER_STATS_QUERY,
  REFERRER_REFERRALS_QUERY,
  REFERRAL_REWARDS_QUERY,
  REFERRAL_LEADERBOARD_QUERY,
} from './graphql';

// ============================================================================
// 类型定义
// ============================================================================

/**
 * 推荐人统计数据
 */
export interface ReferrerStats {
  count: bigint;
  rewards: bigint;
}

/**
 * 推荐参数配置
 */
export interface ReferralParams {
  feeBps: bigint;     // 返佣比例（基点，如 800 = 8%）
  minVolume: bigint;  // 最小有效交易量
}

// ============================================================================
// 写入 Hooks
// ============================================================================

/**
 * 绑定推荐人 Hook
 * @returns 绑定推荐人的函数和状态
 *
 * @example
 * ```tsx
 * const { bindReferral, isPending, isSuccess } = useBindReferral();
 *
 * const handleBind = async () => {
 *   await bindReferral('0x123...', 0n);
 * };
 * ```
 */
export function useBindReferral() {
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

  /**
   * 绑定推荐人
   * @param referrer 推荐人地址
   * @param campaignId 活动 ID（默认 0 = 常规推荐）
   */
  const bindReferral = async (referrer: Address, campaignId: bigint = 0n) => {
    if (!addresses?.referralRegistry) {
      throw new Error('ReferralRegistry 合约未部署');
    }

    console.log('[useBindReferral] 绑定推荐人:', { referrer, campaignId });

    return writeContract({
      address: addresses.referralRegistry,
      abi: ReferralRegistryABI,
      functionName: 'bind',
      args: [referrer, campaignId],
    });
  };

  return {
    bindReferral,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

// ============================================================================
// 只读 Hooks（链上查询）
// ============================================================================

/**
 * 获取用户的推荐人
 * @param userAddress 用户地址
 * @returns 推荐人地址（0x0 表示无推荐人）
 *
 * @example
 * ```tsx
 * const { data: referrer, isLoading } = useGetReferrer(address);
 * if (referrer && referrer !== '0x0000000000000000000000000000000000000000') {
 *   console.log('推荐人:', referrer);
 * }
 * ```
 */
export function useGetReferrer(userAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const result = useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'getReferrer',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!addresses?.referralRegistry && !!userAddress,
    },
  });

  return {
    ...result,
    refetch: result.refetch,
  };
}

/**
 * 获取推荐人统计（链上）
 * @param referrerAddress 推荐人地址
 * @returns 推荐人数和累计返佣
 *
 * @example
 * ```tsx
 * const { data, isLoading } = useReferrerStatsOnChain(referrerAddress);
 * if (data) {
 *   console.log('推荐人数:', data.count);
 *   console.log('累计返佣:', formatUnits(data.rewards, 6), 'USDC');
 * }
 * ```
 */
export function useReferrerStatsOnChain(referrerAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const result = useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'getReferrerStats',
    args: referrerAddress ? [referrerAddress] : undefined,
    query: {
      enabled: !!addresses?.referralRegistry && !!referrerAddress,
    },
  });

  // 格式化返回数据
  // 返回值是元组 [count, rewards]
  const tupleData = result.data as readonly [bigint, bigint] | undefined;
  const data = tupleData ? {
    count: tupleData[0],
    rewards: tupleData[1],
  } : undefined;

  return {
    ...result,
    data,
  };
}

/**
 * 检查推荐关系是否有效
 * @param userAddress 用户地址
 * @returns 是否有效（true/false）
 *
 * @example
 * ```tsx
 * const { data: isValid, isLoading } = useIsReferralValid(address);
 * if (isValid) {
 *   console.log('推荐关系有效');
 * }
 * ```
 */
export function useIsReferralValid(userAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  return useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'isReferralValid',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!addresses?.referralRegistry && !!userAddress,
    },
  });
}

/**
 * 获取推荐系统参数
 * @returns 返佣比例和最小交易量
 *
 * @example
 * ```tsx
 * const { feeBps, minVolume, isLoading } = useReferralParams();
 * if (feeBps) {
 *   console.log('返佣比例:', Number(feeBps) / 100, '%');
 * }
 * ```
 */
export function useReferralParams() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const feeBps = useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'referralFeeBps',
    query: {
      enabled: !!addresses?.referralRegistry,
    },
  });

  const minVolume = useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'minValidVolume',
    query: {
      enabled: !!addresses?.referralRegistry,
    },
  });

  const validityWindow = useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'validityWindow',
    query: {
      enabled: !!addresses?.referralRegistry,
    },
  });

  return {
    feeBps: feeBps.data,
    minVolume: minVolume.data,
    validityWindow: validityWindow.data,
    isLoading: feeBps.isLoading || minVolume.isLoading || validityWindow.isLoading,
    error: feeBps.error || minVolume.error || validityWindow.error,
  };
}

/**
 * 获取用户绑定时间
 * @param userAddress 用户地址
 * @returns 绑定时间戳
 */
export function useBoundAt(userAddress?: Address) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  return useReadContract({
    address: addresses?.referralRegistry,
    abi: ReferralRegistryABI,
    functionName: 'boundAt',
    args: userAddress ? [userAddress] : undefined,
    query: {
      enabled: !!addresses?.referralRegistry && !!userAddress,
    },
  });
}

// ============================================================================
// Subgraph 查询 Hooks
// ============================================================================

/**
 * 获取推荐人统计（Subgraph）
 * @param referrerAddress 推荐人地址
 * @returns 详细统计信息
 *
 * @example
 * ```tsx
 * const { stats, loading, error } = useReferrerStats(address);
 * if (stats) {
 *   console.log('推荐人数:', stats.referralCount);
 *   console.log('累计返佣:', stats.totalRewards, 'USDC');
 *   console.log('有效推荐:', stats.validReferralCount);
 * }
 * ```
 */
export function useReferrerStats(referrerAddress?: Address) {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!referrerAddress) return;

    setLoading(true);
    setError(null);

    const fetchStats = async () => {
      try {
        const referrerId = referrerAddress.toLowerCase();
        const data = await graphqlClient.request(REFERRER_STATS_QUERY, {
          referrerId,
        });

        setStats(data.referrerStat);
      } catch (err) {
        console.error('[useReferrerStats] 查询失败:', err);
        setError(err instanceof Error ? err : new Error('查询推荐统计失败'));
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, [referrerAddress]);

  return { stats, loading, error };
}

/**
 * 获取推荐列表
 * @param referrerAddress 推荐人地址
 * @param first 返回数量
 * @param skip 跳过数量
 * @returns 推荐列表
 *
 * @example
 * ```tsx
 * const { referrals, loading } = useReferrals(address, 20, 0);
 * ```
 */
export function useReferrals(referrerAddress?: Address, first = 20, skip = 0) {
  const [referrals, setReferrals] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!referrerAddress) return;

    setLoading(true);
    setError(null);

    const fetchReferrals = async () => {
      try {
        const referrerId = referrerAddress.toLowerCase();
        const data = await graphqlClient.request(REFERRER_REFERRALS_QUERY, {
          referrerId,
          first,
          skip,
        });

        setReferrals(data.referrerStat?.referrals || []);
      } catch (err) {
        console.error('[useReferrals] 查询失败:', err);
        setError(err instanceof Error ? err : new Error('查询推荐列表失败'));
      } finally {
        setLoading(false);
      }
    };

    fetchReferrals();
  }, [referrerAddress, first, skip]);

  return { referrals, loading, error };
}

/**
 * 获取返佣历史
 * @param referrerAddress 推荐人地址
 * @param first 返回数量
 * @returns 返佣记录列表
 *
 * @example
 * ```tsx
 * const { rewards, loading } = useReferralRewards(address, 50);
 * ```
 */
export function useReferralRewards(referrerAddress?: Address, first = 50) {
  const [rewards, setRewards] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!referrerAddress) return;

    setLoading(true);
    setError(null);

    const fetchRewards = async () => {
      try {
        const referrerId = referrerAddress.toLowerCase();
        const data = await graphqlClient.request(REFERRAL_REWARDS_QUERY, {
          referrerId,
          first,
        });

        setRewards(data.referrerStat?.rewardRecords || []);
      } catch (err) {
        console.error('[useReferralRewards] 查询失败:', err);
        setError(err instanceof Error ? err : new Error('查询返佣历史失败'));
      } finally {
        setLoading(false);
      }
    };

    fetchRewards();
  }, [referrerAddress, first]);

  return { rewards, loading, error };
}

/**
 * 获取推荐排行榜
 * @param first 返回数量
 * @returns 排行榜列表
 *
 * @example
 * ```tsx
 * const { leaderboard, loading } = useReferralLeaderboard(10);
 * ```
 */
export function useReferralLeaderboard(first = 10) {
  const [leaderboard, setLeaderboard] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const fetchLeaderboard = async () => {
      try {
        const data = await graphqlClient.request(REFERRAL_LEADERBOARD_QUERY, {
          first,
        });

        setLeaderboard(data.referrerStats || []);
      } catch (err) {
        console.error('[useReferralLeaderboard] 查询失败:', err);
        setError(err instanceof Error ? err : new Error('查询排行榜失败'));
      } finally {
        setLoading(false);
      }
    };

    fetchLeaderboard();
  }, [first]);

  return { leaderboard, loading, error };
}
