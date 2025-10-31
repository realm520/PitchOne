/**
 * PitchOne Subgraph - 市场事件处理器
 * 处理市场生命周期事件：下注、锁盘、结算、兑付等
 */

import { BigInt, Address } from "@graphprotocol/graph-ts";
import {
  BetPlaced as BetPlacedEvent,
  Locked as LockedEvent,
  Resolved as ResolvedEvent,
  Finalized as FinalizedEvent,
  Redeemed as RedeemedEvent,
  TransferSingle as TransferSingleEvent,
  TransferBatch as TransferBatchEvent,
} from "../generated/WDL_Template/MarketBase";
import {
  Market,
  Order,
  Position,
  Redemption,
  User,
  GlobalStats,
} from "../generated/schema";
import {
  loadOrCreateUser,
  loadOrCreatePosition,
  loadOrCreateGlobalStats,
  toDecimal,
  updatePositionAverageCost,
  generateEventId,
  ZERO_BI,
  ZERO_BD,
  ONE_BI,
} from "./helpers";

// ============================================================================
// BetPlaced - 下注事件
// ============================================================================

export function handleBetPlaced(event: BetPlacedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcome.toI32();
  const amount = event.params.amount;
  const shares = event.params.shares;

  // 加载或创建市场实体
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    // 市场应该已经在 MarketCreated 事件中创建
    // 如果不存在，创建一个临时的
    market = new Market(marketAddress.toHexString());
    market.templateId = new Uint8Array(0);
    market.matchId = new Uint8Array(0);
    market.ruleVer = new Uint8Array(0);
    market.state = "Open";
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

  // 计算手续费（假设 2% 费率）
  const feeRate = 0.02;
  const amountDecimal = toDecimal(amount);
  const fee = amountDecimal.times(BigDecimal.fromString(feeRate.toString()));
  const netAmount = amountDecimal.minus(fee);

  // 创建订单记录
  const orderId = generateEventId(event.transaction.hash, event.logIndex);
  let order = new Order(orderId);
  order.market = marketAddress.toHexString();
  order.user = userAddress.toHexString();
  order.outcome = outcome;
  order.amount = amountDecimal;
  order.shares = shares;
  order.fee = fee;
  order.referrer = null; // TODO: 从合约事件中提取（如果有）
  order.price = shares.gt(ZERO_BI)
    ? netAmount.div(shares.toBigDecimal())
    : ZERO_BD;
  order.timestamp = event.block.timestamp;
  order.blockNumber = event.block.number;
  order.transactionHash = event.transaction.hash;
  order.save();

  // 更新或创建头寸
  let position = loadOrCreatePosition(marketAddress, userAddress, outcome);
  updatePositionAverageCost(position, netAmount, shares);
  position.lastUpdatedAt = event.block.timestamp;
  position.save();

  // 更新用户统计
  user.totalBetAmount = user.totalBetAmount.plus(amountDecimal);
  user.netProfit = user.netProfit.minus(amountDecimal);
  user.totalBets = user.totalBets + 1;

  if (user.firstBetAt === null) {
    user.firstBetAt = event.block.timestamp;
  }
  user.lastBetAt = event.block.timestamp;

  // 检查是否首次参与该市场
  // 简化逻辑：检查订单数量
  const userOrdersInMarket = Order.load(orderId);
  if (userOrdersInMarket !== null) {
    const isFirstTime = user.totalBets === 1;
    if (isFirstTime) {
      user.marketsParticipated = user.marketsParticipated + 1;
      market.uniqueBettors = market.uniqueBettors + 1;
    }
  }
  user.save();

  // 更新市场统计
  market.totalVolume = market.totalVolume.plus(amountDecimal);
  market.feeAccrued = market.feeAccrued.plus(fee);
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalVolume = stats.totalVolume.plus(amountDecimal);
  stats.totalFees = stats.totalFees.plus(fee);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// Locked - 锁盘事件
// ============================================================================

export function handleLocked(event: LockedEvent): void {
  const marketAddress = event.address;
  const lockTime = event.params.lockTime;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return; // 市场不存在，忽略
  }

  market.state = "Locked";
  market.lockedAt = lockTime;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.activeMarkets = stats.activeMarkets - 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// Resolved - 结算事件
// ============================================================================

export function handleResolved(event: ResolvedEvent): void {
  const marketAddress = event.address;
  const resolveTime = event.params.resolveTime;
  const winnerOutcome = event.params.winnerOutcome.toI32();

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Resolved";
  market.resolvedAt = resolveTime;
  market.winnerOutcome = winnerOutcome;
  market.save();
}

// ============================================================================
// Finalized - 最终确认事件
// ============================================================================

export function handleFinalized(event: FinalizedEvent): void {
  const marketAddress = event.address;
  const finalizeTime = event.params.finalizeTime;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Finalized";
  market.finalizedAt = finalizeTime;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.resolvedMarkets = stats.resolvedMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// Redeemed - 赎回事件
// ============================================================================

export function handleRedeemed(event: RedeemedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcome.toI32();
  const shares = event.params.shares;
  const payout = event.params.payout;

  // 创建赎回记录
  const redemptionId = generateEventId(event.transaction.hash, event.logIndex);
  let redemption = new Redemption(redemptionId);
  redemption.market = marketAddress.toHexString();
  redemption.user = userAddress.toHexString();
  redemption.outcome = outcome;
  redemption.shares = shares;
  redemption.payout = toDecimal(payout);
  redemption.timestamp = event.block.timestamp;
  redemption.blockNumber = event.block.number;
  redemption.transactionHash = event.transaction.hash;
  redemption.save();

  // 更新头寸
  let position = loadOrCreatePosition(marketAddress, userAddress, outcome);
  position.balance = position.balance.minus(shares);
  position.lastUpdatedAt = event.block.timestamp;
  position.save();

  // 更新用户统计
  let user = loadOrCreateUser(userAddress);
  const payoutDecimal = toDecimal(payout);
  user.totalRedeemed = user.totalRedeemed.plus(payoutDecimal);
  user.netProfit = user.netProfit.plus(payoutDecimal);
  user.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalRedeemed = stats.totalRedeemed.plus(payoutDecimal);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// TransferSingle - ERC1155 单个转账事件
// ============================================================================

export function handleTransferSingle(event: TransferSingleEvent): void {
  const from = event.params.from;
  const to = event.params.to;
  const id = event.params.id;
  const value = event.params.value;

  // 如果是 mint (from == 0x0)，在 BetPlaced 中已处理
  // 如果是 burn (to == 0x0)，在 Redeemed 中已处理
  // 这里处理转账情况

  const zeroAddress = Address.fromString(
    "0x0000000000000000000000000000000000000000"
  );

  if (from.equals(zeroAddress) || to.equals(zeroAddress)) {
    return; // Mint/Burn 已在其他 handler 中处理
  }

  // 处理普通转账（如果允许）
  const marketAddress = event.address;
  const outcome = id.toI32(); // 假设 tokenId == outcome

  // 更新 from 的头寸
  let fromPosition = loadOrCreatePosition(marketAddress, from, outcome);
  fromPosition.balance = fromPosition.balance.minus(value);
  fromPosition.lastUpdatedAt = event.block.timestamp;
  fromPosition.save();

  // 更新 to 的头寸
  let toPosition = loadOrCreatePosition(marketAddress, to, outcome);
  toPosition.balance = toPosition.balance.plus(value);
  toPosition.lastUpdatedAt = event.block.timestamp;
  toPosition.save();
}

// ============================================================================
// TransferBatch - ERC1155 批量转账事件
// ============================================================================

export function handleTransferBatch(event: TransferBatchEvent): void {
  const from = event.params.from;
  const to = event.params.to;
  const ids = event.params.ids;
  const values = event.params.values;

  const zeroAddress = Address.fromString(
    "0x0000000000000000000000000000000000000000"
  );

  if (from.equals(zeroAddress) || to.equals(zeroAddress)) {
    return;
  }

  const marketAddress = event.address;

  for (let i = 0; i < ids.length; i++) {
    const outcome = ids[i].toI32();
    const value = values[i];

    // 更新 from 的头寸
    let fromPosition = loadOrCreatePosition(marketAddress, from, outcome);
    fromPosition.balance = fromPosition.balance.minus(value);
    fromPosition.lastUpdatedAt = event.block.timestamp;
    fromPosition.save();

    // 更新 to 的头寸
    let toPosition = loadOrCreatePosition(marketAddress, to, outcome);
    toPosition.balance = toPosition.balance.plus(value);
    toPosition.lastUpdatedAt = event.block.timestamp;
    toPosition.save();
  }
}
