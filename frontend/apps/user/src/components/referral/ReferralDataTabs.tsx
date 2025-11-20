'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import { useReferrals, useReferrerStats, useReferralRewards } from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';

type TabType = 'list' | 'rewards';

/**
 * ReferralDataTabs 组件
 *
 * 功能：
 * 1. Tab 切换显示推荐列表和返佣记录
 * 2. 统一的界面风格和高度
 * 3. 完整的分页和数据展示
 *
 * @example
 * ```tsx
 * import { ReferralDataTabs } from '@/components/referral/ReferralDataTabs';
 *
 * export default function ReferralPage() {
 *   return <ReferralDataTabs />;
 * }
 * ```
 */
export function ReferralDataTabs() {
  const { address, isConnected } = useAccount();
  const [activeTab, setActiveTab] = useState<TabType>('list');
  const [page, setPage] = useState(0);
  const [mounted, setMounted] = useState(false);
  const pageSize = 10;

  // 避免 hydration 错误
  useEffect(() => {
    setMounted(true);
  }, []);

  // 切换 Tab 时重置页码
  useEffect(() => {
    setPage(0);
  }, [activeTab]);

  // 获取推荐列表（分页）
  const { referrals, loading: referralsLoading, error: referralsError } = useReferrals(
    address,
    pageSize,
    page * pageSize
  );

  // 获取推荐人统计（包含总人数）
  const { stats, loading: statsLoading } = useReferrerStats(address);

  // 获取返佣历史
  const { rewards, loading: rewardsLoading, error: rewardsError } = useReferralRewards(address, 50);

  if (!mounted) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <div className="w-12 h-12 mx-auto mb-4 animate-pulse bg-gray-700 rounded-full" />
          <p className="text-gray-400 text-sm">加载中...</p>
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
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm">请先连接钱包以查看推荐数据</p>
        </div>
      </Card>
    );
  }

  // 计算数据
  const totalReferrals = stats?.referralCount || 0;
  const totalPages = Math.ceil(totalReferrals / pageSize);
  const hasNextPage = referrals.length === pageSize;
  const hasPrevPage = page > 0;

  const totalRewards = rewards.reduce(
    (sum: number, reward: any) => sum + Number(reward.amount),
    0
  );

  return (
    <Card padding="none">
      {/* Tab 切换栏 */}
      <div className="border-b border-dark-border">
        <div className="flex">
          <button
            onClick={() => setActiveTab('list')}
            className={`flex-1 px-6 py-4 text-sm font-medium transition-colors relative ${
              activeTab === 'list'
                ? 'text-neon-blue'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              <span>推荐列表</span>
              {totalReferrals > 0 && (
                <Badge variant="info" size="sm">
                  {totalReferrals}
                </Badge>
              )}
            </div>
            {activeTab === 'list' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-neon-blue" />
            )}
          </button>

          <button
            onClick={() => setActiveTab('rewards')}
            className={`flex-1 px-6 py-4 text-sm font-medium transition-colors relative ${
              activeTab === 'rewards'
                ? 'text-neon-green'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            <div className="flex items-center justify-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span>返佣记录</span>
              {rewards.length > 0 && (
                <Badge variant="success" size="sm">
                  {rewards.length}
                </Badge>
              )}
            </div>
            {activeTab === 'rewards' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-neon-green" />
            )}
          </button>
        </div>
      </div>

      {/* Tab 内容 */}
      <div className="min-h-[500px]">
        {activeTab === 'list' ? (
          // 推荐列表内容
          <>
            {/* 标题 */}
            <div className="px-6 py-4 border-b border-dark-border">
              <p className="text-sm text-gray-400">
                {statsLoading ? (
                  '加载中...'
                ) : (
                  <>
                    共 <span className="text-neon-blue font-semibold">{totalReferrals}</span> 位用户
                    {totalPages > 1 && (
                      <span className="text-gray-500 ml-2">
                        · 第 {page + 1}/{totalPages} 页
                      </span>
                    )}
                  </>
                )}
              </p>
            </div>

            {referralsError ? (
              <div className="text-center py-12">
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
                <p className="text-gray-500 text-xs mt-1">{referralsError.message}</p>
              </div>
            ) : referralsLoading && referrals.length === 0 ? (
              <div className="px-6 py-8 space-y-4">
                {[...Array(3)].map((_, i) => (
                  <div key={i} className="animate-pulse flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-gray-700" />
                    <div className="flex-1">
                      <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
                      <div className="h-3 bg-gray-700 rounded w-1/4" />
                    </div>
                  </div>
                ))}
              </div>
            ) : referrals.length === 0 ? (
              <div className="text-center py-12">
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
            ) : (
              <>
                {/* 推荐列表 */}
                <div className="divide-y divide-dark-border">
                  {referrals.map((referral: any) => {
                    const boundDate = new Date(Number(referral.boundAt) * 1000);
                    const refereeAddress = referral.referee?.id;

                    if (!refereeAddress) {
                      return null;
                    }

                    return (
                      <div
                        key={referral.id}
                        className="px-6 py-4 hover:bg-dark-card/50 transition-colors"
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-neon-blue to-neon-purple flex items-center justify-center text-white text-sm font-bold">
                              {refereeAddress.slice(2, 4).toUpperCase()}
                            </div>
                            <div>
                              <p className="text-sm font-medium text-white">
                                {refereeAddress.slice(0, 6)}...{refereeAddress.slice(-4)}
                              </p>
                              <p className="text-xs text-gray-500">
                                绑定时间: {boundDate.toLocaleDateString('zh-CN')}
                              </p>
                            </div>
                          </div>
                          {Number(referral.campaignId) > 0 && (
                            <Badge variant="info" size="sm">
                              活动 #{referral.campaignId.toString()}
                            </Badge>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* 分页控制 */}
                {totalPages > 1 && (
                  <div className="px-6 py-4 border-t border-dark-border">
                    <div className="flex items-center justify-between">
                      <button
                        onClick={() => setPage(Math.max(0, page - 1))}
                        disabled={!hasPrevPage}
                        className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                        </svg>
                        上一页
                      </button>

                      <div className="flex items-center gap-2">
                        {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                          let pageNum: number;
                          if (totalPages <= 5) {
                            pageNum = i;
                          } else if (page < 2) {
                            pageNum = i;
                          } else if (page > totalPages - 3) {
                            pageNum = totalPages - 5 + i;
                          } else {
                            pageNum = page - 2 + i;
                          }

                          return (
                            <button
                              key={pageNum}
                              onClick={() => setPage(pageNum)}
                              className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                                pageNum === page
                                  ? 'bg-neon-blue text-white'
                                  : 'text-gray-400 hover:bg-dark-card hover:text-white'
                              }`}
                            >
                              {pageNum + 1}
                            </button>
                          );
                        })}
                      </div>

                      <button
                        onClick={() => setPage(page + 1)}
                        disabled={!hasNextPage}
                        className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
                      >
                        下一页
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                        </svg>
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
          </>
        ) : (
          // 返佣记录内容
          <>
            {/* 标题 + 总计 */}
            <div className="px-6 py-4 border-b border-dark-border">
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-400">
                  共 {rewards.length} 笔记录
                </p>
                <div className="text-right">
                  <p className="text-xs text-gray-400">累计返佣</p>
                  <p className="text-xl font-bold text-neon-green">
                    {totalRewards.toFixed(4)} USDC
                  </p>
                </div>
              </div>
            </div>

            {rewardsError ? (
              <div className="text-center py-12">
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
                <p className="text-red-400 text-sm">加载返佣历史失败</p>
                <p className="text-gray-500 text-xs mt-1">{rewardsError.message}</p>
              </div>
            ) : rewardsLoading && rewards.length === 0 ? (
              <div className="px-6 py-8 space-y-4">
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="animate-pulse flex items-center justify-between">
                    <div className="flex-1">
                      <div className="h-4 bg-gray-700 rounded w-1/3 mb-2" />
                      <div className="h-3 bg-gray-700 rounded w-1/4" />
                    </div>
                    <div className="h-6 bg-gray-700 rounded w-20" />
                  </div>
                ))}
              </div>
            ) : rewards.length === 0 ? (
              <div className="text-center py-12">
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
                <p className="text-gray-400 text-sm mb-2">暂无返佣记录</p>
                <p className="text-gray-500 text-xs">
                  当被推荐人下注后，您将获得返佣奖励
                </p>
              </div>
            ) : (
              <div className="max-h-[400px] overflow-y-auto divide-y divide-dark-border">
                {rewards.map((reward: any) => {
                  const rewardDate = new Date(Number(reward.timestamp) * 1000);
                  const refereeAddress = reward.referee?.id;

                  if (!refereeAddress) {
                    return null;
                  }

                  return (
                    <div
                      key={reward.id}
                      className="px-6 py-4 hover:bg-dark-card/50 transition-colors"
                    >
                      <div className="flex items-center justify-between mb-2">
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
                              来自 {refereeAddress.slice(0, 6)}...{refereeAddress.slice(-4)}
                            </p>
                            <p className="text-xs text-gray-500">
                              {rewardDate.toLocaleString('zh-CN')}
                            </p>
                          </div>
                        </div>
                        <Badge variant="success" size="md">
                          +{Number(reward.amount).toFixed(4)} USDC
                        </Badge>
                      </div>
                      <div className="flex items-center justify-between text-xs">
                        <span className="text-gray-500">
                          区块 #{reward.blockNumber.toString()}
                        </span>
                        <a
                          href={`https://etherscan.io/tx/${reward.transactionHash}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-neon-blue hover:text-neon-purple transition-colors"
                        >
                          查看交易 ↗
                        </a>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </>
        )}
      </div>
    </Card>
  );
}
