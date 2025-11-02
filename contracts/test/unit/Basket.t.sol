// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/parlay/Basket.sol";
import "../../src/parlay/CorrelationGuard.sol";
import "../../src/templates/WDL_Template.sol";
import "../../src/templates/OU_Template.sol";
import "../../src/interfaces/IBasket.sol";
import "../../src/interfaces/ICorrelationGuard.sol";

/**
 * @title BasketTest
 * @notice Unit tests for Basket (Parlay) contract
 */
contract BasketTest is BaseTest {
    Basket public basket;
    CorrelationGuard public guard;

    // Test markets
    WDL_Template public market1;
    WDL_Template public market2;
    OU_Template public market3;

    // Match IDs
    bytes32 constant MATCH_ID_1 = keccak256("EPL_2024_MUN_vs_MCI");
    bytes32 constant MATCH_ID_2 = keccak256("EPL_2024_LIV_vs_CHE");
    bytes32 constant MATCH_ID_3 = keccak256("EPL_2024_ARS_vs_TOT");

    // Default config
    uint256 constant MIN_ODDS = 11000; // 1.1x
    uint256 constant MAX_ODDS = 1000000; // 100x
    uint256 constant DEFAULT_PENALTY = 2000; // 20%

    event ParlayCreated(
        uint256 indexed parlayId,
        address indexed user,
        ICorrelationGuard.ParlayLeg[] legs,
        uint256 stake,
        uint256 potentialPayout,
        uint256 combinedOdds,
        uint256 penaltyBps
    );

    event ParlaySettled(
        uint256 indexed parlayId,
        address indexed user,
        IBasket.ParlayStatus status,
        uint256 payout
    );

    function setUp() public override {
        super.setUp();

        // Deploy CorrelationGuard
        guard = new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            DEFAULT_PENALTY
        );

        // Deploy Basket
        basket = new Basket(
            address(usdc),
            address(guard),
            MIN_ODDS,
            MAX_ODDS
        );

        vm.label(address(basket), "Basket");
        vm.label(address(guard), "CorrelationGuard");

        // Deploy test markets
        uint256 kickoffTime = block.timestamp + 2 hours;

        market1 = new WDL_Template(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/market1"
        );

        market2 = new WDL_Template(
            "EPL_2024_LIV_vs_CHE",
            "Liverpool",
            "Chelsea",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/market2"
        );

        market3 = new OU_Template(
            "EPL_2024_ARS_vs_TOT",
            "Arsenal",
            "Tottenham",
            kickoffTime,
            2500, // 2.5 goals
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/market3"
        );

        // Register markets in CorrelationGuard
        guard.registerMarket(address(market1), MATCH_ID_1);
        guard.registerMarket(address(market2), MATCH_ID_2);
        guard.registerMarket(address(market3), MATCH_ID_3);

        // Add some initial liquidity to markets (seed the AMM)
        _seedMarketLiquidity(address(market1), 10000e6);
        _seedMarketLiquidity(address(market2), 10000e6);
        _seedMarketLiquidity(address(market3), 10000e6);
    }

    // ============================================================================
    // Constructor Tests
    // ============================================================================

    function test_Constructor_Success() public view {
        assertEq(address(basket.settlementToken()), address(usdc));
        assertEq(address(basket.correlationGuard()), address(guard));
        assertEq(basket.minOdds(), MIN_ODDS);
        assertEq(basket.maxOdds(), MAX_ODDS);
        assertEq(basket.maxLegs(), 10);
    }

    function test_Constructor_RevertIf_InvalidToken() public {
        vm.expectRevert("Invalid settlement token");
        new Basket(
            address(0),
            address(guard),
            MIN_ODDS,
            MAX_ODDS
        );
    }

    function test_Constructor_RevertIf_InvalidGuard() public {
        vm.expectRevert("Invalid correlation guard");
        new Basket(
            address(usdc),
            address(0),
            MIN_ODDS,
            MAX_ODDS
        );
    }

    function test_Constructor_RevertIf_InvalidOddsLimits() public {
        vm.expectRevert("Invalid odds limits");
        new Basket(
            address(usdc),
            address(guard),
            MAX_ODDS,
            MIN_ODDS // min > max
        );
    }

    // ============================================================================
    // Quote Tests
    // ============================================================================

    function test_Quote_TwoLegs_Success() public view {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0}); // MUN wins
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 0}); // LIV wins

        uint256 stake = 1000e6;

        (uint256 combinedOdds, uint256 penaltyBps, uint256 potentialPayout) =
            basket.quote(legs, stake);

        // Each market should have odds around 2.0-3.0x initially
        assertGt(combinedOdds, 10000, "Combined odds should be > 1.0x");
        assertEq(penaltyBps, 0, "No correlation penalty for different matches");
        assertGt(potentialPayout, stake, "Payout should be > stake");
    }

    function test_Quote_ThreeLegs_Success() public view {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](3);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});
        legs[2] = ICorrelationGuard.ParlayLeg({market: address(market3), outcomeId: 0});

        uint256 stake = 1000e6;

        (uint256 combinedOdds,, uint256 potentialPayout) = basket.quote(legs, stake);

        assertGt(combinedOdds, 10000);
        assertGt(potentialPayout, stake);
    }

    function test_Quote_RevertIf_TooFewLegs() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](1);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});

        vm.expectRevert(
            abi.encodeWithSelector(IBasket.InvalidLegCount.selector, 1, 2, 10)
        );
        basket.quote(legs, 1000e6);
    }

    function test_Quote_RevertIf_TooManyLegs() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](11);
        for (uint256 i = 0; i < 11; i++) {
            legs[i] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        }

        vm.expectRevert(
            abi.encodeWithSelector(IBasket.InvalidLegCount.selector, 11, 2, 10)
        );
        basket.quote(legs, 1000e6);
    }

    function test_Quote_SameMatch_AppliesPenalty() public {
        // Set same matchId for both markets
        guard.registerMarket(address(market1), MATCH_ID_1);
        guard.registerMarket(address(market2), MATCH_ID_1);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        (, uint256 penaltyBps,) = basket.quote(legs, 1000e6);

        assertEq(penaltyBps, DEFAULT_PENALTY, "Should apply default same-match penalty");
    }

    function test_Quote_BlockedByCorrelation() public {
        // Set strict block policy
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK);
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 0, true);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 0});

        vm.expectRevert(); // Will revert with ParlayBlocked
        basket.quote(legs, 1000e6);
    }

    // ============================================================================
    // Create Parlay Tests
    // ============================================================================

    function test_CreateParlay_Success() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;

        // Get quote first
        (uint256 combinedOdds, uint256 penaltyBps, uint256 potentialPayout) =
            basket.quote(legs, stake);

        // Prepare funds
        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);

        // Expect event
        vm.expectEmit(true, true, false, false);
        emit ParlayCreated(1, user1, legs, stake, potentialPayout, combinedOdds, penaltyBps);

        // Create parlay
        uint256 parlayId = basket.createParlay(legs, stake, potentialPayout);

        vm.stopPrank();

        // Verify
        assertEq(parlayId, 1);
        assertEq(basket.parlayCounter(), 1);

        IBasket.Parlay memory parlay = basket.getParlay(parlayId);
        assertEq(parlay.user, user1);
        assertEq(parlay.stake, stake);
        assertEq(parlay.potentialPayout, potentialPayout);
        assertEq(parlay.combinedOdds, combinedOdds);
        assertEq(uint256(parlay.status), uint256(IBasket.ParlayStatus.Pending));
    }

    function test_CreateParlay_MultipleUsers() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;
        (, , uint256 minPayout) = basket.quote(legs, stake);

        // User1 creates parlay
        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);
        uint256 parlayId1 = basket.createParlay(legs, stake, minPayout);
        vm.stopPrank();

        // User2 creates parlay
        deal(address(usdc), user2, stake);
        vm.startPrank(user2);
        usdc.approve(address(basket), stake);
        uint256 parlayId2 = basket.createParlay(legs, stake, minPayout);
        vm.stopPrank();

        assertEq(parlayId1, 1);
        assertEq(parlayId2, 2);

        uint256[] memory user1Parlays = basket.getUserParlays(user1);
        uint256[] memory user2Parlays = basket.getUserParlays(user2);

        assertEq(user1Parlays.length, 1);
        assertEq(user2Parlays.length, 1);
        assertEq(user1Parlays[0], parlayId1);
        assertEq(user2Parlays[0], parlayId2);
    }

    function test_CreateParlay_RevertIf_ZeroStake() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        vm.expectRevert(IBasket.ZeroAmount.selector);
        basket.createParlay(legs, 0, 0);
    }

    function test_CreateParlay_RevertIf_SlippageExceeded() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;
        (, , uint256 potentialPayout) = basket.quote(legs, stake);

        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);

        // Set minPayout higher than actual payout
        vm.expectRevert(
            abi.encodeWithSelector(
                IBasket.SlippageExceeded.selector,
                potentialPayout,
                potentialPayout + 1
            )
        );
        basket.createParlay(legs, stake, potentialPayout + 1);

        vm.stopPrank();
    }

    // ============================================================================
    // Settlement Tests
    // ============================================================================

    function test_SettleParlay_Won() public {
        // Create parlay
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0}); // MUN wins
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1}); // Draw

        uint256 stake = 1000e6;
        (, , uint256 potentialPayout) = basket.quote(legs, stake);

        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);
        uint256 parlayId = basket.createParlay(legs, stake, potentialPayout);
        vm.stopPrank();

        // Lock markets
        vm.warp(block.timestamp + 2 hours);
        market1.lock();
        market2.lock();

        // Settle markets with winning outcomes
        market1.resolve(0); // MUN wins ✓
        market2.resolve(1); // Draw ✓

        // Check can settle
        (bool canSettle, IBasket.ParlayStatus expectedStatus) = basket.canSettle(parlayId);
        assertTrue(canSettle);
        assertEq(uint256(expectedStatus), uint256(IBasket.ParlayStatus.Won));

        // Settle parlay
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.expectEmit(true, true, false, true);
        emit ParlaySettled(parlayId, user1, IBasket.ParlayStatus.Won, potentialPayout);

        uint256 payout = basket.settleParlay(parlayId);

        assertEq(payout, potentialPayout);
        assertEq(usdc.balanceOf(user1), balanceBefore + potentialPayout);

        IBasket.Parlay memory parlay = basket.getParlay(parlayId);
        assertEq(uint256(parlay.status), uint256(IBasket.ParlayStatus.Won));
        assertGt(parlay.settledAt, 0);
    }

    function test_SettleParlay_Lost() public {
        // Create parlay
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0}); // MUN wins
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1}); // Draw

        uint256 stake = 1000e6;
        (, , uint256 potentialPayout) = basket.quote(legs, stake);

        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);
        uint256 parlayId = basket.createParlay(legs, stake, potentialPayout);
        vm.stopPrank();

        // Lock and settle markets
        vm.warp(block.timestamp + 2 hours);
        market1.lock();
        market2.lock();

        market1.resolve(0); // MUN wins ✓
        market2.resolve(0); // LIV wins ✗ (expected Draw)

        // Check can settle
        (bool canSettle, IBasket.ParlayStatus expectedStatus) = basket.canSettle(parlayId);
        assertTrue(canSettle);
        assertEq(uint256(expectedStatus), uint256(IBasket.ParlayStatus.Lost));

        // Settle parlay
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.expectEmit(true, true, false, true);
        emit ParlaySettled(parlayId, user1, IBasket.ParlayStatus.Lost, 0);

        uint256 payout = basket.settleParlay(parlayId);

        assertEq(payout, 0, "Should not pay out on loss");
        assertEq(usdc.balanceOf(user1), balanceBefore, "Balance should not change");

        IBasket.Parlay memory parlay = basket.getParlay(parlayId);
        assertEq(uint256(parlay.status), uint256(IBasket.ParlayStatus.Lost));
    }

    function test_SettleParlay_RevertIf_NotReady() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;
        (, , uint256 minPayout) = basket.quote(legs, stake);

        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);
        uint256 parlayId = basket.createParlay(legs, stake, minPayout);
        vm.stopPrank();

        // Markets not yet settled
        vm.expectRevert(abi.encodeWithSelector(IBasket.NotReadyToSettle.selector, parlayId));
        basket.settleParlay(parlayId);
    }

    function test_SettleParlay_RevertIf_AlreadySettled() public {
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;
        (, , uint256 minPayout) = basket.quote(legs, stake);

        deal(address(usdc), user1, stake);
        vm.startPrank(user1);
        usdc.approve(address(basket), stake);
        uint256 parlayId = basket.createParlay(legs, stake, minPayout);
        vm.stopPrank();

        // Lock and settle markets
        vm.warp(block.timestamp + 2 hours);
        market1.lock();
        market2.lock();
        market1.resolve(0);
        market2.resolve(1);

        // Settle once
        basket.settleParlay(parlayId);

        // Try to settle again
        vm.expectRevert(abi.encodeWithSelector(IBasket.AlreadySettled.selector, parlayId));
        basket.settleParlay(parlayId);
    }

    // ============================================================================
    // Batch Settlement Tests
    // ============================================================================

    function test_BatchSettle_Success() public {
        // Create multiple parlays
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(market1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(market2), outcomeId: 1});

        uint256 stake = 1000e6;
        (, , uint256 minPayout) = basket.quote(legs, stake);

        uint256[] memory parlayIds = new uint256[](3);

        for (uint256 i = 0; i < 3; i++) {
            deal(address(usdc), user1, stake);
            vm.startPrank(user1);
            usdc.approve(address(basket), stake);
            parlayIds[i] = basket.createParlay(legs, stake, minPayout);
            vm.stopPrank();
        }

        // Lock and settle markets
        vm.warp(block.timestamp + 2 hours);
        market1.lock();
        market2.lock();
        market1.resolve(0);
        market2.resolve(1);

        // Batch settle
        basket.batchSettle(parlayIds);

        // Verify all settled
        for (uint256 i = 0; i < 3; i++) {
            IBasket.Parlay memory parlay = basket.getParlay(parlayIds[i]);
            assertEq(uint256(parlay.status), uint256(IBasket.ParlayStatus.Won));
        }
    }

    // ============================================================================
    // Management Function Tests
    // ============================================================================

    function test_SetCorrelationGuard_Success() public {
        CorrelationGuard newGuard = new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.ALLOW_ALL,
            1000
        );

        basket.setCorrelationGuard(address(newGuard));
        assertEq(address(basket.correlationGuard()), address(newGuard));
    }

    function test_SetCorrelationGuard_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        basket.setCorrelationGuard(address(0x123));
    }

    function test_SetMaxLegs_Success() public {
        basket.setMaxLegs(15);
        assertEq(basket.maxLegs(), 15);
    }

    function test_SetMaxLegs_RevertIf_TooSmall() public {
        vm.expectRevert("Max legs too small");
        basket.setMaxLegs(1);
    }

    function test_SetOddsLimits_Success() public {
        basket.setOddsLimits(12000, 500000);
        assertEq(basket.minOdds(), 12000);
        assertEq(basket.maxOdds(), 500000);
    }

    function test_SetOddsLimits_RevertIf_Invalid() public {
        vm.expectRevert("Invalid odds limits");
        basket.setOddsLimits(500000, 12000); // min > max
    }

    // ============================================================================
    // Helper Functions
    // ============================================================================

    /**
     * @notice Seed market with initial liquidity
     * @dev Places small bets on all outcomes to initialize AMM
     */
    function _seedMarketLiquidity(address market, uint256 totalAmount) private {
        IMarket m = IMarket(market);
        uint256 outcomeCount = m.outcomeCount();

        // For OU markets with Push (3 outcomes), only bet on Over/Under (0, 1)
        // Push is not bettable
        uint256 bettableOutcomes = outcomeCount == 3 ? 2 : outcomeCount;
        uint256 amountPerOutcome = totalAmount / bettableOutcomes;

        // Use user3 address for seeding (won't interfere with test users)
        deal(address(usdc), user3, totalAmount);

        vm.startPrank(user3);
        usdc.approve(market, totalAmount);

        for (uint256 i = 0; i < bettableOutcomes; i++) {
            m.placeBet(i, amountPerOutcome);
        }
        vm.stopPrank();
    }
}
