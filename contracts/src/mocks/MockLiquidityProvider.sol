// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILiquidityProvider.sol";

/**
 * @title MockLiquidityProvider
 * @notice Mock 实现的流动性提供者，用于测试
 * @dev 简化的实现，不包含 ERC-4626 功能
 *
 * 特性：
 *      - 无限流动性（测试模式）
 *      - 简化的授权机制
 *      - 用于单元测试和集成测试
 *
 * @author PitchOne Team
 */
contract MockLiquidityProvider is ILiquidityProvider {
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

    /// @notice 无限流动性模式（默认 true）
    bool public unlimitedLiquidity;

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _asset 底层资产地址（USDC）
     */
    constructor(IERC20 _asset) {
        assetToken = _asset;
        unlimitedLiquidity = true; // 默认无限流动性
    }

    // ============ ILiquidityProvider 接口实现 ============

    /**
     * @inheritdoc ILiquidityProvider
     */
    function borrow(uint256 amount) external override {
        if (!authorizedMarkets[msg.sender]) {
            revert UnauthorizedMarket(msg.sender);
        }

        // 更新借款记录
        borrowed[msg.sender] += amount;
        totalBorrowed += amount;

        // 转账给市场（如果启用无限流动性，直接铸造）
        if (unlimitedLiquidity) {
            // 在测试环境中，直接从合约余额转账
            // 假设合约有足够余额（或使用 MockERC20 铸造）
            assetToken.safeTransfer(msg.sender, amount);
        } else {
            // 检查余额
            uint256 available = assetToken.balanceOf(address(this));
            if (available < amount) {
                revert InsufficientLiquidity(amount, available);
            }
            assetToken.safeTransfer(msg.sender, amount);
        }

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

        // 收取本金+收益
        uint256 totalRepayment = principal + revenue;
        assetToken.safeTransferFrom(msg.sender, address(this), totalRepayment);

        emit LiquidityRepaid(msg.sender, principal, revenue, block.timestamp);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function availableLiquidity() external view override returns (uint256) {
        if (unlimitedLiquidity) {
            return type(uint256).max; // 无限流动性
        }
        return assetToken.balanceOf(address(this));
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function totalLiquidity() external view override returns (uint256) {
        if (unlimitedLiquidity) {
            return type(uint256).max; // 无限流动性
        }
        return assetToken.balanceOf(address(this)) + totalBorrowed;
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function utilizationRate() external view override returns (uint256) {
        if (unlimitedLiquidity) {
            return 0; // 无限流动性时利用率为 0
        }
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
        uint256 limit = type(uint256).max; // Mock: 无限制
        uint256 available = type(uint256).max; // Mock: 无限可用

        if (!unlimitedLiquidity) {
            uint256 balance = assetToken.balanceOf(address(this));
            available = balance;
            limit = balance + marketBorrowed;
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
    function authorizeMarket(address market) external override {
        require(market != address(0), "Invalid market address");
        require(!authorizedMarkets[market], "Market already authorized");

        authorizedMarkets[market] = true;
        markets.push(market);

        emit MarketAuthorizationChanged(market, true);
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function revokeMarket(address market) external override {
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
        return "Mock";
    }

    /**
     * @inheritdoc ILiquidityProvider
     */
    function asset() external view override returns (address) {
        return address(assetToken);
    }

    // ============ Mock 特定函数 ============

    /**
     * @notice 设置无限流动性模式
     * @param _unlimited 是否启用无限流动性
     */
    function setUnlimitedLiquidity(bool _unlimited) external {
        unlimitedLiquidity = _unlimited;
    }

    /**
     * @notice 存入资产到 Mock Provider（用于测试）
     * @param amount 存入金额
     */
    function deposit(uint256 amount) external {
        assetToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice 提取资产（用于测试）
     * @param amount 提取金额
     */
    function withdraw(uint256 amount) external {
        assetToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice 铸造资产到合约（配合 MockERC20 使用）
     * @param amount 铸造金额
     * @dev 需要 assetToken 支持 mint 函数
     */
    function mint(uint256 amount) external {
        // 假设 assetToken 是 MockERC20，支持 mint
        // 实际调用需要通过接口或类型转换
        (bool success, ) = address(assetToken).call(
            abi.encodeWithSignature("mint(address,uint256)", address(this), amount)
        );
        require(success, "Mint failed");
    }

    /**
     * @notice 清空所有借款记录（用于测试重置）
     */
    function reset() external {
        // 清空市场列表
        for (uint256 i = 0; i < markets.length; i++) {
            borrowed[markets[i]] = 0;
            authorizedMarkets[markets[i]] = false;
        }
        delete markets;
        totalBorrowed = 0;
    }
}
