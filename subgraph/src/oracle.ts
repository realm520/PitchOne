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
  const facts = event.params.facts;
  const factsHash = event.params.factsHash;
  const proposer = event.params.proposer;

  // 计算简单的结果：比较进球数
  const homeGoals = facts.homeGoals;
  const awayGoals = facts.awayGoals;
  let result = 1; // 默认平局
  if (homeGoals > awayGoals) {
    result = 0; // 主队胜
  } else if (awayGoals > homeGoals) {
    result = 2; // 客队胜
  }

  // 生成提案 ID
  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-")
    .concat(factsHash.toHexString());

  // 创建提案实体
  let proposal = new OracleProposal(proposalId);
  proposal.oracle = event.address;
  proposal.market = marketId.toHexString();
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
  const factsHash = event.params.factsHash;
  const disputer = event.params.disputer;
  const reason = event.params.reason;

  // 使用 marketId 和 factsHash 查找提案
  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-")
    .concat(factsHash.toHexString());

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
  const factsHash = event.params.factsHash;
  const accepted = event.params.accepted;

  // 使用 marketId 和 factsHash 查找提案
  const proposalId = event.address
    .toHexString()
    .concat("-")
    .concat(marketId.toHexString())
    .concat("-")
    .concat(factsHash.toHexString());

  let proposal = OracleProposal.load(proposalId);
  if (proposal === null) {
    // 创建占位符（理论上不应该发生）
    proposal = new OracleProposal(proposalId);
    proposal.oracle = event.address;
    proposal.market = marketId.toHexString();
    proposal.proposer = event.address;
    proposal.result = 0;
    proposal.bond = toDecimal(ZERO_BI);
    proposal.proposedAt = event.block.timestamp;
    proposal.disputed = false;
    proposal.disputer = null;
    proposal.disputedAt = null;
  }

  proposal.finalized = true;
  proposal.finalizedAt = event.block.timestamp;
  proposal.finalResult = accepted ? proposal.result : null;
  proposal.save();

  // 如果接受提案，更新市场状态
  if (accepted) {
    let market = Market.load(marketId.toHexString());
    if (market !== null && market.state === "Locked") {
      market.state = "Resolved";
      market.resolvedAt = event.block.timestamp;
      market.winnerOutcome = proposal.result;
      market.save();
    }
  }
}
