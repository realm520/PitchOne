'use client';

import { SidebarProvider } from "../../lib/sidebar-store";
import { SidebarContent, MobileMenuButton, Sidebar } from "../../components/sidebar";
import { BetSlip } from "../../components/betslip";

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

      {/* 三栏布局容器 */}
      <div className="flex h-[calc(100vh-4rem)] overflow-hidden">
        {/* 移动端菜单按钮 */}
        <div className="lg:hidden fixed top-20 left-4 z-40">
          <MobileMenuButton />
        </div>

        {/* 左栏: Sidebar (桌面端) */}
        <aside className="hidden lg:flex flex-col w-64 shrink-0 border-r border-dark-border bg-dark-bg">
          <div className="flex-1 overflow-y-auto">
            <SidebarContent />
          </div>
        </aside>

        {/* 中栏: Markets 内容 */}
        <main className="flex-1 min-w-0 overflow-y-auto bg-dark-bg">
          {children}
        </main>

        {/* 右栏: BetSlip */}
        <aside className="hidden lg:flex flex-col w-[360px] shrink-0 border-l border-dark-border bg-dark-bg">
          <div className="flex-1 overflow-y-auto p-4">
            <BetSlip />
          </div>
        </aside>
      </div>
    </SidebarProvider>
  );
}
