// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/mappers/WDL_Mapper.sol";

/**
 * @title WDL_Mapper_Test
 * @notice WDL（胜平负）映射器单元测试
 */
contract WDL_Mapper_Test is Test {
    WDL_Mapper public mapper;

    uint256 constant OUTCOME_WIN = 0;
    uint256 constant OUTCOME_DRAW = 1;
    uint256 constant OUTCOME_LOSS = 2;
    uint256 constant FULL_WEIGHT = 10000;

    function setUp() public {
        mapper = new WDL_Mapper();
    }

    // ============ 元数据测试 ============

    function test_outcomeCount() public view {
        assertEq(mapper.outcomeCount(), 3);
    }

    function test_mapperType() public view {
        assertEq(mapper.mapperType(), "WDL");
    }

    function test_version() public view {
        assertEq(mapper.version(), "1.0.0");
    }

    function test_getParams() public view {
        assertEq(mapper.getParams(), "");
    }

    function test_getOutcomeName_Win() public view {
        assertEq(mapper.getOutcomeName(OUTCOME_WIN), "Home Win");
    }

    function test_getOutcomeName_Draw() public view {
        assertEq(mapper.getOutcomeName(OUTCOME_DRAW), "Draw");
    }

    function test_getOutcomeName_Loss() public view {
        assertEq(mapper.getOutcomeName(OUTCOME_LOSS), "Away Win");
    }

    function test_getOutcomeName_Invalid() public {
        vm.expectRevert("Invalid outcome ID");
        mapper.getOutcomeName(3);
    }

    function test_getAllOutcomeNames() public view {
        string[] memory names = mapper.getAllOutcomeNames();
        assertEq(names.length, 3);
        assertEq(names[0], "Home Win");
        assertEq(names[1], "Draw");
        assertEq(names[2], "Away Win");
    }

    // ============ 核心映射测试 - mapResult ============

    function test_mapResult_HomeWin_1_0() public view {
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_WIN);
        assertEq(weights.length, 1);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_HomeWin_3_1() public view {
        bytes memory rawResult = abi.encode(uint256(3), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_HomeWin_5_2() public view {
        bytes memory rawResult = abi.encode(uint256(5), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Draw_0_0() public view {
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_DRAW);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Draw_1_1() public view {
        bytes memory rawResult = abi.encode(uint256(1), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_DRAW);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Draw_2_2() public view {
        bytes memory rawResult = abi.encode(uint256(2), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_DRAW);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_AwayWin_0_1() public view {
        bytes memory rawResult = abi.encode(uint256(0), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_LOSS);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_AwayWin_1_3() public view {
        bytes memory rawResult = abi.encode(uint256(1), uint256(3));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_LOSS);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_AwayWin_2_5() public view {
        bytes memory rawResult = abi.encode(uint256(2), uint256(5));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_LOSS);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 核心映射测试 - previewResult ============

    function test_previewResult_HomeWin() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.previewResult(2, 1);

        assertEq(outcomeIds[0], OUTCOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_Draw() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.previewResult(3, 3);

        assertEq(outcomeIds[0], OUTCOME_DRAW);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_AwayWin() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.previewResult(0, 2);

        assertEq(outcomeIds[0], OUTCOME_LOSS);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 边界测试 ============

    function test_mapResult_HighScore() public view {
        bytes memory rawResult = abi.encode(uint256(10), uint256(5));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_ZeroZero() public view {
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_DRAW);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_mapResult_AlwaysSingleOutcome(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        // 应该总是返回单个结果
        assertEq(outcomeIds.length, 1);
        assertEq(weights.length, 1);
        assertEq(weights[0], FULL_WEIGHT);

        // 验证 outcomeId 在有效范围内
        assertTrue(outcomeIds[0] <= OUTCOME_LOSS);
    }

    function testFuzz_mapResult_CorrectOutcome(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        if (homeScore > awayScore) {
            assertEq(outcomeIds[0], OUTCOME_WIN);
        } else if (homeScore == awayScore) {
            assertEq(outcomeIds[0], OUTCOME_DRAW);
        } else {
            assertEq(outcomeIds[0], OUTCOME_LOSS);
        }
    }

    function testFuzz_previewResult_MatchesMapResult(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds1, uint256[] memory weights1) = mapper.mapResult(rawResult);
        (uint256[] memory outcomeIds2, uint256[] memory weights2) = mapper.previewResult(homeScore, awayScore);

        assertEq(outcomeIds1[0], outcomeIds2[0]);
        assertEq(weights1[0], weights2[0]);
    }
}
