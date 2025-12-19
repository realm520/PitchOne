'use client';

import { useState, useEffect } from 'react';
import { formatUnits } from 'viem';
import {
  useAccount,
  usePlaceBet,
  useApproveUSDC,
  useUSDCAllowance,
  useUSDCBalance,
  useMarketFullData,
} from '@pitchone/web3';
import { Card, Button } from '@pitchone/ui';
import { useBetSlipStore, SelectedBet } from '../../lib/betslip-store';
import { BetSlipEmpty } from './BetSlipEmpty';
import { betNotifications } from '@/lib/notifications';

interface BetSlipProps {
  className?: string;
}

export function BetSlip({ className }: BetSlipProps) {
  const { selectedBet, clearBet } = useBetSlipStore();
  const { address, isConnected } = useAccount();

  const [betAmount, setBetAmount] = useState('');
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
  const {
    data: allowance,
    refetch: refetchAllowance,
    isLoading: isAllowanceLoading,
    error: allowanceError,
  } = useUSDCAllowance(address as `0x${string}`, selectedBet?.marketAddress);

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

  // Reset amount when bet changes
  useEffect(() => {
    setBetAmount('');
  }, [selectedBet?.marketAddress, selectedBet?.outcomeId]);

  // Check if needs approval
  useEffect(() => {
    if (!betAmount) {
      setNeedsApproval(false);
      return;
    }

    if (allowanceError) {
      setNeedsApproval(true);
      return;
    }

    if (allowance !== undefined && allowance !== null && typeof allowance === 'bigint') {
      const amountInWei = BigInt(parseFloat(betAmount) * 1e6);
      setNeedsApproval(allowance < amountInWei);
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
      betNotifications.approveFailed(approveToastId, approveError.message || 'Approval failed');
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
      let errorMessage = 'Transaction failed';
      if (betError.message?.includes('nonce')) {
        errorMessage = 'Transaction nonce conflict, please clear wallet history and retry';
      } else if (betError.message) {
        const shortMessage = betError.message.split('\n')[0];
        errorMessage = shortMessage.length > 100 ? shortMessage.substring(0, 100) + '...' : shortMessage;
      }
      betNotifications.betFailed(betToastId, errorMessage);
      setBetToastId(null);
    }
  }, [betError, betToastId]);

  useEffect(() => {
    if (isBetSuccess && betToastId && selectedBet) {
      betNotifications.betPlaced(betToastId, betAmount, selectedBet.outcomeName);
      setBetToastId(null);
      setBetAmount('');
      clearBet();
    }
  }, [isBetSuccess, betToastId, selectedBet, betAmount, clearBet]);

  // Calculate expected payout
  const calculatePayout = () => {
    if (!betAmount || !selectedBet || !marketFullData) return '0.00';

    const amount = parseFloat(betAmount);
    const feeRate = Number(marketFullData.feeRate) / 10000;
    const netAmount = amount * (1 - feeRate);

    if (marketFullData.isParimutel) {
      const newTotalPool = Number(marketFullData.totalLiquidity) + amount * 1e6;
      const currentOutcomeBets = Number(marketFullData.outcomeLiquidity[selectedBet.outcomeId]);
      const newOutcomeBets = currentOutcomeBets + amount * 1e6;
      const netPool = newTotalPool * (1 - feeRate);

      if (newOutcomeBets > 0) {
        const payout = (netPool * (amount * 1e6)) / newOutcomeBets;
        return (payout / 1e6).toFixed(2);
      }
      return '0.00';
    } else {
      const outcomeCount = Number(marketFullData.outcomeCount);
      const reserves = marketFullData.outcomeLiquidity.map((r: bigint) => Number(r));
      let shares = 0;

      if (outcomeCount === 2) {
        const r_target = reserves[selectedBet.outcomeId];
        const r_other = reserves[1 - selectedBet.outcomeId];
        const k = r_target * r_other;
        const r_other_new = r_other + netAmount * 1e6;
        const r_target_new = k / r_other_new;
        shares = r_target - r_target_new;
      } else if (outcomeCount === 3) {
        const r_target = reserves[selectedBet.outcomeId];
        let opponent_total = 0;
        for (let i = 0; i < 3; i++) {
          if (i !== selectedBet.outcomeId) {
            opponent_total += reserves[i];
          }
        }
        const k_approx = r_target * opponent_total;
        const opponent_total_new = opponent_total + netAmount * 1e6;
        const r_target_new = k_approx / opponent_total_new;
        shares = r_target - r_target_new;
      } else {
        // Multi-outcome markets: use current odds as approximation
        const odds = parseFloat(selectedBet.odds);
        return (amount * odds).toFixed(2);
      }

      return (shares / 1e6).toFixed(2);
    }
  };

  const handleApprove = async () => {
    if (!selectedBet?.marketAddress) return;
    try {
      await approve(selectedBet.marketAddress, 'max');
    } catch (error: unknown) {
      console.error('Approve error:', error);
      if (approveToastId) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
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
      console.error('Place bet error:', error);
      if (betToastId) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        betNotifications.betFailed(betToastId, errorMessage);
        setBetToastId(null);
      }
    }
  };

  const handleClear = () => {
    clearBet();
    setBetAmount('');
  };

  // Show empty state when no bet selected
  if (!selectedBet) {
    return <BetSlipEmpty />;
  }

  return (
    <Card className={`bg-white shadow-lg border border-gray-200 ${className || ''}`} padding="lg">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-bold text-gray-900">Bet Slip</h3>
        <button
          onClick={handleClear}
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
          {selectedBet.homeTeam} vs {selectedBet.awayTeam}
        </p>
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-900">{selectedBet.outcomeName}</p>
          <span className="text-sm font-bold text-blue-600">{selectedBet.odds}x</span>
        </div>
      </div>

      {/* Balance Display */}
      {usdcBalance !== undefined && usdcBalance !== null && typeof usdcBalance === 'bigint' && (
        <p className="text-xs text-gray-500 mb-2">
          Balance: {formatUnits(usdcBalance, 6)} USDC
        </p>
      )}

      {/* Amount Input */}
      <div className="mb-4">
        <label className="block text-xs font-medium text-gray-500 mb-1">
          Amount (USDC)
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
            MAX
          </button>
        </div>
      </div>

      {/* Expected Payout */}
      {betAmount && parseFloat(betAmount) > 0 && (
        <div className="p-3 bg-blue-50 rounded-lg mb-4">
          <p className="text-xs text-gray-500 mb-1">Potential Payout</p>
          <p className="text-xl font-bold text-blue-600">${calculatePayout()}</p>
          <p className="text-xs text-gray-500">
            Profit: ${(parseFloat(calculatePayout()) - parseFloat(betAmount)).toFixed(2)}
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
            {isApproving || isApprovingConfirming ? 'Approving...' : isAllowanceLoading ? 'Checking...' : 'Approve USDC'}
          </Button>
        ) : (
          <Button
            variant="neon"
            fullWidth
            onClick={handlePlaceBet}
            disabled={!betAmount || parseFloat(betAmount) < 1 || isBetting || isBettingConfirming || !isConnected}
            isLoading={isBetting || isBettingConfirming}
          >
            {isBetting || isBettingConfirming ? 'Placing Bet...' : 'Place Bet'}
          </Button>
        )}
      </div>

      {!isConnected && (
        <p className="text-xs text-amber-600 text-center mt-3">
          Connect wallet to place bet
        </p>
      )}

      {needsApproval && (
        <p className="text-xs text-blue-500 text-center mt-3">
          First time? Approve USDC spending
        </p>
      )}
    </Card>
  );
}
