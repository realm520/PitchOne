/**
 * PitchOne Subgraph - PayoutScaler 预算缩放事件处理器
 */

import { BigInt, BigDecimal } from "@graphprotocol/graph-ts";
import {
  BudgetRefilled as BudgetRefilledEvent,
  ScalingCalculated as ScalingCalculatedEvent,
  BudgetUsed as BudgetUsedEvent,
  AutoScaleUpdated as AutoScaleUpdatedEvent,
} from "../generated/PayoutScaler/PayoutScaler";
import { BudgetPool, BudgetRefill, ScalingRecord, BudgetUsage } from "../generated/schema";
import { toDecimal, ZERO_BD, ZERO_BI } from "./helpers";

function getPoolIdString(pool: i32): string {
  if (pool == 0) return "PROMO";
  if (pool == 1) return "CAMPAIGN";
  if (pool == 2) return "QUEST";
  if (pool == 3) return "INSURANCE";
  return "UNKNOWN";
}

function loadOrCreateBudgetPool(poolId: string): BudgetPool {
  let pool = BudgetPool.load(poolId);
  if (pool === null) {
    pool = new BudgetPool(poolId);
    pool.totalBudget = ZERO_BD;
    pool.usedBudget = ZERO_BD;
    pool.pendingPayout = ZERO_BD;
    pool.availableBudget = ZERO_BD;
    pool.lastRefillAt = ZERO_BI;
    pool.autoScaleEnabled = true;
    pool.lastUpdatedAt = ZERO_BI;
  }
  return pool;
}

export function handleBudgetRefilled(event: BudgetRefilledEvent): void {
  const poolId = getPoolIdString(event.params.pool);
  let pool = loadOrCreateBudgetPool(poolId);

  pool.totalBudget = toDecimal(event.params.newTotal, 6);
  pool.availableBudget = pool.totalBudget.minus(pool.usedBudget);
  pool.lastRefillAt = event.block.timestamp;
  pool.lastUpdatedAt = event.block.timestamp;
  pool.save();

  const refillId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let refill = new BudgetRefill(refillId);
  refill.pool = poolId;
  refill.amount = toDecimal(event.params.amount, 6);
  refill.newTotal = toDecimal(event.params.newTotal, 6);
  refill.timestamp = event.block.timestamp;
  refill.blockNumber = event.block.number;
  refill.transactionHash = event.transaction.hash;
  refill.save();
}

export function handleScalingCalculated(event: ScalingCalculatedEvent): void {
  const poolId = getPoolIdString(event.params.pool);
  const recordId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let record = new ScalingRecord(recordId);
  record.pool = poolId;
  record.period = event.params.period;
  record.requestedAmount = toDecimal(event.params.requestedAmount, 6);
  record.availableBudget = toDecimal(event.params.availableBudget, 6);
  record.scaleBps = event.params.scaleBps.toI32();
  record.scaledAmount = toDecimal(event.params.scaledAmount, 6);
  record.timestamp = event.block.timestamp;
  record.blockNumber = event.block.number;
  record.transactionHash = event.transaction.hash;
  record.save();

  let pool = loadOrCreateBudgetPool(poolId);
  pool.pendingPayout = pool.pendingPayout.plus(record.scaledAmount);
  pool.lastUpdatedAt = event.block.timestamp;
  pool.save();
}

export function handleBudgetUsed(event: BudgetUsedEvent): void {
  const poolId = getPoolIdString(event.params.pool);
  const usageId = event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  let pool = loadOrCreateBudgetPool(poolId);
  const amount = toDecimal(event.params.amount, 6);
  
  pool.usedBudget = pool.usedBudget.plus(amount);
  pool.pendingPayout = pool.pendingPayout.minus(amount);
  pool.availableBudget = pool.totalBudget.minus(pool.usedBudget);
  pool.lastUpdatedAt = event.block.timestamp;
  pool.save();

  let usage = new BudgetUsage(usageId);
  usage.pool = poolId;
  usage.period = event.params.period;
  usage.amount = amount;
  usage.remainingBudget = pool.availableBudget;
  usage.timestamp = event.block.timestamp;
  usage.blockNumber = event.block.number;
  usage.transactionHash = event.transaction.hash;
  usage.save();
}

export function handleAutoScaleUpdated(event: AutoScaleUpdatedEvent): void {
  const poolId = getPoolIdString(event.params.pool);
  let pool = loadOrCreateBudgetPool(poolId);
  pool.autoScaleEnabled = event.params.enabled;
  pool.lastUpdatedAt = event.block.timestamp;
  pool.save();
}
