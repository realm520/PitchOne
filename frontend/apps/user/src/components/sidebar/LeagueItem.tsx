'use client';

import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import type { League } from '../../types/sports';

interface LeagueItemProps {
  league: League;
  sportId: string;
}

export function LeagueItem({ league, sportId }: LeagueItemProps) {
  const { t } = useTranslation();
  const { selectedLeague, selectLeague } = useSidebarStore();
  const isSelected = selectedLeague === league.id;

  return (
    <button
      onClick={() => selectLeague(sportId, league.id)}
      className={`
        w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm
        transition-colors duration-200
        ${isSelected
          ? 'bg-accent/20 text-accent'
          : 'text-gray-400 hover:bg-dark-border/50 hover:text-gray-200'
        }
      `}
    >
      <span>{t(league.name)}</span>
      {league.marketCount > 0 && (
        <span className={`text-xs ${isSelected ? 'text-accent' : 'text-gray-500'}`}>
          {league.marketCount}
        </span>
      )}
    </button>
  );
}
