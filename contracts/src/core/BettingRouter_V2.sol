// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IBettingRouter_V2.sol";
import "../interfaces/IMarket_V3.sol";

/**
 * @title BettingRouter_V2
 * @notice 统一下注路由器 V2 - 支持批量下注
 * @dev 核心功能：
 *      - 单笔下注
 *      - 批量下注（多市场/多结果）
 *      - 费用计算和路由
 *      - 滑点保护
 *      - 市场验证
 */
contract BettingRouter_V2 is IBettingRouter_V2, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @notice 市场工厂
    address public override factory;

    /// @notice 结算代币
    IERC20 public settlementToken;

    /// @notice 费用适配器（未使用，保留接口兼容）
    address public override feeAdapter;

    /// @notice 费用路由器（未使用，保留接口兼容）
    address public override feeRouter;

    /// @notice 费用接收地址
    address public feeRecipient;

    /// @notice 基础费率（基点，如 200 = 2%）
    uint256 public baseFeeRate;

    /// @notice 暂停状态
    bool public paused;

    // ============ 错误定义 ============

    error InvalidMarket();
    error MarketNotOpen();
    error SlippageExceeded();
    error InsufficientAllowance();
    error RouterPaused();
    error InvalidParams();

    // ============ 修饰器 ============

    modifier notPaused() {
        if (paused) revert RouterPaused();
        _;
    }

    modifier validMarket(address market) {
        if (!isValidMarket(market)) revert InvalidMarket();
        _;
    }

    // ============ 构造函数 ============

    constructor(
        address _factory,
        address _settlementToken,
        address _feeRecipient,
        uint256 _baseFeeRate
    ) Ownable(msg.sender) {
        require(_factory != address(0), "Router: Invalid factory");
        require(_settlementToken != address(0), "Router: Invalid token");

        factory = _factory;
        settlementToken = IERC20(_settlementToken);
        feeRecipient = _feeRecipient;
        baseFeeRate = _baseFeeRate;
    }

    // ============ 单笔下注 ============

    /// @inheritdoc IBettingRouter_V2
    function placeBet(
        address market,
        uint256 outcomeId,
        uint256 amount,
        uint256 minShares
    )
        external
        override
        nonReentrant
        notPaused
        validMarket(market)
        returns (uint256 shares)
    {
        // 计算费用
        FeeResult memory feeResult = _calculateFee(msg.sender, amount);

        // 转入资金
        settlementToken.safeTransferFrom(msg.sender, address(this), amount);

        // 路由费用
        if (feeResult.feeAmount > 0 && feeRecipient != address(0)) {
            settlementToken.safeTransfer(feeRecipient, feeResult.feeAmount);
        }

        // 转账净金额到市场
        settlementToken.safeTransfer(market, feeResult.netAmount);

        // 调用市场下注
        shares = IMarket_V3(market).placeBetFor(
            msg.sender,
            outcomeId,
            feeResult.netAmount,
            minShares
        );

        emit BetPlaced(msg.sender, market, outcomeId, amount, shares, feeResult.feeAmount);
    }

    // ============ 批量下注 ============

    /// @inheritdoc IBettingRouter_V2
    function placeBetBatch(BetParams[] calldata bets)
        external
        override
        nonReentrant
        notPaused
        returns (BetResult[] memory results)
    {
        if (bets.length == 0) revert InvalidParams();

        results = new BetResult[](bets.length);
        uint256 totalAmount = 0;
        uint256 totalFee = 0;

        // 计算总金额
        for (uint256 i = 0; i < bets.length; i++) {
            totalAmount += bets[i].amount;
        }

        // 转入总资金
        settlementToken.safeTransferFrom(msg.sender, address(this), totalAmount);

        // 处理每笔下注
        for (uint256 i = 0; i < bets.length; i++) {
            BetParams calldata bet = bets[i];

            // 计算费用
            FeeResult memory feeResult = _calculateFee(msg.sender, bet.amount);
            totalFee += feeResult.feeAmount;

            // 验证市场
            if (!isValidMarket(bet.market)) {
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: 0,
                    shares: 0,
                    fee: 0
                });
                // 退还资金
                settlementToken.safeTransfer(msg.sender, bet.amount);
                continue;
            }

            // 转账净金额到市场
            settlementToken.safeTransfer(bet.market, feeResult.netAmount);

            // 调用市场下注
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
                    fee: feeResult.feeAmount
                });

                emit BetPlaced(
                    msg.sender,
                    bet.market,
                    bet.outcomeId,
                    bet.amount,
                    shares,
                    feeResult.feeAmount
                );
            } catch {
                results[i] = BetResult({
                    market: bet.market,
                    outcomeId: bet.outcomeId,
                    amount: 0,
                    shares: 0,
                    fee: 0
                });
                // 退还净金额
                settlementToken.safeTransfer(msg.sender, feeResult.netAmount);
            }
        }

        // 路由费用
        if (totalFee > 0 && feeRecipient != address(0)) {
            settlementToken.safeTransfer(feeRecipient, totalFee);
        }

        emit BatchBetPlaced(msg.sender, bets.length, totalAmount, totalFee);
    }

    /// @inheritdoc IBettingRouter_V2
    function placeBetMultiOutcome(
        address market,
        uint256[] calldata outcomeIds,
        uint256[] calldata amounts,
        uint256[] calldata minShares
    )
        external
        override
        nonReentrant
        notPaused
        validMarket(market)
        returns (uint256[] memory shares)
    {
        if (outcomeIds.length != amounts.length || amounts.length != minShares.length) {
            revert InvalidParams();
        }

        shares = new uint256[](outcomeIds.length);
        uint256 totalAmount = 0;
        uint256 totalFee = 0;

        // 计算总金额
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // 转入总资金
        settlementToken.safeTransferFrom(msg.sender, address(this), totalAmount);

        // 处理每笔下注
        for (uint256 i = 0; i < outcomeIds.length; i++) {
            FeeResult memory feeResult = _calculateFee(msg.sender, amounts[i]);
            totalFee += feeResult.feeAmount;

            // 转账净金额到市场
            settlementToken.safeTransfer(market, feeResult.netAmount);

            // 调用市场下注
            shares[i] = IMarket_V3(market).placeBetFor(
                msg.sender,
                outcomeIds[i],
                feeResult.netAmount,
                minShares[i]
            );

            emit BetPlaced(msg.sender, market, outcomeIds[i], amounts[i], shares[i], feeResult.feeAmount);
        }

        // 路由费用
        if (totalFee > 0 && feeRecipient != address(0)) {
            settlementToken.safeTransfer(feeRecipient, totalFee);
        }
    }

    /// @inheritdoc IBettingRouter_V2
    function placeBetMultiMarket(
        address[] calldata markets,
        uint256 outcomeId,
        uint256[] calldata amounts,
        uint256[] calldata minShares
    )
        external
        override
        nonReentrant
        notPaused
        returns (uint256[] memory shares)
    {
        if (markets.length != amounts.length || amounts.length != minShares.length) {
            revert InvalidParams();
        }

        shares = new uint256[](markets.length);
        uint256 totalAmount = 0;
        uint256 totalFee = 0;

        // 计算总金额
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // 转入总资金
        settlementToken.safeTransferFrom(msg.sender, address(this), totalAmount);

        // 处理每笔下注
        for (uint256 i = 0; i < markets.length; i++) {
            if (!isValidMarket(markets[i])) {
                // 跳过无效市场，退还资金
                settlementToken.safeTransfer(msg.sender, amounts[i]);
                continue;
            }

            FeeResult memory feeResult = _calculateFee(msg.sender, amounts[i]);
            totalFee += feeResult.feeAmount;

            // 转账净金额到市场
            settlementToken.safeTransfer(markets[i], feeResult.netAmount);

            // 调用市场下注
            shares[i] = IMarket_V3(markets[i]).placeBetFor(
                msg.sender,
                outcomeId,
                feeResult.netAmount,
                minShares[i]
            );

            emit BetPlaced(msg.sender, markets[i], outcomeId, amounts[i], shares[i], feeResult.feeAmount);
        }

        // 路由费用
        if (totalFee > 0 && feeRecipient != address(0)) {
            settlementToken.safeTransfer(feeRecipient, totalFee);
        }
    }

    // ============ 费用计算 ============

    /// @inheritdoc IBettingRouter_V2
    function calculateFee(address user, uint256 amount)
        external
        view
        override
        returns (FeeResult memory)
    {
        return _calculateFee(user, amount);
    }

    /// @inheritdoc IBettingRouter_V2
    function calculateFeeBatch(address user, uint256[] calldata amounts)
        external
        view
        override
        returns (
            FeeResult[] memory results,
            uint256 totalGross,
            uint256 totalFee,
            uint256 totalNet
        )
    {
        results = new FeeResult[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            results[i] = _calculateFee(user, amounts[i]);
            totalGross += results[i].grossAmount;
            totalFee += results[i].feeAmount;
            totalNet += results[i].netAmount;
        }
    }

    function _calculateFee(address user, uint256 amount)
        internal
        view
        returns (FeeResult memory result)
    {
        // 可以在这里添加用户折扣逻辑
        uint256 feeAmount = amount * baseFeeRate / 10000;

        result = FeeResult({
            grossAmount: amount,
            feeAmount: feeAmount,
            netAmount: amount - feeAmount,
            discountBps: 0,
            referrer: address(0)
        });
    }

    // ============ 查询函数 ============

    /// @inheritdoc IBettingRouter_V2
    function previewBet(address market, uint256 outcomeId, uint256 amount)
        external
        view
        override
        returns (
            uint256 netAmount,
            uint256 shares,
            uint256 fee
        )
    {
        FeeResult memory feeResult = _calculateFee(msg.sender, amount);
        fee = feeResult.feeAmount;
        netAmount = feeResult.netAmount;

        uint256 newPrice;
        (shares, newPrice) = IMarket_V3(market).previewBet(outcomeId, netAmount);
    }

    /// @inheritdoc IBettingRouter_V2
    function previewBetBatch(BetParams[] calldata bets)
        external
        view
        override
        returns (uint256 totalAmount, uint256 totalShares, uint256 totalFee)
    {
        for (uint256 i = 0; i < bets.length; i++) {
            FeeResult memory feeResult = _calculateFee(msg.sender, bets[i].amount);
            totalAmount += bets[i].amount;
            totalFee += feeResult.feeAmount;

            try IMarket_V3(bets[i].market).previewBet(bets[i].outcomeId, feeResult.netAmount) returns (uint256 shares, uint256) {
                totalShares += shares;
            } catch {
                // 无效市场，跳过
            }
        }
    }

    // ============ 市场验证 ============

    /// @inheritdoc IBettingRouter_V2
    function isValidMarket(address market) public view override returns (bool) {
        // 检查工厂注册
        if (factory != address(0)) {
            try IMarketFactory(factory).isMarket(market) returns (bool registered) {
                if (!registered) return false;
            } catch {
                return false;
            }
        }

        // 检查市场状态
        try IMarket_V3(market).status() returns (IMarket_V3.MarketStatus status) {
            if (status != IMarket_V3.MarketStatus.Open) return false;
        } catch {
            return false;
        }

        return true;
    }

    // ============ 管理函数 ============

    function setFeeRate(uint256 _rate) external onlyOwner {
        require(_rate <= 1000, "Router: Fee too high"); // max 10%
        baseFeeRate = _rate;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    /// @notice 紧急提取代币（仅 owner）
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}

// ============ 辅助接口 ============

interface IMarketFactory {
    function isMarket(address market) external view returns (bool);
}
