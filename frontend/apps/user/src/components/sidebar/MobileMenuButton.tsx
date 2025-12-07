'use client';

import { useSidebarStore } from '../../lib/sidebar-store';

export function MobileMenuButton() {
  const { openSidebar } = useSidebarStore();

  return (
    <button
      onClick={openSidebar}
      className="lg:hidden p-2 -ml-2 text-gray-400 hover:text-white transition-colors"
      aria-label="Open menu"
    >
      <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M4 6h16M4 12h16M4 18h16"
        />
      </svg>
    </button>
  );
}
