// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/mappers/AH_Mapper.sol";

/**
 * @title AH_Mapper_Test
 * @notice 让球（Asian Handicap）映射器单元测试
 * @dev 测试半球盘、整球盘、四分一盘的各种场景
 */
contract AH_Mapper_Test is Test {
    AH_Mapper public mapperHalf; // 主队让 0.5 球（半球盘）
    AH_Mapper public mapperWhole; // 主队让 1.0 球（整球盘）
    AH_Mapper public mapperQuarter75; // 主队让 0.75 球（四分一盘）
    AH_Mapper public mapperQuarter25; // 主队让 0.25 球（四分一盘）

    uint256 constant OUTCOME_HOME_WIN = 0;
    uint256 constant OUTCOME_PUSH = 1;
    uint256 constant OUTCOME_AWAY_WIN = 2;
    uint256 constant FULL_WEIGHT = 10000;
    uint256 constant HALF_WEIGHT = 5000;

    function setUp() public {
        mapperHalf = new AH_Mapper(-500); // 主队让 0.5 球
        mapperWhole = new AH_Mapper(-1000); // 主队让 1.0 球
        mapperQuarter75 = new AH_Mapper(-750); // 主队让 0.75 球
        mapperQuarter25 = new AH_Mapper(-250); // 主队让 0.25 球
    }

    // ============ 元数据测试 ============

    function test_outcomeCount() public view {
        assertEq(mapperHalf.outcomeCount(), 3);
    }

    function test_mapperType() public view {
        assertEq(mapperHalf.mapperType(), "AH");
    }

    function test_version() public view {
        assertEq(mapperHalf.version(), "1.0.0");
    }

    function test_line() public view {
        assertEq(mapperHalf.line(), -500);
        assertEq(mapperWhole.line(), -1000);
        assertEq(mapperQuarter75.line(), -750);
    }

    function test_lineType() public view {
        assertEq(mapperHalf.lineType(), 0); // 半球盘
        assertEq(mapperWhole.lineType(), 1); // 整球盘
        assertEq(mapperQuarter75.lineType(), 2); // 四分一盘
        assertEq(mapperQuarter25.lineType(), 2); // 四分一盘
    }

    function test_getParams() public view {
        assertEq(mapperHalf.getParams(), abi.encode(int256(-500)));
    }

    function test_getAllOutcomeNames() public view {
        string[] memory names = mapperHalf.getAllOutcomeNames();
        assertEq(names.length, 3);
        assertEq(names[0], "Home +line");
        assertEq(names[1], "Push");
        assertEq(names[2], "Away -line");
    }

    // ============ 半球盘测试（主队让 0.5 球）============

    function test_halfLine_HomeWin2Goals() public view {
        // 主队 2-0 赢，让 0.5 球后差值 = 2 - 0.5 = 1.5 > 0 => 主队赢盘
        bytes memory rawResult = abi.encode(uint256(2), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperHalf.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine_HomeWin1Goal() public view {
        // 主队 1-0 赢，让 0.5 球后差值 = 1 - 0.5 = 0.5 > 0 => 主队赢盘
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperHalf.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine_Draw() public view {
        // 0-0 平局，让 0.5 球后差值 = 0 - 0.5 = -0.5 < 0 => 客队赢盘
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperHalf.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine_AwayWin() public view {
        // 0-1 客队赢，让 0.5 球后差值 = -1 - 0.5 = -1.5 < 0 => 客队赢盘
        bytes memory rawResult = abi.encode(uint256(0), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperHalf.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 整球盘测试（主队让 1.0 球）============

    function test_wholeLine_HomeWin2Goals() public view {
        // 主队 2-0 赢，让 1 球后差值 = 2 - 1 = 1 > 0 => 主队赢盘
        bytes memory rawResult = abi.encode(uint256(2), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperWhole.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_wholeLine_Push() public view {
        // 主队 1-0 赢，让 1 球后差值 = 1 - 1 = 0 => Push
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperWhole.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_PUSH);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_wholeLine_Draw() public view {
        // 0-0 平局，让 1 球后差值 = 0 - 1 = -1 < 0 => 客队赢盘
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperWhole.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_wholeLine_AwayWin() public view {
        // 0-1 客队赢，让 1 球后差值 = -1 - 1 = -2 < 0 => 客队赢盘
        bytes memory rawResult = abi.encode(uint256(0), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperWhole.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 四分一盘测试（主队让 0.75 球）============
    // 0.75 盘 = (0.5 + 1.0) / 2 的组合

    function test_quarterLine75_FullWin() public view {
        // 主队 2-0 赢，让 0.75 球后差值 = 2 - 0.75 = 1.25 > 0.5 => 主队全赢
        bytes memory rawResult = abi.encode(uint256(2), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_quarterLine75_HalfWin() public view {
        // 主队 1-0 赢，让 0.75 球后差值 = 1 - 0.75 = 0.25
        // 0 < 0.25 <= 0.5 => 主队半赢
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.mapResult(rawResult);

        assertEq(outcomeIds.length, 2);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(outcomeIds[1], OUTCOME_PUSH);
        assertEq(weights[0], HALF_WEIGHT);
        assertEq(weights[1], HALF_WEIGHT);
    }

    function test_quarterLine75_FullLoss() public view {
        // 0-0 平局，让 0.75 球后差值 = 0 - 0.75 = -0.75 < -0.5 => 客队全赢
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_quarterLine75_AwayWin() public view {
        // 0-2 客队赢，让 0.75 球后差值 = -2 - 0.75 = -2.75 < 0 => 客队全赢
        bytes memory rawResult = abi.encode(uint256(0), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 四分一盘测试（主队让 0.25 球）============

    function test_quarterLine25_FullWin() public view {
        // 主队 1-0 赢，让 0.25 球后差值 = 1 - 0.25 = 0.75 > 0.5 => 主队全赢
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter25.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_quarterLine25_HalfLoss() public view {
        // 0-0 平局，让 0.25 球后差值 = 0 - 0.25 = -0.25
        // -0.5 <= -0.25 < 0 => 主队半输
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter25.mapResult(rawResult);

        assertEq(outcomeIds.length, 2);
        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(outcomeIds[1], OUTCOME_PUSH);
        assertEq(weights[0], HALF_WEIGHT);
        assertEq(weights[1], HALF_WEIGHT);
    }

    function test_quarterLine25_FullLoss() public view {
        // 0-1 客队赢，让 0.25 球后差值 = -1 - 0.25 = -1.25 < -0.5 => 客队全赢
        bytes memory rawResult = abi.encode(uint256(0), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter25.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 客队让球测试（正数 line）============

    function test_awayHandicap_HalfBall() public {
        // 客队让 0.5 球 (line = +500)
        AH_Mapper mapperAwayHalf = new AH_Mapper(500);

        // 0-0 平局，客队让 0.5 后差值 = 0 + 0.5 = 0.5 > 0 => 主队赢盘
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperAwayHalf.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);

        // 0-1 客队赢，客队让 0.5 后差值 = -1 + 0.5 = -0.5 < 0 => 客队赢盘
        rawResult = abi.encode(uint256(0), uint256(1));
        (outcomeIds, weights) = mapperAwayHalf.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ previewResult 测试 ============

    function test_previewResult_HalfLine() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperHalf.previewResult(2, 1);

        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_WholeLine_Push() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperWhole.previewResult(2, 1);

        // 2-1 = 差值 1，让 1 球后 = 0 => Push
        assertEq(outcomeIds[0], OUTCOME_PUSH);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_QuarterLine_HalfWin() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.previewResult(1, 0);

        assertEq(outcomeIds.length, 2);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
        assertEq(outcomeIds[1], OUTCOME_PUSH);
        assertEq(weights[0], HALF_WEIGHT);
        assertEq(weights[1], HALF_WEIGHT);
    }

    // ============ 更大让球盘测试 ============

    function test_largerHandicap_Minus15() public {
        // 主队让 1.5 球
        AH_Mapper mapper15 = new AH_Mapper(-1500);
        assertEq(mapper15.lineType(), 0); // 半球盘

        // 2-0 主队赢，让 1.5 后差值 = 0.5 > 0 => 主队赢盘
        bytes memory rawResult = abi.encode(uint256(2), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper15.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);

        // 1-0 主队赢，让 1.5 后差值 = -0.5 < 0 => 客队赢盘
        rawResult = abi.encode(uint256(1), uint256(0));
        (outcomeIds, ) = mapper15.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_AWAY_WIN);
    }

    function test_largerHandicap_Minus2() public {
        // 主队让 2 球
        AH_Mapper mapper2 = new AH_Mapper(-2000);
        assertEq(mapper2.lineType(), 1); // 整球盘

        // 3-1 主队赢 2 球，让 2 后差值 = 0 => Push
        bytes memory rawResult = abi.encode(uint256(3), uint256(1));
        (uint256[] memory outcomeIds, ) = mapper2.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_PUSH);

        // 3-0 主队赢 3 球，让 2 后差值 = 1 > 0 => 主队赢盘
        rawResult = abi.encode(uint256(3), uint256(0));
        (outcomeIds, ) = mapper2.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_HOME_WIN);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_halfLine_NoPush(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapperHalf.mapResult(rawResult);

        // 半球盘不应该产生 Push
        if (outcomeIds.length == 1) {
            assertTrue(outcomeIds[0] != OUTCOME_PUSH);
        }
    }

    function testFuzz_weights_SumToFull(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapperQuarter75.mapResult(rawResult);

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }

        assertEq(totalWeight, FULL_WEIGHT);
        assertEq(outcomeIds.length, weights.length);
    }

    function testFuzz_previewResult_MatchesMapResult(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds1, uint256[] memory weights1) = mapperHalf.mapResult(rawResult);
        (uint256[] memory outcomeIds2, uint256[] memory weights2) = mapperHalf.previewResult(homeScore, awayScore);

        assertEq(outcomeIds1.length, outcomeIds2.length);
        for (uint256 i = 0; i < outcomeIds1.length; i++) {
            assertEq(outcomeIds1[i], outcomeIds2[i]);
            assertEq(weights1[i], weights2[i]);
        }
    }
}
