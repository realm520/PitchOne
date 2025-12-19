'use client';

import { useState, useMemo } from 'react';
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
import { BetSlip } from '../../components/betslip';
import { MarketCard } from './components/MarketCard';

// Market type grouped by day
interface MarketsByDay {
  dateKey: string;
  dateLabel: string;
  markets: ReturnType<typeof useMarkets>['data'];
}

export function MarketsContent() {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState<MarketStatus[] | undefined>();
  const [typeFilter, setTypeFilter] = useState<string | undefined>();
  const { data: markets, isLoading, error, refetch } = useMarkets(statusFilter);

  // Get league filter from sidebar
  const { selectedLeague, resetFilters: resetLeagueFilter } = useSidebarStore();

  // Generate filter options
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

  // Filter markets by type and league, sort by time
  const filteredMarkets = useMemo(() => {
    if (!markets) return [];

    const filtered = markets.filter((market) => {
      // Type filter
      if (typeFilter) {
        const templateType = market._displayInfo?.templateType;
        if (typeFilter === 'OU') {
          if (templateType !== 'OU' && templateType !== 'OU_MULTI') {
            return false;
          }
        } else if (templateType !== typeFilter) {
          return false;
        }
      }

      // League filter
      if (selectedLeague) {
        const marketLeagueId = parseLeagueFromMatchId(market.matchId);
        if (marketLeagueId !== selectedLeague) {
          return false;
        }
      }

      return true;
    });

    // Sort by creation time (earliest first)
    return filtered.sort((a, b) => parseInt(a.createdAt) - parseInt(b.createdAt));
  }, [markets, typeFilter, selectedLeague]);

  // Group markets by day
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

    // Sort by date
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

  // Get current league name for display
  const currentLeagueName = selectedLeague ? t(`leagues.${selectedLeague}`) : null;

  return (
    <div className="min-h-screen bg-dark-bg">
      <div className="flex">
        {/* Left: Markets List */}
        <div className="flex-1 min-w-0 py-8">
          <Container size="lg">
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
              {/* Status filter */}
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

              {/* Type filter */}
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

              {/* League filter indicator */}
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
                    {/* Date section header */}
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

                    {/* Market list */}
                    <div className="space-y-2">
                      {dayGroup.markets?.map((market) => (
                        <MarketCard key={market.id} market={market} />
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

        {/* Right: Sticky Bet Slip */}
        <div className="w-80 shrink-0 hidden lg:block p-4 pt-8">
          <div className="sticky top-20">
            <BetSlip />
          </div>
        </div>
      </div>
    </div>
  );
}
