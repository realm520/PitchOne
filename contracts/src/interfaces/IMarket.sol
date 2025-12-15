// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMarket
 * @notice 市场合约核心接口
 * @dev 定义市场的状态机、关键函数和事件
 */
interface IMarket {
    // ============ 枚举 ============

    /// @notice 市场状态
    enum MarketStatus {
        Open,      // 开放下注
        Locked,    // 锁盘（比赛进行中）
        Resolved,  // 已结算（预言机上报结果）
        Finalized, // 已终结（争议期结束）
        Cancelled  // 已取消（比赛取消/无效）
    }

    // ============ 事件 ============

    /// @notice 下注事件
    /// @param user 用户地址
    /// @param outcomeId 结果ID（ERC-1155 token ID）
    /// @param amount 下注金额（稳定币）
    /// @param shares 获得的份额（position token数量）
    /// @param fee 手续费
    event BetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    /// @notice 锁盘事件
    /// @param timestamp 锁盘时间
    event Locked(uint256 timestamp);

    /// @notice 结算事件
    /// @param winningOutcome 获胜结果ID
    /// @param timestamp 结算时间
    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);

    /// @notice 终结事件（争议期结束）
    /// @param timestamp 终结时间
    event Finalized(uint256 timestamp);

    /// @notice 取消事件（比赛取消/无效）
    /// @param reason 取消原因
    /// @param timestamp 取消时间
    event Cancelled(string reason, uint256 timestamp);

    /// @notice 退款事件（用户领取退款）
    /// @param user 用户地址
    /// @param outcomeId 结果ID
    /// @param shares 退款份额
    /// @param amount 退款金额
    event Refunded(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 amount
    );

    /// @notice 赎回事件
    /// @param user 用户地址
    /// @param outcomeId 结果ID
    /// @param shares 赎回份额
    /// @param payout 赔付金额
    event Redeemed(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 payout
    );

    /// @notice 折扣预言机更新事件
    /// @param oldOracle 旧预言机地址
    /// @param newOracle 新预言机地址
    event DiscountOracleUpdated(address indexed oldOracle, address indexed newOracle);

    /// @notice 结果预言机更新事件
    /// @param newOracle 新预言机地址
    event ResultOracleUpdated(address indexed newOracle);

    /// @notice 通过预言机结算事件
    /// @param winningOutcome 获胜结果ID
    /// @param resultHash 结果哈希（来自预言机）
    /// @param timestamp 结算时间
    event ResolvedWithOracle(
        uint256 indexed winningOutcome,
        bytes32 indexed resultHash,
        uint256 timestamp
    );

    /// @notice 流动性添加事件
    /// @param provider 流动性提供者地址
    /// @param totalAmount 总金额
    /// @param timestamp 添加时间
    event LiquidityAdded(
        address indexed provider,
        uint256 totalAmount,
        uint256 timestamp
    );

    // ============ 只读函数 ============

    /// @notice 获取市场状态
    function status() external view returns (MarketStatus);

    /// @notice 获取结果数量（如 WDL 有3个结果）
    function outcomeCount() external view returns (uint256);

    /// @notice 获取获胜结果ID（仅在 Resolved/Finalized 状态有效）
    function winningOutcome() external view returns (uint256);

    /// @notice 获取用户在某结果上的持仓
    /// @param user 用户地址
    /// @param outcomeId 结果ID
    function getUserPosition(address user, uint256 outcomeId) external view returns (uint256);

    /// @notice 计算手续费（考虑折扣）
    /// @param user 用户地址
    /// @param amount 金额
    function calculateFee(address user, uint256 amount) external view returns (uint256);

    // ============ 写入函数 ============

    /// @notice 下注
    /// @param outcomeId 结果ID
    /// @param amount 金额（稳定币）
    /// @return shares 获得的份额
    function placeBet(uint256 outcomeId, uint256 amount) external returns (uint256 shares);

    /// @notice 锁盘（管理员/Keeper）
    function lock() external;

    /// @notice 结算（预言机上报）
    /// @param winningOutcomeId 获胜结果ID
    function resolve(uint256 winningOutcomeId) external;

    /// @notice 终结（争议期结束后）
    function finalize() external;

    /// @notice 取消市场（比赛取消/无效）
    /// @param reason 取消原因
    function cancel(string calldata reason) external;

    /// @notice 退款（用户领取退款，仅 Cancelled 状态）
    /// @param outcomeId 结果ID
    /// @param shares 份额
    /// @return amount 退款金额
    function refund(uint256 outcomeId, uint256 shares) external returns (uint256 amount);

    /// @notice 赎回
    /// @param outcomeId 结果ID
    /// @param shares 份额
    /// @return payout 赔付金额
    function redeem(uint256 outcomeId, uint256 shares) external returns (uint256 payout);

    /// @notice 添加流动性（仅 owner）
    /// @param totalAmount 总金额（将按权重分配到各 outcome）
    /// @param weights 每个 outcome 的权重（如果为空，则均分）
    function addLiquidity(uint256 totalAmount, uint256[] calldata weights) external;

    // ============ Router 集成 ============

    /// @notice 获取受信任的 Router 地址
    /// @return Router 合约地址
    function trustedRouter() external view returns (address);

    /// @notice 设置受信任的 Router（仅 owner）
    /// @param _router Router 合约地址
    function setTrustedRouter(address _router) external;
}
