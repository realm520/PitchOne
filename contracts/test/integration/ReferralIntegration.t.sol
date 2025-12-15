// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/WDL_Template_V2.sol";
import "../../src/liquidity/LiquidityVault.sol";

/**
 * @title ReferralIntegrationTest
 * @notice 测试完整的推荐返佣流程：绑定 → 下注 → 自动返佣
 */
contract ReferralIntegrationTest is BaseTest {
    WDL_Template_V2 public market;
    LiquidityVault public vault;

    address referrer = address(0x100);  // 推荐人
    address referee = address(0x200);   // 被推荐人


    function setUp() public override {
        super.setUp();

        // 设置 minValidVolume 为 0，以便测试（在 transferOwnership 之前）
        referralRegistry.setMinValidVolume(0);

        // 将 ReferralRegistry 的所有权转移给 FeeRouter，使其可以调用 accrueReferralReward
        referralRegistry.transferOwnership(address(feeRouter));

        // 部署 Vault
        vault = new LiquidityVault(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );

        // 部署市场
        market = new WDL_Template_V2();
        market.initialize(
            "EPL_2024_TEST",
            "Home Team",
            "Away Team",
            block.timestamp + 7 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "https://metadata.com/{id}",
            100_000 * 1e6  // virtualReservePerSide
        );

        // 授权市场
        vault.authorizeMarket(address(market));

        // 设置 trustedRouter（必需，否则无法下注）
        // 使用测试合约地址作为 router，允许测试直接下注
        market.setTrustedRouter(address(this));

        // LP 存入流动性
        usdc.mint(user1, 500_000e6);
        vm.startPrank(user1);
        usdc.approve(address(vault), 500_000e6);
        vault.deposit(500_000e6, user1);
        vm.stopPrank();

        // 给推荐人和被推荐人发币
        usdc.mint(referrer, 10_000e6);
        usdc.mint(referee, 10_000e6);
    }

    /**
     * @notice 测试完整的推荐返佣流程
     */
    function test_FullReferralFlow() public {
        // 1. 被推荐人绑定推荐关系
        vm.prank(referee);
        referralRegistry.bind(referrer, 0);

        // 验证绑定成功
        assertEq(referralRegistry.referrer(referee), referrer);
        assertTrue(referralRegistry.isReferralValid(referee));

        // 2. 记录初始余额
        uint256 referrerBalanceBefore = usdc.balanceOf(referrer);
        uint256 feeRouterBalanceBefore = usdc.balanceOf(address(feeRouter));

        // 3. 被推荐人下注 100 USDC
        uint256 betAmount = 100e6;
        vm.startPrank(referee);
        usdc.approve(address(market), betAmount);
        market.placeBet(0, betAmount); // 投注 outcome 0 (主队胜)
        vm.stopPrank();

        // 4. 验证返佣
        // 手续费 = 100 * 2% = 2 USDC
        // 返佣 = 2 * 8% = 0.16 USDC (默认返佣比例 800 bps = 8%)
        uint256 expectedFee = (betAmount * 200) / 10000; // 2 USDC
        uint256 expectedReferralAmount = (expectedFee * 800) / 10000; // 0.16 USDC

        uint256 referrerBalanceAfter = usdc.balanceOf(referrer);
        uint256 referralReward = referrerBalanceAfter - referrerBalanceBefore;

        // 验证推荐人收到返佣
        assertEq(referralReward, expectedReferralAmount, "Referrer should receive commission");

        // 5. 验证推荐注册表的累计返佣记录
        (uint256 count, uint256 totalRewards) = referralRegistry.getReferrerStats(referrer);
        assertEq(count, 1, "Referrer should have 1 referee");
        assertEq(totalRewards, expectedReferralAmount, "Total rewards should match");

        // 6. 验证 FeeRouter 的统计数据
        (
            uint256 totalReceived,
            uint256 totalReferral,
            uint256 totalLP,
            uint256 totalPromo,
            uint256 totalInsurance,
            uint256 totalTreasury
        ) = feeRouter.getFeeStats(address(usdc));

        assertEq(totalReceived, expectedFee, "FeeRouter should record total fees");
        assertEq(totalReferral, expectedReferralAmount, "FeeRouter should record referral amount");

        // 验证剩余手续费分配到各池
        uint256 remainingFee = expectedFee - expectedReferralAmount;
        uint256 expectedLP = (remainingFee * 4000) / 10000;      // 40%
        uint256 expectedPromo = (remainingFee * 3000) / 10000;   // 30%
        uint256 expectedInsurance = (remainingFee * 1000) / 10000; // 10%
        // treasury 获得剩余部分，避免舍入误差

        assertEq(totalLP, expectedLP, "LP should receive 40% of remaining fee");
        assertEq(totalPromo, expectedPromo, "Promo should receive 30% of remaining fee");
        assertEq(totalInsurance, expectedInsurance, "Insurance should receive 10% of remaining fee");
    }

    /**
     * @notice 测试无推荐人的情况
     */
    function test_BetWithoutReferrer() public {
        // 被推荐人没有绑定推荐关系，直接下注
        uint256 betAmount = 100e6;

        vm.startPrank(referee);
        usdc.approve(address(market), betAmount);
        market.placeBet(0, betAmount);
        vm.stopPrank();

        // 验证：无人收到返佣
        (uint256 count, uint256 totalRewards) = referralRegistry.getReferrerStats(referrer);
        assertEq(count, 0, "No referrals should exist");
        assertEq(totalRewards, 0, "No rewards should be distributed");

        // 验证：全部手续费分配到各池
        uint256 expectedFee = (betAmount * 200) / 10000;
        (
            uint256 totalReceived,
            uint256 totalReferral,
            ,
            ,
            ,
        ) = feeRouter.getFeeStats(address(usdc));

        assertEq(totalReceived, expectedFee, "FeeRouter should receive all fees");
        assertEq(totalReferral, 0, "No referral commission");
    }

    /**
     * @notice 测试多次下注累计返佣
     */
    function test_MultipleBets_AccumulateRewards() public {
        // 1. 绑定推荐关系
        vm.prank(referee);
        referralRegistry.bind(referrer, 0);

        uint256 referrerBalanceBefore = usdc.balanceOf(referrer);

        // 2. 第一次下注 50 USDC
        vm.startPrank(referee);
        usdc.approve(address(market), 200e6);
        market.placeBet(0, 50e6);

        // 3. 第二次下注 100 USDC
        market.placeBet(1, 100e6);
        vm.stopPrank();

        // 4. 验证累计返佣
        uint256 totalBet = 150e6;
        uint256 totalFee = (totalBet * 200) / 10000; // 3 USDC
        uint256 expectedTotalReferral = (totalFee * 800) / 10000; // 0.24 USDC

        uint256 referrerBalanceAfter = usdc.balanceOf(referrer);
        assertEq(
            referrerBalanceAfter - referrerBalanceBefore,
            expectedTotalReferral,
            "Referrer should receive accumulated commission"
        );

        // 验证注册表记录
        (uint256 count, uint256 totalRewards) = referralRegistry.getReferrerStats(referrer);
        assertEq(count, 1, "Still only 1 referee");
        assertEq(totalRewards, expectedTotalReferral, "Total rewards should accumulate");
    }

    /**
     * @notice 测试推荐关系过期后不返佣
     */
    function test_ExpiredReferral_NoCommission() public {
        // 1. 绑定推荐关系
        vm.prank(referee);
        referralRegistry.bind(referrer, 0);

        // 2. 时间快进超过有效期（默认 365 天）
        vm.warp(block.timestamp + 366 days);

        // 验证推荐关系已过期
        assertFalse(referralRegistry.isReferralValid(referee), "Referral should be expired");

        uint256 referrerBalanceBefore = usdc.balanceOf(referrer);

        // 3. 创建一个新市场（因为原市场的开赛时间已过）
        WDL_Template_V2 newMarket = new WDL_Template_V2();
        newMarket.initialize(
            "EPL_2024_TEST_NEW",
            "Home Team",
            "Away Team",
            block.timestamp + 7 days,  // 使用当前时间 + 7 天
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "https://metadata.com/{id}",
            100_000 * 1e6
        );
        vault.authorizeMarket(address(newMarket));
        newMarket.setTrustedRouter(address(this));

        // 4. 被推荐人下注
        vm.startPrank(referee);
        usdc.approve(address(newMarket), 100e6);
        newMarket.placeBet(0, 100e6);
        vm.stopPrank();

        // 5. 验证推荐人没有收到返佣
        uint256 referrerBalanceAfter = usdc.balanceOf(referrer);
        assertEq(referrerBalanceAfter, referrerBalanceBefore, "Expired referral should not receive commission");
    }
}
