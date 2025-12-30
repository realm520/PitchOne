'use client';

import { useEffect, useMemo } from 'react';
import { formatUnits } from 'viem';
import {
  useAccount,
  useMarket,
  useMarketOrders,
  useMarketAllOrders,
  MarketStatus,
  useAutoRefresh,
  useWatchBetPlaced,
  useMarketOutcomes,
  useIsMarketLocked,
} from '@pitchone/web3';
import {
  Card,
  LoadingSpinner,
  ErrorState,
  Badge,
} from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import Link from 'next/link';
import { ChevronLeft, ShieldCheck, BadgeCheck, Copy } from 'lucide-react';
import { marketNotifications, notifySuccess } from '@/lib/notifications';
import { OutcomeButton } from '@/components/betslip';
import { useBetSlipStore, SelectedBet } from '@/lib/betslip-store';
import { formatTxHash, getTxExplorerUrl } from '@/app/portfolio/utils';

export function MarketDetailClient({ marketId }: { marketId: string }) {
  const { t, translateTeam, translateLeague } = useTranslation();
  const { address } = useAccount();
  const { selectBet, isSelected, refreshCounter } = useBetSlipStore();

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

  // 调用 isLocked() 检查基于开赛时间的锁定状态
  const { data: isMarketLocked } = useIsMarketLocked(marketId as `0x${string}`);

  // 计算有效的下注状态
  // 如果基于时间的锁定生效，或者市场已暂停，则不允许下注（即使合约状态是 Open）
  const canBet = useMemo(() => {
    if (!market) return false;
    return market.state === MarketStatus.Open && !isMarketLocked && !market.paused;
  }, [market, isMarketLocked]);

  // 状态指示器（与列表页保持一致）
  const getStatusIndicator = (state: MarketStatus, isPaused?: boolean) => {
    // 如果市场是 Open 但已暂停，显示为 Locked
    if (state === MarketStatus.Open && isPaused) {
      return (
        <span className="inline-flex items-center gap-1.5 text-sm text-gray-400">
          <span className="w-2 h-2 rounded-full bg-yellow-500" />
          {t('markets.status.locked')}
        </span>
      );
    }

    const config = {
      [MarketStatus.Created]: { color: '#A855F7', label: t('markets.status.created') },
      [MarketStatus.Open]: { color: '#22C55E', label: t('markets.status.open') },
      [MarketStatus.Locked]: { color: '#FC1B0B', label: t('markets.status.locked') },
      [MarketStatus.Resolved]: { color: '#61D4D3', label: t('markets.status.resolved') },
      [MarketStatus.Finalized]: { color: '#FC870B', label: t('markets.status.finalized') },
      [MarketStatus.Cancelled]: { color: '#6B7280', label: t('markets.status.cancelled') },
    };
    const { color, label } = config[state] || { color: '#6B7280', label: t('markets.unknown') };

    return (
      <span className="inline-flex items-center gap-1.5 text-sm text-gray-400">
        <span className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
        {label}
      </span>
    );
  };

  // 调试日志：显示所有关键状态
  console.log('[MarketDetailClient] 组件状态:', {
    marketId,
    address,
    hasMarket: !!market,
    hasOutcomes: !!outcomes,
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
    // Subgraph 返回的是小数格式（如 "0.98" USDC），需要转换为 wei
    const stringToBigInt = (value: string | undefined, decimals: number = 6): bigint => {
      if (!value) return 0n;
      try {
        // 处理小数格式（如 "0.98"）
        const num = parseFloat(value);
        if (isNaN(num)) return 0n;
        // 转换为 wei（USDC 是 6 位小数）
        return BigInt(Math.round(num * Math.pow(10, decimals)));
      } catch {
        return 0n;
      }
    };

    // 辅助函数：将整数字符串转换为 BigInt（如 shares, fee）
    const intStringToBigInt = (value: string | undefined): bigint => {
      if (!value) return 0n;
      try {
        return BigInt(value);
      } catch {
        return 0n;
      }
    };

    const historicalEvents = (allOrders || []).map(order => {
      console.log('[allBetEvents] 处理历史订单:', order);
      return {
        user: order.user as `0x${string}`,
        outcomeId: BigInt(order.outcome),
        amount: stringToBigInt(order.amount), // 小数格式（如 "0.98"），转换为 wei
        shares: intStringToBigInt(order.shares), // 整数格式，直接转换
        fee: intStringToBigInt(order.fee), // 整数格式，直接转换
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

  // 自动刷新（包括 outcomes 和所有订单）
  useAutoRefresh(
    () => {
      refetchMarket();
      refetchOutcomes();
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

  // 监听下注成功后的全局刷新信号
  useEffect(() => {
    if (refreshCounter > 0) {
      console.log('[MarketDetailClient] 收到刷新信号，刷新详情页数据');
      refetchMarket();
      refetchOutcomes();
      refetchAllOrders();
      if (address) {
        refetchOrders();
      }
    }
  }, [refreshCounter, refetchMarket, refetchOutcomes, refetchAllOrders, refetchOrders, address]);

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
    if (!teamName) return t('common.tbd');
    // 提取前3个字母作为缩写
    return teamName.slice(0, 3).toUpperCase();
  };

  // 1. 加载状态（优先级最高）
  if (isLoading || outcomesLoading) {
    return (
      <div className="min-h-[50vh] bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text={t('markets.detail.loadingDetail')} />
      </div>
    );
  }

  // 2. 网络错误
  if (error) {
    return (
      <div className="min-h-[50vh] bg-dark-bg flex items-center justify-center">
        <ErrorState message={`${t('markets.detail.loadError')}: ${(error as Error).message || t('markets.errorLoading')}`} />
      </div>
    );
  }

  // 3. 市场不存在
  if (!market) {
    return (
      <div className="min-h-[50vh] bg-dark-bg flex items-center justify-center">
        <ErrorState message={t('markets.detail.notFound')} />
      </div>
    );
  }

  // 4. 合约数据加载失败
  if (!outcomes) {
    return (
      <div className="min-h-[50vh] bg-dark-bg flex items-center justify-center">
        <ErrorState message={t('markets.detail.oddsLoadError')} />
      </div>
    );
  }

  // 获取市场状态文本
  const getMarketStatusText = () => {
    if (market.state === MarketStatus.Finalized) return 'SETTLED';
    if (market.state === MarketStatus.Resolved) return 'RESOLVED';
    // 暂停状态也显示为 LOCKED
    if (market.state === MarketStatus.Locked || isMarketLocked || market.paused) return 'LOCKED';
    return 'OPEN';
  };

  const homeTeam = market._displayInfo?.homeTeam || 'Home';
  const awayTeam = market._displayInfo?.awayTeam || 'Away';
  const league = market._displayInfo?.league || 'League';

  // 处理 outcome 选择 - 调用全局 BetSlip store
  const handleSelectOutcome = (outcome: { id: number; name: string; odds: string }) => {
    const bet: SelectedBet = {
      marketAddress: marketId as `0x${string}`,
      marketId: marketId,
      homeTeam,
      awayTeam,
      league,
      outcomeId: outcome.id,
      outcomeName: outcome.name,
      odds: outcome.odds,
      templateType: market._displayInfo?.templateType || 'WDL',
      line: market.line ? parseInt(market.line) : undefined,
    };
    selectBet(bet);
  };

  return (
    <div className="bg-dark-bg">
      {/* Back Link */}
      <div className="px-6 py-4">
        <Link href="/markets" className="inline-flex items-center gap-1 text-gray-400 hover:text-white transition-colors">
          <ChevronLeft className="w-5 h-5" />
          {t('common.back')}
        </Link>
      </div>

      {/* Main Content */}
      <div className="px-6 pb-8">
          {/* Match Header */}
          <Card className="mb-6 bg-dark-card border border-dark-border" padding="lg">
            {/* Teams with VS */}
            <div className="flex items-center justify-center gap-4 mb-4">
              {/* Home Team */}
              <div className="flex-1 flex items-center justify-end gap-3">
                <span className="text-xl font-bold text-white">{translateTeam(homeTeam)}</span>
                <ShieldCheck className="w-10 h-10 text-accent" />
              </div>

              {/* VS */}
              <span className="text-gray-500 text-lg font-medium px-2">vs</span>

              {/* Away Team */}
              <div className="flex-1 flex items-center justify-start gap-3">
                <BadgeCheck className="w-10 h-10 text-gray-500" />
                <span className="text-xl font-bold text-white">{translateTeam(awayTeam)}</span>
              </div>
            </div>

            {/* League */}
            <p className="text-center text-gray-400 mb-4">{translateLeague(league)}</p>

            {/* Sport & Match Time */}
            <div className="flex items-center justify-center gap-4 text-sm text-gray-500 mb-4">
              <span className="flex-1 text-right">{t('markets.detail.sport')}: {t('markets.detail.soccer')}</span>
              <span className="text-gray-600 px-2">|</span>
              <span className="flex-1 text-left">{t('markets.detail.matchTime')}: {formatShortDate(market.kickoffTime)}</span>
            </div>

            {/* Market Type & Status */}
            <div className="flex items-center justify-center gap-4 pt-4 border-t border-dark-border text-sm text-gray-500 mb-4">
              <span className="flex-1 text-right flex items-center justify-end gap-2">
                {t('markets.detail.type')}:{' '}
                {market._displayInfo?.templateTypeDisplay
                  ? t(market._displayInfo.templateTypeDisplay)
                  : t('markets.unknown')}
                {market._displayInfo?.lineDisplay && (
                  <Badge variant="info" size="sm">{market._displayInfo.lineDisplay}</Badge>
                )}
              </span>
              <span className="text-gray-600 px-2">|</span>
              <span className="flex-1 text-left flex items-center gap-2">
                {t('markets.detail.status')}: {getStatusIndicator(market.state, market.paused)}
              </span>
            </div>

            {/* Liquidity & Contract Info */}
            <div className="flex items-center justify-center gap-4 pt-4 border-t border-dark-border text-sm">
              <div className="flex-1 flex items-center justify-end gap-2">
                <span className="text-gray-500">{t('markets.detail.liquidity')}:</span>
                <span className="text-white font-medium">{Number(market.totalVolume).toFixed(2)} USDC</span>
              </div>
              <span className="text-gray-600 px-2">|</span>
              <div className="flex-1 flex items-center justify-start gap-2">
                <span className="text-gray-500">{t('markets.detail.contract')}:</span>
                <span className="text-gray-400 font-mono">{marketId.slice(0, 6)}...{marketId.slice(-4)}</span>
                <button
                  onClick={() => {
                    navigator.clipboard.writeText(marketId);
                    notifySuccess(t('common.copied'));
                  }}
                  className="text-gray-500 hover:text-white transition-colors"
                >
                  <Copy className="w-4 h-4" />
                </button>
              </div>
            </div>
          </Card>

          {/* Winner Section */}
          <Card className="mb-6 bg-dark-card border border-dark-border" padding="lg">
            {/* 三列布局标题 */}
            <div className="grid grid-cols-3 gap-2 mb-4">
              {/* 第一列：Resolved Hash */}
              <div className="text-left text-gray-400 text-sm font-medium tracking-wider">
                {t('markets.detail.resolvedHash')}: {market.finalizedTxHash ? (
                  <a
                    href={getTxExplorerUrl(market.finalizedTxHash)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="underline hover:text-white"
                  >
                    {formatTxHash(market.finalizedTxHash)}
                  </a>
                ) : '--'}
              </div>
              {/* 第二列：WINNER */}
              <div className="text-center text-gray-400 text-lg font-medium uppercase tracking-wider">
                WINNER
              </div>
              {/* 第三列：空 */}
              <div></div>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {(() => {
                // 二级防护：根据市场类型限制显示的 outcomes 数量
                const getExpectedOutcomeCount = (type: string): number | null => {
                  switch (type) {
                    case 'WDL': return 3;
                    case 'OU': return 2;
                    case 'AH': return 3;
                    case 'OddEven': return 2;
                    default: return null;
                  }
                };
                const templateType = market._displayInfo?.templateType || 'WDL';
                const expectedCount = getExpectedOutcomeCount(templateType);
                const displayOutcomes = expectedCount
                  ? outcomes.slice(0, expectedCount)
                  : outcomes;

                // Check if market is settled
                const isMarketSettled = market.state === MarketStatus.Resolved ||
                                        market.state === MarketStatus.Finalized;

                return displayOutcomes.map((outcome) => (
                  <OutcomeButton
                    key={outcome.id}
                    outcome={{
                      id: outcome.id,
                      name: outcome.name,
                      odds: outcome.odds,
                    }}
                    isSelected={isSelected(marketId as `0x${string}`, outcome.id)}
                    isDisabled={!canBet}
                    isWinner={isMarketSettled && market.winnerOutcome === outcome.id}
                    onClick={() => handleSelectOutcome({
                      id: outcome.id,
                      name: outcome.name,
                      odds: outcome.odds,
                    })}
                    variant="detail"
                  />
                ));
              })()}
            </div>
          </Card>

          {/* Activity Section */}
          <Card className="bg-dark-card border border-dark-border" padding="none">
            <h3 className="text-center text-gray-400 text-sm font-medium tracking-wider py-4 border-b border-dark-border">
              {t('markets.detail.activity')}
            </h3>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-dark-hover/50 border-b border-dark-border">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.time')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.owner')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.selected')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.paid')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.payout')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.txHash')}</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-400 whitespace-nowrap">{t('markets.detail.status')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-dark-border">
                  {allBetEvents.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="px-4 py-8 text-center text-gray-500">
                        {t('markets.detail.noActivity')}
                      </td>
                    </tr>
                  ) : (
                    allBetEvents.slice(0, 20).map((event, idx) => {
                      const amountUSDC = Number(event.amount) / 1e6;
                      const payoutUSDC = Number(event.shares) / 1e6;
                      const outcomeKey = outcomes[Number(event.outcomeId)]?.name;
                      const outcomeName = outcomeKey ? t(outcomeKey) : `${t('markets.detail.outcomeLabel')} ${event.outcomeId}`;

                      return (
                        <tr key={event.transactionHash || idx} className="hover:bg-dark-hover">
                          <td className="px-4 py-3 text-sm text-gray-400 whitespace-nowrap">
                            {formatShortDate(event.timestamp / 1000)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-400 font-mono whitespace-nowrap">
                            {truncateAddress(event.user)}
                          </td>
                          <td className="px-4 py-3 text-sm text-white font-medium whitespace-nowrap">
                            {getTeamAbbr(homeTeam)} - {outcomeName}
                          </td>
                          <td className="px-4 py-3 text-sm text-white whitespace-nowrap">
                            ${amountUSDC.toFixed(2)}
                          </td>
                          <td className="px-4 py-3 text-sm text-white whitespace-nowrap">
                            ${payoutUSDC.toFixed(2)}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-400 font-mono whitespace-nowrap">
                            {event.transactionHash ? (
                              <a
                                href={`https://basescan.org/tx/${event.transactionHash}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="hover:text-accent transition-colors"
                              >
                                {truncateAddress(event.transactionHash)}
                              </a>
                            ) : '--'}
                          </td>
                          <td className="px-4 py-3 text-sm text-gray-400 whitespace-nowrap">
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
    </div>
  );
}
