// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IMarket_V3.sol";
import "../interfaces/IPricingStrategy.sol";
import "../interfaces/IResultMapper.sol";
import "../interfaces/ILiquidityVault_V3.sol";

/**
 * @title Market_V3
 * @notice 预测市场核心容器合约
 * @dev 职责：状态机管理 + 事件发布 + 组件编排
 *
 * 核心特点：
 *      - 轻量级设计（~300 行核心逻辑）
 *      - 支持可插拔的定价策略和赛果映射器
 *      - 内置 ERC1155 头寸管理
 *      - 半输半赢支持（通过 weights）
 *
 * 权限模型：
 *      - ROUTER_ROLE：下注入口（仅 Router 可调用 placeBetFor）
 *      - KEEPER_ROLE：自动化任务（lock、finalize）
 *      - ORACLE_ROLE：预言机上报（resolve）
 *      - OPERATOR_ROLE：运营操作（cancel、参数调整）
 */
contract Market_V3 is IMarket_V3, ERC1155, AccessControl, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 角色定义 ============

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // ============ 状态变量 ============

    // 市场配置
    bytes32 public marketId;
    string public matchId;
    uint256 public kickoffTime;
    IERC20 public settlementToken;
    IPricingStrategy public pricingStrategy;
    IResultMapper public resultMapper;

    // Vault 集成
    ILiquidityVault_V3 public vault;
    uint256 public borrowedAmount;

    // outcome 规则
    OutcomeRule[] private _outcomeRules;

    // 市场状态
    MarketStatus public status;
    bytes public pricingState;
    SettlementResult public settlementResult;

    // 流动性追踪
    uint256 public totalLiquidity;
    uint256 public initialLiquidity;

    // 已赔付金额追踪（用于计算 PnL）
    uint256 public totalPayoutClaimed;

    // 每个 outcome 的统计
    mapping(uint256 => uint256) public totalSharesPerOutcome;
    mapping(uint256 => uint256) public totalBetAmountPerOutcome;

    // ============ 事件 ============

    event MarketInitialized(
        bytes32 indexed marketId,
        string matchId,
        address pricingStrategy,
        address resultMapper,
        uint256 outcomeCount
    );
    event BetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares
    );
    event MarketLocked(uint256 timestamp);
    event MarketResolved(uint256[] outcomeIds, uint256[] weights);
    event MarketFinalized(uint256 timestamp);
    event MarketCancelled(string reason);
    event PayoutClaimed(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 payout
    );
    event RefundClaimed(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 amount
    );
    event VaultSettled(uint256 principal, int256 pnl);

    // ============ 错误定义 ============

    error InvalidStatus(MarketStatus expected, MarketStatus actual);
    error InvalidOutcome(uint256 outcomeId);
    error InsufficientShares(uint256 requested, uint256 available);
    error SlippageExceeded(uint256 minShares, uint256 actualShares);
    error NotWinningOutcome(uint256 outcomeId);
    error BeforeKickoff();
    error AfterKickoff();

    // ============ 构造函数 ============

    constructor() ERC1155("") {
        _disableInitializers();
    }

    // ============ 初始化 ============

    /**
     * @notice 初始化市场
     * @param config 市场配置
     */
    function initialize(MarketConfig calldata config) external initializer {
        require(config.outcomeRules.length >= 2, "Market: Min 2 outcomes");
        require(config.outcomeRules.length <= 100, "Market: Max 100 outcomes");
        require(address(config.pricingStrategy) != address(0), "Market: Invalid pricing strategy");
        require(address(config.resultMapper) != address(0), "Market: Invalid result mapper");
        require(address(config.settlementToken) != address(0), "Market: Invalid settlement token");
        require(config.kickoffTime > block.timestamp, "Market: Kickoff must be in future");

        marketId = config.marketId;
        matchId = config.matchId;
        kickoffTime = config.kickoffTime;
        settlementToken = IERC20(config.settlementToken);
        pricingStrategy = config.pricingStrategy;
        resultMapper = config.resultMapper;
        initialLiquidity = config.initialLiquidity;

        // 复制 outcome 规则
        for (uint256 i = 0; i < config.outcomeRules.length; i++) {
            _outcomeRules.push(config.outcomeRules[i]);
        }

        // 初始化定价状态
        pricingState = pricingStrategy.getInitialState(
            config.outcomeRules.length,
            config.initialLiquidity
        );

        // 设置初始流动性
        totalLiquidity = config.initialLiquidity;

        // Vault 集成：如果配置了 Vault，从 Vault 借款
        if (config.vault != address(0) && config.initialLiquidity > 0) {
            vault = ILiquidityVault_V3(config.vault);
            borrowedAmount = config.initialLiquidity;

            // 从 Vault 借出初始流动性
            vault.borrow(config.initialLiquidity);
        }

        // 设置角色
        _grantRole(DEFAULT_ADMIN_ROLE, config.admin);
        _grantRole(OPERATOR_ROLE, config.admin);

        status = MarketStatus.Open;

        emit MarketInitialized(
            config.marketId,
            config.matchId,
            address(config.pricingStrategy),
            address(config.resultMapper),
            config.outcomeRules.length
        );
    }

    // ============ 下注 ============

    /**
     * @notice 代理下注（仅 Router 可调用）
     * @param user 下注用户
     * @param outcomeId 下注结果 ID
     * @param amount 下注金额（净金额，已扣除费用）
     * @param minShares 最小接受份额（滑点保护）
     * @return shares 获得的份额
     */
    function placeBetFor(
        address user,
        uint256 outcomeId,
        uint256 amount,
        uint256 minShares
    ) external onlyRole(ROUTER_ROLE) nonReentrant returns (uint256 shares) {
        if (status != MarketStatus.Open) {
            revert InvalidStatus(MarketStatus.Open, status);
        }
        if (block.timestamp >= kickoffTime) {
            revert AfterKickoff();
        }
        if (outcomeId >= _outcomeRules.length) {
            revert InvalidOutcome(outcomeId);
        }

        // 计算份额
        bytes memory newState;
        (shares, newState) = pricingStrategy.calculateShares(outcomeId, amount, pricingState);

        // 滑点检查
        if (shares < minShares) {
            revert SlippageExceeded(minShares, shares);
        }

        // 更新状态
        pricingState = newState;
        totalLiquidity += amount;
        totalSharesPerOutcome[outcomeId] += shares;
        totalBetAmountPerOutcome[outcomeId] += amount;

        // 铸造头寸代币
        _mint(user, outcomeId, shares, "");

        emit BetPlaced(user, outcomeId, amount, shares);
    }

    // ============ 生命周期管理 ============

    /**
     * @notice 锁盘（开赛前调用）
     */
    function lock() external onlyRole(KEEPER_ROLE) {
        if (status != MarketStatus.Open) {
            revert InvalidStatus(MarketStatus.Open, status);
        }

        status = MarketStatus.Locked;
        emit MarketLocked(block.timestamp);
    }

    /**
     * @notice 结算（预言机上报结果）
     * @param rawResult 原始赛果数据
     */
    function resolve(bytes calldata rawResult) external onlyRole(ORACLE_ROLE) {
        if (status != MarketStatus.Locked) {
            revert InvalidStatus(MarketStatus.Locked, status);
        }

        // 通过 Mapper 映射结果
        (uint256[] memory outcomeIds, uint256[] memory weights) = resultMapper.mapResult(rawResult);

        // 存储结算结果
        settlementResult.outcomeIds = outcomeIds;
        settlementResult.weights = weights;
        settlementResult.resolved = true;

        status = MarketStatus.Resolved;
        emit MarketResolved(outcomeIds, weights);
    }

    /**
     * @notice 终结市场（可领取奖金）
     * @dev 如果配置了 Vault，会计算 PnL 并结算
     */
    function finalize() external onlyRole(KEEPER_ROLE) {
        if (status != MarketStatus.Resolved) {
            revert InvalidStatus(MarketStatus.Resolved, status);
        }

        // Vault 集成：结算时归还 Vault
        if (address(vault) != address(0) && borrowedAmount > 0) {
            int256 pnl = _calculatePnL();

            // 计算需要转给 Vault 的金额
            uint256 transferAmount;
            if (pnl >= 0) {
                // LP 盈利：归还本金 + 利润
                transferAmount = borrowedAmount + uint256(pnl);
            } else {
                // LP 亏损：归还本金 - 亏损（如果够的话）
                uint256 loss = uint256(-pnl);
                transferAmount = borrowedAmount > loss ? borrowedAmount - loss : 0;
            }

            // 授权并结算
            if (transferAmount > 0) {
                settlementToken.approve(address(vault), transferAmount);
            }
            vault.settle(borrowedAmount, pnl);

            emit VaultSettled(borrowedAmount, pnl);
        }

        status = MarketStatus.Finalized;
        emit MarketFinalized(block.timestamp);
    }

    /**
     * @notice 取消市场
     * @param reason 取消原因
     * @dev 如果配置了 Vault，会归还借款本金
     */
    function cancel(string calldata reason) external onlyRole(OPERATOR_ROLE) {
        require(
            status == MarketStatus.Open || status == MarketStatus.Locked,
            "Market: Cannot cancel"
        );

        // Vault 集成：取消时归还本金
        if (address(vault) != address(0) && borrowedAmount > 0) {
            settlementToken.approve(address(vault), borrowedAmount);
            vault.returnPrincipal(borrowedAmount);
        }

        status = MarketStatus.Cancelled;
        emit MarketCancelled(reason);
    }

    // ============ 赎回 ============

    /**
     * @notice 赎回赢得的头寸
     * @param outcomeId 结果 ID
     * @param shares 份额数量
     * @return payout 获得的金额
     */
    function redeem(uint256 outcomeId, uint256 shares)
        external
        nonReentrant
        returns (uint256 payout)
    {
        if (status != MarketStatus.Finalized) {
            revert InvalidStatus(MarketStatus.Finalized, status);
        }

        // 检查是否为获胜结果
        (bool isWinner, uint256 weight) = _getOutcomeResult(outcomeId);
        if (!isWinner) {
            revert NotWinningOutcome(outcomeId);
        }

        // 检查用户余额
        uint256 balance = balanceOf(msg.sender, outcomeId);
        if (shares > balance) {
            revert InsufficientShares(shares, balance);
        }

        // 获取赔付类型
        IPricingStrategy.PayoutType payoutType = _outcomeRules[outcomeId].payoutType;

        // 构建各 outcome 总份额数组
        uint256[] memory sharesArray = new uint256[](_outcomeRules.length);
        for (uint256 i = 0; i < _outcomeRules.length; i++) {
            sharesArray[i] = totalSharesPerOutcome[i];
        }

        // 计算赔付
        uint256 basePayout = pricingStrategy.calculatePayout(
            outcomeId,
            shares,
            sharesArray,
            totalLiquidity,
            payoutType
        );

        // 应用权重（半输半赢情况）
        payout = basePayout * weight / 10000;

        // 销毁头寸
        _burn(msg.sender, outcomeId, shares);

        // 追踪已赔付金额
        totalPayoutClaimed += payout;

        // 转账
        settlementToken.safeTransfer(msg.sender, payout);

        emit PayoutClaimed(msg.sender, outcomeId, shares, payout);
    }

    /**
     * @notice 批量赎回多个结果
     * @param outcomeIds 结果 ID 数组
     * @param sharesArray 对应的份额数组
     * @return totalPayout 总获得金额
     */
    function redeemBatch(uint256[] calldata outcomeIds, uint256[] calldata sharesArray)
        external
        nonReentrant
        returns (uint256 totalPayout)
    {
        require(outcomeIds.length == sharesArray.length, "Market: Length mismatch");

        for (uint256 i = 0; i < outcomeIds.length; i++) {
            if (sharesArray[i] > 0) {
                totalPayout += _redeemInternal(outcomeIds[i], sharesArray[i]);
            }
        }
    }

    /**
     * @notice 退款（市场取消时）
     * @param outcomeId 结果 ID
     * @param shares 份额数量
     * @return amount 退款金额
     */
    function refund(uint256 outcomeId, uint256 shares)
        external
        nonReentrant
        returns (uint256 amount)
    {
        if (status != MarketStatus.Cancelled) {
            revert InvalidStatus(MarketStatus.Cancelled, status);
        }

        // 检查用户余额
        uint256 balance = balanceOf(msg.sender, outcomeId);
        if (shares > balance) {
            revert InsufficientShares(shares, balance);
        }

        // 计算退款
        amount = pricingStrategy.calculateRefund(
            outcomeId,
            shares,
            totalSharesPerOutcome[outcomeId],
            totalBetAmountPerOutcome[outcomeId]
        );

        // 销毁头寸
        _burn(msg.sender, outcomeId, shares);

        // 转账
        settlementToken.safeTransfer(msg.sender, amount);

        emit RefundClaimed(msg.sender, outcomeId, shares, amount);
    }

    // ============ 查询函数 ============

    /**
     * @notice 获取当前价格
     * @param outcomeId 结果 ID
     * @return price 价格（基点，0-10000）
     */
    function getPrice(uint256 outcomeId) external view returns (uint256 price) {
        return pricingStrategy.getPrice(outcomeId, pricingState);
    }

    /**
     * @notice 获取所有价格
     * @return prices 价格数组
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        return pricingStrategy.getAllPrices(_outcomeRules.length, pricingState);
    }

    /**
     * @notice 获取 outcome 规则
     * @return rules outcome 规则数组
     */
    function getOutcomeRules() external view returns (OutcomeRule[] memory rules) {
        return _outcomeRules;
    }

    /**
     * @notice 获取 outcome 数量
     * @return count outcome 数量
     */
    function outcomeCount() external view returns (uint256 count) {
        return _outcomeRules.length;
    }

    /**
     * @notice 获取结算结果
     * @return result 结算结果
     */
    function getSettlementResult() external view returns (SettlementResult memory result) {
        return settlementResult;
    }

    /**
     * @notice 获取市场统计（接口要求的格式）
     * @return stats 市场统计数据
     */
    function getStats() external view returns (MarketStats memory stats) {
        uint256 count = _outcomeRules.length;
        stats.totalLiquidity = totalLiquidity;
        stats.borrowedAmount = borrowedAmount;
        stats.totalBetAmount = totalLiquidity - initialLiquidity;

        stats.totalSharesPerOutcome = new uint256[](count);
        stats.totalBetPerOutcome = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            stats.totalSharesPerOutcome[i] = totalSharesPerOutcome[i];
            stats.totalBetPerOutcome[i] = totalBetAmountPerOutcome[i];
        }
    }

    /**
     * @notice 预览下注结果
     * @param outcomeId 结果 ID
     * @param amount 下注金额
     * @return shares 预计获得的份额
     * @return newPrice 下注后的新价格
     */
    function previewBet(uint256 outcomeId, uint256 amount)
        external
        view
        returns (uint256 shares, uint256 newPrice)
    {
        bytes memory newState;
        (shares, newState) = pricingStrategy.calculateShares(outcomeId, amount, pricingState);
        newPrice = pricingStrategy.getPrice(outcomeId, newState);
    }

    /**
     * @notice 获取市场统计信息（旧版兼容）
     */
    function getMarketStats()
        external
        view
        returns (
            uint256 _totalLiquidity,
            uint256 _initialLiquidity,
            uint256[] memory _sharesPerOutcome,
            uint256[] memory _betAmountPerOutcome
        )
    {
        _totalLiquidity = totalLiquidity;
        _initialLiquidity = initialLiquidity;

        uint256 count = _outcomeRules.length;
        _sharesPerOutcome = new uint256[](count);
        _betAmountPerOutcome = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            _sharesPerOutcome[i] = totalSharesPerOutcome[i];
            _betAmountPerOutcome[i] = totalBetAmountPerOutcome[i];
        }
    }

    // ============ 内部函数 ============

    /**
     * @notice 内部赎回逻辑
     */
    function _redeemInternal(uint256 outcomeId, uint256 shares) internal returns (uint256 payout) {
        if (status != MarketStatus.Finalized) {
            revert InvalidStatus(MarketStatus.Finalized, status);
        }

        (bool isWinner, uint256 weight) = _getOutcomeResult(outcomeId);
        if (!isWinner) {
            revert NotWinningOutcome(outcomeId);
        }

        uint256 balance = balanceOf(msg.sender, outcomeId);
        if (shares > balance) {
            revert InsufficientShares(shares, balance);
        }

        IPricingStrategy.PayoutType payoutType = _outcomeRules[outcomeId].payoutType;

        uint256[] memory sharesArray = new uint256[](_outcomeRules.length);
        for (uint256 i = 0; i < _outcomeRules.length; i++) {
            sharesArray[i] = totalSharesPerOutcome[i];
        }

        uint256 basePayout = pricingStrategy.calculatePayout(
            outcomeId,
            shares,
            sharesArray,
            totalLiquidity,
            payoutType
        );

        payout = basePayout * weight / 10000;

        _burn(msg.sender, outcomeId, shares);

        // 追踪已赔付金额
        totalPayoutClaimed += payout;

        settlementToken.safeTransfer(msg.sender, payout);

        emit PayoutClaimed(msg.sender, outcomeId, shares, payout);
    }

    /**
     * @notice 检查某结果是否获胜及其权重
     */
    function _getOutcomeResult(uint256 outcomeId)
        internal
        view
        returns (bool isWinner, uint256 weight)
    {
        for (uint256 i = 0; i < settlementResult.outcomeIds.length; i++) {
            if (settlementResult.outcomeIds[i] == outcomeId) {
                return (true, settlementResult.weights[i]);
            }
        }
        return (false, 0);
    }

    /**
     * @notice 计算 LP 盈亏
     * @return pnl 盈亏（正=LP赚，负=LP亏）
     * @dev PnL = 用户下注总额 - 需支付的赔付总额
     *
     * 计算逻辑：
     *   - 用户下注总额 = totalLiquidity - initialLiquidity
     *   - 需支付的赔付 = 根据获胜 outcome 和总份额计算
     *   - pnl > 0: 用户整体输钱，LP 赚
     *   - pnl < 0: 用户整体赢钱，LP 亏
     */
    function _calculatePnL() internal view returns (int256 pnl) {
        // 用户下注总额
        uint256 totalBetAmount = totalLiquidity - initialLiquidity;

        // 计算需支付的总赔付
        uint256 totalExpectedPayout = _calculateTotalExpectedPayout();

        // PnL = 收到的下注 - 支付的赔付
        if (totalBetAmount >= totalExpectedPayout) {
            pnl = int256(totalBetAmount - totalExpectedPayout);
        } else {
            pnl = -int256(totalExpectedPayout - totalBetAmount);
        }
    }

    /**
     * @notice 计算总预期赔付
     * @return totalPayout 需支付给所有获胜者的总金额
     */
    function _calculateTotalExpectedPayout() internal view returns (uint256 totalPayout) {
        // 遍历所有获胜的 outcome
        for (uint256 i = 0; i < settlementResult.outcomeIds.length; i++) {
            uint256 outcomeId = settlementResult.outcomeIds[i];
            uint256 weight = settlementResult.weights[i];

            uint256 sharesForOutcome = totalSharesPerOutcome[outcomeId];
            if (sharesForOutcome == 0) continue;

            // 获取赔付类型
            IPricingStrategy.PayoutType payoutType = _outcomeRules[outcomeId].payoutType;

            // 构建总份额数组
            uint256[] memory sharesArray = new uint256[](_outcomeRules.length);
            for (uint256 j = 0; j < _outcomeRules.length; j++) {
                sharesArray[j] = totalSharesPerOutcome[j];
            }

            // 计算该 outcome 的总赔付
            uint256 outcomePayout = pricingStrategy.calculatePayout(
                outcomeId,
                sharesForOutcome,  // 该 outcome 的所有份额
                sharesArray,
                totalLiquidity,
                payoutType
            );

            // 应用权重
            totalPayout += outcomePayout * weight / 10000;
        }
    }

    /**
     * @notice 获取当前 PnL（公开查询）
     * @return pnl 当前盈亏
     */
    function getCurrentPnL() external view returns (int256 pnl) {
        if (status != MarketStatus.Resolved && status != MarketStatus.Finalized) {
            return 0;
        }
        return _calculatePnL();
    }

    // ============ ERC1155 元数据 ============

    function uri(uint256 outcomeId) public view override returns (string memory) {
        // 返回空或实现自定义 URI 逻辑
        return "";
    }

    // ============ 接口支持 ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
