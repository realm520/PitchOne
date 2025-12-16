// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPricingStrategy
 * @notice 定价策略接口 - 统一的下注定价和赎回计算
 * @dev 不同的定价策略（CPMM, LMSR, Parimutuel）实现此接口
 *
 * 设计原则：
 * - 无状态/纯函数：所有计算基于传入的 state 参数
 * - 统一接口：下注和赎回使用同一套策略
 * - 可插拔：市场可以在创建时选择不同策略
 *
 * 与 IPricingEngine 的区别：
 * - IPricingEngine: 仅处理下注定价
 * - IPricingStrategy: 完整的定价+赎回逻辑
 */
interface IPricingStrategy {
    // ============ 枚举 ============

    /// @notice 赔付类型
    enum PayoutType {
        WINNER,  // 赢家赔付：按份额比例分配总池
        REFUND   // 退款：按份额比例退回本金（用于 Push）
    }

    // ============ 下注相关 ============

    /**
     * @notice 计算下注获得的份额
     * @param outcomeId 下注的结果 ID
     * @param amount 下注金额（已扣除手续费的净金额）
     * @param state 当前市场状态（编码后的 reserves 等）
     * @return shares 获得的份额
     * @return newState 更新后的状态
     * @dev 实现示例：
     *      - CPMM: state = abi.encode(uint256[] reserves)
     *      - LMSR: state = abi.encode(uint256[] quantities, uint256 b)
     *      - Parimutuel: state = abi.encode(uint256[] pools)
     */
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        bytes memory state
    ) external pure returns (uint256 shares, bytes memory newState);

    // ============ 赎回相关 ============

    /**
     * @notice 计算赎回金额
     * @param outcomeId 持有的结果 ID
     * @param shares 持有的份额
     * @param totalSharesPerOutcome 各 outcome 的总份额
     * @param totalLiquidity 总流动性（包含初始借款 + 用户下注）
     * @param payoutType 赔付类型（WINNER / REFUND）
     * @return payout 赎回金额
     *
     * @dev 计算逻辑：
     *      WINNER 模式（赢家分配）：
     *        payout = shares * totalLiquidity / totalSharesForWinningOutcome
     *
     *      REFUND 模式（退款，用于 Push）：
     *        payout = shares * originalBetAmount / totalSharesForOutcome
     *        （实际实现可能需要额外的 betAmountPerOutcome 参数）
     */
    function calculatePayout(
        uint256 outcomeId,
        uint256 shares,
        uint256[] memory totalSharesPerOutcome,
        uint256 totalLiquidity,
        PayoutType payoutType
    ) external pure returns (uint256 payout);

    /**
     * @notice 计算 REFUND 模式下的退款金额（需要原始投注信息）
     * @param outcomeId 结果 ID
     * @param shares 用户持有的份额
     * @param totalSharesForOutcome 该结果的总份额
     * @param totalBetAmountForOutcome 该结果的总投注金额
     * @return refundAmount 退款金额
     * @dev 计算公式：refundAmount = shares * totalBetAmountForOutcome / totalSharesForOutcome
     */
    function calculateRefund(
        uint256 outcomeId,
        uint256 shares,
        uint256 totalSharesForOutcome,
        uint256 totalBetAmountForOutcome
    ) external pure returns (uint256 refundAmount);

    // ============ 价格查询 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果 ID
     * @param state 当前状态
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getPrice(uint256 outcomeId, bytes memory state)
        external
        pure
        returns (uint256 price);

    /**
     * @notice 获取所有结果的价格
     * @param outcomeCount 结果数量
     * @param state 当前状态
     * @return prices 价格数组
     */
    function getAllPrices(uint256 outcomeCount, bytes memory state)
        external
        pure
        returns (uint256[] memory prices);

    // ============ 状态初始化 ============

    /**
     * @notice 获取初始状态
     * @param outcomeCount 结果数量
     * @param initialLiquidity 初始流动性
     * @return initialState 初始状态（编码后）
     * @dev 不同策略的初始化逻辑：
     *      - CPMM: reserves = [initialLiquidity/outcomeCount, ...]
     *      - LMSR: quantities = [0, ...], b = initialLiquidity / ln(outcomeCount)
     *      - Parimutuel: pools = [0, ...]（不需要初始流动性）
     */
    function getInitialState(uint256 outcomeCount, uint256 initialLiquidity)
        external
        pure
        returns (bytes memory initialState);

    // ============ 策略元数据 ============

    /**
     * @notice 策略类型标识
     * @return 策略名称，如 "CPMM", "LMSR", "PARIMUTUEL"
     */
    function strategyType() external pure returns (string memory);

    /**
     * @notice 是否需要初始流动性
     * @return true 如果需要从 Vault 借出初始流动性
     * @dev CPMM/LMSR 返回 true，Parimutuel 返回 false
     */
    function requiresInitialLiquidity() external pure returns (bool);

    /**
     * @notice 支持的最小结果数量
     * @return 最小结果数量
     */
    function minOutcomeCount() external pure returns (uint256);

    /**
     * @notice 支持的最大结果数量
     * @return 最大结果数量（0 表示无限制）
     */
    function maxOutcomeCount() external pure returns (uint256);
}
