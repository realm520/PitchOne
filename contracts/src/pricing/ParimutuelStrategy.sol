// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingStrategy.sol";

/**
 * @title ParimutuelStrategy
 * @notice Parimutuel（彩池）定价策略
 * @dev 用户对赌模式，所有投注进入池子，赔率在结算时计算
 *
 * 核心特点：
 *      - 不需要初始流动性
 *      - 下注即获得等额份额（1:1）
 *      - 赔率 = 总池 / 胜方池
 *      - 适合传统彩票玩法
 *
 * 状态编码：
 *      state = abi.encode(uint256[] pools)
 *      pools[i] = 该结果的总投注金额
 *
 * 价格计算：
 *      price_i = pools[i] / sum(pools)
 *      这反映的是市场投注分布，而非真正的赔率
 */
contract ParimutuelStrategy is IPricingStrategy {
    // ============ 常量 ============

    string private constant STRATEGY_TYPE = "PARIMUTUEL";

    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant PRECISION = 1e18;

    // ============ 下注相关 ============

    /// @inheritdoc IPricingStrategy
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        bytes memory state
    ) external pure override returns (uint256 shares, bytes memory newState) {
        uint256[] memory pools = abi.decode(state, (uint256[]));
        require(outcomeId < pools.length, "Parimutuel: Invalid outcome");
        require(amount > 0, "Parimutuel: Amount must be > 0");

        // Parimutuel 模式：1:1 兑换份额
        shares = amount;

        // 更新池子
        pools[outcomeId] += amount;
        newState = abi.encode(pools);
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
        require(outcomeId < totalSharesPerOutcome.length, "Parimutuel: Invalid outcome");

        if (payoutType == PayoutType.WINNER) {
            // 赢家赔付：按份额比例分配整个池子
            // payout = shares * (totalPool / winningPool)
            uint256 winningPool = totalSharesPerOutcome[outcomeId];
            if (winningPool == 0) return 0;

            // 在 Parimutuel 模式下，shares == 投注金额
            // 赔率 = totalLiquidity / winningPool
            payout = shares * totalLiquidity / winningPool;
        } else {
            // REFUND 模式：返还原始投注
            // 在 Parimutuel 中，shares == amount，直接返还
            payout = shares;
        }
    }

    /// @inheritdoc IPricingStrategy
    function calculateRefund(
        uint256 outcomeId,
        uint256 shares,
        uint256 totalSharesForOutcome,
        uint256 totalBetAmountForOutcome
    ) external pure override returns (uint256 refundAmount) {
        // 在 Parimutuel 中，shares == 投注金额
        // 直接返还份额数量（即原始投注金额）
        if (totalSharesForOutcome == 0) return 0;

        // 退款 = 用户份额（即投注金额）
        // 注意：totalBetAmountForOutcome 在 Parimutuel 中等于 totalSharesForOutcome
        refundAmount = shares;
    }

    // ============ 价格查询 ============

    /// @inheritdoc IPricingStrategy
    function getPrice(uint256 outcomeId, bytes memory state)
        external
        pure
        override
        returns (uint256 price)
    {
        uint256[] memory pools = abi.decode(state, (uint256[]));
        require(outcomeId < pools.length, "Parimutuel: Invalid outcome");

        uint256 totalPool = _sumArray(pools);

        if (totalPool == 0) {
            // 初始状态：均匀分布
            return BASIS_POINTS / pools.length;
        }

        // 价格 = 该结果投注占比（反映市场分布）
        price = pools[outcomeId] * BASIS_POINTS / totalPool;
    }

    /// @inheritdoc IPricingStrategy
    function getAllPrices(uint256 outcomeCount, bytes memory state)
        external
        pure
        override
        returns (uint256[] memory prices)
    {
        uint256[] memory pools = abi.decode(state, (uint256[]));
        require(pools.length == outcomeCount, "Parimutuel: Outcome count mismatch");

        prices = new uint256[](outcomeCount);
        uint256 totalPool = _sumArray(pools);

        if (totalPool == 0) {
            // 初始状态：均匀分布
            uint256 equalPrice = BASIS_POINTS / outcomeCount;
            for (uint256 i = 0; i < outcomeCount; i++) {
                prices[i] = equalPrice;
            }
            return prices;
        }

        for (uint256 i = 0; i < outcomeCount; i++) {
            prices[i] = pools[i] * BASIS_POINTS / totalPool;
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
        require(outcomeCount >= 2 && outcomeCount <= 100, "Parimutuel: Invalid outcome count");
        // Parimutuel 不需要初始流动性，忽略 initialLiquidity 参数
        // 如果传入了初始流动性，可以选择均分到各池（可选行为）

        uint256[] memory pools = new uint256[](outcomeCount);

        if (initialLiquidity > 0) {
            // 可选：将初始流动性均分到各池
            uint256 perPool = initialLiquidity / outcomeCount;
            for (uint256 i = 0; i < outcomeCount; i++) {
                pools[i] = perPool;
            }
        }
        // 否则所有池为 0

        initialState = abi.encode(pools);
    }

    // ============ 策略元数据 ============

    /// @inheritdoc IPricingStrategy
    function strategyType() external pure override returns (string memory) {
        return STRATEGY_TYPE;
    }

    /// @inheritdoc IPricingStrategy
    function requiresInitialLiquidity() external pure override returns (bool) {
        return false; // Parimutuel 不需要初始流动性
    }

    /// @inheritdoc IPricingStrategy
    function minOutcomeCount() external pure override returns (uint256) {
        return 2;
    }

    /// @inheritdoc IPricingStrategy
    function maxOutcomeCount() external pure override returns (uint256) {
        return 100; // Parimutuel 可支持更多结果
    }

    // ============ 内部函数 ============

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
     * @notice 解码状态获取池子
     * @param state 编码后的状态
     * @return pools 池子数组
     */
    function decodeState(bytes memory state) external pure returns (uint256[] memory pools) {
        pools = abi.decode(state, (uint256[]));
    }

    /**
     * @notice 获取隐含赔率（总池/该结果池）
     * @param outcomeId 结果 ID
     * @param state 当前状态
     * @return odds 赔率（精度 1e18，如 2.5x = 2.5e18）
     */
    function getOdds(uint256 outcomeId, bytes memory state)
        external
        pure
        returns (uint256 odds)
    {
        uint256[] memory pools = abi.decode(state, (uint256[]));
        require(outcomeId < pools.length, "Parimutuel: Invalid outcome");

        uint256 totalPool = _sumArray(pools);
        uint256 outcomePool = pools[outcomeId];

        if (outcomePool == 0) {
            return type(uint256).max; // 无限赔率（无人下注）
        }

        // odds = totalPool / outcomePool（精度 1e18）
        odds = totalPool * PRECISION / outcomePool;
    }

    /**
     * @notice 预览下注后的赔率变化
     * @param outcomeId 下注结果 ID
     * @param amount 下注金额
     * @param state 当前状态
     * @return oddsBefore 下注前赔率
     * @return oddsAfter 下注后赔率
     */
    function previewBet(uint256 outcomeId, uint256 amount, bytes memory state)
        external
        pure
        returns (uint256 oddsBefore, uint256 oddsAfter)
    {
        uint256[] memory pools = abi.decode(state, (uint256[]));
        require(outcomeId < pools.length, "Parimutuel: Invalid outcome");

        uint256 totalPool = _sumArray(pools);
        uint256 outcomePool = pools[outcomeId];

        // 下注前赔率
        if (outcomePool == 0) {
            oddsBefore = type(uint256).max;
        } else {
            oddsBefore = totalPool * PRECISION / outcomePool;
        }

        // 下注后赔率
        uint256 newTotalPool = totalPool + amount;
        uint256 newOutcomePool = outcomePool + amount;
        oddsAfter = newTotalPool * PRECISION / newOutcomePool;
    }
}
