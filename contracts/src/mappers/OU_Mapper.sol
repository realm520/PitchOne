// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title OU_Mapper
 * @notice 大小球（Over/Under）赛果映射器
 * @dev 支持两种盘口类型：
 *      1. 半球盘（如 2.5）：只有大/小两个结果
 *      2. 整球盘（如 3.0）：有大/Push/小三个结果
 *
 * Outcome IDs:
 *      - 0: 大球 (Over)
 *      - 1: Push (仅整球盘有效)
 *      - 2: 小球 (Under)
 *
 * 注意：半球盘时 outcome 1 (Push) 永远不会被触发
 *
 * 盘口线编码：
 *      - 使用 int256，精度为 0.25
 *      - 例如：2500 = 2.5 球，2750 = 2.75 球，3000 = 3.0 球
 */
contract OU_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant OUTCOME_OVER = 0;
    uint256 private constant OUTCOME_PUSH = 1;
    uint256 private constant OUTCOME_UNDER = 2;

    uint256 private constant FULL_WEIGHT = 10000; // 100%
    uint256 private constant LINE_PRECISION = 1000; // 盘口线精度：1000 = 1 球

    string private constant MAPPER_TYPE = "OU";
    string private constant VERSION = "1.0.0";

    // ============ 状态变量 ============

    /// @notice 盘口线（精度 1000，如 2500 = 2.5）
    int256 public immutable line;

    /// @notice 是否为整球盘（会产生 Push）
    bool public immutable isWholeLine;

    // ============ 构造函数 ============

    /**
     * @param _line 盘口线（精度 1000，如 2500 = 2.5）
     */
    constructor(int256 _line) {
        require(_line >= 0, "OU_Mapper: Line must be non-negative");
        line = _line;
        // 检查是否为整球盘（能被 1000 整除）
        isWholeLine = (_line % int256(LINE_PRECISION) == 0);
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
        uint256 totalGoals = homeScore + awayScore;
        int256 totalGoalsScaled = int256(totalGoals) * int256(LINE_PRECISION);

        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        weights[0] = FULL_WEIGHT;

        if (totalGoalsScaled > line) {
            // 大球
            outcomeIds[0] = OUTCOME_OVER;
        } else if (totalGoalsScaled < line) {
            // 小球
            outcomeIds[0] = OUTCOME_UNDER;
        } else {
            // 相等 - 只有整球盘才会出现
            // Push（退款）
            outcomeIds[0] = OUTCOME_PUSH;
        }
    }

    // ============ 元数据 ============

    /// @inheritdoc IResultMapper
    function outcomeCount() external pure override returns (uint256) {
        // 整球盘有 3 个结果（含 Push），半球盘只有 2 个有效结果
        // 但为了接口一致性，都返回 3
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
        if (outcomeId == OUTCOME_OVER) return _formatLineName("Over");
        if (outcomeId == OUTCOME_PUSH) return "Push";
        if (outcomeId == OUTCOME_UNDER) return _formatLineName("Under");
        revert("Invalid outcome ID");
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external view override returns (string[] memory names) {
        names = new string[](3);
        names[0] = _formatLineName("Over");
        names[1] = "Push";
        names[2] = _formatLineName("Under");
    }

    /**
     * @notice 格式化盘口线名称
     * @param prefix 前缀（Over/Under）
     * @return 格式化后的名称
     */
    function _formatLineName(string memory prefix) internal view returns (string memory) {
        // 简化实现：返回 "Over 2.5" 或 "Under 3.0" 格式
        // 实际生产环境可能需要更复杂的字符串处理
        uint256 wholePart = uint256(line) / LINE_PRECISION;
        uint256 decimalPart = uint256(line) % LINE_PRECISION;

        if (decimalPart == 0) {
            return string(abi.encodePacked(prefix, " ", _uint2str(wholePart), ".0"));
        } else if (decimalPart == 500) {
            return string(abi.encodePacked(prefix, " ", _uint2str(wholePart), ".5"));
        } else if (decimalPart == 250) {
            return string(abi.encodePacked(prefix, " ", _uint2str(wholePart), ".25"));
        } else if (decimalPart == 750) {
            return string(abi.encodePacked(prefix, " ", _uint2str(wholePart), ".75"));
        }
        return prefix;
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
