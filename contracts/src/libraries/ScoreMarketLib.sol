// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ScoreMarketLib
 * @notice 精确比分市场的辅助函数库
 * @dev 用于减小 ScoreTemplate 和 ScoreTemplate_V2 的合约大小
 */
library ScoreMarketLib {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice Other 结果的 Outcome ID
    uint256 internal constant OTHER_OUTCOME_ID = 999;

    // ============================================================================
    // 错误定义
    // ============================================================================

    error ProbabilitiesLengthMismatch();
    error ProbabilitiesSumInvalid();

    // ============================================================================
    // 比分编码/解码
    // ============================================================================

    /**
     * @notice 编码比分为 Outcome ID
     * @param homeGoals 主队进球数
     * @param awayGoals 客队进球数
     * @return outcomeId 结果ID
     */
    function encodeScore(uint8 homeGoals, uint8 awayGoals)
        internal
        pure
        returns (uint256 outcomeId)
    {
        return uint256(homeGoals) * 10 + uint256(awayGoals);
    }

    /**
     * @notice 解码 Outcome ID 为比分
     * @param outcomeId 结果ID
     * @return homeGoals 主队进球数
     * @return awayGoals 客队进球数
     */
    function decodeOutcomeId(uint256 outcomeId)
        internal
        pure
        returns (uint8 homeGoals, uint8 awayGoals)
    {
        if (outcomeId == OTHER_OUTCOME_ID) {
            return (255, 255); // 特殊标记
        }

        homeGoals = uint8(outcomeId / 10);
        awayGoals = uint8(outcomeId % 10);
    }

    /**
     * @notice 构建有效的 Outcome IDs
     * @param maxGoals 最大进球数
     * @dev 注意：此函数签名不可用（Solidity 不允许在库函数中返回 storage 映射），
     *      需要在合约中内联或重新设计。返回值未命名以避免编译警告。
     */
    function buildOutcomeIds(uint8 maxGoals)
        internal
        pure
        returns (
            uint256[] memory,
            mapping(uint256 => uint256) storage,
            mapping(uint256 => bool) storage
        )
    {
        // 注意：Solidity 不允许在库函数中返回 storage 映射
        // 此函数签名不可用，需要在合约中内联或重新设计
        maxGoals; // silence unused parameter warning
        revert("Not implemented - use in contract");
    }

    /**
     * @notice 将概率分布转换为 LMSR 初始持仓量
     * @param probabilities 概率数组（基点，总和应该 ≈ 10000）
     * @param outcomeCount 结果数量
     * @return quantities 持仓量数组（WAD 精度）
     *
     * @dev 使用简化公式: q_i = baseQuantity * (p_i / avgProb)
     */
    function convertProbabilitiesToQuantities(
        uint256[] memory probabilities,
        uint256 outcomeCount
    ) internal pure returns (uint256[] memory quantities) {
        // 如果未提供概率，使用均匀分布
        if (probabilities.length == 0) {
            quantities = new uint256[](outcomeCount);
            uint256 uniformQuantity = 100 * 1e18; // 每个结果 100 份额
            for (uint256 i = 0; i < outcomeCount; i++) {
                quantities[i] = uniformQuantity;
            }
            return quantities;
        }

        if (probabilities.length != outcomeCount) {
            revert ProbabilitiesLengthMismatch();
        }

        // 验证概率总和 ≈ 100%
        uint256 totalProb = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            totalProb += probabilities[i];
        }
        if (totalProb < 9900 || totalProb > 10100) {
            revert ProbabilitiesSumInvalid();
        }

        // 转换概率为持仓量
        // 简化方案：q_i = baseQuantity * (p_i / avgProb)
        quantities = new uint256[](outcomeCount);
        uint256 baseQuantity = 100 * 1e18; // 基础份额
        uint256 avgProb = 10000 / outcomeCount; // 平均概率

        for (uint256 i = 0; i < outcomeCount; i++) {
            // 防止 probabilities[i] = 0
            if (probabilities[i] == 0) {
                quantities[i] = baseQuantity / 10; // 最小份额
            } else {
                // q_i = baseQuantity * (p_i / avgProb)
                quantities[i] = (baseQuantity * probabilities[i]) / avgProb;
            }
        }

        return quantities;
    }

    /**
     * @notice 根据最终比分确定获胜结果
     * @param finalHomeGoals 最终主队进球数
     * @param finalAwayGoals 最终客队进球数
     * @param maxGoals 最大进球数范围
     * @return outcomeId 获胜结果ID
     */
    function determineWinningOutcome(
        uint8 finalHomeGoals,
        uint8 finalAwayGoals,
        uint8 maxGoals
    ) internal pure returns (uint256 outcomeId) {
        if (finalHomeGoals <= maxGoals && finalAwayGoals <= maxGoals) {
            // 标准比分
            return encodeScore(finalHomeGoals, finalAwayGoals);
        } else {
            // 超出范围，归为 Other
            return OTHER_OUTCOME_ID;
        }
    }
}
