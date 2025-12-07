'use client';

import { useEffect, useState } from 'react';
import { useWatchContractEvent } from 'wagmi';
import { MarketBaseABI } from '@pitchone/contracts';
import type { Address } from 'viem';

/**
 * 市场事件类型
 */
export interface BetPlacedEvent {
  user: Address;
  outcomeId: bigint;
  amount: bigint;
  shares: bigint;
  fee: bigint;
  blockNumber: bigint | null;
  transactionHash: string | null;
  timestamp: number;
}

export interface MarketLockedEvent {
  timestamp: number;
  blockNumber: bigint | null;
  transactionHash: string | null;
}

export interface ResultProposedEvent {
  proposer: Address;
  winnerOutcome: bigint;
  timestamp: number;
  blockNumber: bigint | null;
  transactionHash: string | null;
}

export interface PositionRedeemedEvent {
  user: Address;
  outcomeId: bigint;
  shares: bigint;
  payout: bigint;
  blockNumber: bigint | null;
  transactionHash: string | null;
  timestamp: number;
}

/**
 * 监听 BetPlaced 事件
 * @param marketAddress 市场合约地址
 */
export function useWatchBetPlaced(marketAddress?: Address) {
  const [events, setEvents] = useState<BetPlacedEvent[]>([]);

  useWatchContractEvent({
    address: marketAddress,
    abi: MarketBaseABI,
    eventName: 'BetPlaced',
    chainId: 31337, // Anvil 本地链
    onLogs: (logs) => {
      console.log('[useWatchBetPlaced] 收到新事件:', logs.length, '条');
      const newEvents = logs.map((log) => {
        // wagmi 返回解析后的日志，args 包含事件参数
        const args = (log as any).args as {
          user?: Address;
          outcomeId?: bigint;
          amount?: bigint;
          shares?: bigint;
          fee?: bigint;
        };
        return {
          user: args?.user ?? ('0x' as Address),
          outcomeId: args?.outcomeId ?? 0n,
          amount: args?.amount ?? 0n,
          shares: args?.shares ?? 0n,
          fee: args?.fee ?? 0n,
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
          timestamp: Date.now(),
        };
      });

      setEvents((prev) => [...newEvents, ...prev].slice(0, 100)); // 保留最近 100 条
      console.log('[useWatchBetPlaced] 更新后事件总数:', newEvents.length + Math.min(100, events.length));
    },
    enabled: !!marketAddress,
  });

  return events;
}

/**
 * 监听 MarketLocked 事件
 * @param marketAddress 市场合约地址
 */
export function useWatchMarketLocked(marketAddress?: Address) {
  const [event, setEvent] = useState<MarketLockedEvent | null>(null);

  useWatchContractEvent({
    address: marketAddress,
    abi: MarketBaseABI,
    eventName: 'MarketLocked',
    onLogs: (logs) => {
      if (logs.length > 0) {
        const log = logs[logs.length - 1]; // 取最新的事件
        setEvent({
          timestamp: Date.now(),
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
        });
      }
    },
    enabled: !!marketAddress,
  });

  return event;
}

/**
 * 监听 ResultProposed 事件
 * @param marketAddress 市场合约地址
 */
export function useWatchResultProposed(marketAddress?: Address) {
  const [event, setEvent] = useState<ResultProposedEvent | null>(null);

  useWatchContractEvent({
    address: marketAddress,
    abi: MarketBaseABI,
    eventName: 'ResultProposed',
    onLogs: (logs) => {
      if (logs.length > 0) {
        const log = logs[logs.length - 1];
        // wagmi 返回解析后的日志，args 包含事件参数
        const args = (log as any).args as {
          proposer?: Address;
          winnerOutcome?: bigint;
        };
        setEvent({
          proposer: args?.proposer ?? ('0x' as Address),
          winnerOutcome: args?.winnerOutcome ?? 0n,
          timestamp: Date.now(),
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
        });
      }
    },
    enabled: !!marketAddress,
  });

  return event;
}

/**
 * 监听 PositionRedeemed 事件
 * @param marketAddress 市场合约地址
 * @param userAddress 用户地址（可选，用于过滤）
 */
export function useWatchPositionRedeemed(marketAddress?: Address, userAddress?: Address) {
  const [events, setEvents] = useState<PositionRedeemedEvent[]>([]);

  useWatchContractEvent({
    address: marketAddress,
    abi: MarketBaseABI,
    eventName: 'PositionRedeemed',
    onLogs: (logs) => {
      const filteredLogs = userAddress
        ? logs.filter((log) => {
            // wagmi 返回解析后的日志，args 包含事件参数
            const args = (log as any).args as { user?: Address };
            return args?.user === userAddress;
          })
        : logs;

      const newEvents = filteredLogs.map((log) => {
        // wagmi 返回解析后的日志，args 包含事件参数
        const args = (log as any).args as {
          user?: Address;
          outcomeId?: bigint;
          shares?: bigint;
          payout?: bigint;
        };
        return {
          user: args?.user ?? ('0x' as Address),
          outcomeId: args?.outcomeId ?? 0n,
          shares: args?.shares ?? 0n,
          payout: args?.payout ?? 0n,
          blockNumber: log.blockNumber,
          transactionHash: log.transactionHash,
          timestamp: Date.now(),
        };
      });

      setEvents((prev) => [...newEvents, ...prev].slice(0, 100));
    },
    enabled: !!marketAddress,
  });

  return events;
}

/**
 * 组合 hook：监听市场所有重要事件
 * @param marketAddress 市场合约地址
 * @param userAddress 用户地址（可选）
 */
export function useMarketEvents(marketAddress?: Address, userAddress?: Address) {
  const betPlacedEvents = useWatchBetPlaced(marketAddress);
  const marketLockedEvent = useWatchMarketLocked(marketAddress);
  const resultProposedEvent = useWatchResultProposed(marketAddress);
  const positionRedeemedEvents = useWatchPositionRedeemed(marketAddress, userAddress);

  return {
    betPlaced: betPlacedEvents,
    marketLocked: marketLockedEvent,
    resultProposed: resultProposedEvent,
    positionRedeemed: positionRedeemedEvents,
  };
}

/**
 * 自动刷新 hook - 基于事件触发或定时轮询
 * @param onRefresh 刷新回调函数
 * @param marketAddress 市场合约地址
 * @param options 配置选项
 */
export function useAutoRefresh(
  onRefresh: () => void,
  marketAddress?: Address,
  options: {
    enabled?: boolean;
    pollInterval?: number; // 轮询间隔（毫秒），0 表示禁用轮询
  } = {}
) {
  const { enabled = true, pollInterval = 10000 } = options;

  // 监听事件
  const events = useMarketEvents(marketAddress);

  // 事件触发刷新
  useEffect(() => {
    if (enabled && events.betPlaced.length > 0) {
      onRefresh();
    }
  }, [events.betPlaced.length, enabled]);

  useEffect(() => {
    if (enabled && events.marketLocked) {
      onRefresh();
    }
  }, [events.marketLocked, enabled]);

  useEffect(() => {
    if (enabled && events.resultProposed) {
      onRefresh();
    }
  }, [events.resultProposed, enabled]);

  // 定时轮询（备选方案）
  useEffect(() => {
    if (!enabled || pollInterval <= 0) return;

    const interval = setInterval(() => {
      onRefresh();
    }, pollInterval);

    return () => clearInterval(interval);
  }, [enabled, pollInterval, onRefresh]);

  return events;
}
