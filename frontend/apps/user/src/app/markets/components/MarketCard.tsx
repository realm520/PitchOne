'use client';

import Link from 'next/link';
import { useMarketOutcomes, MarketStatus, useIsMarketLocked, Market } from '@pitchone/web3';
import { Badge } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import { useBetSlipStore, SelectedBet } from '../../../lib/betslip-store';
import { OutcomeButton } from '../../../components/betslip';

interface MarketCardProps {
  market: Market;
}

export function MarketCard({ market }: MarketCardProps) {
  const { t, translateTeam, translateLeague } = useTranslation();
  const { selectedBet, selectBet, isSelected } = useBetSlipStore();

  // Fetch real-time outcomes/odds for this market
  const { data: outcomes, isLoading: outcomesLoading } = useMarketOutcomes(
    market.id as `0x${string}`,
    market._displayInfo?.templateType || 'WDL',
    market.line
  );

  // Check if market is locked (based on time)
  const { data: isMarketLocked } = useIsMarketLocked(market.id as `0x${string}`);

  const canBet = market.state === MarketStatus.Open && !isMarketLocked;

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

  const homeTeam = market._displayInfo?.homeTeam || 'Team A';
  const awayTeam = market._displayInfo?.awayTeam || 'Team B';
  const league = market._displayInfo?.league || 'EPL';

  const handleSelectOutcome = (outcome: { id: number; name: string; odds: string }) => {
    const bet: SelectedBet = {
      marketAddress: market.id as `0x${string}`,
      marketId: market.id,
      homeTeam,
      awayTeam,
      league,
      outcomeId: outcome.id,
      outcomeName: outcome.name,
      odds: outcome.odds,
      templateType: market._displayInfo?.templateType || 'WDL',
      line: market.line ? parseInt(market.line) : undefined,
    };
    selectBet(bet);
  };

  return (
    <div className="group flex items-center gap-4 p-4 bg-dark-card rounded-lg border border-dark-border hover:border-neon/50 hover:bg-dark-card/80 transition-all">
      {/* Left side: Time column */}
      <div className="w-16 flex-shrink-0 text-center">
        <span className="text-lg font-mono text-gray-300">
          {formatTime(market.createdAt)}
        </span>
      </div>

      {/* League */}
      <div className="w-20 flex-shrink-0">
        <span className="text-xs text-gray-500 uppercase font-medium">
          {translateLeague(league)}
        </span>
      </div>

      {/* Match info - clickable to navigate */}
      <Link href={`/markets/${market.id}`} className="flex-1 min-w-0">
        <h3 className="text-base font-semibold text-white truncate group-hover:text-neon transition-colors cursor-pointer">
          {translateTeam(homeTeam)} vs {translateTeam(awayTeam)}
        </h3>
        <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
          <span>{Number(market.totalVolume).toFixed(0)} USDC</span>
          <span>·</span>
          <span>{market.uniqueBettors} {t('markets.card.participants')}</span>
        </div>
      </Link>

      {/* Outcome buttons */}
      <div className="flex items-center gap-2 flex-shrink-0">
        {outcomesLoading ? (
          <div className="flex items-center gap-2">
            <div className="w-16 h-12 bg-gray-700 rounded animate-pulse" />
            <div className="w-16 h-12 bg-gray-700 rounded animate-pulse" />
            <div className="w-16 h-12 bg-gray-700 rounded animate-pulse" />
          </div>
        ) : outcomes && outcomes.length > 0 ? (
          outcomes.slice(0, 3).map((outcome) => (
            <OutcomeButton
              key={outcome.id}
              outcome={{
                id: outcome.id,
                name: outcome.name,
                odds: outcome.odds,
              }}
              isSelected={isSelected(market.id as `0x${string}`, outcome.id)}
              isDisabled={!canBet}
              onClick={() => handleSelectOutcome(outcome)}
              variant="card"
            />
          ))
        ) : (
          <span className="text-xs text-gray-500">-</span>
        )}
      </div>

      {/* Type badge */}
      <div className="flex items-center gap-2 flex-shrink-0">
        <Badge variant="neon" size="sm">
          {market._displayInfo?.templateTypeDisplay || t('markets.unknown')}
        </Badge>
        {market._displayInfo?.lineDisplay && (
          <Badge variant="info" size="sm">{market._displayInfo.lineDisplay}</Badge>
        )}
      </div>

      {/* Status */}
      <div className="w-20 flex-shrink-0 flex justify-end">
        {getStatusBadge(market.state)}
      </div>

      {/* Arrow - navigate to detail */}
      <Link href={`/markets/${market.id}`} className="flex-shrink-0 text-gray-600 group-hover:text-neon transition-colors">
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
      </Link>
    </div>
  );
}
