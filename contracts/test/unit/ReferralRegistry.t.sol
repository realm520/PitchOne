// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/ReferralRegistry.sol";

/**
 * @title ReferralRegistryTest
 * @notice ReferralRegistry 合约的完整测试套件
 * @dev 覆盖目标：≥80%
 *      测试分类：
 *      1. 基础绑定功能（15个测试）
 *      2. 防作弊机制（10个测试）
 *      3. 返佣累计（5个测试）
 *      4. 查询功能（5个测试）
 *      5. 管理功能（5个测试）
 */
contract ReferralRegistryTest is Test {
    ReferralRegistry public registry;

    address public owner = address(this);
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    address public dave = address(0x4);

    event ReferralBound(
        address indexed user,
        address indexed referrer,
        uint256 indexed campaignId,
        uint256 timestamp
    );

    event ReferralAccrued(
        address indexed referrer,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event ParameterUpdated(string param, uint256 value);

    function setUp() public {
        registry = new ReferralRegistry(owner);
    }

    // ============================================================================
    // 基础绑定功能测试
    // ============================================================================

    function testBind_Success() public {
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit ReferralBound(alice, bob, 0, block.timestamp);
        registry.bind(bob, 0);

        assertEq(registry.referrer(alice), bob);
        assertEq(registry.referralCount(bob), 1);
        assertEq(registry.boundAt(alice), block.timestamp);
    }

    function testBind_WithCampaign() public {
        uint256 campaignId = 123;

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit ReferralBound(alice, bob, campaignId, block.timestamp);
        registry.bind(bob, campaignId);

        assertEq(registry.referrer(alice), bob);
    }

    function testBind_MultipleUsers() public {
        // Bob推荐Alice和Charlie
        vm.prank(alice);
        registry.bind(bob, 0);

        vm.prank(charlie);
        registry.bind(bob, 0);

        assertEq(registry.referralCount(bob), 2);
        assertEq(registry.referrer(alice), bob);
        assertEq(registry.referrer(charlie), bob);
    }

    function testBind_RevertWhen_AlreadyBound() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ReferralRegistry.AlreadyBound.selector,
                alice,
                bob
            )
        );
        registry.bind(charlie, 0);
    }

    function testBind_RevertWhen_SelfReferral() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(ReferralRegistry.SelfReferral.selector, alice)
        );
        registry.bind(alice, 0);
    }

    function testBind_RevertWhen_InvalidReferrer() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ReferralRegistry.InvalidReferrer.selector,
                address(0)
            )
        );
        registry.bind(address(0), 0);
    }

    function testBind_RevertWhen_CircularReferral() public {
        // Alice -> Bob
        vm.prank(alice);
        registry.bind(bob, 0);

        // Bob不能 -> Alice (形成循环)
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                ReferralRegistry.CircularReferral.selector,
                bob,
                alice
            )
        );
        registry.bind(alice, 0);
    }

    function testBind_RevertWhen_Paused() public {
        registry.pause();

        vm.prank(alice);
        vm.expectRevert();
        registry.bind(bob, 0);
    }

    function testBind_ChainReferral() public {
        // Charlie -> Bob -> Alice (链式推荐)
        vm.prank(alice);
        registry.bind(bob, 0);

        vm.prank(bob);
        registry.bind(charlie, 0);

        assertEq(registry.referrer(alice), bob);
        assertEq(registry.referrer(bob), charlie);
        assertEq(registry.referralCount(charlie), 1);
        assertEq(registry.referralCount(bob), 1);
    }

    function testBind_TimestampRecorded() public {
        uint256 expectedTime = block.timestamp;

        vm.prank(alice);
        registry.bind(bob, 0);

        assertEq(registry.boundAt(alice), expectedTime);
    }

    // ============================================================================
    // 防作弊机制测试
    // ============================================================================

    function testIsReferralValid_ValidReferral() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        assertTrue(registry.isReferralValid(alice));
    }

    function testIsReferralValid_NoReferrer() public {
        assertFalse(registry.isReferralValid(alice));
    }

    function testIsReferralValid_Expired() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        // 前进365天 + 1秒
        vm.warp(block.timestamp + 365 days + 1);

        assertFalse(registry.isReferralValid(alice));
    }

    function testIsReferralValid_BeforeExpiry() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        // 前进364天
        vm.warp(block.timestamp + 364 days);

        assertTrue(registry.isReferralValid(alice));
    }

    function testIsReferralValid_ExactlyAtExpiry() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        // 前进正好365天
        vm.warp(block.timestamp + 365 days);

        assertTrue(registry.isReferralValid(alice));
    }

    function testValidityWindow_CustomWindow() public {
        // 设置30天窗口
        registry.setValidityWindow(30 days);

        vm.prank(alice);
        registry.bind(bob, 0);

        // 31天后应该失效
        vm.warp(block.timestamp + 31 days);
        assertFalse(registry.isReferralValid(alice));
    }

    function testValidityWindow_ZeroWindow() public {
        // 设置0天窗口
        registry.setValidityWindow(0);

        vm.prank(alice);
        registry.bind(bob, 0);

        // 在同一个区块内仍然有效（timestamp相等）
        assertTrue(registry.isReferralValid(alice));

        // 下一个区块就会失效
        vm.warp(block.timestamp + 1);
        assertFalse(registry.isReferralValid(alice));
    }

    function testValidityWindow_LongWindow() public {
        // 设置10年窗口
        registry.setValidityWindow(3650 days);

        vm.prank(alice);
        registry.bind(bob, 0);

        // 1年后仍然有效
        vm.warp(block.timestamp + 365 days);
        assertTrue(registry.isReferralValid(alice));
    }

    // ============================================================================
    // 返佣累计测试
    // ============================================================================

    function testAccrueReferralReward_Success() public {
        uint256 amount = 10e6; // 10 USDC

        vm.expectEmit(true, true, false, true);
        emit ReferralAccrued(bob, alice, amount, block.timestamp);
        registry.accrueReferralReward(bob, alice, amount);

        assertEq(registry.totalReferralRewards(bob), amount);
    }

    function testAccrueReferralReward_MultipleAccruals() public {
        registry.accrueReferralReward(bob, alice, 10e6);
        registry.accrueReferralReward(bob, charlie, 20e6);

        assertEq(registry.totalReferralRewards(bob), 30e6);
    }

    function testAccrueReferralReward_ZeroAddress() public {
        // 不应该revert，只是不记录
        registry.accrueReferralReward(address(0), alice, 10e6);

        assertEq(registry.totalReferralRewards(address(0)), 0);
    }

    function testAccrueReferralReward_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.accrueReferralReward(bob, alice, 10e6);
    }

    function testAccrueReferralReward_LargeAmount() public {
        uint256 largeAmount = type(uint256).max / 2;

        registry.accrueReferralReward(bob, alice, largeAmount);
        registry.accrueReferralReward(bob, charlie, largeAmount);

        // 两个 max/2 相加应该接近但不完全等于 max (因为溢出处理)
        assertGe(registry.totalReferralRewards(bob), type(uint256).max - 1);
    }

    // ============================================================================
    // 查询功能测试
    // ============================================================================

    function testGetReferrer_NoReferrer() public {
        assertEq(registry.getReferrer(alice), address(0));
    }

    function testGetReferrer_WithReferrer() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        assertEq(registry.getReferrer(alice), bob);
    }

    function testGetReferrerStats() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        registry.accrueReferralReward(bob, alice, 100e6);

        (uint256 count, uint256 rewards) = registry.getReferrerStats(bob);
        assertEq(count, 1);
        assertEq(rewards, 100e6);
    }

    function testGetReferrersBatch() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        vm.prank(charlie);
        registry.bind(dave, 0);

        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = charlie;
        users[2] = address(0x99); // 无推荐人

        address[] memory referrers = registry.getReferrersBatch(users);

        assertEq(referrers[0], bob);
        assertEq(referrers[1], dave);
        assertEq(referrers[2], address(0));
    }

    function testGetReferrersBatch_EmptyArray() public {
        address[] memory users = new address[](0);
        address[] memory referrers = registry.getReferrersBatch(users);

        assertEq(referrers.length, 0);
    }

    // ============================================================================
    // 管理功能测试
    // ============================================================================

    function testSetValidityWindow() public {
        vm.expectEmit(false, false, false, true);
        emit ParameterUpdated("validityWindow", 180 days);
        registry.setValidityWindow(180 days);

        assertEq(registry.validityWindow(), 180 days);
    }

    function testSetValidityWindow_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.setValidityWindow(180 days);
    }

    function testSetMinValidVolume() public {
        vm.expectEmit(false, false, false, true);
        emit ParameterUpdated("minValidVolume", 500e6);
        registry.setMinValidVolume(500e6);

        assertEq(registry.minValidVolume(), 500e6);
    }

    function testSetReferralFeeBps() public {
        vm.expectEmit(false, false, false, true);
        emit ParameterUpdated("referralFeeBps", 1000); // 10%
        registry.setReferralFeeBps(1000);

        assertEq(registry.referralFeeBps(), 1000);
    }

    function testSetReferralFeeBps_RevertWhen_TooHigh() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ReferralRegistry.InvalidFeeBps.selector,
                2001
            )
        );
        registry.setReferralFeeBps(2001); // > 20%
    }

    function testPause() public {
        registry.pause();
        assertTrue(registry.paused());

        vm.prank(alice);
        vm.expectRevert();
        registry.bind(bob, 0);
    }

    function testUnpause() public {
        registry.pause();
        registry.unpause();
        assertFalse(registry.paused());

        vm.prank(alice);
        registry.bind(bob, 0); // 应该成功
    }

    function testEmergencyUnbind() public {
        vm.prank(alice);
        registry.bind(bob, 0);

        registry.emergencyUnbind(alice);

        assertEq(registry.referrer(alice), address(0));
        assertEq(registry.referralCount(bob), 0);
        assertEq(registry.boundAt(alice), 0);
    }

    function testEmergencyUnbind_NonExistent() public {
        // 不应该revert
        registry.emergencyUnbind(alice);

        assertEq(registry.referrer(alice), address(0));
    }

    function testEmergencyUnbind_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.emergencyUnbind(bob);
    }

    // ============================================================================
    // Fuzz 测试
    // ============================================================================

    function testFuzz_Bind(address user, address _referrer) public {
        // 过滤无效输入
        vm.assume(user != address(0));
        vm.assume(_referrer != address(0));
        vm.assume(user != _referrer);
        vm.assume(user != address(this)); // 避免与owner冲突

        vm.prank(user);
        registry.bind(_referrer, 0);

        assertEq(registry.referrer(user), _referrer);
    }

    function testFuzz_AccrueReward(address _referrer, uint128 amount) public {
        vm.assume(_referrer != address(0));

        registry.accrueReferralReward(_referrer, alice, amount);
        assertEq(registry.totalReferralRewards(_referrer), amount);
    }

    function testFuzz_ValidityWindow(uint32 windowDays) public {
        vm.assume(windowDays > 0 && windowDays < 3650); // 1-3650天

        uint256 window = uint256(windowDays) * 1 days;
        registry.setValidityWindow(window);

        vm.prank(alice);
        registry.bind(bob, 0);

        // 在窗口内应该有效
        vm.warp(block.timestamp + window - 1);
        assertTrue(registry.isReferralValid(alice));

        // 超出窗口应该失效
        vm.warp(block.timestamp + 2);
        assertFalse(registry.isReferralValid(alice));
    }
}
