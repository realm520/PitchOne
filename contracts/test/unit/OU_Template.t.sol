// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/OU_Template.sol";
import "../../src/interfaces/IMarket.sol";

/**
 * @title OU_TemplateTest
 * @notice Unit tests for OU_Template market contract (Over/Under markets)
 */
contract OU_TemplateTest is BaseTest {
    OU_Template public market;

    // Market parameters
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;
    uint256 constant LINE = 2500; // 2.5 goals
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // Outcomes
    uint256 constant OVER = 0;
    uint256 constant UNDER = 1;

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256 line,
        address pricingEngine
    );

    event BetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    event Locked(uint256 timestamp);
    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);
    event Finalized(uint256 timestamp);
    event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout);

    function setUp() public override {
        super.setUp();

        // Set kickoff time to 2 hours from now
        kickoffTime = block.timestamp + 2 hours;

        // Deploy OU market (2.5 goals line)
        market = new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );

        vm.label(address(market), "OU_Market");
    }

    // ============ Constructor and Initialization Tests ============

    function test_Constructor_Success() public {
        assertEq(market.matchId(), MATCH_ID);
        assertEq(market.homeTeam(), HOME_TEAM);
        assertEq(market.awayTeam(), AWAY_TEAM);
        assertEq(market.kickoffTime(), kickoffTime);
        assertEq(market.line(), LINE);
        assertEq(address(market.pricingEngine()), address(cpmm));
        assertEq(market.outcomeCount(), 2); // Over, Under (half line only)
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));
    }

    function test_Constructor_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MarketCreated(MATCH_ID, HOME_TEAM, AWAY_TEAM, kickoffTime, LINE, address(cpmm));

        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_IntegerLine() public {
        uint256 integerLine = 2000; // 2.0 goals (integer line)
        vm.expectRevert("OU: Only half lines allowed");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            integerLine,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidMatchId() public {
        vm.expectRevert("OU: Invalid match ID");
        new OU_Template(
            "",
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidHomeTeam() public {
        vm.expectRevert("OU: Invalid home team");
        new OU_Template(
            MATCH_ID,
            "",
            AWAY_TEAM,
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidAwayTeam() public {
        vm.expectRevert("OU: Invalid away team");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            "",
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_KickoffTimeInPast() public {
        vm.expectRevert("OU: Kickoff time in past");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            block.timestamp - 1,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidLine_Zero() public {
        vm.expectRevert("OU: Invalid line");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            0,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidLine_TooHigh() public {
        vm.expectRevert("OU: Invalid line");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            20001, // > 20.0
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
    }

    function testRevert_Constructor_InvalidPricingEngine() public {
        vm.expectRevert("OU: Invalid pricing engine");
        new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            LINE,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(0),
            URI
        );
    }

    // ============ Betting Tests ============

    function test_PlaceBet_Over() public {
        uint256 betAmount = 1000e6; // 1000 USDC

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(OVER, betAmount);

        assertGt(shares, 0, "Should receive shares");
        assertEq(market.balanceOf(user1, OVER), shares, "User should have shares");
        assertGt(market.outcomeLiquidity(OVER), 0, "Liquidity should increase");
    }

    function test_PlaceBet_Under() public {
        uint256 betAmount = 500e6;

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(UNDER, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, UNDER), shares);
    }

    function test_PlaceBet_MultipleBets() public {
        uint256 bet1 = 1000e6;
        uint256 bet2 = 1500e6;

        // User1 bets on Over
        approveMarket(user1, address(market), bet1);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(OVER, bet1);

        // User2 bets on Under
        approveMarket(user2, address(market), bet2);
        vm.prank(user2);
        uint256 shares2 = market.placeBet(UNDER, bet2);

        assertEq(market.balanceOf(user1, OVER), shares1);
        assertEq(market.balanceOf(user2, UNDER), shares2);
        assertGt(market.totalLiquidity(), 0);
    }

    function testRevert_PlaceBet_InvalidOutcome() public {
        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid outcome");
        market.placeBet(2, betAmount); // Outcome 2 doesn't exist (only 0 and 1)
    }

    function testRevert_PlaceBet_ZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("MarketBase: Zero amount");
        market.placeBet(OVER, 0);
    }

    function testRevert_PlaceBet_AfterLock() public {
        // Lock the market
        market.lock();

        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.placeBet(OVER, betAmount);
    }

    // ============ Price Query Tests ============

    function test_GetCurrentPrice_InitialState() public {
        // Before any bets, both outcomes should have equal probability
        uint256 priceOver = market.getCurrentPrice(OVER);
        uint256 priceUnder = market.getCurrentPrice(UNDER);

        assertApproxEqAbs(priceOver, 5000, 10); // ~50%
        assertApproxEqAbs(priceUnder, 5000, 10); // ~50%
    }

    function test_GetCurrentPrice_AfterBets() public {
        uint256 betAmount = 1000e6;

        // Place balanced bets
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(OVER, betAmount);

        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        market.placeBet(UNDER, betAmount);

        // Now place large bet on Over
        uint256 largeBet = 5000e6;
        approveMarket(user1, address(market), largeBet);
        vm.prank(user1);
        market.placeBet(OVER, largeBet);

        // Get prices after skewed betting
        uint256 priceOver = market.getCurrentPrice(OVER);
        uint256 priceUnder = market.getCurrentPrice(UNDER);

        // Over should be cheaper (more reserve) after heavy betting
        assertLt(priceOver, priceUnder, "Over should be cheaper after heavy betting");

        // Prices should sum to 100%
        assertApproxEqAbs(priceOver + priceUnder, 10000, 10);
    }

    function test_GetAllPrices() public {
        uint256[2] memory prices = market.getAllPrices();

        // Prices should sum to approximately 100%
        uint256 sum = prices[0] + prices[1];
        assertApproxEqAbs(sum, 10000, 10);
    }

    // ============ Market Info Tests ============

    function test_GetMarketInfo() public {
        (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            uint256 _line,
            IMarket.MarketStatus _status
        ) = market.getMarketInfo();

        assertEq(_matchId, MATCH_ID);
        assertEq(_homeTeam, HOME_TEAM);
        assertEq(_awayTeam, AWAY_TEAM);
        assertEq(_kickoffTime, kickoffTime);
        assertEq(_line, LINE);
        assertEq(uint256(_status), uint256(IMarket.MarketStatus.Open));
    }

    function test_GetLineDisplay() public {
        (uint256 integer, uint256 decimal) = market.getLineDisplay();
        assertEq(integer, 2); // 2.5 → integer = 2
        assertEq(decimal, 500); // 2.5 → decimal = 500
    }

    // ============ Locking Tests ============

    function test_Lock_ManualByOwner() public {
        vm.expectEmit(false, false, false, true);
        emit Locked(block.timestamp);

        market.lock();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
        assertEq(market.lockTimestamp(), block.timestamp);
    }

    function test_AutoLock_BeforeKickoff() public {
        // Advance time to 4 minutes before kickoff
        skipTime(2 hours - 4 minutes);

        vm.expectEmit(false, false, false, true);
        emit Locked(block.timestamp);

        market.autoLock();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
    }

    function test_ShouldLock_ReturnsTrue() public {
        // Advance to lock time (5 minutes before kickoff)
        skipTime(2 hours - 4 minutes);

        assertTrue(market.shouldLock(), "Should return true when lock time reached");
    }

    function test_ShouldLock_ReturnsFalse() public {
        assertFalse(market.shouldLock(), "Should return false before lock time");
    }

    function testRevert_AutoLock_TooEarly() public {
        vm.expectRevert("OU: Too early to lock");
        market.autoLock();
    }

    function testRevert_AutoLock_AlreadyLocked() public {
        market.lock();

        skipTime(2 hours);

        vm.expectRevert("OU: Market not open");
        market.autoLock();
    }

    function testRevert_Lock_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        market.lock();
    }

    function testRevert_Lock_AlreadyLocked() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid status");
        market.lock();
    }

    // ============ Resolution Tests ============

    function test_Resolve_Over() public {
        // Lock market first
        market.lock();

        vm.expectEmit(true, false, false, true);
        emit Resolved(OVER, block.timestamp);

        market.resolve(OVER);

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(market.winningOutcome(), OVER);
    }

    function test_Resolve_Under() public {
        market.lock();

        market.resolve(UNDER);

        assertEq(market.winningOutcome(), UNDER);
    }

    function testRevert_Resolve_NotLocked() public {
        vm.expectRevert("MarketBase: Invalid status");
        market.resolve(OVER);
    }

    function testRevert_Resolve_InvalidOutcome() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid outcome");
        market.resolve(2); // Outcome 2 doesn't exist (valid: 0, 1)
    }

    function testRevert_Resolve_NotOwner() public {
        market.lock();

        vm.prank(user1);
        vm.expectRevert();
        market.resolve(OVER);
    }

    // ============ Finalization Tests ============

    function test_Finalize_AfterDisputePeriod() public {
        market.lock();
        market.resolve(OVER);

        // Advance past dispute period
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);

        vm.expectEmit(false, false, false, true);
        emit Finalized(block.timestamp);

        market.finalize();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized));
    }

    function testRevert_Finalize_DisputePeriodNotEnded() public {
        market.lock();
        market.resolve(OVER);

        // Try to finalize before dispute period ends
        vm.expectRevert("MarketBase: Dispute period not ended");
        market.finalize();
    }

    function testRevert_Finalize_NotResolved() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid status");
        market.finalize();
    }

    // ============ Redemption Tests ============

    function test_Redeem_WinningOutcome_Over() public {
        uint256 betAmount = 1000e6;

        // User1 bets on Over
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(OVER, betAmount);

        // User2 bets on Under (losing bet)
        approveMarket(user2, address(market), betAmount * 2);
        vm.prank(user2);
        market.placeBet(UNDER, betAmount * 2);

        // Lock, resolve (Over wins), finalize
        market.lock();
        market.resolve(OVER);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        // User1 redeems winning shares
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        uint256 payout = market.redeem(OVER, shares);

        uint256 balanceAfter = usdc.balanceOf(user1);

        assertGt(payout, 0, "Should receive payout");
        assertEq(balanceAfter - balanceBefore, payout, "Balance should increase by payout");
    }

    function testRevert_Redeem_LosingOutcome() public {
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(UNDER, betAmount);

        market.lock();
        market.resolve(OVER); // Over wins
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(UNDER, shares);
    }

    function testRevert_Redeem_BeforeFinalization() public {
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(OVER, betAmount);

        market.lock();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.redeem(OVER, shares);
    }

    // ============ Admin Function Tests ============

    function test_SetPricingEngine() public {
        SimpleCPMM newEngine = new SimpleCPMM();

        market.setPricingEngine(address(newEngine));

        assertEq(address(market.pricingEngine()), address(newEngine));
    }

    function testRevert_SetPricingEngine_AfterLock() public {
        market.lock();

        SimpleCPMM newEngine = new SimpleCPMM();

        vm.expectRevert("MarketBase: Invalid status");
        market.setPricingEngine(address(newEngine));
    }

    function testRevert_SetPricingEngine_InvalidAddress() public {
        vm.expectRevert("OU: Invalid pricing engine");
        market.setPricingEngine(address(0));
    }

    // ============ Integration Tests ============

    function test_FullLifecycle_OverWins() public {
        uint256 bet1 = 1000e6;
        uint256 bet2 = 2000e6;

        // 1. Multiple users place bets
        approveMarket(user1, address(market), bet1);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(OVER, bet1);

        approveMarket(user2, address(market), bet2);
        vm.prank(user2);
        uint256 shares2 = market.placeBet(UNDER, bet2);

        // 2. Market locks
        market.lock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));

        // 3. Market resolves (Over wins)
        market.resolve(OVER);
        assertEq(market.winningOutcome(), OVER);

        // 4. Dispute period passes
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);

        // 5. Market finalizes
        market.finalize();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized));

        // 6. Winner (user1) redeems
        vm.prank(user1);
        uint256 payout1 = market.redeem(OVER, shares1);
        assertGt(payout1, 0, "Should receive payout");

        // 7. Loser cannot redeem
        vm.prank(user2);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(UNDER, shares2);
    }

    function test_FullLifecycle_UnderWins() public {
        uint256 betAmount = 1000e6;

        // Bets on both outcomes
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(OVER, betAmount);

        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        uint256 underShares = market.placeBet(UNDER, betAmount);

        // Complete lifecycle with Under winning
        market.lock();
        market.resolve(UNDER);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        // Only Under holder can redeem
        vm.prank(user2);
        uint256 payout = market.redeem(UNDER, underShares);
        assertGt(payout, 0);
    }

    // ============ Half Line Only - No Push Scenarios ============

    function test_HalfLine_OnlyOverOrUnder() public {
        // 半球盘 (2.5) 只能结算为 Over 或 Under

        // 只能结算为 Over 或 Under
        market.lock();
        market.resolve(OVER); // 正常

        assertEq(market.winningOutcome(), OVER);
    }

    function testRevert_InvalidOutcome_GetCurrentPrice() public {
        vm.expectRevert("OU: Invalid outcome");
        market.getCurrentPrice(2); // Outcome 2 doesn't exist
    }
}
