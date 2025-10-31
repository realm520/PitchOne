/**
 * PitchOne Subgraph - 预言机事件处理器
 * 处理结算结果的提案、争议和最终确认
 */

import { BigInt } from "@graphprotocol/graph-ts";
import {
  ResultProposed as ResultProposedEvent,
  ResultDisputed as ResultDisputedEvent,
  ResultFinalized as ResultFinalizedEvent,
} from "../generated/MockOracle/MockOracle";
import { OracleProposal, Market } from "../generated/schema";
import { toDecimal, ZERO_BI } from "./helpers";

// ============================================================================
// ResultProposed - 结果提案事件
// ============================================================================

export function handleResultProposed(event: ResultProposedEvent): void {
  const marketId = event.params.marketId;
  const proposer = event.params.proposer;
  const result = event.params.result.toI32();

  // 生成提案 ID
  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-")
    .concat(event.transaction.hash.toHexString());

  // 创建提案实体
  let proposal = new OracleProposal(proposalId);
  proposal.oracle = event.address;
  proposal.market = marketId.toHexString(); // 假设 marketId 是市场地址
  proposal.proposer = proposer;
  proposal.result = result;
  proposal.bond = toDecimal(ZERO_BI); // TODO: 从合约中获取质押金额
  proposal.proposedAt = event.block.timestamp;
  proposal.disputed = false;
  proposal.disputer = null;
  proposal.disputedAt = null;
  proposal.finalized = false;
  proposal.finalizedAt = null;
  proposal.finalResult = null;
  proposal.save();

  // 更新市场的预言机信息
  let market = Market.load(marketId.toHexString());
  if (market !== null) {
    market.oracle = event.address;
    market.save();
  }
}

// ============================================================================
// ResultDisputed - 结果争议事件
// ============================================================================

export function handleResultDisputed(event: ResultDisputedEvent): void {
  const marketId = event.params.marketId;
  const disputer = event.params.disputer;

  // 查找对应的提案
  // 注意：这里需要遍历所有提案找到匹配的，或者维护更好的索引
  // 简化处理：使用 marketId 作为查找依据

  // TODO: 实现更高效的查找逻辑
  // 暂时创建一个新的争议记录

  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-dispute-")
    .concat(event.transaction.hash.toHexString());

  let proposal = OracleProposal.load(proposalId);
  if (proposal === null) {
    // 如果找不到原始提案，创建一个占位符
    proposal = new OracleProposal(proposalId);
    proposal.oracle = event.address;
    proposal.market = marketId.toHexString();
    proposal.proposer = event.address; // 占位符
    proposal.result = 0; // 占位符
    proposal.bond = toDecimal(ZERO_BI);
    proposal.proposedAt = event.block.timestamp;
  }

  proposal.disputed = true;
  proposal.disputer = disputer;
  proposal.disputedAt = event.block.timestamp;
  proposal.save();
}

// ============================================================================
// ResultFinalized - 结果最终确认事件
// ============================================================================

export function handleResultFinalized(event: ResultFinalizedEvent): void {
  const marketId = event.params.marketId;
  const finalResult = event.params.result.toI32();

  // 查找对应的提案
  // 简化处理：使用 marketId 查找最近的提案

  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-")
    .concat(event.transaction.hash.toHexString());

  let proposal = OracleProposal.load(proposalId);
  if (proposal === null) {
    // 创建占位符
    proposal = new OracleProposal(proposalId);
    proposal.oracle = event.address;
    proposal.market = marketId.toHexString();
    proposal.proposer = event.address;
    proposal.result = finalResult;
    proposal.bond = toDecimal(ZERO_BI);
    proposal.proposedAt = event.block.timestamp;
    proposal.disputed = false;
    proposal.disputer = null;
    proposal.disputedAt = null;
  }

  proposal.finalized = true;
  proposal.finalizedAt = event.block.timestamp;
  proposal.finalResult = finalResult;
  proposal.save();

  // 更新市场状态（如果还未更新）
  let market = Market.load(marketId.toHexString());
  if (market !== null && market.state === "Locked") {
    market.state = "Resolved";
    market.resolvedAt = event.block.timestamp;
    market.winnerOutcome = finalResult;
    market.save();
  }
}
