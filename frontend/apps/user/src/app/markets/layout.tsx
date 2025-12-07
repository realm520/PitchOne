'use client';

import { SidebarProvider } from "../../lib/sidebar-store";
import { Sidebar, MobileMenuButton } from "../../components/sidebar";

export default function MarketsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      <div className="flex flex-1 w-full">
        {/* 移动端菜单按钮 - 固定在左上角 */}
        <div className="lg:hidden fixed top-20 left-4 z-40">
          <MobileMenuButton />
        </div>
        <Sidebar />
        <div className="flex-1 overflow-auto">{children}</div>
      </div>
    </SidebarProvider>
  );
}
