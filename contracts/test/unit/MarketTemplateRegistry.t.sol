// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/core/MarketTemplateRegistry.sol";
import "../../src/templates/WDL_Template.sol";

/**
 * @title MarketTemplateRegistryTest
 * @notice 测试 MarketTemplateRegistry 合约的所有功能
 */
contract MarketTemplateRegistryTest is BaseTest {
    MarketTemplateRegistry public registry;
    WDL_Template public wdlTemplate;

    // Mock template addresses
    address public mockTemplate1;
    address public mockTemplate2;

    // Template identifiers
    bytes32 public wdlTemplateId;
    bytes32 public ouTemplateId;

    event TemplateRegistered(
        bytes32 indexed templateId,
        address indexed implementation,
        string name,
        string version
    );

    event TemplateUnregistered(
        bytes32 indexed templateId,
        address indexed implementation
    );

    event TemplateActiveStatusUpdated(
        bytes32 indexed templateId,
        bool active
    );

    event MarketCreated(
        address indexed market,
        bytes32 indexed templateId,
        address indexed creator
    );

    function setUp() public override {
        super.setUp();

        // Deploy registry
        registry = new MarketTemplateRegistry();

        // Deploy a real WDL template for testing
        wdlTemplate = new WDL_Template(
            "TEST_MATCH",
            "Team A",
            "Team B",
            block.timestamp + 1 hours,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            address(cpmm),
            ""
        );

        // Create mock template addresses
        mockTemplate1 = makeAddr("mockTemplate1");
        mockTemplate2 = makeAddr("mockTemplate2");

        // Calculate template IDs
        wdlTemplateId = keccak256(abi.encodePacked("WDL", "1.0.0"));
        ouTemplateId = keccak256(abi.encodePacked("OU", "1.0.0"));

        vm.label(address(registry), "Registry");
        vm.label(address(wdlTemplate), "WDL_Template");
    }

    // ============ Constructor Tests ============

    function test_Constructor_SetsOwner() public view {
        assertEq(registry.owner(), address(this), "Owner should be deployer");
    }

    function test_Constructor_NotPaused() public view {
        assertFalse(registry.paused(), "Should not be paused initially");
    }

    // ============ registerTemplate Tests ============

    function test_RegisterTemplate_Success() public {
        // Expect event
        vm.expectEmit(true, true, false, true);
        emit TemplateRegistered(wdlTemplateId, mockTemplate1, "WDL", "1.0.0");

        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        // Verify template ID
        assertEq(templateId, wdlTemplateId, "Template ID mismatch");

        // Verify template info
        (
            address impl,
            string memory name,
            string memory version,
            bool active,
            uint256 createdAt,
            uint256 marketCount
        ) = registry.templates(templateId);

        assertEq(impl, mockTemplate1, "Implementation mismatch");
        assertEq(name, "WDL", "Name mismatch");
        assertEq(version, "1.0.0", "Version mismatch");
        assertTrue(active, "Should be active");
        assertEq(createdAt, block.timestamp, "CreatedAt mismatch");
        assertEq(marketCount, 0, "Market count should be 0");

        // Verify registration status
        assertTrue(registry.isRegistered(mockTemplate1), "Should be registered");
    }

    function test_RegisterTemplate_MultipleDifferent() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.registerTemplate("OU", "1.0.0", mockTemplate2);

        bytes32[] memory templateIds = registry.getAllTemplateIds();
        assertEq(templateIds.length, 2, "Should have 2 templates");
    }

    function test_RegisterTemplate_RevertIf_EmptyName() public {
        vm.expectRevert("Empty template name");
        registry.registerTemplate("", "1.0.0", mockTemplate1);
    }

    function test_RegisterTemplate_RevertIf_EmptyVersion() public {
        vm.expectRevert("Empty template version");
        registry.registerTemplate("WDL", "", mockTemplate1);
    }

    function test_RegisterTemplate_RevertIf_ZeroAddress() public {
        vm.expectRevert("Invalid implementation address");
        registry.registerTemplate("WDL", "1.0.0", address(0));
    }

    function test_RegisterTemplate_RevertIf_DuplicateImplementation() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.expectRevert("Implementation already registered");
        registry.registerTemplate("WDL", "2.0.0", mockTemplate1);
    }

    function test_RegisterTemplate_RevertIf_DuplicateNameVersion() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.expectRevert("Template already registered");
        registry.registerTemplate("WDL", "1.0.0", mockTemplate2);
    }

    function test_RegisterTemplate_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
    }

    // ============ unregisterTemplate Tests ============

    function test_UnregisterTemplate_Success() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.expectEmit(true, true, false, false);
        emit TemplateUnregistered(templateId, mockTemplate1);

        registry.unregisterTemplate(templateId);

        // Verify template is removed
        (address impl, , , , , ) = registry.templates(templateId);
        assertEq(impl, address(0), "Implementation should be zero");

        // Verify registration status
        assertFalse(registry.isRegistered(mockTemplate1), "Should not be registered");
    }

    function test_UnregisterTemplate_RevertIf_NotRegistered() public {
        vm.expectRevert("Template not registered");
        registry.unregisterTemplate(wdlTemplateId);
    }

    function test_UnregisterTemplate_RevertIf_NotOwner() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.prank(user1);
        vm.expectRevert();
        registry.unregisterTemplate(templateId);
    }

    // ============ setTemplateActive Tests ============

    function test_SetTemplateActive_Deactivate() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.expectEmit(true, false, false, true);
        emit TemplateActiveStatusUpdated(templateId, false);

        registry.setTemplateActive(templateId, false);

        (, , , bool active, , ) = registry.templates(templateId);
        assertFalse(active, "Should be inactive");
    }

    function test_SetTemplateActive_Reactivate() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.setTemplateActive(templateId, false);

        registry.setTemplateActive(templateId, true);

        (, , , bool active, , ) = registry.templates(templateId);
        assertTrue(active, "Should be active");
    }

    function test_SetTemplateActive_RevertIf_NotRegistered() public {
        vm.expectRevert("Template not registered");
        registry.setTemplateActive(wdlTemplateId, false);
    }

    function test_SetTemplateActive_RevertIf_NotOwner() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        vm.prank(user1);
        vm.expectRevert();
        registry.setTemplateActive(templateId, false);
    }

    // ============ Pause/Unpause Tests ============

    function test_Pause_Success() public {
        registry.pause();
        assertTrue(registry.paused(), "Should be paused");
    }

    function test_Unpause_Success() public {
        registry.pause();
        registry.unpause();
        assertFalse(registry.paused(), "Should not be paused");
    }

    function test_Pause_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        registry.pause();
    }

    function test_Unpause_RevertIf_NotOwner() public {
        registry.pause();

        vm.prank(user1);
        vm.expectRevert();
        registry.unpause();
    }

    // ============ Query Tests ============

    function test_GetTemplateInfo() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        MarketTemplateRegistry.TemplateInfo memory info = registry.getTemplateInfo(templateId);

        assertEq(info.implementation, mockTemplate1, "Implementation mismatch");
        assertEq(info.name, "WDL", "Name mismatch");
        assertEq(info.version, "1.0.0", "Version mismatch");
        assertTrue(info.active, "Should be active");
        assertEq(info.createdAt, block.timestamp, "CreatedAt mismatch");
        assertEq(info.marketCount, 0, "Market count should be 0");
    }

    function test_GetAllTemplateIds() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.registerTemplate("OU", "1.0.0", mockTemplate2);

        bytes32[] memory templateIds = registry.getAllTemplateIds();

        assertEq(templateIds.length, 2, "Should have 2 templates");
        assertEq(templateIds[0], wdlTemplateId, "First template ID mismatch");
        assertEq(templateIds[1], ouTemplateId, "Second template ID mismatch");
    }

    function test_GetActiveTemplateIds_AllActive() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.registerTemplate("OU", "1.0.0", mockTemplate2);

        bytes32[] memory activeIds = registry.getActiveTemplateIds();

        assertEq(activeIds.length, 2, "Should have 2 active templates");
    }

    function test_GetActiveTemplateIds_SomeInactive() public {
        bytes32 templateId1 = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.registerTemplate("OU", "1.0.0", mockTemplate2);

        registry.setTemplateActive(templateId1, false);

        bytes32[] memory activeIds = registry.getActiveTemplateIds();

        assertEq(activeIds.length, 1, "Should have 1 active template");
        assertEq(activeIds[0], ouTemplateId, "Active template ID mismatch");
    }

    function test_GetAllMarkets_EmptyInitially() public view {
        address[] memory markets = registry.getAllMarkets();
        assertEq(markets.length, 0, "Should have no markets initially");
    }

    function test_GetMarketCount_ZeroInitially() public view {
        assertEq(registry.getMarketCount(), 0, "Market count should be 0");
    }

    function test_GetTemplateMarketCount() public {
        bytes32 templateId = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);

        uint256 count = registry.getTemplateMarketCount(templateId);
        assertEq(count, 0, "Market count should be 0");
    }

    function test_CalculateTemplateId() public view {
        bytes32 expectedId = keccak256(abi.encodePacked("WDL", "1.0.0"));
        bytes32 calculatedId = registry.calculateTemplateId("WDL", "1.0.0");

        assertEq(calculatedId, expectedId, "Template ID calculation mismatch");
    }

    // ============ Edge Cases ============

    function test_RegisterMultipleVersions_SameTemplate() public {
        registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        registry.registerTemplate("WDL", "2.0.0", mockTemplate2);

        bytes32[] memory templateIds = registry.getAllTemplateIds();
        assertEq(templateIds.length, 2, "Should have 2 versions");
    }

    function test_UnregisterDoesNotAffectOtherTemplates() public {
        bytes32 templateId1 = registry.registerTemplate("WDL", "1.0.0", mockTemplate1);
        bytes32 templateId2 = registry.registerTemplate("OU", "1.0.0", mockTemplate2);

        registry.unregisterTemplate(templateId1);

        // Verify second template still exists
        (address impl, , , , , ) = registry.templates(templateId2);
        assertEq(impl, mockTemplate2, "Second template should still exist");
    }

    function test_TemplateIdCollisionResistance() public view {
        // Verify different name/version combinations produce different IDs
        bytes32 id1 = registry.calculateTemplateId("WDL", "1.0.0");
        bytes32 id2 = registry.calculateTemplateId("WDL", "2.0.0");
        bytes32 id3 = registry.calculateTemplateId("OU", "1.0.0");

        assertTrue(id1 != id2, "Different versions should have different IDs");
        assertTrue(id1 != id3, "Different templates should have different IDs");
        assertTrue(id2 != id3, "All IDs should be unique");
    }
}
