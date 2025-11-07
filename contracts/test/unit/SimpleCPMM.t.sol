// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/pricing/SimpleCPMM.sol";

/**
 * @title SimpleCPMMTest
 * @notice Unit tests for SimpleCPMM虚拟储备定价引擎
 * @dev 验证虚拟储备模型：买入 → 储备减少 → 价格上升
 */
contract SimpleCPMMTest is BaseTest {
    SimpleCPMM public engine;

    // 测试常量（USDC 6 位小数）
    uint256 constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100,000 USDC
    uint256 constant MIN_RESERVE = 1000 * 1e6; // 1,000 USDC
    uint256 constant MAX_RESERVE = 10_000_000 * 1e6; // 10M USDC

    function setUp() public override {
        super.setUp();
        engine = new SimpleCPMM();
    }

    // ============ 核心验证：买入后价格上升 ============

    function test_BuyingIncreasesPrice_TwoOutcomes() public {
        // 初始均衡储备
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = VIRTUAL_RESERVE_INIT;
        reserves[1] = VIRTUAL_RESERVE_INIT;

        // 买入前价格
        uint256 priceBefore = engine.getPrice(0, reserves);
        assertEq(priceBefore, 5000, "Initial price should be 50%");

        // 模拟买入：储备减少
        uint256 buyAmount = 10_000 * 1e6; // 10,000 USDC
        uint256 shares = engine.calculateShares(0, buyAmount, reserves);

        reserves[0] -= shares; // 目标储备减少
        reserves[1] += buyAmount; // 对手盘储备增加

        // 买入后价格
        uint256 priceAfter = engine.getPrice(0, reserves);

        // 关键验证：价格应该上升
        assertGt(priceAfter, priceBefore, "Price must increase after buying");
        emit log_named_uint("Price before", priceBefore);
        emit log_named_uint("Price after", priceAfter);
        emit log_named_uint("Price increase (bps)", priceAfter - priceBefore);
    }

    function test_BuyingIncreasesPrice_ThreeOutcomes() public {
        // 初始均衡储备
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = VIRTUAL_RESERVE_INIT;
        reserves[1] = VIRTUAL_RESERVE_INIT;
        reserves[2] = VIRTUAL_RESERVE_INIT;

        // 买入前价格
        uint256 priceBefore = engine.getPrice(0, reserves);
        assertApproxEqAbs(priceBefore, 3333, 10, "Initial price ~33.33%");

        // 模拟大量买入客队
        uint256 buyAmount = 20_000 * 1e6; // 20,000 USDC
        uint256 shares = engine.calculateShares(0, buyAmount, reserves);

        reserves[0] -= shares;
        reserves[1] += buyAmount / 2; // 对手盘均分
        reserves[2] += buyAmount / 2;

        // 买入后价格
        uint256 priceAfter = engine.getPrice(0, reserves);

        // 关键验证
        assertGt(priceAfter, priceBefore, "Price must increase after buying");
        emit log_named_uint("Price before", priceBefore);
        emit log_named_uint("Price after", priceAfter);

        // 价格应该显著上升（至少5%）
        assertGt(priceAfter, priceBefore + 500, "Price should increase significantly");
    }

    // ============ 初始价格测试 ============

    function test_InitialPrice_TwoOutcomes_Balanced() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000); // USDC 6 decimals

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);

        assertEq(price0, 5000, "Initial price should be 50%");
        assertEq(price1, 5000, "Initial price should be 50%");
        assertEq(price0 + price1, 10000, "Prices must sum to 100%");
    }

    function test_InitialPrice_ThreeOutcomes_Balanced() public {
        uint256[] memory reserves = engine.getInitialReserves(3, 6, 100_000);

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);
        uint256 price2 = engine.getPrice(2, reserves);

        assertApproxEqAbs(price0, 3333, 10, "Initial price ~33.33%");
        assertApproxEqAbs(price1, 3333, 10, "Initial price ~33.33%");
        assertApproxEqAbs(price2, 3333, 10, "Initial price ~33.33%");

        uint256 sum = price0 + price1 + price2;
        assertApproxEqAbs(sum, 10000, 10, "Prices must sum to ~100%");
    }

    function test_Price_LowerReserve_HigherPrice() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 80_000 * 1e6;  // 被买入，储备少
        reserves[1] = 100_000 * 1e6; // 均衡
        reserves[2] = 120_000 * 1e6; // 被卖出，储备多

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);
        uint256 price2 = engine.getPrice(2, reserves);

        // 储备越少 → 价格越高
        assertGt(price0, price1, "Lower reserve should have higher price");
        assertGt(price1, price2, "Lower reserve should have higher price");

        emit log_named_uint("Price 0 (low reserve)", price0);
        emit log_named_uint("Price 1 (medium)", price1);
        emit log_named_uint("Price 2 (high reserve)", price2);
    }

    // ============ 二向市场精确公式验证 ============

    function test_BinaryMarket_ExactFormula() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100_000 * 1e6;
        reserves[1] = 100_000 * 1e6;

        uint256 buyAmount = 5_000 * 1e6;

        // 计算 k
        uint256 k = engine.calculateK(reserves);
        assertEq(k, 100_000 * 1e6 * 100_000 * 1e6, "K calculation");

        // 计算份额
        uint256 shares = engine.calculateShares(0, buyAmount, reserves);

        // 手动验证精确公式：shares = r₀ - k/(r₁ + amount)
        uint256 r0 = reserves[0];
        uint256 r1 = reserves[1];
        uint256 r1_new = r1 + buyAmount;
        uint256 r0_new = k / r1_new;
        uint256 expectedShares = r0 - r0_new;

        emit log_named_uint("Calculated shares", shares);
        emit log_named_uint("Expected shares", expectedShares);

        // 允许小误差（精度损失）
        assertApproxEqRel(shares, expectedShares, 0.01e18, "Binary formula accuracy");
    }

    function test_BinaryMarket_KValuePreserved() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100_000 * 1e6;
        reserves[1] = 100_000 * 1e6;

        uint256 k_before = engine.calculateK(reserves);

        // 模拟买入
        uint256 buyAmount = 10_000 * 1e6;
        uint256 shares = engine.calculateShares(0, buyAmount, reserves);

        reserves[0] -= shares;
        reserves[1] += buyAmount;

        uint256 k_after = engine.calculateK(reserves);

        // K值应该保持不变（允许小误差）
        assertApproxEqRel(k_after, k_before, 0.001e18, "K value should be preserved");

        emit log_named_uint("K before", k_before);
        emit log_named_uint("K after", k_after);
    }

    // ============ 份额计算测试 ============

    function test_CalculateShares_ReturnsPositive() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000);
        uint256 amount = 1_000 * 1e6;

        uint256 shares = engine.calculateShares(0, amount, reserves);

        assertGt(shares, 0, "Shares must be positive");
        assertLt(shares, reserves[0], "Shares < reserve");
    }

    function test_CalculateShares_LargerAmount_LargerShares() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000);

        uint256 shares1 = engine.calculateShares(0, 1_000 * 1e6, reserves);
        uint256 shares2 = engine.calculateShares(0, 2_000 * 1e6, reserves);

        assertGt(shares2, shares1, "Larger amount should give more shares");
        // 但不是线性关系（由于滑点）
        assertLt(shares2, shares1 * 2, "Non-linear due to slippage");
    }

    function test_CalculateShares_ThreeOutcomes_Consistent() public {
        uint256[] memory reserves = engine.getInitialReserves(3, 6, 100_000);
        uint256 amount = 5_000 * 1e6;

        // 同样金额买入不同结果，均衡市场应该给相同份额
        uint256 shares0 = engine.calculateShares(0, amount, reserves);
        uint256 shares1 = engine.calculateShares(1, amount, reserves);
        uint256 shares2 = engine.calculateShares(2, amount, reserves);

        assertApproxEqAbs(shares0, shares1, shares0 / 100, "Shares should be similar");
        assertApproxEqAbs(shares1, shares2, shares1 / 100, "Shares should be similar");
    }

    // ============ 滑点测试 ============

    function test_Slippage_LargeTradeHigherSlippage() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000);
        uint256[] memory reservesCopy = new uint256[](2);
        reservesCopy[0] = reserves[0];
        reservesCopy[1] = reserves[1];

        // 小额交易
        uint256 smallAmount = 1_000 * 1e6;
        uint256 sharesSmall = engine.calculateShares(0, smallAmount, reserves);
        reserves[0] -= sharesSmall;
        reserves[1] += smallAmount;

        (,uint256 slippageSmall) = engine.calculateEffectivePrice(0, reservesCopy, reserves);

        // 重置
        reserves[0] = reservesCopy[0];
        reserves[1] = reservesCopy[1];

        // 大额交易
        uint256 largeAmount = 20_000 * 1e6;
        uint256 sharesLarge = engine.calculateShares(0, largeAmount, reserves);
        reserves[0] -= sharesLarge;
        reserves[1] += largeAmount;

        (,uint256 slippageLarge) = engine.calculateEffectivePrice(0, reservesCopy, reserves);

        // 大额交易滑点更高
        assertGt(slippageLarge, slippageSmall, "Large trade should have higher slippage");

        emit log_named_uint("Slippage small (bps)", slippageSmall);
        emit log_named_uint("Slippage large (bps)", slippageLarge);
    }

    // ============ 对手盘调整测试 ============

    function test_OpponentAdjustments_TwoOutcomes() public {
        int256[] memory adjustments = engine.calculateOpponentAdjustments(0, 10_000 * 1e6, 2);

        assertEq(adjustments.length, 2, "Should have 2 adjustments");
        assertLt(adjustments[0], 0, "Target should decrease");
        assertGt(adjustments[1], 0, "Opponent should increase");

        // 对手盘增加量应该等于买入金额
        assertEq(uint256(adjustments[1]), 10_000 * 1e6, "Opponent increase = buy amount");
    }

    function test_OpponentAdjustments_ThreeOutcomes() public {
        uint256 buyAmount = 12_000 * 1e6;
        int256[] memory adjustments = engine.calculateOpponentAdjustments(1, buyAmount, 3);

        assertEq(adjustments.length, 3, "Should have 3 adjustments");
        assertLt(adjustments[1], 0, "Target (1) should decrease");
        assertGt(adjustments[0], 0, "Opponent (0) should increase");
        assertGt(adjustments[2], 0, "Opponent (2) should increase");

        // 两个对手盘应该均分
        assertEq(uint256(adjustments[0]), buyAmount / 2, "Split evenly");
        assertEq(uint256(adjustments[2]), buyAmount / 2, "Split evenly");
    }

    // ============ 边界情况测试 ============

    function testRevert_CalculateShares_ExceedsReserve() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 10_000 * 1e6;  // 小储备
        reserves[1] = 100_000 * 1e6;

        // 尝试买入超过储备的量
        uint256 hugeAmount = 500_000 * 1e6;

        vm.expectRevert("CPMM: Insufficient reserve");
        engine.calculateShares(0, hugeAmount, reserves);
    }

    // testRevert_Price_ReserveTooHigh 已移除
    // SimpleCPMM 不再硬编码 MAX_RESERVE 检查，由调用者（模板）负责验证

    function testRevert_InvalidOutcomeCount() public {
        uint256[] memory reserves = new uint256[](4);
        reserves[0] = 100_000 * 1e6;
        reserves[1] = 100_000 * 1e6;
        reserves[2] = 100_000 * 1e6;
        reserves[3] = 100_000 * 1e6;

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.getPrice(0, reserves);
    }

    function testRevert_ZeroAmount() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000);

        vm.expectRevert("CPMM: Zero amount");
        engine.calculateShares(0, 0, reserves);
    }

    // ============ 辅助函数测试 ============

    function test_GetInitialReserves_TwoOutcomes() public {
        uint256[] memory reserves = engine.getInitialReserves(2, 6, 100_000);

        assertEq(reserves.length, 2, "Should have 2 reserves");
        assertEq(reserves[0], VIRTUAL_RESERVE_INIT, "Reserve 0 = INIT");
        assertEq(reserves[1], VIRTUAL_RESERVE_INIT, "Reserve 1 = INIT");
    }

    function test_GetInitialReserves_ThreeOutcomes() public {
        uint256[] memory reserves = engine.getInitialReserves(3, 6, 100_000);

        assertEq(reserves.length, 3, "Should have 3 reserves");
        assertEq(reserves[0], VIRTUAL_RESERVE_INIT, "Reserve 0 = INIT");
        assertEq(reserves[1], VIRTUAL_RESERVE_INIT, "Reserve 1 = INIT");
        assertEq(reserves[2], VIRTUAL_RESERVE_INIT, "Reserve 2 = INIT");
    }

    function testRevert_GetInitialReserves_InvalidCount() public {
        vm.expectRevert("CPMM: Invalid outcome count");
        engine.getInitialReserves(4, 6, 100_000);
    }

    // ============ Fuzz测试 ============

    function testFuzz_PriceNormalization_TwoOutcomes(
        uint96 reserve0,
        uint96 reserve1
    ) public {
        vm.assume(reserve0 >= MIN_RESERVE);
        vm.assume(reserve1 >= MIN_RESERVE);
        vm.assume(reserve0 <= MAX_RESERVE);
        vm.assume(reserve1 <= MAX_RESERVE);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = uint256(reserve0);
        reserves[1] = uint256(reserve1);

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);

        // 价格必须归一化为100%
        assertApproxEqAbs(price0 + price1, 10000, 1, "Prices must sum to 100%");

        // 每个价格都在合理范围内
        assertGt(price0, 0, "Price > 0");
        assertLt(price0, 10000, "Price < 100%");
    }

    function testFuzz_BuyingIncreasesPrice(
        uint96 initialReserve,
        uint32 buyAmount
    ) public {
        vm.assume(initialReserve >= MIN_RESERVE * 10);
        vm.assume(initialReserve <= 1_000_000 * 1e6);
        vm.assume(buyAmount >= 100 * 1e6); // 最小100 USDC
        vm.assume(buyAmount <= initialReserve / 10); // 最多买10%储备

        // 确保交易量足够大，能产生可测量的价格变化（至少0.1%）
        // 避免精度损失导致价格变化被四舍五入为0
        vm.assume(buyAmount >= initialReserve / 1000); // 至少0.1%储备

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = uint256(initialReserve);
        reserves[1] = uint256(initialReserve);

        uint256 priceBefore = engine.getPrice(0, reserves);

        uint256 shares = engine.calculateShares(0, uint256(buyAmount), reserves);
        reserves[0] -= shares;
        reserves[1] += uint256(buyAmount);

        uint256 priceAfter = engine.getPrice(0, reserves);

        // 核心不变量：买入必然导致价格上升
        assertGt(priceAfter, priceBefore, "Buying must increase price");
    }
}
