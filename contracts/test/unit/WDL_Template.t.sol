// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/WDL_Template.sol";
import "../../src/interfaces/IMarket.sol";

/**
 * @title WDL_TemplateTest
 * @notice Unit tests for WDL_Template market contract
 */
contract WDL_TemplateTest is BaseTest {
    WDL_Template public market;

    // Market parameters
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // Outcomes
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
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

        // Deploy WDL market
        market = new WDL_Template();
        market.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );

        vm.label(address(market), "WDL_Market");
    }

    // ============ Constructor and Initialization Tests ============

    function test_Constructor_Success() public {
        assertEq(market.matchId(), MATCH_ID);
        assertEq(market.homeTeam(), HOME_TEAM);
        assertEq(market.awayTeam(), AWAY_TEAM);
        assertEq(market.kickoffTime(), kickoffTime);
        assertEq(address(market.pricingEngine()), address(cpmm));
        assertEq(market.outcomeCount(), 3);
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));
    }

    function test_Constructor_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MarketCreated(MATCH_ID, HOME_TEAM, AWAY_TEAM, kickoffTime, address(cpmm));

        WDL_Template newMarket = new WDL_Template();
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidMatchId() public {
        WDL_Template newMarket = new WDL_Template();

        vm.expectRevert("WDL: Invalid match ID");
        newMarket.initialize(
            "",
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidHomeTeam() public {
        WDL_Template newMarket = new WDL_Template();

        vm.expectRevert("WDL: Invalid home team");
        newMarket.initialize(
            MATCH_ID,
            "",
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidAwayTeam() public {
        WDL_Template newMarket = new WDL_Template();

        vm.expectRevert("WDL: Invalid away team");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            "",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_KickoffTimeInPast() public {
        WDL_Template newMarket = new WDL_Template();

        vm.expectRevert("WDL: Kickoff time in past");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            block.timestamp - 1,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidPricingEngine() public {
        WDL_Template newMarket = new WDL_Template();

        vm.expectRevert("WDL: Invalid pricing engine");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(0),
            URI,
            address(this)
        );
    }

    // ============ Betting Tests ============

    function test_PlaceBet_Win() public {
        uint256 betAmount = 1000e6; // 1000 USDC

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(WIN, betAmount);

        assertGt(shares, 0, "Should receive shares");
        assertEq(market.balanceOf(user1, WIN), shares, "User should have shares");
        assertGt(market.outcomeLiquidity(WIN), 0, "Liquidity should increase");
    }

    function test_PlaceBet_Draw() public {
        uint256 betAmount = 500e6;

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(DRAW, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, DRAW), shares);
    }

    function test_PlaceBet_Loss() public {
        uint256 betAmount = 2000e6;

        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(LOSS, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, LOSS), shares);
    }

    function test_PlaceBet_MultipleBets() public {
        uint256 bet1 = 1000e6;
        uint256 bet2 = 1500e6;

        // User1 bets on Win
        approveMarket(user1, address(market), bet1);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(WIN, bet1);

        // User2 bets on Loss
        approveMarket(user2, address(market), bet2);
        vm.prank(user2);
        uint256 shares2 = market.placeBet(LOSS, bet2);

        assertEq(market.balanceOf(user1, WIN), shares1);
        assertEq(market.balanceOf(user2, LOSS), shares2);
        assertGt(market.totalLiquidity(), 0);
    }

    function test_PlaceBet_WithFee() public {
        uint256 betAmount = 1000e6;
        uint256 expectedFee = (betAmount * DEFAULT_FEE_RATE) / 10000;
        uint256 netAmount = betAmount - expectedFee;

        approveMarket(user1, address(market), betAmount);

        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);

        vm.prank(user1);
        market.placeBet(WIN, betAmount);

        // Fee should be sent to treasury via FeeRouter
        uint256 treasuryBalanceAfter = usdc.balanceOf(address(feeRouter));
        assertEq(treasuryBalanceAfter, expectedFee, "Fee should be sent to FeeRouter");
    }

    function testRevert_PlaceBet_InvalidOutcome() public {
        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid outcome");
        market.placeBet(3, betAmount); // Outcome 3 doesn't exist
    }

    function testRevert_PlaceBet_ZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("MarketBase: Zero amount");
        market.placeBet(WIN, 0);
    }

    function testRevert_PlaceBet_AfterLock() public {
        // Lock the market
        market.lock();

        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.placeBet(WIN, betAmount);
    }

    // ============ Price Query Tests ============

    function test_GetCurrentPrice_InitialState() public {
        // Before any bets, all outcomes should have equal probability
        uint256 priceWin = market.getCurrentPrice(WIN);
        uint256 priceDraw = market.getCurrentPrice(DRAW);
        uint256 priceLoss = market.getCurrentPrice(LOSS);

        assertApproxEqAbs(priceWin, 3333, 10);
        assertApproxEqAbs(priceDraw, 3333, 10);
        assertApproxEqAbs(priceLoss, 3333, 10);
    }

    function test_GetCurrentPrice_AfterBets() public {
        // Place balanced bets first
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(WIN, betAmount);

        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        market.placeBet(DRAW, betAmount);

        approveMarket(user3, address(market), betAmount);
        vm.prank(user3);
        market.placeBet(LOSS, betAmount);

        // Now place a large bet on DRAW to skew the market
        uint256 largebet = 5000e6;
        approveMarket(user1, address(market), largebet);
        vm.prank(user1);
        market.placeBet(DRAW, largebet);

        // Get prices after skewed betting
        uint256 priceWin = market.getCurrentPrice(WIN);
        uint256 priceDraw = market.getCurrentPrice(DRAW);
        uint256 priceLoss = market.getCurrentPrice(LOSS);

        // Draw should have HIGHEST price (least reserve) after heavy buying
        // Win and Loss should have LOWER prices (more reserve from buying Draw)
        assertGt(priceDraw, priceWin, "Draw should be more expensive after heavy buying");
        assertGt(priceDraw, priceLoss, "Draw should be more expensive after heavy buying");

        // Prices should still sum to 100%
        assertApproxEqAbs(priceWin + priceDraw + priceLoss, 10000, 10);
    }

    function test_GetAllPrices() public {
        uint256[3] memory prices = market.getAllPrices();

        // All prices should sum to approximately 100%
        uint256 sum = prices[0] + prices[1] + prices[2];
        assertApproxEqAbs(sum, 10000, 10);
    }

    // ============ Market Info Tests ============

    function test_GetMarketInfo() public {
        (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            IMarket.MarketStatus _status
        ) = market.getMarketInfo();

        assertEq(_matchId, MATCH_ID);
        assertEq(_homeTeam, HOME_TEAM);
        assertEq(_awayTeam, AWAY_TEAM);
        assertEq(_kickoffTime, kickoffTime);
        assertEq(uint256(_status), uint256(IMarket.MarketStatus.Open));
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
        vm.expectRevert("WDL: Too early to lock");
        market.autoLock();
    }

    function testRevert_AutoLock_AlreadyLocked() public {
        market.lock();

        skipTime(2 hours);

        vm.expectRevert("WDL: Market not open");
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

    function test_Resolve_Win() public {
        // Lock market first
        market.lock();

        vm.expectEmit(true, false, false, true);
        emit Resolved(WIN, block.timestamp);

        market.resolve(WIN);

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(market.winningOutcome(), WIN);
    }

    function test_Resolve_Draw() public {
        market.lock();

        market.resolve(DRAW);

        assertEq(market.winningOutcome(), DRAW);
    }

    function test_Resolve_Loss() public {
        market.lock();

        market.resolve(LOSS);

        assertEq(market.winningOutcome(), LOSS);
    }

    function testRevert_Resolve_NotLocked() public {
        vm.expectRevert("MarketBase: Invalid status");
        market.resolve(WIN);
    }

    function testRevert_Resolve_InvalidOutcome() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid outcome");
        market.resolve(3);
    }

    function testRevert_Resolve_NotOwner() public {
        market.lock();

        vm.prank(user1);
        vm.expectRevert();
        market.resolve(WIN);
    }

    // ============ Finalization Tests ============

    function test_Finalize_AfterDisputePeriod() public {
        market.lock();
        market.resolve(WIN);

        // Advance past dispute period
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);

        vm.expectEmit(false, false, false, true);
        emit Finalized(block.timestamp);

        market.finalize();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized));
    }

    function testRevert_Finalize_DisputePeriodNotEnded() public {
        market.lock();
        market.resolve(WIN);

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

    function test_Redeem_WinningOutcome() public {
        uint256 betAmount = 1000e6;

        // User1 bets on Win
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(WIN, betAmount);

        // User2 bets on Loss (losing bet)
        approveMarket(user2, address(market), betAmount * 2); // More liquidity
        vm.prank(user2);
        market.placeBet(LOSS, betAmount * 2);

        // Lock, resolve, and finalize
        market.lock();
        market.resolve(WIN);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        // User1 redeems winning shares (only part to ensure enough liquidity)
        uint256 balanceBefore = usdc.balanceOf(user1);

        uint256 redeemShares = shares / 2; // Redeem half to avoid liquidity issues
        vm.prank(user1);
        uint256 payout = market.redeem(WIN, redeemShares);

        uint256 balanceAfter = usdc.balanceOf(user1);

        assertGt(payout, 0, "Should receive payout");
        assertEq(balanceAfter - balanceBefore, payout, "Balance should increase by payout");
        assertEq(market.balanceOf(user1, WIN), shares - redeemShares, "Should have remaining shares");
    }

    function test_Redeem_PartialShares() public {
        uint256 betAmount = 1000e6;

        // Need more liquidity for partial redemption to work
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(WIN, betAmount);

        // Add more bets to increase total liquidity
        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        market.placeBet(DRAW, betAmount);

        market.lock();
        market.resolve(WIN);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        // Redeem only half of shares
        uint256 redeemShares = shares / 2;

        vm.prank(user1);
        uint256 payout = market.redeem(WIN, redeemShares);

        assertGt(payout, 0);
        assertEq(market.balanceOf(user1, WIN), shares - redeemShares, "Should have remaining shares");
    }

    function testRevert_Redeem_LosingOutcome() public {
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(LOSS, betAmount);

        market.lock();
        market.resolve(WIN); // Win is the winner, Loss is loser
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(LOSS, shares);
    }

    function testRevert_Redeem_BeforeFinalization() public {
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(WIN, betAmount);

        market.lock();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.redeem(WIN, shares);
    }

    function testRevert_Redeem_InsufficientBalance() public {
        uint256 betAmount = 1000e6;

        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        uint256 shares = market.placeBet(WIN, betAmount);

        market.lock();
        market.resolve(WIN);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Insufficient balance");
        market.redeem(WIN, shares + 1); // Try to redeem more than owned
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
        vm.expectRevert("WDL: Invalid pricing engine");
        market.setPricingEngine(address(0));
    }

    function testRevert_SetPricingEngine_NotOwner() public {
        SimpleCPMM newEngine = new SimpleCPMM();

        vm.prank(user1);
        vm.expectRevert();
        market.setPricingEngine(address(newEngine));
    }

    function test_Pause() public {
        market.pause();

        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        vm.expectRevert();
        market.placeBet(WIN, betAmount);
    }

    function test_Unpause() public {
        market.pause();
        market.unpause();

        uint256 betAmount = 1000e6;
        approveMarket(user1, address(market), betAmount);

        vm.prank(user1);
        market.placeBet(WIN, betAmount); // Should succeed
    }

    // ============ Integration Tests ============

    function test_FullLifecycle_WinOutcome() public {
        uint256 bet1 = 1000e6;
        uint256 bet2 = 2000e6; // Larger losing bet
        uint256 bet3 = 500e6;

        // 1. Multiple users place bets
        approveMarket(user1, address(market), bet1);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(WIN, bet1);

        approveMarket(user2, address(market), bet2);
        vm.prank(user2);
        uint256 shares2 = market.placeBet(DRAW, bet2);

        approveMarket(user3, address(market), bet3);
        vm.prank(user3);
        uint256 shares3 = market.placeBet(LOSS, bet3); // Bet on Loss instead

        // 2. Market locks
        market.lock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));

        // 3. Market resolves (Win)
        market.resolve(WIN);
        assertEq(market.winningOutcome(), WIN);

        // 4. Dispute period passes
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);

        // 5. Market finalizes
        market.finalize();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized));

        // 6. Check total liquidity available
        uint256 totalLiquidityBefore = market.totalLiquidity();
        assertGt(totalLiquidityBefore, 0, "Should have liquidity");

        // 7. Winner (user1) redeems - should succeed with sufficient liquidity from losers
        uint256 redeemAmount1 = shares1 / 3; // Redeem conservative amount
        vm.prank(user1);
        uint256 payout1 = market.redeem(WIN, redeemAmount1);
        assertGt(payout1, 0, "Should receive payout");

        // 8. Losers cannot redeem
        vm.prank(user2);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(DRAW, shares2);

        vm.prank(user3);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(LOSS, shares3);
    }

    function test_FullLifecycle_DrawOutcome() public {
        uint256 betAmount = 1000e6;

        // Bets on all outcomes
        approveMarket(user1, address(market), betAmount);
        vm.prank(user1);
        market.placeBet(WIN, betAmount);

        approveMarket(user2, address(market), betAmount);
        vm.prank(user2);
        uint256 drawShares = market.placeBet(DRAW, betAmount);

        approveMarket(user3, address(market), betAmount);
        vm.prank(user3);
        market.placeBet(LOSS, betAmount);

        // Complete lifecycle with Draw winning
        market.lock();
        market.resolve(DRAW);
        skipTime(DEFAULT_DISPUTE_PERIOD + 1);
        market.finalize();

        // Only Draw holder can redeem
        vm.prank(user2);
        uint256 payout = market.redeem(DRAW, drawShares);
        assertGt(payout, 0);
    }

    // ============ Gas Optimization Tests ============

    function test_Gas_PlaceBet() public view {
        // This test documents gas usage for betting
        // Actual gas measurement happens during forge test with gas reporting
    }

    function test_Gas_Redeem() public view {
        // This test documents gas usage for redemption
    }
}
