import { useTranslation } from "@pitchone/i18n";
import { Button, Card, EmptyState, ErrorState, Input, LoadingSpinner, Pagination } from "@pitchone/ui";
import { useState } from "react";
import TicketList from "./TicketsList";
import { MarketStatus, useAccount, useUserPositions } from "@pitchone/web3";
import Link from "next/link";
import Stats from "./Stats";
import { MOCK_POSITIONS } from "./data";
import { calculateExpectedPayout } from "./utils";

type TabType = 'all' | 'claimable';

export default function MyTickets() {
    const [activeTab, setActiveTab] = useState('all')
    const [keyword, setKeyword] = useState()
    const { address } = useAccount();
    const { data: positions, isLoading, error } = useUserPositions(address);
    const [currentPage, setCurrentPage] = useState(1);
    const totalPages = 5; // TODO: 从实际数据获取
    const { t } = useTranslation()

    // 计算统计数据
    const stats = (() => {
        if (!positions || positions.length === 0) {
            return {
                totalBetAmount: 0,
                totalMarkets: 0,
                totalBets: 0,
                totalProfit: 0,
            };
        }

        // 总投注额：所有头寸的 totalInvested 之和
        const totalBetAmount = positions.reduce((sum, pos) => {
            const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;
            return sum + invested;
        }, 0);

        // 投注市场数：去重的市场数量
        const uniqueMarkets = new Set(positions.map((pos) => pos.market.id));
        const totalMarkets = uniqueMarkets.size;

        // 总投注次数：头寸数量
        const totalBets = positions.length;

        // 盈利金额：已结算且赢得的头寸的收益 - 已结算且输掉的投注额
        const totalProfit = positions.reduce((sum, pos) => {
            const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;

            // 只计算已结算的市场
            if (pos.market.state === MarketStatus.Resolved || pos.market.state === MarketStatus.Finalized) {
                if (pos.market.winnerOutcome !== undefined && pos.market.winnerOutcome === pos.outcome) {
                    // 赢了：预期收益 - 投入
                    const expectedPayout = calculateExpectedPayout(pos);
                    return sum + (expectedPayout - invested);
                } else {
                    // 输了：损失全部投入
                    return sum - invested;
                }
            }
            return sum;
        }, 0);

        return {
            totalBetAmount,
            totalMarkets,
            totalBets,
            totalProfit,
        };
    })();

    if (isLoading) {
        return (
            <div className="min-h-screen bg-dark-bg flex items-center justify-center h-100vh">
                <LoadingSpinner size="lg" />
            </div>
        )
    }

    if (error) {
        return (
            <div className="min-h-screen bg-dark-bg flex items-center justify-center">
                <ErrorState message={t('portfolio.loadError')} />
            </div>
        )
    }

    return (
        <div className="flex flex-col gap-6">
            <Stats
                totalBetAmount={stats.totalBetAmount}
                totalMarkets={stats.totalMarkets}
                totalBets={stats.totalBets}
                totalProfit={stats.totalProfit}
            />
            <Card>
                <div className=" flex flex-col gap-5">
                    <h2>{t('portfolio.myTickets')}</h2>
                    <div className="flex flex-col gap-6">
                        <div className="flex justify-between">
                            <div>
                                {[
                                    { key: 'all' as TabType, label: t('portfolio.ticketTabs.all') },
                                    { key: 'claimable' as TabType, label: t('portfolio.ticketTabs.claimable') },
                                ].map((tab) => (
                                    <Button
                                        key={tab.key}
                                        variant={activeTab === tab.key ? 'primary' : 'secondary'}
                                        size="sm"
                                        onClick={() => setActiveTab(tab.key)}
                                    >
                                        {tab.label}
                                    </Button>
                                ))}
                            </div>
                            <div className="flex gap-2">
                                <Input className=" p-1" />
                                <Button variant="neon" size="sm" >
                                    {t('portfolio.batchClaim')}
                                </Button>
                            </div>
                        </div>



                        {positions && positions.length === 0 ? (
                            <EmptyState
                                title={activeTab === 'active' ? t('portfolio.emptyActive') : activeTab === 'settled' ? t('portfolio.emptySettled') : t('portfolio.emptyAll')}
                                description={t('portfolio.emptyDesc')}
                                action={
                                    <Link href="/markets">
                                        <Button variant="primary">{t('portfolio.goToMarkets')}</Button>
                                    </Link>
                                }
                            />
                        ) : (
                            <div className="flex flex-col gap-6">
                                <TicketList positions={MOCK_POSITIONS} />
                                {/* <div className="flex justify-end">
                                    <Pagination
                                        currentPage={currentPage}
                                        totalPages={totalPages}
                                        onPageChange={setCurrentPage}
                                    />
                                </div> */}
                            </div>
                        )}
                    </div>
                </div>
            </Card>
        </div>

    )
}