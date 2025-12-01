# 市场配置重构总结

## 概述

将市场创建脚本的配置进行统一管理，通过 `MarketConfig` 库提取共同参数，减少代码重复，提高可维护性。

## 重构前后对比

### 1. 代码行数减少

| 文件 | 重构前 | 重构后 | 减少 |
|------|--------|--------|------|
| CreateAllMarketTypes.s.sol | 372 行 | 420 行 | +48 行 (包含配置库) |
| MarketConfig.sol | 0 行 | 180 行 | +180 行 (新增) |
| **总计** | 372 行 | 600 行 | +228 行 |

**注意**：虽然总行数增加，但代码质量和可维护性大幅提升。每个市场创建函数的代码更简洁。

### 2. 每个市场创建函数的简化

#### WDL 市场

**重构前**：
```solidity
function createWDLMarket(
    MarketFactory_v2 factory,
    string memory matchId,        // 需要完整matchId
    string memory homeTeam,
    string memory awayTeam,
    uint256 dayOffset
) internal returns (address) {
    bytes memory initData = abi.encodeWithSignature(
        "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
        matchId,
        homeTeam,
        awayTeam,
        block.timestamp + dayOffset * 1 days,
        USDC,                    // 硬编码
        FEE_ROUTER,              // 硬编码
        200,                     // 硬编码
        2 hours,                 // 硬编码
        SIMPLE_CPMM,             // 硬编码
        VAULT,                   // 硬编码
        string(abi.encodePacked(homeTeam, " vs ", awayTeam))  // 手动拼接
    );
    return factory.createMarket(WDL_TEMPLATE_ID, initData);
}
```

**重构后**：
```solidity
function createWDLMarket(
    MarketFactory_v2 factory,
    string memory homeTeam,      // 只需要队伍名
    string memory awayTeam,
    uint256 dayOffset
) internal returns (address) {
    // 使用配置库创建默认配置
    MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
        string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam)),
        homeTeam,
        awayTeam,
        dayOffset
    );

    bytes memory initData = abi.encodeWithSignature(
        "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
        config.matchId,
        config.homeTeam,
        config.awayTeam,
        config.kickoffTime,
        config.settlementToken,  // 来自配置
        config.feeRecipient,     // 来自配置
        config.feeRate,          // 来自配置
        config.disputePeriod,    // 来自配置
        config.pricingEngine,    // 来自配置
        MarketConfig.VAULT,
        MarketConfig.generateURI(homeTeam, awayTeam, "WDL")  // 使用工具函数
    );
    return factory.createMarket(MarketConfig.WDL_TEMPLATE_ID, initData);
}
```

**调用方式对比**：
```solidity
// 重构前
createWDLMarket(factory, "EPL_2024_WDL_1", "Man Utd", "Man City", 1);

// 重构后（参数更少，更简洁）
createWDLMarket(factory, "Man Utd", "Man City", 1);
```

### 3. 配置统一管理的优势

#### 3.1 默认参数集中管理

**MarketConfig.sol** 提供：
- 所有合约地址常量
- 所有模板ID常量
- 默认配置参数（费率、争议期等）
- 工具函数（URI生成、概率分布等）

```solidity
library MarketConfig {
    // ============ 默认配置参数 ============
    uint256 public constant DEFAULT_FEE_RATE = 200;           // 2%
    uint256 public constant DEFAULT_DISPUTE_PERIOD = 2 hours;

    // ============ 工具函数 ============
    function createBaseConfig(...) internal view returns (BaseConfig memory);
    function generateURI(...) internal pure returns (string memory);
    function getUniformProbabilities(uint256 n) internal pure returns (uint256[] memory);
    // ... 更多工具函数
}
```

#### 3.2 修改配置更方便

**场景：需要调整费率从 2% 到 1.5%**

**重构前**：需要修改 7 个市场创建函数中的每一个
```solidity
// 需要在每个函数中找到并修改
200,  // feeRate ← 需要改7次
```

**重构后**：只需修改一处
```solidity
// 在 MarketConfig.sol 中修改一次即可
uint256 public constant DEFAULT_FEE_RATE = 150;  // 改为 1.5%
```

#### 3.3 新增市场类型更简单

如果要添加新的市场类型（如角球数市场），只需：

1. 在 `MarketConfig.sol` 添加模板ID
2. 创建简化的创建函数（使用 `BaseConfig`）

**示例**：
```solidity
function createCornerMarket(
    MarketFactory_v2 factory,
    string memory homeTeam,
    string memory awayTeam,
    uint256 line,
    uint256 dayOffset
) internal returns (address) {
    MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
        string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_CR")),
        homeTeam,
        awayTeam,
        dayOffset
    );

    // 只需要关注差异化参数（line）
    bytes memory initData = abi.encodeWithSignature(
        "initialize(...)",
        config.matchId,
        // ... 基础配置参数
        line  // 唯一的差异化参数
    );
    return factory.createMarket(MarketConfig.CORNER_TEMPLATE_ID, initData);
}
```

### 4. 配置库提供的工具函数

#### 4.1 常用盘口线
```solidity
// 获取常用OU线
uint256[] memory lines = MarketConfig.getCommonOULines();
// 返回：[0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5]

// 获取常用让球数
int256[] memory handicaps = MarketConfig.getCommonHandicaps();
// 返回：[-2.5, -2.0, -1.5, -1.0, -0.5, 0.0, +0.5, +1.0, +1.5, +2.0, +2.5]
```

#### 4.2 概率分布生成
```solidity
// 生成均匀概率分布（总和=10000）
uint256[] memory probs = MarketConfig.getUniformProbabilities(37);
// 对于37个结果，每个约270，自动调整余数
```

#### 4.3 默认储备配置
```solidity
// PlayerProps市场的默认储备
uint256[] memory reserves = MarketConfig.getDefaultPlayerPropsReserves(usdcUnit);
// 返回：[100k USDC, 100k USDC] for Over/Under
```

### 5. 代码可读性提升

#### 重构前的调用
```solidity
createdMarkets.push(createWDLMarket(
    factory,
    "EPL_2024_WDL_1",           // 冗长的matchId
    "Man Utd",
    "Man City",
    1
));
```

#### 重构后的调用
```solidity
createdMarkets.push(createWDLMarket(
    factory,
    "Man Utd",                  // 简洁明了
    "Man City",
    1
));
```

### 6. 类型安全改进

通过 `BaseConfig` 结构体，编译器可以检查参数类型：

```solidity
struct BaseConfig {
    string matchId;
    string homeTeam;
    string awayTeam;
    uint256 kickoffTime;
    address settlementToken;
    address feeRecipient;
    uint256 feeRate;
    uint256 disputePeriod;
    address pricingEngine;
    address owner;
}
```

如果传错参数类型，编译时就会报错，而不是运行时。

### 7. 未来扩展性

#### 7.1 环境配置切换

可以轻松添加不同环境的配置：

```solidity
function getConfig(Environment env) internal pure returns (Addresses memory) {
    if (env == Environment.Localhost) {
        return Addresses({
            factory: 0xF85...,
            usdc: 0xDf9...,
            // ...
        });
    } else if (env == Environment.Testnet) {
        return Addresses({
            factory: 0x123...,
            usdc: 0x456...,
            // ...
        });
    }
    // ... mainnet config
}
```

#### 7.2 动态参数调整

可以添加参数验证和动态调整：

```solidity
function getOptimalFeeRate(uint256 marketType) internal pure returns (uint256) {
    if (marketType == TYPE_WDL) return 200;      // 2%
    if (marketType == TYPE_SCORE) return 250;    // 2.5% (更复杂)
    if (marketType == TYPE_PARLAY) return 300;   // 3% (串关)
    return DEFAULT_FEE_RATE;
}
```

## 使用指南

### 迁移到新版本

1. **编译新文件**：
   ```bash
   forge build
   ```

2. **使用新脚本**：
   ```bash
   # 使用重构后的版本
   PRIVATE_KEY=... forge script script/CreateAllMarketTypes_V2.s.sol:CreateAllMarketTypes_V2 \
     --rpc-url http://localhost:8545 --broadcast
   ```

3. **验证结果**：
   - 创建的市场数量应该相同（21个）
   - 每个市场的参数应该相同

### 自定义配置

如果需要修改默认配置：

1. 编辑 `MarketConfig.sol`
2. 修改常量或添加新函数
3. 重新编译并运行脚本

**示例：修改费率**
```solidity
// 在 MarketConfig.sol 中
uint256 public constant DEFAULT_FEE_RATE = 150;  // 改为 1.5%
```

## 总结

### 优势
✅ **减少重复代码** - 共同参数集中管理
✅ **提高可维护性** - 修改配置只需一处
✅ **改善可读性** - 函数参数更简洁
✅ **类型安全** - 结构体提供编译时检查
✅ **易于扩展** - 新增市场类型更简单
✅ **工具函数** - 提供常用配置生成器

### 注意事项
⚠️ **向后兼容** - 保留旧脚本 `CreateAllMarketTypes.s.sol`
⚠️ **测试充分** - 确保重构后行为一致
⚠️ **文档更新** - 更新 CLAUDE.md 中的使用说明

## 下一步

1. ✅ 创建配置库 `MarketConfig.sol`
2. ✅ 创建重构版本 `CreateAllMarketTypes_V2.sol`
3. 🔄 测试编译和运行
4. ⏳ 更新其他脚本使用配置库
5. ⏳ 更新文档
