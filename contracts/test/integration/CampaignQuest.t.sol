// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/growth/Campaign.sol";
import "../../src/growth/Quest.sol";
import "../../src/core/RewardsDistributor.sol";
import "../../src/interfaces/ICampaign.sol";
import "../../src/interfaces/IQuest.sol";

/**
 * @title CampaignQuestIntegrationTest
 * @notice Integration tests for Campaign and Quest system
 * @dev Tests the complete flow of campaigns, quests, and rewards
 */
contract CampaignQuestIntegrationTest is BaseTest {
    Campaign public campaign;
    Quest public quest;
    RewardsDistributor public rewardsDistributor;

    // Test data
    bytes32 public constant CAMPAIGN_ID = keccak256("CAMPAIGN_1");
    bytes32 public constant QUEST_FIRST_BET = keccak256("QUEST_FIRST_BET");
    bytes32 public constant QUEST_VOLUME = keccak256("QUEST_VOLUME");
    bytes32 public constant QUEST_REFERRAL = keccak256("QUEST_REFERRAL");

    uint256 public campaignStartTime;
    uint256 public campaignEndTime;
    uint256 public questStartTime;
    uint256 public questEndTime;

    // Events from Campaign
    event CampaignCreated(
        bytes32 indexed campaignId,
        string name,
        bytes32 ruleHash,
        uint256 budgetCap,
        uint256 startTime,
        uint256 endTime
    );
    event CampaignParticipated(bytes32 indexed campaignId, address indexed user, uint256 timestamp);
    event CampaignBudgetSpent(bytes32 indexed campaignId, uint256 amount, uint256 totalSpent);

    // Events from Quest
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

    function setUp() public override {
        super.setUp();

        // Deploy contracts
        campaign = new Campaign(owner);
        quest = new Quest(owner, address(campaign));
        rewardsDistributor = new RewardsDistributor(address(usdc), owner);

        // Set time ranges
        campaignStartTime = block.timestamp + 1 hours;
        campaignEndTime = block.timestamp + 30 days;
        questStartTime = block.timestamp + 2 hours;
        questEndTime = block.timestamp + 15 days;

        // Grant OPERATOR_ROLE to Quest contract for recording spending
        campaign.grantRole(campaign.OPERATOR_ROLE(), address(quest));

        vm.label(address(campaign), "Campaign");
        vm.label(address(quest), "Quest");
        vm.label(address(rewardsDistributor), "RewardsDistributor");
    }

    // ============ Complete User Journey Tests ============

    /**
     * @notice Test complete user journey: Campaign -> Quest -> Reward Claim
     * Scenario: User completes a "First Bet" quest and claims reward
     */
    function test_CompleteUserJourney_FirstBet() public {
        // 1. Create Campaign
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "First Deposit Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        // 2. User participates in campaign
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);
        assertTrue(campaign.hasParticipated(CAMPAIGN_ID, user1));

        // 3. Create Quest
        quest.createQuest(
            QUEST_FIRST_BET,
            CAMPAIGN_ID,
            IQuest.QuestType.FIRST_BET,
            "Make Your First Bet",
            100e6, // 100 USDC reward
            1, // 1 bet required
            questStartTime,
            questEndTime
        );

        // 4. Warp to quest start time
        vm.warp(questStartTime);

        // 5. User makes a bet (simulated by OPERATOR updating progress)
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);

        // 6. Verify quest is completed
        assertTrue(quest.isCompleted(QUEST_FIRST_BET, user1));
        assertFalse(quest.isRewardClaimed(QUEST_FIRST_BET, user1));

        // 7. User claims reward
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);

        // 8. Verify reward claimed and budget recorded
        assertTrue(quest.isRewardClaimed(QUEST_FIRST_BET, user1));
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, 100e6);
        assertEq(campaignInfo.participantCount, 1);
    }

    /**
     * @notice Test multiple users completing different quests
     * Scenario: 3 users complete different quests in the same campaign
     */
    function test_MultipleUsers_DifferentQuests() public {
        // Setup campaign and quests
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Multi-Quest Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        // Create 3 different quests
        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet Quest", 100e6, 1, questStartTime, questEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume Quest", 500e6, 1000e6, questStartTime, questEndTime
        );

        quest.createQuest(
            QUEST_REFERRAL, CAMPAIGN_ID, IQuest.QuestType.REFERRAL, "Referral Quest", 300e6, 3, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1: Complete FIRST_BET quest
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);

        // User2: Complete VOLUME quest
        vm.prank(user2);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_VOLUME, user2, 1000e6);
        vm.prank(user2);
        quest.claimReward(QUEST_VOLUME);

        // User3: Complete REFERRAL quest
        vm.prank(user3);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_REFERRAL, user3, 3);
        vm.prank(user3);
        quest.claimReward(QUEST_REFERRAL);

        // Verify campaign budget
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, 100e6 + 500e6 + 300e6); // 900 USDC
        assertEq(campaignInfo.participantCount, 3);
        assertEq(campaign.getRemainingBudget(CAMPAIGN_ID), 10_000e6 - 900e6);
    }

    /**
     * @notice Test incremental progress tracking
     * Scenario: User makes multiple bets to complete a volume quest
     */
    function test_IncrementalProgress_VolumeQuest() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Volume Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Reach 1000 USDC Volume", 200e6, 1000e6, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1 participates
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);

        // Incremental progress updates
        quest.updateProgress(QUEST_VOLUME, user1, 100e6); // 100 USDC
        IQuest.UserQuestProgress memory progress1 = quest.getUserProgress(QUEST_VOLUME, user1);
        assertEq(progress1.currentValue, 100e6);
        assertFalse(progress1.completed);

        quest.updateProgress(QUEST_VOLUME, user1, 300e6); // Total: 400 USDC
        IQuest.UserQuestProgress memory progress2 = quest.getUserProgress(QUEST_VOLUME, user1);
        assertEq(progress2.currentValue, 400e6);
        assertFalse(progress2.completed);

        quest.updateProgress(QUEST_VOLUME, user1, 600e6); // Total: 1000 USDC
        IQuest.UserQuestProgress memory progress3 = quest.getUserProgress(QUEST_VOLUME, user1);
        assertEq(progress3.currentValue, 1000e6);
        assertTrue(progress3.completed); // Auto-completed

        // Verify quest info
        IQuest.QuestInfo memory questInfo = quest.getQuestInfo(QUEST_VOLUME);
        assertEq(questInfo.completionCount, 1);

        // Claim reward
        vm.prank(user1);
        quest.claimReward(QUEST_VOLUME);
        assertTrue(quest.isRewardClaimed(QUEST_VOLUME, user1));
    }

    /**
     * @notice Test campaign budget exhaustion
     * Scenario: Campaign runs out of budget before all users claim
     */
    function test_CampaignBudgetExhaustion() public {
        // Create campaign with small budget
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Limited Budget Campaign", keccak256("ipfs://rules"), 250e6, // Only 250 USDC
            campaignStartTime, campaignEndTime
        );

        // Create quest with 100 USDC reward
        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1 completes and claims (100 USDC spent)
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);

        // User2 completes and claims (200 USDC spent)
        vm.prank(user2);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user2, 1);
        vm.prank(user2);
        quest.claimReward(QUEST_FIRST_BET);

        // User3 completes quest
        vm.prank(user3);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user3, 1);

        // User3 tries to claim but budget is exceeded (need 300 USDC but only 250 available)
        vm.prank(user3);
        vm.expectRevert(
            abi.encodeWithSelector(ICampaign.CampaignBudgetExceeded.selector, CAMPAIGN_ID, 300e6, 250e6)
        );
        quest.claimReward(QUEST_FIRST_BET);

        // Verify campaign spent amount
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, 200e6);
        assertEq(campaign.getRemainingBudget(CAMPAIGN_ID), 50e6);
    }

    /**
     * @notice Test quest pause/resume with campaign active
     * Scenario: Quest is paused temporarily, users cannot progress
     */
    function test_QuestPauseResume_WithActiveCampaign() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Pausable Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume Quest", 200e6, 1000e6, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User starts quest
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_VOLUME, user1, 500e6);

        // Pause quest
        quest.pauseQuest(QUEST_VOLUME);

        // Try to update progress - should revert
        vm.expectRevert(abi.encodeWithSelector(IQuest.QuestNotActive.selector, QUEST_VOLUME));
        quest.updateProgress(QUEST_VOLUME, user1, 500e6);

        // Resume quest
        quest.resumeQuest(QUEST_VOLUME);

        // Now progress can be updated
        quest.updateProgress(QUEST_VOLUME, user1, 500e6);
        assertTrue(quest.isCompleted(QUEST_VOLUME, user1));
    }

    /**
     * @notice Test campaign pause affecting all quests
     * Scenario: When campaign is paused, no new quests can be created
     */
    function test_CampaignPause_BlocksNewQuests() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Pausable Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        // Pause campaign
        campaign.pauseCampaign(CAMPAIGN_ID);

        // Try to create quest - should fail because campaign not active
        vm.expectRevert(abi.encodeWithSelector(IQuest.CampaignNotActive.selector, CAMPAIGN_ID));
        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );

        // Resume campaign
        campaign.resumeCampaign(CAMPAIGN_ID);

        // Now quest can be created
        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );
    }

    /**
     * @notice Test quest outside campaign time range
     * Scenario: Quest time must be within campaign time range
     */
    function test_QuestTimeRange_OutsideCampaign() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID,
            "Short Campaign",
            keccak256("ipfs://rules"),
            10_000e6,
            campaignStartTime,
            campaignStartTime + 7 days // Campaign only lasts 7 days
        );

        // Quest can be created even if it extends beyond campaign end
        // (This is intentional - quest end time is independent)
        quest.createQuest(
            QUEST_VOLUME,
            CAMPAIGN_ID,
            IQuest.QuestType.VOLUME,
            "Long Quest",
            200e6,
            1000e6,
            questStartTime,
            campaignStartTime + 30 days // Quest ends after campaign
        );

        // Warp to after campaign end but before quest end
        vm.warp(campaignStartTime + 10 days);

        // Campaign is no longer active
        assertFalse(campaign.isActive(CAMPAIGN_ID));

        // But quest is still active (based on its own time range)
        assertTrue(quest.isActive(QUEST_VOLUME));

        // User can still progress quest
        quest.updateProgress(QUEST_VOLUME, user1, 1000e6);
        assertTrue(quest.isCompleted(QUEST_VOLUME, user1));

        // User can claim reward even after campaign ended
        vm.prank(user1);
        quest.claimReward(QUEST_VOLUME);
        assertTrue(quest.isRewardClaimed(QUEST_VOLUME, user1));
    }

    /**
     * @notice Test multiple quests in same campaign
     * Scenario: User completes multiple quests to maximize rewards
     */
    function test_MultipleQuests_SameCampaign() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Multi-Quest Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        // Create 3 quests
        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume 1000", 500e6, 1000e6, questStartTime, questEndTime
        );

        bytes32 QUEST_VOLUME_5K = keccak256("QUEST_VOLUME_5K");
        quest.createQuest(
            QUEST_VOLUME_5K, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume 5000", 2000e6, 5000e6, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1 participates and completes all 3 quests
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);

        // Complete FIRST_BET
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);

        // Complete VOLUME (1000)
        quest.updateProgress(QUEST_VOLUME, user1, 1000e6);
        vm.prank(user1);
        quest.claimReward(QUEST_VOLUME);

        // Complete VOLUME_5K
        quest.updateProgress(QUEST_VOLUME_5K, user1, 5000e6);
        vm.prank(user1);
        quest.claimReward(QUEST_VOLUME_5K);

        // Total rewards: 100 + 500 + 2000 = 2600 USDC
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, 2600e6);
        assertEq(campaignInfo.participantCount, 1);

        // Verify all quests completed
        assertTrue(quest.isRewardClaimed(QUEST_FIRST_BET, user1));
        assertTrue(quest.isRewardClaimed(QUEST_VOLUME, user1));
        assertTrue(quest.isRewardClaimed(QUEST_VOLUME_5K, user1));
    }

    /**
     * @notice Test campaign end and budget increase
     * Scenario: Campaign ends, admin increases budget and extends time
     */
    function test_CampaignBudgetIncrease_AndReopen() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Extendable Campaign", keccak256("ipfs://rules"), 1000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 500e6, 1, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1 claims reward
        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);

        // User2 claims reward
        vm.prank(user2);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user2, 1);
        vm.prank(user2);
        quest.claimReward(QUEST_FIRST_BET);

        // Now budget is exhausted (1000 USDC spent)
        ICampaign.CampaignInfo memory info1 = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(info1.spentAmount, 1000e6);
        assertEq(campaign.getRemainingBudget(CAMPAIGN_ID), 0);

        // Admin increases budget
        campaign.increaseBudget(CAMPAIGN_ID, 2000e6);

        // Now user3 can claim
        vm.prank(user3);
        campaign.participate(CAMPAIGN_ID);
        quest.updateProgress(QUEST_FIRST_BET, user3, 1);
        vm.prank(user3);
        quest.claimReward(QUEST_FIRST_BET);

        // Verify final state
        ICampaign.CampaignInfo memory info2 = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(info2.budgetCap, 3000e6); // 1000 + 2000
        assertEq(info2.spentAmount, 1500e6);
        assertEq(campaign.getRemainingBudget(CAMPAIGN_ID), 1500e6);
    }

    /**
     * @notice Test quest completion count tracking
     * Scenario: Track how many users completed each quest
     */
    function test_QuestCompletionCount() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Completion Tracking", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // Initially no completions
        IQuest.QuestInfo memory info0 = quest.getQuestInfo(QUEST_FIRST_BET);
        assertEq(info0.completionCount, 0);

        // User1 completes
        quest.updateProgress(QUEST_FIRST_BET, user1, 1);
        IQuest.QuestInfo memory info1 = quest.getQuestInfo(QUEST_FIRST_BET);
        assertEq(info1.completionCount, 1);

        // User2 completes
        quest.updateProgress(QUEST_FIRST_BET, user2, 1);
        IQuest.QuestInfo memory info2 = quest.getQuestInfo(QUEST_FIRST_BET);
        assertEq(info2.completionCount, 2);

        // User3 completes
        quest.updateProgress(QUEST_FIRST_BET, user3, 1);
        IQuest.QuestInfo memory info3 = quest.getQuestInfo(QUEST_FIRST_BET);
        assertEq(info3.completionCount, 3);

        // All 3 users claim rewards
        vm.prank(user1);
        quest.claimReward(QUEST_FIRST_BET);
        vm.prank(user2);
        quest.claimReward(QUEST_FIRST_BET);
        vm.prank(user3);
        quest.claimReward(QUEST_FIRST_BET);

        // Verify campaign budget
        ICampaign.CampaignInfo memory campaignInfo = campaign.getCampaignInfo(CAMPAIGN_ID);
        assertEq(campaignInfo.spentAmount, 300e6); // 3 * 100 USDC
    }

    /**
     * @notice Test access control - only OPERATOR can update progress
     * Scenario: Regular user cannot update quest progress
     */
    function test_AccessControl_OnlyOperatorUpdatesProgress() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Access Control Test", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume Quest", 200e6, 1000e6, questStartTime, questEndTime
        );

        vm.warp(questStartTime);

        // User1 tries to update their own progress - should fail
        vm.prank(user1);
        vm.expectRevert();
        quest.updateProgress(QUEST_VOLUME, user1, 1000e6);

        // Owner (has OPERATOR_ROLE) can update progress
        quest.updateProgress(QUEST_VOLUME, user1, 1000e6);
        assertTrue(quest.isCompleted(QUEST_VOLUME, user1));
    }

    /**
     * @notice Test quest and campaign query functions
     * Scenario: Test all query/view functions work correctly
     */
    function test_QueryFunctions() public {
        vm.warp(campaignStartTime);
        campaign.createCampaign(
            CAMPAIGN_ID, "Query Test Campaign", keccak256("ipfs://rules"), 10_000e6, campaignStartTime, campaignEndTime
        );

        quest.createQuest(
            QUEST_FIRST_BET, CAMPAIGN_ID, IQuest.QuestType.FIRST_BET, "First Bet", 100e6, 1, questStartTime, questEndTime
        );

        quest.createQuest(
            QUEST_VOLUME, CAMPAIGN_ID, IQuest.QuestType.VOLUME, "Volume Quest", 200e6, 1000e6, questStartTime, questEndTime
        );

        // Campaign queries
        assertEq(campaign.getCampaignCount(), 1);
        bytes32[] memory campaignIds = campaign.getAllCampaignIds();
        assertEq(campaignIds.length, 1);
        assertEq(campaignIds[0], CAMPAIGN_ID);

        // Quest queries
        assertEq(quest.getQuestCount(), 2);
        bytes32[] memory questIds = quest.getAllQuestIds();
        assertEq(questIds.length, 2);
        assertEq(questIds[0], QUEST_FIRST_BET);
        assertEq(questIds[1], QUEST_VOLUME);

        // Before quest start time
        assertFalse(quest.isActive(QUEST_FIRST_BET));

        // During quest time
        vm.warp(questStartTime);
        assertTrue(quest.isActive(QUEST_FIRST_BET));
        assertTrue(quest.isActive(QUEST_VOLUME));

        // After quest end time
        vm.warp(questEndTime);
        assertFalse(quest.isActive(QUEST_FIRST_BET));

        // Campaign still active
        assertTrue(campaign.isActive(CAMPAIGN_ID));
    }
}
