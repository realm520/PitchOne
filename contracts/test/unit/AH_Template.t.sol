// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/AH_Template.sol";
import "../../src/interfaces/IAH_Template.sol";
import "../../src/interfaces/IMarket.sol";

/**
 * @title AH_TemplateTest
 * @notice Unit tests for AH_Template market contract (Asian Handicap markets)
 */
contract AH_TemplateTest is BaseTest {
    AH_Template public market;

    // Market parameters
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;
    int256 constant HANDICAP_HALF = -500; // -0.5 (主队让半球)
    int256 constant HANDICAP_WHOLE = -1000; // -1.0 (主队让一球)
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // Outcomes
    uint256 constant HOME_COVER = 0;
    uint256 constant AWAY_COVER = 1;
    uint256 constant PUSH = 2;

    event AHMarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        int256 handicap,
        IAH_Template.HandicapType handicapType,
        IAH_Template.HandicapDirection direction,
        address pricingEngine
    );

    event AHSettled(
        string indexed matchId,
        uint256 homeScore,
        uint256 awayScore,
        int256 adjustedHomeScore,
        int256 adjustedAwayScore,
        uint256 winningOutcome
    );

    event BetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    event Locked(uint256 timestamp);
    event MarketResolved(uint256 indexed winningOutcome, uint256 timestamp);

    function setUp() public override {
        super.setUp();

        // Set kickoff time to 2 hours from now
        kickoffTime = block.timestamp + 2 hours;

        // Deploy AH market (半球盘 -0.5)
        market = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_HALF,
            IAH_Template.HandicapType.HALF,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        vm.label(address(market), "AH_Market");
    }

    // ============================================================================
    // Constructor and Initialization Tests
    // ============================================================================

    function test_Constructor_HalfHandicap_Success() public {
        assertEq(market.matchId(), MATCH_ID);
        assertEq(market.homeTeam(), HOME_TEAM);
        assertEq(market.awayTeam(), AWAY_TEAM);
        assertEq(market.kickoffTime(), kickoffTime);
        assertEq(market.getHandicap(), HANDICAP_HALF);
        assertEq(uint256(market.getHandicapType()), uint256(IAH_Template.HandicapType.HALF));
        assertEq(
            uint256(market.getHandicapDirection()), uint256(IAH_Template.HandicapDirection.HOME_GIVE)
        );
        assertEq(address(market.pricingEngine()), address(cpmm));
        assertEq(market.outcomeCount(), 2); // Home Cover, Away Cover (no Push for half)
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));
    }

    function test_Constructor_WholeHandicap_Success() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        assertEq(wholeMarket.getHandicap(), HANDICAP_WHOLE);
        assertEq(uint256(wholeMarket.getHandicapType()), uint256(IAH_Template.HandicapType.WHOLE));
        assertEq(wholeMarket.outcomeCount(), 3); // Home Cover, Away Cover, Push
    }

    function test_Constructor_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit AHMarketCreated(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_HALF,
            IAH_Template.HandicapType.HALF,
            IAH_Template.HandicapDirection.HOME_GIVE,
            address(cpmm)
        );

        new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_HALF,
            IAH_Template.HandicapType.HALF,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function test_Constructor_RevertIf_EmptyMatchId() public {
        vm.expectRevert("Empty match ID");
        new AH_Template(
            "",
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_HALF,
            IAH_Template.HandicapType.HALF,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function test_Constructor_RevertIf_InvalidHandicap() public {
        // 让球数不是 0.25 的倍数
        vm.expectRevert(abi.encodeWithSelector(IAH_Template.InvalidHandicap.selector, -300));
        new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            -300, // 无效的让球数
            IAH_Template.HandicapType.HALF,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function test_Constructor_RevertIf_HandicapTypeMismatch() public {
        // 整球盘但给了半球数
        vm.expectRevert(abi.encodeWithSelector(IAH_Template.InvalidHandicap.selector, HANDICAP_HALF));
        new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_HALF,
            IAH_Template.HandicapType.WHOLE, // 类型不匹配
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    // ============================================================================
    // Betting Tests - Half Handicap
    // ============================================================================

    function test_PlaceBet_HalfHandicap_HomeCover() public {
        uint256 betAmount = 1000e6; // 1000 USDC

        // Mint USDC to user1
        deal(address(usdc), user1, betAmount);

        // Approve market
        vm.prank(user1);
        usdc.approve(address(market), betAmount);

        // Place bet on Home Cover
        vm.prank(user1);
        uint256 shares = market.placeBet(HOME_COVER, betAmount);

        assertGt(shares, 0, "Should receive shares");
        assertEq(market.balanceOf(user1, HOME_COVER), shares, "User balance mismatch");
    }

    function test_PlaceBet_HalfHandicap_AwayCover() public {
        uint256 betAmount = 1000e6;

        deal(address(usdc), user1, betAmount);
        vm.prank(user1);
        usdc.approve(address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(AWAY_COVER, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, AWAY_COVER), shares);
    }

    function test_PlaceBet_HalfHandicap_RevertIf_BetOnPush() public {
        uint256 betAmount = 1000e6;

        deal(address(usdc), user1, betAmount);
        vm.prank(user1);
        usdc.approve(address(market), betAmount);

        // 半球盘不允许下注 Push (outcomeCount=2, PUSH=2 超出范围)
        // MarketBase 会先检查 outcomeId < outcomeCount
        vm.expectRevert("MarketBase: Invalid outcome");
        vm.prank(user1);
        market.placeBet(PUSH, betAmount);
    }

    // ============================================================================
    // Betting Tests - Whole Handicap
    // ============================================================================

    function test_PlaceBet_WholeHandicap_AllOutcomes() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        uint256 betAmount = 1000e6;
        deal(address(usdc), user1, betAmount * 3);

        // 可以下注三个结果（包括 Push）
        vm.startPrank(user1);
        usdc.approve(address(wholeMarket), betAmount * 3);

        uint256 sharesHome = wholeMarket.placeBet(HOME_COVER, betAmount);
        uint256 sharesAway = wholeMarket.placeBet(AWAY_COVER, betAmount);
        uint256 sharesPush = wholeMarket.placeBet(PUSH, betAmount);

        vm.stopPrank();

        assertGt(sharesHome, 0);
        assertGt(sharesAway, 0);
        // Push 为 1:1，但是扣除了手续费（2%）
        // sharesPush = betAmount - fee = 1000e6 - 20e6 = 980e6
        uint256 expectedPushShares = betAmount - (betAmount * DEFAULT_FEE_RATE / 10000);
        assertEq(sharesPush, expectedPushShares, "Push shares should equal net amount after fee");
    }

    // ============================================================================
    // Score Calculation Tests
    // ============================================================================

    function test_CalculateAdjustedScore_HomeGiveHalf() public {
        // 主队让 0.5 球：主队 2:1 客队
        (int256 adjustedHome, int256 adjustedAway) = market.calculateAdjustedScore(2, 1);

        // 调整后：(2 - 0.5) vs 1 → 1.5 vs 1.0 (千分位：1500 vs 1000)
        assertEq(adjustedHome, 2 * 1000 - 500); // 1500
        assertEq(adjustedAway, 1 * 1000); // 1000
    }

    function test_CalculateAdjustedScore_HomeGiveWhole() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        // 主队让 1.0 球：主队 2:1 客队
        (int256 adjustedHome, int256 adjustedAway) = wholeMarket.calculateAdjustedScore(2, 1);

        // 调整后：(2 - 1.0) vs 1 → 1.0 vs 1.0 (千分位：1000 vs 1000)
        assertEq(adjustedHome, 2 * 1000 - 1000); // 1000
        assertEq(adjustedAway, 1 * 1000); // 1000
    }

    // ============================================================================
    // Outcome Determination Tests
    // ============================================================================

    function test_DetermineOutcome_HalfHandicap_HomeCover() public {
        // 主队 2:1 客队，让0.5球 → 调整后 1.5:1 → 主队赢盘
        (int256 adjustedHome, int256 adjustedAway) = market.calculateAdjustedScore(2, 1);
        uint256 outcome = market.determineOutcome(adjustedHome, adjustedAway);

        assertEq(outcome, HOME_COVER);
    }

    function test_DetermineOutcome_HalfHandicap_AwayCover() public {
        // 主队 1:1 客队，让0.5球 → 调整后 0.5:1 → 客队赢盘
        (int256 adjustedHome, int256 adjustedAway) = market.calculateAdjustedScore(1, 1);
        uint256 outcome = market.determineOutcome(adjustedHome, adjustedAway);

        assertEq(outcome, AWAY_COVER);
    }

    function test_DetermineOutcome_WholeHandicap_HomeCover() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        // 主队 3:1 客队，让1球 → 调整后 2:1 → 主队赢盘
        (int256 adjustedHome, int256 adjustedAway) = wholeMarket.calculateAdjustedScore(3, 1);
        uint256 outcome = wholeMarket.determineOutcome(adjustedHome, adjustedAway);

        assertEq(outcome, HOME_COVER);
    }

    function test_DetermineOutcome_WholeHandicap_Push() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        // 主队 2:1 客队，让1球 → 调整后 1:1 → 退款
        (int256 adjustedHome, int256 adjustedAway) = wholeMarket.calculateAdjustedScore(2, 1);
        uint256 outcome = wholeMarket.determineOutcome(adjustedHome, adjustedAway);

        assertEq(outcome, PUSH);
    }

    function test_DetermineOutcome_WholeHandicap_AwayCover() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        // 主队 1:1 客队，让1球 → 调整后 0:1 → 客队赢盘
        (int256 adjustedHome, int256 adjustedAway) = wholeMarket.calculateAdjustedScore(1, 1);
        uint256 outcome = wholeMarket.determineOutcome(adjustedHome, adjustedAway);

        assertEq(outcome, AWAY_COVER);
    }

    // ============================================================================
    // Settlement Tests
    // ============================================================================

    function test_Settle_HalfHandicap_HomeCover() public {
        // Place some bets first
        uint256 betAmount = 1000e6;
        deal(address(usdc), user1, betAmount);
        vm.prank(user1);
        usdc.approve(address(market), betAmount);
        vm.prank(user1);
        market.placeBet(HOME_COVER, betAmount);

        // Lock market
        vm.warp(kickoffTime);
        market.lock();

        // Settle: 主队 2:1 客队，让0.5球 → 主队赢盘
        vm.expectEmit(true, false, false, true);
        emit AHSettled(
            MATCH_ID,
            2,
            1,
            int256(2 * 1000 - 500), // 1500
            int256(1 * 1000), // 1000
            HOME_COVER
        );

        market.settle(2, 1);

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(market.winningOutcome(), HOME_COVER);
    }

    function test_Settle_WholeHandicap_Push() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        // Lock and settle
        vm.warp(kickoffTime);
        wholeMarket.lock();

        vm.expectEmit(true, false, false, true);
        emit AHSettled(
            MATCH_ID,
            2,
            1,
            int256(2 * 1000 - 1000), // 1000
            int256(1 * 1000), // 1000
            PUSH
        );

        wholeMarket.settle(2, 1);

        assertEq(wholeMarket.winningOutcome(), PUSH);
    }

    function test_Settle_RevertIf_NotLocked() public {
        vm.expectRevert("Market not locked");
        market.settle(2, 1);
    }

    function test_Settle_RevertIf_NotOwner() public {
        vm.warp(kickoffTime);
        market.lock();

        vm.prank(user1);
        vm.expectRevert();
        market.settle(2, 1);
    }

    // ============================================================================
    // Edge Cases and Fuzz Tests
    // ============================================================================

    function testFuzz_CalculateAdjustedScore(uint8 homeScore, uint8 awayScore) public {
        vm.assume(homeScore <= 20);
        vm.assume(awayScore <= 20);

        (int256 adjustedHome, int256 adjustedAway) = market.calculateAdjustedScore(homeScore, awayScore);

        // 验证计算正确性
        assertEq(adjustedHome, int256(uint256(homeScore)) * 1000 + HANDICAP_HALF);
        assertEq(adjustedAway, int256(uint256(awayScore)) * 1000);
    }

    function test_HandicapDirection_AwayGive() public {
        // 主队受让 0.5 球（客队让球）
        AH_Template awayGiveMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            500, // +0.5 (主队受让)
            IAH_Template.HandicapType.HALF,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        assertEq(
            uint256(awayGiveMarket.getHandicapDirection()),
            uint256(IAH_Template.HandicapDirection.AWAY_GIVE)
        );
    }

    function test_OutcomeNames_HalfHandicap() public view {
        assertEq(market.outcomeNames(0), "Home Cover");
        assertEq(market.outcomeNames(1), "Away Cover");
    }

    function test_OutcomeNames_WholeHandicap() public {
        AH_Template wholeMarket = new AH_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            HANDICAP_WHOLE,
            IAH_Template.HandicapType.WHOLE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        assertEq(wholeMarket.outcomeNames(0), "Home Cover");
        assertEq(wholeMarket.outcomeNames(1), "Away Cover");
        assertEq(wholeMarket.outcomeNames(2), "Push");
    }

    // ============================================================================
    // Pricing Engine Management Tests
    // ============================================================================

    function test_SetPricingEngine_Success() public {
        address newEngine = makeAddr("newEngine");

        vm.expectEmit(true, true, false, false);
        emit PricingEngineUpdated(address(cpmm), newEngine);

        market.setPricingEngine(newEngine);

        assertEq(address(market.pricingEngine()), newEngine);
    }

    function test_SetPricingEngine_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        market.setPricingEngine(makeAddr("newEngine"));
    }

    function test_SetPricingEngine_RevertIf_MarketNotOpen() public {
        vm.warp(kickoffTime);
        market.lock();

        vm.expectRevert("Market not open");
        market.setPricingEngine(makeAddr("newEngine"));
    }

    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);
}
