import { useTranslation } from "@pitchone/i18n";
import { Button, Card, EmptyState, ErrorState, Input, Pagination } from "@pitchone/ui";
import { useMemo, useState } from "react";
import PositionList from "./PositionList";
import { Position, useAccount, useUserPositions, useUserPositionsPaginated, useUserStats } from "@pitchone/web3";
import Link from "next/link";
import Stats from "./Stats";
import { calculateExpectedPayout, getClaimStatus } from "./utils";
import { LoadingFallback } from "@/components/LoadingFallback";

type TabType = 'all' | 'claimable';

/**
 * 根据 Tab 和关键字过滤 positions
 */
const filterPositions = (
    positions: Position[],
    tab: TabType,
    keyword: string
): Position[] => {
    let filtered = positions;

    // 按 Tab 筛选
    if (tab === 'claimable') {
        filtered = filtered.filter((pos) => getClaimStatus(pos) === 'claimable');
    }

    // 按关键字筛选
    if (keyword.trim()) {
        const lowerKeyword = keyword.toLowerCase().trim();
        filtered = filtered.filter((pos) => {
            // 搜索主队名
            if (pos.market.homeTeam?.toLowerCase().includes(lowerKeyword)) return true;
            // 搜索客队名
            if (pos.market.awayTeam?.toLowerCase().includes(lowerKeyword)) return true;
            // 搜索 matchId（包含联赛代码）
            if (pos.market.matchId?.toLowerCase().includes(lowerKeyword)) return true;
            // 搜索市场 ID
            if (pos.market.id?.toLowerCase().includes(lowerKeyword)) return true;
            return false;
        });
    }

    return filtered;
};

export default function MyPositions() {
    const [activeTab, setActiveTab] = useState('all')
    const [keyword, setKeyword] = useState('')
    const { address } = useAccount();
    const [currentPage, setCurrentPage] = useState(1);
    const pageSize = 10; // 每页显示条数
    const { data, isLoading, error } = useUserPositionsPaginated(address, currentPage, pageSize);
    const { data: userStats } = useUserStats(address);
    // 获取所有头寸用于计算 Active Tickets 和 Potential Profit
    const { data: allPositions } = useUserPositions(address);
    const positions = data?.positions;
    const totalCount = data?.total || 0;
    const totalPages = Math.ceil(totalCount / pageSize);
    const { t } = useTranslation()

    // 计算 Active Tickets 和 Potential Profit
    const { activeTickets, potentialProfit } = useMemo(() => {
        if (!allPositions || allPositions.length === 0) {
            return { activeTickets: 0, potentialProfit: 0 };
        }

        // 过滤出"市场未结算状态"的头寸（pending 状态）
        const pendingPositions = allPositions.filter(pos => getClaimStatus(pos) === 'pending');

        // Active Tickets = pending 状态的投注单数量
        const activeTickets = pendingPositions.length;

        // Potential Profit = 累计 Payout - 累计 Payment
        let totalPayout = 0;
        let totalPayment = 0;

        pendingPositions.forEach(pos => {
            // 计算预期赔付（Payout）
            const payout = calculateExpectedPayout(pos);
            totalPayout += payout;

            // 计算原始支付金额（Payment）- 使用 totalPayment 字段（已是 USDC 单位）
            const payment = parseFloat(pos.totalPayment || pos.totalInvested || '0');
            totalPayment += payment;
        });

        // Potential Profit = Payout - Payment，小于 0 则显示 0
        const potentialProfit = Math.max(0, totalPayout - totalPayment);

        return { activeTickets, potentialProfit };
    }, [allPositions]);

    // 使用 Subgraph 的 User 实体统计数据
    const stats = {
        // 总投注额（从 Subgraph User.totalPayment 获取，原始金额不扣手续费）
        totalBetAmount: userStats?.totalPayment || 0,
        // 投注市场数
        totalMarkets: userStats?.marketsParticipated || 0,
        // 总投注次数
        totalBets: userStats?.totalBets || 0,
        // Active Tickets = pending 状态的投注单数量
        activeTickets,
        // Potential Profit = pending 状态的投注预期盈利
        potentialProfit,
    };

    return (
        <div className="flex flex-col gap-6">
            <Stats
                totalBetAmount={stats.totalBetAmount}
                totalMarkets={stats.totalMarkets}
                totalBets={stats.totalBets}
                activeTickets={stats.activeTickets}
                potentialProfit={stats.potentialProfit}
            />
            <Card>
                <div className=" flex flex-col gap-5">
                    <h2>{t('portfolio.myTickets')}</h2>
                    <div className="flex flex-col gap-6">
                        <div className="flex justify-between">
                            <div className="flex gap-4">
                                {[
                                    { key: 'all' as TabType, label: t('portfolio.ticketTabs.all') },
                                    { key: 'claimable' as TabType, label: t('portfolio.ticketTabs.claimable') },
                                ].map((tab) => (
                                    <Button
                                        key={tab.key}
                                        variant={activeTab === tab.key ? 'primary' : 'secondary'}
                                        size="sm"
                                        onClick={() => setActiveTab(tab.key)}
                                        disabled={isLoading}
                                    >
                                        {tab.label}
                                    </Button>
                                ))}
                            </div>
                            <Input
                                className="p-1 w-64"
                                placeholder={t('portfolio.searchPlaceholder')}
                                value={keyword}
                                onChange={(e) => setKeyword(e.target.value)}
                                disabled={isLoading}
                            />
                        </div>

                        {isLoading ? (
                            <div className="flex items-center justify-center">
                                <LoadingFallback type="position" height="224px" />
                            </div>
                        ) : error ? (
                            <div className="flex items-center justify-center">
                                <ErrorState message={t('portfolio.loadError')} />
                            </div>
                        ) : (() => {
                            const filteredPositions = filterPositions(positions || [], activeTab as TabType, keyword);
                            return filteredPositions.length === 0 ? (
                                <EmptyState
                                    title={keyword ? t('portfolio.noSearchResults') : activeTab === 'active' ? t('portfolio.emptyActive') : activeTab === 'settled' ? t('portfolio.emptySettled') : t('portfolio.emptyAll')}
                                    description={keyword ? t('portfolio.tryDifferentKeyword') : t('portfolio.emptyDesc')}
                                    action={
                                        keyword ? (
                                            <Button variant="secondary" onClick={() => setKeyword('')}>
                                                {t('portfolio.clearSearch')}
                                            </Button>
                                        ) : (
                                            <Link href="/markets">
                                                <Button variant="primary">{t('portfolio.goToMarkets')}</Button>
                                            </Link>
                                        )
                                    }
                                />
                            ) : (
                                <div className="flex flex-col gap-6">
                                    <PositionList positions={filteredPositions} />
                                    {totalPages > 1 && (
                                        <Pagination
                                            currentPage={currentPage}
                                            totalPages={totalPages}
                                            onPageChange={setCurrentPage}
                                        />
                                    )}
                                </div>
                            );
                        })()}
                    </div>
                </div>
            </Card>
        </div>

    )
}