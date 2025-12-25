// 参数类别
export type ParamCategoryType = 'fee' | 'limit' | 'pricing' | 'referral' | 'other';

// 参数定义
export interface ParamDefinition {
  key: string;
  name: string;
  category: ParamCategoryType;
  unit: string;
  divisor: number;
  decimals: number;
  description: string;
  validator?: string;
  defaultValue: bigint;
}

// 参数类别标签
export const CATEGORY_LABELS: Record<ParamCategoryType, { label: string; color: string }> = {
  fee: { label: '费用', color: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' },
  limit: { label: '限额', color: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200' },
  pricing: { label: '定价', color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' },
  referral: { label: '推荐', color: 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200' },
  other: { label: '其他', color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200' },
};

// 所有参数定义（与合约 ParamKeys.sol 中的 12 个参数对应）
export const PARAM_DEFINITIONS: ParamDefinition[] = [
  // 费用参数
  {
    key: 'FEE_RATE',
    name: '基础费率',
    category: 'fee',
    unit: 'bp',
    divisor: 100,
    decimals: 2,
    description: '下注时收取的基础手续费率',
    validator: '0% - 10%',
    defaultValue: BigInt(200), // 2%
  },
  {
    key: 'FEE_LP_SHARE_BPS',
    name: 'LP 分成',
    category: 'fee',
    unit: 'bp',
    divisor: 100,
    decimals: 2,
    description: '手续费中分配给 LP 的比例',
    validator: '0% - 100%',
    defaultValue: BigInt(6000), // 60%
  },
  {
    key: 'FEE_PROMO_SHARE_BPS',
    name: '推广池分成',
    category: 'fee',
    unit: 'bp',
    divisor: 100,
    decimals: 2,
    description: '手续费中分配给推广池的比例',
    validator: '0% - 100%',
    defaultValue: BigInt(2000), // 20%
  },
  {
    key: 'FEE_INSURANCE_SHARE_BPS',
    name: '保险池分成',
    category: 'fee',
    unit: 'bp',
    divisor: 100,
    decimals: 2,
    description: '手续费中分配给保险金的比例',
    validator: '0% - 100%',
    defaultValue: BigInt(1000), // 10%
  },
  {
    key: 'FEE_TREASURY_SHARE_BPS',
    name: '国库分成',
    category: 'fee',
    unit: 'bp',
    divisor: 100,
    decimals: 2,
    description: '手续费中分配给国库的比例',
    validator: '0% - 100%',
    defaultValue: BigInt(1000), // 10%
  },

  // 限额参数
  {
    key: 'MIN_BET_AMOUNT',
    name: '最小下注额',
    category: 'limit',
    unit: 'USDC',
    divisor: 1000000,
    decimals: 2,
    description: '单笔下注的最小金额',
    validator: '0.1 - 100 USDC',
    defaultValue: BigInt(1000000), // 1 USDC (6 decimals)
  },
  {
    key: 'MAX_BET_AMOUNT',
    name: '最大下注额',
    category: 'limit',
    unit: 'USDC',
    divisor: 1000000,
    decimals: 2,
    description: '单笔下注的最大金额',
    validator: '1 - 1,000,000 USDC',
    defaultValue: BigInt(5000000), // 5 USDC
  },
  {
    key: 'USER_EXPOSURE_LIMIT',
    name: '单用户敞口',
    category: 'limit',
    unit: 'USDC',
    divisor: 1000000,
    decimals: 0,
    description: '单个用户在单个市场的最大敞口',
    validator: '1 - 1,000,000 USDC',
    defaultValue: BigInt(50000000000), // 50,000 USDC
  },
  {
    key: 'MARKET_PAYOUT_CAP',
    name: '市场赔付上限',
    category: 'limit',
    unit: 'USDC',
    divisor: 1000000,
    decimals: 0,
    description: '单个市场的最大赔付金额',
    validator: '1,000 - 100,000,000 USDC',
    defaultValue: BigInt(10000000000000), // 10,000,000 USDC
  },

  // 定价参数
  {
    key: 'MAX_ODDS',
    name: '最大赔率',
    category: 'pricing',
    unit: 'x',
    divisor: 10000,
    decimals: 2,
    description: '允许的最高赔率倍数',
    validator: '1.01x - 10000x',
    defaultValue: BigInt(10000000), // 1000x
  },
  {
    key: 'MIN_ODDS',
    name: '最小赔率',
    category: 'pricing',
    unit: 'x',
    divisor: 10000,
    decimals: 2,
    description: '允许的最低赔率倍数',
    validator: '1.0x - 1.01x',
    defaultValue: BigInt(10000), // 1.0x
  },
  {
    key: 'DISPUTE_WINDOW',
    name: '争议窗口期',
    category: 'other',
    unit: '秒',
    divisor: 1,
    decimals: 0,
    description: '结算后的争议期时长',
    validator: '30分钟 - 7天',
    defaultValue: BigInt(7200), // 2 hours
  },
];

// 所有参数 key
export const ALL_PARAM_KEYS = PARAM_DEFINITIONS.map(p => p.key);

// 按类别分组的参数配置（兼容旧格式）
export interface ParamCategory {
  category: string;
  params: ParamDefinition[];
}

export const PARAM_CONFIG: ParamCategory[] = [
  {
    category: '费用设置',
    params: PARAM_DEFINITIONS.filter(p => p.category === 'fee'),
  },
  {
    category: '投注限制',
    params: PARAM_DEFINITIONS.filter(p => p.category === 'limit'),
  },
  {
    category: '定价参数',
    params: PARAM_DEFINITIONS.filter(p => p.category === 'pricing'),
  },
  {
    category: '其他参数',
    params: PARAM_DEFINITIONS.filter(p => p.category === 'other'),
  },
];

// 格式化参数值显示
export function formatParamValue(value: bigint | undefined, divisor: number, decimals: number, unit: string): string {
  if (value === undefined) return '--';
  const num = Number(value) / divisor;
  if (unit === 'USDC') {
    return `${num.toLocaleString(undefined, { minimumFractionDigits: decimals, maximumFractionDigits: decimals })} USDC`;
  }
  if (unit === 'bp') {
    return `${num.toFixed(decimals)}%`;
  }
  return `${num.toFixed(decimals)} ${unit}`;
}

// 格式化秒数为人类可读格式
export function formatSeconds(seconds: number): string {
  if (seconds < 60) return `${seconds} 秒`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)} 分钟`;
  if (seconds < 86400) return `${(seconds / 3600).toFixed(1)} 小时`;
  return `${(seconds / 86400).toFixed(1)} 天`;
}
