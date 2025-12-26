'use client';

import { useTranslation } from "@pitchone/i18n";
import { Button, LoadingSpinner } from "@pitchone/ui";
import { Position, useRedeem } from "@pitchone/web3";
import { useState } from "react";
import { type Address } from "viem";
import { getClaimStatus } from "../utils";

export default function ClaimButton({ position, onSuccess }: { position: Position; onSuccess?: () => void }) {
    const { t } = useTranslation();
    const [isClaiming, setIsClaiming] = useState(false);
    const { redeem, isPending, isConfirming, isSuccess } = useRedeem(position.market.id as Address);

    const status = getClaimStatus(position);

    const handleClaim = async () => {
        if (status !== 'claimable') return;

        // 打印 Claim 调用参数（JSON 字符串形式）
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
            // 延迟刷新，等待 Subgraph 索引
            setTimeout(() => onSuccess?.(), 1500);
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

    if (status === 'claimed' || isSuccess) {
        return <span className="text-green-400">{t("portfolio.ticket.claimed")}</span>;
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
