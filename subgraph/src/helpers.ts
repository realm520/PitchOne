/**
 * PitchOne Subgraph - 辅助工具函数
 * 提供实体加载、创建和转换的通用函数
 */

import { BigInt, BigDecimal, Address, Bytes, store } from "@graphprotocol/graph-ts";
import {
  Market,
  User,
  Position,
  GlobalStats,
} from "../generated/schema";

// ============================================================================
// 常量定义
// ============================================================================

export const ZERO_BI = BigInt.fromI32(0);
export const ONE_BI = BigInt.fromI32(1);
export const ZERO_BD = BigDecimal.fromString("0");
export const ONE_BD = BigDecimal.fromString("1");
export const BI_18 = BigInt.fromI32(18);

// 10^18 用于转换 wei 到 USDC (假设 6 位小数)
export const USDC_DECIMALS = 6;
export const USDC_DIVISOR = BigInt.fromI32(10).pow(USDC_DECIMALS as u8);

/**
 * 将 BigInt (wei) 转换为 BigDecimal (USDC)
 * @param value - 金额（wei）
 * @returns BigDecimal 表示的 USDC 金额
 */
export function toDecimal(value: BigInt): BigDecimal {
  return value.toBigDecimal().div(USDC_DIVISOR.toBigDecimal());
}

/**
 * 将 BigDecimal 转换为 BigInt (wei)
 * @param value - BigDecimal 金额
 * @returns BigInt 表示的 wei 金额
 */
export function fromDecimal(value: BigDecimal): BigInt {
  return BigInt.fromString(
    value.times(USDC_DIVISOR.toBigDecimal()).truncate(0).toString()
  );
}

// ============================================================================
// 实体加载或创建
// ============================================================================

/**
 * 加载或创建 User 实体
 * @param address - 用户地址
 * @returns User 实体
 */
export function loadOrCreateUser(address: Address): User {
  let user = User.load(address.toHexString());

  if (user === null) {
    user = new User(address.toHexString());
    user.totalBetAmount = ZERO_BD;
    user.totalRedeemed = ZERO_BD;
    user.netProfit = ZERO_BD;
    user.totalBets = 0;
    user.marketsParticipated = 0;
    user.firstBetAt = null;
    user.lastBetAt = null;
    user.referrer = null;
    user.save();

    // 更新全局用户数
    let stats = loadOrCreateGlobalStats();
    stats.totalUsers = stats.totalUsers + 1;
    stats.save();
  }

  return user as User;
}

/**
 * 加载或创建 Position 实体
 * @param marketAddress - 市场地址
 * @param userAddress - 用户地址
 * @param outcome - 头寸方向
 * @returns Position 实体
 */
export function loadOrCreatePosition(
  marketAddress: Address,
  userAddress: Address,
  outcome: i32
): Position {
  const positionId = marketAddress
    .toHexString()
    .concat("-")
    .concat(userAddress.toHexString())
    .concat("-")
    .concat(outcome.toString());

  let position = Position.load(positionId);

  if (position === null) {
    position = new Position(positionId);
    position.market = marketAddress.toHexString();
    position.owner = userAddress.toHexString();
    position.outcome = outcome;
    position.balance = ZERO_BI;
    position.averageCost = ZERO_BD;
    position.totalInvested = ZERO_BD;
    position.lastUpdatedAt = ZERO_BI;
    position.save();
  }

  return position as Position;
}

/**
 * 加载或创建 GlobalStats 实体
 * @returns GlobalStats 实体
 */
export function loadOrCreateGlobalStats(): GlobalStats {
  let stats = GlobalStats.load("global");

  if (stats === null) {
    stats = new GlobalStats("global");
    stats.totalMarkets = 0;
    stats.totalUsers = 0;
    stats.totalVolume = ZERO_BD;
    stats.totalFees = ZERO_BD;
    stats.totalRedeemed = ZERO_BD;
    stats.activeMarkets = 0;
    stats.resolvedMarkets = 0;
    stats.lastUpdatedAt = ZERO_BI;
    stats.save();
  }

  return stats as GlobalStats;
}

/**
 * 更新 Position 的平均成本
 * @param position - Position 实体
 * @param newAmount - 新增投入金额（USDC）
 * @param newShares - 新增份额
 */
export function updatePositionAverageCost(
  position: Position,
  newAmount: BigDecimal,
  newShares: BigInt
): void {
  const totalInvested = position.totalInvested.plus(newAmount);
  const totalShares = position.balance.plus(newShares);

  if (totalShares.gt(ZERO_BI)) {
    position.averageCost = totalInvested
      .div(totalShares.toBigDecimal());
  }

  position.totalInvested = totalInvested;
  position.balance = totalShares;
}

/**
 * 检查用户是否首次参与某市场
 * @param user - User 实体
 * @param marketAddress - 市场地址
 * @returns 是否首次参与
 */
export function isFirstTimeInMarket(userAddress: Address, marketAddress: Address): boolean {
  // 检查常见的 outcome (0, 1, 2) 是否有任何 position
  for (let i = 0; i < 3; i++) {
    const positionId = marketAddress
      .toHexString()
      .concat("-")
      .concat(userAddress.toHexString())
      .concat("-")
      .concat(i.toString());

    const position = Position.load(positionId);
    if (position !== null && position.totalInvested.gt(ZERO_BD)) {
      return false; // 已经在这个市场下过注了
    }
  }

  return true; // 首次参与
}

/**
 * 生成唯一的事件 ID
 * @param txHash - 交易哈希
 * @param logIndex - 日志索引
 * @returns 唯一 ID
 */
export function generateEventId(txHash: Bytes, logIndex: BigInt): string {
  return txHash
    .toHexString()
    .concat("-")
    .concat(logIndex.toString());
}

