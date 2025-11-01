/**
 * PitchOne Subgraph - 费用分发事件处理器
 * 处理手续费的收取和分配
 */

import { BigInt } from "@graphprotocol/graph-ts";
import {
  FeeReceived as FeeReceivedEvent,
  FeeRouted as FeeRoutedEvent,
} from "../generated/FeeRouter/FeeRouter";
import { FeeDistribution, GlobalStats } from "../generated/schema";
import { loadOrCreateGlobalStats, toDecimal, generateEventId } from "./helpers";

// ============================================================================
// FeeReceived - 费用接收事件
// ============================================================================

export function handleFeeReceived(event: FeeReceivedEvent): void {
  const token = event.params.token;
  const from = event.params.from;
  const amount = event.params.amount;

  // 费用接收通常只记录在 GlobalStats 中
  // 不单独创建实体，避免冗余

  let stats = loadOrCreateGlobalStats();
  stats.totalFees = stats.totalFees.plus(toDecimal(amount));
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

// ============================================================================
// FeeRouted - 费用路由事件
// ============================================================================

export function handleFeeRouted(event: FeeRoutedEvent): void {
  const token = event.params.token;
  const totalAmount = event.params.totalAmount;
  const referrer = event.params.referrer;
  const referralAmount = event.params.referralAmount;
  const lpAmount = event.params.lpAmount;
  const promoAmount = event.params.promoAmount;
  const insuranceAmount = event.params.insuranceAmount;
  const treasuryAmount = event.params.treasuryAmount;

  // 创建 LP 分发记录
  if (lpAmount.gt(BigInt.zero())) {
    const lpDistId = generateEventId(event.transaction.hash, event.logIndex.plus(BigInt.fromI32(1)));
    let lpDist = new FeeDistribution(lpDistId);
    lpDist.token = token;
    lpDist.recipient = event.address; // FeeRouter 地址
    lpDist.amount = toDecimal(lpAmount);
    lpDist.category = "lp";
    lpDist.timestamp = event.block.timestamp;
    lpDist.blockNumber = event.block.number;
    lpDist.transactionHash = event.transaction.hash;
    lpDist.save();
  }

  // 创建 Promo 分发记录
  if (promoAmount.gt(BigInt.zero())) {
    const promoDistId = generateEventId(event.transaction.hash, event.logIndex.plus(BigInt.fromI32(2)));
    let promoDist = new FeeDistribution(promoDistId);
    promoDist.token = token;
    promoDist.recipient = event.address;
    promoDist.amount = toDecimal(promoAmount);
    promoDist.category = "promo";
    promoDist.timestamp = event.block.timestamp;
    promoDist.blockNumber = event.block.number;
    promoDist.transactionHash = event.transaction.hash;
    promoDist.save();
  }

  // 创建 Insurance 分发记录
  if (insuranceAmount.gt(BigInt.zero())) {
    const insDistId = generateEventId(event.transaction.hash, event.logIndex.plus(BigInt.fromI32(3)));
    let insDist = new FeeDistribution(insDistId);
    insDist.token = token;
    insDist.recipient = event.address;
    insDist.amount = toDecimal(insuranceAmount);
    insDist.category = "insurance";
    insDist.timestamp = event.block.timestamp;
    insDist.blockNumber = event.block.number;
    insDist.transactionHash = event.transaction.hash;
    insDist.save();
  }

  // 创建 Treasury 分发记录
  if (treasuryAmount.gt(BigInt.zero())) {
    const treasuryDistId = generateEventId(event.transaction.hash, event.logIndex.plus(BigInt.fromI32(4)));
    let treasuryDist = new FeeDistribution(treasuryDistId);
    treasuryDist.token = token;
    treasuryDist.recipient = event.address;
    treasuryDist.amount = toDecimal(treasuryAmount);
    treasuryDist.category = "treasury";
    treasuryDist.timestamp = event.block.timestamp;
    treasuryDist.blockNumber = event.block.number;
    treasuryDist.transactionHash = event.transaction.hash;
    treasuryDist.save();
  }

  // 创建推荐返佣分发记录（如果有）
  if (referralAmount.gt(BigInt.zero())) {
    const refDistId = generateEventId(event.transaction.hash, event.logIndex.plus(BigInt.fromI32(5)));
    let refDist = new FeeDistribution(refDistId);
    refDist.token = token;
    refDist.recipient = referrer;
    refDist.amount = toDecimal(referralAmount);
    refDist.category = "referral";
    refDist.timestamp = event.block.timestamp;
    refDist.blockNumber = event.block.number;
    refDist.transactionHash = event.transaction.hash;
    refDist.save();
  }
}
