# 市场配置统一化 - 使用指南

## 概述

我们创建了 `MarketConfig.sol` 库来统一管理所有市场的配置参数，大幅简化市场创建代码，提高可维护性。

## 文件说明

- **MarketConfig.sol** - 统一配置库（180行）
- **CreateAllMarketTypes_V2.sol** - 重构后的市场创建脚本（420行）
- **TestMarketConfig.s.sol** - 配置库测试脚本
- **REFACTORING_SUMMARY.md** - 详细的重构说明文档

## 快速开始

### 1. 测试配置库功能

```bash
cd contracts/
forge script script/TestMarketConfig.s.sol:TestMarketConfig
```

**输出示例**：
```
========================================
  Testing MarketConfig Library
========================================

Test 1: Creating Base Config
  Match ID: TEST_MATCH_001
  Home Team: Man Utd
  ...

All Tests Passed! [OK]
========================================
```

### 2. 使用新配置创建市场

```bash
# 使用重构后的脚本创建所有市场类型
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes_V2.s.sol:CreateAllMarketTypes_V2 \
  --rpc-url http://localhost:8545 \
  --broadcast
```

## 核心优势

### ✅ 1. 参数集中管理

**所有默认配置在一处定义**：

```solidity
library MarketConfig {
    // 合约地址
    address public constant FACTORY = 0xF85...;
    address public constant USDC = 0xDf9...;
    address public constant VAULT = 0x67b...;

    // 默认参数
    uint256 public constant DEFAULT_FEE_RATE = 200;        // 2%
    uint256 public constant DEFAULT_DISPUTE_PERIOD = 2 hours;
}
```

**修改配置只需一处**：
- 需要调整费率？只改 `DEFAULT_FEE_RATE`
- 需要更换合约？只改对应的地址常量

### ✅ 2. 代码大幅简化

**创建WDL市场对比**：

```solidity
// 重构前（需要传入完整matchId和所有参数）
createWDLMarket(factory, "EPL_2024_WDL_1", "Man Utd", "Man City", 1);

// 重构后（只需要核心参数）
createWDLMarket(factory, "Man Utd", "Man City", 1);
```

**函数内部对比**：

```solidity
// 重构前：硬编码所有参数
bytes memory initData = abi.encodeWithSignature(
    "initialize(...)",
    matchId,
    homeTeam,
    awayTeam,
    block.timestamp + dayOffset * 1 days,  // 手动计算
    USDC,                                   // 硬编码
    FEE_ROUTER,                             // 硬编码
    200,                                    // 硬编码
    2 hours,                                // 硬编码
    ...
);

// 重构后：使用配置库
MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
    string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam)),
    homeTeam,
    awayTeam,
    dayOffset
);

bytes memory initData = abi.encodeWithSignature(
    "initialize(...)",
    config.matchId,
    config.homeTeam,
    config.awayTeam,
    config.kickoffTime,      // 自动计算
    config.settlementToken,  // 来自配置
    config.feeRecipient,     // 来自配置
    config.feeRate,          // 来自配置
    config.disputePeriod,    // 来自配置
    ...
);
```

### ✅ 3. 提供实用工具函数

#### URI 生成
```solidity
string memory uri = MarketConfig.generateURI("Man Utd", "Man City", "WDL");
// 输出: "Man Utd vs Man City WDL"
```

#### 常用盘口线
```solidity
uint256[] memory lines = MarketConfig.getCommonOULines();
// 返回: [500, 1500, 2500, 3500, 4500, 5500, 6500] (0.5 - 6.5)
```

#### 均匀概率分布
```solidity
uint256[] memory probs = MarketConfig.getUniformProbabilities(37);
// 生成37个结果的均匀概率（总和=10000）
```

#### 默认储备配置
```solidity
uint256[] memory reserves = MarketConfig.getDefaultPlayerPropsReserves(usdcUnit);
// 返回: [100k USDC, 100k USDC]
```

## 使用场景

### 场景1：创建单个市场

```solidity
import "./MarketConfig.sol";

function createMyWDLMarket() public {
    MarketFactory_v2 factory = MarketFactory_v2(MarketConfig.FACTORY);

    // 使用默认配置
    MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
        "MY_MATCH_001",
        "Team A",
        "Team B",
        3  // 3 days from now
    );

    // 编码并创建
    bytes memory initData = abi.encodeWithSignature(..., config);
    address market = factory.createMarket(MarketConfig.WDL_TEMPLATE_ID, initData);
}
```

### 场景2：修改默认费率

**需求**：将费率从 2% 改为 1.5%

**操作**：
1. 编辑 `MarketConfig.sol`
2. 修改 `DEFAULT_FEE_RATE = 150`
3. 重新编译 `forge build`
4. 运行脚本创建市场

**影响**：所有使用该配置的市场都会自动使用新费率

### 场景3：添加新市场类型

假设要添加"角球数"市场：

```solidity
// 1. 在 MarketConfig.sol 添加模板ID
bytes32 public constant CORNER_TEMPLATE_ID = 0x...;

// 2. 创建市场创建函数
function createCornerMarket(
    MarketFactory_v2 factory,
    string memory homeTeam,
    string memory awayTeam,
    uint256 line,
    uint256 dayOffset
) internal returns (address) {
    // 使用基础配置
    MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
        string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_CORNER")),
        homeTeam,
        awayTeam,
        dayOffset
    );

    // 只需关注差异化参数（line）
    bytes memory initData = abi.encodeWithSignature(
        "initialize(string,string,string,uint256,uint256,address,address,uint256,uint256,address,string,address)",
        config.matchId,
        config.homeTeam,
        config.awayTeam,
        config.kickoffTime,
        line,  // 唯一的差异参数
        config.settlementToken,
        config.feeRecipient,
        config.feeRate,
        config.disputePeriod,
        config.pricingEngine,
        MarketConfig.generateURI(homeTeam, awayTeam, "Corner"),
        config.owner
    );
    return factory.createMarket(MarketConfig.CORNER_TEMPLATE_ID, initData);
}
```

### 场景4：多环境配置

可以扩展 `MarketConfig` 支持多环境：

```solidity
enum Environment { Localhost, Testnet, Mainnet }

function getFactory(Environment env) internal pure returns (address) {
    if (env == Environment.Localhost) return 0xF85...;
    if (env == Environment.Testnet) return 0x123...;
    if (env == Environment.Mainnet) return 0x456...;
}

// 使用
address factory = MarketConfig.getFactory(Environment.Testnet);
```

## 配置项说明

### 合约地址常量

| 常量 | 说明 | 当前值 |
|------|------|--------|
| `FACTORY` | 市场工厂合约 | `0xF85895D0...` |
| `USDC` | 结算代币 | `0xDf951d20...` |
| `VAULT` | 流动性金库 | `0x67baFF31...` |
| `FEE_ROUTER` | 费用路由 | `0x2b639Cc8...` |
| `SIMPLE_CPMM` | 定价引擎 | `0x6533158b...` |
| `OWNER` | 合约所有者 | `0xf39Fd6e5...` |

### 模板ID常量

| 常量 | 说明 |
|------|------|
| `WDL_TEMPLATE_ID` | 胜平负模板 |
| `OU_TEMPLATE_ID` | 大小球单线模板 |
| `OU_MULTILINE_TEMPLATE_ID` | 大小球多线模板 |
| `AH_TEMPLATE_ID` | 让球模板 |
| `ODDEVEN_TEMPLATE_ID` | 单双模板 |
| `SCORE_TEMPLATE_ID` | 精确比分模板 |
| `PLAYERPROPS_TEMPLATE_ID` | 球员道具模板 |

### 默认参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `DEFAULT_FEE_RATE` | 费用率（基点） | `200` (2%) |
| `DEFAULT_DISPUTE_PERIOD` | 争议期 | `2 hours` |

## 工具函数列表

### createBaseConfig
创建基础配置结构体
```solidity
function createBaseConfig(
    string memory matchId,
    string memory homeTeam,
    string memory awayTeam,
    uint256 daysOffset
) internal view returns (BaseConfig memory)
```

### generateURI
生成市场URI
```solidity
function generateURI(
    string memory homeTeam,
    string memory awayTeam,
    string memory suffix
) internal pure returns (string memory)
```

### getCommonOULines
获取常用OU盘口线（7条：0.5 - 6.5）
```solidity
function getCommonOULines() internal pure returns (uint256[] memory)
```

### getCommonHandicaps
获取常用让球数（11个：-2.5 到 +2.5）
```solidity
function getCommonHandicaps() internal pure returns (int256[] memory)
```

### getUniformProbabilities
生成均匀概率分布（总和=10000）
```solidity
function getUniformProbabilities(uint256 numOutcomes) internal pure returns (uint256[] memory)
```

### getDefaultPlayerPropsReserves
获取PlayerProps默认储备
```solidity
function getDefaultPlayerPropsReserves(uint256 usdcUnit) internal pure returns (uint256[] memory)
```

### getDefaultLMSRLiquidity
获取LMSR默认流动性参数
```solidity
function getDefaultLMSRLiquidity() internal pure returns (uint256)
```

## 最佳实践

### ✅ DO

1. **使用配置库创建市场**
   ```solidity
   MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(...);
   ```

2. **使用工具函数生成URI**
   ```solidity
   string memory uri = MarketConfig.generateURI(homeTeam, awayTeam, "WDL");
   ```

3. **修改配置时更新MarketConfig.sol**
   ```solidity
   uint256 public constant DEFAULT_FEE_RATE = 150;  // 统一修改
   ```

### ❌ DON'T

1. **不要硬编码配置值**
   ```solidity
   // ❌ 不要这样
   uint256 feeRate = 200;

   // ✅ 应该这样
   uint256 feeRate = MarketConfig.DEFAULT_FEE_RATE;
   ```

2. **不要重复拼接URI**
   ```solidity
   // ❌ 不要这样
   string memory uri = string(abi.encodePacked(homeTeam, " vs ", awayTeam));

   // ✅ 应该这样
   string memory uri = MarketConfig.generateURI(homeTeam, awayTeam, "WDL");
   ```

3. **不要跳过BaseConfig**
   ```solidity
   // ❌ 不要这样（除非有特殊需求）
   bytes memory initData = abi.encodeWithSignature(
       "initialize(...)",
       matchId,
       homeTeam,
       // ... 手动填所有参数
   );

   // ✅ 应该这样
   MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(...);
   bytes memory initData = abi.encodeWithSignature(
       "initialize(...)",
       config.matchId,
       config.homeTeam,
       // ... 使用配置项
   );
   ```

## 测试验证

运行完整测试：
```bash
# 1. 测试配置库
forge script script/TestMarketConfig.s.sol:TestMarketConfig

# 2. 编译新脚本
forge build

# 3. 在本地链上测试创建市场（需要先启动 Anvil）
anvil --host 0.0.0.0 &
PRIVATE_KEY=0xac09... forge script script/CreateAllMarketTypes_V2.s.sol:CreateAllMarketTypes_V2 \
  --rpc-url http://localhost:8545 --broadcast
```

## 常见问题

### Q1: 如何修改默认费率？
**A**: 编辑 `MarketConfig.sol` 中的 `DEFAULT_FEE_RATE` 常量，然后重新编译。

### Q2: 如何添加新环境的配置？
**A**: 可以在 `MarketConfig.sol` 中添加环境枚举和对应的getter函数，参考"场景4"。

### Q3: BaseConfig包含哪些字段？
**A**: matchId, homeTeam, awayTeam, kickoffTime, settlementToken, feeRecipient, feeRate, disputePeriod, pricingEngine, owner。

### Q4: 旧脚本还能用吗？
**A**: 可以！我们保留了 `CreateAllMarketTypes.s.sol` 向后兼容，但建议迁移到 `_V2` 版本。

### Q5: 如何为特定市场使用不同的费率？
**A**: 可以创建BaseConfig后手动覆盖：
```solidity
MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(...);
config.feeRate = 300;  // 覆盖为3%
```

## 总结

通过 `MarketConfig` 库，我们实现了：

✅ **配置集中管理** - 一处修改，全局生效
✅ **代码大幅简化** - 减少重复，提高可读性
✅ **易于扩展** - 新增市场类型更简单
✅ **类型安全** - 结构体提供编译时检查
✅ **工具丰富** - 提供常用配置生成器

**下一步建议**：
1. 将其他脚本迁移到使用 `MarketConfig`
2. 根据实际需求扩展工具函数
3. 添加多环境支持（测试网、主网）
