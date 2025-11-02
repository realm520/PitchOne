// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ParamController} from "../src/governance/ParamController.sol";

/**
 * @title MockValidator
 * @notice 用于测试的参数验证器
 */
contract MockValidator {
    mapping(bytes32 => uint256) public minValues;
    mapping(bytes32 => uint256) public maxValues;

    function setRange(bytes32 key, uint256 min, uint256 max) external {
        minValues[key] = min;
        maxValues[key] = max;
    }

    function validate(bytes32 key, uint256 value) external view returns (bool) {
        uint256 min = minValues[key];
        uint256 max = maxValues[key];

        if (max == 0) return true; // 未设置范围，总是通过

        return value >= min && value <= max;
    }
}

contract ParamControllerTest is Test {
    ParamController public controller;
    MockValidator public validator;

    address public admin = address(this);
    address public proposer = address(0x1);
    address public executor = address(0x2);
    address public guardian = address(0x3);
    address public user = address(0x4);

    // 常用参数键
    bytes32 public constant FEE_RATE = keccak256("FEE_RATE");
    bytes32 public constant MIN_BET = keccak256("MIN_BET");
    bytes32 public constant MAX_BET = keccak256("MAX_BET");
    bytes32 public constant LP_SHARE = keccak256("LP_SHARE");

    uint256 public constant DEFAULT_TIMELOCK = 2 days;

    event ParamRegistered(bytes32 indexed key, uint256 initialValue, address indexed validator);
    event ProposalCreated(
        bytes32 indexed proposalId,
        bytes32 indexed key,
        uint256 oldValue,
        uint256 newValue,
        uint256 eta,
        address indexed proposer,
        string reason
    );
    event ProposalExecuted(bytes32 indexed proposalId, bytes32 indexed key, uint256 oldValue, uint256 newValue);
    event ProposalCancelled(bytes32 indexed proposalId, address indexed canceller);
    event ParamChanged(bytes32 indexed key, uint256 oldValue, uint256 newValue, uint256 timestamp);

    function setUp() public {
        // 部署合约
        controller = new ParamController(admin, DEFAULT_TIMELOCK);
        validator = new MockValidator();

        // 授予角色
        controller.grantRole(controller.PROPOSER_ROLE(), proposer);
        controller.grantRole(controller.EXECUTOR_ROLE(), executor);
        controller.grantRole(controller.GUARDIAN_ROLE(), guardian);

        // 注册基本参数
        controller.registerParam(FEE_RATE, 200, address(0)); // 2%
        controller.registerParam(MIN_BET, 1e6, address(0));  // 1 USDC
        controller.registerParam(MAX_BET, 10000e6, address(0)); // 10,000 USDC
    }

    /*//////////////////////////////////////////////////////////////
                          CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor() public {
        assertEq(controller.timelockDelay(), DEFAULT_TIMELOCK);
        assertTrue(controller.hasRole(controller.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(controller.hasRole(controller.PROPOSER_ROLE(), admin));
        assertTrue(controller.hasRole(controller.EXECUTOR_ROLE(), admin));
        assertTrue(controller.hasRole(controller.GUARDIAN_ROLE(), admin));
    }

    function test_Constructor_RevertInvalidTimelockDelay() public {
        vm.expectRevert(abi.encodeWithSelector(ParamController.InvalidTimelockDelay.selector, 30 minutes));
        new ParamController(admin, 30 minutes);

        vm.expectRevert(abi.encodeWithSelector(ParamController.InvalidTimelockDelay.selector, 8 days));
        new ParamController(admin, 8 days);
    }

    /*//////////////////////////////////////////////////////////////
                      PARAM REGISTRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegisterParam() public {
        bytes32 key = keccak256("NEW_PARAM");
        uint256 value = 100;

        vm.expectEmit(true, true, false, true);
        emit ParamRegistered(key, value, address(0));

        controller.registerParam(key, value, address(0));

        assertTrue(controller.isParamRegistered(key));
        assertEq(controller.getParam(key), value);
    }

    function test_RegisterParam_WithValidator() public {
        bytes32 key = keccak256("VALIDATED_PARAM");

        // 设置验证器范围 50-500
        validator.setRange(key, 50, 500);

        controller.registerParam(key, 100, address(validator));

        assertEq(controller.getParam(key), 100);
        assertEq(controller.validators(key), address(validator));
    }

    function test_RegisterParam_RevertAlreadyRegistered() public {
        vm.expectRevert(abi.encodeWithSelector(ParamController.ParamAlreadyRegistered.selector, FEE_RATE));
        controller.registerParam(FEE_RATE, 300, address(0));
    }

    function test_RegisterParam_RevertValidationFailed() public {
        bytes32 key = keccak256("VALIDATED_PARAM");
        validator.setRange(key, 50, 500);

        vm.expectRevert(abi.encodeWithSelector(ParamController.ValidationFailed.selector, key, 1000));
        controller.registerParam(key, 1000, address(validator));
    }

    function test_RegisterParam_RevertNotAdmin() public {
        vm.prank(user);
        vm.expectRevert();
        controller.registerParam(keccak256("NEW_PARAM"), 100, address(0));
    }

    function test_RegisterParamsBatch() public {
        bytes32[] memory keys = new bytes32[](3);
        keys[0] = keccak256("PARAM1");
        keys[1] = keccak256("PARAM2");
        keys[2] = keccak256("PARAM3");

        uint256[] memory values = new uint256[](3);
        values[0] = 100;
        values[1] = 200;
        values[2] = 300;

        address[] memory validators = new address[](3);
        validators[0] = address(0);
        validators[1] = address(0);
        validators[2] = address(0);

        controller.registerParamsBatch(keys, values, validators);

        assertEq(controller.getParam(keys[0]), 100);
        assertEq(controller.getParam(keys[1]), 200);
        assertEq(controller.getParam(keys[2]), 300);
    }

    /*//////////////////////////////////////////////////////////////
                        PARAM QUERY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetParam() public {
        assertEq(controller.getParam(FEE_RATE), 200);
        assertEq(controller.getParam(MIN_BET), 1e6);
    }

    function test_GetParam_RevertNotRegistered() public {
        bytes32 key = keccak256("NOT_REGISTERED");
        vm.expectRevert(abi.encodeWithSelector(ParamController.ParamNotRegistered.selector, key));
        controller.getParam(key);
    }

    function test_GetParams() public {
        bytes32[] memory keys = new bytes32[](2);
        keys[0] = FEE_RATE;
        keys[1] = MIN_BET;

        uint256[] memory values = controller.getParams(keys);
        assertEq(values[0], 200);
        assertEq(values[1], 1e6);
    }

    function test_TryGetParam() public {
        assertEq(controller.tryGetParam(FEE_RATE, 999), 200);
        assertEq(controller.tryGetParam(keccak256("NOT_EXIST"), 999), 999);
    }

    /*//////////////////////////////////////////////////////////////
                      PROPOSAL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ProposeChange() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Lower fee to attract users");

        (
            bytes32 key,
            uint256 oldValue,
            uint256 newValue,
            uint256 eta,
            bool executed,
            bool cancelled,
            address _proposer,
            string memory reason
        ) = controller.proposals(proposalId);

        assertEq(key, FEE_RATE);
        assertEq(oldValue, 200);
        assertEq(newValue, 150);
        assertEq(eta, block.timestamp + DEFAULT_TIMELOCK);
        assertFalse(executed);
        assertFalse(cancelled);
        assertEq(_proposer, proposer);
        assertEq(reason, "Lower fee to attract users");
    }

    function test_ProposeChange_RevertNotProposer() public {
        vm.prank(user);
        vm.expectRevert();
        controller.proposeChange(FEE_RATE, 150, "Test");
    }

    function test_ProposeChange_RevertParamNotRegistered() public {
        bytes32 key = keccak256("NOT_REGISTERED");

        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ParamNotRegistered.selector, key));
        controller.proposeChange(key, 150, "Test");
    }

    function test_ProposeChange_RevertSameValue() public {
        vm.prank(proposer);
        vm.expectRevert("New value same as old");
        controller.proposeChange(FEE_RATE, 200, "Test");
    }

    function test_ProposeChange_WithValidation() public {
        bytes32 key = keccak256("VALIDATED_PARAM");
        validator.setRange(key, 50, 500);
        controller.registerParam(key, 100, address(validator));

        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(key, 200, "Valid change");

        (, , uint256 newValue, , , , , ) = controller.proposals(proposalId);
        assertEq(newValue, 200);
    }

    function test_ProposeChange_RevertValidationFailed() public {
        bytes32 key = keccak256("VALIDATED_PARAM");
        validator.setRange(key, 50, 500);
        controller.registerParam(key, 100, address(validator));

        vm.prank(proposer);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ValidationFailed.selector, key, 1000));
        controller.proposeChange(key, 1000, "Invalid change");
    }

    /*//////////////////////////////////////////////////////////////
                      PROPOSAL EXECUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExecuteProposal() public {
        // 创建提案
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        // 快进时间
        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        // 执行提案
        vm.expectEmit(true, true, false, true);
        emit ParamChanged(FEE_RATE, 200, 150, block.timestamp);

        vm.prank(executor);
        controller.executeProposal(proposalId);

        // 验证参数已更新
        assertEq(controller.getParam(FEE_RATE), 150);

        // 验证提案状态
        (, , , , bool executed, , , ) = controller.proposals(proposalId);
        assertTrue(executed);
    }

    function test_ExecuteProposal_RevertNotExecutor() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        vm.prank(user);
        vm.expectRevert();
        controller.executeProposal(proposalId);
    }

    function test_ExecuteProposal_RevertProposalNotFound() public {
        bytes32 fakeId = keccak256("FAKE");

        vm.prank(executor);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ProposalNotFound.selector, fakeId));
        controller.executeProposal(fakeId);
    }

    function test_ExecuteProposal_RevertTimelockNotExpired() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        uint256 eta = block.timestamp + DEFAULT_TIMELOCK;

        vm.prank(executor);
        vm.expectRevert(
            abi.encodeWithSelector(
                ParamController.TimelockNotExpired.selector,
                proposalId,
                eta,
                block.timestamp
            )
        );
        controller.executeProposal(proposalId);
    }

    function test_ExecuteProposal_RevertAlreadyExecuted() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        vm.prank(executor);
        controller.executeProposal(proposalId);

        vm.prank(executor);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ProposalAlreadyExecuted.selector, proposalId));
        controller.executeProposal(proposalId);
    }

    function test_ExecuteProposal_RevertCancelled() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.prank(proposer);
        controller.cancelProposal(proposalId);

        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        vm.prank(executor);
        vm.expectRevert(abi.encodeWithSelector(ParamController.ProposalAlreadyCancelled.selector, proposalId));
        controller.executeProposal(proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                      PROPOSAL CANCELLATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CancelProposal_ByProposer() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.expectEmit(true, true, false, true);
        emit ProposalCancelled(proposalId, proposer);

        vm.prank(proposer);
        controller.cancelProposal(proposalId);

        (, , , , , bool cancelled, , ) = controller.proposals(proposalId);
        assertTrue(cancelled);
    }

    function test_CancelProposal_ByAdmin() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.prank(admin);
        controller.cancelProposal(proposalId);

        (, , , , , bool cancelled, , ) = controller.proposals(proposalId);
        assertTrue(cancelled);
    }

    function test_CancelProposal_RevertNotAuthorized() public {
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Test");

        vm.prank(user);
        vm.expectRevert("Not authorized to cancel");
        controller.cancelProposal(proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                      EMERGENCY CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Pause() public {
        vm.prank(guardian);
        controller.pause();

        assertTrue(controller.paused());

        // 暂停后不能创建提案
        vm.prank(proposer);
        vm.expectRevert();
        controller.proposeChange(FEE_RATE, 150, "Test");
    }

    function test_Unpause() public {
        vm.prank(guardian);
        controller.pause();

        vm.prank(guardian);
        controller.unpause();

        assertFalse(controller.paused());

        // 恢复后可以创建提案
        vm.prank(proposer);
        controller.proposeChange(FEE_RATE, 150, "Test");
    }

    function test_Pause_RevertNotGuardian() public {
        vm.prank(user);
        vm.expectRevert();
        controller.pause();
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateTimelockDelay() public {
        uint256 newDelay = 3 days;

        vm.expectEmit(false, false, false, true);
        emit ParamController.TimelockDelayUpdated(DEFAULT_TIMELOCK, newDelay);

        controller.updateTimelockDelay(newDelay);

        assertEq(controller.timelockDelay(), newDelay);
    }

    function test_UpdateTimelockDelay_RevertInvalid() public {
        vm.expectRevert(abi.encodeWithSelector(ParamController.InvalidTimelockDelay.selector, 30 minutes));
        controller.updateTimelockDelay(30 minutes);
    }

    function test_UpdateValidator() public {
        address newValidator = address(0x999);

        vm.expectEmit(true, false, false, true);
        emit ParamController.ValidatorUpdated(FEE_RATE, address(0), newValidator);

        controller.updateValidator(FEE_RATE, newValidator);

        assertEq(controller.validators(FEE_RATE), newValidator);
    }

    /*//////////////////////////////////////////////////////////////
                          INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullProposalLifecycle() public {
        // 1. 创建提案
        vm.prank(proposer);
        bytes32 proposalId = controller.proposeChange(FEE_RATE, 150, "Reduce fee");

        // 2. 验证提案状态
        (, uint256 oldValue, uint256 newValue, uint256 eta, , , , ) = controller.proposals(proposalId);
        assertEq(oldValue, 200);
        assertEq(newValue, 150);

        // 3. 快进时间
        vm.warp(eta);

        // 4. 执行提案
        vm.prank(executor);
        controller.executeProposal(proposalId);

        // 5. 验证参数已更新
        assertEq(controller.getParam(FEE_RATE), 150);
    }

    function test_MultipleProposals() public {
        // 创建多个提案
        vm.startPrank(proposer);
        bytes32 id1 = controller.proposeChange(FEE_RATE, 150, "Change 1");
        bytes32 id2 = controller.proposeChange(MIN_BET, 2e6, "Change 2");
        bytes32 id3 = controller.proposeChange(MAX_BET, 20000e6, "Change 3");
        vm.stopPrank();

        // 快进时间
        vm.warp(block.timestamp + DEFAULT_TIMELOCK);

        // 执行所有提案
        vm.startPrank(executor);
        controller.executeProposal(id1);
        controller.executeProposal(id2);
        controller.executeProposal(id3);
        vm.stopPrank();

        // 验证所有参数已更新
        assertEq(controller.getParam(FEE_RATE), 150);
        assertEq(controller.getParam(MIN_BET), 2e6);
        assertEq(controller.getParam(MAX_BET), 20000e6);
    }
}
