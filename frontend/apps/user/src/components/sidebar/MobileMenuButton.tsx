'use client';

import { useSidebarStore } from '../../lib/sidebar-store';

export function MobileMenuButton() {
  const { isOpen, openSidebar } = useSidebarStore();

  // Sidebar 展开时隐藏此按钮（Sidebar 头部已有关闭按钮）
  if (isOpen) {
    return null;
  }

  return (
    <button
      onClick={openSidebar}
      className="lg:hidden p-2 -ml-2 text-gray-400 hover:text-white transition-colors"
      aria-label="Open menu"
    >
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
      </svg>
    </button>
  );
}
