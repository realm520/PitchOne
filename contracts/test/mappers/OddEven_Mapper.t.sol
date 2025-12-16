// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/mappers/OddEven_Mapper.sol";

/**
 * @title OddEven_Mapper_Test
 * @notice 单双（Odd/Even）映射器单元测试
 */
contract OddEven_Mapper_Test is Test {
    OddEven_Mapper public mapper;

    uint256 constant OUTCOME_ODD = 0;
    uint256 constant OUTCOME_EVEN = 1;
    uint256 constant FULL_WEIGHT = 10000;

    function setUp() public {
        mapper = new OddEven_Mapper();
    }

    // ============ 元数据测试 ============

    function test_outcomeCount() public view {
        assertEq(mapper.outcomeCount(), 2);
    }

    function test_mapperType() public view {
        assertEq(mapper.mapperType(), "ODD_EVEN");
    }

    function test_version() public view {
        assertEq(mapper.version(), "1.0.0");
    }

    function test_getParams() public view {
        assertEq(mapper.getParams(), "");
    }

    function test_getOutcomeName_Odd() public view {
        assertEq(mapper.getOutcomeName(OUTCOME_ODD), "Odd");
    }

    function test_getOutcomeName_Even() public view {
        assertEq(mapper.getOutcomeName(OUTCOME_EVEN), "Even");
    }

    function test_getOutcomeName_Invalid() public {
        vm.expectRevert("Invalid outcome ID");
        mapper.getOutcomeName(2);
    }

    function test_getAllOutcomeNames() public view {
        string[] memory names = mapper.getAllOutcomeNames();
        assertEq(names.length, 2);
        assertEq(names[0], "Odd");
        assertEq(names[1], "Even");
    }

    // ============ 核心映射测试 - Even ============

    function test_mapResult_Even_0goals() public view {
        // 0-0 = 0 球，0 是偶数
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds.length, 1);
        assertEq(outcomeIds[0], OUTCOME_EVEN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Even_2goals() public view {
        // 1-1 = 2 球
        bytes memory rawResult = abi.encode(uint256(1), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_EVEN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Even_4goals() public view {
        // 3-1 = 4 球
        bytes memory rawResult = abi.encode(uint256(3), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_EVEN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Even_6goals() public view {
        // 4-2 = 6 球
        bytes memory rawResult = abi.encode(uint256(4), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_EVEN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 核心映射测试 - Odd ============

    function test_mapResult_Odd_1goal() public view {
        // 1-0 = 1 球
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Odd_3goals() public view {
        // 2-1 = 3 球
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Odd_5goals() public view {
        // 3-2 = 5 球
        bytes memory rawResult = abi.encode(uint256(3), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_mapResult_Odd_7goals() public view {
        // 5-2 = 7 球
        bytes memory rawResult = abi.encode(uint256(5), uint256(2));
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ previewResult 测试 ============

    function test_previewResult_Even() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.previewResult(2, 2);

        // 4 球是偶数
        assertEq(outcomeIds[0], OUTCOME_EVEN);
        assertEq(weights[0], FULL_WEIGHT);
    }

    function test_previewResult_Odd() public view {
        (uint256[] memory outcomeIds, uint256[] memory weights) = mapper.previewResult(3, 0);

        // 3 球是奇数
        assertEq(outcomeIds[0], OUTCOME_ODD);
        assertEq(weights[0], FULL_WEIGHT);
    }

    // ============ 边界测试 ============

    function test_boundary_ZeroIsEven() public view {
        // 0 是偶数
        bytes memory rawResult = abi.encode(uint256(0), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_EVEN);
    }

    function test_boundary_OneIsOdd() public view {
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
    }

    function test_highScore_Even() public view {
        // 10 球是偶数
        bytes memory rawResult = abi.encode(uint256(5), uint256(5));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_EVEN);
    }

    function test_highScore_Odd() public view {
        // 9 球是奇数
        bytes memory rawResult = abi.encode(uint256(5), uint256(4));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        assertEq(outcomeIds[0], OUTCOME_ODD);
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
        assertTrue(outcomeIds[0] <= OUTCOME_EVEN);
    }

    function testFuzz_mapResult_CorrectParity(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

        uint256 totalGoals = uint256(homeScore) + uint256(awayScore);

        if (totalGoals % 2 == 0) {
            assertEq(outcomeIds[0], OUTCOME_EVEN);
        } else {
            assertEq(outcomeIds[0], OUTCOME_ODD);
        }
    }

    function testFuzz_previewResult_MatchesMapResult(uint8 homeScore, uint8 awayScore) public view {
        bytes memory rawResult = abi.encode(uint256(homeScore), uint256(awayScore));
        (uint256[] memory outcomeIds1, uint256[] memory weights1) = mapper.mapResult(rawResult);
        (uint256[] memory outcomeIds2, uint256[] memory weights2) = mapper.previewResult(homeScore, awayScore);

        assertEq(outcomeIds1[0], outcomeIds2[0]);
        assertEq(weights1[0], weights2[0]);
    }

    // ============ 模式测试 ============

    function test_alternatingPattern() public view {
        // 测试连续进球数的奇偶交替
        for (uint256 i = 0; i <= 10; i++) {
            bytes memory rawResult = abi.encode(i, uint256(0));
            (uint256[] memory outcomeIds, ) = mapper.mapResult(rawResult);

            if (i % 2 == 0) {
                assertEq(outcomeIds[0], OUTCOME_EVEN);
            } else {
                assertEq(outcomeIds[0], OUTCOME_ODD);
            }
        }
    }
}
