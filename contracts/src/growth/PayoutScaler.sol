// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PayoutScaler
 * @notice 预算缩放策略合约
 * @dev 核心功能：
 *      - 动态计算奖励缩放比例：根据可用预算和待发放金额
 *      - 多预算池管理：Promo、Campaign、Quest 等独立预算
 *      - 预算补充机制：支持充值和自动调度
 *      - 缩放历史记录：审计追溯
 *      - 预算不足告警：事件通知
 *      - 最小缩放保护：防止过度削减（最低10%）
 */
contract PayoutScaler is AccessControl, Pausable {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 操作员角色（Keeper 服务）
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice 暂停者角色
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice 基点分母（100%）
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice 最小缩放比例（10%）
    uint256 public constant MIN_SCALE_BPS = 1000;

    /// @notice 最大缩放比例（100%）
    uint256 public constant MAX_SCALE_BPS = 10000;

    /// @notice 预算告警阈值（20%）
    uint256 public constant BUDGET_WARNING_THRESHOLD_BPS = 2000;

    // ============================================================================
    // 枚举
    // ============================================================================

    /**
     * @notice 预算池类型
     */
    enum BudgetPool {
        PROMO,      // 推广池（推荐返佣、空投）
        CAMPAIGN,   // 活动池
        QUEST,      // 任务池
        INSURANCE   // 保险基金（极端缩放时的备用金）
    }

    // ============================================================================
    // 数据结构
    // ============================================================================

    /**
     * @notice 预算池状态
     * @param totalBudget 总预算
     * @param usedBudget 已使用预算
     * @param pendingPayout 待发放金额
     * @param lastRefillAt 最后充值时间
     */
    struct BudgetStatus {
        uint256 totalBudget;
        uint256 usedBudget;
        uint256 pendingPayout;
        uint256 lastRefillAt;
    }

    /**
     * @notice 缩放记录
     * @param pool 预算池类型
     * @param period 周期（如周编号）
     * @param requestedAmount 请求金额
     * @param availableBudget 可用预算
     * @param scaleBps 缩放比例（基点）
     * @param scaledAmount 缩放后金额
     * @param timestamp 时间戳
     */
    struct ScalingRecord {
        BudgetPool pool;
        uint256 period;
        uint256 requestedAmount;
        uint256 availableBudget;
        uint256 scaleBps;
        uint256 scaledAmount;
        uint256 timestamp;
    }

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 奖励代币（USDC 或其他）
    IERC20 public immutable rewardToken;

    /// @notice 预算池 -> 状态
    mapping(BudgetPool => BudgetStatus) public budgetStatus;

    /// @notice 缩放历史记录
    ScalingRecord[] public scalingHistory;

    /// @notice 预算池 -> 周期 -> 缩放比例
    mapping(BudgetPool => mapping(uint256 => uint256)) public periodScaleBps;

    /// @notice 预算池 -> 是否启用自动缩放
    mapping(BudgetPool => bool) public autoScaleEnabled;

    /// @notice 国库地址（接收预算补充）
    address public treasury;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 预算充值事件
     * @param pool 预算池
     * @param amount 充值金额
     * @param newTotal 新总预算
     */
    event BudgetRefilled(
        BudgetPool indexed pool,
        uint256 amount,
        uint256 newTotal
    );

    /**
     * @notice 缩放比例计算事件
     * @param pool 预算池
     * @param period 周期
     * @param requestedAmount 请求金额
     * @param availableBudget 可用预算
     * @param scaleBps 缩放比例
     * @param scaledAmount 缩放后金额
     * @param recordId 记录 ID
     */
    event ScalingCalculated(
        BudgetPool indexed pool,
        uint256 indexed period,
        uint256 requestedAmount,
        uint256 availableBudget,
        uint256 scaleBps,
        uint256 scaledAmount,
        uint256 recordId
    );

    /**
     * @notice 预算不足告警事件
     * @param pool 预算池
     * @param availableBudget 可用预算
     * @param requestedAmount 请求金额
     * @param utilizationBps 使用率（基点）
     */
    event BudgetWarning(
        BudgetPool indexed pool,
        uint256 availableBudget,
        uint256 requestedAmount,
        uint256 utilizationBps
    );

    /**
     * @notice 预算使用事件
     * @param pool 预算池
     * @param period 周期
     * @param amount 使用金额
     * @param remainingBudget 剩余预算
     */
    event BudgetUsed(
        BudgetPool indexed pool,
        uint256 indexed period,
        uint256 amount,
        uint256 remainingBudget
    );

    /**
     * @notice 自动缩放配置更新事件
     * @param pool 预算池
     * @param enabled 是否启用
     */
    event AutoScaleUpdated(BudgetPool indexed pool, bool enabled);

    /**
     * @notice 国库地址更新事件
     * @param oldTreasury 旧地址
     * @param newTreasury 新地址
     */
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    // ============================================================================
    // 错误
    // ============================================================================

    error InsufficientBudget();
    error InvalidScaleBps();
    error InvalidPool();
    error ZeroAddress();
    error ZeroAmount();
    error BudgetExhausted();

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param _rewardToken 奖励代币地址
     * @param _treasury 国库地址
     */
    constructor(address _rewardToken, address _treasury) {
        if (_rewardToken == address(0) || _treasury == address(0)) revert ZeroAddress();

        rewardToken = IERC20(_rewardToken);
        treasury = _treasury;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        // 默认启用所有池的自动缩放
        autoScaleEnabled[BudgetPool.PROMO] = true;
        autoScaleEnabled[BudgetPool.CAMPAIGN] = true;
        autoScaleEnabled[BudgetPool.QUEST] = true;
        autoScaleEnabled[BudgetPool.INSURANCE] = true;
    }

    // ============================================================================
    // 预算管理函数
    // ============================================================================

    /**
     * @notice 充值预算池
     * @param pool 预算池类型
     * @param amount 充值金额
     * @dev 从 msg.sender 转入代币
     */
    function refillBudget(
        BudgetPool pool,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (uint8(pool) > uint8(BudgetPool.INSURANCE)) revert InvalidPool();

        // 转入代币
        rewardToken.transferFrom(msg.sender, address(this), amount);

        // 更新预算状态
        BudgetStatus storage status = budgetStatus[pool];
        status.totalBudget += amount;
        status.lastRefillAt = block.timestamp;

        emit BudgetRefilled(pool, amount, status.totalBudget);
    }

    /**
     * @notice 设置自动缩放配置
     * @param pool 预算池类型
     * @param enabled 是否启用
     */
    function setAutoScale(
        BudgetPool pool,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (uint8(pool) > uint8(BudgetPool.INSURANCE)) revert InvalidPool();

        autoScaleEnabled[pool] = enabled;
        emit AutoScaleUpdated(pool, enabled);
    }

    /**
     * @notice 更新国库地址
     * @param newTreasury 新国库地址
     */
    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert ZeroAddress();

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    // ============================================================================
    // 缩放计算函数
    // ============================================================================

    /**
     * @notice 计算缩放比例
     * @param pool 预算池类型
     * @param period 周期（如周编号）
     * @param requestedAmount 请求金额
     * @return scaleBps 缩放比例（基点）
     * @return scaledAmount 缩放后金额
     */
    function calculateScale(
        BudgetPool pool,
        uint256 period,
        uint256 requestedAmount
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused returns (uint256 scaleBps, uint256 scaledAmount) {
        if (uint8(pool) > uint8(BudgetPool.INSURANCE)) revert InvalidPool();
        if (requestedAmount == 0) revert ZeroAmount();

        BudgetStatus storage status = budgetStatus[pool];
        uint256 availableBudget = status.totalBudget - status.usedBudget;

        // 如果可用预算为 0，尝试从保险基金获取
        if (availableBudget == 0) {
            if (pool != BudgetPool.INSURANCE) {
                // 尝试从保险基金借用
                BudgetStatus storage insuranceStatus = budgetStatus[BudgetPool.INSURANCE];
                uint256 insuranceAvailable = insuranceStatus.totalBudget - insuranceStatus.usedBudget;

                if (insuranceAvailable > 0) {
                    emit BudgetWarning(pool, 0, requestedAmount, BPS_DENOMINATOR);
                    availableBudget = insuranceAvailable;
                } else {
                    revert BudgetExhausted();
                }
            } else {
                revert BudgetExhausted();
            }
        }

        // 计算缩放比例
        if (availableBudget >= requestedAmount) {
            // 预算充足，100% 发放
            scaleBps = MAX_SCALE_BPS;
            scaledAmount = requestedAmount;
        } else {
            // 预算不足，按比例缩放
            if (!autoScaleEnabled[pool]) {
                revert InsufficientBudget();
            }

            scaleBps = (availableBudget * BPS_DENOMINATOR) / requestedAmount;

            // 应用最小缩放保护
            if (scaleBps < MIN_SCALE_BPS) {
                scaleBps = MIN_SCALE_BPS;
            }

            scaledAmount = (requestedAmount * scaleBps) / BPS_DENOMINATOR;

            // 发出预算告警
            uint256 utilizationBps = (status.usedBudget * BPS_DENOMINATOR) / status.totalBudget;
            if (utilizationBps > BUDGET_WARNING_THRESHOLD_BPS) {
                emit BudgetWarning(pool, availableBudget, requestedAmount, utilizationBps);
            }
        }

        // 记录缩放历史
        uint256 recordId = scalingHistory.length;
        scalingHistory.push(ScalingRecord({
            pool: pool,
            period: period,
            requestedAmount: requestedAmount,
            availableBudget: availableBudget,
            scaleBps: scaleBps,
            scaledAmount: scaledAmount,
            timestamp: block.timestamp
        }));

        // 存储周期缩放比例
        periodScaleBps[pool][period] = scaleBps;

        // 更新待发放金额
        status.pendingPayout += scaledAmount;

        emit ScalingCalculated(
            pool,
            period,
            requestedAmount,
            availableBudget,
            scaleBps,
            scaledAmount,
            recordId
        );
    }

    /**
     * @notice 标记预算已使用
     * @param pool 预算池类型
     * @param period 周期
     * @param amount 使用金额
     * @dev 由 RewardsDistributor 在实际发放后调用
     */
    function markBudgetUsed(
        BudgetPool pool,
        uint256 period,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
        if (uint8(pool) > uint8(BudgetPool.INSURANCE)) revert InvalidPool();
        if (amount == 0) revert ZeroAmount();

        BudgetStatus storage status = budgetStatus[pool];

        // 检查待发放金额
        if (status.pendingPayout < amount) {
            revert InsufficientBudget();
        }

        // 更新状态
        status.usedBudget += amount;
        status.pendingPayout -= amount;

        uint256 remainingBudget = status.totalBudget - status.usedBudget;

        emit BudgetUsed(pool, period, amount, remainingBudget);
    }

    // ============================================================================
    // 查询函数
    // ============================================================================

    /**
     * @notice 获取预算池状态
     * @param pool 预算池类型
     * @return total 总预算
     * @return used 已使用预算
     * @return pending 待发放金额
     * @return available 可用预算
     */
    function getBudgetStatus(
        BudgetPool pool
    ) external view returns (
        uint256 total,
        uint256 used,
        uint256 pending,
        uint256 available
    ) {
        BudgetStatus storage status = budgetStatus[pool];
        total = status.totalBudget;
        used = status.usedBudget;
        pending = status.pendingPayout;
        available = total - used;
    }

    /**
     * @notice 获取周期缩放比例
     * @param pool 预算池类型
     * @param period 周期
     * @return scaleBps 缩放比例（基点）
     */
    function getPeriodScale(
        BudgetPool pool,
        uint256 period
    ) external view returns (uint256 scaleBps) {
        return periodScaleBps[pool][period];
    }

    /**
     * @notice 获取缩放历史记录数量
     * @return count 记录数量
     */
    function getScalingHistoryCount() external view returns (uint256 count) {
        return scalingHistory.length;
    }

    /**
     * @notice 预览缩放比例（不写入状态）
     * @param pool 预算池类型
     * @param requestedAmount 请求金额
     * @return scaleBps 缩放比例（基点）
     * @return scaledAmount 缩放后金额
     */
    function previewScale(
        BudgetPool pool,
        uint256 requestedAmount
    ) external view returns (uint256 scaleBps, uint256 scaledAmount) {
        if (uint8(pool) > uint8(BudgetPool.INSURANCE)) return (0, 0);
        if (requestedAmount == 0) return (0, 0);

        BudgetStatus storage status = budgetStatus[pool];
        uint256 availableBudget = status.totalBudget - status.usedBudget;

        if (availableBudget >= requestedAmount) {
            scaleBps = MAX_SCALE_BPS;
            scaledAmount = requestedAmount;
        } else {
            if (!autoScaleEnabled[pool]) {
                return (0, 0);
            }

            scaleBps = (availableBudget * BPS_DENOMINATOR) / requestedAmount;

            if (scaleBps < MIN_SCALE_BPS) {
                scaleBps = MIN_SCALE_BPS;
            }

            scaledAmount = (requestedAmount * scaleBps) / BPS_DENOMINATOR;
        }
    }

    // ============================================================================
    // 暂停功能
    // ============================================================================

    /**
     * @notice 暂停合约
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice 恢复合约
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============================================================================
    // 紧急提款
    // ============================================================================

    /**
     * @notice 紧急提款（仅管理员）
     * @param to 接收地址
     * @param amount 金额
     */
    function emergencyWithdraw(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        rewardToken.transfer(to, amount);
    }
}
