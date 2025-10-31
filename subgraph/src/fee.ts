/**
 * PitchOne Subgraph - 费用分发事件处理器
 * 处理手续费的收取和分配
 */

import { BigInt } from "@graphprotocol/graph-ts";
import {
  FeeReceived as FeeReceivedEvent,
  FeeDistributed as FeeDistributedEvent,
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
// FeeDistributed - 费用分发事件
// ============================================================================

export function handleFeeDistributed(event: FeeDistributedEvent): void {
  const token = event.params.token;
  const recipient = event.params.recipient;
  const amount = event.params.amount;
  const category = event.params.category;

  // 创建费用分发记录
  const distributionId = generateEventId(
    event.transaction.hash,
    event.logIndex
  );

  let distribution = new FeeDistribution(distributionId);
  distribution.token = token;
  distribution.recipient = recipient;
  distribution.amount = toDecimal(amount);
  distribution.category = category;
  distribution.timestamp = event.block.timestamp;
  distribution.blockNumber = event.block.number;
  distribution.transactionHash = event.transaction.hash;
  distribution.save();
}
