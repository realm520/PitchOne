// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/core/FeeRouter.sol";

/**
 * @title FeeRouterTest
 * @notice 测试 FeeRouter 合约的费用路由和分配功能
 * @dev Phase 0 版本：所有费用发往单一国库地址
 */
contract FeeRouterTest is BaseTest {
    FeeRouter public router;

    // 测试地址
    address public newTreasury;

    // 事件定义（用于测试）
    event FeeReceived(address indexed token, address indexed from, uint256 amount);
    event FeeDistributed(
        address indexed token,
        address indexed recipient,
        uint256 amount,
        string category
    );

    function setUp() public override {
        super.setUp();

        // FeeRouter 已在 BaseTest 中创建
        router = feeRouter;
        newTreasury = makeAddr("newTreasury");

        vm.label(address(router), "FeeRouter");
        vm.label(newTreasury, "NewTreasury");
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsTreasury() public view {
        assertEq(router.treasury(), treasury, "Treasury should be set");
    }

    function test_Constructor_SetsOwner() public view {
        assertEq(router.owner(), owner, "Owner should be deployer");
    }

    function test_Constructor_RevertIf_ZeroTreasury() public {
        vm.expectRevert("FeeRouter: Invalid treasury");
        new FeeRouter(address(0));
    }

    // ============ Receive ETH Tests ============

    function test_Receive_ETH() public {
        uint256 amount = 1 ether;

        // 期望事件
        vm.expectEmit(true, true, false, true);
        emit FeeReceived(address(0), address(this), amount);

        // 发送 ETH
        (bool success, ) = address(router).call{value: amount}("");
        assertTrue(success, "ETH transfer should succeed");

        // 验证余额
        assertEq(address(router).balance, amount, "Router should have ETH");
    }

    function test_Receive_MultipleETHDeposits() public {
        uint256 amount1 = 1 ether;
        uint256 amount2 = 2 ether;

        // 第一次存入
        (bool success1, ) = address(router).call{value: amount1}("");
        assertTrue(success1, "First ETH transfer should succeed");

        // 第二次存入
        (bool success2, ) = address(router).call{value: amount2}("");
        assertTrue(success2, "Second ETH transfer should succeed");

        // 验证总余额
        assertEq(
            address(router).balance,
            amount1 + amount2,
            "Router should have total ETH"
        );
    }

    // ============ DistributeFees Tests (ERC20) ============

    function test_DistributeFees_ERC20() public {
        uint256 amount = 1000e6; // 1000 USDC

        // 给 FeeRouter 转入 USDC
        usdc.mint(address(router), amount);

        uint256 treasuryBalanceBefore = usdc.balanceOf(treasury);

        // 期望事件
        vm.expectEmit(true, true, false, true);
        emit FeeDistributed(address(usdc), treasury, amount, "treasury");

        // 分配费用
        router.distributeFees(address(usdc));

        // 验证余额
        assertEq(
            usdc.balanceOf(address(router)),
            0,
            "Router should have no USDC left"
        );
        assertEq(
            usdc.balanceOf(treasury),
            treasuryBalanceBefore + amount,
            "Treasury should receive USDC"
        );
    }

    function test_DistributeFees_ERC20_MultipleDistributions() public {
        uint256 amount1 = 500e6;
        uint256 amount2 = 300e6;

        // 第一次分配
        usdc.mint(address(router), amount1);
        router.distributeFees(address(usdc));

        uint256 treasuryAfterFirst = usdc.balanceOf(treasury);

        // 第二次分配
        usdc.mint(address(router), amount2);
        router.distributeFees(address(usdc));

        // 验证总额
        assertEq(
            usdc.balanceOf(treasury),
            treasuryAfterFirst + amount2,
            "Treasury should receive all fees"
        );
    }

    function test_DistributeFees_ERC20_RevertIf_NoBalance() public {
        vm.expectRevert("FeeRouter: No tokens to distribute");
        router.distributeFees(address(usdc));
    }

    function test_DistributeFees_ERC20_RevertIf_NotOwner() public {
        usdc.mint(address(router), 100e6);

        vm.prank(user1);
        vm.expectRevert();
        router.distributeFees(address(usdc));
    }

    // ============ DistributeFees Tests (ETH) ============

    function test_DistributeFees_ETH() public {
        uint256 amount = 5 ether;

        // 发送 ETH 到 FeeRouter
        vm.deal(address(router), amount);

        uint256 treasuryBalanceBefore = treasury.balance;

        // 期望事件
        vm.expectEmit(true, true, false, true);
        emit FeeDistributed(address(0), treasury, amount, "treasury");

        // 分配费用
        router.distributeFees(address(0));

        // 验证余额
        assertEq(
            address(router).balance,
            0,
            "Router should have no ETH left"
        );
        assertEq(
            treasury.balance,
            treasuryBalanceBefore + amount,
            "Treasury should receive ETH"
        );
    }

    function test_DistributeFees_ETH_RevertIf_NoBalance() public {
        vm.expectRevert("FeeRouter: No ETH to distribute");
        router.distributeFees(address(0));
    }

    function test_DistributeFees_ETH_RevertIf_NotOwner() public {
        vm.deal(address(router), 1 ether);

        vm.prank(user1);
        vm.expectRevert();
        router.distributeFees(address(0));
    }

    // ============ SetTreasury Tests ============

    function test_SetTreasury_Success() public {
        router.setTreasury(newTreasury);
        assertEq(router.treasury(), newTreasury, "Treasury should be updated");
    }

    function test_SetTreasury_RevertIf_ZeroAddress() public {
        vm.expectRevert("FeeRouter: Invalid treasury");
        router.setTreasury(address(0));
    }

    function test_SetTreasury_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        router.setTreasury(newTreasury);
    }

    function test_SetTreasury_AffectsDistribution() public {
        uint256 amount = 1000e6;

        // 更新国库地址
        router.setTreasury(newTreasury);

        // 分配费用
        usdc.mint(address(router), amount);
        router.distributeFees(address(usdc));

        // 验证新国库收到费用
        assertEq(
            usdc.balanceOf(newTreasury),
            amount,
            "New treasury should receive fees"
        );
        assertEq(
            usdc.balanceOf(treasury),
            0,
            "Old treasury should not receive fees"
        );
    }

    // ============ EmergencyWithdraw Tests (ERC20) ============

    function test_EmergencyWithdraw_ERC20() public {
        uint256 amount = 500e6;
        address recipient = makeAddr("recipient");

        usdc.mint(address(router), amount);

        uint256 recipientBalanceBefore = usdc.balanceOf(recipient);

        // 紧急提取
        router.emergencyWithdraw(address(usdc), recipient, amount);

        // 验证余额
        assertEq(
            usdc.balanceOf(address(router)),
            0,
            "Router should have no USDC left"
        );
        assertEq(
            usdc.balanceOf(recipient),
            recipientBalanceBefore + amount,
            "Recipient should receive USDC"
        );
    }

    function test_EmergencyWithdraw_ERC20_PartialAmount() public {
        uint256 totalAmount = 1000e6;
        uint256 withdrawAmount = 300e6;
        address recipient = makeAddr("recipient");

        usdc.mint(address(router), totalAmount);

        // 提取部分金额
        router.emergencyWithdraw(address(usdc), recipient, withdrawAmount);

        // 验证余额
        assertEq(
            usdc.balanceOf(address(router)),
            totalAmount - withdrawAmount,
            "Router should have remaining USDC"
        );
        assertEq(
            usdc.balanceOf(recipient),
            withdrawAmount,
            "Recipient should receive partial amount"
        );
    }

    function test_EmergencyWithdraw_ERC20_RevertIf_ZeroAddress() public {
        usdc.mint(address(router), 100e6);

        vm.expectRevert("FeeRouter: Invalid address");
        router.emergencyWithdraw(address(usdc), address(0), 100e6);
    }

    function test_EmergencyWithdraw_ERC20_RevertIf_NotOwner() public {
        usdc.mint(address(router), 100e6);

        vm.prank(user1);
        vm.expectRevert();
        router.emergencyWithdraw(address(usdc), user1, 100e6);
    }

    // ============ EmergencyWithdraw Tests (ETH) ============

    function test_EmergencyWithdraw_ETH() public {
        uint256 amount = 3 ether;
        address recipient = makeAddr("recipient");

        vm.deal(address(router), amount);

        uint256 recipientBalanceBefore = recipient.balance;

        // 紧急提取
        router.emergencyWithdraw(address(0), recipient, amount);

        // 验证余额
        assertEq(
            address(router).balance,
            0,
            "Router should have no ETH left"
        );
        assertEq(
            recipient.balance,
            recipientBalanceBefore + amount,
            "Recipient should receive ETH"
        );
    }

    function test_EmergencyWithdraw_ETH_PartialAmount() public {
        uint256 totalAmount = 10 ether;
        uint256 withdrawAmount = 3 ether;
        address recipient = makeAddr("recipient");

        vm.deal(address(router), totalAmount);

        // 提取部分金额
        router.emergencyWithdraw(address(0), recipient, withdrawAmount);

        // 验证余额
        assertEq(
            address(router).balance,
            totalAmount - withdrawAmount,
            "Router should have remaining ETH"
        );
        assertEq(
            recipient.balance,
            withdrawAmount,
            "Recipient should receive partial amount"
        );
    }

    function test_EmergencyWithdraw_ETH_RevertIf_ZeroAddress() public {
        vm.deal(address(router), 1 ether);

        vm.expectRevert("FeeRouter: Invalid address");
        router.emergencyWithdraw(address(0), address(0), 1 ether);
    }

    function test_EmergencyWithdraw_ETH_RevertIf_NotOwner() public {
        vm.deal(address(router), 1 ether);

        vm.prank(user1);
        vm.expectRevert();
        router.emergencyWithdraw(address(0), user1, 1 ether);
    }

    // ============ Integration Tests ============

    function test_FullFlow_ReceiveAndDistributeERC20() public {
        uint256 fee1 = 100e6;
        uint256 fee2 = 200e6;
        uint256 fee3 = 150e6;

        // 模拟多个市场发送费用
        usdc.mint(address(router), fee1);
        usdc.mint(address(router), fee2);
        usdc.mint(address(router), fee3);

        uint256 totalFees = fee1 + fee2 + fee3;

        // 分配所有费用
        router.distributeFees(address(usdc));

        // 验证国库收到所有费用
        assertEq(
            usdc.balanceOf(treasury),
            totalFees,
            "Treasury should receive all fees"
        );
        assertEq(
            usdc.balanceOf(address(router)),
            0,
            "Router should be empty"
        );
    }

    function test_FullFlow_ReceiveAndDistributeETH() public {
        uint256 fee1 = 1 ether;
        uint256 fee2 = 2 ether;

        // 发送 ETH
        (bool success1, ) = address(router).call{value: fee1}("");
        assertTrue(success1, "First ETH transfer should succeed");

        (bool success2, ) = address(router).call{value: fee2}("");
        assertTrue(success2, "Second ETH transfer should succeed");

        uint256 totalFees = fee1 + fee2;

        // 分配所有费用
        router.distributeFees(address(0));

        // 验证国库收到所有费用
        assertEq(
            treasury.balance,
            totalFees,
            "Treasury should receive all ETH"
        );
        assertEq(
            address(router).balance,
            0,
            "Router should be empty"
        );
    }

    function test_MixedTokens_IndependentBalances() public {
        uint256 usdcAmount = 500e6;
        uint256 ethAmount = 2 ether;

        // 发送 USDC 和 ETH
        usdc.mint(address(router), usdcAmount);
        vm.deal(address(router), ethAmount);

        // 分别分配
        router.distributeFees(address(usdc));
        router.distributeFees(address(0));

        // 验证两种资产都正确分配
        assertEq(
            usdc.balanceOf(treasury),
            usdcAmount,
            "Treasury should receive USDC"
        );
        assertEq(
            treasury.balance,
            ethAmount,
            "Treasury should receive ETH"
        );
    }

    // ============ Edge Cases ============

    function test_DistributeFees_AfterTreasuryChange() public {
        uint256 amount = 1000e6;

        // 第一次分配（旧国库）
        usdc.mint(address(router), amount);
        router.distributeFees(address(usdc));

        uint256 oldTreasuryBalance = usdc.balanceOf(treasury);

        // 更换国库
        router.setTreasury(newTreasury);

        // 第二次分配（新国库）
        usdc.mint(address(router), amount);
        router.distributeFees(address(usdc));

        // 验证两个国库的余额
        assertEq(
            usdc.balanceOf(treasury),
            oldTreasuryBalance,
            "Old treasury balance unchanged"
        );
        assertEq(
            usdc.balanceOf(newTreasury),
            amount,
            "New treasury should receive fees"
        );
    }

    function test_MultipleEmergencyWithdrawals() public {
        uint256 totalAmount = 1000e6;
        address recipient1 = makeAddr("recipient1");
        address recipient2 = makeAddr("recipient2");

        usdc.mint(address(router), totalAmount);

        // 两次紧急提取
        router.emergencyWithdraw(address(usdc), recipient1, 400e6);
        router.emergencyWithdraw(address(usdc), recipient2, 300e6);

        // 验证余额
        assertEq(usdc.balanceOf(recipient1), 400e6, "Recipient1 balance");
        assertEq(usdc.balanceOf(recipient2), 300e6, "Recipient2 balance");
        assertEq(
            usdc.balanceOf(address(router)),
            300e6,
            "Router remaining balance"
        );
    }

    // 接收 ETH 的辅助函数
    receive() external payable {}
}
