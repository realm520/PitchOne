// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/mappers/Score_Mapper.sol";

/**
 * @title Score_Mapper_Test
 * @notice 精确比分（Correct Score）映射器单元测试
 */
contract Score_Mapper_Test is Test {
    Score_Mapper public mapper5; // 最大 5 球
    Score_Mapper public mapper3; // 最大 3 球

    uint256 constant OUTCOME_OTHER = 999;
    uint256 constant FULL_WEIGHT = 10000;

    function setUp() public {
        mapper5 = new Score_Mapper(5);
        mapper3 = new Score_Mapper(3);
    }

    // ============ 元数据测试 ============

    function test_outcomeCount() public view {
        // maxGoals=5: (5+1)^2 + 1 = 37
        assertEq(mapper5.outcomeCount(), 37);
        // maxGoals=3: (3+1)^2 + 1 = 17
        assertEq(mapper3.outcomeCount(), 17);
    }

    function test_mapperType() public view {
        assertEq(mapper5.mapperType(), "SCORE");
    }

    function test_version() public view {
        assertEq(mapper5.version(), "1.0.0");
    }

    function test_maxGoals() public view {
        assertEq(mapper5.maxGoals(), 5);
        assertEq(mapper3.maxGoals(), 3);
    }

    function test_getParams() public view {
        assertEq(mapper5.getParams(), abi.encode(uint256(5)));
        assertEq(mapper3.getParams(), abi.encode(uint256(3)));
    }

    function test_getOutcomeName_0_0() public view {
        assertEq(mapper5.getOutcomeName(0), "0-0");
    }

    function test_getOutcomeName_2_1() public view {
        // 2-1 = 21
        assertEq(mapper5.getOutcomeName(21), "2-1");
    }

    function test_getOutcomeName_5_5() public view {
        // 5-5 = 55
        assertEq(mapper5.getOutcomeName(55), "5-5");
    }

    function test_getOutcomeName_Other() public view {
        assertEq(mapper5.getOutcomeName(OUTCOME_OTHER), "Other");
    }

    function test_getOutcomeName_Invalid() public {
        // 6-0 = 60，超出 maxGoals=5
        vm.expectRevert("Invalid outcome ID");
        mapper5.getOutcomeName(60);
    }

    function test_getAllOutcomeNames() public view {
        string[] memory names = mapper5.getAllOutcomeNames();
        assertEq(names.length, 37);
        assertEq(names[0], "0-0");
        assertEq(names[1], "0-1");
        assertEq(names[6], "1-0");
        assertEq(names[36], "Other");
    }

    // ============ 核心映射测试 ============

    function test_mapResult_0_0() public view {
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], 0); // 0*10 + 0 = 0
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_1_0() public view {
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], 10); // 1*10 + 0 = 10
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_2_1() public view {
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], 21); // 2*10 + 1 = 21
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_3_3() public view {
        bytes memory rawResult = abi.encode(uint256(3), uint256(3));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], 33);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_5_5() public view {
        bytes memory rawResult = abi.encode(uint256(5), uint256(5));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], 55);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Other_6_0() public view {
        // 6-0 超出范围
        bytes memory rawResult = abi.encode(uint256(6), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OTHER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Other_0_6() public view {
        // 0-6 超出范围
        bytes memory rawResult = abi.encode(uint256(0), uint256(6));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OTHER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Other_10_10() public view {
        // 10-10 超出范围
        bytes memory rawResult = abi.encode(uint256(10), uint256(10));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OTHER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ previewResult 测试 ============

    function test_previewResult() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.previewResult(4, 2);

        assertEq(outcomeIds[0], 42);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_Other() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.previewResult(7, 3);

        assertEq(outcomeIds[0], OUTCOME_OTHER);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 辅助函数测试 ============

    function test_encodeOutcome() public view {
        assertEq(mapper5.encodeOutcome(0, 0), 0);
        assertEq(mapper5.encodeOutcome(2, 1), 21);
        assertEq(mapper5.encodeOutcome(5, 5), 55);
        assertEq(mapper5.encodeOutcome(6, 0), OUTCOME_OTHER);
        assertEq(mapper5.encodeOutcome(0, 6), OUTCOME_OTHER);
    }

    function test_decodeOutcome() public view {
        (uint256 home, uint256 away, bool isOther) = mapper5.decodeOutcome(0);
        assertEq(home, 0);
        assertEq(away, 0);
        assertFalse(isOther);

        (home, away, isOther) = mapper5.decodeOutcome(21);
        assertEq(home, 2);
        assertEq(away, 1);
        assertFalse(isOther);

        (home, away, isOther) = mapper5.decodeOutcome(OUTCOME_OTHER);
        assertEq(home, 0);
        assertEq(away, 0);
        assertTrue(isOther);
    }

    function test_decodeOutcome_Invalid() public {
        // 60 = 6-0，超出范围
        vm.expectRevert("Invalid outcome ID");
        mapper5.decodeOutcome(60);
    }

    function test_getAllValidOutcomeIds() public view {
        uint256[] memory ids = mapper5.getAllValidOutcomeIds();
        assertEq(ids.length, 37);

        // 检查前几个
        assertEq(ids[0], 0);   // 0-0
        assertEq(ids[1], 1);   // 0-1
        assertEq(ids[5], 5);   // 0-5
        assertEq(ids[6], 10);  // 1-0
        assertEq(ids[36], OUTCOME_OTHER);
    }

    // ============ 不同 maxGoals 测试 ============

    function test_mapper3_boundary() public view {
        // 3-3 应该在范围内
        (uint256[] memory outcomeIds, ) = mapper3.previewResult(3, 3);
        assertEq(outcomeIds[0], 33);

        // 4-0 应该是 Other
        (outcomeIds, ) = mapper3.previewResult(4, 0);
        assertEq(outcomeIds[0], OUTCOME_OTHER);
    }

    // ============ 构造函数测试 ============

    function test_constructor_MinMaxGoals() public {
        Score_Mapper mapper2 = new Score_Mapper(2);
        assertEq(mapper2.maxGoals(), 2);
        // (2+1)^2 + 1 = 10
        assertEq(mapper2.outcomeCount(), 10);
    }

    function test_constructor_MaxMaxGoals() public {
        Score_Mapper mapper9 = new Score_Mapper(9);
        assertEq(mapper9.maxGoals(), 9);
        // (9+1)^2 + 1 = 101
        assertEq(mapper9.outcomeCount(), 101);
    }

    function test_constructor_TooLow_Reverts() public {
        vm.expectRevert("Score_Mapper: maxGoals must be 2-9");
        new Score_Mapper(1);
    }

    function test_constructor_TooHigh_Reverts() public {
        vm.expectRevert("Score_Mapper: maxGoals must be 2-9");
        new Score_Mapper(10);
    }

    // ============ Fuzz 测试 ============

    function testFuzz_mapResult_AlwaysSingleOutcome(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(weights.length, 1);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function testFuzz_mapResult_CorrectEncoding(uint8 homeScore, uint8 awayScore) public view {
        vm.assume(homeScore <= 5 && awayScore <= 5);

        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper5.mapResult(rawResult);

        uint256 expected = uint256(homeScore) * 10 + uint256(awayScore);
        assertEq(outcomeIds[0], expected);
    }

    function testFuzz_mapResult_OutOfRange_IsOther(uint8 homeScore, uint8 awayScore) public view {
        vm.assume(homeScore > 5 || awayScore > 5);

        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper5.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_OTHER);
    }

    function testFuzz_previewResult_MatchesMapResult(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds1, uint256[] memory weights1) = mapper5.mapResult(rawResult);
        (uint256[] memory outcomeIds2, uint256[] memory weights2) = mapper5.previewResult(homeScore, awayScore);

        assertEq(outcomeIds1[0], outcomeIds2[0]);
        assertEq(weights1[0], weights2[0]);
    }

    function testFuzz_encodeDecodeRoundtrip(uint8 homeScore, uint8 awayScore) public view {
        vm.assume(homeScore <= 5 && awayScore <= 5);

        uint256 encoded = mapper5.encodeOutcome(homeScore, awayScore);
        (uint256 decodedHome, uint256 decodedAway, bool isOther) = mapper5.decodeOutcome(encoded);

        assertEq(decodedHome, homeScore);
        assertEq(decodedAway, awayScore);
        assertFalse(isOther);
    }
}
