// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IResultMapper.sol";

/**
 * @title Identity_Mapper
 * @notice 身份映射器 - 直接返回传入的 outcome ID
 * @dev 用于预言机直接指定获胜者的市场（如首位进球者、最佳球员、冠军预测）
 *
 * rawResult 格式: abi.encode(uint256 winningOutcomeId)
 *
 * 使用场景:
 * - 首位进球者（预言机报告进球球员 ID）
 * - 最佳球员（预言机报告获胜球员 ID）
 * - 冠军预测（预言机报告夺冠球队 ID）
 * - 其他由预言机直接决定结果的市场
 *
 * 注意：此 Mapper 是无状态的，一个实例可服务所有使用它的市场。
 * outcome 数量和名称由 Market 自身管理，不由 Mapper 提供。
 */
contract Identity_Mapper is IResultMapper {
    // ============ 常量 ============

    uint256 private constant BASIS_POINTS = 10000;

    // ============ IResultMapper 实现 ============

    /// @inheritdoc IResultMapper
    function mapResult(bytes calldata rawResult)
        external
        pure
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        // 解码获胜的 outcome ID
        uint256 winningOutcomeId = abi.decode(rawResult, (uint256));

        // 返回单一获胜者，权重 100%
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        outcomeIds[0] = winningOutcomeId;
        weights[0] = BASIS_POINTS;
    }

    /// @inheritdoc IResultMapper
    function outcomeCount() external pure override returns (uint256) {
        // 无状态，返回 0 表示不限制
        return 0;
    }

    /// @inheritdoc IResultMapper
    function mapperType() external pure override returns (string memory) {
        return "IDENTITY";
    }

    /// @inheritdoc IResultMapper
    function version() external pure override returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc IResultMapper
    function getParams() external pure override returns (bytes memory) {
        return "";
    }

    /// @inheritdoc IResultMapper
    function getOutcomeName(uint256 /* outcomeId */) external pure override returns (string memory) {
        // outcome 名称由 Market 管理
        return "";
    }

    /// @inheritdoc IResultMapper
    function getAllOutcomeNames() external pure override returns (string[] memory) {
        // outcome 名称由 Market 管理
        return new string[](0);
    }

    /// @inheritdoc IResultMapper
    function previewResult(uint256 homeScore, uint256 /* awayScore */)
        external
        pure
        override
        returns (uint256[] memory outcomeIds, uint256[] memory weights)
    {
        // 对于 Identity Mapper，homeScore 被视为 winningOutcomeId
        outcomeIds = new uint256[](1);
        weights = new uint256[](1);
        outcomeIds[0] = homeScore;
        weights[0] = BASIS_POINTS;
    }
}
