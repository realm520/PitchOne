import { useTranslation } from "@pitchone/i18n";
import { Table, Head, Body, Row, Th, Td } from "@pitchone/ui";
import { Position } from "@pitchone/web3";
import { motion } from "framer-motion";
import {
    calculateExpectedPayout,
    getResultKey,
    getSelection,
    formatDate,
    getLeagueCode,
    formatAmount,
} from "./utils";
import ClaimButton from "./components/ClaimButton";

export default function TicketList({ positions }: { positions?: Position[] }) {
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
                        <Th className="text-right">{t("portfolio.ticket.claimingTx")}</Th>
                    </Row>
                </Head>
                <Body>
                    {positions?.map((position) =>
                        <Row key={position.id}>
                            <Td>
                                <div className="flex flex-col">
                                    <div className="text-[10px]">{getLeagueCode(position)}</div>
                                    <div className="font-bold">
                                        {position.market.homeTeam ? translateTeam(position.market.homeTeam) : t('markets.unknown')} vs{' '}
                                        {position.market.awayTeam ? translateTeam(position.market.awayTeam) : t('markets.unknown')}
                                    </div>
                                    <div>{formatDate(position.createdAt)}</div>
                                </div>
                            </Td>
                            <Td>{getSelection(position, translateTeam)}</Td>
                            <Td>{formatAmount(position.balance)}</Td>
                            <Td>-</Td>
                            <Td>{formatAmount(calculateExpectedPayout(position))}</Td>
                            <Td>{t(getResultKey(position))}</Td>
                            <Td>{formatDate(position.createdAt)}</Td>
                            <Td>0x222</Td>
                            <Td className="text-right">
                                <ClaimButton position={position} />
                            </Td>
                        </Row>
                    )}
                </Body>
            </Table>
        </motion.div>
    );
}
