// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingStrategy.sol";

/**
 * @title CPMMStrategy
 * @notice CPMM（Constant Product Market Maker）定价策略
 * @dev 基于恒定乘积公式的做市商模型，适用于 2-3 向市场
 *
 * 核心公式：
 *      - 恒定乘积：k = r0 * r1 (对于二向市场)
 *      - 下注获得份额：shares = r_target - k / (r_target + amount)
 *      - 价格计算：price_i = r_i^(-1) / sum(r_j^(-1))
 *
 * 状态编码：
 *      state = abi.encode(uint256[] reserves)
 *
 * 特点：
 *      - 流动性好，滑点可控
 *      - 需要初始流动性
 *      - 适合 WDL、OU、AH、OddEven 等市场
 */
contract CPMMStrategy is IPricingStrategy {
    // ============ 常量 ============

    string private constant STRATEGY_TYPE = "CPMM";

    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant PRECISION = 1e18;

    // ============ 下注相关 ============

    /// @inheritdoc IPricingStrategy
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        bytes memory state
    ) external pure override returns (uint256 shares, bytes memory newState) {
        uint256[] memory reserves = abi.decode(state, (uint256[]));
        require(outcomeId < reserves.length, "CPMM: Invalid outcome");
        require(amount > 0, "CPMM: Amount must be > 0");

        uint256 outcomeCount = reserves.length;

        // 计算恒定乘积 k
        uint256 k = _calculateK(reserves);

        // 计算下注后目标储备应该变为多少（保持 k 不变）
        // 其他所有储备都增加 amount
        uint256[] memory newReserves = new uint256[](outcomeCount);
        uint256 productOthers = PRECISION;

        for (uint256 i = 0; i < outcomeCount; i++) {
            if (i != outcomeId) {
                newReserves[i] = reserves[i] + amount;
                productOthers = productOthers * newReserves[i] / PRECISION;
            }
        }

        // 目标储备 = k / productOthers
        // shares = reserves[outcomeId] - newReserves[outcomeId]
        uint256 newTargetReserve = k * PRECISION / productOthers;
        require(reserves[outcomeId] > newTargetReserve, "CPMM: Insufficient liquidity");

        shares = reserves[outcomeId] - newTargetReserve;
        newReserves[outcomeId] = newTargetReserve;

        newState = abi.encode(newReserves);
    }

    // ============ 赎回相关 ============

    /// @inheritdoc IPricingStrategy
    function calculatePayout(
        uint256 outcomeId,
        uint256 shares,
        uint256[] memory totalSharesPerOutcome,
        uint256 totalLiquidity,
        PayoutType payoutType
    ) external pure override returns (uint256 payout) {
        require(outcomeId < totalSharesPerOutcome.length, "CPMM: Invalid outcome");

        if (payoutType == PayoutType.WINNER) {
            // 赢家赔付：按份额比例分配总池
            uint256 totalWinningShares = totalSharesPerOutcome[outcomeId];
            if (totalWinningShares == 0) return 0;

            payout = shares * totalLiquidity / totalWinningShares;
        } else {
            // REFUND 模式下，使用 calculateRefund 更准确
            // 这里提供一个简化版本
            uint256 totalShares = totalSharesPerOutcome[outcomeId];
            if (totalShares == 0) return 0;

            // 假设投注金额与份额成正比（简化处理）
            payout = shares * totalLiquidity / _sumArray(totalSharesPerOutcome);
        }
    }

    /// @inheritdoc IPricingStrategy
    function calculateRefund(
        uint256 outcomeId,
        uint256 shares,
        uint256 totalSharesForOutcome,
        uint256 totalBetAmountForOutcome
    ) external pure override returns (uint256 refundAmount) {
        if (totalSharesForOutcome == 0) return 0;

        // 退款 = 用户份额占比 * 该结果的总投注金额
        refundAmount = shares * totalBetAmountForOutcome / totalSharesForOutcome;
    }

    // ============ 价格查询 ============

    /// @inheritdoc IPricingStrategy
    function getPrice(uint256 outcomeId, bytes memory state)
        external
        pure
        override
        returns (uint256 price)
    {
        uint256[] memory reserves = abi.decode(state, (uint256[]));
        require(outcomeId < reserves.length, "CPMM: Invalid outcome");

        // CPMM 价格公式：price_i = (1/r_i) / sum(1/r_j)
        // 等价于：price_i = (product_others) / sum(product_j)
        uint256 outcomeCount = reserves.length;
        uint256 invSum = 0;

        for (uint256 i = 0; i < outcomeCount; i++) {
            invSum += PRECISION * PRECISION / reserves[i];
        }

        uint256 invTarget = PRECISION * PRECISION / reserves[outcomeId];
        price = invTarget * BASIS_POINTS / invSum;
    }

    /// @inheritdoc IPricingStrategy
    function getAllPrices(uint256 outcomeCount, bytes memory state)
        external
        pure
        override
        returns (uint256[] memory prices)
    {
        uint256[] memory reserves = abi.decode(state, (uint256[]));
        require(reserves.length == outcomeCount, "CPMM: Outcome count mismatch");

        prices = new uint256[](outcomeCount);

        // 计算 1/r_i 的总和
        uint256 invSum = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            invSum += PRECISION * PRECISION / reserves[i];
        }

        // 计算每个 outcome 的价格
        for (uint256 i = 0; i < outcomeCount; i++) {
            uint256 invTarget = PRECISION * PRECISION / reserves[i];
            prices[i] = invTarget * BASIS_POINTS / invSum;
        }
    }

    // ============ 状态初始化 ============

    /// @inheritdoc IPricingStrategy
    function getInitialState(uint256 outcomeCount, uint256 initialLiquidity)
        external
        pure
        override
        returns (bytes memory initialState)
    {
        require(outcomeCount >= 2 && outcomeCount <= 10, "CPMM: Invalid outcome count");
        require(initialLiquidity > 0, "CPMM: Initial liquidity required");

        // 初始储备：均分流动性
        uint256[] memory reserves = new uint256[](outcomeCount);
        uint256 reservePerOutcome = initialLiquidity / outcomeCount;

        for (uint256 i = 0; i < outcomeCount; i++) {
            reserves[i] = reservePerOutcome;
        }

        initialState = abi.encode(reserves);
    }

    // ============ 策略元数据 ============

    /// @inheritdoc IPricingStrategy
    function strategyType() external pure override returns (string memory) {
        return STRATEGY_TYPE;
    }

    /// @inheritdoc IPricingStrategy
    function requiresInitialLiquidity() external pure override returns (bool) {
        return true;
    }

    /// @inheritdoc IPricingStrategy
    function minOutcomeCount() external pure override returns (uint256) {
        return 2;
    }

    /// @inheritdoc IPricingStrategy
    function maxOutcomeCount() external pure override returns (uint256) {
        return 10;
    }

    // ============ 内部函数 ============

    /**
     * @notice 计算恒定乘积 k
     * @param reserves 当前储备
     * @return k 恒定乘积（使用 PRECISION 归一化）
     */
    function _calculateK(uint256[] memory reserves) internal pure returns (uint256 k) {
        k = PRECISION;
        for (uint256 i = 0; i < reserves.length; i++) {
            k = k * reserves[i] / PRECISION;
        }
    }

    /**
     * @notice 计算数组元素之和
     */
    function _sumArray(uint256[] memory arr) internal pure returns (uint256 sum) {
        for (uint256 i = 0; i < arr.length; i++) {
            sum += arr[i];
        }
    }

    // ============ 辅助查询 ============

    /**
     * @notice 解码状态获取储备
     * @param state 编码后的状态
     * @return reserves 储备数组
     */
    function decodeState(bytes memory state) external pure returns (uint256[] memory reserves) {
        reserves = abi.decode(state, (uint256[]));
    }

    /**
     * @notice 预览下注结果（不修改状态）
     * @param outcomeId 结果 ID
     * @param amount 下注金额
     * @param state 当前状态
     * @return shares 预计获得的份额
     * @return newPrice 下注后的新价格
     */
    function previewBet(uint256 outcomeId, uint256 amount, bytes memory state)
        external
        pure
        returns (uint256 shares, uint256 newPrice)
    {
        uint256[] memory reserves = abi.decode(state, (uint256[]));
        require(outcomeId < reserves.length, "CPMM: Invalid outcome");
        require(amount > 0, "CPMM: Amount must be > 0");

        uint256 outcomeCount = reserves.length;
        uint256 k = _calculateK(reserves);

        // 计算新储备
        uint256[] memory newReserves = new uint256[](outcomeCount);
        uint256 productOthers = PRECISION;

        for (uint256 i = 0; i < outcomeCount; i++) {
            if (i != outcomeId) {
                newReserves[i] = reserves[i] + amount;
                productOthers = productOthers * newReserves[i] / PRECISION;
            }
        }

        uint256 newTargetReserve = k * PRECISION / productOthers;
        require(reserves[outcomeId] > newTargetReserve, "CPMM: Insufficient liquidity");

        shares = reserves[outcomeId] - newTargetReserve;
        newReserves[outcomeId] = newTargetReserve;

        // 计算新价格
        uint256 invSum = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            invSum += PRECISION * PRECISION / newReserves[i];
        }
        uint256 invTarget = PRECISION * PRECISION / newReserves[outcomeId];
        newPrice = invTarget * BASIS_POINTS / invSum;
    }
}
