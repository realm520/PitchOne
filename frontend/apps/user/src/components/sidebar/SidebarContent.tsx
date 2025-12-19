'use client';

import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import { SPORT_TYPES } from '../../types/sports';
import { useLeagues } from '../../hooks/useLeagues';
import { SportSection } from './SportSection';

export function SidebarContent() {
  const { t } = useTranslation();
  const { resetFilters, selectedLeague } = useSidebarStore();

  const enabledSports = SPORT_TYPES.filter((s) => s.enabled);
  const disabledSports = SPORT_TYPES.filter((s) => !s.enabled);

  const { leagues: footballLeagues, isLoading: footballLoading } = useLeagues('football');

  return (
    <nav className="py-4 px-3">
      {/* 显示全部市场按钮 */}
      {selectedLeague !== null && (
        <button
          onClick={resetFilters}
          className="w-full flex items-center gap-2 px-3 py-2 mb-4 text-sm text-gray-400 hover:text-white transition-colors"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
          {t('sidebar.showAll')}
        </button>
      )}

      {/* 已启用的体育类型 */}
      {enabledSports.map((sport) => (
        <SportSection
          key={sport.id}
          sport={sport}
          leagues={sport.id === 'football' ? footballLeagues : []}
          isLoading={sport.id === 'football' ? footballLoading : false}
        />
      ))}

      {/* 未启用的体育类型 */}
      {disabledSports.length > 0 && (
        <div className="mt-4 pt-4 border-t border-dark-border">
          {disabledSports.map((sport) => (
            <SportSection key={sport.id} sport={sport} leagues={[]} />
          ))}
        </div>
      )}
    </nav>
  );
}
