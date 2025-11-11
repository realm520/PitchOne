// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/tokens/Coupon.sol";

contract CouponTest is Test {
    Coupon public coupon;
    address public admin = address(this);
    address public minter = address(0x1);
    address public alice = address(0x3);

    uint256 public couponTypeId;

    function setUp() public {
        coupon = new Coupon("https://pitchone.io/coupons/{id}.json");
        coupon.grantRole(coupon.MINTER_ROLE(), minter);

        couponTypeId = coupon.createCouponType(
            500,  // 5% 加成
            Coupon.UsageScope.ALL,
            1_000_000, // 最低 1 USDC
            0,    // 无赔率上限
            0,    // 永不过期
            0,    // 无限使用
            "boost5.json"
        );
    }

    function test_Constructor() public view {
        assertEq(coupon.nextCouponTypeId(), 1);
    }

    function test_CreateCouponType() public {
        uint256 newId = coupon.createCouponType(
            1000, // 10% 加成
            Coupon.UsageScope.WDL_ONLY,
            0,
            5e18, // 最大赔率 5.0
            block.timestamp + 30 days,
            1,
            ""
        );
        assertEq(newId, 1);
    }

    function test_Mint() public {
        vm.prank(minter);
        coupon.mint(alice, couponTypeId, 5);
        assertEq(coupon.balanceOf(alice, couponTypeId), 5);
    }

    function test_UseCoupon() public {
        vm.prank(minter);
        coupon.mint(alice, couponTypeId, 1);

        vm.prank(minter);
        uint256 boosted = coupon.useCoupon(
            alice,
            couponTypeId,
            address(0x123),
            1_000_000,
            2e18, // 原始赔率 2.0
            Coupon.UsageScope.WDL_ONLY
        );

        // 2.0 * (1 + 5%) = 2.1
        assertEq(boosted, 2.1e18);
        assertEq(coupon.balanceOf(alice, couponTypeId), 0);
    }

    function test_PreviewBoostedOdds() public view {
        uint256 boosted = coupon.previewBoostedOdds(couponTypeId, 2e18);
        assertEq(boosted, 2.1e18); // 2.0 * 1.05
    }

    function test_IsCouponValid() public {
        vm.prank(minter);
        coupon.mint(alice, couponTypeId, 1);

        bool valid = coupon.isCouponValid(
            alice,
            couponTypeId,
            1_000_000,
            Coupon.UsageScope.ALL
        );
        assertTrue(valid);
    }

    function test_RevertWhen_UseCouponInsufficientBalance() public {
        vm.prank(minter);
        vm.expectRevert(Coupon.InsufficientCoupon.selector);
        coupon.useCoupon(alice, couponTypeId, address(0x123), 1_000_000, 2e18, Coupon.UsageScope.ALL);
    }

    function test_RevertWhen_CreateCouponTypeInvalidBoost() public {
        vm.expectRevert(Coupon.InvalidBoostBps.selector);
        coupon.createCouponType(5001, Coupon.UsageScope.ALL, 0, 0, 0, 0, "");
    }

    function test_GetCouponStatus() public {
        vm.prank(minter);
        coupon.mint(alice, couponTypeId, 5);

        (uint256 balance, uint256 used, uint256 maxUses) = coupon.getCouponStatus(alice, couponTypeId);
        assertEq(balance, 5);
        assertEq(used, 0);
        assertEq(maxUses, 0);
    }

    function test_UsageHistory() public {
        vm.prank(minter);
        coupon.mint(alice, couponTypeId, 1);

        vm.prank(minter);
        coupon.useCoupon(alice, couponTypeId, address(0x123), 1_000_000, 2e18, Coupon.UsageScope.ALL);

        uint256[] memory history = coupon.getUserUsageHistory(alice);
        assertEq(history.length, 1);

        Coupon.CouponUsage memory usage = coupon.getUsageDetail(history[0]);
        assertEq(usage.user, alice);
        assertEq(usage.betAmount, 1_000_000);
    }
}
