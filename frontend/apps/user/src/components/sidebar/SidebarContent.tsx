'use client';

import { SPORT_TYPES } from '../../types/sports';
import { useLeagues } from '../../hooks/useLeagues';
import { SportSection } from './SportSection';

export function SidebarContent() {
  const enabledSports = SPORT_TYPES.filter((s) => s.enabled);
  const disabledSports = SPORT_TYPES.filter((s) => !s.enabled);

  const { leagues: footballLeagues, isLoading: footballLoading } = useLeagues('football');

  return (
    <nav className="py-4 px-3">
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
