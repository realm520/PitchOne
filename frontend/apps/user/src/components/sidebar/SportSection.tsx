'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from 'nextjs-toploader/app'; // 使用包装的 router，自动触发进度条
import { usePathname } from 'next/navigation';
import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import { SportIcon } from './SportIcon';
import { LeagueItem } from './LeagueItem';
import type { SportType, League } from '../../types/sports';

interface SportSectionProps {
  sport: SportType;
  leagues: League[];
  isLoading?: boolean;
}

export function SportSection({ sport, leagues, isLoading }: SportSectionProps) {
  const { t } = useTranslation();
  const router = useRouter();
  const pathname = usePathname();
  const { expandedSports, toggleSport, selectedLeague, selectLeague } = useSidebarStore();
  const isExpanded = expandedSports.includes(sport.id);

  // 处理联赛选择，如果在详情页则导航回列表页
  const handleSelectLeague = (sportId: string, leagueId: string | null) => {
    selectLeague(sportId, leagueId);
    // 如果在详情页（路径格式为 /markets/0x...），导航回列表
    // 使用 nextjs-toploader/app 的 router.push 会自动触发进度条
    if (pathname && pathname.startsWith('/markets/') && pathname !== '/markets') {
      router.push('/markets');
    }
  };

  // 计算该运动类型下的市场总数
  const totalMarkets = leagues.reduce((sum, league) => sum + league.marketCount, 0);

  if (!sport.enabled) {
    return (
      <div className="mb-2">
        <div className="flex items-center justify-between px-3 py-2.5 rounded-lg text-gray-500 cursor-not-allowed">
          <div className="flex items-center gap-3">
            <SportIcon type={sport.icon} className="w-5 h-5" />
            <span className="font-medium">{t(sport.name)}</span>
          </div>
          <span className="text-xs bg-dark-border px-2 py-0.5 rounded">
            {t('sidebar.comingSoon')}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className="mb-2">
      {/* Sport Header */}
      <button
        onClick={() => toggleSport(sport.id)}
        className={`
          w-full flex items-center justify-between px-3 py-2.5 rounded-lg
          transition-colors duration-200
          ${isExpanded ? 'bg-dark-border/50' : 'hover:bg-dark-border/30'}
        `}
      >
        <div className="flex items-center gap-3">
          <SportIcon type={sport.icon} className="w-5 h-5 text-accent" />
          <span className="font-medium text-white">{t(sport.name)}</span>
          {totalMarkets > 0 && (
            <span className="text-xs text-gray-500">({totalMarkets})</span>
          )}
        </div>
        <svg
          className={`w-4 h-4 text-gray-400 transition-transform duration-200 ${isExpanded ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {/* Leagues List */}
      <AnimatePresence>
        {isExpanded && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden"
          >
            <div className="pl-3 py-1 space-y-0.5">
              {/* All Leagues Option */}
              <button
                onClick={() => handleSelectLeague(sport.id, null)}
                className={`
                  w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm
                  transition-colors duration-200
                  ${selectedLeague === null
                    ? 'bg-accent/20 text-accent'
                    : 'text-gray-400 hover:bg-dark-border/50 hover:text-gray-200'
                  }
                `}
              >
                <span>{t('sidebar.allLeagues')}</span>
                {totalMarkets > 0 && (
                  <span className={`text-xs ${selectedLeague === null ? 'text-accent' : 'text-gray-500'}`}>
                    {totalMarkets}
                  </span>
                )}
              </button>

              {/* Individual Leagues */}
              {isLoading ? (
                <div className="px-3 py-2 text-sm text-gray-500">
                  {t('common.loading')}
                </div>
              ) : (
                leagues.map((league) => (
                  <LeagueItem key={league.id} league={league} sportId={sport.id} />
                ))
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
