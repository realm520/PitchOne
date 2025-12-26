// 市场状态映射
export const STATUS_MAP = {
  Open: { label: '开盘中', color: 'bg-green-100 text-green-800' },
  Locked: { label: '已锁盘', color: 'bg-yellow-100 text-yellow-800' },
  Resolved: { label: '已结算', color: 'bg-blue-100 text-blue-800' },
  Finalized: { label: '已完成', color: 'bg-gray-100 text-gray-800' },
} as const;

// 玩法类型映射
export const TEMPLATE_MAP: Record<string, string> = {
  WDL: '胜平负',
  OU: '大小球',
  AH: '让球',
  Score: '精确比分',
  ODDEVEN: '单双',
  PLAYERPROPS: '球员道具',
};

// 从 templateId (bytes32 hex string) 解析模板类型
// templateId 可能是:
// - 完整的 keccak256 哈希 (0x...)
// - 类似 "WDL_V3" 的字符串
// - 或者其他格式
export function parseTemplateType(templateId?: string): string {
  if (!templateId) return 'WDL'; // 默认

  // 如果 templateId 不是 hex 字符串，直接尝试匹配
  if (!templateId.startsWith('0x')) {
    const upper = templateId.toUpperCase();
    // 尝试提取前缀 (WDL, OU, AH 等)
    for (const key of Object.keys(TEMPLATE_MAP)) {
      if (upper.startsWith(key)) {
        return key;
      }
    }
    return upper.slice(0, 3);
  }

  // 如果是 hex 字符串，检查是否包含可读的模板名称
  // bytes32 转换的 hex 字符串中，模板名称会出现在开头
  // 例如: "WDL" -> 0x57444c...（ASCII 码）
  // 尝试解码 hex 字符串的前几个字节为 ASCII
  try {
    const hexData = templateId.slice(2); // 移除 "0x"
    let decoded = '';

    // 逐字节解码，直到遇到 0x00 或非 ASCII 字符
    for (let i = 0; i < hexData.length && i < 20; i += 2) { // 最多读取 10 个字符
      const byte = parseInt(hexData.slice(i, i + 2), 16);
      if (byte === 0) break; // 遇到 null 终止符
      if (byte >= 32 && byte <= 126) { // 可打印 ASCII
        decoded += String.fromCharCode(byte);
      } else {
        break; // 遇到非 ASCII 字符
      }
    }

    if (decoded.length >= 2) {
      const upper = decoded.toUpperCase();
      // 尝试匹配已知模板类型
      for (const key of Object.keys(TEMPLATE_MAP)) {
        if (upper.startsWith(key)) {
          return key;
        }
      }
      // 如果无法匹配，返回解码的前几个字符
      return upper.slice(0, 3);
    }
  } catch {
    // 解码失败，忽略
  }

  // 无法解析，返回默认值
  return 'WDL';
}

// 联赛映射
export const LEAGUE_MAP: Record<string, string> = {
  EPL: '英超联赛', LALIGA: '西甲联赛', SERIEA: '意甲联赛',
  BUNDESLIGA: '德甲联赛', LIGUE1: '法甲联赛', UCL: '欧冠联赛',
  UEL: '欧联杯', WC: '世界杯', NBA: 'NBA', MLB: 'MLB',
};

// 结果选项配置
const OUTCOME_OPTIONS: Record<string, { id: number; label: string; isPush?: boolean; description?: string }[]> = {
  WDL: [
    { id: 0, label: '主队胜', description: '主队获胜' },
    { id: 1, label: '平局', description: '双方打平' },
    { id: 2, label: '客队胜', description: '客队获胜' },
  ],
  OU: [
    { id: 0, label: '大 (Over)', description: '总进球数超过盘口' },
    { id: 1, label: '小 (Under)', description: '总进球数低于盘口' },
    { id: 2, label: '走盘 (Push)', isPush: true, description: '整球盘恰好相等，1:1 退回本金' },
  ],
  AH: [
    { id: 0, label: '主队赢盘', description: '主队让球后获胜' },
    { id: 1, label: '客队赢盘', description: '客队让球后获胜' },
    { id: 2, label: '走盘 (Push)', isPush: true, description: '整球盘抵消，1:1 退回本金' },
  ],
  ODDEVEN: [
    { id: 0, label: '奇数', description: '总进球数为奇数' },
    { id: 1, label: '偶数', description: '总进球数为偶数' },
  ],
};

const DEFAULT_OPTIONS = [
  { id: 0, label: '选项 A' },
  { id: 1, label: '选项 B' },
  { id: 2, label: '选项 C' },
];

export function getOutcomeOptions(
  templateType?: string,
  homeTeam?: string,
  awayTeam?: string,
  outcomeCount?: number
) {
  let options = OUTCOME_OPTIONS[templateType?.toUpperCase() || ''] || DEFAULT_OPTIONS;

  // 如果提供了 outcomeCount，过滤掉超出范围的选项
  // 例如：半球盘 AH/OU 市场只有 2 个 outcome，不包含走盘选项
  if (outcomeCount !== undefined && outcomeCount > 0) {
    options = options.filter(opt => opt.id < outcomeCount);
  }

  // 如果提供了球队名称，替换选项中的"主队"/"客队"
  if (homeTeam && awayTeam) {
    return options.map(opt => ({
      ...opt,
      label: opt.label
        .replace('主队胜', `${homeTeam} 胜`)
        .replace('客队胜', `${awayTeam} 胜`)
        .replace('主队赢盘', `${homeTeam} 赢盘`)
        .replace('客队赢盘', `${awayTeam} 赢盘`),
    }));
  }

  return options;
}

export function getOutcomeName(templateType?: string, outcomeId?: number): string {
  if (outcomeId === undefined || outcomeId === null) return '--';
  const option = getOutcomeOptions(templateType).find(o => o.id === outcomeId);
  return option?.label || `结果 ${outcomeId}`;
}

// 解析 matchId
export function parseMatchInfo(matchId: string) {
  const parts = matchId.split('_');
  if (parts.length >= 4) {
    const vsIndex = parts.findIndex(p => p.toLowerCase() === 'vs');
    if (vsIndex > 2) {
      return {
        league: parts[0],
        season: parts[1],
        homeTeam: parts.slice(2, vsIndex).join(' '),
        awayTeam: parts.slice(vsIndex + 1).join(' '),
      };
    }
  }
  return { league: 'Unknown', season: '-', homeTeam: matchId, awayTeam: '' };
}

// 地址缩写
export function shortAddr(addr: string) {
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

// USDC 格式化（6 位小数）
const USDC_DECIMALS = 6;

export function formatUSDC(value: string | number | undefined | null): string {
  if (value === undefined || value === null) return '0.00';
  const num = Number(value);
  if (isNaN(num)) return '0.00';
  // 如果数值大于 1000000，认为是原始值（需要除以 10^6）
  // 否则认为已经是标准单位
  const normalized = num > 1000000 ? num / Math.pow(10, USDC_DECIMALS) : num;
  return normalized.toFixed(2);
}
