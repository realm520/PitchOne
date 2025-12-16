// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title WDL_Mapper
 * @notice 胜平负（Win/Draw/Loss）赛果映射器
 * @dev Outcome IDs:
 *      - 0: 主队胜 (Win)
 *      - 1: 平局 (Draw)
 *      - 2: 客队胜 (Loss/Away Win)
 *
 * 适用场景：
 *      - 足球 90 分钟比赛结果
 *      - 篮球常规时间胜负（需调整为二向）
 */
contract WDL_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant OUTCOME_WIN = 0;
    uint256 private constant OUTCOME_DRAW = 1;
    uint256 private constant OUTCOME_LOSS = 2;

    uint256 private constant FULL_WEIGHT = 10000; // 100%

    string private constant MAPPER_TYPE = "WDL";
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
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        if (homeScore > awayScore) {
            outcomeIds[0] = OUTCOME_WIN;
        } else if (homeScore == awayScore) {
            outcomeIds[0] = OUTCOME_DRAW;
        } else {
            outcomeIds[0] = OUTCOME_LOSS;
        }
    }

    // ============ 元数据 ============

    /// @inheritdoc IResultMapper
    function outcomeCount() external pure override returns (uint256) {
        return 3;
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
        return ""; // WDL 无参数
    }

    // ============ 辅助查询 ============

    /// @inheritdoc IResultMapper
    function getOutcomeName(uint256 outcomeId) external pure override returns (string memory name) {
        if (outcomeId == OUTCOME_WIN) return "Home Win";
        if (outcomeId == OUTCOME_DRAW) return "Draw";
        if (outcomeId == OUTCOME_LOSS) return "Away Win";
        revert("Invalid outcome ID");
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external pure override returns (string[] memory names) {
        names = new string[](3);
        names[0] = "Home Win";
        names[1] = "Draw";
        names[2] = "Away Win";
    }
}
