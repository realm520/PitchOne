'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKET_QUERY } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, Badge, Button } from '@pitchone/ui';
import { format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { use } from 'react';

// 市场状态映射
const STATUS_MAP = {
  Open: { label: '开盘中', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  Locked: { label: '已锁盘', color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' },
  Resolved: { label: '已结算', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
};

// 玩法类型映射
const TEMPLATE_TYPE_MAP: Record<string, string> = {
  WDL: '胜平负',
  OU: '大小球',
  AH: '让球',
  Score: '精确比分',
};

// 信息卡片组件
function InfoCard({ title, value, subtitle }: { title: string; value: string; subtitle?: string }) {
  return (
    <Card className="p-6">
      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">{title}</h3>
      <p className="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
      {subtitle && (
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{subtitle}</p>
      )}
    </Card>
  );
}

export default function MarketDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);

  // 获取市场详情
  const { data: market, isLoading, error } = useQuery({
    queryKey: ['market', id],
    queryFn: async () => {
      const data: any = await graphqlClient.request(MARKET_QUERY, { id });
      return data.market;
    },
  });

  // 加载状态
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" text="加载市场详情..." />
      </div>
    );
  }

  // 错误状态
  if (error || !market) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <ErrorState
          title="数据加载失败"
          message={error instanceof Error ? error.message : '市场不存在或无法加载'}
          onRetry={() => window.location.reload()}
        />
      </div>
    );
  }

  const status = STATUS_MAP[market.status as keyof typeof STATUS_MAP] || {
    label: market.status,
    color: 'bg-gray-100 text-gray-800'
  };

  const kickoffTime = new Date(Number(market.kickoffTime) * 1000);
  const createdAt = new Date(Number(market.createdAt) * 1000);
  const resolvedAt = market.resolvedAt ? new Date(Number(market.resolvedAt) * 1000) : null;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                  {market.homeTeam} vs {market.awayTeam}
                </h1>
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${status.color}`}>
                  {status.label}
                </span>
              </div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                {market.event} · 市场 ID: {market.id.slice(0, 10)}...
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/markets">
                <Button variant="outline">
                  返回列表
                </Button>
              </Link>
              {market.status === 'Open' && (
                <Button variant="secondary" disabled>
                  锁盘
                  <span className="ml-2 text-xs">(需要 Web3)</span>
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 核心指标 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <InfoCard
            title="总交易量"
            value={`${(Number(market.totalVolume || 0) / 1e6).toFixed(2)} USDC`}
            subtitle="累计下注金额"
          />
          <InfoCard
            title="玩法类型"
            value={TEMPLATE_TYPE_MAP[market.template?.type] || market.template?.type || '未知'}
            subtitle="市场模板"
          />
          <InfoCard
            title="结果选项"
            value={market.outcomeCount || '0'}
            subtitle="可投注的结果数量"
          />
          <InfoCard
            title="胜出结果"
            value={market.winningOutcome !== null && market.winningOutcome !== undefined ? `#${market.winningOutcome}` : '--'}
            subtitle={market.status === 'Resolved' ? '已确定' : '待结算'}
          />
        </div>

        {/* 详细信息 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* 赛事信息 */}
          <Card className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              赛事信息
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">主队</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">{market.homeTeam}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">客队</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">{market.awayTeam}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">赛事</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">{market.event}</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">开赛时间</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">
                  {format(kickoffTime, 'PPP HH:mm', { locale: zhCN })}
                </dd>
              </div>
            </dl>
          </Card>

          {/* 市场状态 */}
          <Card className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              市场状态
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">当前状态</dt>
                <dd>
                  <Badge variant={
                    market.status === 'Open' ? 'primary' :
                    market.status === 'Locked' ? 'warning' :
                    market.status === 'Resolved' ? 'success' :
                    'secondary'
                  }>
                    {status.label}
                  </Badge>
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">创建时间</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">
                  {format(createdAt, 'PPP HH:mm', { locale: zhCN })}
                </dd>
              </div>
              {resolvedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500 dark:text-gray-400">结算时间</dt>
                  <dd className="text-sm font-medium text-gray-900 dark:text-white">
                    {format(resolvedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">玩法模板</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">
                  {TEMPLATE_TYPE_MAP[market.template?.type] || market.template?.type || '未知'}
                </dd>
              </div>
            </dl>
          </Card>
        </div>

        {/* 技术信息 */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            技术信息
          </h2>
          <dl className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <dt className="text-sm text-gray-500 dark:text-gray-400 mb-1">市场合约地址</dt>
              <dd className="text-sm font-mono text-gray-900 dark:text-white break-all">
                {market.id}
              </dd>
            </div>
            <div>
              <dt className="text-sm text-gray-500 dark:text-gray-400 mb-1">模板类型</dt>
              <dd className="text-sm font-mono text-gray-900 dark:text-white">
                {market.template?.type || 'Unknown'}
              </dd>
            </div>
          </dl>
        </Card>

        {/* 操作提示 */}
        {market.status === 'Open' && (
          <Card className="p-6 mt-6 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-blue-800 dark:text-blue-200">
                  市场管理提示
                </h3>
                <div className="mt-2 text-sm text-blue-700 dark:text-blue-300">
                  <p>
                    此市场当前开盘中。管理员可以执行锁盘操作以准备结算。
                    Web3 钱包集成功能即将推出，届时可直接在此页面操作。
                  </p>
                </div>
              </div>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
}
