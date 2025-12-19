'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import { useReferrals, useReferrerStats } from '@pitchone/web3';
import { Card, Badge } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';

/**
 * ReferralList 组件
 *
 * 功能：
 * 1. 显示当前用户的被推荐人列表
 * 2. 显示每个被推荐人的基本信息（地址、绑定时间、下注统计）
 * 3. 支持分页加载
 * 4. 显示总推荐人数和总页数
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
  const { t } = useTranslation();
  const { address, isConnected } = useAccount();
  const [page, setPage] = useState(0);
  const [mounted, setMounted] = useState(false);
  const pageSize = 10;

  // 避免 hydration 错误
  useEffect(() => {
    setMounted(true);
  }, []);

  // 获取推荐列表（分页）
  const { referrals, loading, error } = useReferrals(
    address,
    pageSize,
    page * pageSize
  );

  // 获取推荐人统计（包含总人数）
  const { stats, loading: statsLoading } = useReferrerStats(address);

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
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <p className="text-gray-400 text-sm">{t('referral.listComp.connectWallet')}</p>
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
          <p className="text-red-400 text-sm">{t('referral.listComp.loadError')}</p>
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
          <p className="text-gray-400 text-sm mb-2">{t('referral.listComp.empty')}</p>
          <p className="text-gray-500 text-xs">{t('referral.listComp.emptyDesc')}</p>
        </div>
      </Card>
    );
  }

  // 计算总页数
  const totalReferrals = stats?.referralCount || 0;
  const totalPages = Math.ceil(totalReferrals / pageSize);
  const hasNextPage = referrals.length === pageSize;
  const hasPrevPage = page > 0;

  return (
    <Card padding="none">
      {/* 标题 */}
      <div className="px-6 py-4 border-b border-dark-border">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-bold text-white">{t('referral.listComp.title')}</h3>
            <p className="text-sm text-gray-400 mt-1">
              {statsLoading ? (
                t('referral.loading')
              ) : (
                <>
                  {t('referral.listComp.totalUsers', { count: totalReferrals })}
                  {totalPages > 1 && (
                    <span className="text-gray-500 ml-2">
                      · {t('referral.listComp.pageInfo', { current: page + 1, total: totalPages })}
                    </span>
                  )}
                </>
              )}
            </p>
          </div>
        </div>
      </div>

      {/* 列表 */}
      <div className="max-h-96 overflow-y-auto divide-y divide-dark-border scrollbar-thin scrollbar-thumb-gray-600 scrollbar-track-gray-800">
        {referrals.map((referral: any, index: number) => {
          const boundDate = new Date(Number(referral.boundAt) * 1000);
          const refereeAddress = referral.referee?.id;

          // 防御性检查：如果 referee 为空，跳过该记录
          if (!refereeAddress) {
            console.warn('[ReferralList] 跳过无效的推荐记录:', referral.id);
            return null;
          }

          return (
            <div
              key={referral.id}
              className="px-6 py-4 hover:bg-dark-card/50 transition-colors"
            >
              <div className="flex items-center justify-between">
                {/* 用户信息 */}
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-accent flex items-center justify-center text-white text-sm font-bold">
                    {refereeAddress.slice(2, 4).toUpperCase()}
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <p className="text-sm font-medium text-white">
                        {refereeAddress.slice(0, 6)}...{refereeAddress.slice(-4)}
                      </p>
                    </div>
                    <p className="text-xs text-gray-500">
                      {t('referral.listComp.bindTime')}: {boundDate.toLocaleDateString()}
                    </p>
                  </div>
                </div>

                {/* 统计信息 */}
                <div className="text-right">
                  <p className="text-xs text-gray-500">
                    {t('referral.listComp.campaign')}: {referral.campaignId.toString()}
                  </p>
                </div>
              </div>

              {/* Campaign ID (如果有) */}
              {Number(referral.campaignId) > 0 && (
                <div className="mt-2">
                  <Badge variant="info" size="sm">
                    {t('referral.listComp.campaign')} #{referral.campaignId.toString()}
                  </Badge>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* 分页控制 */}
      {totalPages > 1 && (
        <div className="px-6 py-4 border-t border-dark-border">
          <div className="flex items-center justify-between">
            {/* 上一页按钮 */}
            <button
              onClick={() => setPage(Math.max(0, page - 1))}
              disabled={!hasPrevPage}
              className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
              {t('referral.listComp.prev')}
            </button>

            {/* 页码指示器 */}
            <div className="flex items-center gap-2">
              {/* 显示前后页码 */}
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
                        ? 'bg-accent text-white'
                        : 'text-gray-400 hover:bg-dark-card hover:text-white'
                    }`}
                  >
                    {pageNum + 1}
                  </button>
                );
              })}
            </div>

            {/* 下一页按钮 */}
            <button
              onClick={() => setPage(page + 1)}
              disabled={!hasNextPage}
              className="px-4 py-2 text-sm text-white bg-dark-card border border-dark-border rounded-lg hover:bg-dark-card/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
            >
              {t('referral.listComp.next')}
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>

          {/* 快速跳转（如果页数很多） */}
          {totalPages > 5 && (
            <div className="mt-3 flex items-center justify-center gap-2 text-sm">
              <span className="text-gray-500">{t('referral.listComp.jumpTo')}</span>
              <input
                type="number"
                min={1}
                max={totalPages}
                placeholder={(page + 1).toString()}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    const target = parseInt((e.target as HTMLInputElement).value) - 1;
                    if (target >= 0 && target < totalPages) {
                      setPage(target);
                    }
                  }
                }}
                className="w-16 px-2 py-1 bg-dark-card border border-dark-border rounded text-white text-center focus:outline-none focus:border-accent"
              />
              <span className="text-gray-500">{t('referral.listComp.page')}</span>
            </div>
          )}
        </div>
      )}
    </Card>
  );
}
