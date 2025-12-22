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
  useIsMarketLocked,
} from '@pitchone/web3';
import {
  Card,
  Button,
  LoadingSpinner,
  ErrorState,
} from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import Link from 'next/link';
import { betNotifications, marketNotifications } from '@/lib/notifications';

export function MarketDetailClient({ marketId }: { marketId: string }) {
  const { t, translateTeam, translateLeague } = useTranslation();
  const { address, isConnected } = useAccount();

  const [selectedOutcome, setSelectedOutcome] = useState<number | null>(null);
  const [betAmount, setBetAmount] = useState('');
  const [needsApproval, setNeedsApproval] = useState(false);
  const [approveToastId, setApproveToastId] = useState<string | null>(null);
  const [betToastId, setBetToastId] = useState<string | null>(null);

  const { data: market, isLoading, error, refetch: refetchMarket } = useMarket(marketId);
  const { refetch: refetchOrders } = useMarketOrders(address, marketId);
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

  // 调用 isLocked() 检查基于开赛时间的锁定状态
  const { data: isMarketLocked } = useIsMarketLocked(marketId as `0x${string}`);

  // 计算有效的下注状态
  // 如果基于时间的锁定生效，则不允许下注（即使合约状态是 Open）
  const canBet = useMemo(() => {
    if (!market) return false;
    return market.state === MarketStatus.Open && !isMarketLocked;
  }, [market, isMarketLocked]);

  // 调试日志：显示所有关键状态
  console.log('[MarketDetailClient] 组件状态:', {
    marketId,
    isConnected,
    address,
    hasMarket: !!market,
    hasOutcomes: !!outcomes,
    hasMarketFullData: !!marketFullData,
    isLoading,
    outcomesLoading,
    hasError: !!error,
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
      const outcomeName = outcomes[Number(latestBet.outcomeId)]?.name || `${t('markets.detail.outcomeLabel')} ${latestBet.outcomeId}`;
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
    if (allowance !== undefined && allowance !== null && typeof allowance === 'bigint') {
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
        ? outcomes[selectedOutcome]?.name || `${t('markets.detail.outcomeLabel')} ${selectedOutcome}`
        : t('markets.unknown');

      betNotifications.betPlaced(betToastId, betAmount, outcomeName);
      setBetToastId(null);
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

  // 格式化日期为简短格式 (DEC 02 12:07)
  const formatShortDate = (timestamp: string | number) => {
    const ts = typeof timestamp === 'string' ? parseInt(timestamp) : timestamp;
    const date = new Date(ts * 1000);
    const month = date.toLocaleString('en-US', { month: 'short' }).toUpperCase();
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${month} ${day} ${hour}:${minute}`;
  };

  // 截断地址显示
  const truncateAddress = (address: string) => {
    if (!address || address.length < 10) return address;
    return `${address.slice(0, 5)}...${address.slice(-4)}`;
  };

  // 获取队名缩写
  const getTeamAbbr = (teamName: string) => {
    if (!teamName) return 'TBD';
    // 提取前3个字母作为缩写
    return teamName.slice(0, 3).toUpperCase();
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

  // 获取市场状态文本
  const getMarketStatusText = () => {
    if (market.state === MarketStatus.Finalized) return t('markets.detail.statusSettled');
    if (market.state === MarketStatus.Resolved) return t('markets.detail.statusResolved');
    if (market.state === MarketStatus.Locked || isMarketLocked) return t('markets.detail.statusLocked');
    return t('markets.detail.statusOpen');
  };

  const homeTeam = market._displayInfo?.homeTeam || 'Home';
  const awayTeam = market._displayInfo?.awayTeam || 'Away';
  const league = market._displayInfo?.league || 'League';

  return (
    <div className="min-h-screen bg-white">
      {/* Back Link */}
      <div className="px-6 py-4">
        <Link href="/markets" className="text-gray-600 hover:text-gray-900 flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          {t('common.back')}
        </Link>
      </div>

      <div className="flex">
        {/* Main Content */}
        <div className={`flex-1 px-6 pb-8 ${selectedOutcome !== null ? 'pr-4' : ''}`}>
          {/* Match Header */}
          <Card className="mb-6 bg-white shadow-sm" padding="lg">
            {/* League Name */}
            <h2 className="text-xl font-bold text-gray-900 text-center mb-6">{league}</h2>

            {/* Three Column Layout */}
            <div className="grid grid-cols-3 items-center mb-4">
              {/* Left: Sport & League */}
              <div>
                <p className="text-gray-500 text-sm">{t('markets.detail.soccer')}</p>
                <p className="text-gray-900 font-medium">{translateLeague(league)}</p>
              </div>

              {/* Center: Team Logos */}
              <div className="flex justify-center items-center gap-4">
                {/* Home Team Logo */}
                <div className="flex flex-col items-center">
                  <div className="w-16 h-16 rounded-full bg-gray-100 border-2 border-gray-200 flex items-center justify-center">
                    <span className="text-xl font-bold text-gray-400">{getTeamAbbr(homeTeam)}</span>
                  </div>
                  <span className="text-xs text-gray-500 mt-1">{translateTeam(homeTeam)}</span>
                </div>

                {/* Away Team Logo */}
                <div className="flex flex-col items-center">
                  <div className="w-16 h-16 rounded-full bg-gray-100 border-2 border-gray-200 flex items-center justify-center">
                    <span className="text-xl font-bold text-gray-400">{getTeamAbbr(awayTeam)}</span>
                  </div>
                  <span className="text-xs text-gray-500 mt-1">{translateTeam(awayTeam)}</span>
                </div>
              </div>

              {/* Right: Match Time */}
              <div className="text-right">
                <p className="text-gray-500 text-sm">{t('markets.detail.matchtime')}:</p>
                <p className="text-gray-900 font-bold">{formatShortDate(market.kickoffTime)}</p>
                <p className="text-gray-500 text-sm">{t('markets.detail.regularSeason')}</p>
              </div>
            </div>

            {/* Team Names */}
            <p className="text-center text-lg font-semibold text-gray-900">
              {getTeamAbbr(homeTeam)} {translateTeam(homeTeam).charAt(0)} - {getTeamAbbr(awayTeam)} {translateTeam(awayTeam).charAt(0)}
            </p>
          </Card>

          {/* Winner Section */}
          <Card className="mb-6 bg-white shadow-sm" padding="lg">
            <h3 className="text-center text-gray-500 text-sm font-medium uppercase tracking-wider mb-4">
              {t('markets.detail.winner')}
            </h3>
            <div className="grid grid-cols-3 gap-0 rounded-lg overflow-hidden border border-gray-200">
              {outcomes.map((outcome, index) => (
                <button
                  key={outcome.id}
                  onClick={() => canBet && setSelectedOutcome(outcome.id)}
                  disabled={!canBet}
                  className={`
                    py-4 px-2 text-center transition-all
                    ${index < outcomes.length - 1 ? 'border-r border-gray-200' : ''}
                    ${selectedOutcome === outcome.id
                      ? 'bg-gray-100 ring-2 ring-inset ring-blue-500'
                      : 'bg-gray-50 hover:bg-gray-100'
                    }
                    ${!canBet ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
                  `}
                >
                  <p className="text-gray-600 text-sm font-medium mb-1">{outcome.name}</p>
                  <p className="text-gray-900 text-xl font-bold">{outcome.odds}</p>
                </button>
              ))}
            </div>
          </Card>

          {/* Activity Section */}
          <Card className="bg-white shadow-sm" padding="none">
            <h3 className="text-center text-gray-500 text-sm font-medium uppercase tracking-wider py-4 border-b border-gray-200">
              {t('markets.detail.activity')}
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tableTime')} ▼</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tableOwner')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tableSelected')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tablePaid')} ▼</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tablePayout')} ▼</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">{t('markets.detail.tableStatus')} ▼</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {allBetEvents.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-4 py-8 text-center text-gray-400">
                        {t('markets.detail.noActivity')}
                      </td>
                    </tr>
                  ) : (
                    allBetEvents.slice(0, 20).map((event, idx) => {
                      const amountUSDC = Number(event.amount) / 1e6;
                      const payoutUSDC = Number(event.shares) / 1e6;
                      const outcomeName = outcomes[Number(event.outcomeId)]?.name || `${t('markets.detail.outcomeLabel')} ${event.outcomeId}`;

                      return (
                        <tr key={event.transactionHash || idx} className="hover:bg-gray-50">
                          <td className="px-4 py-3 text-sm text-gray-600">
                            {formatShortDate(event.timestamp / 1000)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-600 font-mono">
                            {truncateAddress(event.user)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-900 font-medium">
                            {getTeamAbbr(homeTeam)} - {outcomeName.toUpperCase()}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-900">
                            ${amountUSDC.toFixed(2)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-900">
                            ${payoutUSDC.toFixed(2)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-600 uppercase">
                            {getMarketStatusText()}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </Card>
        </div>

        {/* Right Side Bet Slip - Only shown when outcome is selected */}
        {selectedOutcome !== null && outcomes && (
          <div className="w-80 shrink-0 p-4">
            <Card className="sticky top-4 bg-white shadow-lg border border-gray-200" padding="lg">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">{t('markets.detail.betSlip')}</h3>
                <button
                  onClick={() => {
                    setSelectedOutcome(null);
                    setBetAmount('');
                  }}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* Selected Outcome */}
              <div className="p-3 bg-gray-50 rounded-lg mb-4">
                <p className="text-xs text-gray-500 mb-1">
                  {translateTeam(homeTeam)} vs {translateTeam(awayTeam)}
                </p>
                <div className="flex items-center justify-between">
                  <p className="text-sm font-semibold text-gray-900">{outcomes[selectedOutcome].name}</p>
                  <span className="text-sm font-bold text-blue-600">{outcomes[selectedOutcome].odds}x</span>
                </div>
              </div>

              {/* Balance Display */}
              {usdcBalance !== undefined && usdcBalance !== null && typeof usdcBalance === 'bigint' && (
                <p className="text-xs text-gray-500 mb-2">
                  {t('markets.detail.balance')}: {formatUnits(usdcBalance, 6)} USDC
                </p>
              )}

              {/* Amount Input */}
              <div className="mb-4">
                <label className="block text-xs font-medium text-gray-500 mb-1">
                  {t('markets.detail.amountUsdc')}
                </label>
                <div className="relative">
                  <input
                    type="number"
                    placeholder="0.00"
                    value={betAmount}
                    onChange={(e) => setBetAmount(e.target.value)}
                    min="1"
                    max="10000"
                    className="w-full px-3 py-2 pr-14 bg-white border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      if (usdcBalance !== undefined && usdcBalance !== null && typeof usdcBalance === 'bigint') {
                        setBetAmount(formatUnits(usdcBalance, 6));
                      }
                    }}
                    disabled={!usdcBalance || usdcBalance === 0n}
                    className="absolute right-2 top-1/2 -translate-y-1/2 px-2 py-1 text-xs font-semibold text-blue-600 hover:bg-blue-50 rounded disabled:opacity-50"
                  >
                    {t('markets.detail.max')}
                  </button>
                </div>
              </div>

              {/* Expected Payout */}
              {betAmount && parseFloat(betAmount) > 0 && (
                <div className="p-3 bg-blue-50 rounded-lg mb-4">
                  <p className="text-xs text-gray-500 mb-1">{t('markets.detail.potentialPayoutLabel')}</p>
                  <p className="text-xl font-bold text-blue-600">${calculatePayout()}</p>
                  <p className="text-xs text-gray-500">
                    {t('markets.detail.profitLabel')}: ${(parseFloat(calculatePayout()) - parseFloat(betAmount)).toFixed(2)}
                  </p>
                </div>
              )}

              {/* Action Buttons */}
              <div className="space-y-2">
                {needsApproval ? (
                  <Button
                    variant="neon"
                    fullWidth
                    onClick={handleApprove}
                    disabled={!betAmount || parseFloat(betAmount) < 1 || isApproving || isApprovingConfirming || isAllowanceLoading}
                    isLoading={isApproving || isApprovingConfirming || isAllowanceLoading}
                  >
                    {isApproving || isApprovingConfirming ? t('markets.detail.approvingBtn') : isAllowanceLoading ? t('markets.detail.checkingBtn') : t('markets.detail.approveUsdcBtn')}
                  </Button>
                ) : (
                  <Button
                    variant="neon"
                    fullWidth
                    onClick={handlePlaceBet}
                    disabled={!betAmount || parseFloat(betAmount) < 1 || isBetting || isBettingConfirming || !isConnected}
                    isLoading={isBetting || isBettingConfirming}
                  >
                    {isBetting || isBettingConfirming ? t('markets.detail.placingBetBtn') : t('markets.detail.placeBetBtn')}
                  </Button>
                )}
              </div>

              {!isConnected && (
                <p className="text-xs text-amber-600 text-center mt-3">
                  {t('markets.detail.connectWalletToBet')}
                </p>
              )}

              {needsApproval && (
                <p className="text-xs text-blue-500 text-center mt-3">
                  {t('markets.detail.firstTimeApproval')}
                </p>
              )}
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
