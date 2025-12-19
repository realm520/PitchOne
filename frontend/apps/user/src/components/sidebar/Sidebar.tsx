'use client';

import { motion } from 'framer-motion';
import { useTranslation } from '@pitchone/i18n';
import { useSidebarStore } from '../../lib/sidebar-store';
import { SidebarOverlay } from './SidebarOverlay';
import { SidebarContent } from './SidebarContent';

export function Sidebar() {
  const { t } = useTranslation();
  const { isOpen, closeSidebar } = useSidebarStore();

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
        <div className="flex-1 overflow-y-auto">
          <SidebarContent />
        </div>
      </motion.aside>
    </>
  );
}
