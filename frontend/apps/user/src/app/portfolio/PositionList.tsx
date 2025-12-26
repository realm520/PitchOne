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

/**
 * 格式化交易哈希为短格式（0x1234...5678）
 */
function formatTxHash(hash: string | undefined): string {
    if (!hash) return '-';
    // 处理 0x 前缀
    const cleanHash = hash.startsWith('0x') ? hash : `0x${hash}`;
    if (cleanHash.length <= 12) return cleanHash;
    return `${cleanHash.slice(0, 6)}...${cleanHash.slice(-4)}`;
}

/**
 * 获取区块浏览器链接
 * TODO: 根据实际网络配置动态获取
 */
function getTxExplorerUrl(hash: string | undefined): string | undefined {
    if (!hash) return undefined;
    const cleanHash = hash.startsWith('0x') ? hash : `0x${hash}`;
    // 本地测试环境暂时不返回链接
    // 生产环境可以返回如 https://etherscan.io/tx/${cleanHash}
    return undefined;
}

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
                        <Th className="text-right">{t("portfolio.ticket.claimingTx")}</Th>
                    </Row>
                </Head>
                <Body>
                    {positions?.map((position) => {
                        const bettingTxUrl = getTxExplorerUrl(position.createdTxHash);
                        const claimTxUrl = getTxExplorerUrl(position.claimTxHash);

                        return (
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
                                <Td>
                                    {bettingTxUrl ? (
                                        <a
                                            href={bettingTxUrl}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="text-blue-500 hover:text-blue-700 hover:underline"
                                            title={position.createdTxHash}
                                        >
                                            {formatTxHash(position.createdTxHash)}
                                        </a>
                                    ) : (
                                        <span title={position.createdTxHash} className="text-gray-500">
                                            {formatTxHash(position.createdTxHash)}
                                        </span>
                                    )}
                                </Td>
                                <Td className="text-right">
                                    {position.claimTxHash ? (
                                        claimTxUrl ? (
                                            <a
                                                href={claimTxUrl}
                                                target="_blank"
                                                rel="noopener noreferrer"
                                                className="text-blue-500 hover:text-blue-700 hover:underline"
                                                title={position.claimTxHash}
                                            >
                                                {formatTxHash(position.claimTxHash)}
                                            </a>
                                        ) : (
                                            <span title={position.claimTxHash} className="text-gray-500">
                                                {formatTxHash(position.claimTxHash)}
                                            </span>
                                        )
                                    ) : (
                                        <ClaimButton position={position} />
                                    )}
                                </Td>
                            </Row>
                        );
                    })}
                </Body>
            </Table>
        </motion.div>
    );
}
