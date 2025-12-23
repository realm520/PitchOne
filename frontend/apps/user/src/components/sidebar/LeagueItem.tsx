'use client';

import { useRouter } from 'nextjs-toploader/app'; // 使用包装的 router，自动触发进度条
import { usePathname } from 'next/navigation';
import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import type { League } from '../../types/sports';

interface LeagueItemProps {
  league: League;
  sportId: string;
}

export function LeagueItem({ league, sportId }: LeagueItemProps) {
  const { t } = useTranslation();
  const router = useRouter();
  const pathname = usePathname();
  const { selectedLeague, selectLeague } = useSidebarStore();
  const isSelected = selectedLeague === league.id;

  // 处理联赛选择，如果在详情页则导航回列表页
  const handleClick = () => {
    selectLeague(sportId, league.id);
    // 如果在详情页（路径格式为 /markets/0x...），导航回列表
    // 使用 nextjs-toploader/app 的 router.push 会自动触发进度条
    if (pathname && pathname.startsWith('/markets/') && pathname !== '/markets') {
      router.push('/markets');
    }
  };

  return (
    <button
      onClick={handleClick}
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
