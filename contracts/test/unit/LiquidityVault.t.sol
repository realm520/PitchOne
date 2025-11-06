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
}
