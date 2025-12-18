// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/liquidity/LiquidityVault_V3.sol";
import "../../src/core/Market_V3.sol";
import "../../src/core/MarketFactory_V3.sol";
import "../../src/pricing/CPMMStrategy.sol";
import "../../src/mappers/WDL_Mapper.sol";
import "../../src/interfaces/IMarket_V3.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 10_000_000 * 1e6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract LiquidityVaultV3Test is Test {
    LiquidityVault_V3 public vault;
    MockUSDC public usdc;
    CPMMStrategy public cpmm;
    WDL_Mapper public mapper;
    MarketFactory_V3 public factory;
    Market_V3 public marketImpl;

    address public admin = address(1);
    address public lp1 = address(2);
    address public lp2 = address(3);
    address public user1 = address(4);
    address public keeper = address(5);
    address public oracle = address(6);

    uint256 constant INITIAL_LP_DEPOSIT = 1_000_000 * 1e6; // 1M USDC
    uint256 constant INITIAL_LIQUIDITY = 100_000 * 1e6; // 100k USDC per market

    function setUp() public {
        vm.startPrank(admin);

        // Deploy tokens
        usdc = new MockUSDC();

        // Deploy vault
        vault = new LiquidityVault_V3(
            IERC20(address(usdc)),
            "PitchOne LP Token V3",
            "pLP-V3"
        );

        // Deploy pricing strategy and mapper
        cpmm = new CPMMStrategy();
        mapper = new WDL_Mapper();

        // Deploy Factory（先用临时地址）
        factory = new MarketFactory_V3(
            address(1), // 临时占位
            address(usdc),
            admin
        );

        // Deploy market implementation（绑定 Factory 地址）
        marketImpl = new Market_V3(address(factory));

        // 更新 Factory 的实现地址
        factory.setImplementation(address(marketImpl));

        // Setup LP accounts
        usdc.transfer(lp1, INITIAL_LP_DEPOSIT);
        usdc.transfer(lp2, INITIAL_LP_DEPOSIT);
        usdc.transfer(user1, 100_000 * 1e6);

        vm.stopPrank();
    }

    // ============ LP Deposit/Withdraw Tests ============

    function test_LP_Deposit() public {
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);

        uint256 shares = vault.deposit(INITIAL_LP_DEPOSIT, lp1);

        assertEq(vault.balanceOf(lp1), shares);
        assertEq(vault.totalAssets(), INITIAL_LP_DEPOSIT);
        vm.stopPrank();
    }

    function test_LP_Withdraw() public {
        // First deposit
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);

        // Then withdraw
        uint256 shares = vault.balanceOf(lp1);
        vault.redeem(shares, lp1, lp1);

        assertEq(vault.balanceOf(lp1), 0);
        assertEq(usdc.balanceOf(lp1), INITIAL_LP_DEPOSIT);
        vm.stopPrank();
    }

    function test_Multiple_LP_Deposits() public {
        // LP1 deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), 500_000 * 1e6);
        uint256 shares1 = vault.deposit(500_000 * 1e6, lp1);
        vm.stopPrank();

        // LP2 deposits
        vm.startPrank(lp2);
        usdc.approve(address(vault), 500_000 * 1e6);
        uint256 shares2 = vault.deposit(500_000 * 1e6, lp2);
        vm.stopPrank();

        assertEq(vault.totalAssets(), 1_000_000 * 1e6);
        assertEq(shares1, shares2); // Same deposit = same shares
    }

    // ============ Market Authorization Tests ============

    function test_AuthorizeMarket() public {
        address mockMarket = address(100);

        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500); // 5% max liability

        ILiquidityVault_V3.BorrowInfo memory info = vault.getBorrowInfo(mockMarket);
        assertTrue(info.active);
        assertEq(info.maxLiabilityBps, 500);
    }

    function test_RevokeMarket() public {
        address mockMarket = address(100);

        vm.startPrank(admin);
        vault.authorizeMarket(mockMarket, 500);
        vault.revokeMarket(mockMarket);
        vm.stopPrank();

        ILiquidityVault_V3.BorrowInfo memory info = vault.getBorrowInfo(mockMarket);
        assertFalse(info.active);
    }

    function test_Revert_RevokeMarket_WithDebt() public {
        // Setup: LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Create and authorize a mock market
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        // Borrow as market
        vm.prank(mockMarket);
        vault.borrow(100_000 * 1e6);

        // Try to revoke - should fail
        vm.prank(admin);
        vm.expectRevert(ILiquidityVault_V3.MarketHasOutstandingDebt.selector);
        vault.revokeMarket(mockMarket);
    }

    // ============ Borrow Tests ============

    function test_Market_Borrow() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize market
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        // Borrow
        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        assertEq(vault.totalBorrowed(), borrowAmount);
        assertEq(usdc.balanceOf(mockMarket), borrowAmount);

        ILiquidityVault_V3.BorrowInfo memory info = vault.getBorrowInfo(mockMarket);
        assertEq(info.principal, borrowAmount);
    }

    function test_Revert_Unauthorized_Borrow() public {
        address unauthorizedMarket = address(999);

        vm.prank(unauthorizedMarket);
        vm.expectRevert();
        vault.borrow(100_000 * 1e6);
    }

    function test_Revert_ExceedsUtilization() public {
        // LP deposits 1M
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize market
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        // Try to borrow 95% (exceeds 90% utilization limit)
        uint256 exceedingAmount = 950_000 * 1e6;
        vm.prank(mockMarket);
        vm.expectRevert();
        vault.borrow(exceedingAmount);
    }

    // ============ Settle Tests ============

    function test_Settle_WithProfit() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize and borrow
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        // Simulate profit: market returns principal + 10k profit
        uint256 profit = 10_000 * 1e6;
        vm.startPrank(admin);
        usdc.mint(mockMarket, profit);
        vm.stopPrank();

        vm.startPrank(mockMarket);
        usdc.approve(address(vault), borrowAmount + profit);
        vault.settle(borrowAmount, int256(profit));
        vm.stopPrank();

        // Check state
        assertEq(vault.totalBorrowed(), 0);
        assertTrue(vault.totalAssets() > INITIAL_LP_DEPOSIT); // Has profit (minus reserve)
    }

    function test_Settle_WithLoss() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize and borrow
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500); // 5% max loss

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        // Simulate loss: market returns principal - 5k loss
        uint256 loss = 5_000 * 1e6; // 5% loss (within limit)
        uint256 returnAmount = borrowAmount - loss;

        vm.startPrank(mockMarket);
        usdc.approve(address(vault), returnAmount);
        vault.settle(borrowAmount, -int256(loss));
        vm.stopPrank();

        // Check state
        assertEq(vault.totalBorrowed(), 0);
        assertEq(vault.totalLossAccumulated(), loss);
    }

    function test_Revert_Settle_ExceedsLiability() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize and borrow
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500); // 5% max loss

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        // Try to settle with 10% loss (exceeds 5% limit)
        uint256 excessiveLoss = 10_000 * 1e6;
        uint256 returnAmount = borrowAmount - excessiveLoss;

        vm.startPrank(mockMarket);
        usdc.approve(address(vault), returnAmount);
        vm.expectRevert();
        vault.settle(borrowAmount, -int256(excessiveLoss));
        vm.stopPrank();
    }

    // ============ Return Principal Tests ============

    function test_ReturnPrincipal() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize and borrow
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        // Return principal (market cancelled scenario)
        vm.startPrank(mockMarket);
        usdc.approve(address(vault), borrowAmount);
        vault.returnPrincipal(borrowAmount);
        vm.stopPrank();

        assertEq(vault.totalBorrowed(), 0);
        assertEq(vault.totalAssets(), INITIAL_LP_DEPOSIT);
    }

    // ============ Reserve Fund Tests ============

    function test_ReserveFund_FromProfit() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize and borrow
        address mockMarket = address(100);
        vm.prank(admin);
        vault.authorizeMarket(mockMarket, 500);

        uint256 borrowAmount = 100_000 * 1e6;
        vm.prank(mockMarket);
        vault.borrow(borrowAmount);

        // Settle with profit
        uint256 profit = 10_000 * 1e6;
        vm.prank(admin);
        usdc.mint(mockMarket, profit);

        vm.startPrank(mockMarket);
        usdc.approve(address(vault), borrowAmount + profit);
        vault.settle(borrowAmount, int256(profit));
        vm.stopPrank();

        // 10% of profit goes to reserve (default ratio)
        uint256 expectedReserve = profit * 1000 / 10000; // 10%
        assertEq(vault.reserveFund(), expectedReserve);
    }

    function test_DepositReserve() public {
        uint256 reserveAmount = 50_000 * 1e6;

        vm.startPrank(admin);
        usdc.approve(address(vault), reserveAmount);
        vault.depositReserve(reserveAmount);
        vm.stopPrank();

        assertEq(vault.reserveFund(), reserveAmount);
    }

    // ============ Utilization Rate Tests ============

    function test_UtilizationRate() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        // Authorize multiple markets and borrow to reach 50% utilization
        // Each market limited to 20% = 200k, so need 3 markets to reach 50%
        address mockMarket1 = address(100);
        address mockMarket2 = address(101);
        address mockMarket3 = address(102);

        vm.startPrank(admin);
        vault.authorizeMarket(mockMarket1, 500);
        vault.authorizeMarket(mockMarket2, 500);
        vault.authorizeMarket(mockMarket3, 500);
        vm.stopPrank();

        // Borrow 200k from each market (total 500k = 50%)
        vm.prank(mockMarket1);
        vault.borrow(200_000 * 1e6);

        vm.prank(mockMarket2);
        vault.borrow(200_000 * 1e6);

        vm.prank(mockMarket3);
        vault.borrow(100_000 * 1e6);

        // Utilization should be 50% = 5000 bps
        assertEq(vault.utilizationRate(), 5000);
    }

    // ============ Query Tests ============

    function test_GetVaultStats() public {
        // LP deposits
        vm.startPrank(lp1);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lp1);
        vm.stopPrank();

        (
            uint256 totalAssets,
            uint256 totalBorrowed,
            uint256 availableLiquidity,
            uint256 reserveFund,
            uint256 totalProfit,
            uint256 totalLoss
        ) = vault.getVaultStats();

        assertEq(totalAssets, INITIAL_LP_DEPOSIT);
        assertEq(totalBorrowed, 0);
        assertGt(availableLiquidity, 0);
        assertEq(reserveFund, 0);
        assertEq(totalProfit, 0);
        assertEq(totalLoss, 0);
    }

    function test_GetAuthorizedMarkets() public {
        address market1 = address(100);
        address market2 = address(101);

        vm.startPrank(admin);
        vault.authorizeMarket(market1, 500);
        vault.authorizeMarket(market2, 500);
        vm.stopPrank();

        address[] memory markets = vault.getAuthorizedMarkets();
        assertEq(markets.length, 2);
        assertEq(markets[0], market1);
        assertEq(markets[1], market2);
    }
}
