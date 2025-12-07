'use client';

import { motion } from 'framer-motion';
import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import { SPORT_TYPES } from '../../types/sports';
import { useLeagues } from '../../hooks/useLeagues';
import { SportSection } from './SportSection';
import { SidebarOverlay } from './SidebarOverlay';

export function Sidebar() {
  const { t } = useTranslation();
  const { isOpen, closeSidebar, resetFilters, selectedLeague } = useSidebarStore();

  // 获取已启用的体育类型
  const enabledSports = SPORT_TYPES.filter((s) => s.enabled);
  const disabledSports = SPORT_TYPES.filter((s) => !s.enabled);

  // 获取足球联赛数据
  const { leagues: footballLeagues, isLoading: footballLoading } = useLeagues('football');

  return (
    <>
      {/* 移动端遮罩 */}
      <SidebarOverlay isOpen={isOpen} onClose={closeSidebar} />

      {/* 侧边栏 */}
      <motion.aside
        className={`
          fixed lg:sticky top-16 left-0 z-40
          h-[calc(100vh-4rem)] w-64
          bg-dark-bg border-r border-dark-border
          flex flex-col
          transform lg:transform-none
          ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
          transition-transform duration-300 ease-in-out
        `}
        initial={false}
      >
        {/* 头部 - 移动端显示关闭按钮 */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-dark-border lg:hidden">
          <span className="font-semibold text-white">{t('sidebar.title')}</span>
          <button
            onClick={closeSidebar}
            className="p-1 text-gray-400 hover:text-white transition-colors"
            aria-label="Close menu"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        {/* 导航内容 */}
        <nav className="flex-1 overflow-y-auto py-4 px-3">
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
      </motion.aside>
    </>
  );
}
