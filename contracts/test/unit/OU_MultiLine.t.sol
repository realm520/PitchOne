// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/OU_MultiLine.sol";
import "../../src/pricing/LinkedLinesController.sol";
import "../../src/governance/ParamController.sol";
import "../../src/interfaces/IMarket.sol";

/**
 * @title OU_MultiLineTest
 * @notice Unit tests for OU_MultiLine market contract (Multi-line Over/Under markets)
 */
contract OU_MultiLineTest is BaseTest {
    OU_MultiLine public market;
    LinkedLinesController public linkedController;
    ParamController public paramController;

    // Market parameters
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;
    uint256[] private testLines; // 2.0, 2.5, 3.0 goals
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // Outcomes
    uint256 constant OVER = 0;
    uint256 constant UNDER = 1;
    uint256 constant PUSH = 2;

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256[] lines,
        bytes32 groupId,
        address pricingEngine,
        address linkedLinesController
    );

    event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee);

    event Locked(uint256 timestamp);
    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);
    event Finalized(uint256 timestamp);
    event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout);

    function setUp() public override {
        super.setUp();

        // Set kickoff time to 2 hours from now
        kickoffTime = block.timestamp + 2 hours;

        // Setup test lines: 2.0, 2.5, 3.0 goals
        testLines.push(2000);
        testLines.push(2500);
        testLines.push(3000);

        // Deploy ParamController
        paramController = new ParamController(owner, 2 days);

        // Deploy LinkedLinesController
        linkedController = new LinkedLinesController(owner, address(paramController));

        // Deploy OU_MultiLine market
        OU_MultiLine.ConstructorParams memory params = OU_MultiLine.ConstructorParams({
            matchId: MATCH_ID,
            homeTeam: HOME_TEAM,
            awayTeam: AWAY_TEAM,
            kickoffTime: kickoffTime,
            lines: testLines,
            settlementToken: address(usdc),
            feeRecipient: address(feeRouter),
            feeRate: DEFAULT_FEE_RATE,
            disputePeriod: DEFAULT_DISPUTE_PERIOD,
            pricingEngine: address(cpmm),
            linkedLinesController: address(linkedController),
            uri: URI
        });

        market = new OU_MultiLine(params);

        vm.label(address(market), "OU_MultiLine_Market");
        vm.label(address(linkedController), "LinkedLinesController");
        vm.label(address(paramController), "ParamController");
    }

    // ============ Constructor and Initialization Tests ============

    function test_Constructor_Success() public {
        assertEq(market.matchId(), MATCH_ID);
        assertEq(market.homeTeam(), HOME_TEAM);
        assertEq(market.awayTeam(), AWAY_TEAM);
        assertEq(market.kickoffTime(), kickoffTime);
        assertEq(address(market.pricingEngine()), address(cpmm));
        assertEq(address(market.linkedLinesController()), address(linkedController));
        assertEq(market.outcomeCount(), 9); // 3 lines * 3 outcomes
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));

        // Check lines
        uint256[] memory lines = market.getLines();
        assertEq(lines.length, 3);
        assertEq(lines[0], 2000);
        assertEq(lines[1], 2500);
        assertEq(lines[2], 3000);
    }

    function test_Constructor_EmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit MarketCreated(
            MATCH_ID, HOME_TEAM, AWAY_TEAM, kickoffTime, testLines, bytes32(0), address(cpmm), address(linkedController)
        );

        OU_MultiLine.ConstructorParams memory params = OU_MultiLine.ConstructorParams({
            matchId: MATCH_ID,
            homeTeam: HOME_TEAM,
            awayTeam: AWAY_TEAM,
            kickoffTime: kickoffTime,
            lines: testLines,
            settlementToken: address(usdc),
            feeRecipient: address(feeRouter),
            feeRate: DEFAULT_FEE_RATE,
            disputePeriod: DEFAULT_DISPUTE_PERIOD,
            pricingEngine: address(cpmm),
            linkedLinesController: address(linkedController),
            uri: URI
        });

        new OU_MultiLine(params);
    }

    function test_Constructor_CheckLineTypes() public {
        assertFalse(market.isHalfLine(2000)); // 2.0 is integer line
        assertTrue(market.isHalfLine(2500)); // 2.5 is half line
        assertFalse(market.isHalfLine(3000)); // 3.0 is integer line
    }

    function testRevert_Constructor_NoLines() public {
        uint256[] memory emptyLines = new uint256[](0);

        OU_MultiLine.ConstructorParams memory params = OU_MultiLine.ConstructorParams({
            matchId: MATCH_ID,
            homeTeam: HOME_TEAM,
            awayTeam: AWAY_TEAM,
            kickoffTime: kickoffTime,
            lines: emptyLines,
            settlementToken: address(usdc),
            feeRecipient: address(feeRouter),
            feeRate: DEFAULT_FEE_RATE,
            disputePeriod: DEFAULT_DISPUTE_PERIOD,
            pricingEngine: address(cpmm),
            linkedLinesController: address(linkedController),
            uri: URI
        });

        // MarketBase checks outcomeCount first, so it will revert with "Invalid outcome count"
        vm.expectRevert("MarketBase: Invalid outcome count");
        new OU_MultiLine(params);
    }

    function testRevert_Constructor_LinesNotSorted() public {
        uint256[] memory unsortedLines = new uint256[](3);
        unsortedLines[0] = 3000;
        unsortedLines[1] = 2000; // Wrong order
        unsortedLines[2] = 2500;

        OU_MultiLine.ConstructorParams memory params = OU_MultiLine.ConstructorParams({
            matchId: MATCH_ID,
            homeTeam: HOME_TEAM,
            awayTeam: AWAY_TEAM,
            kickoffTime: kickoffTime,
            lines: unsortedLines,
            settlementToken: address(usdc),
            feeRecipient: address(feeRouter),
            feeRate: DEFAULT_FEE_RATE,
            disputePeriod: DEFAULT_DISPUTE_PERIOD,
            pricingEngine: address(cpmm),
            linkedLinesController: address(linkedController),
            uri: URI
        });

        vm.expectRevert(OU_MultiLine.LinesNotSorted.selector);
        new OU_MultiLine(params);
    }

    // ============ Outcome ID Encoding/Decoding Tests ============

    function test_EncodeDecodeOutcomeId() public {
        // Line 0 (2.0 goals)
        assertEq(market.encodeOutcomeId(0, OVER), 0);
        assertEq(market.encodeOutcomeId(0, UNDER), 1);
        assertEq(market.encodeOutcomeId(0, PUSH), 2);

        // Line 1 (2.5 goals)
        assertEq(market.encodeOutcomeId(1, OVER), 3);
        assertEq(market.encodeOutcomeId(1, UNDER), 4);
        assertEq(market.encodeOutcomeId(1, PUSH), 5);

        // Line 2 (3.0 goals)
        assertEq(market.encodeOutcomeId(2, OVER), 6);
        assertEq(market.encodeOutcomeId(2, UNDER), 7);
        assertEq(market.encodeOutcomeId(2, PUSH), 8);

        // Decode test
        (uint256 lineIndex, uint256 direction) = market.decodeOutcomeId(4);
        assertEq(lineIndex, 1);
        assertEq(direction, UNDER);
    }

    // ============ Betting Tests ============

    function test_PlaceBet_FirstLine_Over() public {
        uint256 betAmount = 100e6; // 100 USDC
        uint256 outcomeId = market.encodeOutcomeId(0, OVER); // 2.0 OVER

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectEmit(true, true, false, false);
        emit BetPlaced(user1, outcomeId, betAmount, 0, 0);
        market.placeBet(outcomeId, betAmount);

        assertGt(market.balanceOf(user1, outcomeId), 0);
    }

    function test_PlaceBet_SecondLine_Under() public {
        uint256 betAmount = 200e6; // 200 USDC
        uint256 outcomeId = market.encodeOutcomeId(1, UNDER); // 2.5 UNDER

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        market.placeBet(outcomeId, betAmount);

        assertGt(market.balanceOf(user1, outcomeId), 0);
    }

    function test_PlaceBet_ThirdLine_Over() public {
        uint256 betAmount = 150e6; // 150 USDC
        uint256 outcomeId = market.encodeOutcomeId(2, OVER); // 3.0 OVER

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        market.placeBet(outcomeId, betAmount);

        assertGt(market.balanceOf(user1, outcomeId), 0);
    }

    function testRevert_PlaceBet_OnPush() public {
        uint256 betAmount = 100e6;
        uint256 outcomeId = market.encodeOutcomeId(0, PUSH); // Cannot bet on PUSH

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert(OU_MultiLine.CannotBetOnPush.selector);
        market.placeBet(outcomeId, betAmount);
    }

    function test_PlaceBet_MultipleLinesMultipleUsers() public {
        uint256 betAmount = 100e6;

        // User1 bets on 2.0 OVER
        uint256 outcome1 = market.encodeOutcomeId(0, OVER);
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(outcome1, betAmount);

        // User2 bets on 2.5 UNDER
        uint256 outcome2 = market.encodeOutcomeId(1, UNDER);
        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        market.placeBet(outcome2, betAmount);

        // User3 bets on 3.0 OVER
        uint256 outcome3 = market.encodeOutcomeId(2, OVER);
        approveMarket(user3, address(market), betAmount);
        vm.prank(user3);
        market.placeBet(outcome3, betAmount);

        // Check balances
        assertGt(market.balanceOf(user1, outcome1), 0);
        assertGt(market.balanceOf(user2, outcome2), 0);
        assertGt(market.balanceOf(user3, outcome3), 0);
    }

    // ============ Price Query Tests ============

    function test_GetCurrentPrice() public {
        // Initial price should be around 50% (5000 bp) for balanced reserves
        uint256 price = market.getCurrentPrice(market.encodeOutcomeId(0, OVER));
        assertApproxEqRel(price, 5000, 0.1e18); // 10% tolerance for initial state
    }

    function test_GetAllLinePrices() public {
        uint256[] memory overPrices = market.getAllLinePrices(OVER);
        uint256[] memory underPrices = market.getAllLinePrices(UNDER);

        assertEq(overPrices.length, 3);
        assertEq(underPrices.length, 3);

        // All prices should be around 50% initially
        for (uint256 i = 0; i < overPrices.length; i++) {
            assertApproxEqRel(overPrices[i], 5000, 0.1e18);
            assertApproxEqRel(underPrices[i], 5000, 0.1e18);
        }
    }

    function test_GetAllLinePrices_AfterBets() public {
        // Place bet on first line OVER
        uint256 betAmount = 500e6;
        uint256 outcomeId = market.encodeOutcomeId(0, OVER);
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(outcomeId, betAmount);

        uint256[] memory overPrices = market.getAllLinePrices(OVER);

        // First line OVER price should decrease after buying
        assertLt(overPrices[0], 5000);
    }

    // ============ Market Info Tests ============

    function test_GetMarketInfo() public {
        (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            uint256[] memory _lines,
            bytes32 _groupId,
            IMarket.MarketStatus _status
        ) = market.getMarketInfo();

        assertEq(_matchId, MATCH_ID);
        assertEq(_homeTeam, HOME_TEAM);
        assertEq(_awayTeam, AWAY_TEAM);
        assertEq(_kickoffTime, kickoffTime);
        assertEq(_lines.length, 3);
        assertEq(_lines[0], 2000);
        assertEq(uint256(_status), uint256(IMarket.MarketStatus.Open));
        assertTrue(_groupId != bytes32(0));
    }

    function test_GetLines() public {
        uint256[] memory lines = market.getLines();
        assertEq(lines.length, 3);
        assertEq(lines[0], 2000);
        assertEq(lines[1], 2500);
        assertEq(lines[2], 3000);
    }

    // ============ Locking Tests ============

    function test_ShouldLock_True() public {
        vm.warp(kickoffTime - 4 minutes);
        assertTrue(market.shouldLock());
    }

    function test_ShouldLock_False() public {
        vm.warp(kickoffTime - 10 minutes);
        assertFalse(market.shouldLock());
    }

    function test_AutoLock_Success() public {
        vm.warp(kickoffTime - 4 minutes);

        vm.expectEmit(false, false, false, true);
        emit Locked(block.timestamp);
        market.autoLock();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
    }

    function testRevert_AutoLock_TooEarly() public {
        vm.warp(kickoffTime - 10 minutes);

        vm.expectRevert("OU_ML: Too early to lock");
        market.autoLock();
    }

    // ============ Management Function Tests ============

    function test_SetPricingEngine() public {
        SimpleCPMM newCpmm = new SimpleCPMM();

        market.setPricingEngine(address(newCpmm));

        assertEq(address(market.pricingEngine()), address(newCpmm));
    }

    function testRevert_SetPricingEngine_NotOwner() public {
        SimpleCPMM newCpmm = new SimpleCPMM();

        vm.prank(user1);
        vm.expectRevert();
        market.setPricingEngine(address(newCpmm));
    }

    function test_SetLinkedLinesController() public {
        LinkedLinesController newController = new LinkedLinesController(owner, address(paramController));

        market.setLinkedLinesController(address(newController));

        assertEq(address(market.linkedLinesController()), address(newController));
    }

    // ============ Integration Tests ============
    //
    // 注意：当前版本使用 MarketBase 的标准兑付逻辑
    //      完整的多线独立结算将在 V2 实现
    //
    // TODO: Add integration tests for V2:
    // - Full multi-line resolution and redemption
    // - Integer line with PUSH refund
    // - Edge cases
}
