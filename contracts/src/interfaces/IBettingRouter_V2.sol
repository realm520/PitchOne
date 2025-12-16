// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IBettingRouter_V2
 * @notice 投注路由接口 V2 - 支持批量下注
 * @dev Router 职责：
 *      - 统一下注入口（用户只需授权 Router）
 *      - 费用计算和路由
 *      - 市场验证
 *      - 批量操作支持
 *
 * 改进点（相比 V1）：
 *      - 支持同时投注多个市场
 *      - 支持同一市场多个 outcome
 *      - 批量下注原子性（全部成功或全部失败）
 */
interface IBettingRouter_V2 {
    // ============ 结构体 ============

    /// @notice 单笔下注参数
    struct BetParams {
        address market;         // 市场地址
        uint256 outcomeId;      // 结果 ID
        uint256 amount;         // 下注金额（含手续费）
        uint256 minShares;      // 最小获得份额（滑点保护）
    }

    /// @notice 下注结果
    struct BetResult {
        address market;         // 市场地址
        uint256 outcomeId;      // 结果 ID
        uint256 amount;         // 实际下注金额（扣除手续费后）
        uint256 shares;         // 获得的份额
        uint256 fee;            // 手续费
    }

    /// @notice 费用计算结果
    struct FeeResult {
        uint256 grossAmount;    // 原始金额
        uint256 feeAmount;      // 费用金额
        uint256 netAmount;      // 净金额
        uint256 discountBps;    // 折扣（基点）
        address referrer;       // 推荐人
    }

    // ============ 事件 ============

    /// @notice 单笔下注事件
    event BetPlaced(
        address indexed user,
        address indexed market,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    /// @notice 批量下注事件
    event BatchBetPlaced(
        address indexed user,
        uint256 betCount,
        uint256 totalAmount,
        uint256 totalFee
    );

    /// @notice 费用路由事件
    event FeeRouted(
        address indexed token,
        uint256 amount,
        address referrer
    );

    // ============ 单笔下注 ============

    /**
     * @notice 单笔下注
     * @param market 市场地址
     * @param outcomeId 结果 ID
     * @param amount 下注金额（含手续费）
     * @param minShares 最小获得份额（滑点保护）
     * @return shares 获得的份额
     *
     * @dev 流程：
     *      1. 验证市场合法性
     *      2. 计算费用
     *      3. 从用户转账到 Router
     *      4. 路由费用到各池
     *      5. 转账净金额到市场
     *      6. 调用市场的 placeBetFor
     */
    function placeBet(
        address market,
        uint256 outcomeId,
        uint256 amount,
        uint256 minShares
    ) external returns (uint256 shares);

    // ============ 批量下注 ============

    /**
     * @notice 批量下注（多个市场/多个 outcome）
     * @param bets 下注参数数组
     * @return results 下注结果数组
     *
     * @dev 特性：
     *      - 原子性：全部成功或全部失败
     *      - 单次授权：用户只需授权总金额
     *      - 费用优化：批量计算，可能有折扣
     */
    function placeBetBatch(BetParams[] calldata bets)
        external
        returns (BetResult[] memory results);

    /**
     * @notice 批量下注到同一市场的多个 outcome
     * @param market 市场地址
     * @param outcomeIds 结果 ID 数组
     * @param amounts 下注金额数组（含手续费）
     * @param minSharesList 最小份额数组
     * @return sharesList 获得的份额数组
     *
     * @dev 场景：用户想同时押主胜和平局
     */
    function placeBetMultiOutcome(
        address market,
        uint256[] calldata outcomeIds,
        uint256[] calldata amounts,
        uint256[] calldata minSharesList
    ) external returns (uint256[] memory sharesList);

    /**
     * @notice 批量下注到多个市场的相同 outcome
     * @param markets 市场地址数组
     * @param outcomeId 结果 ID（对所有市场相同）
     * @param amounts 下注金额数组
     * @param minSharesList 最小份额数组
     * @return sharesList 获得的份额数组
     *
     * @dev 场景：用户想押多场比赛的主胜
     */
    function placeBetMultiMarket(
        address[] calldata markets,
        uint256 outcomeId,
        uint256[] calldata amounts,
        uint256[] calldata minSharesList
    ) external returns (uint256[] memory sharesList);

    // ============ 费用查询 ============

    /**
     * @notice 计算单笔下注费用
     * @param user 用户地址
     * @param amount 下注金额
     * @return result 费用计算结果
     */
    function calculateFee(address user, uint256 amount)
        external
        view
        returns (FeeResult memory result);

    /**
     * @notice 计算批量下注费用
     * @param user 用户地址
     * @param amounts 下注金额数组
     * @return results 费用计算结果数组
     * @return totalGross 总原始金额
     * @return totalFee 总费用
     * @return totalNet 总净金额
     */
    function calculateFeeBatch(address user, uint256[] calldata amounts)
        external
        view
        returns (
            FeeResult[] memory results,
            uint256 totalGross,
            uint256 totalFee,
            uint256 totalNet
        );

    // ============ 预览下注 ============

    /**
     * @notice 预览单笔下注结果
     * @param market 市场地址
     * @param outcomeId 结果 ID
     * @param amount 下注金额
     * @return netAmount 净金额
     * @return shares 预计获得份额
     * @return fee 手续费
     */
    function previewBet(address market, uint256 outcomeId, uint256 amount)
        external
        view
        returns (uint256 netAmount, uint256 shares, uint256 fee);

    /**
     * @notice 预览批量下注结果
     * @param bets 下注参数数组
     * @return totalAmount 总下注金额
     * @return totalShares 预计总份额
     * @return totalFee 总手续费
     */
    function previewBetBatch(BetParams[] calldata bets)
        external
        view
        returns (uint256 totalAmount, uint256 totalShares, uint256 totalFee);

    // ============ 管理函数 ============

    /**
     * @notice 获取工厂地址
     */
    function factory() external view returns (address);

    /**
     * @notice 获取费用适配器地址
     */
    function feeAdapter() external view returns (address);

    /**
     * @notice 获取费用路由器地址
     */
    function feeRouter() external view returns (address);

    /**
     * @notice 验证市场是否有效
     * @param market 市场地址
     * @return valid 是否有效
     */
    function isValidMarket(address market) external view returns (bool valid);
}
