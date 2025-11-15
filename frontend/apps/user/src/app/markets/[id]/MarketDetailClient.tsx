'use client';

import { useState, useEffect, useMemo } from 'react';
import { formatUnits } from 'viem';
import {
  useAccount,
  useMarket,
  useMarketOrders,
  useMarketAllOrders,
  MarketStatus,
  usePlaceBet,
  useApproveUSDC,
  useUSDCAllowance,
  useUSDCBalance,
  useAutoRefresh,
  useWatchBetPlaced,
  useMarketOutcomes,
  useMarketFullData,
  formatUSDCFromWei,
} from '@pitchone/web3';
import {
  Container,
  Card,
  Badge,
  Button,
  Input,
  LoadingSpinner,
  EmptyState,
  ErrorState,
  Modal,
} from '@pitchone/ui';
import { LiveActivity } from '@/components/LiveActivity';
import { betNotifications, marketNotifications } from '@/lib/notifications';
import { useParlayStore } from '@/lib/parlay-store';
import toast from 'react-hot-toast';

export function MarketDetailClient({ marketId }: { marketId: string }) {
  const { address, isConnected, chain } = useAccount();
  const { addOutcome, hasMarket, getOutcome } = useParlayStore();

  const [selectedOutcome, setSelectedOutcome] = useState<number | null>(null);
  const [betAmount, setBetAmount] = useState('');
  const [showBetModal, setShowBetModal] = useState(false);
  const [needsApproval, setNeedsApproval] = useState(false);
  const [approveToastId, setApproveToastId] = useState<string | null>(null);
  const [betToastId, setBetToastId] = useState<string | null>(null);

  const { data: market, isLoading, error, refetch: refetchMarket } = useMarket(marketId);
  const { data: orders, refetch: refetchOrders } = useMarketOrders(address, marketId);
  const { data: allOrders, refetch: refetchAllOrders } = useMarketAllOrders(marketId);

  // 获取真实的 outcome 数据（包括实时赔率）
  const { data: outcomes, isLoading: outcomesLoading, refetch: refetchOutcomes } = useMarketOutcomes(
    marketId as `0x${string}`,
    market?._displayInfo?.templateType || 'WDL'
  );

  // 获取实时的市场流动性数据（直接从合约读取）
  const { data: marketFullData, refetch: refetchMarketFullData } = useMarketFullData(
    marketId as `0x${string}`,
    address
  );

  // 调试日志：显示所有关键状态
  console.log('[MarketDetailClient] 组件状态:', {
    marketId,
    isConnected,
    chainId: chain?.id,
    chainName: chain?.name,
    address,
    hasMarket: !!market,
    market,
    hasOutcomes: !!outcomes,
    outcomes,
    hasMarketFullData: !!marketFullData,
    marketFullData,
    isLoading,
    outcomesLoading,
    hasError: !!error,
    error,
    allOrdersCount: allOrders?.length || 0,
  });

  // 实时事件监听
  const betPlacedEvents = useWatchBetPlaced(marketId as `0x${string}`);

  // 合并历史订单和实时事件
  const allBetEvents = useMemo(() => {
    // 辅助函数：安全地将字符串转换为 BigInt
    // Subgraph 现在返回原始 BigInt 字符串，直接转换即可
    const stringToBigInt = (value: string | undefined): bigint => {
      if (!value) return 0n;
      return BigInt(value);
    };

    const historicalEvents = (allOrders || []).map(order => {
      console.log('[allBetEvents] 处理历史订单:', order);
      return {
        user: order.user as `0x${string}`,
        outcomeId: BigInt(order.outcome),
        amount: stringToBigInt(order.amount), // 原始 wei 值
        shares: stringToBigInt(order.shares), // 原始 wei 值
        fee: stringToBigInt(order.fee), // 原始 wei 值
        blockNumber: 0n, // 历史订单没有 blockNumber
        transactionHash: order.transactionHash,
        timestamp: parseInt(order.timestamp) * 1000, // 转换为毫秒
      };
    });

    // 合并实时事件和历史事件，按时间戳排序（最新的在前）
    const combined = [...betPlacedEvents, ...historicalEvents];

    // 去重（通过 transactionHash）
    const uniqueEvents = combined.reduce((acc, event) => {
      if (!acc.find(e => e.transactionHash === event.transactionHash)) {
        acc.push(event);
      }
      return acc;
    }, [] as typeof combined);

    // 按时间戳降序排序
    return uniqueEvents.sort((a, b) => b.timestamp - a.timestamp);
  }, [allOrders, betPlacedEvents]);

  // 监听新下注事件并通知
  useEffect(() => {
    if (betPlacedEvents.length > 0 && market && outcomes) {
      const latestBet = betPlacedEvents[0];
      const outcomeName = outcomes[Number(latestBet.outcomeId)]?.name || `结果 ${latestBet.outcomeId}`;
      const amount = formatUnits(latestBet.amount, 6);

      // 排除自己的下注（已经有专门的通知）
      if (latestBet.user.toLowerCase() !== address?.toLowerCase()) {
        marketNotifications.newBet(amount, outcomeName);
      }
    }
  }, [betPlacedEvents, address, market, outcomes]);

  // 自动刷新（包括 outcomes、流动性和所有订单）
  useAutoRefresh(
    () => {
      refetchMarket();
      refetchOutcomes();
      refetchMarketFullData();
      refetchAllOrders();
      if (address) {
        refetchOrders();
      }
    },
    marketId as `0x${string}`,
    {
      enabled: true,
      pollInterval: 15000, // 15 秒轮询一次作为备选
    }
  );

  // 合约交互 hooks
  const { data: usdcBalance } = useUSDCBalance(address as `0x${string}`);
  const {
    data: allowance,
    refetch: refetchAllowance,
    isLoading: isAllowanceLoading,
    error: allowanceError
  } = useUSDCAllowance(
    address as `0x${string}`,
    marketId as `0x${string}`
  );
  const {
    approve,
    isPending: isApproving,
    isConfirming: isApprovingConfirming,
    isSuccess: isApproved,
    hash: approveHash,
    error: approveError
  } = useApproveUSDC();
  const {
    placeBet,
    isPending: isBetting,
    isConfirming: isBettingConfirming,
    isSuccess: isBetSuccess,
    hash: betHash,
    error: betError
  } = usePlaceBet(marketId as `0x${string}`);

  // 调试日志：追踪下注交易状态
  useEffect(() => {
    console.log('[BET HOOK 状态]:', {
      isPending: isBetting,
      isConfirming: isBettingConfirming,
      isSuccess: isBetSuccess,
      hash: betHash,
      error: betError
    });
  }, [isBetting, isBettingConfirming, isBetSuccess, betHash, betError]);

  // 检查是否需要 approve
  useEffect(() => {
    if (!betAmount) {
      // 没有输入金额时，重置状态
      setNeedsApproval(false);
      return;
    }

    // 如果有授权错误，默认需要授权
    if (allowanceError) {
      console.log('[MarketDetailClient] allowance 查询失败，默认需要授权:', allowanceError);
      setNeedsApproval(true);
      return;
    }

    // 如果授权数据可用，进行检查
    if (allowance !== undefined) {
      const amountInWei = BigInt(parseFloat(betAmount) * 1e6); // USDC 6 decimals
      const needsApprove = allowance < amountInWei;
      console.log('[MarketDetailClient] 授权检查:', {
        betAmount,
        amountInWei: amountInWei.toString(),
        allowance: allowance.toString(),
        needsApprove
      });
      setNeedsApproval(needsApprove);
    }
    // 注意：这里不再默认设置需要授权，让按钮显示"检查授权..."
  }, [betAmount, allowance, allowanceError]);

  // 监听授权交易发起
  useEffect(() => {
    if (isApproving && !approveToastId) {
      console.log('[APPROVE] 交易开始，显示 loading toast');
      const toastId = betNotifications.approvingUSDC();
      setApproveToastId(toastId);
    }
  }, [isApproving, approveToastId]);

  // 监听授权交易错误
  useEffect(() => {
    if (approveError && approveToastId) {
      console.log('[APPROVE] 交易失败:', approveError);
      betNotifications.approveFailed(approveToastId, approveError.message || '授权失败');
      setApproveToastId(null);
    }
  }, [approveError, approveToastId]);

  // 监听授权交易成功
  useEffect(() => {
    console.log('[APPROVE] 状态变化:', { isApproved, approveToastId });

    if (isApproved && approveToastId) {
      console.log('[APPROVE] 交易成功，更新 toast');
      betNotifications.approvedUSDC(approveToastId);
      setApproveToastId(null);
      refetchAllowance();
    }
  }, [isApproved, approveToastId]);

  // 监听下注交易发起
  useEffect(() => {
    if (isBetting && !betToastId) {
      console.log('[BET] 交易开始，显示 loading toast');
      const toastId = betNotifications.placingBet();
      setBetToastId(toastId);
    }
  }, [isBetting, betToastId]);

  // 监听下注交易错误
  useEffect(() => {
    if (betError && betToastId) {
      console.log('[BET] 交易失败:', betError);

      // 识别 nonce 错误并提供友好提示
      let errorMessage = '交易失败';
      if (betError.message && betError.message.includes('nonce')) {
        errorMessage = '交易 nonce 冲突，请在钱包中清除交易历史后重试';
      } else if (betError.message) {
        // 简化错误消息
        const shortMessage = betError.message.split('\n')[0];
        errorMessage = shortMessage.length > 100
          ? shortMessage.substring(0, 100) + '...'
          : shortMessage;
      }

      betNotifications.betFailed(betToastId, errorMessage);
      setBetToastId(null);
    }
  }, [betError, betToastId]);

  // 监听下注交易成功
  useEffect(() => {
    console.log('[BET] 状态变化:', { isBetSuccess, betToastId, hasOutcomes: !!outcomes, selectedOutcome });

    if (isBetSuccess && betToastId) {
      console.log('[BET] 交易成功，更新 toast 并刷新数据');
      const outcomeName = outcomes && selectedOutcome !== null
        ? outcomes[selectedOutcome]?.name || `结果 ${selectedOutcome}`
        : '未知结果';

      betNotifications.betPlaced(betToastId, betAmount, outcomeName);
      setBetToastId(null);
      setShowBetModal(false);
      setBetAmount('');
      setSelectedOutcome(null);

      // 刷新市场数据和订单
      setTimeout(() => {
        refetchMarket();
        refetchOutcomes();
        refetchMarketFullData();
        refetchAllOrders();
        if (address) {
          refetchOrders();
        }
      }, 1000); // 等待 1 秒让 subgraph 索引事件
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isBetSuccess, betToastId]);

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusBadge = (status: MarketStatus) => {
    const variants = {
      [MarketStatus.Open]: { variant: 'success' as const, label: '进行中' },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: '已锁盘' },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: '已结算' },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: '已完成' },
    };
    const config = variants[status];
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  const calculatePayout = () => {
    if (!betAmount || selectedOutcome === null || !outcomes) return '0.00';
    const amount = parseFloat(betAmount);
    const odds = parseFloat(outcomes[selectedOutcome].odds);
    return (amount * odds).toFixed(2);
  };

  const handleApprove = async () => {
    if (!marketId) return;

    try {
      // 授权最大值，避免用户反复授权（DeFi 标准做法）
      await approve(marketId as `0x${string}`, 'max');
    } catch (error: any) {
      console.error('Approve error:', error);
      if (approveToastId) {
        betNotifications.approveFailed(approveToastId, error?.message || '未知错误');
        setApproveToastId(null);
      }
    }
  };

  const handlePlaceBet = async () => {
    if (!isConnected || selectedOutcome === null || !betAmount || !outcomes) return;

    try {
      await placeBet(selectedOutcome, betAmount);
    } catch (error: any) {
      console.error('Place bet error:', error);
      if (betToastId) {
        betNotifications.betFailed(betToastId, error?.message || '未知错误');
        setBetToastId(null);
      }
    }
  };

  const handleAddToParlay = (outcomeId: number) => {
    if (!market || !outcomes || outcomeId >= outcomes.length) return;

    const outcome = outcomes[outcomeId];
    const marketName = market._displayInfo?.homeTeam && market._displayInfo?.awayTeam
      ? `${market._displayInfo.homeTeam} vs ${market._displayInfo.awayTeam}`
      : `市场 ${market.id.slice(0, 8)}...`;

    addOutcome({
      marketAddress: marketId as `0x${string}`,
      marketName,
      outcomeId,
      outcomeName: outcome.name,
      odds: outcome.odds,
    });

    toast.success(`已添加到串关: ${outcome.name}`, {
      icon: '🎯',
      duration: 2000,
    });
  };

  // 1. 加载状态（优先级最高）
  if (isLoading || outcomesLoading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载市场详情..." />
      </div>
    );
  }

  // 2. 网络错误
  if (error) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message={`加载失败: ${(error as Error).message || '网络错误，请检查连接'}`} />
      </div>
    );
  }

  // 3. 市场不存在
  if (!market) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message="市场不存在，可能已被删除或 ID 不正确" />
      </div>
    );
  }

  // 4. 合约数据加载失败
  if (!outcomes) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message="无法加载市场赔率数据，请稍后重试" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="xl">
        {/* Market Header */}
        <Card className="mb-6" variant="neon" padding="lg">
          <div className="flex items-start justify-between mb-4">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-3xl font-bold text-white">
                  {market._displayInfo?.homeTeam || 'Team A'} vs {market._displayInfo?.awayTeam || 'Team B'}
                </h1>
                {getStatusBadge(market.state)}
              </div>
              <p className="text-gray-400">{market._displayInfo?.league || 'Unknown League'}</p>
              <p className="text-sm text-gray-500 mt-1">
                创建时间: {formatDate(market.createdAt)}
              </p>
              {market.lockedAt && (
                <p className="text-sm text-orange-400">
                  锁盘时间: {formatDate(market.lockedAt)}
                </p>
              )}
            </div>
            <div className="flex flex-col items-end gap-2">
              <Badge variant="neon" size="lg">{market._displayInfo?.templateTypeDisplay || '未知'}</Badge>
              {market._displayInfo?.lineDisplay && (
                <Badge variant="info" size="lg">{market._displayInfo.lineDisplay}</Badge>
              )}
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-dark-border">
            <div>
              <p className="text-sm text-gray-500 mb-1">总投注量</p>
              <p className="text-xl font-bold text-neon-blue">{Number(market.totalVolume).toFixed(2)} USDC</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">流动性</p>
              <p className="text-xl font-bold text-neon-green">
                {marketFullData?.totalLiquidity
                  ? Number(formatUnits(marketFullData.totalLiquidity, 6)).toFixed(2)
                  : '0.00'} USDC
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">参与人数</p>
              <p className="text-xl font-bold text-neon-purple">{market.uniqueBettors}</p>
            </div>
          </div>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Outcomes */}
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-2xl font-bold text-white mb-4">投注选项</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {outcomes.map((outcome) => {
                const isInParlay = hasMarket(marketId as `0x${string}`);
                const currentSelection = isInParlay ? getOutcome(marketId as `0x${string}`) : null;
                const isThisOutcomeSelected = currentSelection?.outcomeId === outcome.id;

                return (
                  <Card
                    key={outcome.id}
                    hoverable
                    variant={selectedOutcome === outcome.id ? 'neon' : 'default'}
                    padding="lg"
                    className="flex flex-col"
                  >
                    <div className={`w-full h-2 rounded-full bg-gradient-to-r ${outcome.color} mb-4`} />
                    <h3 className="text-xl font-bold text-white mb-2">{outcome.name}</h3>
                    <div className="flex items-baseline gap-2 mb-4">
                      <span className="text-3xl font-bold text-neon">{outcome.odds}</span>
                      <span className="text-sm text-gray-500">赔率</span>
                    </div>

                    {/* 按钮组 */}
                    <div className="mt-auto space-y-2">
                      {/* 立即下注按钮 */}
                      <Button
                        onClick={() => {
                          if (market.state === MarketStatus.Open) {
                            setSelectedOutcome(outcome.id);
                            setShowBetModal(true);
                          }
                        }}
                        disabled={market.state !== MarketStatus.Open}
                        variant="neon"
                        size="sm"
                        className="w-full"
                      >
                        {market.state === MarketStatus.Open ? '立即下注' : '已锁盘'}
                      </Button>

                      {/* 加入串关按钮 */}
                      <Button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleAddToParlay(outcome.id);
                        }}
                        disabled={isThisOutcomeSelected || market.state !== MarketStatus.Open}
                        variant={isThisOutcomeSelected ? 'secondary' : 'ghost'}
                        size="sm"
                        className="w-full"
                      >
                        {isThisOutcomeSelected ? (
                          <>
                            <svg className="w-4 h-4 mr-1 inline" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                            </svg>
                            已加入串关
                          </>
                        ) : (
                          <>
                            <svg className="w-4 h-4 mr-1 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                            </svg>
                            加入串关
                          </>
                        )}
                      </Button>
                    </div>
                  </Card>
                );
              })}
            </div>

            {/* Live Activity */}
            <div>
              <h2 className="text-2xl font-bold text-white mb-4">实时活动</h2>
              <LiveActivity
                events={allBetEvents}
                outcomeNames={outcomes.map((o) => o.name)}
              />
            </div>

            {/* Orders History */}
            <div>
              <h2 className="text-2xl font-bold text-white mb-4">我的订单</h2>
              {!isConnected ? (
                <Card padding="lg">
                  <EmptyState
                    icon={
                      <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                    }
                    title="请先连接钱包"
                    description="连接钱包后即可查看您的订单历史"
                  />
                </Card>
              ) : !orders || orders.length === 0 ? (
                <Card padding="lg">
                  <EmptyState
                    title="暂无订单"
                    description="您还没有在这个市场进行预测"
                  />
                </Card>
              ) : (
                <Card padding="none">
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-dark-card border-b border-dark-border">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">时间</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">选项</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">金额</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">预期收益</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-dark-border">
                        {orders.map((order) => {
                          // Subgraph 返回的 amount 和 shares 都是 BigInt 字符串（原始 wei 值）
                          // 使用统一的精度转换函数
                          const amountUSDC = formatUSDCFromWei(order.amount);
                          const sharesInUSDC = formatUSDCFromWei(order.shares);
                          // 获取选项名称
                          const outcomeName = outcomes?.[order.outcome]?.name || `结果 ${order.outcome}`;

                          return (
                            <tr key={order.id} className="hover:bg-dark-card/50 transition-colors">
                              <td className="px-6 py-4 text-sm text-gray-400">{formatDate(order.timestamp)}</td>
                              <td className="px-6 py-4">
                                <Badge variant="info">{outcomeName}</Badge>
                              </td>
                              <td className="px-6 py-4 text-sm font-medium text-white">{amountUSDC.toFixed(2)} USDC</td>
                              <td className="px-6 py-4 text-sm font-medium text-neon-green">
                                +{sharesInUSDC.toFixed(2)} USDC
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </Card>
              )}
            </div>
          </div>

          {/* Sidebar - Quick Stats */}
          <div className="lg:col-span-1">
            <Card variant="glass" padding="lg" className="sticky top-24">
              <h3 className="text-lg font-bold text-white mb-4">市场信息</h3>
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-500 mb-1">市场 ID</p>
                  <p className="text-xs font-mono text-gray-400 break-all">{market.id}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">状态</p>
                  {getStatusBadge(market.state)}
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">手续费率</p>
                  <p className="text-sm text-white">2%</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">最小投注</p>
                  <p className="text-sm text-white">1 USDC</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">最大投注</p>
                  <p className="text-sm text-white">10,000 USDC</p>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </Container>

      {/* Bet Modal */}
      <Modal
        isOpen={showBetModal}
        onClose={() => {
          setShowBetModal(false);
          setBetAmount('');
        }}
        title="确认预测"
        size="md"
      >
        {selectedOutcome !== null && outcomes && (
          <div className="space-y-6">
            {/* Selected Outcome */}
            <div className="p-4 bg-dark-bg rounded-lg border border-dark-border">
              <p className="text-sm text-gray-500 mb-1">选择结果</p>
              <div className="flex items-center justify-between">
                <p className="text-xl font-bold text-white">{outcomes[selectedOutcome].name}</p>
                <Badge variant="neon" size="lg">{outcomes[selectedOutcome].odds}x</Badge>
              </div>
            </div>

            {/* Balance Display */}
            {usdcBalance !== undefined && (
              <div className="text-sm text-gray-400">
                余额: {formatUnits(usdcBalance, 6)} USDC
              </div>
            )}

            {/* Amount Input */}
            <Input
              type="number"
              label="投注金额 (USDC)"
              placeholder="输入金额"
              value={betAmount}
              onChange={(e) => setBetAmount(e.target.value)}
              min="1"
              max="10000"
              fullWidth
            />

            {/* Expected Payout */}
            {betAmount && (
              <div className="p-4 bg-gradient-to-r from-neon-blue/10 to-neon-purple/10 rounded-lg border border-neon-blue/30">
                <p className="text-sm text-gray-400 mb-1">预期收益</p>
                <p className="text-3xl font-bold text-neon">{calculatePayout()} USDC</p>
                <p className="text-xs text-gray-500 mt-1">净盈利: {(parseFloat(calculatePayout()) - parseFloat(betAmount)).toFixed(2)} USDC</p>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-3">
              <Button
                variant="secondary"
                fullWidth
                onClick={() => {
                  setShowBetModal(false);
                  setBetAmount('');
                }}
                disabled={isApproving || isApprovingConfirming || isBetting || isBettingConfirming}
              >
                取消
              </Button>

              {needsApproval ? (
                <Button
                  variant="neon"
                  fullWidth
                  onClick={handleApprove}
                  disabled={!betAmount || parseFloat(betAmount) < 1 || isApproving || isApprovingConfirming || isAllowanceLoading}
                  isLoading={isApproving || isApprovingConfirming || isAllowanceLoading}
                >
                  {isApproving || isApprovingConfirming ? '授权中...' : isAllowanceLoading ? '检查授权...' : '授权 USDC'}
                </Button>
              ) : (
                <Button
                  variant="neon"
                  fullWidth
                  onClick={handlePlaceBet}
                  disabled={!betAmount || parseFloat(betAmount) < 1 || isBetting || isBettingConfirming || (isAllowanceLoading && allowance === undefined)}
                  isLoading={isBetting || isBettingConfirming}
                >
                  {isBetting || isBettingConfirming ? '预测中...' : (isAllowanceLoading && allowance === undefined) ? '检查授权...' : '确认预测'}
                </Button>
              )}
            </div>

            {!isConnected && (
              <p className="text-sm text-yellow-500 text-center">⚠️ 请先连接钱包</p>
            )}

            {needsApproval && (
              <p className="text-sm text-blue-400 text-center">
                💡 首次预测需要授权 USDC
              </p>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
