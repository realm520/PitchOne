// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ILiquidityProvider.sol";

/**
 * @title ParimutuelLiquidityProvider
 * @notice 彩池模式流动性提供者，为预测市场提供 Parimutuel 风格的流动性
 * @dev 实现 ILiquidityProvider 接口
 *
 * 核心特性：
 *      - 彩池模型：所有贡献者的资金进入统一奖池
 *      - 赢家分配：赛事结算后，败者投注分配给胜者
 *      - 动态赔率：基于投注分布实时计算
 *      - 收益分配：手续费收益分配给彩池贡献者
 *
 * 与 ERC4626 的区别：
 *      - 无 Vault Shares：贡献者获得的是按比例分配的收益权
 *      - 借贷语义：市场"借款"实际上是从彩池提取初始流动性
 *      - 收益模型：收益来自手续费，而非 AMM 价差
 *
 * @author PitchOne Team
 */
contract ParimutuelLiquidityProvider is ILiquidityProvider, Ownable {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @notice 底层资产（USDC）
    IERC20 public immutable assetToken;

    /// @notice 授权的市场映射
    mapping(address => bool) public authorizedMarkets;

    /// @notice 各市场的借款记录
    mapping(address => uint256) public borrowed;

    /// @notice 总借出金额
    uint256 public totalBorrowed;

    /// @notice 市场列表
    address[] public markets;

    /// @notice 彩池贡献者的贡献金额映射
    mapping(address => uint256) public poolContributions;

    /// @notice 彩池总贡献金额
    uint256 public totalPoolContributions;

    /// @notice 累计收益（手续费）
    uint256 public totalRevenueAccumulated;

    /// @notice 上次收益分配时间
    uint256 public lastRevenueDistribution;

    // ============ 事件 ============

    /// @notice 彩池贡献事件
    event PoolContribution(address indexed contributor, uint256 amount, uint256 timestamp);

    /// @notice 收益分配事件
    event RevenueDistributed(uint256 amount, uint256 timestamp);

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _asset 底层资产地址（USDC）
     */
    constructor(IERC20 _asset) Ownable(msg.sender) {
        assetToken = _asset;
        lastRevenueDistribution = block.timestamp;
    }

    // ============ ILiquidityProvider 接口实现 ============

    /**
     * @inheritdoc ILiquidityProvider
     */
    function borrow(uint256 amount) external override {
        if (!authorizedMarkets[msg.sender]) {
            revert UnauthorizedMarket(msg.sender);
        }

        uint256 available = _availableAssets();
        if (amount > available) {
            revert InsufficientLiquidity(amount, available);
        }

        // 更新借款记录
        borrowed[msg.sender] += amount;
        totalBorrowed += amount;

        // 转账给市场
        assetToken.safeTransfer(msg.sender, amount);

        emit LiquidityBorrowed(msg.sender, amount, block.timestamp);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function repay(uint256 principal, uint256 revenue) external override {
        if (!authorizedMarkets[msg.sender]) {
            revert UnauthorizedMarket(msg.sender);
        }

        if (borrowed[msg.sender] < principal) {
            revert InsufficientBorrowBalance(msg.sender, borrowed[msg.sender]);
        }

        // 更新借款记录
        borrowed[msg.sender] -= principal;
        totalBorrowed -= principal;

        // 累计收益
        totalRevenueAccumulated += revenue;

        // 收取本金+收益
        uint256 totalRepayment = principal + revenue;
        assetToken.safeTransferFrom(msg.sender, address(this), totalRepayment);

        emit LiquidityRepaid(msg.sender, principal, revenue, block.timestamp);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function availableLiquidity() external view override returns (uint256) {
        return _availableAssets();
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function totalLiquidity() external view override returns (uint256) {
        return assetToken.balanceOf(address(this)) + totalBorrowed;
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function utilizationRate() external view override returns (uint256) {
        uint256 total = assetToken.balanceOf(address(this)) + totalBorrowed;
        if (total == 0) return 0;
        return (totalBorrowed * 10000) / total;
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function getMarketBorrowInfo(address market)
        external
        view
        override
        returns (uint256, uint256, uint256)
    {
        uint256 marketBorrowed = borrowed[market];
        uint256 total = assetToken.balanceOf(address(this)) + totalBorrowed;
        uint256 limit = total; // Parimutuel 模式下限制为总池额
        uint256 available = _availableAssets();

        return (marketBorrowed, limit, available);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function isAuthorizedMarket(address market) external view override returns (bool) {
        return authorizedMarkets[market];
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function getAuthorizedMarkets() external view override returns (address[] memory) {
        return markets;
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function authorizeMarket(address market) external override onlyOwner {
        require(market != address(0), "Invalid market address");
        require(!authorizedMarkets[market], "Market already authorized");

        authorizedMarkets[market] = true;
        markets.push(market);

        emit MarketAuthorizationChanged(market, true);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function revokeMarket(address market) external override onlyOwner {
        require(authorizedMarkets[market], "Market not authorized");
        require(borrowed[market] == 0, "Market has outstanding debt");

        authorizedMarkets[market] = false;

        // 从列表中移除
        for (uint256 i = 0; i < markets.length; i++) {
            if (markets[i] == market) {
                markets[i] = markets[markets.length - 1];
                markets.pop();
                break;
            }
        }

        emit MarketAuthorizationChanged(market, false);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function providerType() external pure override returns (string memory) {
        return "Parimutuel";
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function asset() external view override returns (address) {
        return address(assetToken);
    }

    // ============ 彩池管理函数 ============

    /**
     * @notice 贡献资金到彩池
     * @param amount 贡献金额
     * @dev 任何人都可以贡献，按比例获得收益分配权
     */
    function contributeToPool(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // 更新贡献记录
        poolContributions[msg.sender] += amount;
        totalPoolContributions += amount;

        // 转账资产
        assetToken.safeTransferFrom(msg.sender, address(this), amount);

        emit PoolContribution(msg.sender, amount, block.timestamp);
    }

    /**
     * @notice 分配累计收益给彩池贡献者
     * @dev 只有 owner 可调用
     * @dev 收益按贡献比例分配（简化实现：不实际转账，仅记录分配事件）
     */
    function distributeRevenue() external onlyOwner {
        require(totalRevenueAccumulated > 0, "No revenue to distribute");

        uint256 amount = totalRevenueAccumulated;
        totalRevenueAccumulated = 0;
        lastRevenueDistribution = block.timestamp;

        // 注意：完整实现需要记录每个贡献者的收益份额
        // 这里简化为仅发出事件，实际分配逻辑可在链下计算或使用 Merkle 树

        emit RevenueDistributed(amount, block.timestamp);
    }

    // ============ 内部函数 ============

    /**
     * @notice 计算可用资产
     * @return 合约当前 USDC 余额（未借出部分）
     */
    function _availableAssets() internal view returns (uint256) {
        return assetToken.balanceOf(address(this));
    }
}
