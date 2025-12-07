'use client';

import { useMemo } from 'react';
import { useMarkets, type Market } from '@pitchone/web3';
import { FOOTBALL_LEAGUES, parseLeagueFromMatchId, type League } from '../types/sports';

/**
 * 获取指定体育类型的联赛列表
 * 从已有市场数据中聚合联赛信息和市场数量
 */
export function useLeagues(sportId: string) {
  // 获取所有市场数据
  const { data: markets, isLoading, error } = useMarkets();

  // 聚合联赛数据
  const leagues = useMemo(() => {
    if (!markets || sportId !== 'football') {
      return [];
    }

    // 统计每个联赛的市场数量
    const leagueCountMap = new Map<string, number>();

    markets.forEach((market: Market) => {
      const leagueId = parseLeagueFromMatchId(market.matchId);
      leagueCountMap.set(leagueId, (leagueCountMap.get(leagueId) || 0) + 1);
    });

    // 将预定义的联赛配置与市场数量合并
    const result: League[] = FOOTBALL_LEAGUES.map((league) => ({
      ...league,
      marketCount: leagueCountMap.get(league.id) || 0,
    }));

    // 按 order 排序，然后按 marketCount 降序（有市场的优先显示）
    result.sort((a, b) => {
      // 有市场的排在前面
      if (a.marketCount > 0 && b.marketCount === 0) return -1;
      if (a.marketCount === 0 && b.marketCount > 0) return 1;
      // 同类型按 order 排序
      return a.order - b.order;
    });

    return result;
  }, [markets, sportId]);

  return {
    leagues,
    isLoading,
    error,
  };
}

/**
 * 获取指定联赛的市场过滤器
 */
export function useLeagueFilter(leagueId: string | null) {
  return useMemo(() => {
    if (!leagueId) return null;

    // 返回一个过滤函数，用于筛选市场
    return (market: Market) => {
      const marketLeagueId = parseLeagueFromMatchId(market.matchId);
      return marketLeagueId === leagueId;
    };
  }, [leagueId]);
}
