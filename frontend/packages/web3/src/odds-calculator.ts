/**
 * 赔率计算工具 - 基于 Subgraph 数据计算各种定价策略的赔率
 *
 * 支持的定价策略：
 * - PARIMUTUEL: 奖池模式，赔率 = 总池子 / 该结果投注额
 * - CPMM: 恒定乘积做市商，使用储备量计算价格
 * - LMSR: 对数市场评分规则，使用 softmax 公式
 */

// OutcomeVolume 类型定义
export interface OutcomeVolume {
  id: string;
  outcomeId: number;
  volume: string;  // BigDecimal as string
  shares: string;  // BigInt as string
  betCount: number;
}

// 市场赔率数据接口
export interface MarketOddsData {
  pricingType: string | null;
  initialLiquidity: string | null;  // BigDecimal as string
  lmsrB: string | null;  // BigDecimal as string
  totalVolume: string;  // BigDecimal as string
  outcomeVolumes: OutcomeVolume[];
  feeRate?: number;  // 手续费率 (0-1)
  expectedOutcomeCount?: number;  // 预期的 outcome 数量（用于显示没有投注的 outcome）
}

// 单个结果的赔率信息
export interface OutcomeOdds {
  outcomeId: number;
  odds: number | null;  // null 表示无法计算（如没有投注）
  probability: number;  // 隐含概率 (0-1)
  volume: number;  // 该结果的投注金额
  shares: bigint;  // 该结果的份额
}

/**
 * 从 Subgraph 数据计算所有 outcome 的赔率
 *
 * @param data 市场赔率数据
 * @returns 各 outcome 的赔率数组
 */
export function calculateOddsFromSubgraph(data: MarketOddsData): OutcomeOdds[] {
  const { pricingType, initialLiquidity, lmsrB, totalVolume, outcomeVolumes, feeRate = 0.02, expectedOutcomeCount } = data;

  // 构建 outcomeId -> OutcomeVolume 的映射
  const volumeMap = new Map<number, OutcomeVolume>();
  for (const v of outcomeVolumes) {
    volumeMap.set(v.outcomeId, v);
  }

  // 确定需要显示的 outcome 数量
  // 优先使用 expectedOutcomeCount，否则使用已有数据中的最大 outcomeId + 1
  let outcomeCount = expectedOutcomeCount || 0;
  if (outcomeCount === 0 && outcomeVolumes.length > 0) {
    const maxOutcomeId = Math.max(...outcomeVolumes.map(v => v.outcomeId));
    outcomeCount = maxOutcomeId + 1;
  }

  // 如果还是 0，返回空数组
  if (outcomeCount === 0) {
    return [];
  }

  // 生成完整的 outcome 数组（包括没有投注的）
  const allVolumes: OutcomeVolume[] = [];
  for (let i = 0; i < outcomeCount; i++) {
    const existing = volumeMap.get(i);
    if (existing) {
      allVolumes.push(existing);
    } else {
      // 创建空的 OutcomeVolume
      allVolumes.push({
        id: `empty-${i}`,
        outcomeId: i,
        volume: '0',
        shares: '0',
        betCount: 0,
      });
    }
  }

  // 解析数值
  const totalVol = parseFloat(totalVolume) || 0;
  const initLiq = parseFloat(initialLiquidity || '0') || 0;
  const b = parseFloat(lmsrB || '0') || 0;

  // 根据定价类型选择计算方法
  switch (pricingType) {
    case 'PARIMUTUEL':
      return calculateParimutuelOdds(allVolumes, totalVol, feeRate);

    case 'CPMM':
      return calculateCPMMOdds(allVolumes, initLiq, feeRate);

    case 'LMSR':
      return calculateLMSROdds(allVolumes, initLiq, b, feeRate);

    default:
      // 默认使用 PARIMUTUEL（因为大多数市场是 Parimutuel）
      return calculateParimutuelOdds(allVolumes, totalVol, feeRate);
  }
}

/**
 * Parimutuel 奖池模式赔率计算
 * 公式: odds = totalPool * (1 - fee) / outcomePool
 */
function calculateParimutuelOdds(
  volumes: OutcomeVolume[],
  totalVolume: number,
  feeRate: number
): OutcomeOdds[] {
  return volumes.map(v => {
    const volume = parseFloat(v.volume) || 0;
    const shares = BigInt(v.shares || '0');

    let odds: number | null = null;
    let probability = 0;

    if (totalVolume > 0 && volume > 0) {
      // 赔率 = 扣费后的总池子 / 该结果投注额
      odds = (totalVolume * (1 - feeRate)) / volume;
      probability = 1 / odds;
    } else if (volume === 0 && totalVolume > 0) {
      // 该结果没有投注，赔率无限大
      odds = null;
      probability = 0;
    }

    return {
      outcomeId: v.outcomeId,
      odds,
      probability,
      volume,
      shares,
    };
  });
}

/**
 * CPMM 恒定乘积做市商赔率计算
 *
 * 使用投注量 (volume) 而非 shares 来计算储备变化
 * 因为 volume 和 initialLiquidity 单位一致（USDC）
 *
 * 储备变化逻辑：
 * - 初始储备：initialLiquidity / outcomeCount（均分）
 * - 下注到 outcome i 时：
 *   - outcome i 的储备减少（发放份额）
 *   - 其他 outcome 的储备增加（收到资金）
 *
 * 简化近似：
 * - reserve[i] = initialReserve - volume[i] + sum(volume[others]) / (outcomeCount - 1)
 */
function calculateCPMMOdds(
  volumes: OutcomeVolume[],
  initialLiquidity: number,
  feeRate: number
): OutcomeOdds[] {
  const outcomeCount = volumes.length;

  if (outcomeCount === 0 || initialLiquidity <= 0) {
    return volumes.map(v => ({
      outcomeId: v.outcomeId,
      odds: null,
      probability: 1 / Math.max(outcomeCount, 1),
      volume: parseFloat(v.volume) || 0,
      shares: BigInt(v.shares || '0'),
    }));
  }

  // 初始储备（均分）
  const initialReserve = initialLiquidity / outcomeCount;

  // 解析各 outcome 的投注量（使用 volume 而非 shares，因为单位与 initialLiquidity 一致）
  const volumeNums = volumes.map(v => parseFloat(v.volume) || 0);
  const totalVolume = volumeNums.reduce((a, b) => a + b, 0);

  // 如果没有任何投注，返回初始赔率（均分）
  if (totalVolume === 0) {
    const equalProb = 1 / outcomeCount;
    const equalOdds = 1 / (equalProb * (1 - feeRate));
    return volumes.map(v => ({
      outcomeId: v.outcomeId,
      odds: equalOdds,
      probability: equalProb,
      volume: 0,
      shares: BigInt(v.shares || '0'),
    }));
  }

  // 计算当前储备
  // reserve[i] = initialReserve + (流入资金) - (流出资金)
  // 简化模型：假设投注到某个 outcome 会按比例影响储备
  const reserves = volumeNums.map((vol, i) => {
    const otherVolume = totalVolume - vol;
    // 该 outcome 收到其他投注的一部分资金，同时支出自己的投注给池子
    // 储备增加 = 其他投注 / (outcomeCount - 1)
    // 储备减少 ≈ 本 outcome 投注量（用于兑换份额）
    const netChange = (otherVolume / Math.max(outcomeCount - 1, 1)) - vol * 0.5;
    return Math.max(initialReserve + netChange, initialReserve * 0.1);  // 最低保留 10% 初始储备
  });

  // 计算价格
  const prices = calculateCPMMPrices(reserves);

  return volumes.map((v, i) => {
    const volume = parseFloat(v.volume) || 0;
    const sharesBI = BigInt(v.shares || '0');
    const probability = prices[i];

    // 赔率 = 1 / (概率 * (1 - 手续费))
    const effectiveProb = probability * (1 - feeRate);
    const odds = effectiveProb > 0 ? 1 / effectiveProb : null;

    return {
      outcomeId: v.outcomeId,
      odds,
      probability,
      volume,
      shares: sharesBI,
    };
  });
}

/**
 * CPMM 价格公式：price[i] = (1/r[i]) / sum(1/r[j])
 */
function calculateCPMMPrices(reserves: number[]): number[] {
  const sumInverse = reserves.reduce((sum, r) => sum + (r > 0 ? 1 / r : 0), 0);

  if (sumInverse === 0) {
    return reserves.map(() => 1 / reserves.length);
  }

  return reserves.map(r => (r > 0 ? (1 / r) / sumInverse : 0));
}

/**
 * LMSR 对数市场评分规则赔率计算
 * 公式: price[i] = exp(q[i]/b) / sum(exp(q[j]/b))
 *
 * @param volumes outcome 数据
 * @param initialLiquidity 初始流动性（用于推算初始 b 如果未提供）
 * @param b 流动性参数
 * @param feeRate 手续费率
 */
function calculateLMSROdds(
  volumes: OutcomeVolume[],
  initialLiquidity: number,
  b: number,
  feeRate: number
): OutcomeOdds[] {
  const outcomeCount = volumes.length;

  // 如果 b 参数无效，使用初始流动性估算
  const effectiveB = b > 0 ? b : initialLiquidity / Math.log(outcomeCount);

  if (effectiveB <= 0) {
    return volumes.map(v => ({
      outcomeId: v.outcomeId,
      odds: null,
      probability: 1 / Math.max(outcomeCount, 1),
      volume: parseFloat(v.volume) || 0,
      shares: BigInt(v.shares || '0'),
    }));
  }

  // LMSR quantities (份额)
  const quantities = volumes.map(v => parseFloat(v.shares) || 0);

  // 计算 softmax
  const prices = calculateLMSRPrices(quantities, effectiveB);

  return volumes.map((v, i) => {
    const volume = parseFloat(v.volume) || 0;
    const sharesBI = BigInt(v.shares || '0');
    const probability = prices[i];

    // 赔率 = 1 / (概率 * (1 - 手续费))
    const effectiveProb = probability * (1 - feeRate);
    const odds = effectiveProb > 0 ? 1 / effectiveProb : null;

    return {
      outcomeId: v.outcomeId,
      odds,
      probability,
      volume,
      shares: sharesBI,
    };
  });
}

/**
 * LMSR softmax 价格公式: price[i] = exp(q[i]/b) / sum(exp(q[j]/b))
 * 使用数值稳定的 softmax 实现（减去最大值防止溢出）
 */
function calculateLMSRPrices(quantities: number[], b: number): number[] {
  if (b <= 0 || quantities.length === 0) {
    return quantities.map(() => 1 / Math.max(quantities.length, 1));
  }

  // 数值稳定：减去最大值
  const maxQ = Math.max(...quantities);
  const expValues = quantities.map(q => Math.exp((q - maxQ) / b));
  const sumExp = expValues.reduce((a, b) => a + b, 0);

  if (sumExp === 0) {
    return quantities.map(() => 1 / quantities.length);
  }

  return expValues.map(e => e / sumExp);
}

/**
 * 格式化赔率显示
 * @param odds 赔率数值
 * @param defaultValue 无效时的默认显示
 */
export function formatOdds(odds: number | null, defaultValue = '-'): string {
  if (odds === null || !isFinite(odds) || isNaN(odds)) {
    return defaultValue;
  }

  // 限制赔率上限
  if (odds > 999) return '999+';

  return odds.toFixed(2);
}
