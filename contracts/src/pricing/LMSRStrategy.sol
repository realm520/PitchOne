// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingStrategy.sol";

/**
 * @title LMSRStrategy
 * @notice LMSR（Logarithmic Market Scoring Rule）定价策略
 * @dev 基于 Hanson 的 LMSR 算法，适用于多向市场（如精确比分、首位进球者）
 *
 * 核心公式：
 *      - 成本函数：C(q) = b * ln(sum(exp(q_i / b)))
 *      - 下注成本：cost = C(q_new) - C(q_old)
 *      - 价格：price_i = exp(q_i / b) / sum(exp(q_j / b))
 *
 * 状态编码：
 *      state = abi.encode(uint256[] quantities, uint256 b)
 *      quantities[i] = 该结果的累计数量
 *      b = 流动性参数（影响价格敏感度）
 *
 * 特点：
 *      - 支持大量结果（如 25+ 个比分）
 *      - 价格总和恒为 1
 *      - b 越大，滑点越小
 *      - 需要初始流动性
 */
contract LMSRStrategy is IPricingStrategy {
    // ============ 常量 ============

    string private constant STRATEGY_TYPE = "LMSR";

    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant PRECISION = 1e18;

    // LMSR 计算精度
    // 使用 59.18-decimal 定点数避免溢出
    int256 private constant SCALE = 1e18;
    int256 private constant HALF_SCALE = 5e17;

    // ============ 下注相关 ============

    /// @inheritdoc IPricingStrategy
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        bytes memory state
    ) external pure override returns (uint256 shares, bytes memory newState) {
        (uint256[] memory quantities, uint256 b) = abi.decode(state, (uint256[], uint256));
        require(outcomeId < quantities.length, "LMSR: Invalid outcome");
        require(amount > 0, "LMSR: Amount must be > 0");
        require(b > 0, "LMSR: Invalid b parameter");

        // LMSR 中，shares 需要通过二分查找计算
        // 用户支付 amount，获得使 C(q_new) - C(q_old) = amount 的 shares
        uint256 costBefore = _calculateCost(quantities, b);

        // 二分查找：找到使成本差等于 amount 的 shares
        // 对于 LMSR，理论上 shares ≈ amount（当价格接近 1/N 时）
        // 上界设为 amount * 100 以覆盖高杠杆场景
        uint256 low = 1; // 从 1 开始而非 0，确保至少有 1 share
        uint256 high = amount * 100;
        uint256 mid;

        // 创建临时 quantities 用于计算
        uint256[] memory tempQuantities = new uint256[](quantities.length);

        // 首先检查 low=1 是否可行
        for (uint256 i = 0; i < quantities.length; i++) {
            tempQuantities[i] = quantities[i];
        }
        tempQuantities[outcomeId] += 1;
        uint256 costFor1 = _calculateCost(tempQuantities, b);

        // 如果 1 share 的成本已经超过 amount，说明金额太小
        if (costFor1 > costBefore + amount) {
            revert("LMSR: Amount too small for minimum share");
        }

        while (high - low > 1) {
            mid = (low + high) / 2;

            // 复制 quantities
            for (uint256 i = 0; i < quantities.length; i++) {
                tempQuantities[i] = quantities[i];
            }
            tempQuantities[outcomeId] += mid;

            uint256 costAfter = _calculateCost(tempQuantities, b);
            uint256 costDiff = costAfter > costBefore ? costAfter - costBefore : 0;

            if (costDiff <= amount) {
                low = mid;
            } else {
                high = mid;
            }
        }

        shares = low;
        require(shares > 0, "LMSR: Shares too small");

        // 更新状态
        quantities[outcomeId] += shares;
        newState = abi.encode(quantities, b);
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
        require(outcomeId < totalSharesPerOutcome.length, "LMSR: Invalid outcome");

        if (payoutType == PayoutType.WINNER) {
            // 赢家赔付：按份额比例分配总池
            uint256 totalWinningShares = totalSharesPerOutcome[outcomeId];
            if (totalWinningShares == 0) return 0;

            payout = shares * totalLiquidity / totalWinningShares;
        } else {
            // REFUND：按份额比例退款
            uint256 totalShares = 0;
            for (uint256 i = 0; i < totalSharesPerOutcome.length; i++) {
                totalShares += totalSharesPerOutcome[i];
            }
            if (totalShares == 0) return 0;

            payout = shares * totalLiquidity / totalShares;
        }
    }

    /// @inheritdoc IPricingStrategy
    function calculateRefund(
        uint256 /* outcomeId */,
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
        (uint256[] memory quantities, uint256 b) = abi.decode(state, (uint256[], uint256));
        require(outcomeId < quantities.length, "LMSR: Invalid outcome");

        // LMSR 价格：exp(q_i / b) / sum(exp(q_j / b))
        price = _calculatePrice(quantities, b, outcomeId);
    }

    /// @inheritdoc IPricingStrategy
    function getAllPrices(uint256 outcomeCount, bytes memory state)
        external
        pure
        override
        returns (uint256[] memory prices)
    {
        (uint256[] memory quantities, uint256 b) = abi.decode(state, (uint256[], uint256));
        require(quantities.length == outcomeCount, "LMSR: Outcome count mismatch");

        // 使用 log-sum-exp 技巧计算 softmax 价格
        (, uint256[] memory expValues, uint256 sumExp) = _logSumExpComponents(quantities, b);

        prices = new uint256[](outcomeCount);

        // 计算每个价格
        for (uint256 i = 0; i < outcomeCount; i++) {
            if (sumExp > 0) {
                prices[i] = expValues[i] * BASIS_POINTS / sumExp;
            } else {
                prices[i] = BASIS_POINTS / outcomeCount;
            }
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
        require(outcomeCount >= 2 && outcomeCount <= 100, "LMSR: Invalid outcome count");
        require(initialLiquidity > 0, "LMSR: Initial liquidity required");

        // 初始 quantities 全为 0（所有价格相等）
        uint256[] memory quantities = new uint256[](outcomeCount);

        // 默认 b 值计算：
        // b 控制价格敏感度，b 越大滑点越小
        // 推荐公式：b = initialLiquidity / (2 * outcomeCount)
        // 这样可以确保：
        //   - 对于 2 个结果、100k 流动性：b = 25k（合理的滑点）
        //   - 对于 10 个结果、100k 流动性：b = 5k（更敏感的价格）
        //   - 对于 36 个结果（精确比分）、100k 流动性：b ≈ 1.4k（敏感但可用）
        uint256 b = initialLiquidity / (2 * outcomeCount);

        // 设置最小值：确保小流动性市场也能正常工作
        // 最小 b = 1e15 (0.001 TOKEN with e18 precision)
        uint256 minB = 1e15;
        if (b < minB) b = minB;

        initialState = abi.encode(quantities, b);
    }

    /**
     * @notice 带最大下注金额参数的初始化（推荐使用）
     * @param outcomeCount 结果数量
     * @param initialLiquidity 初始流动性
     * @param maxExpectedBetAmount 预期最大单次下注金额
     * @return initialState 初始状态
     * @dev b 参数根据 maxExpectedBetAmount 计算，确保 amount/b < 20（exp 函数安全范围）
     *
     * 示例配置：
     *   - 精确比分 (36 outcomes, 100k 流动性, 最大下注 5000 USDC): b = 500 USDC
     *   - 首位进球者 (25 outcomes, 100k 流动性, 最大下注 2000 USDC): b = 200 USDC
     *   - WDL (3 outcomes, 100k 流动性, 最大下注 10000 USDC): b = 1000 USDC
     */
    function getInitialStateWithMaxBet(
        uint256 outcomeCount,
        uint256 initialLiquidity,
        uint256 maxExpectedBetAmount
    )
        external
        pure
        returns (bytes memory initialState)
    {
        return _getInitialStateInternal(outcomeCount, initialLiquidity, maxExpectedBetAmount);
    }

    /**
     * @notice 内部初始化函数（用于自定义 maxExpectedBetAmount）
     */
    function _getInitialStateInternal(
        uint256 outcomeCount,
        uint256 initialLiquidity,
        uint256 maxExpectedBetAmount
    )
        internal
        pure
        returns (bytes memory initialState)
    {
        require(outcomeCount >= 2 && outcomeCount <= 100, "LMSR: Invalid outcome count");
        require(initialLiquidity > 0, "LMSR: Initial liquidity required");
        require(maxExpectedBetAmount > 0, "LMSR: Invalid max bet amount");

        // 初始 quantities 全为 0（所有价格相等）
        uint256[] memory quantities = new uint256[](outcomeCount);

        // b 参数计算：
        // - _exp 函数中 x = q/b，当 x > 20 时会被截断
        // - 为了确保准确计算，需要 maxBet / b < 20
        // - 因此 b >= maxBet / 20
        // - 为安全起见，使用 b = maxBet / 10（留出余量）
        //
        // 同时 b 不能太大，否则小额下注无法产生足够的成本差
        // b 最大不超过 initialLiquidity / outcomeCount
        uint256 b = maxExpectedBetAmount / 10;

        // 设置最小值：确保小额下注也能正常工作
        // 最小 b = 1e15 (0.001 TOKEN with e18 precision)
        uint256 minB = 1e15;
        if (b < minB) b = minB;

        // 设置最大值：不超过流动性的合理比例
        uint256 maxB = initialLiquidity / outcomeCount;
        if (b > maxB) b = maxB;

        initialState = abi.encode(quantities, b);
    }

    /**
     * @notice 更新现有状态的 b 参数（运行时调整）
     * @param state 当前状态
     * @param newB 新的 b 参数
     * @return newState 更新后的状态
     * @dev 用于运营方根据实际情况调整市场深度
     *
     * 使用场景：
     *   - 市场流动性增加后，提高 b 以支持更大下注
     *   - 发现价格波动过大，提高 b 减少滑点
     *   - 发现价格不敏感，降低 b 增加响应速度
     */
    function updateB(bytes memory state, uint256 newB)
        external
        pure
        returns (bytes memory newState)
    {
        require(newB > 0, "LMSR: Invalid b parameter");

        (uint256[] memory quantities, ) = abi.decode(state, (uint256[], uint256));
        newState = abi.encode(quantities, newB);
    }

    /**
     * @notice 根据最大下注金额计算推荐的 b 值
     * @param maxExpectedBetAmount 预期最大单次下注金额
     * @return recommendedB 推荐的 b 参数
     */
    function calculateRecommendedB(uint256 maxExpectedBetAmount)
        external
        pure
        returns (uint256 recommendedB)
    {
        // b = maxBet / 10，确保 maxBet / b = 10 < 20（安全范围）
        recommendedB = maxExpectedBetAmount / 10;
        // 最小 b = 1e15 (0.001 TOKEN with e18 precision)
        if (recommendedB < 1e15) recommendedB = 1e15;
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
        return 100; // LMSR 适合多向市场
    }

    // ============ 内部函数 ============

    /**
     * @notice 计算 log-sum-exp 的核心组件（复用于 cost 和 price 计算）
     * @dev 使用 log-sum-exp 技巧避免数值溢出
     *
     * Log-sum-exp 技巧：
     *   p_i = exp(q_i/b) / sum(exp(q_j/b))
     *       = exp((q_i - maxQ)/b) / sum(exp((q_j - maxQ)/b))
     *
     * 由于 (q_i - maxQ) <= 0，exp((q_i - maxQ)/b) <= 1，避免了溢出
     *
     * @param quantities 各 outcome 的数量数组
     * @param b 流动性参数
     * @return maxQ 最大的 q 值
     * @return expValues 各 outcome 的 exp((q_i - maxQ)/b) 值
     * @return sumExp 所有 expValues 的总和
     */
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

    /**
     * @notice 计算 LMSR 成本函数 C(q) = b * ln(sum(exp(q_i / b)))
     * @dev 使用 log-sum-exp 技巧：C = maxQ + b * ln(sum(exp((q_i - maxQ)/b)))
     */
    function _calculateCost(uint256[] memory quantities, uint256 b)
        internal
        pure
        returns (uint256 cost)
    {
        (uint256 maxQ, , uint256 sumExp) = _logSumExpComponents(quantities, b);

        // cost = maxQ + b * ln(sumExp)
        // _ln(sumExp) 返回 ln 值的 e18 精度表示，需要除以 PRECISION 转换回原单位
        cost = maxQ + b * _ln(sumExp) / PRECISION;
    }

    /**
     * @notice 计算 exp((q - maxQ) / b)，用于 log-sum-exp 技巧
     * @dev 由于 q <= maxQ，所以 (q - maxQ) / b <= 0，结果 <= 1
     */
    function _expShifted(uint256 q, uint256 maxQ, uint256 b) internal pure returns (uint256) {
        if (b == 0) return PRECISION;
        if (q >= maxQ) return PRECISION; // exp(0) = 1

        // (maxQ - q) / b，结果 >= 0
        uint256 diff = maxQ - q;
        uint256 x = diff * PRECISION / b;

        // 限制 x 的范围避免下溢
        if (x > 20 * PRECISION) {
            return 0; // exp(-20) ≈ 0
        }

        // exp(-x) = 1 / exp(x)
        // 使用泰勒展开计算 exp(x)，然后取倒数
        uint256 expX = PRECISION; // 1
        uint256 term = x;
        expX += term;
        term = term * x / PRECISION / 2;
        expX += term;
        term = term * x / PRECISION / 3;
        expX += term;
        term = term * x / PRECISION / 4;
        expX += term;
        term = term * x / PRECISION / 5;
        expX += term;

        // exp(-x) = 1 / exp(x) = PRECISION / expX (以 PRECISION 精度表示)
        if (expX == 0) return 0;
        return PRECISION * PRECISION / expX;
    }

    /**
     * @notice 计算单个结果的价格
     * @dev 使用 log-sum-exp 技巧保证数值稳定性和 shift invariance
     */
    function _calculatePrice(uint256[] memory quantities, uint256 b, uint256 outcomeId)
        internal
        pure
        returns (uint256 price)
    {
        (, uint256[] memory expValues, uint256 sumExp) = _logSumExpComponents(quantities, b);

        if (sumExp == 0) {
            return BASIS_POINTS / quantities.length;
        }

        price = expValues[outcomeId] * BASIS_POINTS / sumExp;
    }

    /**
     * @notice 近似计算 exp(q / b)
     * @dev 使用泰勒展开或查表
     */
    function _exp(uint256 q, uint256 b) internal pure returns (uint256) {
        if (b == 0) return PRECISION;

        // x = q / b（缩放到 PRECISION）
        uint256 x = q * PRECISION / b;

        // 限制 x 的范围避免溢出
        if (x > 20 * PRECISION) {
            x = 20 * PRECISION; // cap at exp(20) ≈ 485M
        }

        // 泰勒展开：exp(x) ≈ 1 + x + x²/2 + x³/6 + x⁴/24
        // 对于小 x，这是个好的近似
        uint256 result = PRECISION; // 1
        uint256 term = x; // x
        result += term;

        term = term * x / PRECISION / 2; // x²/2
        result += term;

        term = term * x / PRECISION / 3; // x³/6
        result += term;

        term = term * x / PRECISION / 4; // x⁴/24
        result += term;

        term = term * x / PRECISION / 5; // x⁵/120
        result += term;

        return result;
    }

    /**
     * @notice 近似计算 ln(x)
     * @dev 使用牛顿法或查表
     */
    function _ln(uint256 x) internal pure returns (uint256) {
        if (x <= PRECISION) return 0;

        // 简化的对数计算
        // ln(x) ≈ (x - 1) - (x - 1)²/2 + (x - 1)³/3 for x close to 1
        // 或使用二分查找

        // 这里使用简化版本：ln(x) ≈ 2 * (x - 1) / (x + 1)
        uint256 num = (x - PRECISION) * PRECISION;
        uint256 den = x + PRECISION;
        return num / den;
    }

    // ============ 辅助查询 ============

    /**
     * @notice 解码状态
     * @param state 编码后的状态
     * @return quantities 数量数组
     * @return b 流动性参数
     */
    function decodeState(bytes memory state)
        external
        pure
        returns (uint256[] memory quantities, uint256 b)
    {
        (quantities, b) = abi.decode(state, (uint256[], uint256));
    }

    /**
     * @notice 预览下注结果
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
        (uint256[] memory quantities, uint256 b) = abi.decode(state, (uint256[], uint256));
        require(outcomeId < quantities.length, "LMSR: Invalid outcome");
        require(amount > 0, "LMSR: Amount must be > 0");
        require(b > 0, "LMSR: Invalid b parameter");

        // 计算当前成本
        uint256 costBefore = _calculateCost(quantities, b);

        // 二分查找 shares
        uint256 low = 0;
        uint256 high = amount * 10;
        uint256 mid;
        uint256[] memory tempQuantities = new uint256[](quantities.length);

        while (high - low > 1) {
            mid = (low + high) / 2;
            for (uint256 i = 0; i < quantities.length; i++) {
                tempQuantities[i] = quantities[i];
            }
            tempQuantities[outcomeId] += mid;
            uint256 costAfter = _calculateCost(tempQuantities, b);
            if (costAfter - costBefore <= amount) {
                low = mid;
            } else {
                high = mid;
            }
        }

        shares = low;

        // 计算新价格
        quantities[outcomeId] += shares;
        newPrice = _calculatePrice(quantities, b, outcomeId);
    }

    /**
     * @notice 计算购买指定份额需要的成本
     * @param outcomeId 结果 ID
     * @param sharesToBuy 要购买的份额数量
     * @param state 当前状态
     * @return cost 需要支付的金额
     */
    function calculateCost(uint256 outcomeId, uint256 sharesToBuy, bytes memory state)
        external
        pure
        returns (uint256 cost)
    {
        (uint256[] memory quantities, uint256 b) = abi.decode(state, (uint256[], uint256));
        require(outcomeId < quantities.length, "LMSR: Invalid outcome");

        uint256 costBefore = _calculateCost(quantities, b);

        // 更新数量
        quantities[outcomeId] += sharesToBuy;

        uint256 costAfter = _calculateCost(quantities, b);
        cost = costAfter - costBefore;
    }
}
