'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import { useReferralRewards } from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

/**
 * ReferralRewardsHistory 组件
 *
 * 功能：
 * 1. 显示推荐返佣历史记录
 * 2. 显示每笔返佣的详细信息（金额、时间、被推荐人）
 * 3. 支持查看交易哈希
 *
 * @example
 * ```tsx
 * import { ReferralRewardsHistory } from '@/components/referral/ReferralRewardsHistory';
 *
 * export default function ReferralPage() {
 *   return <ReferralRewardsHistory />;
 * }
 * ```
 */
export function ReferralRewardsHistory() {
  const { t } = useTranslation();
  const { address, isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);
  const { rewards, loading, error } = useReferralRewards(address, 50);

  // 避免 hydration 错误
  useEffect(() => {
    setMounted(true);
  }, []);

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
              d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm">{t('referral.historyComp.connectWallet')}</p>
        </div>
      </Card>
    );
  }

  if (error) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <svg
            className="w-12 h-12 mx-auto mb-4 text-red-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <p className="text-red-400 text-sm">{t('referral.historyComp.loadError')}</p>
          <p className="text-gray-500 text-xs mt-1">{error.message}</p>
        </div>
      </Card>
    );
  }

  if (loading && rewards.length === 0) {
    return (
      <Card padding="lg">
        <div className="space-y-4">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
                  <div className="h-3 bg-gray-700 rounded w-1/4" />
                </div>
                <div className="h-6 bg-gray-700 rounded w-20" />
              </div>
            </div>
          ))}
        </div>
      </Card>
    );
  }

  if (rewards.length === 0) {
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
              d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm mb-2">{t('referral.historyComp.empty')}</p>
          <p className="text-gray-500 text-xs">
            {t('referral.historyComp.emptyDesc')}
          </p>
        </div>
      </Card>
    );
  }

  // 计算总返佣金额
  const totalRewards = rewards.reduce(
    (sum: number, reward: any) => sum + Number(reward.amount),
    0
  );

  return (
    <Card padding="none">
      {/* 标题 + 总计 */}
      <div className="px-6 py-4 border-b border-dark-border">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-white">{t('referral.historyComp.title')}</h3>
            <p className="text-sm text-gray-400 mt-1">
              {t('referral.historyComp.totalRecords', { count: rewards.length })}
            </p>
          </div>
          <div className="text-right">
            <p className="text-sm text-gray-400">{t('referral.historyComp.totalRewards')}</p>
            <p className="text-2xl font-bold text-neon-green">
              {totalRewards.toFixed(4)}
            </p>
            <p className="text-xs text-gray-500">USDC</p>
          </div>
        </div>
      </div>

      {/* 返佣记录列表 */}
      <div className="max-h-96 overflow-y-auto divide-y divide-dark-border scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800">
        {rewards.map((reward: any) => {
          const rewardDate = new Date(Number(reward.timestamp) * 1000);
          const refereeAddress = reward.referee?.id;

          // 防御性检查：如果 referee 为空，跳过该记录
          if (!refereeAddress) {
            console.warn('[ReferralRewardsHistory] 跳过无效的返佣记录:', reward.id);
            return null;
          }

          return (
            <div
              key={reward.id}
              className="px-6 py-4 hover:bg-dark-card/50 transition-colors"
            >
              <div className="flex items-center justify-between mb-2">
                {/* 被推荐人信息 */}
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-green to-green-400 flex items-center justify-center">
                    <svg
                      className="w-4 h-4 text-white"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                      />
                    </svg>
                  </div>
                  <div>
                    <p className="text-sm font-medium text-white">
                      {t('referral.historyComp.from')}{' '}
                      {refereeAddress.slice(0, 6)}...
                      {refereeAddress.slice(-4)}
                    </p>
                    <p className="text-xs text-gray-500">
                      {rewardDate.toLocaleString()}
                    </p>
                  </div>
                </div>

                {/* 返佣金额 */}
                <div className="text-right">
                  <Badge variant="success" size="md">
                    +{Number(reward.amount).toFixed(4)} USDC
                  </Badge>
                </div>
              </div>

              {/* 交易哈希 */}
              <div className="flex items-center justify-between text-xs">
                <span className="text-gray-500">
                  {t('referral.historyComp.block')} #{reward.blockNumber.toString()}
                </span>
                <a
                  href={`https://etherscan.io/tx/${reward.transactionHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-neon-blue hover:text-neon-purple transition-colors"
                >
                  {t('referral.historyComp.viewTx')} ↗
                </a>
              </div>
            </div>
          );
        })}
      </div>

      {/* 底部提示 */}
      <div className="px-6 py-3 border-t border-dark-border bg-dark-card/50">
        <p className="text-xs text-gray-500 text-center">
          {t('referral.historyComp.autoPayNote')}
        </p>
      </div>
    </Card>
  );
}
