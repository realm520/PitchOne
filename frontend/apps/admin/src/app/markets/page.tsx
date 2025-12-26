'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKETS_QUERY } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, Badge, Button } from '@pitchone/ui';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { useState } from 'react';
import { TEMPLATE_MAP, parseTemplateType } from '@/lib/market-utils';

// 市场状态映射
const STATUS_MAP = {
  Open: { label: '开盘中', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  Locked: { label: '已锁盘', color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' },
  Resolved: { label: '已结算', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
  Finalized: { label: '已完成', color: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200' },
};

// 从 matchId 解析联赛和赛季信息
// 假设格式: EPL_2024_MUN_vs_MCI 或类似格式
function parseMatchInfo(matchId: string) {
  const parts = matchId.split('_');
  if (parts.length >= 4) {
    const league = parts[0]; // 联赛代码
    const season = parts[1]; // 赛季
    const vsIndex = parts.findIndex(p => p.toLowerCase() === 'vs');
    if (vsIndex > 2) {
      const homeTeam = parts.slice(2, vsIndex).join(' ');
      const awayTeam = parts.slice(vsIndex + 1).join(' ');
      return { league, season, homeTeam, awayTeam };
    }
  }
  // 如果无法解析，返回默认值
  return { league: 'Unknown', season: '-', homeTeam: matchId, awayTeam: '' };
}

// 联赛代码到名称映射（用于已知的标准代码）
const LEAGUE_MAP: Record<string, string> = {
  EPL: '英超联赛',
  LALIGA: '西甲联赛',
  SERIEA: '意甲联赛',
  BUNDESLIGA: '德甲联赛',
  LIGUE1: '法甲联赛',
  UCL: '欧冠联赛',
  UEL: '欧联杯',
  WC: '世界杯',
  NBA: 'NBA',
  MLB: 'MLB',
  PREMIER_LEAGUE: '英超联赛',
  LA_LIGA: '西甲联赛',
  SERIE_A: '意甲联赛',
  CHAMPIONS_LEAGUE: '欧冠联赛',
};

// 格式化联赛名称（将下划线分隔的名称转为正常格式）
function formatLeagueName(rawLeague: string): string {
  // 先查找已知映射
  if (LEAGUE_MAP[rawLeague]) {
    return LEAGUE_MAP[rawLeague];
  }
  // 如果是 CUSTOM，返回"自定义赛事"
  if (rawLeague === 'CUSTOM' || rawLeague === 'Unknown') {
    return '自定义赛事';
  }
  // 将下划线替换为空格，每个单词首字母大写
  return rawLeague
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

// 市场表格行组件
function MarketRow({ market, isLast }: { market: any; isLast: boolean }) {
  const status = STATUS_MAP[market.state as keyof typeof STATUS_MAP] || {
    label: market.state,
    color: 'bg-gray-100 text-gray-800'
  };

  const createdTime = new Date(Number(market.createdAt) * 1000);
  const kickoffTime = market.kickoffTime ? new Date(Number(market.kickoffTime) * 1000) : null;

  // 解析赛事信息
  const matchInfo = parseMatchInfo(market.matchId || '');
  const leagueName = formatLeagueName(matchInfo.league);

  return (
    <tr className={`hover:bg-gray-50 dark:hover:bg-gray-800 ${isLast ? '' : 'border-b dark:border-gray-700'}`}>
      {/* 赛事列 */}
      <td className="py-3 px-4 min-w-[200px]">
        <Link href={`/markets/${market.id}`} className="block hover:opacity-80">
          <div className="flex flex-col">
            <div className="flex items-center gap-2 mb-0.5">
              <span className="text-xs font-medium text-gray-500 dark:text-gray-400">{leagueName}</span>
              <span className="text-xs text-gray-400 dark:text-gray-500">{matchInfo.season}</span>
            </div>
            <div className="font-medium text-gray-900 dark:text-white whitespace-nowrap">
              {market.homeTeam || matchInfo.homeTeam}
              <span className="text-gray-400 dark:text-gray-500 mx-1">vs</span>
              {market.awayTeam || matchInfo.awayTeam}
            </div>
          </div>
        </Link>
      </td>
      {/* 状态列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </td>
      {/* 模式列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200">
          奖金池模式
        </span>
      </td>
      {/* 类型列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
          Live Market
        </span>
      </td>
      {/* 玩法列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <Badge variant="default">
          {TEMPLATE_MAP[parseTemplateType(market.templateId)] || '胜平负'}
        </Badge>
      </td>
      {/* 开赛时间列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <div className="text-sm text-gray-900 dark:text-white">
          {kickoffTime ? kickoffTime.toLocaleString('zh-CN', {
            month: 'numeric',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
          }) : '-'}
        </div>
        {kickoffTime && (
          <div className="text-xs text-gray-500 dark:text-gray-400">
            {formatDistanceToNow(kickoffTime, { addSuffix: true, locale: zhCN })}
          </div>
        )}
      </td>
      {/* 交易量列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <span className="font-semibold text-gray-900 dark:text-white">
          {Number(market.totalVolume || 0).toFixed(2)} USDC
        </span>
      </td>
      {/* 创建时间列 */}
      <td className="py-3 px-3 whitespace-nowrap">
        <span className="text-sm text-gray-600 dark:text-gray-300">
          {formatDistanceToNow(createdTime, { addSuffix: true, locale: zhCN })}
        </span>
      </td>
      {/* 操作列 */}
      <td className="py-3 px-3 whitespace-nowrap text-right">
        <Link href={`/markets/${market.id}`}>
          <Button variant="neon" size="sm">查看详情</Button>
        </Link>
      </td>
    </tr>
  );
}

// 筛选栏组件
function FilterBar({
  statusFilter,
  setStatusFilter,
  templateFilter,
  setTemplateFilter,
  searchQuery,
  setSearchQuery
}: {
  statusFilter: string;
  setStatusFilter: (value: string) => void;
  templateFilter: string;
  setTemplateFilter: (value: string) => void;
  searchQuery: string;
  setSearchQuery: (value: string) => void;
}) {
  return (
    <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border dark:border-gray-700 mb-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* 搜索框 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            搜索市场
          </label>
          <input
            type="text"
            placeholder="输入球队名称或赛事..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {/* 状态筛选 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            市场状态
          </label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">全部状态</option>
            <option value="Open">开盘中</option>
            <option value="Locked">已锁盘</option>
            <option value="Resolved">已结算</option>
          </select>
        </div>

        {/* 玩法类型筛选 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            玩法类型
          </label>
          <select
            value={templateFilter}
            onChange={(e) => setTemplateFilter(e.target.value)}
            className="w-full px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">全部玩法</option>
            <option value="WDL">胜平负</option>
            <option value="OU">大小球</option>
            <option value="AH">让球</option>
            <option value="Score">精确比分</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default function MarketsPage() {
  const [statusFilter, setStatusFilter] = useState('');
  const [templateFilter, setTemplateFilter] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [sortBy, setSortBy] = useState<'createdAt' | 'totalVolume'>('createdAt');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const itemsPerPage = 10;

  // 获取市场列表
  const { data: markets, isLoading, error } = useQuery({
    queryKey: ['admin-markets'],
    queryFn: async () => {
      const data: any = await graphqlClient.request(MARKETS_QUERY, {
        first: 1000,
        skip: 0,
      });
      return data.markets;
    },
  });

  // 客户端筛选
  const filteredMarkets = markets?.filter((market: any) => {
    // 状态筛选
    if (statusFilter && market.state !== statusFilter) return false;

    // 玩法类型筛选 (使用 templateId)
    if (templateFilter && market.templateId !== templateFilter) return false;

    // 搜索筛选 (使用 market ID 和 matchId)
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      const marketId = market.id?.toLowerCase() || '';
      const matchId = market.matchId?.toLowerCase() || '';

      if (!marketId.includes(query) && !matchId.includes(query)) {
        return false;
      }
    }

    return true;
  });

  // 排序
  const sortedMarkets = filteredMarkets?.sort((a: any, b: any) => {
    let aValue, bValue;

    if (sortBy === 'totalVolume') {
      aValue = Number(a.totalVolume || 0);
      bValue = Number(b.totalVolume || 0);
    } else {
      aValue = Number(a.createdAt || 0);
      bValue = Number(b.createdAt || 0);
    }

    if (sortDirection === 'asc') {
      return aValue - bValue;
    } else {
      return bValue - aValue;
    }
  });

  // 分页
  const totalPages = Math.ceil((sortedMarkets?.length || 0) / itemsPerPage);
  const paginatedMarkets = sortedMarkets?.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  // 重置分页当筛选条件变化时
  const resetPagination = () => {
    setCurrentPage(1);
  };

  // 加载状态
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" text="加载市场数据..." />
      </div>
    );
  }

  // 错误状态
  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <ErrorState
          title="数据加载失败"
          message={error instanceof Error ? error.message : '无法连接到 Subgraph'}
          onRetry={() => window.location.reload()}
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Page Title */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">市场管理</h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">查看和管理所有博彩市场</p>
          </div>
          <Link href="/markets/create">
            <Button variant="neon">+ 创建市场</Button>
          </Link>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 筛选栏 */}
        <FilterBar
          statusFilter={statusFilter}
          setStatusFilter={(value) => {
            setStatusFilter(value);
            resetPagination();
          }}
          templateFilter={templateFilter}
          setTemplateFilter={(value) => {
            setTemplateFilter(value);
            resetPagination();
          }}
          searchQuery={searchQuery}
          setSearchQuery={(value) => {
            setSearchQuery(value);
            resetPagination();
          }}
        />

        {/* 排序控件 */}
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">排序方式：</span>
              <select
                value={sortBy}
                onChange={(e) => {
                  setSortBy(e.target.value as 'createdAt' | 'totalVolume');
                  resetPagination();
                }}
                className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="createdAt">创建时间</option>
                <option value="totalVolume">交易量</option>
              </select>
              <button
                onClick={() => {
                  setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc');
                  resetPagination();
                }}
                className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {sortDirection === 'desc' ? '↓ 降序' : '↑ 升序'}
              </button>
            </div>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              显示 <span className="font-semibold text-gray-900 dark:text-white">{paginatedMarkets?.length || 0}</span> / {sortedMarkets?.length || 0} 个市场
              {markets && sortedMarkets && markets.length !== sortedMarkets.length && (
                <span>（已筛选，共 {markets.length} 个）</span>
              )}
            </div>
          </div>
        </div>

        {/* 市场列表 */}
        {paginatedMarkets && paginatedMarkets.length > 0 ? (
          <Card className="overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                  <tr>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      赛事
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      状态
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      模式
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      类型
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      玩法
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      开赛时间
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      交易量
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      创建时间
                    </th>
                    <th className="py-3 px-4 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      操作
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedMarkets.map((market: any, index: number) => (
                    <MarketRow
                      key={market.id}
                      market={market}
                      isLast={index === paginatedMarkets.length - 1}
                    />
                  ))}
                </tbody>
              </table>
            </div>

            {/* 分页控件 */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between px-6 py-4 border-t dark:border-gray-700">
                <div className="text-sm text-gray-600 dark:text-gray-400">
                  第 {currentPage} / {totalPages} 页
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setCurrentPage(1)}
                    disabled={currentPage === 1}
                    className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    首页
                  </button>
                  <button
                    onClick={() => setCurrentPage(currentPage - 1)}
                    disabled={currentPage === 1}
                    className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    上一页
                  </button>
                  {/* 页码按钮 */}
                  {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                    let pageNum;
                    if (totalPages <= 5) {
                      pageNum = i + 1;
                    } else if (currentPage <= 3) {
                      pageNum = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      pageNum = totalPages - 4 + i;
                    } else {
                      pageNum = currentPage - 2 + i;
                    }
                    return (
                      <button
                        key={pageNum}
                        onClick={() => setCurrentPage(pageNum)}
                        className={`w-10 h-10 flex items-center justify-center border dark:border-gray-600 rounded-lg text-sm font-medium ${
                          currentPage === pageNum
                            ? 'bg-blue-600 text-white border-blue-600'
                            : 'bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600'
                        }`}
                      >
                        {pageNum}
                      </button>
                    );
                  })}
                  <button
                    onClick={() => setCurrentPage(currentPage + 1)}
                    disabled={currentPage === totalPages}
                    className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    下一页
                  </button>
                  <button
                    onClick={() => setCurrentPage(totalPages)}
                    disabled={currentPage === totalPages}
                    className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white hover:bg-gray-50 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    末页
                  </button>
                </div>
              </div>
            )}
          </Card>
        ) : (
          <Card className="p-12 text-center">
            <div className="text-gray-400 dark:text-gray-500 mb-4">
              <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              暂无市场数据
            </h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {searchQuery || statusFilter || templateFilter
                ? '没有符合筛选条件的市场'
                : '还没有创建任何市场'}
            </p>
          </Card>
        )}
      </div>
    </div>
  );
}
