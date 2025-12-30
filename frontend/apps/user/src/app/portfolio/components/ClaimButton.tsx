'use client';

import { useTranslation } from "@pitchone/i18n";
import { Button, LoadingSpinner } from "@pitchone/ui";
import { Position, useRedeem } from "@pitchone/web3";
import { useState } from "react";
import { type Address } from "viem";
import { getClaimStatus, formatTxHash, getTxExplorerUrl } from "../utils";

export default function ClaimButton({ position }: { position: Position }) {
    const { t } = useTranslation();
    const [isClaiming, setIsClaiming] = useState(false);
    const { redeem, isPending, isConfirming, isSuccess, hash } = useRedeem(position.market.id as Address);

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

        setIsClaiming(true);
        try {
            await redeem(position.outcome, position.balance);
        } catch (err) {
            console.error('Claim failed:', err);
        } finally {
            setIsClaiming(false);
        }
    };

    const isLoading = isClaiming || isPending || isConfirming;

    if (status === 'pending') {
        return <span className="text-gray-400">{t("portfolio.ticket.pending")}</span>;
    }

    if (status === 'lost') {
        return <span className="text-red-400">{t("portfolio.ticket.lost")}</span>;
    }

    if (status === 'claimed') {
        return <span className="text-green-400">{t("portfolio.ticket.claimed")}</span>;
    }

    // Claim 成功，显示交易 hash
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
