'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useMarkets, MarketStatus } from '@pitchone/web3';
import { useTranslation } from '@pitchone/i18n';
import {
  Container,
  Card,
  Badge,
  Button,
  LoadingSpinner,
  EmptyState,
  ErrorState,
} from '@pitchone/ui';
import { useSidebarStore } from '../../lib/sidebar-store';
import { parseLeagueFromMatchId } from '../../types/sports';

export function MarketsContent() {
  const { t, translateTeam, translateLeague } = useTranslation();
  const [statusFilter, setStatusFilter] = useState<MarketStatus[] | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const { data: markets, isLoading, error, refetch } = useMarkets(statusFilter);

  // 从侧边栏获取联赛过滤
  const { selectedLeague, resetFilters: resetLeagueFilter } = useSidebarStore();

  // 动态生成过滤器选项
  const statusFilters = [
    { label: t('markets.filter.allStatus'), value: undefined },
    { label: t('markets.status.open'), value: MarketStatus.Open },
    { label: t('markets.status.locked'), value: MarketStatus.Locked },
    { label: t('markets.status.resolved'), value: MarketStatus.Resolved },
  ] as const;

  const typeFilters = [
    { label: t('markets.allTypes'), value: undefined },
    { label: t('markets.type.wdl'), value: 'WDL' },
    { label: t('markets.type.ou'), value: 'OU' },
    { label: t('markets.type.oddEven'), value: 'OddEven' },
  ] as const;

  // 根据类型和联赛过滤市场
  const filteredMarkets = useMemo(() => {
    if (!markets) return [];

    return markets.filter((market) => {
      // 类型过滤
      if (typeFilter) {
        const templateType = market._displayInfo?.templateType;
        if (typeFilter === 'OU') {
          // 大小球包括单线和多线
          if (templateType !== 'OU' && templateType !== 'OU_MULTI') {
            return false;
          }
        } else if (templateType !== typeFilter) {
          return false;
        }
      }

      // 联赛过滤
      if (selectedLeague) {
        const marketLeagueId = parseLeagueFromMatchId(market.matchId);
        if (marketLeagueId !== selectedLeague) {
          return false;
        }
      }

      return true;
    });
  }, [markets, typeFilter, selectedLeague]);

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
      [MarketStatus.Open]: { variant: 'success' as const, label: t('markets.status.open') },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: t('markets.status.locked') },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: t('markets.status.resolved') },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: t('markets.status.finalized') },
    };
    const config = variants[state] || { variant: 'default' as const, label: t('markets.unknown') };
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  // 获取当前联赛名称用于显示
  const currentLeagueName = selectedLeague ? t(`leagues.${selectedLeague}`) : null;

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="xl">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-neon mb-2">
            {currentLeagueName ? currentLeagueName : t('markets.listTitle')}
          </h1>
          <p className="text-gray-400">
            {currentLeagueName
              ? t('sidebar.marketCount', { count: filteredMarkets.length })
              : t('markets.listDesc')
            }
          </p>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap items-center gap-3 mb-6">
          {/* 状态过滤 */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">{t('markets.statusLabel')}:</span>
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

          <div className="w-px h-6 bg-dark-border" />

          {/* 类型过滤 */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">{t('markets.typeLabel')}:</span>
            {typeFilters.map((filter) => (
              <Button
                key={filter.label}
                variant={typeFilter === filter.value ? 'neon' : 'ghost'}
                size="sm"
                onClick={() => setTypeFilter(filter.value)}
              >
                {filter.label}
              </Button>
            ))}
          </div>

          {/* 联赛过滤提示 */}
          {selectedLeague && (
            <>
              <div className="w-px h-6 bg-dark-border" />
              <div className="flex items-center gap-2">
                <Badge variant="info" size="sm">
                  {t(`leagues.${selectedLeague}`)}
                </Badge>
                <button
                  onClick={resetLeagueFilter}
                  className="text-xs text-gray-500 hover:text-gray-300"
                >
                  ✕
                </button>
              </div>
            </>
          )}
        </div>

        {/* Content */}
        {isLoading ? (
          <div className="flex justify-center py-20">
            <LoadingSpinner size="lg" text={t('markets.loading')} />
          </div>
        ) : error ? (
          <ErrorState
            message={t('markets.errorLoading')}
            onRetry={() => refetch()}
          />
        ) : !filteredMarkets || filteredMarkets.length === 0 ? (
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
            title={t('markets.empty.title')}
            description={t('markets.empty.desc')}
            action={
              <Button variant="primary" onClick={() => {
                setStatusFilter(undefined);
                setTypeFilter(undefined);
                resetLeagueFilter();
              }}>
                {t('markets.empty.action')}
              </Button>
            }
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
            {filteredMarkets.map((market) => (
              <Link key={market.id} href={`/markets/${market.id}`}>
                <Card hoverable variant="neon" padding="lg">
                  {/* Match Info */}
                  <div className="mb-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs text-gray-500 uppercase">
                        {translateLeague(market._displayInfo?.league || 'EPL')}
                      </span>
                      {getStatusBadge(market.state)}
                    </div>
                    <h3 className="text-xl font-bold text-white mb-1">
                      {translateTeam(market._displayInfo?.homeTeam || 'Team A')} vs {translateTeam(market._displayInfo?.awayTeam || 'Team B')}
                    </h3>
                    <p className="text-sm text-gray-400">
                      {t('markets.card.createdAt')}: {formatDate(market.createdAt)}
                    </p>
                    {market.lockedAt && (
                      <p className="text-xs text-orange-400 mt-1">
                        {t('markets.card.lockedAt')}: {formatDate(market.lockedAt)}
                      </p>
                    )}
                  </div>

                  {/* Market Stats */}
                  <div className="flex items-center justify-between text-xs text-gray-400 mb-3">
                    <span>{t('markets.card.totalVolume')}: {Number(market.totalVolume).toFixed(2)} USDC</span>
                    <span>{market.uniqueBettors} {t('markets.card.participants')}</span>
                  </div>

                  {/* Market Type */}
                  <div className="flex items-center justify-between pt-4 border-t border-dark-border">
                    <span className="text-sm text-gray-400">{t('markets.card.marketType')}</span>
                    <div className="flex gap-2">
                      <Badge variant="neon" size="sm">
                        {market._displayInfo?.templateTypeDisplay || t('markets.unknown')}
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
                      {market.state === MarketStatus.Open ? t('markets.card.placeBet') : t('markets.card.viewDetails')}
                    </Button>
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}

        {/* Pagination Placeholder */}
        {filteredMarkets && filteredMarkets.length > 0 && (
          <div className="mt-12 flex justify-center">
            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" disabled>
                {t('markets.pagination.prev')}
              </Button>
              <span className="px-4 py-2 text-sm text-gray-400">{t('markets.pagination.page', { page: 1 })}</span>
              <Button variant="ghost" size="sm" disabled>
                {t('markets.pagination.next')}
              </Button>
            </div>
          </div>
        )}
      </Container>
    </div>
  );
}
