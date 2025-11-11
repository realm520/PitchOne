/**
 * PitchOne Subgraph - Basket 串关事件处理器
 * 处理串关创建、结算等事件
 */

import { BigInt, Bytes, BigDecimal } from "@graphprotocol/graph-ts";
import {
  ParlayCreated as BasketCreatedEvent,
  ParlaySettled as BasketSettledEvent,
} from "../generated/Basket/Basket";
import {
  Basket,
  User,
} from "../generated/schema";
import {
  loadOrCreateUser,
  toDecimal,
  ZERO_BD,
  ZERO_BI,
  ONE_BI,
} from "./helpers";

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * 将 Basket 状态枚举转换为字符串
 */
function getBasketStatusString(status: i32): string {
  if (status == 0) return "Pending";
  if (status == 1) return "Won";
  if (status == 2) return "Lost";
  if (status == 3) return "Refunded";
  return "Pending";
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * 处理串关创建事件
 * event ParlayCreated(
 *   uint256 indexed parlayId,
 *   address indexed user,
 *   ParlayLeg[] legs,
 *   uint256 stake,
 *   uint256 potentialPayout,
 *   uint256 combinedOdds,
 *   uint256 penaltyBps
 * );
 *
 * ParlayLeg { address market; uint256 outcomeId; }
 */
export function handleBasketCreated(event: BasketCreatedEvent): void {
  const basketId = event.params.parlayId.toString();

  // 加载或创建用户
  let user = loadOrCreateUser(event.params.user);

  // 创建 Basket 实体
  let basket = new Basket(basketId);
  basket.creator = user.id;

  // 解析 legs 数组
  let markets: Bytes[] = [];
  let outcomes: i32[] = [];

  for (let i = 0; i < event.params.legs.length; i++) {
    markets.push(event.params.legs[i].market);
    outcomes.push(event.params.legs[i].outcomeId.toI32());
  }

  basket.markets = markets;
  basket.outcomes = outcomes;
  basket.marketCount = event.params.legs.length;

  // 直接从事件读取数值（合约已计算好）
  basket.totalStake = toDecimal(event.params.stake, 6); // USDC 6 decimals
  basket.potentialPayout = toDecimal(event.params.potentialPayout, 6); // USDC 6 decimals
  basket.combinedOdds = toDecimal(event.params.combinedOdds, 4); // 基点 10000 = 1.0
  basket.correlationDiscount = event.params.penaltyBps.toI32();

  // 计算调整后赔率: combinedOdds * (1 - penaltyBps/10000)
  let penaltyFactor = BigDecimal.fromString("1").minus(
    toDecimal(event.params.penaltyBps, 4)
  );
  basket.adjustedOdds = basket.combinedOdds.times(penaltyFactor);

  basket.status = "Pending";
  basket.actualPayout = null;
  basket.createdAt = event.block.timestamp;
  basket.settledAt = null;
  basket.blockNumber = event.block.number;
  basket.transactionHash = event.transaction.hash;

  basket.save();

  // 更新用户统计（如果需要）
  user.save();
}

/**
 * 处理串关结算事件
 * event ParlaySettled(
 *   uint256 indexed parlayId,
 *   address indexed user,
 *   ParlayStatus status,  // 0=Pending, 1=Won, 2=Lost, 3=Cancelled
 *   uint256 payout
 * );
 */
export function handleBasketSettled(event: BasketSettledEvent): void {
  const basketId = event.params.parlayId.toString();

  // 加载 Basket 实体
  let basket = Basket.load(basketId);
  if (basket === null) {
    // 如果找不到 Basket，记录警告并返回
    return;
  }

  // 更新状态（ParlayStatus: 0=Pending, 1=Won, 2=Lost, 3=Cancelled）
  basket.status = getBasketStatusString(event.params.status);
  basket.actualPayout = toDecimal(event.params.payout, 6); // USDC 6 decimals
  basket.settledAt = event.block.timestamp;

  basket.save();

  // 可选：更新用户的盈亏统计
  let user = User.load(basket.creator);
  if (user !== null) {
    // 如果赢了，增加 totalRedeemed
    if (event.params.status == 1) { // Won
      user.totalRedeemed = user.totalRedeemed.plus(basket.actualPayout!);
      user.netProfit = user.totalRedeemed.minus(user.totalBetAmount);
    }
    user.save();
  }
}
