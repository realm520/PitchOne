'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import {
  useReferrerStatsOnChain,
  useReferrerStats,
  useReferralParams,
  formatUSDCFromWei,
} from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';
import { formatUnits } from 'viem';
import { useTranslation } from '@pitchone/i18n';

/**
 * ReferralStats 组件
 *
 * 功能：
 * 1. 显示推荐统计信息（推荐人数、累计返佣、有效推荐）
 * 2. 显示推荐系统参数（返佣比例、最小交易量）
 * 3. 支持链上数据和 Subgraph 数据混合显示
 *
 * @example
 * ```tsx
 * import { ReferralStats } from '@/components/referral/ReferralStats';
 *
 * export default function ReferralPage() {
 *   return <ReferralStats />;
 * }
 * ```
 */
export function ReferralStats() {
  const { t } = useTranslation();
  const { address, isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);

  // 避免 hydration 错误
  useEffect(() => {
    setMounted(true);
  }, []);

  // 链上查询：推荐统计（实时准确）
  const { data: onChainStats, isLoading: onChainLoading } = useReferrerStatsOnChain(address);

  // Subgraph 查询：详细统计（可能有延迟）
  const { stats: subgraphStats, loading: subgraphLoading } = useReferrerStats(address);

  // 推荐系统参数
  const { feeBps, minVolume, validityWindow, isLoading: paramsLoading } = useReferralParams();

  if (!mounted) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <div className="w-12 h-12 mx-auto mb-4 animate-pulse bg-gray-700 rounded-full" />
          <p className="text-gray-400 text-sm">{t('referral.loading')}</p>
        </div>
      </Card>
    );
  }

  if (!isConnected) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <svg
            className="w-12 h-12 mx-auto mb-4 text-gray-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          <p className="text-gray-400 text-sm">{t('referral.connectWalletForStats')}</p>
        </div>
      </Card>
    );
  }

  const isLoading = onChainLoading || subgraphLoading;

  // 优先使用链上数据（更准确），Subgraph 数据作为补充
  const referralCount = Number(onChainStats?.count || 0);
  const totalRewards = onChainStats?.rewards
    ? formatUSDCFromWei(onChainStats.rewards)
    : '0';
  const validReferralCount = subgraphStats?.validReferralCount || 0;

  // 推荐系统参数
  const feeBpsNumber = feeBps && typeof feeBps === 'bigint' ? Number(feeBps) : 0;
  const feePercentage = (feeBpsNumber / 100).toFixed(2);
  const minVolumeFormatted = minVolume && typeof minVolume === 'bigint' ? formatUnits(minVolume, 6) : '0';
  const validityDays = validityWindow && typeof validityWindow === 'bigint' ? Number(validityWindow) / 86400 : 0; // 转换秒为天

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* 推荐人数 */}
      <Card padding="lg">
        <div className="flex items-start justify-between mb-3">
          <div>
            <p className="text-sm text-gray-400 mb-1">{t('referral.stats.referralCount')}</p>
            {isLoading ? (
              <div className="h-8 w-20 bg-gray-700 animate-pulse rounded" />
            ) : (
              <h3 className="text-3xl font-bold text-white">{referralCount}</h3>
            )}
          </div>
          <div className="w-12 h-12 rounded-full bg-neon-blue/20 flex items-center justify-center">
            <svg className="w-6 h-6 text-neon-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="info" size="sm">
            {t('referral.stats.validCount')}: {validReferralCount}
          </Badge>
        </div>
      </Card>

      {/* 累计返佣 */}
      <Card padding="lg">
        <div className="flex items-start justify-between mb-3">
          <div>
            <p className="text-sm text-gray-400 mb-1">{t('referral.stats.totalRewards')}</p>
            {isLoading ? (
              <div className="h-8 w-32 bg-gray-700 animate-pulse rounded" />
            ) : (
              <h3 className="text-3xl font-bold text-neon-green">{totalRewards}</h3>
            )}
            <p className="text-xs text-gray-500 mt-1">USDC</p>
          </div>
          <div className="w-12 h-12 rounded-full bg-neon-green/20 flex items-center justify-center">
            <svg className="w-6 h-6 text-neon-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="success" size="sm">
            {feePercentage}% {t('referral.stats.commissionRate')}
          </Badge>
        </div>
      </Card>

      {/* 推荐系统参数 */}
      <Card padding="lg">
        <div className="flex items-start justify-between mb-3">
          <div>
            <p className="text-sm text-gray-400 mb-1">{t('referral.stats.systemParams')}</p>
            {paramsLoading ? (
              <div className="h-8 w-20 bg-gray-700 animate-pulse rounded" />
            ) : (
              <h3 className="text-3xl font-bold text-neon-purple">{validityDays}</h3>
            )}
            <p className="text-xs text-gray-500 mt-1">{t('referral.stats.daysValidity')}</p>
          </div>
          <div className="w-12 h-12 rounded-full bg-neon-purple/20 flex items-center justify-center">
            <svg className="w-6 h-6 text-neon-purple" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
              />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </div>
        </div>
        <div className="space-y-1">
          <p className="text-xs text-gray-400">
            {t('referral.stats.minVolume')}: {minVolumeFormatted} USDC
          </p>
        </div>
      </Card>
    </div>
  );
}
