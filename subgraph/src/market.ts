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
import { OU_MultiLine } from "../generated/templates/OUMultiMarket/OU_MultiLine";
import { OddEven_Template } from "../generated/templates/OddEvenMarket/OddEven_Template";
import { PlayerProps_Template } from "../generated/templates/PlayerPropsMarket/PlayerProps_Template";
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
  isFirstTimeInMarket,
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
// event MarketCreated(indexed string matchId, string homeTeam, string awayTeam, uint256 kickoffTime, uint256 line, address pricingEngine)
export function handleOUMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;

  // 加载或创建市场实体
  let market = Market.load(marketAddress.toHexString());
  let isNewMarket = market === null;

  if (isNewMarket) {
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
  }

  // 无论是新建还是已存在，都更新 line 字段
  // 从事件参数直接读取 line（球数）
  const eventParams = event.parameters;
  if (eventParams.length > 4) {
    market!.line = eventParams[4].value.toBigInt();
  }

  market!.save();

  // 只有新市场才更新全局统计
  if (isNewMarket) {
    let stats = loadOrCreateGlobalStats();
    stats.totalMarkets = stats.totalMarkets + 1;
    stats.activeMarkets = stats.activeMarkets + 1;
    stats.lastUpdatedAt = event.block.timestamp;
    stats.save();
  }
}

// OU_MultiLine MarketCreated event
// event MarketCreated(string matchId, string homeTeam, string awayTeam, uint256 kickoffTime, uint256[] lines, bytes32 groupId, address pricingEngine, address linkedLinesController)
export function handleOUMultiLineMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const homeTeam = event.params.homeTeam;
  const awayTeam = event.params.awayTeam;
  const kickoffTime = event.params.kickoffTime;

  // 加载或创建市场实体
  let market = Market.load(marketAddress.toHexString());
  let isNewMarket = market === null;

  if (isNewMarket) {
    // 从合约读取 matchId（因为 indexed string 在事件中是 keccak256 哈希）
    let marketContract = OU_MultiLine.bind(event.address);

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
  }

  // 无论是新建还是已存在，都更新 lines 字段
  // 从事件参数读取 lines 数组（多条盘口线）
  const eventParams = event.parameters;
  let linesArray: BigInt[] = [];

  // lines 是第 5 个参数（索引 4）
  if (eventParams.length > 4) {
    const linesParam = eventParams[4].value.toBigIntArray();
    for (let i = 0; i < linesParam.length; i++) {
      linesArray.push(linesParam[i]);
    }
  }

  // 存储 lines 数组
  if (linesArray.length > 0) {
    market!.lines = linesArray;
  }

  market!.save();

  // 只有新市场才更新全局统计
  if (isNewMarket) {
    let stats = loadOrCreateGlobalStats();
    stats.totalMarkets = stats.totalMarkets + 1;
    stats.activeMarkets = stats.activeMarkets + 1;
    stats.lastUpdatedAt = event.block.timestamp;
    stats.save();
  }
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

  // 直接使用原始 wei 值，不转换为 decimal
  // 前端会使用 formatUnits() 进行转换
  const netAmount = amount.minus(feeParam);

  // 创建订单记录
  const orderId = generateEventId(event.transaction.hash, event.logIndex);
  let order = new Order(orderId);
  order.market = marketAddress.toHexString();
  order.user = userAddress.toHexString();
  order.outcome = outcome;
  order.amount = amount;  // 存储原始 BigInt
  order.shares = shares;
  order.fee = feeParam;   // 存储原始 BigInt
  order.referrer = null; // TODO: 从合约事件中提取（如果有）
  order.price = shares.gt(ZERO_BI)
    ? netAmount.toBigDecimal().div(shares.toBigDecimal())
    : ZERO_BD;
  order.timestamp = event.block.timestamp;
  order.blockNumber = event.block.number;
  order.transactionHash = event.transaction.hash;
  order.save();

  // 检查是否首次参与该市场（在创建/更新 position 之前判断）
  const isFirstBetInMarket = isFirstTimeInMarket(userAddress, marketAddress);

  // 为统计聚合转换为 BigDecimal
  const amountDecimal = toDecimal(amount);
  const feeDecimal = toDecimal(feeParam);
  const netAmountDecimal = amountDecimal.minus(feeDecimal);

  // 更新或创建头寸
  let position = loadOrCreatePosition(marketAddress, userAddress, outcome);
  updatePositionAverageCost(position, netAmountDecimal, shares);
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

  // 如果是首次参与该市场，更新计数
  if (isFirstBetInMarket) {
    user.marketsParticipated = user.marketsParticipated + 1;
    market.uniqueBettors = market.uniqueBettors + 1;
  }
  user.save();

  // 更新市场统计
  market.totalVolume = market.totalVolume.plus(amountDecimal);
  market.feeAccrued = market.feeAccrued.plus(feeDecimal);
  market.save();

  // 更新全局统计
  let stats = loadOrCreateGlobalStats();
  stats.totalVolume = stats.totalVolume.plus(amountDecimal);
  stats.totalFees = stats.totalFees.plus(feeDecimal);
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

// ============================================================================
// PlayerProps 球员道具市场事件
// ============================================================================

/**
 * 处理 PlayerProps 市场创建事件
 * event MarketCreated(
 *   string indexed matchId,
 *   string playerId,
 *   string playerName,
 *   uint8 propType,
 *   uint256 line,
 *   uint256 kickoffTime,
 *   address pricingEngine
 * );
 */
export function handlePlayerPropsMarketCreated(event: MarketCreatedEvent): void {
  const marketAddress = event.address;
  const kickoffTime = event.params.kickoffTime;

  // 加载或创建市场实体
  let market = Market.load(marketAddress.toHexString());
  let isNewMarket = market === null;

  if (isNewMarket) {
    // 从合约读取详细信息
    let marketContract = PlayerProps_Template.bind(event.address);

    // 创建市场实体
    market = new Market(marketAddress.toHexString());
    market.templateId = "PLAYER_PROPS"; // PlayerProps 模板
    market.matchId = marketContract.matchId();
    market.homeTeam = ""; // PlayerProps 没有主客队概念，留空
    market.awayTeam = "";
    market.kickoffTime = kickoffTime;
    market.ruleVer = Bytes.empty();
    market.state = "Open";
    market.createdAt = event.block.timestamp;
    market.totalVolume = ZERO_BD;
    market.feeAccrued = ZERO_BD;
    market.lpLiquidity = ZERO_BD;
    market.uniqueBettors = 0;
    market.oracle = null;
    market.pricingEngine = null;

    // PlayerProps 扩展字段
    market.playerId = marketContract.playerId();
    market.playerName = marketContract.playerName();

    // PropType 枚举转字符串
    const propType = marketContract.propType();
    market.propType = getPropTypeString(propType);

    // Line（如果是 O/U 类型）
    market.line = marketContract.line();

    // Note: firstScorerPlayerIds 和 firstScorerPlayerNames 字段暂不从合约读取
    // 如果未来合约添加了这些 getter 方法，可以在这里调用
    // 目前保持为 null（Schema 中定义为可选字段）
  }

  market!.save();

  // 只有新市场才更新全局统计
  if (isNewMarket) {
    let stats = loadOrCreateGlobalStats();
    stats.totalMarkets = stats.totalMarkets + 1;
    stats.activeMarkets = stats.activeMarkets + 1;
    stats.lastUpdatedAt = event.block.timestamp;
    stats.save();
  }
}

/**
 * 将 PropType 枚举转换为字符串
 */
function getPropTypeString(propType: i32): string {
  if (propType == 0) return "GOALS_OU";
  if (propType == 1) return "ASSISTS_OU";
  if (propType == 2) return "SHOTS_OU";
  if (propType == 3) return "YELLOW_CARD";
  if (propType == 4) return "RED_CARD";
  if (propType == 5) return "ANYTIME_SCORER";
  if (propType == 6) return "FIRST_SCORER";
  return "UNKNOWN";
}
