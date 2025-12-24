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
};

// 联赛映射
export const LEAGUE_MAP: Record<string, string> = {
  EPL: '英超联赛', LALIGA: '西甲联赛', SERIEA: '意甲联赛',
  BUNDESLIGA: '德甲联赛', LIGUE1: '法甲联赛', UCL: '欧冠联赛',
  UEL: '欧联杯', WC: '世界杯', NBA: 'NBA', MLB: 'MLB',
};

// 结果选项配置
const OUTCOME_OPTIONS: Record<string, { id: number; label: string; isPush?: boolean; description?: string }[]> = {
  WDL: [
    { id: 0, label: '主队胜' },
    { id: 1, label: '平局' },
    { id: 2, label: '客队胜' },
  ],
  OU: [
    { id: 0, label: '大 (Over)' },
    { id: 1, label: '小 (Under)' },
    { id: 2, label: '走盘', isPush: true, description: '整球盘恰好相等，1:1 退回本金' },
  ],
  AH: [
    { id: 0, label: '主队赢盘' },
    { id: 1, label: '客队赢盘' },
    { id: 2, label: '走盘', isPush: true, description: '整球盘抵消，1:1 退回本金' },
  ],
  ODDEVEN: [
    { id: 0, label: '奇数' },
    { id: 1, label: '偶数' },
  ],
};

const DEFAULT_OPTIONS = [
  { id: 0, label: '结果 0' },
  { id: 1, label: '结果 1' },
  { id: 2, label: '结果 2' },
];

export function getOutcomeOptions(templateType?: string) {
  return OUTCOME_OPTIONS[templateType?.toUpperCase() || ''] || DEFAULT_OPTIONS;
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
