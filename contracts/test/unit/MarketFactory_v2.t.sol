// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/core/MarketFactory_v2.sol";
import "../../src/templates/WDL_Template_V2.sol";
import "../../src/liquidity/LiquidityVault.sol";

/**
 * @title MarketFactory_v2Test
 * @notice MarketFactory_v2 完整单元测试套件
 * @dev 测试 Clone 模式、权限控制、模板管理、recordMarket 等所有功能
 */
contract MarketFactory_v2Test is BaseTest {
    MarketFactory_v2 public factory;
    LiquidityVault public vault;
    WDL_Template_V2 public wdlTemplate;

    bytes32 public wdlTemplateId;

    function setUp() public override {
        super.setUp();

        // 部署工厂
        factory = new MarketFactory_v2();

        // 部署 Vault
        vault = new LiquidityVault(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );

        // 部署 WDL 模板（作为实现合约）
        wdlTemplate = new WDL_Template_V2(
            "TEMPLATE",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        // 注册模板
        vm.prank(owner);
        wdlTemplateId = factory.registerTemplate("WDL", "2.0.0", address(wdlTemplate));
    }

    // ============ 模板注册测试 ============

    function test_RegisterTemplate_Success() public {
        WDL_Template_V2 newTemplate = new WDL_Template_V2(
            "TEMPLATE2",
            "Team C",
            "Team D",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        bytes32 templateId = factory.registerTemplate("OU", "1.0.0", address(newTemplate));

        MarketFactory_v2.TemplateInfo memory info = factory.getTemplateInfo(templateId);

        assertEq(info.implementation, address(newTemplate), "Implementation address");
        assertEq(info.name, "OU", "Template name");
        assertEq(info.version, "1.0.0", "Template version");
        assertTrue(info.active, "Should be active");
        assertEq(info.marketCount, 0, "Market count = 0");
    }

    function testRevert_RegisterTemplate_AlreadyExists() public {
        // 注意：MarketFactory_v2.sol:132 先检查 isRegistered[implementation]
        // 所以实际的错误消息是 "Already registered"而不是 "Template exists"
        vm.prank(owner);
        vm.expectRevert("Already registered");
        factory.registerTemplate("WDL", "2.0.0", address(wdlTemplate)); // 相同 implementation
    }

    function testRevert_RegisterTemplate_EmptyName() public {
        vm.prank(owner);
        vm.expectRevert("Empty name");
        factory.registerTemplate("", "1.0.0", address(wdlTemplate));
    }

    function testRevert_RegisterTemplate_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        factory.registerTemplate("Test", "1.0.0", address(0));
    }

    function testRevert_RegisterTemplate_Unauthorized() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.registerTemplate("Test", "1.0.0", address(wdlTemplate));
    }

    function test_SetTemplateActive_TogglesStatus() public {
        vm.prank(owner);
        factory.setTemplateActive(wdlTemplateId, false);

        MarketFactory_v2.TemplateInfo memory info = factory.getTemplateInfo(wdlTemplateId);
        assertFalse(info.active, "Should be inactive");

        vm.prank(owner);
        factory.setTemplateActive(wdlTemplateId, true);

        info = factory.getTemplateInfo(wdlTemplateId);
        assertTrue(info.active, "Should be active again");
    }

    function testRevert_SetTemplateActive_NotFound() public {
        bytes32 invalidId = keccak256("invalid");

        vm.prank(owner);
        vm.expectRevert("Template not found");
        factory.setTemplateActive(invalidId, false);
    }

    // ============ 权限控制测试 ============

    function test_Constructor_GrantsRoles() public view {
        // 部署者应该拥有两个角色
        assertTrue(
            factory.hasRole(factory.DEFAULT_ADMIN_ROLE(), owner),
            "Owner should have DEFAULT_ADMIN_ROLE"
        );
        assertTrue(
            factory.hasRole(factory.MARKET_CREATOR_ROLE(), owner),
            "Owner should have MARKET_CREATOR_ROLE"
        );
    }

    function test_AddMarketCreator_GrantsRole() public {
        vm.prank(owner);
        factory.addMarketCreator(user1);

        assertTrue(
            factory.hasRole(factory.MARKET_CREATOR_ROLE(), user1),
            "User1 should have MARKET_CREATOR_ROLE"
        );
    }

    function test_RemoveMarketCreator_RevokesRole() public {
        vm.prank(owner);
        factory.addMarketCreator(user1);

        vm.prank(owner);
        factory.removeMarketCreator(user1);

        assertFalse(
            factory.hasRole(factory.MARKET_CREATOR_ROLE(), user1),
            "User1 should not have MARKET_CREATOR_ROLE"
        );
    }

    function testRevert_AddMarketCreator_Unauthorized() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.addMarketCreator(user2);
    }

    function test_BatchAddMarketCreators() public {
        address[] memory creators = new address[](3);
        creators[0] = user1;
        creators[1] = user2;
        creators[2] = user3;

        vm.prank(owner);
        factory.addMarketCreators(creators);

        assertTrue(factory.hasRole(factory.MARKET_CREATOR_ROLE(), user1), "User1");
        assertTrue(factory.hasRole(factory.MARKET_CREATOR_ROLE(), user2), "User2");
        assertTrue(factory.hasRole(factory.MARKET_CREATOR_ROLE(), user3), "User3");
    }

    function test_IsMarketCreator() public {
        vm.prank(owner);
        factory.addMarketCreator(user1);

        assertTrue(factory.isMarketCreator(user1), "User1 is creator");
        assertFalse(factory.isMarketCreator(user2), "User2 is not creator");
    }

    // ============ recordMarket 测试 ============

    function test_RecordMarket_RegistersExternal() public {
        // 直接部署一个新的 WDL 市场（不通过 factory.createMarket）
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        // 注册到 factory
        vm.prank(owner);
        bool success = factory.recordMarket(address(externalMarket), wdlTemplateId);

        assertTrue(success, "Should succeed");
        assertTrue(factory.isMarket(address(externalMarket)), "Should be registered");

        // 检查市场计数
        MarketFactory_v2.TemplateInfo memory info = factory.getTemplateInfo(wdlTemplateId);
        assertEq(info.marketCount, 1, "Market count should increase");
    }

    function testRevert_RecordMarket_DuplicateMarket() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(externalMarket), wdlTemplateId);

        // 尝试再次注册
        vm.prank(owner);
        vm.expectRevert("Market already registered");
        factory.recordMarket(address(externalMarket), wdlTemplateId);
    }

    function testRevert_RecordMarket_InactiveTemplate() public {
        // 禁用模板
        vm.prank(owner);
        factory.setTemplateActive(wdlTemplateId, false);

        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        vm.expectRevert("Template not active");
        factory.recordMarket(address(externalMarket), wdlTemplateId);
    }

    function testRevert_RecordMarket_Unauthorized() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(user1); // 没有 MARKET_CREATOR_ROLE
        vm.expectRevert();
        factory.recordMarket(address(externalMarket), wdlTemplateId);
    }

    // ============ Market Ownership 管理测试 ============

    function test_RecordMarket_TracksOwner() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(externalMarket), wdlTemplateId);

        // 检查 owner 记录
        address recordedOwner = factory.marketOwner(address(externalMarket));
        assertEq(recordedOwner, address(this), "Should record initial owner");
    }

    function test_UpdateMarketOwnerRecord_Syncs() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(externalMarket), wdlTemplateId);

        // 直接转移市场 ownership（绕过 factory）
        externalMarket.transferOwnership(user1);

        // 更新 factory 记录
        vm.prank(user1);
        factory.updateMarketOwnerRecord(address(externalMarket));

        assertEq(factory.marketOwner(address(externalMarket)), user1, "Owner synced");
    }

    function test_TransferMarketOwnership_ByAdmin() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        // 转移 ownership 给 factory（以便 factory 可以管理）
        externalMarket.transferOwnership(address(factory));

        vm.prank(owner);
        factory.recordMarket(address(externalMarket), wdlTemplateId);

        // Factory admin 强制转移
        vm.prank(owner);
        factory.transferMarketOwnership(address(externalMarket), user1);

        assertEq(factory.marketOwner(address(externalMarket)), user1, "Owner transferred");
    }

    function testRevert_TransferMarketOwnership_Unauthorized() public {
        WDL_Template_V2 externalMarket = new WDL_Template_V2(
            "EXTERNAL_MATCH",
            "Team X",
            "Team Y",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        externalMarket.transferOwnership(address(factory));

        vm.prank(owner);
        factory.recordMarket(address(externalMarket), wdlTemplateId);

        vm.prank(user2); // 非 admin
        vm.expectRevert();
        factory.transferMarketOwnership(address(externalMarket), user1);
    }

    function test_GetMarketOwners_ReturnsArray() public {
        // 创建多个市场
        WDL_Template_V2 market1 = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        WDL_Template_V2 market2 = new WDL_Template_V2(
            "M2",
            "C",
            "D",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.startPrank(owner);
        factory.recordMarket(address(market1), wdlTemplateId);
        factory.recordMarket(address(market2), wdlTemplateId);
        vm.stopPrank();

        address[] memory markets = new address[](2);
        markets[0] = address(market1);
        markets[1] = address(market2);

        address[] memory owners = factory.getMarketOwners(markets);

        assertEq(owners.length, 2, "Should return 2 owners");
        assertEq(owners[0], address(this), "Market1 owner");
        assertEq(owners[1], address(this), "Market2 owner");
    }

    // ============ 查询函数测试 ============

    function test_GetTemplateInfo() public view {
        MarketFactory_v2.TemplateInfo memory info = factory.getTemplateInfo(wdlTemplateId);

        assertEq(info.implementation, address(wdlTemplate), "Implementation");
        assertEq(info.name, "WDL", "Name");
        assertEq(info.version, "2.0.0", "Version");
        assertTrue(info.active, "Active");
    }

    function test_GetAllTemplateIds() public view {
        bytes32[] memory ids = factory.getAllTemplateIds();

        assertEq(ids.length, 1, "Should have 1 template");
        assertEq(ids[0], wdlTemplateId, "Template ID");
    }

    function test_GetMarketCount() public {
        assertEq(factory.getMarketCount(), 0, "Initial count = 0");

        // 注册一个市场
        WDL_Template_V2 market = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(market), wdlTemplateId);

        assertEq(factory.getMarketCount(), 1, "Count = 1");
    }

    function test_GetMarket() public {
        WDL_Template_V2 market = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(market), wdlTemplateId);

        address retrievedMarket = factory.getMarket(0);
        assertEq(retrievedMarket, address(market), "Should return correct market");
    }

    // ============ 暂停功能测试 ============

    function test_Pause_StopsMarketCreation() public {
        vm.prank(owner);
        factory.pause();

        WDL_Template_V2 market = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        vm.expectRevert();
        factory.recordMarket(address(market), wdlTemplateId);
    }

    function test_Unpause_ResumesMarketCreation() public {
        vm.prank(owner);
        factory.pause();

        vm.prank(owner);
        factory.unpause();

        WDL_Template_V2 market = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        factory.recordMarket(address(market), wdlTemplateId);

        assertTrue(factory.isMarket(address(market)), "Market registered");
    }

    // ============ 事件测试 ============

    function test_RegisterTemplate_EmitsEvent() public {
        WDL_Template_V2 newTemplate = new WDL_Template_V2(
            "T2",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        bytes32 expectedId = keccak256(abi.encode("OU", "1.0.0"));

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit TemplateRegistered(expectedId, address(newTemplate), "OU", "1.0.0");

        factory.registerTemplate("OU", "1.0.0", address(newTemplate));
    }

    event TemplateRegistered(
        bytes32 indexed templateId,
        address indexed implementation,
        string name,
        string version
    );

    function test_RecordMarket_EmitsEvent() public {
        WDL_Template_V2 market = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        vm.expectEmit(true, true, true, false);
        emit MarketCreated(address(market), wdlTemplateId, owner);

        factory.recordMarket(address(market), wdlTemplateId);
    }

    event MarketCreated(
        address indexed market,
        bytes32 indexed templateId,
        address indexed creator
    );

    // ============ 多模板测试 ============

    function test_MultipleTemplates_Coexist() public {
        // 注册第二个模板
        WDL_Template_V2 ouTemplate = new WDL_Template_V2(
            "OU_TEMPLATE",
            "Team",
            "Team",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.prank(owner);
        bytes32 ouTemplateId = factory.registerTemplate("OU", "1.0.0", address(ouTemplate));

        bytes32[] memory ids = factory.getAllTemplateIds();
        assertEq(ids.length, 2, "Should have 2 templates");

        // 验证两个模板都可用
        assertTrue(factory.getTemplateInfo(wdlTemplateId).active, "WDL active");
        assertTrue(factory.getTemplateInfo(ouTemplateId).active, "OU active");
    }

    function test_TemplateMarketCount_Independent() public {
        // 创建两个使用同一模板的市场
        WDL_Template_V2 market1 = new WDL_Template_V2(
            "M1",
            "A",
            "B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        WDL_Template_V2 market2 = new WDL_Template_V2(
            "M2",
            "C",
            "D",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "uri"
        );

        vm.startPrank(owner);
        factory.recordMarket(address(market1), wdlTemplateId);
        factory.recordMarket(address(market2), wdlTemplateId);
        vm.stopPrank();

        MarketFactory_v2.TemplateInfo memory info = factory.getTemplateInfo(wdlTemplateId);
        assertEq(info.marketCount, 2, "Should have 2 markets");
    }
}
