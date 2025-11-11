/**
 * PitchOne Subgraph - Coupon 加成券事件处理器
 */

import { BigInt, Bytes, BigDecimal, Address } from "@graphprotocol/graph-ts";
import {
  CouponTypeCreated as CouponTypeCreatedEvent,
  CouponUsed as CouponUsedEvent,
  TransferSingle as TransferSingleEvent,
} from "../generated/Coupon/Coupon";
import { CouponType, CouponUsage, CouponBalance, User } from "../generated/schema";
import { loadOrCreateUser, toDecimal, ZERO_BD, ZERO_BI } from "./helpers";

function loadOrCreateCouponBalance(couponTypeId: string, userAddress: Address): CouponBalance {
  const balanceId = couponTypeId + "-" + userAddress.toHexString();
  let balance = CouponBalance.load(balanceId);
  if (balance === null) {
    balance = new CouponBalance(balanceId);
    balance.couponType = couponTypeId;
    balance.user = userAddress;
    balance.balance = ZERO_BI;
    balance.usedCount = 0;
    balance.lastUpdatedAt = ZERO_BI;
  }
  return balance;
}

function getScopeString(scope: i32): string {
  if (scope == 0) return "ALL";
  if (scope == 1) return "WDL_ONLY";
  if (scope == 2) return "OU_ONLY";
  if (scope == 3) return "AH_ONLY";
  if (scope == 4) return "PARLAY_ONLY";
  return "UNKNOWN";
}

export function handleCouponTypeCreated(event: CouponTypeCreatedEvent): void {
  const couponTypeId = event.params.couponTypeId.toString();
  let couponType = new CouponType(couponTypeId);
  couponType.boostBps = event.params.boostBps.toI32();
  couponType.scope = getScopeString(event.params.scope);
  couponType.minBetAmount = toDecimal(event.params.minBetAmount, 6);
  couponType.maxOdds = toDecimal(event.params.maxOdds, 18);
  couponType.expiresAt = event.params.expiresAt;
  couponType.maxUses = event.params.maxUses.toI32();
  couponType.isActive = true;
  couponType.metadata = "";
  couponType.totalSupply = ZERO_BI;
  couponType.totalUsed = ZERO_BI;
  couponType.createdAt = event.block.timestamp;
  couponType.blockNumber = event.block.number;
  couponType.transactionHash = event.transaction.hash;
  couponType.save();
}

export function handleCouponUsed(event: CouponUsedEvent): void {
  const couponTypeId = event.params.couponTypeId.toString();
  const usageId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let usage = new CouponUsage(usageId);
  usage.couponType = couponTypeId;
  usage.user = event.params.user.toHexString();
  usage.market = event.params.market;
  usage.betAmount = toDecimal(event.params.betAmount, 6);
  usage.originalOdds = toDecimal(event.params.originalOdds, 18);
  usage.boostedOdds = toDecimal(event.params.boostedOdds, 18);
  usage.timestamp = event.block.timestamp;
  usage.blockNumber = event.block.number;
  usage.transactionHash = event.transaction.hash;
  usage.save();

  let couponType = CouponType.load(couponTypeId);
  if (couponType !== null) {
    couponType.totalUsed = couponType.totalUsed.plus(BigInt.fromI32(1));
    couponType.save();
  }

  loadOrCreateUser(event.params.user);
}

export function handleTransferSingle(event: TransferSingleEvent): void {
  const couponTypeId = event.params.id.toString();
  const from = event.params.from;
  const to = event.params.to;
  const value = event.params.value;
  const ZERO_ADDRESS = Address.fromString("0x0000000000000000000000000000000000000000");

  if (from.equals(ZERO_ADDRESS)) {
    let balance = loadOrCreateCouponBalance(couponTypeId, to);
    balance.balance = balance.balance.plus(value);
    balance.lastUpdatedAt = event.block.timestamp;
    balance.save();
    loadOrCreateUser(to);
  } else if (to.equals(ZERO_ADDRESS)) {
    let balance = loadOrCreateCouponBalance(couponTypeId, from);
    balance.balance = balance.balance.minus(value);
    balance.lastUpdatedAt = event.block.timestamp;
    balance.save();
  } else {
    let fromBalance = loadOrCreateCouponBalance(couponTypeId, from);
    fromBalance.balance = fromBalance.balance.minus(value);
    fromBalance.lastUpdatedAt = event.block.timestamp;
    fromBalance.save();

    let toBalance = loadOrCreateCouponBalance(couponTypeId, to);
    toBalance.balance = toBalance.balance.plus(value);
    toBalance.lastUpdatedAt = event.block.timestamp;
    toBalance.save();
    loadOrCreateUser(to);
  }
}
