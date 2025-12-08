'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';
import { useMarkets, MarketStatus } from '@pitchone/web3';
import { useTranslation } from '@pitchone/i18n';
import {
  Container,
  Badge,
  Button,
  LoadingSpinner,
  EmptyState,
  ErrorState,
} from '@pitchone/ui';
import { useSidebarStore } from '../../lib/sidebar-store';
import { parseLeagueFromMatchId } from '../../types/sports';

// 按天分组市场的类型
interface MarketsByDay {
  dateKey: string;
  dateLabel: string;
  markets: ReturnType<typeof useMarkets>['data'];
}

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

  // 根据类型和联赛过滤市场，按时间正序排列
  const filteredMarkets = useMemo(() => {
    if (!markets) return [];

    const filtered = markets.filter((market) => {
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

    // 按创建时间正序排列（最早的在前）
    return filtered.sort((a, b) => parseInt(a.createdAt) - parseInt(b.createdAt));
  }, [markets, typeFilter, selectedLeague]);

  // 按天分组市场
  const marketsByDay = useMemo((): MarketsByDay[] => {
    if (!filteredMarkets || filteredMarkets.length === 0) return [];

    const groups: Record<string, typeof filteredMarkets> = {};

    filteredMarkets.forEach((market) => {
      const date = new Date(parseInt(market.createdAt) * 1000);
      const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD

      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(market);
    });

    // 按日期正序排列
    return Object.entries(groups)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([dateKey, markets]) => {
        const date = new Date(dateKey + 'T00:00:00');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);

        let dateLabel: string;
        if (date.getTime() === today.getTime()) {
          dateLabel = t('markets.list.today');
        } else if (date.getTime() === tomorrow.getTime()) {
          dateLabel = t('markets.list.tomorrow');
        } else if (date.getTime() === yesterday.getTime()) {
          dateLabel = t('markets.list.yesterday');
        } else {
          dateLabel = date.toLocaleDateString('zh-CN', {
            month: 'long',
            day: 'numeric',
            weekday: 'short',
          });
        }

        return { dateKey, dateLabel, markets };
      });
  }, [filteredMarkets, t]);

  const formatTime = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleTimeString('zh-CN', {
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
          <div className="space-y-6">
            {marketsByDay.map((dayGroup) => (
              <div key={dayGroup.dateKey}>
                {/* 日期分隔标题 */}
                <div className="sticky top-0 z-10 py-3 px-4 bg-dark-bg/95 backdrop-blur-sm border-b border-dark-border mb-4">
                  <h2 className="text-lg font-semibold text-white flex items-center gap-2">
                    <svg className="w-5 h-5 text-neon" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                    </svg>
                    {dayGroup.dateLabel}
                    <span className="text-sm text-gray-500 font-normal ml-2">
                      ({dayGroup.markets?.length || 0} {t('markets.list.matches')})
                    </span>
                  </h2>
                </div>

                {/* 市场列表 */}
                <div className="space-y-2">
                  {dayGroup.markets?.map((market) => (
                    <Link key={market.id} href={`/markets/${market.id}`}>
                      <div className="group flex items-center gap-4 p-4 bg-dark-card rounded-lg border border-dark-border hover:border-neon/50 hover:bg-dark-card/80 transition-all cursor-pointer">
                        {/* 时间列 */}
                        <div className="w-16 flex-shrink-0 text-center">
                          <span className="text-lg font-mono text-gray-300">
                            {formatTime(market.createdAt)}
                          </span>
                        </div>

                        {/* 联赛标识 */}
                        <div className="w-20 flex-shrink-0">
                          <span className="text-xs text-gray-500 uppercase font-medium">
                            {translateLeague(market._displayInfo?.league || 'EPL')}
                          </span>
                        </div>

                        {/* 比赛信息 */}
                        <div className="flex-1 min-w-0">
                          <h3 className="text-base font-semibold text-white truncate group-hover:text-neon transition-colors">
                            {translateTeam(market._displayInfo?.homeTeam || 'Team A')} vs {translateTeam(market._displayInfo?.awayTeam || 'Team B')}
                          </h3>
                          <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                            <span>{Number(market.totalVolume).toFixed(0)} USDC</span>
                            <span>·</span>
                            <span>{market.uniqueBettors} {t('markets.card.participants')}</span>
                          </div>
                        </div>

                        {/* 玩法类型 */}
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <Badge variant="neon" size="sm">
                            {market._displayInfo?.templateTypeDisplay || t('markets.unknown')}
                          </Badge>
                          {market._displayInfo?.lineDisplay && (
                            <Badge variant="info" size="sm">{market._displayInfo.lineDisplay}</Badge>
                          )}
                        </div>

                        {/* 状态 */}
                        <div className="w-20 flex-shrink-0 flex justify-end">
                          {getStatusBadge(market.state)}
                        </div>

                        {/* 箭头 */}
                        <div className="flex-shrink-0 text-gray-600 group-hover:text-neon transition-colors">
                          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                          </svg>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
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
