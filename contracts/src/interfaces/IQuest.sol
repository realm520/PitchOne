// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IQuest
 * @notice 任务（Quest）合约接口
 * @dev 用于链上注册和验证用户任务完成情况
 *
 * 任务类型：
 * - FIRST_BET: 首次下注
 * - CONSECUTIVE_BETS: 连续下注（如连续 7 天下注）
 * - REFERRAL: 推荐任务（推荐 N 个有效用户）
 * - VOLUME: 累计交易量达标
 * - WIN_STREAK: 连续 N 次盈利
 *
 * 任务流程：
 * 1. 管理员创建任务（关联 Campaign）
 * 2. 用户完成任务条件
 * 3. 合约验证完成状态
 * 4. 用户领取奖励（通过 RewardsDistributor 或 Credit/Coupon）
 */
interface IQuest {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice 任务类型
    enum QuestType {
        FIRST_BET,          // 首次下注
        CONSECUTIVE_BETS,   // 连续下注
        REFERRAL,           // 推荐任务
        VOLUME,             // 交易量达标
        WIN_STREAK          // 连胜
    }

    /// @notice 任务状态
    enum QuestStatus {
        Active,    // 进行中
        Paused,    // 已暂停
        Ended      // 已结束
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 任务信息
    struct QuestInfo {
        bytes32 questId;           // 任务 ID
        bytes32 campaignId;        // 关联的活动 ID
        QuestType questType;       // 任务类型
        string name;               // 任务名称
        uint256 rewardAmount;      // 奖励金额
        uint256 targetValue;       // 目标值（如交易量、推荐人数、连续天数）
        uint256 startTime;         // 开始时间
        uint256 endTime;           // 结束时间
        QuestStatus status;        // 状态
        uint256 completionCount;   // 完成人数
    }

    /// @notice 用户任务进度
    struct UserQuestProgress {
        uint256 currentValue;      // 当前进度值
        uint256 lastUpdateTime;    // 最后更新时间
        bool completed;            // 是否完成
        bool rewardClaimed;        // 奖励是否已领取
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 任务创建事件
    event QuestCreated(
        bytes32 indexed questId,
        bytes32 indexed campaignId,
        QuestType questType,
        string name,
        uint256 rewardAmount,
        uint256 targetValue,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice 任务进度更新事件
    event QuestProgressUpdated(
        bytes32 indexed questId, address indexed user, uint256 currentValue, uint256 targetValue
    );

    /// @notice 任务完成事件
    event QuestCompleted(bytes32 indexed questId, address indexed user, uint256 timestamp);

    /// @notice 奖励领取事件
    event QuestRewardClaimed(bytes32 indexed questId, address indexed user, uint256 rewardAmount);

    /// @notice 任务状态变更事件
    event QuestStatusChanged(bytes32 indexed questId, QuestStatus oldStatus, QuestStatus newStatus);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error QuestAlreadyExists(bytes32 questId);
    error QuestNotFound(bytes32 questId);
    error QuestNotActive(bytes32 questId);
    error QuestNotCompleted(bytes32 questId, address user);
    error QuestAlreadyCompleted(bytes32 questId, address user);
    error RewardAlreadyClaimed(bytes32 questId, address user);
    error InvalidQuestType(QuestType questType);
    error InvalidTargetValue(uint256 targetValue);
    error CampaignNotActive(bytes32 campaignId);

    /*//////////////////////////////////////////////////////////////
                            WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 创建新任务
     * @param questId 任务 ID
     * @param campaignId 关联的活动 ID
     * @param questType 任务类型
     * @param name 任务名称
     * @param rewardAmount 奖励金额
     * @param targetValue 目标值
     * @param startTime 开始时间
     * @param endTime 结束时间
     */
    function createQuest(
        bytes32 questId,
        bytes32 campaignId,
        QuestType questType,
        string calldata name,
        uint256 rewardAmount,
        uint256 targetValue,
        uint256 startTime,
        uint256 endTime
    ) external;

    /**
     * @notice 更新用户任务进度
     * @dev 由授权合约调用（如 MarketBase, ReferralRegistry）
     * @param questId 任务 ID
     * @param user 用户地址
     * @param incrementValue 增加的进度值
     */
    function updateProgress(bytes32 questId, address user, uint256 incrementValue) external;

    /**
     * @notice 验证任务完成
     * @param questId 任务 ID
     * @param user 用户地址
     */
    function verifyCompletion(bytes32 questId, address user) external;

    /**
     * @notice 领取任务奖励
     * @param questId 任务 ID
     */
    function claimReward(bytes32 questId) external;

    /**
     * @notice 暂停任务
     * @param questId 任务 ID
     */
    function pauseQuest(bytes32 questId) external;

    /**
     * @notice 恢复任务
     * @param questId 任务 ID
     */
    function resumeQuest(bytes32 questId) external;

    /**
     * @notice 结束任务
     * @param questId 任务 ID
     */
    function endQuest(bytes32 questId) external;

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取任务信息
     * @param questId 任务 ID
     * @return info 任务信息
     */
    function getQuestInfo(bytes32 questId) external view returns (QuestInfo memory info);

    /**
     * @notice 获取用户任务进度
     * @param questId 任务 ID
     * @param user 用户地址
     * @return progress 任务进度
     */
    function getUserProgress(bytes32 questId, address user)
        external
        view
        returns (UserQuestProgress memory progress);

    /**
     * @notice 检查任务是否完成
     * @param questId 任务 ID
     * @param user 用户地址
     * @return completed 是否完成
     */
    function isCompleted(bytes32 questId, address user) external view returns (bool completed);

    /**
     * @notice 检查奖励是否已领取
     * @param questId 任务 ID
     * @param user 用户地址
     * @return claimed 是否已领取
     */
    function isRewardClaimed(bytes32 questId, address user) external view returns (bool claimed);

    /**
     * @notice 检查任务是否活跃
     * @param questId 任务 ID
     * @return active 是否活跃
     */
    function isActive(bytes32 questId) external view returns (bool active);
}
