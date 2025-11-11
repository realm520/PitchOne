/**
 * PitchOne Subgraph - Campaign 活动事件处理器
 * 处理活动创建、参与、预算变更、状态变更等事件
 */

import { BigInt, Bytes, BigDecimal } from "@graphprotocol/graph-ts";
import {
  CampaignCreated as CampaignCreatedEvent,
  CampaignParticipated as CampaignParticipatedEvent,
  CampaignBudgetIncreased as CampaignBudgetIncreasedEvent,
  CampaignBudgetSpent as CampaignBudgetSpentEvent,
  CampaignStatusChanged as CampaignStatusChangedEvent,
} from "../generated/Campaign/Campaign";
import {
  Campaign,
  CampaignParticipation,
  CampaignBudgetChange,
  CampaignStatusChange,
  CampaignStats,
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
 * 加载或创建活动统计实体
 */
function loadOrCreateCampaignStats(): CampaignStats {
  let stats = CampaignStats.load("campaign-stats");
  if (stats === null) {
    stats = new CampaignStats("campaign-stats");
    stats.totalCampaigns = 0;
    stats.activeCampaigns = 0;
    stats.pausedCampaigns = 0;
    stats.endedCampaigns = 0;
    stats.totalBudget = ZERO_BD;
    stats.totalSpent = ZERO_BD;
    stats.totalParticipations = 0;
    stats.uniqueParticipants = 0;
    stats.lastUpdatedAt = ZERO_BI;
  }
  return stats;
}

/**
 * 将活动状态枚举转换为字符串
 */
function getStatusString(status: i32): string {
  if (status == 0) return "Active";
  if (status == 1) return "Paused";
  if (status == 2) return "Ended";
  return "Unknown";
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * 处理活动创建事件
 */
export function handleCampaignCreated(event: CampaignCreatedEvent): void {
  const campaignId = event.params.campaignId.toHexString();

  // 创建 Campaign 实体
  let campaign = new Campaign(campaignId);
  campaign.name = event.params.name;
  campaign.ruleHash = event.params.ruleHash;
  campaign.budgetCap = toDecimal(event.params.budgetCap, 6); // USDC 6 decimals
  campaign.spentAmount = ZERO_BD;
  campaign.remainingBudget = campaign.budgetCap;
  campaign.startTime = event.params.startTime;
  campaign.endTime = event.params.endTime;
  campaign.status = "Active";
  campaign.participantCount = 0;
  campaign.createdAt = event.block.timestamp;
  campaign.updatedAt = event.block.timestamp;
  campaign.creator = event.transaction.from; // Use tx sender as creator
  campaign.blockNumber = event.block.number;
  campaign.transactionHash = event.transaction.hash;
  campaign.save();

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();
  stats.totalCampaigns += 1;
  stats.activeCampaigns += 1;
  stats.totalBudget = stats.totalBudget.plus(campaign.budgetCap);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理用户参与活动事件
 */
export function handleCampaignParticipated(
  event: CampaignParticipatedEvent
): void {
  const campaignId = event.params.campaignId.toHexString();
  const userAddress = event.params.user;
  const participationId = campaignId + "-" + userAddress.toHexString();

  // 检查是否已参与（防重复）
  let participation = CampaignParticipation.load(participationId);
  if (participation !== null) {
    // 已参与，跳过
    return;
  }

  // 创建参与记录
  participation = new CampaignParticipation(participationId);
  participation.campaign = campaignId;
  participation.user = userAddress.toHexString();
  participation.timestamp = event.block.timestamp;
  participation.blockNumber = event.block.number;
  participation.transactionHash = event.transaction.hash;
  participation.save();

  // 更新活动参与人数
  let campaign = Campaign.load(campaignId);
  if (campaign !== null) {
    campaign.participantCount += 1;
    campaign.updatedAt = event.block.timestamp;
    campaign.save();
  }

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();
  stats.totalParticipations += 1;
  // 注意：uniqueParticipants 需要额外逻辑统计（可在链下计算）
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();

  // 确保用户实体存在
  loadOrCreateUser(userAddress);
}

/**
 * 处理活动预算增加事件
 */
export function handleCampaignBudgetIncreased(
  event: CampaignBudgetIncreasedEvent
): void {
  const campaignId = event.params.campaignId.toHexString();
  const changeId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 加载活动
  let campaign = Campaign.load(campaignId);
  if (campaign === null) {
    return;
  }

  const oldCap = toDecimal(event.params.oldCap, 6);
  const newCap = toDecimal(event.params.newCap, 6);
  const addedAmount = newCap.minus(oldCap);

  // 更新活动预算
  campaign.budgetCap = newCap;
  campaign.remainingBudget = campaign.remainingBudget.plus(addedAmount);
  campaign.updatedAt = event.block.timestamp;
  campaign.save();

  // 创建预算变更记录
  let budgetChange = new CampaignBudgetChange(changeId);
  budgetChange.campaign = campaignId;
  budgetChange.changeType = "Increased";
  budgetChange.amount = addedAmount;
  budgetChange.oldValue = oldCap;
  budgetChange.newValue = newCap;
  budgetChange.timestamp = event.block.timestamp;
  budgetChange.blockNumber = event.block.number;
  budgetChange.transactionHash = event.transaction.hash;
  budgetChange.save();

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();
  stats.totalBudget = stats.totalBudget.plus(addedAmount);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理活动预算支出事件
 */
export function handleCampaignBudgetSpent(
  event: CampaignBudgetSpentEvent
): void {
  const campaignId = event.params.campaignId.toHexString();
  const changeId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 加载活动
  let campaign = Campaign.load(campaignId);
  if (campaign === null) {
    return;
  }

  const amount = toDecimal(event.params.amount, 6);
  const totalSpent = toDecimal(event.params.totalSpent, 6);

  // 更新活动支出
  campaign.spentAmount = totalSpent;
  campaign.remainingBudget = campaign.budgetCap.minus(totalSpent);
  campaign.updatedAt = event.block.timestamp;
  campaign.save();

  // 创建预算变更记录
  let budgetChange = new CampaignBudgetChange(changeId);
  budgetChange.campaign = campaignId;
  budgetChange.changeType = "Spent";
  budgetChange.amount = amount;
  budgetChange.oldValue = totalSpent.minus(amount);
  budgetChange.newValue = totalSpent;
  budgetChange.timestamp = event.block.timestamp;
  budgetChange.blockNumber = event.block.number;
  budgetChange.transactionHash = event.transaction.hash;
  budgetChange.save();

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();
  stats.totalSpent = stats.totalSpent.plus(amount);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理活动状态变更事件
 */
export function handleCampaignStatusChanged(
  event: CampaignStatusChangedEvent
): void {
  const campaignId = event.params.campaignId.toHexString();
  const changeId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 加载活动
  let campaign = Campaign.load(campaignId);
  if (campaign === null) {
    return;
  }

  const oldStatus = campaign.status;
  const newStatus = getStatusString(event.params.newStatus);

  // 更新活动状态
  campaign.status = newStatus;
  campaign.updatedAt = event.block.timestamp;
  campaign.save();

  // 创建状态变更记录
  let statusChange = new CampaignStatusChange(changeId);
  statusChange.campaign = campaignId;
  statusChange.oldStatus = oldStatus;
  statusChange.newStatus = newStatus;
  statusChange.timestamp = event.block.timestamp;
  statusChange.blockNumber = event.block.number;
  statusChange.transactionHash = event.transaction.hash;
  statusChange.save();

  // 更新全局统计
  let stats = loadOrCreateCampaignStats();

  // 减少旧状态计数
  if (oldStatus == "Active") {
    stats.activeCampaigns -= 1;
  } else if (oldStatus == "Paused") {
    stats.pausedCampaigns -= 1;
  } else if (oldStatus == "Ended") {
    stats.endedCampaigns -= 1;
  }

  // 增加新状态计数
  if (newStatus == "Active") {
    stats.activeCampaigns += 1;
  } else if (newStatus == "Paused") {
    stats.pausedCampaigns += 1;
  } else if (newStatus == "Ended") {
    stats.endedCampaigns += 1;
  }

  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}
