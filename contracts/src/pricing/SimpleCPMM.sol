// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingEngine.sol";

/**
 * @title SimpleCPMM
 * @notice 虚拟 AMM (Virtual Automated Market Maker) 定价引擎
 * @dev 基于虚拟储备的预测市场定价模型
 *
 * ⚠️ 核心变更：买入减少储备 → 价格上升（符合经济学规律）
 *
 * 虚拟储备模型：
 * - 储备代表"剩余可买份额"，而非"已投入资金"
 * - 买入 outcome i → r_i 减少 → price_i 上升 ✅
 * - 对手盘自动调整 → r_others 增加 → 保持市场平衡
 *
 * 定价公式（CPMM）：
 * - k = r₀ × r₁ × r₂ = 常数
 * - price_i = (1/r_i) / Σ(1/r_j) （归一化隐含概率）
 * - 所有价格之和 = 100%
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
contract SimpleCPMM is IPricingEngine {
    // ============ 常量 ============

    /// @notice 虚拟储备初始值（每个结果）
    /// @dev 较大的初始值 → 流动性更好，滑点更小
    uint256 public constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100,000 USDC

    /// @notice 最小储备（防止除零和极端价格）
    uint256 public constant MIN_RESERVE = 1000 * 1e6; // 1,000 USDC

    /// @notice 最大储备（防止溢出）
    uint256 public constant MAX_RESERVE = 10_000_000 * 1e6; // 10M USDC

    // ============ 核心函数 ============

    /**
     * @notice 计算买入获得的份额（使用精确 CPMM 公式）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @param reserves 各结果的虚拟储备
     * @return shares 获得的份额
     *
     * @dev 精确 CPMM 算法：
     *      1. 计算 k = r₀ × r₁ × r₂
     *      2. 买入 amount → r_i 减少
     *      3. 对手盘储备增加（保持 k）
     *      4. 解出实际获得的 shares
     *
     * 二向市场：
     *      k = r₀ × r₁
     *      买入 outcome 0 → r₀' = r₀ - shares
     *      r₁' = k / r₀' = k / (r₀ - shares)
     *      用户支付 amount = r₁' - r₁
     *      解出 shares
     *
     * 三向市场：
     *      使用迭代或数值方法求解
     */
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) external pure override returns (uint256 shares) {
        uint256 n = reserves.length;
        require(n >= 2 && n <= 3, "CPMM: Invalid outcome count");
        require(outcomeId < n, "CPMM: Invalid outcome ID");
        require(amount > 0, "CPMM: Zero amount");

        // 检查储备有效性
        for (uint256 i = 0; i < n; i++) {
            require(reserves[i] >= MIN_RESERVE, "CPMM: Reserve too low");
            require(reserves[i] <= MAX_RESERVE, "CPMM: Reserve too high");
        }

        if (n == 2) {
            // 二向市场精确公式（内部已包含边界检查）
            shares = _calculateSharesBinary(outcomeId, amount, reserves);
        } else {
            // 三向市场（内部已包含边界检查）
            shares = _calculateSharesTernary(outcomeId, amount, reserves);
        }

        // 最终验证
        require(shares > 0, "CPMM: Zero shares calculated");

        return shares;
    }

    /**
     * @notice 计算当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @param reserves 各结果的虚拟储备
     * @return price 价格（基点，0-10000 表示 0%-100%）
     *
     * @dev 公式：price_i = (1/r_i) / Σ(1/r_j)
     *      储备越小 → 价格越高 → 市场认为越可能发生
     *
     * 示例（三向市场）：
     * - r₀ = 90,000, r₁ = 100,000, r₂ = 110,000
     * - 1/r₀ = 0.0000111, 1/r₁ = 0.00001, 1/r₂ = 0.0000091
     * - sum = 0.0000312
     * - price_0 = 0.0000111 / 0.0000312 = 35.6% (主队被买入，价格上升)
     * - price_1 = 32.1%
     * - price_2 = 29.2%
     */
    function getPrice(uint256 outcomeId, uint256[] memory reserves)
        external
        pure
        override
        returns (uint256 price)
    {
        uint256 n = reserves.length;
        require(n >= 2 && n <= 3, "CPMM: Invalid outcome count");
        require(outcomeId < n, "CPMM: Invalid outcome ID");

        // 检查储备有效性
        for (uint256 i = 0; i < n; i++) {
            require(reserves[i] >= MIN_RESERVE, "CPMM: Reserve too low");
        }

        // 计算 sum(1 / r_j) - 使用乘法避免浮点运算
        uint256 numerator;
        uint256 denominator = 0;

        if (n == 2) {
            // 二向市场
            numerator = reserves[1 - outcomeId];
            denominator = reserves[0] + reserves[1];
        } else {
            // 三向市场
            // price_i = (r_j × r_k) / (r₀×r₁ + r₀×r₂ + r₁×r₂)
            if (outcomeId == 0) {
                numerator = reserves[1] * reserves[2];
            } else if (outcomeId == 1) {
                numerator = reserves[0] * reserves[2];
            } else {
                numerator = reserves[0] * reserves[1];
            }

            // 分母：r₁×r₂ + r₀×r₂ + r₀×r₁
            denominator =
                reserves[1] * reserves[2] +
                reserves[0] * reserves[2] +
                reserves[0] * reserves[1];
        }

        // 转换为基点（0-10000）
        price = (numerator * 10000) / denominator;

        // 安全检查：价格应在合理范围内
        require(price > 0 && price < 10000, "CPMM: Invalid price");

        return price;
    }

    // ============ 内部计算函数 ============

    /**
     * @notice 二向市场精确份额计算
     * @dev 公式推导：
     *      k = r₀ × r₁
     *      买入 outcome 0：r₀' = r₀ - shares, r₁' = k / r₀'
     *      用户支付：amount = r₁' - r₁ = k/(r₀ - shares) - r₁
     *      解出：shares = r₀ - k/(r₁ + amount)
     */
    function _calculateSharesBinary(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) internal pure returns (uint256 shares) {
        uint256 r_target = reserves[outcomeId];
        uint256 r_other = reserves[1 - outcomeId];

        // k = r₀ × r₁
        uint256 k = r_target * r_other;

        // 新的对手盘储备：r_other' = r_other + amount
        uint256 r_other_new = r_other + amount;

        // 保持 k 不变：r_target' = k / r_other'
        uint256 r_target_new = k / r_other_new;

        // shares = r_target - r_target'
        shares = r_target - r_target_new;

        // 边界检查：单笔交易不能超过储备的50%（防止过度消耗流动性）
        uint256 maxAllowedShares = r_target / 2;
        require(shares <= maxAllowedShares, "CPMM: Insufficient reserve");

        return shares;
    }

    /**
     * @notice 三向市场份额计算（改进的近似公式）
     * @dev 三向市场没有封闭解，使用改进的近似算法：
     *      将所有对手盘视为一个整体，应用二向市场的精确公式
     *
     * 改进方法：
     *      1. 将三向市场简化为"目标 vs 所有对手盘组合"的二向市场
     *      2. k_approx = r_target × opponent_total
     *      3. 应用二向市场的精确公式
     *      4. 对结果进行小幅调整以符合三向特性
     */
    function _calculateSharesTernary(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) internal pure returns (uint256 shares) {
        uint256 r_target = reserves[outcomeId];

        // 计算所有对手盘储备总和
        uint256 opponent_total = 0;
        for (uint256 i = 0; i < 3; i++) {
            if (i != outcomeId) {
                opponent_total += reserves[i];
            }
        }

        // 使用二向市场公式的近似：
        // k_approx = r_target × opponent_total
        uint256 k_approx = r_target * opponent_total;

        // 新的对手盘总储备
        uint256 opponent_new = opponent_total + amount;

        // 计算新的目标储备
        uint256 r_target_new = k_approx / opponent_new;

        // shares = r_target - r_target_new
        shares = r_target - r_target_new;

        // 三向市场调整因子（使价格上升更快，反映多对手竞争）
        // 提升28%以补偿三向市场的复杂性和多方竞争
        shares = (shares * 128) / 100;

        // 边界检查：单笔交易不能超过储备的50%
        uint256 maxAllowedShares = r_target / 2;
        require(shares <= maxAllowedShares, "CPMM: Insufficient reserve");

        return shares;
    }

    // ============ 辅助函数 ============

    /**
     * @notice 计算 K 值（用于验证）
     * @param reserves 各结果的虚拟储备
     * @return k 常数 K
     */
    function calculateK(uint256[] memory reserves) external pure returns (uint256 k) {
        require(reserves.length >= 2 && reserves.length <= 3, "CPMM: Invalid outcome count");

        k = reserves[0];
        for (uint256 i = 1; i < reserves.length; i++) {
            k *= reserves[i];
        }

        return k;
    }

    /**
     * @notice 计算有效价格（考虑滑点）
     * @param outcomeId 结果ID
     * @param reservesBefore 交易前储备
     * @param reservesAfter 交易后储备
     * @return effectivePrice 有效成交价格（基点）
     * @return slippageBps 滑点（基点）
     */
    function calculateEffectivePrice(
        uint256 outcomeId,
        uint256[] memory reservesBefore,
        uint256[] memory reservesAfter
    ) external view returns (uint256 effectivePrice, uint256 slippageBps) {
        // 交易前价格
        uint256 priceBefore = this.getPrice(outcomeId, reservesBefore);

        // 交易后价格
        uint256 priceAfter = this.getPrice(outcomeId, reservesAfter);

        // 有效价格（平均）
        effectivePrice = (priceBefore + priceAfter) / 2;

        // 滑点（价格变化百分比）
        if (priceAfter > priceBefore) {
            slippageBps = ((priceAfter - priceBefore) * 10000) / priceBefore;
        } else {
            slippageBps = 0; // 价格下降不算滑点（有利于用户）
        }

        return (effectivePrice, slippageBps);
    }

    /**
     * @notice 计算对手盘调整（买入时其他结果如何变化）
     * @param outcomeId 买入的结果
     * @param amount 买入金额
     * @param outcomeCount 总结果数
     * @return adjustments 各结果的储备调整量（正数=增加，负数=减少）
     */
    function calculateOpponentAdjustments(
        uint256 outcomeId,
        uint256 amount,
        uint256 outcomeCount
    ) external pure returns (int256[] memory adjustments) {
        require(outcomeCount >= 2 && outcomeCount <= 3, "CPMM: Invalid outcome count");

        adjustments = new int256[](outcomeCount);

        // 买入的结果：储备减少（用户获得的份额）
        // 这里返回金额，实际shares由calculateShares计算
        adjustments[outcomeId] = -int256(amount);

        // 对手盘：储备增加（均分）
        uint256 amountPerOpponent = amount / (outcomeCount - 1);
        for (uint256 i = 0; i < outcomeCount; i++) {
            if (i != outcomeId) {
                adjustments[i] = int256(amountPerOpponent);
            }
        }

        return adjustments;
    }

    /**
     * @notice 获取初始虚拟储备值
     * @param outcomeCount 结果数量
     * @return initialReserves 初始储备数组
     */
    function getInitialReserves(uint256 outcomeCount)
        external
        pure
        returns (uint256[] memory initialReserves)
    {
        require(outcomeCount >= 2 && outcomeCount <= 3, "CPMM: Invalid outcome count");

        initialReserves = new uint256[](outcomeCount);
        for (uint256 i = 0; i < outcomeCount; i++) {
            initialReserves[i] = VIRTUAL_RESERVE_INIT;
        }

        return initialReserves;
    }
}
