// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IParamController
 * @notice ParamController 接口定义
 */
interface IParamController {
    /**
     * @notice 查询参数值
     * @param key 参数键
     * @return value 参数值
     */
    function getParam(bytes32 key) external view returns (uint256 value);

    /**
     * @notice 批量查询参数值
     * @param keys 参数键数组
     * @return values 参数值数组
     */
    function getParams(bytes32[] calldata keys) external view returns (uint256[] memory values);

    /**
     * @notice 尝试查询参数值（不存在则返回默认值）
     * @param key 参数键
     * @param defaultValue 默认值
     * @return value 参数值或默认值
     */
    function tryGetParam(bytes32 key, uint256 defaultValue) external view returns (uint256 value);

    /**
     * @notice 参数是否已注册
     * @param key 参数键
     * @return registered 是否已注册
     */
    function isParamRegistered(bytes32 key) external view returns (bool registered);

    /**
     * @notice 获取参数的验证器地址
     * @param key 参数键
     * @return validator 验证器合约地址
     */
    function validators(bytes32 key) external view returns (address validator);

    /**
     * @notice 获取 Timelock 延迟时间
     * @return delay 延迟秒数
     */
    function timelockDelay() external view returns (uint256 delay);
}
