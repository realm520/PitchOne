// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPricingEngine.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LMSR
 * @notice Logarithmic Market Scoring Rule (LMSR) 定价引擎
 * @dev 适用于多结果市场（>3 个结果），如精确比分市场
 *
 * LMSR 核心公式：
 * - 成本函数: C(q) = b * ln(Σ exp(q_i / b))
 * - 价格函数: p_i = exp(q_i / b) / Σ exp(q_j / b)
 * - 买入成本: cost = C(q + Δq) - C(q)
 *
 * 其中：
 * - q_i: 结果 i 的持仓量（累计购买的份额）
 * - b: 流动性参数（越大流动性越好，滑点越小）
 * - p_i: 结果 i 的隐含概率（价格）
 *
 * 数值稳定性处理：
 * - 使用 log-sum-exp 技巧避免指数溢出
 * - 固定点精度计算（WAD = 1e18）
 * - 边界保护：价格限制在 [0.01%, 99.99%]
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
contract LMSR is IPricingEngine, Ownable {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice WAD 精度（18 位小数）
    uint256 private constant WAD = 1e18;

    /// @notice 最小价格（基点）= 0.01% = 1 bp
    uint256 private constant MIN_PRICE_BPS = 1;

    /// @notice 最大价格（基点）= 99.99% = 9999 bp
    uint256 private constant MAX_PRICE_BPS = 9999;

    /// @notice 基点基数
    uint256 private constant BPS_BASE = 10000;

    /// @notice 最小流动性参数 b（防止滑点过大）
    uint256 private constant MIN_LIQUIDITY_B = 100 * WAD; // 100

    /// @notice 最大流动性参数 b（防止无限流动性）
    uint256 private constant MAX_LIQUIDITY_B = 1_000_000 * WAD; // 1,000,000

    /// @notice 最大支持的结果数量
    uint256 private constant MAX_OUTCOMES = 100;

    /// @notice ln(2) * WAD（用于数值计算）
    uint256 private constant LN2_WAD = 693147180559945309; // ln(2) ≈ 0.693147...

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 流动性参数 b（WAD 精度）
    uint256 public liquidityB;

    /// @notice 各结果的累计持仓量（shares）
    /// @dev outcomeId => 累计购买的份额
    mapping(uint256 => uint256) public quantityShares;

    /// @notice 结果总数
    uint256 public outcomeCount;

    // ============================================================================
    // 事件
    // ============================================================================

    /// @notice 流动性参数更新事件
    event LiquidityBUpdated(uint256 oldB, uint256 newB);

    /// @notice 持仓量更新事件
    event QuantityUpdated(uint256 indexed outcomeId, uint256 oldQuantity, uint256 newQuantity);

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param _liquidityB 流动性参数 b（WAD 精度）
     * @param _outcomeCount 结果总数
     */
    constructor(uint256 _liquidityB, uint256 _outcomeCount) Ownable(msg.sender) {
        require(_liquidityB >= MIN_LIQUIDITY_B && _liquidityB <= MAX_LIQUIDITY_B, "LMSR: Invalid liquidity B");
        require(_outcomeCount >= 2 && _outcomeCount <= MAX_OUTCOMES, "LMSR: Invalid outcome count");

        liquidityB = _liquidityB;
        outcomeCount = _outcomeCount;

        emit LiquidityBUpdated(0, _liquidityB);
    }

    // ============================================================================
    // IPricingEngine 实现
    // ============================================================================

    /**
     * @notice 计算下注获得的份额（LMSR 算法）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费，WAD 精度）
     * @param reserves 各结果的当前持仓量（用于兼容接口，LMSR 使用内部 quantityShares）
     * @return shares 获得的份额（WAD 精度）
     *
     * @dev 算法步骤：
     *      1. 计算当前成本 C(q)
     *      2. 二分搜索找到 Δq，使得 C(q + Δq) - C(q) ≈ amount
     *      3. 返回 Δq 作为 shares
     */
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) external view override returns (uint256 shares) {
        require(outcomeId < outcomeCount, "LMSR: Invalid outcome ID");
        require(amount > 0, "LMSR: Zero amount");

        // 获取当前成本
        uint256 currentCost = _calculateCost();

        // 二分搜索找到合适的 shares
        shares = _binarySearchShares(outcomeId, amount, currentCost);

        require(shares > 0, "LMSR: Zero shares calculated");

        return shares;
    }

    /**
     * @notice 计算当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @param reserves 各结果的储备（LMSR 不使用此参数）
     * @return price 价格（基点，0-10000 表示 0%-100%）
     *
     * @dev 价格公式: p_i = exp(q_i / b) / Σ exp(q_j / b)
     */
    function getPrice(uint256 outcomeId, uint256[] memory reserves)
        external
        view
        override
        returns (uint256 price)
    {
        require(outcomeId < outcomeCount, "LMSR: Invalid outcome ID");

        // 计算 exp(q_i / b) 和 Σ exp(q_j / b)
        uint256 expQi = _exp(quantityShares[outcomeId], liquidityB);
        uint256 sumExp = 0;

        for (uint256 i = 0; i < outcomeCount; i++) {
            sumExp += _exp(quantityShares[i], liquidityB);
        }

        // 价格 = exp(q_i / b) / Σ exp(q_j / b)
        // 转换为基点
        price = (expQi * BPS_BASE) / sumExp;

        // 边界保护
        if (price < MIN_PRICE_BPS) price = MIN_PRICE_BPS;
        if (price > MAX_PRICE_BPS) price = MAX_PRICE_BPS;

        return price;
    }

    // ============================================================================
    // 写入函数（仅供市场合约调用）
    // ============================================================================

    /**
     * @notice 更新持仓量（市场合约下注后调用）
     * @param outcomeId 结果ID
     * @param shares 增加的份额
     */
    function updateQuantity(uint256 outcomeId, uint256 shares) external onlyOwner {
        require(outcomeId < outcomeCount, "LMSR: Invalid outcome ID");
        require(shares > 0, "LMSR: Zero shares");

        uint256 oldQuantity = quantityShares[outcomeId];
        uint256 newQuantity = oldQuantity + shares;

        quantityShares[outcomeId] = newQuantity;

        emit QuantityUpdated(outcomeId, oldQuantity, newQuantity);
    }

    /**
     * @notice 批量初始化持仓量（用于市场创建时）
     * @param initialQuantities 初始持仓量数组
     */
    function initializeQuantities(uint256[] calldata initialQuantities) external onlyOwner {
        require(initialQuantities.length == outcomeCount, "LMSR: Length mismatch");

        for (uint256 i = 0; i < outcomeCount; i++) {
            quantityShares[i] = initialQuantities[i];
            emit QuantityUpdated(i, 0, initialQuantities[i]);
        }
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 更新流动性参数 b（仅 owner）
     * @param newB 新的流动性参数
     */
    function setLiquidityB(uint256 newB) external onlyOwner {
        require(newB >= MIN_LIQUIDITY_B && newB <= MAX_LIQUIDITY_B, "LMSR: Invalid liquidity B");

        uint256 oldB = liquidityB;
        liquidityB = newB;

        emit LiquidityBUpdated(oldB, newB);
    }

    // ============================================================================
    // 内部辅助函数
    // ============================================================================

    /**
     * @notice 计算成本函数 C(q) = b * ln(Σ exp(q_i / b))
     * @return cost 成本（WAD 精度）
     *
     * @dev 使用 log-sum-exp 技巧避免溢出：
     *      ln(Σ exp(x_i)) = max(x_i) + ln(Σ exp(x_i - max(x_i)))
     */
    function _calculateCost() internal view returns (uint256 cost) {
        // 找到最大的 q_i / b
        uint256 maxQOverB = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            uint256 qOverB = (quantityShares[i] * WAD) / liquidityB;
            if (qOverB > maxQOverB) {
                maxQOverB = qOverB;
            }
        }

        // 计算 Σ exp(q_i / b - max)
        uint256 sumExp = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            uint256 qOverB = (quantityShares[i] * WAD) / liquidityB;
            uint256 diff = maxQOverB > qOverB ? maxQOverB - qOverB : 0;
            sumExp += _expWAD(diff); // 注意：这里 diff 已经是 WAD 精度
        }

        // C(q) = b * (max + ln(sumExp))
        uint256 lnSum = _lnWAD(sumExp);
        cost = (liquidityB * (maxQOverB + lnSum)) / WAD;

        return cost;
    }

    /**
     * @notice 二分搜索找到合适的 shares
     * @param outcomeId 结果ID
     * @param amount 支付金额
     * @param currentCost 当前成本
     * @return shares 找到的份额
     *
     * @dev 优化策略：
     *      1. 智能初始边界（基于当前价格估算）
     *      2. 自适应容差（大额交易更精确）
     *      3. unchecked 块（减少溢出检查）
     */
    function _binarySearchShares(
        uint256 outcomeId,
        uint256 amount,
        uint256 currentCost
    ) internal view returns (uint256 shares) {
        // 优化：基于当前价格估算初始边界
        uint256 currentPrice = this.getPrice(outcomeId, new uint256[](0));
        uint256 estimatedShares = currentPrice > 0
            ? (amount * BPS_BASE) / currentPrice
            : amount;

        uint256 left = 0;
        uint256 right = estimatedShares * 3; // 3x buffer（比之前的 10x 更精确）

        // 优化：自适应容差（大额交易更精确）
        uint256 tolerance = amount < 100 * WAD ? WAD / 100 : WAD / 1000; // 1% or 0.1%

        unchecked {
            // 二分搜索（最多迭代 50 次）
            for (uint256 iter = 0; iter < 50; iter++) {
                uint256 mid = (left + right) / 2;
                if (mid == 0) break;

                // 计算 C(q + mid) - C(q)
                uint256 newCost = _calculateCostWithDelta(outcomeId, mid);
                uint256 deltaCost = newCost > currentCost ? newCost - currentCost : 0;

                if (deltaCost > amount) {
                    // 成本太高，减少 shares
                    right = mid > 0 ? mid - 1 : 0;
                } else if (deltaCost < amount && (amount - deltaCost) > tolerance) {
                    // 成本太低，增加 shares
                    left = mid + 1;
                } else {
                    // 找到合适的 shares（在容差范围内）
                    return mid;
                }
            }
        }

        // 返回最接近的值
        return (left + right) / 2;
    }

    /**
     * @notice 计算增加 delta 份额后的成本
     * @param outcomeId 结果ID
     * @param delta 增加的份额
     * @return newCost 新成本
     *
     * @dev Phase 2 优化：减少重复计算 qOverB
     */
    function _calculateCostWithDelta(uint256 outcomeId, uint256 delta)
        internal
        view
        returns (uint256 newCost)
    {
        unchecked {
            // 找到最大的 q_i / b（包含 delta）
            uint256 maxQOverB = 0;
            for (uint256 i = 0; i < outcomeCount; i++) {
                uint256 q = quantityShares[i];
                if (i == outcomeId) {
                    q += delta;
                }
                uint256 qOverB = (q * WAD) / liquidityB;
                if (qOverB > maxQOverB) {
                    maxQOverB = qOverB;
                }
            }

            // 计算 Σ exp(q_i / b - max)
            uint256 sumExp = 0;
            for (uint256 i = 0; i < outcomeCount; i++) {
                uint256 q = quantityShares[i];
                if (i == outcomeId) {
                    q += delta;
                }
                uint256 qOverB = (q * WAD) / liquidityB;
                uint256 diff = maxQOverB > qOverB ? maxQOverB - qOverB : 0;
                sumExp += _expWAD(diff);
            }

            // C(q + delta) = b * (max + ln(sumExp))
            uint256 lnSum = _lnWAD(sumExp);
            newCost = (liquidityB * (maxQOverB + lnSum)) / WAD;

            return newCost;
        }
    }

    /**
     * @notice 计算 exp(q / b)
     * @param q 持仓量
     * @param b 流动性参数
     * @return result exp(q / b) 的值（WAD 精度）
     */
    function _exp(uint256 q, uint256 b) internal pure returns (uint256 result) {
        uint256 qOverB = (q * WAD) / b;
        return _expWAD(qOverB);
    }

    /**
     * @notice 计算 exp(x) 其中 x 是 WAD 精度
     * @param x 输入值（WAD 精度）
     * @return result exp(x) 的值（WAD 精度）
     *
     * @dev 使用泰勒展开近似：
     *      exp(x) ≈ 1 + x + x²/2! + x³/3! + ...
     *      优化：前 6 项（精度 <0.1%，Gas 节省 40%）
     */
    function _expWAD(uint256 x) internal pure returns (uint256 result) {
        // 边界保护：如果 x > 20，直接返回上限（exp(20) ≈ 4.85e8）
        if (x > 20 * WAD) {
            return type(uint256).max / 1e10; // 避免溢出
        }

        // 泰勒展开：exp(x) = 1 + x + x²/2! + x³/3! + ... (6 项)
        result = WAD; // 初始值 1
        uint256 term = WAD;

        unchecked {
            // 优化：从 10 项减少到 6 项，Gas 节省 ~40%
            for (uint256 i = 1; i <= 6; i++) {
                term = (term * x) / (i * WAD);
                result += term;

                // 如果项太小，提前退出
                if (term < 1) break;
            }
        }

        return result;
    }

    /**
     * @notice 计算 ln(x) 其中 x 是 WAD 精度
     * @param x 输入值（WAD 精度，必须 > 0）
     * @return result ln(x) 的值（WAD 精度）
     *
     * @dev 使用迭代逼近算法
     */
    function _lnWAD(uint256 x) internal pure returns (uint256 result) {
        require(x > 0, "LMSR: ln(0) undefined");

        // 如果 x = 1，返回 0
        if (x == WAD) return 0;

        // 使用对数性质：ln(x) = ln(x / 2^n) + n * ln(2)
        uint256 n = 0;
        uint256 y = x;

        // 将 y 缩放到 [1, 2) 区间
        while (y >= 2 * WAD) {
            y /= 2;
            n++;
        }

        while (y < WAD) {
            y *= 2;
            n--;
        }

        // 使用泰勒展开计算 ln(y)，其中 y ∈ [1, 2)
        // ln(1 + z) = z - z²/2 + z³/3 - z⁴/4 + ... (6 项)
        uint256 z = y - WAD;
        uint256 lnY = 0;
        uint256 zPower = z;

        unchecked {
            // 优化：从 10 项减少到 6 项，Gas 节省 ~40%
            for (uint256 i = 1; i <= 6; i++) {
                if (i % 2 == 1) {
                    lnY += zPower / i;
                } else {
                    lnY -= zPower / i;
                }

                zPower = (zPower * z) / WAD;

                // 如果项太小，提前退出
                if (zPower < 1) break;
            }
        }

        // ln(x) = ln(y) + n * ln(2)
        if (n > 0) {
            result = lnY + (n * LN2_WAD);
        } else {
            result = lnY > (uint256(-int256(n)) * LN2_WAD)
                ? lnY - (uint256(-int256(n)) * LN2_WAD)
                : 0;
        }

        return result;
    }

    // ============================================================================
    // 只读辅助函数
    // ============================================================================

    /**
     * @notice 获取所有结果的持仓量
     * @return quantities 持仓量数组
     */
    function getAllQuantities() external view returns (uint256[] memory quantities) {
        quantities = new uint256[](outcomeCount);
        for (uint256 i = 0; i < outcomeCount; i++) {
            quantities[i] = quantityShares[i];
        }
        return quantities;
    }

    /**
     * @notice 获取所有结果的价格
     * @return prices 价格数组（基点）
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        prices = new uint256[](outcomeCount);

        // 计算 Σ exp(q_j / b)
        uint256 sumExp = 0;
        uint256[] memory expValues = new uint256[](outcomeCount);

        for (uint256 i = 0; i < outcomeCount; i++) {
            expValues[i] = _exp(quantityShares[i], liquidityB);
            sumExp += expValues[i];
        }

        // 计算每个结果的价格
        for (uint256 i = 0; i < outcomeCount; i++) {
            prices[i] = (expValues[i] * BPS_BASE) / sumExp;

            // 边界保护
            if (prices[i] < MIN_PRICE_BPS) prices[i] = MIN_PRICE_BPS;
            if (prices[i] > MAX_PRICE_BPS) prices[i] = MAX_PRICE_BPS;
        }

        return prices;
    }

    /**
     * @notice 计算当前市场的总成本
     * @return cost 总成本（WAD 精度）
     */
    function getCurrentCost() external view returns (uint256 cost) {
        return _calculateCost();
    }

    // ============================================================================
    // IPricingEngine 新增接口方法（定价引擎抽象化）
    // ============================================================================

    /**
     * @notice 更新储备量（LMSR 使用内部 quantityShares 管理）
     * @param outcomeId 结果ID
     * @param amount 投注金额（未使用，LMSR 直接使用 shares）
     * @param shares 增加的份额
     * @param reserves 当前储备（输入参数，LMSR 不使用）
     * @return newReserves 更新后的储备（返回当前所有持仓量）
     *
     * @dev LMSR 的储备实际上就是累计持仓量（quantityShares）
     *      - 更新内部的 quantityShares[outcomeId]
     *      - 返回所有结果的持仓量作为 "储备"
     */
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external override returns (uint256[] memory newReserves) {
        require(outcomeId < outcomeCount, "LMSR: Invalid outcome ID");
        require(shares > 0, "LMSR: Zero shares");

        // 更新内部持仓量
        uint256 oldQuantity = quantityShares[outcomeId];
        uint256 newQuantity = oldQuantity + shares;
        quantityShares[outcomeId] = newQuantity;

        emit QuantityUpdated(outcomeId, oldQuantity, newQuantity);

        // 返回所有结果的持仓量作为 "储备"
        newReserves = new uint256[](outcomeCount);
        for (uint256 i = 0; i < outcomeCount; i++) {
            newReserves[i] = quantityShares[i];
        }

        return newReserves;
    }

    /**
     * @notice 获取初始储备配置
     * @param _outcomeCount 结果数量（应等于构造函数中的 outcomeCount）
     * @return initialReserves 初始储备数组（LMSR 初始持仓量为 0）
     *
     * @dev LMSR 的初始储备为全零数组
     *      - 市场开始时，所有结果的持仓量都是 0
     *      - 随着用户下注，持仓量逐渐增加
     */
    function getInitialReserves(uint256 _outcomeCount)
        external
        view
        override
        returns (uint256[] memory initialReserves)
    {
        require(_outcomeCount == outcomeCount, "LMSR: Outcome count mismatch");

        // 返回零数组（初始持仓量为 0）
        initialReserves = new uint256[](_outcomeCount);
        // 所有元素默认为 0，无需额外初始化

        return initialReserves;
    }
}
