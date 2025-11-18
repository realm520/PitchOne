// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILiquidityProvider.sol";

/**
 * @title ERC4626LiquidityProvider
 * @notice ERC-4626 标准流动性提供者，为预测市场提供流动性
 * @dev 实现 ILiquidityProvider 接口
 *
 * 核心功能：
 *      - LP 存入 USDC，获得 Vault Shares（ERC-20 代币）
 *      - LP 可随时提取本金+收益
 *      - 市场合约可借出流动性
 *      - 市场结算后归还本金+手续费收益
 *      - 收益自动分配给所有 LP（shares 价值上涨）
 *
 * 安全特性：
 *      - 只有授权市场可借款
 *      - 紧急暂停机制
 *      - 利用率限制（防止过度借贷）
 *      - 借款上限（每个市场）
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
contract ERC4626LiquidityProvider is ILiquidityProvider, ERC4626, Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice 最大利用率（90%，保留10%用于提款）
    uint256 public constant MAX_UTILIZATION_BPS = 9000; // 90%

    /// @notice 单个市场最大借款比例（50%）
    uint256 public constant MAX_MARKET_BORROW_BPS = 5000; // 50%

    // ============ 状态变量 ============

    /// @notice 授权的市场合约列表
    mapping(address => bool) public authorizedMarkets;

    /// @notice 各市场的借款记录
    mapping(address => uint256) public borrowed;

    /// @notice 总借出金额
    uint256 public totalBorrowed;

    /// @notice 累计收益（手续费）
    uint256 public totalRevenueAccumulated;

    /// @notice 市场列表（用于遍历）
    address[] public markets;

    // ============ 事件 ============
    // 注意：ILiquidityProvider 接口中已定义的事件无需重复声明

    /// @notice 收益分配事件（额外事件，非接口要求）
    event RevenueDistributed(uint256 amount, uint256 totalAssets, uint256 totalShares);

    /// @notice 紧急提款事件（额外事件，非接口要求）
    event EmergencyWithdrawal(address indexed admin, address indexed recipient, uint256 amount);

    // ============ 错误定义 ============
    // 注意：ILiquidityProvider 接口中已定义的错误无需重复声明

    error NoRevenueToDistribute();

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _asset 底层资产地址（USDC）
     * @param _name Vault Shares 代币名称（如 "PitchOne LP Token"）
     * @param _symbol Vault Shares 代币符号（如 "pLP"）
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {}

    // ============ ILiquidityProvider 接口实现 ============

    /**
     * @inheritdoc ILiquidityProvider
     */
    function borrow(uint256 amount) external override whenNotPaused {
        if (!authorizedMarkets[msg.sender]) {
            revert UnauthorizedMarket(msg.sender);
        }

        uint256 available = _availableAssets();
        uint256 wouldBeUtilization = ((totalBorrowed + amount) * 10000) / totalAssets();

        // 检查利用率限制
        if (wouldBeUtilization > MAX_UTILIZATION_BPS) {
            revert ExceedsUtilizationLimit(amount, available);
        }

        // 检查单市场借款限制
        uint256 marketLimit = (totalAssets() * MAX_MARKET_BORROW_BPS) / 10000;
        if (borrowed[msg.sender] + amount > marketLimit) {
            revert ExceedsMarketBorrowLimit(msg.sender, amount, marketLimit);
        }

        // 更新借款记录
        borrowed[msg.sender] += amount;
        totalBorrowed += amount;

        // 转账给市场
        IERC20(asset()).safeTransfer(msg.sender, amount);

        emit LiquidityBorrowed(msg.sender, amount, block.timestamp);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function repay(uint256 principal, uint256 revenue) external override whenNotPaused {
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
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), totalRepayment);

        emit LiquidityRepaid(msg.sender, principal, revenue, block.timestamp);

        // 如果有收益，触发收益分配事件
        if (revenue > 0) {
            emit RevenueDistributed(revenue, totalAssets(), totalSupply());
        }
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
        return totalAssets();
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function utilizationRate() external view override returns (uint256) {
        uint256 total = totalAssets();
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
        uint256 limit = (totalAssets() * MAX_MARKET_BORROW_BPS) / 10000;
        uint256 available = limit > marketBorrowed ? limit - marketBorrowed : 0;

        // 还需要检查总体利用率
        uint256 totalAvailable = _availableAssets();
        if (available > totalAvailable) {
            available = totalAvailable;
        }

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

        // 从列表中移除（简单实现，不保持顺序）
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
        return "ERC4626";
    }

    /**
     * @notice 获取底层资产地址
     * @return 资产地址（继承自 ERC4626）
     * @dev 此方法已由 ERC4626 实现，这里仅为显式声明
     */
    function asset() public view override(ERC4626, ILiquidityProvider) returns (address) {
        return super.asset();
    }

    // ============ 管理函数 ============

    /**
     * @notice 暂停存取款和借贷
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice 恢复存取款和借贷
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice 紧急提款（仅用于极端情况）
     * @param recipient 接收地址
     * @param amount 提款金额
     */
    function emergencyWithdraw(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient");
        require(amount <= _availableAssets(), "Insufficient available assets");

        IERC20(asset()).safeTransfer(recipient, amount);

        emit EmergencyWithdrawal(msg.sender, recipient, amount);
    }

    // ============ ERC-4626 覆盖函数 ============

    /**
     * @notice 计算 Vault 总资产
     * @return 可用资产 + 已借出资产
     * @dev 覆盖 ERC4626.totalAssets()
     */
    function totalAssets() public view virtual override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + totalBorrowed;
    }

    /**
     * @notice 存款
     * @dev 暂停时不允许存款
     */
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    /**
     * @notice 铸造 shares
     * @dev 暂停时不允许铸造
     */
    function mint(uint256 shares, address receiver)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        return super.mint(shares, receiver);
    }

    /**
     * @notice 提款
     * @dev 暂停时不允许提款，需要足够的可用流动性
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        require(assets <= _availableAssets(), "Insufficient liquidity");
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @notice 赎回 shares
     * @dev 暂停时不允许赎回，需要足够的可用流动性
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 assets = previewRedeem(shares);
        require(assets <= _availableAssets(), "Insufficient liquidity");
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @notice 最大提款金额
     * @dev 限制为当前可用流动性
     */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        uint256 ownerAssets = super.maxWithdraw(owner);
        uint256 available = _availableAssets();
        return ownerAssets < available ? ownerAssets : available;
    }

    /**
     * @notice 最大赎回 shares
     * @dev 限制为当前可用流动性对应的 shares
     */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        uint256 ownerShares = super.maxRedeem(owner);
        uint256 available = _availableAssets();
        uint256 availableShares = convertToShares(available);
        return ownerShares < availableShares ? ownerShares : availableShares;
    }

    // ============ 额外查询函数 ============

    /**
     * @notice 获取 LP 当前收益
     * @param lp LP 地址
     * @return 当前价值 - 存入成本
     * @dev 注意：这里简化处理，实际应追踪每个 LP 的存入成本
     */
    function getCurrentYield(address lp) external view returns (uint256) {
        uint256 shares = balanceOf(lp);
        if (shares == 0) return 0;

        uint256 currentValue = convertToAssets(shares);
        // 完整实现需要记录每次存款的成本基础
        return currentValue; // 返回当前总价值
    }

    // ============ 内部函数 ============

    /**
     * @notice 计算可用资产
     * @return 合约当前 USDC 余额（未借出部分）
     */
    function _availableAssets() internal view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}
