// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/oracle/MockOracle.sol";
import "../../src/interfaces/IResultOracle.sol";

/**
 * @title MockOracleTest
 * @notice MockOracle 合约的单元测试
 * @dev 测试覆盖：
 *      1. 基础功能（提交结果、获取结果）
 *      2. 权限控制（仅 Owner 可提交）
 *      3. 数据验证（scope、进球数、点球数据一致性）
 *      4. 重复提交保护
 *      5. 批量提交
 */
contract MockOracleTest is Test {
    MockOracle public oracle;
    address public owner;
    address public user;

    // 测试用的 marketId
    bytes32 constant MARKET_ID_1 = bytes32(uint256(1));
    bytes32 constant MARKET_ID_2 = bytes32(uint256(2));

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");

        oracle = new MockOracle(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          基础功能测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试成功提交常规90分钟比赛结果（主队胜）
    function test_ProposeResult_FT90_HomeWin() public {
        // 准备数据：主队2:1客队
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        // 预期事件
        bytes32 expectedHash = keccak256(abi.encode(facts));
        vm.expectEmit(true, true, true, true);
        emit IResultOracle.ResultProposed(MARKET_ID_1, facts, expectedHash, owner);
        vm.expectEmit(true, true, true, true);
        emit IResultOracle.ResultFinalized(MARKET_ID_1, expectedHash, true);

        // 执行
        oracle.proposeResult(MARKET_ID_1, facts);

        // 验证结果
        (IResultOracle.MatchFacts memory storedFacts, bool finalized) = oracle.getResult(MARKET_ID_1);
        assertTrue(finalized, "Result should be finalized");
        assertEq(storedFacts.homeGoals, 2, "Home goals mismatch");
        assertEq(storedFacts.awayGoals, 1, "Away goals mismatch");
        assertEq(storedFacts.scope, bytes32("FT_90"), "Scope mismatch");

        // 验证 isFinalized
        assertTrue(oracle.isFinalized(MARKET_ID_1), "Should be finalized");

        // 验证 resultHash
        assertEq(oracle.getResultHash(MARKET_ID_1), expectedHash, "Result hash mismatch");
    }

    /// @notice 测试成功提交平局结果
    function test_ProposeResult_FT90_Draw() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        oracle.proposeResult(MARKET_ID_1, facts);

        (IResultOracle.MatchFacts memory storedFacts,) = oracle.getResult(MARKET_ID_1);
        assertEq(storedFacts.homeGoals, 1, "Home goals mismatch");
        assertEq(storedFacts.awayGoals, 1, "Away goals mismatch");
    }

    /// @notice 测试成功提交120分钟比赛结果（含加时）
    function test_ProposeResult_FT120_WithExtraTime() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_120"),
            homeGoals: 3,
            awayGoals: 2,
            extraTime: true,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        oracle.proposeResult(MARKET_ID_1, facts);

        (IResultOracle.MatchFacts memory storedFacts,) = oracle.getResult(MARKET_ID_1);
        assertEq(storedFacts.homeGoals, 3);
        assertEq(storedFacts.awayGoals, 2);
        assertTrue(storedFacts.extraTime);
    }

    /// @notice 测试成功提交点球大战结果
    function test_ProposeResult_Penalties_HomeWin() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("Penalties"),
            homeGoals: 2,           // 常规时间+加时的进球
            awayGoals: 2,
            extraTime: true,        // 点球大战必须有加时
            penaltiesHome: 5,       // 点球大战进球
            penaltiesAway: 4,
            reportedAt: block.timestamp
        });

        oracle.proposeResult(MARKET_ID_1, facts);

        (IResultOracle.MatchFacts memory storedFacts,) = oracle.getResult(MARKET_ID_1);
        assertEq(storedFacts.penaltiesHome, 5);
        assertEq(storedFacts.penaltiesAway, 4);
    }

    /*//////////////////////////////////////////////////////////////
                          权限控制测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试非 Owner 提交失败
    function test_ProposeResult_RevertWhen_NotOwner() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.prank(user);
        vm.expectRevert();
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /*//////////////////////////////////////////////////////////////
                          数据验证测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试无效 scope 失败
    function test_ProposeResult_RevertWhen_InvalidScope() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("INVALID"),
            homeGoals: 1,
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(MockOracle.InvalidMatchFacts.selector, "Invalid scope")
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /// @notice 测试进球数超限失败
    function test_ProposeResult_RevertWhen_GoalsExceedLimit() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 51, // 超过限制
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(MockOracle.InvalidMatchFacts.selector, "Goals exceed limit")
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /// @notice 测试点球场景但未设置 extraTime 失败
    function test_ProposeResult_RevertWhen_PenaltiesWithoutExtraTime() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("Penalties"),
            homeGoals: 2,
            awayGoals: 2,
            extraTime: false, // 应该为 true
            penaltiesHome: 5,
            penaltiesAway: 4,
            reportedAt: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                MockOracle.InvalidMatchFacts.selector,
                "Penalties require extraTime"
            )
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /// @notice 测试点球场景但点球数据缺失失败
    function test_ProposeResult_RevertWhen_PenaltiesDataMissing() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("Penalties"),
            homeGoals: 2,
            awayGoals: 2,
            extraTime: true,
            penaltiesHome: 0, // 应该非0
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(MockOracle.InvalidMatchFacts.selector, "Penalties data missing")
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /// @notice 测试非点球场景但有点球数据失败
    function test_ProposeResult_RevertWhen_UnexpectedPenaltiesData() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 5, // 不应该有
            penaltiesAway: 4,
            reportedAt: block.timestamp
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                MockOracle.InvalidMatchFacts.selector,
                "Unexpected penalties data"
            )
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /// @notice 测试未来时间戳失败
    function test_ProposeResult_RevertWhen_FutureTimestamp() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp + 1 days // 未来时间
        });

        vm.expectRevert(
            abi.encodeWithSelector(MockOracle.InvalidMatchFacts.selector, "Future timestamp")
        );
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /*//////////////////////////////////////////////////////////////
                        重复提交保护测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试重复提交失败
    function test_ProposeResult_RevertWhen_AlreadySubmitted() public {
        // 第一次提交
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });
        oracle.proposeResult(MARKET_ID_1, facts);

        // 第二次提交（应该失败）
        vm.expectRevert(abi.encodeWithSelector(MockOracle.ResultAlreadySubmitted.selector, MARKET_ID_1));
        oracle.proposeResult(MARKET_ID_1, facts);
    }

    /*//////////////////////////////////////////////////////////////
                          批量提交测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试批量提交成功
    function test_BatchProposeResults_Success() public {
        bytes32[] memory marketIds = new bytes32[](2);
        marketIds[0] = MARKET_ID_1;
        marketIds[1] = MARKET_ID_2;

        IResultOracle.MatchFacts[] memory factsArray = new IResultOracle.MatchFacts[](2);
        factsArray[0] = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });
        factsArray[1] = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 0,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        oracle.batchProposeResults(marketIds, factsArray);

        // 验证两个结果都已提交
        assertTrue(oracle.isFinalized(MARKET_ID_1));
        assertTrue(oracle.isFinalized(MARKET_ID_2));

        (IResultOracle.MatchFacts memory facts1,) = oracle.getResult(MARKET_ID_1);
        assertEq(facts1.homeGoals, 2);

        (IResultOracle.MatchFacts memory facts2,) = oracle.getResult(MARKET_ID_2);
        assertEq(facts2.awayGoals, 1);
    }

    /// @notice 测试批量提交长度不匹配失败
    function test_BatchProposeResults_RevertWhen_LengthMismatch() public {
        bytes32[] memory marketIds = new bytes32[](2);
        IResultOracle.MatchFacts[] memory factsArray = new IResultOracle.MatchFacts[](1);

        vm.expectRevert(
            abi.encodeWithSelector(MockOracle.InvalidMatchFacts.selector, "Length mismatch")
        );
        oracle.batchProposeResults(marketIds, factsArray);
    }

    /*//////////////////////////////////////////////////////////////
                          查询功能测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试查询不存在的结果失败
    function test_GetResult_RevertWhen_NotFound() public {
        vm.expectRevert(abi.encodeWithSelector(MockOracle.ResultNotFound.selector, MARKET_ID_1));
        oracle.getResult(MARKET_ID_1);
    }

    /// @notice 测试查询未提交的 marketId 返回 false
    function test_IsFinalized_ReturnsFalse_WhenNotSubmitted() public {
        assertFalse(oracle.isFinalized(MARKET_ID_1));
    }

    /// @notice 测试查询未提交的 resultHash 返回零值
    function test_GetResultHash_ReturnsZero_WhenNotSubmitted() public {
        assertEq(oracle.getResultHash(MARKET_ID_1), bytes32(0));
    }

    /*//////////////////////////////////////////////////////////////
                          边界条件测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试进球数边界值（50）
    function test_ProposeResult_BoundaryGoals_Max() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 50,
            awayGoals: 50,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        oracle.proposeResult(MARKET_ID_1, facts);

        (IResultOracle.MatchFacts memory storedFacts,) = oracle.getResult(MARKET_ID_1);
        assertEq(storedFacts.homeGoals, 50);
        assertEq(storedFacts.awayGoals, 50);
    }

    /// @notice 测试当前时间戳
    function test_ProposeResult_CurrentTimestamp() public {
        uint256 currentTime = block.timestamp;

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: currentTime
        });

        oracle.proposeResult(MARKET_ID_1, facts);

        (IResultOracle.MatchFacts memory storedFacts,) = oracle.getResult(MARKET_ID_1);
        assertEq(storedFacts.reportedAt, currentTime);
    }
}
