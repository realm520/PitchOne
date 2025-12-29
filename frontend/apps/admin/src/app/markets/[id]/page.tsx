'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, MARKET_QUERY, MARKET_ALL_ORDERS_QUERY, useLockMarket, useResolveMarket, useFinalizeMarket, usePauseMarket, useUnpauseMarket, useAccount, useOutcomeCount } from '@pitchone/web3';
import { LoadingSpinner, ErrorState, Badge } from '@pitchone/ui';
import { format, formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { use, useState, useEffect } from 'react';
import { AdminButton, AdminCard, InfoCard, Pagination, ConfirmDialog, TxStatus, EmptyState } from '@/components/ui';
import { STATUS_MAP, TEMPLATE_MAP, LEAGUE_MAP, getOutcomeOptions, getOutcomeName, parseMatchInfo, shortAddr, formatUSDC, parseTemplateType, isCustomMatch, getCustomMatchDisplayName } from '@/lib/market-utils';
import { toast } from 'sonner';

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
  const [dialog, setDialog] = useState<'pause' | 'unpause' | 'lock' | 'resolve' | 'finalize' | null>(null);
  const [homeScore, setHomeScore] = useState<string>('');
  const [awayScore, setAwayScore] = useState<string>('');
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 10;

  const lock = useLockMarket(id as `0x${string}`);
  const resolve = useResolveMarket(id as `0x${string}`);
  const finalize = useFinalizeMarket(id as `0x${string}`);
  const pause = usePauseMarket(id as `0x${string}`);
  const unpause = useUnpauseMarket(id as `0x${string}`);

  // 读取合约的 outcomeCount
  const { data: outcomeCount } = useOutcomeCount(id as `0x${string}`);

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

  // Toast ID 常量，用于替换旧的 toast
  const TOAST_IDS = {
    pause: 'market-pause-toast',
    unpause: 'market-unpause-toast',
    lock: 'market-lock-toast',
    resolve: 'market-resolve-toast',
    finalize: 'market-finalize-toast',
  };

  const handleAction = async (action: 'pause' | 'unpause' | 'lock' | 'resolve' | 'finalize') => {
    if (!isConnected) {
      toast.error('请先连接钱包');
      return;
    }
    const actionNames = { pause: '临时锁盘', unpause: '恢复', lock: '停盘', resolve: '结算', finalize: '终结' };
    const toastId = TOAST_IDS[action];

    console.log(`[${action.toUpperCase()}] 开始执行操作...`, { marketId: id, action });

    // 显示 loading toast
    toast.loading(`正在${actionNames[action]}...`, {
      id: toastId,
      description: '请在钱包中确认交易',
    });

    try {
      let result;
      if (action === 'pause') {
        console.log('[PAUSE] 调用 pause.pauseMarket()...');
        result = await pause.pauseMarket();
        console.log('[PAUSE] 调用完成，返回结果:', result);
      } else if (action === 'unpause') {
        console.log('[UNPAUSE] 调用 unpause.unpauseMarket()...');
        result = await unpause.unpauseMarket();
        console.log('[UNPAUSE] 调用完成，返回结果:', result);
      } else if (action === 'lock') {
        console.log('[LOCK] 调用 lock.lockMarket()...');
        result = await lock.lockMarket();
        console.log('[LOCK] 调用完成，返回结果:', result);
      } else if (action === 'resolve' && homeScore !== '' && awayScore !== '') {
        const home = BigInt(parseInt(homeScore, 10));
        const away = BigInt(parseInt(awayScore, 10));
        console.log('[RESOLVE] 调用 resolve.resolveMarket()，比分:', home, '-', away);
        result = await resolve.resolveMarket(home, away);
        console.log('[RESOLVE] 调用完成，返回结果:', result);
      } else if (action === 'finalize') {
        console.log('[FINALIZE] 调用 finalize.finalizeMarket()...');
        // scaleBps = 0 表示正常结算模式（超限时会 revert）
        // scaleBps = 10000 表示 100% 赔付（使用储备金兜底）
        result = await finalize.finalizeMarket(0n);
        console.log('[FINALIZE] 调用完成，返回结果:', result);
      }
      console.log(`[${action.toUpperCase()}] 操作成功，关闭对话框`);
      setDialog(null);
      setHomeScore('');
      setAwayScore('');
      setTimeout(refetch, 3000);
      // 成功的 toast 会在 useEffect 监听 hook.isSuccess 时显示
    } catch (e) {
      console.error(`[${action.toUpperCase()}] 操作失败:`, e);
      console.error(`[${action.toUpperCase()}] 错误消息:`, e instanceof Error ? e.message : String(e));
      // 错误 toast 会在 useEffect 监听 hook.error 时显示
      // 这里不需要显示，因为 hook 的 revertError 会触发 useEffect
    }
  };

  // 监听各操作 hook 返回的错误
  useEffect(() => {
    if (pause.error) {
      console.error('[PAUSE] Hook 检测到错误:', pause.error);
      const errorMessage = pause.error.message || '未知错误';
      toast.error('临时锁盘失败', {
        id: TOAST_IDS.pause,
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [pause.error]);

  useEffect(() => {
    if (unpause.error) {
      console.error('[UNPAUSE] Hook 检测到错误:', unpause.error);
      const errorMessage = unpause.error.message || '未知错误';
      toast.error('恢复失败', {
        id: TOAST_IDS.unpause,
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [unpause.error]);

  useEffect(() => {
    if (lock.error) {
      console.error('[LOCK] Hook 检测到错误:', lock.error);
      console.log('[LOCK] 错误消息:', lock.error.message);
      const errorMessage = lock.error.message || '未知错误';
      toast.error('停盘失败', {
        id: TOAST_IDS.lock,
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [lock.error]);

  useEffect(() => {
    if (resolve.error) {
      console.error('[RESOLVE] Hook 检测到错误:', resolve.error);
      const errorMessage = resolve.error.message || '未知错误';
      toast.error('结算失败', {
        id: TOAST_IDS.resolve,
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [resolve.error]);

  useEffect(() => {
    if (finalize.error) {
      console.error('[FINALIZE] Hook 检测到错误:', finalize.error);
      const errorMessage = finalize.error.message || '未知错误';
      toast.error('终结失败', {
        id: TOAST_IDS.finalize,
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [finalize.error]);

  // 监听交易确认中状态，更新 toast 提示
  useEffect(() => {
    if (pause.isConfirming && pause.hash) {
      toast.loading('交易确认中...', {
        id: TOAST_IDS.pause,
        description: `交易哈希: ${pause.hash.slice(0, 10)}...${pause.hash.slice(-8)}`,
      });
    }
  }, [pause.isConfirming, pause.hash]);

  useEffect(() => {
    if (unpause.isConfirming && unpause.hash) {
      toast.loading('交易确认中...', {
        id: TOAST_IDS.unpause,
        description: `交易哈希: ${unpause.hash.slice(0, 10)}...${unpause.hash.slice(-8)}`,
      });
    }
  }, [unpause.isConfirming, unpause.hash]);

  useEffect(() => {
    if (lock.isConfirming && lock.hash) {
      toast.loading('交易确认中...', {
        id: TOAST_IDS.lock,
        description: `交易哈希: ${lock.hash.slice(0, 10)}...${lock.hash.slice(-8)}`,
      });
    }
  }, [lock.isConfirming, lock.hash]);

  useEffect(() => {
    if (resolve.isConfirming && resolve.hash) {
      toast.loading('交易确认中...', {
        id: TOAST_IDS.resolve,
        description: `交易哈希: ${resolve.hash.slice(0, 10)}...${resolve.hash.slice(-8)}`,
      });
    }
  }, [resolve.isConfirming, resolve.hash]);

  useEffect(() => {
    if (finalize.isConfirming && finalize.hash) {
      toast.loading('交易确认中...', {
        id: TOAST_IDS.finalize,
        description: `交易哈希: ${finalize.hash.slice(0, 10)}...${finalize.hash.slice(-8)}`,
      });
    }
  }, [finalize.isConfirming, finalize.hash]);

  // 监听锁盘 hook 状态变化
  useEffect(() => {
    console.log('[LOCK] Hook 状态变化:', {
      isPending: lock.isPending,
      isConfirming: lock.isConfirming,
      isSuccess: lock.isSuccess,
      isReverted: lock.isReverted,
      hash: lock.hash,
      receipt: lock.receipt,
      error: lock.error?.message,
    });
  }, [lock.isPending, lock.isConfirming, lock.isSuccess, lock.hash, lock.error, lock.isReverted, lock.receipt]);

  // 监听交易 revert
  useEffect(() => {
    if (lock.isReverted && lock.hash) {
      console.error('[LOCK] 交易被 revert!', {
        hash: lock.hash,
        receipt: lock.receipt,
      });
      // 如果 hook 已经设置了 revertError，它会通过 lock.error 传递，这里不需要重复 toast
      // toast 会在 lock.error 变化时触发
    }
  }, [lock.isReverted, lock.hash, lock.receipt]);

  // 监听成功状态（使用相同 ID 替换之前的错误 toast）
  useEffect(() => {
    if (pause.isSuccess && pause.hash) {
      console.log('[PAUSE] 交易成功!', { hash: pause.hash });
      toast.success('临时锁盘成功！', {
        id: TOAST_IDS.pause,
        description: `交易哈希: ${pause.hash.slice(0, 10)}...${pause.hash.slice(-8)}`,
      });
    }
  }, [pause.isSuccess, pause.hash]);

  useEffect(() => {
    if (unpause.isSuccess && unpause.hash) {
      console.log('[UNPAUSE] 交易成功!', { hash: unpause.hash });
      toast.success('恢复成功！', {
        id: TOAST_IDS.unpause,
        description: `交易哈希: ${unpause.hash.slice(0, 10)}...${unpause.hash.slice(-8)}`,
      });
    }
  }, [unpause.isSuccess, unpause.hash]);

  useEffect(() => {
    if (lock.isSuccess && lock.hash) {
      console.log('[LOCK] 交易成功!', {
        hash: lock.hash,
        isSuccess: lock.isSuccess,
        receipt: lock.receipt,
      });
      toast.success('停盘成功！', {
        id: TOAST_IDS.lock,
        description: `交易哈希: ${lock.hash.slice(0, 10)}...${lock.hash.slice(-8)}`,
      });
    }
  }, [lock.isSuccess, lock.hash, lock.receipt]);

  useEffect(() => {
    if (resolve.isSuccess && resolve.hash) {
      console.log('[RESOLVE] 交易成功!', { hash: resolve.hash });
      toast.success('结算成功！', {
        id: TOAST_IDS.resolve,
        description: `交易哈希: ${resolve.hash.slice(0, 10)}...${resolve.hash.slice(-8)}`,
      });
    }
  }, [resolve.isSuccess, resolve.hash]);

  useEffect(() => {
    if (finalize.isSuccess && finalize.hash) {
      console.log('[FINALIZE] 交易成功!', { hash: finalize.hash });
      toast.success('终结成功！', {
        id: TOAST_IDS.finalize,
        description: `交易哈希: ${finalize.hash.slice(0, 10)}...${finalize.hash.slice(-8)}`,
      });
    }
  }, [finalize.isSuccess, finalize.hash]);

  if (isLoading) return <div className="flex items-center justify-center min-h-screen"><LoadingSpinner size="lg" text="加载中..." /></div>;
  if (error || !market) return <div className="flex items-center justify-center min-h-screen"><ErrorState title="加载失败" message="市场不存在" onRetry={() => window.location.reload()} /></div>;

  const status = STATUS_MAP[market.state as keyof typeof STATUS_MAP] || { label: market.state, color: 'bg-gray-100 text-gray-800' };
  const matchInfo = parseMatchInfo(market.matchId || '');
  const templateType = parseTemplateType(market.templateId);
  const kickoffTime = market.kickoffTime ? new Date(Number(market.kickoffTime) * 1000) : null;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-4">
        <Link href="/markets" className="text-sm text-gray-500 hover:text-gray-700">← 返回列表</Link>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
        {/* 赛事信息 + 操作 */}
        <AdminCard className="p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <span className="text-sm text-gray-500">{getCustomMatchDisplayName(market.matchId || '')}</span>
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
              <div className="flex items-center gap-2">
                <span className={`px-3 py-1 rounded-full text-sm font-medium ${status.color}`}>{status.label}</span>
                {market.paused && <span className="px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">已暂停</span>}
              </div>
              <div className="flex gap-2">
                {market.state === 'Open' && !market.paused && (
                  <>
                    <AdminButton variant="warning" onClick={() => setDialog('pause')} disabled={!isConnected || pause.isPending}>临时锁盘</AdminButton>
                    <AdminButton variant="danger" onClick={() => setDialog('lock')} disabled={!isConnected || lock.isPending}>停盘</AdminButton>
                  </>
                )}
                {market.state === 'Open' && market.paused && (
                  <AdminButton variant="secondary" onClick={() => setDialog('unpause')} disabled={!isConnected || unpause.isPending}>恢复下注</AdminButton>
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
          <div className="grid grid-cols-4 gap-6 text-sm">
            <div><span className="text-gray-500">玩法类型</span><p className="text-lg font-medium mt-1">{TEMPLATE_MAP[templateType] || templateType}</p></div>
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
                        <td className="py-3 px-4">
                          {(() => {
                            const options = getOutcomeOptions(templateType, market.homeTeam || matchInfo.homeTeam, market.awayTeam || matchInfo.awayTeam);
                            const opt = options.find(o => o.id === order.outcome);
                            return (
                              <div>
                                <Badge variant="default">{opt?.label || `选项 ${order.outcome}`}</Badge>
                              </div>
                            );
                          })()}
                        </td>
                        <td className="py-3 px-4">{order.price ? (1 / Number(order.price)).toFixed(2) : '--'}</td>
                        <td className="py-3 px-4">
                          <a href={`https://etherscan.io/tx/${order.transactionHash}`} target="_blank" rel="noopener noreferrer" className="font-mono text-blue-600 hover:text-blue-800">
                            {order.transactionHash.slice(0, 8)}...
                          </a>
                        </td>
                        <td className="py-3 px-4">
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${!resolved ? 'bg-gray-100 text-gray-600' : win ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
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
        <TxStatus {...pause} actionName="临时锁盘" />
        <TxStatus {...unpause} actionName="恢复" />
        <TxStatus {...lock} actionName="停盘" />
        <TxStatus {...resolve} actionName="结算" />
        <TxStatus {...finalize} actionName="终结" />
      </div>

      {/* 临时锁盘对话框 */}
      <ConfirmDialog
        open={dialog === 'pause'}
        title="临时锁盘"
        message="暂停市场后将暂时禁止新的下注。"
        warning={'提示：此操作可以通过「恢复下注」撤销。'}
        warningType="info"
        confirmText="确认暂停"
        confirmVariant="warning"
        loading={pause.isPending || pause.isConfirming}
        onConfirm={() => handleAction('pause')}
        onCancel={() => setDialog(null)}
      />

      {/* 恢复下注对话框 */}
      <ConfirmDialog
        open={dialog === 'unpause'}
        title="恢复下注"
        message="恢复后用户可以继续下注。"
        confirmText="确认恢复"
        confirmVariant="secondary"
        loading={unpause.isPending || unpause.isConfirming}
        onConfirm={() => handleAction('unpause')}
        onCancel={() => setDialog(null)}
      />

      {/* 停盘对话框 */}
      <ConfirmDialog
        open={dialog === 'lock'}
        title="确认停盘"
        message="停盘后将永久禁止新的下注，等待结算。"
        warning="注意：此操作不可撤销！"
        confirmText="确认停盘"
        confirmVariant="danger"
        loading={lock.isPending || lock.isConfirming}
        onConfirm={() => handleAction('lock')}
        onCancel={() => setDialog(null)}
      />

      {/* 结算对话框 */}
      {dialog === 'resolve' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="max-w-md w-full mx-4 p-6 bg-white rounded-lg shadow-xl">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">结算市场</h3>
            <p className="text-sm text-gray-500 mb-4">
              {market.homeTeam || matchInfo.homeTeam} vs {market.awayTeam || matchInfo.awayTeam}
            </p>
            <p className="text-sm text-gray-600 mb-3">输入比赛比分：</p>
            <div className="flex items-center gap-4 mb-6">
              <div className="flex-1">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {market.homeTeam || matchInfo.homeTeam}
                </label>
                <input
                  type="number"
                  min="0"
                  value={homeScore}
                  onChange={(e) => setHomeScore(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-center text-2xl font-bold"
                  placeholder="0"
                />
              </div>
              <span className="text-2xl font-bold text-gray-400 pt-6">:</span>
              <div className="flex-1">
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {market.awayTeam || matchInfo.awayTeam}
                </label>
                <input
                  type="number"
                  min="0"
                  value={awayScore}
                  onChange={(e) => setAwayScore(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-center text-2xl font-bold"
                  placeholder="0"
                />
              </div>
            </div>
            {homeScore !== '' && awayScore !== '' && (
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
                <p className="text-sm text-blue-800">
                  <strong>预计结果：</strong>
                  {(() => {
                    const h = parseInt(homeScore, 10);
                    const a = parseInt(awayScore, 10);
                    if (templateType === 'WDL') {
                      if (h > a) return `${market.homeTeam || matchInfo.homeTeam} 胜`;
                      if (h < a) return `${market.awayTeam || matchInfo.awayTeam} 胜`;
                      return '平局';
                    }
                    if (templateType === 'AH') {
                      const line = market.line ? Number(market.line) / 10 : 0;
                      const adjustedHome = h + line;
                      if (adjustedHome > a) return `${market.homeTeam || matchInfo.homeTeam} 赢盘`;
                      if (adjustedHome < a) return `${market.awayTeam || matchInfo.awayTeam} 赢盘`;
                      return '走盘 (Push)';
                    }
                    if (templateType === 'OU') {
                      const line = market.line ? Number(market.line) / 10 : 2.5;
                      const total = h + a;
                      if (total > line) return '大 (Over)';
                      if (total < line) return '小 (Under)';
                      return '走盘 (Push)';
                    }
                    if (templateType === 'ODDEVEN') {
                      return (h + a) % 2 === 1 ? '奇数' : '偶数';
                    }
                    return `比分 ${h}:${a}`;
                  })()}
                </p>
              </div>
            )}
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-red-800"><strong>警告：</strong>请确保输入正确的比分，结算后无法撤销！</p>
            </div>
            <div className="flex gap-3">
              <AdminButton variant="outline" onClick={() => { setDialog(null); setHomeScore(''); setAwayScore(''); }} className="flex-1">取消</AdminButton>
              <AdminButton onClick={() => handleAction('resolve')} disabled={homeScore === '' || awayScore === '' || resolve.isPending} className="flex-1">
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
