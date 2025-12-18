// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ILiquidityVault_V3.sol";

/**
 * @title LiquidityVault_V3
 * @notice V3 架构流动性金库 - ERC-4626 标准
 * @dev 核心功能：
 *      1. LP 存入 USDC → 获得 Shares
 *      2. 市场借出初始流动性
 *      3. 市场结算后归还本金 ± 盈亏
 *      4. LP 收益自动分配（Shares 升值）
 *
 * 资金流：
 *      LP存款 → Vault → Market借款 → 用户下注 → 结算 → 归还Vault
 *                         ↓
 *                    LP盈利（用户输）或 LP亏损（用户赢）
 *
 * 安全特性：
 *      - 最大利用率限制（防止挤兑）
 *      - 单市场借款上限（分散风险）
 *      - 最大亏损限额（每个市场）
 *      - 储备金机制（覆盖极端亏损）
 *      - 紧急暂停机制
 *
 * @author PitchOne Team
 */
contract LiquidityVault_V3 is ILiquidityVault_V3, ERC4626, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 角色 ============

    bytes32 public constant MARKET_ROLE = keccak256("MARKET_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // ============ 常量 ============

    uint256 public constant BASIS_POINTS = 10000;

    /// @notice 最大利用率 90%（保留 10% 应对提款）
    uint256 public constant MAX_UTILIZATION_BPS = 9000;

    /// @notice 默认单市场最大亏损比例 5%
    uint256 public constant DEFAULT_MAX_LIABILITY_BPS = 500;

    /// @notice 单市场最大借款比例 20%
    uint256 public constant MAX_SINGLE_MARKET_BPS = 2000;

    // ============ 状态变量 ============

    /// @notice 市场借款信息
    mapping(address => BorrowInfo) private _borrowInfo;

    /// @notice 已授权市场列表
    address[] private _authorizedMarkets;

    /// @notice 总借出金额
    uint256 private _totalBorrowed;

    /// @notice 累计 LP 收益
    uint256 public totalProfitAccumulated;

    /// @notice 累计 LP 亏损
    uint256 public totalLossAccumulated;

    /// @notice 储备金（用于覆盖亏损）
    uint256 private _reserveFund;

    /// @notice 储备金比例（从收益中提取）
    uint256 public reserveRatioBps = 1000; // 10%

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _asset 底层资产地址（USDC）
     * @param _name Vault Shares 代币名称
     * @param _symbol Vault Shares 代币符号
     */
    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    // ============ 管理函数 ============

    /// @inheritdoc ILiquidityVault_V3
    function authorizeMarket(address market, uint256 maxLiabilityBps)
        external
        override
        onlyRole(OPERATOR_ROLE)
    {
        if (market == address(0)) revert InvalidAmount();
        if (_borrowInfo[market].active) revert MarketAlreadyAuthorized();

        _grantRole(MARKET_ROLE, market);

        _borrowInfo[market] = BorrowInfo({
            principal: 0,
            borrowedAt: 0,
            maxLiabilityBps: maxLiabilityBps > 0 ? maxLiabilityBps : DEFAULT_MAX_LIABILITY_BPS,
            active: true
        });

        _authorizedMarkets.push(market);

        emit MarketAuthorized(market, maxLiabilityBps);
    }

    /// @inheritdoc ILiquidityVault_V3
    function revokeMarket(address market) external override onlyRole(OPERATOR_ROLE) {
        if (!_borrowInfo[market].active) revert UnauthorizedMarket();
        if (_borrowInfo[market].principal > 0) revert MarketHasOutstandingDebt();

        _revokeRole(MARKET_ROLE, market);
        _borrowInfo[market].active = false;

        // 从列表移除
        _removeFromArray(_authorizedMarkets, market);

        emit MarketRevoked(market);
    }

    /**
     * @notice 批量授权市场
     * @param markets 市场地址数组
     * @param maxLiabilityBps 最大亏损比例
     */
    function authorizeMarkets(address[] calldata markets, uint256 maxLiabilityBps)
        external
        onlyRole(OPERATOR_ROLE)
    {
        for (uint256 i = 0; i < markets.length; i++) {
            if (!_borrowInfo[markets[i]].active) {
                _grantRole(MARKET_ROLE, markets[i]);

                _borrowInfo[markets[i]] = BorrowInfo({
                    principal: 0,
                    borrowedAt: 0,
                    maxLiabilityBps: maxLiabilityBps > 0 ? maxLiabilityBps : DEFAULT_MAX_LIABILITY_BPS,
                    active: true
                });

                _authorizedMarkets.push(markets[i]);

                emit MarketAuthorized(markets[i], maxLiabilityBps);
            }
        }
    }

    /**
     * @notice 设置储备金比例
     * @param _reserveRatioBps 新比例（基点）
     */
    function setReserveRatio(uint256 _reserveRatioBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_reserveRatioBps <= 5000, "Max 50%");
        reserveRatioBps = _reserveRatioBps;
    }

    /**
     * @notice 注入储备金
     * @param amount 注入金额
     */
    function depositReserve(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
        _reserveFund += amount;
        emit ReserveFundUpdated(_reserveFund, true);
    }

    /**
     * @notice 提取储备金
     * @param amount 提取金额
     * @param recipient 接收地址
     */
    function withdrawReserve(uint256 amount, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= _reserveFund, "Insufficient reserve");
        require(recipient != address(0), "Invalid recipient");

        _reserveFund -= amount;
        IERC20(asset()).safeTransfer(recipient, amount);

        emit ReserveFundUpdated(_reserveFund, false);
    }

    /**
     * @notice 暂停
     */
    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    /**
     * @notice 恢复
     */
    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    // ============ 市场借贷接口 ============

    /// @inheritdoc ILiquidityVault_V3
    function borrow(uint256 amount) external override onlyRole(MARKET_ROLE) whenNotPaused nonReentrant {
        if (amount == 0) revert InvalidAmount();

        BorrowInfo storage info = _borrowInfo[msg.sender];
        if (!info.active) revert UnauthorizedMarket();

        // 检查利用率
        uint256 available = _availableToBorrow();
        if (amount > available) {
            revert ExceedsUtilizationLimit(amount, available);
        }

        // 检查单市场借款上限
        uint256 maxSingleMarketBorrow = totalAssets() * MAX_SINGLE_MARKET_BPS / BASIS_POINTS;
        if (info.principal + amount > maxSingleMarketBorrow) {
            revert ExceedsUtilizationLimit(amount, maxSingleMarketBorrow - info.principal);
        }

        // 更新借款记录
        info.principal += amount;
        info.borrowedAt = block.timestamp;
        _totalBorrowed += amount;

        // 转账给市场
        IERC20(asset()).safeTransfer(msg.sender, amount);

        emit LiquidityBorrowed(msg.sender, amount, _totalBorrowed);
    }

    /// @inheritdoc ILiquidityVault_V3
    function settle(uint256 principal, int256 pnl)
        external
        override
        onlyRole(MARKET_ROLE)
        whenNotPaused
        nonReentrant
    {
        BorrowInfo storage info = _borrowInfo[msg.sender];
        if (info.principal < principal) revert InsufficientBorrowBalance();

        // 检查亏损限额
        if (pnl < 0) {
            uint256 loss = uint256(-pnl);
            uint256 maxLiability = info.principal * info.maxLiabilityBps / BASIS_POINTS;
            if (loss > maxLiability) {
                revert ExceedsLiabilityLimit(loss, maxLiability);
            }
        }

        // 计算实际转账金额
        uint256 transferAmount;
        if (pnl >= 0) {
            // LP 盈利：市场转入 本金 + 利润
            transferAmount = principal + uint256(pnl);
            IERC20(asset()).safeTransferFrom(msg.sender, address(this), transferAmount);
            _distributeProfits(uint256(pnl));
        } else {
            // LP 亏损：市场转入 本金 - 亏损
            uint256 loss = uint256(-pnl);
            if (principal > loss) {
                transferAmount = principal - loss;
                IERC20(asset()).safeTransferFrom(msg.sender, address(this), transferAmount);
            }
            // 如果 principal <= loss，市场不需要转账（已经在赔付中用完）

            // 处理亏损
            _handleLoss(loss);
        }

        // 更新借款记录
        info.principal -= principal;
        _totalBorrowed -= principal;

        emit LiquiditySettled(msg.sender, principal, pnl, _totalBorrowed);
    }

    /// @inheritdoc ILiquidityVault_V3
    function returnPrincipal(uint256 principal)
        external
        override
        onlyRole(MARKET_ROLE)
        whenNotPaused
        nonReentrant
    {
        BorrowInfo storage info = _borrowInfo[msg.sender];
        if (info.principal < principal) revert InsufficientBorrowBalance();

        // 市场转入本金
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), principal);

        // 更新借款记录
        info.principal -= principal;
        _totalBorrowed -= principal;

        emit LiquiditySettled(msg.sender, principal, 0, _totalBorrowed);
    }

    // ============ 内部函数 ============

    /**
     * @notice 分配利润
     * @param profit 利润金额
     */
    function _distributeProfits(uint256 profit) internal {
        // 一部分进入储备金
        uint256 toReserve = profit * reserveRatioBps / BASIS_POINTS;
        uint256 toLPs = profit - toReserve;

        _reserveFund += toReserve;
        totalProfitAccumulated += toLPs;

        // toLPs 自动体现在 totalAssets() 增加，LP shares 升值

        emit ProfitDistributed(profit, toReserve, toLPs);
    }

    /**
     * @notice 处理亏损
     * @param loss 亏损金额
     */
    function _handleLoss(uint256 loss) internal {
        totalLossAccumulated += loss;

        // 优先从储备金覆盖
        if (_reserveFund >= loss) {
            _reserveFund -= loss;
            emit ReserveFundUpdated(_reserveFund, false);
        } else if (_reserveFund > 0) {
            // 储备金不足，用尽储备金，剩余由 LP 承担
            _reserveFund = 0;
            emit ReserveFundUpdated(0, false);
            // 剩余的 loss 由 LP 承担（体现在 totalAssets 减少）
        }
        // 如果储备金为 0，全部亏损由 LP 承担
    }

    /**
     * @notice 可借出金额（考虑利用率限制）
     */
    function _availableToBorrow() internal view returns (uint256) {
        uint256 total = totalAssets();
        if (total == 0) return 0;

        uint256 maxBorrow = total * MAX_UTILIZATION_BPS / BASIS_POINTS;
        return maxBorrow > _totalBorrowed ? maxBorrow - _totalBorrowed : 0;
    }

    /**
     * @notice 从数组中移除元素
     */
    function _removeFromArray(address[] storage arr, address item) internal {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }

    // ============ ERC-4626 覆盖 ============

    /**
     * @notice 总资产 = 合约余额 + 借出金额 - 储备金
     * @dev 储备金不计入 LP 可分配资产
     */
    function totalAssets() public view override returns (uint256) {
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        // 储备金是独立的，不参与 LP 分配
        uint256 lpAssets = balance > _reserveFund ? balance - _reserveFund : 0;
        return lpAssets + _totalBorrowed;
    }

    /**
     * @notice 存款
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    /**
     * @notice 铸造
     */
    function mint(uint256 shares, address receiver)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        return super.mint(shares, receiver);
    }

    /**
     * @notice 提款
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        uint256 available = balance > _reserveFund ? balance - _reserveFund : 0;
        require(assets <= available, "Insufficient liquidity");
        return super.withdraw(assets, receiver, owner);
    }

    /**
     * @notice 赎回
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        whenNotPaused
        returns (uint256)
    {
        uint256 assets = previewRedeem(shares);
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        uint256 available = balance > _reserveFund ? balance - _reserveFund : 0;
        require(assets <= available, "Insufficient liquidity");
        return super.redeem(shares, receiver, owner);
    }

    /**
     * @notice 最大提款金额
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 ownerMax = super.maxWithdraw(owner);
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        uint256 available = balance > _reserveFund ? balance - _reserveFund : 0;
        return ownerMax < available ? ownerMax : available;
    }

    /**
     * @notice 最大赎回 shares
     */
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 ownerShares = super.maxRedeem(owner);
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        uint256 available = balance > _reserveFund ? balance - _reserveFund : 0;
        uint256 availableShares = convertToShares(available);
        return ownerShares < availableShares ? ownerShares : availableShares;
    }

    // ============ 查询函数 ============

    /// @inheritdoc ILiquidityVault_V3
    function getBorrowInfo(address market) external view override returns (BorrowInfo memory) {
        return _borrowInfo[market];
    }

    /// @inheritdoc ILiquidityVault_V3
    function availableLiquidity() external view override returns (uint256) {
        return _availableToBorrow();
    }

    /// @inheritdoc ILiquidityVault_V3
    function totalBorrowed() external view override returns (uint256) {
        return _totalBorrowed;
    }

    /// @inheritdoc ILiquidityVault_V3
    function utilizationRate() external view override returns (uint256) {
        uint256 total = totalAssets();
        if (total == 0) return 0;
        return _totalBorrowed * BASIS_POINTS / total;
    }

    /// @inheritdoc ILiquidityVault_V3
    function reserveFund() external view override returns (uint256) {
        return _reserveFund;
    }

    /// @inheritdoc ILiquidityVault_V3
    function getAuthorizedMarkets() external view override returns (address[] memory) {
        return _authorizedMarkets;
    }

    /// @inheritdoc ILiquidityVault_V3
    function getVaultStats()
        external
        view
        override
        returns (
            uint256 _totalAssets,
            uint256 __totalBorrowed,
            uint256 _availableLiquidity,
            uint256 __reserveFund,
            uint256 _totalProfit,
            uint256 _totalLoss
        )
    {
        return (
            totalAssets(),
            _totalBorrowed,
            _availableToBorrow(),
            _reserveFund,
            totalProfitAccumulated,
            totalLossAccumulated
        );
    }

    /**
     * @notice 获取市场借款详情
     * @param market 市场地址
     * @return principal 借款本金
     * @return maxLiability 最大亏损限额（计算后的金额）
     * @return canBorrowMore 是否还能借更多
     */
    function getMarketBorrowDetails(address market)
        external
        view
        returns (uint256 principal, uint256 maxLiability, bool canBorrowMore)
    {
        BorrowInfo memory info = _borrowInfo[market];
        principal = info.principal;
        maxLiability = info.principal * info.maxLiabilityBps / BASIS_POINTS;

        uint256 maxSingleMarketBorrow = totalAssets() * MAX_SINGLE_MARKET_BPS / BASIS_POINTS;
        canBorrowMore = info.active && info.principal < maxSingleMarketBorrow;
    }

    // ============ 接口支持 ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
