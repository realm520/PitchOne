// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAH_Template
 * @notice 让球（Asian Handicap）市场模板接口
 * @dev M2 阶段实现单线版本（如 -0.5），M3 阶段扩展多线
 */
interface IAH_Template {
    // ============================================================================
    // 枚举与结构体
    // ============================================================================

    /**
     * @notice 让球类型
     * @dev HALF: 半球盘（-0.5, +0.5）
     *      WHOLE: 整球盘（-1.0, +1.0）
     *      QUARTER: 1/4球盘（-0.25, -0.75 等）
     */
    enum HandicapType {
        HALF,      // 半球盘
        WHOLE,     // 整球盘（有退款）
        QUARTER    // 1/4球盘（半输半赢）
    }

    /**
     * @notice 让球方向
     * @dev HOME_GIVE: 主队让球（主队 -X）
     *      AWAY_GIVE: 客队让球（客队 -X，即主队 +X）
     */
    enum HandicapDirection {
        HOME_GIVE,  // 主队让球（主强客弱）
        AWAY_GIVE   // 客队让球（客强主弱）
    }

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 让球市场创建事件
     * @param matchId 比赛ID
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param kickoffTime 开球时间
     * @param handicap 让球数（千分位，如 -0.5 = -500）
     * @param handicapType 让球类型
     * @param direction 让球方向
     * @param pricingEngine 定价引擎地址
     */
    event AHMarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        int256 handicap,
        HandicapType handicapType,
        HandicapDirection direction,
        address pricingEngine
    );

    /**
     * @notice 让球结算事件
     * @param matchId 比赛ID
     * @param homeScore 主队进球数
     * @param awayScore 客队进球数
     * @param adjustedHomeScore 调整后主队得分（加上/减去让球数）
     * @param adjustedAwayScore 调整后客队得分
     * @param winningOutcome 获胜结果（0=主队赢盘，1=客队赢盘，2=退款）
     */
    event AHSettled(
        string indexed matchId,
        uint256 homeScore,
        uint256 awayScore,
        int256 adjustedHomeScore,
        int256 adjustedAwayScore,
        uint256 winningOutcome
    );

    // ============================================================================
    // 只读函数
    // ============================================================================

    /**
     * @notice 获取让球数
     * @return handicap 让球数（千分位，负数表示主队让球）
     */
    function getHandicap() external view returns (int256 handicap);

    /**
     * @notice 获取让球类型
     * @return 让球类型枚举
     */
    function getHandicapType() external view returns (HandicapType);

    /**
     * @notice 获取让球方向
     * @return 让球方向枚举
     */
    function getHandicapDirection() external view returns (HandicapDirection);

    /**
     * @notice 计算调整后的比分
     * @param homeScore 主队实际进球数
     * @param awayScore 客队实际进球数
     * @return adjustedHomeScore 调整后主队得分
     * @return adjustedAwayScore 调整后客队得分
     */
    function calculateAdjustedScore(
        uint256 homeScore,
        uint256 awayScore
    ) external view returns (int256 adjustedHomeScore, int256 adjustedAwayScore);

    /**
     * @notice 根据调整后比分确定获胜结果
     * @param adjustedHomeScore 调整后主队得分
     * @param adjustedAwayScore 调整后客队得分
     * @return outcome 结果ID（0=主队赢盘，1=客队赢盘，2=退款/半输半赢）
     */
    function determineOutcome(
        int256 adjustedHomeScore,
        int256 adjustedAwayScore
    ) external view returns (uint256 outcome);

    // ============================================================================
    // 错误定义
    // ============================================================================

    /// @notice 无效的让球数（必须是 ±0.25, ±0.5, ±0.75, ±1.0 等）
    error InvalidHandicap(int256 handicap);

    /// @notice 无效的让球类型
    error InvalidHandicapType(HandicapType handicapType);

    /// @notice 下注的结果不是主队或客队（不能下注退款）
    error CannotBetOnPush();

    /// @notice 尝试在整数盘/1/4球盘上下注无效结果
    error InvalidOutcomeForHandicapType(uint256 outcome, HandicapType handicapType);
}
