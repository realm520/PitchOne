// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/FeeRouter.sol";
import "../../src/core/ReferralRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Mock ERC20 Token for testing
 */
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000e6); // 1M USDC (6 decimals)
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @title FeeRouter Test Suite  
 */
contract FeeRouterTest is Test {
    FeeRouter public router;
    ReferralRegistry public registry;
    MockERC20 public usdc;

    address public owner = address(this);
    address public lpVault = address(0x10);
    address public promoPool = address(0x20);
    address public insuranceFund = address(0x30);
    address public treasury = address(0x40);

    address public market = address(0x50); // 模拟市场合约
    address public alice = address(0x60);
    address public bob = address(0x70);
    address public referrer = address(0x80);

    event FeeReceived(address indexed token, address indexed from, uint256 amount);
    event FeeRouted(
        address indexed token,
        uint256 totalAmount,
        address indexed referrer,
        uint256 referralAmount,
        uint256 lpAmount,
        uint256 promoAmount,
        uint256 insuranceAmount,
        uint256 treasuryAmount
    );
    event FeeSplitUpdated(uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps);
    event RecipientsUpdated(address lpVault, address promoPool, address insuranceFund, address treasury);

    function setUp() public {
        usdc = new MockERC20();

        // 部署 ReferralRegistry
        registry = new ReferralRegistry(owner);

        // 部署 FeeRouter
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: lpVault,
            promoPool: promoPool,
            insuranceFund: insuranceFund,
            treasury: treasury
        });

        router = new FeeRouter(recipients, address(registry));

        // 授权 FeeRouter 为 ReferralRegistry 的 owner（允许累计返佣）
        registry.transferOwnership(address(router));

        // 给 market 地址分配代币
        usdc.mint(market, 1_000_000e6);
    }

    // ============================================================================
    // Constructor Tests
    // ============================================================================

    function test_Constructor() public view {
        (address _lp, address _promo, address _insurance, address _treasury) = router.recipients();
        assertEq(_lp, lpVault);
        assertEq(_promo, promoPool);
        assertEq(_insurance, insuranceFund);
        assertEq(_treasury, treasury);

        assertEq(address(router.referralRegistry()), address(registry));

        // 默认分配：LP 40%, Promo 30%, Insurance 10%, Treasury 20%
        (uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps) = router.feeSplit();
        assertEq(lpBps, 4000);
        assertEq(promoBps, 3000);
        assertEq(insuranceBps, 1000);
        assertEq(treasuryBps, 2000);
    }

    function test_Constructor_RevertIf_ZeroAddress() public {
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: address(0),
            promoPool: promoPool,
            insuranceFund: insuranceFund,
            treasury: treasury
        });

        vm.expectRevert(abi.encodeWithSelector(FeeRouter.ZeroAddress.selector, "lpVault"));
        new FeeRouter(recipients, address(registry));
    }

    function test_Constructor_RevertIf_ZeroRegistry() public {
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: lpVault,
            promoPool: promoPool,
            insuranceFund: insuranceFund,
            treasury: treasury
        });

        vm.expectRevert(abi.encodeWithSelector(FeeRouter.ZeroAddress.selector, "referralRegistry"));
        new FeeRouter(recipients, address(0));
    }

    // ============================================================================
    // routeFee Tests (without referral)
    // ============================================================================

    function test_RouteFee_WithoutReferral() public {
        uint256 feeAmount = 1000e6;

        // market 授权并调用
        vm.startPrank(market);
        usdc.approve(address(router), feeAmount);

        vm.expectEmit(true, true, true, true);
        emit FeeReceived(address(usdc), market, feeAmount);

        vm.expectEmit(true, true, true, true);
        emit FeeRouted(
            address(usdc),
            feeAmount,
            address(0), // no referrer
            0, // no referral
            400e6, // LP 40%
            300e6, // Promo 30%
            100e6, // Insurance 10%
            200e6  // Treasury 20%
        );

        router.routeFee(address(usdc), alice, feeAmount, 100e6);
        vm.stopPrank();

        // 验证余额
        assertEq(usdc.balanceOf(lpVault), 400e6);
        assertEq(usdc.balanceOf(promoPool), 300e6);
        assertEq(usdc.balanceOf(insuranceFund), 100e6);
        assertEq(usdc.balanceOf(treasury), 200e6);

        // 验证统计
        assertEq(router.totalFeesReceived(address(usdc)), feeAmount);
        (,, uint256 totalLP, uint256 totalPromo, uint256 totalInsurance, uint256 totalTreasury) =
            router.getFeeStats(address(usdc));
        assertEq(totalLP, 400e6);
        assertEq(totalPromo, 300e6);
        assertEq(totalInsurance, 100e6);
        assertEq(totalTreasury, 200e6);
    }

    function test_RouteFee_ZeroAmount() public {
        vm.prank(market);
        router.routeFee(address(usdc), alice, 0, 100e6);

        // 不应该有任何转账
        assertEq(usdc.balanceOf(lpVault), 0);
    }

    // ============================================================================
    // routeFee Tests (with referral)
    // ============================================================================

    function test_RouteFee_WithReferral() public {
        // alice 绑定 referrer
        vm.prank(alice);
        registry.bind(referrer, 0);

        uint256 feeAmount = 1000e6;

        // 推荐返佣 8% = 80e6
        // 剩余 920e6 分配：LP 368e6, Promo 276e6, Insurance 92e6, Treasury 184e6

        vm.startPrank(market);
        usdc.approve(address(router), feeAmount);

        vm.expectEmit(true, true, true, true);
        emit FeeRouted(
            address(usdc),
            feeAmount,
            referrer,
            80e6,
            368e6,
            276e6,
            92e6,
            184e6
        );

        router.routeFee(address(usdc), alice, feeAmount, 100e6);
        vm.stopPrank();

        // 验证返佣
        assertEq(usdc.balanceOf(referrer), 80e6);
        assertEq(registry.totalReferralRewards(referrer), 80e6);

        // 验证池分配
        assertEq(usdc.balanceOf(lpVault), 368e6);
        assertEq(usdc.balanceOf(promoPool), 276e6);
        assertEq(usdc.balanceOf(insuranceFund), 92e6);
        assertEq(usdc.balanceOf(treasury), 184e6);
    }

    function test_RouteFee_ReferralExpired() public {
        // alice 绑定 referrer
        vm.prank(alice);
        registry.bind(referrer, 0);

        // 快进超过有效期（365天）
        vm.warp(block.timestamp + 366 days);

        uint256 feeAmount = 1000e6;

        vm.startPrank(market);
        usdc.approve(address(router), feeAmount);

        // 应该没有返佣（过期）
        vm.expectEmit(true, true, true, true);
        emit FeeRouted(
            address(usdc),
            feeAmount,
            address(0),
            0, // no referral
            400e6,
            300e6,
            100e6,
            200e6
        );

        router.routeFee(address(usdc), alice, feeAmount, 100e6);
        vm.stopPrank();

        assertEq(usdc.balanceOf(referrer), 0);
    }

    // ============================================================================
    // batchRouteFee Tests
    // ============================================================================

    function test_BatchRouteFee() public {
        // alice 有推荐人，bob 没有
        vm.prank(alice);
        registry.bind(referrer, 0);

        address[] memory users = new address[](2);
        users[0] = alice;
        users[1] = bob;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000e6;
        amounts[1] = 500e6;

        uint256 totalAmount = 1500e6;

        vm.startPrank(market);
        usdc.approve(address(router), totalAmount);
        (uint256 successCount, uint256[] memory failedIndices) = router.batchRouteFee(address(usdc), users, amounts);
        vm.stopPrank();

        // 验证批量处理结果
        assertEq(successCount, 2, "Should have 2 successful operations");
        assertEq(failedIndices.length, 0, "Should have no failed operations");

        // 注意: alice 绑定推荐人但未达到有效阈值,所以不会有推荐返佣
        // alice: 0 返佣(推荐未生效) + 1000e6 分配
        // bob: 0 返佣 + 500e6 分配
        // 总计返佣: 0
        // 总计LP: 400e6 + 200e6 = 600e6 (40% of 1500e6)
        assertEq(usdc.balanceOf(referrer), 0, "No referral commission until valid");
        assertEq(usdc.balanceOf(lpVault), 600e6, "LP gets 40% of total fees");
    }

    function test_BatchRouteFee_RevertIf_LengthMismatch() public {
        address[] memory users = new address[](2);
        uint256[] memory amounts = new uint256[](1);

        vm.prank(market);
        vm.expectRevert("Length mismatch");
        router.batchRouteFee(address(usdc), users, amounts);
    }

    // ============================================================================
    // Query Tests
    // ============================================================================

    function test_GetReferralBps() public {
        // alice 没有推荐人
        assertEq(router.getReferralBps(alice), 0);

        // alice 绑定推荐人
        vm.prank(alice);
        registry.bind(referrer, 0);

        // 模拟交易量达到最低门槛 (通过 FeeRouter 的 routeFee 调用)
        vm.startPrank(market);
        usdc.approve(address(router), 1000e6);
        router.routeFee(address(usdc), alice, 1000e6, 100e6); // 模拟 alice 交易 100 USDC
        vm.stopPrank();

        assertEq(router.getReferralBps(alice), 800);

        // 过期后
        vm.warp(block.timestamp + 366 days);
        assertEq(router.getReferralBps(alice), 0);
    }

    function test_PreviewFeeSplit_WithoutReferral() public view {
        (
            uint256 referralAmount,
            uint256 lpAmount,
            uint256 promoAmount,
            uint256 insuranceAmount,
            uint256 treasuryAmount
        ) = router.previewFeeSplit(1000e6, false);

        assertEq(referralAmount, 0);
        assertEq(lpAmount, 400e6);
        assertEq(promoAmount, 300e6);
        assertEq(insuranceAmount, 100e6);
        assertEq(treasuryAmount, 200e6);
    }

    function test_PreviewFeeSplit_WithReferral() public view {
        (
            uint256 referralAmount,
            uint256 lpAmount,
            uint256 promoAmount,
            uint256 insuranceAmount,
            uint256 treasuryAmount
        ) = router.previewFeeSplit(1000e6, true);

        assertEq(referralAmount, 80e6);
        assertEq(lpAmount, 368e6);
        assertEq(promoAmount, 276e6);
        assertEq(insuranceAmount, 92e6);
        assertEq(treasuryAmount, 184e6);
    }

    function test_GetFeeStats() public {
        // 路由一些费用
        vm.startPrank(market);
        usdc.approve(address(router), 1000e6);
        router.routeFee(address(usdc), alice, 1000e6, 100e6);
        vm.stopPrank();

        (
            uint256 totalReceived,
            uint256 totalReferral,
            uint256 totalLP,
            uint256 totalPromo,
            uint256 totalInsurance,
            uint256 totalTreasury
        ) = router.getFeeStats(address(usdc));

        assertEq(totalReceived, 1000e6);
        assertEq(totalReferral, 0); // alice 没有推荐人
        assertEq(totalLP, 400e6);
        assertEq(totalPromo, 300e6);
        assertEq(totalInsurance, 100e6);
        assertEq(totalTreasury, 200e6);
    }

    // ============================================================================
    // Admin Tests
    // ============================================================================

    function test_SetFeeSplit() public {
        vm.expectEmit(true, true, true, true);
        emit FeeSplitUpdated(5000, 2000, 2000, 1000);
        router.setFeeSplit(5000, 2000, 2000, 1000);

        (uint256 lpBps, uint256 promoBps, uint256 insuranceBps, uint256 treasuryBps) = router.feeSplit();
        assertEq(lpBps, 5000);
        assertEq(promoBps, 2000);
        assertEq(insuranceBps, 2000);
        assertEq(treasuryBps, 1000);
    }

    function test_SetFeeSplit_RevertIf_InvalidTotal() public {
        vm.expectRevert(abi.encodeWithSelector(FeeRouter.InvalidFeeSplit.selector, 9999));
        router.setFeeSplit(5000, 2000, 2000, 999); // 总和 9999
    }

    function test_SetFeeSplit_RevertIf_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        router.setFeeSplit(5000, 2000, 2000, 1000);
    }

    function test_SetRecipients() public {
        FeeRouter.FeeRecipients memory newRecipients = FeeRouter.FeeRecipients({
            lpVault: address(0x100),
            promoPool: address(0x200),
            insuranceFund: address(0x300),
            treasury: address(0x400)
        });

        vm.expectEmit(true, true, true, true);
        emit RecipientsUpdated(address(0x100), address(0x200), address(0x300), address(0x400));
        router.setRecipients(newRecipients);

        (address _lp, address _promo, address _insurance, address _treasury) = router.recipients();
        assertEq(_lp, address(0x100));
        assertEq(_promo, address(0x200));
        assertEq(_insurance, address(0x300));
        assertEq(_treasury, address(0x400));
    }

    function test_SetRecipients_RevertIf_ZeroAddress() public {
        FeeRouter.FeeRecipients memory newRecipients = FeeRouter.FeeRecipients({
            lpVault: address(0),
            promoPool: promoPool,
            insuranceFund: insuranceFund,
            treasury: treasury
        });

        vm.expectRevert(abi.encodeWithSelector(FeeRouter.ZeroAddress.selector, "lpVault"));
        router.setRecipients(newRecipients);
    }

    function test_SetReferralRegistry() public {
        ReferralRegistry newRegistry = new ReferralRegistry(owner);

        router.setReferralRegistry(address(newRegistry));
        assertEq(address(router.referralRegistry()), address(newRegistry));
    }

    function test_SetReferralRegistry_RevertIf_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(FeeRouter.ZeroAddress.selector, "registry"));
        router.setReferralRegistry(address(0));
    }

    function test_EmergencyWithdraw() public {
        // 先路由一些费用到合约
        vm.startPrank(market);
        usdc.approve(address(router), 1000e6);
        usdc.transfer(address(router), 1000e6);
        vm.stopPrank();

        uint256 balanceBefore = usdc.balanceOf(treasury);
        router.emergencyWithdraw(address(usdc), treasury, 500e6);

        assertEq(usdc.balanceOf(treasury), balanceBefore + 500e6);
    }

    function test_EmergencyWithdraw_RevertIf_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(FeeRouter.ZeroAddress.selector, "to"));
        router.emergencyWithdraw(address(usdc), address(0), 100e6);
    }

    function test_Pause() public {
        router.pause();
        assertTrue(router.paused());

        vm.startPrank(market);
        usdc.approve(address(router), 1000e6);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        router.routeFee(address(usdc), alice, 1000e6, 100e6);
        vm.stopPrank();
    }

    function test_Unpause() public {
        router.pause();
        router.unpause();
        assertFalse(router.paused());

        // 恢复后可以路由
        vm.startPrank(market);
        usdc.approve(address(router), 1000e6);
        router.routeFee(address(usdc), alice, 1000e6, 100e6);
        vm.stopPrank();
    }

    // ============================================================================
    // Edge Cases & Rounding Tests
    // ============================================================================

    function test_RouteFee_SmallAmount_NoRounding() public {
        // 测试小额费用的舍入
        uint256 feeAmount = 10; // 10 最小单位

        vm.startPrank(market);
        usdc.approve(address(router), feeAmount);
        router.routeFee(address(usdc), alice, feeAmount, 100e6);
        vm.stopPrank();

        // LP: 10 * 4000 / 10000 = 4
        // Promo: 10 * 3000 / 10000 = 3
        // Insurance: 10 * 1000 / 10000 = 1
        // Treasury: 10 - 4 - 3 - 1 = 2 (剩余)

        assertEq(usdc.balanceOf(lpVault), 4);
        assertEq(usdc.balanceOf(promoPool), 3);
        assertEq(usdc.balanceOf(insuranceFund), 1);
        assertEq(usdc.balanceOf(treasury), 2);

        // 总和应该等于原始金额
        uint256 total = usdc.balanceOf(lpVault) + usdc.balanceOf(promoPool) +
                        usdc.balanceOf(insuranceFund) + usdc.balanceOf(treasury);
        assertEq(total, feeAmount);
    }

    function test_RouteFee_WithReferral_Rounding() public {
        vm.prank(alice);
        registry.bind(referrer, 0);

        // 1000 * 800 / 10000 = 80 返佣
        // 剩余 920
        uint256 feeAmount = 1000;

        vm.startPrank(market);
        usdc.approve(address(router), feeAmount);
        router.routeFee(address(usdc), alice, feeAmount, 100e6);
        vm.stopPrank();

        // LP: 920 * 4000 / 10000 = 368
        // Promo: 920 * 3000 / 10000 = 276
        // Insurance: 920 * 1000 / 10000 = 92
        // Treasury: 920 - 368 - 276 - 92 = 184

        uint256 total = usdc.balanceOf(referrer) + usdc.balanceOf(lpVault) +
                        usdc.balanceOf(promoPool) + usdc.balanceOf(insuranceFund) +
                        usdc.balanceOf(treasury);
        assertEq(total, feeAmount);
    }

    // ============================================================================
    // Fuzz Tests
    // ============================================================================

    function testFuzz_RouteFee_NoReferral(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e6);

        vm.startPrank(market);
        usdc.approve(address(router), amount);
        router.routeFee(address(usdc), alice, amount, 100e6);
        vm.stopPrank();

        // 验证总和守恒
        uint256 total = usdc.balanceOf(lpVault) + usdc.balanceOf(promoPool) +
                        usdc.balanceOf(insuranceFund) + usdc.balanceOf(treasury);
        assertEq(total, amount);
    }

    function testFuzz_RouteFee_WithReferral(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e6);

        vm.prank(alice);
        registry.bind(referrer, 0);

        vm.startPrank(market);
        usdc.approve(address(router), amount);
        router.routeFee(address(usdc), alice, amount, 100e6);
        vm.stopPrank();

        // 验证总和守恒
        uint256 total = usdc.balanceOf(referrer) + usdc.balanceOf(lpVault) +
                        usdc.balanceOf(promoPool) + usdc.balanceOf(insuranceFund) +
                        usdc.balanceOf(treasury);
        assertEq(total, amount);
    }

    function testFuzz_FeeSplit(
        uint256 lpBps,
        uint256 promoBps,
        uint256 insuranceBps
    ) public {
        // 确保总和为 10000
        lpBps = bound(lpBps, 0, 10000);
        promoBps = bound(promoBps, 0, 10000 - lpBps);
        insuranceBps = bound(insuranceBps, 0, 10000 - lpBps - promoBps);
        uint256 treasuryBps = 10000 - lpBps - promoBps - insuranceBps;

        router.setFeeSplit(lpBps, promoBps, insuranceBps, treasuryBps);

        // 路由费用验证
        uint256 amount = 10000e6;
        vm.startPrank(market);
        usdc.approve(address(router), amount);
        router.routeFee(address(usdc), alice, amount, 100e6);
        vm.stopPrank();

        // 验证分配比例
        uint256 expectedLP = (amount * lpBps) / 10000;
        uint256 expectedPromo = (amount * promoBps) / 10000;
        uint256 expectedInsurance = (amount * insuranceBps) / 10000;

        assertApproxEqAbs(usdc.balanceOf(lpVault), expectedLP, 1);
        assertApproxEqAbs(usdc.balanceOf(promoPool), expectedPromo, 1);
        assertApproxEqAbs(usdc.balanceOf(insuranceFund), expectedInsurance, 1);

        // 总和守恒
        uint256 total = usdc.balanceOf(lpVault) + usdc.balanceOf(promoPool) +
                        usdc.balanceOf(insuranceFund) + usdc.balanceOf(treasury);
        assertEq(total, amount);
    }
}
