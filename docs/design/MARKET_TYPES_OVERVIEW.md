# 市场类型全览

## 概述

PitchOne 平台支持 **7 种核心市场类型**，覆盖足球博彩的主流玩法，所有市场均已完成开发和测试。

## 市场类型对比

| 市场类型 | 模板合约 | 定价引擎 | 结果数 | Clone 支持 | 测试数 | 状态 |
|---------|---------|---------|-------|-----------|-------|------|
| 胜平负 (WDL) | WDL_Template_V2.sol | SimpleCPMM | 3 | ✅ | 51 | ✅ 完成 |
| 大小球单线 (OU) | OU_Template.sol | SimpleCPMM | 2-3 | ✅ | 47 | ✅ 完成 |
| 大小球多线 (OU_MultiLine) | OU_MultiLine.sol | SimpleCPMM + LinkedLinesController | 2N (N条线) | ✅ | 23 | ✅ 完成 |
| 让球 (AH) | AH_Template.sol | SimpleCPMM | 2-3 | ✅ | 28 | ✅ 完成 |
| 单双号 (OddEven) | OddEven_Template.sol | SimpleCPMM | 2 | ✅ | 34 | ✅ 完成 |
| 精确比分 (Score) | ScoreTemplate.sol | LMSR | 25-100 | ✅ | 34 | ✅ 完成 |
| 球员道具 (PlayerProps) | PlayerProps_Template.sol | SimpleCPMM / LMSR | 2-N | ✅ | 14 | ✅ 完成 |

**测试覆盖**: 231 个单元测试，100% 通过率

---

## 1. 胜平负市场 (Win-Draw-Lose, WDL)

### 基本信息
- **模板合约**: `WDL_Template_V2.sol`
- **定价引擎**: SimpleCPMM
- **结果数**: 3 个（主队赢、平局、客队赢）

### Outcome ID 编码
```
0: 主队赢 (Home Win)
1: 平局 (Draw)
2: 客队赢 (Away Win)
```

### 使用场景
```solidity
// 创建市场示例
factory.createMarket(wdlTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
    "EPL_2025_MUN_vs_LIV",      // matchId
    "Manchester United",         // homeTeam
    "Liverpool",                 // awayTeam
    block.timestamp + 3 days,    // kickoffTime
    usdc,                        // settlementToken
    feeRouter,                   // feeRecipient
    200,                         // feeRate (2%)
    2 hours,                     // disputePeriod
    cpmm,                        // pricingEngine
    vault,                       // vault
    "https://api.pitchone.io/metadata/wdl/EPL_2025_MUN_vs_LIV" // uri
));
```

### 结算逻辑
- 主队得分 > 客队得分 → Outcome 0 赢
- 主队得分 = 客队得分 → Outcome 1 赢
- 主队得分 < 客队得分 → Outcome 2 赢

---

## 2. 大小球单线市场 (Over/Under, OU)

### 基本信息
- **模板合约**: `OU_Template.sol`
- **定价引擎**: SimpleCPMM
- **结果数**: 2 个（半球盘）或 3 个（整球盘）

### Outcome ID 编码

#### 半球盘（如 2.5 球）
```
0: Over (总进球 > 2.5)
1: Under (总进球 < 2.5)
```

#### 整球盘（如 2.0 球）
```
0: Over (总进球 > 2.0)
1: Push (总进球 = 2.0，退款）
2: Under (总进球 < 2.0)
```

### 使用场景
```solidity
// 创建 2.5 球盘口市场
factory.createMarket(ouTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,uint256,address,address,uint256,uint256,address,string,address)",
    "EPL_OU_CHE_vs_NEW",         // matchId
    "Chelsea",                   // homeTeam
    "Newcastle",                 // awayTeam
    block.timestamp + 3 days,    // kickoffTime
    2500,                        // line (2.5 球，千分位)
    usdc,                        // settlementToken
    feeRouter,                   // feeRecipient
    200,                         // feeRate (2%)
    2 hours,                     // disputePeriod
    cpmm,                        // pricingEngine
    "https://api.pitchone.io/metadata/ou/EPL_OU_CHE_vs_NEW", // uri
    msg.sender                   // owner
));
```

### 结算逻辑
- 半球盘：总进球 > 线 → Over 赢，否则 Under 赢
- 整球盘：总进球 > 线 → Over 赢，= 线 → Push 退款，< 线 → Under 赢

---

## 3. 大小球多线市场 (OU Multi-Line)

### 基本信息
- **模板合约**: `OU_MultiLine.sol`
- **定价引擎**: SimpleCPMM + LinkedLinesController（联动定价）
- **结果数**: 2N 个（N 条线 × 2 方向）
- **限制**: 仅支持半球盘（避免 Push 退款复杂性）

### Outcome ID 编码
```
outcomeId = lineIndex * 2 + direction
direction: 0 = OVER, 1 = UNDER

示例（3条线：2.5、3.5、4.5）：
0: 2.5球 OVER
1: 2.5球 UNDER
2: 3.5球 OVER
3: 3.5球 UNDER
4: 4.5球 OVER
5: 4.5球 UNDER
```

### 核心特性
- **联动定价**: 相邻线的赔率自动联动，防止套利
- **流动性共享**: 所有线共享同一流动性池
- **储备量调整**: 根据投注分布动态调整各线储备

### 使用场景
```solidity
// 创建 3 条线的多线市场
uint256[] memory lines = new uint256[](3);
lines[0] = 2500; // 2.5 球
lines[1] = 3500; // 3.5 球
lines[2] = 4500; // 4.5 球

factory.createMarket(ouMultiLineTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,uint256[],address,address,uint256,uint256,address,address,string,address)",
    "EPL_ML_MUN_vs_LIV",         // matchId
    "Manchester United",          // homeTeam
    "Liverpool",                  // awayTeam
    block.timestamp + 3 days,     // kickoffTime
    lines,                        // 多条盘口线
    usdc,                         // settlementToken
    feeRouter,                    // feeRecipient
    200,                          // feeRate
    2 hours,                      // disputePeriod
    cpmm,                         // pricingEngine
    linkedLinesController,        // linkedLinesController
    "https://api.pitchone.io/metadata/ou-ml/EPL_ML_MUN_vs_LIV", // uri
    msg.sender                    // owner
));
```

---

## 4. 让球市场 (Asian Handicap, AH)

### 基本信息
- **模板合约**: `AH_Template.sol`
- **定价引擎**: SimpleCPMM
- **结果数**: 2 个（半球盘）或 3 个（整球盘）

### Outcome ID 编码

#### 半球盘（如 -0.5、-1.5）
```
0: 主队赢盘 (Home Covers)
1: 客队赢盘 (Away Covers)
```

#### 整球盘（如 -1.0、-2.0）
```
0: 主队赢盘 (Home Covers)
1: Push (平盘，退款)
2: 客队赢盘 (Away Covers)
```

### 结算逻辑

#### 主队让球（handicap < 0）
- 半球盘（-0.5）：调整后主队得分 > 客队 → Outcome 0 赢
- 整球盘（-1.0）：调整后主队得分 > 客队 → Outcome 0 赢，= → Push，< → Outcome 2 赢

#### 客队让球（handicap > 0）
- 逻辑相反

### 使用场景
```solidity
// 创建主队让 1.5 球市场
factory.createMarket(ahTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,int256,uint8,address,address,uint256,uint256,address,string,address)",
    "EPL_AH_LIV_vs_BUR",         // matchId
    "Liverpool",                 // homeTeam
    "Burnley",                   // awayTeam
    block.timestamp + 3 days,    // kickoffTime
    -1500,                       // handicap (-1.5 球，千分位)
    0,                           // handicapType (0=HALF, 1=WHOLE)
    usdc,                        // settlementToken
    feeRouter,                   // feeRecipient
    200,                         // feeRate
    2 hours,                     // disputePeriod
    cpmm,                        // pricingEngine
    "https://api.pitchone.io/metadata/ah/EPL_AH_LIV_vs_BUR", // uri
    msg.sender                   // owner
));
```

---

## 5. 单双号市场 (Odd/Even)

### 基本信息
- **模板合约**: `OddEven_Template.sol`
- **定价引擎**: SimpleCPMM
- **结果数**: 2 个

### Outcome ID 编码
```
0: 奇数 (Odd，总进球为 1/3/5/7...)
1: 偶数 (Even，总进球为 0/2/4/6...)
```

### 使用场景
```solidity
// 创建单双号市场
factory.createMarket(oddEvenTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,address,address,uint256,uint256,address,string,address)",
    "EPL_OE_LEI_vs_FUL",         // matchId
    "Leicester",                 // homeTeam
    "Fulham",                    // awayTeam
    block.timestamp + 3 days,    // kickoffTime
    usdc,                        // settlementToken
    feeRouter,                   // feeRecipient
    200,                         // feeRate
    2 hours,                     // disputePeriod
    cpmm,                        // pricingEngine
    "https://api.pitchone.io/metadata/oddeven/EPL_OE_LEI_vs_FUL", // uri
    msg.sender                   // owner
));
```

### 结算逻辑
- 总进球数 % 2 == 1 → Outcome 0（奇数）赢
- 总进球数 % 2 == 0 → Outcome 1（偶数）赢

---

## 6. 精确比分市场 (Exact Score)

### 基本信息
- **模板合约**: `ScoreTemplate.sol`
- **定价引擎**: LMSR（Logarithmic Market Scoring Rule）
- **结果数**: 25-100 个（可配置）

### Outcome ID 编码
```
标准比分: outcomeId = homeGoals * 10 + awayGoals
示例:
  0: 0-0 平局
  10: 1-0 主队小胜
  21: 2-1 主队胜
  32: 3-2 主队胜

特殊结果:
  999: Other (其他比分，超出配置范围)
```

### 配置参数
- **scoreRange**: 比分范围（默认 5，表示 0-0 到 5-5，共 36 个结果）
- **liquidityB**: LMSR 流动性参数（影响价格敏感度）

### 使用场景
```solidity
// 创建 0-0 到 5-5 的精确比分市场
factory.createMarket(scoreTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint256,uint8,address,address,uint256,uint256,address,uint256,string,address)",
    "EPL_SCORE_MUN_vs_LIV",      // matchId
    "Manchester United",          // homeTeam
    "Liverpool",                  // awayTeam
    block.timestamp + 3 days,     // kickoffTime
    5,                            // scoreRange (0-5)
    usdc,                         // settlementToken
    feeRouter,                    // feeRecipient
    200,                          // feeRate
    2 hours,                      // disputePeriod
    lmsr,                         // pricingEngine (LMSR)
    10000 * 1e6,                  // liquidityB (流动性参数)
    "https://api.pitchone.io/metadata/score/EPL_SCORE_MUN_vs_LIV", // uri
    msg.sender                    // owner
));
```

### 结算逻辑
- 实际比分在范围内 → 对应 outcomeId 赢
- 实际比分超出范围 → outcomeId 999（Other）赢

---

## 7. 球员道具市场 (Player Props)

### 基本信息
- **模板合约**: `PlayerProps_Template.sol`
- **定价引擎**: SimpleCPMM（O/U、Y/N 类型）或 LMSR（首位进球者）
- **结果数**: 2-N 个（取决于道具类型）

### 支持的道具类型
```solidity
enum PropType {
    GOALS_OU,        // 进球数大小 (2-3 个结果)
    ASSISTS_OU,      // 助攻数大小 (2-3 个结果)
    SHOTS_OU,        // 射门次数大小 (2-3 个结果)
    YELLOW_CARD,     // 黄牌 Yes/No (2 个结果)
    RED_CARD,        // 红牌 Yes/No (2 个结果)
    ANYTIME_SCORER,  // 任意时间进球 Yes/No (2 个结果)
    FIRST_SCORER     // 首位进球者 (N+1 个结果: N 个球员 + 无进球)
}
```

### Outcome ID 编码

#### O/U 类型（半球盘）
```
0: Over (数据 > 线)
1: Under (数据 < 线)
```

#### O/U 类型（整球盘）
```
0: Over (数据 > 线)
1: Push (数据 = 线，退款)
2: Under (数据 < 线)
```

#### Yes/No 类型
```
0: Yes (发生)
1: No (未发生)
```

#### 首位进球者类型
```
0 ~ (playerCount-1): 各球员索引
playerCount: 无进球 (No Scorer)
```

### 使用场景

#### 示例 1: 哈兰德进球数 O/U 1.5
```solidity
factory.createMarket(playerPropsTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint8,uint256,address,address,uint256,uint256,address,uint256,string,address)",
    "EPL_PP_HAALAND_GOALS",      // matchId
    "Erling Haaland",            // playerName
    "Manchester City vs Arsenal", // matchInfo
    0,                            // propType (GOALS_OU)
    1500,                         // line (1.5 球，千分位)
    usdc,                         // settlementToken
    feeRouter,                    // feeRecipient
    200,                          // feeRate
    2 hours,                      // disputePeriod
    cpmm,                         // pricingEngine (SimpleCPMM)
    0,                            // liquidityB (不用于 CPMM)
    "https://api.pitchone.io/metadata/pp/EPL_PP_HAALAND_GOALS", // uri
    msg.sender                    // owner
));
```

#### 示例 2: 卡塞米罗黄牌 Yes/No
```solidity
factory.createMarket(playerPropsTemplateId, abi.encodeWithSignature(
    "initialize(string,string,string,uint8,uint256,address,address,uint256,uint256,address,uint256,string,address)",
    "EPL_PP_CASEMIRO_YELLOW",    // matchId
    "Casemiro",                  // playerName
    "Manchester United vs Liverpool", // matchInfo
    3,                            // propType (YELLOW_CARD)
    0,                            // line (不适用)
    usdc,                         // settlementToken
    feeRouter,                    // feeRecipient
    200,                          // feeRate
    2 hours,                      // disputePeriod
    cpmm,                         // pricingEngine
    0,                            // liquidityB
    "https://api.pitchone.io/metadata/pp/EPL_PP_CASEMIRO_YELLOW", // uri
    msg.sender                    // owner
));
```

---

## 定价引擎对比

### SimpleCPMM (Constant Product Market Maker)
- **适用场景**: 2-3 个结果的市场
- **优点**: 简单高效，Gas 消耗低
- **缺点**: 不支持多结果市场（>3 个）
- **使用市场**: WDL、OU、AH、OddEven、PlayerProps（O/U、Y/N 类型）

### LMSR (Logarithmic Market Scoring Rule)
- **适用场景**: 3-100 个结果的市场
- **优点**: 支持多结果，价格发现更准确
- **缺点**: Gas 消耗较高，需配置流动性参数 b
- **使用市场**: ScoreTemplate、PlayerProps（首位进球者）

### LinkedLinesController
- **适用场景**: 多线市场的联动定价
- **优点**: 防止套利，自动调整储备量
- **缺点**: 需额外部署和配置
- **使用市场**: OU_MultiLine

---

## Clone 模式部署

所有 7 种市场模板均支持 **Clone 模式**（EIP-1167 最小代理），通过 `Factory.createMarket()` 部署：

### 优势
- 节省 **~95% 部署 Gas**
- 统一管理和注册
- 自动发出 `MarketCreated` 事件供 Subgraph 索引

### 使用流程
1. 部署模板实现合约（一次性）
2. 在 Factory 注册模板
3. 通过 `factory.createMarket(templateId, initData)` 创建市场
4. Factory 自动执行 Clone + initialize

---

## 测试覆盖

| 市场类型 | 单元测试 | 集成测试 | 覆盖率 |
|---------|---------|---------|--------|
| WDL | 51 | 多个 | 100% |
| OU | 47 | 多个 | 97.96% |
| OU_MultiLine | 23 | 1 | 83.62% |
| AH | 28 | 多个 | 100% |
| OddEven | 34 | 多个 | 100% |
| ScoreTemplate | 34 | 1 | 高覆盖 |
| PlayerProps | 14 | 0 | 高覆盖 |

**总计**: 231+ 单元测试，100% 通过率

---

## 下一步：创建测试市场

使用 `CreateMarkets.s.sol` 脚本批量创建测试市场：

```bash
# 使用默认配置（创建 21 个市场）
PRIVATE_KEY=0x... forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 --broadcast

# 自定义数量
NUM_WDL_MARKETS=3 NUM_OU_MARKETS=3 NUM_AH_MARKETS=2 \
PRIVATE_KEY=0x... forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 --broadcast
```

详见: `contracts/script/CreateMarkets.s.sol`

---

## 参考文档

- **LinkedLinesController 使用指南**: `contracts/docs/LinkedLinesController_Usage.md`
- **LMSR Gas 优化**: `contracts/docs/LMSR_GAS_OPTIMIZATION.md`
- **PlayerProps 使用指南**: `contracts/docs/PlayerProps_Usage.md`
- **ScoreTemplate 使用指南**: `contracts/docs/ScoreTemplate_Usage.md`
- **事件字典**: `docs/模块接口事件参数/EVENT_DICTIONARY.md`

---

**最后更新**: 2025-11-09
**版本**: v1.0.0
