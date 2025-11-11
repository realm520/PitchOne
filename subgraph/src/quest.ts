/**
 * PitchOne Subgraph - Quest 任务事件处理器
 * 处理任务创建、进度更新、完成、奖励领取等事件
 */

import { BigInt, Bytes, BigDecimal } from "@graphprotocol/graph-ts";
import {
  QuestCreated as QuestCreatedEvent,
  QuestProgressUpdated as QuestProgressUpdatedEvent,
  QuestCompleted as QuestCompletedEvent,
  QuestRewardClaimed as QuestRewardClaimedEvent,
  QuestStatusChanged as QuestStatusChangedEvent,
} from "../generated/Quest/Quest";
import {
  Quest,
  QuestProgress,
  QuestProgressUpdate,
  QuestRewardClaim,
  QuestStatusChange,
  QuestStats,
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
 * 加载或创建任务统计实体
 */
function loadOrCreateQuestStats(): QuestStats {
  let stats = QuestStats.load("quest-stats");
  if (stats === null) {
    stats = new QuestStats("quest-stats");
    stats.totalQuests = 0;
    stats.activeQuests = 0;
    stats.pausedQuests = 0;
    stats.endedQuests = 0;
    stats.totalRewards = ZERO_BD;
    stats.totalRewardsClaimed = ZERO_BD;
    stats.totalCompletions = 0;
    stats.uniqueCompletors = 0;
    stats.firstBetQuests = 0;
    stats.consecutiveBetsQuests = 0;
    stats.referralQuests = 0;
    stats.volumeQuests = 0;
    stats.winStreakQuests = 0;
    stats.lastUpdatedAt = ZERO_BI;
  }
  return stats;
}

/**
 * 将任务类型枚举转换为字符串
 */
function getQuestTypeString(questType: i32): string {
  if (questType == 0) return "FIRST_BET";
  if (questType == 1) return "CONSECUTIVE_BETS";
  if (questType == 2) return "REFERRAL";
  if (questType == 3) return "VOLUME";
  if (questType == 4) return "WIN_STREAK";
  return "UNKNOWN";
}

/**
 * 将任务状态枚举转换为字符串
 */
function getQuestStatusString(status: i32): string {
  if (status == 0) return "Active";
  if (status == 1) return "Paused";
  if (status == 2) return "Ended";
  return "Unknown";
}

// ============================================================================
// Event Handlers
// ============================================================================

/**
 * 处理任务创建事件
 */
export function handleQuestCreated(event: QuestCreatedEvent): void {
  const questId = event.params.questId.toHexString();
  const campaignId = event.params.campaignId.toHexString();

  // 创建 Quest 实体
  let quest = new Quest(questId);
  quest.campaign = campaignId;
  quest.questType = getQuestTypeString(event.params.questType);
  quest.name = event.params.name;
  quest.rewardAmount = toDecimal(event.params.rewardAmount, 6); // USDC 6 decimals
  quest.targetValue = toDecimal(event.params.targetValue, 18); // 通用 18 decimals
  quest.startTime = event.params.startTime;
  quest.endTime = event.params.endTime;
  quest.status = "Active";
  quest.completionCount = 0;
  quest.createdAt = event.block.timestamp;
  quest.updatedAt = event.block.timestamp;
  quest.creator = event.transaction.from; // Use tx sender as creator
  quest.blockNumber = event.block.number;
  quest.transactionHash = event.transaction.hash;
  quest.save();

  // 更新全局统计
  let stats = loadOrCreateQuestStats();
  stats.totalQuests += 1;
  stats.activeQuests += 1;
  stats.totalRewards = stats.totalRewards.plus(quest.rewardAmount);

  // 更新各类型任务计数
  const questType = quest.questType;
  if (questType == "FIRST_BET") {
    stats.firstBetQuests += 1;
  } else if (questType == "CONSECUTIVE_BETS") {
    stats.consecutiveBetsQuests += 1;
  } else if (questType == "REFERRAL") {
    stats.referralQuests += 1;
  } else if (questType == "VOLUME") {
    stats.volumeQuests += 1;
  } else if (questType == "WIN_STREAK") {
    stats.winStreakQuests += 1;
  }

  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理任务进度更新事件
 */
export function handleQuestProgressUpdated(
  event: QuestProgressUpdatedEvent
): void {
  const questId = event.params.questId.toHexString();
  const userAddress = event.params.user;
  const progressId = questId + "-" + userAddress.toHexString();

  // 加载 Quest
  let quest = Quest.load(questId);
  if (quest === null) {
    return;
  }

  // 加载或创建进度实体
  let progress = QuestProgress.load(progressId);
  if (progress === null) {
    progress = new QuestProgress(progressId);
    progress.quest = questId;
    progress.user = userAddress.toHexString();
    progress.targetValue = quest.targetValue;
    progress.currentValue = ZERO_BD;
    progress.completionPercentage = ZERO_BD;
    progress.completed = false;
    progress.rewardClaimed = false;
    progress.createdAt = event.block.timestamp;
  }

  // 记录旧值和新值
  const oldValue = progress.currentValue;
  const newValue = toDecimal(event.params.currentValue, 18);
  const targetValue = toDecimal(event.params.targetValue, 18);
  const incrementValue = newValue.minus(oldValue);

  // 更新进度
  progress.currentValue = newValue;
  progress.targetValue = targetValue;

  // 计算完成百分比
  if (progress.targetValue.gt(ZERO_BD)) {
    progress.completionPercentage = progress.currentValue
      .div(progress.targetValue)
      .times(BigDecimal.fromString("100"));
  } else {
    progress.completionPercentage = ZERO_BD;
  }

  progress.lastUpdateTime = event.block.timestamp;
  progress.save();

  // 创建进度更新记录
  const updateId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();
  let update = new QuestProgressUpdate(updateId);
  update.progress = progressId;
  update.quest = questId;
  update.user = userAddress.toHexString();
  update.incrementValue = incrementValue;
  update.oldValue = oldValue;
  update.newValue = newValue;
  update.completedInThisUpdate = false; // 将在 QuestCompleted 事件中标记
  update.timestamp = event.block.timestamp;
  update.blockNumber = event.block.number;
  update.transactionHash = event.transaction.hash;
  update.save();

  // 确保用户实体存在
  loadOrCreateUser(userAddress);
}

/**
 * 处理任务完成事件
 */
export function handleQuestCompleted(event: QuestCompletedEvent): void {
  const questId = event.params.questId.toHexString();
  const userAddress = event.params.user;
  const progressId = questId + "-" + userAddress.toHexString();

  // 加载进度
  let progress = QuestProgress.load(progressId);
  if (progress === null) {
    return;
  }

  // 标记为已完成
  progress.completed = true;
  progress.completedAt = event.block.timestamp;
  progress.completionPercentage = BigDecimal.fromString("100");
  progress.save();

  // 更新任务完成人数
  let quest = Quest.load(questId);
  if (quest !== null) {
    quest.completionCount += 1;
    quest.updatedAt = event.block.timestamp;
    quest.save();
  }

  // 更新全局统计
  let stats = loadOrCreateQuestStats();
  stats.totalCompletions += 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理任务奖励领取事件
 */
export function handleQuestRewardClaimed(
  event: QuestRewardClaimedEvent
): void {
  const questId = event.params.questId.toHexString();
  const userAddress = event.params.user;
  const progressId = questId + "-" + userAddress.toHexString();
  const claimId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 更新进度状态
  let progress = QuestProgress.load(progressId);
  if (progress !== null) {
    progress.rewardClaimed = true;
    progress.rewardClaimedAt = event.block.timestamp;
    progress.save();
  }

  // 创建奖励领取记录
  let claim = new QuestRewardClaim(claimId);
  claim.quest = questId;
  claim.user = userAddress.toHexString();
  claim.rewardAmount = toDecimal(event.params.rewardAmount, 6);
  claim.timestamp = event.block.timestamp;
  claim.blockNumber = event.block.number;
  claim.transactionHash = event.transaction.hash;
  claim.save();

  // 更新全局统计
  let stats = loadOrCreateQuestStats();
  stats.totalRewardsClaimed = stats.totalRewardsClaimed.plus(claim.rewardAmount);
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理任务状态变更事件
 */
export function handleQuestStatusChanged(
  event: QuestStatusChangedEvent
): void {
  const questId = event.params.questId.toHexString();
  const changeId =
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString();

  // 加载任务
  let quest = Quest.load(questId);
  if (quest === null) {
    return;
  }

  const oldStatus = quest.status;
  const newStatus = getQuestStatusString(event.params.newStatus);

  // 更新任务状态
  quest.status = newStatus;
  quest.updatedAt = event.block.timestamp;
  quest.save();

  // 创建状态变更记录
  let statusChange = new QuestStatusChange(changeId);
  statusChange.quest = questId;
  statusChange.oldStatus = oldStatus;
  statusChange.newStatus = newStatus;
  statusChange.timestamp = event.block.timestamp;
  statusChange.blockNumber = event.block.number;
  statusChange.transactionHash = event.transaction.hash;
  statusChange.save();

  // 更新全局统计
  let stats = loadOrCreateQuestStats();

  // 减少旧状态计数
  if (oldStatus == "Active") {
    stats.activeQuests -= 1;
  } else if (oldStatus == "Paused") {
    stats.pausedQuests -= 1;
  } else if (oldStatus == "Ended") {
    stats.endedQuests -= 1;
  }

  // 增加新状态计数
  if (newStatus == "Active") {
    stats.activeQuests += 1;
  } else if (newStatus == "Paused") {
    stats.pausedQuests += 1;
  } else if (newStatus == "Ended") {
    stats.endedQuests += 1;
  }

  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}
