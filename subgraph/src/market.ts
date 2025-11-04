/**
 * PitchOne Subgraph - 市场事件处理器
 * 处理市场生命周期事件：下注、锁盘、结算、兑付等
 */

import { BigInt, Address, Bytes, BigDecimal } from "@graphprotocol/graph-ts";
import {
  MarketCreated as MarketCreatedEvent,
  BetPlaced as BetPlacedEvent,
  Locked as LockedEvent,
  Resolved as ResolvedEvent,
  Finalized as FinalizedEvent,
  Redeemed as RedeemedEvent,
  TransferSingle as TransferSingleEvent,
  TransferBatch as TransferBatchEvent,
  WDL_Template,
} from "../generated/WDL_Template/WDL_Template";
import { OU_Template } from "../generated/templates/OUMarket/OU_Template";
import { OddEven_Template } from "../generated/templates/OddEvenMarket/OddEven_Template";
import {
  LiquidityAdded as LiquidityAddedEvent,
} from "../generated/OldMarket1_MUN_vs_MCI/MarketBase";
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
// MarketCreated - 市场创建事件
// ============================================================================

export function handleMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;
  const pricingEngine = event.params.pricingEngine;

  // 检查市场是否已经由 Registry handler 创建
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    // Market 已由 Registry 创建，跳过
    return;
  }

  // 从合约读取 matchId（因为 indexed string 在事件中是 keccak256 哈希）
  let marketContract = WDL_Template.bind(event.address);

  // 创建市场实体
  market = new Market(marketAddress.toHexString());
  market.templateId = "WDL"; // WDL 模板
  market.matchId = marketContract.matchId();
  market.homeTeam = homeTeam;
  market.awayTeam = awayTeam;
  market.kickoffTime = kickoffTime;
  market.ruleVer = Bytes.empty(); // 暂时使用空值
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = pricingEngine;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// OU_Template MarketCreated event
// event MarketCreated(indexed string matchId, string homeTeam, string awayTeam, uint256 kickoffTime, uint256 line, bool isHalfLine, address pricingEngine)
export function handleOUMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;
  // Note: pricingEngine is the 7th parameter (index 6) in OU_Template event

  // 检查市场是否已经由 Registry handler 创建
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    // Market 已由 Registry 创建，跳过
    return;
  }

  // 从合约读取 matchId（因为 indexed string 在事件中是 keccak256 哈希）
  let marketContract = OU_Template.bind(event.address);

  // 创建市场实体
  market = new Market(marketAddress.toHexString());
  market.templateId = "OU"; // OU 单线模板
  market.matchId = marketContract.matchId();
  market.homeTeam = homeTeam;
  market.awayTeam = awayTeam;
  market.kickoffTime = kickoffTime;
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = null; // Set to null for OU markets
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// OU_MultiLine MarketCreated event
// event MarketCreated(string matchId, string homeTeam, string awayTeam, uint256 kickoffTime, uint256[] lines, bytes32 groupId, address pricingEngine, address linkedLinesController)
export function handleOUMultiLineMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;

  // 检查市场是否已经由 Registry handler 创建
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    // Market 已由 Registry 创建，跳过
    return;
  }

  // 从合约读取 matchId（因为 indexed string 在事件中是 keccak256 哈希）
  let marketContract = OU_Template.bind(event.address);

  // 创建市场实体
  market = new Market(marketAddress.toHexString());
  market.templateId = "OU_MULTI"; // OU 多线模板
  market.matchId = marketContract.matchId();
  market.homeTeam = homeTeam;
  market.awayTeam = awayTeam;
  market.kickoffTime = kickoffTime;
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = null; // Set to null for OU Multi markets
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// OddEven_Template MarketCreated event
// event MarketCreated(indexed string matchId, string homeTeam, string awayTeam, uint256 kickoffTime, address pricingEngine)
export function handleOddEvenMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;
  const pricingEngine = event.params.pricingEngine;

  // 检查市场是否已经由 Registry handler 创建
  let market = Market.load(marketAddress.toHexString());
  if (market !== null) {
    // Market 已由 Registry 创建，跳过
    return;
  }

  // 从合约读取 matchId（因为 indexed string 在事件中是 keccak256 哈希）
  let marketContract = OddEven_Template.bind(event.address);

  // 创建市场实体
  market = new Market(marketAddress.toHexString());
  market.templateId = "OddEven"; // OddEven 模板
  market.matchId = marketContract.matchId();
  market.homeTeam = homeTeam;
  market.awayTeam = awayTeam;
  market.kickoffTime = kickoffTime;
  market.ruleVer = Bytes.empty();
  market.state = "Open";
  market.createdAt = event.block.timestamp;
  market.totalVolume = ZERO_BD;
  market.feeAccrued = ZERO_BD;
  market.lpLiquidity = ZERO_BD;
  market.uniqueBettors = 0;
  market.oracle = null;
  market.pricingEngine = pricingEngine;
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalMarkets = stats.totalMarkets + 1;
  stats.activeMarkets = stats.activeMarkets + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// BetPlaced - 下注事件
// ============================================================================

export function handleBetPlaced(event: BetPlacedEvent): void {
  const marketAddress = event.address;
  const userAddress = event.params.user;
  const outcome = event.params.outcomeId.toI32();
  const amount = event.params.amount;
  const shares = event.params.shares;
  const feeParam = event.params.fee;

  // 加载或创建市场实体
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    // 市场应该已经在 MarketCreated 事件中创建
    // 如果不存在，创建一个临时的
    market = new Market(marketAddress.toHexString());
    market.templateId = "WDL"; // 默认为 WDL 类型
    market.matchId = "";  // 临时使用空字符串
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

  // 使用事件中的费用参数
  const amountDecimal = toDecimal(amount);
  const fee = toDecimal(feeParam);
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
  const timestamp = event.params.timestamp;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return; // 市场不存在，忽略
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
// Resolved - 结算事件
// ============================================================================

export function handleResolved(event: ResolvedEvent): void {
  const marketAddress = event.address;
  const winnerOutcome = event.params.winningOutcome.toI32();
  const timestamp = event.params.timestamp;

  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return;
  }

  market.state = "Resolved";
  market.resolvedAt = timestamp;
  market.winnerOutcome = winnerOutcome;
  market.save();
}

// ============================================================================
// Finalized - 最终确认事件
// ============================================================================

export function handleFinalized(event: FinalizedEvent): void {
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
// Redeemed - 赎回事件
// ============================================================================

export function handleRedeemed(event: RedeemedEvent): void {
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

// ============================================================================
// LiquidityAdded - 流动性添加事件
// ============================================================================

export function handleLiquidityAdded(event: LiquidityAddedEvent): void {
  const marketAddress = event.address;
  const provider = event.params.provider;
  const totalAmount = event.params.totalAmount;
  const timestamp = event.params.timestamp;

  // 加载市场实体
  let market = Market.load(marketAddress.toHexString());
  if (market === null) {
    return; // 市场不存在，忽略
  }

  // 更新市场的 LP 流动性
  const amountDecimal = toDecimal(totalAmount);
  market.lpLiquidity = market.lpLiquidity.plus(amountDecimal);
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}
