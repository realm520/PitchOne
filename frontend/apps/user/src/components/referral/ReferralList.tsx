'use client';

import { useState } from 'react';
import { useAccount } from '@pitchone/web3';
import { useReferrals } from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';

/**
 * ReferralList 组件
 *
 * 功能：
 * 1. 显示当前用户的被推荐人列表
 * 2. 显示每个被推荐人的基本信息（地址、绑定时间、下注统计）
 * 3. 支持分页加载
 *
 * @example
 * ```tsx
 * import { ReferralList } from '@/components/referral/ReferralList';
 *
 * export default function ReferralPage() {
 *   return <ReferralList />;
 * }
 * ```
 */
export function ReferralList() {
  const { address, isConnected } = useAccount();
  const [page, setPage] = useState(0);
  const pageSize = 10;

  const { referrals, loading, error } = useReferrals(
    address,
    pageSize,
    page * pageSize
  );

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
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm">请先连接钱包以查看推荐列表</p>
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
          <p className="text-red-400 text-sm">加载推荐列表失败</p>
          <p className="text-gray-500 text-xs mt-1">{error.message}</p>
        </div>
      </Card>
    );
  }

  if (loading && referrals.length === 0) {
    return (
      <Card padding="lg">
        <div className="space-y-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-full bg-gray-700" />
                <div className="flex-1">
                  <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
                  <div className="h-3 bg-gray-700 rounded w-1/4" />
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>
    );
  }

  if (referrals.length === 0) {
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
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm mb-2">暂无推荐用户</p>
          <p className="text-gray-500 text-xs">分享您的推荐链接以邀请好友</p>
        </div>
      </Card>
    );
  }

  return (
    <Card padding="none">
      {/* 标题 */}
      <div className="px-6 py-4 border-b border-dark-border">
        <h3 className="text-lg font-bold text-white">推荐列表</h3>
        <p className="text-sm text-gray-400 mt-1">
          共 {referrals.length} 位用户
        </p>
      </div>

      {/* 列表 */}
      <div className="divide-y divide-dark-border">
        {referrals.map((referral: any, index: number) => {
          const boundDate = new Date(Number(referral.boundAt) * 1000);
          const totalBets = referral.referee?.totalBets || 0;
          const totalBetAmount = referral.referee?.totalBetAmount || '0';

          return (
            <div
              key={referral.id}
              className="px-6 py-4 hover:bg-dark-card/50 transition-colors"
            >
              <div className="flex items-center justify-between">
                {/* 用户信息 */}
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-blue to-neon-purple flex items-center justify-center text-white text-sm font-bold">
                    {referral.referee.id.slice(2, 4).toUpperCase()}
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-sm font-medium text-white">
                        {referral.referee.id.slice(0, 6)}...{referral.referee.id.slice(-4)}
                      </p>
                      {totalBets > 0 && (
                        <Badge variant="success" size="sm">
                          活跃
                        </Badge>
                      )}
                    </div>
                    <p className="text-xs text-gray-500">
                      绑定时间: {boundDate.toLocaleDateString('zh-CN')}
                    </p>
                  </div>
                </div>

                {/* 统计信息 */}
                <div className="text-right">
                  <p className="text-sm font-medium text-white">
                    {totalBets} 笔下注
                  </p>
                  <p className="text-xs text-gray-500">
                    总额: {Number(totalBetAmount).toFixed(2)} USDC
                  </p>
                </div>
              </div>

              {/* Campaign ID (如果有) */}
              {Number(referral.campaignId) > 0 && (
                <div className="mt-2">
                  <Badge variant="info" size="sm">
                    活动 #{referral.campaignId.toString()}
                  </Badge>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* 分页控制 */}
      {referrals.length >= pageSize && (
        <div className="px-6 py-4 border-t border-dark-border flex items-center justify-between">
          <button
            onClick={() => setPage(Math.max(0, page - 1))}
            disabled={page === 0}
            className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            上一页
          </button>

          <p className="text-sm text-gray-400">
            第 {page + 1} 页
          </p>

          <button
            onClick={() => setPage(page + 1)}
            disabled={referrals.length < pageSize}
            className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            下一页
          </button>
        </div>
      )}
    </Card>
  );
}
