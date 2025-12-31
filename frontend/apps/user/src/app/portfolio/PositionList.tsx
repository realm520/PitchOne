import { useTranslation } from "@pitchone/i18n";
import { Table, Head, Body, Row, Th, Td } from "@pitchone/ui";
import { Position } from "@pitchone/web3";
import { motion } from "framer-motion";
import { ChevronRight } from "lucide-react";
import Link from "next/link";
import {
    calculateExpectedPayout,
    calculateOdds,
    getOriginalPayment,
    getResultKey,
    getSelection,
    formatDate,
    getLeagueCode,
    formatUSDC,
    formatTxHash,
    getTxExplorerUrl,
    getStatusDisplay,
} from "./utils";
import ClaimButton from "./components/ClaimButton";

export default function PositionList({ positions }: { positions?: Position[] }) {
    const { t, translateTeam } = useTranslation();
    return (
        <motion.div
            className="flex flex-col gap-4 text-xs"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3 }}
        >
            <Table striped hoverable>
                <Head>
                    <Row>
                        <Th>{t("portfolio.ticket.match")}</Th>
                        <Th>{t("portfolio.ticket.selection")}</Th>
                        <Th>{t("portfolio.ticket.payment")}</Th>
                        <Th>{t("portfolio.ticket.odds")}</Th>
                        <Th>{t("portfolio.ticket.payout")}</Th>
                        <Th>{t("portfolio.ticket.result")}</Th>
                        <Th>{t("portfolio.ticket.placed")}</Th>
                        <Th>{t("portfolio.ticket.bettingTx")}</Th>
                        <Th>{t("portfolio.ticket.claimingTx")}</Th>
                        <Th className="w-10"></Th>
                    </Row>
                </Head>
                <Body>
                    {positions?.map((position) => {
                        const bettingTxUrl = getTxExplorerUrl(position.createdTxHash);
                        const claimTxUrl = getTxExplorerUrl(position.claimTxHash);
                        const statusDisplay = getStatusDisplay(position);

                        return (
                            <Row key={position.id}>
                                <Td>
                                    <div className="flex flex-col gap-1">
                                        <div className="flex items-center gap-2">
                                            <span className="text-[10px]">{getLeagueCode(position)}</span>
                                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium border ${statusDisplay.color}`}>
                                                {t(statusDisplay.textKey)}
                                            </span>
                                        </div>
                                        <div className="font-bold">
                                            {position.market.homeTeam ? translateTeam(position.market.homeTeam) : t('markets.unknown')} vs{' '}
                                            {position.market.awayTeam ? translateTeam(position.market.awayTeam) : t('markets.unknown')}
                                        </div>
                                        <div className="text-[10px] text-gray-400">{formatDate(position.createdAt)}</div>
                                    </div>
                                </Td>
                                <Td>{getSelection(position, translateTeam, t)}</Td>
                                <Td>{formatUSDC(getOriginalPayment(position))} USDC</Td>
                                <Td>{calculateOdds(position)}</Td>
                                <Td>{calculateExpectedPayout(position).toFixed(2)} USDC</Td>
                                <Td>{t(getResultKey(position))}</Td>
                                <Td>{formatDate(position.createdAt)}</Td>
                                <Td>
                                    {bettingTxUrl ? (
                                        <a
                                            href={bettingTxUrl}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="text-blue-400 hover:text-blue-300 hover:underline"
                                            title={position.createdTxHash}
                                        >
                                            {formatTxHash(position.createdTxHash)}
                                        </a>
                                    ) : (
                                        <span className="text-gray-500">-</span>
                                    )}
                                </Td>
                                <Td>
                                    {position.claimTxHash ? (
                                        <a
                                            href={claimTxUrl}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="text-green-400 hover:text-green-300 hover:underline"
                                            title={position.claimTxHash}
                                        >
                                            {formatTxHash(position.claimTxHash)}
                                        </a>
                                    ) : (
                                        <ClaimButton position={position} />
                                    )}
                                </Td>
                                <Td className="text-right">
                                    <Link
                                        href={`/markets/${position.market.id}`}
                                        className="inline-flex items-center text-gray-500 hover:text-white transition-colors"
                                        title={t("portfolio.ticket.viewMarket")}
                                    >
                                        <ChevronRight className="w-5 h-5" />
                                    </Link>
                                </Td>
                            </Row>
                        );
                    })}
                </Body>
            </Table>
        </motion.div>
    );
}
