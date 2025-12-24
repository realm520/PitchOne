// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPricingStrategy.sol";
import "./IResultMapper.sol";

/**
 * @title IMarket_V3
 * @notice Market 核心接口 V3 - 轻量级市场容器
 * @dev 市场职责：
 *      - 状态机管理（Created → Open → Locked → Resolved → Finalized）
 *      - 组件编排（Strategy + Mapper + Vault）
 *      - 头寸管理（ERC1155）
 *      - 资金流转
 *
 * 改进点（相比 V2）：
 *      - 清晰的职责分离
 *      - 统一的赎回逻辑（委托给 Strategy）
 *      - 支持半输半赢（通过 weights）
 *      - 代码量从 960 行降到 ~300 行
 */
interface IMarket_V3 {
    // ============ 枚举 ============

    /// @notice 市场状态
    enum MarketStatus {
        Created,    // 已创建，尚未开放
        Open,       // 开放下注
        Locked,     // 锁盘，禁止下注
        Resolved,   // 已结算，等待争议期
        Finalized,  // 已终结，可赎回
        Cancelled   // 已取消，可退款
    }

    // ============ 结构体 ============

    /// @notice Outcome 规则
    struct OutcomeRule {
        string name;                         // "主队胜", "平局", "大球"
        IPricingStrategy.PayoutType payoutType; // WINNER / REFUND
    }

    /// @notice 市场配置
    struct MarketConfig {
        bytes32 marketId;                   // 市场唯一标识
        string matchId;                     // 比赛 ID（如 "EPL_2024_MUN_vs_MCI"）
        uint256 kickoffTime;                // 开球时间（用于自动锁盘）
        address settlementToken;            // 结算币种（如 USDC）
        IPricingStrategy pricingStrategy;   // 定价策略
        IResultMapper resultMapper;         // 赛果映射器
        address vault;                      // 流动性金库（Parimutuel 为 address(0)）
        uint256 initialLiquidity;           // 初始流动性
        OutcomeRule[] outcomeRules;         // 各 outcome 的规则
        string uri;                         // ERC1155 元数据 URI
        address admin;                      // 管理员地址
        address paramController;            // 参数控制器地址（可选）
    }

    /// @notice 结算结果
    struct SettlementResult {
        uint256[] outcomeIds;               // 触发的 outcome IDs
        uint256[] weights;                  // 各 outcome 的权重（基点）
        bytes rawResult;                    // 原始赛果数据
        uint256 settledAt;                  // 结算时间戳
        bool resolved;                      // 是否已结算
    }

    /// @notice 市场统计
    struct MarketStats {
        uint256 totalLiquidity;             // 总流动性（借款 + 用户下注）
        uint256 borrowedAmount;             // 从 Vault 借出的金额
        uint256 totalBetAmount;             // 用户总下注金额
        uint256[] totalSharesPerOutcome;    // 各 outcome 的总份额
        uint256[] totalBetPerOutcome;       // 各 outcome 的总下注金额
    }

    // ============ 事件 ============

    /// @notice 市场创建
    event MarketCreated(
        bytes32 indexed marketId,
        string matchId,
        uint256 kickoffTime,
        address pricingStrategy,
        address resultMapper
    );

    /// @notice 市场开放
    event MarketOpened(bytes32 indexed marketId, uint256 timestamp);

    /// @notice 下注事件
    event BetPlaced(
        bytes32 indexed marketId,
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares
    );

    /// @notice 市场锁盘
    event MarketLocked(bytes32 indexed marketId, uint256 timestamp);

    /// @notice 市场结算
    event MarketResolved(
        bytes32 indexed marketId,
        uint256[] outcomeIds,
        uint256[] weights,
        bytes rawResult
    );

    /// @notice 市场终结
    event MarketFinalized(bytes32 indexed marketId, uint256 timestamp);

    /// @notice 市场取消
    event MarketCancelled(bytes32 indexed marketId, string reason);

    /// @notice 赎回事件
    event PayoutClaimed(
        bytes32 indexed marketId,
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 payout
    );

    /// @notice 退款事件
    event RefundClaimed(
        bytes32 indexed marketId,
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 refundAmount
    );

    // ============ 初始化 ============

    /**
     * @notice 初始化市场
     * @param config 市场配置
     */
    function initialize(MarketConfig calldata config) external;

    // ============ 下注（仅 Router 可调用）============

    /**
     * @notice 代理下注（由 Router 调用）
     * @param user 下注用户
     * @param outcomeId 下注的结果 ID
     * @param amount 下注金额（净金额，已扣除手续费）
     * @param minShares 最小获得份额（滑点保护）
     * @return shares 获得的份额
     */
    function placeBetFor(
        address user,
        uint256 outcomeId,
        uint256 amount,
        uint256 minShares
    ) external returns (uint256 shares);

    // ============ 生命周期管理 ============

    /**
     * @notice 锁定市场（禁止新下注）
     * @dev 仅 KEEPER_ROLE 可调用，或开球时间到达后任何人可调用
     */
    function lock() external;

    /**
     * @notice 结算市场
     * @param rawResult 原始赛果数据
     * @dev 仅 ORACLE_ROLE 可调用
     */
    function resolve(bytes calldata rawResult) external;

    /**
     * @notice 检查是否会超出亏损限额
     * @return exceedsLimit 是否超限
     * @return excessLoss 超出的亏损金额
     */
    function checkLiabilityLimit() external view returns (bool exceedsLimit, uint256 excessLoss);

    /**
     * @notice 终结市场（争议期结束后）
     * @param scaleBps 赔付缩放比例（基点）
     *        - 0: 正常结算，超限时 revert
     *        - 1-10000: 按比例缩减赔付 + 储备金兜底
     * @dev 仅 KEEPER_ROLE 可调用
     */
    function finalize(uint256 scaleBps) external;

    /**
     * @notice 取消市场（全额退款）
     * @param reason 取消原因
     * @dev 仅 OPERATOR_ROLE 可调用，仅限 Open/Locked 状态
     */
    function cancel(string calldata reason) external;

    /**
     * @notice 取消已结算的市场并退款
     * @param reason 取消原因
     * @dev 仅 OPERATOR_ROLE 可调用，仅限 Resolved 状态
     */
    function cancelResolved(string calldata reason) external;

    // ============ 赎回（仅通过 Router）============

    /**
     * @notice 代理赎回（供 Router 调用）
     * @param user 用户地址
     * @param outcomeId 结果 ID
     * @param shares 份额数量
     * @return payout 获得金额
     * @dev 需要用户授权 Router（通过 setApprovalForAll）
     */
    function redeemFor(address user, uint256 outcomeId, uint256 shares) external returns (uint256 payout);

    /**
     * @notice 代理批量赎回（供 Router 调用）
     * @param user 用户地址
     * @param outcomeIds 结果 ID 数组
     * @param sharesArray 份额数组
     * @return totalPayout 总获得金额
     */
    function redeemBatchFor(address user, uint256[] calldata outcomeIds, uint256[] calldata sharesArray)
        external returns (uint256 totalPayout);

    /**
     * @notice 代理退款（供 Router 调用）
     * @param user 用户地址
     * @param outcomeId 结果 ID
     * @param shares 份额数量
     * @return amount 退款金额
     */
    function refundFor(address user, uint256 outcomeId, uint256 shares) external returns (uint256 amount);

    // ============ 查询函数 ============

    /**
     * @notice 获取市场 ID
     */
    function marketId() external view returns (bytes32);

    /**
     * @notice 获取市场状态
     */
    function status() external view returns (MarketStatus);

    /**
     * @notice 获取 outcome 价格
     * @param outcomeId 结果 ID
     * @return price 价格（基点，0-10000）
     */
    function getPrice(uint256 outcomeId) external view returns (uint256 price);

    /**
     * @notice 获取所有价格
     * @return prices 价格数组
     */
    function getAllPrices() external view returns (uint256[] memory prices);

    /**
     * @notice 获取 outcome 规则
     * @return rules outcome 规则数组
     */
    function getOutcomeRules() external view returns (OutcomeRule[] memory rules);

    /**
     * @notice 获取市场统计
     * @return stats 市场统计数据
     */
    function getStats() external view returns (MarketStats memory stats);

    /**
     * @notice 获取结算结果
     * @return result 结算结果（仅 Resolved/Finalized 状态有效）
     */
    function getSettlementResult() external view returns (SettlementResult memory result);

    /**
     * @notice 获取定价策略
     */
    function pricingStrategy() external view returns (IPricingStrategy);

    /**
     * @notice 获取赛果映射器
     */
    function resultMapper() external view returns (IResultMapper);

    /**
     * @notice 获取开球时间
     */
    function kickoffTime() external view returns (uint256);

    /**
     * @notice 获取结算代币
     */
    function settlementToken() external view returns (IERC20);

    /**
     * @notice 预览下注结果
     * @param outcomeId 结果 ID
     * @param amount 下注金额
     * @return shares 预计获得的份额
     * @return newPrice 下注后的新价格
     */
    function previewBet(uint256 outcomeId, uint256 amount)
        external
        view
        returns (uint256 shares, uint256 newPrice);

    // ============ 暂停管理 ============

    /**
     * @notice 暂停市场（紧急情况下使用）
     * @dev 仅 PAUSER_ROLE 可调用
     */
    function pause() external;

    /**
     * @notice 恢复市场
     * @dev 仅 PAUSER_ROLE 可调用
     */
    function unpause() external;
}
