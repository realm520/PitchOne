// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {LinkedLinesController} from "../src/pricing/LinkedLinesController.sol";
import {SimpleCPMM} from "../src/pricing/SimpleCPMM.sol";
import {ParamController} from "../src/governance/ParamController.sol";

contract LinkedLinesControllerTest is Test {
    LinkedLinesController public controller;
    ParamController public paramController;
    SimpleCPMM public cpmm20;  // OU 2.0
    SimpleCPMM public cpmm25;  // OU 2.5
    SimpleCPMM public cpmm30;  // OU 3.0

    address public admin = address(this);
    address public operator = address(0x1);

    bytes32 public constant GROUP_ID = keccak256("OU_MATCH_123");

    uint256 public constant LINE_20 = 2000;  // 2.0 球
    uint256 public constant LINE_25 = 2500;  // 2.5 球
    uint256 public constant LINE_30 = 3000;  // 3.0 球

    function setUp() public {
        // 部署 ParamController
        paramController = new ParamController(admin, 2 days);

        // 部署 LinkedLinesController
        controller = new LinkedLinesController(admin, address(paramController));

        // 授予操作员角色
        controller.grantRole(controller.OPERATOR_ROLE(), operator);

        // 部署 CPMM 实例
        cpmm20 = new SimpleCPMM(100_000 * 10**6);
        cpmm25 = new SimpleCPMM(100_000 * 10**6);
        cpmm30 = new SimpleCPMM(100_000 * 10**6);
    }

    /*//////////////////////////////////////////////////////////////
                          LINE GROUP TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CreateLineGroup() public {
        uint256[] memory lines = new uint256[](3);
        lines[0] = LINE_20;
        lines[1] = LINE_25;
        lines[2] = LINE_30;

        controller.createLineGroup(GROUP_ID, lines);

        (uint256[] memory storedLines, bool isActive) = controller.getLineGroup(GROUP_ID);

        assertTrue(isActive);
        assertEq(storedLines.length, 3);
        assertEq(storedLines[0], LINE_20);
        assertEq(storedLines[1], LINE_25);
        assertEq(storedLines[2], LINE_30);
    }

    function test_CreateLineGroup_RevertIfNotSorted() public {
        uint256[] memory lines = new uint256[](3);
        lines[0] = LINE_30;  // 错误顺序
        lines[1] = LINE_20;
        lines[2] = LINE_25;

        vm.expectRevert(LinkedLinesController.InvalidLineOrder.selector);
        controller.createLineGroup(GROUP_ID, lines);
    }

    function test_CreateLineGroup_RevertIfLessThan2Lines() public {
        uint256[] memory lines = new uint256[](1);
        lines[0] = LINE_20;

        vm.expectRevert("At least 2 lines required");
        controller.createLineGroup(GROUP_ID, lines);
    }

    function test_CreateLineGroup_RevertIfAlreadyExists() public {
        uint256[] memory lines = new uint256[](2);
        lines[0] = LINE_20;
        lines[1] = LINE_25;

        controller.createLineGroup(GROUP_ID, lines);

        vm.expectRevert("Group already exists");
        controller.createLineGroup(GROUP_ID, lines);
    }

    /*//////////////////////////////////////////////////////////////
                          LINE CONFIG TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConfigureLine() public {
        _createBasicLineGroup();

        controller.configureLine(GROUP_ID, LINE_20, address(cpmm20), 1000e18, 1000e18);

        LinkedLinesController.LineConfig memory config = controller.getLineConfig(GROUP_ID, LINE_20);

        assertEq(config.line, LINE_20);
        assertTrue(config.isActive);
        assertEq(config.cpmm, address(cpmm20));
        assertEq(config.baseReserve0, 1000e18);
        assertEq(config.baseReserve1, 1000e18);
    }

    function test_ConfigureLine_RevertGroupNotFound() public {
        bytes32 fakeGroupId = keccak256("FAKE");

        vm.expectRevert(abi.encodeWithSelector(LinkedLinesController.LineGroupNotFound.selector, fakeGroupId));
        controller.configureLine(fakeGroupId, LINE_20, address(cpmm20), 1000e18, 1000e18);
    }

    function test_ConfigureLine_RevertLineNotInGroup() public {
        _createBasicLineGroup();

        uint256 invalidLine = 1500;

        vm.expectRevert(abi.encodeWithSelector(LinkedLinesController.LineNotFound.selector, GROUP_ID, invalidLine));
        controller.configureLine(GROUP_ID, invalidLine, address(cpmm20), 1000e18, 1000e18);
    }

    /*//////////////////////////////////////////////////////////////
                          LINK CONFIG TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConfigureLink() public {
        _createBasicLineGroup();

        controller.configureLink(
            GROUP_ID,
            LINE_20,    // lower line
            LINE_25,    // upper line
            8000,       // 80% coefficient
            50,         // 0.5% min spread
            500         // 5% max spread
        );

        bytes32 linkId = keccak256(abi.encodePacked(GROUP_ID, LINE_20, LINE_25));
        (uint256 lowerLine, uint256 upperLine, uint256 coefficient, uint256 minSpread, uint256 maxSpread) =
            controller.linkConfigs(linkId);

        assertEq(lowerLine, LINE_20);
        assertEq(upperLine, LINE_25);
        assertEq(coefficient, 8000);
        assertEq(minSpread, 50);
        assertEq(maxSpread, 500);
    }

    function test_ConfigureLink_RevertInvalidOrder() public {
        _createBasicLineGroup();

        vm.expectRevert(LinkedLinesController.InvalidLineOrder.selector);
        controller.configureLink(GROUP_ID, LINE_25, LINE_20, 8000, 50, 500);
    }

    function test_ConfigureLink_RevertInvalidCoefficient() public {
        _createBasicLineGroup();

        vm.expectRevert(abi.encodeWithSelector(LinkedLinesController.InvalidCoefficient.selector, 4000));
        controller.configureLink(GROUP_ID, LINE_20, LINE_25, 4000, 50, 500);

        vm.expectRevert(abi.encodeWithSelector(LinkedLinesController.InvalidCoefficient.selector, 11000));
        controller.configureLink(GROUP_ID, LINE_20, LINE_25, 11000, 50, 500);
    }

    function test_ConfigureLink_RevertInvalidSpread() public {
        _createBasicLineGroup();

        vm.expectRevert(abi.encodeWithSelector(LinkedLinesController.InvalidSpread.selector, 500, 50));
        controller.configureLink(GROUP_ID, LINE_20, LINE_25, 8000, 500, 50);
    }

    /*//////////////////////////////////////////////////////////////
                          PRICE CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetLinkedPrice() public {
        _createAndConfigureFullGroup();

        // 准备储备量参数
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1000e18;
        reserves[1] = 1000e18;

        // 查询 2.0 球 OVER 价格
        uint256 price = controller.getLinkedPrice(GROUP_ID, LINE_20, 0, reserves);

        // 初始储备相等，价格应该接近 50%（5000 bp）
        assertApproxEqRel(price, 5000, 0.01e18); // 1% tolerance
    }

    function test_GetAllLinkedPrices() public {
        _createAndConfigureFullGroup();

        // 准备所有线的储备量
        uint256[][] memory allReserves = new uint256[][](3);
        for (uint256 i = 0; i < 3; i++) {
            allReserves[i] = new uint256[](2);
            allReserves[i][0] = 1000e18;
            allReserves[i][1] = 1000e18;
        }

        (uint256[] memory lines, uint256[] memory prices) = controller.getAllLinkedPrices(GROUP_ID, 0, allReserves);

        assertEq(lines.length, 3);
        assertEq(prices.length, 3);

        // 所有价格都应该接近 50%
        for (uint256 i = 0; i < prices.length; i++) {
            assertApproxEqRel(prices[i], 5000, 0.01e18);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ARBITRAGE DETECTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DetectArbitrage_NoArbitrage() public {
        _createAndConfigureFullGroup();

        // 准备所有线的储备量（合理的价差，无套利）
        // 注意：SimpleCPMM.getPrice(outcomeId, reserves)
        // 对于二向市场，price = reserves[1-outcomeId] / (reserves[0] + reserves[1])
        //
        // outcome=0 价格 = reserves[1] / total
        // 所以要让 outcome=0 (OVER) 价格高，需要 reserves[1] 大
        //
        // 价差限制：minSpread=50 (0.5%), maxSpread=500 (5%)
        // 所以相邻线的价差应该在 0.5%-5% 之间
        //
        // 2.0 球：OVER 概率 52% (最容易OVER)
        // 2.5 球：OVER 概率 50%
        // 3.0 球：OVER 概率 48% (最难OVER)
        // 价差：(52-50)/52 = 3.8%，(50-48)/50 = 4% (都在范围内)
        uint256[][] memory allReserves = new uint256[][](3);

        // 2.0 球：r0=480, r1=520 → outcome=0价格 = 520/1000 = 52%
        allReserves[0] = new uint256[](2);
        allReserves[0][0] = 480e18;
        allReserves[0][1] = 520e18;

        // 2.5 球：r0=500, r1=500 → outcome=0价格 = 500/1000 = 50%
        allReserves[1] = new uint256[](2);
        allReserves[1][0] = 500e18;
        allReserves[1][1] = 500e18;

        // 3.0 球：r0=520, r1=480 → outcome=0价格 = 480/1000 = 48%
        allReserves[2] = new uint256[](2);
        allReserves[2][0] = 520e18;
        allReserves[2][1] = 480e18;

        (bool hasArbitrage, uint256 line1, uint256 line2, uint256 profitBps) =
            controller.detectArbitrage(GROUP_ID, allReserves);

        assertFalse(hasArbitrage);
        assertEq(line1, 0);
        assertEq(line2, 0);
        assertEq(profitBps, 0);
    }

    function test_DetectArbitrage_PriceInversion() public {
        _createAndConfigureFullGroup();

        // 模拟价格反转：让 2.5 球 OVER 价格 > 2.0 球 OVER 价格
        // 这在现实中不应该发生（2.0 更容易 OVER）

        // 通过模拟下注来改变储备量（这里简化处理，实际测试中需要更复杂的设置）
        // TODO: 添加模拟套利场景的测试

        // 暂时跳过，因为需要更复杂的 CPMM 状态设置
        vm.skip(true);
    }

    /*//////////////////////////////////////////////////////////////
                          RESERVE ADJUSTMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AdjustReserves() public {
        _createAndConfigureFullGroup();

        uint256 newReserve0 = 1500e18;
        uint256 newReserve1 = 800e18;

        vm.prank(operator);
        controller.adjustReserves(GROUP_ID, LINE_20, newReserve0, newReserve1);

        LinkedLinesController.LineConfig memory config = controller.getLineConfig(GROUP_ID, LINE_20);

        assertEq(config.baseReserve0, newReserve0);
        assertEq(config.baseReserve1, newReserve1);
    }

    function test_AdjustReserves_RevertNotOperator() public {
        _createAndConfigureFullGroup();

        vm.prank(address(0x999));
        vm.expectRevert();
        controller.adjustReserves(GROUP_ID, LINE_20, 1500e18, 800e18);
    }

    /*//////////////////////////////////////////////////////////////
                          QUERY FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetAllGroupIds() public {
        uint256[] memory lines1 = new uint256[](2);
        lines1[0] = LINE_20;
        lines1[1] = LINE_25;

        bytes32 groupId1 = keccak256("GROUP_1");
        controller.createLineGroup(groupId1, lines1);

        uint256[] memory lines2 = new uint256[](2);
        lines2[0] = LINE_25;
        lines2[1] = LINE_30;

        bytes32 groupId2 = keccak256("GROUP_2");
        controller.createLineGroup(groupId2, lines2);

        bytes32[] memory allIds = controller.getAllGroupIds();

        assertEq(allIds.length, 2);
        assertEq(allIds[0], groupId1);
        assertEq(allIds[1], groupId2);
    }

    function test_GetLinkCoefficient_FromParamController() public {
        // 注册联动系数参数
        bytes32 key = keccak256(abi.encodePacked("LINK_COEFF_", LINE_20, "_", LINE_25));
        paramController.registerParam(key, 7500, address(0)); // 75%

        uint256 coefficient = controller.getLinkCoefficient(LINE_20, LINE_25);

        assertEq(coefficient, 7500);
    }

    function test_GetLinkCoefficient_DefaultValue() public {
        // 未注册参数，应返回默认值
        uint256 coefficient = controller.getLinkCoefficient(LINE_20, LINE_25);

        assertEq(coefficient, controller.DEFAULT_LINK_COEFFICIENT()); // 8000 (80%)
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _createBasicLineGroup() internal {
        uint256[] memory lines = new uint256[](3);
        lines[0] = LINE_20;
        lines[1] = LINE_25;
        lines[2] = LINE_30;

        controller.createLineGroup(GROUP_ID, lines);
    }

    function _createAndConfigureFullGroup() internal {
        _createBasicLineGroup();

        // 配置所有线
        controller.configureLine(GROUP_ID, LINE_20, address(cpmm20), 1000e18, 1000e18);
        controller.configureLine(GROUP_ID, LINE_25, address(cpmm25), 1000e18, 1000e18);
        controller.configureLine(GROUP_ID, LINE_30, address(cpmm30), 1000e18, 1000e18);

        // 配置联动关系
        controller.configureLink(GROUP_ID, LINE_20, LINE_25, 8000, 50, 500);
        controller.configureLink(GROUP_ID, LINE_25, LINE_30, 8000, 50, 500);
    }
}
