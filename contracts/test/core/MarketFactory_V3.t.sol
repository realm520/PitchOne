// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/MarketFactory_V3.sol";
import "../../src/core/Market_V3.sol";
import "../../src/interfaces/IMarket_V3.sol";
import "../../src/interfaces/IPricingStrategy.sol";
import "../../src/pricing/CPMMStrategy.sol";
import "../../src/mappers/WDL_Mapper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000_000e6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title MarketFactory_V3_Test
 * @notice MarketFactory_V3 单元测试
 */
contract MarketFactory_V3_Test is Test {
    MarketFactory_V3 public factory;
    Market_V3 public marketImpl;
    CPMMStrategy public strategy;
    WDL_Mapper public mapper;
    MockUSDC public usdc;

    address public admin = address(1);
    address public operator = address(2);
    address public router = address(3);
    address public keeper = address(4);
    address public oracle = address(5);
    address public vault = address(6);
    address public user = address(7);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    uint256 constant INITIAL_LIQUIDITY = 100_000e6;

    IMarket_V3.OutcomeRule[] public defaultRules;

    function setUp() public {
        vm.startPrank(admin);

        // 部署依赖合约
        usdc = new MockUSDC();
        strategy = new CPMMStrategy();
        mapper = new WDL_Mapper();

        // 部署 Factory（先用临时实现地址）
        factory = new MarketFactory_V3(
            address(1), // 临时占位
            address(usdc),
            admin
        );

        // 部署 Market 实现
        marketImpl = new Market_V3(address(factory));

        // 更新实现地址
        factory.setImplementation(address(marketImpl));

        // 授予 operator 角色
        factory.grantRole(OPERATOR_ROLE, operator);

        vm.stopPrank();

        // 准备默认 outcome 规则
        defaultRules.push(IMarket_V3.OutcomeRule({
            name: "Home Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        }));
        defaultRules.push(IMarket_V3.OutcomeRule({
            name: "Draw",
            payoutType: IPricingStrategy.PayoutType.WINNER
        }));
        defaultRules.push(IMarket_V3.OutcomeRule({
            name: "Away Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        }));
    }

    // ============ 构造函数测试 ============

    function test_constructor_Success() public view {
        assertEq(factory.settlementToken(), address(usdc));
        assertEq(factory.marketImplementation(), address(marketImpl));
        assertTrue(factory.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(factory.hasRole(OPERATOR_ROLE, admin));
    }

    function test_constructor_InvalidImplementation_Reverts() public {
        vm.expectRevert("Factory: Invalid implementation");
        new MarketFactory_V3(address(0), address(usdc), admin);
    }

    function test_constructor_InvalidToken_Reverts() public {
        vm.expectRevert("Factory: Invalid token");
        new MarketFactory_V3(address(marketImpl), address(0), admin);
    }

    function test_constructor_InvalidAdmin_Reverts() public {
        vm.expectRevert("Factory: Invalid admin");
        new MarketFactory_V3(address(marketImpl), address(usdc), address(0));
    }

    // ============ 模板注册测试 ============

    function test_registerTemplate_Success() public {
        bytes32 templateId = keccak256("WDL");

        vm.prank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );

        (
            string memory name,
            string memory strategyType,
            address pricingStrategy,
            address mapperTemplate,
            uint256 defaultInitialLiquidity,
            bool active
        ) = factory.getTemplate(templateId);

        assertEq(name, "WDL");
        assertEq(strategyType, "CPMM");
        assertEq(pricingStrategy, address(strategy));
        assertEq(mapperTemplate, address(mapper));
        assertEq(defaultInitialLiquidity, INITIAL_LIQUIDITY);
        assertTrue(active);
    }

    function test_registerTemplate_EmitsEvent() public {
        bytes32 templateId = keccak256("WDL");

        vm.expectEmit(true, false, false, true);
        emit MarketFactory_V3.TemplateRegistered(templateId, "WDL", "CPMM");

        vm.prank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );
    }

    function test_registerTemplate_InvalidStrategy_Reverts() public {
        bytes32 templateId = keccak256("WDL");

        vm.prank(operator);
        vm.expectRevert("Factory: Invalid strategy");
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(0),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );
    }

    function test_registerTemplate_TooFewOutcomes_Reverts() public {
        bytes32 templateId = keccak256("WDL");
        IMarket_V3.OutcomeRule[] memory singleOutcome = new IMarket_V3.OutcomeRule[](1);
        singleOutcome[0] = IMarket_V3.OutcomeRule({
            name: "Only",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        vm.prank(operator);
        vm.expectRevert("Factory: Min 2 outcomes");
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            singleOutcome,
            INITIAL_LIQUIDITY
        );
    }

    function test_registerTemplate_NonOperator_Reverts() public {
        bytes32 templateId = keccak256("WDL");

        vm.prank(user);
        vm.expectRevert();
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );
    }

    function test_registerTemplate_UpdateExisting() public {
        bytes32 templateId = keccak256("WDL");

        // 首次注册
        vm.prank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );

        // 更新同一模板
        vm.prank(operator);
        factory.registerTemplate(
            templateId,
            "WDL_Updated",
            "LMSR",
            address(strategy),
            address(mapper),
            defaultRules,
            200_000e6
        );

        (string memory name, string memory strategyType, , , uint256 liquidity, ) = factory.getTemplate(templateId);
        assertEq(name, "WDL_Updated");
        assertEq(strategyType, "LMSR");
        assertEq(liquidity, 200_000e6);
    }

    // ============ 模板状态测试 ============

    function test_setTemplateActive_Success() public {
        bytes32 templateId = keccak256("WDL");

        vm.startPrank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );

        factory.setTemplateActive(templateId, false);
        vm.stopPrank();

        (, , , , , bool active) = factory.getTemplate(templateId);
        assertFalse(active);
    }

    function test_setTemplateActive_EmitsEvent() public {
        bytes32 templateId = keccak256("WDL");

        vm.startPrank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );

        vm.expectEmit(true, false, false, true);
        emit MarketFactory_V3.TemplateUpdated(templateId, false);

        factory.setTemplateActive(templateId, false);
        vm.stopPrank();
    }

    // ============ 市场创建测试 ============

    function test_createMarket_Success() public {
        bytes32 templateId = _registerDefaultTemplate();

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(operator);
        address marketAddr = factory.createMarket(params);

        assertTrue(marketAddr != address(0));
        assertTrue(factory.isMarket(marketAddr));
        assertEq(factory.marketCount(), 1);
        assertEq(factory.getMarket(0), marketAddr);
    }

    function test_createMarket_EmitsEvent() public {
        bytes32 templateId = _registerDefaultTemplate();

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(operator);
        vm.expectEmit(false, true, false, true);
        emit MarketFactory_V3.MarketCreated(address(0), templateId, "EPL_2024_MUN_vs_MCI", block.timestamp + 1 days);

        factory.createMarket(params);
    }

    function test_createMarket_InactiveTemplate_Reverts() public {
        bytes32 templateId = _registerDefaultTemplate();

        vm.prank(operator);
        factory.setTemplateActive(templateId, false);

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(operator);
        vm.expectRevert(MarketFactory_V3.TemplateNotActive.selector);
        factory.createMarket(params);
    }

    function test_createMarket_InvalidTemplate_Reverts() public {
        bytes32 invalidTemplateId = keccak256("NONEXISTENT");

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: invalidTemplateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(operator);
        vm.expectRevert(MarketFactory_V3.TemplateNotActive.selector);
        factory.createMarket(params);
    }

    function test_createMarket_NonOperator_Reverts() public {
        bytes32 templateId = _registerDefaultTemplate();

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(user);
        vm.expectRevert();
        factory.createMarket(params);
    }

    function test_createMarket_UsesTemplateDefaults() public {
        bytes32 templateId = _registerDefaultTemplate();

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: 0, // 使用模板默认值
            outcomeRules: new IMarket_V3.OutcomeRule[](0) // 使用模板默认规则
        });

        vm.prank(operator);
        address marketAddr = factory.createMarket(params);

        Market_V3 market = Market_V3(marketAddr);
        assertEq(market.outcomeCount(), 3);
    }

    function test_createMarket_WithRouterRole() public {
        bytes32 templateId = _registerDefaultTemplate();

        vm.prank(admin);
        factory.setRouter(router);

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(operator);
        address marketAddr = factory.createMarket(params);

        Market_V3 market = Market_V3(marketAddr);
        bytes32 ROUTER_ROLE = keccak256("ROUTER_ROLE");
        assertTrue(market.hasRole(ROUTER_ROLE, router));
    }

    function test_createMarket_MultipleMarkets() public {
        bytes32 templateId = _registerDefaultTemplate();

        for (uint256 i = 0; i < 5; i++) {
            MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
                templateId: templateId,
                matchId: string(abi.encodePacked("MATCH_", vm.toString(i))),
                kickoffTime: block.timestamp + 1 days + i * 1 hours,
                mapperInitData: "",
                initialLiquidity: INITIAL_LIQUIDITY,
                outcomeRules: new IMarket_V3.OutcomeRule[](0)
            });

            vm.prank(operator);
            factory.createMarket(params);
        }

        assertEq(factory.marketCount(), 5);
        assertEq(factory.getMarketCount(), 5);
    }

    // ============ 配置管理测试 ============

    function test_setRouter_Success() public {
        vm.prank(admin);
        factory.setRouter(router);

        assertEq(factory.trustedRouter(), router);
    }

    function test_setRouter_EmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit MarketFactory_V3.RouterUpdated(router);

        vm.prank(admin);
        factory.setRouter(router);
    }

    function test_setRouter_NonAdmin_Reverts() public {
        vm.prank(user);
        vm.expectRevert();
        factory.setRouter(router);
    }

    function test_addKeeper_Success() public {
        vm.prank(admin);
        factory.addKeeper(keeper);

        assertTrue(factory.isKeeper(keeper));
        assertEq(factory.keeper(), keeper);
        assertEq(factory.getKeepers().length, 1);
        assertEq(factory.getKeepers()[0], keeper);
    }

    function test_addKeeper_Multiple() public {
        address keeper2 = makeAddr("keeper2");
        address keeper3 = makeAddr("keeper3");

        vm.startPrank(admin);
        factory.addKeeper(keeper);
        factory.addKeeper(keeper2);
        factory.addKeeper(keeper3);
        vm.stopPrank();

        assertTrue(factory.isKeeper(keeper));
        assertTrue(factory.isKeeper(keeper2));
        assertTrue(factory.isKeeper(keeper3));
        assertEq(factory.getKeepers().length, 3);
    }

    function test_addKeeper_ZeroAddress_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(MarketFactory_V3.ZeroAddress.selector);
        factory.addKeeper(address(0));
    }

    function test_addKeeper_AlreadyKeeper_Reverts() public {
        vm.startPrank(admin);
        factory.addKeeper(keeper);

        vm.expectRevert(abi.encodeWithSelector(MarketFactory_V3.AlreadyKeeper.selector, keeper));
        factory.addKeeper(keeper);
        vm.stopPrank();
    }

    function test_removeKeeper_Success() public {
        vm.startPrank(admin);
        factory.addKeeper(keeper);
        factory.removeKeeper(keeper);
        vm.stopPrank();

        assertFalse(factory.isKeeper(keeper));
        assertEq(factory.getKeepers().length, 0);
        assertEq(factory.keeper(), address(0));
    }

    function test_removeKeeper_NotKeeper_Reverts() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(MarketFactory_V3.NotKeeper.selector, keeper));
        factory.removeKeeper(keeper);
    }

    function test_removeKeeper_UpdatesKeeperVariable() public {
        address keeper2 = makeAddr("keeper2");

        vm.startPrank(admin);
        factory.addKeeper(keeper);
        factory.addKeeper(keeper2);

        // keeper 是第一个，所以 factory.keeper() == keeper
        assertEq(factory.keeper(), keeper);

        // 移除第一个 keeper
        factory.removeKeeper(keeper);

        // factory.keeper() 应该更新为 keeper2
        assertEq(factory.keeper(), keeper2);
        vm.stopPrank();
    }

    function test_setOracle_Success() public {
        vm.prank(admin);
        factory.setOracle(oracle);

        assertEq(factory.oracle(), oracle);
    }

    function test_setVault_Success() public {
        vm.prank(admin);
        factory.setVault(vault);

        assertEq(factory.defaultVault(), vault);
    }

    function test_setImplementation_Success() public {
        Market_V3 newImpl = new Market_V3(address(factory));

        vm.prank(admin);
        factory.setImplementation(address(newImpl));

        assertEq(factory.marketImplementation(), address(newImpl));
    }

    function test_setImplementation_InvalidAddress_Reverts() public {
        vm.prank(admin);
        vm.expectRevert("Factory: Invalid implementation");
        factory.setImplementation(address(0));
    }

    // ============ 组件注册测试 ============

    function test_registerStrategy_Success() public {
        vm.prank(operator);
        factory.registerStrategy("CPMM", address(strategy));

        assertEq(factory.strategies("CPMM"), address(strategy));
    }

    function test_registerStrategy_EmitsEvent() public {
        vm.expectEmit(false, false, false, true);
        emit MarketFactory_V3.StrategyRegistered("CPMM", address(strategy));

        vm.prank(operator);
        factory.registerStrategy("CPMM", address(strategy));
    }

    function test_registerMapper_Success() public {
        vm.prank(operator);
        factory.registerMapper(address(mapper));

        assertTrue(factory.registeredMappers(address(mapper)));
    }

    function test_registerMapper_EmitsEvent() public {
        vm.expectEmit(false, false, false, true);
        emit MarketFactory_V3.MapperRegistered(address(mapper));

        vm.prank(operator);
        factory.registerMapper(address(mapper));
    }

    // ============ 查询函数测试 ============

    function test_getTemplateIds() public {
        bytes32 templateId1 = keccak256("WDL");
        bytes32 templateId2 = keccak256("OU");

        vm.startPrank(operator);
        factory.registerTemplate(templateId1, "WDL", "CPMM", address(strategy), address(mapper), defaultRules, INITIAL_LIQUIDITY);
        factory.registerTemplate(templateId2, "OU", "CPMM", address(strategy), address(mapper), defaultRules, INITIAL_LIQUIDITY);
        vm.stopPrank();

        bytes32[] memory ids = factory.getTemplateIds();
        assertEq(ids.length, 2);
        assertEq(ids[0], templateId1);
        assertEq(ids[1], templateId2);
    }

    function test_getTemplateOutcomes() public {
        bytes32 templateId = _registerDefaultTemplate();

        IMarket_V3.OutcomeRule[] memory outcomes = factory.getTemplateOutcomes(templateId);
        assertEq(outcomes.length, 3);
        assertEq(outcomes[0].name, "Home Win");
        assertEq(outcomes[1].name, "Draw");
        assertEq(outcomes[2].name, "Away Win");
    }

    function test_getMarkets_Pagination() public {
        bytes32 templateId = _registerDefaultTemplate();

        // 创建 10 个市场
        for (uint256 i = 0; i < 10; i++) {
            MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
                templateId: templateId,
                matchId: string(abi.encodePacked("MATCH_", vm.toString(i))),
                kickoffTime: block.timestamp + 1 days + i * 1 hours,
                mapperInitData: "",
                initialLiquidity: INITIAL_LIQUIDITY,
                outcomeRules: new IMarket_V3.OutcomeRule[](0)
            });

            vm.prank(operator);
            factory.createMarket(params);
        }

        // 测试分页
        address[] memory page1 = factory.getMarkets(0, 5);
        assertEq(page1.length, 5);

        address[] memory page2 = factory.getMarkets(5, 5);
        assertEq(page2.length, 5);

        address[] memory page3 = factory.getMarkets(8, 5);
        assertEq(page3.length, 2); // 只剩 2 个

        address[] memory emptyPage = factory.getMarkets(15, 5);
        assertEq(emptyPage.length, 0);
    }

    function test_getMarket_OutOfBounds_Reverts() public {
        vm.expectRevert("Factory: Index out of bounds");
        factory.getMarket(0);
    }

    // ============ 辅助函数 ============

    function _registerDefaultTemplate() internal returns (bytes32) {
        bytes32 templateId = keccak256("WDL");

        vm.prank(operator);
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            defaultRules,
            INITIAL_LIQUIDITY
        );

        return templateId;
    }
}
