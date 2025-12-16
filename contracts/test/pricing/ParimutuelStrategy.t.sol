// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/ParimutuelStrategy.sol";
import "../../src/interfaces/IPricingStrategy.sol";

/**
 * @title ParimutuelStrategy_Test
 * @notice Parimutuel（彩池）定价策略单元测试
 */
contract ParimutuelStrategy_Test is Test {
    ParimutuelStrategy public strategy;

    uint256 constant PRECISION = 1e18;
    uint256 constant BASIS_POINTS = 10000;

    function setUp() public {
        strategy = new ParimutuelStrategy();
    }

    // ============ 元数据测试 ============

    function test_strategyType() public view {
        assertEq(strategy.strategyType(), "PARIMUTUEL");
    }

    function test_requiresInitialLiquidity() public view {
        assertFalse(strategy.requiresInitialLiquidity());
    }

    function test_minOutcomeCount() public view {
        assertEq(strategy.minOutcomeCount(), 2);
    }

    function test_maxOutcomeCount() public view {
        assertEq(strategy.maxOutcomeCount(), 100);
    }

    // ============ 初始状态测试 ============

    function test_getInitialState_NoLiquidity() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        uint256[] memory pools = strategy.decodeState(state);

        assertEq(pools.length, 2);
        assertEq(pools[0], 0);
        assertEq(pools[1], 0);
    }

    function test_getInitialState_WithLiquidity() public view {
        bytes memory state = strategy.getInitialState(3, 30000e6);
        uint256[] memory pools = strategy.decodeState(state);

        assertEq(pools.length, 3);
        assertEq(pools[0], 10000e6);
        assertEq(pools[1], 10000e6);
        assertEq(pools[2], 10000e6);
    }

    function test_getInitialState_InvalidOutcomeCount_Low() public {
        vm.expectRevert("Parimutuel: Invalid outcome count");
        strategy.getInitialState(1, 0);
    }

    function test_getInitialState_InvalidOutcomeCount_High() public {
        vm.expectRevert("Parimutuel: Invalid outcome count");
        strategy.getInitialState(101, 0);
    }

    // ============ 价格测试 ============

    function test_getPrice_EmptyPools_EqualDistribution() public view {
        bytes memory state = strategy.getInitialState(2, 0);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);

        assertEq(price0, 5000);
        assertEq(price1, 5000);
    }

    function test_getPrice_ThreeOutcomes_Empty() public view {
        bytes memory state = strategy.getInitialState(3, 0);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);
        uint256 price2 = strategy.getPrice(2, state);

        assertEq(price0, 3333);
        assertEq(price1, 3333);
        assertEq(price2, 3333);
    }

    function test_getPrice_WithBets() public view {
        bytes memory state = strategy.getInitialState(2, 0);

        // 下注后
        (, bytes memory state1) = strategy.calculateShares(0, 7000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 3000e6, state1);

        uint256 price0 = strategy.getPrice(0, state2);
        uint256 price1 = strategy.getPrice(1, state2);

        // 70% / 30% 分布
        assertEq(price0, 7000);
        assertEq(price1, 3000);
    }

    function test_getAllPrices_Empty() public view {
        bytes memory state = strategy.getInitialState(3, 0);
        uint256[] memory prices = strategy.getAllPrices(3, state);

        assertEq(prices.length, 3);
        assertEq(prices[0], 3333);
        assertEq(prices[1], 3333);
        assertEq(prices[2], 3333);
    }

    function test_getAllPrices_WithBets() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        (, bytes memory state1) = strategy.calculateShares(0, 8000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 2000e6, state1);

        uint256[] memory prices = strategy.getAllPrices(2, state2);

        assertEq(prices[0], 8000);
        assertEq(prices[1], 2000);
    }

    function test_getPrice_Invalid_Reverts() public {
        bytes memory state = strategy.getInitialState(2, 0);

        vm.expectRevert("Parimutuel: Invalid outcome");
        strategy.getPrice(2, state);
    }

    // ============ 下注测试 ============

    function test_calculateShares_OneToOne() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        uint256 betAmount = 5000e6;

        (uint256 shares, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        // Parimutuel: shares = amount (1:1)
        assertEq(shares, betAmount);

        // 检查池子更新
        uint256[] memory pools = strategy.decodeState(newState);
        assertEq(pools[0], betAmount);
        assertEq(pools[1], 0);
    }

    function test_calculateShares_MultipleBets() public view {
        bytes memory state = strategy.getInitialState(2, 0);

        (uint256 shares1, bytes memory state1) = strategy.calculateShares(0, 1000e6, state);
        (uint256 shares2, bytes memory state2) = strategy.calculateShares(0, 2000e6, state1);
        (uint256 shares3, bytes memory state3) = strategy.calculateShares(1, 3000e6, state2);

        // 每次下注都是 1:1
        assertEq(shares1, 1000e6);
        assertEq(shares2, 2000e6);
        assertEq(shares3, 3000e6);

        // 检查最终池子状态
        uint256[] memory pools = strategy.decodeState(state3);
        assertEq(pools[0], 3000e6);
        assertEq(pools[1], 3000e6);
    }

    function test_calculateShares_ZeroAmount_Reverts() public {
        bytes memory state = strategy.getInitialState(2, 0);

        vm.expectRevert("Parimutuel: Amount must be > 0");
        strategy.calculateShares(0, 0, state);
    }

    function test_calculateShares_InvalidOutcome_Reverts() public {
        bytes memory state = strategy.getInitialState(2, 0);

        vm.expectRevert("Parimutuel: Invalid outcome");
        strategy.calculateShares(2, 1000e6, state);
    }

    // ============ 赔付测试 ============

    function test_calculatePayout_Winner() public view {
        // 场景：总池 10000，胜方池 4000，用户持有 1000 份额
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 4000e6;  // 胜方池
        totalShares[1] = 6000e6;
        uint256 totalLiquidity = 10000e6;
        uint256 userShares = 1000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            userShares,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        // payout = 1000 * 10000 / 4000 = 2500（2.5x 赔率）
        assertEq(payout, 2500e6);
    }

    function test_calculatePayout_Winner_HighOdds() public view {
        // 场景：总池 10000，胜方池 1000（10x 赔率）
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 1000e6;  // 胜方池
        totalShares[1] = 9000e6;
        uint256 totalLiquidity = 10000e6;
        uint256 userShares = 1000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            userShares,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        // payout = 1000 * 10000 / 1000 = 10000（10x 赔率）
        assertEq(payout, 10000e6);
    }

    function test_calculatePayout_Refund() public view {
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 4000e6;
        totalShares[1] = 6000e6;
        uint256 totalLiquidity = 10000e6;
        uint256 userShares = 1000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            userShares,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.REFUND
        );

        // REFUND 模式：直接返回份额（在 Parimutuel 中 = 投注金额）
        assertEq(payout, userShares);
    }

    function test_calculatePayout_Winner_ZeroPool() public view {
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 0;  // 无人下注
        totalShares[1] = 6000e6;
        uint256 totalLiquidity = 6000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            1000e6,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        assertEq(payout, 0);
    }

    // ============ 退款测试 ============

    function test_calculateRefund() public view {
        uint256 userShares = 1000e6;
        uint256 totalShares = 5000e6;
        uint256 totalBetAmount = 5000e6;  // 在 Parimutuel 中 = totalShares

        uint256 refund = strategy.calculateRefund(0, userShares, totalShares, totalBetAmount);

        // 在 Parimutuel 中，退款 = 份额 = 原始投注
        assertEq(refund, userShares);
    }

    function test_calculateRefund_ZeroShares() public view {
        uint256 refund = strategy.calculateRefund(0, 1000e6, 0, 0);
        assertEq(refund, 0);
    }

    // ============ 赔率测试 ============

    function test_getOdds_NoPool() public view {
        bytes memory state = strategy.getInitialState(2, 0);

        uint256 odds = strategy.getOdds(0, state);

        // 无人下注时，赔率为无限大
        assertEq(odds, type(uint256).max);
    }

    function test_getOdds_WithBets() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        (, bytes memory state1) = strategy.calculateShares(0, 4000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 6000e6, state1);

        uint256 odds0 = strategy.getOdds(0, state2);
        uint256 odds1 = strategy.getOdds(1, state2);

        // odds0 = 10000 / 4000 = 2.5x
        // odds1 = 10000 / 6000 = 1.667x
        assertEq(odds0, 25 * PRECISION / 10);  // 2.5e18
        assertApproxEqRel(odds1, 1666666666666666666, 0.001e18);  // ~1.667e18
    }

    // ============ previewBet 测试 ============

    function test_previewBet_EmptyPool() public view {
        bytes memory state = strategy.getInitialState(2, 0);

        (uint256 oddsBefore, uint256 oddsAfter) = strategy.previewBet(0, 1000e6, state);

        // 下注前无人下注
        assertEq(oddsBefore, type(uint256).max);

        // 下注后只有 outcome 0 有投注，赔率 = 1x
        assertEq(oddsAfter, 1 * PRECISION);
    }

    function test_previewBet_ExistingPool() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        (, bytes memory state1) = strategy.calculateShares(0, 4000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 6000e6, state1);

        // 预览在 outcome 0 上再下 1000
        (uint256 oddsBefore, uint256 oddsAfter) = strategy.previewBet(0, 1000e6, state2);

        // oddsBefore = 10000 / 4000 = 2.5
        assertEq(oddsBefore, 25 * PRECISION / 10);

        // oddsAfter = 11000 / 5000 = 2.2
        assertEq(oddsAfter, 22 * PRECISION / 10);
    }

    // ============ 不变量测试 ============

    function test_invariant_SharesEqualPool() public view {
        bytes memory state = strategy.getInitialState(3, 0);

        (, bytes memory state1) = strategy.calculateShares(0, 1000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 2000e6, state1);
        (, bytes memory state3) = strategy.calculateShares(2, 3000e6, state2);

        uint256[] memory pools = strategy.decodeState(state3);

        // 每个池的大小应该等于总投注金额
        assertEq(pools[0], 1000e6);
        assertEq(pools[1], 2000e6);
        assertEq(pools[2], 3000e6);
    }

    function test_invariant_TotalPoolMatchesTotalBets() public view {
        bytes memory state = strategy.getInitialState(2, 0);
        uint256 totalBets = 0;

        uint256 bet1 = 1500e6;
        uint256 bet2 = 2500e6;
        uint256 bet3 = 3000e6;

        (, bytes memory state1) = strategy.calculateShares(0, bet1, state);
        totalBets += bet1;
        (, bytes memory state2) = strategy.calculateShares(1, bet2, state1);
        totalBets += bet2;
        (, bytes memory state3) = strategy.calculateShares(0, bet3, state2);
        totalBets += bet3;

        uint256[] memory pools = strategy.decodeState(state3);
        uint256 totalPool = pools[0] + pools[1];

        assertEq(totalPool, totalBets);
    }

    function test_invariant_PricesSumToOne() public view {
        bytes memory state = strategy.getInitialState(3, 0);
        (, bytes memory state1) = strategy.calculateShares(0, 5000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 3000e6, state1);
        (, bytes memory state3) = strategy.calculateShares(2, 2000e6, state2);

        uint256[] memory prices = strategy.getAllPrices(3, state3);
        uint256 priceSum = prices[0] + prices[1] + prices[2];

        assertEq(priceSum, 10000);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_calculateShares_AlwaysOneToOne(uint256 betAmount) public view {
        vm.assume(betAmount > 0 && betAmount < type(uint128).max);

        bytes memory state = strategy.getInitialState(2, 0);
        (uint256 shares, ) = strategy.calculateShares(0, betAmount, state);

        assertEq(shares, betAmount);
    }

    function testFuzz_prices_AlwaysValid(uint256 bet0, uint256 bet1) public view {
        // 确保最小值足够大以避免精度问题
        // 同时限制两者比例，避免极端情况下较小者价格舍入为 0
        vm.assume(bet0 >= 1e6 && bet0 <= 1e12);
        vm.assume(bet1 >= 1e6 && bet1 <= 1e12);
        // 限制比例在 1000:1 以内，避免整数除法精度丢失
        vm.assume(bet0 <= bet1 * 1000 && bet1 <= bet0 * 1000);

        bytes memory state = strategy.getInitialState(2, 0);
        (, bytes memory state1) = strategy.calculateShares(0, bet0, state);
        (, bytes memory state2) = strategy.calculateShares(1, bet1, state1);

        uint256 price0 = strategy.getPrice(0, state2);
        uint256 price1 = strategy.getPrice(1, state2);

        assertTrue(price0 > 0 && price0 <= BASIS_POINTS);
        assertTrue(price1 > 0 && price1 <= BASIS_POINTS);
        // 允许 1 基点的舍入误差
        assertTrue(price0 + price1 >= BASIS_POINTS - 1 && price0 + price1 <= BASIS_POINTS);
    }

    function testFuzz_payout_NeverExceedsPool(uint256 bet0, uint256 bet1, uint256 userBet) public view {
        vm.assume(bet0 > 1000 && bet0 < type(uint64).max);
        vm.assume(bet1 > 1000 && bet1 < type(uint64).max);
        vm.assume(userBet > 0 && userBet <= bet0);

        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = bet0;
        totalShares[1] = bet1;
        uint256 totalLiquidity = bet0 + bet1;

        uint256 payout = strategy.calculatePayout(
            0,
            userBet,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        // 单个用户的赔付不应超过总池
        assertTrue(payout <= totalLiquidity);
    }
}
