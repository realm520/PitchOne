// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IResultOracle.sol";

/**
 * @title MatchFactsHelper
 * @notice 辅助函数用于在测试中创建 MatchFacts
 * @dev Week 9: M3 扩展 - 简化测试中的 MatchFacts 创建
 */
library MatchFactsHelper {
    /**
     * @notice 创建基础 MatchFacts（不含球员数据）
     * @dev 向后兼容旧测试，playerStats 为空数组
     */
    function createBasicFacts(
        bytes32 scope,
        uint8 homeGoals,
        uint8 awayGoals,
        bool extraTime,
        uint8 penaltiesHome,
        uint8 penaltiesAway,
        uint256 reportedAt
    ) internal pure returns (IResultOracle.MatchFacts memory) {
        IResultOracle.PlayerStats[] memory emptyStats = new IResultOracle.PlayerStats[](0);

        return IResultOracle.MatchFacts({
            scope: scope,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            extraTime: extraTime,
            penaltiesHome: penaltiesHome,
            penaltiesAway: penaltiesAway,
            reportedAt: reportedAt,
            playerStats: emptyStats
        });
    }

    /**
     * @notice 创建包含单个球员数据的 MatchFacts
     */
    function createFactsWithPlayer(
        bytes32 scope,
        uint8 homeGoals,
        uint8 awayGoals,
        bool extraTime,
        uint8 penaltiesHome,
        uint8 penaltiesAway,
        uint256 reportedAt,
        IResultOracle.PlayerStats memory playerStat
    ) internal pure returns (IResultOracle.MatchFacts memory) {
        IResultOracle.PlayerStats[] memory stats = new IResultOracle.PlayerStats[](1);
        stats[0] = playerStat;

        return IResultOracle.MatchFacts({
            scope: scope,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            extraTime: extraTime,
            penaltiesHome: penaltiesHome,
            penaltiesAway: penaltiesAway,
            reportedAt: reportedAt,
            playerStats: stats
        });
    }

    /**
     * @notice 创建包含多个球员数据的 MatchFacts
     */
    function createFactsWithPlayers(
        bytes32 scope,
        uint8 homeGoals,
        uint8 awayGoals,
        bool extraTime,
        uint8 penaltiesHome,
        uint8 penaltiesAway,
        uint256 reportedAt,
        IResultOracle.PlayerStats[] memory playerStats
    ) internal pure returns (IResultOracle.MatchFacts memory) {
        return IResultOracle.MatchFacts({
            scope: scope,
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            extraTime: extraTime,
            penaltiesHome: penaltiesHome,
            penaltiesAway: penaltiesAway,
            reportedAt: reportedAt,
            playerStats: playerStats
        });
    }

    /**
     * @notice 创建球员统计数据
     */
    function createPlayerStats(
        string memory playerId,
        uint8 goals,
        uint8 assists,
        uint8 shots,
        uint8 shotsOnTarget,
        bool yellowCard,
        bool redCard,
        bool isFirstScorer,
        uint8 minuteFirstGoal
    ) internal pure returns (IResultOracle.PlayerStats memory) {
        return IResultOracle.PlayerStats({
            playerId: playerId,
            goals: goals,
            assists: assists,
            shots: shots,
            shotsOnTarget: shotsOnTarget,
            yellowCard: yellowCard,
            redCard: redCard,
            isFirstScorer: isFirstScorer,
            minuteFirstGoal: minuteFirstGoal
        });
    }
}
