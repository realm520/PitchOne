'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useMarkets, MarketStatus } from '@pitchone/web3';
import {
  Container,
  Card,
  Badge,
  Button,
  LoadingSpinner,
  EmptyState,
  ErrorState,
} from '@pitchone/ui';

const statusFilters = [
  { label: '全部', value: undefined },
  { label: '进行中', value: MarketStatus.Open },
  { label: '已锁盘', value: MarketStatus.Locked },
  { label: '已结算', value: MarketStatus.Resolved },
] as const;

export default function MarketsPage() {
  const [statusFilter, setStatusFilter] = useState<MarketStatus[] | undefined>();
  const { data: markets, isLoading, error, refetch } = useMarkets(statusFilter);

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusBadge = (state: MarketStatus) => {
    const variants = {
      [MarketStatus.Open]: { variant: 'success' as const, label: '进行中' },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: '已锁盘' },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: '已结算' },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: '已完成' },
    };
    const config = variants[state] || { variant: 'default' as const, label: '未知' };
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="xl">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-neon mb-2">市场列表</h1>
          <p className="text-gray-400">浏览所有可下注的足球赛事市场</p>
        </div>

        {/* Filters */}
        <div className="flex items-center gap-3 mb-6 overflow-x-auto pb-2">
          {statusFilters.map((filter) => (
            <Button
              key={filter.label}
              variant={
                (filter.value === undefined && statusFilter === undefined) ||
                (statusFilter && statusFilter[0] === filter.value)
                  ? 'neon'
                  : 'ghost'
              }
              size="sm"
              onClick={() =>
                setStatusFilter(filter.value ? [filter.value] : undefined)
              }
            >
              {filter.label}
            </Button>
          ))}
        </div>

        {/* Content */}
        {isLoading ? (
          <div className="flex justify-center py-20">
            <LoadingSpinner size="lg" text="加载市场数据中..." />
          </div>
        ) : error ? (
          <ErrorState
            message="无法加载市场数据，请检查网络连接或稍后重试"
            onRetry={() => refetch()}
          />
        ) : !markets || markets.length === 0 ? (
          <EmptyState
            icon={
              <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
            }
            title="暂无市场"
            description="当前没有符合条件的市场，请稍后再来或更改筛选条件"
            action={
              <Button variant="primary" onClick={() => setStatusFilter(undefined)}>
                查看全部市场
              </Button>
            }
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {markets.map((market) => (
              <Link key={market.id} href={`/markets/${market.id}`}>
                <Card hoverable variant="neon" padding="lg">
                  {/* Match Info */}
                  <div className="mb-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs text-gray-500 uppercase">
                        {market._displayInfo?.league || 'Unknown League'}
                      </span>
                      {getStatusBadge(market.state)}
                    </div>
                    <h3 className="text-xl font-bold text-white mb-1">
                      {market._displayInfo?.homeTeam || 'Team A'} vs {market._displayInfo?.awayTeam || 'Team B'}
                    </h3>
                    <p className="text-sm text-gray-400">
                      创建时间: {formatDate(market.createdAt)}
                    </p>
                    {market.lockedAt && (
                      <p className="text-xs text-orange-400 mt-1">
                        锁盘: {formatDate(market.lockedAt)}
                      </p>
                    )}
                  </div>

                  {/* Market Stats */}
                  <div className="flex items-center justify-between text-xs text-gray-400 mb-3">
                    <span>交易量: {Number(market.totalVolume).toFixed(2)} USDC</span>
                    <span>{market.uniqueBettors} 人参与</span>
                  </div>

                  {/* Market Type */}
                  <div className="flex items-center justify-between pt-4 border-t border-dark-border">
                    <span className="text-sm text-gray-400">玩法类型</span>
                    <div className="flex gap-2">
                      <Badge variant="neon" size="sm">
                        {market._displayInfo?.templateTypeDisplay || '未知'}
                      </Badge>
                      {market._displayInfo?.lineDisplay && (
                        <Badge variant="info" size="sm">{market._displayInfo.lineDisplay}</Badge>
                      )}
                    </div>
                  </div>

                  {/* CTA */}
                  <div className="mt-4">
                    <Button
                      variant={market.state === MarketStatus.Open ? 'neon' : 'secondary'}
                      fullWidth
                    >
                      {market.state === MarketStatus.Open ? '立即下注' : '查看详情'}
                    </Button>
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}

        {/* Pagination Placeholder */}
        {markets && markets.length > 0 && (
          <div className="mt-12 flex justify-center">
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" disabled>
                上一页
              </Button>
              <span className="px-4 py-2 text-sm text-gray-400">第 1 页</span>
              <Button variant="ghost" size="sm" disabled>
                下一页
              </Button>
            </div>
          </div>
        )}
      </Container>
    </div>
  );
}
