// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingEngine.sol";

/**
 * @title SimpleCPMM
 * @notice 简化版 CPMM（Constant Product Market Maker）定价引擎
 * @dev 基于 x * y * z = k 的三向市场（WDL）定价
 *      支持 2-3 个结果的市场
 *
 * 定价公式：
 * - k = r0 * r1 * r2 (三向市场)
 * - 用户买入 outcome i，支付 amount，获得 shares
 * - 新储备 r_i' = r_i + shares
 * - 保持 k 不变：r0 * r1 * ... * r_i' * ... = k
 * - 解出 shares
 *
 * 价格计算：
 * - price_i = (1 / r_i) / sum(1 / r_j)
 * - 价格表示隐含概率（归一化）
 */
contract SimpleCPMM is IPricingEngine {
    // ============ 常量 ============

    /// @notice 最小储备（防止除零）
    uint256 public constant MIN_RESERVE = 1e6; // 0.000001 token (假设 18 decimals)

    /// @notice 最大滑点保护（10%）
    uint256 public constant MAX_SLIPPAGE = 1000; // 10% in basis points

    // ============ 核心函数 ============

    /**
     * @notice 计算下注获得的份额
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @param reserves 各结果的流动性储备
     * @return shares 获得的份额
     *
     * @dev 基于 CPMM 公式：
     *      k = r0 * r1 * r2
     *      用户支付 amount，买入 outcome i
     *      新储备 r_i' = r_i + shares
     *      保持 k 不变，解出 shares
     *
     * 简化实现（二向/三向市场）：
     * - 二向：r_other' = k / r_i'
     * - 三向：迭代求解（或使用近似公式）
     *
     * 当前实现：使用线性近似（适合小额交易）
     * shares ≈ amount * (total_liquidity / r_i)
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
        }

        // 计算总流动性
        uint256 totalLiquidity = 0;
        for (uint256 i = 0; i < n; i++) {
            totalLiquidity += reserves[i];
        }

        // 线性近似公式（适合小额交易）
        // shares = amount * (totalLiquidity / r_i) * adjustment_factor
        //
        // adjustment_factor 考虑：
        // 1. 价格影响（交易越大，滑点越大）
        // 2. 其他 outcome 的相对储备
        //
        // 简化版：shares = amount * (totalLiquidity / r_i) * 0.95
        // （保守估计，留 5% 缓冲）

        // 先计算基础份额，再应用调整因子（业务逻辑需要分步计算）
        // slither-disable-next-line divide-before-multiply
        uint256 baseShares = (amount * totalLiquidity) / reserves[outcomeId];

        // 应用调整因子（95%，保守估计留缓冲）
        shares = (baseShares * 9500) / 10000;

        // 确保至少返回 amount（1:1 最低保障）
        if (shares < amount) {
            shares = amount;
        }

        return shares;
    }

    /**
     * @notice 计算当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @param reserves 各结果的流动性储备
     * @return price 价格（基点，0-10000 表示 0%-100%）
     *
     * @dev 公式：price_i = (1 / r_i) / sum(1 / r_j)
     *      归一化后，所有价格之和 = 100%
     *
     * 示例（三向市场）：
     * - r0 = 100, r1 = 200, r2 = 300
     * - 1/r0 = 0.01, 1/r1 = 0.005, 1/r2 = 0.0033
     * - sum = 0.01 + 0.005 + 0.0033 = 0.0183
     * - price_0 = 0.01 / 0.0183 = 54.6%
     * - price_1 = 0.005 / 0.0183 = 27.3%
     * - price_2 = 0.0033 / 0.0183 = 18.1%
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

        // 计算 sum(1 / r_j)
        // 为避免浮点运算，使用分数表示
        // sum = (r1*r2 + r0*r2 + r0*r1) / (r0*r1*r2)
        //
        // price_i = (1/r_i) / sum = (r0*r1*...*r_(i-1)*r_(i+1)*...) / (r1*r2 + r0*r2 + ...)

        uint256 numerator;
        uint256 denominator = 0;

        if (n == 2) {
            // 二向市场
            numerator = reserves[1 - outcomeId];
            denominator = reserves[0] + reserves[1];
        } else {
            // 三向市场
            if (outcomeId == 0) {
                numerator = reserves[1] * reserves[2];
            } else if (outcomeId == 1) {
                numerator = reserves[0] * reserves[2];
            } else {
                numerator = reserves[0] * reserves[1];
            }

            // 分母：r1*r2 + r0*r2 + r0*r1
            denominator =
                reserves[1] * reserves[2] +
                reserves[0] * reserves[2] +
                reserves[0] * reserves[1];
        }

        // 转换为基点（0-10000）
        price = (numerator * 10000) / denominator;

        return price;
    }

    // ============ 辅助函数 ============

    /**
     * @notice 计算 K 值（用于验证）
     * @param reserves 各结果的流动性储备
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
}
