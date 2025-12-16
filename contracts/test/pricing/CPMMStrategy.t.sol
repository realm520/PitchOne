// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/CPMMStrategy.sol";
import "../../src/interfaces/IPricingStrategy.sol";

/**
 * @title CPMMStrategy_Test
 * @notice CPMM 定价策略单元测试
 */
contract CPMMStrategy_Test is Test {
    CPMMStrategy public strategy;

    uint256 constant PRECISION = 1e18;
    uint256 constant BASIS_POINTS = 10000;
    uint256 constant INITIAL_LIQUIDITY = 100_000e6; // 100k USDC

    function setUp() public {
        strategy = new CPMMStrategy();
    }

    // ============ 元数据测试 ============

    function test_strategyType() public view {
        assertEq(strategy.strategyType(), "CPMM");
    }

    function test_requiresInitialLiquidity() public view {
        assertTrue(strategy.requiresInitialLiquidity());
    }

    function test_minOutcomeCount() public view {
        assertEq(strategy.minOutcomeCount(), 2);
    }

    function test_maxOutcomeCount() public view {
        assertEq(strategy.maxOutcomeCount(), 10);
    }

    // ============ 初始状态测试 ============

    function test_getInitialState_TwoOutcomes() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256[] memory reserves = strategy.decodeState(state);

        assertEq(reserves.length, 2);
        assertEq(reserves[0], INITIAL_LIQUIDITY / 2);
        assertEq(reserves[1], INITIAL_LIQUIDITY / 2);
    }

    function test_getInitialState_ThreeOutcomes() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        uint256[] memory reserves = strategy.decodeState(state);

        assertEq(reserves.length, 3);
        assertEq(reserves[0], INITIAL_LIQUIDITY / 3);
        assertEq(reserves[1], INITIAL_LIQUIDITY / 3);
        assertEq(reserves[2], INITIAL_LIQUIDITY / 3);
    }

    function test_getInitialState_InvalidOutcomeCount_Low() public {
        vm.expectRevert("CPMM: Invalid outcome count");
        strategy.getInitialState(1, INITIAL_LIQUIDITY);
    }

    function test_getInitialState_InvalidOutcomeCount_High() public {
        vm.expectRevert("CPMM: Invalid outcome count");
        strategy.getInitialState(11, INITIAL_LIQUIDITY);
    }

    function test_getInitialState_ZeroLiquidity() public {
        vm.expectRevert("CPMM: Initial liquidity required");
        strategy.getInitialState(2, 0);
    }

    // ============ 价格测试 ============

    function test_getPrice_EqualReserves() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);

        // 均匀储备时，价格应该各为 50%
        assertApproxEqRel(price0, 5000, 0.01e18); // 允许 1% 误差
        assertApproxEqRel(price1, 5000, 0.01e18);
    }

    function test_getPrice_ThreeOutcomes_Equal() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);
        uint256 price2 = strategy.getPrice(2, state);

        // 均匀储备时，价格应该各约 33.33%
        assertApproxEqRel(price0, 3333, 0.01e18);
        assertApproxEqRel(price1, 3333, 0.01e18);
        assertApproxEqRel(price2, 3333, 0.01e18);
    }

    function test_getAllPrices() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        uint256[] memory prices = strategy.getAllPrices(3, state);

        assertEq(prices.length, 3);
        assertApproxEqRel(prices[0], 3333, 0.01e18);
        assertApproxEqRel(prices[1], 3333, 0.01e18);
        assertApproxEqRel(prices[2], 3333, 0.01e18);
    }

    function test_getPrice_Invalid_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("CPMM: Invalid outcome");
        strategy.getPrice(2, state);
    }

    // ============ 下注测试 ============

    function test_calculateShares_BasicBet() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256 betAmount = 1000e6; // 1k USDC

        (uint256 shares, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        // 应该获得一些份额
        assertTrue(shares > 0);

        // 新状态储备应该变化
        uint256[] memory newReserves = strategy.decodeState(newState);
        assertEq(newReserves.length, 2);

        // outcome 0 的储备减少（用户获得了份额）
        assertTrue(newReserves[0] < INITIAL_LIQUIDITY / 2);
        // outcome 1 的储备增加（加上了下注金额）
        assertEq(newReserves[1], INITIAL_LIQUIDITY / 2 + betAmount);
    }

    function test_calculateShares_PriceIncreasesAfterBet() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256 betAmount = 10000e6; // 10k USDC

        uint256 priceBefore = strategy.getPrice(0, state);
        (, bytes memory newState) = strategy.calculateShares(0, betAmount, state);
        uint256 priceAfter = strategy.getPrice(0, newState);

        // 下注后价格应该上升
        assertTrue(priceAfter > priceBefore);
    }

    function test_calculateShares_ZeroAmount_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("CPMM: Amount must be > 0");
        strategy.calculateShares(0, 0, state);
    }

    function test_calculateShares_InvalidOutcome_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("CPMM: Invalid outcome");
        strategy.calculateShares(2, 1000e6, state);
    }

    function test_calculateShares_MultipleBets() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256 betAmount = 1000e6;

        // 第一次下注
        (uint256 shares1, bytes memory state1) = strategy.calculateShares(0, betAmount, state);

        // 第二次下注同方向
        (uint256 shares2, bytes memory state2) = strategy.calculateShares(0, betAmount, state1);

        // 第二次应该获得更少份额（价格上升了）
        assertTrue(shares2 < shares1);

        // 第三次下注反方向
        (uint256 shares3, ) = strategy.calculateShares(1, betAmount, state2);

        // 反方向下注应该也能获得份额
        assertTrue(shares3 > 0);
    }

    // ============ 赔付测试 ============

    function test_calculatePayout_Winner() public view {
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 10000e6;
        totalShares[1] = 5000e6;
        uint256 totalLiquidity = 150000e6;
        uint256 userShares = 1000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            userShares,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        // payout = userShares * totalLiquidity / totalWinningShares
        // payout = 1000 * 150000 / 10000 = 15000
        assertEq(payout, 15000e6);
    }

    function test_calculatePayout_Winner_ZeroShares() public view {
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 0;
        totalShares[1] = 5000e6;
        uint256 totalLiquidity = 150000e6;

        uint256 payout = strategy.calculatePayout(
            0,
            1000e6,
            totalShares,
            totalLiquidity,
            IPricingStrategy.PayoutType.WINNER
        );

        assertEq(payout, 0);
    }

    function test_calculatePayout_Invalid_Reverts() public {
        uint256[] memory totalShares = new uint256[](2);
        totalShares[0] = 10000e6;
        totalShares[1] = 5000e6;

        vm.expectRevert("CPMM: Invalid outcome");
        strategy.calculatePayout(
            2,
            1000e6,
            totalShares,
            150000e6,
            IPricingStrategy.PayoutType.WINNER
        );
    }

    // ============ 退款测试 ============

    function test_calculateRefund() public view {
        uint256 userShares = 1000e6;
        uint256 totalShares = 10000e6;
        uint256 totalBetAmount = 50000e6;

        uint256 refund = strategy.calculateRefund(0, userShares, totalShares, totalBetAmount);

        // refund = userShares * totalBetAmount / totalShares
        // refund = 1000 * 50000 / 10000 = 5000
        assertEq(refund, 5000e6);
    }

    function test_calculateRefund_ZeroShares() public view {
        uint256 refund = strategy.calculateRefund(0, 1000e6, 0, 50000e6);
        assertEq(refund, 0);
    }

    // ============ previewBet 测试 ============

    function test_previewBet() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256 betAmount = 5000e6;

        (uint256 shares, uint256 newPrice) = strategy.previewBet(0, betAmount, state);

        // 应该获得份额
        assertTrue(shares > 0);

        // 新价格应该大于初始价格
        uint256 initialPrice = strategy.getPrice(0, state);
        assertTrue(newPrice > initialPrice);
    }

    function test_previewBet_MatchesCalculateShares() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256 betAmount = 3000e6;

        (uint256 previewShares, ) = strategy.previewBet(0, betAmount, state);
        (uint256 actualShares, ) = strategy.calculateShares(0, betAmount, state);

        assertEq(previewShares, actualShares);
    }

    // ============ 不变量测试 ============

    function test_invariant_KConstant() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        uint256[] memory reserves1 = strategy.decodeState(state);
        uint256 k1 = (reserves1[0] * reserves1[1]) / PRECISION;

        // 执行下注
        (, bytes memory newState) = strategy.calculateShares(0, 10000e6, state);
        uint256[] memory reserves2 = strategy.decodeState(newState);
        uint256 k2 = (reserves2[0] * reserves2[1]) / PRECISION;

        // k 应该保持不变（或非常接近）
        assertApproxEqRel(k2, k1, 0.001e18); // 允许 0.1% 误差
    }

    function test_invariant_PricesSumToOne() public view {
        // 使用二向市场，避免多向市场的储备耗尽问题
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        // 执行一些下注（金额要适度，避免储备耗尽）
        (, bytes memory state1) = strategy.calculateShares(0, 5000e6, state);
        (, bytes memory state2) = strategy.calculateShares(1, 3000e6, state1);

        uint256[] memory prices = strategy.getAllPrices(2, state2);
        uint256 priceSum = prices[0] + prices[1];

        // 价格之和应该接近 10000 (100%)
        assertApproxEqRel(priceSum, 10000, 0.01e18);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_calculateShares_AlwaysPositive(uint256 betAmount) public view {
        vm.assume(betAmount > 0 && betAmount < INITIAL_LIQUIDITY / 2);

        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        (uint256 shares, ) = strategy.calculateShares(0, betAmount, state);

        assertTrue(shares > 0);
    }

    function testFuzz_prices_AlwaysValid(uint256 betAmount) public view {
        vm.assume(betAmount > 0 && betAmount < INITIAL_LIQUIDITY / 4);

        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        (, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        uint256 price0 = strategy.getPrice(0, newState);
        uint256 price1 = strategy.getPrice(1, newState);

        assertTrue(price0 > 0 && price0 < BASIS_POINTS);
        assertTrue(price1 > 0 && price1 < BASIS_POINTS);
    }

    function testFuzz_initialState_ValidPrices(uint8 outcomeCount, uint256 liquidity) public view {
        vm.assume(outcomeCount >= 2 && outcomeCount <= 10);
        // 限制流动性范围，避免每个 outcome 储备过小或过大
        vm.assume(liquidity >= outcomeCount * 1e6 && liquidity <= type(uint64).max);

        bytes memory state = strategy.getInitialState(outcomeCount, liquidity);
        uint256[] memory prices = strategy.getAllPrices(outcomeCount, state);

        uint256 priceSum = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            assertTrue(prices[i] > 0);
            priceSum += prices[i];
        }

        // 价格之和应该接近 10000
        assertApproxEqRel(priceSum, 10000, 0.02e18);
    }
}
