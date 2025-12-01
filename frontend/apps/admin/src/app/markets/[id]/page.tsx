'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKET_QUERY, useLockMarket, useResolveMarket, useFinalizeMarket, useAccount } from '@pitchone/web3';
import { LoadingSpinner, ErrorState, Badge } from '@pitchone/ui';
import { format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { use, useState } from 'react';

// Admin 专用简洁按钮组件
function AdminButton({
  children,
  variant = 'primary',
  disabled,
  onClick,
  className = '',
}: {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'outline' | 'danger';
  disabled?: boolean;
  onClick?: () => void;
  className?: string;
}) {
  const baseStyles = 'inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed';
  const variants = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700',
    secondary: 'bg-amber-500 text-white hover:bg-amber-600',
    outline: 'border border-gray-300 text-gray-700 bg-white hover:bg-gray-50',
    danger: 'bg-red-600 text-white hover:bg-red-700',
  };
  return (
    <button
      className={`${baseStyles} ${variants[variant]} ${className}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
}

// Admin 专用简洁卡片组件
function AdminCard({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`bg-white border border-gray-200 rounded-lg shadow-sm ${className}`}>
      {children}
    </div>
  );
}

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
    <AdminCard className="p-6">
      <h3 className="text-sm font-medium text-gray-500 mb-2">{title}</h3>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
      {subtitle && (
        <p className="text-xs text-gray-500 mt-1">{subtitle}</p>
      )}
    </AdminCard>
  );
}

// 根据模板类型获取结果选项
function getOutcomeOptions(templateType?: string): { id: number; label: string; isPush?: boolean; description?: string }[] {
  switch (templateType?.toUpperCase()) {
    case 'WDL':
      return [
        { id: 0, label: '主队胜 (Home Win)' },
        { id: 1, label: '平局 (Draw)' },
        { id: 2, label: '客队胜 (Away Win)' },
      ];
    case 'OU':
      return [
        { id: 0, label: '大 (Over)' },
        { id: 1, label: '小 (Under)' },
        { id: 2, label: '走盘 (Push)', isPush: true, description: '整球盘恰好相等，所有用户 1:1 退回本金' },
      ];
    case 'AH':
      return [
        { id: 0, label: '主队赢盘 (Home Cover)' },
        { id: 1, label: '客队赢盘 (Away Cover)' },
        { id: 2, label: '走盘 (Push)', isPush: true, description: '整球盘恰好抵消让球，所有用户 1:1 退回本金' },
      ];
    case 'ODDEVEN':
      return [
        { id: 0, label: '奇数 (Odd)' },
        { id: 1, label: '偶数 (Even)' },
      ];
    default:
      // 默认返回通用选项
      return [
        { id: 0, label: '结果 0' },
        { id: 1, label: '结果 1' },
        { id: 2, label: '结果 2' },
      ];
  }
}

export default function MarketDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { isConnected } = useAccount();
  const [showLockConfirm, setShowLockConfirm] = useState(false);
  const [showResolveDialog, setShowResolveDialog] = useState(false);
  const [showFinalizeConfirm, setShowFinalizeConfirm] = useState(false);
  const [selectedOutcome, setSelectedOutcome] = useState<number | null>(null);

  // 锁盘功能
  const {
    lockMarket,
    isPending: isLockPending,
    isConfirming: isLockConfirming,
    isSuccess: isLockSuccess,
    error: lockError,
    hash: lockHash
  } = useLockMarket(id as `0x${string}`);

  // 结算功能
  const {
    resolveMarket,
    isPending: isResolvePending,
    isConfirming: isResolveConfirming,
    isSuccess: isResolveSuccess,
    error: resolveError,
    hash: resolveHash
  } = useResolveMarket(id as `0x${string}`);

  // 终结功能
  const {
    finalizeMarket,
    isPending: isFinalizePending,
    isConfirming: isFinalizeConfirming,
    isSuccess: isFinalizeSuccess,
    error: finalizeError,
    hash: finalizeHash
  } = useFinalizeMarket(id as `0x${string}`);

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

  // 处理结算
  const handleResolveMarket = async () => {
    if (!isConnected) {
      alert('请先连接钱包');
      return;
    }

    if (selectedOutcome === null) {
      alert('请选择获胜结果');
      return;
    }

    try {
      await resolveMarket(BigInt(selectedOutcome));
      setShowResolveDialog(false);
      setSelectedOutcome(null);
      // 3秒后刷新市场数据
      setTimeout(() => {
        refetch();
      }, 3000);
    } catch (err) {
      console.error('结算失败:', err);
    }
  };

  // 处理终结
  const handleFinalizeMarket = async () => {
    if (!isConnected) {
      alert('请先连接钱包');
      return;
    }

    try {
      await finalizeMarket();
      setShowFinalizeConfirm(false);
      // 3秒后刷新市场数据
      setTimeout(() => {
        refetch();
      }, 3000);
    } catch (err) {
      console.error('终结失败:', err);
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
                <AdminButton variant="outline">
                  返回列表
                </AdminButton>
              </Link>
              {market.state === 'Open' && (
                <AdminButton
                  variant="secondary"
                  onClick={() => setShowLockConfirm(true)}
                  disabled={!isConnected || isLockPending || isLockConfirming || isLockSuccess}
                >
                  {isLockPending || isLockConfirming ? '锁盘中...' : '锁盘市场'}
                </AdminButton>
              )}
              {market.state === 'Locked' && (
                <AdminButton
                  variant="primary"
                  onClick={() => setShowResolveDialog(true)}
                  disabled={!isConnected || isResolvePending || isResolveConfirming || isResolveSuccess}
                >
                  {isResolvePending || isResolveConfirming ? '结算中...' : '结算市场'}
                </AdminButton>
              )}
              {market.state === 'Resolved' && (
                <AdminButton
                  variant="secondary"
                  onClick={() => setShowFinalizeConfirm(true)}
                  disabled={!isConnected || isFinalizePending || isFinalizeConfirming || isFinalizeSuccess}
                >
                  {isFinalizePending || isFinalizeConfirming ? '终结中...' : '终结市场'}
                </AdminButton>
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
          <AdminCard className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              市场信息
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">市场 ID</dt>
                <dd className="text-sm font-mono text-gray-900">{market.id.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Match ID</dt>
                <dd className="text-sm font-mono text-gray-900">{market.matchId.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Template ID</dt>
                <dd className="text-sm font-mono text-gray-900">{market.templateId.slice(0, 16)}...</dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">独立下注者</dt>
                <dd className="text-sm font-medium text-gray-900">{market.uniqueBettors || 0} 人</dd>
              </div>
            </dl>
          </AdminCard>

          {/* 时间轴 */}
          <AdminCard className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              时间轴
            </h2>
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">当前状态</dt>
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
                <dt className="text-sm text-gray-500">创建时间</dt>
                <dd className="text-sm font-medium text-gray-900">
                  {format(createdAt, 'PPP HH:mm', { locale: zhCN })}
                </dd>
              </div>
              {lockedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500">锁盘时间</dt>
                  <dd className="text-sm font-medium text-gray-900">
                    {format(lockedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
              {resolvedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500">结算时间</dt>
                  <dd className="text-sm font-medium text-gray-900">
                    {format(resolvedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
              {finalizedAt && (
                <div className="flex justify-between">
                  <dt className="text-sm text-gray-500">完成时间</dt>
                  <dd className="text-sm font-medium text-gray-900">
                    {format(finalizedAt, 'PPP HH:mm', { locale: zhCN })}
                  </dd>
                </div>
              )}
            </dl>
          </AdminCard>
        </div>

        {/* 技术信息 */}
        <AdminCard className="p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">
            技术信息
          </h2>
          <dl className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <dt className="text-sm text-gray-500 mb-1">市场合约地址</dt>
              <dd className="text-sm font-mono text-gray-900 break-all">
                {market.id}
              </dd>
            </div>
            <div>
              <dt className="text-sm text-gray-500 mb-1">模板类型</dt>
              <dd className="text-sm font-mono text-gray-900">
                {market.template?.type || 'Unknown'}
              </dd>
            </div>
          </dl>
        </AdminCard>

        {/* 交易状态显示 - 锁盘 */}
        {(isLockPending || isLockConfirming || isLockSuccess || lockError) && (
          <div className="mt-6 space-y-4">
            {isLockPending && (
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <p className="text-sm text-yellow-800">
                  等待钱包确认锁盘交易...
                </p>
              </div>
            )}
            {isLockConfirming && (
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <LoadingSpinner size="sm" />
                  <div>
                    <p className="text-sm font-medium text-blue-800">
                      锁盘交易确认中...
                    </p>
                    {lockHash && (
                      <p className="text-xs text-blue-600">
                        交易: {lockHash.slice(0, 10)}...
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}
            {isLockSuccess && (
              <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                <p className="text-sm font-medium text-green-800">
                  市场锁盘成功！页面将在 3 秒后刷新...
                </p>
              </div>
            )}
            {lockError && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm font-medium text-red-800">
                  锁盘失败
                </p>
                <p className="text-xs text-red-600 mt-1">
                  {lockError.message}
                </p>
              </div>
            )}
          </div>
        )}

        {/* 交易状态显示 - 结算 */}
        {(isResolvePending || isResolveConfirming || isResolveSuccess || resolveError) && (
          <div className="mt-6 space-y-4">
            {isResolvePending && (
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <p className="text-sm text-yellow-800">
                  等待钱包确认结算交易...
                </p>
              </div>
            )}
            {isResolveConfirming && (
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <LoadingSpinner size="sm" />
                  <div>
                    <p className="text-sm font-medium text-blue-800">
                      结算交易确认中...
                    </p>
                    {resolveHash && (
                      <p className="text-xs text-blue-600">
                        交易: {resolveHash.slice(0, 10)}...
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}
            {isResolveSuccess && (
              <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                <p className="text-sm font-medium text-green-800">
                  市场结算成功！页面将在 3 秒后刷新...
                </p>
              </div>
            )}
            {resolveError && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm font-medium text-red-800">
                  结算失败
                </p>
                <p className="text-xs text-red-600 mt-1">
                  {resolveError.message}
                </p>
              </div>
            )}
          </div>
        )}

        {/* 交易状态显示 - 终结 */}
        {(isFinalizePending || isFinalizeConfirming || isFinalizeSuccess || finalizeError) && (
          <div className="mt-6 space-y-4">
            {isFinalizePending && (
              <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                <p className="text-sm text-yellow-800">
                  等待钱包确认终结交易...
                </p>
              </div>
            )}
            {isFinalizeConfirming && (
              <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <div className="flex items-center gap-3">
                  <LoadingSpinner size="sm" />
                  <div>
                    <p className="text-sm font-medium text-blue-800">
                      终结交易确认中...
                    </p>
                    {finalizeHash && (
                      <p className="text-xs text-blue-600">
                        交易: {finalizeHash.slice(0, 10)}...
                      </p>
                    )}
                  </div>
                </div>
              </div>
            )}
            {isFinalizeSuccess && (
              <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                <p className="text-sm font-medium text-green-800">
                  市场终结成功！页面将在 3 秒后刷新...
                </p>
              </div>
            )}
            {finalizeError && (
              <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm font-medium text-red-800">
                  终结失败
                </p>
                <p className="text-xs text-red-600 mt-1">
                  {finalizeError.message}
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* 锁盘确认对话框 */}
      {showLockConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              确认锁盘市场
            </h3>
            <p className="text-sm text-gray-600 mb-6">
              确定要锁盘此市场吗？锁盘后将禁止新的下注，仅允许用户卖出现有头寸。
            </p>
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-yellow-800">
                <strong>注意：</strong>此操作不可撤销！锁盘后市场无法重新开盘。
              </p>
            </div>
            <div className="flex items-center gap-3">
              <AdminButton
                variant="outline"
                onClick={() => setShowLockConfirm(false)}
                disabled={isLockPending || isLockConfirming}
                className="flex-1"
              >
                取消
              </AdminButton>
              <AdminButton
                variant="secondary"
                onClick={handleLockMarket}
                disabled={isLockPending || isLockConfirming}
                className="flex-1"
              >
                {isLockPending || isLockConfirming ? '锁盘中...' : '确认锁盘'}
              </AdminButton>
            </div>
          </div>
        </div>
      )}

      {/* 结算对话框 */}
      {showResolveDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              结算市场
            </h3>
            <p className="text-sm text-gray-600 mb-4">
              请选择此市场的获胜结果：
            </p>

            {/* 结果选项 */}
            <div className="space-y-2 mb-6">
              {getOutcomeOptions(market?.template?.type).map((option) => (
                <label
                  key={option.id}
                  className={`flex items-start p-3 border-2 rounded-lg cursor-pointer transition-colors ${
                    option.isPush
                      ? selectedOutcome === option.id
                        ? 'border-orange-500 bg-orange-50'
                        : 'border-orange-300 bg-orange-50/50 hover:bg-orange-50'
                      : selectedOutcome === option.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-gray-200 hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    name="outcome"
                    value={option.id}
                    checked={selectedOutcome === option.id}
                    onChange={() => setSelectedOutcome(option.id)}
                    className="mt-0.5 mr-3"
                  />
                  <div className="flex-1">
                    <span className={`text-sm font-medium ${option.isPush ? 'text-orange-800' : 'text-gray-900'}`}>
                      {option.label}
                    </span>
                    {option.description && (
                      <p className={`text-xs mt-1 ${option.isPush ? 'text-orange-600' : 'text-gray-500'}`}>
                        {option.description}
                      </p>
                    )}
                  </div>
                </label>
              ))}
            </div>

            {selectedOutcome !== null && (
              <div className={`border rounded-lg p-4 mb-6 ${
                getOutcomeOptions(market?.template?.type)[selectedOutcome]?.isPush
                  ? 'bg-orange-50 border-orange-200'
                  : 'bg-red-50 border-red-200'
              }`}>
                <p className={`text-sm ${
                  getOutcomeOptions(market?.template?.type)[selectedOutcome]?.isPush
                    ? 'text-orange-800'
                    : 'text-red-800'
                }`}>
                  <strong>
                    {getOutcomeOptions(market?.template?.type)[selectedOutcome]?.isPush ? '提示：' : '警告：'}
                  </strong>
                  {getOutcomeOptions(market?.template?.type)[selectedOutcome]?.isPush
                    ? '选择 Push 后，所有用户将 1:1 退回本金，市场不产生赢家。'
                    : '结算后将根据选择的结果分配奖金。请确保选择正确的结果！'}
                </p>
              </div>
            )}
            {selectedOutcome === null && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <p className="text-sm text-red-800">
                  <strong>警告：</strong>结算后将根据选择的结果分配奖金。请确保选择正确的结果！
                </p>
              </div>
            )}

            <div className="flex items-center gap-3">
              <AdminButton
                variant="outline"
                onClick={() => {
                  setShowResolveDialog(false);
                  setSelectedOutcome(null);
                }}
                disabled={isResolvePending || isResolveConfirming}
                className="flex-1"
              >
                取消
              </AdminButton>
              <AdminButton
                variant="primary"
                onClick={handleResolveMarket}
                disabled={selectedOutcome === null || isResolvePending || isResolveConfirming}
                className="flex-1"
              >
                {isResolvePending || isResolveConfirming ? '结算中...' : '确认结算'}
              </AdminButton>
            </div>
          </div>
        </div>
      )}

      {/* 终结确认对话框 */}
      {showFinalizeConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              终结市场
            </h3>
            <p className="text-sm text-gray-600 mb-6">
              确定要终结此市场吗？终结后用户可以领取奖金。
            </p>
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-blue-800">
                <strong>提示：</strong>通常在争议期结束后执行此操作。终结后市场状态将变为 Finalized。
              </p>
            </div>
            <div className="flex items-center gap-3">
              <AdminButton
                variant="outline"
                onClick={() => setShowFinalizeConfirm(false)}
                disabled={isFinalizePending || isFinalizeConfirming}
                className="flex-1"
              >
                取消
              </AdminButton>
              <AdminButton
                variant="secondary"
                onClick={handleFinalizeMarket}
                disabled={isFinalizePending || isFinalizeConfirming}
                className="flex-1"
              >
                {isFinalizePending || isFinalizeConfirming ? '终结中...' : '确认终结'}
              </AdminButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
