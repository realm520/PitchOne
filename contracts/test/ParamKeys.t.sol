// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ParamController} from "../src/governance/ParamController.sol";
import {ParamKeys} from "../src/governance/ParamKeys.sol";
import {RangeValidator} from "../src/governance/RangeValidator.sol";

/**
 * @title ParamKeysTest
 * @notice 测试 ParamKeys 库和 RangeValidator 合约
 */
contract ParamKeysTest is Test {
    ParamController public controller;
    RangeValidator public validator;

    address public admin = address(this);
    address public proposer = address(0x1);
    address public executor = address(0x2);

    uint256 public constant DEFAULT_TIMELOCK = 2 days;

    function setUp() public {
        // 部署验证器
        validator = new RangeValidator(admin);

        // 部署参数控制器
        controller = new ParamController(admin, DEFAULT_TIMELOCK);

        // 授予角色
        controller.grantRole(controller.PROPOSER_ROLE(), proposer);
        controller.grantRole(controller.EXECUTOR_ROLE(), executor);
    }

    /*//////////////////////////////////////////////////////////////
                          PARAM KEYS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ParamKeys_Constants() public pure {
        // 验证键值不为空且唯一
        assertTrue(ParamKeys.FEE_RATE != bytes32(0));
        assertTrue(ParamKeys.FEE_LP_SHARE_BPS != bytes32(0));
        assertTrue(ParamKeys.FEE_PROMO_SHARE_BPS != bytes32(0));
        assertTrue(ParamKeys.FEE_INSURANCE_SHARE_BPS != bytes32(0));
        assertTrue(ParamKeys.FEE_TREASURY_SHARE_BPS != bytes32(0));
        assertTrue(ParamKeys.MIN_BET_AMOUNT != bytes32(0));
        assertTrue(ParamKeys.MAX_BET_AMOUNT != bytes32(0));
        assertTrue(ParamKeys.USER_EXPOSURE_LIMIT != bytes32(0));
        assertTrue(ParamKeys.MARKET_PAYOUT_CAP != bytes32(0));
        assertTrue(ParamKeys.MAX_ODDS != bytes32(0));
        assertTrue(ParamKeys.MIN_ODDS != bytes32(0));
        assertTrue(ParamKeys.DISPUTE_WINDOW != bytes32(0));

        // 验证所有键值唯一
        bytes32[] memory keys = ParamKeys.getAllKeys();
        for (uint256 i = 0; i < keys.length; i++) {
            for (uint256 j = i + 1; j < keys.length; j++) {
                assertTrue(keys[i] != keys[j], "Duplicate key found");
            }
        }
    }

    function test_ParamKeys_GetAllKeys() public pure {
        bytes32[] memory keys = ParamKeys.getAllKeys();
        assertEq(keys.length, 12);
        assertEq(keys[0], ParamKeys.FEE_RATE);
        assertEq(keys[1], ParamKeys.FEE_LP_SHARE_BPS);
        assertEq(keys[2], ParamKeys.FEE_PROMO_SHARE_BPS);
        assertEq(keys[3], ParamKeys.FEE_INSURANCE_SHARE_BPS);
        assertEq(keys[4], ParamKeys.FEE_TREASURY_SHARE_BPS);
        assertEq(keys[5], ParamKeys.MIN_BET_AMOUNT);
        assertEq(keys[6], ParamKeys.MAX_BET_AMOUNT);
        assertEq(keys[7], ParamKeys.USER_EXPOSURE_LIMIT);
        assertEq(keys[8], ParamKeys.MARKET_PAYOUT_CAP);
        assertEq(keys[9], ParamKeys.MAX_ODDS);
        assertEq(keys[10], ParamKeys.MIN_ODDS);
        assertEq(keys[11], ParamKeys.DISPUTE_WINDOW);
    }

    function test_ParamKeys_GetDefaultValues() public pure {
        uint256[] memory values = ParamKeys.getDefaultValues();
        assertEq(values.length, 12);
        assertEq(values[0], 200);                    // FEE_RATE: 2.00%
        assertEq(values[1], 6000);                   // FEE_LP_SHARE_BPS: 60.00%
        assertEq(values[2], 2000);                   // FEE_PROMO_SHARE_BPS: 20.00%
        assertEq(values[3], 1000);                   // FEE_INSURANCE_SHARE_BPS: 10.00%
        assertEq(values[4], 1000);                   // FEE_TREASURY_SHARE_BPS: 10.00%
        assertEq(values[5], 1_000_000);              // MIN_BET_AMOUNT: 1 USDC
        assertEq(values[6], 5_000_000);              // MAX_BET_AMOUNT: 5 USDC
        assertEq(values[7], 50_000_000_000);         // USER_EXPOSURE_LIMIT: 50,000 USDC
        assertEq(values[8], 10_000_000_000_000);     // MARKET_PAYOUT_CAP: 10,000,000 USDC
        assertEq(values[9], 10_000_000);             // MAX_ODDS: 1000x
        assertEq(values[10], 10_000);                // MIN_ODDS: 1.0x
        assertEq(values[11], 7200);                  // DISPUTE_WINDOW: 2 小时
    }

    function test_ParamKeys_ValidRanges() public pure {
        // FEE_RATE: 0-10%
        (uint256 min, uint256 max) = ParamKeys.getValidRange(ParamKeys.FEE_RATE);
        assertEq(min, 0);
        assertEq(max, 1000);

        // FEE_LP_SHARE_BPS: 0-100%
        (min, max) = ParamKeys.getValidRange(ParamKeys.FEE_LP_SHARE_BPS);
        assertEq(min, 0);
        assertEq(max, 10000);

        // MIN_BET_AMOUNT: 0.1 - 100 USDC
        (min, max) = ParamKeys.getValidRange(ParamKeys.MIN_BET_AMOUNT);
        assertEq(min, 100_000);
        assertEq(max, 100_000_000);

        // MAX_ODDS: 1.01x - 10000x
        (min, max) = ParamKeys.getValidRange(ParamKeys.MAX_ODDS);
        assertEq(min, 10_100);
        assertEq(max, 100_000_000);

        // DISPUTE_WINDOW: 30 分钟 - 7 天
        (min, max) = ParamKeys.getValidRange(ParamKeys.DISPUTE_WINDOW);
        assertEq(min, 1800);
        assertEq(max, 604800);
    }

    function test_ParamKeys_FeeSplitSumTo100() public pure {
        uint256[] memory values = ParamKeys.getDefaultValues();
        // 验证费用分成总和为 10000 (100%)
        uint256 feeSplitSum = values[1] + values[2] + values[3] + values[4];
        assertEq(feeSplitSum, 10000, "Fee split should sum to 100%");
    }

    /*//////////////////////////////////////////////////////////////
                       RANGE VALIDATOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RangeValidator_ValidateDefaultRanges() public view {
        // 在默认范围内
        assertTrue(validator.validate(ParamKeys.FEE_RATE, 200));
        assertTrue(validator.validate(ParamKeys.FEE_RATE, 0));
        assertTrue(validator.validate(ParamKeys.FEE_RATE, 1000));

        // 超出默认范围
        assertFalse(validator.validate(ParamKeys.FEE_RATE, 1001));

        // MIN_BET_AMOUNT
        assertTrue(validator.validate(ParamKeys.MIN_BET_AMOUNT, 1_000_000));
        assertFalse(validator.validate(ParamKeys.MIN_BET_AMOUNT, 50_000));  // 太小
        assertFalse(validator.validate(ParamKeys.MIN_BET_AMOUNT, 200_000_000));  // 太大
    }

    function test_RangeValidator_SetCustomRange() public {
        // 设置自定义范围
        validator.setRange(ParamKeys.FEE_RATE, 100, 500);

        (uint256 min, uint256 max) = validator.getRange(ParamKeys.FEE_RATE);
        assertEq(min, 100);
        assertEq(max, 500);

        // 验证自定义范围生效
        assertTrue(validator.validate(ParamKeys.FEE_RATE, 200));
        assertFalse(validator.validate(ParamKeys.FEE_RATE, 50));   // 低于自定义最小值
        assertFalse(validator.validate(ParamKeys.FEE_RATE, 600));  // 高于自定义最大值
    }

    function test_RangeValidator_SetRangesBatch() public {
        bytes32[] memory keys = new bytes32[](2);
        keys[0] = ParamKeys.FEE_RATE;
        keys[1] = ParamKeys.MIN_BET_AMOUNT;

        uint256[] memory minValues = new uint256[](2);
        minValues[0] = 50;
        minValues[1] = 500_000;

        uint256[] memory maxValues = new uint256[](2);
        maxValues[0] = 300;
        maxValues[1] = 50_000_000;

        validator.setRangesBatch(keys, minValues, maxValues);

        (uint256 min, uint256 max) = validator.getRange(ParamKeys.FEE_RATE);
        assertEq(min, 50);
        assertEq(max, 300);

        (min, max) = validator.getRange(ParamKeys.MIN_BET_AMOUNT);
        assertEq(min, 500_000);
        assertEq(max, 50_000_000);
    }

    function test_RangeValidator_ClearCustomRange() public {
        // 设置自定义范围
        validator.setRange(ParamKeys.FEE_RATE, 100, 500);

        // 清除自定义范围
        validator.clearCustomRange(ParamKeys.FEE_RATE);

        // 应该恢复为 ParamKeys 默认范围
        (uint256 min, uint256 max) = validator.getRange(ParamKeys.FEE_RATE);
        assertEq(min, 0);
        assertEq(max, 1000);
    }

    function test_RangeValidator_RevertInvalidRange() public {
        vm.expectRevert(abi.encodeWithSelector(RangeValidator.InvalidRange.selector, 500, 100));
        validator.setRange(ParamKeys.FEE_RATE, 500, 100);  // min > max
    }

    function test_RangeValidator_RevertNotOwner() public {
        vm.prank(address(0x999));
        vm.expectRevert(RangeValidator.NotOwner.selector);
        validator.setRange(ParamKeys.FEE_RATE, 100, 500);
    }

    function test_RangeValidator_TransferOwnership() public {
        address newOwner = address(0x888);
        validator.transferOwnership(newOwner);

        assertEq(validator.owner(), newOwner);

        // 旧 owner 不能再操作
        vm.expectRevert(RangeValidator.NotOwner.selector);
        validator.setRange(ParamKeys.FEE_RATE, 100, 500);

        // 新 owner 可以操作
        vm.prank(newOwner);
        validator.setRange(ParamKeys.FEE_RATE, 100, 500);
    }

    /*//////////////////////////////////////////////////////////////
                   INTEGRATION: CONTROLLER + VALIDATOR
    //////////////////////////////////////////////////////////////*/

    function test_Integration_RegisterAllParams() public {
        bytes32[] memory keys = ParamKeys.getAllKeys();
        uint256[] memory values = ParamKeys.getDefaultValues();

        // 为所有参数创建验证器数组
        address[] memory validators = new address[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            validators[i] = address(validator);
        }

        // 批量注册所有参数
        controller.registerParamsBatch(keys, values, validators);

        // 验证所有参数已注册
        for (uint256 i = 0; i < keys.length; i++) {
            assertTrue(controller.isParamRegistered(keys[i]));
            assertEq(controller.getParam(keys[i]), values[i]);
            assertEq(controller.validators(keys[i]), address(validator));
        }
    }

    function test_Integration_ProposeAndExecuteWithValidation() public {
        // 注册 FEE_RATE 参数，带验证器
        controller.registerParam(ParamKeys.FEE_RATE, 200, address(validator));

        // 提案一个在范围内的新值
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(ParamKeys.FEE_RATE, 150, "Lower fee");

        // 快进时间
        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        // 执行提案
        vm.prank(executor);
        controller.executeProposal(proposalId);

        assertEq(controller.getParam(ParamKeys.FEE_RATE), 150);
    }

    function test_Integration_ProposeRevertOutOfRange() public {
        // 注册 FEE_RATE 参数，带验证器
        controller.registerParam(ParamKeys.FEE_RATE, 200, address(validator));

        // 提案一个超出范围的新值（1500 > 1000）
        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ValidationFailed.selector, ParamKeys.FEE_RATE, 1500));
        controller.proposeChange(ParamKeys.FEE_RATE, 1500, "Too high fee");
    }

    function test_Integration_FeeSplitValidation() public {
        // 注册所有费用分成参数
        controller.registerParam(ParamKeys.FEE_LP_SHARE_BPS, 6000, address(validator));
        controller.registerParam(ParamKeys.FEE_PROMO_SHARE_BPS, 2000, address(validator));
        controller.registerParam(ParamKeys.FEE_INSURANCE_SHARE_BPS, 1000, address(validator));
        controller.registerParam(ParamKeys.FEE_TREASURY_SHARE_BPS, 1000, address(validator));

        // 查询当前分成
        uint256 lpShare = controller.getParam(ParamKeys.FEE_LP_SHARE_BPS);
        uint256 promoShare = controller.getParam(ParamKeys.FEE_PROMO_SHARE_BPS);
        uint256 insuranceShare = controller.getParam(ParamKeys.FEE_INSURANCE_SHARE_BPS);
        uint256 treasuryShare = controller.getParam(ParamKeys.FEE_TREASURY_SHARE_BPS);

        // 验证总和为 100%
        assertEq(lpShare + promoShare + insuranceShare + treasuryShare, 10000);
    }

    function test_Integration_BetLimitsValidation() public {
        // 注册投注限制参数
        controller.registerParam(ParamKeys.MIN_BET_AMOUNT, 1_000_000, address(validator));
        controller.registerParam(ParamKeys.MAX_BET_AMOUNT, 5_000_000, address(validator));

        uint256 minBet = controller.getParam(ParamKeys.MIN_BET_AMOUNT);
        uint256 maxBet = controller.getParam(ParamKeys.MAX_BET_AMOUNT);

        // 验证 min < max
        assertTrue(minBet < maxBet, "MIN_BET should be less than MAX_BET");
    }

    function test_Integration_OddsValidation() public {
        // 注册赔率参数
        controller.registerParam(ParamKeys.MIN_ODDS, 10_000, address(validator));
        controller.registerParam(ParamKeys.MAX_ODDS, 10_000_000, address(validator));

        uint256 minOdds = controller.getParam(ParamKeys.MIN_ODDS);
        uint256 maxOdds = controller.getParam(ParamKeys.MAX_ODDS);

        // 验证 min < max
        assertTrue(minOdds < maxOdds, "MIN_ODDS should be less than MAX_ODDS");

        // 验证最小赔率 >= 1.0x (10000)
        assertTrue(minOdds >= 10_000, "MIN_ODDS should be at least 1.0x");
    }

    function test_Integration_DisputeWindowValidation() public {
        // 注册争议期参数
        controller.registerParam(ParamKeys.DISPUTE_WINDOW, 7200, address(validator));

        uint256 disputeWindow = controller.getParam(ParamKeys.DISPUTE_WINDOW);

        // 验证争议期在合理范围内
        assertTrue(disputeWindow >= 1800, "Dispute window should be at least 30 minutes");
        assertTrue(disputeWindow <= 604800, "Dispute window should be at most 7 days");
    }
}
