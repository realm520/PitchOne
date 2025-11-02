'use client';

import { useState } from 'react';
import Link from 'next/link';
import { formatEther } from 'viem';
import { useAccount } from 'wagmi';
import { useUserPositions, MarketStatus } from '@pitchone/web3';
import {
  Container,
  Card,
  Badge,
  Button,
  LoadingSpinner,
  EmptyState,
  ErrorState,
} from '@pitchone/ui';

type TabType = 'active' | 'settled' | 'all';

export default function PortfolioPage() {
  const { address, isConnected } = useAccount();
  const [activeTab, setActiveTab] = useState<TabType>('active');

  const { data: positions, isLoading, error } = useUserPositions(address);

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getOutcomeName = (outcomeId: number) => {
    const names = ['主胜', '平局', '客胜'];
    return names[outcomeId] || `结果 ${outcomeId}`;
  };

  const getStatusBadge = (status: MarketStatus) => {
    const variants = {
      [MarketStatus.Open]: { variant: 'success' as const, label: '进行中' },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: '已锁盘' },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: '可兑付' },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: '已完成' },
    };
    const config = variants[status];
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  const filteredPositions = positions?.filter((pos) => {
    if (activeTab === 'active') {
      return pos.market.state === MarketStatus.Open || pos.market.state === MarketStatus.Locked;
    }
    if (activeTab === 'settled') {
      return pos.market.state === MarketStatus.Resolved || pos.market.state === MarketStatus.Finalized;
    }
    return true;
  });

  // Mock stats (in real app, calculate from positions)
  const stats = {
    totalValue: '15,234.50',
    totalProfit: '+2,456.00',
    winRate: '68%',
    activePositions: filteredPositions?.length || 0,
  };

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <Card padding="lg" className="max-w-md">
          <EmptyState
            icon={
              <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
              </svg>
            }
            title="请先连接钱包"
            description="连接钱包后即可查看您的头寸和交易历史"
          />
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="xl">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-neon mb-2">我的头寸</h1>
          <p className="text-gray-400">查看和管理您的所有投注头寸</p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
          <Card variant="glass" padding="lg">
            <p className="text-sm text-gray-500 mb-1">总价值</p>
            <p className="text-2xl font-bold text-white">{stats.totalValue} USDC</p>
          </Card>
          <Card variant="glass" padding="lg">
            <p className="text-sm text-gray-500 mb-1">总盈亏</p>
            <p className="text-2xl font-bold text-neon-green">{stats.totalProfit} USDC</p>
          </Card>
          <Card variant="glass" padding="lg">
            <p className="text-sm text-gray-500 mb-1">胜率</p>
            <p className="text-2xl font-bold text-neon-blue">{stats.winRate}</p>
          </Card>
          <Card variant="glass" padding="lg">
            <p className="text-sm text-gray-500 mb-1">活跃头寸</p>
            <p className="text-2xl font-bold text-neon-purple">{stats.activePositions}</p>
          </Card>
        </div>

        {/* Tabs */}
        <div className="flex items-center gap-2 mb-6 border-b border-dark-border">
          {[
            { id: 'active' as TabType, label: '进行中' },
            { id: 'settled' as TabType, label: '已结算' },
            { id: 'all' as TabType, label: '全部' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-6 py-3 font-medium transition-colors relative ${
                activeTab === tab.id
                  ? 'text-neon-blue'
                  : 'text-gray-400 hover:text-gray-300'
              }`}
            >
              {tab.label}
              {activeTab === tab.id && (
                <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-neon-blue to-neon-purple" />
              )}
            </button>
          ))}
        </div>

        {/* Positions List */}
        {isLoading ? (
          <div className="flex justify-center py-20">
            <LoadingSpinner size="lg" text="加载头寸数据..." />
          </div>
        ) : error ? (
          <ErrorState message="无法加载头寸数据，请检查网络连接或稍后重试" />
        ) : !filteredPositions || filteredPositions.length === 0 ? (
          <Card padding="lg">
            <EmptyState
              icon={
                <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                </svg>
              }
              title="暂无头寸"
              description={
                activeTab === 'active'
                  ? '您还没有活跃的头寸，去市场列表页下注吧！'
                  : '您在此分类下还没有头寸'
              }
              action={
                activeTab === 'active' && (
                  <Link href="/markets">
                    <Button variant="neon">浏览市场</Button>
                  </Link>
                )
              }
            />
          </Card>
        ) : (
          <div className="space-y-4">
            {filteredPositions.map((position) => (
              <Card key={position.id} variant="neon" padding="lg" hoverable>
                <div className="flex items-start justify-between">
                  {/* Position Info */}
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <Link
                        href={`/markets/${position.market.id}`}
                        className="text-xl font-bold text-white hover:text-neon-blue transition-colors"
                      >
                        市场 {position.market.matchId.slice(0, 20)}...
                      </Link>
                      {getStatusBadge(position.market.state)}
                    </div>
                    <p className="text-gray-400 text-sm mb-3">
                      市场 ID: {position.market.id.slice(0, 20)}...
                    </p>

                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div>
                        <p className="text-xs text-gray-500 mb-1">选择结果</p>
                        <Badge variant="info">{getOutcomeName(position.outcome)}</Badge>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 mb-1">持有份额</p>
                        <p className="text-sm font-medium text-white">
                          {formatEther(BigInt(position.balance))}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 mb-1">当前价值</p>
                        <p className="text-sm font-medium text-neon-green">
                          {(parseFloat(formatEther(BigInt(position.balance))) * 1.5).toFixed(2)} USDC
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 mb-1">预期收益</p>
                        <p className="text-sm font-medium text-neon-blue">
                          +{(parseFloat(formatEther(BigInt(position.balance))) * 0.5).toFixed(2)} USDC
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="ml-6 flex flex-col gap-2">
                    {position.market.state === MarketStatus.Resolved && (
                      <Button variant="neon" size="sm">
                        兑付
                      </Button>
                    )}
                    {(position.market.state === MarketStatus.Open ||
                      position.market.state === MarketStatus.Locked) && (
                      <Button variant="secondary" size="sm">
                        卖出
                      </Button>
                    )}
                    <Link href={`/markets/${position.market.id}`}>
                      <Button variant="ghost" size="sm" fullWidth>
                        查看详情
                      </Button>
                    </Link>
                  </div>
                </div>
              </Card>
            ))}
          </div>
        )}
      </Container>
    </div>
  );
}
