"use client";

import { useState, useEffect, useMemo, useCallback } from "react";
import { formatUnits } from "viem";
import { X } from "lucide-react";
import { useQueryClient } from "@tanstack/react-query";
import {
  useAccount,
  usePlaceBet,
  useApproveUSDC,
  useUSDCAllowance,
  useUSDCBalance,
  useMarketFullData,
} from "@pitchone/web3";
import { getContractAddresses } from "@pitchone/contracts";
import { Card, Button } from "@pitchone/ui";
import { useTranslation } from "@pitchone/i18n";
import { useBetSlipStore } from "../../lib/betslip-store";
import { BetSlipEmpty } from "./BetSlipEmpty";
import { betNotifications } from "@/lib/notifications";

interface BetSlipProps {
  className?: string;
}

export function BetSlip({ className }: BetSlipProps) {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const { selectedBet, clearBet } = useBetSlipStore();
  const { address, isConnected, chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 避免水合不匹配：延迟渲染客户端特定 UI
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  const [betAmount, setBetAmount] = useState("");
  const [needsApproval, setNeedsApproval] = useState(false);
  const [approveToastId, setApproveToastId] = useState<string | null>(null);
  const [betToastId, setBetToastId] = useState<string | null>(null);

  // Get market full data for payout calculation
  const { data: marketFullData } = useMarketFullData(
    selectedBet?.marketAddress,
    address
  );

  // Contract interaction hooks
  const { data: usdcBalance } = useUSDCBalance(address as `0x${string}`);
  // 重要：用户需要授权给 BettingRouter，而不是市场地址
  // 因为下注是通过 BettingRouter.placeBet() 进行的
  const {
    data: allowance,
    refetch: refetchAllowance,
    isLoading: isAllowanceLoading,
    error: allowanceError,
  } = useUSDCAllowance(address as `0x${string}`, addresses?.bettingRouter);

  const {
    approve,
    isPending: isApproving,
    isConfirming: isApprovingConfirming,
    isSuccess: isApproved,
    error: approveError,
  } = useApproveUSDC();

  const {
    placeBet,
    isPending: isBetting,
    isConfirming: isBettingConfirming,
    isSuccess: isBetSuccess,
    error: betError,
  } = usePlaceBet(selectedBet?.marketAddress);

  // 格式化余额
  const formattedBalance =
    usdcBalance !== undefined &&
    usdcBalance !== null &&
    typeof usdcBalance === "bigint"
      ? parseFloat(formatUnits(usdcBalance, 6)).toFixed(2)
      : "--";

  // 检查余额是否不足
  const insufficientBalance = useMemo(() => {
    if (!betAmount || parseFloat(betAmount) <= 0) return false;
    if (usdcBalance === undefined || usdcBalance === null) return false;
    if (typeof usdcBalance !== "bigint") return false;

    const amountInWei = BigInt(Math.floor(parseFloat(betAmount) * 1e6));
    return usdcBalance < amountInWei;
  }, [betAmount, usdcBalance]);

  // Reset amount when bet changes
  useEffect(() => {
    setBetAmount("");
  }, [selectedBet?.marketAddress, selectedBet?.outcomeId]);

  // Check if needs approval
  // 优化：提前检查授权状态，如果用户已授权 BettingRouter，直接显示 Trade 按钮
  useEffect(() => {
    // 如果查询出错，假设需要授权
    if (allowanceError) {
      setNeedsApproval(true);
      return;
    }

    // 如果还没有授权数据，等待查询完成
    if (allowance === undefined || allowance === null) {
      return;
    }

    if (typeof allowance === "bigint") {
      // 如果用户输入了金额，检查是否足够
      if (betAmount && parseFloat(betAmount) > 0) {
        const amountInWei = BigInt(Math.floor(parseFloat(betAmount) * 1e6));
        setNeedsApproval(allowance < amountInWei);
      } else {
        // 没有输入金额时，检查是否有任何授权
        // 如果授权额度 > 0（通常是 max），认为已授权
        // 使用 1 USDC (1e6) 作为最小阈值
        const minThreshold = BigInt(1e6);
        setNeedsApproval(allowance < minThreshold);
      }
    }
  }, [betAmount, allowance, allowanceError]);

  // Handle approve toast notifications
  useEffect(() => {
    if (isApproving && !approveToastId) {
      const toastId = betNotifications.approvingUSDC();
      setApproveToastId(toastId);
    }
  }, [isApproving, approveToastId]);

  useEffect(() => {
    if (approveError && approveToastId) {
      betNotifications.approveFailed(
        approveToastId,
        approveError.message || "Approval failed"
      );
      setApproveToastId(null);
    }
  }, [approveError, approveToastId]);

  useEffect(() => {
    if (isApproved && approveToastId) {
      betNotifications.approvedUSDC(approveToastId);
      setApproveToastId(null);
      refetchAllowance();
    }
  }, [isApproved, approveToastId, refetchAllowance]);

  // Handle bet toast notifications
  useEffect(() => {
    if (isBetting && !betToastId) {
      const toastId = betNotifications.placingBet();
      setBetToastId(toastId);
    }
  }, [isBetting, betToastId]);

  useEffect(() => {
    if (betError && betToastId) {
      let errorMessage = "Transaction failed";
      if (betError.message?.includes("nonce")) {
        errorMessage =
          "Transaction nonce conflict, please clear wallet history and retry";
      } else if (betError.message) {
        const shortMessage = betError.message.split("\n")[0];
        errorMessage =
          shortMessage.length > 100
            ? shortMessage.substring(0, 100) + "..."
            : shortMessage;
      }
      betNotifications.betFailed(betToastId, errorMessage);
      setBetToastId(null);
    }
  }, [betError, betToastId]);

  useEffect(() => {
    if (isBetSuccess && betToastId && selectedBet) {
      betNotifications.betPlaced(
        betToastId,
        betAmount,
        selectedBet.outcomeName
      );
      setBetToastId(null);
      setBetAmount("");
      clearBet();

      // 延迟刷新市场数据，等待 Subgraph 索引新的下注数据
      // 第一次刷新：2秒后（快速反馈）
      // 第二次刷新：5秒后（确保 Subgraph 完成索引）
      const refreshMarketData = () => {
        queryClient.invalidateQueries({ queryKey: ['markets'] });
        queryClient.invalidateQueries({ queryKey: ['marketOutcomesSubgraph'] });
        queryClient.invalidateQueries({ queryKey: ['userPositions'] });
      };

      const timer1 = setTimeout(refreshMarketData, 2000);
      const timer2 = setTimeout(refreshMarketData, 5000);

      return () => {
        clearTimeout(timer1);
        clearTimeout(timer2);
      };
    }
  }, [isBetSuccess, betToastId, selectedBet, betAmount, clearBet, queryClient]);

  // Calculate expected payout
  const calculatePayout = () => {
    if (!betAmount || !selectedBet || !marketFullData) return "0.00";

    const amount = parseFloat(betAmount);
    if (isNaN(amount) || amount <= 0) return "0.00";

    // 防御性检查：feeRate 可能未定义
    const feeRate = marketFullData.feeRate ? Number(marketFullData.feeRate) / 10000 : 0;
    const netAmount = amount * (1 - feeRate);

    // 检查 outcomeId 是否有效
    const outcomeId = selectedBet.outcomeId;
    if (outcomeId < 0 || outcomeId >= marketFullData.outcomeLiquidity.length) {
      return "0.00";
    }

    if (marketFullData.isParimutel) {
      const newTotalPool = Number(marketFullData.totalLiquidity || 0n) + amount * 1e6;
      const currentOutcomeBets = Number(
        marketFullData.outcomeLiquidity[outcomeId] || 0n
      );
      const newOutcomeBets = currentOutcomeBets + amount * 1e6;
      const netPool = newTotalPool * (1 - feeRate);

      if (newOutcomeBets > 0) {
        const payout = (netPool * (amount * 1e6)) / newOutcomeBets;
        return (payout / 1e6).toFixed(2);
      }
      return "0.00";
    } else {
      const outcomeCount = Number(marketFullData.outcomeCount);
      const reserves = marketFullData.outcomeLiquidity.map((r: bigint) =>
        Number(r || 0n)
      );
      let shares = 0;

      if (outcomeCount === 2) {
        const r_target = reserves[outcomeId] || 0;
        const r_other = reserves[1 - outcomeId] || 0;
        if (r_target === 0 || r_other === 0) {
          // 使用赔率作为后备
          const odds = parseFloat(selectedBet.odds);
          return isNaN(odds) ? "0.00" : (netAmount * odds).toFixed(2);
        }
        const k = r_target * r_other;
        const r_other_new = r_other + netAmount * 1e6;
        const r_target_new = k / r_other_new;
        shares = r_target - r_target_new;
      } else if (outcomeCount === 3) {
        const r_target = reserves[outcomeId] || 0;
        let opponent_total = 0;
        for (let i = 0; i < 3; i++) {
          if (i !== outcomeId) {
            opponent_total += reserves[i] || 0;
          }
        }
        if (r_target === 0 || opponent_total === 0) {
          // 使用赔率作为后备
          const odds = parseFloat(selectedBet.odds);
          return isNaN(odds) ? "0.00" : (netAmount * odds).toFixed(2);
        }
        const k_approx = r_target * opponent_total;
        const opponent_total_new = opponent_total + netAmount * 1e6;
        const r_target_new = k_approx / opponent_total_new;
        shares = r_target - r_target_new;
      } else {
        // Multi-outcome markets: use current odds as approximation
        const odds = parseFloat(selectedBet.odds);
        return isNaN(odds) ? "0.00" : (netAmount * odds).toFixed(2);
      }

      // 最终检查
      if (isNaN(shares) || shares < 0) {
        const odds = parseFloat(selectedBet.odds);
        return isNaN(odds) ? "0.00" : (netAmount * odds).toFixed(2);
      }

      return (shares / 1e6).toFixed(2);
    }
  };

  const handleApprove = async () => {
    // 授权给 BettingRouter，而不是市场地址
    if (!addresses?.bettingRouter) return;
    try {
      await approve(addresses.bettingRouter, "max");
    } catch (error: unknown) {
      console.error("Approve error:", error);
      if (approveToastId) {
        const errorMessage =
          error instanceof Error ? error.message : "Unknown error";
        betNotifications.approveFailed(approveToastId, errorMessage);
        setApproveToastId(null);
      }
    }
  };

  const handlePlaceBet = async () => {
    if (!isConnected || !selectedBet || !betAmount) return;
    try {
      await placeBet(selectedBet.outcomeId, betAmount);
    } catch (error: unknown) {
      console.error("Place bet error:", error);
      if (betToastId) {
        const errorMessage =
          error instanceof Error ? error.message : "Unknown error";
        betNotifications.betFailed(betToastId, errorMessage);
        setBetToastId(null);
      }
    }
  };

  const handleClear = () => {
    clearBet();
    setBetAmount("");
  };

  return (
    <Card
      className={`p-0 bg-dark-card border border-dark-border ${
        className || ""
      }`}
    >
      {/* 头部 - 始终显示 */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-dark-border">
        <h3 className="text-base font-bold text-white tracking-wide">
          {t("betslip.title")}
        </h3>
        <div className="flex items-center gap-2">
          <div
            className={`w-2 h-2 rounded-full ${
              mounted && isConnected ? "bg-green-500" : "bg-zinc-500"
            }`}
          />
          <span className="text-sm text-zinc-400">{formattedBalance} USDC</span>
        </div>
      </div>

      <div className="">
        {/* 内容 - 根据状态切换 */}
        {selectedBet ? (
          <>
            {/* 选中投注卡片 */}
            <div className="border border-zinc-700 rounded-lg p-3 m-4">
              {/* 卡片第1行：比赛信息 + 关闭按钮 */}
              <div className="flex items-center justify-between mb-3">
                <p className="text-sm text-zinc-400">
                  {selectedBet.homeTeam} vs {selectedBet.awayTeam}
                </p>
                <button
                  onClick={handleClear}
                  className="text-zinc-500 hover:text-white transition-colors"
                >
                  <X className="w-4 h-4" strokeWidth={2} />
                </button>
              </div>

              {/* 卡片第2行：选中结果徽章 + 金额输入（并排） */}
              <div className="flex items-center gap-2 mb-3">
                {/* 结果徽章 */}
                <div className="flex-shrink-0 px-3 py-1.5 bg-zinc-700 rounded">
                  <span className="text-sm font-semibold text-white whitespace-nowrap">
                    {selectedBet.outcomeName.startsWith('outcomes.')
                      ? t(selectedBet.outcomeName, { id: selectedBet.outcomeId })
                      : selectedBet.outcomeName} {selectedBet.odds}
                  </span>
                </div>
                {/* 金额输入 */}
                <div className="flex-1 min-w-0 flex items-center border border-zinc-700 rounded bg-zinc-900 focus-within:border-white/40 overflow-hidden">
                  <input
                    type="number"
                    placeholder={t("betslip.enterAmount")}
                    value={betAmount}
                    onChange={(e) => setBetAmount(e.target.value)}
                    min="1"
                    max="10000"
                    className="flex-1 min-w-0 px-2 py-1.5 bg-transparent text-white placeholder-zinc-500 focus:outline-none text-sm"
                  />
                  <span className="flex-shrink-0 px-2 py-1.5 text-xs text-zinc-400">
                    USDC
                  </span>
                </div>
              </div>

              {/* 卡片第3行：流动性 + 潜在收益 */}
              <div className="flex items-center justify-between text-xs text-zinc-500">
                <span>
                  {t("betslip.liquidity")}:{" "}
                  <span className="text-zinc-300">
                    {marketFullData
                      ? (Number(marketFullData.totalLiquidity) / 1e6).toFixed(2)
                      : "--"}
                  </span>{" "}
                  USDC
                </span>
                <span>
                  {t("betslip.potentialWin")}:{" "}
                  <span className="text-zinc-300">
                    {betAmount && parseFloat(betAmount) > 0
                      ? calculatePayout()
                      : "--"}
                  </span>{" "}
                  USDC
                </span>
              </div>

              {/* 余额不足警告 */}
              {insufficientBalance && (
                <p className="text-red-400 text-xs mt-2">
                  {t("betslip.insufficientBalance")}
                </p>
              )}
            </div>

            {/* 分割线 */}
            <div className="border-t border-zinc-700" />

            <div className="p-4">
              {/* 汇总信息 */}
              <div className="space-y-2 mb-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-zinc-400">
                    {t("betslip.totalPayment")}
                  </span>
                  <span className="text-white font-semibold">
                    {betAmount && parseFloat(betAmount) > 0
                      ? parseFloat(betAmount).toFixed(2)
                      : "--"}{" "}
                    USDC
                  </span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-zinc-400">
                    {t("betslip.totalPotentialWin")}
                  </span>
                  <span className="text-white font-semibold">
                    {betAmount && parseFloat(betAmount) > 0
                      ? calculatePayout()
                      : "--"}{" "}
                    USDC
                  </span>
                </div>
              </div>

              {/* 操作按钮 */}
              {needsApproval ? (
                <Button
                  variant="primary"
                  fullWidth
                  onClick={handleApprove}
                  disabled={
                    !betAmount ||
                    parseFloat(betAmount) < 1 ||
                    insufficientBalance ||
                    isApproving ||
                    isApprovingConfirming ||
                    isAllowanceLoading
                  }
                  isLoading={
                    isApproving || isApprovingConfirming || isAllowanceLoading
                  }
                >
                  {insufficientBalance
                    ? t("betslip.insufficientBalance")
                    : isApproving || isApprovingConfirming
                    ? t("betslip.approving")
                    : isAllowanceLoading
                    ? t("betslip.checking")
                    : t("betslip.approveUSDC")}
                </Button>
              ) : (
                <Button
                  variant="primary"
                  fullWidth
                  onClick={handlePlaceBet}
                  disabled={
                    !isConnected ||
                    !betAmount ||
                    parseFloat(betAmount) < 1 ||
                    insufficientBalance ||
                    isBetting ||
                    isBettingConfirming
                  }
                  isLoading={isBetting || isBettingConfirming}
                >
                  {!isConnected
                    ? t("betslip.connectWallet")
                    : insufficientBalance
                    ? t("betslip.insufficientBalance")
                    : isBetting || isBettingConfirming
                    ? t("betslip.trading")
                    : t("betslip.trade")}
                </Button>
              )}

              {/* 条款文字 */}
              <p className="text-xs text-zinc-500 text-center mt-3">
                {t("betslip.termsText")} {t("betslip.termsLink")}.
              </p>
            </div>
          </>
        ) : (
          <BetSlipEmpty />
        )}
      </div>
    </Card>
  );
}
