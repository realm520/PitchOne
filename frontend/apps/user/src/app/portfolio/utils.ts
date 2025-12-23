import { Position, MarketStatus, TOKEN_DECIMALS, getOutcomeName } from "@pitchone/web3";
import { formatUnits } from "viem/utils";

/**
 * Claim 状态类型
 */
export type ClaimStatus = 'claimable' | 'claimed' | 'lost' | 'pending';

/**
 * 获取头寸的 claim 状态
 */
export const getClaimStatus = (position: Position): ClaimStatus => {
    const { state, winnerOutcome } = position.market;

    // 市场未结算，还在进行中
    if (state === MarketStatus.Open || state === MarketStatus.Locked) {
        return 'pending';
    }

    // 市场已结算（Resolved 或 Finalized）
    if (state === MarketStatus.Resolved || state === MarketStatus.Finalized) {
        // 用户的 outcome 与赢家 outcome 匹配
        if (winnerOutcome !== undefined && winnerOutcome === position.outcome) {
            // 检查是否还有余额可领取
            const balance = parseFloat(position.balance);
            if (balance > 0) {
                return 'claimable';
            }
            return 'claimed';
        }
        return 'lost';
    }

    return 'pending';
};

/**
 * 计算预期收益
 */
export const calculateExpectedPayout = (position: Position): number => {
    try {
        // 预期收益 = 持有份额（假设赢了的话，1 share = 1 USDC）
        // balance 存储的是 USDC 单位（6 位小数），不是 ETH（18 位小数）
        if (!position.balance || position.balance === '0') {
            // 如果 balance 为 0，尝试使用 totalInvested 估算（假设赔率约 2.0）
            if (position.totalInvested) {
                const invested = parseFloat(position.totalInvested);
                return invested * 1.8; // 估算 80% 收益
            }
            return 0;
        }

        // 将 balance（USDC）转换为标准单位
        const balanceInUSDC = BigInt(position.balance);
        const shares = parseFloat(formatUnits(balanceInUSDC, TOKEN_DECIMALS.USDC));

        return shares;
    } catch (error) {
        console.error('[Portfolio] 计算预期收益失败:', error, position);
        return 0;
    }
};

/**
 * 获取投注结果状态（返回 i18n key）
 */
export const getResultKey = (position: Position): string => {
    if (position.market.winnerOutcome === undefined) {
        return 'portfolio.pending';
    } else {
        if (position.market.winnerOutcome === position.outcome) {
            return 'portfolio.win';
        } else {
            return 'portfolio.lose';
        }
    }
};

/**
 * 获取用户选择的投注内容（显示具体队伍名称）
 */
export const getSelection = (
    position: Position,
    translateTeam: (team: string) => string
): string => {
    const { templateId, line, homeTeam, awayTeam } = position.market;
    const outcomeId = position.outcome;

    // WDL (胜平负): 显示押注的队伍名称
    if (templateId === '1' || templateId === 'WDL' || templateId === '0x00000000') {
        if (outcomeId === 0) return translateTeam(homeTeam); // 主队胜
        if (outcomeId === 1) return 'Draw'; // 平局
        if (outcomeId === 2) return translateTeam(awayTeam); // 客队胜
    }

    // OU (大小球): 显示大球/小球 + 盘口
    if (templateId === '2' || templateId === 'OU' || templateId?.includes('OU')) {
        const lineValue = line ? parseFloat(line) / 1000000 : 0;
        if (outcomeId === 0) return `Over ${lineValue}`;
        if (outcomeId === 1) return `Under ${lineValue}`;
    }

    // AH (让球): 显示队伍名 + 让球数
    if (templateId === '3' || templateId === 'AH') {
        const lineValue = line ? parseFloat(line) / 1000000 : 0;
        const sign = lineValue >= 0 ? '+' : '';
        if (outcomeId === 0) return `${translateTeam(homeTeam)} (${sign}${lineValue})`;
        if (outcomeId === 1) return `${translateTeam(awayTeam)} (${sign}${-lineValue})`;
        if (outcomeId === 2) return 'Push';
    }

    // OddEven (单双)
    if (templateId === '4' || templateId === 'OddEven') {
        if (outcomeId === 0) return 'Odd';
        if (outcomeId === 1) return 'Even';
    }

    // Score (精确比分)
    if (templateId === '5' || templateId === 'Score') {
        if (outcomeId === 999) return 'Other';
        const homeGoals = Math.floor(outcomeId / 10);
        const awayGoals = outcomeId % 10;
        return `${homeGoals}-${awayGoals}`;
    }

    // 默认使用 getOutcomeName
    return getOutcomeName(templateId, outcomeId);
};

/**
 * 格式化日期 (格式: DEC 01 · 20:30)
 */
export const formatDate = (timestamp: string): string => {
    const date = new Date(parseInt(timestamp) * 1000);

    const month = date.toLocaleString('en-US', { month: 'short' }).toUpperCase();
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');

    return `${month} ${day} · ${hours}:${minutes}`;
};

/**
 * 从 matchId 中提取联赛代码
 */
export const getLeagueCode = (position: Position): string => {
    return position.market.matchId.split('_')[0];
};

/**
 * 格式化交易哈希（显示缩略形式）
 */
export const formatTxHash = (hash: string): string => {
    if (!hash || hash.length < 10) return hash;
    return `${hash.slice(0, 6)}...${hash.slice(-4)}`;
};

/**
 * 格式化金额（带 K/M/B 单位）
 * @param amount - 金额数值
 * @param decimals - 小数位数（默认 2）
 * @returns 格式化后的字符串
 */
export const formatAmount = (amount: number | string, decimals: number = 2): string => {
    const num = typeof amount === 'string' ? parseFloat(amount) : amount;

    if (isNaN(num)) return '0';

    const absNum = Math.abs(num);
    const sign = num < 0 ? '-' : '';

    if (absNum >= 1_000_000_000) {
        return `${sign}${(absNum / 1_000_000_000).toFixed(decimals)}B`;
    }
    if (absNum >= 1_000_000) {
        return `${sign}${(absNum / 1_000_000).toFixed(decimals)}M`;
    }
    if (absNum >= 1_000) {
        return `${sign}${(absNum / 1_000).toFixed(decimals)}K`;
    }

    return `${sign}${absNum.toFixed(decimals)}`;
};

/**
 * 格式化 USDC 金额（从链上原始值转换）
 * @param rawAmount - 链上原始值（6 位小数）
 * @param decimals - 显示小数位数（默认 2）
 * @returns 格式化后的字符串
 */
export const formatUSDC = (rawAmount: string | number, decimals: number = 2): string => {
    const raw = typeof rawAmount === 'string' ? parseFloat(rawAmount) : rawAmount;
    if (isNaN(raw)) return '0';

    // USDC 有 6 位小数
    const amount = raw / 1_000_000;
    return formatAmount(amount, decimals);
};
