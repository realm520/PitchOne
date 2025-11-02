// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/growth/Campaign.sol";
import "../../src/interfaces/ICampaign.sol";

/**
 * @title CampaignTest
 * @notice Unit tests for Campaign contract
 */
contract CampaignTest is BaseTest {
    Campaign public campaign;

    // Test data
    bytes32 public constant CAMPAIGN_ID_1 = keccak256("CAMPAIGN_1");
    bytes32 public constant CAMPAIGN_ID_2 = keccak256("CAMPAIGN_2");
    string public constant CAMPAIGN_NAME = "First Deposit Bonus";
    bytes32 public constant RULE_HASH = keccak256("ipfs://QmTest123");
    uint256 public constant BUDGET_CAP = 10_000e6; // 10k USDC
    uint256 public startTime;
    uint256 public endTime;

    // Events
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
    event CampaignStatusChanged(
        bytes32 indexed campaignId, ICampaign.CampaignStatus oldStatus, ICampaign.CampaignStatus newStatus
    );
    event CampaignBudgetIncreased(bytes32 indexed campaignId, uint256 oldCap, uint256 newCap);

    function setUp() public override {
        super.setUp();

        // Deploy Campaign contract
        campaign = new Campaign(owner);

        // Set campaign time range (starts in 1 hour, ends in 8 days)
        startTime = block.timestamp + 1 hours;
        endTime = block.timestamp + 8 days;

        vm.label(address(campaign), "Campaign");
    }

    // ============ Constructor Tests ============

    function test_Constructor_Success() public view {
        assertTrue(campaign.hasRole(campaign.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(campaign.hasRole(campaign.ADMIN_ROLE(), owner));
        assertTrue(campaign.hasRole(campaign.OPERATOR_ROLE(), owner));
    }

    function testRevert_Constructor_InvalidAdmin() public {
        vm.expectRevert("Campaign: Invalid admin");
        new Campaign(address(0));
    }

    // ============ Create Campaign Tests ============

    function test_CreateCampaign_Success() public {
        vm.expectEmit(true, false, false, true);
        emit CampaignCreated(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(info.campaignId, CAMPAIGN_ID_1);
        assertEq(info.name, CAMPAIGN_NAME);
        assertEq(info.ruleHash, RULE_HASH);
        assertEq(info.budgetCap, BUDGET_CAP);
        assertEq(info.spentAmount, 0);
        assertEq(info.startTime, startTime);
        assertEq(info.endTime, endTime);
        assertEq(uint256(info.status), uint256(ICampaign.CampaignStatus.Active));
        assertEq(info.participantCount, 0);
    }

    function testRevert_CreateCampaign_AlreadyExists() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.expectRevert(abi.encodeWithSelector(ICampaign.CampaignAlreadyExists.selector, CAMPAIGN_ID_1));
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
    }

    function testRevert_CreateCampaign_InvalidBudget() public {
        vm.expectRevert(abi.encodeWithSelector(ICampaign.InvalidBudget.selector, 0));
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, 0, startTime, endTime);
    }

    function testRevert_CreateCampaign_InvalidTimeRange() public {
        vm.expectRevert(abi.encodeWithSelector(ICampaign.InvalidTimeRange.selector, endTime, startTime));
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, endTime, startTime);
    }

    function testRevert_CreateCampaign_StartTimeInPast() public {
        // Warp to a time with enough room to go back
        vm.warp(block.timestamp + 10 days);
        uint256 pastTime = block.timestamp - 1 hours;
        uint256 futureEndTime = block.timestamp + 8 days;
        vm.expectRevert(abi.encodeWithSelector(ICampaign.InvalidTimeRange.selector, pastTime, block.timestamp));
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, pastTime, futureEndTime);
    }

    function testRevert_CreateCampaign_NotAdmin() public {
        vm.prank(user1);
        vm.expectRevert();
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
    }

    // ============ Participate Tests ============

    function test_Participate_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        // Warp to campaign start time
        vm.warp(startTime);

        vm.expectEmit(true, true, false, true);
        emit CampaignParticipated(CAMPAIGN_ID_1, user1, block.timestamp);

        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID_1);

        assertTrue(campaign.hasParticipated(CAMPAIGN_ID_1, user1));

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(info.participantCount, 1);
    }

    function testRevert_Participate_AlreadyParticipated() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        vm.warp(startTime);

        vm.startPrank(user1);
        campaign.participate(CAMPAIGN_ID_1);

        vm.expectRevert(abi.encodeWithSelector(ICampaign.AlreadyParticipated.selector, CAMPAIGN_ID_1, user1));
        campaign.participate(CAMPAIGN_ID_1);
        vm.stopPrank();
    }

    function testRevert_Participate_CampaignNotStarted() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICampaign.CampaignNotStarted.selector, CAMPAIGN_ID_1));
        campaign.participate(CAMPAIGN_ID_1);
    }

    function testRevert_Participate_CampaignEnded() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        // Warp past end time
        vm.warp(endTime + 1);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICampaign.CampaignAlreadyEnded.selector, CAMPAIGN_ID_1));
        campaign.participate(CAMPAIGN_ID_1);
    }

    function testRevert_Participate_CampaignPaused() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        campaign.pauseCampaign(CAMPAIGN_ID_1);

        vm.warp(startTime);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(ICampaign.CampaignNotActive.selector, CAMPAIGN_ID_1));
        campaign.participate(CAMPAIGN_ID_1);
    }

    // ============ Record Spending Tests ============

    function test_RecordSpending_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        uint256 spendAmount = 100e6;

        vm.expectEmit(true, false, false, true);
        emit CampaignBudgetSpent(CAMPAIGN_ID_1, spendAmount, spendAmount);

        campaign.recordSpending(CAMPAIGN_ID_1, spendAmount);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(info.spentAmount, spendAmount);
        assertEq(campaign.getRemainingBudget(CAMPAIGN_ID_1), BUDGET_CAP - spendAmount);
    }

    function testRevert_RecordSpending_BudgetExceeded() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        uint256 excessAmount = BUDGET_CAP + 1;

        vm.expectRevert(
            abi.encodeWithSelector(ICampaign.CampaignBudgetExceeded.selector, CAMPAIGN_ID_1, excessAmount, BUDGET_CAP)
        );
        campaign.recordSpending(CAMPAIGN_ID_1, excessAmount);
    }

    function testRevert_RecordSpending_NotOperator() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.prank(user1);
        vm.expectRevert();
        campaign.recordSpending(CAMPAIGN_ID_1, 100e6);
    }

    // ============ Pause/Resume Tests ============

    function test_PauseCampaign_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.expectEmit(true, false, false, true);
        emit CampaignStatusChanged(
            CAMPAIGN_ID_1, ICampaign.CampaignStatus.Active, ICampaign.CampaignStatus.Paused
        );

        campaign.pauseCampaign(CAMPAIGN_ID_1);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(uint256(info.status), uint256(ICampaign.CampaignStatus.Paused));
        assertFalse(campaign.isActive(CAMPAIGN_ID_1));
    }

    function test_ResumeCampaign_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        campaign.pauseCampaign(CAMPAIGN_ID_1);

        vm.expectEmit(true, false, false, true);
        emit CampaignStatusChanged(
            CAMPAIGN_ID_1, ICampaign.CampaignStatus.Paused, ICampaign.CampaignStatus.Active
        );

        campaign.resumeCampaign(CAMPAIGN_ID_1);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(uint256(info.status), uint256(ICampaign.CampaignStatus.Active));
    }

    function testRevert_ResumeCampaign_AfterEndTime() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        campaign.pauseCampaign(CAMPAIGN_ID_1);

        vm.warp(endTime + 1);

        vm.expectRevert(abi.encodeWithSelector(ICampaign.CampaignAlreadyEnded.selector, CAMPAIGN_ID_1));
        campaign.resumeCampaign(CAMPAIGN_ID_1);
    }

    // ============ End Campaign Tests ============

    function test_EndCampaign_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.expectEmit(true, false, false, true);
        emit CampaignStatusChanged(CAMPAIGN_ID_1, ICampaign.CampaignStatus.Active, ICampaign.CampaignStatus.Ended);

        campaign.endCampaign(CAMPAIGN_ID_1);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(uint256(info.status), uint256(ICampaign.CampaignStatus.Ended));
        assertFalse(campaign.isActive(CAMPAIGN_ID_1));
    }

    // ============ Increase Budget Tests ============

    function test_IncreaseBudget_Success() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        uint256 additionalBudget = 5_000e6;
        uint256 newCap = BUDGET_CAP + additionalBudget;

        vm.expectEmit(true, false, false, true);
        emit CampaignBudgetIncreased(CAMPAIGN_ID_1, BUDGET_CAP, newCap);

        campaign.increaseBudget(CAMPAIGN_ID_1, additionalBudget);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(info.budgetCap, newCap);
    }

    function testRevert_IncreaseBudget_InvalidAmount() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        vm.expectRevert(abi.encodeWithSelector(ICampaign.InvalidBudget.selector, 0));
        campaign.increaseBudget(CAMPAIGN_ID_1, 0);
    }

    // ============ Query Tests ============

    function test_GetCampaignCount() public {
        assertEq(campaign.getCampaignCount(), 0);

        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        assertEq(campaign.getCampaignCount(), 1);

        uint256 startTime2 = block.timestamp + 2 hours;
        uint256 endTime2 = block.timestamp + 9 days;
        campaign.createCampaign(CAMPAIGN_ID_2, "Campaign 2", RULE_HASH, BUDGET_CAP, startTime2, endTime2);
        assertEq(campaign.getCampaignCount(), 2);
    }

    function test_GetAllCampaignIds() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        uint256 startTime2 = block.timestamp + 2 hours;
        uint256 endTime2 = block.timestamp + 9 days;
        campaign.createCampaign(CAMPAIGN_ID_2, "Campaign 2", RULE_HASH, BUDGET_CAP, startTime2, endTime2);

        bytes32[] memory ids = campaign.getAllCampaignIds();
        assertEq(ids.length, 2);
        assertEq(ids[0], CAMPAIGN_ID_1);
        assertEq(ids[1], CAMPAIGN_ID_2);
    }

    function test_IsActive() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);

        // Before start time
        assertFalse(campaign.isActive(CAMPAIGN_ID_1));

        // During campaign
        vm.warp(startTime);
        assertTrue(campaign.isActive(CAMPAIGN_ID_1));

        // After end time
        vm.warp(endTime);
        assertFalse(campaign.isActive(CAMPAIGN_ID_1));

        // Paused campaign
        vm.warp(startTime);
        campaign.pauseCampaign(CAMPAIGN_ID_1);
        assertFalse(campaign.isActive(CAMPAIGN_ID_1));
    }

    function test_MultipleParticipants() public {
        campaign.createCampaign(CAMPAIGN_ID_1, CAMPAIGN_NAME, RULE_HASH, BUDGET_CAP, startTime, endTime);
        vm.warp(startTime);

        vm.prank(user1);
        campaign.participate(CAMPAIGN_ID_1);

        vm.prank(user2);
        campaign.participate(CAMPAIGN_ID_1);

        vm.prank(user3);
        campaign.participate(CAMPAIGN_ID_1);

        ICampaign.CampaignInfo memory info = campaign.getCampaignInfo(CAMPAIGN_ID_1);
        assertEq(info.participantCount, 3);

        assertTrue(campaign.hasParticipated(CAMPAIGN_ID_1, user1));
        assertTrue(campaign.hasParticipated(CAMPAIGN_ID_1, user2));
        assertTrue(campaign.hasParticipated(CAMPAIGN_ID_1, user3));
    }
}
