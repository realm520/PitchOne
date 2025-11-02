'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, ORACLE_PROPOSALS_QUERY } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, Badge, Button } from '@pitchone/ui';
import { formatDistanceToNow, format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { useState } from 'react';

// 提案状态映射
const getProposalStatus = (proposal: any) => {
  if (proposal.finalized) {
    return {
      label: '已确认',
      color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      variant: 'success' as const
    };
  }
  if (proposal.disputed) {
    return {
      label: '已争议',
      color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
      variant: 'danger' as const
    };
  }
  return {
    label: '待确认',
    color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    variant: 'warning' as const
  };
};

// 结果标签映射
const RESULT_LABELS: Record<number, string> = {
  0: '主队胜/大',
  1: '平局',
  2: '客队胜/小',
};

// 提案表格行组件
function ProposalRow({ proposal }: { proposal: any }) {
  const status = getProposalStatus(proposal);
  const proposedAt = new Date(Number(proposal.proposedAt) * 1000);
  const disputedAt = proposal.disputedAt ? new Date(Number(proposal.disputedAt) * 1000) : null;
  const finalizedAt = proposal.finalizedAt ? new Date(Number(proposal.finalizedAt) * 1000) : null;

  // 计算争议窗口剩余时间（假设争议窗口为 2 小时）
  const disputeWindowEnd = new Date(proposedAt.getTime() + 2 * 60 * 60 * 1000);
  const isDisputeWindowOpen = !proposal.finalized && !proposal.disputed && disputeWindowEnd > new Date();
  const timeRemaining = isDisputeWindowOpen
    ? formatDistanceToNow(disputeWindowEnd, { addSuffix: true, locale: zhCN })
    : null;

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800 border-b dark:border-gray-700">
      <td className="py-4 px-4">
        {proposal.market ? (
          <div className="flex flex-col">
            <Link
              href={`/markets/${proposal.market.id}`}
              className="font-medium text-blue-600 dark:text-blue-400 hover:underline"
            >
              市场 {proposal.market.id.slice(0, 8)}...
            </Link>
            <span className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Match: {proposal.market.matchId.slice(0, 10)}... | State: {proposal.market.state}
            </span>
          </div>
        ) : (
          <span className="text-sm text-gray-500">市场未找到</span>
        )}
      </td>
      <td className="py-4 px-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col gap-1">
          <Badge variant="secondary">
            {RESULT_LABELS[proposal.result] || `结果 ${proposal.result}`}
          </Badge>
          {proposal.finalized && proposal.finalResult !== null && proposal.finalResult !== proposal.result && (
            <Badge variant="warning">
              最终: {RESULT_LABELS[proposal.finalResult] || `结果 ${proposal.finalResult}`}
            </Badge>
          )}
        </div>
      </td>
      <td className="py-4 px-4">
        <span className="font-mono text-xs text-gray-600 dark:text-gray-300">
          {proposal.proposer.slice(0, 6)}...{proposal.proposer.slice(-4)}
        </span>
      </td>
      <td className="py-4 px-4">
        <span className="font-semibold text-gray-900 dark:text-white">
          {(Number(proposal.bond) / 1e6).toFixed(2)} USDC
        </span>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="text-sm text-gray-900 dark:text-white">
            {format(proposedAt, 'MM/dd HH:mm', { locale: zhCN })}
          </span>
          {isDisputeWindowOpen && (
            <span className="text-xs text-orange-600 dark:text-orange-400 mt-1">
              争议窗口{timeRemaining}结束
            </span>
          )}
          {disputedAt && (
            <span className="text-xs text-red-600 dark:text-red-400 mt-1">
              争议于 {format(disputedAt, 'MM/dd HH:mm')}
            </span>
          )}
          {finalizedAt && (
            <span className="text-xs text-green-600 dark:text-green-400 mt-1">
              确认于 {format(finalizedAt, 'MM/dd HH:mm')}
            </span>
          )}
        </div>
      </td>
      <td className="py-4 px-4">
        {proposal.disputed && proposal.disputer && (
          <span className="font-mono text-xs text-red-600 dark:text-red-400">
            {proposal.disputer.slice(0, 6)}...{proposal.disputer.slice(-4)}
          </span>
        )}
      </td>
    </tr>
  );
}

// 筛选栏组件
function FilterBar({
  statusFilter,
  setStatusFilter,
}: {
  statusFilter: string;
  setStatusFilter: (value: string) => void;
}) {
  return (
    <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border dark:border-gray-700 mb-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* 状态筛选 */}
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            提案状态
          </label>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">全部状态</option>
            <option value="pending">待确认</option>
            <option value="disputed">已争议</option>
            <option value="finalized">已确认</option>
          </select>
        </div>
      </div>
    </div>
  );
}

export default function OraclesPage() {
  const [statusFilter, setStatusFilter] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [sortBy, setSortBy] = useState<'proposedAt' | 'bond'>('proposedAt');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const itemsPerPage = 20;

  // 获取 Oracle 提案列表
  const { data: proposals, isLoading, error } = useQuery({
    queryKey: ['oracle-proposals'],
    queryFn: async () => {
      const data: any = await graphqlClient.request(ORACLE_PROPOSALS_QUERY, {
        first: 1000,
        skip: 0,
      });
      return data.oracleProposals || [];
    },
  });

  // 客户端筛选
  const filteredProposals = proposals?.filter((proposal: any) => {
    if (!statusFilter) return true;

    if (statusFilter === 'pending') {
      return !proposal.disputed && !proposal.finalized;
    }
    if (statusFilter === 'disputed') {
      return proposal.disputed && !proposal.finalized;
    }
    if (statusFilter === 'finalized') {
      return proposal.finalized;
    }

    return true;
  });

  // 排序
  const sortedProposals = filteredProposals?.sort((a: any, b: any) => {
    let aValue, bValue;

    if (sortBy === 'bond') {
      aValue = Number(a.bond || 0);
      bValue = Number(b.bond || 0);
    } else {
      aValue = Number(a.proposedAt || 0);
      bValue = Number(b.proposedAt || 0);
    }

    if (sortDirection === 'asc') {
      return aValue - bValue;
    } else {
      return bValue - aValue;
    }
  });

  // 分页
  const totalPages = Math.ceil((sortedProposals?.length || 0) / itemsPerPage);
  const paginatedProposals = sortedProposals?.slice(
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
        <LoadingSpinner size="lg" text="加载 Oracle 提案数据..." />
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
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Oracle 提案管理
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                监控和管理 UMA 预言机的赛果提案
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/">
                <Button variant="outline">
                  返回看板
                </Button>
              </Link>
            </div>
          </div>
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
        />

        {/* 排序控件 */}
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg border dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">排序方式：</span>
              <select
                value={sortBy}
                onChange={(e) => {
                  setSortBy(e.target.value as 'proposedAt' | 'bond');
                  resetPagination();
                }}
                className="px-3 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="proposedAt">提案时间</option>
                <option value="bond">质押金额</option>
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
              显示 <span className="font-semibold text-gray-900 dark:text-white">{paginatedProposals?.length || 0}</span> / {sortedProposals?.length || 0} 个提案
              {proposals && sortedProposals && proposals.length !== sortedProposals.length && (
                <span>（已筛选，共 {proposals.length} 个）</span>
              )}
            </div>
          </div>
        </div>

        {/* 统计信息 */}
        <div className="mb-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card className="p-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">全部提案</div>
              <div className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
                {proposals?.length || 0}
              </div>
            </Card>
            <Card className="p-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">待确认</div>
              <div className="text-2xl font-bold text-yellow-600 dark:text-yellow-400 mt-1">
                {proposals?.filter((p: any) => !p.disputed && !p.finalized).length || 0}
              </div>
            </Card>
            <Card className="p-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">已争议</div>
              <div className="text-2xl font-bold text-red-600 dark:text-red-400 mt-1">
                {proposals?.filter((p: any) => p.disputed && !p.finalized).length || 0}
              </div>
            </Card>
            <Card className="p-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">已确认</div>
              <div className="text-2xl font-bold text-green-600 dark:text-green-400 mt-1">
                {proposals?.filter((p: any) => p.finalized).length || 0}
              </div>
            </Card>
          </div>
        </div>

        {/* 提案列表 */}
        {paginatedProposals && paginatedProposals.length > 0 ? (
          <Card className="overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                  <tr>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      市场
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      状态
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      提案结果
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      提案者
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      质押金额
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      时间
                    </th>
                    <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      争议者
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedProposals.map((proposal: any) => (
                    <ProposalRow key={proposal.id} proposal={proposal} />
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
                        className={`px-3 py-2 border dark:border-gray-600 rounded-lg ${
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
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              暂无提案数据
            </h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {statusFilter
                ? '没有符合筛选条件的提案'
                : '还没有任何 Oracle 提案'}
            </p>
          </Card>
        )}
      </div>
    </div>
  );
}
