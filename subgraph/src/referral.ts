/**
 * ReferralRegistry 事件处理器
 * 处理推荐关系绑定和返佣记录
 */

import { BigDecimal, BigInt, Bytes } from '@graphprotocol/graph-ts';
import {
  ReferralBound as ReferralBoundEvent,
  ReferralAccrued as ReferralAccruedEvent,
} from '../generated/ReferralRegistry/ReferralRegistry';
import { Referral, ReferrerStats, ReferralReward, User } from '../generated/schema';

// 常量
const ZERO_BD = BigDecimal.zero();
const USDC_DECIMALS = 6;

/**
 * 将 USDC 原始值（6 decimals）转换为 BigDecimal
 */
function convertUSDCToBigDecimal(value: BigInt): BigDecimal {
  return value.toBigDecimal().div(BigDecimal.fromString('1000000'));
}

/**
 * 处理推荐关系绑定事件
 * @param event ReferralBound 事件
 */
export function handleReferralBound(event: ReferralBoundEvent): void {
  const referrerId = event.params.referrer.toHexString().toLowerCase();
  const refereeId = event.params.user.toHexString().toLowerCase();
  const referralId = `${referrerId}-${refereeId}`;

  // ============================================
  // 1. 确保 ReferrerStats 存在（先创建/加载，后续会更新）
  // ============================================
  let stats = ReferrerStats.load(referrerId);
  if (stats == null) {
    // 如果统计实体不存在，创建新的
    stats = new ReferrerStats(referrerId);
    stats.referrer = referrerId;
    stats.referralCount = 0;
    stats.totalRewards = ZERO_BD;
    stats.validReferralCount = 0;
    stats.lastUpdatedAt = event.block.timestamp;
    stats.save();
  }

  // ============================================
  // 2. 创建 Referral 实体
  // ============================================
  let referral = new Referral(referralId);
  referral.referrer = referrerId;
  referral.referee = refereeId;
  referral.referrerStats = referrerId; // 关联到 ReferrerStats
  referral.campaignId = event.params.campaignId;
  referral.boundAt = event.params.timestamp;
  referral.blockNumber = event.block.number;
  referral.transactionHash = event.transaction.hash;
  referral.save();

  // ============================================
  // 3. 更新被推荐人（User）的 referrer 字段
  // ============================================
  let referee = User.load(refereeId);
  if (referee == null) {
    // 如果用户不存在，创建新用户
    referee = new User(refereeId);
    referee.totalBetAmount = ZERO_BD;
    referee.totalRedeemed = ZERO_BD;
    referee.netProfit = ZERO_BD;
    referee.totalBets = 0;
    referee.marketsParticipated = 0;
  }
  referee.referrer = event.params.referrer;
  referee.save();

  // ============================================
  // 4. 更新推荐人（User）实体（如果不存在则创建）
  // ============================================
  let referrer = User.load(referrerId);
  if (referrer == null) {
    referrer = new User(referrerId);
    referrer.totalBetAmount = ZERO_BD;
    referrer.totalRedeemed = ZERO_BD;
    referrer.netProfit = ZERO_BD;
    referrer.totalBets = 0;
    referrer.marketsParticipated = 0;
    referrer.save();
  }

  // ============================================
  // 5. 更新 ReferrerStats 统计
  // ============================================
  // 推荐人数 +1
  stats.referralCount = stats.referralCount + 1;
  stats.lastUpdatedAt = event.block.timestamp;
  stats.save();
}

/**
 * 处理推荐返佣事件
 * @param event ReferralAccrued 事件
 */
export function handleReferralAccrued(event: ReferralAccruedEvent): void {
  const referrerId = event.params.referrer.toHexString().toLowerCase();
  const refereeId = event.params.user.toHexString().toLowerCase();
  const rewardId = `${event.transaction.hash.toHexString()}-${event.logIndex.toString()}`;

  // ============================================
  // 1. 确保 ReferrerStats 存在
  // ============================================
  let stats = ReferrerStats.load(referrerId);
  if (stats == null) {
    // 如果统计实体不存在（理论上不应该发生，但做防御性编程）
    stats = new ReferrerStats(referrerId);
    stats.referrer = referrerId;
    stats.referralCount = 0;
    stats.totalRewards = ZERO_BD;
    stats.validReferralCount = 0;
    stats.lastUpdatedAt = event.block.timestamp;
    stats.save();
  }

  // ============================================
  // 2. 创建 ReferralReward 实体
  // ============================================
  let reward = new ReferralReward(rewardId);
  reward.referrer = referrerId;
  reward.referee = refereeId;
  reward.referrerStats = referrerId; // 关联到 ReferrerStats
  reward.amount = convertUSDCToBigDecimal(event.params.amount);
  reward.timestamp = event.params.timestamp;
  reward.blockNumber = event.block.number;
  reward.transactionHash = event.transaction.hash;
  reward.save();

  // ============================================
  // 3. 更新 ReferrerStats 实体的累计返佣
  // ============================================
  // 累加返佣金额
  stats.totalRewards = stats.totalRewards.plus(reward.amount);
  stats.lastUpdatedAt = event.block.timestamp;

  // 检查被推荐人是否已下注（有效推荐）
  let referee = User.load(refereeId);
  if (referee != null && referee.totalBets > 0) {
    // 如果被推荐人已下注，更新有效推荐人数
    // 注意：这里简化处理，实际可能需要更精确的逻辑（例如标记已计入）
    // TODO: 优化逻辑，避免重复计数
    if (stats.validReferralCount < stats.referralCount) {
      stats.validReferralCount = stats.validReferralCount + 1;
    }
  }

  stats.save();

  // ============================================
  // 4. 确保推荐人 User 实体存在
  // ============================================
  let referrer = User.load(referrerId);
  if (referrer == null) {
    referrer = new User(referrerId);
    referrer.totalBetAmount = ZERO_BD;
    referrer.totalRedeemed = ZERO_BD;
    referrer.netProfit = ZERO_BD;
    referrer.totalBets = 0;
    referrer.marketsParticipated = 0;
    referrer.save();
  }
}
