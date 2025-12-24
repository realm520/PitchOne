'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKET_QUERY, MARKET_ALL_ORDERS_QUERY, useLockMarket, useResolveMarket, useFinalizeMarket, useAccount } from '@pitchone/web3';
import { LoadingSpinner, ErrorState, Badge } from '@pitchone/ui';
import { format, formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { use, useState } from 'react';
import { AdminButton, AdminCard, InfoCard, Pagination, ConfirmDialog, TxStatus, EmptyState } from '@/components/ui';
import { STATUS_MAP, TEMPLATE_MAP, LEAGUE_MAP, getOutcomeOptions, getOutcomeName, parseMatchInfo, shortAddr, formatUSDC } from '@/lib/market-utils';

interface Order {
  id: string;
  user: { id: string };
  outcome: number;
  amount: string;
  price: string;
  timestamp: string;
  transactionHash: string;
}

export default function MarketDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const { isConnected } = useAccount();
  const [dialog, setDialog] = useState<'lock' | 'resolve' | 'finalize' | null>(null);
  const [selectedOutcome, setSelectedOutcome] = useState<number | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;

  const lock = useLockMarket(id as `0x${string}`);
  const resolve = useResolveMarket(id as `0x${string}`);
  const finalize = useFinalizeMarket(id as `0x${string}`);

  const { data: market, isLoading, error, refetch } = useQuery({
    queryKey: ['market', id],
    queryFn: async () => (await graphqlClient.request<any>(MARKET_QUERY, { id })).market,
  });

  const { data: orders = [], isLoading: ordersLoading } = useQuery({
    queryKey: ['market-orders', id],
    queryFn: async () => (await graphqlClient.request<any>(MARKET_ALL_ORDERS_QUERY, { marketId: id, first: 1000 })).orders || [],
    enabled: !!id,
  });

  const totalPages = Math.ceil(orders.length / pageSize);
  const paginatedOrders = orders.slice((currentPage - 1) * pageSize, currentPage * pageSize);

  const handleAction = async (action: 'lock' | 'resolve' | 'finalize') => {
    if (!isConnected) return alert('请先连接钱包');
    try {
      if (action === 'lock') await lock.lockMarket();
      else if (action === 'resolve' && selectedOutcome !== null) await resolve.resolveMarket(BigInt(selectedOutcome));
      else if (action === 'finalize') await finalize.finalizeMarket();
      setDialog(null);
      setSelectedOutcome(null);
      setTimeout(refetch, 3000);
    } catch (e) {
      console.error(`${action}失败:`, e);
    }
  };

  if (isLoading) return <div className="flex items-center justify-center min-h-screen"><LoadingSpinner size="lg" text="加载中..." /></div>;
  if (error || !market) return <div className="flex items-center justify-center min-h-screen"><ErrorState title="加载失败" message="市场不存在" onRetry={() => window.location.reload()} /></div>;

  const status = STATUS_MAP[market.state as keyof typeof STATUS_MAP] || { label: market.state, color: 'bg-gray-100 text-gray-800' };
  const matchInfo = parseMatchInfo(market.matchId || '');
  const templateType = market.templateId?.slice(0, 3)?.toUpperCase();
  const kickoffTime = market.kickoffTime ? new Date(Number(market.kickoffTime) * 1000) : null;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/markets" className="text-sm text-gray-500 hover:text-gray-700">← 返回列表</Link>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
        {/* 赛事信息 + 操作 */}
        <AdminCard className="p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-sm text-gray-500">{LEAGUE_MAP[matchInfo.league] || matchInfo.league}</span>
                <span className="text-sm text-gray-400">{matchInfo.season}</span>
                <Badge variant="default">{TEMPLATE_MAP[templateType] || '胜平负'}</Badge>
              </div>
              <h1 className="text-2xl font-bold text-gray-900 mb-2">
                {market.homeTeam || matchInfo.homeTeam}
                <span className="text-gray-400 mx-3">vs</span>
                {market.awayTeam || matchInfo.awayTeam}
              </h1>
              {kickoffTime && (
                <p className="text-sm text-gray-500">
                  开赛：{format(kickoffTime, 'yyyy-MM-dd HH:mm', { locale: zhCN })}
                  <span className="ml-2 text-gray-400">({formatDistanceToNow(kickoffTime, { addSuffix: true, locale: zhCN })})</span>
                </p>
              )}
              <p className="mt-2 text-xs text-gray-400 font-mono">ID: {market.id}</p>
            </div>
            <div className="flex flex-col items-end gap-3">
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${status.color}`}>{status.label}</span>
              <div className="flex gap-2">
                {market.state === 'Open' && (
                  <>
                    <AdminButton variant="warning" onClick={() => setDialog('lock')} disabled={!isConnected || lock.isPending}>临时锁盘</AdminButton>
                    <AdminButton variant="danger" onClick={() => setDialog('lock')} disabled={!isConnected || lock.isPending}>停盘</AdminButton>
                  </>
                )}
                {market.state === 'Locked' && <AdminButton onClick={() => setDialog('resolve')} disabled={!isConnected || resolve.isPending}>结算市场</AdminButton>}
                {market.state === 'Resolved' && <AdminButton variant="secondary" onClick={() => setDialog('finalize')} disabled={!isConnected || finalize.isPending}>终结市场</AdminButton>}
              </div>
            </div>
          </div>
        </AdminCard>

        {/* 指标 */}
        <div className="grid grid-cols-4 gap-4">
          <InfoCard title="总交易量" value={`${formatUSDC(market.totalVolume)} USDC`} subtitle="累计下注" />
          <InfoCard title="手续费" value={`${formatUSDC(market.feeAccrued)} USDC`} subtitle="已收取" />
          <InfoCard title="投注笔数" value={`${orders.length}`} subtitle="累计次数" />
          <InfoCard title="投注人数" value={`${market.uniqueBettors || 0}`} subtitle="独立用户" />
        </div>

        {/* 详情 */}
        <AdminCard className="p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">市场详情</h2>
          <div className="grid grid-cols-3 gap-6 text-sm">
            <div><span className="text-gray-500">胜出结果</span><p className="text-lg font-medium mt-1">{getOutcomeName(templateType, market.winnerOutcome)}</p></div>
            <div><span className="text-gray-500">盘口线</span><p className="text-lg font-medium mt-1">{market.line ? Number(market.line) / 10 : '--'}</p></div>
            <div><span className="text-gray-500">创建时间</span><p className="text-lg font-medium mt-1">{format(new Date(Number(market.createdAt) * 1000), 'yyyy-MM-dd HH:mm', { locale: zhCN })}</p></div>
          </div>
        </AdminCard>

        {/* 投注记录 */}
        <AdminCard className="overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900">投注记录</h2>
          </div>
          {ordersLoading ? (
            <div className="p-8 text-center"><LoadingSpinner size="md" text="加载中..." /></div>
          ) : paginatedOrders.length > 0 ? (
            <>
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    {['投注时间', '用户', '金额', '选项', '赔率', '交易Hash', '结果'].map(h => (
                      <th key={h} className="py-3 px-4 text-left text-xs font-medium text-gray-500 uppercase">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {paginatedOrders.map((order: Order, i: number) => {
                    const t = new Date(Number(order.timestamp) * 1000);
                    const win = market.winnerOutcome !== null && order.outcome === market.winnerOutcome;
                    const resolved = ['Resolved', 'Finalized'].includes(market.state);
                    return (
                      <tr key={order.id} className={`hover:bg-gray-50 ${i < paginatedOrders.length - 1 ? 'border-b border-gray-100' : ''}`}>
                        <td className="py-3 px-4">
                          <div className="text-sm">{format(t, 'MM-dd HH:mm:ss')}</div>
                          <div className="text-xs text-gray-500">{formatDistanceToNow(t, { addSuffix: true, locale: zhCN })}</div>
                        </td>
                        <td className="py-3 px-4 font-mono text-sm">{shortAddr(order.user.id)}</td>
                        <td className="py-3 px-4 font-semibold">{formatUSDC(order.amount)} USDC</td>
                        <td className="py-3 px-4"><Badge variant="default">{getOutcomeName(templateType, order.outcome)}</Badge></td>
                        <td className="py-3 px-4">{order.price ? (1 / Number(order.price)).toFixed(2) : '--'}</td>
                        <td className="py-3 px-4">
                          <a href={`https://etherscan.io/tx/${order.transactionHash}`} target="_blank" rel="noopener noreferrer" className="font-mono text-blue-600 hover:text-blue-800">
                            {order.transactionHash.slice(0, 8)}...
                          </a>
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            !resolved ? 'bg-gray-100 text-gray-600' : win ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                          }`}>
                            {!resolved ? '待定' : win ? '胜' : '负'}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              {totalPages > 1 && (
                <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
                  <span className="text-sm text-gray-600">第 {currentPage}/{totalPages} 页，共 {orders.length} 条</span>
                  <Pagination current={currentPage} total={totalPages} onChange={setCurrentPage} />
                </div>
              )}
            </>
          ) : (
            <EmptyState title="暂无记录" message="该市场还没有投注" />
          )}
        </AdminCard>

        {/* 交易状态 */}
        <TxStatus {...lock} actionName="锁盘" />
        <TxStatus {...resolve} actionName="结算" />
        <TxStatus {...finalize} actionName="终结" />
      </div>

      {/* 锁盘对话框 */}
      <ConfirmDialog
        open={dialog === 'lock'}
        title="确认锁盘"
        message="锁盘后将禁止新的下注。"
        warning="注意：此操作不可撤销！"
        confirmText="确认锁盘"
        confirmVariant="warning"
        loading={lock.isPending || lock.isConfirming}
        onConfirm={() => handleAction('lock')}
        onCancel={() => setDialog(null)}
      />

      {/* 结算对话框 */}
      {dialog === 'resolve' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">结算市场</h3>
            <p className="text-sm text-gray-600 mb-4">选择获胜结果：</p>
            <div className="space-y-2 mb-6">
              {getOutcomeOptions(templateType).map(opt => (
                <label key={opt.id} className={`flex items-start p-3 border-2 rounded-lg cursor-pointer ${
                  selectedOutcome === opt.id ? (opt.isPush ? 'border-orange-500 bg-orange-50' : 'border-blue-500 bg-blue-50') : 'border-gray-200 hover:bg-gray-50'
                }`}>
                  <input type="radio" checked={selectedOutcome === opt.id} onChange={() => setSelectedOutcome(opt.id)} className="mt-0.5 mr-3" />
                  <div>
                    <span className={`text-sm font-medium ${opt.isPush ? 'text-orange-800' : ''}`}>{opt.label}</span>
                    {opt.description && <p className="text-xs text-gray-500 mt-1">{opt.description}</p>}
                  </div>
                </label>
              ))}
            </div>
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-red-800"><strong>警告：</strong>请确保选择正确的结果！</p>
            </div>
            <div className="flex gap-3">
              <AdminButton variant="outline" onClick={() => { setDialog(null); setSelectedOutcome(null); }} className="flex-1">取消</AdminButton>
              <AdminButton onClick={() => handleAction('resolve')} disabled={selectedOutcome === null || resolve.isPending} className="flex-1">
                {resolve.isPending ? '结算中...' : '确认结算'}
              </AdminButton>
            </div>
          </div>
        </div>
      )}

      {/* 终结对话框 */}
      <ConfirmDialog
        open={dialog === 'finalize'}
        title="终结市场"
        message="终结后用户可以领取奖金。"
        warning="提示：通常在争议期结束后执行。"
        warningType="info"
        confirmText="确认终结"
        confirmVariant="secondary"
        loading={finalize.isPending || finalize.isConfirming}
        onConfirm={() => handleAction('finalize')}
        onCancel={() => setDialog(null)}
      />
    </div>
  );
}
