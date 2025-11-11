# ScoreTemplate 精确比分市场使用文档

**版本**: v1.0
**日期**: 2025-11-08
**合约**: `contracts/src/templates/ScoreTemplate.sol`
**测试**: `contracts/test/unit/ScoreTemplate.t.sol` (34 个测试，100% 通过)

---

## 📊 概述

**ScoreTemplate** 是精确比分市场模板，允许用户对足球比赛的具体比分进行投注（如 0-0, 1-0, 2-1 等）。

### 适用场景
- ✅ **精确比分投注**: 用户预测准确比分（如 2-1, 3-0）
- ✅ **多结果市场**: 25-50 个可能结果（基于 maxGoals 配置）
- ✅ **Other 比分**: 超出范围的比分归为特殊结果
- ✅ **LMSR 定价**: 使用 Logarithmic Market Scoring Rule 提供流动性

### 核心优势
1. **灵活的比分范围**: 可配置支持 0-0 到 maxGoals-maxGoals
2. **智能编码方案**: homeGoals * 10 + awayGoals（如 21 = 2-1）
3. **自动处理超范围**: 6-0, 7-3 等自动归入 Other 结果
4. **LMSR 定价**: 无套利、流动性可调、价格总和 100%

---

## 🎯 核心设计

### 1. Outcome 编码方案

**编码公式**:
```
outcomeId = homeGoals * 10 + awayGoals
特殊: 999 = Other (超出 maxGoals 的任何比分)
```

**编码示例** (假设 maxGoals = 5):
```
0-0 → 0
1-0 → 10
0-1 → 1
1-1 → 11
2-1 → 21
5-5 → 55
6-0 → 999 (Other)
7-3 → 999 (Other)
```

**内部索引映射**:
- MarketBase 使用索引 0 到 outcomeCount-1
- ScoreTemplate 维护 `validOutcomeIds` 数组映射索引到编码值
- 例如: index 0 → outcomeId 0 (0-0), index 36 → outcomeId 999 (Other)

### 2. 结果数量计算

```solidity
outcomeCount = (maxGoals + 1) * (maxGoals + 1) + 1

// 示例:
maxGoals = 5 → outcomeCount = 6 * 6 + 1 = 37
maxGoals = 4 → outcomeCount = 5 * 5 + 1 = 26
maxGoals = 3 → outcomeCount = 4 * 4 + 1 = 17
```

---

## 🛠️ 基本用法

### 通过 Factory 创建市场

```solidity
// 准备初始化数据
ScoreTemplate.ScoreMarketInitData memory initData = ScoreTemplate.ScoreMarketInitData({
    matchId: "EPL_2024_MUN_vs_MCI",
    event: "Manchester United vs Manchester City",
    homeTeam: "Manchester United",
    awayTeam: "Manchester City",
    kickoffTime: block.timestamp + 3 days,
    maxGoals: 5,  // 支持 0-0 到 5-5，加 Other
    liquidityB: 5000 * 1e18,  // LMSR 流动性参数
    initialQuantities: new uint256[](37)  // 37 个结果的初始份额
});

// 设置初始概率分布（可选，不提供则均匀分布）
initData.initialQuantities[0] = 150 * 1e18;   // 0-0: 高概率
initData.initialQuantities[11] = 120 * 1e18;  // 1-1: 中高概率
initData.initialQuantities[21] = 100 * 1e18;  // 2-1: 中等概率
// ... 其他比分

// 通过 Factory 创建市场
bytes memory encodedData = abi.encode(initData);
address marketAddr = marketFactory.createMarket(scoreTemplateId, encodedData);
ScoreTemplate market = ScoreTemplate(marketAddr);
```

### 用户下注

```solidity
// 用户下注 100 USDC 在比分 2-1 上
uint256 betAmount = 100 * 1e6; // USDC 6 decimals

// 计算 2-1 的 outcomeIndex
uint8 homeGoals = 2;
uint8 awayGoals = 1;
uint256 outcomeIndex = homeGoals * (market.maxGoals() + 1) + awayGoals;
// outcomeIndex = 2 * 6 + 1 = 13

// 用户授权并下注
usdc.approve(address(market), betAmount);
uint256 shares = market.placeBet(outcomeIndex, betAmount);

// 用户获得 ERC-1155 头寸 Token
uint256 balance = market.balanceOf(msg.sender, outcomeIndex);
```

### 查询价格

```solidity
// 方法 1: 通过索引查询价格
uint256 outcomeIndex = 13; // 2-1
uint256 price = market.getCurrentPrice(outcomeIndex);
// price 单位: 基点 (0-10000, 即 0%-100%)
console.log("2-1 probability: %d%%", price / 100);

// 方法 2: 通过比分查询价格（使用辅助函数）
uint256 price = market.getPriceByScore(2, 1);

// 方法 3: 批量查询多个比分
uint8[] memory homeGoals = new uint8[](3);
homeGoals[0] = 0; homeGoals[1] = 1; homeGoals[2] = 2;
uint8[] memory awayGoals = new uint8[](3);
awayGoals[0] = 0; awayGoals[1] = 0; awayGoals[2] = 1;

uint256[] memory prices = market.queryScorePrices(homeGoals, awayGoals);
// prices[0] = 0-0 概率
// prices[1] = 1-0 概率
// prices[2] = 2-1 概率
```

### 锁盘与结算

```solidity
// 1. Keeper 在开赛前 5 分钟锁盘
market.lock();

// 2. 比赛结束，Keeper 调用 UMA OO 提交赛果
IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
    matchId: "EPL_2024_MUN_vs_MCI",
    homeGoals: 2,
    awayGoals: 1,
    awayBetrayal: false,
    homeBetrayal: false,
    // ... 其他字段
});
umaAdapter.proposeResult(facts);

// 3. 争议窗口结束，市场自动解决
// winningOutcomeId = determineWinningOutcome(2, 1) = 21

// 4. 用户兑付赢得的头寸
market.redeem(outcomeIndex, shares);
```

---

## 📐 参数配置指南

### maxGoals 的选择

| maxGoals | 结果数 | 适用场景 | Gas 消耗 |
|----------|--------|---------|---------|
| 3 | 17 | 低进球场次 | 低 |
| 4 | 26 | 一般场次 | 中 |
| 5 | 37 | 高进球场次 | 中高 |
| 6 | 50 | 特殊场次 | 高 |

**推荐**: maxGoals = 5（覆盖 99% 的足球比赛结果）

### liquidityB 的选择

参考 LMSR 定价引擎指南：

| 结果数 | 建议 liquidityB | 说明 |
|--------|----------------|------|
| 17-26 | 3,000 - 5,000 | 中等流动性 |
| 37-50 | 5,000 - 10,000 | 平衡流动性和滑点 |

**规则**:
- liquidityB 越大 → 滑点越小，用户体验越好，但平台风险越高
- liquidityB 越小 → 滑点越大，用户体验下降，但平台风险越低

### 初始概率分布

**方案 1: 均匀分布**（最简单）
```solidity
uint256[] memory initialQuantities = new uint256[](37);
for (uint256 i = 0; i < 37; i++) {
    initialQuantities[i] = 100 * 1e18; // 每个结果相同概率
}
```

**方案 2: 基于历史统计**（推荐）
```solidity
// 足球精确比分历史概率（示例数据）
initialQuantities[0] = 150 * 1e18;   // 0-0: 15%
initialQuantities[10] = 120 * 1e18;  // 1-0: 12%
initialQuantities[1] = 100 * 1e18;   // 0-1: 10%
initialQuantities[11] = 120 * 1e18;  // 1-1: 12%
initialQuantities[20] = 100 * 1e18;  // 2-0: 10%
initialQuantities[2] = 80 * 1e18;    // 0-2: 8%
initialQuantities[21] = 90 * 1e18;   // 2-1: 9%
initialQuantities[12] = 80 * 1e18;   // 1-2: 8%
initialQuantities[22] = 70 * 1e18;   // 2-2: 7%
// ... 其他比分较低概率
initialQuantities[36] = 60 * 1e18;   // Other: 6%
```

**计算初始份额**（基于目标概率）:
```python
# 目标概率 p_i，流动性参数 b
# 初始份额 q_i 应正比于 ln(p_i)
# 简化方案：q_i 正比于 p_i
q_i = baseQuantity * (p_i / p_avg)
```

---

## 🔍 高级功能

### 动态调整流动性

```solidity
// 仅 owner 可调用
uint256 newLiquidityB = 7000 * 1e18;
market.setLiquidityB(newLiquidityB);

// 事件: LiquidityBUpdated(oldB, newB)
```

**使用场景**:
- 市场开盘初期: 使用较小 liquidityB（降低风险）
- 流动性充足后: 增加 liquidityB（提升体验）
- 临近锁盘: 减少 liquidityB（减少冲击）

### 查询市场状态

```solidity
// 获取所有有效 Outcome IDs（编码值）
uint256[] memory outcomeIds = market.getValidOutcomeIds();
// outcomeIds = [0, 1, 10, 11, 20, 21, ..., 999]

// 获取当前 LMSR 成本函数值
uint256 currentCost = market.getCurrentCost();

// 获取所有价格（按索引）
uint256[] memory prices = new uint256[](market.outcomeCount());
for (uint256 i = 0; i < market.outcomeCount(); i++) {
    prices[i] = market.getCurrentPrice(i);
}
```

### 辅助函数

```solidity
// 编码比分
uint256 outcomeId = market.encodeScore(2, 1); // 返回 21

// 检查比分是否在范围内
bool inRange = market.isScoreInRange(6, 0); // false (超出 maxGoals=5)
bool inRange = market.isScoreInRange(3, 2); // true

// 通过比分查询价格
uint256 price = market.getPriceByScore(2, 1); // 等价于 getCurrentPrice(21 的索引)
```

---

## ⚠️ 注意事项

### 编码与索引的区别

**关键概念**:
- **编码值 (outcomeId)**: homeGoals * 10 + awayGoals (如 21, 32, 999)
- **索引值 (index)**: MarketBase 使用的 0 到 outcomeCount-1

**在不同场景中使用**:
- `placeBet(index, amount)` - 使用索引
- `getCurrentPrice(index)` - 使用索引
- `encodeScore(home, away)` - 返回编码值
- `getPriceByScore(home, away)` - 内部转换为索引

**示例**:
```solidity
// ❌ 错误：直接使用编码值
market.placeBet(21, betAmount); // 可能 revert（21 可能不是有效索引）

// ✅ 正确：先计算索引
uint256 index = 2 * (market.maxGoals() + 1) + 1;
market.placeBet(index, betAmount);

// ✅ 或使用辅助函数
uint256 price = market.getPriceByScore(2, 1);
```

### Gas 消耗

| 操作 | Gas 消耗 (估算) |
|------|----------------|
| 创建市场 (37 结果) | ~10,000,000 |
| placeBet | ~300,000 - 350,000 |
| getCurrentPrice | ~80,000 - 100,000 |
| queryScorePrices (10 个) | ~600,000 |
| redeem | ~150,000 |

**优化建议**:
- 前端缓存价格查询结果
- 批量查询使用 `queryScorePrices` 而非循环调用
- 考虑使用链下计算 + 链上验证

### 数值边界

- **maxGoals**: [3, 9]（推荐 5）
- **outcomeCount**: [17, 101]
- **liquidityB**: [1,000, 100,000] WAD
- **价格**: [1 bp, 9999 bp] (0.01% - 99.99%)

---

## 🧪 测试覆盖

### 测试统计
- **总测试数**: 34 个
- **通过率**: 100%
- **覆盖场景**:
  - 初始化验证 (6 测试)
  - 编码/解码逻辑 (5 测试)
  - 下注功能 (8 测试)
  - 价格查询 (5 测试)
  - 结算逻辑 (4 测试)
  - 流动性调整 (2 测试)
  - 辅助函数 (2 测试)
  - 边界测试 (2 测试)

### 关键测试用例

```bash
# 运行所有测试
forge test --match-path test/unit/ScoreTemplate.t.sol

# 运行特定测试
forge test --match-test test_PlaceBet_StandardScore -vv

# Gas 报告
forge test --match-path test/unit/ScoreTemplate.t.sol --gas-report
```

---

## 📚 集成示例

### 前端查询价格

```typescript
// TypeScript / ethers.js
import { ethers } from "ethers";

const market = new ethers.Contract(marketAddress, ScoreTemplate_ABI, provider);

// 查询 2-1 的价格
const maxGoals = await market.maxGoals();
const outcomeIndex = 2 * (maxGoals + 1) + 1;
const price = await market.getCurrentPrice(outcomeIndex);
console.log(`2-1 probability: ${price.toNumber() / 100}%`);

// 或使用辅助函数
const price = await market.getPriceByScore(2, 1);

// 批量查询常见比分
const homeGoals = [0, 1, 0, 1, 2, 2];
const awayGoals = [0, 0, 1, 1, 0, 1];
const prices = await market.queryScorePrices(homeGoals, awayGoals);
prices.forEach((p, i) => {
  console.log(`${homeGoals[i]}-${awayGoals[i]}: ${p.toNumber() / 100}%`);
});
```

### 下注流程

```typescript
// 用户下注 100 USDC 在 2-1 上
const betAmount = ethers.utils.parseUnits("100", 6); // USDC 6 decimals

// 计算 outcomeIndex
const maxGoals = await market.maxGoals();
const outcomeIndex = 2 * (maxGoals.toNumber() + 1) + 1;

// 授权
const usdc = new ethers.Contract(usdcAddress, ERC20_ABI, signer);
await usdc.approve(market.address, betAmount);

// 下注
const tx = await market.placeBet(outcomeIndex, betAmount);
const receipt = await tx.wait();

// 解析事件获取 shares
const event = receipt.events.find(e => e.event === "ScoreBetPlaced");
const shares = event.args.shares;
console.log(`You received ${ethers.utils.formatUnits(shares, 18)} shares`);
```

### Keeper 结算

```typescript
// Keeper 脚本
const keeper = new ethers.Contract(keeperAddress, Keeper_ABI, signer);

// 1. 锁盘（开赛前 5 分钟）
if (Date.now() >= kickoffTime - 5 * 60 * 1000) {
  await market.lock();
}

// 2. 提交赛果（比赛结束后）
if (matchFinished) {
  const facts = {
    matchId: "EPL_2024_MUN_vs_MCI",
    homeGoals: 2,
    awayGoals: 1,
    // ... 其他字段
  };
  await umaAdapter.proposeResult(facts);
}
```

---

## 🔗 相关资源

### 内部文档
- [LMSR 使用文档](./LMSR_Usage.md)
- [M3 开发计划](../../docs/M3_DEVELOPMENT_PLAN.md)
- [事件字典](../../docs/模块接口事件参数/EVENT_DICTIONARY.md)

### 参考合约
- `contracts/src/pricing/LMSR.sol` - LMSR 定价引擎
- `contracts/src/core/MarketBase.sol` - 市场基类
- `contracts/src/templates/WDL_Template.sol` - 胜平负模板（参考）

---

## 🚀 下一步

1. ✅ ScoreTemplate 核心实现完成（450 行代码，34 测试）
2. ✅ LMSR 集成完成（100% 测试通过）
3. ⏳ Gas 优化分析（待完成）
4. ⏳ 前端集成与 UI 开发（待完成）

---

**作者**: Claude Code
**最后更新**: 2025-11-08
**版本**: v1.0
