// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/growth/Quest.sol";
import "../../src/growth/Campaign.sol";
import "../../src/interfaces/IQuest.sol";
import "../../src/interfaces/ICampaign.sol";

/**
 * @title QuestTest
 * @notice Unit tests for Quest contract
 */
contract QuestTest is BaseTest {
    Quest public quest;
    Campaign public campaign;

    // Test data
    bytes32 public constant CAMPAIGN_ID = keccak256("CAMPAIGN_1");
    bytes32 public constant QUEST_ID_1 = keccak256("QUEST_1");
    bytes32 public constant QUEST_ID_2 = keccak256("QUEST_2");
    string public constant QUEST_NAME = "First Bet Challenge";
    uint256 public constant REWARD_AMOUNT = 100e6; // 100 USDC
    uint256 public constant TARGET_VALUE = 1; // 1 bet for FIRST_BET
    uint256 public questStartTime;
    uint256 public questEndTime;
    uint256 public campaignStartTime;
    uint256 public campaignEndTime;

    // Events
    event QuestCreated(
        bytes32 indexed questId,
        bytes32 indexed campaignId,
        IQuest.QuestType questType,
        string name,
        uint256 rewardAmount,
        uint256 targetValue,
        uint256 startTime,
        uint256 endTime
    );
    event QuestProgressUpdated(
        bytes32 indexed questId, address indexed user, uint256 currentValue, uint256 targetValue
    );
    event QuestCompleted(bytes32 indexed questId, address indexed user, uint256 timestamp);
    event QuestRewardClaimed(bytes32 indexed questId, address indexed user, uint256 rewardAmount);
    event QuestStatusChanged(bytes32 indexed questId, IQuest.QuestStatus oldStatus, IQuest.QuestStatus newStatus);

    function setUp() public override {
        super.setUp();

        // Deploy Campaign contract first
        campaign = new Campaign(owner);

        // Deploy Quest contract
        quest = new Quest(owner, address(campaign));

        // Set time ranges
        campaignStartTime = block.timestamp + 1 hours;
        campaignEndTime = block.timestamp + 30 days;
        questStartTime = block.timestamp + 2 hours;
        questEndTime = block.timestamp + 15 days;

        // Create a campaign for quests to reference
        campaign.createCampaign(
            CAMPAIGN_ID, "Test Campaign", keccak256("ipfs://test"), 10_000e6, campaignStartTime, campaignEndTime
        );

        // Grant OPERATOR_ROLE to Quest contract for recording spending
        campaign.grantRole(campaign.OPERATOR_ROLE(), address(quest));

        vm.label(address(quest), "Quest");
        vm.label(address(campaign), "Campaign");
    }

    // ============ Helper Functions ============

    /// @notice Helper to create a quest (automatically warps to campaign start time)
    function _createQuest(
        bytes32 questId,
        IQuest.QuestType questType,
        string memory name,
        uint256 rewardAmount,
        uint256 targetValue
    ) internal {
        // Warp to campaign start time so it's active
        vm.warp(campaignStartTime);

        quest.createQuest(questId, CAMPAIGN_ID, questType, name, rewardAmount, targetValue, questStartTime, questEndTime);
    }

    // ============ Constructor Tests ============

    function test_Constructor_Success() public view {
        assertTrue(quest.hasRole(quest.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(quest.hasRole(quest.ADMIN_ROLE(), owner));
        assertTrue(quest.hasRole(quest.OPERATOR_ROLE(), owner));
        assertEq(address(quest.campaignContract()), address(campaign));
    }

    function testRevert_Constructor_InvalidAdmin() public {
        vm.expectRevert("Quest: Invalid admin");
        new Quest(address(0), address(campaign));
    }

    function testRevert_Constructor_InvalidCampaign() public {
        vm.expectRevert("Quest: Invalid campaign contract");
        new Quest(owner, address(0));
    }

    // ============ Create Quest Tests ============

    function test_CreateQuest_Success() public {
        // Warp to campaign start time so campaign is active
        vm.warp(campaignStartTime);

        vm.expectEmit(true, true, false, true);
        emit QuestCreated(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(info.questId, QUEST_ID_1);
        assertEq(info.campaignId, CAMPAIGN_ID);
        assertEq(uint256(info.questType), uint256(IQuest.QuestType.FIRST_BET));
        assertEq(info.name, QUEST_NAME);
        assertEq(info.rewardAmount, REWARD_AMOUNT);
        assertEq(info.targetValue, TARGET_VALUE);
        assertEq(info.startTime, questStartTime);
        assertEq(info.endTime, questEndTime);
        assertEq(uint256(info.status), uint256(IQuest.QuestStatus.Active));
        assertEq(info.completionCount, 0);
    }

    function testRevert_CreateQuest_AlreadyExists() public {
        _createQuest(QUEST_ID_1, IQuest.QuestType.FIRST_BET, QUEST_NAME, REWARD_AMOUNT, TARGET_VALUE);

        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestAlreadyExists.selector, QUEST_ID_1));
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );
    }

    function testRevert_CreateQuest_InvalidTargetValue() public {
        vm.expectRevert(abi.encodeWithSelector(IQuest.InvalidTargetValue.selector, 0));
        quest.createQuest(
            QUEST_ID_1, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, QUEST_NAME, REWARD_AMOUNT, 0, questStartTime, questEndTime
        );
    }

    function testRevert_CreateQuest_InvalidTimeRange() public {
        vm.expectRevert("Quest: Invalid time range");
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questEndTime,
            questStartTime
        );
    }

    // Note: Cannot test invalid enum values directly in Solidity
    // This would require low-level call or external contract
    // The validation in createQuest prevents invalid quest types

    function testRevert_CreateQuest_CampaignNotActive() public {
        // Pause the campaign
        campaign.pauseCampaign(CAMPAIGN_ID);

        vm.expectRevert(abi.encodeWithSelector(IQuest.CampaignNotActive.selector, CAMPAIGN_ID));
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );
    }

    function testRevert_CreateQuest_NotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );
    }

    // ============ Update Progress Tests ============

    function test_UpdateProgress_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Volume Quest",
            REWARD_AMOUNT,
            1000e6, // Target is 1000 USDC
            questStartTime,
            questEndTime
        );

        // Warp to quest start time
        vm.warp(questStartTime);

        vm.expectEmit(true, true, false, true);
        emit QuestProgressUpdated(QUEST_ID_1, user1, 100e6, 1000e6);

        quest.updateProgress(QUEST_ID_1, user1, 100e6);

        IQuest.UserQuestProgress memory progress = quest.getUserProgress(QUEST_ID_1, user1);
        assertEq(progress.currentValue, 100e6);
        assertEq(progress.lastUpdateTime, block.timestamp);
        assertFalse(progress.completed);
        assertFalse(progress.rewardClaimed);
    }

    function test_UpdateProgress_AutoComplete() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Volume Quest",
            REWARD_AMOUNT,
            1000e6,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);

        // Update progress to target value - should auto complete
        vm.expectEmit(true, true, false, true);
        emit QuestCompleted(QUEST_ID_1, user1, block.timestamp);

        quest.updateProgress(QUEST_ID_1, user1, 1000e6);

        IQuest.UserQuestProgress memory progress = quest.getUserProgress(QUEST_ID_1, user1);
        assertEq(progress.currentValue, 1000e6);
        assertTrue(progress.completed);

        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(info.completionCount, 1);
    }

    function test_UpdateProgress_BeforeStart() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        // Don't warp time - before start
        quest.updateProgress(QUEST_ID_1, user1, 1);

        // Should silently fail - progress not updated
        IQuest.UserQuestProgress memory progress = quest.getUserProgress(QUEST_ID_1, user1);
        assertEq(progress.currentValue, 0);
    }

    function test_UpdateProgress_AfterEnd() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        // Warp past end time
        vm.warp(questEndTime + 1);

        quest.updateProgress(QUEST_ID_1, user1, 1);

        // Should silently fail - progress not updated
        IQuest.UserQuestProgress memory progress = quest.getUserProgress(QUEST_ID_1, user1);
        assertEq(progress.currentValue, 0);
    }

    function test_UpdateProgress_AlreadyCompleted() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);

        // First update - complete quest
        quest.updateProgress(QUEST_ID_1, user1, 1);

        // Second update - should silently skip
        quest.updateProgress(QUEST_ID_1, user1, 1);

        IQuest.UserQuestProgress memory progress = quest.getUserProgress(QUEST_ID_1, user1);
        assertEq(progress.currentValue, 1); // Still 1, not 2
    }

    function testRevert_UpdateProgress_QuestNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestNotFound.selector, QUEST_ID_1));
        quest.updateProgress(QUEST_ID_1, user1, 1);
    }

    function testRevert_UpdateProgress_QuestNotActive() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        quest.pauseQuest(QUEST_ID_1);

        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestNotActive.selector, QUEST_ID_1));
        quest.updateProgress(QUEST_ID_1, user1, 1);
    }

    function testRevert_UpdateProgress_NotOperator() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.prank(user1);
        vm.expectRevert();
        quest.updateProgress(QUEST_ID_1, user1, 1);
    }

    // ============ Verify Completion Tests ============

    function test_VerifyCompletion_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Volume Quest",
            REWARD_AMOUNT,
            1000e6,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);

        // Update progress but not enough to auto-complete
        quest.updateProgress(QUEST_ID_1, user1, 500e6);
        quest.updateProgress(QUEST_ID_1, user1, 499e6);

        // Now progress is 999e6 (just under target), manually verify will fail
        // Need to add the remaining 1e6 to reach target
        quest.updateProgress(QUEST_ID_1, user1, 1e6);

        // Auto-completed, verify it's completed
        assertTrue(quest.isCompleted(QUEST_ID_1, user1));
    }

    function testRevert_VerifyCompletion_AlreadyCompleted() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);
        quest.updateProgress(QUEST_ID_1, user1, 1);

        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestAlreadyCompleted.selector, QUEST_ID_1, user1));
        quest.verifyCompletion(QUEST_ID_1, user1);
    }

    function testRevert_VerifyCompletion_NotCompleted() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Volume Quest",
            REWARD_AMOUNT,
            1000e6,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);
        quest.updateProgress(QUEST_ID_1, user1, 500e6);

        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestNotCompleted.selector, QUEST_ID_1, user1));
        quest.verifyCompletion(QUEST_ID_1, user1);
    }

    // ============ Claim Reward Tests ============

    function test_ClaimReward_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);
        quest.updateProgress(QUEST_ID_1, user1, 1);

        vm.expectEmit(true, true, false, true);
        emit QuestRewardClaimed(QUEST_ID_1, user1, REWARD_AMOUNT);

        vm.prank(user1);
        quest.claimReward(QUEST_ID_1);

        assertTrue(quest.isRewardClaimed(QUEST_ID_1, user1));

        // Check campaign budget was recorded
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, REWARD_AMOUNT);
    }

    function testRevert_ClaimReward_NotCompleted() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestNotCompleted.selector, QUEST_ID_1, user1));
        quest.claimReward(QUEST_ID_1);
    }

    function testRevert_ClaimReward_AlreadyClaimed() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);
        quest.updateProgress(QUEST_ID_1, user1, 1);

        vm.prank(user1);
        quest.claimReward(QUEST_ID_1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IQuest.RewardAlreadyClaimed.selector, QUEST_ID_1, user1));
        quest.claimReward(QUEST_ID_1);
    }

    // ============ Pause/Resume Tests ============

    function test_PauseQuest_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.expectEmit(true, false, false, true);
        emit QuestStatusChanged(QUEST_ID_1, IQuest.QuestStatus.Active, IQuest.QuestStatus.Paused);

        quest.pauseQuest(QUEST_ID_1);

        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(uint256(info.status), uint256(IQuest.QuestStatus.Paused));
    }

    function test_ResumeQuest_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        quest.pauseQuest(QUEST_ID_1);

        vm.expectEmit(true, false, false, true);
        emit QuestStatusChanged(QUEST_ID_1, IQuest.QuestStatus.Paused, IQuest.QuestStatus.Active);

        quest.resumeQuest(QUEST_ID_1);

        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(uint256(info.status), uint256(IQuest.QuestStatus.Active));
    }

    function testRevert_ResumeQuest_NotPaused() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.expectRevert("Quest: Not paused");
        quest.resumeQuest(QUEST_ID_1);
    }

    // ============ End Quest Tests ============

    function test_EndQuest_Success() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        vm.expectEmit(true, false, false, true);
        emit QuestStatusChanged(QUEST_ID_1, IQuest.QuestStatus.Active, IQuest.QuestStatus.Ended);

        quest.endQuest(QUEST_ID_1);

        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(uint256(info.status), uint256(IQuest.QuestStatus.Ended));
    }

    // ============ Query Tests ============

    function test_IsActive() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        // Before start time
        assertFalse(quest.isActive(QUEST_ID_1));

        // During quest
        vm.warp(questStartTime);
        assertTrue(quest.isActive(QUEST_ID_1));

        // After end time
        vm.warp(questEndTime);
        assertFalse(quest.isActive(QUEST_ID_1));

        // Paused quest
        vm.warp(questStartTime);
        quest.pauseQuest(QUEST_ID_1);
        assertFalse(quest.isActive(QUEST_ID_1));
    }

    function test_GetAllQuestIds() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            "Quest 1",
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        // Campaign is still active, no need to warp again
        quest.createQuest(
            QUEST_ID_2,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Quest 2",
            REWARD_AMOUNT,
            1000e6,
            questStartTime,
            questEndTime
        );

        bytes32[] memory ids = quest.getAllQuestIds();
        assertEq(ids.length, 2);
        assertEq(ids[0], QUEST_ID_1);
        assertEq(ids[1], QUEST_ID_2);
    }

    function test_GetQuestCount() public {
        assertEq(quest.getQuestCount(), 0);

        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            QUEST_NAME,
            REWARD_AMOUNT,
            TARGET_VALUE,
            questStartTime,
            questEndTime
        );

        assertEq(quest.getQuestCount(), 1);
    }

    // ============ Multiple Quest Types Tests ============

    function test_MultipleQuestTypes() public {
        // FIRST_BET quest
        bytes32 firstBetId = keccak256("FIRST_BET_QUEST");
        vm.warp(campaignStartTime);
        quest.createQuest(
            firstBetId,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            "First Bet",
            100e6,
            1,
            questStartTime,
            questEndTime
        );

        // CONSECUTIVE_BETS quest
        bytes32 consecutiveId = keccak256("CONSECUTIVE_QUEST");
        quest.createQuest(
            consecutiveId,
            CAMPAIGN_ID,
            IQuest.QuestType.CONSECUTIVE_BETS,
            "7 Day Streak",
            500e6,
            7,
            questStartTime,
            questEndTime
        );

        // REFERRAL quest
        bytes32 referralId = keccak256("REFERRAL_QUEST");
        quest.createQuest(referralId, CAMPAIGN_ID, IQuest.QuestType.REFERRAL, "Refer 5 Friends", 1000e6, 5, questStartTime, questEndTime);

        // VOLUME quest
        bytes32 volumeId = keccak256("VOLUME_QUEST");
        quest.createQuest(volumeId, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "10k Volume", 2000e6, 10_000e6, questStartTime, questEndTime);

        // WIN_STREAK quest
        bytes32 winStreakId = keccak256("WIN_STREAK_QUEST");
        quest.createQuest(
            winStreakId, CAMPAIGN_ID, IQuest.QuestType.WIN_STREAK, "3 Wins Streak", 300e6, 3, questStartTime, questEndTime
        );

        assertEq(quest.getQuestCount(), 5);

        // Verify each quest
        IQuest.QuestInfo memory info1 = quest.getQuestInfo(firstBetId);
        assertEq(uint256(info1.questType), uint256(IQuest.QuestType.FIRST_BET));

        IQuest.QuestInfo memory info2 = quest.getQuestInfo(consecutiveId);
        assertEq(uint256(info2.questType), uint256(IQuest.QuestType.CONSECUTIVE_BETS));

        IQuest.QuestInfo memory info3 = quest.getQuestInfo(referralId);
        assertEq(uint256(info3.questType), uint256(IQuest.QuestType.REFERRAL));

        IQuest.QuestInfo memory info4 = quest.getQuestInfo(volumeId);
        assertEq(uint256(info4.questType), uint256(IQuest.QuestType.VOLUME));

        IQuest.QuestInfo memory info5 = quest.getQuestInfo(winStreakId);
        assertEq(uint256(info5.questType), uint256(IQuest.QuestType.WIN_STREAK));
    }

    // ============ Multiple Users Tests ============

    function test_MultipleUsersProgress() public {
        vm.warp(campaignStartTime);
        quest.createQuest(
            QUEST_ID_1,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Volume Quest",
            REWARD_AMOUNT,
            1000e6,
            questStartTime,
            questEndTime
        );

        vm.warp(questStartTime);

        // User 1 completes quest
        quest.updateProgress(QUEST_ID_1, user1, 1000e6);
        assertTrue(quest.isCompleted(QUEST_ID_1, user1));

        // User 2 partial progress
        quest.updateProgress(QUEST_ID_1, user2, 500e6);
        assertFalse(quest.isCompleted(QUEST_ID_1, user2));

        // User 3 completes quest
        quest.updateProgress(QUEST_ID_1, user3, 1000e6);
        assertTrue(quest.isCompleted(QUEST_ID_1, user3));

        // Check completion count
        IQuest.QuestInfo memory info = quest.getQuestInfo(QUEST_ID_1);
        assertEq(info.completionCount, 2);

        // Users claim rewards
        vm.prank(user1);
        quest.claimReward(QUEST_ID_1);

        vm.prank(user3);
        quest.claimReward(QUEST_ID_1);

        // Check campaign budget
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, REWARD_AMOUNT * 2);
    }
}
