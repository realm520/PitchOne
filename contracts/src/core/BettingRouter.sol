// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IBettableMarket
 * @notice 可下注市场接口（由 BettingRouter 使用）
 */
interface IBettableMarket {
    function placeBetFor(address user, uint256 outcomeId, uint256 amount) external returns (uint256 shares);
    function placeBetForWithSlippage(address user, uint256 outcomeId, uint256 amount, uint256 maxSlippageBps) external returns (uint256 shares);
    function settlementToken() external view returns (IERC20);
    function status() external view returns (uint8);
    function trustedRouter() external view returns (address);
}

/**
 * @title IMarketFactory
 * @notice 市场工厂接口（用于验证市场合法性）
 */
interface IMarketFactory {
    function isMarket(address market) external view returns (bool);
}

/**
 * @title BettingRouter
 * @notice 统一投注入口合约
 * @dev 用户只需授权 USDC 到此合约，即可投注所有已注册的市场
 *
 * 核心功能：
 * 1. 单笔下注：placeBet(market, outcomeId, amount)
 * 2. 批量下注：placeBets(BetParams[])
 * 3. 带滑点保护：placeBetWithSlippage(...)
 *
 * 安全机制：
 * - 仅允许投注已在 Factory 注册的市场
 * - 验证市场的 trustedRouter 设置
 * - 支持暂停和紧急提款
 *
 * @author PitchOne Team
 */
contract BettingRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @notice 结算代币（USDC）
    IERC20 public immutable settlementToken;

    /// @notice 市场工厂（用于验证市场合法性）
    IMarketFactory public factory;

    // ============ 事件 ============

    /// @notice 下注事件
    event BetPlaced(
        address indexed user,
        address indexed market,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares
    );

    /// @notice 批量下注事件
    event BatchBetsPlaced(
        address indexed user,
        uint256 totalBets,
        uint256 totalAmount
    );

    /// @notice 工厂更新事件
    event FactoryUpdated(address indexed oldFactory, address indexed newFactory);

    // ============ 错误 ============

    error InvalidMarket(address market);
    error MarketNotOpen(address market);
    error RouterNotTrusted(address market);
    error InsufficientAllowance(uint256 required, uint256 actual);
    error ZeroAmount();
    error ZeroAddress();

    // ============ 结构体 ============

    /// @notice 下注参数
    struct BetParams {
        address market;      // 市场地址
        uint256 outcomeId;   // 结果ID
        uint256 amount;      // 下注金额
        uint256 maxSlippage; // 最大滑点（基点，0 = 无限制）
    }

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _settlementToken 结算代币地址（USDC）
     * @param _factory 市场工厂地址
     */
    constructor(address _settlementToken, address _factory) Ownable(msg.sender) {
        if (_settlementToken == address(0)) revert ZeroAddress();
        if (_factory == address(0)) revert ZeroAddress();

        settlementToken = IERC20(_settlementToken);
        factory = IMarketFactory(_factory);
    }

    // ============ 核心函数 ============

    /**
     * @notice 单笔下注
     * @param market 市场地址
     * @param outcomeId 结果ID
     * @param amount 下注金额
     * @return shares 获得的份额
     */
    function placeBet(address market, uint256 outcomeId, uint256 amount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        return _placeBet(msg.sender, market, outcomeId, amount, 10000);
    }

    /**
     * @notice 单笔下注（带滑点保护）
     * @param market 市场地址
     * @param outcomeId 结果ID
     * @param amount 下注金额
     * @param maxSlippageBps 最大滑点（基点）
     * @return shares 获得的份额
     */
    function placeBetWithSlippage(
        address market,
        uint256 outcomeId,
        uint256 amount,
        uint256 maxSlippageBps
    )
        external
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        return _placeBet(msg.sender, market, outcomeId, amount, maxSlippageBps);
    }

    /**
     * @notice 批量下注
     * @param bets 下注参数数组
     * @return sharesList 每笔下注获得的份额
     */
    function placeBets(BetParams[] calldata bets)
        external
        whenNotPaused
        nonReentrant
        returns (uint256[] memory sharesList)
    {
        uint256 len = bets.length;
        sharesList = new uint256[](len);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < len; i++) {
            BetParams calldata bet = bets[i];
            uint256 slippage = bet.maxSlippage == 0 ? 10000 : bet.maxSlippage;
            sharesList[i] = _placeBet(msg.sender, bet.market, bet.outcomeId, bet.amount, slippage);
            totalAmount += bet.amount;
        }

        emit BatchBetsPlaced(msg.sender, len, totalAmount);
    }

    // ============ 内部函数 ============

    /**
     * @notice 内部下注实现
     */
    function _placeBet(
        address user,
        address market,
        uint256 outcomeId,
        uint256 amount,
        uint256 maxSlippageBps
    )
        internal
        returns (uint256 shares)
    {
        if (amount == 0) revert ZeroAmount();

        // 1. 验证市场合法性
        _validateMarket(market);

        // 2. 从用户转移资金到 Router
        settlementToken.safeTransferFrom(user, address(this), amount);

        // 3. 授权市场合约使用资金
        settlementToken.approve(market, amount);

        // 4. 调用市场的 placeBetFor
        IBettableMarket marketContract = IBettableMarket(market);
        if (maxSlippageBps < 10000) {
            shares = marketContract.placeBetForWithSlippage(user, outcomeId, amount, maxSlippageBps);
        } else {
            shares = marketContract.placeBetFor(user, outcomeId, amount);
        }

        emit BetPlaced(user, market, outcomeId, amount, shares);
    }

    /**
     * @notice 验证市场合法性
     */
    function _validateMarket(address market) internal view {
        // 检查是否为工厂注册的市场
        if (!factory.isMarket(market)) {
            revert InvalidMarket(market);
        }

        IBettableMarket marketContract = IBettableMarket(market);

        // 检查市场状态是否为 Open (0)
        if (marketContract.status() != 0) {
            revert MarketNotOpen(market);
        }

        // 检查市场是否信任此 Router
        if (marketContract.trustedRouter() != address(this)) {
            revert RouterNotTrusted(market);
        }
    }

    // ============ 视图函数 ============

    /**
     * @notice 检查用户授权额度
     * @param user 用户地址
     * @return allowance 授权额度
     */
    function checkAllowance(address user) external view returns (uint256) {
        return settlementToken.allowance(user, address(this));
    }

    /**
     * @notice 检查市场是否可用
     * @param market 市场地址
     * @return valid 是否有效
     * @return reason 无效原因（如果无效）
     */
    function checkMarket(address market) external view returns (bool valid, string memory reason) {
        if (!factory.isMarket(market)) {
            return (false, "Not a registered market");
        }

        IBettableMarket marketContract = IBettableMarket(market);

        if (marketContract.status() != 0) {
            return (false, "Market not open");
        }

        if (marketContract.trustedRouter() != address(this)) {
            return (false, "Router not trusted by market");
        }

        return (true, "");
    }

    // ============ 管理函数 ============

    /**
     * @notice 更新工厂地址
     * @param _factory 新工厂地址
     */
    function setFactory(address _factory) external onlyOwner {
        if (_factory == address(0)) revert ZeroAddress();
        emit FactoryUpdated(address(factory), _factory);
        factory = IMarketFactory(_factory);
    }

    /**
     * @notice 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice 紧急提款（仅 owner，用于处理意外滞留的资金）
     * @param token 代币地址
     * @param to 接收地址
     * @param amount 金额
     */
    function emergencyWithdraw(address token, address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        IERC20(token).safeTransfer(to, amount);
    }
}
