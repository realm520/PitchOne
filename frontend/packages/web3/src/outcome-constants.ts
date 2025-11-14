/**
 * Outcome 常量定义 - 对应合约中的 Outcome IDs
 *
 * 所有 outcome 名称必须与合约定义保持一致
 * 参考：contracts/src/templates/*.sol
 */

/**
 * WDL (胜平负) 市场 Outcome 定义
 * 对应合约：WDL_Template.sol
 *
 * Outcome IDs:
 * - 0: 主队胜 (Win)
 * - 1: 平局 (Draw)
 * - 2: 主队负/客队胜 (Loss)
 */
export const WDL_OUTCOMES = {
  HOME_WIN: 0,
  DRAW: 1,
  AWAY_WIN: 2,
} as const;

export const WDL_OUTCOME_NAMES: Record<number, string> = {
  [WDL_OUTCOMES.HOME_WIN]: '主胜',
  [WDL_OUTCOMES.DRAW]: '平局',
  [WDL_OUTCOMES.AWAY_WIN]: '客胜',
};

/**
 * OU (大小球) 市场 Outcome 定义
 * 对应合约：OU_Template.sol, OU_MultiLine.sol
 *
 * Outcome IDs:
 * - 0: 大球 (Over)
 * - 1: 小球 (Under)
 */
export const OU_OUTCOMES = {
  OVER: 0,
  UNDER: 1,
} as const;

export const OU_OUTCOME_NAMES: Record<number, string> = {
  [OU_OUTCOMES.OVER]: '大球',
  [OU_OUTCOMES.UNDER]: '小球',
};

/**
 * AH (让球) 市场 Outcome 定义
 * 对应合约：AH_Template.sol
 *
 * Outcome IDs (半球盘):
 * - 0: 主队赢盘 (Home Cover)
 * - 1: 客队赢盘 (Away Cover)
 *
 * Outcome IDs (整球盘):
 * - 0: 主队赢盘 (Home Cover)
 * - 1: 客队赢盘 (Away Cover)
 * - 2: 走盘 (Push)
 */
export const AH_OUTCOMES = {
  HOME_COVER: 0,
  AWAY_COVER: 1,
  PUSH: 2,
} as const;

export const AH_OUTCOME_NAMES: Record<number, string> = {
  [AH_OUTCOMES.HOME_COVER]: '主队赢盘',
  [AH_OUTCOMES.AWAY_COVER]: '客队赢盘',
  [AH_OUTCOMES.PUSH]: '走盘',
};

/**
 * OddEven (单双) 市场 Outcome 定义
 * 对应合约：OddEven_Template.sol
 *
 * Outcome IDs:
 * - 0: 单数 (Odd)
 * - 1: 双数 (Even)
 */
export const ODDEVEN_OUTCOMES = {
  ODD: 0,
  EVEN: 1,
} as const;

export const ODDEVEN_OUTCOME_NAMES: Record<number, string> = {
  [ODDEVEN_OUTCOMES.ODD]: '单数',
  [ODDEVEN_OUTCOMES.EVEN]: '双数',
};

/**
 * Score (精确比分) 市场 Outcome 定义
 * 对应合约：ScoreTemplate.sol
 *
 * Outcome IDs: homeGoals * 10 + awayGoals
 * - 例如：2-1 = 21, 0-0 = 0
 * - 999: Other (其他比分)
 */
export const SCORE_OUTCOMES = {
  OTHER: 999,
} as const;

/**
 * 格式化比分 outcome
 * @param outcomeId - Outcome ID
 * @returns 格式化的比分字符串（如 "2-1"）
 */
export function formatScoreOutcome(outcomeId: number): string {
  if (outcomeId === SCORE_OUTCOMES.OTHER) {
    return '其他比分';
  }
  const homeGoals = Math.floor(outcomeId / 10);
  const awayGoals = outcomeId % 10;
  return `${homeGoals}-${awayGoals}`;
}

/**
 * PlayerProps (球员道具) 市场 Outcome 定义
 * 对应合约：PlayerProps_Template.sol
 *
 * 根据道具类型不同，outcome 含义不同：
 * - O/U 类型：0 = Over, 1 = Under
 * - Y/N 类型：0 = Yes, 1 = No
 * - 首位进球者：使用 LMSR，outcome = 球员 ID
 */
export const PLAYER_PROPS_OUTCOMES = {
  // O/U 类型
  OVER: 0,
  UNDER: 1,

  // Y/N 类型
  YES: 0,
  NO: 1,
} as const;

export const PLAYER_PROPS_OU_NAMES: Record<number, string> = {
  [PLAYER_PROPS_OUTCOMES.OVER]: '大于',
  [PLAYER_PROPS_OUTCOMES.UNDER]: '小于',
};

export const PLAYER_PROPS_YN_NAMES: Record<number, string> = {
  [PLAYER_PROPS_OUTCOMES.YES]: '是',
  [PLAYER_PROPS_OUTCOMES.NO]: '否',
};

/**
 * 通用工具函数：根据市场类型和 outcome ID 获取名称
 *
 * @param templateId - 市场模板 ID
 * @param outcomeId - Outcome ID
 * @param propType - 球员道具类型（可选）
 * @returns Outcome 名称
 */
export function getOutcomeName(
  templateId: string | undefined,
  outcomeId: number,
  propType?: string
): string {
  if (!templateId) {
    return `结果 ${outcomeId}`;
  }

  // 根据模板类型返回对应名称
  if (templateId === 'WDL' || templateId === '0x00000000') {
    return WDL_OUTCOME_NAMES[outcomeId] || `结果 ${outcomeId}`;
  }

  if (templateId === 'OU' || templateId?.includes('OU')) {
    return OU_OUTCOME_NAMES[outcomeId] || `结果 ${outcomeId}`;
  }

  if (templateId === 'AH') {
    return AH_OUTCOME_NAMES[outcomeId] || `结果 ${outcomeId}`;
  }

  if (templateId === 'OddEven') {
    return ODDEVEN_OUTCOME_NAMES[outcomeId] || `结果 ${outcomeId}`;
  }

  if (templateId === 'Score') {
    return formatScoreOutcome(outcomeId);
  }

  if (templateId === 'PlayerProps') {
    // 根据道具类型返回不同名称
    if (propType?.includes('OU')) {
      return PLAYER_PROPS_OU_NAMES[outcomeId] || `结果 ${outcomeId}`;
    }
    if (propType?.includes('YN')) {
      return PLAYER_PROPS_YN_NAMES[outcomeId] || `结果 ${outcomeId}`;
    }
    // 首位进球者类型
    return `球员 ${outcomeId}`;
  }

  // 默认返回
  return `结果 ${outcomeId}`;
}
