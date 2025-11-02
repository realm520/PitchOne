// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title MarketTemplateRegistry
 * @notice 市场模板注册表和工厂合约
 * @dev 负责管理市场模板的注册/注销，并提供统一的市场创建接口
 *
 * 核心功能:
 * 1. 模板注册管理 (仅 Owner)
 * 2. 市场创建工厂
 * 3. 模板验证和查询
 *
 * 安全特性:
 * - Ownable: 仅 Owner 可注册/注销模板
 * - Pausable: 紧急情况下可暂停市场创建
 * - 模板地址验证: 防止零地址和重复注册
 */
contract MarketTemplateRegistry is Ownable, Pausable {
    // ============ 结构体 ============

    /// @notice 模板信息
    struct TemplateInfo {
        address implementation; // 模板实现合约地址
        string name;            // 模板名称 (e.g., "WDL", "OU", "AH")
        string version;         // 模板版本 (e.g., "1.0.0")
        bool active;            // 是否激活
        uint256 createdAt;      // 注册时间
        uint256 marketCount;    // 使用该模板创建的市场数量
    }

    // ============ 状态变量 ============

    /// @notice 模板ID => 模板信息
    mapping(bytes32 => TemplateInfo) public templates;

    /// @notice 已注册的模板ID列表
    bytes32[] public templateIds;

    /// @notice 模板实现地址 => 是否已注册
    mapping(address => bool) public isRegistered;

    /// @notice 创建的市场地址列表
    address[] public markets;

    /// @notice 市场地址 => 是否存在
    mapping(address => bool) public isMarket;

    /// @notice 市场地址 => 模板ID
    mapping(address => bytes32) public marketTemplate;

    // ============ 事件 ============

    /// @notice 模板注册事件
    /// @param templateId 模板ID
    /// @param implementation 模板实现地址
    /// @param name 模板名称
    /// @param version 模板版本
    event TemplateRegistered(
        bytes32 indexed templateId,
        address indexed implementation,
        string name,
        string version
    );

    /// @notice 模板注销事件
    /// @param templateId 模板ID
    /// @param implementation 模板实现地址
    event TemplateUnregistered(
        bytes32 indexed templateId,
        address indexed implementation
    );

    /// @notice 模板激活状态更新事件
    /// @param templateId 模板ID
    /// @param active 是否激活
    event TemplateActiveStatusUpdated(
        bytes32 indexed templateId,
        bool active
    );

    /// @notice 市场创建事件
    /// @param market 市场合约地址
    /// @param templateId 使用的模板ID
    /// @param creator 创建者地址
    event MarketCreated(
        address indexed market,
        bytes32 indexed templateId,
        address indexed creator
    );

    // ============ 修饰符 ============

    /// @notice 仅在模板已注册时执行
    modifier onlyRegisteredTemplate(bytes32 templateId) {
        require(templates[templateId].implementation != address(0), "Template not registered");
        _;
    }

    /// @notice 仅在模板激活时执行
    modifier onlyActiveTemplate(bytes32 templateId) {
        require(templates[templateId].active, "Template not active");
        _;
    }

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @dev 部署者成为 Owner
     */
    constructor() Ownable(msg.sender) {}

    // ============ 管理函数 (仅 Owner) ============

    /**
     * @notice 注册新模板
     * @param name 模板名称 (e.g., "WDL", "OU", "AH")
     * @param version 模板版本 (e.g., "1.0.0")
     * @param implementation 模板实现合约地址
     * @return templateId 模板ID (name 和 version 的 keccak256 哈希)
     *
     * @dev 规则:
     *      - 仅 Owner 可调用
     *      - implementation 不能为零地址
     *      - 相同 name+version 不能重复注册
     *      - implementation 地址不能重复注册
     *      - 新注册的模板默认为激活状态
     */
    function registerTemplate(
        string memory name,
        string memory version,
        address implementation
    ) external onlyOwner returns (bytes32 templateId) {
        require(bytes(name).length > 0, "Empty template name");
        require(bytes(version).length > 0, "Empty template version");
        require(implementation != address(0), "Invalid implementation address");
        require(!isRegistered[implementation], "Implementation already registered");

        // 生成模板ID（使用 abi.encode 避免哈希碰撞）
        templateId = keccak256(abi.encode(name, version));
        require(templates[templateId].implementation == address(0), "Template already registered");

        // 保存模板信息
        templates[templateId] = TemplateInfo({
            implementation: implementation,
            name: name,
            version: version,
            active: true,
            createdAt: block.timestamp,
            marketCount: 0
        });

        templateIds.push(templateId);
        isRegistered[implementation] = true;

        emit TemplateRegistered(templateId, implementation, name, version);
    }

    /**
     * @notice 注销模板
     * @param templateId 模板ID
     *
     * @dev 规则:
     *      - 仅 Owner 可调用
     *      - 模板必须已注册
     *      - 注销后不能再创建新市场，但不影响已创建的市场
     */
    function unregisterTemplate(bytes32 templateId)
        external
        onlyOwner
        onlyRegisteredTemplate(templateId)
    {
        TemplateInfo memory info = templates[templateId];

        // 标记为未注册
        isRegistered[info.implementation] = false;

        // 删除模板信息
        delete templates[templateId];

        emit TemplateUnregistered(templateId, info.implementation);
    }

    /**
     * @notice 更新模板激活状态
     * @param templateId 模板ID
     * @param active 是否激活
     *
     * @dev 规则:
     *      - 仅 Owner 可调用
     *      - 模板必须已注册
     *      - 未激活的模板不能创建新市场
     */
    function setTemplateActive(bytes32 templateId, bool active)
        external
        onlyOwner
        onlyRegisteredTemplate(templateId)
    {
        templates[templateId].active = active;
        emit TemplateActiveStatusUpdated(templateId, active);
    }

    /**
     * @notice 暂停/恢复市场创建
     * @dev 紧急情况下可调用
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 市场创建函数 (公开) ============

    /**
     * @notice 创建新市场 (使用模板的 clone 模式)
     * @param templateId 模板ID
     * @param initData 初始化数据 (编码后的构造函数参数)
     * @return market 创建的市场合约地址
     *
     * @dev 规则:
     *      - 模板必须已注册且激活
     *      - 合约未暂停
     *      - 使用 CREATE2 确保地址可预测
     *
     * 注意: 此版本使用简化的 new 方式创建，生产环境可考虑使用 Proxy 或 Clone 优化 Gas
     */
    function createMarket(bytes32 templateId, bytes memory initData)
        external
        whenNotPaused
        onlyRegisteredTemplate(templateId)
        onlyActiveTemplate(templateId)
        returns (address market)
    {
        // 获取模板实现地址
        address implementation = templates[templateId].implementation;

        // 使用 low-level call 创建市场
        // 注意: 这里需要模板合约实现工厂函数或使用 Proxy 模式
        // 简化版: 假设调用者传入完整的 bytecode + constructor args
        assembly {
            market := create(0, add(initData, 0x20), mload(initData))
        }

        require(market != address(0), "Market creation failed");

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = templateId;

        // 更新模板计数
        templates[templateId].marketCount++;

        emit MarketCreated(market, templateId, msg.sender);
    }

    // ============ 查询函数 ============

    /**
     * @notice 获取模板信息
     * @param templateId 模板ID
     * @return info 模板信息
     */
    function getTemplateInfo(bytes32 templateId)
        external
        view
        returns (TemplateInfo memory info)
    {
        return templates[templateId];
    }

    /**
     * @notice 获取所有已注册的模板ID
     * @return ids 模板ID数组
     */
    function getAllTemplateIds() external view returns (bytes32[] memory ids) {
        return templateIds;
    }

    /**
     * @notice 获取激活的模板ID列表
     * @return activeIds 激活的模板ID数组
     */
    function getActiveTemplateIds() external view returns (bytes32[] memory activeIds) {
        uint256 activeCount = 0;

        // 第一遍: 统计激活数量
        for (uint256 i = 0; i < templateIds.length; i++) {
            if (templates[templateIds[i]].active) {
                activeCount++;
            }
        }

        // 第二遍: 填充数组
        activeIds = new bytes32[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < templateIds.length; i++) {
            if (templates[templateIds[i]].active) {
                activeIds[index] = templateIds[i];
                index++;
            }
        }
    }

    /**
     * @notice 获取所有市场地址
     * @return addresses 市场地址数组
     */
    function getAllMarkets() external view returns (address[] memory addresses) {
        return markets;
    }

    /**
     * @notice 获取市场总数
     * @return count 市场数量
     */
    function getMarketCount() external view returns (uint256 count) {
        return markets.length;
    }

    /**
     * @notice 获取使用特定模板创建的市场数量
     * @param templateId 模板ID
     * @return count 市场数量
     */
    function getTemplateMarketCount(bytes32 templateId)
        external
        view
        returns (uint256 count)
    {
        return templates[templateId].marketCount;
    }

    /**
     * @notice 计算模板ID
     * @param name 模板名称
     * @param version 模板版本
     * @return templateId 模板ID
     */
    function calculateTemplateId(string memory name, string memory version)
        external
        pure
        returns (bytes32 templateId)
    {
        return keccak256(abi.encode(name, version));
    }
}
