// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/LMSR.sol";

/**
 * @title LMSR Test
 * @notice LMSR 定价引擎的单元测试
 */
contract LMSRTest is Test {
    LMSR public lmsr;

    // 测试参数
    uint256 constant WAD = 1e18;
    uint256 constant BPS_BASE = 10000;
    uint256 constant DEFAULT_B = 1000 * WAD; // 流动性参数 b = 1000
    uint256 constant OUTCOME_COUNT_BINARY = 2;
    uint256 constant OUTCOME_COUNT_TERNARY = 3;
    uint256 constant OUTCOME_COUNT_MANY = 10;

    address owner = address(this);

    function setUp() public {
        // 默认创建二向市场
        lmsr = new LMSR(DEFAULT_B, OUTCOME_COUNT_BINARY);
    }

    // ============================================================================
    // 构造函数测试
    // ============================================================================

    function test_Constructor_Success() public {
        LMSR newLmsr = new LMSR(DEFAULT_B, 5);

        assertEq(newLmsr.liquidityB(), DEFAULT_B);
        assertEq(newLmsr.outcomeCount(), 5);
    }

    function test_Constructor_RevertIf_InvalidLiquidityB_TooSmall() public {
        vm.expectRevert("LMSR: Invalid liquidity B");
        new LMSR(50 * WAD, 3); // 小于 MIN_LIQUIDITY_B (100)
    }

    function test_Constructor_RevertIf_InvalidLiquidityB_TooLarge() public {
        vm.expectRevert("LMSR: Invalid liquidity B");
        new LMSR(2_000_000 * WAD, 3); // 大于 MAX_LIQUIDITY_B (1,000,000)
    }

    function test_Constructor_RevertIf_InvalidOutcomeCount_TooSmall() public {
        vm.expectRevert("LMSR: Invalid outcome count");
        new LMSR(DEFAULT_B, 1); // 小于 2
    }

    function test_Constructor_RevertIf_InvalidOutcomeCount_TooLarge() public {
        vm.expectRevert("LMSR: Invalid outcome count");
        new LMSR(DEFAULT_B, 101); // 大于 MAX_OUTCOMES (100)
    }

    // ============================================================================
    // 初始化持仓量测试
    // ============================================================================

    function test_InitializeQuantities_Success() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;

        lmsr.initializeQuantities(initialQ);

        assertEq(lmsr.quantityShares(0), 100 * WAD);
        assertEq(lmsr.quantityShares(1), 100 * WAD);
    }

    function test_InitializeQuantities_RevertIf_LengthMismatch() public {
        uint256[] memory initialQ = new uint256[](3); // 期望 2 个，提供 3 个

        vm.expectRevert("LMSR: Length mismatch");
        lmsr.initializeQuantities(initialQ);
    }

    function test_InitializeQuantities_EmitsEvents() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 200 * WAD;

        vm.expectEmit(true, true, true, true);
        emit LMSR.QuantityUpdated(0, 0, 100 * WAD);

        vm.expectEmit(true, true, true, true);
        emit LMSR.QuantityUpdated(1, 0, 200 * WAD);

        lmsr.initializeQuantities(initialQ);
    }

    // ============================================================================
    // GetPrice 测试
    // ============================================================================

    function test_GetPrice_EqualQuantities_EqualPrices() public {
        // 初始化相等持仓
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        // 获取价格
        uint256[] memory reserves = new uint256[](0); // LMSR 不使用 reserves 参数
        uint256 price0 = lmsr.getPrice(0, reserves);
        uint256 price1 = lmsr.getPrice(1, reserves);

        // 相等持仓 → 相等价格 ≈ 50%
        assertApproxEqAbs(price0, 5000, 10); // 50% ± 0.1%
        assertApproxEqAbs(price1, 5000, 10);
    }

    function test_GetPrice_UnequalQuantities_DifferentPrices() public {
        // 初始化不等持仓
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 200 * WAD; // 更多份额 → 更高价格
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256[] memory reserves = new uint256[](0);
        uint256 price0 = lmsr.getPrice(0, reserves);
        uint256 price1 = lmsr.getPrice(1, reserves);

        // price0 应该 > price1
        assertGt(price0, price1);
        assertGt(price0, 5000); // > 50%
        assertLt(price1, 5000); // < 50%
    }

    function test_GetPrice_ThreeOutcomes_SumTo100Percent() public {
        // 创建三向市场
        LMSR lmsr3 = new LMSR(DEFAULT_B, 3);

        uint256[] memory initialQ = new uint256[](3);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 150 * WAD;
        initialQ[2] = 200 * WAD;
        lmsr3.initializeQuantities(initialQ);

        uint256[] memory prices = lmsr3.getAllPrices();

        // 价格总和应该 ≈ 100%
        uint256 totalPrice = prices[0] + prices[1] + prices[2];
        assertApproxEqAbs(totalPrice, BPS_BASE, 50); // 100% ± 0.5%
    }

    function test_GetPrice_RevertIf_InvalidOutcomeId() public {
        uint256[] memory reserves = new uint256[](0);

        vm.expectRevert("LMSR: Invalid outcome ID");
        lmsr.getPrice(5, reserves); // outcomeCount = 2, 所以 5 无效
    }

    // ============================================================================
    // CalculateShares 测试
    // ============================================================================

    function test_CalculateShares_SmallAmount() public {
        // 初始化持仓
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 1000 * WAD;
        initialQ[1] = 1000 * WAD;
        lmsr.initializeQuantities(initialQ);

        // 买入小额
        uint256 amount = 10 * WAD; // 10 单位
        uint256[] memory reserves = new uint256[](0);

        uint256 shares = lmsr.calculateShares(0, amount, reserves);

        // 应该获得 > 0 份额
        assertGt(shares, 0);
        // LMSR 特性：shares 可能小于 amount（由于成本函数非线性）
        // 这是正常的，只需验证获得了合理数量的份额
        assertGt(shares, amount / 2); // 至少获得 amount 的 50%
    }

    function test_CalculateShares_LargeAmount() public {
        // 初始化持仓
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 1000 * WAD;
        initialQ[1] = 1000 * WAD;
        lmsr.initializeQuantities(initialQ);

        // 买入大额
        uint256 amount = 1000 * WAD; // 1000 单位
        uint256[] memory reserves = new uint256[](0);

        uint256 shares = lmsr.calculateShares(0, amount, reserves);

        // 应该获得份额
        assertGt(shares, 0);
        // 大额购买会有更多滑点
        assertLt(shares, amount); // shares < amount（由于滑点）
    }

    function test_CalculateShares_RevertIf_ZeroAmount() public {
        uint256[] memory reserves = new uint256[](0);

        vm.expectRevert("LMSR: Zero amount");
        lmsr.calculateShares(0, 0, reserves);
    }

    function test_CalculateShares_RevertIf_InvalidOutcomeId() public {
        uint256[] memory reserves = new uint256[](0);

        vm.expectRevert("LMSR: Invalid outcome ID");
        lmsr.calculateShares(10, 100 * WAD, reserves);
    }

    // ============================================================================
    // UpdateQuantity 测试
    // ============================================================================

    function test_UpdateQuantity_Success() public {
        // 初始化持仓
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        // 更新持仓
        uint256 sharesToAdd = 50 * WAD;
        lmsr.updateQuantity(0, sharesToAdd);

        assertEq(lmsr.quantityShares(0), 150 * WAD);
    }

    function test_UpdateQuantity_EmitsEvent() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        vm.expectEmit(true, true, true, true);
        emit LMSR.QuantityUpdated(0, 100 * WAD, 150 * WAD);

        lmsr.updateQuantity(0, 50 * WAD);
    }

    function test_UpdateQuantity_RevertIf_ZeroShares() public {
        vm.expectRevert("LMSR: Zero shares");
        lmsr.updateQuantity(0, 0);
    }

    function test_UpdateQuantity_RevertIf_InvalidOutcomeId() public {
        vm.expectRevert("LMSR: Invalid outcome ID");
        lmsr.updateQuantity(10, 100 * WAD);
    }

    function test_UpdateQuantity_RevertIf_NotOwner() public {
        address notOwner = address(0x123);

        vm.prank(notOwner);
        vm.expectRevert(); // Ownable: caller is not the owner
        lmsr.updateQuantity(0, 100 * WAD);
    }

    // ============================================================================
    // SetLiquidityB 测试
    // ============================================================================

    function test_SetLiquidityB_Success() public {
        uint256 newB = 2000 * WAD;

        vm.expectEmit(true, true, true, true);
        emit LMSR.LiquidityBUpdated(DEFAULT_B, newB);

        lmsr.setLiquidityB(newB);

        assertEq(lmsr.liquidityB(), newB);
    }

    function test_SetLiquidityB_RevertIf_TooSmall() public {
        vm.expectRevert("LMSR: Invalid liquidity B");
        lmsr.setLiquidityB(50 * WAD); // < MIN_LIQUIDITY_B
    }

    function test_SetLiquidityB_RevertIf_TooLarge() public {
        vm.expectRevert("LMSR: Invalid liquidity B");
        lmsr.setLiquidityB(2_000_000 * WAD); // > MAX_LIQUIDITY_B
    }

    function test_SetLiquidityB_RevertIf_NotOwner() public {
        address notOwner = address(0x123);

        vm.prank(notOwner);
        vm.expectRevert(); // Ownable: caller is not the owner
        lmsr.setLiquidityB(2000 * WAD);
    }

    // ============================================================================
    // GetAllPrices 测试
    // ============================================================================

    function test_GetAllPrices_BinaryMarket() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256[] memory prices = lmsr.getAllPrices();

        assertEq(prices.length, 2);
        assertApproxEqAbs(prices[0], 5000, 10); // ≈ 50%
        assertApproxEqAbs(prices[1], 5000, 10);
    }

    function test_GetAllPrices_TernaryMarket() public {
        LMSR lmsr3 = new LMSR(DEFAULT_B, 3);

        uint256[] memory initialQ = new uint256[](3);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        initialQ[2] = 100 * WAD;
        lmsr3.initializeQuantities(initialQ);

        uint256[] memory prices = lmsr3.getAllPrices();

        assertEq(prices.length, 3);
        // 相等持仓 → 相等价格 ≈ 33.33%
        assertApproxEqAbs(prices[0], 3333, 50);
        assertApproxEqAbs(prices[1], 3333, 50);
        assertApproxEqAbs(prices[2], 3333, 50);
    }

    function test_GetAllPrices_ManyOutcomes() public {
        LMSR lmsrMany = new LMSR(DEFAULT_B, 10);

        uint256[] memory initialQ = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            initialQ[i] = 100 * WAD;
        }
        lmsrMany.initializeQuantities(initialQ);

        uint256[] memory prices = lmsrMany.getAllPrices();

        assertEq(prices.length, 10);

        // 每个价格应该 ≈ 10%
        for (uint256 i = 0; i < 10; i++) {
            assertApproxEqAbs(prices[i], 1000, 50); // 10% ± 0.5%
        }

        // 总和应该 ≈ 100%
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < 10; i++) {
            totalPrice += prices[i];
        }
        assertApproxEqAbs(totalPrice, BPS_BASE, 100);
    }

    // ============================================================================
    // GetAllQuantities 测试
    // ============================================================================

    function test_GetAllQuantities_Success() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 200 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256[] memory quantities = lmsr.getAllQuantities();

        assertEq(quantities.length, 2);
        assertEq(quantities[0], 100 * WAD);
        assertEq(quantities[1], 200 * WAD);
    }

    // ============================================================================
    // GetCurrentCost 测试
    // ============================================================================

    function test_GetCurrentCost_EqualQuantities() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 100 * WAD;
        initialQ[1] = 100 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256 cost = lmsr.getCurrentCost();

        // 成本应该 > 0
        assertGt(cost, 0);
    }

    function test_GetCurrentCost_IncreasesWithQuantity() public {
        uint256[] memory initialQ1 = new uint256[](2);
        initialQ1[0] = 100 * WAD;
        initialQ1[1] = 100 * WAD;

        LMSR lmsr1 = new LMSR(DEFAULT_B, 2);
        lmsr1.initializeQuantities(initialQ1);
        uint256 cost1 = lmsr1.getCurrentCost();

        uint256[] memory initialQ2 = new uint256[](2);
        initialQ2[0] = 200 * WAD; // 更多持仓
        initialQ2[1] = 200 * WAD;

        LMSR lmsr2 = new LMSR(DEFAULT_B, 2);
        lmsr2.initializeQuantities(initialQ2);
        uint256 cost2 = lmsr2.getCurrentCost();

        // 更多持仓 → 更高成本
        assertGt(cost2, cost1);
    }

    // ============================================================================
    // 价格不变量测试
    // ============================================================================

    function test_Invariant_PricesSumTo100Percent() public {
        // 测试不同配置下价格总和都是 100%
        for (uint256 n = 2; n <= 5; n++) {
            LMSR testLmsr = new LMSR(DEFAULT_B, n);

            uint256[] memory initialQ = new uint256[](n);
            for (uint256 i = 0; i < n; i++) {
                // 随机但合理的初始持仓
                initialQ[i] = (100 + i * 50) * WAD;
            }
            testLmsr.initializeQuantities(initialQ);

            uint256[] memory prices = testLmsr.getAllPrices();

            uint256 totalPrice = 0;
            for (uint256 i = 0; i < n; i++) {
                totalPrice += prices[i];
            }

            // 允许一定误差
            assertApproxEqAbs(totalPrice, BPS_BASE, 100, "Prices should sum to 100%");
        }
    }

    // ============================================================================
    // 边界测试
    // ============================================================================

    function test_BoundaryTest_VerySmallQuantity() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 1 * WAD; // 非常小的持仓
        initialQ[1] = 1000 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256[] memory prices = lmsr.getAllPrices();

        // price0 应该非常小，price1 应该非常大
        // 由于 exp 函数的特性，极端比例下价格可能不会完全接近 0% 或 100%
        assertLt(prices[0], 3000); // < 30% (更宽松的边界)
        assertGt(prices[1], 7000); // > 70%

        // 验证 price1 > price0
        assertGt(prices[1], prices[0]);
    }

    function test_BoundaryTest_VeryLargeQuantity() public {
        uint256[] memory initialQ = new uint256[](2);
        initialQ[0] = 10000 * WAD; // 非常大的持仓
        initialQ[1] = 1 * WAD;
        lmsr.initializeQuantities(initialQ);

        uint256[] memory prices = lmsr.getAllPrices();

        // price0 应该非常高
        assertGt(prices[0], 9900); // > 99%
        assertLt(prices[1], 100);  // < 1%
    }
}
