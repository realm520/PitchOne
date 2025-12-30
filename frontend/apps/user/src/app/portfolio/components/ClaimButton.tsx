'use client';

import { useTranslation } from "@pitchone/i18n";
import { Button, LoadingSpinner } from "@pitchone/ui";
import { Position, useRedeem, useRefund } from "@pitchone/web3";
import { useState } from "react";
import { type Address } from "viem";
import { getClaimStatus, formatTxHash, getTxExplorerUrl } from "../utils";

export default function ClaimButton({ position }: { position: Position }) {
    const { t } = useTranslation();
    const [isProcessing, setIsProcessing] = useState(false);
    const { redeem, isPending: isRedeemPending, isConfirming: isRedeemConfirming, isSuccess: isRedeemSuccess, hash: redeemHash } = useRedeem(position.market.id as Address);
    const { refund, isPending: isRefundPending, isConfirming: isRefundConfirming, isSuccess: isRefundSuccess, hash: refundHash } = useRefund(position.market.id as Address);

    const status = getClaimStatus(position);

    const handleClaim = async () => {
        if (status !== 'claimable') return;

        console.log('[ClaimButton] Claim 调用参数:', JSON.stringify({
            marketId: position.market.id,
            marketState: position.market.state,
            winnerOutcome: position.market.winnerOutcome,
            userOutcome: position.outcome,
            balance: position.balance,
            status,
        }, null, 2));

        setIsProcessing(true);
        try {
            await redeem(position.outcome, position.balance);
        } catch (err) {
            console.error('Claim failed:', err);
        } finally {
            setIsProcessing(false);
        }
    };

    const handleRefund = async () => {
        if (status !== 'refundable') return;

        console.log('[ClaimButton] Refund 调用参数:', JSON.stringify({
            marketId: position.market.id,
            marketState: position.market.state,
            userOutcome: position.outcome,
            balance: position.balance,
            status,
        }, null, 2));

        setIsProcessing(true);
        try {
            await refund(position.outcome, position.balance);
        } catch (err) {
            console.error('Refund failed:', err);
        } finally {
            setIsProcessing(false);
        }
    };

    const isLoading = isProcessing || isRedeemPending || isRedeemConfirming || isRefundPending || isRefundConfirming;
    const isSuccess = isRedeemSuccess || isRefundSuccess;
    const hash = redeemHash || refundHash;

    if (status === 'pending') {
        return <span className="text-gray-400">{t("portfolio.ticket.pending")}</span>;
    }

    if (status === 'lost') {
        return <span className="text-red-400">{t("portfolio.ticket.lost")}</span>;
    }

    if (status === 'claimed') {
        return <span className="text-green-400">{t("portfolio.ticket.claimed")}</span>;
    }

    // Claim/Refund 成功，显示交易 hash
    if (isSuccess && hash) {
        return (
            <a
                href={getTxExplorerUrl(hash)}
                target="_blank"
                rel="noopener noreferrer"
                className="text-green-400 hover:text-green-300 underline"
            >
                {formatTxHash(hash)}
            </a>
        );
    }

    if (isLoading) {
        return <LoadingSpinner size="sm" />;
    }

    // 市场取消，显示 Refund 按钮
    if (status === 'refundable') {
        return (
            <Button
                size="sm"
                variant="secondary"
                onClick={handleRefund}
            >
                {t("portfolio.ticket.refund")}
            </Button>
        );
    }

    // 可领取奖金，显示 Claim 按钮
    return (
        <Button
            size="sm"
            variant="neon"
            onClick={handleClaim}
        >
            {t("portfolio.ticket.claim")}
        </Button>
    );
}
