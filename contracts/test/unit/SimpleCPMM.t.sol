// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/pricing/SimpleCPMM.sol";

/**
 * @title SimpleCPMMTest
 * @notice Unit tests for SimpleCPMM pricing engine
 */
contract SimpleCPMMTest is BaseTest {
    SimpleCPMM public engine;

    function setUp() public override {
        super.setUp();
        engine = new SimpleCPMM();
    }

    // ============ Price Calculation Tests ============

    function test_GetPrice_TwoOutcomes_Equal() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);

        // Equal reserves should give 50% probability each
        assertEq(price0, 5000, "Outcome 0 should be 50%");
        assertEq(price1, 5000, "Outcome 1 should be 50%");
        assertEq(price0 + price1, 10000, "Prices should sum to 100%");
    }

    function test_GetPrice_TwoOutcomes_Skewed() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 250e18;  // Lower reserve = higher price (more likely)
        reserves[1] = 750e18;  // Higher reserve = lower price (less likely)

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);

        // Outcome 0 should be more expensive (higher probability)
        assertGt(price0, price1, "Outcome 0 should have higher price");
        assertApproxEqAbs(price0, 7500, 10); // ~75%
        assertApproxEqAbs(price1, 2500, 10); // ~25%
        assertEq(price0 + price1, 10000, "Prices should sum to 100%");
    }

    function test_GetPrice_ThreeOutcomes_Equal() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;
        reserves[2] = 1000e18;

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);
        uint256 price2 = engine.getPrice(2, reserves);

        // Equal reserves should give 33.33% probability each
        assertApproxEqAbs(price0, 3333, 10); // ~33.33%
        assertApproxEqAbs(price1, 3333, 10);
        assertApproxEqAbs(price2, 3333, 10);

        // Sum should be approximately 100% (within rounding error)
        uint256 sum = price0 + price1 + price2;
        assertApproxEqAbs(sum, 10000, 10);
    }

    function test_GetPrice_ThreeOutcomes_Skewed() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 200e18;  // Favorite
        reserves[1] = 500e18;  // Middle
        reserves[2] = 800e18;  // Underdog

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);
        uint256 price2 = engine.getPrice(2, reserves);

        // Verify ordering
        assertGt(price0, price1, "Price 0 > Price 1");
        assertGt(price1, price2, "Price 1 > Price 2");

        // Verify normalization (sum = 100%)
        uint256 sum = price0 + price1 + price2;
        assertApproxEqAbs(sum, 10000, 10);
    }

    // ============ Shares Calculation Tests ============

    function test_CalculateShares_TwoOutcomes_Basic() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;

        uint256 amount = 100e18;
        uint256 shares = engine.calculateShares(0, amount, reserves);

        // Shares should be at least amount (1:1 minimum)
        assertGe(shares, amount, "Shares should be at least amount");

        // For balanced market, shares should be close to amount
        // Within reasonable range (can vary based on market conditions)
        assertLe(shares, amount * 2); // Not more than 2x
    }

    function test_CalculateShares_TwoOutcomes_LowReserve() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;   // Low reserve
        reserves[1] = 1000e18;  // High reserve

        uint256 amount = 10e18;
        uint256 shares = engine.calculateShares(0, amount, reserves);

        // Buying into low reserve outcome should give fewer shares
        // (more expensive because it's the favorite)
        assertGe(shares, amount, "Shares should be at least amount");
    }

    function test_CalculateShares_ThreeOutcomes_Basic() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;
        reserves[2] = 1000e18;

        uint256 amount = 100e18;
        uint256 shares0 = engine.calculateShares(0, amount, reserves);
        uint256 shares1 = engine.calculateShares(1, amount, reserves);
        uint256 shares2 = engine.calculateShares(2, amount, reserves);

        // All outcomes should give similar shares (balanced market)
        assertApproxEqAbs(shares0, shares1, shares1 / 100); // Within 1%
        assertApproxEqAbs(shares1, shares2, shares2 / 100);
        assertGe(shares0, amount, "Shares should be at least amount");
    }

    function test_CalculateShares_MinimumGuarantee() public {
        // Test that shares are always at least the amount
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 100e18;

        uint256 amount = 50e18;
        uint256 shares = engine.calculateShares(0, amount, reserves);

        assertGe(shares, amount, "Shares must be at least amount");
    }

    // ============ Edge Cases and Validation ============

    function testRevert_GetPrice_InvalidOutcomeCount_Zero() public {
        uint256[] memory reserves = new uint256[](0);

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.getPrice(0, reserves);
    }

    function testRevert_GetPrice_InvalidOutcomeCount_One() public {
        uint256[] memory reserves = new uint256[](1);
        reserves[0] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.getPrice(0, reserves);
    }

    function testRevert_GetPrice_InvalidOutcomeCount_Four() public {
        uint256[] memory reserves = new uint256[](4);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;
        reserves[2] = 1000e18;
        reserves[3] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.getPrice(0, reserves);
    }

    function testRevert_GetPrice_InvalidOutcomeId() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome ID");
        engine.getPrice(2, reserves); // ID 2 doesn't exist for 2-outcome market
    }

    function testRevert_GetPrice_ReserveTooLow() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100; // Below MIN_RESERVE
        reserves[1] = 1000e18;

        vm.expectRevert("CPMM: Reserve too low");
        engine.getPrice(0, reserves);
    }

    function testRevert_CalculateShares_ZeroAmount() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;

        vm.expectRevert("CPMM: Zero amount");
        engine.calculateShares(0, 0, reserves);
    }

    function testRevert_CalculateShares_InvalidOutcomeCount() public {
        uint256[] memory reserves = new uint256[](1);
        reserves[0] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.calculateShares(0, 100e18, reserves);
    }

    function testRevert_CalculateShares_InvalidOutcomeId() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;
        reserves[2] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome ID");
        engine.calculateShares(3, 100e18, reserves); // ID 3 doesn't exist
    }

    function testRevert_CalculateShares_ReserveTooLow() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100; // Below MIN_RESERVE
        reserves[1] = 1000e18;

        vm.expectRevert("CPMM: Reserve too low");
        engine.calculateShares(0, 100e18, reserves);
    }

    // ============ K Value Calculation Tests ============

    function test_CalculateK_TwoOutcomes() public {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100e18;
        reserves[1] = 200e18;

        uint256 k = engine.calculateK(reserves);
        assertEq(k, 100e18 * 200e18, "K should be product of reserves");
    }

    function test_CalculateK_ThreeOutcomes() public {
        uint256[] memory reserves = new uint256[](3);
        reserves[0] = 100e18;
        reserves[1] = 200e18;
        reserves[2] = 300e18;

        uint256 k = engine.calculateK(reserves);
        assertEq(k, 100e18 * 200e18 * 300e18, "K should be product of reserves");
    }

    function testRevert_CalculateK_InvalidOutcomeCount() public {
        uint256[] memory reserves = new uint256[](1);
        reserves[0] = 1000e18;

        vm.expectRevert("CPMM: Invalid outcome count");
        engine.calculateK(reserves);
    }

    // ============ Fuzz Tests ============

    function testFuzz_GetPrice_Normalization(
        uint128 reserve0,
        uint128 reserve1
    ) public {
        // Ensure reserves are valid and not too extreme
        vm.assume(reserve0 >= engine.MIN_RESERVE() * 100);
        vm.assume(reserve1 >= engine.MIN_RESERVE() * 100);
        // Avoid extreme ratios (max 100:1)
        if (reserve0 > reserve1) {
            vm.assume(reserve0 / reserve1 < 100);
        } else {
            vm.assume(reserve1 / reserve0 < 100);
        }

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = uint256(reserve0);
        reserves[1] = uint256(reserve1);

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);

        // Prices should always sum to 10000 (100%)
        // Allow 1 basis point tolerance for rounding
        uint256 sum = price0 + price1;
        assertApproxEqAbs(sum, 10000, 1, "Prices must sum to ~100%");

        // Each price should be > 0 and < 100%
        assertGt(price0, 0, "Price must be > 0");
        assertLt(price0, 10000, "Price must be < 100%");
        assertGt(price1, 0, "Price must be > 0");
        assertLt(price1, 10000, "Price must be < 100%");
    }

    function testFuzz_GetPrice_ThreeOutcomes_Normalization(
        uint64 reserve0,
        uint64 reserve1,
        uint64 reserve2
    ) public {
        // Ensure reserves are valid and not too extreme
        uint256 minReserve = engine.MIN_RESERVE() * 10;
        vm.assume(reserve0 >= minReserve);
        vm.assume(reserve1 >= minReserve);
        vm.assume(reserve2 >= minReserve);

        // Avoid extreme ratios that cause precision issues
        uint256 maxReserve = reserve0;
        if (reserve1 > maxReserve) maxReserve = reserve1;
        if (reserve2 > maxReserve) maxReserve = reserve2;
        uint256 minR = reserve0;
        if (reserve1 < minR) minR = reserve1;
        if (reserve2 < minR) minR = reserve2;
        vm.assume(maxReserve / minR < 50); // Max 50:1 ratio

        uint256[] memory reserves = new uint256[](3);
        reserves[0] = uint256(reserve0);
        reserves[1] = uint256(reserve1);
        reserves[2] = uint256(reserve2);

        uint256 price0 = engine.getPrice(0, reserves);
        uint256 price1 = engine.getPrice(1, reserves);
        uint256 price2 = engine.getPrice(2, reserves);

        // Prices should approximately sum to 10000 (100%)
        // Allow small rounding error
        uint256 sum = price0 + price1 + price2;
        assertApproxEqAbs(sum, 10000, 10);

        // Each price should be > 0 and < 100%
        if (price0 > 0) assertLt(price0, 10000, "Price must be < 100%");
        if (price1 > 0) assertLt(price1, 10000, "Price must be < 100%");
        if (price2 > 0) assertLt(price2, 10000, "Price must be < 100%");
    }

    function testFuzz_CalculateShares_MinimumGuarantee(
        uint64 reserve0,
        uint64 reserve1,
        uint64 amount
    ) public {
        // Ensure valid inputs
        vm.assume(reserve0 >= engine.MIN_RESERVE());
        vm.assume(reserve1 >= engine.MIN_RESERVE());
        vm.assume(amount > 0 && amount < type(uint64).max);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = uint256(reserve0);
        reserves[1] = uint256(reserve1);

        uint256 shares = engine.calculateShares(0, uint256(amount), reserves);

        // Shares should always be at least the amount
        assertGe(shares, amount, "Shares must be at least amount");
    }
}
