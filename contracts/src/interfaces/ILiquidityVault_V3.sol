// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILiquidityVault_V3
 * @notice V3 架构的流动性金库接口
 * @dev 设计原则：
 *      - 与 Market_V3 解耦，通过接口交互
 *      - 支持多种借款模式（固定/动态）
 *      - LP 收益自动复利（ERC-4626）
 *
 * 资金流：
 *      LP存款 → Vault → Market借款 → 用户下注 → 结算 → 归还Vault
 *                         ↓
 *                    LP盈利（用户输）或 LP亏损（用户赢）
 */
interface ILiquidityVault_V3 {
    // ============ 结构体 ============

    /// @notice 市场借款信息
    struct BorrowInfo {
        uint256 principal;          // 借款本金
        uint256 borrowedAt;         // 借款时间
        uint256 maxLiabilityBps;    // 最大亏损比例（基点）
        bool active;                // 是否活跃
    }

    // ============ 事件 ============

    /// @notice 市场授权
    event MarketAuthorized(address indexed market, uint256 maxLiabilityBps);

    /// @notice 市场撤销授权
    event MarketRevoked(address indexed market);

    /// @notice 流动性借出
    event LiquidityBorrowed(address indexed market, uint256 amount, uint256 totalBorrowed);

    /// @notice 流动性结算
    event LiquiditySettled(
        address indexed market,
        uint256 principal,
        int256 pnl,
        uint256 totalBorrowed
    );

    /// @notice 利润分配
    event ProfitDistributed(uint256 profit, uint256 toReserve, uint256 toLPs);

    /// @notice 储备金更新
    event ReserveFundUpdated(uint256 newBalance, bool isDeposit);

    // ============ 错误 ============

    error UnauthorizedMarket();
    error MarketAlreadyAuthorized();
    error MarketHasOutstandingDebt();
    error ExceedsUtilizationLimit(uint256 requested, uint256 available);
    error ExceedsLiabilityLimit(uint256 loss, uint256 maxLiability);
    error InsufficientBorrowBalance();
    error InvalidAmount();

    // ============ 管理函数 ============

    /**
     * @notice 授权市场借款
     * @param market 市场地址
     * @param maxLiabilityBps 最大亏损比例（基点，相对于借款金额）
     */
    function authorizeMarket(address market, uint256 maxLiabilityBps) external;

    /**
     * @notice 撤销市场授权
     * @param market 市场地址
     */
    function revokeMarket(address market) external;

    // ============ 市场借贷接口 ============

    /**
     * @notice 市场借出初始流动性
     * @param amount 借款金额
     * @dev 仅授权市场可调用，在 Market.initialize() 时调用
     */
    function borrow(uint256 amount) external;

    /**
     * @notice 市场归还流动性 + 结算盈亏
     * @param principal 本金
     * @param pnl 盈亏（正数=LP赚钱，负数=LP亏损）
     * @dev 仅授权市场可调用，在 Market.finalize() 时调用
     *
     * PnL 计算：
     *   pnl = 收到的下注金额 - 支付的赔付金额
     *   正数 = 用户整体输钱，LP 赚
     *   负数 = 用户整体赢钱，LP 亏
     */
    function settle(uint256 principal, int256 pnl) external;

    /**
     * @notice 市场取消时归还本金
     * @param principal 本金
     * @dev 仅授权市场可调用，在 Market.cancel() 时调用
     */
    function returnPrincipal(uint256 principal) external;

    // ============ 查询函数 ============

    /**
     * @notice 获取市场借款信息
     * @param market 市场地址
     * @return info 借款信息
     */
    function getBorrowInfo(address market) external view returns (BorrowInfo memory info);

    /**
     * @notice 获取可借出流动性
     * @return 可用金额
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @notice 获取总借出金额
     * @return 总借出金额
     */
    function totalBorrowed() external view returns (uint256);

    /**
     * @notice 获取利用率
     * @return 利用率（基点，0-10000）
     */
    function utilizationRate() external view returns (uint256);

    /**
     * @notice 获取储备金余额
     * @return 储备金金额
     */
    function reserveFund() external view returns (uint256);

    /**
     * @notice 获取授权市场列表
     * @return 市场地址数组
     */
    function getAuthorizedMarkets() external view returns (address[] memory);

    /**
     * @notice 获取 Vault 统计信息
     * @return _totalAssets 总资产
     * @return _totalBorrowed 总借出
     * @return _availableLiquidity 可用流动性
     * @return _reserveFund 储备金
     * @return _totalProfit 累计利润
     * @return _totalLoss 累计亏损
     */
    function getVaultStats()
        external
        view
        returns (
            uint256 _totalAssets,
            uint256 _totalBorrowed,
            uint256 _availableLiquidity,
            uint256 _reserveFund,
            uint256 _totalProfit,
            uint256 _totalLoss
        );
}
