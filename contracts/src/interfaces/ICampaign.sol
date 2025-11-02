// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICampaign
 * @notice 活动（Campaign）合约接口
 * @dev 用于链上注册营销活动，管理活动预算和参与记录
 *
 * 活动类型示例：
 * - 首单奖励活动
 * - 推荐奖励活动
 * - 连续下注奖励
 * - 交易量挑战赛
 *
 * 规则存储：
 * - 活动详细规则存储在链下（IPFS/Arweave）
 * - 链上只存储规则哈希（ruleHash）用于验证
 * - 奖励发放通过 RewardsDistributor 完成
 */
interface ICampaign {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice 活动状态
    enum CampaignStatus {
        Active,      // 活动进行中
        Paused,      // 已暂停
        Ended        // 已结束
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 活动信息
    struct CampaignInfo {
        bytes32 campaignId;        // 活动 ID
        string name;               // 活动名称
        bytes32 ruleHash;          // 规则哈希（IPFS CID）
        uint256 budgetCap;         // 预算上限（USDC）
        uint256 spentAmount;       // 已支出金额
        uint256 startTime;         // 开始时间
        uint256 endTime;           // 结束时间
        CampaignStatus status;     // 状态
        uint256 participantCount;  // 参与人数
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 活动创建事件
    event CampaignCreated(
        bytes32 indexed campaignId,
        string name,
        bytes32 ruleHash,
        uint256 budgetCap,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice 活动状态变更事件
    event CampaignStatusChanged(bytes32 indexed campaignId, CampaignStatus oldStatus, CampaignStatus newStatus);

    /// @notice 用户参与活动事件
    event CampaignParticipated(bytes32 indexed campaignId, address indexed user, uint256 timestamp);

    /// @notice 活动预算支出事件
    event CampaignBudgetSpent(bytes32 indexed campaignId, uint256 amount, uint256 totalSpent);

    /// @notice 活动预算增加事件
    event CampaignBudgetIncreased(bytes32 indexed campaignId, uint256 oldCap, uint256 newCap);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error CampaignAlreadyExists(bytes32 campaignId);
    error CampaignNotFound(bytes32 campaignId);
    error CampaignNotActive(bytes32 campaignId);
    error CampaignBudgetExceeded(bytes32 campaignId, uint256 required, uint256 available);
    error CampaignAlreadyEnded(bytes32 campaignId);
    error CampaignNotStarted(bytes32 campaignId);
    error InvalidTimeRange(uint256 startTime, uint256 endTime);
    error InvalidBudget(uint256 budget);
    error AlreadyParticipated(bytes32 campaignId, address user);

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 创建新活动
     * @param campaignId 活动 ID
     * @param name 活动名称
     * @param ruleHash 规则哈希（IPFS CID）
     * @param budgetCap 预算上限
     * @param startTime 开始时间
     * @param endTime 结束时间
     */
    function createCampaign(
        bytes32 campaignId,
        string calldata name,
        bytes32 ruleHash,
        uint256 budgetCap,
        uint256 startTime,
        uint256 endTime
    ) external;

    /**
     * @notice 用户参与活动
     * @param campaignId 活动 ID
     */
    function participate(bytes32 campaignId) external;

    /**
     * @notice 记录活动预算支出
     * @param campaignId 活动 ID
     * @param amount 支出金额
     */
    function recordSpending(bytes32 campaignId, uint256 amount) external;

    /**
     * @notice 暂停活动
     * @param campaignId 活动 ID
     */
    function pauseCampaign(bytes32 campaignId) external;

    /**
     * @notice 恢复活动
     * @param campaignId 活动 ID
     */
    function resumeCampaign(bytes32 campaignId) external;

    /**
     * @notice 结束活动
     * @param campaignId 活动 ID
     */
    function endCampaign(bytes32 campaignId) external;

    /**
     * @notice 增加活动预算
     * @param campaignId 活动 ID
     * @param additionalBudget 新增预算
     */
    function increaseBudget(bytes32 campaignId, uint256 additionalBudget) external;

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取活动信息
     * @param campaignId 活动 ID
     * @return info 活动信息
     */
    function getCampaignInfo(bytes32 campaignId) external view returns (CampaignInfo memory info);

    /**
     * @notice 检查用户是否已参与活动
     * @param campaignId 活动 ID
     * @param user 用户地址
     * @return participated 是否已参与
     */
    function hasParticipated(bytes32 campaignId, address user) external view returns (bool participated);

    /**
     * @notice 获取活动剩余预算
     * @param campaignId 活动 ID
     * @return remaining 剩余预算
     */
    function getRemainingBudget(bytes32 campaignId) external view returns (uint256 remaining);

    /**
     * @notice 检查活动是否活跃
     * @param campaignId 活动 ID
     * @return active 是否活跃
     */
    function isActive(bytes32 campaignId) external view returns (bool active);
}
