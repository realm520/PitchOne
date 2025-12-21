
import { useTranslation } from "@pitchone/i18n";
import { Card, LoadingSpinner } from "@pitchone/ui";
import { useAccount, useUSDCBalance, formatUSDCFromWei } from "@pitchone/web3";

export default function Stats({
    totalBetAmount,
    totalMarkets,
    totalBets,
    totalProfit,
}: {
    totalBetAmount: number;
    totalMarkets: number;
    totalBets: number;
    totalProfit: number;
}) {
    const { t } = useTranslation();
    const { address, isConnected } = useAccount();
    const { data: balance, isLoading } = useUSDCBalance(address);

    // 格式化余额显示
    const formattedBalance = balance !== undefined ? formatUSDCFromWei(balance as bigint).toFixed(2) : '0.00';

    return (
        <Card padding="lg">
            <div className="flex items-center justify-between">
                <div className="flex flex-col">
                    <p className="text-sm text-gray-400 mb-1">{t('portfolio.balance')}</p>
                    <div className="flex items-baseline gap-1">
                        {isLoading ? (
                            <LoadingSpinner size="sm" />
                        ) : <span className="font-bold text-4xl">{formattedBalance}</span>}
                        <span className="text-gray-400">USDC</span>
                    </div>
                </div>

                <div className="flex gap-10">
                    <Card className="py-2 px-4">
                        <div className="flex flex-col items-center">
                            <h6>{t("portfolio.totalBet")}</h6>
                            <div className="flex items-baseline gap-1">
                                <span className="font-bold text-3xl">{totalBetAmount.toFixed(2)}</span>
                                <span>USDC</span>
                            </div>
                        </div>
                    </Card>
                    <Card className="py-2 px-4">
                        <div className="flex flex-col items-center">
                            <h6>{t("portfolio.totalProfit")}</h6>
                            <div className="flex items-baseline gap-1 text-[#17AD70]">
                                <span className="font-bold text-3xl">{totalProfit.toFixed(2)}</span>
                                <span>USDC</span>
                            </div>
                        </div>
                    </Card>
                </div>
            </div>
        </Card>
    );
}
