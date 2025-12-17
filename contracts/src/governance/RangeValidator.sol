// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ParamKeys} from "./ParamKeys.sol";

/**
 * @title RangeValidator
 * @notice 参数范围验证器
 * @dev 基于 ParamKeys 中定义的范围进行验证
 *      支持动态添加自定义范围
 */
contract RangeValidator {
    /// @notice 自定义验证范围（覆盖 ParamKeys 默认值）
    mapping(bytes32 => uint256) public customMinValues;
    mapping(bytes32 => uint256) public customMaxValues;
    mapping(bytes32 => bool) public hasCustomRange;

    /// @notice 合约所有者
    address public owner;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event RangeUpdated(bytes32 indexed key, uint256 minValue, uint256 maxValue);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner();
    error InvalidRange(uint256 min, uint256 max);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 验证参数值是否在有效范围内
     * @param key 参数键
     * @param value 参数值
     * @return valid 是否有效
     */
    function validate(bytes32 key, uint256 value) external view returns (bool) {
        (uint256 min, uint256 max) = getRange(key);
        return value >= min && value <= max;
    }

    /**
     * @notice 获取参数的验证范围
     * @param key 参数键
     * @return min 最小值
     * @return max 最大值
     */
    function getRange(bytes32 key) public view returns (uint256 min, uint256 max) {
        if (hasCustomRange[key]) {
            return (customMinValues[key], customMaxValues[key]);
        }
        return ParamKeys.getValidRange(key);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 设置自定义验证范围
     * @param key 参数键
     * @param minValue 最小值
     * @param maxValue 最大值
     */
    function setRange(bytes32 key, uint256 minValue, uint256 maxValue) external onlyOwner {
        if (minValue > maxValue) revert InvalidRange(minValue, maxValue);

        customMinValues[key] = minValue;
        customMaxValues[key] = maxValue;
        hasCustomRange[key] = true;

        emit RangeUpdated(key, minValue, maxValue);
    }

    /**
     * @notice 批量设置自定义验证范围
     * @param keys 参数键数组
     * @param minValues 最小值数组
     * @param maxValues 最大值数组
     */
    function setRangesBatch(
        bytes32[] calldata keys,
        uint256[] calldata minValues,
        uint256[] calldata maxValues
    ) external onlyOwner {
        require(keys.length == minValues.length && keys.length == maxValues.length, "Length mismatch");

        for (uint256 i = 0; i < keys.length; i++) {
            if (minValues[i] > maxValues[i]) revert InvalidRange(minValues[i], maxValues[i]);

            customMinValues[keys[i]] = minValues[i];
            customMaxValues[keys[i]] = maxValues[i];
            hasCustomRange[keys[i]] = true;

            emit RangeUpdated(keys[i], minValues[i], maxValues[i]);
        }
    }

    /**
     * @notice 清除自定义范围（恢复使用 ParamKeys 默认值）
     * @param key 参数键
     */
    function clearCustomRange(bytes32 key) external onlyOwner {
        hasCustomRange[key] = false;
        delete customMinValues[key];
        delete customMaxValues[key];
    }

    /**
     * @notice 转移所有权
     * @param newOwner 新所有者地址
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
