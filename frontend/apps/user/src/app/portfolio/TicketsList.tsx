import { useTranslation } from "@pitchone/i18n";
import { Button, Table, Head, Body, Row, Th, Td } from "@pitchone/ui";

export default function TicketList() {
    const { t } = useTranslation();

    return (
        <div className="flex flex-col gap-4">
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
                    </Row>
                </Head>
                <Body>
                    <Row>
                        <Td>曼联 vs 曼城</Td>
                        <Td>主胜</Td>
                        <Td>100 USDC</Td>
                        <Td>2.45</Td>
                        <Td>245 USDC</Td>
                        <Td>胜利</Td>
                        <Td>2024-10-01 12:30</Td>
                        <Td>0x222</Td>
                        <Td><Button size="sm">{t("portfolio.ticket.claim")}</Button></Td>
                    </Row>
                </Body>
            </Table>
        </div>
    );
}