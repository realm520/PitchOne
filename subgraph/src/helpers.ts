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
  OutcomeVolume,
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
 * 将 BigInt (wei) 转换为 BigDecimal
 * @param value - 金额（wei）
 * @param decimals - 小数位数（默认 6 for USDC）
 * @returns BigDecimal 表示的金额
 */
export function toDecimal(value: BigInt, decimals: i32 = 6): BigDecimal {
  if (decimals == 6) {
    return value.toBigDecimal().div(USDC_DIVISOR.toBigDecimal());
  }

  const divisor = BigInt.fromI32(10).pow(decimals as u8);
  return value.toBigDecimal().div(divisor.toBigDecimal());
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
    user.totalPayment = ZERO_BD;
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
 * @param txHash - 交易哈希（可选，用于新创建的 position）
 * @param timestamp - 时间戳（可选，用于新创建的 position）
 * @returns Position 实体
 */
export function loadOrCreatePosition(
  marketAddress: Address,
  userAddress: Address,
  outcome: i32,
  txHash: Bytes | null = null,
  timestamp: BigInt | null = null
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
    position.totalPayment = ZERO_BD;
    position.createdTxHash = txHash;
    position.createdAt = timestamp !== null ? timestamp : ZERO_BI;
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

/**
 * 球队代码到全称的映射
 */
function getTeamFullName(code: string): string {
  // 意甲球队
  if (code == "MIL") return "AC Milan";
  if (code == "INT") return "Inter";
  if (code == "JUV") return "Juventus";
  if (code == "NAP") return "Napoli";
  if (code == "ROM") return "AS Roma";
  if (code == "LAZ") return "Lazio";
  if (code == "ATA") return "Atalanta";
  if (code == "FIO") return "Fiorentina";
  if (code == "BOL") return "Bologna";
  if (code == "TOR") return "Torino";
  if (code == "UDI") return "Udinese";
  if (code == "SAS") return "Sassuolo";
  if (code == "EMP") return "Empoli";
  if (code == "SAL") return "Salernitana";
  if (code == "LEC") return "Lecce";
  if (code == "VER") return "Verona";
  if (code == "MON") return "Monza";
  if (code == "CAG") return "Cagliari";
  if (code == "GEN") return "Genoa";
  if (code == "FRO") return "Frosinone";
  if (code == "PAR") return "Parma";
  if (code == "VEN") return "Venezia";
  if (code == "COM") return "Como";
  if (code == "CRE") return "Cremonese";
  if (code == "SPE") return "Spezia";
  if (code == "SAM") return "Sampdoria";
  if (code == "PIS") return "Pisa";
  // 英超球队
  if (code == "MUN") return "Manchester United";
  if (code == "MCI") return "Manchester City";
  if (code == "LIV") return "Liverpool";
  if (code == "CHE") return "Chelsea";
  if (code == "ARS") return "Arsenal";
  if (code == "TOT") return "Tottenham";
  // 其他联赛
  if (code == "BAR") return "Barcelona";
  if (code == "RMA") return "Real Madrid";
  if (code == "BAY") return "Bayern Munich";
  if (code == "DOR") return "Borussia Dortmund";
  if (code == "PSG") return "Paris Saint-Germain";
  if (code == "LYO") return "Lyon";
  // 未知代码返回原值
  return code;
}

/**
 * 从 matchId 解析球队信息
 * matchId 格式: "SerieA_2025_R17_PAR_vs_FIO_WDL" 或 "EPL_2024_MUN_vs_MCI_WDL"
 * @param matchId - 比赛标识符
 * @returns [homeTeam, awayTeam] 元组，解析失败返回 ["", ""]
 */
export function parseTeamsFromMatchId(matchId: string): string[] {
  let vsIndex = matchId.indexOf("_vs_");
  if (vsIndex == -1) {
    return ["", ""];
  }

  // 获取 vs 之前的部分，找到最后一个 _，取球队代码
  let beforeVs = matchId.slice(0, vsIndex);
  let lastUnderscoreBefore = beforeVs.lastIndexOf("_");
  if (lastUnderscoreBefore == -1) {
    return ["", ""];
  }
  let homeCode = beforeVs.slice(lastUnderscoreBefore + 1);

  // 获取 vs 之后的部分
  let afterVs = matchId.slice(vsIndex + 4);  // +4 跳过 "_vs_"
  let firstUnderscoreAfter = afterVs.indexOf("_");
  let awayCode: string;
  if (firstUnderscoreAfter == -1) {
    awayCode = afterVs;
  } else {
    awayCode = afterVs.slice(0, firstUnderscoreAfter);
  }

  // 转换为全称
  return [getTeamFullName(homeCode), getTeamFullName(awayCode)];
}

// ============================================================================
// OutcomeVolume 实体管理
// ============================================================================

/**
 * 加载或创建 OutcomeVolume 实体
 * @param marketAddress - 市场地址
 * @param outcomeId - 结果 ID
 * @param timestamp - 时间戳（用于新创建的实体）
 * @returns OutcomeVolume 实体
 */
export function loadOrCreateOutcomeVolume(
  marketAddress: Address,
  outcomeId: i32,
  timestamp: BigInt
): OutcomeVolume {
  const id = marketAddress.toHexString().concat("-").concat(outcomeId.toString());
  let outcomeVolume = OutcomeVolume.load(id);

  if (outcomeVolume === null) {
    outcomeVolume = new OutcomeVolume(id);
    outcomeVolume.market = marketAddress.toHexString();
    outcomeVolume.outcomeId = outcomeId;
    outcomeVolume.volume = ZERO_BD;
    outcomeVolume.shares = ZERO_BI;
    outcomeVolume.betCount = 0;
    outcomeVolume.lastUpdatedAt = timestamp;
    outcomeVolume.save();
  }

  return outcomeVolume as OutcomeVolume;
}

