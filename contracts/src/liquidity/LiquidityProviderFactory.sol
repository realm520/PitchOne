// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

import "./ERC4626LiquidityProvider.sol";
import "./ParimutuelLiquidityProvider.sol";
import "../interfaces/ILiquidityProvider.sol";

/**
 * @title LiquidityProviderFactory
 * @notice 流动性提供者工厂,统一管理不同类型 Provider 的部署
 * @dev 支持多种 Provider 类型:ERC4626、Parimutuel 等
 *
 * 核心功能:
 *      - Provider 类型注册与管理
 *      - 授权 Deployer 管理
 *      - Provider 实例部署
 *      - Provider 信息追踪与查询
 *
 * @author PitchOne Team
 */
contract LiquidityProviderFactory is Ownable {
    // ============ 结构体 ============

    struct ProviderInfo {
        string providerType; // Provider 类型(ERC4626, Parimutuel 等)
        address deployer; // 部署者地址
        uint256 deployedAt; // 部署时间戳
        bool exists; // 是否存在
    }

    // ============ 状态变量 ============

    /// @notice Provider 类型 => 实现地址
    mapping(string => address) public providerImplementations;

    /// @notice Provider 类型是否已注册
    mapping(string => bool) public isProviderTypeRegistered;

    /// @notice 授权的 Deployer 映射
    mapping(address => bool) public isAuthorizedDeployer;

    /// @notice 所有部署的 Provider 列表
    address[] public allProviders;

    /// @notice Provider 地址 => Provider 信息
    mapping(address => ProviderInfo) public providerInfoMap;

    /// @notice Provider 类型 => Provider 地址列表
    mapping(string => address[]) public providersByType;

    /// @notice Deployer 地址 => Provider 地址列表
    mapping(address => address[]) public providersByDeployer;

    // ============ 事件 ============

    /// @notice Provider 类型注册事件
    event ProviderTypeRegistered(string indexed providerType, address implementation);

    /// @notice Provider 部署事件
    event ProviderDeployed(
        address indexed provider, string indexed providerType, address indexed deployer, uint256 index
    );

    /// @notice Deployer 授权变更事件
    event DeployerAuthorized(address indexed deployer, bool authorized);

    // ============ 构造函数 ============

    constructor() Ownable(msg.sender) {}

    // ============ Provider 类型管理 ============

    /**
     * @notice 注册 Provider 类型
     * @param providerType Provider 类型标识(如 "ERC4626", "Parimutuel")
     * @param implementation 实现地址(用于参考,非强制使用)
     * @dev 只有 owner 可调用
     */
    function registerProviderType(string memory providerType, address implementation) external onlyOwner {
        require(bytes(providerType).length > 0, "Invalid provider type");
        require(implementation != address(0), "Invalid implementation address");
        require(!isProviderTypeRegistered[providerType], "Provider type already registered");

        providerImplementations[providerType] = implementation;
        isProviderTypeRegistered[providerType] = true;

        emit ProviderTypeRegistered(providerType, implementation);
    }

    // ============ Deployer 管理 ============

    /**
     * @notice 授权 Deployer
     * @param deployer Deployer 地址
     * @dev 只有 owner 可调用
     */
    function authorizeDeployer(address deployer) external onlyOwner {
        require(deployer != address(0), "Invalid deployer address");
        isAuthorizedDeployer[deployer] = true;
        emit DeployerAuthorized(deployer, true);
    }

    /**
     * @notice 撤销 Deployer 授权
     * @param deployer Deployer 地址
     * @dev 只有 owner 可调用
     */
    function revokeDeployer(address deployer) external onlyOwner {
        isAuthorizedDeployer[deployer] = false;
        emit DeployerAuthorized(deployer, false);
    }

    // ============ Provider 部署 ============

    /**
     * @notice 通用 Provider 部署函数
     * @param providerType Provider 类型
     * @param initData 初始化数据(abi 编码的构造函数参数)
     * @return provider 部署的 Provider 地址
     * @dev 根据 providerType 路由到具体的部署函数
     */
    function deployProvider(string memory providerType, bytes memory initData)
        external
        returns (address provider)
    {
        require(isAuthorizedDeployer[msg.sender], "Unauthorized deployer");
        require(isProviderTypeRegistered[providerType], "Provider type not registered");

        // 根据类型路由到具体的部署逻辑
        if (keccak256(bytes(providerType)) == keccak256(bytes("ERC4626"))) {
            provider = _deployERC4626Provider(initData);
        } else if (keccak256(bytes(providerType)) == keccak256(bytes("Parimutuel"))) {
            provider = _deployParimutuelProvider(initData);
        } else {
            revert("Unsupported provider type");
        }

        // 记录 Provider 信息
        _recordProvider(provider, providerType, msg.sender);

        return provider;
    }

    /**
     * @notice 部署 ERC4626 Provider
     * @param initData abi.encode(asset, name, symbol)
     * @return provider 部署的 Provider 地址
     */
    function _deployERC4626Provider(bytes memory initData) internal returns (address provider) {
        (address asset, string memory name, string memory symbol) = abi.decode(initData, (address, string, string));

        ERC4626LiquidityProvider newProvider =
            new ERC4626LiquidityProvider(IERC20(asset), name, symbol);

        return address(newProvider);
    }

    /**
     * @notice 部署 Parimutuel Provider
     * @param initData abi.encode(asset)
     * @return provider 部署的 Provider 地址
     */
    function _deployParimutuelProvider(bytes memory initData) internal returns (address provider) {
        (address asset) = abi.decode(initData, (address));

        ParimutuelLiquidityProvider newProvider = new ParimutuelLiquidityProvider(IERC20(asset));

        return address(newProvider);
    }

    /**
     * @notice 记录 Provider 信息
     * @param provider Provider 地址
     * @param providerType Provider 类型
     * @param deployer 部署者地址
     */
    function _recordProvider(address provider, string memory providerType, address deployer) internal {
        // 记录到全局列表
        uint256 index = allProviders.length;
        allProviders.push(provider);

        // 记录 Provider 信息
        providerInfoMap[provider] = ProviderInfo({
            providerType: providerType,
            deployer: deployer,
            deployedAt: block.timestamp,
            exists: true
        });

        // 按类型记录
        providersByType[providerType].push(provider);

        // 按 Deployer 记录
        providersByDeployer[deployer].push(provider);

        emit ProviderDeployed(provider, providerType, deployer, index);
    }

    // ============ 查询函数 ============

    /**
     * @notice 获取 Provider 总数
     * @return 总数
     */
    function getProviderCount() external view returns (uint256) {
        return allProviders.length;
    }

    /**
     * @notice 根据索引获取 Provider 地址
     * @param index 索引
     * @return Provider 地址
     */
    function getProvider(uint256 index) external view returns (address) {
        require(index < allProviders.length, "Index out of bounds");
        return allProviders[index];
    }

    /**
     * @notice 获取所有 Provider 列表
     * @return Provider 地址数组
     */
    function getAllProviders() external view returns (address[] memory) {
        return allProviders;
    }

    /**
     * @notice 根据类型获取 Provider 列表
     * @param providerType Provider 类型
     * @return Provider 地址数组
     */
    function getProvidersByType(string memory providerType) external view returns (address[] memory) {
        return providersByType[providerType];
    }

    /**
     * @notice 根据 Deployer 获取 Provider 列表
     * @param deployer Deployer 地址
     * @return Provider 地址数组
     */
    function getProvidersByDeployer(address deployer) external view returns (address[] memory) {
        return providersByDeployer[deployer];
    }

    /**
     * @notice 获取 Provider 详细信息
     * @param provider Provider 地址
     * @return providerType Provider 类型
     * @return deployer 部署者地址
     * @return deployedAt 部署时间戳
     */
    function getProviderInfo(address provider)
        external
        view
        returns (string memory providerType, address deployer, uint256 deployedAt)
    {
        ProviderInfo memory info = providerInfoMap[provider];
        require(info.exists, "Provider not found");
        return (info.providerType, info.deployer, info.deployedAt);
    }
}
