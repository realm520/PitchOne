'use client';

import { useState, useMemo } from 'react';
import {
  useParlayQuote,
  useCreateParlay,
  useApproveUSDC,
  useUSDCAllowance,
  useAccount,
  type ParlayLeg,
  TOKEN_DECIMALS,
} from '@pitchone/web3';
import { getContractAddresses, type Address } from '@pitchone/contracts';
import { Card, Button, Input, LoadingSpinner } from '@pitchone/ui';
import { parseUnits } from 'viem';

export interface SelectedOutcome {
  marketAddress: Address;
  marketName: string; // 如 "MUN vs CHE"
  outcomeId: number;
  outcomeName: string; // 如 "Home Win"
  odds: string; // 如 "2.5x"
}

export interface ParlayBuilderProps {
  selectedOutcomes: SelectedOutcome[];
  onRemoveOutcome: (marketAddress: Address) => void;
  onClearAll: () => void;
  onSuccess?: () => void;
}

/**
 * 串关构建器组件
 * 允许用户选择多个市场结果并创建串关
 */
export function ParlayBuilder({
  selectedOutcomes,
  onRemoveOutcome,
  onClearAll,
  onSuccess,
}: ParlayBuilderProps) {
  const { address, chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const [stakeAmount, setStakeAmount] = useState('');

  // 构建串关腿数据
  const legs: ParlayLeg[] = useMemo(
    () =>
      selectedOutcomes.map((outcome) => ({
        marketAddress: outcome.marketAddress,
        outcomeId: outcome.outcomeId,
      })),
    [selectedOutcomes]
  );

  // 获取报价
  const {
    quote,
    formattedOdds,
    formattedPayout,
    penaltyPercentage,
    isLoading: isQuoteLoading,
    isError: isQuoteError,
    error: quoteError,
  } = useParlayQuote(legs.length >= 2 ? legs : undefined, stakeAmount || undefined);

  // USDC 授权
  const { data: allowance } = useUSDCAllowance(address, addresses?.basket);
  const { approve, isPending: isApproving } = useApproveUSDC();

  // 创建串关
  const { createParlay, isPending, isConfirming, isSuccess, error } = useCreateParlay();

  // 检查是否需要授权
  const needsApproval = useMemo(() => {
    if (!stakeAmount || !allowance) return false;
    const stakeInWei = parseUnits(stakeAmount, TOKEN_DECIMALS.USDC);
    return allowance < stakeInWei;
  }, [stakeAmount, allowance]);

  // 处理创建串关
  const handleCreateParlay = async () => {
    if (!stakeAmount || legs.length < 2) return;

    try {
      // 先检查是否需要授权
      if (needsApproval && addresses) {
        await approve(addresses.basket, stakeAmount);
        return;
      }

      // 创建串关
      await createParlay(legs, stakeAmount);
    } catch (err) {
      console.error('创建串关失败:', err);
    }
  };

  // 成功后重置
  if (isSuccess && onSuccess) {
    setTimeout(() => {
      setStakeAmount('');
      onSuccess();
    }, 1000);
  }

  // 验证
  const canCreateParlay =
    legs.length >= 2 &&
    legs.length <= 10 &&
    stakeAmount &&
    parseFloat(stakeAmount) > 0 &&
    !isQuoteError;

  const buttonText = needsApproval
    ? isApproving
      ? '授权中...'
      : `授权 USDC`
    : isPending || isConfirming
    ? '创建中...'
    : '创建串关';

  return (
    <Card variant="neon" className="w-full max-w-2xl">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold text-white">
            串关构建器 ({legs.length} 场)
          </h2>
          {legs.length > 0 && (
            <Button variant="ghost" size="sm" onClick={onClearAll}>
              清空
            </Button>
          )}
        </div>

        {/* 选中的结果列表 */}
        {legs.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            <p className="text-lg">请至少选择 2 场比赛进行串关</p>
            <p className="text-sm mt-2">串关将组合多场比赛的赔率，全中才赢！</p>
          </div>
        ) : (
          <div className="space-y-3">
            {selectedOutcomes.map((outcome, index) => (
              <div
                key={outcome.marketAddress}
                className="flex items-center justify-between p-4 bg-dark-bg rounded-lg border border-dark-border hover:border-neon-blue/50 transition-colors"
              >
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-neon-blue font-mono text-sm">#{index + 1}</span>
                    <span className="text-white font-semibold">{outcome.marketName}</span>
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-gray-400 text-sm">{outcome.outcomeName}</span>
                    <span className="text-neon-green text-sm font-mono">@ {outcome.odds}</span>
                  </div>
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => onRemoveOutcome(outcome.marketAddress)}
                  className="text-red-400 hover:text-red-300"
                >
                  移除
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* 下注金额输入 */}
        {legs.length >= 2 && (
          <div className="space-y-4">
            <Input
              label="下注金额 (USDC)"
              type="number"
              placeholder="0.00"
              value={stakeAmount}
              onChange={(e) => setStakeAmount(e.target.value)}
              min="0"
              step="0.01"
            />

            {/* 报价信息 */}
            {isQuoteLoading && (
              <div className="flex items-center justify-center py-4">
                <LoadingSpinner size="sm" />
                <span className="ml-2 text-gray-400">计算中...</span>
              </div>
            )}

            {quote && stakeAmount && (
              <div className="bg-dark-bg rounded-lg p-4 space-y-2 border border-neon-blue/30">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">组合赔率</span>
                  <span className="text-neon-green font-bold text-lg">{formattedOdds}</span>
                </div>
                {Number(penaltyPercentage?.replace('%', '')) > 0 && (
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">相关性惩罚</span>
                    <span className="text-orange-400 font-mono text-sm">-{penaltyPercentage}</span>
                  </div>
                )}
                <div className="flex justify-between items-center pt-2 border-t border-dark-border">
                  <span className="text-white font-semibold">潜在赔付</span>
                  <span className="text-neon-blue font-bold text-xl">{formattedPayout} USDC</span>
                </div>
              </div>
            )}

            {isQuoteError && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4">
                <p className="text-red-400 text-sm">
                  {quoteError?.message || '无法获取报价，请检查选择的市场'}
                </p>
              </div>
            )}

            {error && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4">
                <p className="text-red-400 text-sm">
                  {error.message || '创建串关失败'}
                </p>
              </div>
            )}

            {isSuccess && (
              <div className="bg-green-500/10 border border-green-500/30 rounded-lg p-4">
                <p className="text-green-400 text-sm font-semibold">
                  ✓ 串关创建成功！
                </p>
              </div>
            )}
          </div>
        )}

        {/* 创建按钮 */}
        <Button
          onClick={handleCreateParlay}
          disabled={!canCreateParlay || isPending || isConfirming || isApproving}
          className="w-full"
          size="lg"
          variant="primary"
        >
          {buttonText}
        </Button>

        {/* 提示信息 */}
        <div className="text-xs text-gray-500 space-y-1">
          <p>• 串关要求：2-10 场比赛</p>
          <p>• 全部正确才能获得赔付，任一错误全输</p>
          <p>• 相关性惩罚：同一比赛或相关比赛可能会降低赔率</p>
        </div>
      </div>
    </Card>
  );
}
