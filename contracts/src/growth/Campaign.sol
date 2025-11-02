// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/ICampaign.sol";

/**
 * @title Campaign
 * @notice 营销活动管理合约
 * @dev 用于链上注册营销活动，管理活动预算和参与记录
 *
 * 功能特性：
 * - 活动创建与生命周期管理（Active/Paused/Ended）
 * - 预算硬上限保护
 * - 参与记录与防重复参与
 * - 活动状态查询
 * - 权限控制（仅管理员可创建/管理活动）
 *
 * 使用场景：
 * - 首单奖励活动
 * - 推荐奖励活动
 * - 连续下注挑战
 * - 交易量竞赛
 *
 * 奖励发放：
 * - 活动规则存储在链下（IPFS）
 * - 奖励通过 RewardsDistributor 或 Quest 合约发放
 */
contract Campaign is ICampaign, AccessControl, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 管理员角色（可创建和管理活动）
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice 操作员角色（可记录支出）
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 活动 ID -> 活动信息
    mapping(bytes32 => CampaignInfo) private campaigns;

    /// @notice 活动 ID -> 用户地址 -> 是否已参与
    mapping(bytes32 => mapping(address => bool)) private userParticipation;

    /// @notice 所有活动 ID 列表
    bytes32[] private allCampaignIds;

    /// @notice 活动 ID 是否存在
    mapping(bytes32 => bool) private campaignExists;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param admin 管理员地址
     */
    constructor(address admin) {
        require(admin != address(0), "Campaign: Invalid admin");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);
    }

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
    ) external onlyRole(ADMIN_ROLE) {
        // 验证参数
        if (campaignExists[campaignId]) {
            revert CampaignAlreadyExists(campaignId);
        }
        if (budgetCap == 0) {
            revert InvalidBudget(budgetCap);
        }
        if (startTime >= endTime) {
            revert InvalidTimeRange(startTime, endTime);
        }
        if (startTime < block.timestamp) {
            revert InvalidTimeRange(startTime, block.timestamp);
        }

        // 创建活动
        campaigns[campaignId] = CampaignInfo({
            campaignId: campaignId,
            name: name,
            ruleHash: ruleHash,
            budgetCap: budgetCap,
            spentAmount: 0,
            startTime: startTime,
            endTime: endTime,
            status: CampaignStatus.Active,
            participantCount: 0
        });

        campaignExists[campaignId] = true;
        allCampaignIds.push(campaignId);

        emit CampaignCreated(campaignId, name, ruleHash, budgetCap, startTime, endTime);
    }

    /**
     * @notice 用户参与活动
     * @param campaignId 活动 ID
     */
    function participate(bytes32 campaignId) external nonReentrant {
        CampaignInfo storage campaign = campaigns[campaignId];

        // 验证活动状态
        _validateCampaignActive(campaignId);

        // 检查是否已参与
        if (userParticipation[campaignId][msg.sender]) {
            revert AlreadyParticipated(campaignId, msg.sender);
        }

        // 记录参与
        userParticipation[campaignId][msg.sender] = true;
        campaign.participantCount++;

        emit CampaignParticipated(campaignId, msg.sender, block.timestamp);
    }

    /**
     * @notice 记录活动预算支出
     * @dev 由授权的 Quest 合约或 Operator 调用
     * @param campaignId 活动 ID
     * @param amount 支出金额
     */
    function recordSpending(bytes32 campaignId, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        CampaignInfo storage campaign = campaigns[campaignId];

        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }

        // 检查预算
        uint256 newSpent = campaign.spentAmount + amount;
        if (newSpent > campaign.budgetCap) {
            revert CampaignBudgetExceeded(campaignId, newSpent, campaign.budgetCap);
        }

        campaign.spentAmount = newSpent;

        emit CampaignBudgetSpent(campaignId, amount, newSpent);
    }

    /**
     * @notice 暂停活动
     * @param campaignId 活动 ID
     */
    function pauseCampaign(bytes32 campaignId) external onlyRole(ADMIN_ROLE) {
        CampaignInfo storage campaign = campaigns[campaignId];

        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        if (campaign.status != CampaignStatus.Active) {
            revert CampaignNotActive(campaignId);
        }

        CampaignStatus oldStatus = campaign.status;
        campaign.status = CampaignStatus.Paused;

        emit CampaignStatusChanged(campaignId, oldStatus, CampaignStatus.Paused);
    }

    /**
     * @notice 恢复活动
     * @param campaignId 活动 ID
     */
    function resumeCampaign(bytes32 campaignId) external onlyRole(ADMIN_ROLE) {
        CampaignInfo storage campaign = campaigns[campaignId];

        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        if (campaign.status != CampaignStatus.Paused) {
            revert("Campaign: Not paused");
        }
        if (block.timestamp >= campaign.endTime) {
            revert CampaignAlreadyEnded(campaignId);
        }

        CampaignStatus oldStatus = campaign.status;
        campaign.status = CampaignStatus.Active;

        emit CampaignStatusChanged(campaignId, oldStatus, CampaignStatus.Active);
    }

    /**
     * @notice 结束活动
     * @param campaignId 活动 ID
     */
    function endCampaign(bytes32 campaignId) external onlyRole(ADMIN_ROLE) {
        CampaignInfo storage campaign = campaigns[campaignId];

        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        if (campaign.status == CampaignStatus.Ended) {
            revert CampaignAlreadyEnded(campaignId);
        }

        CampaignStatus oldStatus = campaign.status;
        campaign.status = CampaignStatus.Ended;

        emit CampaignStatusChanged(campaignId, oldStatus, CampaignStatus.Ended);
    }

    /**
     * @notice 增加活动预算
     * @param campaignId 活动 ID
     * @param additionalBudget 新增预算
     */
    function increaseBudget(bytes32 campaignId, uint256 additionalBudget) external onlyRole(ADMIN_ROLE) {
        CampaignInfo storage campaign = campaigns[campaignId];

        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        if (additionalBudget == 0) {
            revert InvalidBudget(additionalBudget);
        }

        uint256 oldCap = campaign.budgetCap;
        campaign.budgetCap = oldCap + additionalBudget;

        emit CampaignBudgetIncreased(campaignId, oldCap, campaign.budgetCap);
    }

    /*//////////////////////////////////////////////////////////////
                            READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取活动信息
     * @param campaignId 活动 ID
     * @return info 活动信息
     */
    function getCampaignInfo(bytes32 campaignId) external view returns (CampaignInfo memory info) {
        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        return campaigns[campaignId];
    }

    /**
     * @notice 检查用户是否已参与活动
     * @param campaignId 活动 ID
     * @param user 用户地址
     * @return participated 是否已参与
     */
    function hasParticipated(bytes32 campaignId, address user) external view returns (bool participated) {
        return userParticipation[campaignId][user];
    }

    /**
     * @notice 获取活动剩余预算
     * @param campaignId 活动 ID
     * @return remaining 剩余预算
     */
    function getRemainingBudget(bytes32 campaignId) external view returns (uint256 remaining) {
        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }
        CampaignInfo storage campaign = campaigns[campaignId];
        return campaign.budgetCap - campaign.spentAmount;
    }

    /**
     * @notice 检查活动是否活跃
     * @param campaignId 活动 ID
     * @return active 是否活跃
     */
    function isActive(bytes32 campaignId) external view returns (bool active) {
        if (!campaignExists[campaignId]) {
            return false;
        }

        CampaignInfo storage campaign = campaigns[campaignId];

        return campaign.status == CampaignStatus.Active && block.timestamp >= campaign.startTime
            && block.timestamp < campaign.endTime;
    }

    /**
     * @notice 获取所有活动 ID
     * @return campaignIds 活动 ID 数组
     */
    function getAllCampaignIds() external view returns (bytes32[] memory campaignIds) {
        return allCampaignIds;
    }

    /**
     * @notice 获取活动数量
     * @return count 活动总数
     */
    function getCampaignCount() external view returns (uint256 count) {
        return allCampaignIds.length;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 验证活动是否活跃
     * @param campaignId 活动 ID
     */
    function _validateCampaignActive(bytes32 campaignId) private view {
        if (!campaignExists[campaignId]) {
            revert CampaignNotFound(campaignId);
        }

        CampaignInfo storage campaign = campaigns[campaignId];

        if (campaign.status != CampaignStatus.Active) {
            revert CampaignNotActive(campaignId);
        }

        if (block.timestamp < campaign.startTime) {
            revert CampaignNotStarted(campaignId);
        }

        if (block.timestamp >= campaign.endTime) {
            revert CampaignAlreadyEnded(campaignId);
        }
    }
}
