// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title OddEven_Mapper
 * @notice 单双（Odd/Even）赛果映射器
 * @dev 判断总进球数是奇数还是偶数
 *
 * Outcome IDs:
 *      - 0: 奇数 (Odd)
 *      - 1: 偶数 (Even)
 *
 * 注意：0-0 算作偶数（0 是偶数）
 */
contract OddEven_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant OUTCOME_ODD = 0;
    uint256 private constant OUTCOME_EVEN = 1;

    uint256 private constant FULL_WEIGHT = 10000; // 100%

    string private constant MAPPER_TYPE = "ODD_EVEN";
    string private constant VERSION = "1.0.0";

    // ============ 核心映射 ============

    /// @inheritdoc IResultMapper
    function mapResult(bytes calldata rawResult)
        external
        pure
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        (uint256 homeScore, uint256 awayScore) = abi.decode(rawResult, (uint256, uint256));
        return _mapScores(homeScore, awayScore);
    }

    /// @inheritdoc IResultMapper
    function previewResult(uint256 homeScore, uint256 awayScore)
        external
        pure
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        return _mapScores(homeScore, awayScore);
    }

    // ============ 内部函数 ============

    function _mapScores(uint256 homeScore, uint256 awayScore)
        internal
        pure
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        uint256 totalGoals = homeScore + awayScore;

        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        if (totalGoals % 2 == 1) {
            outcomeIds[0] = OUTCOME_ODD;
        } else {
            outcomeIds[0] = OUTCOME_EVEN;
        }
    }

    // ============ 元数据 ============

    /// @inheritdoc IResultMapper
    function outcomeCount() external pure override returns (uint256) {
        return 2;
    }

    /// @inheritdoc IResultMapper
    function mapperType() external pure override returns (string memory) {
        return MAPPER_TYPE;
    }

    /// @inheritdoc IResultMapper
    function version() external pure override returns (string memory) {
        return VERSION;
    }

    /// @inheritdoc IResultMapper
    function getParams() external pure override returns (bytes memory) {
        return ""; // 无参数
    }

    // ============ 辅助查询 ============

    /// @inheritdoc IResultMapper
    function getOutcomeName(uint256 outcomeId) external pure override returns (string memory name) {
        if (outcomeId == OUTCOME_ODD) return "Odd";
        if (outcomeId == OUTCOME_EVEN) return "Even";
        revert("Invalid outcome ID");
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external pure override returns (string[] memory names) {
        names = new string[](2);
        names[0] = "Odd";
        names[1] = "Even";
    }
}
