'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { formatEther } from 'viem';
import { useAccount, useUserPositions, MarketStatus } from '@pitchone/web3';
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

export function PortfolioClient() {
  const { address, isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('active');

  const { data: positions, isLoading, error } = useUserPositions(address);

  useEffect(() => {
    setMounted(true);
  }, []);

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

  if (isLoading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载头寸数据..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message="无法加载头寸数据" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">我的头寸</h1>
          <p className="text-gray-400">管理您的所有市场头寸</p>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mb-6">
          {[
            { key: 'active' as TabType, label: '活跃' },
            { key: 'settled' as TabType, label: '已结算' },
            { key: 'all' as TabType, label: '全部' },
          ].map((tab) => (
            <Button
              key={tab.key}
              variant={activeTab === tab.key ? 'neon' : 'secondary'}
              size="sm"
              onClick={() => setActiveTab(tab.key)}
            >
              {tab.label}
            </Button>
          ))}
        </div>

        {/* Content */}
        {mounted && !isConnected ? (
          <Card padding="xl">
            <EmptyState
              icon={
                <svg className="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              }
              title="请先连接钱包"
              description="连接钱包后即可查看您的头寸"
            />
          </Card>
        ) : !filteredPositions || filteredPositions.length === 0 ? (
          <Card padding="xl">
            <EmptyState
              title={`暂无${activeTab === 'active' ? '活跃' : activeTab === 'settled' ? '已结算的' : ''}头寸`}
              description="您还没有任何头寸，去市场页面下注吧"
              action={
                <Link href="/markets">
                  <Button variant="neon">浏览市场</Button>
                </Link>
              }
            />
          </Card>
        ) : (
          <div className="grid gap-4">
            {filteredPositions.map((position) => (
              <Link key={position.id} href={`/markets/${position.market.id}`}>
                <Card hoverable padding="lg">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-lg font-bold text-white">
                          市场 {position.market.matchId}
                        </h3>
                        {getStatusBadge(position.market.state)}
                        {position.market.winnerOutcome !== undefined &&
                          position.market.winnerOutcome === position.outcome && (
                            <Badge variant="success">赢</Badge>
                          )}
                      </div>
                      <p className="text-sm text-gray-400 mb-1">
                        结果: {getOutcomeName(position.outcome)}
                      </p>
                      <p className="text-xs text-gray-500">
                        创建时间: {formatDate(position.createdAt)}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-500 mb-1">持有份额</p>
                      <p className="text-xl font-bold text-neon">
                        {parseFloat(formatEther(BigInt(position.balance))).toFixed(2)}
                      </p>
                      {position.market.state === MarketStatus.Resolved &&
                        position.market.winnerOutcome === position.outcome && (
                          <Button variant="neon" size="sm" className="mt-2">
                            兑付
                          </Button>
                        )}
                    </div>
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}
      </Container>
    </div>
  );
}
