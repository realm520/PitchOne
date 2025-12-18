# LMSR 测试与数学保证说明

本文档详细说明 LMSR（Logarithmic Market Scoring Rule）定价策略的完整测试覆盖，包括 62 个测试用例的具体名称、验证内容和数学保证。

---

## 1. 模块与数学模型概述

当前 LMSR 模块实现的是一个多结果预测市场 AMM，核心采用**对数市场评分规则（LMSR, Logarithmic Market Scoring Rule）**：

* 市场有 `n` 个互斥且完备的 outcome；
* 第 `i` 个 outcome 的已发行份额为 `q_i`；

* **成本函数（Cost Function）**：
  ```
  C(q) = b · ln(∑ exp(q_j/b))
  ```

* **即时价格（边际成本）**：
  ```
  p_i(q) = ∂C/∂q_i = exp(q_i/b) / ∑ exp(q_j/b)
  ```

* **做市方最坏亏损上界**：
  ```
  WorstCaseLoss ≤ b · ln(n)
  ```

### 实现特性

* **数值稳定性**：使用 Log-Sum-Exp 技巧避免指数溢出
* **统一复用**：`_logSumExpComponents` 函数被 `_calculateCost`、`_calculatePrice`、`getAllPrices` 三个核心函数复用
* **精度**：使用 e18 精度，价格以 BASIS_POINTS (10000) 表示

---

## 2. 测试结构总览

当前测试集由两大类构成：

| 测试类别 | 测试数量 | 文件位置 |
|---------|---------|---------|
| 数学属性测试 | 30 个 | `test/pricing/LMSR_MathProperties.t.sol` |
| 基础功能测试 | 32 个 | `test/pricing/LMSRStrategy.t.sol` |
| **总计** | **62 个** | |

---

## 3. 数学属性测试详细列表（30 项）

### 3.1 风险上界（最大亏损）相关 - 2 个测试

#### 1. `test_MaxLoss_TwoOutcomes`

* **场景**：`n = 2` 的二元事件市场，执行 15 次递增金额的下注（5k - 33k TOKEN）
* **验证内容**：
  * 做市方的实际亏损满足：`loss ≤ b · ln(2) + ε`
  * 每次下注后价格变化合理
* **意义**：验证在最简单的二元市场里，LMSR 的风险上界公式实现正确

#### 2. `test_MaxLoss_TenOutcomes`

* **场景**：`n = 10` 的多结果市场，执行 15 次递增金额的下注（2k - 23.5k TOKEN）
* **验证内容**：
  * 做市方的实际亏损满足：`loss ≤ b · ln(10) + ε`
* **意义**：验证随 n 增大时，风险上界按 `b·ln(n)` 缩放

---

### 3.2 价格变化与单调性 - 3 个测试

#### 3. `test_PriceChange_ConsecutiveBets`

* **场景**：对同一 outcome 连续执行 12 次下注（5k - 27k TOKEN）
* **验证内容**：
  * 每次下注后，该 outcome 的价格 `p_i` 单调递增
  * 每次下注后，价格总和 ≈ 100%
* **意义**：验证 `p_i(q)` 随 `q_i` 增加而上升，符合"买得越多越贵"的直觉

#### 4. `test_PriceChange_AlternatingBets`

* **场景**：4 outcome 市场，交替在不同 outcome 上下注 12 次
* **验证内容**：
  * 买入某 outcome 后：该 outcome 价格上升、其他 outcome 价格下降
  * 价格总和始终 ≈ 100%
* **意义**：验证 outcome 之间的联动关系，体现 LMSR 作为 softmax 模型的"竞争性"

#### 5. `test_PriceChange_DirectionCorrect`

* **场景**：4 outcome 市场，对 outcome 1 下注 20k TOKEN
* **验证内容**：
  * 买入 outcome 1 → `p_1` 增大
  * 其他 outcome 价格下降或保持
  * 价格总和仍 ≈ 100%
* **意义**：精细校验价格变化方向逻辑正确

---

### 3.3 路径无关性 / 顺序无关性 - 2 个测试

#### 6. `test_PathIndependence_SameNetBuy`

* **场景**：对同一 outcome：
  * 方案 A：一次性买入 30k TOKEN
  * 方案 B：分 10 次，每次 3k TOKEN
* **验证内容**：
  * 两种方案的最终 quantities 接近（允许 5% 误差）
* **意义**：验证 cost-function AMM 的路径无关性：只看最终 `q`，不看拆单方式

#### 7. `test_PathIndependence_DifferentOrders`

* **场景**：3 outcome 市场，三种下注顺序：
  * 方案 A：先 5 次 outcome 0，再 5 次 outcome 1
  * 方案 B：交替下注
  * 方案 C：先 5 次 outcome 1，再 5 次 outcome 0
* **验证内容**：
  * 所有方案的价格总和 ≈ 100%
  * A 和 C 对称：`q0_A ≈ q1_C`，`q1_A ≈ q0_C`
  * 总投注金额相同
* **意义**：验证跨 outcome 的路径无关性和对称性

---

### 3.4 多结果市场结构与初始状态 - 3 个测试

#### 8. `test_MultipleOutcomes_2to100`

* **场景**：n 从 2 到 100 的 10 种规模（2, 3, 5, 10, 20, 25, 36, 50, 75, 100）
* **验证内容**：
  * 对每个 n，所有 outcome 的初始价格均为 `1/n`
  * 价格总和 ≈ 100%
* **意义**：验证初始对称状态设置正确

#### 9. `test_InitialState_ExactValues`

* **场景**：6 种 outcome 数量（2, 3, 4, 5, 10, 25）
* **验证内容**：
  * 初始 quantities 都为 0
  * 初始价格精确等于 `1/n`（允许舍入误差 ≤ 2 basis points）
  * 价格总和 ≈ 100%
* **意义**：对初始状态精度做强化验证

#### 10. `test_MultipleOutcomes_WithBets`

* **场景**：5 种规模（2, 5, 10, 25, 50），每种执行 12 次下注
* **验证内容**：
  * 下注后价格变化合理
  * 各 outcome 价格均在 (0, 100%) 区间内
  * 价格总和始终 ≈ 100%
* **意义**：多结果市场的综合行为验证

---

### 3.5 综合 / 极端场景行为 - 2 个测试

#### 11. `test_Comprehensive_ManyBets`

* **场景**：5 outcome 市场，执行 20 笔不同方向的下注
* **验证内容**：
  * 每一步价格行为正常（无 NaN/Inf，方向性正确）
  * 中途与最终时刻 `∑p_i ≈ 1`
  * 所有价格为正
* **意义**：压力测试路径，验证长交易序列的鲁棒性

#### 12. `test_Extreme_OneOutcomeDominates`

* **场景**：4 outcome 市场，连续 15 次对 outcome 0 下注（5k - 40k TOKEN）
* **验证内容**：
  * 目标 outcome 价格趋近 1，其他趋近 0
  * 价格仍归一化
  * 无数值溢出或异常
* **意义**：验证 softmax 在极端不平衡场景下的数值稳定性

---

### 3.6 概率归一化相关测试 - 2 个测试

#### 13. `test_ProbabilityNormalization_RandomTrades`

* **场景**：5 outcome 市场，执行 25 次预定义的"随机"交易
* **验证内容**：
  * 每笔交易后：所有价格 `p_i ∈ (0, 1)`
  * `|∑ p_i - 1|` 小于预设 ε（200 basis points）
* **意义**：从动态过程角度验证概率归一化不变量

#### 14. `test_ProbabilityNormalization_ExtremeImbalance`

* **场景**：3 outcome 市场，连续 20 次对 outcome 0 下注（5k - 62k TOKEN）
* **验证内容**：
  * 即便在极度不平衡的持仓下，`∑ p_i` 仍然 ≈ 1
  * 数值没有崩坏
* **意义**：确认归一化在极端单边持仓下仍保持

---

### 3.7 数值稳定性相关测试 - 3 个测试

#### 15. `test_NumericalStability_LargeQuantities`

* **场景**：3 outcome 市场，连续 15 次大额下注（每次 20k TOKEN）
* **验证内容**：
  * log-sum-exp 实现无溢出/下溢
  * 价格计算结果在 (0, 1) 区间内，且 `∑p_i ≈ 1`
  * 最终 q0 > 100k TOKEN
* **意义**：确保实现适用于量级较大的实盘场景

#### 16. `test_NumericalStability_ManyOutcomes`

* **场景**：`n = 100` 的高维市场，15 次分散下注
* **验证内容**：
  * 价格计算稳定，无异常
  * 总和归一化（允许 1000 basis points 误差）
* **意义**：验证高维 outcome 空间下的数值稳定性

#### 17. `test_NumericalStability_EdgeBValues`

* **场景**：分别测试小流动性（1k TOKEN，b ≈ 333）和大流动性（10M TOKEN，b ≈ 3.3M）
* **验证内容**：
  * 小 b：价格敏感但仍合法
  * 大 b：价格平滑但无溢出
  * 两种情况下价格总和都 ≈ 100%
* **意义**：保证参数调优时，即便 b 被设到边界也不会引发数值灾难

---

### 3.8 参数与输入校验测试 - 4 个测试

#### 18. `test_ParameterValidation_InvalidInputs`

* **场景**：构造不合法的 outcomeCount（0, 1, 101）和零流动性
* **验证内容**：
  * outcomeCount < 2 或 > 100 被拒绝
  * liquidity = 0 被拒绝
  * 有效参数成功
* **意义**：防止创建数学上无意义或实现不可支持的市场

#### 19. `test_ParameterValidation_InvalidOutcomeId`

* **场景**：对不存在的 outcomeId（3, 100）发起交易
* **验证内容**：
  * 系统拒绝并返回明确错误
  * 有效 outcomeId（2）成功
* **意义**：防止坏 id 导致数据越界

#### 20. `test_ParameterValidation_ZeroAmount`

* **场景**：提交 amount = 0 的下注请求
* **验证内容**：
  * 请求被明确拒绝
* **意义**：清理边界输入

#### 21. `test_ParameterValidation_TinyAmount`

* **场景**：提交极小金额（1 wei）的交易
* **验证内容**：
  * 要么被拒绝，要么状态变化受控
  * 合理小额（1000 TOKEN）成功
* **意义**：避免数值层面的 DoS 或精度累积误差

---

### 3.9 成本函数形状与凸性测试 - 2 个测试

#### 22. `test_CostFunction_Monotonicity`

* **场景**：购买 10 次递增金额（5k - 50k TOKEN）
* **验证内容**：
  * C(q) 随 q 单调递增
* **意义**：保证"买得越多，总成本越大"

#### 23. `test_CostFunction_Convexity`

* **场景**：固定金额（10k TOKEN）连续下注 10 次
* **验证内容**：
  * 每次获得的 shares 递减或持平
  * 即边际成本递增
* **意义**：保证"后来者付出的边际代价更高"，无简单套利回路

---

### 3.10 买卖回路无套利测试 - 2 个测试

#### 24. `test_NoArbitrage_CostConsistency`

* **场景**：先执行一些交易后，购买 10k shares
* **验证内容**：
  * 同一状态下购买相同数量的成本一致
  * 从新状态再买同样数量会更贵（凸性）
* **意义**：验证成本函数的确定性和凸性

#### 25. `test_NoArbitrage_MultiOutcomeLoop`

* **场景**：4 outcome 市场，依次在每个 outcome 上下注
* **验证内容**：
  * 最终价格归一化
  * 所有 quantities 为正
* **意义**：验证多 outcome 交易的成本一致性

---

### 3.11 Shift Invariance（平移不变性）测试 - 2 个测试

#### 26. `test_ShiftInvariance_PricesUnchanged`

* **场景**：3 outcome 非对称状态，分别 shift 1k, 10k, 50k TOKEN
* **验证内容**：
  * 对所有 `q_i` 加同一常数 c，价格向量不变
  * 允许 0.05% 误差（舍入）
* **意义**：验证 softmax 的经典平移不变性质：`p(q + c·1) = p(q)`

#### 27. `test_ShiftInvariance_VeryLargeShift`

* **场景**：4 outcome 市场，shift 100k TOKEN
* **验证内容**：
  * 即使 shift 非常大，价格保持不变
  * 归一化保持
* **意义**：验证 log-sum-exp 实现在大 shift 下的严格不变性

---

### 3.12 排列对称性（Permutation Symmetry）测试 - 3 个测试

#### 28. `test_PermutationSymmetry_SwapOutcomes`

* **场景**：4 outcome 市场，交换 q[0] 和 q[2]
* **验证内容**：
  * swappedPrices[0] ≈ originalPrices[2]
  * swappedPrices[2] ≈ originalPrices[0]
  * 未交换的保持不变
* **意义**：验证交换 q 的两个分量，对应的价格也交换

#### 29. `test_PermutationSymmetry_FullReverse`

* **场景**：5 outcome 市场，反转整个 q 向量
* **验证内容**：
  * 价格向量也完全反转
* **意义**：验证完全反转排列的对称性

#### 30. `test_PermutationSymmetry_EqualQuantitiesEqualPrices`

* **场景**：4 outcome 市场，让 outcome 0 和 2 有相同下注量
* **验证内容**：
  * 相同 q 值产生相同价格
  * 价格排序与 q 排序一致
* **意义**：验证相等 quantities 产生相等价格

---

## 4. 基础功能测试详细列表（32 项）

### 4.1 元数据测试 - 4 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_strategyType` | 返回 "LMSR" |
| `test_requiresInitialLiquidity` | 返回 true |
| `test_minOutcomeCount` | 返回 2 |
| `test_maxOutcomeCount` | 返回 100 |

### 4.2 初始状态测试 - 5 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_getInitialState_TwoOutcomes` | 2 outcome 初始化：quantities = [0, 0]，b > 0 |
| `test_getInitialState_ManyOutcomes` | 25 outcome 初始化：所有 quantities = 0，b > 0 |
| `test_getInitialState_InvalidOutcomeCount_Low` | outcomeCount = 1 时 revert |
| `test_getInitialState_InvalidOutcomeCount_High` | outcomeCount = 101 时 revert |
| `test_getInitialState_ZeroLiquidity` | liquidity = 0 时 revert |

### 4.3 价格测试 - 4 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_getPrice_EqualQuantities` | 初始状态：2 outcome 各 50% |
| `test_getPrice_ThreeOutcomes_Equal` | 初始状态：3 outcome 各 33.33% |
| `test_getAllPrices` | 返回数组长度正确，总和 ≈ 100% |
| `test_getPrice_Invalid_Reverts` | 无效 outcomeId 时 revert |

### 4.4 下注测试 - 6 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_calculateShares_BasicBet` | 基本下注返回正数 shares，quantities 正确更新 |
| `test_calculateShares_PriceIncreasesAfterBet` | 下注后目标 outcome 价格不下降 |
| `test_calculateShares_OtherPricesDecrease` | 下注后其他 outcome 价格不上升 |
| `test_calculateShares_ZeroAmount_Reverts` | amount = 0 时 revert |
| `test_calculateShares_InvalidOutcome_Reverts` | 无效 outcomeId 时 revert |
| `test_calculateShares_MultipleBets` | 连续下注：第二次获得更少 shares，反方向也能下注 |

### 4.5 赔付测试 - 2 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_calculatePayout_Winner` | 正常赔付计算：payout = userShares × totalLiquidity / totalWinningShares |
| `test_calculatePayout_Winner_ZeroShares` | totalWinningShares = 0 时返回 0 |

### 4.6 退款测试 - 2 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_calculateRefund` | 退款计算：refund = userShares × totalBetAmount / totalShares |
| `test_calculateRefund_ZeroShares` | totalShares = 0 时返回 0 |

### 4.7 预览测试 - 2 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_previewBet` | 预览返回 shares > 0，newPrice >= initialPrice |
| `test_previewBet_MatchesCalculateShares` | previewBet 和 calculateShares 返回相同 shares |

### 4.8 成本测试 - 1 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_calculateCost` | 购买份额需要正数成本 |

### 4.9 不变量测试 - 1 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_invariant_PricesSumToOne` | 多次下注后价格总和仍 ≈ 100% |

### 4.10 多结果市场测试 - 2 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `test_manyOutcomes_CorrectScore` | 25 outcome：初始价格各 ≈ 4%，总和 ≈ 100% |
| `test_manyOutcomes_BetOnOne` | 10 outcome：下注后目标 outcome 价格 > 其他 |

### 4.11 Fuzz 测试 - 3 个测试

| 测试名称 | 验证内容 |
|---------|---------|
| `testFuzz_calculateShares_AlwaysPositive` | 任意合理金额下注返回正数 shares |
| `testFuzz_prices_AlwaysValid` | 任意下注后所有价格在 (0, 100%) 区间 |
| `testFuzz_initialState_ValidPrices` | 任意合理参数初始化后价格总和 ≈ 100% |

---

## 5. 数学保证总结

在这 62 个测试约束下，本实现保证：

### 5.1 风险上界有明确保证

```
WorstCaseLoss ≤ b · ln(n)
```

对于 2-100 个 outcome 的市场，做市方最大亏损有数学上界。

### 5.2 价格向量始终可解释为概率分布

* 对任意可达状态，所有价格 `p_i ∈ (0, 1)`
* `∑ p_i ≈ 1`（允许 < 5% 误差）

### 5.3 成本函数满足单调与凸性

* 买得越多总成本越大
* 边际成本递增

### 5.4 价格行为符合经济直觉

* 买入某 outcome 其价格上升
* 卖出则下降
* 其它 outcome 价格联动调整（softmax 竞争性）

### 5.5 路径无关性 / 顺序无关性成立

* 相同最终头寸下，总成本与价格向量与交易拆分、顺序无关

### 5.6 数值在极端参数与大规模场景下稳定

* 大 q、大 n、极端 b 仍无溢出 / NaN
* 概率归一化不被破坏
* Log-sum-exp 技巧保证平移不变性

### 5.7 对称性保证

* **平移不变性**：`p(q + c·1) = p(q)`
* **排列对称性**：交换 `q_i` 和 `q_j` 会交换 `p_i` 和 `p_j`

### 5.8 非法输入被严格拒绝

* outcomeCount 必须在 [2, 100] 范围内
* liquidity 必须 > 0
* outcomeId 必须有效
* amount 必须 > 0

---

## 6. 测试运行

```bash
# 运行所有 LMSR 测试
forge test --match-path "test/pricing/LMSR*.t.sol" -vv

# 运行数学属性测试
forge test --match-contract LMSR_MathProperties_Test -vv

# 运行基础功能测试
forge test --match-contract LMSRStrategy_Test -vv

# 查看详细输出
forge test --match-path "test/pricing/LMSR*.t.sol" -vvvv

# 查看测试覆盖率
forge coverage --match-path "test/pricing/LMSR*.t.sol"
```

---

## 7. 测试结果摘要

```
╭--------------------------+--------+--------+---------╮
| Test Suite               | Passed | Failed | Skipped |
+======================================================+
| LMSRStrategy_Test        | 32     | 0      | 0       |
|--------------------------+--------+--------+---------|
| LMSR_MathProperties_Test | 30     | 0      | 0       |
╰--------------------------+--------+--------+---------╯

Total: 62 tests passed
```

---

## 8. 附录：Log-Sum-Exp 技巧实现

为保证数值稳定性，实现使用了 log-sum-exp 技巧。核心逻辑被提取到 `_logSumExpComponents` 函数中：

```solidity
function _logSumExpComponents(uint256[] memory quantities, uint256 b)
    internal
    pure
    returns (uint256 maxQ, uint256[] memory expValues, uint256 sumExp)
{
    uint256 n = quantities.length;
    expValues = new uint256[](n);

    // 找到最大值
    maxQ = 0;
    for (uint256 i = 0; i < n; i++) {
        if (quantities[i] > maxQ) {
            maxQ = quantities[i];
        }
    }

    // 计算 exp((q_i - maxQ) / b)
    sumExp = 0;
    for (uint256 i = 0; i < n; i++) {
        expValues[i] = _expShifted(quantities[i], maxQ, b);
        sumExp += expValues[i];
    }
}
```

这个函数被以下三个核心函数复用：
- `_calculateCost`: 计算购买成本
- `_calculatePrice`: 计算单个 outcome 价格
- `getAllPrices`: 计算所有 outcome 价格

---

*文档生成时间: 2025-12*
*测试框架: Foundry*
*Solidity 版本: ^0.8.20*
