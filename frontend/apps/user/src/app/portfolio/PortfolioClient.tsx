'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { formatUnits } from 'viem';
import {
  useAccount,
  useUserPositions,
  MarketStatus,
  TOKEN_DECIMALS,
  getOutcomeName as getOutcomeNameFromConstants,
} from '@pitchone/web3';
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

  // 调试日志：查看实际加载的预测数据
  useEffect(() => {
    if (positions && positions.length > 0) {
      console.log('[Portfolio] 加载的预测数据:', positions);
      console.log('[Portfolio] 第一个预测详情:', {
        id: positions[0].id,
        balance: positions[0].balance,
        totalInvested: positions[0].totalInvested,
        averageCost: positions[0].averageCost,
        market: positions[0].market,
      });
    }
  }, [positions]);

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };


  const calculateExpectedPayout = (position: typeof positions[0]) => {
    try {
      // 预期收益 = 持有份额（假设赢了的话，1 share = 1 USDC）
      // balance 存储的是 USDC 单位（6 位小数），不是 ETH（18 位小数）
      if (!position.balance || position.balance === '0') {
        // 如果 balance 为 0，尝试使用 totalInvested 估算（假设赔率约 2.0）
        if (position.totalInvested) {
          const invested = parseFloat(position.totalInvested);
          return invested * 1.8; // 估算 80% 收益
        }
        return 0;
      }

      // 将 balance（USDC）转换为标准单位
      const balanceInUSDC = BigInt(position.balance);
      const shares = parseFloat(formatUnits(balanceInUSDC, TOKEN_DECIMALS.USDC));

      console.log('[Portfolio] 预测收益计算:', {
        positionId: position.id,
        balance: position.balance,
        shares,
        totalInvested: position.totalInvested,
      });

      return shares;
    } catch (error) {
      console.error('[Portfolio] 计算预期收益失败:', error, position);
      return 0;
    }
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
        <LoadingSpinner size="lg" text="加载预测数据..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message="无法加载预测数据" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">我的预测</h1>
          <p className="text-gray-400">管理您的所有市场预测</p>
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
              description="连接钱包后即可查看您的预测"
            />
          </Card>
        ) : !filteredPositions || filteredPositions.length === 0 ? (
          <Card padding="xl">
            <EmptyState
              title={`暂无${activeTab === 'active' ? '活跃' : activeTab === 'settled' ? '已结算的' : ''}预测`}
              description="您还没有任何预测，去市场页面下注吧"
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
                          {position.market.homeTeam || '主队'} vs{' '}
                          {position.market.awayTeam || '客队'}
                        </h3>
                        {getStatusBadge(position.market.state)}
                        {position.market.winnerOutcome !== undefined &&
                          position.market.winnerOutcome === position.outcome && (
                            <Badge variant="success">赢</Badge>
                          )}
                      </div>
                      <div className="space-y-1">
                        <p className="text-sm text-gray-400">
                          <span className="font-medium">投注方向:</span>{' '}
                          {getOutcomeNameFromConstants(position.market.templateId, position.outcome)}
                        </p>
                        <p className="text-xs text-gray-500">
                          创建时间: {formatDate(position.createdAt)}
                        </p>
                      </div>
                    </div>
                    <div className="text-right space-y-2">
                      <div>
                        <p className="text-xs text-gray-500 mb-1">投注额</p>
                        <p className="text-lg font-bold text-white">
                          {position.totalInvested
                            ? parseFloat(position.totalInvested).toFixed(2)
                            : position.averageCost && position.balance
                            ? (
                                parseFloat(position.averageCost) *
                                parseFloat(formatUnits(BigInt(position.balance), TOKEN_DECIMALS.USDC))
                              ).toFixed(2)
                            : '数据加载中...'}{' '}
                          {position.totalInvested || (position.averageCost && position.balance)
                            ? 'USDC'
                            : ''}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 mb-1">预期收益</p>
                        <p className="text-lg font-bold text-neon">
                          {(() => {
                            const payout = calculateExpectedPayout(position);
                            return payout > 0
                              ? `${payout.toFixed(2)} USDC`
                              : '数据加载中...';
                          })()}
                        </p>
                      </div>
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
