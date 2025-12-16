// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/mappers/OU_Mapper.sol";

/**
 * @title OU_Mapper_Test
 * @notice 大小球（Over/Under）映射器单元测试
 */
contract OU_Mapper_Test is Test {
    OU_Mapper public mapper25; // 2.5 球线（半球盘）
    OU_Mapper public mapper30; // 3.0 球线（整球盘）
    OU_Mapper public mapper275; // 2.75 球线（四分一盘）

    uint256 constant OUTCOME_OVER = 0;
    uint256 constant OUTCOME_PUSH = 1;
    uint256 constant OUTCOME_UNDER = 2;
    uint256 constant FULL_WEIGHT = 10000;
    int256 constant LINE_PRECISION = 1000;

    function setUp() public {
        mapper25 = new OU_Mapper(2500); // 2.5 球
        mapper30 = new OU_Mapper(3000); // 3.0 球
        mapper275 = new OU_Mapper(2750); // 2.75 球
    }

    // ============ 元数据测试 ============

    function test_outcomeCount() public view {
        assertEq(mapper25.outcomeCount(), 3);
        assertEq(mapper30.outcomeCount(), 3);
    }

    function test_mapperType() public view {
        assertEq(mapper25.mapperType(), "OU");
    }

    function test_version() public view {
        assertEq(mapper25.version(), "1.0.0");
    }

    function test_line() public view {
        assertEq(mapper25.line(), 2500);
        assertEq(mapper30.line(), 3000);
        assertEq(mapper275.line(), 2750);
    }

    function test_isWholeLine() public view {
        assertFalse(mapper25.isWholeLine());
        assertTrue(mapper30.isWholeLine());
        assertFalse(mapper275.isWholeLine());
    }

    function test_getParams() public view {
        assertEq(mapper25.getParams(), abi.encode(int256(2500)));
    }

    function test_getOutcomeName() public view {
        assertEq(mapper25.getOutcomeName(OUTCOME_OVER), "Over 2.5");
        assertEq(mapper25.getOutcomeName(OUTCOME_PUSH), "Push");
        assertEq(mapper25.getOutcomeName(OUTCOME_UNDER), "Under 2.5");
    }

    function test_getOutcomeName_WholeLine() public view {
        assertEq(mapper30.getOutcomeName(OUTCOME_OVER), "Over 3.0");
        assertEq(mapper30.getOutcomeName(OUTCOME_UNDER), "Under 3.0");
    }

    function test_getOutcomeName_Invalid() public {
        vm.expectRevert("Invalid outcome ID");
        mapper25.getOutcomeName(3);
    }

    function test_getAllOutcomeNames() public view {
        string[] memory names = mapper25.getAllOutcomeNames();
        assertEq(names.length, 3);
        assertEq(names[0], "Over 2.5");
        assertEq(names[1], "Push");
        assertEq(names[2], "Under 2.5");
    }

    // ============ 半球盘测试（2.5 球）============

    function test_halfLine25_Over_3goals() public view {
        // 2-1 = 3 球，大于 2.5，应该是 Over
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_OVER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine25_Over_4goals() public view {
        // 3-1 = 4 球
        bytes memory rawResult = abi.encode(uint256(3), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OVER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine25_Under_2goals() public view {
        // 1-1 = 2 球，小于 2.5，应该是 Under
        bytes memory rawResult = abi.encode(uint256(1), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_UNDER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_halfLine25_Under_0goals() public view {
        // 0-0 = 0 球
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_UNDER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 整球盘测试（3.0 球）============

    function test_wholeLine30_Over() public view {
        // 3-1 = 4 球，大于 3.0
        bytes memory rawResult = abi.encode(uint256(3), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper30.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OVER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_wholeLine30_Push() public view {
        // 2-1 = 3 球，等于 3.0，Push
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper30.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_PUSH);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_wholeLine30_Under() public view {
        // 1-1 = 2 球，小于 3.0
        bytes memory rawResult = abi.encode(uint256(1), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper30.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_UNDER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ previewResult 测试 ============

    function test_previewResult_Over() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.previewResult(2, 2);

        // 4 球 > 2.5
        assertEq(outcomeIds[0], OUTCOME_OVER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_Under() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.previewResult(0, 1);

        // 1 球 < 2.5
        assertEq(outcomeIds[0], OUTCOME_UNDER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_Push() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper30.previewResult(1, 2);

        // 3 球 = 3.0
        assertEq(outcomeIds[0], OUTCOME_PUSH);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 边界测试 ============

    function test_boundary_JustOver25() public view {
        // 3 球正好大于 2.5
        bytes memory rawResult = abi.encode(uint256(3), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OVER);
    }

    function test_boundary_JustUnder25() public view {
        // 2 球正好小于 2.5
        bytes memory rawResult = abi.encode(uint256(2), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_UNDER);
    }

    function test_highScore() public view {
        // 高比分测试
        bytes memory rawResult = abi.encode(uint256(5), uint256(5));
        (uint256[] memory outcomeIds, ) = mapper25.mapResult(rawResult);

        // 10 球 > 2.5
        assertEq(outcomeIds[0], OUTCOME_OVER);
    }

    // ============ 不同盘口线测试 ============

    function test_line05() public {
        OU_Mapper mapper05 = new OU_Mapper(500); // 0.5 球

        // 1 球 > 0.5 = Over
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper05.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_OVER);

        // 0 球 < 0.5 = Under
        rawResult = abi.encode(uint256(0), uint256(0));
        (outcomeIds, ) = mapper05.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_UNDER);
    }

    function test_line10() public {
        OU_Mapper mapper10 = new OU_Mapper(1000); // 1.0 球（整球盘）

        // 0 球 < 1.0 = Under
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper10.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_UNDER);

        // 1 球 = 1.0 = Push
        rawResult = abi.encode(uint256(1), uint256(0));
        (outcomeIds, ) = mapper10.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_PUSH);

        // 2 球 > 1.0 = Over
        rawResult = abi.encode(uint256(1), uint256(1));
        (outcomeIds, ) = mapper10.mapResult(rawResult);
        assertEq(outcomeIds[0], OUTCOME_OVER);
    }

    // ============ 构造函数测试 ============

    function test_constructor_NegativeLine_Reverts() public {
        vm.expectRevert("OU_Mapper: Line must be non-negative");
        new OU_Mapper(-1000);
    }

    function test_constructor_ZeroLine() public {
        OU_Mapper mapper0 = new OU_Mapper(0); // 0 球线
        assertTrue(mapper0.isWholeLine());

        // 任何进球都是 Over
        (uint256[] memory outcomeIds, ) = mapper0.previewResult(1, 0);
        assertEq(outcomeIds[0], OUTCOME_OVER);

        // 0-0 是 Push
        (outcomeIds, ) = mapper0.previewResult(0, 0);
        assertEq(outcomeIds[0], OUTCOME_PUSH);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_mapResult_AlwaysSingleOutcome(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper25.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(weights.length, 1);
        assertEq(weights[0], FULL_WEIGHT);
        assertTrue(outcomeIds[0] <= OUTCOME_UNDER);
    }

    function testFuzz_halfLine_NoPush(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper25.mapResult(rawResult);

        // 半球盘不应该产生 Push
        assertTrue(outcomeIds[0] != OUTCOME_PUSH);
    }

    function testFuzz_wholeLine_CorrectOutcome(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper30.mapResult(rawResult);

        uint256 totalGoals = uint256(homeScore) + uint256(awayScore);

        if (totalGoals > 3) {
            assertEq(outcomeIds[0], OUTCOME_OVER);
        } else if (totalGoals < 3) {
            assertEq(outcomeIds[0], OUTCOME_UNDER);
        } else {
            assertEq(outcomeIds[0], OUTCOME_PUSH);
        }
    }

    function testFuzz_previewResult_MatchesMapResult(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds1, uint256[] memory weights1) = mapper25.mapResult(rawResult);
        (uint256[] memory outcomeIds2, uint256[] memory weights2) = mapper25.previewResult(homeScore, awayScore);

        assertEq(outcomeIds1[0], outcomeIds2[0]);
        assertEq(weights1[0], weights2[0]);
    }
}
