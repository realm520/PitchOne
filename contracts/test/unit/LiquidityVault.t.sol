// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/liquidity/LiquidityVault.sol";

/**
 * @title LiquidityVaultTest
 * @notice LiquidityVault (ERC-4626 LP 金库) 单元测试
 */
contract LiquidityVaultTest is BaseTest {
    LiquidityVault public vault;

    // 测试常量
    uint256 constant INITIAL_DEPOSIT = 100_000 * 1e6; // 100,000 USDC
    uint256 constant MARKET_BORROW = 30_000 * 1e6;    // 30,000 USDC

    // 模拟市场地址
    address public mockMarket1;
    address public mockMarket2;

    function setUp() public override {
        super.setUp();

        // 部署 Vault
        vault = new LiquidityVault(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );

        // 创建模拟市场地址
        mockMarket1 = address(0x1111);
        mockMarket2 = address(0x2222);

        // 授权模拟市场
        vault.authorizeMarket(mockMarket1);

        // 给测试账户铸造 USDC
        usdc.mint(user1, 1_000_000 * 1e6); // 1M USDC
        usdc.mint(user2, 1_000_000 * 1e6);
        usdc.mint(mockMarket1, 100_000 * 1e6);
    }

    // ============ 基本 ERC-4626 功能测试 ============

    function test_Vault_BasicInfo() public view {
        assertEq(vault.name(), "PitchOne LP Token");
        assertEq(vault.symbol(), "pLP");
        assertEq(address(vault.asset()), address(usdc));
        assertEq(vault.decimals(), 6); // USDC decimals
    }

    function test_Deposit_MintShares() public {
        vm.startPrank(user1);

        // 授权 Vault
        usdc.approve(address(vault), INITIAL_DEPOSIT);

        // 存款
        uint256 shares = vault.deposit(INITIAL_DEPOSIT, user1);

        // 验证
        assertEq(vault.balanceOf(user1), shares, "User should have shares");
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT, "Total assets");
        assertEq(vault.totalSupply(), shares, "Total supply");

        // 首次存款：1:1 比例
        assertEq(shares, INITIAL_DEPOSIT, "Initial shares = assets");

        vm.stopPrank();
    }

    function test_Withdraw_BurnShares() public {
        // 先存款
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        uint256 shares = vault.deposit(INITIAL_DEPOSIT, user1);

        // 提款一半
        uint256 withdrawAmount = INITIAL_DEPOSIT / 2;
        uint256 sharesBurned = vault.withdraw(withdrawAmount, user1, user1);

        // 验证
        assertEq(vault.balanceOf(user1), shares - sharesBurned, "Remaining shares");
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT - withdrawAmount, "Remaining assets");

        vm.stopPrank();
    }

    function test_Redeem_ConvertSharesToAssets() public {
        vm.startPrank(user1);

        usdc.approve(address(vault), INITIAL_DEPOSIT);
        uint256 shares = vault.deposit(INITIAL_DEPOSIT, user1);

        // 赎回一半 shares
        uint256 redeemShares = shares / 2;
        uint256 assetsReceived = vault.redeem(redeemShares, user1, user1);

        // 验证
        assertEq(vault.balanceOf(user1), shares - redeemShares, "Remaining shares");
        assertApproxEqAbs(assetsReceived, INITIAL_DEPOSIT / 2, 1, "Assets received");

        vm.stopPrank();
    }

    function test_MultipleDepositors_SharesCalculation() public {
        // User1 存入 100k
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        uint256 shares1 = vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // User2 存入 50k
        vm.startPrank(user2);
        usdc.approve(address(vault), 50_000 * 1e6);
        uint256 shares2 = vault.deposit(50_000 * 1e6, user2);
        vm.stopPrank();

        // 验证
        assertEq(vault.totalAssets(), 150_000 * 1e6, "Total assets");
        assertEq(vault.balanceOf(user1), shares1, "User1 shares");
        assertEq(vault.balanceOf(user2), shares2, "User2 shares");

        // User1 拥有 2/3 份额
        assertApproxEqRel(shares1, (vault.totalSupply() * 2) / 3, 0.01e18, "User1 ~66.67%");
    }

    // ============ 市场借贷功能测试 ============

    function test_AuthorizeMarket() public {
        address newMarket = address(0x3333);

        vault.authorizeMarket(newMarket);

        assertTrue(vault.authorizedMarkets(newMarket), "Market should be authorized");

        address[] memory markets = vault.getAuthorizedMarkets();
        assertEq(markets.length, 2, "Should have 2 markets"); // mockMarket1 + newMarket
    }

    function testRevert_AuthorizeMarket_Duplicate() public {
        vm.expectRevert("Market already authorized");
        vault.authorizeMarket(mockMarket1);
    }

    function test_RevokeMarket() public {
        vault.revokeMarket(mockMarket1);

        assertFalse(vault.authorizedMarkets(mockMarket1), "Market should be revoked");
    }

    function testRevert_RevokeMarket_WithDebt() public {
        // 先让市场借款
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        vm.prank(mockMarket1);
        vault.borrow(10_000 * 1e6);

        // 尝试撤销（应该失败）
        vm.expectRevert("Market has outstanding debt");
        vault.revokeMarket(mockMarket1);
    }

    function test_Borrow_UpdatesState() public {
        // LP 存入流动性
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        // 市场借款
        uint256 borrowAmount = 30_000 * 1e6;
        uint256 vaultBalanceBefore = usdc.balanceOf(address(vault));

        vm.prank(mockMarket1);
        vault.borrow(borrowAmount);

        // 验证
        assertEq(vault.borrowed(mockMarket1), borrowAmount, "Borrow balance");
        assertEq(vault.totalBorrowed(), borrowAmount, "Total borrowed");
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT, "Total assets unchanged");
        assertEq(
            usdc.balanceOf(address(vault)),
            vaultBalanceBefore - borrowAmount,
            "Vault USDC decreased"
        );
        assertEq(usdc.balanceOf(mockMarket1), 100_000 * 1e6 + borrowAmount, "Market received");
    }

    function testRevert_Borrow_Unauthorized() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        // 未授权市场尝试借款
        vm.prank(mockMarket2);
        vm.expectRevert(
            abi.encodeWithSelector(LiquidityVault.UnauthorizedMarket.selector, mockMarket2)
        );
        vault.borrow(10_000 * 1e6);
    }

    function testRevert_Borrow_ExceedsUtilization() public {
        // 存入 100k
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 尝试借 95k（超过 90% 利用率）
        // available = 当前余额 = 100k（因为还没借出）
        vm.prank(mockMarket1);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidityVault.ExceedsUtilizationLimit.selector,
                95_000 * 1e6,
                100_000 * 1e6 // available = 当前全部资产
            )
        );
        vault.borrow(95_000 * 1e6);
    }

    function testRevert_Borrow_ExceedsMarketLimit() public {
        // 存入 100k
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 单市场最大 50k
        vm.prank(mockMarket1);
        vm.expectRevert(); // ExceedsMarketBorrowLimit
        vault.borrow(60_000 * 1e6);
    }

    function test_Repay_UpdatesStateAndRevenue() public {
        // LP 存入
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        // 市场借款
        uint256 borrowAmount = 30_000 * 1e6;
        vm.prank(mockMarket1);
        vault.borrow(borrowAmount);

        // 市场还款（本金 + 收益）
        uint256 revenue = 1_000 * 1e6; // 1,000 USDC 手续费
        vm.startPrank(mockMarket1);
        usdc.approve(address(vault), borrowAmount + revenue);
        vault.repay(borrowAmount, revenue);
        vm.stopPrank();

        // 验证
        assertEq(vault.borrowed(mockMarket1), 0, "Debt cleared");
        assertEq(vault.totalBorrowed(), 0, "Total borrowed = 0");
        assertEq(vault.totalRevenueAccumulated(), revenue, "Revenue accumulated");
        assertEq(vault.totalAssets(), INITIAL_DEPOSIT + revenue, "Assets increased");
    }

    function testRevert_Repay_ExceedsBorrowed() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_DEPOSIT);
        vault.deposit(INITIAL_DEPOSIT, user1);
        vm.stopPrank();

        vm.prank(mockMarket1);
        vault.borrow(10_000 * 1e6);

        // 尝试还款 20k（超过借款）
        vm.startPrank(mockMarket1);
        usdc.approve(address(vault), 30_000 * 1e6);
        vm.expectRevert(); // InsufficientBorrowBalance
        vault.repay(20_000 * 1e6, 0);
        vm.stopPrank();
    }

    // ============ 收益分配测试 ============

    function test_Revenue_IncreasesShareValue() public {
        // User1 存入 100k
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        uint256 shares1 = vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 市场借款 → 归还 + 收益
        vm.prank(mockMarket1);
        vault.borrow(30_000 * 1e6);

        uint256 revenue = 5_000 * 1e6; // 5k 收益
        vm.startPrank(mockMarket1);
        usdc.approve(address(vault), 30_000 * 1e6 + revenue);
        vault.repay(30_000 * 1e6, revenue);
        vm.stopPrank();

        // 验证 share 价值上涨（允许精度误差）
        uint256 shareValue = vault.convertToAssets(shares1);
        assertApproxEqAbs(shareValue, 105_000 * 1e6, 10, "Share value ~105k (100k + 5k revenue)");

        // User2 现在存入 105k，应该得到相同数量的 shares
        vm.startPrank(user2);
        usdc.approve(address(vault), 105_000 * 1e6);
        uint256 shares2 = vault.deposit(105_000 * 1e6, user2);
        vm.stopPrank();

        assertApproxEqAbs(shares2, shares1, 100, "Same shares for same value");
    }

    function test_MultipleLP_RevenueDistribution() public {
        // User1 存入 60k
        vm.startPrank(user1);
        usdc.approve(address(vault), 60_000 * 1e6);
        uint256 shares1 = vault.deposit(60_000 * 1e6, user1);
        vm.stopPrank();

        // User2 存入 40k
        vm.startPrank(user2);
        usdc.approve(address(vault), 40_000 * 1e6);
        uint256 shares2 = vault.deposit(40_000 * 1e6, user2);
        vm.stopPrank();

        // 总资产 100k，User1 占 60%，User2 占 40%

        // 市场产生 10k 收益
        vm.prank(mockMarket1);
        vault.borrow(50_000 * 1e6);

        vm.startPrank(mockMarket1);
        usdc.approve(address(vault), 60_000 * 1e6);
        vault.repay(50_000 * 1e6, 10_000 * 1e6);
        vm.stopPrank();

        // 验证收益分配
        uint256 user1Value = vault.convertToAssets(shares1);
        uint256 user2Value = vault.convertToAssets(shares2);

        assertApproxEqAbs(user1Value, 66_000 * 1e6, 100, "User1 value = 60k + 6k");
        assertApproxEqAbs(user2Value, 44_000 * 1e6, 100, "User2 value = 40k + 4k");
    }

    // ============ 流动性限制测试 ============

    function test_AvailableLiquidity_AfterBorrow() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        vm.prank(mockMarket1);
        vault.borrow(30_000 * 1e6);

        uint256 available = vault.availableLiquidity();
        assertEq(available, 70_000 * 1e6, "Available = 70k");

        uint256 utilization = vault.utilizationRate();
        assertEq(utilization, 3000, "Utilization = 30%");
    }

    function testRevert_Withdraw_InsufficientLiquidity() public {
        // User1 存入 100k
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 市场借走 90k
        vm.prank(mockMarket1);
        vault.borrow(50_000 * 1e6);

        // User1 尝试提取 60k（但只有 50k 可用）
        vm.prank(user1);
        vm.expectRevert("Insufficient liquidity");
        vault.withdraw(60_000 * 1e6, user1, user1);
    }

    function test_MaxWithdraw_LimitedByLiquidity() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 借走 70k，剩余 30k
        vm.prank(mockMarket1);
        vault.borrow(50_000 * 1e6);

        uint256 maxWithdraw = vault.maxWithdraw(user1);
        assertEq(maxWithdraw, 50_000 * 1e6, "Max withdraw = available liquidity");
    }

    // ============ 暂停功能测试 ============

    function test_Pause_StopsDeposits() public {
        vault.pause();

        vm.startPrank(user1);
        usdc.approve(address(vault), 10_000 * 1e6);

        vm.expectRevert();
        vault.deposit(10_000 * 1e6, user1);

        vm.stopPrank();
    }

    function test_Unpause_ResumesDeposits() public {
        vault.pause();
        vault.unpause();

        vm.startPrank(user1);
        usdc.approve(address(vault), 10_000 * 1e6);
        vault.deposit(10_000 * 1e6, user1);
        vm.stopPrank();

        assertEq(vault.totalAssets(), 10_000 * 1e6);
    }

    // ============ 紧急提款测试 ============

    function test_EmergencyWithdraw() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 管理员紧急提款 10k
        address recipient = address(0x9999);
        vault.emergencyWithdraw(recipient, 10_000 * 1e6);

        assertEq(usdc.balanceOf(recipient), 10_000 * 1e6);
        assertEq(vault.availableLiquidity(), 90_000 * 1e6);
    }

    function testRevert_EmergencyWithdraw_ExceedsAvailable() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        vm.prank(mockMarket1);
        vault.borrow(50_000 * 1e6);

        // 尝试提取 60k（但只有 50k 可用）
        vm.expectRevert("Insufficient available assets");
        vault.emergencyWithdraw(address(0x9999), 60_000 * 1e6);
    }

    // ============ 查询函数测试 ============

    function test_GetMarketBorrowInfo() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        vm.prank(mockMarket1);
        vault.borrow(20_000 * 1e6);

        (uint256 borrowed, uint256 limit, uint256 available) = vault.getMarketBorrowInfo(mockMarket1);

        assertEq(borrowed, 20_000 * 1e6, "Borrowed = 20k");
        assertEq(limit, 50_000 * 1e6, "Limit = 50k (50% of 100k)");
        assertEq(available, 30_000 * 1e6, "Available = 30k");
    }

    function test_GetCurrentYield() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 100_000 * 1e6);
        vault.deposit(100_000 * 1e6, user1);
        vm.stopPrank();

        // 初始收益应为存入金额
        uint256 initialYield = vault.getCurrentYield(user1);
        assertEq(initialYield, 100_000 * 1e6);

        // 产生收益后
        vm.prank(mockMarket1);
        vault.borrow(30_000 * 1e6);

        vm.startPrank(mockMarket1);
        usdc.approve(address(vault), 40_000 * 1e6);
        vault.repay(30_000 * 1e6, 10_000 * 1e6);
        vm.stopPrank();

        uint256 yieldAfter = vault.getCurrentYield(user1);
        assertApproxEqAbs(yieldAfter, 110_000 * 1e6, 10, "Yield increased by ~10k");
    }

    // ============ 多市场借款额度边界测试 ============

    /**
     * @notice 测试21个市场同时借款（模拟真实场景）
     * @dev 验证：1M USDC Vault可以支持21个市场每个借10k
     */
    function test_MultipleMarkets_21MarketsEachBorrow10k() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 创建并授权21个市场地址
        address[] memory markets = new address[](21);
        for (uint256 i = 0; i < 21; i++) {
            markets[i] = address(uint160(0x3000 + i));
            vault.authorizeMarket(markets[i]);
            usdc.mint(markets[i], 20_000 * 1e6); // 每个市场铸造20k用于还款
        }

        // 3. 所有21个市场每个借10k USDC
        for (uint256 i = 0; i < 21; i++) {
            vm.prank(markets[i]);
            vault.borrow(10_000 * 1e6);
        }

        // 4. 验证总借款金额
        assertEq(vault.totalBorrowed(), 210_000 * 1e6, "Total borrowed should be 210k");

        // 5. 验证利用率
        uint256 utilization = vault.utilizationRate();
        // 210k / 1M = 21%
        assertEq(utilization, 2100, "Utilization should be 21% (2100 bps)");

        // 6. 验证可用流动性
        assertEq(vault.availableLiquidity(), 790_000 * 1e6, "Available should be 790k");
    }

    /**
     * @notice 测试接近90%利用率的边界情况
     * @dev 验证：1M Vault最多可借出900k（90%）
     */
    function test_MultipleMarkets_BorrowUpTo90Percent() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 创建9个市场，每个借100k = 900k总计
        address[] memory markets = new address[](9);
        for (uint256 i = 0; i < 9; i++) {
            markets[i] = address(uint160(0x4000 + i));
            vault.authorizeMarket(markets[i]);
        }

        // 3. 前8个市场每个借100k
        for (uint256 i = 0; i < 8; i++) {
            vm.prank(markets[i]);
            vault.borrow(100_000 * 1e6);
        }

        // 4. 第9个市场借100k（总计900k，正好90%）
        vm.prank(markets[8]);
        vault.borrow(100_000 * 1e6);

        // 5. 验证总借款和利用率
        assertEq(vault.totalBorrowed(), 900_000 * 1e6, "Should borrow exactly 900k");
        assertEq(vault.utilizationRate(), 9000, "Should be exactly 90% (9000 bps)");
        assertEq(vault.availableLiquidity(), 100_000 * 1e6, "Should have 100k left");
    }

    /**
     * @notice 测试超过90%利用率限制失败
     * @dev 验证：借款总额超过90%时应该失败
     */
    function testRevert_MultipleMarkets_ExceedsUtilization() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 创建10个市场
        address[] memory markets = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            markets[i] = address(uint160(0x5000 + i));
            vault.authorizeMarket(markets[i]);
        }

        // 3. 前9个市场每个借100k = 900k（正好90%）
        for (uint256 i = 0; i < 9; i++) {
            vm.prank(markets[i]);
            vault.borrow(100_000 * 1e6);
        }

        // 4. 第10个市场尝试借100k应该失败（总计会超过90%）
        vm.prank(markets[9]);
        vm.expectRevert(); // ExceedsUtilizationLimit
        vault.borrow(100_000 * 1e6);
    }

    /**
     * @notice 测试多个市场借款后的可用额度计算
     * @dev 验证：getMarketBorrowInfo在多市场场景下的正确性
     */
    function test_MultipleMarkets_BorrowInfoAfterPartialBorrow() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 授权2个市场
        vault.authorizeMarket(mockMarket2);

        // 3. market1借200k, market2借300k
        vm.prank(mockMarket1);
        vault.borrow(200_000 * 1e6);

        vm.prank(mockMarket2);
        vault.borrow(300_000 * 1e6);

        // 4. 查询market1的借款信息
        (uint256 borrowed1, uint256 limit1, uint256 available1) =
            vault.getMarketBorrowInfo(mockMarket1);

        assertEq(borrowed1, 200_000 * 1e6, "Market1 borrowed 200k");
        assertEq(limit1, 500_000 * 1e6, "Market1 limit should be 50% of 1M = 500k");
        assertEq(available1, 300_000 * 1e6, "Market1 can borrow 300k more (500k limit - 200k borrowed)");

        // 5. 查询market2的借款信息
        (uint256 borrowed2, uint256 limit2, uint256 available2) =
            vault.getMarketBorrowInfo(mockMarket2);

        assertEq(borrowed2, 300_000 * 1e6, "Market2 borrowed 300k");
        assertEq(limit2, 500_000 * 1e6, "Market2 limit should be 50% of 1M = 500k");
        assertEq(available2, 200_000 * 1e6, "Market2 can borrow 200k more (500k limit - 300k borrowed)");
    }

    /**
     * @notice 测试多个小额市场借款的累积效应
     * @dev 验证：21个市场每个借10k，总利用率21%，仍有充足流动性
     */
    function test_MultipleMarkets_SmallBorrowsAccumulation() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 创建21个市场，每个借10k
        for (uint256 i = 0; i < 21; i++) {
            address market = address(uint160(0x6000 + i));
            vault.authorizeMarket(market);
            usdc.mint(market, 15_000 * 1e6);

            vm.prank(market);
            vault.borrow(10_000 * 1e6);
        }

        // 3. 验证累积借款
        assertEq(vault.totalBorrowed(), 210_000 * 1e6, "Total borrowed: 210k");

        // 4. 验证仍有大量可用流动性
        uint256 available = vault.availableLiquidity();
        assertEq(available, 790_000 * 1e6, "Should have 790k available");

        // 5. 验证利用率远低于90%
        uint256 utilization = vault.utilizationRate();
        assertLt(utilization, 9000, "Utilization should be < 90%");
        assertEq(utilization, 2100, "Utilization should be 21%");
    }

    // ============ 单市场50%限制 + 总体90%利用率组合测试 ============

    /**
     * @notice 测试单个市场借满50%限制（500k）
     * @dev 验证：单市场可以借到其最大限制50%
     */
    function test_SingleMarket_BorrowUpTo50Percent() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. market1借500k（正好50%限制）
        vm.prank(mockMarket1);
        vault.borrow(500_000 * 1e6);

        // 3. 验证借款
        assertEq(vault.totalBorrowed(), 500_000 * 1e6, "Should borrow 500k");
        (uint256 borrowed, uint256 limit, uint256 available) = vault.getMarketBorrowInfo(mockMarket1);

        assertEq(borrowed, 500_000 * 1e6, "Market borrowed 500k");
        assertEq(limit, 500_000 * 1e6, "Limit is 50% of 1M = 500k");
        assertEq(available, 0, "No more available for this market (reached limit)");

        // 4. 验证总利用率
        assertEq(vault.utilizationRate(), 5000, "Utilization should be 50%");
    }

    /**
     * @notice 测试单市场达到50%后无法再借
     * @dev 验证：单市场借款超过50%会失败
     */
    function testRevert_SingleMarket_ExceedsSingleMarketLimit() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. market1先借450k
        vm.prank(mockMarket1);
        vault.borrow(450_000 * 1e6);

        // 3. market1尝试再借100k（总计550k，超过500k限制）
        vm.prank(mockMarket1);
        vm.expectRevert(); // ExceedsMarketBorrowLimit
        vault.borrow(100_000 * 1e6);
    }

    /**
     * @notice 测试两个市场各借50%，总计100%（应该失败）
     * @dev 验证：总利用率限制（90%）优先于单市场限制
     */
    function testRevert_TwoMarkets_Each50Percent_ExceedsTotal() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 授权market2
        vault.authorizeMarket(mockMarket2);

        // 3. market1借500k（50%单市场限制）
        vm.prank(mockMarket1);
        vault.borrow(500_000 * 1e6);

        // 4. market2尝试借500k（单市场限制允许，但总计1M会超过90%限制）
        vm.prank(mockMarket2);
        vm.expectRevert(); // ExceedsUtilizationLimit
        vault.borrow(500_000 * 1e6);
    }

    /**
     * @notice 测试达到90%总利用率的最大单市场组合
     * @dev 验证：market1借500k + market2借400k = 900k（正好90%）
     */
    function test_TwoLargeMarkets_ReachExactly90Percent() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 授权market2
        vault.authorizeMarket(mockMarket2);

        // 3. market1借500k（50%单市场限制）
        vm.prank(mockMarket1);
        vault.borrow(500_000 * 1e6);

        // 4. market2借400k（总计900k，正好90%）
        vm.prank(mockMarket2);
        vault.borrow(400_000 * 1e6);

        // 5. 验证总借款和利用率
        assertEq(vault.totalBorrowed(), 900_000 * 1e6, "Total borrowed: 900k");
        assertEq(vault.utilizationRate(), 9000, "Utilization: exactly 90%");

        // 6. 验证各市场借款信息
        (uint256 borrowed1,,) = vault.getMarketBorrowInfo(mockMarket1);
        (uint256 borrowed2,,) = vault.getMarketBorrowInfo(mockMarket2);

        assertEq(borrowed1, 500_000 * 1e6, "Market1: 500k (50% limit)");
        assertEq(borrowed2, 400_000 * 1e6, "Market2: 400k (40%)");
    }

    /**
     * @notice 测试多个市场分别达到接近50%限制
     * @dev 验证：market1借480k + market2借420k，两个都接近50%限制
     */
    function test_TwoMarkets_BothNear50PercentLimit() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 授权market2
        vault.authorizeMarket(mockMarket2);

        // 3. market1借480k（接近50%限制）
        vm.prank(mockMarket1);
        vault.borrow(480_000 * 1e6);

        // 4. market2借420k（总计900k，正好90%）
        vm.prank(mockMarket2);
        vault.borrow(420_000 * 1e6);

        // 5. 验证两个市场都还能借一点
        (, uint256 limit1, uint256 available1) = vault.getMarketBorrowInfo(mockMarket1);
        (, uint256 limit2, uint256 available2) = vault.getMarketBorrowInfo(mockMarket2);

        assertEq(limit1, 500_000 * 1e6, "Market1 limit: 500k");
        assertEq(available1, 20_000 * 1e6, "Market1 can borrow 20k more to reach limit");

        assertEq(limit2, 500_000 * 1e6, "Market2 limit: 500k");
        assertEq(available2, 80_000 * 1e6, "Market2 can borrow 80k more to reach limit");

        // 6. 但总利用率已达90%，实际都不能再借
        assertEq(vault.availableLiquidity(), 100_000 * 1e6, "Only 100k total available");
        assertEq(vault.utilizationRate(), 9000, "Utilization: 90%");
    }

    /**
     * @notice 测试单市场达到50%后其他市场仍可借款
     * @dev 验证：market1满50%后，market2仍可借到40%使总利用率达90%
     */
    function test_OneMarketFull_OtherCanStillBorrow() public {
        // 1. LP存入 1M USDC
        vm.startPrank(user1);
        usdc.approve(address(vault), 1_000_000 * 1e6);
        vault.deposit(1_000_000 * 1e6, user1);
        vm.stopPrank();

        // 2. 授权market2
        vault.authorizeMarket(mockMarket2);

        // 3. market1借满500k
        vm.prank(mockMarket1);
        vault.borrow(500_000 * 1e6);

        // 4. 验证market1已达限制
        (, , uint256 available1) = vault.getMarketBorrowInfo(mockMarket1);
        assertEq(available1, 0, "Market1 reached limit, cannot borrow more");

        // 5. market2仍可借400k
        vm.prank(mockMarket2);
        vault.borrow(400_000 * 1e6);

        (, , uint256 available2) = vault.getMarketBorrowInfo(mockMarket2);
        assertEq(available2, 100_000 * 1e6, "Market2 can still borrow 100k more");

        // 6. 验证总利用率
        assertEq(vault.totalBorrowed(), 900_000 * 1e6, "Total: 900k");
        assertEq(vault.utilizationRate(), 9000, "Utilization: 90%");
    }
}
