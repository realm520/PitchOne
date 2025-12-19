// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ICorrelationGuard.sol";

/**
 * @title IBasket
 * @notice 串关（Parlay）合约接口
 * @dev 允许用户组合多个市场的结果进行串关下注
 *
 * 串关规则：
 * - 支持 2-10 场市场组合
 * - 组合赔率 = 各市场赔率相乘 × (1 - 相关性惩罚)
 * - 全中才赢，任一错误全输
 * - 集成 CorrelationGuard 进行相关性检查
 */
interface IBasket {
    // ============================================================================
    // 枚举与结构体
    // ============================================================================

    /**
     * @notice 串关状态
     * @dev Pending: 等待所有市场结算
     *      Won: 全部正确，可领取奖金
     *      Lost: 至少一个错误，无奖金
     *      Cancelled: 被取消（如市场取消）
     */
    enum ParlayStatus {
        Pending,    // 待结算
        Won,        // 赢
        Lost,       // 输
        Cancelled   // 取消
    }

    /**
     * @notice 串关数据结构
     * @param user 用户地址
     * @param legs 串关腿（市场 + 结果选择）
     * @param stake 下注金额
     * @param potentialPayout 潜在赔付金额
     * @param combinedOdds 组合赔率（基点，10000 = 1.0）
     * @param penaltyBps 相关性惩罚基点
     * @param status 状态
     * @param createdAt 创建时间
     * @param settledAt 结算时间
     */
    struct Parlay {
        address user;
        ICorrelationGuard.ParlayLeg[] legs;
        uint256 stake;
        uint256 potentialPayout;
        uint256 combinedOdds;
        uint256 penaltyBps;
        ParlayStatus status;
        uint256 createdAt;
        uint256 settledAt;
    }

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 串关创建事件
     * @param parlayId 串关ID
     * @param user 用户地址
     * @param legs 串关腿
     * @param stake 下注金额
     * @param potentialPayout 潜在赔付
     * @param combinedOdds 组合赔率
     * @param penaltyBps 惩罚基点
     */
    event ParlayCreated(
        uint256 indexed parlayId,
        address indexed user,
        ICorrelationGuard.ParlayLeg[] legs,
        uint256 stake,
        uint256 potentialPayout,
        uint256 combinedOdds,
        uint256 penaltyBps
    );

    /**
     * @notice 串关结算事件
     * @param parlayId 串关ID
     * @param user 用户地址
     * @param status 最终状态
     * @param payout 实际赔付（0 如果输了）
     */
    event ParlaySettled(
        uint256 indexed parlayId,
        address indexed user,
        ParlayStatus status,
        uint256 payout
    );

    /**
     * @notice 串关报价事件
     * @param user 用户地址
     * @param legs 串关腿
     * @param combinedOdds 组合赔率
     * @param penaltyBps 惩罚基点
     * @param potentialPayout 潜在赔付
     */
    event ParlayQuoted(
        address indexed user,
        ICorrelationGuard.ParlayLeg[] legs,
        uint256 combinedOdds,
        uint256 penaltyBps,
        uint256 potentialPayout
    );

    /**
     * @notice CorrelationGuard 更新事件
     * @param oldGuard 旧守卫地址
     * @param newGuard 新守卫地址
     */
    event CorrelationGuardUpdated(address indexed oldGuard, address indexed newGuard);

    /**
     * @notice 最大串关腿数更新事件
     * @param oldMax 旧最大值
     * @param newMax 新最大值
     */
    event MaxLegsUpdated(uint256 oldMax, uint256 newMax);

    /**
     * @notice 最小/最大赔率更新事件
     * @param minOdds 最小赔率
     * @param maxOdds 最大赔率
     */
    event OddsLimitsUpdated(uint256 minOdds, uint256 maxOdds);

    // ============================================================================
    // 只读函数
    // ============================================================================

    /**
     * @notice 获取串关信息
     * @param parlayId 串关ID
     * @return parlay 串关数据
     */
    function getParlay(uint256 parlayId) external view returns (Parlay memory parlay);

    /**
     * @notice 获取用户的所有串关ID
     * @param user 用户地址
     * @return parlayIds 串关ID数组
     */
    function getUserParlays(address user) external view returns (uint256[] memory parlayIds);

    /**
     * @notice 报价：计算组合赔率和潜在赔付
     * @param legs 串关腿
     * @param stake 下注金额
     * @return combinedOdds 组合赔率（基点）
     * @return penaltyBps 相关性惩罚基点
     * @return potentialPayout 潜在赔付金额
     */
    function quote(ICorrelationGuard.ParlayLeg[] calldata legs, uint256 stake)
        external
        view
        returns (
            uint256 combinedOdds,
            uint256 penaltyBps,
            uint256 potentialPayout
        );

    /**
     * @notice 检查串关是否可结算
     * @param parlayId 串关ID
     * @return canSettle 是否可结算
     * @return status 预期状态（Won/Lost/Cancelled）
     */
    function canSettle(uint256 parlayId)
        external
        view
        returns (bool canSettle, ParlayStatus status);

    // ============================================================================
    // 写入函数
    // ============================================================================

    /**
     * @notice 创建串关
     * @param legs 串关腿数组
     * @param stake 下注金额
     * @param minPayout 最小赔付金额（滑点保护）
     * @return parlayId 串关ID
     */
    function createParlay(
        ICorrelationGuard.ParlayLeg[] calldata legs,
        uint256 stake,
        uint256 minPayout
    ) external returns (uint256 parlayId);

    /**
     * @notice 结算串关（任何人可调用，自动判断输赢）
     * @param parlayId 串关ID
     * @return payout 赔付金额
     */
    function settleParlay(uint256 parlayId) external returns (uint256 payout);

    /**
     * @notice 批量结算串关
     * @param parlayIds 串关ID数组
     */
    function batchSettle(uint256[] calldata parlayIds) external;

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 设置 CorrelationGuard（仅 owner）
     * @param newGuard 新守卫地址
     */
    function setCorrelationGuard(address newGuard) external;

    /**
     * @notice 设置最大串关腿数（仅 owner）
     * @param newMax 新最大值
     */
    function setMaxLegs(uint256 newMax) external;

    /**
     * @notice 设置赔率限制（仅 owner）
     * @param minOdds 最小赔率（基点）
     * @param maxOdds 最大赔率（基点）
     */
    function setOddsLimits(uint256 minOdds, uint256 maxOdds) external;

    // ============================================================================
    // 错误定义
    // ============================================================================

    /// @notice 无效的腿数（少于2或超过最大值）
    error InvalidLegCount(uint256 count, uint256 min, uint256 max);

    /// @notice 串关被相关性守卫阻断
    error ParlayBlocked(string reason);

    /// @notice 组合赔率超出限制
    error OddsOutOfBounds(uint256 odds, uint256 min, uint256 max);

    /// @notice 滑点过大（实际赔付低于最小值）
    error SlippageExceeded(uint256 actualPayout, uint256 minPayout);

    /// @notice 串关尚未可结算（市场未结算）
    error NotReadyToSettle(uint256 parlayId);

    /// @notice 串关已结算
    error AlreadySettled(uint256 parlayId);

    /// @notice 无效的串关ID
    error InvalidParlayId(uint256 parlayId);

    /// @notice 市场状态无效（未锁盘或未结算）
    error InvalidMarketStatus(address market, uint8 status);

    /// @notice 零金额
    error ZeroAmount();

    /// @notice 未授权的操作
    error Unauthorized();

    /// @notice 资金不足
    error InsufficientFunds(uint256 required, uint256 available);

    /// @notice 有活跃串关时无法提取储备金
    error CannotWithdrawWhileParlaysActive();

    /// @notice 储备金不足
    error InsufficientReserveFund(uint256 requested, uint256 available);

    /// @notice 用户敞口超限
    error UserExposureExceeded(address user, uint256 newExposure, uint256 limit);

    /// @notice 平台敞口超限
    error PlatformExposureExceeded(uint256 newExposure, uint256 limit);

    /// @notice 储备金覆盖不足
    error InsufficientReserveCapacity(uint256 availableFunds, uint256 requiredReserve);
}
