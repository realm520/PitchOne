// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/LMSR.sol";
import "../../src/pricing/LMSR_Optimized.sol";

contract LMSR_GasComparisonTest is Test {
    LMSR public lmsrOriginal;
    LMSR_Optimized public lmsrOptimized;

    uint256 constant WAD = 1e18;
    uint256 constant LIQUIDITY_B = 10_000 * WAD;

    function setUp() public {
        lmsrOriginal = new LMSR(LIQUIDITY_B, 17);
        lmsrOptimized = new LMSR_Optimized(LIQUIDITY_B, 17);

        uint256[] memory initialQuantities = new uint256[](17);
        for (uint256 i = 0; i < 17; i++) {
            initialQuantities[i] = 1000 * WAD;
        }

        lmsrOriginal.initializeQuantities(initialQuantities);
        lmsrOptimized.initializeQuantities(initialQuantities);
    }

    function test_Gas_SmallBet_Original() public view {
        uint256[] memory reserves = new uint256[](0);
        lmsrOriginal.calculateShares(0, 100 * WAD, reserves);
    }

    function test_Gas_SmallBet_Optimized() public view {
        uint256[] memory reserves = new uint256[](0);
        lmsrOptimized.calculateShares(0, 100 * WAD, reserves);
    }

    function test_Gas_MediumBet_Original() public view {
        uint256[] memory reserves = new uint256[](0);
        lmsrOriginal.calculateShares(0, 1000 * WAD, reserves);
    }

    function test_Gas_MediumBet_Optimized() public view {
        uint256[] memory reserves = new uint256[](0);
        lmsrOptimized.calculateShares(0, 1000 * WAD, reserves);
    }

    function test_AccuracyComparison() public view {
        uint256[] memory reserves = new uint256[](0);
        
        uint256 sharesOriginal = lmsrOriginal.calculateShares(0, 1000 * WAD, reserves);
        uint256 sharesOptimized = lmsrOptimized.calculateShares(0, 1000 * WAD, reserves);

        uint256 diff = sharesOriginal > sharesOptimized 
            ? sharesOriginal - sharesOptimized 
            : sharesOptimized - sharesOriginal;
        
        uint256 diffPercent = (diff * 10000) / sharesOriginal;
        
        assertLe(diffPercent, 50, "Accuracy loss should be < 0.5%");
        
        console.log("Original shares:", sharesOriginal / WAD);
        console.log("Optimized shares:", sharesOptimized / WAD);
        console.log("Difference (bps):", diffPercent);
    }
}
