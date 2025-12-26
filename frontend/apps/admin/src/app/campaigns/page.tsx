'use client';

import { Card, Badge, Button } from '@pitchone/ui';
import { formatDistanceToNow, format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import { useState } from 'react';

// Campaign 类型
interface Campaign {
  id: string;
  name: string;
  budgetCap: number;
  spentAmount: number;
  remainingBudget: number;
  startTime: Date;
  endTime: Date;
  status: 'Active' | 'Paused' | 'Ended';
  participantCount: number;
  creator: string;
}

// Quest 类型
type QuestType = 'FIRST_BET' | 'CONSECUTIVE_BETS' | 'REFERRAL' | 'VOLUME' | 'WIN_STREAK';

interface Quest {
  id: string;
  campaignName: string;
  questType: QuestType;
  name: string;
  rewardAmount: number;
  targetValue: number;
  startTime: Date;
  endTime: Date;
  status: 'Active' | 'Paused' | 'Ended';
  completionCount: number;
}

// 模拟 Campaign 数据
const MOCK_CAMPAIGNS: Campaign[] = [
  {
    id: '0x1234...5678',
    name: '新春首单奖励',
    budgetCap: 100000,
    spentAmount: 45000,
    remainingBudget: 55000,
    startTime: new Date('2025-01-01'),
    endTime: new Date('2025-01-31'),
    status: 'Active',
    participantCount: 2345,
    creator: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  },
  {
    id: '0xabcd...ef01',
    name: '推荐返佣活动',
    budgetCap: 50000,
    spentAmount: 50000,
    remainingBudget: 0,
    startTime: new Date('2024-12-01'),
    endTime: new Date('2024-12-31'),
    status: 'Ended',
    participantCount: 1823,
    creator: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  },
  {
    id: '0x9876...5432',
    name: '连续下注挑战',
    budgetCap: 30000,
    spentAmount: 12000,
    remainingBudget: 18000,
    startTime: new Date('2025-01-15'),
    endTime: new Date('2025-02-15'),
    status: 'Active',
    participantCount: 567,
    creator: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
  },
];

// 模拟 Quest 数据
const MOCK_QUESTS: Quest[] = [
  {
    id: '0xquest1',
    campaignName: '新春首单奖励',
    questType: 'FIRST_BET',
    name: '首次下注奖励',
    rewardAmount: 10,
    targetValue: 1,
    startTime: new Date('2025-01-01'),
    endTime: new Date('2025-01-31'),
    status: 'Active',
    completionCount: 1234,
  },
  {
    id: '0xquest2',
    campaignName: '新春首单奖励',
    questType: 'VOLUME',
    name: '交易量达标',
    rewardAmount: 50,
    targetValue: 1000,
    startTime: new Date('2025-01-01'),
    endTime: new Date('2025-01-31'),
    status: 'Active',
    completionCount: 345,
  },
  {
    id: '0xquest3',
    campaignName: '推荐返佣活动',
    questType: 'REFERRAL',
    name: '推荐好友',
    rewardAmount: 20,
    targetValue: 5,
    startTime: new Date('2024-12-01'),
    endTime: new Date('2024-12-31'),
    status: 'Ended',
    completionCount: 892,
  },
  {
    id: '0xquest4',
    campaignName: '连续下注挑战',
    questType: 'CONSECUTIVE_BETS',
    name: '连续7天下注',
    rewardAmount: 30,
    targetValue: 7,
    startTime: new Date('2025-01-15'),
    endTime: new Date('2025-02-15'),
    status: 'Active',
    completionCount: 123,
  },
  {
    id: '0xquest5',
    campaignName: '连续下注挑战',
    questType: 'WIN_STREAK',
    name: '连胜5场',
    rewardAmount: 100,
    targetValue: 5,
    startTime: new Date('2025-01-15'),
    endTime: new Date('2025-02-15'),
    status: 'Active',
    completionCount: 23,
  },
];

// 状态映射
const getCampaignStatus = (status: string) => {
  const statusMap = {
    Active: {
      label: '进行中',
      color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      variant: 'success' as const,
    },
    Paused: {
      label: '已暂停',
      color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
      variant: 'warning' as const,
    },
    Ended: {
      label: '已结束',
      color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
      variant: 'secondary' as const,
    },
  };
  return statusMap[status as keyof typeof statusMap];
};

// Quest 类型标签
const QUEST_TYPE_LABELS: Record<QuestType, { label: string; color: string }> = {
  FIRST_BET: { label: '首次下注', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  CONSECUTIVE_BETS: { label: '连续下注', color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200' },
  REFERRAL: { label: '推荐任务', color: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200' },
  VOLUME: { label: '交易量', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
  WIN_STREAK: { label: '连胜', color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' },
};

// Campaign 卡片组件
function CampaignCard({ campaign }: { campaign: Campaign }) {
  const status = getCampaignStatus(campaign.status);
  const budgetUsage = (campaign.spentAmount / campaign.budgetCap) * 100;
  const isActive = campaign.status === 'Active' && campaign.endTime > new Date();
  const timeRemaining = isActive
    ? formatDistanceToNow(campaign.endTime, { addSuffix: true, locale: zhCN })
    : null;

  return (
    <Card className="p-6 hover:shadow-lg transition-shadow">
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {campaign.name}
            </h3>
            <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${status.color}`}>
              {status.label}
            </span>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            {format(campaign.startTime, 'yyyy/MM/dd')} - {format(campaign.endTime, 'yyyy/MM/dd')}
          </p>
          {timeRemaining && (
            <p className="text-xs text-orange-600 dark:text-orange-400 mt-1">
              {timeRemaining}结束
            </p>
          )}
        </div>
      </div>

      <div className="space-y-3">
        {/* 预算进度条 */}
        <div>
          <div className="flex items-center justify-between text-sm mb-1">
            <span className="text-gray-600 dark:text-gray-400">预算使用</span>
            <span className="font-semibold text-gray-900 dark:text-white">
              {budgetUsage.toFixed(1)}%
            </span>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div
              className={`h-2 rounded-full ${
                budgetUsage >= 90
                  ? 'bg-red-600'
                  : budgetUsage >= 70
                  ? 'bg-yellow-600'
                  : 'bg-green-600'
              }`}
              style={{ width: `${budgetUsage}%` }}
            />
          </div>
          <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
            <span>已支出: {(campaign.spentAmount / 1e6).toFixed(2)} USDC</span>
            <span>总预算: {(campaign.budgetCap / 1e6).toFixed(2)} USDC</span>
          </div>
        </div>

        {/* 统计信息 */}
        <div className="grid grid-cols-2 gap-3 pt-3 border-t dark:border-gray-700">
          <div>
            <div className="text-xs text-gray-500 dark:text-gray-400">参与人数</div>
            <div className="text-xl font-bold text-gray-900 dark:text-white">
              {campaign.participantCount.toLocaleString()}
            </div>
          </div>
          <div>
            <div className="text-xs text-gray-500 dark:text-gray-400">剩余预算</div>
            <div className="text-xl font-bold text-gray-900 dark:text-white">
              {(campaign.remainingBudget / 1e6).toFixed(0)} USDC
            </div>
          </div>
        </div>

        {/* 创建者 */}
        <div className="pt-3 border-t dark:border-gray-700">
          <div className="text-xs text-gray-500 dark:text-gray-400 mb-1">创建者</div>
          <div className="text-xs font-mono text-gray-600 dark:text-gray-300">
            {campaign.creator.slice(0, 10)}...{campaign.creator.slice(-8)}
          </div>
        </div>
      </div>
    </Card>
  );
}

// Quest 行组件
function QuestRow({ quest }: { quest: Quest }) {
  const status = getCampaignStatus(quest.status);
  const typeInfo = QUEST_TYPE_LABELS[quest.questType];
  const isActive = quest.status === 'Active' && quest.endTime > new Date();
  const timeRemaining = isActive
    ? formatDistanceToNow(quest.endTime, { addSuffix: true, locale: zhCN })
    : null;

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800 border-b dark:border-gray-700">
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="font-medium text-gray-900 dark:text-white">{quest.name}</span>
          <span className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {quest.campaignName}
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${typeInfo.color}`}>
          {typeInfo.label}
        </span>
      </td>
      <td className="py-4 px-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="text-sm font-semibold text-gray-900 dark:text-white">
            {(quest.rewardAmount / 1e6).toFixed(2)} USDC
          </span>
          <span className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            目标: {quest.targetValue}
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="text-sm text-gray-900 dark:text-white">
            {quest.completionCount.toLocaleString()} 人
          </span>
          <span className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            已完成
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="text-sm text-gray-900 dark:text-white">
            {format(quest.endTime, 'MM/dd HH:mm')}
          </span>
          {timeRemaining && (
            <span className="text-xs text-orange-600 dark:text-orange-400 mt-1">
              {timeRemaining}
            </span>
          )}
        </div>
      </td>
    </tr>
  );
}

export default function CampaignsPage() {
  const [activeTab, setActiveTab] = useState<'campaigns' | 'quests'>('campaigns');
  const [campaignFilter, setCampaignFilter] = useState<'all' | 'Active' | 'Ended'>('all');
  const [questFilter, setQuestFilter] = useState<'all' | 'Active' | 'Ended'>('all');

  // 筛选 Campaigns
  const filteredCampaigns = MOCK_CAMPAIGNS.filter(c =>
    campaignFilter === 'all' || c.status === campaignFilter
  );

  // 筛选 Quests
  const filteredQuests = MOCK_QUESTS.filter(q =>
    questFilter === 'all' || q.status === questFilter
  );

  // 统计数据
  const campaignStats = {
    total: MOCK_CAMPAIGNS.length,
    active: MOCK_CAMPAIGNS.filter(c => c.status === 'Active').length,
    ended: MOCK_CAMPAIGNS.filter(c => c.status === 'Ended').length,
    totalBudget: MOCK_CAMPAIGNS.reduce((sum, c) => sum + c.budgetCap, 0),
    totalSpent: MOCK_CAMPAIGNS.reduce((sum, c) => sum + c.spentAmount, 0),
  };

  const questStats = {
    total: MOCK_QUESTS.length,
    active: MOCK_QUESTS.filter(q => q.status === 'Active').length,
    ended: MOCK_QUESTS.filter(q => q.status === 'Ended').length,
    totalCompletions: MOCK_QUESTS.reduce((sum, q) => sum + q.completionCount, 0),
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Page Title */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">活动与任务管理</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">管理营销活动和用户任务系统</p>
          </div>
          <Button variant="primary" disabled>
            创建活动
            <span className="ml-2 text-xs">(需要 Web3)</span>
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 演示模式提示 */}
        <Card className="p-6 mb-8 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
          <div className="flex items-start">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-blue-800 dark:text-blue-200">
                演示模式
              </h3>
              <div className="mt-2 text-sm text-blue-700 dark:text-blue-300">
                <p>
                  当前显示的是模拟数据。未来将集成 Campaign/Quest 合约，
                  支持创建活动、管理任务、追踪进度等完整的增长运营功能。
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* Tab 切换 */}
        <div className="flex items-center gap-4 mb-6">
          <button
            onClick={() => setActiveTab('campaigns')}
            className={`px-6 py-3 rounded-lg font-medium transition-colors ${
              activeTab === 'campaigns'
                ? 'bg-blue-600 text-white shadow-md'
                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
            }`}
          >
            活动管理 ({campaignStats.total})
          </button>
          <button
            onClick={() => setActiveTab('quests')}
            className={`px-6 py-3 rounded-lg font-medium transition-colors ${
              activeTab === 'quests'
                ? 'bg-blue-600 text-white shadow-md'
                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
            }`}
          >
            任务管理 ({questStats.total})
          </button>
        </div>

        {/* Campaigns Tab */}
        {activeTab === 'campaigns' && (
          <>
            {/* 统计卡片 */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">全部活动</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
                  {campaignStats.total}
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">进行中</div>
                <div className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
                  {campaignStats.active}
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">总预算</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
                  {(campaignStats.totalBudget / 1e6).toFixed(0)} USDC
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">已支出</div>
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400 mt-1">
                  {(campaignStats.totalSpent / 1e6).toFixed(0)} USDC
                </div>
              </Card>
            </div>

            {/* 筛选 */}
            <div className="flex items-center gap-2 mb-6">
              <button
                onClick={() => setCampaignFilter('all')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  campaignFilter === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                全部
              </button>
              <button
                onClick={() => setCampaignFilter('Active')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  campaignFilter === 'Active'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                进行中
              </button>
              <button
                onClick={() => setCampaignFilter('Ended')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  campaignFilter === 'Ended'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                已结束
              </button>
            </div>

            {/* Campaign 网格 */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredCampaigns.map((campaign) => (
                <CampaignCard key={campaign.id} campaign={campaign} />
              ))}
            </div>
          </>
        )}

        {/* Quests Tab */}
        {activeTab === 'quests' && (
          <>
            {/* 统计卡片 */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">全部任务</div>
                <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
                  {questStats.total}
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">进行中</div>
                <div className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
                  {questStats.active}
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">已结束</div>
                <div className="text-2xl font-bold text-gray-600 dark:text-gray-400 mt-1">
                  {questStats.ended}
                </div>
              </Card>
              <Card className="p-4">
                <div className="text-sm text-gray-500 dark:text-gray-400">总完成人次</div>
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400 mt-1">
                  {questStats.totalCompletions.toLocaleString()}
                </div>
              </Card>
            </div>

            {/* 筛选 */}
            <div className="flex items-center gap-2 mb-6">
              <button
                onClick={() => setQuestFilter('all')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  questFilter === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                全部
              </button>
              <button
                onClick={() => setQuestFilter('Active')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  questFilter === 'Active'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                进行中
              </button>
              <button
                onClick={() => setQuestFilter('Ended')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  questFilter === 'Ended'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                已结束
              </button>
            </div>

            {/* Quest 表格 */}
            {filteredQuests.length > 0 ? (
              <Card className="overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                      <tr>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          任务名称
                        </th>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          类型
                        </th>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          状态
                        </th>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          奖励
                        </th>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          完成人数
                        </th>
                        <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          结束时间
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredQuests.map((quest) => (
                        <QuestRow key={quest.id} quest={quest} />
                      ))}
                    </tbody>
                  </table>
                </div>
              </Card>
            ) : (
              <Card className="p-12 text-center">
                <div className="text-gray-400 dark:text-gray-500 mb-4">
                  <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                  暂无任务
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {questFilter !== 'all'
                    ? '没有符合筛选条件的任务'
                    : '还没有创建任何任务'}
                </p>
              </Card>
            )}
          </>
        )}
      </div>
    </div>
  );
}
