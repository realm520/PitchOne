/**
 * 精度配置 - 集中管理所有代币和业务精度
 *
 * 部署到不同链时，可以在此文件统一修改精度配置
 */

/**
 * 代币精度配置
 */
export const TOKEN_DECIMALS = {
  /**
   * USDC 代币精度
   * - 以太坊主网: 6
   * - Polygon: 6
   * - Arbitrum: 6
   * - Base: 6
   * - 本地测试链 (Anvil): 6
   */
  USDC: 6,

  /**
   * ERC-1155 份额精度 (Shares)
   * - 标准固定为 18 位小数
   */
  SHARES: 18,
} as const;

/**
 * 业务精度配置
 */
export const BUSINESS_DECIMALS = {
  /**
   * 赔率精度
   * - 10000 = 1.0000x
   * - 支持 4 位小数精度
   */
  ODDS: 4,

  /**
   * 基点 (Basis Points) 精度
   * - 10000 = 100.00%
   * - 支持 2 位小数精度
   */
  BPS: 2,
} as const;

/**
 * 获取 USDC 代币精度
 *
 * @returns USDC 代币精度
 */
export function getUSDCDecimals(): number {
  return TOKEN_DECIMALS.USDC;
}

/**
 * 获取 Shares 精度
 *
 * @returns Shares 精度
 */
export function getSharesDecimals(): number {
  return TOKEN_DECIMALS.SHARES;
}

/**
 * 获取赔率精度
 *
 * @returns 赔率精度
 */
export function getOddsDecimals(): number {
  return BUSINESS_DECIMALS.ODDS;
}

/**
 * 获取基点精度
 *
 * @returns 基点精度
 */
export function getBPSDecimals(): number {
  return BUSINESS_DECIMALS.BPS;
}

/**
 * USDC 缩放因子 (10^6)
 * 用于将 wei 值转换为 USDC 显示值
 */
export const USDC_SCALE = Math.pow(10, TOKEN_DECIMALS.USDC);

/**
 * 将 USDC wei 值转换为显示值
 *
 * @param weiValue - USDC wei 值（BigInt 字符串或数字）
 * @returns USDC 显示值（数字）
 *
 * @example
 * formatUSDCFromWei('1000000') // => 1
 * formatUSDCFromWei(1000000) // => 1
 */
export function formatUSDCFromWei(weiValue: string | number | bigint): number {
  return Number(weiValue) / USDC_SCALE;
}
