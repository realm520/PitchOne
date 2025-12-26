import { useTranslation } from "@pitchone/i18n";
import { Button, Card, EmptyState, ErrorState, Input, Pagination } from "@pitchone/ui";
import { useState } from "react";
import PositionList from "./PositionList";
import { MarketStatus, Position, useAccount, useUserPositionsPaginated } from "@pitchone/web3";
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
    const positions = data?.positions;
    const totalCount = data?.total || 0;
    const totalPages = Math.ceil(totalCount / pageSize);
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