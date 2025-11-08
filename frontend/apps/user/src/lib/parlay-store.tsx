'use client';

import { createContext, useContext, useState, useCallback, ReactNode } from 'react';

type Address = `0x${string}`;

// ============================================================================
// 类型定义
// ============================================================================

export interface SelectedOutcome {
  marketAddress: Address;
  marketName: string;
  outcomeId: number;
  outcomeName: string;
  odds: string;
}

interface ParlayStore {
  selectedOutcomes: SelectedOutcome[];
  addOutcome: (outcome: SelectedOutcome) => void;
  removeOutcome: (marketAddress: Address) => void;
  clearAll: () => void;
  hasMarket: (marketAddress: Address) => boolean;
  getOutcome: (marketAddress: Address) => SelectedOutcome | undefined;
}

// ============================================================================
// Context
// ============================================================================

const ParlayContext = createContext<ParlayStore | undefined>(undefined);

// ============================================================================
// Provider
// ============================================================================

export function ParlayProvider({ children }: { children: ReactNode }) {
  const [selectedOutcomes, setSelectedOutcomes] = useState<SelectedOutcome[]>([]);

  // 添加或更新结果
  const addOutcome = useCallback((outcome: SelectedOutcome) => {
    setSelectedOutcomes((prev) => {
      const index = prev.findIndex((o) => o.marketAddress === outcome.marketAddress);
      if (index >= 0) {
        // 替换已存在的市场
        const updated = [...prev];
        updated[index] = outcome;
        return updated;
      } else {
        // 添加新市场
        return [...prev, outcome];
      }
    });
  }, []);

  // 移除结果
  const removeOutcome = useCallback((marketAddress: Address) => {
    setSelectedOutcomes((prev) => prev.filter((o) => o.marketAddress !== marketAddress));
  }, []);

  // 清空所有
  const clearAll = useCallback(() => {
    setSelectedOutcomes([]);
  }, []);

  // 检查是否包含市场
  const hasMarket = useCallback(
    (marketAddress: Address) => {
      return selectedOutcomes.some((o) => o.marketAddress === marketAddress);
    },
    [selectedOutcomes]
  );

  // 获取市场的选择
  const getOutcome = useCallback(
    (marketAddress: Address) => {
      return selectedOutcomes.find((o) => o.marketAddress === marketAddress);
    },
    [selectedOutcomes]
  );

  const value: ParlayStore = {
    selectedOutcomes,
    addOutcome,
    removeOutcome,
    clearAll,
    hasMarket,
    getOutcome,
  };

  return <ParlayContext.Provider value={value}>{children}</ParlayContext.Provider>;
}

// ============================================================================
// Hook
// ============================================================================

export function useParlayStore() {
  const context = useContext(ParlayContext);
  if (!context) {
    throw new Error('useParlayStore must be used within ParlayProvider');
  }
  return context;
}
