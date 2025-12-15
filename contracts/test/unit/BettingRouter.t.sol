// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/core/BettingRouter.sol";
import "../../src/core/MarketFactory_v3.sol";
import "../../src/templates/WDL_Template_V2.sol";
import "../../src/liquidity/LiquidityVault.sol";

/**
 * @title BettingRouterTest
 * @notice BettingRouter 单元测试套件
 * @dev 测试统一投注入口功能：单笔下注、批量下注、权限验证等
 */
contract BettingRouterTest is BaseTest {
    BettingRouter public router;
    MarketFactory_v3 public factory;
    WDL_Template_V2 public market1;
    WDL_Template_V2 public market2;
    LiquidityVault public vault;
    WDL_Template_V2 public wdlImpl;

    // 测试常量
    uint256 constant INITIAL_VAULT_DEPOSIT = 500_000 * 1e6;
    uint256 constant BET_AMOUNT = 100 * 1e6; // 100 USDC

    function setUp() public override {
        super.setUp();

        // 部署 Vault
        vault = new LiquidityVault(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );

        // 部署模板实现
        wdlImpl = new WDL_Template_V2();

        // 部署 Factory
        factory = new MarketFactory_v3();
        bytes32 templateId = factory.registerTemplate(
            "WDL",       // name
            "1.0.0",     // version
            address(wdlImpl)
        );

        // 部署 Router
        router = new BettingRouter(address(usdc), address(factory));

        // 创建测试市场 1
        bytes memory initData1 = abi.encodeWithSelector(
            WDL_Template_V2.initialize.selector,
            "MATCH_001",
            "Team A",
            "Team B",
            block.timestamp + 7 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "https://metadata.com/{id}",
            VIRTUAL_RESERVE_INIT
        );
        market1 = WDL_Template_V2(factory.createMarket(templateId, initData1));

        // 创建测试市场 2
        bytes memory initData2 = abi.encodeWithSelector(
            WDL_Template_V2.initialize.selector,
            "MATCH_002",
            "Team C",
            "Team D",
            block.timestamp + 7 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "https://metadata.com/{id}",
            VIRTUAL_RESERVE_INIT
        );
        market2 = WDL_Template_V2(factory.createMarket(templateId, initData2));

        // 授权市场使用 Vault
        vault.authorizeMarket(address(market1));
        vault.authorizeMarket(address(market2));

        // 转移市场所有权给测试合约（Factory 创建时 owner 是 Factory）
        factory.transferMarketOwnership(address(market1), address(this));
        factory.transferMarketOwnership(address(market2), address(this));

        // 设置 Router 为市场的受信任路由
        market1.setTrustedRouter(address(router));
        market2.setTrustedRouter(address(router));

        // LP 存入流动性
        usdc.mint(user1, INITIAL_VAULT_DEPOSIT);
        vm.startPrank(user1);
        usdc.approve(address(vault), INITIAL_VAULT_DEPOSIT);
        vault.deposit(INITIAL_VAULT_DEPOSIT, user1);
        vm.stopPrank();

        // 用户授权 Router
        vm.prank(user2);
        usdc.approve(address(router), type(uint256).max);

        vm.prank(user3);
        usdc.approve(address(router), type(uint256).max);

        // Label for traces
        vm.label(address(router), "BettingRouter");
        vm.label(address(factory), "MarketFactory");
        vm.label(address(market1), "Market1");
        vm.label(address(market2), "Market2");
    }

    // ============ 构造函数测试 ============

    function test_Constructor_SetsSettlementToken() public view {
        assertEq(address(router.settlementToken()), address(usdc));
    }

    function test_Constructor_SetsFactory() public view {
        assertEq(address(router.factory()), address(factory));
    }

    function test_Constructor_RevertOnZeroToken() public {
        vm.expectRevert(BettingRouter.ZeroAddress.selector);
        new BettingRouter(address(0), address(factory));
    }

    function test_Constructor_RevertOnZeroFactory() public {
        vm.expectRevert(BettingRouter.ZeroAddress.selector);
        new BettingRouter(address(usdc), address(0));
    }

    // ============ 单笔下注测试 ============

    function test_PlaceBet_Success() public {
        uint256 balanceBefore = usdc.balanceOf(user2);

        vm.prank(user2);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT);

        assertGt(shares, 0, "Should receive shares");
        assertEq(usdc.balanceOf(user2), balanceBefore - BET_AMOUNT, "USDC deducted");
        assertEq(market1.balanceOf(user2, 0), shares, "Position minted to user");
    }

    function test_PlaceBet_EmitEvent() public {
        vm.prank(user2);
        vm.expectEmit(true, true, true, false);
        emit BettingRouter.BetPlaced(user2, address(market1), 0, BET_AMOUNT, 0);
        router.placeBet(address(market1), 0, BET_AMOUNT);
    }

    function test_PlaceBet_MultipleBets() public {
        // 用户可以对不同结果下注
        vm.startPrank(user2);
        uint256 shares0 = router.placeBet(address(market1), 0, BET_AMOUNT);
        uint256 shares1 = router.placeBet(address(market1), 1, BET_AMOUNT);
        uint256 shares2 = router.placeBet(address(market1), 2, BET_AMOUNT);
        vm.stopPrank();

        assertGt(shares0, 0);
        assertGt(shares1, 0);
        assertGt(shares2, 0);
        assertEq(market1.balanceOf(user2, 0), shares0);
        assertEq(market1.balanceOf(user2, 1), shares1);
        assertEq(market1.balanceOf(user2, 2), shares2);
    }

    function test_PlaceBet_RevertOnZeroAmount() public {
        vm.prank(user2);
        vm.expectRevert(BettingRouter.ZeroAmount.selector);
        router.placeBet(address(market1), 0, 0);
    }

    function test_PlaceBet_RevertOnInvalidMarket() public {
        address fakeMarket = makeAddr("fakeMarket");

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(BettingRouter.InvalidMarket.selector, fakeMarket));
        router.placeBet(fakeMarket, 0, BET_AMOUNT);
    }

    function test_PlaceBet_RevertOnLockedMarket() public {
        // 锁定市场
        market1.lock();

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(BettingRouter.MarketNotOpen.selector, address(market1)));
        router.placeBet(address(market1), 0, BET_AMOUNT);
    }

    function test_PlaceBet_RevertOnUntrustedRouter() public {
        // 移除 Router 信任
        market1.setTrustedRouter(address(0));

        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(BettingRouter.RouterNotTrusted.selector, address(market1)));
        router.placeBet(address(market1), 0, BET_AMOUNT);
    }

    // ============ 带滑点保护的下注测试 ============

    function test_PlaceBetWithSlippage_Success() public {
        // 先下多笔普通注单以建立流动性并稳定价格
        vm.startPrank(user2);
        router.placeBet(address(market1), 0, BET_AMOUNT);
        router.placeBet(address(market1), 1, BET_AMOUNT);
        router.placeBet(address(market1), 2, BET_AMOUNT);
        vm.stopPrank();

        // 记录下注前的余额
        uint256 balanceBefore = market1.balanceOf(user2, 0);

        // 测试带滑点保护的下注
        // CPMM 三向市场在虚拟储备较大时，10 USDC 下注约获得 6.27M shares
        // 这意味着价格约为 1.56 USDC/share，需要约 60% 的滑点容忍度
        uint256 smallBet = 10 * 1e6; // 10 USDC
        vm.prank(user2);
        uint256 shares = router.placeBetWithSlippage(address(market1), 0, smallBet, 6000); // 60% 滑点

        assertGt(shares, 0);
        // 验证余额增加了正确的 shares 数量
        assertEq(market1.balanceOf(user2, 0), balanceBefore + shares);
    }

    function test_PlaceBetWithSlippage_RevertOnHighSlippage() public {
        // 先下一笔大单改变价格
        usdc.mint(user1, 50_000 * 1e6);
        vm.startPrank(user1);
        usdc.approve(address(router), type(uint256).max);
        router.placeBet(address(market1), 0, 50_000 * 1e6);
        vm.stopPrank();

        // 尝试下注但滑点限制很严格
        vm.prank(user2);
        vm.expectRevert("MarketBase_V2: Slippage too high");
        router.placeBetWithSlippage(address(market1), 0, 10_000 * 1e6, 10); // 0.1% 滑点限制
    }

    // ============ 批量下注测试 ============

    function test_PlaceBets_Success() public {
        BettingRouter.BetParams[] memory bets = new BettingRouter.BetParams[](3);
        bets[0] = BettingRouter.BetParams({
            market: address(market1),
            outcomeId: 0,
            amount: BET_AMOUNT,
            maxSlippage: 0 // 无滑点限制
        });
        bets[1] = BettingRouter.BetParams({
            market: address(market1),
            outcomeId: 1,
            amount: BET_AMOUNT * 2,
            maxSlippage: 0
        });
        bets[2] = BettingRouter.BetParams({
            market: address(market2),
            outcomeId: 2,
            amount: BET_AMOUNT,
            maxSlippage: 0 // 无滑点限制（新市场，首笔下注）
        });

        uint256 totalAmount = BET_AMOUNT + BET_AMOUNT * 2 + BET_AMOUNT;
        uint256 balanceBefore = usdc.balanceOf(user2);

        vm.prank(user2);
        uint256[] memory sharesList = router.placeBets(bets);

        assertEq(sharesList.length, 3);
        assertGt(sharesList[0], 0);
        assertGt(sharesList[1], 0);
        assertGt(sharesList[2], 0);

        assertEq(usdc.balanceOf(user2), balanceBefore - totalAmount);
        assertEq(market1.balanceOf(user2, 0), sharesList[0]);
        assertEq(market1.balanceOf(user2, 1), sharesList[1]);
        assertEq(market2.balanceOf(user2, 2), sharesList[2]);
    }

    function test_PlaceBets_EmitBatchEvent() public {
        BettingRouter.BetParams[] memory bets = new BettingRouter.BetParams[](2);
        bets[0] = BettingRouter.BetParams({
            market: address(market1),
            outcomeId: 0,
            amount: BET_AMOUNT,
            maxSlippage: 0
        });
        bets[1] = BettingRouter.BetParams({
            market: address(market2),
            outcomeId: 1,
            amount: BET_AMOUNT,
            maxSlippage: 0
        });

        vm.prank(user2);
        vm.expectEmit(true, false, false, true);
        emit BettingRouter.BatchBetsPlaced(user2, 2, BET_AMOUNT * 2);
        router.placeBets(bets);
    }

    // ============ 视图函数测试 ============

    function test_CheckAllowance() public {
        assertEq(router.checkAllowance(user2), type(uint256).max);
        assertEq(router.checkAllowance(makeAddr("noApproval")), 0);
    }

    function test_CheckMarket_Valid() public {
        (bool valid, string memory reason) = router.checkMarket(address(market1));
        assertTrue(valid);
        assertEq(reason, "");
    }

    function test_CheckMarket_NotRegistered() public {
        address fakeMarket = makeAddr("fakeMarket");
        (bool valid, string memory reason) = router.checkMarket(fakeMarket);
        assertFalse(valid);
        assertEq(reason, "Not a registered market");
    }

    function test_CheckMarket_NotOpen() public {
        market1.lock();
        (bool valid, string memory reason) = router.checkMarket(address(market1));
        assertFalse(valid);
        assertEq(reason, "Market not open");
    }

    function test_CheckMarket_RouterNotTrusted() public {
        market1.setTrustedRouter(address(0));
        (bool valid, string memory reason) = router.checkMarket(address(market1));
        assertFalse(valid);
        assertEq(reason, "Router not trusted by market");
    }

    // ============ 管理函数测试 ============

    function test_SetFactory_Success() public {
        address newFactory = makeAddr("newFactory");
        router.setFactory(newFactory);
        assertEq(address(router.factory()), newFactory);
    }

    function test_SetFactory_RevertOnZeroAddress() public {
        vm.expectRevert(BettingRouter.ZeroAddress.selector);
        router.setFactory(address(0));
    }

    function test_SetFactory_RevertOnNonOwner() public {
        vm.prank(user2);
        vm.expectRevert();
        router.setFactory(makeAddr("newFactory"));
    }

    function test_Pause_Success() public {
        router.pause();

        vm.prank(user2);
        vm.expectRevert();
        router.placeBet(address(market1), 0, BET_AMOUNT);
    }

    function test_Unpause_Success() public {
        router.pause();
        router.unpause();

        vm.prank(user2);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT);
        assertGt(shares, 0);
    }

    function test_EmergencyWithdraw_Success() public {
        // 模拟意外滞留的资金
        usdc.mint(address(router), 1000e6);

        uint256 balanceBefore = usdc.balanceOf(treasury);
        router.emergencyWithdraw(address(usdc), treasury, 1000e6);
        assertEq(usdc.balanceOf(treasury), balanceBefore + 1000e6);
    }

    function test_EmergencyWithdraw_RevertOnZeroAddress() public {
        vm.expectRevert(BettingRouter.ZeroAddress.selector);
        router.emergencyWithdraw(address(usdc), address(0), 1000e6);
    }

    // ============ 用户体验场景测试 ============

    function test_UserFlow_SingleApprovalMultipleMarkets() public {
        // 用户只授权一次 Router，就可以投注所有市场
        // 已在 setUp 中完成授权

        vm.startPrank(user2);

        // 投注市场 1
        uint256 shares1 = router.placeBet(address(market1), 0, BET_AMOUNT);

        // 投注市场 2
        uint256 shares2 = router.placeBet(address(market2), 1, BET_AMOUNT);

        vm.stopPrank();

        // 验证两个市场都成功收到投注
        assertGt(shares1, 0);
        assertGt(shares2, 0);
        assertEq(market1.balanceOf(user2, 0), shares1);
        assertEq(market2.balanceOf(user2, 1), shares2);
    }

    function test_UserFlow_DirectBetStillWorks() public {
        // V2 版本要求通过 trustedRouter 下注，测试设置其他 router 仍然可以工作
        // 首先部署一个新的 router 并设置为 trustedRouter
        BettingRouter newRouter = new BettingRouter(address(usdc), address(factory));
        market1.setTrustedRouter(address(newRouter));

        vm.startPrank(user2);
        usdc.approve(address(newRouter), type(uint256).max);
        uint256 shares = newRouter.placeBet(address(market1), 0, BET_AMOUNT);
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(market1.balanceOf(user2, 0), shares);
    }
}
