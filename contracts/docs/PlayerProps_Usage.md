# PlayerProps 球员道具市场使用文档

**版本**: v1.0
**日期**: 2025-11-08
**合约**: `contracts/src/templates/PlayerProps_Template.sol`
**测试**: `contracts/test/unit/PlayerProps.t.sol` (14 个测试，100% 通过)

---

## 📊 概述

**PlayerProps_Template** 是球员道具市场模板，支持基于球员个人表现的投注玩法。

### 适用场景
- ✅ **进球数大小（Goals O/U）**: 球员进球数 Over/Under
- ✅ **助攻数大小（Assists O/U）**: 球员助攻数 Over/Under
- ✅ **射门次数大小（Shots O/U）**: 球员射门次数 Over/Under
- ✅ **黄牌 Yes/No**: 球员是否吃黄牌
- ✅ **红牌 Yes/No**: 球员是否吃红牌
- ✅ **任意时间进球**: 球员是否会进球
- ✅ **首位进球者**: 谁会打入本场首球（多向市场）

### 核心优势
1. **多定价引擎支持**: SimpleCPMM（二/三向）+ LMSR（多向）
2. **智能市场类型**: 自动识别半球/整球盘，整球盘支持 Push
3. **真实球员数据**: 集成 IResultOracle PlayerStats
4. **灵活的结算逻辑**: 支持 7 种道具类型

---

## 🎯 核心设计

### 1. 道具类型分类

**O/U 类型**（Over/Under）:
- `GOALS_OU` - 进球数大小
- `ASSISTS_OU` - 助攻数大小
- `SHOTS_OU` - 射门次数大小

**Yes/No 类型**:
- `YELLOW_CARD` - 黄牌 Yes/No
- `RED_CARD` - 红牌 Yes/No
- `ANYTIME_SCORER` - 任意时间进球 Yes/No

**多向类型**:
- `FIRST_SCORER` - 首位进球者（N 个球员 + 无进球）

### 2. Outcome 编码方案

**O/U 市场（半球盘，如 0.5, 1.5, 2.5）**:
```
outcomeId 0: Over
outcomeId 1: Under
outcomeCount = 2
```

**O/U 市场（整球盘，如 1.0, 2.0）**:
```
outcomeId 0: Over
outcomeId 1: Push（走水，全额退款）
outcomeId 2: Under
outcomeCount = 3
```

**Yes/No 市场**:
```
outcomeId 0: Yes
outcomeId 1: No
outcomeCount = 2
```

**首位进球者市场**:
```
outcomeId 0 ~ (N-1): 各球员索引（按 playerIds 数组顺序）
outcomeId N: 无进球 (No Scorer)
outcomeCount = N + 1
```

### 3. 定价引擎选择

| 道具类型 | 定价引擎 | Outcome 数 | 原因 |
|---------|---------|-----------|------|
| O/U（半球盘） | SimpleCPMM | 2 | Gas 效率高 |
| O/U（整球盘） | SimpleCPMM | 3 | 支持 Push |
| Yes/No | SimpleCPMM | 2 | 标准二向市场 |
| FIRST_SCORER | LMSR | N+1 | 多结果无套利 |

---

## 🛠️ 基本用法

### 通过 Factory 创建市场

#### 示例 1: 哈兰德进球数 O/U 1.5（半球盘）

```solidity
// 准备定价引擎
SimpleCPMM simpleCPMM = new SimpleCPMM();

// 准备初始储备（Over: 50%, Under: 50%）
uint256[] memory initialReserves = new uint256[](2);
initialReserves[0] = 1000 * 1e18; // Over
initialReserves[1] = 1000 * 1e18; // Under

// 准备初始化数据
PlayerProps_Template.PlayerPropsInitData memory initData = PlayerProps_Template.PlayerPropsInitData({
    matchId: "EPL_2024_MUN_vs_MCI",
    playerId: "player_haaland",
    playerName: "Erling Haaland",
    propType: PlayerProps_Template.PropType.GOALS_OU,
    line: 1.5 * 1e18,  // 1.5 球（半球盘）
    kickoffTime: block.timestamp + 3 days,
    settlementToken: address(usdc),
    feeRecipient: feeRouter,
    feeRate: 200,  // 2%
    disputePeriod: 2 hours,
    uri: "https://api.pitchone.io/metadata/{id}",
    owner: owner,
    pricingEngineAddr: address(simpleCPMM),
    initialReserves: initialReserves,
    playerIds: new string[](0),  // 非 FIRST_SCORER 市场为空
    playerNames: new string[](0)
});

// 通过 Factory 创建市场
bytes memory encodedData = abi.encode(initData);
address marketAddr = marketFactory.createMarket(playerPropsTemplateId, encodedData);
PlayerProps_Template market = PlayerProps_Template(marketAddr);
```

#### 示例 2: 卡塞米罗黄牌 Yes/No

```solidity
// 准备初始储备（Yes: 30%, No: 70%）
uint256[] memory initialReserves = new uint256[](2);
initialReserves[0] = 300 * 1e18; // Yes
initialReserves[1] = 700 * 1e18; // No

PlayerProps_Template.PlayerPropsInitData memory initData = PlayerProps_Template.PlayerPropsInitData({
    matchId: "EPL_2024_MUN_vs_MCI",
    playerId: "player_casemiro",
    playerName: "Casemiro",
    propType: PlayerProps_Template.PropType.YELLOW_CARD,
    line: 0,  // Yes/No 市场 line 为 0
    kickoffTime: block.timestamp + 3 days,
    settlementToken: address(usdc),
    feeRecipient: feeRouter,
    feeRate: 200,
    disputePeriod: 2 hours,
    uri: "https://api.pitchone.io/metadata/{id}",
    owner: owner,
    pricingEngineAddr: address(simpleCPMM),
    initialReserves: initialReserves,
    playerIds: new string[](0),
    playerNames: new string[](0)
});

// 创建市场...
```

#### 示例 3: 首位进球者（LMSR 多向市场）

```solidity
// 准备 LMSR 引擎
LMSR lmsr = new LMSR(5000 * 1e18, 6); // liquidityB = 5000, 6 个结果

// 准备候选球员
string[] memory playerIds = new string[](5);
playerIds[0] = "player_haaland";
playerIds[1] = "player_foden";
playerIds[2] = "player_debruyne";
playerIds[3] = "player_rashford";
playerIds[4] = "player_fernandes";

string[] memory playerNames = new string[](5);
playerNames[0] = "Erling Haaland";
playerNames[1] = "Phil Foden";
playerNames[2] = "Kevin De Bruyne";
playerNames[3] = "Marcus Rashford";
playerNames[4] = "Bruno Fernandes";

// 准备初始份额（基于历史概率）
uint256[] memory initialQuantities = new uint256[](6);
initialQuantities[0] = 200 * 1e18;  // Haaland: 20%
initialQuantities[1] = 150 * 1e18;  // Foden: 15%
initialQuantities[2] = 120 * 1e18;  // De Bruyne: 12%
initialQuantities[3] = 130 * 1e18;  // Rashford: 13%
initialQuantities[4] = 100 * 1e18;  // Fernandes: 10%
initialQuantities[5] = 300 * 1e18;  // No Scorer: 30%

PlayerProps_Template.PlayerPropsInitData memory initData = PlayerProps_Template.PlayerPropsInitData({
    matchId: "EPL_2024_MUN_vs_MCI",
    playerId: "",  // FIRST_SCORER 市场此字段为空
    playerName: "First Goal Scorer",
    propType: PlayerProps_Template.PropType.FIRST_SCORER,
    line: 0,
    kickoffTime: block.timestamp + 3 days,
    settlementToken: address(usdc),
    feeRecipient: feeRouter,
    feeRate: 200,
    disputePeriod: 2 hours,
    uri: "https://api.pitchone.io/metadata/{id}",
    owner: owner,
    pricingEngineAddr: address(lmsr),
    initialReserves: initialQuantities,
    playerIds: playerIds,
    playerNames: playerNames
});

// 创建市场...
```

### 用户下注

```solidity
// 用户下注 100 USDC 在"哈兰德进球数 Over 1.5"
uint256 betAmount = 100 * 1e6; // USDC 6 decimals

// 授权
usdc.approve(address(market), betAmount);

// 下注 Over（outcomeId = 0）
uint256 shares = market.placeBet(0, betAmount);

// 用户获得 ERC-1155 头寸 Token
uint256 balance = market.balanceOf(msg.sender, 0);
```

### 查询价格

```solidity
// 查询单个结果价格
uint256 priceOver = market.getCurrentPrice(0); // Over
uint256 priceUnder = market.getCurrentPrice(1); // Under
console.log("Over: %d%%", priceOver / 100);
console.log("Under: %d%%", priceUnder / 100);

// 查询所有结果价格
uint256[] memory prices = market.getAllPrices();
for (uint256 i = 0; i < prices.length; i++) {
    console.log("Outcome %d: %d%%", i, prices[i] / 100);
}
```

### 锁盘与结算

```solidity
// 1. Keeper 在开赛前 5 分钟锁盘
market.lock();

// 2. 比赛结束，Keeper 调用 UMA OO 提交赛果（含球员数据）
IResultOracle.PlayerStats[] memory playerStats = new IResultOracle.PlayerStats[](2);

// 哈兰德数据
playerStats[0] = IResultOracle.PlayerStats({
    playerId: "player_haaland",
    goals: 2,        // 进 2 球
    assists: 1,
    shots: 5,
    shotsOnTarget: 3,
    yellowCard: false,
    redCard: false,
    isFirstScorer: true,
    minuteFirstGoal: 23
});

// 卡塞米罗数据
playerStats[1] = IResultOracle.PlayerStats({
    playerId: "player_casemiro",
    goals: 0,
    assists: 0,
    shots: 1,
    shotsOnTarget: 0,
    yellowCard: true,  // 吃黄牌
    redCard: false,
    isFirstScorer: false,
    minuteFirstGoal: 0
});

IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
    scope: bytes32("FT_90"),
    homeGoals: 3,
    awayGoals: 1,
    extraTime: false,
    penaltiesHome: 0,
    penaltiesAway: 0,
    reportedAt: block.timestamp,
    playerStats: playerStats  // 球员统计数据
});

umaAdapter.proposeResult(keccak256(abi.encodePacked(matchId)), facts);

// 3. 争议窗口结束，市场自动解决
// "哈兰德进球数 O/U 1.5" → Over 获胜（2 > 1.5）
// "卡塞米罗黄牌 Yes/No" → Yes 获胜

// 4. 用户兑付赢得的头寸
market.redeem(outcomeId, shares);
```

---

## 📐 参数配置指南

### line 的选择（O/U 市场）

| 盘口线 | 类型 | Outcome 数 | 适用场景 |
|--------|------|-----------|---------|
| 0.5, 1.5, 2.5 | 半球盘 | 2 | 明确 Over/Under，无平局 |
| 1.0, 2.0, 3.0 | 整球盘 | 3 | 支持 Push（走水退款） |

**推荐**:
- 进球数: 0.5（哈兰德）, 1.5（一般前锋）
- 助攻数: 0.5（中场）
- 射门次数: 2.5（前锋）, 1.5（中场）

### 初始储备/份额的设置

**方案 1: 均匀分布**（无历史数据）
```solidity
// 二向市场
initialReserves[0] = 1000 * 1e18; // 50%
initialReserves[1] = 1000 * 1e18; // 50%
```

**方案 2: 基于历史概率**（推荐）
```solidity
// 哈兰德进球数 O/U 0.5（历史数据：60% Over）
initialReserves[0] = 1200 * 1e18; // Over: 60%
initialReserves[1] = 800 * 1e18;  // Under: 40%

// 卡塞米罗黄牌（历史数据：35% Yes）
initialReserves[0] = 350 * 1e18; // Yes: 35%
initialReserves[1] = 650 * 1e18; // No: 65%
```

**方案 3: FIRST_SCORER 市场**（LMSR 份额）
```solidity
// 基于球员进球率
initialQuantities[0] = 250 * 1e18;  // 顶级前锋: 25%
initialQuantities[1] = 150 * 1e18;  // 二线前锋: 15%
initialQuantities[2] = 100 * 1e18;  // 中场: 10%
// ...
initialQuantities[N] = 300 * 1e18;  // 无进球: 30%
```

---

## 🔍 高级功能

### 球员数据结构

```solidity
struct PlayerStats {
    string playerId;        // 球员 ID（如 "player_haaland"）
    uint8 goals;            // 进球数
    uint8 assists;          // 助攻数
    uint8 shots;            // 射门次数
    uint8 shotsOnTarget;    // 射正次数
    bool yellowCard;        // 是否吃黄牌
    bool redCard;           // 是否吃红牌
    bool isFirstScorer;     // 是否首位进球者
    uint8 minuteFirstGoal;  // 首粒进球时间（分钟）
}
```

### 结算逻辑

**O/U 市场**:
```solidity
if (actualValue > line) return OUTCOME_OVER;
if (actualValue < line) return OUTCOME_UNDER;
if (actualValue == line) return OUTCOME_PUSH; // 仅整球盘
```

**Yes/No 市场**:
```solidity
// 黄牌
return stats.yellowCard ? OUTCOME_YES : OUTCOME_NO;

// 任意时间进球
return stats.goals > 0 ? OUTCOME_YES : OUTCOME_NO;
```

**首位进球者**:
```solidity
// 查找所有 isFirstScorer = true 的球员
// 如果多个球员同时进球，取 minuteFirstGoal 最小的
// 返回该球员在 playerIds 中的索引
// 如果无人进球，返回 playerIds.length（No Scorer）
```

### 辅助函数

```solidity
// 获取道具类型名称
string memory typeName = market._getPropTypeName(propType);
// 返回: "Goals O/U", "Yellow Card", "First Scorer" 等

// 获取结果名称
string memory outcomeName = market._getOutcomeName(outcomeId);
// 返回: "Over", "Yes", "Erling Haaland", "No Scorer" 等

// 检查盘口线类型
bool isWhole = market._isWholeNumberLine(line);
// 返回: true（整球盘）, false（半球盘）
```

---

## ⚠️ 注意事项

### 数值边界

- **line**: [0, 10 * 1e18]（O/U 市场，WAD 精度）
- **outcomeCount**: 2（二向），3（整球盘），N+1（FIRST_SCORER）
- **价格**: [1 bp, 9999 bp] (0.01% - 99.99%)

### Gas 消耗

| 操作 | Gas 消耗 (估算) |
|------|----------------|
| 创建市场（SimpleCPMM） | ~5,000,000 |
| 创建市场（LMSR） | ~10,000,000 |
| placeBet（SimpleCPMM） | ~200,000 |
| placeBet（LMSR） | ~300,000 |
| getCurrentPrice | ~50,000 - 100,000 |
| redeem | ~150,000 |

**优化建议**:
- FIRST_SCORER 市场：限制球员数 ≤ 20（Gas 考虑）
- 前端缓存价格查询结果
- 批量查询使用 `getAllPrices`

### 预言机数据要求

PlayerProps 市场**必须**提供球员统计数据：

```solidity
// ❌ 错误：空 playerStats 会导致错误结算
IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
    // ...
    playerStats: new IResultOracle.PlayerStats[](0) // 缺少数据
});

// ✅ 正确：提供完整球员数据
playerStats[0] = IResultOracle.PlayerStats({
    playerId: "player_haaland",
    goals: 2,
    // ... 其他字段
});
```

### 特殊情况处理

**1. 未找到球员数据**:
- `_findPlayerStats` 返回空统计（所有值为 0/false）
- 相当于球员未出场或无表现

**2. 多个球员同时进球**:
- FIRST_SCORER 市场取 `minuteFirstGoal` 最小的
- 如果时间相同，取 `playerStats` 数组中最先出现的

**3. 整球盘 Push**:
- `line = 1.0`, 实际进球 = 1 → Push（退款）
- 用户获得 `amount / getCurrentPrice(OUTCOME_PUSH)` 份额

---

## 🧪 测试覆盖

### 测试统计
- **总测试数**: 14 个
- **通过率**: 100%
- **覆盖场景**:
  - 初始化验证 (5 测试)
  - 下注功能 (3 测试)
  - 价格查询 (3 测试)
  - 辅助函数 (3 测试)

### 关键测试用例

```bash
# 运行所有测试
forge test --match-path test/unit/PlayerProps.t.sol

# 运行特定测试
forge test --match-test test_Initialize_GoalsOU_HalfLine -vv

# Gas 报告
forge test --match-path test/unit/PlayerProps.t.sol --gas-report
```

---

## 📚 集成示例

### 前端查询价格

```typescript
// TypeScript / ethers.js
import { ethers } from "ethers";

const market = new ethers.Contract(marketAddress, PlayerProps_ABI, provider);

// 查询哈兰德进球数 O/U 1.5 的价格
const priceOver = await market.getCurrentPrice(0);
const priceUnder = await market.getCurrentPrice(1);

console.log(`Over 1.5: ${priceOver.toNumber() / 100}%`);
console.log(`Under 1.5: ${priceUnder.toNumber() / 100}%`);

// 查询首位进球者市场所有价格
const prices = await market.getAllPrices();
const playerNames = await market.playerNames(0); // 假设有此 getter

for (let i = 0; i < prices.length - 1; i++) {
  const name = await market.playerNames(i);
  console.log(`${name}: ${prices[i].toNumber() / 100}%`);
}
console.log(`No Scorer: ${prices[prices.length - 1].toNumber() / 100}%`);
```

### 下注流程

```typescript
// 用户下注 100 USDC 在"哈兰德 Over 1.5"
const betAmount = ethers.utils.parseUnits("100", 6); // USDC 6 decimals

// 授权
const usdc = new ethers.Contract(usdcAddress, ERC20_ABI, signer);
await usdc.approve(market.address, betAmount);

// 下注 Over（outcomeId = 0）
const tx = await market.placeBet(0, betAmount);
const receipt = await tx.wait();

// 解析事件获取 shares
const event = receipt.events.find(e => e.event === "PlayerPropsBetPlaced");
const shares = event.args.shares;
console.log(`You received ${ethers.utils.formatUnits(shares, 18)} shares`);
```

### Keeper 结算流程

```typescript
// Keeper 脚本
const keeper = new ethers.Contract(keeperAddress, Keeper_ABI, signer);

// 1. 锁盘（开赛前 5 分钟）
if (Date.now() >= kickoffTime - 5 * 60 * 1000) {
  await market.lock();
}

// 2. 提交赛果（含球员数据）
if (matchFinished) {
  // 从数据源获取球员统计
  const haalandStats = await fetchPlayerStats("player_haaland");

  const playerStats = [{
    playerId: "player_haaland",
    goals: haalandStats.goals,
    assists: haalandStats.assists,
    shots: haalandStats.shots,
    shotsOnTarget: haalandStats.shotsOnTarget,
    yellowCard: haalandStats.yellowCard,
    redCard: haalandStats.redCard,
    isFirstScorer: haalandStats.isFirstScorer,
    minuteFirstGoal: haalandStats.minuteFirstGoal
  }];

  const facts = {
    scope: ethers.utils.formatBytes32String("FT_90"),
    homeGoals: matchResult.homeGoals,
    awayGoals: matchResult.awayGoals,
    extraTime: false,
    penaltiesHome: 0,
    penaltiesAway: 0,
    reportedAt: Date.now() / 1000,
    playerStats: playerStats
  };

  await umaAdapter.proposeResult(matchId, facts);
}
```

---

## 🔗 相关资源

### 内部文档
- [LMSR 使用文档](./LMSR_Usage.md)
- [ScoreTemplate 使用文档](./ScoreTemplate_Usage.md)
- [M3 开发计划](../../docs/M3_DEVELOPMENT_PLAN.md)
- [事件字典](../../docs/模块接口事件参数/EVENT_DICTIONARY.md)

### 参考合约
- `contracts/src/pricing/SimpleCPMM.sol` - CPMM 定价引擎
- `contracts/src/pricing/LMSR.sol` - LMSR 定价引擎
- `contracts/src/interfaces/IResultOracle.sol` - 预言机接口（含 PlayerStats）

---

## 🚀 下一步

1. ✅ PlayerProps_Template 核心实现完成（450 行代码，14 测试）
2. ✅ IResultOracle 扩展支持 PlayerStats
3. ✅ 完整结算逻辑（7 种道具类型）
4. ⏳ 数据源集成（Sportradar API 获取球员数据）
5. ⏳ 前端集成与 UI 开发

---

**作者**: Claude Code
**最后更新**: 2025-11-08
**版本**: v1.0
