// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICorrelationGuard
 * @notice 相关性守卫接口 - 检测串关中的相关性并应用惩罚或阻断
 * @dev 用于 Basket（串关）合约，防止高度相关的组合下注
 *
 * 相关性规则示例：
 * - 同场同向（如曼联赢 + 大2.5球）：赔率折扣 10-30%
 * - 同场强相关（如曼联赢 + OU大）：可能阻断或高惩罚
 * - 不同场：无惩罚
 */
interface ICorrelationGuard {
    // ============================================================================
    // 枚举与结构体
    // ============================================================================

    /**
     * @notice 相关性策略
     * @dev ALLOW_ALL: 允许所有组合，无惩罚
     *      PENALTY: 应用赔率惩罚（降低组合赔率）
     *      STRICT_BLOCK: 严格阻断相关组合
     */
    enum CorrelationPolicy {
        ALLOW_ALL,      // 允许所有组合
        PENALTY,        // 应用惩罚
        STRICT_BLOCK    // 严格阻断
    }

    /**
     * @notice 串关腿（单个市场选择）
     * @param market 市场合约地址
     * @param outcomeId 选择的结果ID
     */
    struct ParlayLeg {
        address market;
        uint256 outcomeId;
    }

    /**
     * @notice 相关性规则
     * @param matchId1 比赛1 ID
     * @param matchId2 比赛2 ID
     * @param penaltyBps 惩罚基点（10000 = 100%，例如 2000 = 20% 惩罚）
     * @param isBlocked 是否完全阻断
     */
    struct CorrelationRule {
        bytes32 matchId1;
        bytes32 matchId2;
        uint256 penaltyBps;
        bool isBlocked;
    }

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 相关性策略更新事件
     * @param oldPolicy 旧策略
     * @param newPolicy 新策略
     */
    event PolicyUpdated(CorrelationPolicy indexed oldPolicy, CorrelationPolicy indexed newPolicy);

    /**
     * @notice 相关性规则更新事件
     * @param matchId1 比赛1 ID
     * @param matchId2 比赛2 ID
     * @param penaltyBps 惩罚基点
     * @param isBlocked 是否阻断
     */
    event CorrelationRuleSet(
        bytes32 indexed matchId1,
        bytes32 indexed matchId2,
        uint256 penaltyBps,
        bool isBlocked
    );

    /**
     * @notice 默认惩罚更新事件
     * @param sameMatchPenalty 同场惩罚基点
     */
    event DefaultPenaltyUpdated(uint256 sameMatchPenalty);

    /**
     * @notice 串关被阻断事件
     * @param user 用户地址
     * @param reason 阻断原因
     */
    event ParlayBlocked(address indexed user, string reason);

    // ============================================================================
    // 只读函数
    // ============================================================================

    /**
     * @notice 获取当前策略
     * @return policy 相关性策略
     */
    function getPolicy() external view returns (CorrelationPolicy policy);

    /**
     * @notice 检查串关是否被阻断
     * @param legs 串关腿数组
     * @return isBlocked 是否被阻断
     * @return reason 阻断原因（如果被阻断）
     */
    function checkBlocked(ParlayLeg[] calldata legs)
        external
        view
        returns (bool isBlocked, string memory reason);

    /**
     * @notice 计算相关性惩罚
     * @param legs 串关腿数组
     * @return totalPenaltyBps 总惩罚基点（累积）
     * @return details 每对腿之间的惩罚详情
     */
    function calculatePenalty(ParlayLeg[] calldata legs)
        external
        view
        returns (uint256 totalPenaltyBps, uint256[] memory details);

    /**
     * @notice 获取两个比赛之间的相关性规则
     * @param matchId1 比赛1 ID
     * @param matchId2 比赛2 ID
     * @return penaltyBps 惩罚基点
     * @return isBlocked 是否阻断
     */
    function getCorrelationRule(bytes32 matchId1, bytes32 matchId2)
        external
        view
        returns (uint256 penaltyBps, bool isBlocked);

    /**
     * @notice 从市场地址获取比赛ID
     * @param market 市场合约地址
     * @return matchId 比赛ID（哈希）
     */
    function getMatchId(address market) external view returns (bytes32 matchId);

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 设置相关性策略（仅 owner）
     * @param newPolicy 新策略
     */
    function setPolicy(CorrelationPolicy newPolicy) external;

    /**
     * @notice 设置相关性规则（仅 owner 或 authorized）
     * @param matchId1 比赛1 ID
     * @param matchId2 比赛2 ID
     * @param penaltyBps 惩罚基点
     * @param isBlocked 是否阻断
     */
    function setCorrelationRule(
        bytes32 matchId1,
        bytes32 matchId2,
        uint256 penaltyBps,
        bool isBlocked
    ) external;

    /**
     * @notice 批量设置相关性规则（仅 owner 或 authorized）
     * @param rules 规则数组
     */
    function batchSetRules(CorrelationRule[] calldata rules) external;

    /**
     * @notice 设置默认同场惩罚（仅 owner）
     * @param penaltyBps 惩罚基点
     */
    function setDefaultSameMatchPenalty(uint256 penaltyBps) external;

    // ============================================================================
    // 错误定义
    // ============================================================================

    /// @notice 串关被阻断（相关性冲突）
    error ParlayBlockedByCorrelation(string reason);

    /// @notice 无效的策略
    error InvalidPolicy();

    /// @notice 无效的惩罚值（超过100%）
    error InvalidPenalty(uint256 penaltyBps);

    /// @notice 无效的腿数（少于2个）
    error InvalidLegCount(uint256 count);

    /// @notice 未授权的操作
    error Unauthorized();
}
