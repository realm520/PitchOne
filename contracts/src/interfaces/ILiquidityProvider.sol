// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILiquidityProvider
 * @notice 流动性提供者接口，用于为预测市场提供流动性
 * @dev 不同的流动性策略（ERC4626 AMM、Parimutuel、Hybrid等）实现此接口
 *
 * 设计原则：
 * - 流动性提供者负责资金管理和风险控制
 * - 市场模板只负责调用接口，不关心内部实现
 * - 符合策略模式（Strategy Pattern）和开闭原则
 * - 与定价引擎（IPricingEngine）协同工作但独立部署
 *
 * 核心流程：
 * 1. 市场创建时从 Provider borrow 初始流动性
 * 2. 用户下注时资金留在市场合约
 * 3. 市场结算后 repay 本金+收益给 Provider
 * 4. Provider 将收益分配给 LP（具体机制由实现决定）
 */
interface ILiquidityProvider {
    // ============ 事件 ============

    /**
     * @notice 流动性被市场借出事件
     * @param market 市场合约地址
     * @param amount 借出金额
     * @param timestamp 时间戳
     */
    event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp);

    /**
     * @notice 流动性归还事件
     * @param market 市场合约地址
     * @param principal 归还本金
     * @param revenue 归还收益（手续费）
     * @param timestamp 时间戳
     */
    event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp);

    /**
     * @notice 市场授权事件
     * @param market 市场合约地址
     * @param authorized 是否授权
     */
    event MarketAuthorizationChanged(address indexed market, bool authorized);

    // ============ 错误定义 ============

    /// @notice 未授权的市场尝试借款或还款
    error UnauthorizedMarket(address market);

    /// @notice 超过最大利用率限制
    error ExceedsUtilizationLimit(uint256 requested, uint256 available);

    /// @notice 超过单市场借款限制
    error ExceedsMarketBorrowLimit(address market, uint256 requested, uint256 limit);

    /// @notice 市场借款余额不足
    error InsufficientBorrowBalance(address market, uint256 balance);

    /// @notice 可用流动性不足
    error InsufficientLiquidity(uint256 requested, uint256 available);

    // ============ 核心借贷接口 ============

    /**
     * @notice 市场借出流动性
     * @param amount 借款金额
     * @dev 只有授权市场可调用
     * @dev 实现需要检查：
     *      - 调用者是否为授权市场
     *      - 是否超过最大利用率
     *      - 是否超过单市场借款限制
     */
    function borrow(uint256 amount) external;

    /**
     * @notice 市场归还流动性（本金+收益）
     * @param principal 本金
     * @param revenue 收益（手续费）
     * @dev 只有授权市场可调用
     * @dev 实现需要：
     *      - 验证调用者为授权市场
     *      - 验证借款余额充足
     *      - 更新借款记录
     *      - 分配收益给 LP（具体机制由实现决定）
     */
    function repay(uint256 principal, uint256 revenue) external;

    // ============ 查询接口 ============

    /**
     * @notice 获取可用流动性
     * @return 未借出的流动性数量
     * @dev 对于 ERC4626 实现：返回合约 USDC 余额
     * @dev 对于 Parimutuel 实现：返回当前彩池总额
     */
    function availableLiquidity() external view returns (uint256);

    /**
     * @notice 获取总流动性
     * @return 总流动性（可用 + 已借出）
     * @dev 对于 ERC4626 实现：返回 totalAssets()
     * @dev 对于 Parimutuel 实现：返回彩池总额（无借出概念）
     */
    function totalLiquidity() external view returns (uint256);

    /**
     * @notice 获取当前利用率
     * @return 利用率（基点，0-10000 表示 0%-100%）
     * @dev 利用率 = (已借出金额 / 总流动性) * 10000
     */
    function utilizationRate() external view returns (uint256);

    /**
     * @notice 获取市场借款信息
     * @param market 市场地址
     * @return borrowed 已借金额
     * @return limit 借款上限
     * @return available 可借金额
     * @dev 用于市场查询自身的借款状态
     */
    function getMarketBorrowInfo(address market)
        external
        view
        returns (uint256 borrowed, uint256 limit, uint256 available);

    /**
     * @notice 检查市场是否已授权
     * @param market 市场地址
     * @return 是否授权
     */
    function isAuthorizedMarket(address market) external view returns (bool);

    /**
     * @notice 获取所有授权市场列表
     * @return 授权市场地址数组
     */
    function getAuthorizedMarkets() external view returns (address[] memory);

    // ============ 管理接口 ============

    /**
     * @notice 授权市场合约
     * @param market 市场合约地址
     * @dev 只有管理员可调用（具体权限由实现定义）
     */
    function authorizeMarket(address market) external;

    /**
     * @notice 取消市场授权
     * @param market 市场合约地址
     * @dev 只有管理员可调用
     * @dev 要求市场已还清所有借款
     */
    function revokeMarket(address market) external;

    // ============ 类型信息 ============

    /**
     * @notice 获取流动性提供者类型
     * @return 类型标识符（如 "ERC4626", "Parimutuel", "Hybrid"）
     * @dev 用于前端显示和合约识别
     */
    function providerType() external view returns (string memory);

    /**
     * @notice 获取底层资产地址（如 USDC）
     * @return 资产地址
     */
    function asset() external view returns (address);
}
