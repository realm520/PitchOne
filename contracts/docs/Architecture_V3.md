# PitchOne V3 架构文档

## 概述

PitchOne V3 采用分层架构设计，实现了清晰的职责分离，支持多种体育类型和玩法的灵活扩展。

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    Market_V3 (容器)                          │
│  职责：状态机管理 + 事件发布 + 组件编排                        │
│  状态：marketId, status, outcomeRules[], pricingState       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ IPricingStrategy │ │  IResultMapper   │ │   ERC1155        │
│    (定价层)       │ │    (映射层)      │ │   (头寸层)       │
│                  │ │                  │ │                  │
│ - CPMMStrategy   │ │ - WDL_Mapper     │ │ - 内置于 Market  │
│ - LMSRStrategy   │ │ - OU_Mapper      │ │                  │
│ - Parimutuel     │ │ - AH_Mapper      │ │                  │
│                  │ │ - Score_Mapper   │ │                  │
│                  │ │ - OddEven_Mapper │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

## 核心接口

### 1. IPricingStrategy - 定价策略接口

**职责**：计算下注份额、赔付金额、价格查询

**实现**：
- `CPMMStrategy` - 恒定乘积做市商（2-10 向市场）
- `LMSRStrategy` - 对数市场评分规则（多向市场，如精确比分）
- `ParimutuelStrategy` - 彩池模式（无需初始流动性）

**核心方法**：
```solidity
function calculateShares(uint256 outcomeId, uint256 amount, bytes memory state)
    external pure returns (uint256 shares, bytes memory newState);

function calculatePayout(uint256 outcomeId, uint256 shares, uint256[] memory totalSharesPerOutcome,
    uint256 totalLiquidity, PayoutType payoutType)
    external pure returns (uint256 payout);

function getPrice(uint256 outcomeId, bytes memory state)
    external pure returns (uint256 price);
```

### 2. IResultMapper - 赛果映射接口

**职责**：将原始赛果（如比分 2-1）映射到 outcome ID

**实现**：
- `WDL_Mapper` - 胜平负（3 outcomes）
- `OU_Mapper` - 大小球（2-3 outcomes，支持 Push）
- `AH_Mapper` - 让球（2-3 outcomes，支持半输半赢）
- `Score_Mapper` - 精确比分（37+ outcomes）
- `OddEven_Mapper` - 单双（2 outcomes）

**核心方法**：
```solidity
function mapResult(bytes calldata rawResult)
    external view returns (uint256[] memory outcomeIds, uint256[] memory weights);

function outcomeCount() external view returns (uint256);
```

### 3. IMarket_V3 - 市场容器接口

**职责**：状态机管理、组件编排、头寸管理

**状态机**：
```
Open → Locked → Resolved → Finalized
  │
  └────────→ Cancelled
```

**核心方法**：
```solidity
function placeBetFor(address user, uint256 outcomeId, uint256 amount, uint256 minShares)
    external returns (uint256 shares);

function resolve(bytes calldata rawResult) external;
function redeem(uint256 outcomeId, uint256 shares) external returns (uint256 payout);
function refund(uint256 outcomeId, uint256 shares) external returns (uint256 amount);
```

## 数据流

### 下注流程

```
用户 → BettingRouter.placeBet(market, outcomeId, amount)
    │
    ├─1. 验证市场合法性
    ├─2. 计算并路由费用
    ├─3. 转账净金额到 Market
    │
    └─→ Market.placeBetFor(user, outcomeId, netAmount)
        │
        ├─4. 调用 PricingStrategy.calculateShares()
        ├─5. 更新 pricingState
        ├─6. mint ERC1155 头寸
        └─7. 发出 BetPlaced 事件
```

### 结算流程

```
Oracle → Market.resolve(rawResult)
    │
    ├─1. 调用 ResultMapper.mapResult(rawResult)
    │       → (outcomeIds[], weights[])
    │
    ├─2. 存储 settlementResult
    └─3. 状态 → Resolved

Keeper → Market.finalize()
    │
    └─4. 状态 → Finalized
```

### 赎回流程

```
用户 → Market.redeem(outcomeId, shares)
    │
    ├─1. 验证 status == Finalized
    ├─2. 验证 outcomeId 是获胜 outcome
    ├─3. 调用 PricingStrategy.calculatePayout()
    ├─4. burn ERC1155 头寸
    └─5. 转账 payout 给用户
```

## 玩法配置示例

### WDL（胜平负）

```solidity
MarketConfig({
    outcomeRules: [
        { name: "主胜", payoutType: WINNER },
        { name: "平局", payoutType: WINNER },
        { name: "客胜", payoutType: WINNER }
    ],
    pricingStrategy: CPMMStrategy,
    resultMapper: WDL_Mapper
})

// WDL_Mapper.mapResult(abi.encode(3, 1))
// → outcomeIds: [0], weights: [10000]  (主胜)
```

### OU 2.5（大小球半球盘）

```solidity
MarketConfig({
    outcomeRules: [
        { name: "大球", payoutType: WINNER },
        { name: "小球", payoutType: WINNER }
    ],
    pricingStrategy: CPMMStrategy,
    resultMapper: OU_Mapper(line: 2.5)
})

// OU_Mapper.mapResult(abi.encode(2, 1))  // 总进球 3
// → outcomeIds: [0], weights: [10000]  (大球)
```

### AH -0.5（让球半球盘）

```solidity
MarketConfig({
    outcomeRules: [
        { name: "主队赢盘", payoutType: WINNER },
        { name: "客队赢盘", payoutType: WINNER }
    ],
    pricingStrategy: CPMMStrategy,
    resultMapper: AH_Mapper(line: -0.5)
})

// AH_Mapper.mapResult(abi.encode(2, 1))  // 主队净胜 1
// → outcomeIds: [0], weights: [10000]  (主队赢盘)
```

### AH -0.75（让球 3/4 盘，支持半输半赢）

```solidity
// AH_Mapper.mapResult(abi.encode(2, 1))  // 主队净胜 1
// → outcomeIds: [0, 1], weights: [5000, 5000]  (半赢)
```

### 精确比分

```solidity
MarketConfig({
    outcomeRules: [
        { name: "0-0", payoutType: WINNER },
        { name: "0-1", payoutType: WINNER },
        // ... 36 个比分
        { name: "Other", payoutType: WINNER }
    ],
    pricingStrategy: LMSRStrategy,
    resultMapper: Score_Mapper(maxGoals: 5)
})

// Score_Mapper.mapResult(abi.encode(2, 1))
// → outcomeIds: [21], weights: [10000]  (比分 2-1)
```

## 权限模型

```
DEFAULT_ADMIN_ROLE (多签钱包)
    │
    ├── OPERATOR_ROLE - 创建/取消市场
    ├── KEEPER_ROLE   - lock / finalize
    ├── ORACLE_ROLE   - resolve
    └── ROUTER_ROLE   - placeBetFor
```

## 已知限制

### 1. CPMM 三向市场精度问题

**现象**：在三向市场（如 WDL）中，CPMM 策略可能因精度问题导致某个储备归零。

**原因**：`PRECISION = 1e18` 与 USDC 的 `6 decimals` 交互时，`k` 的计算可能出现精度损失。

**影响**：下注后调用 `getPrice` 可能触发除零错误。

**解决方案**：
- 增加初始流动性（推荐 >= 1M USDC）
- 或使用二向市场（如 OU、OddEven）

### 2. LMSR 高流动性价格敏感度

**现象**：当 `b = liquidity / outcomeCount` 很大时，价格变化不明显。

**解决方案**：调整 `b` 参数或使用较低的初始流动性。

## 测试覆盖

| 模块 | 测试数量 | 覆盖率 |
|------|---------|--------|
| Mapper | 149 | ~98% |
| Strategy | 96 | ~95% |
| Market_V3 | 30 | ~90% |
| **总计** | **1012** | - |

## 文件结构

```
contracts/
├── src/
│   ├── core/
│   │   └── Market_V3.sol          # 市场容器
│   ├── interfaces/
│   │   ├── IPricingStrategy.sol   # 定价策略接口
│   │   ├── IResultMapper.sol      # 赛果映射接口
│   │   └── IMarket_V3.sol         # 市场接口
│   ├── pricing/
│   │   ├── CPMMStrategy.sol       # CPMM 定价
│   │   ├── LMSRStrategy.sol       # LMSR 定价
│   │   └── ParimutuelStrategy.sol # 彩池定价
│   └── mappers/
│       ├── WDL_Mapper.sol         # 胜平负
│       ├── OU_Mapper.sol          # 大小球
│       ├── AH_Mapper.sol          # 让球
│       ├── Score_Mapper.sol       # 精确比分
│       └── OddEven_Mapper.sol     # 单双
└── test/
    ├── core/
    │   └── Market_V3.t.sol
    ├── pricing/
    │   ├── CPMMStrategy.t.sol
    │   ├── LMSRStrategy.t.sol
    │   └── ParimutuelStrategy.t.sol
    └── mappers/
        ├── WDL_Mapper.t.sol
        ├── OU_Mapper.t.sol
        ├── AH_Mapper.t.sol
        ├── Score_Mapper.t.sol
        └── OddEven_Mapper.t.sol
```

## 扩展新玩法

只需实现 `IResultMapper` 接口：

```solidity
contract NewPlayType_Mapper is IResultMapper {
    function mapResult(bytes calldata rawResult)
        external view returns (uint256[] memory, uint256[] memory)
    {
        // 实现赛果到 outcome 的映射逻辑
    }

    function outcomeCount() external view returns (uint256) {
        // 返回 outcome 数量
    }

    function mapperType() external pure returns (string memory) {
        return "NEW_PLAY_TYPE";
    }
}
```

## 版本历史

- **V3.0** (2024-12) - 分层架构重构，支持可插拔的定价策略和赛果映射器
