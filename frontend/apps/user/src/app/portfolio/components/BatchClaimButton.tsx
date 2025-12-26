'use client';

import { useTranslation } from "@pitchone/i18n";
import { Button, LoadingSpinner } from "@pitchone/ui";
import { Position, useRedeemBatch } from "@pitchone/web3";
import { useState, useMemo } from "react";
import { type Address } from "viem";
import { getClaimStatus } from "../utils";

interface ClaimablePosition {
    marketAddress: Address;
    outcomeId: number;
    shares: string;
}

/**
 * 按市场分组可领取的头寸
 */
function groupByMarket(positions: Position[]): Map<Address, ClaimablePosition[]> {
    const grouped = new Map<Address, ClaimablePosition[]>();

    for (const pos of positions) {
        if (getClaimStatus(pos) !== 'claimable') continue;

        const marketAddress = pos.market.id as Address;
        if (!grouped.has(marketAddress)) {
            grouped.set(marketAddress, []);
        }
        grouped.get(marketAddress)!.push({
            marketAddress,
            outcomeId: pos.outcome,
            shares: pos.balance,
        });
    }

    return grouped;
}

interface BatchClaimButtonProps {
    positions: Position[];
    onSuccess?: () => void;
}

export default function BatchClaimButton({ positions, onSuccess }: BatchClaimButtonProps) {
    const { t } = useTranslation();
    const [isClaiming, setIsClaiming] = useState(false);
    const [currentMarketIndex, setCurrentMarketIndex] = useState(0);
    const { redeemBatch, isPending, isConfirming, isSuccess } = useRedeemBatch();

    // 计算可领取的头寸，按市场分组
    const groupedClaimable = useMemo(() => groupByMarket(positions), [positions]);
    const marketAddresses = useMemo(() => Array.from(groupedClaimable.keys()), [groupedClaimable]);
    const totalClaimable = useMemo(() => {
        let count = 0;
        groupedClaimable.forEach(items => count += items.length);
        return count;
    }, [groupedClaimable]);

    const handleBatchClaim = async () => {
        if (totalClaimable === 0) return;

        setIsClaiming(true);
        setCurrentMarketIndex(0);

        try {
            // 按市场依次调用 redeemBatch
            for (let i = 0; i < marketAddresses.length; i++) {
                setCurrentMarketIndex(i);
                const marketAddress = marketAddresses[i];
                const items = groupedClaimable.get(marketAddress)!;

                console.log(`[BatchClaim] 正在领取市场 ${i + 1}/${marketAddresses.length}:`, {
                    marketAddress,
                    items,
                });

                await redeemBatch(
                    marketAddress,
                    items.map(item => item.outcomeId),
                    items.map(item => item.shares)
                );
            }

            // 成功后延迟刷新
            setTimeout(() => onSuccess?.(), 1500);
        } catch (err) {
            console.error('[BatchClaim] 批量领取失败:', err);
        } finally {
            setIsClaiming(false);
            setCurrentMarketIndex(0);
        }
    };

    const isLoading = isClaiming || isPending || isConfirming;

    // 没有可领取的头寸
    if (totalClaimable === 0) {
        return (
            <Button variant="secondary" size="sm" disabled>
                {t('portfolio.batchClaim')}
            </Button>
        );
    }

    return (
        <Button
            variant="neon"
            size="sm"
            onClick={handleBatchClaim}
            disabled={isLoading}
        >
            {isLoading ? (
                <span className="flex items-center gap-2">
                    <LoadingSpinner size="sm" />
                    <span>
                        {marketAddresses.length > 1
                            ? `${currentMarketIndex + 1}/${marketAddresses.length}`
                            : t('portfolio.claiming')
                        }
                    </span>
                </span>
            ) : (
                <span>
                    {t('portfolio.batchClaim')} ({totalClaimable})
                </span>
            )}
        </Button>
    );
}
