// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../mocks/MockERC20.sol";

/**
 * @title ParimutuelLiquidityProviderTest
 * @notice 彩池模式流动性提供者测试
 */
contract ParimutuelLiquidityProviderTest is Test {
    ParimutuelLiquidityProvider public provider;
    MockERC20 public usdc;

    address public owner = makeAddr("owner");
    address public market1 = makeAddr("market1");
    address public market2 = makeAddr("market2");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 constant INITIAL_POOL = 1_000_000 * 1e6; // 1M USDC

    event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp);
    event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp);
    event MarketAuthorizationChanged(address indexed market, bool authorized);
    event PoolContribution(address indexed contributor, uint256 amount, uint256 timestamp);
    event RevenueDistributed(uint256 amount, uint256 timestamp);

    function setUp() public {
        // 部署 USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // 部署 Provider
        vm.prank(owner);
        provider = new ParimutuelLiquidityProvider(IERC20(address(usdc)));

        // 初始化彩池
        usdc.mint(owner, INITIAL_POOL);
        vm.startPrank(owner);
        usdc.approve(address(provider), INITIAL_POOL);
        provider.contributeToPool(INITIAL_POOL);
        vm.stopPrank();
    }

    // ============ 基础测试 ============

    function test_Constructor() public view {
        assertEq(provider.asset(), address(usdc));
        assertEq(provider.providerType(), "Parimutuel");
        assertEq(provider.totalLiquidity(), INITIAL_POOL);
        assertEq(provider.availableLiquidity(), INITIAL_POOL);
    }

    function test_ContributeToPool() public {
        uint256 amount = 100_000 * 1e6;
        usdc.mint(user1, amount);

        vm.startPrank(user1);
        usdc.approve(address(provider), amount);

        vm.expectEmit(true, false, false, true);
        emit PoolContribution(user1, amount, block.timestamp);

        provider.contributeToPool(amount);
        vm.stopPrank();

        assertEq(provider.totalLiquidity(), INITIAL_POOL + amount);
        assertEq(provider.poolContributions(user1), amount);
    }

    function test_ContributeToPool_Revert_ZeroAmount() public {
        vm.expectRevert("Amount must be greater than 0");
        provider.contributeToPool(0);
    }

    // ============ 市场授权测试 ============

    function test_AuthorizeMarket() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit MarketAuthorizationChanged(market1, true);

        provider.authorizeMarket(market1);

        assertTrue(provider.isAuthorizedMarket(market1));

        address[] memory markets = provider.getAuthorizedMarkets();
        assertEq(markets.length, 1);
        assertEq(markets[0], market1);
    }

    function test_AuthorizeMarket_Revert_NonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.authorizeMarket(market1);
    }

    function test_AuthorizeMarket_Revert_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid market address");
        provider.authorizeMarket(address(0));
    }

    function test_AuthorizeMarket_Revert_AlreadyAuthorized() public {
        vm.startPrank(owner);
        provider.authorizeMarket(market1);

        vm.expectRevert("Market already authorized");
        provider.authorizeMarket(market1);
        vm.stopPrank();
    }

    function test_RevokeMarket() public {
        vm.startPrank(owner);
        provider.authorizeMarket(market1);

        vm.expectEmit(true, false, false, true);
        emit MarketAuthorizationChanged(market1, false);

        provider.revokeMarket(market1);
        vm.stopPrank();

        assertFalse(provider.isAuthorizedMarket(market1));
        assertEq(provider.getAuthorizedMarkets().length, 0);
    }

    function test_RevokeMarket_Revert_NotAuthorized() public {
        vm.prank(owner);
        vm.expectRevert("Market not authorized");
        provider.revokeMarket(market1);
    }

    function test_RevokeMarket_Revert_HasOutstandingDebt() public {
        vm.startPrank(owner);
        provider.authorizeMarket(market1);
        vm.stopPrank();

        // 市场借款
        usdc.mint(market1, 0); // 确保 market1 有足够的 gas
        vm.prank(market1);
        provider.borrow(10_000 * 1e6);

        // 尝试撤销授权
        vm.prank(owner);
        vm.expectRevert("Market has outstanding debt");
        provider.revokeMarket(market1);
    }

    // ============ 借款/还款测试 ============

    function test_Borrow() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        uint256 borrowAmount = 50_000 * 1e6;
        uint256 poolBefore = provider.totalLiquidity();

        vm.expectEmit(true, false, false, true);
        emit LiquidityBorrowed(market1, borrowAmount, block.timestamp);

        vm.prank(market1);
        provider.borrow(borrowAmount);

        assertEq(provider.borrowed(market1), borrowAmount);
        assertEq(provider.totalBorrowed(), borrowAmount);
        assertEq(provider.availableLiquidity(), poolBefore - borrowAmount);
        assertEq(usdc.balanceOf(market1), borrowAmount);
    }

    function test_Borrow_Revert_UnauthorizedMarket() public {
        vm.prank(market1);
        vm.expectRevert();
        provider.borrow(10_000 * 1e6);
    }

    function test_Borrow_Revert_InsufficientLiquidity() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        uint256 excessiveAmount = INITIAL_POOL + 1;

        vm.prank(market1);
        vm.expectRevert();
        provider.borrow(excessiveAmount);
    }

    function test_Repay() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        uint256 borrowAmount = 50_000 * 1e6;
        uint256 revenue = 1_000 * 1e6;

        // 借款
        vm.prank(market1);
        provider.borrow(borrowAmount);

        // 准备还款
        usdc.mint(market1, revenue);
        vm.startPrank(market1);
        usdc.approve(address(provider), borrowAmount + revenue);

        vm.expectEmit(true, false, false, true);
        emit LiquidityRepaid(market1, borrowAmount, revenue, block.timestamp);

        provider.repay(borrowAmount, revenue);
        vm.stopPrank();

        assertEq(provider.borrowed(market1), 0);
        assertEq(provider.totalBorrowed(), 0);
        assertEq(provider.totalRevenueAccumulated(), revenue);
        assertEq(provider.totalLiquidity(), INITIAL_POOL + revenue);
    }

    function test_Repay_Revert_UnauthorizedMarket() public {
        vm.prank(market1);
        vm.expectRevert();
        provider.repay(10_000 * 1e6, 100 * 1e6);
    }

    function test_Repay_Revert_InsufficientBorrowBalance() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        vm.prank(market1);
        provider.borrow(10_000 * 1e6);

        vm.prank(market1);
        vm.expectRevert();
        provider.repay(20_000 * 1e6, 0);
    }

    // ============ 利用率测试 ============

    function test_UtilizationRate() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        // 初始利用率为 0
        assertEq(provider.utilizationRate(), 0);

        // 借款 50%
        uint256 borrowAmount = INITIAL_POOL / 2;
        vm.prank(market1);
        provider.borrow(borrowAmount);

        // 利用率应为 50%
        assertEq(provider.utilizationRate(), 5000); // 50.00%

        // 借款 25%
        uint256 borrowAmount2 = INITIAL_POOL / 4;
        vm.prank(owner);
        provider.authorizeMarket(market2);

        vm.prank(market2);
        provider.borrow(borrowAmount2);

        // 利用率应为 75%
        assertEq(provider.utilizationRate(), 7500); // 75.00%
    }

    function test_UtilizationRate_ZeroLiquidity() public {
        // 创建空彩池
        vm.prank(owner);
        ParimutuelLiquidityProvider emptyProvider = new ParimutuelLiquidityProvider(IERC20(address(usdc)));

        assertEq(emptyProvider.utilizationRate(), 0);
    }

    // ============ 查询测试 ============

    function test_GetMarketBorrowInfo() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(market1);
        provider.borrow(borrowAmount);

        (uint256 borrowed, uint256 limit, uint256 available) = provider.getMarketBorrowInfo(market1);

        assertEq(borrowed, borrowAmount);
        assertEq(limit, INITIAL_POOL); // Parimutuel 模式下限制为总池额
        assertEq(available, INITIAL_POOL - borrowAmount);
    }

    // ============ 收益分配测试 ============

    function test_DistributeRevenue() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        // 市场借款并还款(带收益)
        uint256 borrowAmount = 50_000 * 1e6;
        uint256 revenue = 1_000 * 1e6;

        vm.prank(market1);
        provider.borrow(borrowAmount);

        usdc.mint(market1, revenue);
        vm.startPrank(market1);
        usdc.approve(address(provider), borrowAmount + revenue);
        provider.repay(borrowAmount, revenue);
        vm.stopPrank();

        // 检查累计收益
        assertEq(provider.totalRevenueAccumulated(), revenue);

        // 分配收益
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RevenueDistributed(revenue, block.timestamp);

        provider.distributeRevenue();

        assertEq(provider.totalRevenueAccumulated(), 0);
        assertEq(provider.lastRevenueDistribution(), block.timestamp);
    }

    function test_DistributeRevenue_Revert_NoRevenue() public {
        vm.prank(owner);
        vm.expectRevert("No revenue to distribute");
        provider.distributeRevenue();
    }

    function test_DistributeRevenue_Revert_NonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        provider.distributeRevenue();
    }

    // ============ 多市场测试 ============

    function test_MultipleMarkets_BorrowAndRepay() public {
        vm.startPrank(owner);
        provider.authorizeMarket(market1);
        provider.authorizeMarket(market2);
        vm.stopPrank();

        uint256 borrow1 = 30_000 * 1e6;
        uint256 borrow2 = 20_000 * 1e6;

        // 市场1 借款
        vm.prank(market1);
        provider.borrow(borrow1);

        // 市场2 借款
        vm.prank(market2);
        provider.borrow(borrow2);

        assertEq(provider.totalBorrowed(), borrow1 + borrow2);
        assertEq(provider.borrowed(market1), borrow1);
        assertEq(provider.borrowed(market2), borrow2);

        // 市场1 还款
        vm.startPrank(market1);
        usdc.approve(address(provider), borrow1);
        provider.repay(borrow1, 0);
        vm.stopPrank();

        assertEq(provider.borrowed(market1), 0);
        assertEq(provider.totalBorrowed(), borrow2);

        // 市场2 还款
        vm.startPrank(market2);
        usdc.approve(address(provider), borrow2);
        provider.repay(borrow2, 0);
        vm.stopPrank();

        assertEq(provider.totalBorrowed(), 0);
    }

    // ============ 边界测试 ============

    function test_Borrow_MaxLiquidity() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        // 借出所有流动性
        vm.prank(market1);
        provider.borrow(INITIAL_POOL);

        assertEq(provider.availableLiquidity(), 0);
        assertEq(provider.utilizationRate(), 10000); // 100%
    }

    function test_PartialRepay() public {
        vm.prank(owner);
        provider.authorizeMarket(market1);

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(market1);
        provider.borrow(borrowAmount);

        // 部分还款
        uint256 partialRepay = 50_000 * 1e6;
        vm.startPrank(market1);
        usdc.approve(address(provider), partialRepay);
        provider.repay(partialRepay, 0);
        vm.stopPrank();

        assertEq(provider.borrowed(market1), borrowAmount - partialRepay);
    }

    function test_GetAuthorizedMarkets() public {
        vm.startPrank(owner);
        provider.authorizeMarket(market1);
        provider.authorizeMarket(market2);
        vm.stopPrank();

        address[] memory markets = provider.getAuthorizedMarkets();
        assertEq(markets.length, 2);
        assertEq(markets[0], market1);
        assertEq(markets[1], market2);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_Borrow(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_POOL);

        vm.prank(owner);
        provider.authorizeMarket(market1);

        vm.prank(market1);
        provider.borrow(amount);

        assertEq(provider.borrowed(market1), amount);
        assertEq(provider.availableLiquidity(), INITIAL_POOL - amount);
    }

    function testFuzz_ContributeToPool(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1_000_000_000 * 1e6);

        usdc.mint(user1, amount);

        vm.startPrank(user1);
        usdc.approve(address(provider), amount);
        provider.contributeToPool(amount);
        vm.stopPrank();

        assertEq(provider.poolContributions(user1), amount);
    }
}
