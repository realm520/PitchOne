'use client';

import { SidebarProvider } from "../../lib/sidebar-store";
import { SidebarContent, MobileMenuButton, Sidebar } from "../../components/sidebar";
import { BetSlip, MarketPositions } from "../../components/betslip";

export default function MarketsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      {/* 移动端侧边栏（保留原有行为） */}
      <div className="lg:hidden">
        <Sidebar />
      </div>

      {/* 三栏布局容器 - 整页滚动 */}
      <div className="flex min-h-[calc(100vh-4rem)]">
        {/* 移动端菜单按钮 */}
        <div className="lg:hidden fixed top-20 left-4 z-40">
          <MobileMenuButton />
        </div>

        {/* 左栏: Sidebar (桌面端) - Sticky */}
        <aside className="hidden lg:block w-64 shrink-0 border-r border-dark-border bg-dark-bg">
          <div className="sticky top-16 h-[calc(100vh-4rem)] overflow-y-auto">
            <SidebarContent />
          </div>
        </aside>

        {/* 中栏: Markets 内容 - 自然滚动 */}
        <main className="flex-1 min-w-0 bg-dark-bg">
          {children}
        </main>

        {/* 右栏: BetSlip + MarketPositions - Sticky */}
        <aside className="hidden lg:block w-[360px] shrink-0 border-l border-dark-border bg-dark-bg">
          <div className="sticky top-16 h-[calc(100vh-4rem)] overflow-y-auto p-4 space-y-4">
            <BetSlip />
            <MarketPositions />
          </div>
        </aside>
      </div>
    </SidebarProvider>
  );
}
