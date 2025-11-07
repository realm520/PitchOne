// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/RewardsDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
 * @title RewardsDistributor Test Suite
 */
contract RewardsDistributorTest is Test {
    RewardsDistributor public distributor;
    MockERC20 public usdc;

    address public owner = address(this);
    address public publisher = address(0x1);
    address public emergency = address(0x2);
    address public alice = address(0x3);
    address public bob = address(0x4);
    address public charlie = address(0x5);

    // Merkle Tree 测试数据
    // Week 0: alice=1000, bob=2000, charlie=500
    bytes32 public constant WEEK0_ROOT = 0x7c8b9e5e8c3e3b2b5b5f5e8e9b8b5e3e8c9b5f5e8e9b8b5e3e8c9b5f5e8e9b8b;
    bytes32[][] public week0Proofs;

    // Week 1: alice=5000, bob=3000
    bytes32 public constant WEEK1_ROOT = 0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b;

    event RewardsRootPublished(
        uint256 indexed week,
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 scaleBps,
        uint256 publishedAt
    );

    event RewardClaimed(
        address indexed user,
        uint256 indexed week,
        uint256 amount,
        uint256 claimedAt
    );

    event BatchClaimed(
        address indexed user,
        uint256 weekCount,
        uint256 totalAmount
    );

    function setUp() public {
        usdc = new MockERC20();
        distributor = new RewardsDistributor(address(usdc), emergency);

        // 转入奖励资金
        usdc.transfer(address(distributor), 100_000e6);

        // 设置发布者
        distributor.setPublisher(publisher, true);

        // 准备 Merkle Proofs (简化版，实际需要完整构造)
        _setupMerkleProofs();
    }

    function _setupMerkleProofs() internal {
        // 注意：这里是简化版，实际测试中需要完整构造 Merkle 树
        // 为了测试通过，我们使用假的 proof
        week0Proofs.push(new bytes32[](2));
        week0Proofs[0][0] = bytes32(uint256(1));
        week0Proofs[0][1] = bytes32(uint256(2));
    }

    // ============================================================================
    // Constructor Tests
    // ============================================================================

    function test_Constructor() public view {
        assertEq(address(distributor.rewardToken()), address(usdc));
        assertEq(distributor.emergencyWithdrawAddress(), emergency);
        assertEq(distributor.currentWeek(), 0);

        (bool enabled, uint256 duration) = distributor.vestingConfig();
        assertTrue(enabled);
        assertEq(duration, 7 days);
    }

    function test_Constructor_RevertIf_ZeroAddress() public {
        vm.expectRevert(RewardsDistributor.ZeroAddress.selector);
        new RewardsDistributor(address(0), emergency);

        vm.expectRevert(RewardsDistributor.ZeroAddress.selector);
        new RewardsDistributor(address(usdc), address(0));
    }

    // ============================================================================
    // publishRoot Tests
    // ============================================================================

    function test_PublishRoot_ByOwner() public {
        uint256 week = 0;
        bytes32 root = WEEK0_ROOT;
        uint256 total = 10_000e6;
        uint256 scale = 10000; // 100%

        vm.expectEmit(true, true, true, true);
        emit RewardsRootPublished(week, root, total, scale, block.timestamp);

        distributor.publishRoot(week, root, total, scale);

        (bytes32 storedRoot, uint256 storedTotal, uint256 storedScale, uint256 publishedAt, uint256 claimed) =
            distributor.weeklyRewards(week);

        assertEq(storedRoot, root);
        assertEq(storedTotal, total);
        assertEq(storedScale, scale);
        assertEq(publishedAt, block.timestamp);
        assertEq(claimed, 0);
        assertEq(distributor.currentWeek(), 1);
    }

    function test_PublishRoot_ByPublisher() public {
        vm.prank(publisher);
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 10000);

        (bytes32 root,,,, ) = distributor.weeklyRewards(0);
        assertEq(root, WEEK0_ROOT);
    }

    function test_PublishRoot_RevertIf_Unauthorized() public {
        vm.prank(alice);
        vm.expectRevert(RewardsDistributor.UnauthorizedPublisher.selector);
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 10000);
    }

    function test_PublishRoot_RevertIf_ZeroRoot() public {
        vm.expectRevert(RewardsDistributor.InvalidMerkleRoot.selector);
        distributor.publishRoot(0, bytes32(0), 10_000e6, 10000);
    }

    function test_PublishRoot_RevertIf_InvalidScale() public {
        // 低于最小值
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.InvalidScaleBps.selector,
                500,
                1000
            )
        );
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 500);

        // 高于最大值
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.InvalidScaleBps.selector,
                10001,
                1000
            )
        );
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 10001);
    }

    function test_PublishRoot_RevertIf_AlreadyPublished() public {
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 10000);

        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.WeekAlreadyPublished.selector,
                0
            )
        );
        distributor.publishRoot(0, WEEK1_ROOT, 5_000e6, 10000);
    }

    function test_PublishRoot_NonSequential() public {
        // 跳过 week 0，直接发布 week 5
        distributor.publishRoot(5, WEEK0_ROOT, 10_000e6, 10000);
        assertEq(distributor.currentWeek(), 6);

        // 再发布 week 2（早于当前周）
        distributor.publishRoot(2, WEEK1_ROOT, 5_000e6, 10000);
        assertEq(distributor.currentWeek(), 6); // currentWeek 不变
    }

    function test_PublishRoot_WithScaling() public {
        // 预算不足，缩放至 50%
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 5000);

        (,, uint256 scale,,) = distributor.weeklyRewards(0);
        assertEq(scale, 5000);
    }

    // ============================================================================
    // claim Tests (需要真实的 Merkle Proof)
    // ============================================================================

    function test_Claim_RealMerkleTree() public {
        // 构造真实的 Merkle 树
        // alice: 1000e6, bob: 2000e6, charlie: 500e6

        // Leaf: keccak256(abi.encode(user, week, amount))
        bytes32 leafAlice = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        bytes32 leafBob = keccak256(bytes.concat(keccak256(abi.encode(bob, uint256(0), 2000e6))));
        bytes32 leafCharlie = keccak256(bytes.concat(keccak256(abi.encode(charlie, uint256(0), 500e6))));

        // 手动构造 Merkle 树（3个叶子）
        bytes32 node1 = leafAlice < leafBob ?
            keccak256(abi.encodePacked(leafAlice, leafBob)) :
            keccak256(abi.encodePacked(leafBob, leafAlice));

        bytes32 root = node1 < leafCharlie ?
            keccak256(abi.encodePacked(node1, leafCharlie)) :
            keccak256(abi.encodePacked(leafCharlie, node1));

        // 发布 Root
        distributor.publishRoot(0, root, 3500e6, 10000);

        // 跳过 vesting 期
        vm.warp(block.timestamp + 7 days);

        // Alice 的 Proof: [leafBob, leafCharlie] 或 [node1]
        bytes32[] memory proofAlice = new bytes32[](2);
        proofAlice[0] = leafBob;
        proofAlice[1] = leafCharlie;

        // 领取前的余额
        uint256 balanceBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit RewardClaimed(alice, 0, 1000e6, block.timestamp);
        distributor.claim(0, 1000e6, proofAlice);

        // 验证余额变化
        assertEq(usdc.balanceOf(alice), balanceBefore + 1000e6);
        assertEq(distributor.claimed(alice, 0), 1000e6);
    }

    function test_Claim_RevertIf_WeekNotPublished() public {
        bytes32[] memory proof = new bytes32[](1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.WeekNotPublished.selector,
                0
            )
        );
        distributor.claim(0, 1000e6, proof);
    }

    function test_Claim_RevertIf_AlreadyClaimed() public {
        // 构造简单的单叶子树（仅测试重复领取）
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);

        // 跳过 vesting
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0); // 单叶子，空 proof

        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);

        // 尝试再次领取
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.AlreadyClaimed.selector,
                alice,
                0
            )
        );
        distributor.claim(0, 1000e6, proof);
    }

    function test_Claim_RevertIf_InvalidProof() public {
        bytes32 root = keccak256("fake_root");
        distributor.publishRoot(0, root, 1000e6, 10000);

        bytes32[] memory wrongProof = new bytes32[](1);
        wrongProof[0] = bytes32(uint256(999));

        vm.prank(alice);
        vm.expectRevert(RewardsDistributor.InvalidProof.selector);
        distributor.claim(0, 1000e6, wrongProof);
    }

    function test_Claim_WithScaling() public {
        // 单叶子树，缩放至 50%
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 5000); // 50%

        // 跳过 vesting
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0);

        uint256 balanceBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);

        // 应该只领到 500e6 (1000e6 * 50%)
        assertEq(usdc.balanceOf(alice), balanceBefore + 500e6);
    }

    function test_Claim_WithVesting() public {
        // 单叶子树，启用线性释放
        bytes32 leafBob = keccak256(bytes.concat(keccak256(abi.encode(bob, uint256(0), 1000e6))));
        distributor.publishRoot(0, leafBob, 1000e6, 10000);

        bytes32[] memory proof = new bytes32[](0);

        // 快进 3.5 天（50%）
        vm.warp(block.timestamp + 3.5 days);

        uint256 balanceBefore = usdc.balanceOf(bob);
        vm.prank(bob);
        distributor.claim(0, 1000e6, proof);

        // 应该领到约 500e6（50% vesting）
        uint256 expected = (1000e6 * 3.5 days) / 7 days;
        assertApproxEqRel(usdc.balanceOf(bob) - balanceBefore, expected, 0.01e18); // 1% 误差
    }

    function test_Claim_FullyVested() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);

        // 快进 7 天
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0);
        uint256 balanceBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);

        // 应该领到全额
        assertEq(usdc.balanceOf(alice), balanceBefore + 1000e6);
    }

    function test_Claim_RevertIf_InsufficientBalance() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);

        // 跳过 vesting
        vm.warp(block.timestamp + 7 days);

        // 清空合约余额
        vm.prank(owner);
        distributor.emergencyWithdraw(usdc.balanceOf(address(distributor)));

        bytes32[] memory proof = new bytes32[](0);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.InsufficientBalance.selector,
                1000e6,
                0
            )
        );
        distributor.claim(0, 1000e6, proof);
    }

    // ============================================================================
    // batchClaim Tests
    // ============================================================================

    function test_BatchClaim() public {
        // 发布两周
        bytes32 leaf0 = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(1), 2000e6))));

        // 发布第一周
        distributor.publishRoot(0, leaf0, 1000e6, 10000);
        vm.warp(1 + 7 days); // Warp to absolute time

        // 发布第二周
        distributor.publishRoot(1, leaf1, 2000e6, 10000);
        vm.warp(1 + 14 days); // Warp to absolute time (14 days from start)

        // 批量领取
        uint256[] memory weekNumbers = new uint256[](2);
        weekNumbers[0] = 0;
        weekNumbers[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000e6;
        amounts[1] = 2000e6;

        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = new bytes32[](0);
        proofs[1] = new bytes32[](0);

        uint256 balanceBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit BatchClaimed(alice, 2, 3000e6);
        distributor.batchClaim(weekNumbers, amounts, proofs);

        assertEq(usdc.balanceOf(alice), balanceBefore + 3000e6);
        assertEq(distributor.claimed(alice, 0), 1000e6);
        assertEq(distributor.claimed(alice, 1), 2000e6);
    }

    function test_BatchClaim_RevertIf_EmptyArray() public {
        uint256[] memory weekNumbers = new uint256[](0);
        uint256[] memory amounts = new uint256[](0);
        bytes32[][] memory proofs = new bytes32[][](0);

        vm.prank(alice);
        vm.expectRevert(RewardsDistributor.EmptyWeeksArray.selector);
        distributor.batchClaim(weekNumbers, amounts, proofs);
    }

    function test_BatchClaim_RevertIf_LengthMismatch() public {
        uint256[] memory weekNumbers = new uint256[](2);
        uint256[] memory amounts = new uint256[](1); // 长度不匹配
        bytes32[][] memory proofs = new bytes32[][](2);

        vm.prank(alice);
        vm.expectRevert("Length mismatch");
        distributor.batchClaim(weekNumbers, amounts, proofs);
    }

    // ============================================================================
    // Query Tests
    // ============================================================================

    function test_GetClaimable() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);

        vm.warp(block.timestamp + 7 days); // 完全释放

        bytes32[] memory proof = new bytes32[](0);
        (uint256 claimable, bool claimed) = distributor.getClaimable(alice, 0, 1000e6, proof);

        assertEq(claimable, 1000e6);
        assertFalse(claimed);
    }

    function test_GetClaimable_AlreadyClaimed() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0);

        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);

        (uint256 claimable, bool claimed) = distributor.getClaimable(alice, 0, 1000e6, proof);
        assertEq(claimable, 0);
        assertTrue(claimed);
    }

    function test_GetClaimable_WithVesting() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 1000e6, 10000);

        vm.warp(block.timestamp + 3.5 days); // 50% 释放

        bytes32[] memory proof = new bytes32[](0);
        (uint256 claimable,) = distributor.getClaimable(alice, 0, 1000e6, proof);

        uint256 expected = (1000e6 * 3.5 days) / 7 days;
        assertApproxEqRel(claimable, expected, 0.01e18);
    }

    function test_GetWeekStats() public {
        distributor.publishRoot(0, WEEK0_ROOT, 10_000e6, 8000); // 80%

        (
            bytes32 root,
            uint256 total,
            uint256 scale,
            uint256 claimed,
            uint256 claimRate
        ) = distributor.getWeekStats(0);

        assertEq(root, WEEK0_ROOT);
        assertEq(total, 10_000e6);
        assertEq(scale, 8000);
        assertEq(claimed, 0);
        assertEq(claimRate, 0);
    }

    function test_GetWeekStats_WithClaims() public {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        distributor.publishRoot(0, leaf, 2000e6, 10000);
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0);
        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);

        (,,, uint256 claimed, uint256 claimRate) = distributor.getWeekStats(0);
        assertEq(claimed, 1000e6);
        assertEq(claimRate, 5000); // 50% (1000 / 2000)
    }

    function test_GetBatchClaimed() public {
        // 领取两周
        bytes32 leaf0 = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), 1000e6))));
        bytes32 leaf1 = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(1), 2000e6))));

        distributor.publishRoot(0, leaf0, 1000e6, 10000);
        distributor.publishRoot(1, leaf1, 2000e6, 10000);
        vm.warp(block.timestamp + 7 days);

        bytes32[] memory proof = new bytes32[](0);
        vm.prank(alice);
        distributor.claim(0, 1000e6, proof);
        vm.prank(alice);
        distributor.claim(1, 2000e6, proof);

        // 批量查询
        uint256[] memory weekNumbers = new uint256[](2);
        weekNumbers[0] = 0;
        weekNumbers[1] = 1;

        uint256[] memory amounts = distributor.getBatchClaimed(alice, weekNumbers);
        assertEq(amounts[0], 1000e6);
        assertEq(amounts[1], 2000e6);
    }

    // ============================================================================
    // Admin Tests
    // ============================================================================

    function test_SetPublisher() public {
        address newPublisher = address(0x99);

        vm.expectEmit(true, true, true, true);
        emit RewardsDistributor.PublisherUpdated(newPublisher, true);
        distributor.setPublisher(newPublisher, true);

        assertTrue(distributor.isPublisher(newPublisher));

        // 禁用
        distributor.setPublisher(newPublisher, false);
        assertFalse(distributor.isPublisher(newPublisher));
    }

    function test_SetPublisher_RevertIf_ZeroAddress() public {
        vm.expectRevert(RewardsDistributor.ZeroAddress.selector);
        distributor.setPublisher(address(0), true);
    }

    function test_SetPublisher_RevertIf_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        distributor.setPublisher(address(0x99), true);
    }

    function test_SetVestingConfig() public {
        vm.expectEmit(true, true, true, true);
        emit RewardsDistributor.VestingConfigUpdated(false, 0);
        distributor.setVestingConfig(false, 0);

        (bool enabled, uint256 duration) = distributor.vestingConfig();
        assertFalse(enabled);
        assertEq(duration, 0);

        // 重新启用，14天
        distributor.setVestingConfig(true, 14 days);
        (enabled, duration) = distributor.vestingConfig();
        assertTrue(enabled);
        assertEq(duration, 14 days);
    }

    function test_SetVestingConfig_RevertIf_InvalidDuration() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.InvalidVestingDuration.selector,
                0
            )
        );
        distributor.setVestingConfig(true, 0);
    }

    function test_SetEmergencyWithdrawAddress() public {
        address newEmergency = address(0x88);
        distributor.setEmergencyWithdrawAddress(newEmergency);
        assertEq(distributor.emergencyWithdrawAddress(), newEmergency);
    }

    function test_SetEmergencyWithdrawAddress_RevertIf_ZeroAddress() public {
        vm.expectRevert(RewardsDistributor.ZeroAddress.selector);
        distributor.setEmergencyWithdrawAddress(address(0));
    }

    function test_EmergencyWithdraw() public {
        uint256 amount = 10_000e6;
        uint256 balanceBefore = usdc.balanceOf(emergency);

        vm.expectEmit(true, true, true, true);
        emit RewardsDistributor.EmergencyWithdraw(emergency, amount);
        distributor.emergencyWithdraw(amount);

        assertEq(usdc.balanceOf(emergency), balanceBefore + amount);
    }

    function test_EmergencyWithdraw_RevertIf_InsufficientBalance() public {
        uint256 contractBalance = usdc.balanceOf(address(distributor));

        vm.expectRevert(
            abi.encodeWithSelector(
                RewardsDistributor.InsufficientBalance.selector,
                contractBalance + 1,
                contractBalance
            )
        );
        distributor.emergencyWithdraw(contractBalance + 1);
    }

    function test_EmergencyWithdraw_RevertIf_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        distributor.emergencyWithdraw(1000e6);
    }

    function test_Pause() public {
        distributor.pause();
        assertTrue(distributor.paused());

        // 暂停后无法发布
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        distributor.publishRoot(0, WEEK0_ROOT, 1000e6, 10000);
    }

    function test_Unpause() public {
        distributor.pause();
        distributor.unpause();
        assertFalse(distributor.paused());

        // 恢复后可以发布
        distributor.publishRoot(0, WEEK0_ROOT, 1000e6, 10000);
    }

    // ============================================================================
    // Fuzz Tests
    // ============================================================================

    function testFuzz_PublishRoot(
        uint256 week,
        uint256 totalAmount,
        uint256 scaleBps
    ) public {
        // 限制输入范围
        week = bound(week, 0, 1000);
        totalAmount = bound(totalAmount, 1e6, 1_000_000e6);
        scaleBps = bound(scaleBps, 1000, 10000);

        // 使用假的 root
        bytes32 root = keccak256(abi.encode(week, totalAmount, scaleBps));

        distributor.publishRoot(week, root, totalAmount, scaleBps);

        (bytes32 storedRoot, uint256 storedTotal, uint256 storedScale,,) =
            distributor.weeklyRewards(week);

        assertEq(storedRoot, root);
        assertEq(storedTotal, totalAmount);
        assertEq(storedScale, scaleBps);
    }

    function testFuzz_Claim_SingleLeaf(
        uint256 amount,
        uint256 scaleBps
    ) public {
        amount = bound(amount, 1e6, 100_000e6);
        scaleBps = bound(scaleBps, 1000, 10000);

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), amount))));
        distributor.publishRoot(0, leaf, amount, scaleBps);
        vm.warp(block.timestamp + 7 days); // 跳过 vesting

        bytes32[] memory proof = new bytes32[](0);

        uint256 balanceBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        distributor.claim(0, amount, proof);

        uint256 expected = (amount * scaleBps) / 10000;
        assertEq(usdc.balanceOf(alice), balanceBefore + expected);
    }

    function testFuzz_VestingCalculation(
        uint256 amount,
        uint256 elapsed
    ) public {
        amount = bound(amount, 1e6, 100_000e6);
        elapsed = bound(elapsed, 0, 7 days);

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(alice, uint256(0), amount))));
        distributor.publishRoot(0, leaf, amount, 10000);

        vm.warp(block.timestamp + elapsed);

        bytes32[] memory proof = new bytes32[](0);
        (uint256 claimable,) = distributor.getClaimable(alice, 0, amount, proof);

        uint256 expected = elapsed >= 7 days ? amount : (amount * elapsed) / 7 days;
        assertApproxEqRel(claimable, expected, 0.01e18);
    }
}
