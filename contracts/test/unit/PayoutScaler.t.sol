// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/growth/PayoutScaler.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000e6);
    }
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract PayoutScalerTest is Test {
    PayoutScaler public scaler;
    MockERC20 public usdc;

    address public admin = address(this);
    address public operator = address(0x1);
    address public treasury = address(0x2);

    function setUp() public {
        usdc = new MockERC20();
        scaler = new PayoutScaler(address(usdc), treasury);
        scaler.grantRole(scaler.OPERATOR_ROLE(), operator);

        // 充值预算池
        usdc.approve(address(scaler), type(uint256).max);
        scaler.refillBudget(PayoutScaler.BudgetPool.PROMO, 100_000e6);
    }

    function test_Constructor() public view {
        assertEq(address(scaler.rewardToken()), address(usdc));
        assertEq(scaler.treasury(), treasury);
    }

    function test_RefillBudget() public {
        scaler.refillBudget(PayoutScaler.BudgetPool.CAMPAIGN, 50_000e6);

        (uint256 total, uint256 used, uint256 pending, uint256 available) = 
            scaler.getBudgetStatus(PayoutScaler.BudgetPool.CAMPAIGN);

        assertEq(total, 50_000e6);
        assertEq(used, 0);
        assertEq(available, 50_000e6);
    }

    function test_CalculateScale_SufficientBudget() public {
        vm.prank(operator);
        (uint256 scaleBps, uint256 scaledAmount) = scaler.calculateScale(
            PayoutScaler.BudgetPool.PROMO,
            1,  // week 1
            50_000e6
        );

        assertEq(scaleBps, 10000); // 100%
        assertEq(scaledAmount, 50_000e6);
    }

    function test_CalculateScale_InsufficientBudget() public {
        vm.prank(operator);
        (uint256 scaleBps, uint256 scaledAmount) = scaler.calculateScale(
            PayoutScaler.BudgetPool.PROMO,
            1,
            200_000e6  // 需求超过预算
        );

        // 100k / 200k = 50%
        assertEq(scaleBps, 5000);
        assertEq(scaledAmount, 100_000e6);
    }

    function test_MarkBudgetUsed() public {
        vm.prank(operator);
        scaler.calculateScale(PayoutScaler.BudgetPool.PROMO, 1, 50_000e6);

        vm.prank(operator);
        scaler.markBudgetUsed(PayoutScaler.BudgetPool.PROMO, 1, 50_000e6);

        (uint256 total, uint256 used, uint256 pending, uint256 available) = 
            scaler.getBudgetStatus(PayoutScaler.BudgetPool.PROMO);

        assertEq(used, 50_000e6);
        assertEq(pending, 0);
        assertEq(available, 50_000e6);
    }

    function test_PreviewScale() public view {
        (uint256 scaleBps, uint256 scaledAmount) = scaler.previewScale(
            PayoutScaler.BudgetPool.PROMO,
            50_000e6
        );

        assertEq(scaleBps, 10000);
        assertEq(scaledAmount, 50_000e6);
    }

    function test_GetPeriodScale() public {
        vm.prank(operator);
        scaler.calculateScale(PayoutScaler.BudgetPool.PROMO, 1, 50_000e6);

        uint256 scale = scaler.getPeriodScale(PayoutScaler.BudgetPool.PROMO, 1);
        assertEq(scale, 10000);
    }

    function test_SetAutoScale() public {
        scaler.setAutoScale(PayoutScaler.BudgetPool.PROMO, false);
        assertFalse(scaler.autoScaleEnabled(PayoutScaler.BudgetPool.PROMO));
    }

    function test_SetTreasury() public {
        address newTreasury = address(0x999);
        scaler.setTreasury(newTreasury);
        assertEq(scaler.treasury(), newTreasury);
    }

    function test_RevertWhen_CalculateScaleBudgetExhausted() public {
        // 用完预算
        vm.prank(operator);
        scaler.calculateScale(PayoutScaler.BudgetPool.PROMO, 1, 100_000e6);

        vm.prank(operator);
        scaler.markBudgetUsed(PayoutScaler.BudgetPool.PROMO, 1, 100_000e6);

        // 再次请求应失败
        vm.prank(operator);
        vm.expectRevert(PayoutScaler.BudgetExhausted.selector);
        scaler.calculateScale(PayoutScaler.BudgetPool.PROMO, 2, 50_000e6);
    }

    function test_EmergencyWithdraw() public {
        scaler.emergencyWithdraw(treasury, 10_000e6);
        assertEq(usdc.balanceOf(treasury), 10_000e6);
    }
}
