import type { Metadata } from 'next';
import {
  ReferralLink,
  ReferralStats,
  ReferralList,
  ReferralRewardsHistory,
  ReferralLeaderboard,
} from '@/components/referral';

export const metadata: Metadata = {
  title: '推荐中心 - PitchOne',
  description: '分享推荐链接，邀请好友，获得 8% 返佣奖励',
};

/**
 * 推荐系统主页
 *
 * 功能：
 * 1. 显示用户的推荐链接
 * 2. 显示推荐统计数据
 * 3. 显示被推荐人列表
 * 4. 显示返佣历史
 * 5. 显示全站推荐排行榜
 */
export default function ReferralPage() {
  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl">
      {/* 页面标题 */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">推荐中心</h1>
        <p className="text-gray-400">
          分享您的推荐链接，邀请好友加入 PitchOne，获得 8% 返佣奖励
        </p>
      </div>

      {/* 第一行：推荐链接 */}
      <div className="mb-6">
        <ReferralLink />
      </div>

      {/* 第二行：推荐统计 */}
      <div className="mb-6">
        <ReferralStats />
      </div>

      {/* 第三行：两栏布局 - 左侧推荐列表，右侧返佣历史 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div>
          <h2 className="text-xl font-bold text-white mb-4">我的推荐</h2>
          <ReferralList />
        </div>

        <div>
          <h2 className="text-xl font-bold text-white mb-4">返佣记录</h2>
          <ReferralRewardsHistory />
        </div>
      </div>

      {/* 第四行：排行榜 */}
      <div>
        <h2 className="text-xl font-bold text-white mb-4">推荐排行榜</h2>
        <ReferralLeaderboard limit={20} />
      </div>

      {/* 页脚提示 */}
      <div className="mt-8 p-6 bg-dark-card border border-dark-border rounded-lg">
        <div className="flex items-start gap-4">
          <svg
            className="w-6 h-6 text-neon-blue flex-shrink-0 mt-1"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <h3 className="text-lg font-bold text-white mb-2">如何获得推荐奖励？</h3>
            <ol className="space-y-2 text-sm text-gray-400">
              <li className="flex gap-2">
                <span className="text-neon-blue">1.</span>
                <span>复制您的专属推荐链接</span>
              </li>
              <li className="flex gap-2">
                <span className="text-neon-blue">2.</span>
                <span>分享给好友，好友通过链接访问并连接钱包完成绑定</span>
              </li>
              <li className="flex gap-2">
                <span className="text-neon-blue">3.</span>
                <span>好友每次下注，您将获得其手续费的 8% 作为返佣</span>
              </li>
              <li className="flex gap-2">
                <span className="text-neon-blue">4.</span>
                <span>返佣将自动发放到您的钱包地址，无需手动领取</span>
              </li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
