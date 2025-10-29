# RewardsDistributor / ReferralRegistry / Campaign-Quest 详细设计

## 1. 概述
- **Referral**：一次绑定长期分成（8–12%）；
- **Rewards**：周度 Merkle 空投/返利/任务发放；
- **Campaign/Quest**：链上登记规则哈希与预算上限，发放 Credit/Coupon。

## 2. 数据与状态
- Referral：`referrer[user]`、有效窗口、累计计提；
- Rewards：`week -> merkleRoot, scaleBps, totalAmount`；
- Campaign：`id, ruleHash(IPFS), budgetCap, startAt, endAt`。

## 3. 接口
- Referral：`bind(referrer,campaignId)`；查询 `getReferrer(user)`；
- Rewards：`publish(week,root,scaleBps)`；`claim(week,amount,proof)`；
- Campaign：`create(id,ruleHash,budgetCap,startAt,endAt)`。

## 4. 事件
- `ReferralBound/ReferralAccrued`；`RewardsRootPublished/RewardClaimed`；`CampaignCreated`。

## 5. 参数与安全
- Promo 预算不足 → `scaleBps` 统一缩放；
- 反作弊：有效用户判定；claim 线性释放（T+7）。

## 6. 测试/运维
- Merkle 对账、一致性；返佣重复领取保护；活动预算硬上限与报警。
