// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/liquidity/ERC4626LiquidityProvider.sol";
import "../../src/interfaces/ILiquidityProvider.sol";

/**
 * @title ERC4626LiquidityProviderTest
 * @notice ERC4626LiquidityProvider 单元测试
 * @dev 测试模块化流动性提供者实现和 ILiquidityProvider 接口
 */
contract ERC4626LiquidityProviderTest is BaseTest {
    ERC4626LiquidityProvider public provider;
    ILiquidityProvider public providerInterface;

    // 测试常量
    uint256 constant INITIAL_DEPOSIT = 100_000 * 1e6; // 100,000 USDC
    uint256 constant MARKET_BORROW = 30_000 * 1e6;    // 30,000 USDC

    // 模拟市场地址
    address public mockMarket1;
    address public mockMarket2;

    function setUp() public override {
        super.setUp();

        // 部署 Provider
        provider = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );

        // 获取接口引用
        providerInterface = ILiquidityProvider(address(provider));

        // 创建模拟市场地址
        mockMarket1 = address(0x1111);
        mockMarket2 = address(0x2222);

        // 授权模拟市场
        provider.authorizeMarket(mockMarket1);

        // 给测试账户铸造 USDC
        usdc.mint(user1, 1_000_000 * 1e6); // 1M USDC
        usdc.mint(user2, 1_000_000 * 1e6);
        usdc.mint(mockMarket1, 100_000 * 1e6);
    }

    // ============ ILiquidityProvider 接口测试 ============

    function test_Interface_ProviderType() public view {
        assertEq(providerInterface.providerType(), "ERC4626");
    }

    function test_Interface_Asset() public view {
        assertEq(providerInterface.asset(), address(usdc));
    }

    function test_Interface_IsAuthorizedMarket() public view {
        assertTrue(providerInterface.isAuthorizedMarket(mockMarket1));
        assertFalse(providerInterface.isAuthorizedMarket(mockMarket2));
    }

    function test_Interface_GetAuthorizedMarkets() public view {
        address[] memory markets = providerInterface.getAuthorizedMarkets();
        assertEq(markets.length, 1);
        assertEq(markets[0], mockMarket1);
    }

    // ============ 基本 ERC-4626 功能测试 ============

    function test_Provider_BasicInfo() public view {
        assertEq(provider.name(), "PitchOne LP Token");
        assertEq(provider.symbol(), "pLP");
        assertEq(address(provider.asset()), address(usdc));
    }

    function test_Provider_Deposit() public {
        vm.startPrank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);

        uint256 shares = provider.deposit(INITIAL_DEPOSIT, user1);

        assertEq(provider.balanceOf(user1), shares);
        assertEq(provider.totalAssets(), INITIAL_DEPOSIT);
        assertEq(usdc.balanceOf(address(provider)), INITIAL_DEPOSIT);
        vm.stopPrank();
    }

    function test_Provider_Withdraw() public {
        // 先存款
        vm.startPrank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        provider.deposit(INITIAL_DEPOSIT, user1);

        // 提款
        uint256 withdrawAmount = 50_000 * 1e6;
        uint256 balanceBefore = usdc.balanceOf(user1);
        provider.withdraw(withdrawAmount, user1, user1);

        assertEq(usdc.balanceOf(user1), balanceBefore + withdrawAmount);
        assertEq(provider.totalAssets(), INITIAL_DEPOSIT - withdrawAmount);
        vm.stopPrank();
    }

    // ============ 市场授权测试 ============

    function test_Provider_AuthorizeMarket() public {
        provider.authorizeMarket(mockMarket2);

        assertTrue(provider.isAuthorizedMarket(mockMarket2));

        address[] memory markets = provider.getAuthorizedMarkets();
        assertEq(markets.length, 2);
    }

    function test_Provider_RevokeMarket() public {
        provider.revokeMarket(mockMarket1);

        assertFalse(provider.isAuthorizedMarket(mockMarket1));

        address[] memory markets = provider.getAuthorizedMarkets();
        assertEq(markets.length, 0);
    }

    function testRevert_Provider_RevokeMarket_WithDebt() public {
        // 先存款
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        // 市场借款
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        // 尝试撤销授权（应该失败）
        vm.expectRevert("Market has outstanding debt");
        provider.revokeMarket(mockMarket1);
    }

    function testRevert_Provider_AuthorizeMarket_Duplicate() public {
        vm.expectRevert("Market already authorized");
        provider.authorizeMarket(mockMarket1);
    }

    // ============ 借贷功能测试 ============

    function test_Provider_Borrow() public {
        // 先存款提供流动性
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        // 市场借款
        uint256 balanceBefore = usdc.balanceOf(mockMarket1);

        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        assertEq(usdc.balanceOf(mockMarket1), balanceBefore + MARKET_BORROW);
        assertEq(provider.borrowed(mockMarket1), MARKET_BORROW);
        assertEq(provider.totalBorrowed(), MARKET_BORROW);
    }

    function testRevert_Provider_Borrow_Unauthorized() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        vm.prank(mockMarket2); // 未授权的市场
        vm.expectRevert(abi.encodeWithSelector(ILiquidityProvider.UnauthorizedMarket.selector, mockMarket2));
        provider.borrow(MARKET_BORROW);
    }

    function testRevert_Provider_Borrow_ExceedsUtilization() public {
        // 存入少量资金
        uint256 smallDeposit = 10_000 * 1e6;
        vm.prank(user1);
        usdc.approve(address(provider), smallDeposit);
        vm.prank(user1);
        provider.deposit(smallDeposit, user1);

        // 尝试借出超过 90% 利用率
        uint256 excessiveAmount = 9_500 * 1e6; // 95%

        vm.prank(mockMarket1);
        vm.expectRevert();
        provider.borrow(excessiveAmount);
    }

    function testRevert_Provider_Borrow_ExceedsMarketLimit() public {
        // 存入大量资金
        uint256 largeDeposit = 200_000 * 1e6;
        vm.prank(user1);
        usdc.approve(address(provider), largeDeposit);
        vm.prank(user1);
        provider.deposit(largeDeposit, user1);

        // 尝试借出超过单市场 50% 限制
        uint256 excessiveAmount = 110_000 * 1e6; // 55%

        vm.prank(mockMarket1);
        vm.expectRevert();
        provider.borrow(excessiveAmount);
    }

    // ============ 还款功能测试 ============

    function test_Provider_Repay_PrincipalOnly() public {
        // Setup: 存款和借款
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        // 市场归还本金
        vm.startPrank(mockMarket1);
        usdc.approve(address(provider), MARKET_BORROW);
        provider.repay(MARKET_BORROW, 0);
        vm.stopPrank();

        assertEq(provider.borrowed(mockMarket1), 0);
        assertEq(provider.totalBorrowed(), 0);
        assertEq(usdc.balanceOf(address(provider)), INITIAL_DEPOSIT);
    }

    function test_Provider_Repay_WithRevenue() public {
        // Setup: 存款和借款
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        uint256 sharesBefore = provider.deposit(INITIAL_DEPOSIT, user1);

        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        // 市场归还本金 + 收益
        uint256 revenue = 1_000 * 1e6; // 1,000 USDC 收益
        uint256 totalRepayment = MARKET_BORROW + revenue;

        // 给 mockMarket1 铸造 revenue (因为借出的 MARKET_BORROW 已经在 mockMarket1)
        usdc.mint(mockMarket1, revenue);

        vm.startPrank(mockMarket1);
        usdc.approve(address(provider), totalRepayment);
        provider.repay(MARKET_BORROW, revenue);
        vm.stopPrank();

        assertEq(provider.totalRevenueAccumulated(), revenue);
        assertEq(provider.totalAssets(), INITIAL_DEPOSIT + revenue);

        // 验证 LP 收益：shares 价值应该增加
        // 注意：由于 ERC-4626 整数除法的舍入,允许 ±1 误差
        uint256 lpAssets = provider.convertToAssets(sharesBefore);
        assertApproxEqAbs(lpAssets, INITIAL_DEPOSIT + revenue, 1);
    }

    function testRevert_Provider_Repay_Unauthorized() public {
        vm.prank(mockMarket2); // 未授权的市场
        vm.expectRevert(abi.encodeWithSelector(ILiquidityProvider.UnauthorizedMarket.selector, mockMarket2));
        provider.repay(1000, 0);
    }

    function testRevert_Provider_Repay_InsufficientBorrowBalance() public {
        vm.prank(mockMarket1);
        vm.expectRevert();
        provider.repay(1000, 0); // 未借款就还款
    }

    // ============ 查询接口测试 ============

    function test_Provider_AvailableLiquidity() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        assertEq(provider.availableLiquidity(), INITIAL_DEPOSIT);

        // 借款后可用流动性减少
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        assertEq(provider.availableLiquidity(), INITIAL_DEPOSIT - MARKET_BORROW);
    }

    function test_Provider_TotalLiquidity() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        assertEq(provider.totalLiquidity(), INITIAL_DEPOSIT);

        // 借款后总流动性不变
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        assertEq(provider.totalLiquidity(), INITIAL_DEPOSIT);
    }

    function test_Provider_UtilizationRate() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        assertEq(provider.utilizationRate(), 0);

        // 借款后利用率应该是 30%
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        uint256 expectedRate = (MARKET_BORROW * 10000) / INITIAL_DEPOSIT;
        assertEq(provider.utilizationRate(), expectedRate);
    }

    function test_Provider_GetMarketBorrowInfo() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        (uint256 borrowed, uint256 limit, uint256 available) = provider.getMarketBorrowInfo(mockMarket1);

        assertEq(borrowed, 0);
        assertEq(limit, 50_000 * 1e6); // 50% of 100,000
        assertEq(available, 50_000 * 1e6);

        // 借款后
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        (borrowed, limit, available) = provider.getMarketBorrowInfo(mockMarket1);

        assertEq(borrowed, MARKET_BORROW);
        assertEq(limit, 50_000 * 1e6);
        assertEq(available, 20_000 * 1e6); // 50,000 - 30,000
    }

    // ============ 暂停机制测试 ============

    function test_Provider_Pause() public {
        provider.pause();

        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);

        vm.prank(user1);
        vm.expectRevert();
        provider.deposit(INITIAL_DEPOSIT, user1);
    }

    function test_Provider_Unpause() public {
        provider.pause();
        provider.unpause();

        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);

        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        assertEq(provider.totalAssets(), INITIAL_DEPOSIT);
    }

    // ============ 所有权测试 ============

    function testRevert_Provider_OnlyOwner_AuthorizeMarket() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.authorizeMarket(mockMarket2);
    }

    function testRevert_Provider_OnlyOwner_RevokeMarket() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.revokeMarket(mockMarket1);
    }

    function testRevert_Provider_OnlyOwner_Pause() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.pause();
    }

    // ============ 边界条件测试 ============

    function test_Provider_MaxBorrow_AtLimit() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        // 借款刚好达到单市场限制（50%）
        uint256 maxBorrow = 50_000 * 1e6;

        vm.prank(mockMarket1);
        provider.borrow(maxBorrow);

        assertEq(provider.utilizationRate(), 5000); // 50%
    }

    function test_Provider_MultipleMarkets_Borrowing() public {
        // 授权第二个市场
        provider.authorizeMarket(mockMarket2);

        // 存入大量流动性
        uint256 largeDeposit = 200_000 * 1e6;
        vm.prank(user1);
        usdc.approve(address(provider), largeDeposit);
        vm.prank(user1);
        provider.deposit(largeDeposit, user1);

        // 两个市场分别借款
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        vm.prank(mockMarket2);
        provider.borrow(MARKET_BORROW);

        assertEq(provider.totalBorrowed(), MARKET_BORROW * 2);
        assertEq(provider.borrowed(mockMarket1), MARKET_BORROW);
        assertEq(provider.borrowed(mockMarket2), MARKET_BORROW);
    }

    // ============ ERC-4626 扩展功能测试 ============

    function test_Provider_Mint() public {
        vm.startPrank(user1);
        uint256 depositAmount = 50_000 * 1e6; // 50,000 USDC
        usdc.approve(address(provider), depositAmount);

        uint256 shares = provider.previewDeposit(depositAmount); // 计算对应的 shares
        uint256 assets = provider.mint(shares, user1);

        assertEq(provider.balanceOf(user1), shares);
        assertEq(assets, depositAmount);
        vm.stopPrank();
    }

    function test_Provider_Redeem() public {
        vm.startPrank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);

        uint256 shares = provider.deposit(INITIAL_DEPOSIT, user1);
        provider.redeem(shares / 2, user1, user1);

        assertEq(provider.balanceOf(user1), shares / 2);
        vm.stopPrank();
    }

    function test_Provider_MaxWithdraw_WithBorrowing() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        // 借款后，最大提款应该受限于可用流动性
        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        uint256 maxWithdraw = provider.maxWithdraw(user1);
        assertEq(maxWithdraw, INITIAL_DEPOSIT - MARKET_BORROW);
    }

    // ============ 事件测试 ============

    function test_Provider_Events_LiquidityBorrowed() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        vm.expectEmit(true, false, false, true);
        emit ILiquidityProvider.LiquidityBorrowed(mockMarket1, MARKET_BORROW, block.timestamp);

        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);
    }

    function test_Provider_Events_LiquidityRepaid() public {
        vm.prank(user1);
        usdc.approve(address(provider), INITIAL_DEPOSIT);
        vm.prank(user1);
        provider.deposit(INITIAL_DEPOSIT, user1);

        vm.prank(mockMarket1);
        provider.borrow(MARKET_BORROW);

        uint256 revenue = 1_000 * 1e6;

        // 给 mockMarket1 铸造 revenue
        usdc.mint(mockMarket1, revenue);

        vm.startPrank(mockMarket1);
        usdc.approve(address(provider), MARKET_BORROW + revenue);

        vm.expectEmit(true, false, false, true);
        emit ILiquidityProvider.LiquidityRepaid(mockMarket1, MARKET_BORROW, revenue, block.timestamp);

        provider.repay(MARKET_BORROW, revenue);
        vm.stopPrank();
    }

    function test_Provider_Events_MarketAuthorization() public {
        vm.expectEmit(true, false, false, true);
        emit ILiquidityProvider.MarketAuthorizationChanged(mockMarket2, true);

        provider.authorizeMarket(mockMarket2);
    }
}
