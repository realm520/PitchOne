// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IQuest.sol";
import "../interfaces/ICampaign.sol";

/**
 * @title Quest
 * @notice 任务（Quest）管理合约
 * @dev 用于链上注册和验证用户任务完成情况
 *
 * 支持的任务类型：
 * - FIRST_BET: 首次下注
 * - CONSECUTIVE_BETS: 连续下注（如连续 7 天）
 * - REFERRAL: 推荐任务（推荐 N 个有效用户）
 * - VOLUME: 累计交易量达标
 * - WIN_STREAK: 连续 N 次盈利
 *
 * 任务生命周期：
 * 1. 管理员创建任务（关联 Campaign）
 * 2. 用户完成任务条件（由授权合约更新进度）
 * 3. 系统验证完成状态
 * 4. 用户领取奖励
 *
 * 权限设计：
 * - ADMIN_ROLE: 创建/管理任务
 * - OPERATOR_ROLE: 更新用户进度
 * - 用户: 领取奖励
 */
contract Quest is IQuest, AccessControl, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 管理员角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice 操作员角色（可更新用户进度）
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Campaign 合约地址
    ICampaign public immutable campaignContract;

    /// @notice 任务 ID -> 任务信息
    mapping(bytes32 => QuestInfo) private quests;

    /// @notice 任务 ID -> 用户地址 -> 用户进度
    mapping(bytes32 => mapping(address => UserQuestProgress)) private userProgress;

    /// @notice 任务 ID 是否存在
    mapping(bytes32 => bool) private questExists;

    /// @notice 所有任务 ID 列表
    bytes32[] private allQuestIds;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param admin 管理员地址
     * @param _campaignContract Campaign 合约地址
     */
    constructor(address admin, address _campaignContract) {
        require(admin != address(0), "Quest: Invalid admin");
        require(_campaignContract != address(0), "Quest: Invalid campaign contract");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);

        campaignContract = ICampaign(_campaignContract);
    }

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
    ) external onlyRole(ADMIN_ROLE) {
        // 验证参数
        if (questExists[questId]) {
            revert QuestAlreadyExists(questId);
        }
        if (targetValue == 0) {
            revert InvalidTargetValue(targetValue);
        }
        if (startTime >= endTime) {
            revert("Quest: Invalid time range");
        }
        if (uint256(questType) > uint256(QuestType.WIN_STREAK)) {
            revert InvalidQuestType(questType);
        }

        // 验证关联的 Campaign 是否活跃
        if (!campaignContract.isActive(campaignId)) {
            revert CampaignNotActive(campaignId);
        }

        // 创建任务
        quests[questId] = QuestInfo({
            questId: questId,
            campaignId: campaignId,
            questType: questType,
            name: name,
            rewardAmount: rewardAmount,
            targetValue: targetValue,
            startTime: startTime,
            endTime: endTime,
            status: QuestStatus.Active,
            completionCount: 0
        });

        questExists[questId] = true;
        allQuestIds.push(questId);

        emit QuestCreated(questId, campaignId, questType, name, rewardAmount, targetValue, startTime, endTime);
    }

    /**
     * @notice 更新用户任务进度
     * @dev 由授权合约调用（如 MarketBase, ReferralRegistry）
     * @param questId 任务 ID
     * @param user 用户地址
     * @param incrementValue 增加的进度值
     */
    function updateProgress(bytes32 questId, address user, uint256 incrementValue)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        QuestInfo storage quest = quests[questId];
        UserQuestProgress storage progress = userProgress[questId][user];

        // 检查任务状态
        if (quest.status != QuestStatus.Active) {
            revert QuestNotActive(questId);
        }
        if (block.timestamp < quest.startTime || block.timestamp >= quest.endTime) {
            return; // 静默失败，不影响正常流程
        }

        // 如果已完成，不再更新
        if (progress.completed) {
            return;
        }

        // 更新进度
        progress.currentValue += incrementValue;
        progress.lastUpdateTime = block.timestamp;

        emit QuestProgressUpdated(questId, user, progress.currentValue, quest.targetValue);

        // 自动验证完成
        if (progress.currentValue >= quest.targetValue) {
            _completeQuest(questId, user);
        }
    }

    /**
     * @notice 验证任务完成
     * @param questId 任务 ID
     * @param user 用户地址
     */
    function verifyCompletion(bytes32 questId, address user) external {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        UserQuestProgress storage progress = userProgress[questId][user];
        QuestInfo storage quest = quests[questId];

        if (progress.completed) {
            revert QuestAlreadyCompleted(questId, user);
        }
        if (progress.currentValue < quest.targetValue) {
            revert QuestNotCompleted(questId, user);
        }

        _completeQuest(questId, user);
    }

    /**
     * @notice 领取任务奖励
     * @param questId 任务 ID
     */
    function claimReward(bytes32 questId) external nonReentrant {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        UserQuestProgress storage progress = userProgress[questId][msg.sender];
        QuestInfo storage quest = quests[questId];

        // 验证领取条件
        if (!progress.completed) {
            revert QuestNotCompleted(questId, msg.sender);
        }
        if (progress.rewardClaimed) {
            revert RewardAlreadyClaimed(questId, msg.sender);
        }

        // 标记已领取
        progress.rewardClaimed = true;

        // 记录 Campaign 预算支出
        campaignContract.recordSpending(quest.campaignId, quest.rewardAmount);

        emit QuestRewardClaimed(questId, msg.sender, quest.rewardAmount);

        // Note: 实际奖励发放通过 RewardsDistributor 或其他机制完成
        // 这里只记录链上状态
    }

    /**
     * @notice 暂停任务
     * @param questId 任务 ID
     */
    function pauseQuest(bytes32 questId) external onlyRole(ADMIN_ROLE) {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        QuestInfo storage quest = quests[questId];

        if (quest.status != QuestStatus.Active) {
            revert QuestNotActive(questId);
        }

        QuestStatus oldStatus = quest.status;
        quest.status = QuestStatus.Paused;

        emit QuestStatusChanged(questId, oldStatus, QuestStatus.Paused);
    }

    /**
     * @notice 恢复任务
     * @param questId 任务 ID
     */
    function resumeQuest(bytes32 questId) external onlyRole(ADMIN_ROLE) {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        QuestInfo storage quest = quests[questId];

        if (quest.status != QuestStatus.Paused) {
            revert("Quest: Not paused");
        }

        QuestStatus oldStatus = quest.status;
        quest.status = QuestStatus.Active;

        emit QuestStatusChanged(questId, oldStatus, QuestStatus.Active);
    }

    /**
     * @notice 结束任务
     * @param questId 任务 ID
     */
    function endQuest(bytes32 questId) external onlyRole(ADMIN_ROLE) {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }

        QuestInfo storage quest = quests[questId];

        QuestStatus oldStatus = quest.status;
        quest.status = QuestStatus.Ended;

        emit QuestStatusChanged(questId, oldStatus, QuestStatus.Ended);
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取任务信息
     * @param questId 任务 ID
     * @return info 任务信息
     */
    function getQuestInfo(bytes32 questId) external view returns (QuestInfo memory info) {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }
        return quests[questId];
    }

    /**
     * @notice 获取用户任务进度
     * @param questId 任务 ID
     * @param user 用户地址
     * @return progress 任务进度
     */
    function getUserProgress(bytes32 questId, address user) external view returns (UserQuestProgress memory progress) {
        if (!questExists[questId]) {
            revert QuestNotFound(questId);
        }
        return userProgress[questId][user];
    }

    /**
     * @notice 检查任务是否完成
     * @param questId 任务 ID
     * @param user 用户地址
     * @return completed 是否完成
     */
    function isCompleted(bytes32 questId, address user) external view returns (bool completed) {
        return userProgress[questId][user].completed;
    }

    /**
     * @notice 检查奖励是否已领取
     * @param questId 任务 ID
     * @param user 用户地址
     * @return claimed 是否已领取
     */
    function isRewardClaimed(bytes32 questId, address user) external view returns (bool claimed) {
        return userProgress[questId][user].rewardClaimed;
    }

    /**
     * @notice 检查任务是否活跃
     * @param questId 任务 ID
     * @return active 是否活跃
     */
    function isActive(bytes32 questId) external view returns (bool active) {
        if (!questExists[questId]) {
            return false;
        }

        QuestInfo storage quest = quests[questId];

        return quest.status == QuestStatus.Active && block.timestamp >= quest.startTime
            && block.timestamp < quest.endTime;
    }

    /**
     * @notice 获取所有任务 ID
     * @return questIds 任务 ID 数组
     */
    function getAllQuestIds() external view returns (bytes32[] memory questIds) {
        return allQuestIds;
    }

    /**
     * @notice 获取任务数量
     * @return count 任务总数
     */
    function getQuestCount() external view returns (uint256 count) {
        return allQuestIds.length;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 完成任务
     * @param questId 任务 ID
     * @param user 用户地址
     */
    function _completeQuest(bytes32 questId, address user) private {
        UserQuestProgress storage progress = userProgress[questId][user];
        QuestInfo storage quest = quests[questId];

        progress.completed = true;
        quest.completionCount++;

        emit QuestCompleted(questId, user, block.timestamp);
    }
}
