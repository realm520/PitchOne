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
  type Position,
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
import { useTranslation } from '@pitchone/i18n';
import Header from './PortfolioHeader';
import UnLogin from './un-login';

type TabType = 'active' | 'settled' | 'all';

export function PortfolioClient() {
  const { t, translateTeam } = useTranslation();
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

  // 计算统计数据
  const stats = (() => {
    if (!positions || positions.length === 0) {
      return {
        totalBetAmount: 0,
        totalMarkets: 0,
        totalBets: 0,
        totalProfit: 0,
      };
    }

    // 总投注额：所有头寸的 totalInvested 之和
    const totalBetAmount = positions.reduce((sum, pos) => {
      const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;
      return sum + invested;
    }, 0);

    // 投注市场数：去重的市场数量
    const uniqueMarkets = new Set(positions.map((pos) => pos.market.id));
    const totalMarkets = uniqueMarkets.size;

    // 总投注次数：头寸数量
    const totalBets = positions.length;

    // 盈利金额：已结算且赢得的头寸的收益 - 已结算且输掉的投注额
    const totalProfit = positions.reduce((sum, pos) => {
      const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;

      // 只计算已结算的市场
      if (pos.market.state === MarketStatus.Resolved || pos.market.state === MarketStatus.Finalized) {
        if (pos.market.winnerOutcome !== undefined && pos.market.winnerOutcome === pos.outcome) {
          // 赢了：预期收益 - 投入
          const expectedPayout = calculateExpectedPayout(pos);
          return sum + (expectedPayout - invested);
        } else {
          // 输了：损失全部投入
          return sum - invested;
        }
      }
      return sum;
    }, 0);

    return {
      totalBetAmount,
      totalMarkets,
      totalBets,
      totalProfit,
    };
  })();

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };


  const calculateExpectedPayout = (position: Position) => {
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
      [MarketStatus.Open]: { variant: 'success' as const, label: t('portfolio.status.open') },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: t('portfolio.status.locked') },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: t('portfolio.status.resolved') },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: t('portfolio.status.finalized') },
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
        <LoadingSpinner size="lg" text={t('portfolio.loading')} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message={t('portfolio.loadError')} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        {/* Header */}
        <Header />
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">{t('portfolio.title')}</h1>
          <p className="text-gray-400">{t('portfolio.subtitle')}</p>
        </div>

        {/* Stats Cards */}
        {mounted && isConnected && (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <Card padding="md">
              <div className="text-center">
                <p className="text-sm text-gray-400 mb-1">{t('portfolio.stats.totalBetAmount')}</p>
                <p className="text-2xl font-bold text-white">
                  {stats.totalBetAmount.toFixed(2)} <span className="text-sm text-gray-400">USDC</span>
                </p>
              </div>
            </Card>
            <Card padding="md">
              <div className="text-center">
                <p className="text-sm text-gray-400 mb-1">{t('portfolio.stats.totalMarkets')}</p>
                <p className="text-2xl font-bold text-white">{stats.totalMarkets}</p>
              </div>
            </Card>
            <Card padding="md">
              <div className="text-center">
                <p className="text-sm text-gray-400 mb-1">{t('portfolio.stats.totalBets')}</p>
                <p className="text-2xl font-bold text-white">{stats.totalBets}</p>
              </div>
            </Card>
            <Card padding="md">
              <div className="text-center">
                <p className="text-sm text-gray-400 mb-1">{t('portfolio.stats.totalProfit')}</p>
                <p className={`text-2xl font-bold ${stats.totalProfit >= 0 ? 'text-white' : 'text-zinc-400'}`}>
                  {stats.totalProfit >= 0 ? '+' : ''}{stats.totalProfit.toFixed(2)} <span className="text-sm text-gray-400">USDC</span>
                </p>
              </div>
            </Card>
          </div>
        )}

        {/* Tabs */}
        <div className="flex gap-2 mb-6">
          {[
            { key: 'active' as TabType, label: t('portfolio.tabs.active') },
            { key: 'settled' as TabType, label: t('portfolio.tabs.settled') },
            { key: 'all' as TabType, label: t('portfolio.tabs.all') },
          ].map((tab) => (
            <Button
              key={tab.key}
              variant={activeTab === tab.key ? 'primary' : 'secondary'}
              size="sm"
              onClick={() => setActiveTab(tab.key)}
            >
              {tab.label}
            </Button>
          ))}
        </div>

        {/* Content */}
        {mounted && !isConnected ? (
          <UnLogin />
        ) : !filteredPositions || filteredPositions.length === 0 ? (
          <Card padding="lg">
            <EmptyState
              title={activeTab === 'active' ? t('portfolio.emptyActive') : activeTab === 'settled' ? t('portfolio.emptySettled') : t('portfolio.emptyAll')}
              description={t('portfolio.emptyDesc')}
              action={
                <Link href="/markets">
                  <Button variant="primary">{t('portfolio.goToMarkets')}</Button>
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
                          {position.market.homeTeam ? translateTeam(position.market.homeTeam) : t('markets.unknown')} vs{' '}
                          {position.market.awayTeam ? translateTeam(position.market.awayTeam) : t('markets.unknown')}
                        </h3>
                        {getStatusBadge(position.market.state)}
                        {position.market.winnerOutcome !== undefined &&
                          position.market.winnerOutcome === position.outcome && (
                            <Badge variant="success">{t('portfolio.win')}</Badge>
                          )}
                      </div>
                      <div className="space-y-1">
                        <p className="text-sm text-gray-400">
                          <span className="font-medium">{t('portfolio.betDirection')}:</span>{' '}
                          {getOutcomeNameFromConstants(position.market.templateId, position.outcome)}
                        </p>
                        <p className="text-xs text-gray-500">
                          {t('portfolio.createdAt')}: {formatDate(position.createdAt)}
                        </p>
                      </div>
                    </div>
                    <div className="text-right space-y-2">
                      <div>
                        <p className="text-xs text-gray-500 mb-1">{t('portfolio.betAmount')}</p>
                        <p className="text-lg font-bold text-white">
                          {position.totalInvested
                            ? parseFloat(position.totalInvested).toFixed(2)
                            : position.averageCost && position.balance
                              ? (
                                parseFloat(position.averageCost) *
                                parseFloat(formatUnits(BigInt(position.balance), TOKEN_DECIMALS.USDC))
                              ).toFixed(2)
                              : t('portfolio.dataLoading')}{' '}
                          {position.totalInvested || (position.averageCost && position.balance)
                            ? 'USDC'
                            : ''}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500 mb-1">{t('portfolio.expectedPayout')}</p>
                        <p className="text-lg font-bold text-white">
                          {(() => {
                            const payout = calculateExpectedPayout(position);
                            return payout > 0
                              ? `${payout.toFixed(2)} USDC`
                              : t('portfolio.dataLoading');
                          })()}
                        </p>
                      </div>
                      {position.market.state === MarketStatus.Resolved &&
                        position.market.winnerOutcome === position.outcome && (
                          <Button variant="primary" size="sm" className="mt-2">
                            {t('portfolio.redeem')}
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
