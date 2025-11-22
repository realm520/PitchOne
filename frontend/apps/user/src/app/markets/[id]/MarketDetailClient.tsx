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
import { useTranslation } from '@pitchone/i18n';
import { LiveActivity } from '@/components/LiveActivity';
import { betNotifications, marketNotifications } from '@/lib/notifications';
import { useParlayStore } from '@/lib/parlay-store';
import toast from 'react-hot-toast';

export function MarketDetailClient({ marketId }: { marketId: string }) {
  const { t } = useTranslation();
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
  // 传递盘口线信息（如果有），用于 OU/AH 市场显示完整的投注提示
  const { data: outcomes, isLoading: outcomesLoading, refetch: refetchOutcomes } = useMarketOutcomes(
    marketId as `0x${string}`,
    market?._displayInfo?.templateType || 'WDL',
    market?.line // 传递盘口线（千分位表示）
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
      [MarketStatus.Open]: { variant: 'success' as const, label: t('markets.status.open') },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: t('markets.status.locked') },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: t('markets.status.resolved') },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: t('markets.status.finalized') },
    };
    const config = variants[status];
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  /**
   * 计算预期收益（基于实际奖池分布）
   *
   * 对于 Parimutuel（奖池）模式：
   * - 预期收益 = (总奖池 + 投注金额) × (1 - 手续费) × (投注金额 / (该结果投注额 + 投注金额))
   *
   * 对于 CPMM 模式：
   * - 计算用户能获得的 shares（使用精确的 CPMM 公式）
   * - 预期收益 = shares（因为赢的情况下 1 share = 1 USDC）
   */
  const calculatePayout = () => {
    if (!betAmount || selectedOutcome === null || !outcomes || !marketFullData) return '0.00';

    const amount = parseFloat(betAmount);
    const feeRate = Number(marketFullData.feeRate) / 10000; // feeRate 是基点（如 200 = 2%）
    const netAmount = amount * (1 - feeRate); // 扣除手续费后的净投注额

    if (marketFullData.isParimutel) {
      // ===== Parimutuel 奖池模式 =====
      // 投注后的总奖池
      const newTotalPool = Number(marketFullData.totalLiquidity) + amount * 1e6; // 转换为 wei

      // 投注后该结果的投注额
      const currentOutcomeBets = Number(marketFullData.outcomeLiquidity[selectedOutcome]);
      const newOutcomeBets = currentOutcomeBets + amount * 1e6; // 转换为 wei

      // 扣除手续费后的奖池
      const netPool = newTotalPool * (1 - feeRate);

      // 用户的预期收益 = 净奖池 × 用户投注占该结果的比例
      if (newOutcomeBets > 0) {
        const payout = (netPool * (amount * 1e6)) / newOutcomeBets;
        return (payout / 1e6).toFixed(2); // 转换回 USDC
      }

      return '0.00';
    } else {
      // ===== CPMM 做市商模式 =====
      // 使用精确的 CPMM 公式计算 shares
      const outcomeCount = Number(marketFullData.outcomeCount);
      const reserves = marketFullData.outcomeLiquidity.map(r => Number(r));

      let shares = 0;

      if (outcomeCount === 2) {
        // 二向市场精确公式
        const r_target = reserves[selectedOutcome];
        const r_other = reserves[1 - selectedOutcome];

        // k = r₀ × r₁
        const k = r_target * r_other;

        // 新的对手盘储备：r_other' = r_other + netAmount (wei)
        const r_other_new = r_other + netAmount * 1e6;

        // 保持 k 不变：r_target' = k / r_other'
        const r_target_new = k / r_other_new;

        // shares = r_target - r_target'
        shares = r_target - r_target_new;
      } else if (outcomeCount === 3) {
        // 三向市场近似公式
        const r_target = reserves[selectedOutcome];

        // 计算所有对手盘储备总和
        let opponent_total = 0;
        for (let i = 0; i < 3; i++) {
          if (i !== selectedOutcome) {
            opponent_total += reserves[i];
          }
        }

        // 使用二向市场公式的近似：k_approx = r_target × opponent_total
        const k_approx = r_target * opponent_total;

        // 新的对手盘总储备：每个对手盘增加 amount/2
        const opponent_total_new = opponent_total + netAmount * 1e6;

        // 保持 k_approx 不变：r_target' = k_approx / opponent_total'
        const r_target_new = k_approx / opponent_total_new;

        // shares = r_target - r_target'
        shares = r_target - r_target_new;
      } else {
        // 多结果市场（如 Score、PlayerProps）：使用当前赔率作为近似
        const odds = parseFloat(outcomes[selectedOutcome].odds);
        return (amount * odds).toFixed(2);
      }

      // 预期收益 = shares（因为赢的情况下 1 share = 1 USDC）
      return (shares / 1e6).toFixed(2); // 转换回 USDC
    }
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
      : `${t('markets.unknown')} ${market.id.slice(0, 8)}...`;

    addOutcome({
      marketAddress: marketId as `0x${string}`,
      marketName,
      outcomeId,
      outcomeName: outcome.name,
      odds: outcome.odds,
    });

    toast.success(`${t('markets.detail.addedToParlay')}: ${outcome.name}`, {
      icon: '🎯',
      duration: 2000,
    });
  };

  // 1. 加载状态（优先级最高）
  if (isLoading || outcomesLoading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text={t('markets.detail.loadingDetail')} />
      </div>
    );
  }

  // 2. 网络错误
  if (error) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message={`${t('markets.detail.loadError')}: ${(error as Error).message || t('markets.errorLoading')}`} />
      </div>
    );
  }

  // 3. 市场不存在
  if (!market) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message={t('markets.detail.notFound')} />
      </div>
    );
  }

  // 4. 合约数据加载失败
  if (!outcomes) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message={t('markets.detail.oddsLoadError')} />
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
                {t('markets.detail.createdAt')}: {formatDate(market.createdAt)}
              </p>
              {market.lockedAt && (
                <p className="text-sm text-orange-400">
                  {t('markets.detail.lockedAt')}: {formatDate(market.lockedAt)}
                </p>
              )}
            </div>
            <div className="flex flex-col items-end gap-2">
              <Badge variant="neon" size="lg">{market._displayInfo?.templateTypeDisplay || t('markets.unknown')}</Badge>
              {market._displayInfo?.lineDisplay && (
                <Badge variant="info" size="lg">{market._displayInfo.lineDisplay}</Badge>
              )}
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-dark-border">
            <div>
              <p className="text-sm text-gray-500 mb-1">{t('markets.detail.totalVolume')}</p>
              <p className="text-xl font-bold text-neon-blue">{Number(market.totalVolume).toFixed(2)} USDC</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">
                {marketFullData?.isParimutel ? t('markets.detail.totalPool') : t('markets.detail.liquidity')}
              </p>
              <p className="text-xl font-bold text-neon-green">
                {marketFullData?.totalLiquidity
                  ? Number(formatUnits(marketFullData.totalLiquidity, 6)).toFixed(2)
                  : '0.00'} USDC
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">{t('markets.detail.participants')}</p>
              <p className="text-xl font-bold text-neon-purple">{market.uniqueBettors}</p>
            </div>
          </div>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Outcomes */}
          <div className="lg:col-span-2 space-y-6">
            <h2 className="text-2xl font-bold text-white mb-4">{t('markets.detail.betOptions')}</h2>
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
                      <span className="text-sm text-gray-500">{t('markets.bet.odds')}</span>
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
                        {market.state === MarketStatus.Open ? t('markets.detail.placeBetNow') : t('markets.detail.locked')}
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
                            {t('markets.detail.addedToParlay')}
                          </>
                        ) : (
                          <>
                            <svg className="w-4 h-4 mr-1 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                            </svg>
                            {t('markets.detail.addToParlay')}
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
              <h2 className="text-2xl font-bold text-white mb-4">{t('markets.detail.liveActivity')}</h2>
              <LiveActivity
                events={allBetEvents}
                outcomeNames={outcomes.map((o) => o.name)}
              />
            </div>

            {/* Orders History */}
            <div>
              <h2 className="text-2xl font-bold text-white mb-4">{t('markets.detail.myOrders')}</h2>
              {!isConnected ? (
                <Card padding="lg">
                  <EmptyState
                    icon={
                      <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                    }
                    title={t('markets.detail.connectFirst')}
                    description={t('markets.detail.connectToViewOrders')}
                  />
                </Card>
              ) : !orders || orders.length === 0 ? (
                <Card padding="lg">
                  <EmptyState
                    title={t('markets.detail.noOrders')}
                    description={t('markets.detail.noOrdersDesc')}
                  />
                </Card>
              ) : (
                <Card padding="none">
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-dark-card border-b border-dark-border">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">{t('markets.detail.tableTime')}</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">{t('markets.detail.tableOption')}</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">{t('markets.detail.tableAmount')}</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">{t('markets.detail.tableExpected')}</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-dark-border">
                        {orders.map((order) => {
                          // Subgraph 返回的 amount 和 shares 都是 BigInt 字符串（原始 wei 值）
                          // 使用统一的精度转换函数
                          const amountUSDC = formatUSDCFromWei(order.amount);
                          const sharesInUSDC = formatUSDCFromWei(order.shares);
                          // 获取选项名称
                          const outcomeName = outcomes?.[order.outcome]?.name || `${t('markets.detail.result')} ${order.outcome}`;

                          // 计算预期收益（根据市场模式）
                          let expectedPayout = sharesInUSDC; // 默认值（CPMM 模式或无数据时）
                          let netProfit = sharesInUSDC - amountUSDC;

                          if (marketFullData?.isParimutel) {
                            // Parimutuel 模式：计算基于奖池分布的预期收益
                            const totalPool = Number(formatUnits(marketFullData.totalLiquidity, 6));
                            const outcomePool = Number(formatUnits(marketFullData.outcomeLiquidity[order.outcome], 6));

                            if (outcomePool > 0) {
                              // 预期赔率 = 总奖池 / 该结果投注额
                              const odds = totalPool / outcomePool;
                              // 预期回报 = shares × 赔率
                              expectedPayout = sharesInUSDC * odds;
                              // 净利润 = 预期回报 - 投入金额
                              netProfit = expectedPayout - amountUSDC;
                            } else {
                              // 如果该结果还没有投注（理论上不应该发生），显示 shares
                              expectedPayout = sharesInUSDC;
                              netProfit = 0;
                            }
                          }

                          return (
                            <tr key={order.id} className="hover:bg-dark-card/50 transition-colors">
                              <td className="px-6 py-4 text-sm text-gray-400">{formatDate(order.timestamp)}</td>
                              <td className="px-6 py-4">
                                <Badge variant="info">{outcomeName}</Badge>
                              </td>
                              <td className="px-6 py-4 text-sm font-medium text-white">{amountUSDC.toFixed(2)} USDC</td>
                              <td className="px-6 py-4">
                                <div className="flex flex-col gap-1">
                                  <span className="text-sm font-medium text-neon-green">
                                    {expectedPayout.toFixed(2)} USDC
                                  </span>
                                  <span className={`text-xs ${netProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                                    ({netProfit >= 0 ? '+' : ''}{netProfit.toFixed(2)} USDC)
                                  </span>
                                </div>
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
              <h3 className="text-lg font-bold text-white mb-4">{t('markets.detail.marketInfo')}</h3>
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-500 mb-1">{t('markets.detail.marketId')}</p>
                  <p className="text-xs font-mono text-gray-400 break-all">{market.id}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">{t('markets.statusLabel')}</p>
                  {getStatusBadge(market.state)}
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">{t('markets.detail.feeRate')}</p>
                  <p className="text-sm text-white">2%</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">{t('markets.detail.minBet')}</p>
                  <p className="text-sm text-white">1 USDC</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">{t('markets.detail.maxBet')}</p>
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
        title={t('markets.detail.confirmBet')}
        size="md"
      >
        {selectedOutcome !== null && outcomes && (
          <div className="space-y-6">
            {/* Selected Outcome */}
            <div className="p-4 bg-dark-bg rounded-lg border border-dark-border">
              <p className="text-sm text-gray-500 mb-1">{t('markets.detail.selectedOutcome')}</p>
              <div className="flex items-center justify-between">
                <p className="text-xl font-bold text-white">{outcomes[selectedOutcome].name}</p>
                <Badge variant="neon" size="lg">{outcomes[selectedOutcome].odds}x</Badge>
              </div>
            </div>

            {/* Balance Display */}
            {usdcBalance !== undefined && (
              <div className="text-sm text-gray-400">
                {t('markets.detail.balance')}: {formatUnits(usdcBalance, 6)} USDC
              </div>
            )}

            {/* Amount Input */}
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                {t('markets.detail.betAmountLabel')}
              </label>
              <div className="relative">
                <input
                  type="number"
                  placeholder={t('markets.detail.inputAmount')}
                  value={betAmount}
                  onChange={(e) => setBetAmount(e.target.value)}
                  min="1"
                  max="10000"
                  className="w-full px-4 py-3 pr-16 bg-dark-bg border border-dark-border rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-neon-blue focus:ring-1 focus:ring-neon-blue transition-colors"
                />
                <button
                  type="button"
                  onClick={() => {
                    if (usdcBalance !== undefined) {
                      const maxAmount = formatUnits(usdcBalance, 6);
                      setBetAmount(maxAmount);
                    }
                  }}
                  disabled={usdcBalance === undefined || usdcBalance === 0n}
                  className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-xs font-semibold text-neon-blue hover:text-white hover:bg-neon-blue/20 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  MAX
                </button>
              </div>
            </div>

            {/* Expected Payout */}
            {betAmount && (
              <div className="p-4 bg-gradient-to-r from-neon-blue/10 to-neon-purple/10 rounded-lg border border-neon-blue/30">
                <p className="text-sm text-gray-400 mb-1">{t('markets.detail.expectedPayout')}</p>
                <p className="text-3xl font-bold text-neon">{calculatePayout()} USDC</p>
                <p className="text-xs text-gray-500 mt-1">{t('markets.detail.netProfit')}: {(parseFloat(calculatePayout()) - parseFloat(betAmount)).toFixed(2)} USDC</p>
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
                {t('common.cancel')}
              </Button>

              {needsApproval ? (
                <Button
                  variant="neon"
                  fullWidth
                  onClick={handleApprove}
                  disabled={!betAmount || parseFloat(betAmount) < 1 || isApproving || isApprovingConfirming || isAllowanceLoading}
                  isLoading={isApproving || isApprovingConfirming || isAllowanceLoading}
                >
                  {isApproving || isApprovingConfirming ? t('markets.detail.approving') : isAllowanceLoading ? t('markets.detail.checkingApproval') : t('markets.detail.approveUSDC')}
                </Button>
              ) : (
                <Button
                  variant="neon"
                  fullWidth
                  onClick={handlePlaceBet}
                  disabled={!betAmount || parseFloat(betAmount) < 1 || isBetting || isBettingConfirming || (isAllowanceLoading && allowance === undefined)}
                  isLoading={isBetting || isBettingConfirming}
                >
                  {isBetting || isBettingConfirming ? t('markets.detail.betting') : (isAllowanceLoading && allowance === undefined) ? t('markets.detail.checkingApproval') : t('markets.detail.confirmBetBtn')}
                </Button>
              )}
            </div>

            {!isConnected && (
              <p className="text-sm text-yellow-500 text-center">⚠️ {t('markets.detail.connectWalletWarning')}</p>
            )}

            {needsApproval && (
              <p className="text-sm text-blue-400 text-center">
                💡 {t('markets.detail.firstBetApproval')}
              </p>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
