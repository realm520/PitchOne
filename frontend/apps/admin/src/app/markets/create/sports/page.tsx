'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { graphqlClient } from '@pitchone/web3';
import { Card, Button, Badge, LoadingSpinner } from '@pitchone/ui';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';

// 运动分类
const SPORT_CATEGORIES = [
  { id: 'football', name: '足球', icon: '⚽' },
  { id: 'basketball', name: '篮球', icon: '🏀' },
  { id: 'tennis', name: '网球', icon: '🎾' },
  { id: 'baseball', name: '棒球', icon: '⚾' },
];

// 赛事查询（未创建市场的）
const AVAILABLE_MATCHES_QUERY = `
  query AvailableMatches($first: Int, $skip: Int, $sport: String, $league: String) {
    matches(
      first: $first
      skip: $skip
      where: {
        sport: $sport
        league: $league
        hasMarket: false
        status: scheduled
      }
      orderBy: kickoffTime
      orderDirection: asc
    ) {
      id
      sport
      league
      leagueName
      season
      round
      homeTeamCode
      homeTeamName
      awayTeamCode
      awayTeamName
      kickoffTime
      status
      hasMarket
    }
  }
`;

// 联赛列表查询
const LEAGUES_FROM_MATCHES_QUERY = `
  query LeaguesFromMatches($sport: String) {
    matches(
      first: 1000
      where: { sport: $sport, status: scheduled, hasMarket: false }
    ) {
      league
      leagueName
    }
  }
`;

// Match 类型定义
interface Match {
  id: string;
  sport: string;
  league: string;
  leagueName: string;
  season: string;
  round: string | null;
  homeTeamCode: string;
  homeTeamName: string;
  awayTeamCode: string;
  awayTeamName: string;
  kickoffTime: string;
  status: string;
  hasMarket: boolean;
}

export default function SportsMatchesPage() {
  const router = useRouter();
  const [selectedSport, setSelectedSport] = useState('football');
  const [selectedLeague, setSelectedLeague] = useState('');
  const [searchQuery, setSearchQuery] = useState('');

  // 获取联赛列表
  const { data: leaguesData } = useQuery({
    queryKey: ['leagues', selectedSport],
    queryFn: async () => {
      const data: { matches: { league: string; leagueName: string }[] } = await graphqlClient.request(
        LEAGUES_FROM_MATCHES_QUERY,
        { sport: selectedSport }
      );
      // 去重
      const leagueMap = new Map<string, string>();
      data.matches.forEach((m) => {
        if (!leagueMap.has(m.league)) {
          leagueMap.set(m.league, m.leagueName);
        }
      });
      return Array.from(leagueMap.entries()).map(([code, name]) => ({
        id: code.toLowerCase(),
        code,
        name,
      }));
    },
  });

  // 获取未创建市场的赛事
  const { data: matches, isLoading, error } = useQuery({
    queryKey: ['available-matches', selectedSport, selectedLeague],
    queryFn: async () => {
      const variables: Record<string, unknown> = {
        first: 100,
        skip: 0,
        sport: selectedSport,
      };
      if (selectedLeague) {
        variables.league = selectedLeague.toUpperCase();
      }
      const data: { matches: Match[] } = await graphqlClient.request(AVAILABLE_MATCHES_QUERY, variables);
      return data.matches;
    },
  });

  // 过滤赛事（按搜索关键词）
  const filteredMatches = matches?.filter((match) => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      match.homeTeamName.toLowerCase().includes(query) ||
      match.awayTeamName.toLowerCase().includes(query) ||
      match.id.toLowerCase().includes(query)
    );
  }) || [];

  // 处理创建市场
  const handleCreateMarket = (match: Match) => {
    const params = new URLSearchParams({
      matchId: match.id,
      homeTeam: match.homeTeamName,
      awayTeam: match.awayTeamName,
      kickoffTime: match.kickoffTime,
      league: match.leagueName,
      season: match.season,
      round: match.round || '',
    });
    router.push(`/markets/create/sports/new?${params.toString()}`);
  };

  // 加载状态
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载赛事数据..." />
      </div>
    );
  }

  // 错误状态
  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <Card className="p-8 text-center max-w-md">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            数据加载失败
          </h2>
          <p className="text-gray-500 dark:text-gray-400 mb-6">
            {error instanceof Error ? error.message : '无法连接到数据源'}
          </p>
          <Button variant="neon" onClick={() => window.location.reload()}>
            重试
          </Button>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                选择体育赛事
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                选择一场赛事来创建预测市场
              </p>
            </div>
            <div className="flex items-center gap-4">
              <Link href="/markets/create/sports/manual">
                <Button variant="neon" size="sm">
                  + 手动创建市场
                </Button>
              </Link>
              <Link href="/markets/create" className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200">
                ← 返回
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 运动分类标签 */}
        <div className="flex items-center gap-2 mb-6 overflow-x-auto pb-2">
          {SPORT_CATEGORIES.map((sport) => (
            <button
              key={sport.id}
              onClick={() => {
                setSelectedSport(sport.id);
                setSelectedLeague('');
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all ${
                selectedSport === sport.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700'
              }`}
            >
              <span>{sport.icon}</span>
              <span>{sport.name}</span>
            </button>
          ))}
        </div>

        <div className="flex gap-6">
          {/* 左侧：联赛列表 */}
          <div className="w-64 flex-shrink-0">
            <Card className="p-4">
              <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">
                联赛
              </h3>
              <div className="space-y-1">
                <button
                  onClick={() => setSelectedLeague('')}
                  className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-all ${
                    selectedLeague === ''
                      ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 font-medium'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                  }`}
                >
                  <div className="font-medium">全部联赛</div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    {matches?.length || 0} 场赛事
                  </div>
                </button>
                {leaguesData?.map((league) => (
                  <button
                    key={league.id}
                    onClick={() => setSelectedLeague(league.code)}
                    className={`w-full text-left px-3 py-2 rounded-lg text-sm transition-all ${
                      selectedLeague.toLowerCase() === league.id
                        ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 font-medium'
                        : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                    }`}
                  >
                    <div className="font-medium">{league.name}</div>
                  </button>
                ))}
              </div>
            </Card>
          </div>

          {/* 右侧：赛事列表 */}
          <div className="flex-1">
            {/* 搜索框 */}
            <div className="mb-4">
              <input
                type="text"
                placeholder="搜索球队名称..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 赛事表格 */}
            <Card className="overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                    <tr>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        赛事
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        轮次
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        主队
                      </th>
                      <th className="py-3 px-4 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        VS
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        客队
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        开赛时间
                      </th>
                      <th className="py-3 px-4 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        操作
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredMatches.map((match, index) => {
                      const kickoffTime = new Date(Number(match.kickoffTime) * 1000);

                      return (
                        <tr
                          key={match.id}
                          className={`hover:bg-gray-50 dark:hover:bg-gray-800 ${
                            index < filteredMatches.length - 1 ? 'border-b dark:border-gray-700' : ''
                          }`}
                        >
                          <td className="py-4 px-4">
                            <div className="flex flex-col">
                              <span className="text-sm font-medium text-gray-900 dark:text-white">
                                {match.leagueName}
                              </span>
                              <span className="text-xs text-gray-500 dark:text-gray-400">
                                {match.season}
                              </span>
                            </div>
                          </td>
                          <td className="py-4 px-4">
                            {match.round ? (
                              <Badge variant="default">{match.round}</Badge>
                            ) : (
                              <span className="text-gray-400">-</span>
                            )}
                          </td>
                          <td className="py-4 px-4">
                            <span className="font-medium text-gray-900 dark:text-white">
                              {match.homeTeamName}
                            </span>
                          </td>
                          <td className="py-4 px-4 text-center">
                            <span className="text-gray-400 dark:text-gray-500">vs</span>
                          </td>
                          <td className="py-4 px-4">
                            <span className="font-medium text-gray-900 dark:text-white">
                              {match.awayTeamName}
                            </span>
                          </td>
                          <td className="py-4 px-4">
                            <div className="flex flex-col">
                              <span className="text-sm text-gray-900 dark:text-white">
                                {kickoffTime.toLocaleString('zh-CN', {
                                  month: 'numeric',
                                  day: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit',
                                })}
                              </span>
                              <span className="text-xs text-gray-500 dark:text-gray-400">
                                {formatDistanceToNow(kickoffTime, {
                                  addSuffix: true,
                                  locale: zhCN,
                                })}
                              </span>
                            </div>
                          </td>
                          <td className="py-4 px-4 text-right">
                            <Button
                              variant="neon"
                              size="sm"
                              onClick={() => handleCreateMarket(match)}
                            >
                              创建市场
                            </Button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>

              {filteredMatches.length === 0 && (
                <div className="p-12 text-center">
                  <div className="text-gray-400 dark:text-gray-500 mb-4">
                    <svg
                      className="mx-auto h-12 w-12"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                      />
                    </svg>
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                    暂无赛事
                  </h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {searchQuery
                      ? '没有符合搜索条件的赛事'
                      : '该联赛暂无可创建市场的赛事'}
                  </p>
                </div>
              )}
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
