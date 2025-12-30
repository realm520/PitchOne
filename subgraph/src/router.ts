/**
 * BettingRouter_V3 事件处理器
 *
 * 处理通过 BettingRouter 下注的事件，包含原始金额和手续费信息
 */

import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";
import { BetPlaced as RouterBetPlacedEvent } from "../generated/BettingRouter/BettingRouter_V3";
import { Market, Order, Position } from "../generated/schema";
import {
  loadOrCreateUser,
  loadOrCreatePosition,
  loadOrCreateGlobalStats,
  loadOrCreateOutcomeVolume,
  toDecimal,
  updatePositionAverageCost,
  generateEventId,
  isFirstTimeInMarket,
  ZERO_BI,
  ZERO_BD,
  ONE_BI,
} from "./helpers";

// ============================================================================
// BetPlaced - 通过 BettingRouter 下注事件
// event BetPlaced(
//   address indexed user,
//   address indexed market,
//   address indexed token,
//   uint256 outcomeId,
//   uint256 amount,      // 原始押注金额（未扣手续费）
//   uint256 shares,
//   uint256 fee
// )
// ============================================================================

export function handleRouterBetPlaced(event: RouterBetPlacedEvent): void {
  const userAddress = event.params.user;
  const marketAddress = event.params.market;
  const outcome = event.params.outcomeId.toI32();
  const originalAmount = event.params.amount;  // 原始金额（未扣手续费）
  const shares = event.params.shares;
  const fee = event.params.fee;

  // 计算净金额（扣除手续费后）
  const netAmount = originalAmount.minus(fee);

  // 加载市场实体
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    // 如果市场不存在，可能是因为 Market 事件还没有被处理
    // 创建一个基础的市场实体
    market = new Market(marketAddress.toHexString());
    market.templateId = "V3";
    market.matchId = "";
    market.homeTeam = "";
    market.awayTeam = "";
    market.kickoffTime = ZERO_BI;
    market.ruleVer = Bytes.empty();
    market.state = "Open";
    market.paused = false;
    market.createdAt = event.block.timestamp;
    market.totalVolume = ZERO_BD;
    market.feeAccrued = ZERO_BD;
    market.lpLiquidity = ZERO_BD;
    market.uniqueBettors = 0;
    market.oracle = null;
    market.pricingEngine = null;
  }

  // 加载或创建用户
  let user = loadOrCreateUser(userAddress);

  // 创建订单记录
  const orderId = generateEventId(event.transaction.hash, event.logIndex);
  let order = new Order(orderId);
  order.market = marketAddress.toHexString();
  order.user = userAddress.toHexString();
  order.outcome = outcome;
  order.amount = toDecimal(netAmount);  // 净金额（扣除手续费后）
  order.shares = shares;
  order.fee = toDecimal(fee);
  order.referrer = null;
  order.price = shares.gt(ZERO_BI)
    ? netAmount.toBigDecimal().div(shares.toBigDecimal())
    : ZERO_BD;
  order.timestamp = event.block.timestamp;
  order.blockNumber = event.block.number;
  order.transactionHash = event.transaction.hash;
  order.save();

  // 检查是否首次参与该市场
  const isFirstBetInMarket = isFirstTimeInMarket(userAddress, marketAddress);

  // 转换为 BigDecimal 用于统计
  const netAmountDecimal = toDecimal(netAmount);
  const originalAmountDecimal = toDecimal(originalAmount);
  const feeDecimal = toDecimal(fee);

  // 更新或创建头寸
  let position = loadOrCreatePosition(
    marketAddress,
    userAddress,
    outcome,
    event.transaction.hash,
    event.block.timestamp
  );

  // 更新平均成本（使用净金额）
  updatePositionAverageCost(position, netAmountDecimal, shares);

  // 更新 totalPayment（原始押注金额）
  position.totalPayment = position.totalPayment.plus(originalAmountDecimal);
  position.lastUpdatedAt = event.block.timestamp;
  position.save();

  // 更新用户统计（使用净金额）
  user.totalBetAmount = user.totalBetAmount.plus(netAmountDecimal);
  user.netProfit = user.netProfit.minus(netAmountDecimal);
  user.totalBets = user.totalBets + 1;

  if (user.firstBetAt === null) {
    user.firstBetAt = event.block.timestamp;
  }
  user.lastBetAt = event.block.timestamp;

  if (isFirstBetInMarket) {
    user.marketsParticipated = user.marketsParticipated + 1;
    market.uniqueBettors = market.uniqueBettors + 1;
  }
  user.save();

  // 更新市场统计
  market.totalVolume = market.totalVolume.plus(netAmountDecimal);
  market.feeAccrued = market.feeAccrued.plus(feeDecimal);
  market.save();

  // 更新 OutcomeVolume
  let outcomeVolume = loadOrCreateOutcomeVolume(marketAddress, outcome, event.block.timestamp);
  outcomeVolume.volume = outcomeVolume.volume.plus(netAmountDecimal);
  outcomeVolume.shares = outcomeVolume.shares.plus(shares);
  outcomeVolume.betCount = outcomeVolume.betCount + 1;
  outcomeVolume.lastUpdatedAt = event.block.timestamp;
  outcomeVolume.save();

  // 更新全局统计
  let globalStats = loadOrCreateGlobalStats();
  globalStats.totalVolume = globalStats.totalVolume.plus(netAmountDecimal);
  globalStats.totalFees = globalStats.totalFees.plus(feeDecimal);
  globalStats.lastUpdatedAt = event.block.timestamp;
  globalStats.save();
}
