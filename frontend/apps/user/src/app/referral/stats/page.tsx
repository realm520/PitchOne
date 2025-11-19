import type { Metadata } from 'next';
import {
  ReferralStats,
  ReferralList,
  ReferralRewardsHistory,
} from '@/components/referral';

export const metadata: Metadata = {
  title: '推荐统计 - PitchOne',
  description: '查看您的推荐统计数据和详细信息',
};

/**
 * 推荐统计页面
 *
 * 功能：
 * 1. 详细的推荐统计数据展示
 * 2. 被推荐人列表（支持分页）
 * 3. 完整的返佣历史记录
 *
 * 与主页的区别：
 * - 主页：概览式展示，包含排行榜和推荐链接
 * - 统计页：聚焦于个人数据，更详细的列表和历史
 */
export default function ReferralStatsPage() {
  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl">
      {/* 页面标题 */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">推荐统计</h1>
        <p className="text-gray-400">
          查看您的推荐数据和收益详情
        </p>
      </div>

      {/* 统计卡片 */}
      <div className="mb-8">
        <ReferralStats />
      </div>

      {/* 数据详情 - 两栏布局 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 左栏：推荐列表 */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-white">推荐用户</h2>
          </div>
          <ReferralList />
        </div>

        {/* 右栏：返佣历史 */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-white">返佣记录</h2>
          </div>
          <ReferralRewardsHistory />
        </div>
      </div>

      {/* 数据说明 */}
      <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="p-4 bg-dark-card border border-dark-border rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <svg className="w-5 h-5 text-neon-blue" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="font-medium text-white">推荐人数</h3>
          </div>
          <p className="text-sm text-gray-400">
            统计所有通过您的推荐链接绑定的用户数量
          </p>
        </div>

        <div className="p-4 bg-dark-card border border-dark-border rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <svg className="w-5 h-5 text-neon-green" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="font-medium text-white">有效推荐</h3>
          </div>
          <p className="text-sm text-gray-400">
            已下注且交易量达到最小要求的推荐用户
          </p>
        </div>

        <div className="p-4 bg-dark-card border border-dark-border rounded-lg">
          <div className="flex items-center gap-3 mb-2">
            <svg className="w-5 h-5 text-neon-purple" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <h3 className="font-medium text-white">累计返佣</h3>
          </div>
          <p className="text-sm text-gray-400">
            所有被推荐人下注产生的返佣总和（USDC）
          </p>
        </div>
      </div>
    </div>
  );
}
