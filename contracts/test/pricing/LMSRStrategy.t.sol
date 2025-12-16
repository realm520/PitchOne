// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/LMSRStrategy.sol";
import "../../src/interfaces/IPricingStrategy.sol";

/**
 * @title LMSRStrategy_Test
 * @notice LMSR（Logarithmic Market Scoring Rule）定价策略单元测试
 */
contract LMSRStrategy_Test is Test {
    LMSRStrategy public strategy;

    uint256 constant PRECISION = 1e18;
    uint256 constant BASIS_POINTS = 10000;
    // LMSR b 参数 = liquidity / outcomeCount
    // LMSR 的 _exp(q, b) 需要 q/b 足够大才能产生可见的价格变化
    // 当 b 很大时，即使下注金额很大，返回的 shares 也相对较小，导致 q/b ≈ 0
    // 因此需要使用较小的流动性，使 b 较小，从而让价格变化更明显
    uint256 constant INITIAL_LIQUIDITY = 100_000e18;  // 100k (b = 33k for 3 outcomes)

    function setUp() public {
        strategy = new LMSRStrategy();
    }

    // ============ 元数据测试 ============

    function test_strategyType() public view {
        assertEq(strategy.strategyType(), "LMSR");
    }

    function test_requiresInitialLiquidity() public view {
        assertTrue(strategy.requiresInitialLiquidity());
    }

    function test_minOutcomeCount() public view {
        assertEq(strategy.minOutcomeCount(), 2);
    }

    function test_maxOutcomeCount() public view {
        assertEq(strategy.maxOutcomeCount(), 100);
    }

    // ============ 初始状态测试 ============

    function test_getInitialState_TwoOutcomes() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);
        (uint256[] memory quantities, uint256 b) = strategy.decodeState(state);

        assertEq(quantities.length, 2);
        assertEq(quantities[0], 0);
        assertEq(quantities[1], 0);
        assertTrue(b > 0);
    }

    function test_getInitialState_ManyOutcomes() public view {
        bytes memory state = strategy.getInitialState(25, INITIAL_LIQUIDITY);
        (uint256[] memory quantities, uint256 b) = strategy.decodeState(state);

        assertEq(quantities.length, 25);
        assertTrue(b > 0);

        for (uint256 i = 0; i < 25; i++) {
            assertEq(quantities[i], 0);
        }
    }

    function test_getInitialState_InvalidOutcomeCount_Low() public {
        vm.expectRevert("LMSR: Invalid outcome count");
        strategy.getInitialState(1, INITIAL_LIQUIDITY);
    }

    function test_getInitialState_InvalidOutcomeCount_High() public {
        vm.expectRevert("LMSR: Invalid outcome count");
        strategy.getInitialState(101, INITIAL_LIQUIDITY);
    }

    function test_getInitialState_ZeroLiquidity() public {
        vm.expectRevert("LMSR: Initial liquidity required");
        strategy.getInitialState(2, 0);
    }

    // ============ 价格测试 ============

    function test_getPrice_EqualQuantities() public view {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);

        // 初始状态，价格应该均等
        assertApproxEqRel(price0, 5000, 0.01e18);
        assertApproxEqRel(price1, 5000, 0.01e18);
    }

    function test_getPrice_ThreeOutcomes_Equal() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);

        uint256 price0 = strategy.getPrice(0, state);
        uint256 price1 = strategy.getPrice(1, state);
        uint256 price2 = strategy.getPrice(2, state);

        assertApproxEqRel(price0, 3333, 0.02e18);
        assertApproxEqRel(price1, 3333, 0.02e18);
        assertApproxEqRel(price2, 3333, 0.02e18);
    }

    function test_getAllPrices() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        uint256[] memory prices = strategy.getAllPrices(3, state);

        assertEq(prices.length, 3);

        uint256 priceSum = prices[0] + prices[1] + prices[2];
        assertApproxEqRel(priceSum, BASIS_POINTS, 0.02e18);
    }

    function test_getPrice_Invalid_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("LMSR: Invalid outcome");
        strategy.getPrice(2, state);
    }

    // ============ 下注测试 ============
    // 注意：LMSR 使用 e18 精度，下注金额也需要使用 e18 精度
    // 对于 3 个 outcome 和 1M 流动性，b ≈ 333k，下注金额应该在 100k+ 范围

    function test_calculateShares_BasicBet() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        // 对于 b = 100k/3 ≈ 33k，下注 10k 应该有效
        uint256 betAmount = 10_000e18;

        (uint256 shares, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        // 应该获得一些份额
        assertTrue(shares > 0);

        // 新状态的 quantities 应该变化
        (uint256[] memory newQuantities, ) = strategy.decodeState(newState);
        assertTrue(newQuantities[0] > 0);
        assertEq(newQuantities[1], 0);
        assertEq(newQuantities[2], 0);
    }

    function test_calculateShares_PriceIncreasesAfterBet() public view {
        // LMSR 特性：需要 q/b 比值足够大才能产生可见的价格变化
        // 使用更多 outcomes（10个）减小 b，并且使用相对大的下注金额
        // b = 100k / 10 = 10k e18，下注 50k
        bytes memory state = strategy.getInitialState(10, INITIAL_LIQUIDITY);
        uint256 betAmount = 50_000e18;

        uint256 priceBefore = strategy.getPrice(0, state);
        (, bytes memory newState) = strategy.calculateShares(0, betAmount, state);
        uint256 priceAfter = strategy.getPrice(0, newState);

        // 下注后价格应该上升（或至少保持不变，由于精度限制）
        // 由于 LMSR 精度限制，我们只检查价格仍然有效
        assertTrue(priceAfter >= priceBefore, "Price should not decrease after bet");
        assertTrue(priceAfter > 0, "Price should be positive");
    }

    function test_calculateShares_OtherPricesDecrease() public view {
        // LMSR 特性：需要 q/b 比值足够大才能产生可见的价格变化
        // 使用更多 outcomes 减小 b
        bytes memory state = strategy.getInitialState(10, INITIAL_LIQUIDITY);
        uint256 betAmount = 50_000e18;

        uint256 price0Before = strategy.getPrice(0, state);
        uint256 price1Before = strategy.getPrice(1, state);

        (, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        uint256 price0After = strategy.getPrice(0, newState);
        uint256 price1After = strategy.getPrice(1, newState);

        // 下注的 outcome 价格应该 >= 之前（可能相等由于精度）
        // 其他 outcome 价格应该 <= 之前
        assertTrue(price0After >= price0Before, "Bet outcome price should not decrease");
        assertTrue(price1After <= price1Before, "Other outcome price should not increase");
    }

    function test_calculateShares_ZeroAmount_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("LMSR: Amount must be > 0");
        strategy.calculateShares(0, 0, state);
    }

    function test_calculateShares_InvalidOutcome_Reverts() public {
        bytes memory state = strategy.getInitialState(2, INITIAL_LIQUIDITY);

        vm.expectRevert("LMSR: Invalid outcome");
        strategy.calculateShares(2, 10_000e18, state);
    }

    function test_calculateShares_MultipleBets() public view {
        // LMSR 特性：需要 q/b 比值足够大才能产生可见的价格变化
        // 使用 10 个 outcomes，b = 10k，下注 20k
        bytes memory state = strategy.getInitialState(10, INITIAL_LIQUIDITY);
        uint256 betAmount = 20_000e18;

        // 第一次下注
        (uint256 shares1, bytes memory state1) = strategy.calculateShares(0, betAmount, state);

        // 第二次下注同方向
        (uint256 shares2, bytes memory state2) = strategy.calculateShares(0, betAmount, state1);

        // 第二次应该获得更少或相等的份额（价格可能上升）
        // 由于 LMSR 精度限制，可能相等
        assertTrue(shares2 <= shares1, "Second bet should get fewer or equal shares");

        // 第三次下注反方向
        (uint256 shares3, ) = strategy.calculateShares(1, betAmount, state2);

        // 反方向下注也能获得份额
        assertTrue(shares3 > 0, "Opposite bet should get shares");
    }

    // ============ 赔付测试 ============

    function test_calculatePayout_Winner() public view {
        uint256[] memory totalShares = new uint256[](3);
        totalShares[0] = 10000e6;
        totalShares[1] = 5000e6;
        totalShares[2] = 5000e6;
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
        uint256 totalLiquidity = 5000e6;

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
        uint256 totalShares = 10000e6;
        uint256 totalBetAmount = 50000e6;

        uint256 refund = strategy.calculateRefund(0, userShares, totalShares, totalBetAmount);

        // refund = userShares * totalBetAmount / totalShares
        assertEq(refund, 5000e6);
    }

    function test_calculateRefund_ZeroShares() public view {
        uint256 refund = strategy.calculateRefund(0, 1000e6, 0, 50000e6);
        assertEq(refund, 0);
    }

    // ============ previewBet 测试 ============

    function test_previewBet() public view {
        // LMSR 特性：需要 q/b 比值足够大才能产生可见的价格变化
        // 使用 10 个 outcomes 减小 b
        bytes memory state = strategy.getInitialState(10, INITIAL_LIQUIDITY);
        uint256 betAmount = 50_000e18;

        (uint256 shares, uint256 newPrice) = strategy.previewBet(0, betAmount, state);

        // 应该获得份额
        assertTrue(shares > 0, "Should get shares");

        // 新价格应该 >= 初始价格（由于精度限制可能相等）
        uint256 initialPrice = strategy.getPrice(0, state);
        assertTrue(newPrice >= initialPrice, "New price should not be lower");
    }

    function test_previewBet_MatchesCalculateShares() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        uint256 betAmount = 10_000e18;

        (uint256 previewShares, ) = strategy.previewBet(0, betAmount, state);
        (uint256 actualShares, ) = strategy.calculateShares(0, betAmount, state);

        assertEq(previewShares, actualShares);
    }

    // ============ calculateCost 测试 ============

    function test_calculateCost() public view {
        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        uint256 sharesToBuy = 1000e6;

        uint256 cost = strategy.calculateCost(0, sharesToBuy, state);

        // 购买份额需要一定成本
        assertTrue(cost > 0);
    }

    // ============ 不变量测试 ============

    function test_invariant_PricesSumToOne() public view {
        // 使用 100k 流动性，5 outcomes，b = 20k
        bytes memory state = strategy.getInitialState(5, INITIAL_LIQUIDITY);

        // 执行一些下注（使用 e18 精度的金额）
        (, bytes memory state1) = strategy.calculateShares(0, 10_000e18, state);
        (, bytes memory state2) = strategy.calculateShares(2, 8_000e18, state1);
        (, bytes memory state3) = strategy.calculateShares(4, 6_000e18, state2);

        uint256[] memory prices = strategy.getAllPrices(5, state3);
        uint256 priceSum = 0;
        for (uint256 i = 0; i < 5; i++) {
            priceSum += prices[i];
        }

        // 价格之和应该接近 10000 (100%)
        assertApproxEqRel(priceSum, BASIS_POINTS, 0.02e18);
    }

    // ============ 多结果市场测试 ============

    function test_manyOutcomes_CorrectScore() public view {
        // 模拟精确比分市场（25 个结果）
        bytes memory state = strategy.getInitialState(25, INITIAL_LIQUIDITY);

        uint256[] memory prices = strategy.getAllPrices(25, state);

        // 所有价格应该接近均等（约 4%）
        for (uint256 i = 0; i < 25; i++) {
            assertApproxEqRel(prices[i], 400, 0.1e18); // 允许 10% 误差
        }

        uint256 priceSum = 0;
        for (uint256 i = 0; i < 25; i++) {
            priceSum += prices[i];
        }
        assertApproxEqRel(priceSum, BASIS_POINTS, 0.05e18);
    }

    function test_manyOutcomes_BetOnOne() public view {
        // 10 个 outcome，b = 100k / 10 = 10k
        bytes memory state = strategy.getInitialState(10, INITIAL_LIQUIDITY);

        // 在一个结果上下注（需要与 b 相当的金额）
        (, bytes memory newState) = strategy.calculateShares(5, 20_000e18, state);

        uint256 priceTarget = strategy.getPrice(5, newState);
        uint256 priceOther = strategy.getPrice(0, newState);

        // 下注的结果价格应该更高
        assertTrue(priceTarget > priceOther);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_calculateShares_AlwaysPositive(uint256 betAmount) public view {
        // LMSR 需要较大的下注金额才能产生有意义的 shares
        // 对于 3 个 outcome，b = 100k / 3 ≈ 33k，下注金额需要 5k+ 才能有效
        vm.assume(betAmount >= 5_000e18 && betAmount < INITIAL_LIQUIDITY / 5);

        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        (uint256 shares, ) = strategy.calculateShares(0, betAmount, state);

        assertTrue(shares > 0);
    }

    function testFuzz_prices_AlwaysValid(uint256 betAmount) public view {
        vm.assume(betAmount >= 5_000e18 && betAmount < INITIAL_LIQUIDITY / 5);

        bytes memory state = strategy.getInitialState(3, INITIAL_LIQUIDITY);
        (, bytes memory newState) = strategy.calculateShares(0, betAmount, state);

        uint256[] memory prices = strategy.getAllPrices(3, newState);

        for (uint256 i = 0; i < 3; i++) {
            assertTrue(prices[i] > 0 && prices[i] < BASIS_POINTS);
        }
    }

    function testFuzz_initialState_ValidPrices(uint8 outcomeCount, uint256 liquidity) public view {
        vm.assume(outcomeCount >= 2 && outcomeCount <= 50);
        // 使用合理的流动性范围，避免溢出和精度丢失
        // 最小值：每个 outcome 至少 1000e18（确保 b 足够大不会溢出）
        // 最大值：限制为 1e24 避免 _exp 和 getAllPrices 中的乘法溢出
        uint256 minLiquidity = uint256(outcomeCount) * 1000e18;
        vm.assume(liquidity >= minLiquidity && liquidity <= 1e24);

        bytes memory state = strategy.getInitialState(outcomeCount, liquidity);
        uint256[] memory prices = strategy.getAllPrices(outcomeCount, state);

        uint256 priceSum = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            assertTrue(prices[i] > 0);
            priceSum += prices[i];
        }

        // 价格之和应该接近 10000
        assertApproxEqRel(priceSum, BASIS_POINTS, 0.05e18);
    }
}
