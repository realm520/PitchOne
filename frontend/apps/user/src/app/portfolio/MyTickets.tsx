import { useTranslation } from "@pitchone/i18n";
import { Button, Card, EmptyState, ErrorState, Input, LoadingSpinner, Pagination } from "@pitchone/ui";
import { Ticket } from "lucide-react";
import { useState } from "react";
import TicketList from "./TicketsList";
import { useAccount, useUserPositions } from "@pitchone/web3";
import { p } from "framer-motion/client";
import Link from "next/link";

type TabType = 'all' | 'claimable';

function A() {

}

export default function MyTickets() {
    const [activeTab, setActiveTab] = useState('all')
    const [keyword, setKeyword] = useState()
    const { address } = useAccount();
    const { data: positions, isLoading, error } = useUserPositions(address);
    const [currentPage, setCurrentPage] = useState(1);
    const totalPages = 5; // TODO: 从实际数据获取
    const { t } = useTranslation()

    return (
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
                    {isLoading && (
                        <div className="min-h-screen bg-dark-bg flex items-center justify-center">
                            <LoadingSpinner size="lg" text={t('portfolio.loading')} />
                        </div>
                    )}

                    {error && (
                        <div className="min-h-screen bg-dark-bg flex items-center justify-center">
                            <ErrorState message={t('portfolio.loadError')} />
                        </div>
                    )}

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
                            <TicketList />
                            <div className="flex justify-end">
                                <Pagination
                                    currentPage={currentPage}
                                    totalPages={totalPages}
                                    onPageChange={setCurrentPage}
                                />
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </Card>
    )
}