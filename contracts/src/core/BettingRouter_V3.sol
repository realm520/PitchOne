// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IBettingRouter_V3} from "../interfaces/IBettingRouter_V3.sol";
import {IMarket_V3} from "../interfaces/IMarket_V3.sol";

/**
 * @title BettingRouter_V3
 * @notice 统一下注路由器 V3 - 支持多代币
 * @dev 核心改进：
 *      - 动态读取市场的 settlementToken
 *      - 代币白名单机制
 *      - 每种代币可配置不同费率
 *      - 支持跨代币批量下注
 *
 * 安全机制：
 *      - 代币白名单（防止恶意代币）
 *      - 最小/最大下注限制
 *      - 暂停功能
 *      - 重入保护
 */
contract BettingRouter_V3 is IBettingRouter_V3, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ 状态变量 ============

    /// @notice 市场工厂
    address public override factory;

    /// @notice 暂停状态
    bool public override paused;

    /// @notice 支持的代币集合
    EnumerableSet.AddressSet private _supportedTokens;

    /// @notice 代币配置
    mapping(address => TokenInfo) private _tokenInfo;

    /// @notice 默认费率（基点，用于未单独配置的代币）
    uint256 public defaultFeeRateBps;

    /// @notice 默认费用接收地址
    address public defaultFeeRecipient;

    // ============ 修饰器 ============

    modifier notPaused() {
        if (paused) revert RouterPaused();
        _;
    }

    modifier validToken(address token) {
        if (!_supportedTokens.contains(token)) revert UnsupportedToken(token);
        _;
    }

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _factory 市场工厂地址
     * @param _defaultFeeRateBps 默认费率（基点）
     * @param _defaultFeeRecipient 默认费用接收地址
     */
    constructor(
        address _factory,
        uint256 _defaultFeeRateBps,
        address _defaultFeeRecipient
    ) Ownable(msg.sender) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_defaultFeeRecipient == address(0)) revert ZeroAddress();
        if (_defaultFeeRateBps > 1000) revert InvalidParams(); // max 10%

        factory = _factory;
        defaultFeeRateBps = _defaultFeeRateBps;
        defaultFeeRecipient = _defaultFeeRecipient;
    }

    // ============ 单笔下注 ============

    /// @inheritdoc IBettingRouter_V3
    function placeBet(
        address market,
        uint256 outcomeId,
        uint256 amount,
        uint256 minShares
    ) external override nonReentrant notPaused returns (uint256 shares) {
        if (amount == 0) revert ZeroAmount();

        // 1. 获取市场的结算代币
        address token = _getMarketToken(market);

        // 2. 验证代币和市场
        _validateToken(token, amount);
        _validateMarket(market);

        // 3. 计算费用
        FeeResult memory feeResult = _calculateFee(token, msg.sender, amount);

        // 4. 从用户转账到 Router
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // 5. 路由费用
        if (feeResult.feeAmount > 0) {
            address recipient = _getFeeRecipient(token);
            IERC20(token).safeTransfer(recipient, feeResult.feeAmount);
            emit FeeRouted(token, feeResult.feeAmount, recipient);
        }

        // 6. 转账净金额到市场
        IERC20(token).safeTransfer(market, feeResult.netAmount);

        // 7. 调用市场的 placeBetFor
        shares = IMarket_V3(market).placeBetFor(
            msg.sender,
            outcomeId,
            feeResult.netAmount,
            minShares
        );

        emit BetPlaced(
            msg.sender,
            market,
            token,
            outcomeId,
            amount,
            shares,
            feeResult.feeAmount
        );
    }

    // ============ 批量下注 ============

    /// @inheritdoc IBettingRouter_V3
    function placeBetBatch(BetParams[] calldata bets)
        external
        override
        nonReentrant
        notPaused
        returns (BetResult[] memory results)
    {
        if (bets.length == 0) revert InvalidParams();

        results = new BetResult[](bets.length);
        uint256 totalFee = 0;

        for (uint256 i = 0; i < bets.length; i++) {
            BetParams calldata bet = bets[i];

            // 获取市场代币
            address token;
            try this.getMarketToken(bet.market) returns (address _token) {
                token = _token;
            } catch {
                // 市场无效，记录失败结果
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: 0,
                    shares: 0,
                    fee: 0,
                    token: address(0)
                });
                continue;
            }

            // 验证代币
            if (!_supportedTokens.contains(token)) {
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: 0,
                    shares: 0,
                    fee: 0,
                    token: token
                });
                continue;
            }

            // 计算费用
            FeeResult memory feeResult = _calculateFee(token, msg.sender, bet.amount);

            // 转账
            IERC20(token).safeTransferFrom(msg.sender, address(this), bet.amount);

            // 路由费用
            if (feeResult.feeAmount > 0) {
                address recipient = _getFeeRecipient(token);
                IERC20(token).safeTransfer(recipient, feeResult.feeAmount);
                totalFee += feeResult.feeAmount;
            }

            // 转账到市场
            IERC20(token).safeTransfer(bet.market, feeResult.netAmount);

            // 下注
            try IMarket_V3(bet.market).placeBetFor(
                msg.sender,
                bet.outcomeId,
                feeResult.netAmount,
                bet.minShares
            ) returns (uint256 shares) {
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: feeResult.netAmount,
                    shares: shares,
                    fee: feeResult.feeAmount,
                    token: token
                });

                emit BetPlaced(
                    msg.sender,
                    bet.market,
                    token,
                    bet.outcomeId,
                    bet.amount,
                    shares,
                    feeResult.feeAmount
                );
            } catch {
                // 下注失败，退还资金
                IERC20(token).safeTransfer(msg.sender, feeResult.netAmount);
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: 0,
                    shares: 0,
                    fee: 0,
                    token: token
                });
            }
        }

        emit BatchBetPlaced(msg.sender, bets.length, totalFee);
    }

    /// @inheritdoc IBettingRouter_V3
    function placeBetMultiOutcome(
        address market,
        uint256[] calldata outcomeIds,
        uint256[] calldata amounts,
        uint256[] calldata minSharesList
    ) external override nonReentrant notPaused returns (uint256[] memory sharesList) {
        if (outcomeIds.length != amounts.length || amounts.length != minSharesList.length) {
            revert InvalidParams();
        }

        // 获取市场代币
        address token = _getMarketToken(market);
        _validateMarket(market);

        sharesList = new uint256[](outcomeIds.length);
        uint256 totalAmount = 0;
        uint256 totalFee = 0;

        // 计算总金额
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // 一次性转账
        IERC20(token).safeTransferFrom(msg.sender, address(this), totalAmount);

        // 处理每笔下注
        for (uint256 i = 0; i < outcomeIds.length; i++) {
            FeeResult memory feeResult = _calculateFee(token, msg.sender, amounts[i]);
            totalFee += feeResult.feeAmount;

            // 转账到市场
            IERC20(token).safeTransfer(market, feeResult.netAmount);

            // 下注
            sharesList[i] = IMarket_V3(market).placeBetFor(
                msg.sender,
                outcomeIds[i],
                feeResult.netAmount,
                minSharesList[i]
            );

            emit BetPlaced(
                msg.sender,
                market,
                token,
                outcomeIds[i],
                amounts[i],
                sharesList[i],
                feeResult.feeAmount
            );
        }

        // 路由费用
        if (totalFee > 0) {
            address recipient = _getFeeRecipient(token);
            IERC20(token).safeTransfer(recipient, totalFee);
            emit FeeRouted(token, totalFee, recipient);
        }
    }

    // ============ 费用计算 ============

    /// @inheritdoc IBettingRouter_V3
    function calculateFee(address token, address user, uint256 amount)
        external
        view
        override
        returns (FeeResult memory result)
    {
        return _calculateFee(token, user, amount);
    }

    /// @inheritdoc IBettingRouter_V3
    function calculateFeeForMarket(address market, address user, uint256 amount)
        external
        view
        override
        returns (FeeResult memory result)
    {
        address token = _getMarketToken(market);
        return _calculateFee(token, user, amount);
    }

    function _calculateFee(address token, address /* user */, uint256 amount)
        internal
        view
        returns (FeeResult memory result)
    {
        uint256 feeRate = _getFeeRate(token);
        uint256 feeAmount = (amount * feeRate) / 10000;

        result = FeeResult({
            grossAmount: amount,
            feeAmount: feeAmount,
            netAmount: amount - feeAmount,
            discountBps: 0,
            referrer: address(0)
        });
    }

    // ============ 预览下注 ============

    /// @inheritdoc IBettingRouter_V3
    function previewBet(address market, uint256 outcomeId, uint256 amount)
        external
        view
        override
        returns (address token, uint256 netAmount, uint256 shares, uint256 fee)
    {
        token = _getMarketToken(market);
        FeeResult memory feeResult = _calculateFee(token, msg.sender, amount);
        fee = feeResult.feeAmount;
        netAmount = feeResult.netAmount;

        (shares, ) = IMarket_V3(market).previewBet(outcomeId, netAmount);
    }

    // ============ 代币管理 ============

    /// @inheritdoc IBettingRouter_V3
    function isTokenSupported(address token) external view override returns (bool) {
        return _supportedTokens.contains(token);
    }

    /// @inheritdoc IBettingRouter_V3
    function getTokenInfo(address token) external view override returns (TokenInfo memory) {
        return _tokenInfo[token];
    }

    /// @inheritdoc IBettingRouter_V3
    function getSupportedTokens() external view override returns (address[] memory tokens) {
        uint256 length = _supportedTokens.length();
        tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = _supportedTokens.at(i);
        }
    }

    /**
     * @notice 添加支持的代币
     * @param token 代币地址
     * @param feeRateBps 费率（基点）
     * @param feeRecipient 费用接收地址
     * @param minBetAmount 最小下注金额
     * @param maxBetAmount 最大下注金额（0 = 无限制）
     */
    function addToken(
        address token,
        uint256 feeRateBps,
        address feeRecipient,
        uint256 minBetAmount,
        uint256 maxBetAmount
    ) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        if (feeRateBps > 1000) revert InvalidParams(); // max 10%

        _supportedTokens.add(token);
        _tokenInfo[token] = TokenInfo({
            supported: true,
            feeRateBps: feeRateBps,
            feeRecipient: feeRecipient,
            minBetAmount: minBetAmount,
            maxBetAmount: maxBetAmount
        });

        emit TokenAdded(token, feeRateBps, feeRecipient);
    }

    /**
     * @notice 移除支持的代币
     * @param token 代币地址
     */
    function removeToken(address token) external onlyOwner {
        _supportedTokens.remove(token);
        delete _tokenInfo[token];
        emit TokenRemoved(token);
    }

    /**
     * @notice 更新代币配置
     * @param token 代币地址
     * @param feeRateBps 费率（基点）
     * @param feeRecipient 费用接收地址
     * @param minBetAmount 最小下注金额
     * @param maxBetAmount 最大下注金额
     */
    function updateTokenConfig(
        address token,
        uint256 feeRateBps,
        address feeRecipient,
        uint256 minBetAmount,
        uint256 maxBetAmount
    ) external onlyOwner {
        if (!_supportedTokens.contains(token)) revert UnsupportedToken(token);
        if (feeRateBps > 1000) revert InvalidParams();

        _tokenInfo[token] = TokenInfo({
            supported: true,
            feeRateBps: feeRateBps,
            feeRecipient: feeRecipient,
            minBetAmount: minBetAmount,
            maxBetAmount: maxBetAmount
        });

        emit TokenConfigUpdated(token, feeRateBps, feeRecipient, minBetAmount, maxBetAmount);
    }

    // ============ 市场验证 ============

    /// @inheritdoc IBettingRouter_V3
    function validateMarket(address market)
        external
        view
        override
        returns (bool valid, address token)
    {
        try IMarket_V3(market).settlementToken() returns (IERC20 _token) {
            token = address(_token);
        } catch {
            return (false, address(0));
        }

        // 检查工厂注册
        if (factory != address(0)) {
            try IMarketFactory_V3(factory).isMarket(market) returns (bool registered) {
                if (!registered) return (false, token);
            } catch {
                return (false, token);
            }
        }

        // 检查市场状态
        try IMarket_V3(market).status() returns (IMarket_V3.MarketStatus status) {
            if (status != IMarket_V3.MarketStatus.Open) return (false, token);
        } catch {
            return (false, token);
        }

        // 检查代币是否支持
        if (!_supportedTokens.contains(token)) return (false, token);

        return (true, token);
    }

    /// @inheritdoc IBettingRouter_V3
    function getMarketToken(address market) external view override returns (address) {
        return _getMarketToken(market);
    }

    // ============ 管理函数 ============

    /**
     * @notice 设置工厂地址
     * @param _factory 工厂地址
     */
    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     * @notice 设置默认费率
     * @param _feeRateBps 费率（基点）
     */
    function setDefaultFeeRate(uint256 _feeRateBps) external onlyOwner {
        if (_feeRateBps > 1000) revert InvalidParams();
        defaultFeeRateBps = _feeRateBps;
    }

    /**
     * @notice 设置默认费用接收地址
     * @param _recipient 接收地址
     */
    function setDefaultFeeRecipient(address _recipient) external onlyOwner {
        if (_recipient == address(0)) revert ZeroAddress();
        defaultFeeRecipient = _recipient;
    }

    /**
     * @notice 暂停/恢复
     * @param _paused 暂停状态
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /**
     * @notice 紧急提取代币
     * @param token 代币地址
     * @param amount 金额
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    // ============ 内部函数 ============

    function _getMarketToken(address market) internal view returns (address) {
        try IMarket_V3(market).settlementToken() returns (IERC20 token) {
            return address(token);
        } catch {
            revert InvalidMarket(market);
        }
    }

    function _validateMarket(address market) internal view {
        // 检查工厂注册
        if (factory != address(0)) {
            try IMarketFactory_V3(factory).isMarket(market) returns (bool registered) {
                if (!registered) revert InvalidMarket(market);
            } catch {
                revert InvalidMarket(market);
            }
        }

        // 检查市场状态
        try IMarket_V3(market).status() returns (IMarket_V3.MarketStatus status) {
            if (status != IMarket_V3.MarketStatus.Open) revert MarketNotOpen(market);
        } catch {
            revert InvalidMarket(market);
        }
    }

    function _validateToken(address token, uint256 amount) internal view {
        if (!_supportedTokens.contains(token)) revert UnsupportedToken(token);

        TokenInfo storage info = _tokenInfo[token];
        if (info.minBetAmount > 0 && amount < info.minBetAmount) {
            revert BetAmountTooLow(amount, info.minBetAmount);
        }
        if (info.maxBetAmount > 0 && amount > info.maxBetAmount) {
            revert BetAmountTooHigh(amount, info.maxBetAmount);
        }
    }

    function _getFeeRate(address token) internal view returns (uint256) {
        TokenInfo storage info = _tokenInfo[token];
        return info.supported ? info.feeRateBps : defaultFeeRateBps;
    }

    function _getFeeRecipient(address token) internal view returns (address) {
        TokenInfo storage info = _tokenInfo[token];
        return info.feeRecipient != address(0) ? info.feeRecipient : defaultFeeRecipient;
    }
}

// ============ 辅助接口 ============

interface IMarketFactory_V3 {
    function isMarket(address market) external view returns (bool);
}
