// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IBasket.sol";
import "../interfaces/ICorrelationGuard.sol";
import "../interfaces/IMarket.sol";

/**
 * @title Basket
 * @notice 串关（Parlay）合约 - 允许用户组合多个市场进行串关下注
 * @dev 功能：
 *      - 支持 2-10 场市场组合
 *      - 组合赔率 = 各市场赔率相乘 × (1 - 相关性惩罚)
 *      - 全中才赢，任一错误全输
 *      - 集成 CorrelationGuard 进行相关性检查
 *      - 支持滑点保护
 */
contract Basket is IBasket, Ownable, ReentrancyGuard, IERC1155Receiver, ERC165 {
    using SafeERC20 for IERC20;

    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 赔率基点（10000 = 1.0）
    uint256 private constant ODDS_BASE = 10000;

    /// @notice 默认最大串关腿数
    uint256 private constant DEFAULT_MAX_LEGS = 10;

    /// @notice 默认最小串关腿数
    uint256 private constant MIN_LEGS = 2;

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 结算币种（USDC）
    IERC20 public immutable settlementToken;

    /// @notice 相关性守卫
    ICorrelationGuard public correlationGuard;

    /// @notice 串关计数器
    uint256 public parlayCounter;

    /// @notice 串关数据映射
    mapping(uint256 => Parlay) public parlays;

    /// @notice 用户串关列表
    mapping(address => uint256[]) private userParlays;

    /// @notice 最大串关腿数
    uint256 public maxLegs;

    /// @notice 最小组合赔率（基点）
    uint256 public minOdds;

    /// @notice 最大组合赔率（基点）
    uint256 public maxOdds;

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param _settlementToken 结算币种地址
     * @param _correlationGuard 相关性守卫地址
     * @param _minOdds 最小组合赔率（基点）
     * @param _maxOdds 最大组合赔率（基点）
     */
    constructor(
        address _settlementToken,
        address _correlationGuard,
        uint256 _minOdds,
        uint256 _maxOdds
    ) Ownable(msg.sender) {
        require(_settlementToken != address(0), "Invalid settlement token");
        require(_correlationGuard != address(0), "Invalid correlation guard");
        require(_minOdds < _maxOdds, "Invalid odds limits");

        settlementToken = IERC20(_settlementToken);
        correlationGuard = ICorrelationGuard(_correlationGuard);
        maxLegs = DEFAULT_MAX_LEGS;
        minOdds = _minOdds;
        maxOdds = _maxOdds;
    }

    // ============================================================================
    // 只读函数
    // ============================================================================

    /// @inheritdoc IBasket
    function getParlay(uint256 parlayId) external view override returns (Parlay memory) {
        if (parlayId == 0 || parlayId > parlayCounter) {
            revert InvalidParlayId(parlayId);
        }
        return parlays[parlayId];
    }

    /// @inheritdoc IBasket
    function getUserParlays(address user) external view override returns (uint256[] memory) {
        return userParlays[user];
    }

    /// @inheritdoc IBasket
    function quote(ICorrelationGuard.ParlayLeg[] calldata legs, uint256 stake)
        external
        view
        override
        returns (uint256 combinedOdds, uint256 penaltyBps, uint256 potentialPayout)
    {
        // 验证腿数
        if (legs.length < MIN_LEGS || legs.length > maxLegs) {
            revert InvalidLegCount(legs.length, MIN_LEGS, maxLegs);
        }

        // 检查是否被阻断
        (bool isBlocked, string memory reason) = correlationGuard.checkBlocked(legs);
        if (isBlocked) {
            revert ParlayBlocked(reason);
        }

        // 计算组合赔率
        combinedOdds = ODDS_BASE; // 从 1.0 开始

        for (uint256 i = 0; i < legs.length; i++) {
            IMarket market = IMarket(legs[i].market);

            // 检查市场状态（必须是 Open）
            if (market.status() != IMarket.MarketStatus.Open) {
                revert InvalidMarketStatus(legs[i].market, uint8(market.status()));
            }

            // 获取该腿的赔率
            uint256 legOdds = _getMarketOdds(legs[i].market, legs[i].outcomeId);

            // 累乘赔率
            combinedOdds = (combinedOdds * legOdds) / ODDS_BASE;
        }

        // 计算相关性惩罚
        (penaltyBps,) = correlationGuard.calculatePenalty(legs);

        // 应用惩罚：finalOdds = combinedOdds * (1 - penalty)
        uint256 finalOdds = combinedOdds;
        if (penaltyBps > 0) {
            finalOdds = (combinedOdds * (ODDS_BASE - penaltyBps)) / ODDS_BASE;
        }

        // 检查赔率限制
        if (finalOdds < minOdds || finalOdds > maxOdds) {
            revert OddsOutOfBounds(finalOdds, minOdds, maxOdds);
        }

        // 计算潜在赔付
        potentialPayout = (stake * finalOdds) / ODDS_BASE;

        return (finalOdds, penaltyBps, potentialPayout);
    }

    /// @inheritdoc IBasket
    function canSettle(uint256 parlayId)
        external
        view
        override
        returns (bool, ParlayStatus)
    {
        if (parlayId == 0 || parlayId > parlayCounter) {
            revert InvalidParlayId(parlayId);
        }

        Parlay storage parlay = parlays[parlayId];

        // 已结算
        if (parlay.status != ParlayStatus.Pending) {
            return (false, parlay.status);
        }

        // 检查所有腿是否已结算
        bool allResolved = true;
        bool anyLost = false;
        bool anyCancelled = false;

        for (uint256 i = 0; i < parlay.legs.length; i++) {
            IMarket market = IMarket(parlay.legs[i].market);
            IMarket.MarketStatus marketStatus = market.status();

            // 如果市场还在 Open 或 Locked，串关无法结算
            if (marketStatus == IMarket.MarketStatus.Open || marketStatus == IMarket.MarketStatus.Locked) {
                allResolved = false;
                break;
            }

            // 如果市场已结算 (Resolved/Finalized)，检查结果
            if (marketStatus == IMarket.MarketStatus.Resolved || marketStatus == IMarket.MarketStatus.Finalized) {
                uint256 winningOutcome = market.winningOutcome();
                if (winningOutcome != parlay.legs[i].outcomeId) {
                    anyLost = true;
                }
            }

            // 处理市场取消的情况
            // 注意：当前 IMarket 枚举没有 Cancelled 状态
            // 如果未来添加 Cancelled 状态，可通过以下逻辑检测：
            // - 检查 winningOutcome 是否为特殊值（如 type(uint256).max）
            // - 或检查市场的 isPaused/isCancelled 标志
            // 当前暂时不处理（保留 anyCancelled = false）
        }

        if (!allResolved) {
            return (false, ParlayStatus.Pending);
        }

        if (anyLost) {
            return (true, ParlayStatus.Lost);
        }

        if (anyCancelled) {
            return (true, ParlayStatus.Cancelled);
        }

        return (true, ParlayStatus.Won);
    }

    // ============================================================================
    // 写入函数
    // ============================================================================

    /// @inheritdoc IBasket
    function createParlay(
        ICorrelationGuard.ParlayLeg[] calldata legs,
        uint256 stake,
        uint256 minPayout
    ) external override nonReentrant returns (uint256 parlayId) {
        // 验证输入
        if (stake == 0) {
            revert ZeroAmount();
        }

        // 获取报价
        (uint256 combinedOdds, uint256 penaltyBps, uint256 potentialPayout) =
            this.quote(legs, stake);

        // 滑点保护
        if (potentialPayout < minPayout) {
            revert SlippageExceeded(potentialPayout, minPayout);
        }

        // 转入资金到 Basket
        settlementToken.safeTransferFrom(msg.sender, address(this), stake);

        // 创建串关
        parlayCounter++;
        parlayId = parlayCounter;

        Parlay storage parlay = parlays[parlayId];
        parlay.user = msg.sender;
        parlay.stake = stake;
        parlay.potentialPayout = potentialPayout;
        parlay.combinedOdds = combinedOdds;
        parlay.penaltyBps = penaltyBps;
        parlay.status = ParlayStatus.Pending;
        parlay.createdAt = block.timestamp;
        parlay.settledAt = 0;

        // 计算每条腿的下注金额（按赔率权重分配）
        uint256[] memory legStakes = _allocateStakesToLegs(legs, stake);

        // 为每条腿下注（Basket 代表用户在各市场下注）
        for (uint256 i = 0; i < legs.length; i++) {
            IMarket market = IMarket(legs[i].market);

            // 授权市场使用资金
            settlementToken.approve(legs[i].market, legStakes[i]);

            // Basket 代表用户下注，获得头寸 Token
            uint256 shares = market.placeBet(legs[i].outcomeId, legStakes[i]);

            // 记录头寸数量（用于后续 redeem）
            parlay.legs.push(legs[i]);
            // 注意：头寸 Token (ERC-1155) 已经归 Basket 所有
        }

        // 记录用户串关
        userParlays[msg.sender].push(parlayId);

        emit ParlayCreated(
            parlayId,
            msg.sender,
            legs,
            stake,
            potentialPayout,
            combinedOdds,
            penaltyBps
        );

        return parlayId;
    }

    /// @inheritdoc IBasket
    function settleParlay(uint256 parlayId)
        external
        override
        nonReentrant
        returns (uint256 payout)
    {
        if (parlayId == 0 || parlayId > parlayCounter) {
            revert InvalidParlayId(parlayId);
        }

        Parlay storage parlay = parlays[parlayId];

        // 检查状态
        if (parlay.status != ParlayStatus.Pending) {
            revert AlreadySettled(parlayId);
        }

        // 检查是否可结算
        (bool canSettleNow, ParlayStatus finalStatus) = this.canSettle(parlayId);
        if (!canSettleNow) {
            revert NotReadyToSettle(parlayId);
        }

        // 更新状态
        parlay.status = finalStatus;
        parlay.settledAt = block.timestamp;

        // 计算赔付
        if (finalStatus == ParlayStatus.Won) {
            // 赢了：从各市场 redeem 头寸并汇总赔付
            payout = _redeemAllLegs(parlay);
            settlementToken.safeTransfer(parlay.user, payout);
        } else if (finalStatus == ParlayStatus.Cancelled) {
            // 取消：从各市场 redeem 头寸（退本金）
            payout = _redeemAllLegs(parlay);
            settlementToken.safeTransfer(parlay.user, payout);
        } else {
            // 输了：不 redeem（让 LP 保留资金）
            payout = 0;
        }

        emit ParlaySettled(parlayId, parlay.user, finalStatus, payout);

        return payout;
    }

    /// @inheritdoc IBasket
    function batchSettle(uint256[] calldata parlayIds) external override {
        for (uint256 i = 0; i < parlayIds.length; i++) {
            // 使用 try/catch 避免单个失败阻塞批量操作
            try this.settleParlay(parlayIds[i]) {} catch {}
        }
    }

    // ============================================================================
    // ERC1155 Receiver 实现
    // ============================================================================

    /// @inheritdoc IERC1155Receiver
    function onERC1155Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*id*/,
        uint256 /*value*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @inheritdoc IERC1155Receiver
    function onERC1155BatchReceived(
        address /*operator*/,
        address /*from*/,
        uint256[] calldata /*ids*/,
        uint256[] calldata /*values*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /// @inheritdoc IBasket
    function setCorrelationGuard(address newGuard) external override onlyOwner {
        require(newGuard != address(0), "Invalid guard");
        address oldGuard = address(correlationGuard);
        correlationGuard = ICorrelationGuard(newGuard);
        emit CorrelationGuardUpdated(oldGuard, newGuard);
    }

    /// @inheritdoc IBasket
    function setMaxLegs(uint256 newMax) external override onlyOwner {
        require(newMax >= MIN_LEGS, "Max legs too small");
        uint256 oldMax = maxLegs;
        maxLegs = newMax;
        emit MaxLegsUpdated(oldMax, newMax);
    }

    /// @inheritdoc IBasket
    function setOddsLimits(uint256 _minOdds, uint256 _maxOdds) external override onlyOwner {
        require(_minOdds < _maxOdds, "Invalid odds limits");
        minOdds = _minOdds;
        maxOdds = _maxOdds;
        emit OddsLimitsUpdated(_minOdds, _maxOdds);
    }

    // ============================================================================
    // 内部辅助函数
    // ============================================================================

    /**
     * @notice 获取市场的赔率
     * @param market 市场地址
     * @param outcomeId 结果ID
     * @return odds 赔率（基点）
     * @dev 调用市场的 getCurrentPrice 或类似函数
     */
    function _getMarketOdds(address market, uint256 outcomeId)
        private
        view
        returns (uint256 odds)
    {
        // 尝试调用 getCurrentPrice(uint256) 函数
        (bool success, bytes memory data) =
            market.staticcall(abi.encodeWithSignature("getCurrentPrice(uint256)", outcomeId));

        if (success && data.length >= 32) {
            uint256 price = abi.decode(data, (uint256));

            // price 是隐含概率（基点），赔率 = 10000 / price
            // 例如：price = 5000 (50%) → odds = 10000 / 5000 = 2.0 = 20000
            if (price > 0) {
                odds = (ODDS_BASE * ODDS_BASE) / price;
                return odds;
            }
        }

        // 如果失败，返回默认赔率 2.0
        return 2 * ODDS_BASE;
    }

    /**
     * @notice 将本金分配到各条腿
     * @param legs 串关腿
     * @param totalStake 总本金
     * @return legStakes 各条腿的下注金额
     * @dev 简化版：平均分配（后续可优化为按赔率权重分配）
     *
     * TODO (HIGH PRIORITY): 当前的平均分配策略会导致总赔付远超预期！
     * 问题：平均分配本金到各腿，每条腿独立赔付，总赔付 = sum(各腿赔付)
     * 但用户预期的赔付 = combinedOdds × totalStake
     *
     * 示例：2 腿串关，各赔率 2.0x，本金 1000 USDC
     * - 当前实现: 各腿 500 USDC → 各腿赔付 1000 USDC → 总计 2000 USDC
     * - 预期逻辑: 组合赔率 4.0x → 总赔付 4000 USDC ❌ 不符！
     *
     * 待选方案:
     * A. 改为池化资金模式 (Basket 独立管理资金池，不依赖 Market)
     * B. 只在一条腿下注全部本金，其他腿作为结算条件
     * C. 调整 AMM 定价逻辑，使组合赔付与各腿赔付一致
     */
    function _allocateStakesToLegs(
        ICorrelationGuard.ParlayLeg[] calldata legs,
        uint256 totalStake
    ) private pure returns (uint256[] memory legStakes) {
        uint256 legCount = legs.length;
        legStakes = new uint256[](legCount);

        // 平均分配（确保总和 = totalStake）
        uint256 baseStake = totalStake / legCount;
        uint256 remainder = totalStake % legCount;

        for (uint256 i = 0; i < legCount; i++) {
            legStakes[i] = baseStake;
            if (i < remainder) {
                legStakes[i] += 1; // 将余数分配到前几条腿
            }
        }

        return legStakes;
    }

    /**
     * @notice 从各市场 redeem 头寸并汇总赔付
     * @param parlay 串关数据
     * @return totalPayout 总赔付金额
     * @dev 查询 Basket 持有的头寸 Token (ERC-1155)，然后 redeem
     */
    function _redeemAllLegs(Parlay storage parlay)
        private
        returns (uint256 totalPayout)
    {
        totalPayout = 0;

        for (uint256 i = 0; i < parlay.legs.length; i++) {
            IMarket market = IMarket(parlay.legs[i].market);
            uint256 outcomeId = parlay.legs[i].outcomeId;

            // 查询 Basket 持有的该头寸数量（ERC-1155）
            uint256 shares = market.getUserPosition(address(this), outcomeId);

            if (shares > 0) {
                // Redeem 头寸，获得赔付
                uint256 payout = market.redeem(outcomeId, shares);
                totalPayout += payout;
            }
        }

        return totalPayout;
    }
}
