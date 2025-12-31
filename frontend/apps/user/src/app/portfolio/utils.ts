import { Position, MarketStatus, TOKEN_DECIMALS, getOutcomeName } from "@pitchone/web3";
import { formatUnits } from "viem/utils";

/**
 * Claim 状态类型
 * - claimable: 可领取奖金（赢了）
 * - refundable: 可退款（市场取消）
 * - claimed: 已领取
 * - lost: 输了
 * - pending: 进行中
 */
export type ClaimStatus = 'claimable' | 'refundable' | 'claimed' | 'lost' | 'pending';

/**
 * 获取市场状态的显示信息（颜色和文本）
 *
 * 状态说明：
 * - Open：市场创建完后自动变为Open，此时市场可以接受下注
 * - Open + paused：市场已暂停，显示为 Locked
 * - Locked：市场达到开赛时间后，市场自动变为Locked，停止接受下注
 * - Resolved：已提交结算结果
 * - Finalized：结算已通过挑战期，获胜玩家可以领取获胜奖金
 * - Refunded：市场取消，可以发起退款
 */
export const getStatusDisplay = (position: Position): { color: string; textKey: string } => {
    const { state, paused } = position.market;

    // 如果市场是 Open 但已暂停，显示为 Locked
    if (state === MarketStatus.Open && paused) {
        return { color: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30', textKey: 'portfolio.status.locked' };
    }

    switch (state) {
        case MarketStatus.Open:
            return { color: 'bg-green-500/20 text-green-400 border-green-500/30', textKey: 'portfolio.status.open' };
        case MarketStatus.Locked:
            return { color: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30', textKey: 'portfolio.status.locked' };
        case MarketStatus.Resolved:
            return { color: 'bg-blue-500/20 text-blue-400 border-blue-500/30', textKey: 'portfolio.status.resolved' };
        case MarketStatus.Finalized:
            return { color: 'bg-purple-500/20 text-purple-400 border-purple-500/30', textKey: 'portfolio.status.finalized' };
        case MarketStatus.Cancelled:
            return { color: 'bg-orange-500/20 text-orange-400 border-orange-500/30', textKey: 'portfolio.status.refunded' };
        default:
            return { color: 'bg-gray-500/20 text-gray-400 border-gray-500/30', textKey: 'portfolio.status.open' };
    }
};

/**
 * 获取头寸的 claim 状态
 */
export const getClaimStatus = (position: Position): ClaimStatus => {
    const { state, winnerOutcome } = position.market;

    // 市场未结算，还在进行中
    if (state === MarketStatus.Open || state === MarketStatus.Locked) {
        return 'pending';
    }

    // 市场已取消，可退款
    if (state === MarketStatus.Cancelled) {
        const balance = parseFloat(position.balance);
        if (balance > 0) {
            return 'refundable';
        }
        return 'claimed'; // 已退款
    }

    // 市场已结算（Resolved 或 Finalized）
    if (state === MarketStatus.Resolved || state === MarketStatus.Finalized) {
        // 用户的 outcome 与赢家 outcome 匹配
        // 注意：GraphQL 返回 null 而非 undefined，需要使用 != null 检查
        if (winnerOutcome != null && winnerOutcome === position.outcome) {
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
 * 计算预期赔付金额（Pari-mutuel 模式）
 *
 * Payout = 如果该结果胜出，用户能获得的金额
 *
 * 市场 Cancelled 状态：显示 0
 *
 * 其他状态（Open/Locked/Resolved/Finalized）：
 *   预期赔付 = 净池子 × (用户投注额 / 该结果总投注)
 *   - 净池子 = totalVolume - feeAccrued
 *   - 用户投注额 = totalInvested（已扣手续费）
 *   - 该结果总投注 = outcomeVolume
 *
 * 注意：Subgraph 返回的金额字段（totalVolume, feeAccrued, outcomeVolume, totalInvested）
 * 已经是 USDC 单位（如 "6.86"），不是链上原始值（wei）。
 */
export const calculateExpectedPayout = (position: Position): number => {
    try {
        const { state, totalVolume, feeAccrued, outcomeVolumes } = position.market;

        // 市场已取消：显示 0
        if (state === MarketStatus.Cancelled) {
            return 0;
        }

        // 其他状态：计算预期赔付
        // Subgraph 返回的金额已是 USDC 单位，直接使用
        const userInvestment = parseFloat(position.totalInvested || '0');
        if (userInvestment <= 0) {
            return 0;
        }

        const totalVolumeNum = parseFloat(totalVolume || '0');
        const feeAccruedNum = parseFloat(feeAccrued || '0');

        // 净池子 = 总投注 - 手续费
        const netPool = totalVolumeNum - feeAccruedNum;
        if (netPool <= 0) {
            return 0;
        }

        // 获取该结果的总投注额
        const outcomeVolume = outcomeVolumes?.find(ov => ov.outcomeId === position.outcome);
        const outcomeVolumeNum = parseFloat(outcomeVolume?.volume || '0');
        if (outcomeVolumeNum <= 0) {
            return 0;
        }

        // 预期赔付 = 净池子 × (用户投注额 / 该结果总投注)
        // 所有金额已是 USDC 单位，不需要再转换
        const expectedPayout = (netPool * userInvestment) / outcomeVolumeNum;

        return expectedPayout;
    } catch (error) {
        console.error('[Portfolio] 计算预期赔付失败:', error, position);
        return 0;
    }
};

/**
 * 获取投注结果状态（返回 i18n key）
 */
export const getResultKey = (position: Position): string => {
    const { state, winnerOutcome } = position.market;

    // 市场已取消
    if (state === MarketStatus.Cancelled) {
        return 'portfolio.cancelled';
    }

    // 市场未结算
    if (winnerOutcome == null) {
        return 'portfolio.pending';
    }

    // 市场已结算
    if (winnerOutcome === position.outcome) {
        return 'portfolio.win';
    } else {
        return 'portfolio.lose';
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

    // WDL (胜平负): 显示押注的队伍名称 - 包括 WDL 和 WDL_Pari
    if (templateId === '1' || templateId === 'WDL' || templateId === 'WDL_Pari' || templateId === '0x00000000') {
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

    // Score (精确比分) - 包括 Score 和 Score_Pari
    if (templateId === '5' || templateId === 'Score' || templateId === 'Score_Pari') {
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
export const formatTxHash = (hash: string | undefined): string => {
    if (!hash) return '-';
    const cleanHash = hash.startsWith('0x') ? hash : `0x${hash}`;
    if (cleanHash.length <= 12) return cleanHash;
    return `${cleanHash.slice(0, 6)}...${cleanHash.slice(-4)}`;
};

/**
 * 获取区块浏览器交易链接
 * @param hash - 交易哈希
 * @returns BaseScan 交易链接
 */
export const getTxExplorerUrl = (hash: string | undefined): string | undefined => {
    if (!hash) return undefined;
    const cleanHash = hash.startsWith('0x') ? hash : `0x${hash}`;
    return `https://basescan.org/tx/${cleanHash}`;
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

/**
 * 默认手续费率（基点）
 * 200 = 2%
 */
const DEFAULT_FEE_RATE_BPS = 200;

/**
 * 获取原始押注金额（未扣手续费）
 *
 * 优先使用 Subgraph 的 totalPayment 字段（通过 BettingRouter 下注时记录）
 * 如果 totalPayment 不存在（旧数据或直接调用 Market 下注），则通过 totalInvested 计算
 *
 * 注意：Subgraph 返回的 totalInvested/totalPayment 已经是 USDC 单位（如 "0.98"），
 * 而不是链上原始值（如 "980000"）。此函数返回的是**链上原始值（6位小数）**，
 * 用于后续与 formatUSDC 配合使用。
 *
 * @param position - 用户头寸
 * @returns 原始押注金额（链上原始值，需要除以 10^6 才是 USDC）
 */
export const getOriginalPayment = (position: Position): string => {
    // 优先使用 Subgraph 的 totalPayment 字段（已是 USDC 单位）
    if (position.totalPayment && parseFloat(position.totalPayment) > 0) {
        // 转换为链上原始值
        return (parseFloat(position.totalPayment) * 1_000_000).toString();
    }

    // 回退：通过 totalInvested 计算（已是 USDC 单位）
    const invested = parseFloat(position.totalInvested || '0');
    if (invested <= 0) return '0';

    // 原始金额 = 净金额 / (1 - 手续费率)
    // 手续费率 = 200 / 10000 = 0.02
    const feeRate = DEFAULT_FEE_RATE_BPS / 10000;
    const originalPayment = invested / (1 - feeRate);

    // 转换为链上原始值（6位小数）
    return (originalPayment * 1_000_000).toString();
};

/**
 * @deprecated 使用 getOriginalPayment 代替
 */
export const calculateOriginalPayment = getOriginalPayment;

/**
 * 计算投注赔率（Parimutuel 模式）
 * 公式: odds = totalPool * (1 - fee) / outcomePool
 *      = (totalVolume - feeAccrued) / outcomeVolume
 *
 * 与 markets 列表使用相同的计算方式
 *
 * @param position - 用户头寸
 * @returns 赔率字符串（如 "1.85"）
 */
export const calculateOdds = (position: Position): string => {
    try {
        const { totalVolume, feeAccrued, outcomeVolumes } = position.market;

        // 获取市场总投注额和手续费
        const totalVolumeNum = parseFloat(totalVolume || '0');
        const feeAccruedNum = parseFloat(feeAccrued || '0');

        // 净池子 = 总投注 - 手续费
        const netPool = totalVolumeNum - feeAccruedNum;
        if (netPool <= 0) {
            return '-';
        }

        // 获取该结果的总投注额
        const outcomeVolume = outcomeVolumes?.find(ov => ov.outcomeId === position.outcome);
        const outcomeVolumeNum = parseFloat(outcomeVolume?.volume || '0');
        if (outcomeVolumeNum <= 0) {
            return '-';
        }

        // 赔率 = 净池子 / 该结果投注额
        const odds = netPool / outcomeVolumeNum;

        // 限制赔率范围
        if (odds < 1.01) return '1.01';
        if (odds > 999) return '999+';

        return odds.toFixed(2);
    } catch (error) {
        console.error('[Portfolio] 计算赔率失败:', error, position);
        return '-';
    }
};
