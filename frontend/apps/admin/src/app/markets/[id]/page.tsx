'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKET_QUERY, useLockMarket, useAccount } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, Badge, Button } from '@pitchone/ui';
import { format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { use, useState } from 'react';

// 市场状态映射
const STATUS_MAP = {
  Open: { label: '开盘中', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  Locked: { label: '已锁盘', color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' },
  Resolved: { label: '已结算', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
  Finalized: { label: '已完成', color: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200' },
};

// 玩法类型映射
const TEMPLATE_TYPE_MAP: Record<string, string> = {
  WDL: '胜平负',
  OU: '大小球',
  AH: '让球',
  Score: '精确比分',
};

// 信息卡片组件
function InfoCard({ title, value, subtitle }: { title: string; value: string; subtitle?: string }) {
  return (
    <Card className="p-6">
      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">{title}</h3>
      <p className="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
      {subtitle && (
        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{subtitle}</p>
      )}
    </Card>
  );
}

export default function MarketDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { isConnected } = useAccount();
  const [showLockConfirm, setShowLockConfirm] = useState(false);

  // 锁盘功能
  const {
    lockMarket,
    isPending: isLockPending,
    isConfirming: isLockConfirming,
    isSuccess: isLockSuccess,
    error: lockError,
    hash: lockHash
  } = useLockMarket(id as `0x${string}`);

  // 获取市场详情
  const { data: market, isLoading, error, refetch } = useQuery({
    queryKey: ['market', id],
    queryFn: async () => {
      const data: any = await graphqlClient.request(MARKET_QUERY, { id });
      return data.market;
    },
  });

  // 处理锁盘
  const handleLockMarket = async () => {
    if (!isConnected) {
      alert('请先连接钱包');
      return;
    }

    try {
      await lockMarket();
      setShowLockConfirm(false);
      // 3秒后刷新市场数据
      setTimeout(() => {
        refetch();
      }, 3000);
    } catch (err) {
      console.error('锁盘失败:', err);
    }
  };

  // 加载状态
  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" text="加载市场详情..." />
      </div>
    );
  }

  // 错误状态
  if (error || !market) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <ErrorState
          title="数据加载失败"
          message={error instanceof Error ? error.message : '市场不存在或无法加载'}
          onRetry={() => window.location.reload()}
        />
      </div>
    );
  }

  const status = STATUS_MAP[market.state as keyof typeof STATUS_MAP] || {
    label: market.state,
    color: 'bg-gray-100 text-gray-800'
  };

  const createdAt = new Date(Number(market.createdAt) * 1000);
  const lockedAt = market.lockedAt ? new Date(Number(market.lockedAt) * 1000) : null;
  const resolvedAt = market.resolvedAt ? new Date(Number(market.resolvedAt) * 1000) : null;
  const finalizedAt = market.finalizedAt ? new Date(Number(market.finalizedAt) * 1000) : null;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                  市场 {market.id.slice(0, 8)}...
                </h1>
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${status.color}`}>
                  {status.label}
                </span>
              </div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Match: {market.matchId.slice(0, 10)}... · Template: {market.templateId.slice(0, 10)}...
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/markets">
                <Button variant="outline">
                  返回列表
                </Button>
              </Link>
              {market.state === 'Open' && (
                <Button
                  variant="secondary"
                  onClick={() => setShowLockConfirm(true)}
                  disabled={!isConnected || isLockPending || isLockConfirming || isLockSuccess}
                >
                  {isLockPending || isLockConfirming ? '锁盘中...' : '🔒 锁盘市场'}
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 核心指标 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <InfoCard
            title="总交易量"
            value={`${Number(market.totalVolume || 0).toFixed(2)} USDC`}
            subtitle="累计下注金额"
          />
          <InfoCard
            title="手续费累计"
            value={`${Number(market.feeAccrued || 0).toFixed(2)} USDC`}
            subtitle="已收取手续费"
          />
          <InfoCard
            title="LP 流动性"
            value={`${Number(market.lpLiquidity || 0).toFixed(2)} USDC`}
            subtitle="流动性池规模"
          />
          <InfoCard
            title="胜出结果"
            value={market.winnerOutcome !== null && market.winnerOutcome !== undefined ? `#${market.winnerOutcome}` : '--'}
            subtitle={market.state === 'Resolved' || market.state === 'Finalized' ? '已确定' : '待结算'}
          />
        </div>

        {/* 详细信息 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* 市场信息 */}
          <Card className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              市场信息
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">市场 ID</dt>
                <dd className="text-sm font-mono text-gray-900 dark:text-white">{market.id.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">Match ID</dt>
                <dd className="text-sm font-mono text-gray-900 dark:text-white">{market.matchId.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">Template ID</dt>
                <dd className="text-sm font-mono text-gray-900 dark:text-white">{market.templateId.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">独立下注者</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">{market.uniqueBettors || 0} 人</dd>
              </div>
            </dl>
          </Card>

          {/* 时间轴 */}
          <Card className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              时间轴
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">当前状态</dt>
                <dd>
                  <Badge variant={
                    market.state === 'Open' ? 'primary' :
                    market.state === 'Locked' ? 'warning' :
                    market.state === 'Resolved' ? 'success' :
                    market.state === 'Finalized' ? 'success' :
                    'secondary'
                  }>
                    {status.label}
                  </Badge>
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500 dark:text-gray-400">创建时间</dt>
                <dd className="text-sm font-medium text-gray-900 dark:text-white">
                  {format(createdAt, 'PPP HH:mm', { locale: zhCN })}
                </dd>
              </div>
              {lockedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500 dark:text-gray-400">锁盘时间</dt>
                  <dd className="text-sm font-medium text-gray-900 dark:text-white">
                    {format(lockedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
              {resolvedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500 dark:text-gray-400">结算时间</dt>
                  <dd className="text-sm font-medium text-gray-900 dark:text-white">
                    {format(resolvedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
              {finalizedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500 dark:text-gray-400">完成时间</dt>
                  <dd className="text-sm font-medium text-gray-900 dark:text-white">
                    {format(finalizedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
            </dl>
          </Card>
        </div>

        {/* 技术信息 */}
        <Card className="p-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            技术信息
          </h2>
          <dl className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <dt className="text-sm text-gray-500 dark:text-gray-400 mb-1">市场合约地址</dt>
              <dd className="text-sm font-mono text-gray-900 dark:text-white break-all">
                {market.id}
              </dd>
            </div>
            <div>
              <dt className="text-sm text-gray-500 dark:text-gray-400 mb-1">模板类型</dt>
              <dd className="text-sm font-mono text-gray-900 dark:text-white">
                {market.template?.type || 'Unknown'}
              </dd>
            </div>
          </dl>
        </Card>

        {/* 交易状态显示 */}
        {(isLockPending || isLockConfirming || isLockSuccess || lockError) && (
          <div className="mt-6 space-y-4">
            {isLockPending && (
              <Card className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800">
                <p className="text-sm text-yellow-800 dark:text-yellow-200">
                  ⏳ 等待钱包确认锁盘交易...
                </p>
              </Card>
            )}
            {isLockConfirming && (
              <Card className="p-4 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
                <div className="flex items-center gap-3">
                  <LoadingSpinner size="sm" />
                  <div>
                    <p className="text-sm font-medium text-blue-800 dark:text-blue-200">
                      ⛓️ 锁盘交易确认中...
                    </p>
                    {lockHash && (
                      <a
                        href={`http://localhost:8545/tx/${lockHash}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-xs text-blue-600 dark:text-blue-400 hover:underline"
                      >
                        查看交易: {lockHash.slice(0, 10)}...
                      </a>
                    )}
                  </div>
                </div>
              </Card>
            )}
            {isLockSuccess && (
              <Card className="p-4 bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800">
                <p className="text-sm font-medium text-green-800 dark:text-green-200">
                  ✅ 市场锁盘成功！页面将在 3 秒后刷新...
                </p>
              </Card>
            )}
            {lockError && (
              <Card className="p-4 bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800">
                <p className="text-sm font-medium text-red-800 dark:text-red-200">
                  ❌ 锁盘失败
                </p>
                <p className="text-xs text-red-600 dark:text-red-400 mt-1">
                  {lockError.message}
                </p>
              </Card>
            )}
          </div>
        )}
      </div>

      {/* 锁盘确认对话框 */}
      {showLockConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <Card className="max-w-md w-full mx-4 p-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              确认锁盘市场
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
              确定要锁盘此市场吗？锁盘后将禁止新的下注，仅允许用户卖出现有头寸。
            </p>
            <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-6">
              <p className="text-sm text-yellow-800 dark:text-yellow-200">
                ⚠️ <strong>注意：</strong>此操作不可撤销！锁盘后市场无法重新开盘。
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Button
                variant="outline"
                onClick={() => setShowLockConfirm(false)}
                disabled={isLockPending || isLockConfirming}
                className="flex-1"
              >
                取消
              </Button>
              <Button
                variant="outline"
                onClick={handleLockMarket}
                disabled={isLockPending || isLockConfirming}
                className="flex-1"
              >
                {isLockPending || isLockConfirming ? '锁盘中...' : '确认锁盘'}
              </Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
