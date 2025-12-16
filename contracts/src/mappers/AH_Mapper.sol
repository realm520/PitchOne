// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title AH_Mapper
 * @notice 让球（Asian Handicap）赛果映射器
 * @dev 支持多种盘口类型：
 *      1. 半球盘（如 -0.5）：只有两个结果，无 Push
 *      2. 整球盘（如 -1.0）：有三个结果，含 Push
 *      3. 四分一盘（如 -0.75, -1.25）：支持半输半赢
 *
 * Outcome IDs:
 *      - 0: 主队赢盘
 *      - 1: Push（仅整球盘有效，四分一盘用 weights 表示）
 *      - 2: 客队赢盘
 *
 * 盘口线编码：
 *      - 使用 int256，精度为 0.25（乘以 1000）
 *      - 正数表示客队让球，负数表示主队让球
 *      - 例如：-750 = 主队让 0.75 球
 *
 * 四分一盘结算逻辑（以主队让 0.75 为例）：
 *      - 主队赢 2+ 球：主队赢盘 100%
 *      - 主队赢 1 球：主队赢盘 50% + Push 50%（表示为 weights = [5000, 5000]）
 *      - 平局或客队赢：客队赢盘 100%
 */
contract AH_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant OUTCOME_HOME_WIN = 0;
    uint256 private constant OUTCOME_PUSH = 1;
    uint256 private constant OUTCOME_AWAY_WIN = 2;

    uint256 private constant FULL_WEIGHT = 10000; // 100%
    uint256 private constant HALF_WEIGHT = 5000;  // 50%
    int256 private constant LINE_PRECISION = 1000; // 盘口线精度

    string private constant MAPPER_TYPE = "AH";
    string private constant VERSION = "1.0.0";

    // ============ 状态变量 ============

    /// @notice 让球盘口线（精度 1000，负数表示主队让球）
    int256 public immutable line;

    /// @notice 盘口类型
    /// 0: 半球盘（.5）- 无 Push
    /// 1: 整球盘（.0）- 有 Push
    /// 2: 四分一盘（.25 或 .75）- 支持半输半赢
    uint8 public immutable lineType;

    // ============ 构造函数 ============

    /**
     * @param _line 让球盘口线（精度 1000）
     *              负数 = 主队让球，正数 = 客队让球
     *              例如：-750 = 主队让 0.75 球
     */
    constructor(int256 _line) {
        line = _line;

        // 确定盘口类型
        int256 remainder = _line % LINE_PRECISION;
        if (remainder < 0) remainder = -remainder; // 取绝对值

        if (remainder == 500) {
            lineType = 0; // 半球盘
        } else if (remainder == 0) {
            lineType = 1; // 整球盘
        } else {
            lineType = 2; // 四分一盘（.25 或 .75）
        }
    }

    // ============ 核心映射 ============

    /// @inheritdoc IResultMapper
    function mapResult(bytes calldata rawResult)
        external
        view
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        (uint256 homeScore, uint256 awayScore) = abi.decode(rawResult, (uint256, uint256));
        return _mapScores(homeScore, awayScore);
    }

    /// @inheritdoc IResultMapper
    function previewResult(uint256 homeScore, uint256 awayScore)
        external
        view
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        return _mapScores(homeScore, awayScore);
    }

    // ============ 内部函数 ============

    function _mapScores(uint256 homeScore, uint256 awayScore)
        internal
        view
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        // 计算让球后的差值（主队视角）
        // adjustedDiff = (homeScore - awayScore) * 1000 + line
        // 如果 line = -750（主队让 0.75），则主队赢 1 球时 adjustedDiff = 1000 - 750 = 250
        int256 goalDiff = int256(homeScore) - int256(awayScore);
        int256 adjustedDiff = goalDiff * LINE_PRECISION + line;

        if (lineType == 0) {
            // 半球盘：无 Push，只有输赢
            return _handleHalfLine(adjustedDiff);
        } else if (lineType == 1) {
            // 整球盘：可能有 Push
            return _handleWholeLine(adjustedDiff);
        } else {
            // 四分一盘：可能半输半赢
            return _handleQuarterLine(adjustedDiff, goalDiff);
        }
    }

    /**
     * @notice 处理半球盘（如 -0.5, -1.5）
     */
    function _handleHalfLine(int256 adjustedDiff)
        internal
        pure
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        if (adjustedDiff > 0) {
            outcomeIds[0] = OUTCOME_HOME_WIN;
        } else {
            outcomeIds[0] = OUTCOME_AWAY_WIN;
        }
    }

    /**
     * @notice 处理整球盘（如 -1.0, -2.0）
     */
    function _handleWholeLine(int256 adjustedDiff)
        internal
        pure
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        if (adjustedDiff > 0) {
            outcomeIds[0] = OUTCOME_HOME_WIN;
        } else if (adjustedDiff < 0) {
            outcomeIds[0] = OUTCOME_AWAY_WIN;
        } else {
            // Push - 退款
            outcomeIds[0] = OUTCOME_PUSH;
        }
    }

    /**
     * @notice 处理四分一盘（如 -0.75, -1.25）
     * @dev 四分一盘可以理解为两个相邻半球盘的组合
     *      例如 -0.75 = (-0.5 + -1.0) / 2
     *
     *      结算规则（以主队让 0.75 为例）：
     *      - 主队赢 2+ 球：主队全赢
     *      - 主队赢 1 球：主队半赢（赢盘 50% + Push 50%）
     *      - 平局：客队全赢
     *      - 客队赢：客队全赢
     */
    function _handleQuarterLine(int256 adjustedDiff, int256 goalDiff)
        internal
        view
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        // 获取盘口线的小数部分来判断是 .25 还是 .75
        int256 remainder = line % LINE_PRECISION;
        if (remainder < 0) remainder = -remainder;
        bool isPoint75 = (remainder == 750);
        bool isPoint25 = (remainder == 250);

        // 计算让球后的整数差值
        int256 baseAdjustedDiff = goalDiff * LINE_PRECISION + (line / LINE_PRECISION) * LINE_PRECISION;

        if (adjustedDiff > LINE_PRECISION / 2) {
            // 明显赢盘（差值 > 0.5 球）
            outcomeIds = new uint256[](1);
            weights = new uint256[](1);
            outcomeIds[0] = OUTCOME_HOME_WIN;
            weights[0] = FULL_WEIGHT;
        } else if (adjustedDiff < -int256(LINE_PRECISION / 2)) {
            // 明显输盘（差值 < -0.5 球）
            outcomeIds = new uint256[](1);
            weights = new uint256[](1);
            outcomeIds[0] = OUTCOME_AWAY_WIN;
            weights[0] = FULL_WEIGHT;
        } else if (adjustedDiff > 0) {
            // 半赢：0 < 差值 <= 0.5
            // 主队半赢 = 主队赢盘 50% + Push 退款 50%
            outcomeIds = new uint256[](2);
            weights = new uint256[](2);
            outcomeIds[0] = OUTCOME_HOME_WIN;
            outcomeIds[1] = OUTCOME_PUSH;
            weights[0] = HALF_WEIGHT;
            weights[1] = HALF_WEIGHT;
        } else if (adjustedDiff < 0) {
            // 半输：-0.5 <= 差值 < 0
            // 主队半输 = 客队赢盘 50% + Push 退款 50%
            outcomeIds = new uint256[](2);
            weights = new uint256[](2);
            outcomeIds[0] = OUTCOME_AWAY_WIN;
            outcomeIds[1] = OUTCOME_PUSH;
            weights[0] = HALF_WEIGHT;
            weights[1] = HALF_WEIGHT;
        } else {
            // adjustedDiff == 0，这在四分一盘中不应该发生
            // 但作为安全措施，处理为 Push
            outcomeIds = new uint256[](1);
            weights = new uint256[](1);
            outcomeIds[0] = OUTCOME_PUSH;
            weights[0] = FULL_WEIGHT;
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
    function getParams() external view override returns (bytes memory) {
        return abi.encode(line);
    }

    // ============ 辅助查询 ============

    /// @inheritdoc IResultMapper
    function getOutcomeName(uint256 outcomeId) external view override returns (string memory name) {
        if (outcomeId == OUTCOME_HOME_WIN) return "Home +line";
        if (outcomeId == OUTCOME_PUSH) return "Push";
        if (outcomeId == OUTCOME_AWAY_WIN) return "Away -line";
        revert("Invalid outcome ID");
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external view override returns (string[] memory names) {
        names = new string[](3);
        names[0] = "Home +line";
        names[1] = "Push";
        names[2] = "Away -line";
    }
}
