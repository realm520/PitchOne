# LMSR 定价引擎使用文档

**版本**: v1.0
**日期**: 2025-11-08
**合约**: `contracts/src/pricing/LMSR.sol`
**测试**: `contracts/test/unit/LMSR.t.sol` (34 个测试，100% 通过)

---

## 📊 概述

**LMSR (Logarithmic Market Scoring Rule)** 是一种自动化做市算法，特别适用于**多结果市场**（>3 个结果）。

### 适用场景
- ✅ **精确比分市场**: 25-50 个可能结果（如 0-0, 1-0, 2-1, ...）
- ✅ **首位进球者市场**: 10-22 个球员选项
- ✅ **多选题市场**: 4-10 个选项
- ❌ **二/三向市场**: 使用 SimpleCPMM 更高效

### 核心优势
1. **无套利定价**: 价格总和始终为 100%
2. **流动性参数可调**: 通过 `b` 参数控制滑点
3. **数值稳定**: 使用 log-sum-exp 技巧避免溢出
4. **适合多结果**: 结果越多，LMSR 相比 CPMM 优势越明显

---

## 🎯 核心公式

### 1. 成本函数
```
C(q) = b * ln(Σ exp(q_i / b))
```
- `q_i`: 结果 i 的累计持仓量（所有用户购买的总份额）
- `b`: 流动性参数（越大流动性越好，滑点越小）

### 2. 价格函数（隐含概率）
```
p_i = exp(q_i / b) / Σ exp(q_j / b)
```
- 价格范围: [0.01%, 99.99%]
- 自动满足: Σ p_i = 100%

### 3. 买入成本
```
cost = C(q + Δq) - C(q)
```
- 用户支付 `cost`，获得 `Δq` 份额

---

## 🛠️ 基本用法

### 部署合约

```solidity
// 示例：精确比分市场（25 个结果）
uint256 liquidityB = 5000 * 1e18; // 流动性参数
uint256 outcomeCount = 25;        // 结果数量

LMSR lmsr = new LMSR(liquidityB, outcomeCount);
```

### 初始化持仓量

```solidity
// 方案 A: 均匀初始化（所有结果相同概率）
uint256[] memory initialQ = new uint256[](25);
for (uint256 i = 0; i < 25; i++) {
    initialQ[i] = 100 * 1e18; // 每个结果 100 份额
}
lmsr.initializeQuantities(initialQ);

// 方案 B: 根据历史数据初始化（不同概率）
uint256[] memory initialQ = new uint256[](25);
initialQ[0] = 50 * 1e18;  // 0-0: 5% 概率
initialQ[1] = 80 * 1e18;  // 1-0: 8% 概率
initialQ[2] = 120 * 1e18; // 1-1: 12% 概率
// ...
lmsr.initializeQuantities(initialQ);
```

### 查询价格

```solidity
// 查询单个结果的价格
uint256[] memory reserves = new uint256[](0); // LMSR 不使用此参数
uint256 price = lmsr.getPrice(outcomeId, reserves);
// price 单位: 基点 (0-10000, 即 0%-100%)

// 查询所有结果的价格
uint256[] memory prices = lmsr.getAllPrices();
for (uint256 i = 0; i < prices.length; i++) {
    console.log("Outcome %d: %d bps (%.2f%%)", i, prices[i], prices[i] / 100.0);
}
```

### 计算下注获得的份额

```solidity
// 用户下注 100 USDC 在结果 5 上
uint256 outcomeId = 5;
uint256 amount = 100 * 1e6; // USDC 6 decimals (已扣除手续费)
uint256[] memory reserves = new uint256[](0);

uint256 shares = lmsr.calculateShares(outcomeId, amount, reserves);
// shares: 用户获得的份额（WAD 精度 1e18）
```

### 更新持仓量（下注后）

```solidity
// 市场合约下注后调用（仅 owner 可调用）
lmsr.updateQuantity(outcomeId, shares);
```

---

## 📐 参数配置指南

### 流动性参数 `b` 的选择

| 市场类型 | 建议 `b` 值 | 说明 |
|---------|------------|------|
| 精确比分 (25 结果) | 5,000 - 10,000 | 平衡流动性和滑点 |
| 首位进球者 (22 结果) | 3,000 - 5,000 | 中等流动性 |
| 多选题 (5-10 结果) | 1,000 - 3,000 | 高流动性 |

**规则**:
- `b` 越大 → 滑点越小，流动性越好，但平台风险越高
- `b` 越小 → 滑点越大，用户体验下降，但平台风险越低

**示例计算**:
```python
# 假设用户下注 100 USDC，b = 5000，初始概率 5%
# 预期滑点: 约 0.5-1%
# 获得份额: 约 95-99 份额

# 如果 b = 1000（流动性较低）
# 预期滑点: 约 3-5%
# 获得份额: 约 80-90 份额
```

### 初始持仓量的设置

**方案 1: 均匀分布**（适用于缺乏历史数据）
```solidity
// 每个结果初始化为相同份额
// 初始价格: 100% / outcomeCount
uint256 baseQuantity = 100 * 1e18;
```

**方案 2: 历史概率分布**（推荐）
```solidity
// 根据历史数据设置初始概率
// 例如：足球精确比分历史统计
uint256[] memory initialQ = new uint256[](25);
initialQ[0] = 150 * 1e18;  // 0-0: 15% (平局常见)
initialQ[1] = 100 * 1e18;  // 1-0: 10%
initialQ[2] = 80 * 1e18;   // 0-1: 8%
initialQ[10] = 120 * 1e18; // 1-1: 12%
initialQ[21] = 90 * 1e18;  // 2-1: 9%
// 其他比分: 较低概率
```

**计算初始份额**:
```python
# 目标概率 p_i，流动性参数 b
# 初始份额 q_i = b * ln(p_i * C)
# 其中 C 是归一化常数

# 简化方案：q_i 正比于 p_i
q_i = baseQuantity * (p_i / p_avg)
```

---

## 🔍 高级功能

### 动态调整流动性参数

```solidity
// 仅 owner 可调用
uint256 newB = 7000 * 1e18;
lmsr.setLiquidityB(newB);

// 事件：LiquidityBUpdated(oldB, newB)
```

**使用场景**:
- 市场开盘初期：使用较小 `b`（降低风险）
- 流动性充足后：增加 `b`（提升用户体验）
- 临近锁盘：减少 `b`（减少大额下注冲击）

### 查询市场状态

```solidity
// 获取所有持仓量
uint256[] memory quantities = lmsr.getAllQuantities();

// 获取当前成本函数值
uint256 currentCost = lmsr.getCurrentCost();

// 查询特定结果的持仓
uint256 quantity = lmsr.quantityShares(outcomeId);
```

### 批量操作优化

```solidity
// Gas 优化：批量查询价格（单次调用）
uint256[] memory prices = lmsr.getAllPrices();

// 而不是：
// for (uint256 i = 0; i < count; i++) {
//     uint256 price = lmsr.getPrice(i, reserves); // 多次调用，Gas 高
// }
```

---

## ⚠️ 注意事项

### 数值边界
1. **最小价格**: 1 bp (0.01%)
2. **最大价格**: 9999 bp (99.99%)
3. **流动性参数**: [100, 1,000,000] (WAD 精度)
4. **结果数量**: [2, 100]

### Gas 消耗
| 操作 | Gas 消耗 (估算) |
|------|---------------|
| 部署合约 | ~900,000 |
| 初始化 (10 结果) | ~150,000 |
| 初始化 (25 结果) | ~350,000 |
| calculateShares | ~200,000 - 300,000 |
| getPrice | ~80,000 |
| getAllPrices (10 结果) | ~200,000 |
| getAllPrices (25 结果) | ~450,000 |
| updateQuantity | ~50,000 |

**优化建议**:
- 避免频繁调用 `getAllPrices`（在前端缓存）
- 批量操作时使用 `getAllPrices` 而非循环调用 `getPrice`
- 考虑使用链下计算 + 链上验证模式

### 数值稳定性
- 使用 **log-sum-exp 技巧**避免指数溢出
- 泰勒展开计算 `exp()` 和 `ln()`（10 项精度）
- 极端情况下（如 exp(100)）会触发边界保护

### 安全性
1. **权限控制**: 仅 owner 可调用 `updateQuantity` 和 `initializeQuantities`
2. **参数验证**: 所有输入都经过边界检查
3. **溢出保护**: 使用 Solidity 0.8+ 自动检查

---

## 🧪 测试覆盖

### 测试统计
- **总测试数**: 34 个
- **通过率**: 100%
- **覆盖场景**:
  - 构造函数验证 (5 测试)
  - 持仓量初始化 (3 测试)
  - 价格计算 (5 测试)
  - 份额计算 (4 测试)
  - 持仓更新 (5 测试)
  - 流动性参数调整 (4 测试)
  - 辅助函数 (4 测试)
  - 不变量测试 (2 测试)
  - 边界测试 (2 测试)

### 关键测试用例
```bash
# 运行所有测试
forge test --match-path test/unit/LMSR.t.sol

# 运行特定测试
forge test --match-test test_GetPrice_ThreeOutcomes_SumTo100Percent -vv

# 运行 Gas 报告
forge test --match-path test/unit/LMSR.t.sol --gas-report
```

---

## 📚 集成示例

### 与 MarketBase 集成

```solidity
// 在市场合约中使用 LMSR
contract ScoreMarket is MarketBase {
    LMSR public pricingEngine;

    function initialize(uint256 liquidityB, uint256 outcomeCount) external {
        pricingEngine = new LMSR(liquidityB, outcomeCount);

        // 初始化持仓量
        uint256[] memory initialQ = _getInitialQuantities(outcomeCount);
        pricingEngine.initializeQuantities(initialQ);
    }

    function placeBet(uint256 outcomeId, uint256 amount)
        external
        override
        returns (uint256 shares)
    {
        // 计算份额
        uint256[] memory reserves = new uint256[](0);
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        // 更新持仓
        pricingEngine.updateQuantity(outcomeId, shares);

        // 铸造 ERC-1155 头寸
        _mint(msg.sender, outcomeId, shares, "");

        emit BetPlaced(msg.sender, outcomeId, amount, shares, 0);
    }

    function getCurrentPrice(uint256 outcomeId)
        external
        view
        returns (uint256 price)
    {
        uint256[] memory reserves = new uint256[](0);
        return pricingEngine.getPrice(outcomeId, reserves);
    }
}
```

### 链下价格查询（前端）

```typescript
// TypeScript / ethers.js
import { ethers } from "ethers";

const lmsr = new ethers.Contract(lmsrAddress, LMSR_ABI, provider);

// 查询所有价格
const prices = await lmsr.getAllPrices();
console.log("Prices:", prices.map(p => p.toNumber() / 100 + "%"));

// 查询特定结果价格
const price = await lmsr.getPrice(outcomeId, []);
console.log(`Outcome ${outcomeId}: ${price.toNumber() / 100}%`);

// 模拟下注（链下计算份额）
const amount = ethers.utils.parseUnits("100", 6); // 100 USDC
const shares = await lmsr.calculateShares(outcomeId, amount, []);
console.log(`Shares: ${ethers.utils.formatUnits(shares, 18)}`);
```

---

## 🔗 相关资源

### 学术论文
- Hanson, R. (2003). "Combinatorial Information Market Design"
- Chen, Y., & Pennock, D. M. (2007). "A utility framework for bounded-loss market makers"

### 参考实现
- [Gnosis Conditional Tokens](https://github.com/gnosis/conditional-tokens-contracts)
- [Augur v2](https://github.com/AugurProject/augur-core)

### 内部文档
- [M3 开发计划](../../docs/M3_DEVELOPMENT_PLAN.md)
- [AMM 设计文档](../../docs/design/02_AMM_LinkedLines.md)
- [事件字典](../../docs/模块接口事件参数/EVENT_DICTIONARY.md)

---

## 🚀 下一步

1. ✅ LMSR 核心实现完成（500 行代码，34 测试）
2. 🔄 ScoreTemplate 集成（下一个任务）
3. ⏳ 生产环境优化（Gas 优化、审计）

---

**作者**: Claude Code
**最后更新**: 2025-11-08
**版本**: v1.0
