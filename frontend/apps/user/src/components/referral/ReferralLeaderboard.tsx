'use client';

import { useReferralLeaderboard } from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

interface ReferralLeaderboardProps {
  /**
   * 显示的排行榜条目数量
   * @default 10
   */
  limit?: number;
}

/**
 * ReferralLeaderboard 组件
 *
 * 功能：
 * 1. 显示推荐系统排行榜（按累计返佣排序）
 * 2. 显示每位推荐人的统计信息
 * 3. 高亮显示前三名
 *
 * @example
 * ```tsx
 * import { ReferralLeaderboard } from '@/components/referral/ReferralLeaderboard';
 *
 * export default function LeaderboardPage() {
 *   return <ReferralLeaderboard limit={20} />;
 * }
 * ```
 */
export function ReferralLeaderboard({ limit = 10 }: ReferralLeaderboardProps) {
  const { t } = useTranslation();
  const { leaderboard, loading, error } = useReferralLeaderboard(limit);

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
          <p className="text-red-400 text-sm">{t('referral.leaderboardComp.loadError')}</p>
          <p className="text-gray-500 text-xs mt-1">{error.message}</p>
        </div>
      </Card>
    );
  }

  if (loading && leaderboard.length === 0) {
    return (
      <Card padding="lg">
        <div className="space-y-4">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="flex items-center gap-4">
                <div className="w-8 h-8 rounded-full bg-gray-700" />
                <div className="w-10 h-10 rounded-full bg-gray-700" />
                <div className="flex-1">
                  <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
                  <div className="h-3 bg-gray-700 rounded w-1/4" />
                </div>
                <div className="h-6 bg-gray-700 rounded w-24" />
              </div>
            </div>
          ))}
        </div>
      </Card>
    );
  }

  if (leaderboard.length === 0) {
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
              d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
            />
          </svg>
          <p className="text-gray-400 text-sm">{t('referral.leaderboardComp.empty')}</p>
        </div>
      </Card>
    );
  }

  // 获取排名徽章样式
  const getRankBadge = (rank: number) => {
    switch (rank) {
      case 1:
        return {
          icon: '🥇',
          gradient: 'from-yellow-400 to-yellow-600',
          color: 'text-yellow-400',
        };
      case 2:
        return {
          icon: '🥈',
          gradient: 'from-gray-300 to-gray-500',
          color: 'text-gray-300',
        };
      case 3:
        return {
          icon: '🥉',
          gradient: 'from-orange-400 to-orange-600',
          color: 'text-orange-400',
        };
      default:
        return {
          icon: rank.toString(),
          gradient: 'from-gray-600 to-gray-700',
          color: 'text-gray-400',
        };
    }
  };

  return (
    <Card padding="none">
      {/* 标题 */}
      <div className="px-6 py-4 border-b border-dark-border bg-gradient-to-r from-neon-purple/10 to-neon-blue/10">
        <div className="flex items-center gap-3">
          <svg
            className="w-6 h-6 text-neon-purple"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"
            />
          </svg>
          <div>
            <h3 className="text-lg font-bold text-white">{t('referral.leaderboardComp.title')}</h3>
            <p className="text-sm text-gray-400">{t('referral.leaderboardComp.sortBy')}</p>
          </div>
        </div>
      </div>

      {/* 排行榜列表 */}
      <div className="divide-y divide-dark-border">
        {leaderboard.map((entry: any, index: number) => {
          const rank = index + 1;
          const { icon, gradient, color } = getRankBadge(rank);
          const isTopThree = rank <= 3;

          // 防御性检查：如果 ID 为空，跳过该记录
          if (!entry.id) {
            console.warn('[ReferralLeaderboard] 跳过无效的排行榜记录:', entry);
            return null;
          }

          return (
            <div
              key={entry.id}
              className={`px-6 py-4 hover:bg-dark-card/50 transition-colors ${
                isTopThree ? 'bg-dark-card/30' : ''
              }`}
            >
              <div className="flex items-center gap-4">
                {/* 排名徽章 */}
                <div
                  className={`w-10 h-10 rounded-full bg-gradient-to-br ${gradient} flex items-center justify-center font-bold text-white shadow-lg`}
                >
                  {icon}
                </div>

                {/* 用户头像 */}
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-neon-blue to-neon-purple flex items-center justify-center text-white text-sm font-bold">
                  {entry.id.slice(2, 4).toUpperCase()}
                </div>

                {/* 用户信息 */}
                <div className="flex-1 min-w-0">
                  <p className={`text-sm font-medium ${color} truncate`}>
                    {entry.id.slice(0, 6)}...{entry.id.slice(-4)}
                  </p>
                  <div className="flex items-center gap-3 mt-1">
                    <span className="text-xs text-gray-500">
                      {entry.referralCount} {t('referral.leaderboardComp.referrals')}
                    </span>
                    <span className="text-xs text-gray-500">•</span>
                    <span className="text-xs text-gray-500">
                      {entry.validReferralCount} {t('referral.leaderboardComp.active')}
                    </span>
                  </div>
                </div>

                {/* 返佣金额 */}
                <div className="text-right">
                  <Badge variant="success" size="lg">
                    {Number(entry.totalRewards).toFixed(4)} USDC
                  </Badge>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* 底部提示 */}
      <div className="px-6 py-3 border-t border-dark-border bg-dark-card/50">
        <p className="text-xs text-gray-500 text-center">
          {t('referral.leaderboardComp.updateNote')}
        </p>
      </div>
    </Card>
  );
}
