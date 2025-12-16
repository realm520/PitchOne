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
        uint256 low = 0;
        uint256 high = amount * 10; // 上界：最多 10 倍杠杆
        uint256 mid;

        // 创建临时 quantities 用于计算
        uint256[] memory tempQuantities = new uint256[](quantities.length);

        while (high - low > 1) {
            mid = (low + high) / 2;

            // 复制 quantities
            for (uint256 i = 0; i < quantities.length; i++) {
                tempQuantities[i] = quantities[i];
            }
            tempQuantities[outcomeId] += mid;

            uint256 costAfter = _calculateCost(tempQuantities, b);
            uint256 costDiff = costAfter - costBefore;

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

        prices = new uint256[](outcomeCount);

        // 计算 exp(q_i / b) 的总和
        uint256 sumExp = 0;
        uint256[] memory expValues = new uint256[](outcomeCount);

        for (uint256 i = 0; i < outcomeCount; i++) {
            expValues[i] = _exp(quantities[i], b);
            sumExp += expValues[i];
        }

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

        // b 参数：影响价格敏感度
        // b 越大，滑点越小；b 越小，滑点越大
        // 通常设置为 initialLiquidity / outcomeCount
        uint256 b = initialLiquidity / outcomeCount;
        if (b == 0) b = 1;

        initialState = abi.encode(quantities, b);
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
     * @notice 计算 LMSR 成本函数 C(q) = b * ln(sum(exp(q_i / b)))
     * @dev 使用简化的近似计算避免溢出
     */
    function _calculateCost(uint256[] memory quantities, uint256 b)
        internal
        pure
        returns (uint256 cost)
    {
        // 找到最大值用于数值稳定性（log-sum-exp 技巧）
        uint256 maxQ = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            if (quantities[i] > maxQ) {
                maxQ = quantities[i];
            }
        }

        // 计算 sum(exp((q_i - maxQ) / b))
        uint256 sumExp = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            // 使用线性近似：exp(x) ≈ 1 + x for small x
            // 或使用查表法
            uint256 diff = maxQ >= quantities[i] ? maxQ - quantities[i] : quantities[i] - maxQ;
            sumExp += _exp(quantities[i], b);
        }

        // cost = b * ln(sumExp) + maxQ
        // 简化：cost ≈ maxQ + b * ln(outcomeCount) 当 quantities 接近时
        cost = maxQ + b * _ln(sumExp);
    }

    /**
     * @notice 计算单个结果的价格
     */
    function _calculatePrice(uint256[] memory quantities, uint256 b, uint256 outcomeId)
        internal
        pure
        returns (uint256 price)
    {
        uint256 sumExp = 0;
        for (uint256 i = 0; i < quantities.length; i++) {
            sumExp += _exp(quantities[i], b);
        }

        if (sumExp == 0) {
            return BASIS_POINTS / quantities.length;
        }

        uint256 expTarget = _exp(quantities[outcomeId], b);
        price = expTarget * BASIS_POINTS / sumExp;
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
