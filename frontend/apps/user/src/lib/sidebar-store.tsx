'use client';

import { createContext, useContext, useState, useCallback, ReactNode, useEffect } from 'react';

// ============================================================================
// 类型定义
// ============================================================================

interface SidebarState {
  isOpen: boolean;                    // 移动端展开状态
  expandedSports: string[];           // 展开的体育类型 ID 列表
  selectedSport: string | null;       // 当前选中的体育类型
  selectedLeague: string | null;      // 当前选中的联赛
}

interface SidebarStore extends SidebarState {
  openSidebar: () => void;
  closeSidebar: () => void;
  toggleSidebar: () => void;
  toggleSport: (sportId: string) => void;
  selectLeague: (sportId: string, leagueId: string | null) => void;
  resetFilters: () => void;
}

// ============================================================================
// Context
// ============================================================================

const SidebarContext = createContext<SidebarStore | undefined>(undefined);

// ============================================================================
// 持久化工具
// ============================================================================

const STORAGE_KEY = 'pitchone-sidebar-state';

function loadPersistedState(): Partial<SidebarState> {
  if (typeof window === 'undefined') return {};
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      const parsed = JSON.parse(stored);
      return {
        expandedSports: parsed.expandedSports || ['football'],
        selectedSport: parsed.selectedSport || null,
        selectedLeague: parsed.selectedLeague || null,
      };
    }
  } catch {
    // 忽略解析错误
  }
  return {};
}

function persistState(state: Pick<SidebarState, 'expandedSports' | 'selectedSport' | 'selectedLeague'>) {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // 忽略存储错误
  }
}

// ============================================================================
// Provider
// ============================================================================

export function SidebarProvider({ children }: { children: ReactNode }) {
  const [isOpen, setIsOpen] = useState(false);
  const [expandedSports, setExpandedSports] = useState<string[]>(['football']);
  const [selectedSport, setSelectedSport] = useState<string | null>(null);
  const [selectedLeague, setSelectedLeague] = useState<string | null>(null);

  // 客户端挂载时加载持久化状态
  useEffect(() => {
    const persisted = loadPersistedState();
    if (persisted.expandedSports) setExpandedSports(persisted.expandedSports);
    if (persisted.selectedSport !== undefined) setSelectedSport(persisted.selectedSport);
    if (persisted.selectedLeague !== undefined) setSelectedLeague(persisted.selectedLeague);
  }, []);

  // 状态变化时持久化
  useEffect(() => {
    persistState({ expandedSports, selectedSport, selectedLeague });
  }, [expandedSports, selectedSport, selectedLeague]);

  // 打开侧边栏（移动端）
  const openSidebar = useCallback(() => {
    setIsOpen(true);
  }, []);

  // 关闭侧边栏（移动端）
  const closeSidebar = useCallback(() => {
    setIsOpen(false);
  }, []);

  // 切换侧边栏
  const toggleSidebar = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  // 展开/折叠体育类型
  const toggleSport = useCallback((sportId: string) => {
    setExpandedSports((prev) => {
      if (prev.includes(sportId)) {
        return prev.filter((id) => id !== sportId);
      } else {
        return [...prev, sportId];
      }
    });
  }, []);

  // 选择联赛
  const selectLeague = useCallback((sportId: string, leagueId: string | null) => {
    setSelectedSport(sportId);
    setSelectedLeague(leagueId);
    // 移动端选择后自动关闭侧边栏
    setIsOpen(false);
  }, []);

  // 重置过滤器
  const resetFilters = useCallback(() => {
    setSelectedSport(null);
    setSelectedLeague(null);
  }, []);

  const value: SidebarStore = {
    isOpen,
    expandedSports,
    selectedSport,
    selectedLeague,
    openSidebar,
    closeSidebar,
    toggleSidebar,
    toggleSport,
    selectLeague,
    resetFilters,
  };

  return <SidebarContext.Provider value={value}>{children}</SidebarContext.Provider>;
}

// ============================================================================
// Hook
// ============================================================================

export function useSidebarStore() {
  const context = useContext(SidebarContext);
  if (!context) {
    throw new Error('useSidebarStore must be used within SidebarProvider');
  }
  return context;
}
