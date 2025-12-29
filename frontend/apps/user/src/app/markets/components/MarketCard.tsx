'use client';

import Link from 'next/link';
import { ShieldCheck, BadgeCheck, ChevronRight } from 'lucide-react';
import {
  MarketStatus,
  useIsMarketLocked,
  Market,
  useAccount,
  useUserPositions,
} from '@pitchone/web3';
import { Badge } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import { useBetSlipStore, SelectedBet } from '../../../lib/betslip-store';
import { OutcomeButton } from '../../../components/betslip';

interface MarketCardProps {
  market: Market;
  totalLiquidity?: bigint; // 来自合约的链上流动性（包含初始流动性）
}

export function MarketCard({ market, totalLiquidity }: MarketCardProps) {
  const { t, translateTeam, translateLeague } = useTranslation();
  const { selectBet, isSelected } = useBetSlipStore();
  const { address } = useAccount();

  // 直接使用 market.outcomes（已在 useMarkets 中计算好）
  const outcomes = market.outcomes;

  // Check if market is locked (based on time)
  const { data: isMarketLocked } = useIsMarketLocked(market.id as `0x${string}`);

  // Check if user has participated in this market
  const { data: positions } = useUserPositions(address);
  const hasParticipated = positions?.some(
    (p) => p.market.id.toLowerCase() === market.id.toLowerCase()
  );

  // 暂停状态也视为不可下注
  const canBet = market.state === MarketStatus.Open && !isMarketLocked && !market.paused;

  // Check if market is settled (has winner)
  const isMarketSettled = market.state === MarketStatus.Resolved ||
                          market.state === MarketStatus.Finalized;

  // Format time in 12-hour format
  const formatTime12h = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date
      .toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
      })
      .toLowerCase();
  };

  const getStatusIndicator = (state: MarketStatus, isPaused?: boolean) => {
    // 如果市场是 Open 但已暂停，显示为 Locked
    if (state === MarketStatus.Open && isPaused) {
      return (
        <span className="inline-flex items-center gap-1.5 text-sm text-gray-400">
          <span className="w-2 h-2 rounded-full bg-yellow-500" />
          {t('markets.status.locked')}
        </span>
      );
    }

    const config = {
      [MarketStatus.Created]: { color: '#A855F7', label: t('markets.status.created') },
      [MarketStatus.Open]: { color: '#22C55E', label: t('markets.status.open') },
      [MarketStatus.Locked]: { color: '#FC1B0B', label: t('markets.status.locked') },
      [MarketStatus.Resolved]: { color: '#61D4D3', label: t('markets.status.resolved') },
      [MarketStatus.Finalized]: { color: '#FC870B', label: t('markets.status.finalized') },
      [MarketStatus.Cancelled]: { color: '#6B7280', label: t('markets.status.cancelled') },
    };
    const { color, label } = config[state] || { color: '#6B7280', label: t('markets.unknown') };

    return (
      <span className="inline-flex items-center gap-1.5 text-sm text-gray-400">
        <span className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
        {label}
      </span>
    );
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
    <div className="group flex items-stretch bg-dark-card rounded-lg border border-dark-border hover:border-white/30 hover:bg-dark-card/80 transition-all">
      {/* Left: Main content area */}
      <div className="flex-1 w-0 flex flex-col gap-3 pl-4 py-2">
        {/* Top row: Time/League | Market type/Status */}
        <div className="flex items-center justify-between">
          {/* Left: Time and League */}
          <div className="flex items-center gap-2 text-sm text-gray-400">
            <span className="font-mono">{formatTime12h(market.createdAt)}</span>
            <span className="text-gray-600">|</span>
            <span>{translateLeague(league)}</span>
          </div>

          {/* Right: Market type and Status */}
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-400">
              {market._displayInfo?.templateTypeDisplay
                ? t(market._displayInfo.templateTypeDisplay)
                : t('markets.unknown')}
            </span>
            {market._displayInfo?.lineDisplay && (
              <Badge variant="info" size="sm">{market._displayInfo.lineDisplay}</Badge>
            )}
            {getStatusIndicator(market.state, market.paused)}
          </div>
        </div>

        {/* Middle row: Teams | Outcome buttons */}
        <div className="flex items-center gap-4">
          {/* Left: Team info */}
          <div className="w-[30%] flex items-center gap-3 min-w-0">
            {/* Team logos - Shield for home, Badge for away */}
            <div className="flex-shrink-0 flex items-center">
              <ShieldCheck className="w-8 h-8 text-accent" />
              <BadgeCheck className="w-8 h-8 text-gray-500 -ml-3" />
            </div>
            {/* Team names stacked */}
            <div className="flex flex-col gap-1 min-w-0">
              <span className="text-white font-medium truncate group-hover:text-zinc-300 transition-colors">
                {translateTeam(homeTeam)}
              </span>
              <span className="text-gray-400 truncate group-hover:text-zinc-400 transition-colors">
                {translateTeam(awayTeam)}
              </span>
            </div>
          </div>

          {/* Right: Outcome buttons */}
          <div className="w-[70%] flex flex-col gap-1 flex-shrink-0">
            {/* WINNER label */}
            <span className="text-base text-gray-500 text-center">WINNER</span>
            {/* Buttons row - grid ensures fixed 33.33% width per button */}
            <div className="grid grid-cols-3 gap-2">
              {outcomes && outcomes.length > 0 ? (
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
                    isWinner={isMarketSettled && market.winnerOutcome === outcome.id}
                    onClick={() => handleSelectOutcome(outcome)}
                    variant="card"
                  />
                ))
              ) : (
                // 没有赔率数据时显示占位符
                <>
                  <div className="h-10 bg-white/5 rounded flex items-center justify-center text-gray-500">-</div>
                  <div className="h-10 bg-white/5 rounded flex items-center justify-center text-gray-500">-</div>
                  <div className="h-10 bg-white/5 rounded flex items-center justify-center text-gray-500">-</div>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Bottom row: Volume/Players | Participated */}
        <div className="flex items-center justify-between text-xs">
          {/* Left: Liquidity and participants */}
          <div className="flex items-center gap-2 text-gray-500">
            <span>
              {totalLiquidity
                ? (Number(totalLiquidity) / 1e6).toFixed(2)
                : Number(market.totalVolume).toFixed(2)}{' '}
              USDC
            </span>
            <span>|</span>
            <span>{market.uniqueBettors} {t('markets.card.participants')}</span>
          </div>

          {/* Right: Participated indicator */}
          {address && hasParticipated && (
            <span className="text-gray-400 font-medium">
              {t('markets.card.participated')}
            </span>
          )}
        </div>
      </div>

      {/* Right: Navigation arrow */}
      <Link
        href={`/markets/${market.id}`}
        className="flex-shrink-0 flex items-center px-2 text-gray-600 hover:text-white transition-colors"
      >
        <ChevronRight className="w-5 h-5" />
      </Link>
    </div>
  );
}
