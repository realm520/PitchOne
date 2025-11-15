// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingEngine.sol";

/**
 * @title ParimutuelPricing
 * @notice 彩池定价引擎 - 赔率由实际投注总额决定
 * @dev 实现 Parimutuel (池化博彩) 定价模型
 *
 * 核心原理：
 * - 所有投注进入池子，按 1:1 兑换份额
 * - 赔率在结算时计算：payout = (总池子 / 胜方池子) * 用户份额
 * - 不需要虚拟储备（储备 = 实际累计投注额）
 *
 * 与 SimpleCPMM 的区别：
 * - SimpleCPMM: 虚拟储备定价，即时赔率，价格敏感度低
 * - Parimutuel: 实际投注定价，结算时赔率，价格完全由市场决定
 *
 * 适用场景：
 * - 想要赔率完全反映市场投注分布
 * - 不需要即时赔率，可以等到结算时确定
 * - 传统博彩玩家熟悉的模式
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
contract ParimutuelPricing is IPricingEngine {
    // ============ 常量 ============

    /// @notice 最小初始储备（避免除零错误）
    /// @dev 可以设置为极小值（如 1 wei）
    uint256 public constant MIN_RESERVE = 1;

    // ============ 错误定义 ============

    error ZeroAmount();
    error InvalidOutcomeCount();
    error InvalidOutcomeId();
    error ZeroReserve();

    // ============ 核心函数 ============

    /**
     * @notice 计算买入获得的份额
     * @param outcomeId 结果ID（在 Parimutuel 中不影响份额计算）
     * @param amount 净金额（已扣除手续费）
     * @param reserves 各结果的累计投注额（不是虚拟储备！）
     * @return shares 获得的份额
     *
     * @dev Parimutuel 模式核心：
     *      - shares = amount（1:1 兑换）
     *      - 投入多少就得到多少份额
     *      - 真实赔率在结算时根据池子比例计算
     *      - 不关心当前储备状态
     *
     * 示例：
     *      用户投注 100 USDC → 获得 100 份额
     *      如果胜方总投注 500 USDC，总池子 1000 USDC
     *      → 最终赔率 = 1000/500 = 2.0x
     *      → 用户收益 = 100 * 2.0 = 200 USDC
     */
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) external pure override returns (uint256 shares) {
        // 基本验证
        if (amount == 0) revert ZeroAmount();

        uint256 n = reserves.length;
        if (n < 2 || n > 3) revert InvalidOutcomeCount();
        if (outcomeId >= n) revert InvalidOutcomeId();

        // Parimutuel 核心：1:1 兑换
        // 赔率由结算时的池子比例决定，不在此计算
        return amount;
    }

    /**
     * @notice 计算当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @param reserves 各结果的累计投注额
     * @return price 价格（基点，0-10000 表示 0%-100%）
     *
     * @dev 价格公式：
     *      price_i = (reserves_i / totalReserves) * 10000
     *
     *      这是"隐含概率"（市场认为的获胜概率）
     *      真实赔率 = 1 / (price / 10000) = 10000 / price
     *
     * 示例：
     *      - Outcome 0: 300 USDC 投注
     *      - Outcome 1: 700 USDC 投注
     *      - 总投注: 1000 USDC
     *      → price_0 = 300/1000 = 30% = 3000 基点
     *      → price_1 = 700/1000 = 70% = 7000 基点
     *      → 隐含赔率: 3.33x vs 1.43x
     */
    function getPrice(uint256 outcomeId, uint256[] memory reserves)
        external
        pure
        override
        returns (uint256 price)
    {
        uint256 n = reserves.length;
        if (outcomeId >= n) revert InvalidOutcomeId();

        // 计算总投注额
        uint256 totalBets = 0;
        for (uint256 i = 0; i < n; i++) {
            totalBets += reserves[i];
        }

        // 如果还没有任何投注，返回均等价格
        if (totalBets == 0) {
            // 二向市场: 50:50 = 5000 基点
            // 三向市场: 33.33:33.33:33.33 ≈ 3333 基点
            return 10000 / n;
        }

        // 某方投注额为 0 时，价格为 0（赔率无穷大，实际上不可能赢）
        if (reserves[outcomeId] == 0) {
            return 0;
        }

        // 当前隐含价格 = 某方投注额 / 总投注额
        // 乘以 10000 转换为基点
        return (reserves[outcomeId] * 10000) / totalBets;
    }

    /**
     * @notice 更新储备（在用户下注后调用）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @param shares 用户获得的份额（由 calculateShares 计算）
     * @param reserves 当前储备
     * @return newReserves 更新后的储备
     *
     * @dev Parimutuel 储备更新逻辑：
     *      - 累加到目标结果的实际投注池
     *      - newReserves[outcomeId] += amount
     *      - 其他结果储备不变
     *
     *      这与 SimpleCPMM 完全不同（CPMM 是减少目标储备,增加对手盘储备）
     *
     * 示例：
     *      初始状态: [100, 200]（Outcome 0 有 100 USDC，Outcome 1 有 200 USDC）
     *      用户投注 50 USDC 到 Outcome 0
     *      → newReserves = [150, 200]
     */
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external pure override returns (uint256[] memory newReserves) {
        uint256 n = reserves.length;
        if (n < 2 || n > 3) revert InvalidOutcomeCount();
        if (outcomeId >= n) revert InvalidOutcomeId();
        if (amount == 0) revert ZeroAmount();

        // 创建新数组并复制储备
        newReserves = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            newReserves[i] = reserves[i];
        }

        // Parimutuel 核心逻辑：累加到目标结果的投注池
        newReserves[outcomeId] += amount;

        return newReserves;
    }

    /**
     * @notice 获取初始储备配置
     * @param outcomeCount 结果数量（2 或 3）
     * @return initialReserves 初始储备数组
     *
     * @dev Parimutuel 模式的初始储备为零
     *      这意味着市场启动时不需要任何流动性
     *      赔率完全由实际投注分布决定
     *
     * 返回值：
     *      - 二向市场: [0, 0]
     *      - 三向市场: [0, 0, 0]
     *
     * 对比 SimpleCPMM:
     *      - CPMM 初始储备: [100_000 USDC, 100_000 USDC]
     *      - Parimutuel 初始储备: [0, 0]
     */
    function getInitialReserves(uint256 outcomeCount)
        external
        pure
        override
        returns (uint256[] memory initialReserves)
    {
        if (outcomeCount < 2 || outcomeCount > 3) revert InvalidOutcomeCount();

        // 返回零储备数组
        initialReserves = new uint256[](outcomeCount);
        // 数组默认初始化为 0，无需显式赋值

        return initialReserves;
    }

    /**
     * @notice 验证储备值（Parimutuel 模式下储备可以为 0）
     * @param reserves 储备数组
     * @return valid 是否有效
     *
     * @dev Parimutuel 模式下，初始储备可以全为 0
     *      这与 SimpleCPMM 不同（CPMM 需要非零储备）
     */
    function validateReserves(uint256[] memory reserves)
        external
        pure
        returns (bool valid)
    {
        // Parimutuel 允许储备为 0（市场刚创建时）
        // 只需验证数组长度
        return reserves.length >= 2 && reserves.length <= 3;
    }
}
