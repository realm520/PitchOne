'use client';

import { useEffect, useState } from 'react';
import { usePublicClient, useWatchContractEvent } from 'wagmi';
import { MarketBaseABI } from '@pitchone/contracts';
import type { Address, Log } from 'viem';

/**
 * 市场事件类型
 */
export interface BetPlacedEvent {
  user: Address;
  outcomeId: bigint;
  amount: bigint;
  shares: bigint;
  fee: bigint;
  blockNumber: bigint;
  transactionHash: string;
  timestamp: number;
}

export interface MarketLockedEvent {
  timestamp: number;
  blockNumber: bigint;
  transactionHash: string;
}

export interface ResultProposedEvent {
  proposer: Address;
  winnerOutcome: bigint;
  timestamp: number;
  blockNumber: bigint;
  transactionHash: string;
}

export interface PositionRedeemedEvent {
  user: Address;
  outcomeId: bigint;
  shares: bigint;
  payout: bigint;
  blockNumber: bigint;
  transactionHash: string;
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
    onLogs: (logs) => {
      const newEvents = logs.map((log) => ({
        user: log.args.user as Address,
        outcomeId: log.args.outcomeId as bigint,
        amount: log.args.amount as bigint,
        shares: log.args.shares as bigint,
        fee: log.args.fee as bigint,
        blockNumber: log.blockNumber,
        transactionHash: log.transactionHash,
        timestamp: Date.now(),
      }));

      setEvents((prev) => [...newEvents, ...prev].slice(0, 100)); // 保留最近 100 条
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
        setEvent({
          proposer: log.args.proposer as Address,
          winnerOutcome: log.args.winnerOutcome as bigint,
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
        ? logs.filter((log) => log.args.user === userAddress)
        : logs;

      const newEvents = filteredLogs.map((log) => ({
        user: log.args.user as Address,
        outcomeId: log.args.outcomeId as bigint,
        shares: log.args.shares as bigint,
        payout: log.args.payout as bigint,
        blockNumber: log.blockNumber,
        transactionHash: log.transactionHash,
        timestamp: Date.now(),
      }));

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
