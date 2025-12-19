'use client';

import { useMemo } from 'react';
import {
  useParlayDetails,
  useCanSettle,
  useSettleParlay,
  ParlayStatus,
} from '@pitchone/web3';
import { Card, Button, LoadingSpinner, ErrorState } from '@pitchone/ui';
import { formatUnits } from 'viem';
import { cn } from '@pitchone/utils';
import { useTranslation } from '@pitchone/i18n';

export interface ParlayCardProps {
  parlayId: number;
  compact?: boolean;
}

/**
 * Parlay card component
 * Displays single parlay details and status
 */
export function ParlayCard({ parlayId, compact = false }: ParlayCardProps) {
  const { t } = useTranslation();
  const { parlay, isLoading, isError, error } = useParlayDetails(parlayId);
  const { canSettle, status: expectedStatus } = useCanSettle(parlayId);
  const { settle, isPending: isSettling, isSuccess: isSettled } = useSettleParlay();

  // 状态标签样式
  const statusBadge = useMemo(() => {
    if (!parlay) return null;

    const badges = {
      [ParlayStatus.Pending]: {
        label: '待结算',
        className: 'bg-zinc-700 text-zinc-300 border-zinc-500',
      },
      [ParlayStatus.Won]: {
        label: '赢',
        className: 'bg-zinc-800 text-white border-zinc-500',
      },
      [ParlayStatus.Lost]: {
        label: '输',
        className: 'bg-zinc-800 text-zinc-400 border-dashed border-zinc-600',
      },
      [ParlayStatus.Cancelled]: {
        label: '已取消',
        className: 'bg-zinc-800 text-zinc-500 border-zinc-600',
      },
    };

    return badges[parlay.status];
  }, [parlay]);

  // 处理结算
  const handleSettle = async () => {
    try {
      await settle(parlayId);
    } catch (err) {
      console.error('结算失败:', err);
    }
  };

  if (isLoading) {
    return (
      <Card className="w-full">
        <div className="flex items-center justify-center py-8">
          <LoadingSpinner />
        </div>
      </Card>
    );
  }

  if (isError || !parlay) {
    return (
      <Card className="w-full">
        <ErrorState
          title={t('common.error')}
          message={error?.message || t('parlay.loadParlayError')}
        />
      </Card>
    );
  }

  const formattedStake = formatUnits(parlay.stake, 6);
  const formattedPayout = formatUnits(parlay.potentialPayout, 6);
  const formattedOdds = (Number(formatUnits(parlay.combinedOdds, 4))).toFixed(2) + 'x';
  const penalty = Number(formatUnits(parlay.penaltyBps, 2));

  return (
    <Card
      variant="neon"
      className={cn(
        'w-full',
        parlay.status === ParlayStatus.Won && 'border-white/30',
        parlay.status === ParlayStatus.Lost && 'border-zinc-600 border-dashed'
      )}
    >
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <h3 className="text-lg font-bold text-white">串关 #{parlayId}</h3>
            {statusBadge && (
              <span
                className={cn(
                  'px-3 py-1 rounded-full text-xs font-semibold border',
                  statusBadge.className
                )}
              >
                {statusBadge.label}
              </span>
            )}
          </div>
          <div className="text-right">
            <div className="text-sm text-gray-400">
              {new Date(Number(parlay.createdAt) * 1000).toLocaleDateString('zh-CN')}
            </div>
            <div className="text-xs text-gray-500">
              {parlay.legs.length} 场串关
            </div>
          </div>
        </div>

        {/* 串关腿列表 */}
        {!compact && (
          <div className="space-y-2">
            <div className="text-sm font-semibold text-gray-400">选择的比赛：</div>
            {parlay.legs.map((leg, index) => (
              <div
                key={index}
                className="flex items-center justify-between p-3 bg-dark-bg rounded-lg border border-dark-border"
              >
                <div className="flex items-center gap-2">
                  <span className="text-white font-mono text-sm">#{index + 1}</span>
                  <span className="text-white text-sm font-mono">
                    {leg.marketAddress.slice(0, 6)}...{leg.marketAddress.slice(-4)}
                  </span>
                </div>
                <span className="text-gray-400 text-sm">
                  结果 {leg.outcomeId}
                </span>
              </div>
            ))}
          </div>
        )}

        {/* 金额信息 */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-dark-bg rounded-lg p-4 border border-dark-border">
            <div className="text-sm text-gray-400 mb-1">下注金额</div>
            <div className="text-xl font-bold text-white">{formattedStake} USDC</div>
          </div>
          <div className="bg-dark-bg rounded-lg p-4 border border-white/20">
            <div className="text-sm text-gray-400 mb-1">潜在赔付</div>
            <div className="text-xl font-bold text-white">{formattedPayout} USDC</div>
          </div>
        </div>

        {/* 赔率信息 */}
        <div className="flex items-center justify-between p-4 bg-dark-bg rounded-lg border border-dark-border">
          <div>
            <div className="text-sm text-gray-400">组合赔率</div>
            <div className="text-2xl font-bold text-white">{formattedOdds}</div>
          </div>
          {penalty > 0 && (
            <div className="text-right">
              <div className="text-sm text-gray-400">相关性惩罚</div>
              <div className="text-lg font-semibold text-zinc-400">-{penalty.toFixed(2)}%</div>
            </div>
          )}
        </div>

        {/* 结算按钮 */}
        {canSettle && parlay.status === ParlayStatus.Pending && (
          <Button
            onClick={handleSettle}
            disabled={isSettling}
            className="w-full"
            variant="primary"
          >
            {isSettling ? '结算中...' : '立即结算'}
          </Button>
        )}

        {isSettled && (
          <div className="bg-zinc-800 border border-zinc-600 rounded-lg p-3">
            <p className="text-white text-sm font-semibold text-center">
              ✓ 结算成功！
            </p>
          </div>
        )}

        {/* 结算时间 */}
        {parlay.status !== ParlayStatus.Pending && parlay.settledAt > 0n && (
          <div className="text-xs text-gray-500 text-center">
            结算于 {new Date(Number(parlay.settledAt) * 1000).toLocaleString('zh-CN')}
          </div>
        )}
      </div>
    </Card>
  );
}
