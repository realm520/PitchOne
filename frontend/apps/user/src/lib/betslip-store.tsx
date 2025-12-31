'use client';

import { createContext, useContext, useState, useCallback, ReactNode } from 'react';

type Address = `0x${string}`;

// ============================================================================
// Type Definitions
// ============================================================================

export interface SelectedBet {
  marketAddress: Address;
  marketId: string;
  homeTeam: string;
  awayTeam: string;
  league: string;
  outcomeId: number;
  outcomeName: string;
  odds: string;
  templateType: string;
  line?: number; // For OU/AH markets
}

// 选中的市场信息（用于显示持仓）
export interface SelectedMarketInfo {
  marketId: string;
  homeTeam: string;
  awayTeam: string;
  league: string;
}

interface BetSlipStore {
  selectedBet: SelectedBet | null;
  selectBet: (bet: SelectedBet) => void;
  clearBet: () => void;
  isSelected: (marketAddress: Address, outcomeId: number) => boolean;
  updateOdds: (marketAddress: Address, outcomeId: number, newOdds: string) => void;
  // 刷新触发器：下注成功后递增，市场列表监听此值来触发刷新
  refreshCounter: number;
  triggerRefresh: () => void;
  // 选中的市场（用于显示持仓）
  selectedMarket: SelectedMarketInfo | null;
  selectMarket: (market: SelectedMarketInfo) => void;
  clearSelectedMarket: () => void;
  isMarketSelected: (marketId: string) => boolean;
}

// ============================================================================
// Context
// ============================================================================

const BetSlipContext = createContext<BetSlipStore | undefined>(undefined);

// ============================================================================
// Provider
// ============================================================================

export function BetSlipProvider({ children }: { children: ReactNode }) {
  const [selectedBet, setSelectedBet] = useState<SelectedBet | null>(null);
  const [refreshCounter, setRefreshCounter] = useState(0);
  const [selectedMarket, setSelectedMarket] = useState<SelectedMarketInfo | null>(null);

  // Select or replace bet
  const selectBet = useCallback((bet: SelectedBet) => {
    setSelectedBet(bet);
  }, []);

  // 触发市场列表刷新
  const triggerRefresh = useCallback(() => {
    setRefreshCounter(c => c + 1);
  }, []);

  // Clear selection
  const clearBet = useCallback(() => {
    setSelectedBet(null);
  }, []);

  // Check if specific market/outcome is selected
  const isSelected = useCallback(
    (marketAddress: Address, outcomeId: number) => {
      if (!selectedBet) return false;
      return (
        selectedBet.marketAddress.toLowerCase() === marketAddress.toLowerCase() &&
        selectedBet.outcomeId === outcomeId
      );
    },
    [selectedBet]
  );

  // Update odds for selected bet (for real-time updates)
  const updateOdds = useCallback(
    (marketAddress: Address, outcomeId: number, newOdds: string) => {
      setSelectedBet((prev) => {
        if (!prev) return null;
        if (
          prev.marketAddress.toLowerCase() === marketAddress.toLowerCase() &&
          prev.outcomeId === outcomeId
        ) {
          return { ...prev, odds: newOdds };
        }
        return prev;
      });
    },
    []
  );

  // 选中市场（用于显示持仓）
  const selectMarket = useCallback((market: SelectedMarketInfo) => {
    setSelectedMarket(market);
  }, []);

  // 清除选中的市场
  const clearSelectedMarket = useCallback(() => {
    setSelectedMarket(null);
  }, []);

  // 检查市场是否被选中
  const isMarketSelected = useCallback(
    (marketId: string) => {
      if (!selectedMarket) return false;
      return selectedMarket.marketId.toLowerCase() === marketId.toLowerCase();
    },
    [selectedMarket]
  );

  const value: BetSlipStore = {
    selectedBet,
    selectBet,
    clearBet,
    isSelected,
    updateOdds,
    refreshCounter,
    triggerRefresh,
    selectedMarket,
    selectMarket,
    clearSelectedMarket,
    isMarketSelected,
  };

  return <BetSlipContext.Provider value={value}>{children}</BetSlipContext.Provider>;
}

// ============================================================================
// Hook
// ============================================================================

export function useBetSlipStore() {
  const context = useContext(BetSlipContext);
  if (!context) {
    throw new Error('useBetSlipStore must be used within BetSlipProvider');
  }
  return context;
}
