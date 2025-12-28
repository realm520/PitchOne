/**
 * PitchOne Subgraph - 市场事件处理器 (V3 架构)
 * 处理 Market_V3 的事件：下注、锁盘、结算、兑付等
 */

import { BigInt, Address, Bytes, BigDecimal } from "@graphprotocol/graph-ts";
import {
  MarketInitialized as MarketInitializedEvent,
  BetPlaced as BetPlacedEvent,
  MarketLocked as MarketLockedEvent,
  MarketResolved as MarketResolvedEvent,
  MarketFinalized as MarketFinalizedEvent,
  MarketCancelled as MarketCancelledEvent,
  PayoutClaimed as PayoutClaimedEvent,
  RefundClaimed as RefundClaimedEvent,
  TransferSingle as TransferSingleEvent,
  TransferBatch as TransferBatchEvent,
  Market_V3,
} from "../generated/templates/Market_V3/Market_V3";
import {
  Market,
  Order,
  Position,
  Redemption,
  User,
  GlobalStats,
  OutcomeVolume,
} from "../generated/schema";
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
// MarketInitialized - 市场初始化事件 (V3)
// ============================================================================

export function handleMarketInitialized(event: MarketInitializedEvent): void {
  const marketAddress = event.address;
  const matchId = event.params.matchId;
  const pricingStrategy = event.params.pricingStrategy;
  const resultMapper = event.params.resultMapper;
  const outcomeCount = event.params.outcomeCount;

  // 加载市场实体（应该已由 Factory 创建）
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    // 如果不存在，创建一个
    market = new Market(marketAddress.toHexString());
    market.templateId = "V3";
    market.matchId = matchId;
    market.homeTeam = "";
    market.awayTeam = "";
    market.kickoffTime = ZERO_BI;
    market.ruleVer = Bytes.empty();
    market.state = "Open";
    market.createdAt = event.block.timestamp;
    market.totalVolume = ZERO_BD;
    market.feeAccrued = ZERO_BD;
    market.lpLiquidity = ZERO_BD;
    market.uniqueBettors = 0;
    market.oracle = null;
  }

  // 更新市场信息
  market.matchId = matchId;
  market.pricingEngine = pricingStrategy;
  market.outcomeCount = outcomeCount.toI32();
  market.save();
}

// ============================================================================
// BetPlaced - 下注事件 (V3)
// event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares)
// ============================================================================

export function handleBetPlaced(event: BetPlacedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcomeId.toI32();
  const amount = event.params.amount;
  const shares = event.params.shares;

  // 加载市场实体
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    market = new Market(marketAddress.toHexString());
    market.templateId = "V3";
    market.matchId = "";
    market.homeTeam = "";
    market.awayTeam = "";
    market.kickoffTime = ZERO_BI;
    market.ruleVer = Bytes.empty();
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

  // V3 的 BetPlaced 事件不包含 fee 参数
  // fee 需要从合约读取或者假设为 0
  let fee = ZERO_BI;

  // 创建订单记录
  const orderId = generateEventId(event.transaction.hash, event.logIndex);
  let order = new Order(orderId);
  order.market = marketAddress.toHexString();
  order.user = userAddress.toHexString();
  order.outcome = outcome;
  order.amount = toDecimal(amount);
  order.shares = shares;
  order.fee = toDecimal(fee);
  order.referrer = null;
  order.price = shares.gt(ZERO_BI)
    ? amount.toBigDecimal().div(shares.toBigDecimal())
    : ZERO_BD;
  order.timestamp = event.block.timestamp;
  order.blockNumber = event.block.number;
  order.transactionHash = event.transaction.hash;
  order.save();

  // 检查是否首次参与该市场
  const isFirstBetInMarket = isFirstTimeInMarket(userAddress, marketAddress);

  // 转换为 BigDecimal 用于统计
  const amountDecimal = toDecimal(amount);
  const feeDecimal = toDecimal(fee);

  // 更新或创建头寸（传递交易哈希和时间戳用于新创建的 position）
  let position = loadOrCreatePosition(
    marketAddress,
    userAddress,
    outcome,
    event.transaction.hash,
    event.block.timestamp
  );
  updatePositionAverageCost(position, amountDecimal, shares);
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

  if (isFirstBetInMarket) {
    user.marketsParticipated = user.marketsParticipated + 1;
    market.uniqueBettors = market.uniqueBettors + 1;
  }
  user.save();

  // 更新市场统计
  market.totalVolume = market.totalVolume.plus(amountDecimal);
  market.feeAccrued = market.feeAccrued.plus(feeDecimal);
  market.save();

  // 更新 OutcomeVolume 统计（用于前端计算赔率）
  let outcomeVolume = loadOrCreateOutcomeVolume(
    marketAddress,
    outcome,
    event.block.timestamp
  );
  outcomeVolume.volume = outcomeVolume.volume.plus(amountDecimal);
  outcomeVolume.shares = outcomeVolume.shares.plus(shares);
  outcomeVolume.betCount = outcomeVolume.betCount + 1;
  outcomeVolume.lastUpdatedAt = event.block.timestamp;
  outcomeVolume.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalVolume = stats.totalVolume.plus(amountDecimal);
  stats.totalFees = stats.totalFees.plus(feeDecimal);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// MarketLocked - 锁盘事件 (V3)
// ============================================================================

export function handleMarketLocked(event: MarketLockedEvent): void {
  const marketAddress = event.address;
  const timestamp = event.params.timestamp;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Locked";
  market.lockedAt = timestamp;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.activeMarkets = stats.activeMarkets - 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// MarketResolved - 结算事件 (V3)
// event MarketResolved(uint256[] outcomeIds, uint256[] weights)
// ============================================================================

export function handleMarketResolved(event: MarketResolvedEvent): void {
  const marketAddress = event.address;
  const outcomeIds = event.params.outcomeIds;
  const weights = event.params.weights;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Resolved";
  market.resolvedAt = event.block.timestamp;

  // 存储获胜的 outcome（第一个非零权重的 outcome）
  for (let i = 0; i < outcomeIds.length; i++) {
    if (weights[i].gt(ZERO_BI)) {
      market.winnerOutcome = outcomeIds[i].toI32();
      break;
    }
  }

  market.save();
}

// ============================================================================
// MarketFinalized - 最终确认事件 (V3)
// ============================================================================

export function handleMarketFinalized(event: MarketFinalizedEvent): void {
  const marketAddress = event.address;
  const timestamp = event.params.timestamp;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Finalized";
  market.finalizedAt = timestamp;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.resolvedMarkets = stats.resolvedMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// MarketCancelled - 市场取消事件 (V3)
// ============================================================================

export function handleMarketCancelled(event: MarketCancelledEvent): void {
  const marketAddress = event.address;
  const reason = event.params.reason;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Cancelled";
  market.cancelledAt = event.block.timestamp;
  market.cancelReason = reason;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.activeMarkets = stats.activeMarkets - 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// PayoutClaimed - 赔付领取事件 (V3)
// event PayoutClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout)
// ============================================================================

export function handlePayoutClaimed(event: PayoutClaimedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcomeId.toI32();
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
// RefundClaimed - 退款领取事件 (V3，市场取消时)
// event RefundClaimed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 amount)
// ============================================================================

export function handleRefundClaimed(event: RefundClaimedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcomeId.toI32();
  const shares = event.params.shares;
  const amount = event.params.amount;

  // 创建赎回记录（标记为退款）
  const redemptionId = generateEventId(event.transaction.hash, event.logIndex);
  let redemption = new Redemption(redemptionId);
  redemption.market = marketAddress.toHexString();
  redemption.user = userAddress.toHexString();
  redemption.outcome = outcome;
  redemption.shares = shares;
  redemption.payout = toDecimal(amount);
  redemption.isRefund = true;
  redemption.timestamp = event.block.timestamp;
  redemption.blockNumber = event.block.number;
  redemption.transactionHash = event.transaction.hash;
  redemption.save();

  // 更新头寸
  let position = loadOrCreatePosition(marketAddress, userAddress, outcome);
  position.balance = position.balance.minus(shares);
  position.lastUpdatedAt = event.block.timestamp;
  position.save();

  // 更新用户统计（退款不算盈利）
  let user = loadOrCreateUser(userAddress);
  const amountDecimal = toDecimal(amount);
  user.totalRedeemed = user.totalRedeemed.plus(amountDecimal);
  // 退款抵消之前的下注，所以 netProfit 增加
  user.netProfit = user.netProfit.plus(amountDecimal);
  user.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalRedeemed = stats.totalRedeemed.plus(amountDecimal);
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

  const zeroAddress = Address.fromString(
    "0x0000000000000000000000000000000000000000"
  );

  // Mint/Burn 已在其他 handler 中处理
  if (from.equals(zeroAddress) || to.equals(zeroAddress)) {
    return;
  }

  // 处理普通转账
  const marketAddress = event.address;
  const outcome = id.toI32();

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
