/**
 * PitchOne Subgraph - CorrelationGuard 相关性守卫事件处理器
 * 处理相关性规则设置、惩罚更新、串关阻断等事件
 */

import { BigInt, Bytes, BigDecimal, log } from "@graphprotocol/graph-ts";
import {
  CorrelationRuleSet as CorrelationRuleSetEvent,
  DefaultPenaltyUpdated as DefaultPenaltyUpdatedEvent,
  ParlayBlocked as ParlayBlockedEvent,
} from "../generated/CorrelationGuard/CorrelationGuard";
import {
  CorrelationRule,
  CorrelationApplication,
} from "../generated/schema";
import {
  ZERO_BD,
  ZERO_BI,
  ONE_BI,
} from "./helpers";

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * 生成规则 ID（基于两个 matchId）
 */
function generateRuleId(matchId1: Bytes, matchId2: Bytes): string {
  // 确保顺序一致（较小的在前）
  if (matchId1.toHexString() < matchId2.toHexString()) {
    return matchId1.toHexString() + "-" + matchId2.toHexString();
  }
  return matchId2.toHexString() + "-" + matchId1.toHexString();
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * 处理相关性规则设置事件
 * event CorrelationRuleSet(
 *   bytes32 indexed matchId1,
 *   bytes32 indexed matchId2,
 *   uint256 penaltyBps,
 *   bool isBlocked
 * );
 */
export function handleCorrelationRuleSet(event: CorrelationRuleSetEvent): void {
  const ruleId = generateRuleId(event.params.matchId1, event.params.matchId2);

  // 加载或创建 CorrelationRule 实体
  let rule = CorrelationRule.load(ruleId);
  if (rule === null) {
    rule = new CorrelationRule(ruleId);
    rule.matchA = event.params.matchId1.toHexString();
    rule.matchB = event.params.matchId2.toHexString();
    rule.templateA = ""; // 从事件无法获取，留空
    rule.templateB = "";
    rule.outcomeA = 0;
    rule.outcomeB = 0;
    rule.createdAt = event.block.timestamp;
    rule.creator = event.transaction.from;
    rule.blockNumber = event.block.number;
    rule.transactionHash = event.transaction.hash;
  }

  // 更新规则
  rule.penaltyType = event.params.isBlocked ? "Block" : "Discount";
  rule.discountBps = event.params.penaltyBps.toI32();
  rule.isActive = true;

  rule.save();

  log.info("CorrelationRule set: {} (penalty: {}bps, blocked: {})", [
    ruleId,
    event.params.penaltyBps.toString(),
    event.params.isBlocked.toString(),
  ]);
}

/**
 * 处理默认惩罚更新事件
 * event DefaultPenaltyUpdated(uint256 sameMatchPenalty);
 *
 * 注意：此事件更新全局默认惩罚，不创建单独的规则实体
 * 可用于监控系统参数变化
 */
export function handleDefaultPenaltyUpdated(event: DefaultPenaltyUpdatedEvent): void {
  log.info("DefaultPenalty updated: {}bps at block {}", [
    event.params.sameMatchPenalty.toString(),
    event.block.number.toString(),
  ]);

  // 可选：创建一个特殊的 "default" 规则记录
  // 或记录到全局配置实体中
}

/**
 * 处理串关阻断事件
 * event ParlayBlocked(indexed address user, string reason);
 *
 * 注意：此事件记录用户被阻断的情况，可用于审计
 */
export function handleParlayBlocked(event: ParlayBlockedEvent): void {
  log.warning("Parlay blocked for user {} - Reason: {}", [
    event.params.user.toHexString(),
    event.params.reason,
  ]);

  // 可选：创建 CorrelationApplication 记录被阻断的情况
  // 或记录到专门的审计日志实体中
}
