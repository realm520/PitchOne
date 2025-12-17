// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IMarket_V3.sol";
import "../interfaces/IPricingStrategy.sol";
import "../interfaces/IResultMapper.sol";

/**
 * @title MarketFactory_V4
 * @notice 市场工厂 V4 - 基于模板创建市场
 * @dev 核心功能：
 *      - 模板管理（预定义的 Strategy + Mapper + Outcomes 组合）
 *      - Clone 部署市场
 *      - 市场注册表
 *      - 权限控制
 *
 * 模板概念：
 *      模板 = 预定义的配置组合，包括：
 *      - 定价策略（CPMM / LMSR / Parimutuel）
 *      - 赛果映射器模板（可参数化，如 OU_Mapper 的 line）
 *      - 默认 outcome 规则
 *      - 默认初始流动性
 */
contract MarketFactory_V4 is AccessControl {
    using Clones for address;

    // ============ 角色定义 ============

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");

    // ============ 结构体 ============

    /// @notice 市场模板
    struct MarketTemplate {
        string name;                        // 模板名称（如 "WDL", "OU", "AH"）
        string strategyType;                // 策略类型（"CPMM", "LMSR", "PARIMUTUEL"）
        address pricingStrategy;            // 定价策略合约地址
        address mapperTemplate;             // Mapper 模板合约地址
        IMarket_V3.OutcomeRule[] defaultOutcomes; // 默认 outcome 规则
        uint256 defaultInitialLiquidity;    // 默认初始流动性
        bool active;                        // 是否激活
    }

    /// @notice 创建市场参数
    struct CreateMarketParams {
        bytes32 templateId;                 // 模板 ID
        string matchId;                     // 比赛 ID
        uint256 kickoffTime;                // 开球时间
        bytes mapperInitData;               // Mapper 初始化数据（可选）
        uint256 initialLiquidity;           // 初始流动性（0 表示使用模板默认值）
        IMarket_V3.OutcomeRule[] outcomeRules; // outcome 规则（空表示使用模板默认值）
    }

    // ============ 状态变量 ============

    /// @notice Market 实现合约地址
    address public marketImplementation;

    /// @notice 结算代币
    address public settlementToken;

    /// @notice Keeper 地址
    address public keeper;

    /// @notice Oracle 地址
    address public oracle;

    /// @notice 信任的 Router 地址
    address public trustedRouter;

    /// @notice 默认 Vault 地址
    address public defaultVault;

    /// @notice 模板注册表
    mapping(bytes32 => MarketTemplate) public templates;
    bytes32[] public templateIds;

    /// @notice 定价策略注册表
    mapping(string => address) public strategies;

    /// @notice Mapper 工厂（用于创建参数化的 Mapper）
    mapping(address => bool) public registeredMappers;

    /// @notice 市场注册表
    mapping(address => bool) public isMarket;
    address[] public markets;

    /// @notice 市场计数器
    uint256 public marketCount;

    // ============ 事件 ============

    event TemplateRegistered(bytes32 indexed templateId, string name, string strategyType);
    event TemplateUpdated(bytes32 indexed templateId, bool active);
    event StrategyRegistered(string strategyType, address strategy);
    event MapperRegistered(address mapper);
    event MarketCreated(
        address indexed market,
        bytes32 indexed templateId,
        string matchId,
        uint256 kickoffTime
    );
    event RouterUpdated(address indexed newRouter);
    event KeeperUpdated(address indexed newKeeper);
    event OracleUpdated(address indexed newOracle);
    event VaultUpdated(address indexed newVault);

    // ============ 错误定义 ============

    error InvalidTemplate();
    error TemplateNotActive();
    error InvalidImplementation();
    error InvalidParams();

    // ============ 构造函数 ============

    constructor(
        address _marketImplementation,
        address _settlementToken,
        address _admin
    ) {
        require(_marketImplementation != address(0), "Factory: Invalid implementation");
        require(_settlementToken != address(0), "Factory: Invalid token");
        require(_admin != address(0), "Factory: Invalid admin");

        marketImplementation = _marketImplementation;
        settlementToken = _settlementToken;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _admin);
    }

    // ============ 模板管理 ============

    /**
     * @notice 注册新模板
     * @param templateId 模板 ID
     * @param name 模板名称
     * @param strategyType 策略类型
     * @param pricingStrategy 定价策略地址
     * @param mapperTemplate Mapper 模板地址
     * @param defaultOutcomes 默认 outcome 规则
     * @param defaultInitialLiquidity 默认初始流动性
     */
    function registerTemplate(
        bytes32 templateId,
        string memory name,
        string memory strategyType,
        address pricingStrategy,
        address mapperTemplate,
        IMarket_V3.OutcomeRule[] memory defaultOutcomes,
        uint256 defaultInitialLiquidity
    ) external onlyRole(OPERATOR_ROLE) {
        require(pricingStrategy != address(0), "Factory: Invalid strategy");
        require(defaultOutcomes.length >= 2, "Factory: Min 2 outcomes");

        MarketTemplate storage template = templates[templateId];
        template.name = name;
        template.strategyType = strategyType;
        template.pricingStrategy = pricingStrategy;
        template.mapperTemplate = mapperTemplate;
        template.defaultInitialLiquidity = defaultInitialLiquidity;
        template.active = true;

        // 复制 defaultOutcomes
        delete template.defaultOutcomes;
        for (uint256 i = 0; i < defaultOutcomes.length; i++) {
            template.defaultOutcomes.push(defaultOutcomes[i]);
        }

        // 添加到模板列表（如果是新模板）
        bool found = false;
        for (uint256 i = 0; i < templateIds.length; i++) {
            if (templateIds[i] == templateId) {
                found = true;
                break;
            }
        }
        if (!found) {
            templateIds.push(templateId);
        }

        emit TemplateRegistered(templateId, name, strategyType);
    }

    /**
     * @notice 更新模板状态
     * @param templateId 模板 ID
     * @param active 是否激活
     */
    function setTemplateActive(bytes32 templateId, bool active)
        external
        onlyRole(OPERATOR_ROLE)
    {
        templates[templateId].active = active;
        emit TemplateUpdated(templateId, active);
    }

    // ============ 组件注册 ============

    /**
     * @notice 注册定价策略
     * @param strategyType 策略类型
     * @param strategy 策略合约地址
     */
    function registerStrategy(string memory strategyType, address strategy)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(strategy != address(0), "Factory: Invalid strategy");
        strategies[strategyType] = strategy;
        emit StrategyRegistered(strategyType, strategy);
    }

    /**
     * @notice 注册 Mapper
     * @param mapper Mapper 合约地址
     */
    function registerMapper(address mapper)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(mapper != address(0), "Factory: Invalid mapper");
        registeredMappers[mapper] = true;
        emit MapperRegistered(mapper);
    }

    // ============ 市场创建 ============

    /**
     * @notice 创建市场
     * @param params 创建参数
     * @return market 市场地址
     */
    function createMarket(CreateMarketParams calldata params)
        external
        onlyRole(OPERATOR_ROLE)
        returns (address market)
    {
        MarketTemplate storage template = templates[params.templateId];
        if (!template.active) revert TemplateNotActive();
        if (bytes(template.name).length == 0) revert InvalidTemplate();

        // Clone 部署市场
        market = marketImplementation.clone();

        // 确定 Mapper
        address mapper = template.mapperTemplate;
        if (params.mapperInitData.length > 0 && mapper != address(0)) {
            // 如果有初始化数据，可以在这里处理参数化 Mapper
            // 暂时直接使用模板 Mapper
        }

        // 确定初始流动性
        uint256 initialLiquidity = params.initialLiquidity > 0
            ? params.initialLiquidity
            : template.defaultInitialLiquidity;

        // 确定 outcome 规则
        IMarket_V3.OutcomeRule[] memory outcomes;
        if (params.outcomeRules.length > 0) {
            outcomes = params.outcomeRules;
        } else {
            outcomes = template.defaultOutcomes;
        }

        // 构建配置
        IMarket_V3.MarketConfig memory config = IMarket_V3.MarketConfig({
            marketId: keccak256(abi.encodePacked(params.matchId, params.templateId, block.timestamp)),
            matchId: params.matchId,
            kickoffTime: params.kickoffTime,
            settlementToken: settlementToken,
            pricingStrategy: IPricingStrategy(template.pricingStrategy),
            resultMapper: IResultMapper(mapper),
            vault: defaultVault,
            initialLiquidity: initialLiquidity,
            outcomeRules: outcomes,
            uri: "",
            admin: msg.sender
        });

        // 初始化市场
        IMarket_V3(market).initialize(config);

        // 授权角色
        if (trustedRouter != address(0)) {
            // 授权 Router
            bytes32 routerRole = keccak256("ROUTER_ROLE");
            AccessControl(market).grantRole(routerRole, trustedRouter);
        }

        if (keeper != address(0)) {
            bytes32 keeperRole = keccak256("KEEPER_ROLE");
            AccessControl(market).grantRole(keeperRole, keeper);
        }

        if (oracle != address(0)) {
            bytes32 oracleRole = keccak256("ORACLE_ROLE");
            AccessControl(market).grantRole(oracleRole, oracle);
        }

        // 注册市场
        isMarket[market] = true;
        markets.push(market);
        marketCount++;

        emit MarketCreated(market, params.templateId, params.matchId, params.kickoffTime);
    }

    // ============ 配置管理 ============

    /**
     * @notice 设置 Router
     * @param _router Router 地址
     */
    function setRouter(address _router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedRouter = _router;
        emit RouterUpdated(_router);
    }

    /**
     * @notice 设置 Keeper
     * @param _keeper Keeper 地址
     */
    function setKeeper(address _keeper) external onlyRole(DEFAULT_ADMIN_ROLE) {
        keeper = _keeper;
        emit KeeperUpdated(_keeper);
    }

    /**
     * @notice 设置 Oracle
     * @param _oracle Oracle 地址
     */
    function setOracle(address _oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    /**
     * @notice 设置默认 Vault
     * @param _vault Vault 地址
     */
    function setVault(address _vault) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultVault = _vault;
        emit VaultUpdated(_vault);
    }

    /**
     * @notice 更新 Market 实现
     * @param _implementation 新实现地址
     */
    function setImplementation(address _implementation)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_implementation != address(0), "Factory: Invalid implementation");
        marketImplementation = _implementation;
    }

    // ============ 查询函数 ============

    /**
     * @notice 获取所有模板 ID
     */
    function getTemplateIds() external view returns (bytes32[] memory) {
        return templateIds;
    }

    /**
     * @notice 获取模板详情
     */
    function getTemplate(bytes32 templateId)
        external
        view
        returns (
            string memory name,
            string memory strategyType,
            address pricingStrategy,
            address mapperTemplate,
            uint256 defaultInitialLiquidity,
            bool active
        )
    {
        MarketTemplate storage t = templates[templateId];
        return (
            t.name,
            t.strategyType,
            t.pricingStrategy,
            t.mapperTemplate,
            t.defaultInitialLiquidity,
            t.active
        );
    }

    /**
     * @notice 获取模板默认 outcomes
     */
    function getTemplateOutcomes(bytes32 templateId)
        external
        view
        returns (IMarket_V3.OutcomeRule[] memory)
    {
        return templates[templateId].defaultOutcomes;
    }

    /**
     * @notice 获取市场列表（分页）
     */
    function getMarkets(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        if (offset >= markets.length) {
            return new address[](0);
        }

        uint256 end = offset + limit;
        if (end > markets.length) {
            end = markets.length;
        }

        address[] memory result = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = markets[i];
        }

        return result;
    }

    /**
     * @notice 获取市场数量
     */
    function getMarketCount() external view returns (uint256) {
        return marketCount;
    }
}
