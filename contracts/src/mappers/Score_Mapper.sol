// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title Score_Mapper
 * @notice 精确比分（Correct Score）赛果映射器
 * @dev 支持多种精确比分结果，适合与 LMSR 定价策略配合使用
 *
 * Outcome ID 编码规则：
 *      outcomeId = homeScore * 10 + awayScore
 *      例如：2-1 的 outcomeId = 21
 *
 * 默认支持的比分范围：0-5 : 0-5，共 36 种比分
 * 另外还有一个 "Other" 选项（outcomeId = 999），用于超出范围的比分
 *
 * 总 outcome 数量 = 37（36 种精确比分 + 1 个 Other）
 */
contract Score_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant OUTCOME_OTHER = 999; // 超出范围的比分
    uint256 private constant FULL_WEIGHT = 10000; // 100%

    string private constant MAPPER_TYPE = "SCORE";
    string private constant VERSION = "1.0.0";

    // ============ 状态变量 ============

    /// @notice 最大单方进球数（默认 5，可配置）
    uint256 public immutable maxGoals;

    /// @notice 总 outcome 数量（包含 Other）
    uint256 public immutable totalOutcomes;

    // ============ 构造函数 ============

    /**
     * @param _maxGoals 最大单方进球数（如 5 表示支持 0-5 : 0-5 的所有比分）
     */
    constructor(uint256 _maxGoals) {
        require(_maxGoals >= 2 && _maxGoals <= 9, "Score_Mapper: maxGoals must be 2-9");
        maxGoals = _maxGoals;
        // 总数 = (maxGoals + 1)^2 + 1 (Other)
        totalOutcomes = (maxGoals + 1) * (maxGoals + 1) + 1;
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
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        // 检查是否在支持范围内
        if (homeScore <= maxGoals && awayScore <= maxGoals) {
            // 编码：homeScore * 10 + awayScore
            outcomeIds[0] = homeScore * 10 + awayScore;
        } else {
            // 超出范围，归类到 Other
            outcomeIds[0] = OUTCOME_OTHER;
        }
    }

    // ============ 元数据 ============

    /// @inheritdoc IResultMapper
    function outcomeCount() external view override returns (uint256) {
        return totalOutcomes;
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
        return abi.encode(maxGoals);
    }

    // ============ 辅助查询 ============

    /// @inheritdoc IResultMapper
    function getOutcomeName(uint256 outcomeId) external view override returns (string memory name) {
        if (outcomeId == OUTCOME_OTHER) {
            return "Other";
        }

        uint256 homeScore = outcomeId / 10;
        uint256 awayScore = outcomeId % 10;

        if (homeScore > maxGoals || awayScore > maxGoals) {
            revert("Invalid outcome ID");
        }

        return string(abi.encodePacked(
            _uint2str(homeScore),
            "-",
            _uint2str(awayScore)
        ));
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external view override returns (string[] memory names) {
        names = new string[](totalOutcomes);

        uint256 index = 0;
        for (uint256 home = 0; home <= maxGoals; home++) {
            for (uint256 away = 0; away <= maxGoals; away++) {
                names[index] = string(abi.encodePacked(
                    _uint2str(home),
                    "-",
                    _uint2str(away)
                ));
                index++;
            }
        }

        // 最后一个是 Other
        names[index] = "Other";
    }

    // ============ 辅助函数 ============

    /**
     * @notice 将 outcomeId 解码为比分
     * @param outcomeId outcome ID
     * @return homeScore 主队进球
     * @return awayScore 客队进球
     * @return isOther 是否为 Other
     */
    function decodeOutcome(uint256 outcomeId)
        external
        view
        returns (uint256 homeScore, uint256 awayScore, bool isOther)
    {
        if (outcomeId == OUTCOME_OTHER) {
            return (0, 0, true);
        }

        homeScore = outcomeId / 10;
        awayScore = outcomeId % 10;

        if (homeScore > maxGoals || awayScore > maxGoals) {
            revert("Invalid outcome ID");
        }

        return (homeScore, awayScore, false);
    }

    /**
     * @notice 将比分编码为 outcomeId
     * @param homeScore 主队进球
     * @param awayScore 客队进球
     * @return outcomeId outcome ID
     */
    function encodeOutcome(uint256 homeScore, uint256 awayScore)
        external
        view
        returns (uint256 outcomeId)
    {
        if (homeScore > maxGoals || awayScore > maxGoals) {
            return OUTCOME_OTHER;
        }
        return homeScore * 10 + awayScore;
    }

    /**
     * @notice 获取所有有效的 outcomeIds（用于前端）
     * @return ids 所有有效的 outcomeId 数组
     */
    function getAllValidOutcomeIds() external view returns (uint256[] memory ids) {
        ids = new uint256[](totalOutcomes);

        uint256 index = 0;
        for (uint256 home = 0; home <= maxGoals; home++) {
            for (uint256 away = 0; away <= maxGoals; away++) {
                ids[index] = home * 10 + away;
                index++;
            }
        }

        ids[index] = OUTCOME_OTHER;
    }

    /**
     * @notice 将 uint 转为字符串
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _i % 10);
            bstr[k] = bytes1(temp);
            _i /= 10;
        }
        return string(bstr);
    }
}
