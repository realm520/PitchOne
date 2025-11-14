// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/pricing/LinkedLinesController.sol";
import "../../src/pricing/LinkedLinesController_Optimized.sol";
import "../../src/pricing/SimpleCPMM.sol";
import {MockParamController} from "../mocks/MockParamController.sol";

/**
 * @notice LinkedLinesController gas 对比测试
 * @dev 对比原版和优化版的 gas 消耗
 */
contract LinkedLinesController_GasComparisonTest is Test {
    LinkedLinesController public controllerOriginal;
    LinkedLinesController_Optimized public controllerOptimized;

    MockParamController public paramController;

    SimpleCPMM public cpmmLine20;  // 2.0 球
    SimpleCPMM public cpmmLine25;  // 2.5 球
    SimpleCPMM public cpmmLine30;  // 3.0 球

    bytes32 public groupId;
    uint256[] public lines;
    uint256[][] public allReserves;

    address public admin = address(this);

    function setUp() public {
        // 部署 ParamController
        paramController = new MockParamController();

        // 部署两个版本的 Controller
        controllerOriginal = new LinkedLinesController(admin, address(paramController));
        controllerOptimized = new LinkedLinesController_Optimized(admin, address(paramController));

        // 部署 3 条线的 CPMM（无参数构造）
        cpmmLine20 = new SimpleCPMM();
        cpmmLine25 = new SimpleCPMM();
        cpmmLine30 = new SimpleCPMM();

        // 创建线组
        groupId = keccak256("OU_MATCH_123");
        lines = new uint256[](3);
        lines[0] = 2000; // 2.0 球
        lines[1] = 2500; // 2.5 球
        lines[2] = 3000; // 3.0 球

        // 准备储备量数据
        allReserves = new uint256[][](3);
        allReserves[0] = new uint256[](2);
        allReserves[0][0] = 1 ether;
        allReserves[0][1] = 1 ether;

        allReserves[1] = new uint256[](2);
        allReserves[1][0] = 1 ether;
        allReserves[1][1] = 1 ether;

        allReserves[2] = new uint256[](2);
        allReserves[2][0] = 1 ether;
        allReserves[2][1] = 1 ether;

        // ===== 原版设置 =====
        controllerOriginal.createLineGroup(groupId, lines);
        controllerOriginal.configureLine(groupId, 2000, address(cpmmLine20), 1 ether, 1 ether);
        controllerOriginal.configureLine(groupId, 2500, address(cpmmLine25), 1 ether, 1 ether);
        controllerOriginal.configureLine(groupId, 3000, address(cpmmLine30), 1 ether, 1 ether);

        // ===== 优化版设置 =====
        uint64[] memory linesOptimized = new uint64[](3);
        linesOptimized[0] = 2000;
        linesOptimized[1] = 2500;
        linesOptimized[2] = 3000;

        controllerOptimized.createLineGroup(groupId, linesOptimized);
        controllerOptimized.configureLine(groupId, 2000, address(cpmmLine20), 1 ether, 1 ether);
        controllerOptimized.configureLine(groupId, 2500, address(cpmmLine25), 1 ether, 1 ether);
        controllerOptimized.configureLine(groupId, 3000, address(cpmmLine30), 1 ether, 1 ether);
    }

    /**
     * @notice 原版 - getAllLinkedPrices
     */
    function test_Gas_GetAllLinkedPrices_Original() public view {
        controllerOriginal.getAllLinkedPrices(groupId, 0, allReserves);
    }

    /**
     * @notice 优化版 - getAllLinkedPrices
     */
    function test_Gas_GetAllLinkedPrices_Optimized() public view {
        controllerOptimized.getAllLinkedPrices(groupId, 0, allReserves);
    }

    /**
     * @notice 原版 - detectArbitrage
     */
    function test_Gas_DetectArbitrage_Original() public view {
        controllerOriginal.detectArbitrage(groupId, allReserves);
    }

    /**
     * @notice 优化版 - detectArbitrage
     */
    function test_Gas_DetectArbitrage_Optimized() public view {
        controllerOptimized.detectArbitrage(groupId, allReserves);
    }

    /**
     * @notice 原版 - 单次价格查询
     */
    function test_Gas_GetLinkedPrice_Original() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1 ether;
        reserves[1] = 1 ether;

        controllerOriginal.getLinkedPrice(groupId, 2000, 0, reserves);
    }

    /**
     * @notice 优化版 - 单次价格查询
     */
    function test_Gas_GetLinkedPrice_Optimized() public view {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1 ether;
        reserves[1] = 1 ether;

        controllerOptimized.getLinkedPrice(groupId, 2000, 0, reserves);
    }

    /**
     * @notice 功能对比测试：确保优化后功能一致
     */
    function test_FunctionalityComparison() public view {
        // 1. getAllLinkedPrices 返回结果一致
        (uint256[] memory linesOrig, uint256[] memory pricesOrig) =
            controllerOriginal.getAllLinkedPrices(groupId, 0, allReserves);

        (uint64[] memory linesOpt, uint256[] memory pricesOpt) =
            controllerOptimized.getAllLinkedPrices(groupId, 0, allReserves);

        assertEq(linesOrig.length, linesOpt.length, "Lines length mismatch");
        for (uint256 i = 0; i < linesOrig.length; i++) {
            assertEq(linesOrig[i], uint256(linesOpt[i]), "Line value mismatch");
            assertEq(pricesOrig[i], pricesOpt[i], "Price mismatch");
        }

        // 2. detectArbitrage 返回结果一致
        (bool hasArbitrageOrig,,, uint256 profitOrig) = controllerOriginal.detectArbitrage(groupId, allReserves);
        (bool hasArbitrageOpt,,, uint256 profitOpt) = controllerOptimized.detectArbitrage(groupId, allReserves);

        assertEq(hasArbitrageOrig, hasArbitrageOpt, "Arbitrage detection mismatch");
        assertEq(profitOrig, profitOpt, "Profit calculation mismatch");

        // 3. getLinkedPrice 返回结果一致
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 1 ether;
        reserves[1] = 1 ether;

        uint256 priceOrig = controllerOriginal.getLinkedPrice(groupId, 2000, 0, reserves);
        uint256 priceOpt = controllerOptimized.getLinkedPrice(groupId, 2000, 0, reserves);

        assertEq(priceOrig, priceOpt, "Single price query mismatch");
    }

    /**
     * @notice 批量查询性能测试 - 原版（10 条线）
     */
    function test_Gas_GetAllLinkedPrices_Original_10Lines() public {
        // 创建 10 条线的线组
        bytes32 bigGroupId = keccak256("OU_BIG_MATCH");
        uint256[] memory bigLines = new uint256[](10);
        uint256[][] memory bigReserves = new uint256[][](10);

        for (uint256 i = 0; i < 10; i++) {
            bigLines[i] = 2000 + (i * 500); // 2.0, 2.5, 3.0, ... 6.5 球
            bigReserves[i] = new uint256[](2);
            bigReserves[i][0] = 1 ether;
            bigReserves[i][1] = 1 ether;
        }

        // 先创建线组
        controllerOriginal.createLineGroup(bigGroupId, bigLines);

        // 再配置每条线
        for (uint256 i = 0; i < 10; i++) {
            SimpleCPMM cpmm = new SimpleCPMM();
            controllerOriginal.configureLine(bigGroupId, bigLines[i], address(cpmm), 1 ether, 1 ether);
        }

        // 查询所有价格
        controllerOriginal.getAllLinkedPrices(bigGroupId, 0, bigReserves);
    }

    /**
     * @notice 批量查询性能测试 - 优化版（10 条线）
     */
    function test_Gas_GetAllLinkedPrices_Optimized_10Lines() public {
        // 创建 10 条线的线组
        bytes32 bigGroupId = keccak256("OU_BIG_MATCH");
        uint64[] memory bigLines = new uint64[](10);
        uint256[][] memory bigReserves = new uint256[][](10);

        for (uint256 i = 0; i < 10; i++) {
            bigLines[i] = uint64(2000 + (i * 500));
            bigReserves[i] = new uint256[](2);
            bigReserves[i][0] = 1 ether;
            bigReserves[i][1] = 1 ether;
        }

        // 先创建线组
        controllerOptimized.createLineGroup(bigGroupId, bigLines);

        // 再配置每条线
        for (uint256 i = 0; i < 10; i++) {
            SimpleCPMM cpmm = new SimpleCPMM();
            controllerOptimized.configureLine(bigGroupId, bigLines[i], address(cpmm), 1 ether, 1 ether);
        }

        // 查询所有价格
        controllerOptimized.getAllLinkedPrices(bigGroupId, 0, bigReserves);
    }
}
