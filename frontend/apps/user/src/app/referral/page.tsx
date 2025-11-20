import type { Metadata } from 'next';
import {
  ReferralManualBinder,
  ReferralLink,
  ReferralStats,
  ReferralDataTabs,
  ReferralLeaderboard,
  ReferralPageHeader,
  ReferralPageFooter,
} from '@/components/referral';

export const metadata: Metadata = {
  title: '推荐中心 - PitchOne',
  description: '分享推荐链接，邀请好友，获得返佣奖励',
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
      {/* 页面标题（动态显示返佣比例） */}
      <ReferralPageHeader />

      {/* 第一行：手动绑定推荐人（如果未绑定） */}
      <div className="mb-6">
        <ReferralManualBinder />
      </div>

      {/* 第二行：推荐链接 */}
      <div className="mb-6">
        <ReferralLink />
      </div>

      {/* 第三行：推荐统计 */}
      <div className="mb-6">
        <ReferralStats />
      </div>

      {/* 第四行：推荐数据 Tab（推荐列表 + 返佣记录） */}
      <div className="mb-6">
        <h2 className="text-xl font-bold text-white mb-4">我的推荐数据</h2>
        <ReferralDataTabs />
      </div>

      {/* 第五行：排行榜 */}
      <div>
        <h2 className="text-xl font-bold text-white mb-4">推荐排行榜</h2>
        <ReferralLeaderboard limit={20} />
      </div>

      {/* 页脚提示（动态显示返佣比例） */}
      <ReferralPageFooter />
    </div>
  );
}
