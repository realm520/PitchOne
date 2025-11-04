// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title MarketFactory_v2
 * @notice 市场工厂 - 使用 Clone 模式创建市场
 * @dev 优化版本：
 *      - 使用 EIP-1167 Minimal Proxy 克隆模板（节省 gas）
 *      - 支持动态注册新模板
 *      - 轻量级（< 24KB）
 */
contract MarketFactory_v2 is Ownable, Pausable {
    using Clones for address;

    // ============ 结构体 ============

    /// @notice 模板信息
    struct TemplateInfo {
        address implementation; // 模板实现合约地址
        string name;            // 模板名称 (e.g., "WDL", "OU")
        string version;         // 版本 (e.g., "1.0.0")
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
    event TemplateRegistered(
        bytes32 indexed templateId,
        address indexed implementation,
        string name,
        string version
    );

    /// @notice 模板激活状态更新
    event TemplateActiveStatusUpdated(bytes32 indexed templateId, bool active);

    /// @notice 市场创建事件
    event MarketCreated(
        address indexed market,
        bytes32 indexed templateId,
        address indexed creator
    );

    // ============ 构造函数 ============

    constructor() Ownable(msg.sender) {}

    // ============ 管理函数 ============

    /**
     * @notice 注册新模板
     * @param name 模板名称
     * @param version 版本号
     * @param implementation 模板实现地址
     * @return templateId 模板ID
     */
    function registerTemplate(
        string memory name,
        string memory version,
        address implementation
    ) external onlyOwner returns (bytes32 templateId) {
        require(bytes(name).length > 0, "Empty name");
        require(bytes(version).length > 0, "Empty version");
        require(implementation != address(0), "Invalid address");
        require(!isRegistered[implementation], "Already registered");

        templateId = keccak256(abi.encode(name, version));
        require(templates[templateId].implementation == address(0), "Template exists");

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
     * @notice 设置模板激活状态
     */
    function setTemplateActive(bytes32 templateId, bool active) external onlyOwner {
        require(templates[templateId].implementation != address(0), "Template not found");
        templates[templateId].active = active;
        emit TemplateActiveStatusUpdated(templateId, active);
    }

    /**
     * @notice 暂停/恢复市场创建
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 市场创建 ============

    /**
     * @notice 创建新市场（使用 Clone 模式）
     * @param templateId 模板ID
     * @param initData 初始化数据（编码后的 initialize 参数）
     * @return market 市场地址
     *
     * @dev 使用 EIP-1167 Minimal Proxy 克隆模板
     *      Gas 成本：~200 gas（vs 直接部署的 ~1M gas）
     */
    function createMarket(bytes32 templateId, bytes memory initData)
        external
        whenNotPaused
        returns (address market)
    {
        TemplateInfo storage template = templates[templateId];
        require(template.implementation != address(0), "Template not found");
        require(template.active, "Template not active");

        // 使用 Clone 克隆模板
        market = template.implementation.clone();

        // 调用 initialize 初始化市场
        (bool success,) = market.call(initData);
        require(success, "Initialization failed");

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = templateId;
        template.marketCount++;

        emit MarketCreated(market, templateId, msg.sender);
    }

    /**
     * @notice 使用 deterministic 地址创建市场
     * @dev 可预测市场地址（便于前端）
     */
    function createMarketDeterministic(
        bytes32 templateId,
        bytes32 salt,
        bytes memory initData
    ) external whenNotPaused returns (address market) {
        TemplateInfo storage template = templates[templateId];
        require(template.implementation != address(0), "Template not found");
        require(template.active, "Template not active");

        // 使用 cloneDeterministic 创建可预测地址的 clone
        market = template.implementation.cloneDeterministic(salt);

        // 初始化
        (bool success,) = market.call(initData);
        require(success, "Initialization failed");

        // 记录
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = templateId;
        template.marketCount++;

        emit MarketCreated(market, templateId, msg.sender);
    }

    /**
     * @notice 记录外部创建的市场（方案 A）
     * @dev 用于支持使用 constructor 的模板
     *      创建流程：
     *      1. 外部直接 new Template(...)
     *      2. 调用此方法注册市场
     *      3. Subgraph 监听 MarketCreated 事件索引
     *
     * @param market 市场地址
     * @param templateId 使用的模板 ID
     */
    function recordMarket(address market, bytes32 templateId)
        external
        whenNotPaused
        returns (bool)
    {
        TemplateInfo storage template = templates[templateId];
        require(template.implementation != address(0), "Template not found");
        require(template.active, "Template not active");
        require(market != address(0), "Invalid market address");
        require(!isMarket[market], "Market already registered");

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = templateId;
        template.marketCount++;

        emit MarketCreated(market, templateId, msg.sender);
        return true;
    }

    /**
     * @notice 预测 deterministic 市场地址
     */
    function predictMarketAddress(bytes32 templateId, bytes32 salt)
        external
        view
        returns (address)
    {
        address implementation = templates[templateId].implementation;
        require(implementation != address(0), "Template not found");
        return implementation.predictDeterministicAddress(salt);
    }

    // ============ 查询函数 ============

    function getTemplateInfo(bytes32 templateId)
        external
        view
        returns (TemplateInfo memory)
    {
        return templates[templateId];
    }

    function getAllTemplateIds() external view returns (bytes32[] memory) {
        return templateIds;
    }

    function getMarketCount() external view returns (uint256) {
        return markets.length;
    }

    function getMarket(uint256 index) external view returns (address) {
        return markets[index];
    }
}
