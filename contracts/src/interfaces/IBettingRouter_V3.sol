// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBettingRouter_V3
 * @notice 投注路由接口 V3 - 支持多代币
 * @dev 改进点（相比 V2）：
 *      - 支持多种结算代币（USDC、USDT、DAI、WETH 等）
 *      - 动态读取市场的结算代币
 *      - 代币白名单安全机制
 *      - 批量下注支持跨代币市场
 */
interface IBettingRouter_V3 {
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
        address token;          // 使用的代币
    }

    /// @notice 费用计算结果
    struct FeeResult {
        uint256 grossAmount;    // 原始金额
        uint256 feeAmount;      // 费用金额
        uint256 netAmount;      // 净金额
        uint256 discountBps;    // 折扣（基点）
        address referrer;       // 推荐人
    }

    /// @notice 代币信息
    struct TokenInfo {
        bool supported;         // 是否支持
        uint256 feeRateBps;     // 该代币的费率（基点）
        address feeRecipient;   // 该代币的费用接收地址
        uint256 minBetAmount;   // 最小下注金额
        uint256 maxBetAmount;   // 最大下注金额（0 = 无限制）
    }

    // ============ 事件 ============

    /// @notice 单笔下注事件
    event BetPlaced(
        address indexed user,
        address indexed market,
        address indexed token,
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    /// @notice 批量下注事件
    event BatchBetPlaced(
        address indexed user,
        uint256 betCount,
        uint256 totalFee
    );

    /// @notice 费用路由事件
    event FeeRouted(
        address indexed token,
        uint256 amount,
        address indexed recipient
    );

    /// @notice 代币添加事件
    event TokenAdded(
        address indexed token,
        uint256 feeRateBps,
        address feeRecipient
    );

    /// @notice 代币移除事件
    event TokenRemoved(address indexed token);

    /// @notice 代币配置更新事件
    event TokenConfigUpdated(
        address indexed token,
        uint256 feeRateBps,
        address feeRecipient,
        uint256 minBetAmount,
        uint256 maxBetAmount
    );

    // ============ 错误 ============

    error InvalidMarket(address market);
    error MarketNotOpen(address market);
    error UnsupportedToken(address token);
    error TokenMismatch(address expected, address actual);
    error BetAmountTooLow(uint256 amount, uint256 minimum);
    error BetAmountTooHigh(uint256 amount, uint256 maximum);
    error SlippageExceeded(uint256 expected, uint256 actual);
    error RouterPaused();
    error InvalidParams();
    error ZeroAddress();
    error ZeroAmount();

    // ============ 单笔下注 ============

    /**
     * @notice 单笔下注（自动读取市场代币）
     * @param market 市场地址
     * @param outcomeId 结果 ID
     * @param amount 下注金额（含手续费）
     * @param minShares 最小获得份额（滑点保护）
     * @return shares 获得的份额
     *
     * @dev 流程：
     *      1. 从市场读取 settlementToken
     *      2. 验证代币在白名单中
     *      3. 从用户转账到 Router
     *      4. 计算并路由费用
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
     * @notice 批量下注（支持跨代币市场）
     * @param bets 下注参数数组
     * @return results 下注结果数组
     *
     * @dev 特性：
     *      - 每笔下注独立处理代币
     *      - 原子性操作：任一下注失败将导致整个交易回滚（保证资金安全）
     *      - 验证失败的下注（无效市场、不支持的代币、超出限额）返回空结果而不回滚
     *      - 执行失败的下注（市场 placeBetFor 失败）会回滚整个交易
     *      - 返回每笔下注的结果
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
     */
    function placeBetMultiOutcome(
        address market,
        uint256[] calldata outcomeIds,
        uint256[] calldata amounts,
        uint256[] calldata minSharesList
    ) external returns (uint256[] memory sharesList);

    // ============ 费用查询 ============

    /**
     * @notice 计算单笔下注费用（指定代币）
     * @param token 代币地址
     * @param user 用户地址
     * @param amount 下注金额
     * @return result 费用计算结果
     */
    function calculateFee(address token, address user, uint256 amount)
        external
        view
        returns (FeeResult memory result);

    /**
     * @notice 计算市场下注费用（自动读取代币）
     * @param market 市场地址
     * @param user 用户地址
     * @param amount 下注金额
     * @return result 费用计算结果
     */
    function calculateFeeForMarket(address market, address user, uint256 amount)
        external
        view
        returns (FeeResult memory result);

    // ============ 预览下注 ============

    /**
     * @notice 预览单笔下注结果
     * @param market 市场地址
     * @param outcomeId 结果 ID
     * @param amount 下注金额
     * @return token 使用的代币
     * @return netAmount 净金额
     * @return shares 预计获得份额
     * @return fee 手续费
     */
    function previewBet(address market, uint256 outcomeId, uint256 amount)
        external
        view
        returns (address token, uint256 netAmount, uint256 shares, uint256 fee);

    // ============ 代币管理 ============

    /**
     * @notice 检查代币是否支持
     * @param token 代币地址
     * @return supported 是否支持
     */
    function isTokenSupported(address token) external view returns (bool supported);

    /**
     * @notice 获取代币配置
     * @param token 代币地址
     * @return info 代币信息
     */
    function getTokenInfo(address token) external view returns (TokenInfo memory info);

    /**
     * @notice 获取所有支持的代币
     * @return tokens 代币地址数组
     */
    function getSupportedTokens() external view returns (address[] memory tokens);

    // ============ 市场验证 ============

    /**
     * @notice 验证市场是否有效
     * @param market 市场地址
     * @return valid 是否有效
     * @return token 市场的结算代币
     */
    function validateMarket(address market)
        external
        view
        returns (bool valid, address token);

    /**
     * @notice 获取市场的结算代币
     * @param market 市场地址
     * @return token 结算代币地址
     */
    function getMarketToken(address market) external view returns (address token);

    // ============ 管理函数 ============

    /**
     * @notice 获取工厂地址
     */
    function factory() external view returns (address);

    /**
     * @notice 获取暂停状态
     */
    function paused() external view returns (bool);
}
