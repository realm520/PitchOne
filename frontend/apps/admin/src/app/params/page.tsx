'use client';

import { Card, Badge, Button } from '@pitchone/ui';
import { formatDistanceToNow, format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { useState } from 'react';

// 参数类别
type ParamCategory = 'fee' | 'limit' | 'pricing' | 'referral' | 'other';

// 参数定义
interface ParamDefinition {
  key: string;
  name: string;
  category: ParamCategory;
  currentValue: number;
  unit: string;
  description: string;
  validator?: string;
}

// 提案定义
interface Proposal {
  id: string;
  key: string;
  paramName: string;
  oldValue: number;
  newValue: number;
  status: 'pending' | 'executed' | 'cancelled';
  proposer: string;
  reason: string;
  createdAt: Date;
  eta: Date;
  executedAt?: Date;
}

// 模拟参数数据
const MOCK_PARAMS: ParamDefinition[] = [
  // 费用参数
  {
    key: 'FEE_RATE',
    name: '基础费率',
    category: 'fee',
    currentValue: 200,
    unit: 'bp (2%)',
    description: '下注时收取的基础手续费率',
    validator: '0.1% - 5%'
  },
  {
    key: 'LP_SHARE',
    name: 'LP 分成',
    category: 'fee',
    currentValue: 6000,
    unit: 'bp (60%)',
    description: '手续费中分配给 LP 的比例'
  },
  {
    key: 'PROMO_SHARE',
    name: '推广池分成',
    category: 'fee',
    currentValue: 2000,
    unit: 'bp (20%)',
    description: '手续费中分配给推广池的比例'
  },
  {
    key: 'INSURANCE_SHARE',
    name: '保险金分成',
    category: 'fee',
    currentValue: 1000,
    unit: 'bp (10%)',
    description: '手续费中分配给保险金的比例'
  },
  {
    key: 'TREASURY_SHARE',
    name: '国库分成',
    category: 'fee',
    currentValue: 1000,
    unit: 'bp (10%)',
    description: '手续费中分配给国库的比例'
  },

  // 限额参数
  {
    key: 'MIN_BET',
    name: '最小下注额',
    category: 'limit',
    currentValue: 1000000,
    unit: 'USDC (1)',
    description: '单笔下注的最小金额'
  },
  {
    key: 'MAX_BET',
    name: '最大下注额',
    category: 'limit',
    currentValue: 10000000000,
    unit: 'USDC (10,000)',
    description: '单笔下注的最大金额'
  },
  {
    key: 'MAX_USER_EXPOSURE',
    name: '单用户敞口',
    category: 'limit',
    currentValue: 50000000000,
    unit: 'USDC (50,000)',
    description: '单个用户在单个市场的最大敞口'
  },

  // 联动定价参数
  {
    key: 'OU_LINK_COEFF_2_0_TO_2_5',
    name: '大小球 2.0-2.5 联动系数',
    category: 'pricing',
    currentValue: 8500,
    unit: 'bp (0.85)',
    description: '相邻盘口线的价格联动系数'
  },
  {
    key: 'SPREAD_GUARD_BPS',
    name: '价差保护阈值',
    category: 'pricing',
    currentValue: 500,
    unit: 'bp (5%)',
    description: '套利检测的价差阈值'
  },

  // 推荐返佣参数
  {
    key: 'REFERRAL_RATE_TIER1',
    name: '一级推荐返佣',
    category: 'referral',
    currentValue: 2000,
    unit: 'bp (20%)',
    description: '直推用户的返佣比例'
  },
  {
    key: 'REFERRAL_RATE_TIER2',
    name: '二级推荐返佣',
    category: 'referral',
    currentValue: 1000,
    unit: 'bp (10%)',
    description: '间推用户的返佣比例'
  },
  {
    key: 'MAX_REFERRAL_DEPTH',
    name: '最大推荐层级',
    category: 'referral',
    currentValue: 2,
    unit: '层',
    description: '推荐关系的最大深度'
  },
];

// 模拟提案数据
const MOCK_PROPOSALS: Proposal[] = [
  {
    id: '0x1234...5678',
    key: 'FEE_RATE',
    paramName: '基础费率',
    oldValue: 200,
    newValue: 150,
    status: 'pending',
    proposer: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    reason: '降低费率以吸引更多用户',
    createdAt: new Date(Date.now() - 12 * 60 * 60 * 1000), // 12小时前
    eta: new Date(Date.now() + 36 * 60 * 60 * 1000), // 36小时后
  },
  {
    id: '0xabcd...ef01',
    key: 'MAX_BET',
    paramName: '最大下注额',
    oldValue: 10000000000,
    newValue: 50000000000,
    status: 'executed',
    proposer: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
    reason: '提高限额以支持大额用户',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5天前
    eta: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3天前
    executedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
  },
];

// 参数类别标签
const CATEGORY_LABELS: Record<ParamCategory, { label: string; color: string }> = {
  fee: { label: '费用', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  limit: { label: '限额', color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200' },
  pricing: { label: '定价', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
  referral: { label: '推荐', color: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200' },
  other: { label: '其他', color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200' },
};

// 提案状态
const getProposalStatus = (proposal: Proposal) => {
  if (proposal.status === 'executed') {
    return {
      label: '已执行',
      color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      variant: 'success' as const
    };
  }
  if (proposal.status === 'cancelled') {
    return {
      label: '已取消',
      color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
      variant: 'secondary' as const
    };
  }
  return {
    label: '待执行',
    color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    variant: 'warning' as const
  };
};

// 参数卡片组件
function ParamCard({ param }: { param: ParamDefinition }) {
  const category = CATEGORY_LABELS[param.category];

  return (
    <Card className="p-5 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
              {param.name}
            </h3>
            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${category.color}`}>
              {category.label}
            </span>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
            {param.description}
          </p>
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-baseline justify-between">
          <span className="text-xs text-gray-500 dark:text-gray-400">当前值</span>
          <span className="text-lg font-bold text-gray-900 dark:text-white">
            {param.unit}
          </span>
        </div>

        {param.validator && (
          <div className="flex items-center justify-between">
            <span className="text-xs text-gray-500 dark:text-gray-400">验证范围</span>
            <span className="text-xs font-mono text-gray-600 dark:text-gray-300">
              {param.validator}
            </span>
          </div>
        )}

        <div className="pt-2 border-t dark:border-gray-700">
          <span className="text-xs font-mono text-gray-400 dark:text-gray-500">
            {param.key}
          </span>
        </div>
      </div>
    </Card>
  );
}

// 提案行组件
function ProposalRow({ proposal }: { proposal: Proposal }) {
  const status = getProposalStatus(proposal);
  const isPending = proposal.status === 'pending';
  const timeRemaining = isPending
    ? formatDistanceToNow(proposal.eta, { addSuffix: true, locale: zhCN })
    : null;

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800 border-b dark:border-gray-700">
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="font-medium text-gray-900 dark:text-white">
            {proposal.paramName}
          </span>
          <span className="text-xs font-mono text-gray-500 dark:text-gray-400 mt-1">
            {proposal.key}
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-600 dark:text-gray-300">
            {proposal.oldValue}
          </span>
          <span className="text-gray-400">→</span>
          <span className="text-sm font-semibold text-blue-600 dark:text-blue-400">
            {proposal.newValue}
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </td>
      <td className="py-4 px-4">
        <span className="font-mono text-xs text-gray-600 dark:text-gray-300">
          {proposal.proposer.slice(0, 6)}...{proposal.proposer.slice(-4)}
        </span>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="text-sm text-gray-900 dark:text-white">
            {format(proposal.createdAt, 'MM/dd HH:mm', { locale: zhCN })}
          </span>
          {isPending && timeRemaining && (
            <span className="text-xs text-orange-600 dark:text-orange-400 mt-1">
              ETA {timeRemaining}
            </span>
          )}
          {proposal.executedAt && (
            <span className="text-xs text-green-600 dark:text-green-400 mt-1">
              执行于 {format(proposal.executedAt, 'MM/dd HH:mm')}
            </span>
          )}
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="text-xs text-gray-600 dark:text-gray-300 max-w-xs truncate">
          {proposal.reason}
        </div>
      </td>
    </tr>
  );
}

export default function ParamsPage() {
  const [selectedCategory, setSelectedCategory] = useState<ParamCategory | 'all'>('all');
  const [proposalFilter, setProposalFilter] = useState<'all' | 'pending' | 'executed'>('all');

  // 按类别筛选参数
  const filteredParams = MOCK_PARAMS.filter(param =>
    selectedCategory === 'all' || param.category === selectedCategory
  );

  // 按状态筛选提案
  const filteredProposals = MOCK_PROPOSALS.filter(proposal =>
    proposalFilter === 'all' || proposal.status === proposalFilter
  );

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                参数配置管理
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                管理平台参数和 Timelock 提案 · Timelock 延迟: 2 天
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/">
                <Button variant="outline">
                  返回看板
                </Button>
              </Link>
              <Button variant="primary" disabled>
                创建提案
                <span className="ml-2 text-xs">(需要 Web3)</span>
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Web3 未连接提示 */}
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
                  当前显示的是模拟数据。未来将集成 Web3 钱包和 ParamController 合约，
                  支持创建提案、执行变更等完整的链上治理功能。
                </p>
              </div>
            </div>
          </div>
        </Card>

        {/* 参数列表部分 */}
        <div className="mb-12">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              参数列表
            </h2>

            {/* 类别筛选 */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setSelectedCategory('all')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  selectedCategory === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                全部 ({MOCK_PARAMS.length})
              </button>
              {Object.entries(CATEGORY_LABELS).map(([key, { label }]) => {
                const count = MOCK_PARAMS.filter(p => p.category === key).length;
                return (
                  <button
                    key={key}
                    onClick={() => setSelectedCategory(key as ParamCategory)}
                    className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                      selectedCategory === key
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                    }`}
                  >
                    {label} ({count})
                  </button>
                );
              })}
            </div>
          </div>

          {/* 参数网格 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredParams.map((param) => (
              <ParamCard key={param.key} param={param} />
            ))}
          </div>
        </div>

        {/* 提案列表部分 */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              变更提案
            </h2>

            {/* 提案筛选 */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setProposalFilter('all')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  proposalFilter === 'all'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                全部
              </button>
              <button
                onClick={() => setProposalFilter('pending')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  proposalFilter === 'pending'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                待执行
              </button>
              <button
                onClick={() => setProposalFilter('executed')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${
                  proposalFilter === 'executed'
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                已执行
              </button>
            </div>
          </div>

          {/* 提案表格 */}
          {filteredProposals.length > 0 ? (
            <Card className="overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                    <tr>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        参数
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        变更
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        状态
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        提案者
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        时间
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        理由
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredProposals.map((proposal) => (
                      <ProposalRow key={proposal.id} proposal={proposal} />
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          ) : (
            <Card className="p-12 text-center">
              <div className="text-gray-400 dark:text-gray-500 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                暂无提案
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {proposalFilter !== 'all'
                  ? '没有符合筛选条件的提案'
                  : '还没有创建任何参数变更提案'}
              </p>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
