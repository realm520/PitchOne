// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IParamController.sol";

/**
 * @notice Mock ParamController for testing
 */
contract MockParamController is IParamController {
    mapping(bytes32 => uint256) private params;

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

    // Helper function for testing
    function setParam(bytes32 key, uint256 value) external {
        params[key] = value;
    }
}
