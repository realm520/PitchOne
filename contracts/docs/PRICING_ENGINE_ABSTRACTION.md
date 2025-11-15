# 定价引擎完全抽象化设计文档

## 🎯 目标

将定价逻辑完全抽象到 IPricingEngine 接口，让所有市场模板通过传入不同的定价引擎合约地址来切换定价策略，实现：
- ✅ 策略模式（Strategy Pattern）
- ✅ 依赖注入（Dependency Injection）
- ✅ 开闭原则（Open-Closed Principle）

## 📐 重构后的架构

### 1. IPricingEngine 接口（已更新）

```solidity
interface IPricingEngine {
    // 计算份额
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) external view returns (uint256 shares);

    // 更新储备（核心新增）
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external pure returns (uint256[] memory newReserves);

    // 计算价格
    function getPrice(uint256 outcomeId, uint256[] memory reserves)
        external view returns (uint256 price);

    // 获取初始储备（核心新增）
    function getInitialReserves(uint256 outcomeCount)
        external view returns (uint256[] memory initialReserves);
}
```

**关键设计**：
- `updateReserves()` - 定价引擎自己负责储备更新逻辑
- `getInitialReserves()` - 定价引擎自己返回初始储备配置
- 市场模板完全不需要知道内部逻辑

### 2. ParimutuelPricing 实现

```solidity
contract ParimutuelPricing is IPricingEngine {
    // 1:1 份额兑换
    function calculateShares(...) external pure returns (uint256) {
        return amount;
    }

    // Parimutuel 储备更新：累加到目标结果
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external pure returns (uint256[] memory newReserves) {
        newReserves = reserves;
        newReserves[outcomeId] += amount;  // 累加实际投注
        return newReserves;
    }

    // 价格 = 实际投注分布
    function getPrice(...) external pure returns (uint256) {
        uint256 totalBets = sum(reserves);
        if (totalBets == 0) return 10000 / reserves.length;
        return (reserves[outcomeId] * 10000) / totalBets;
    }

    // 初始储备为 0
    function getInitialReserves(uint256 outcomeCount)
        external pure returns (uint256[] memory)
    {
        return new uint256[](outcomeCount);  // [0, 0] 或 [0, 0, 0]
    }
}
```

### 3. SimpleCPMM 实现

```solidity
contract SimpleCPMM is IPricingEngine {
    uint256 public defaultReservePerSide;  // 可配置

    constructor(uint256 _defaultReserve) {
        defaultReservePerSide = _defaultReserve;  // 如 100_000
    }

    // CPMM 份额计算
    function calculateShares(...) external view returns (uint256) {
        // k = r0 * r1
        // shares = r_target - (k / (r_other + amount))
        // ...
    }

    // CPMM 储备更新：目标减少，对手增加
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external pure returns (uint256[] memory newReserves) {
        newReserves = reserves;

        // 二向市场
        if (reserves.length == 2) {
            uint256 opponentId = 1 - outcomeId;
            newReserves[outcomeId] -= shares;
            newReserves[opponentId] += amount;
        }
        // 三向市场
        else if (reserves.length == 3) {
            newReserves[outcomeId] -= shares;
            // 对手盘储备平均分配
            for (uint256 i = 0; i < 3; i++) {
                if (i != outcomeId) {
                    newReserves[i] += amount / 2;
                }
            }
        }

        return newReserves;
    }

    // CPMM 价格计算
    function getPrice(...) external pure returns (uint256) {
        // price_i = r_other / (r_target + r_other)
        // ...
    }

    // 初始储备 = 默认值
    function getInitialReserves(uint256 outcomeCount)
        external view returns (uint256[] memory)
    {
        uint256[] memory reserves = new uint256[](outcomeCount);
        for (uint256 i = 0; i < outcomeCount; i++) {
            reserves[i] = defaultReservePerSide;
        }
        return reserves;
    }
}
```

### 4. 市场模板简化（以 OddEven_Template_V2 为例）

**重构前**（硬编码逻辑）：
```solidity
function _calculateShares(uint256 outcomeId, uint256 netAmount)
    internal override returns (uint256 shares)
{
    shares = pricingEngine.calculateShares(outcomeId, netAmount, virtualReserves);

    // ❌ 硬编码两种模式的逻辑
    if (virtualReserveInit == 0) {
        virtualReserves[outcomeId] += netAmount;  // Parimutuel
    } else {
        virtualReserves[outcomeId] -= shares;  // CPMM
        virtualReserves[opponentId] += netAmount;
    }

    return shares;
}
```

**重构后**（完全抽象）：
```solidity
function _calculateShares(uint256 outcomeId, uint256 netAmount)
    internal override returns (uint256 shares)
{
    // 1. 计算份额
    shares = pricingEngine.calculateShares(outcomeId, netAmount, virtualReserves);

    // 2. 更新储备（由定价引擎决定逻辑）
    virtualReserves = pricingEngine.updateReserves(
        outcomeId,
        netAmount,
        shares,
        virtualReserves
    );

    // ✅ 完全不需要知道内部逻辑！
    emit VirtualReservesUpdated(virtualReserves);
    return shares;
}
```

**初始化简化**：
```solidity
function initialize(
    // ... 其他参数
    address _pricingEngine,
    string memory _uri
) external initializer {
    // ... 其他初始化

    pricingEngine = IPricingEngine(_pricingEngine);

    // 从定价引擎获取初始储备
    virtualReserves = pricingEngine.getInitialReserves(OUTCOME_COUNT);

    // ✅ 完全不需要硬编码初始值！
}
```

**移除的代码**：
- ❌ `_virtualReservePerSide` 参数
- ❌ `virtualReserveInit` 状态变量
- ❌ `if (virtualReserveInit == 0)` 条件判断
- ❌ `defaultBorrowAmount` 计算逻辑

## 🔄 完整的使用流程

### 创建 Parimutuel 市场

```solidity
// 1. 部署定价引擎
ParimutuelPricing parimutuel = new ParimutuelPricing();

// 2. 创建市场，传入定价引擎地址
OddEven_Template_V2 market = new OddEven_Template_V2();
market.initialize(
    "MATCH_ID",
    "Team A",
    "Team B",
    block.timestamp + 1 days,
    address(usdc),
    feeRecipient,
    200,
    2 hours,
    address(parimutuel),  // ← 传入 Parimutuel 引擎
    address(vault),
    ""
);

// 市场自动使用 [0, 0] 初始储备（由引擎返回）
```

### 创建 SimpleCPMM 市场

```solidity
// 1. 部署定价引擎（配置默认储备）
SimpleCPMM cpmm = new SimpleCPMM(100_000 * 10**6);  // 100k USDC

// 2. 创建市场，传入定价引擎地址
market.initialize(
    // ... 其他参数相同
    address(cpmm),  // ← 传入 CPMM 引擎
    address(vault),
    ""
);

// 市场自动使用 [100k, 100k] 初始储备（由引擎返回）
```

### 创建自定义定价市场

```solidity
// 1. 实现自定义定价引擎
contract CustomPricing is IPricingEngine {
    function calculateShares(...) {...}
    function updateReserves(...) {...}
    function getPrice(...) {...}
    function getInitialReserves(...) {...}
}

// 2. 部署并使用
CustomPricing custom = new CustomPricing();
market.initialize(/* ... */, address(custom), address(vault), "");

// ✅ 无需修改市场模板代码！
```

## 📊 架构对比

| 特性 | 重构前 | 重构后 |
|------|--------|--------|
| **定价逻辑位置** | 部分在引擎，部分在模板 | 完全在引擎 |
| **模板复杂度** | 需要 if/else 判断模式 | 简单调用接口 |
| **扩展性** | 需要修改模板代码 | 部署新引擎即可 |
| **初始储备** | 硬编码在模板 | 引擎返回 |
| **储备更新** | 模板决定逻辑 | 引擎决定逻辑 |
| **可维护性** | 模板与引擎耦合 | 完全解耦 |
| **代码行数** | ~50 行逻辑 | ~10 行调用 |

## 🚀 实施步骤

### 步骤 1：更新 IPricingEngine 接口 ✅
已完成，添加了 `updateReserves()` 和 `getInitialReserves()` 方法。

### 步骤 2：更新 ParimutuelPricing
```solidity
// 添加 updateReserves() 实现
function updateReserves(...) external pure returns (uint256[] memory) {
    uint256[] memory newReserves = new uint256[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
        newReserves[i] = reserves[i];
    }
    newReserves[outcomeId] += amount;
    return newReserves;
}

// 添加 getInitialReserves() 实现
function getInitialReserves(uint256 outcomeCount)
    external pure returns (uint256[] memory)
{
    return new uint256[](outcomeCount);  // 零储备
}
```

### 步骤 3：更新 SimpleCPMM
```solidity
// 添加可配置的默认储备
uint256 public immutable defaultReservePerSide;

constructor(uint256 _defaultReserve) {
    defaultReservePerSide = _defaultReserve;
}

// 添加 updateReserves() 实现（CPMM 逻辑）
// 添加 getInitialReserves() 实现
```

### 步骤 4：简化 OddEven_Template_V2
移除硬编码逻辑，改为调用接口：
```solidity
// 初始化
virtualReserves = pricingEngine.getInitialReserves(OUTCOME_COUNT);

// 计算份额
virtualReserves = pricingEngine.updateReserves(...);
```

### 步骤 5：更新其他模板
使用相同的模式更新：
- WDL_Template_V2
- OU_Template
- AH_Template
- 等等...

### 步骤 6：更新 LMSR
LMSR 需要额外的配置参数（流动性参数 b），可以通过构造函数传入：
```solidity
contract LMSR is IPricingEngine {
    uint256 public immutable liquidityParameter;

    constructor(uint256 _b) {
        liquidityParameter = _b;
    }

    function getInitialReserves(uint256 outcomeCount)
        external view returns (uint256[] memory)
    {
        // 根据 b 参数计算初始储备
        uint256[] memory reserves = new uint256[](outcomeCount);
        for (uint256 i = 0; i < outcomeCount; i++) {
            reserves[i] = liquidityParameter;
        }
        return reserves;
    }

    // ... 其他方法
}
```

## ✅ 优势总结

1. **完全解耦**：市场模板不需要知道定价逻辑
2. **易于扩展**：添加新定价策略只需实现接口
3. **配置灵活**：通过构造函数传入参数
4. **代码简洁**：模板代码从 ~50 行减少到 ~10 行
5. **符合原则**：策略模式 + 开闭原则 + 依赖注入

## 📝 待办任务

- [ ] 更新 ParimutuelPricing 实现新方法
- [ ] 更新 SimpleCPMM 实现新方法
- [ ] 简化 OddEven_Template_V2
- [ ] 更新其他 SimpleCPMM 模板（WDL, OU, AH）
- [ ] 更新 LMSR 实现新方法
- [ ] 更新使用 LMSR 的模板（Score, PlayerProps）
- [ ] 添加单元测试验证所有定价引擎
- [ ] 更新部署脚本
- [ ] 更新文档

## 🎯 最终效果

**创建市场时只需要改变定价引擎地址**：
```solidity
// Parimutuel 市场
market.initialize(/* ... */, address(parimutuelPricing), /* ... */);

// CPMM 市场（小储备 = 高滑点）
SimpleCPMM cpmmSmall = new SimpleCPMM(1_000 * 10**6);
market.initialize(/* ... */, address(cpmmSmall), /* ... */);

// CPMM 市场（大储备 = 低滑点）
SimpleCPMM cpmmLarge = new SimpleCPMM(1_000_000 * 10**6);
market.initialize(/* ... */, address(cpmmLarge), /* ... */);

// LMSR 市场
LMSR lmsr = new LMSR(50_000 * 10**6);  // b = 50k
market.initialize(/* ... */, address(lmsr), /* ... */);
```

**所有市场模板使用统一的简洁代码**，完全不需要关心定价逻辑内部实现！
