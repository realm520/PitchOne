// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/MarketFactory_v2.sol";
import "../../src/core/MarketFactory_v3.sol";

/**
 * @notice Mock 市场合约（用于 gas 测试）
 */
contract MockMarket {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
}

contract MarketFactory_GasComparisonTest is Test {
    MarketFactory_v2 public factoryV2;
    MarketFactory_v3 public factoryV3;

    MockMarket public mockTemplate;
    bytes32 public templateId;

    function setUp() public {
        // 部署两个版本的 Factory
        factoryV2 = new MarketFactory_v2();
        factoryV3 = new MarketFactory_v3();

        // 部署 Mock 模板
        mockTemplate = new MockMarket();

        // 在两个 Factory 中注册相同的模板
        templateId = factoryV2.registerTemplate(
            "Mock",
            "1.0.0",
            address(mockTemplate)
        );

        factoryV3.registerTemplate(
            "Mock",
            "1.0.0",
            address(mockTemplate)
        );
    }

    /**
     * @notice V2 版本 - 使用 recordMarket
     */
    function test_Gas_RecordMarket_V2() public {
        // 创建一个 Mock 市场实例
        MockMarket market = new MockMarket();

        // 记录市场（测试 gas 消耗）
        factoryV2.recordMarket(address(market), templateId);
    }

    /**
     * @notice V3 版本 - 使用优化的 recordMarket
     */
    function test_Gas_RecordMarket_V3() public {
        // 创建一个 Mock 市场实例
        MockMarket market = new MockMarket();

        // 记录市场（测试 gas 消耗）
        factoryV3.recordMarket(address(market), templateId);
    }

    /**
     * @notice 批量记录测试 - V2
     */
    function test_Gas_RecordMarket_V2_Batch10() public {
        for (uint256 i = 0; i < 10; i++) {
            MockMarket market = new MockMarket();
            factoryV2.recordMarket(address(market), templateId);
        }
    }

    /**
     * @notice 批量记录测试 - V3
     */
    function test_Gas_RecordMarket_V3_Batch10() public {
        for (uint256 i = 0; i < 10; i++) {
            MockMarket market = new MockMarket();
            factoryV3.recordMarket(address(market), templateId);
        }
    }

    /**
     * @notice 功能对比测试：确保优化后功能一致
     */
    function test_FunctionalityComparison() public {
        // 创建两个相同的市场
        MockMarket marketV2 = new MockMarket();
        MockMarket marketV3 = new MockMarket();

        // 记录市场
        factoryV2.recordMarket(address(marketV2), templateId);
        factoryV3.recordMarket(address(marketV3), templateId);

        // 验证功能一致性

        // 1. 市场计数
        assertEq(factoryV2.getMarketCount(), factoryV3.getMarketCount(), "Market count mismatch");

        // 2. 市场存在性
        assertTrue(factoryV2.isMarket(address(marketV2)), "V2: Market not found");
        assertTrue(factoryV3.isMarket(address(marketV3)), "V3: Market not found");

        // 3. 模板 ID
        assertEq(factoryV2.marketTemplate(address(marketV2)), templateId, "V2: Template ID mismatch");
        assertEq(factoryV3.marketTemplate(address(marketV3)), templateId, "V3: Template ID mismatch");

        // 4. 市场检索
        assertEq(factoryV2.getMarket(0), address(marketV2), "V2: Market retrieval failed");
        assertEq(factoryV3.getMarket(0), address(marketV3), "V3: Market retrieval failed");
    }

    /**
     * @notice 查询性能对比
     */
    function test_Gas_QueryPerformance_V2() public {
        // 先创建 10 个市场
        for (uint256 i = 0; i < 10; i++) {
            MockMarket market = new MockMarket();
            factoryV2.recordMarket(address(market), templateId);
        }

        // 测试查询性能
        factoryV2.getMarketCount();
    }

    function test_Gas_QueryPerformance_V3() public {
        // 先创建 10 个市场
        for (uint256 i = 0; i < 10; i++) {
            MockMarket market = new MockMarket();
            factoryV3.recordMarket(address(market), templateId);
        }

        // 测试查询性能
        factoryV3.getMarketCount();
    }
}
