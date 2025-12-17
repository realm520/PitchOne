// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IParamController.sol";

/**
 * @notice Mock ParamController for testing
 */
contract MockParamController is IParamController {
    mapping(bytes32 => uint256) private params;
    mapping(bytes32 => address) private _validators;
    uint256 private _timelockDelay = 2 days;

    function getParam(bytes32 key) external view override returns (uint256 value) {
        return params[key];
    }

    function getParams(bytes32[] calldata keys) external view override returns (uint256[] memory values) {
        values = new uint256[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = params[keys[i]];
        }
    }

    function tryGetParam(bytes32 key, uint256 defaultValue) external view override returns (uint256 value) {
        if (params[key] == 0) {
            return defaultValue;
        }
        return params[key];
    }

    function isParamRegistered(bytes32 key) external view override returns (bool registered) {
        return params[key] != 0;
    }

    function validators(bytes32 key) external view override returns (address validator) {
        return _validators[key];
    }

    function timelockDelay() external view override returns (uint256 delay) {
        return _timelockDelay;
    }

    // Helper functions for testing
    function setParam(bytes32 key, uint256 value) external {
        params[key] = value;
    }

    function setValidator(bytes32 key, address validator) external {
        _validators[key] = validator;
    }

    function setTimelockDelay(uint256 delay) external {
        _timelockDelay = delay;
    }
}
