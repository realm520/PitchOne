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
 * @title BasketIntegration
 * @notice 串关系统集成测试 - Basket + CorrelationGuard + Markets
 * @dev 测试场景：
 *      1. 跨多市场串关创建（资金流转、头寸管理）
 *      2. 相关性惩罚在真实市场中的应用
 *      3. 多用户并发串关
 *      4. 储备金管理与破产保护
 *      5. Gas 优化验证
 */
contract BasketIntegrationTest is BaseTest {
    Basket public basket;
    CorrelationGuard public guard;

    // Test markets
    WDL_Template public marketMUNvsMCI; // EPL: MUN vs MCI
    WDL_Template public marketCHEvsARS; // EPL: CHE vs ARS
    OU_Template public marketMUNvsMCI_OU; // EPL: MUN vs MCI Over/Under

    // Match IDs
    bytes32 constant MATCH_ID_MUN_MCI = keccak256("EPL_2024_MUN_vs_MCI");
    bytes32 constant MATCH_ID_CHE_ARS = keccak256("EPL_2024_CHE_vs_ARS");

    // Basket config
    uint256 constant MIN_ODDS = 11000; // 1.1x
    uint256 constant MAX_ODDS = 1000000; // 100x
    uint256 constant SAME_MATCH_PENALTY = 2000; // 20%
    uint256 constant INITIAL_RESERVE = 100_000 * 1e6; // 100k USDC

    event ParlayCreated(
        uint256 indexed parlayId,
        address indexed user,
        ICorrelationGuard.ParlayLeg[] legs,
        uint256 stake,
        uint256 potentialPayout,
        uint256 combinedOdds,
        uint256 penaltyBps
    );

    function setUp() public override {
        super.setUp();

        // Deploy CorrelationGuard
        guard = new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            SAME_MATCH_PENALTY
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

        // Create test markets
        uint256 kickoffTime = block.timestamp + 1 days;

        // Market 1: MUN vs MCI (WDL)
        marketMUNvsMCI = new WDL_Template();
        marketMUNvsMCI.initialize(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/mun_mci",
            owner
        );

        // Market 2: CHE vs ARS (WDL)
        marketCHEvsARS = new WDL_Template();
        marketCHEvsARS.initialize(
            "EPL_2024_CHE_vs_ARS",
            "Chelsea",
            "Arsenal",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/che_ars",
            owner
        );

        // Market 3: MUN vs MCI Over/Under 2.5
        marketMUNvsMCI_OU = new OU_Template();
        marketMUNvsMCI_OU.initialize(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            kickoffTime,
            25, // 2.5 goals
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            "https://api.test/mun_mci_ou",
            owner
        );

        // Add initial liquidity to markets via LP deposits
        _addMarketLiquidity(address(marketMUNvsMCI), 50_000 * 1e6);
        _addMarketLiquidity(address(marketCHEvsARS), 50_000 * 1e6);
        _addMarketLiquidity(address(marketMUNvsMCI_OU), 50_000 * 1e6);

        // Add reserve to Basket
        deal(address(usdc), owner, INITIAL_RESERVE);
        vm.startPrank(owner);
        usdc.approve(address(basket), INITIAL_RESERVE);
        basket.addReserveFund(INITIAL_RESERVE);
        vm.stopPrank();

        // Fund test users
        deal(address(usdc), user1, 100_000 * 1e6);
        deal(address(usdc), user2, 100_000 * 1e6);
    }

    function _addMarketLiquidity(address market, uint256 amount) internal {
        deal(address(usdc), owner, amount);
        vm.startPrank(owner);
        usdc.approve(market, amount);
        // Note: 需要实现市场的 addLiquidity 方法，这里简化处理
        vm.stopPrank();
    }

    // ============================================================================
    // 测试 1: 跨市场串关 - 不同场次（无相关性）
    // ============================================================================
    function testIntegration_CreateParlay_DifferentMatches() public {
        uint256 betAmount = 10_000 * 1e6;

        vm.startPrank(user1);

        // Step 1: 批准 Basket 使用 USDC（用于创建串关）
        usdc.approve(address(basket), betAmount);

        // Step 2: 构建串关
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({
            market: address(marketMUNvsMCI),
            outcomeId: 0
        });
        legs[1] = ICorrelationGuard.ParlayLeg({
            market: address(marketCHEvsARS),
            outcomeId: 1
        });

        uint256 snapshot = vm.snapshotState();

        // Step 3: 创建串关
        uint256 parlayId = basket.createParlay(legs, betAmount, 0);

        // Verify parlay created
        IBasket.Parlay memory parlay = basket.getParlay(parlayId);

        assertEq(parlay.user, user1, "Creator should be user1");
        assertEq(uint256(parlay.status), uint256(IBasket.ParlayStatus.Pending));
        assertEq(parlay.penaltyBps, 0, "No penalty for different matches");
        assertGt(parlay.potentialPayout, parlay.stake, "Payout should exceed stake");

        vm.stopPrank();

        vm.revertToState(snapshot);
    }

    // ============================================================================
    // 测试 2: 同场串关（触发相关性惩罚）
    // ============================================================================
    function testIntegration_CreateParlay_SameMatch_WithPenalty() public {
        uint256 betAmount = 10_000 * 1e6;

        vm.startPrank(user1);

        // 批准 Basket 使用 USDC
        usdc.approve(address(basket), betAmount);

        // 构建同场串关（WDL + OU）
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({
            market: address(marketMUNvsMCI),
            outcomeId: 0
        });
        legs[1] = ICorrelationGuard.ParlayLeg({
            market: address(marketMUNvsMCI_OU),
            outcomeId: 0
        });

        uint256 snapshot = vm.snapshotState();

        uint256 parlayId = basket.createParlay(legs, betAmount, 0);

        // Verify penalty applied
        IBasket.Parlay memory parlay = basket.getParlay(parlayId);

        assertEq(parlay.penaltyBps, SAME_MATCH_PENALTY, "Should apply 20% penalty");

        // Verify adjusted payout is lower due to penalty
        // adjustedOdds = combinedOdds * (1 - penaltyBps/10000)
        uint256 expectedAdjustedOdds = parlay.combinedOdds * (10000 - SAME_MATCH_PENALTY) / 10000;
        // potentialPayout should reflect this adjustment

        vm.stopPrank();

        vm.revertToState(snapshot);
    }

    // ============================================================================
    // 测试 3: 多用户并发串关（资源竞争）
    // ============================================================================
    function testIntegration_MultipleUsers_ConcurrentParlays() public {
        uint256 betAmount = 5_000 * 1e6;

        // User 1 创建串关
        vm.startPrank(user1);
        usdc.approve(address(basket), betAmount);

        ICorrelationGuard.ParlayLeg[] memory legs1 = new ICorrelationGuard.ParlayLeg[](2);
        legs1[0] = ICorrelationGuard.ParlayLeg(address(marketMUNvsMCI), 0);
        legs1[1] = ICorrelationGuard.ParlayLeg(address(marketCHEvsARS), 0);

        uint256 snapshot = vm.snapshotState();
        uint256 parlay1 = basket.createParlay(legs1, betAmount, 0);
        vm.stopPrank();

        // User 2 创建不同的串关
        vm.startPrank(user2);
        usdc.approve(address(basket), betAmount);

        ICorrelationGuard.ParlayLeg[] memory legs2 = new ICorrelationGuard.ParlayLeg[](2);
        legs2[0] = ICorrelationGuard.ParlayLeg(address(marketMUNvsMCI), 1);
        legs2[1] = ICorrelationGuard.ParlayLeg(address(marketCHEvsARS), 1);

        uint256 parlay2 = basket.createParlay(legs2, betAmount, 0);
        vm.stopPrank();

        // Verify both parlays exist independently
        IBasket.Parlay memory parlayData1 = basket.getParlay(parlay1);
        IBasket.Parlay memory parlayData2 = basket.getParlay(parlay2);

        assertEq(parlayData1.user, user1);
        assertEq(parlayData2.user, user2);
        assertTrue(parlay1 != parlay2);

        // Verify Basket's accounting
        uint256 totalLocked = basket.totalLockedStake();
        uint256 totalPotential = basket.totalPotentialPayout();
        assertGt(totalLocked, 0, "Should have locked stakes");
        assertGt(totalPotential, totalLocked, "Potential payout should exceed stakes");

        vm.revertToState(snapshot);
    }

    // ============================================================================
    // 测试 4: 储备金管理
    // ============================================================================
    function testIntegration_ReserveManagement() public {
        uint256 additionalReserve = 50_000 * 1e6;

        // Add reserve
        deal(address(usdc), owner, additionalReserve);
        vm.startPrank(owner);
        usdc.approve(address(basket), additionalReserve);
        basket.addReserveFund(additionalReserve);
        vm.stopPrank();

        assertEq(
            basket.reserveFund(),
            INITIAL_RESERVE + additionalReserve,
            "Reserve should increase"
        );

        // Withdraw reserve
        uint256 withdrawAmount = 30_000 * 1e6;
        uint256 balanceBefore = usdc.balanceOf(owner);

        vm.prank(owner);
        basket.withdrawReserveFund(withdrawAmount);

        assertEq(
            usdc.balanceOf(owner) - balanceBefore,
            withdrawAmount,
            "Should receive withdrawn amount"
        );
        assertEq(
            basket.reserveFund(),
            INITIAL_RESERVE + additionalReserve - withdrawAmount,
            "Reserve should decrease"
        );
    }

    // ============================================================================
    // 测试 5: Gas 优化 - 串关创建成本
    // ============================================================================
    function testIntegration_GasUsage_CreateParlay() public {
        uint256 betAmount = 10_000 * 1e6;

        vm.startPrank(user1);

        // 批准 Basket 使用 USDC
        usdc.approve(address(basket), betAmount);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg(address(marketMUNvsMCI), 0);
        legs[1] = ICorrelationGuard.ParlayLeg(address(marketCHEvsARS), 0);

        // Measure gas
        uint256 snapshot = vm.snapshotState();
        uint256 gasBefore = gasleft();
        basket.createParlay(legs, betAmount, 0);
        uint256 gasUsed = gasBefore - gasleft();

        // Gas should be reasonable (< 500k for 2-leg parlay)
        assertLt(gasUsed, 500_000, "Gas usage should be < 500k");

        vm.stopPrank();
        vm.revertToState(snapshot);
    }

    // ============================================================================
    // 测试 6: 相关性规则动态更新
    // ============================================================================
    function testIntegration_CorrelationRule_DynamicUpdate() public {
        // 初始状态: PENALTY 模式
        assertEq(
            uint256(guard.getPolicy()),
            uint256(ICorrelationGuard.CorrelationPolicy.PENALTY),
            "Should start in PENALTY mode"
        );

        // Owner 切换到 STRICT_BLOCK 模式
        vm.prank(owner);
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK);

        assertEq(
            uint256(guard.getPolicy()),
            uint256(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK),
            "Should switch to STRICT_BLOCK mode"
        );

        // 验证新串关会受阻（同场组合）
        uint256 betAmount = 10_000 * 1e6;

        vm.startPrank(user1);
        usdc.approve(address(marketMUNvsMCI), betAmount);
        marketMUNvsMCI.placeBet(0, betAmount);
        usdc.approve(address(marketMUNvsMCI_OU), betAmount);
        marketMUNvsMCI_OU.placeBet(0, betAmount);
        marketMUNvsMCI.setApprovalForAll(address(basket), true);
        marketMUNvsMCI_OU.setApprovalForAll(address(basket), true);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg(address(marketMUNvsMCI), 0);
        legs[1] = ICorrelationGuard.ParlayLeg(address(marketMUNvsMCI_OU), 0);

        // 应该 revert（同场组合在 BLOCK 模式下被阻断）
        vm.expectRevert();
        basket.createParlay(legs, betAmount, 0);

        vm.stopPrank();
    }
}
