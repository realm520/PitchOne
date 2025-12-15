// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IFeeDiscountOracle.sol";
import "../interfaces/IResultOracle.sol";
import "../interfaces/ILiquidityProvider.sol";
import "../interfaces/IFeeRouter.sol";

/**
 * @title MarketBase_V2
 * @notice 市场合约基类 V2 - 集成 LiquidityVault
 * @dev 核心改进：
 *      - 移除内部 LP 管理（addLiquidity）
 *      - 使用 LiquidityVault 提供流动性
 *      - 市场从 Vault borrow 流动性
 *      - 结算后 repay 本金+收益给 Vault
 *      - 添加紧急提款机制
 *
 * 资金流：
 *      1. 市场创建 → 从 Vault borrow 初始流动性
 *      2. 用户下注 → USDC 保留在市场合约
 *      3. 市场结算 → 计算收益，repay 给 Vault
 *      4. 用户赎回 → 从市场合约领取奖金
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
abstract contract MarketBase_V2 is IMarket, Initializable, ERC1155SupplyUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @notice 市场当前状态
    MarketStatus public override status;

    /// @notice 结果数量（如 WDL = 3，OU = 2）
    uint256 public override outcomeCount;

    /// @notice 获胜结果ID（仅在 Resolved/Finalized 后有效）
    uint256 public override winningOutcome;

    /// @notice 结算币种（稳定币地址）
    IERC20 public settlementToken;

    /// @notice 基础手续费率（基点，默认 200 = 2%）
    uint256 public feeRate;

    /// @notice 费用折扣预言机（Phase 0: address(0), Phase 1: P1FeeDiscountOracle）
    IFeeDiscountOracle public discountOracle;

    /// @notice 结果预言机（用于获取比赛结果）
    IResultOracle public resultOracle;

    /// @notice 费用接收地址（FeeRouter）
    address public feeRecipient;

    /// @notice 锁盘时间（用于争议期计算）
    uint256 public lockTimestamp;

    /// @notice 争议期时长（秒，默认 24 小时）
    uint256 public disputePeriod;

    /// @notice 开球时间（由子合约设置，用于自动锁盘）
    uint256 public kickoffTime;

    // ============ Vault 集成新增 ============

    /// @notice 流动性提供者接口
    ILiquidityProvider public liquidityProvider;

    /// @notice 从 Vault 借出的金额
    uint256 public borrowedAmount;

    /// @notice 市场总流动性（用户下注 + Vault 借出）
    uint256 public totalLiquidity;

    /// @notice 是否已从 Vault 借出流动性
    bool public liquidityBorrowed;

    /// @notice 是否已归还流动性给 Vault
    bool public liquidityRepaid;

    // ============ Router 集成 ============

    /// @notice 受信任的投注路由合约（可代替用户下注）
    address public trustedRouter;

    // ============ 事件 ============

    /// @notice 从 Vault 借出流动性
    event LiquidityBorrowed(uint256 amount, uint256 timestamp);

    /// @notice Vault 借款失败（降级为 Parimutuel 模式）
    event BorrowFailed(uint256 requestedAmount, string reason);

    /// @notice 归还流动性给 Vault
    event LiquidityRepaid(uint256 principal, uint256 revenue, uint256 timestamp);

    /// @notice 紧急提款事件
    event EmergencyUserWithdrawal(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 amount,
        address indexed admin
    );

    /// @notice 手续费率更新
    event FeeRateUpdated(uint256 oldRate, uint256 newRate);

    /// @notice 费用接收地址更新
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    /// @notice 开球时间更新事件
    event KickoffTimeUpdated(uint256 oldKickoffTime, uint256 newKickoffTime, uint256 timestamp);

    /// @notice 受信任路由更新事件
    event TrustedRouterUpdated(address indexed oldRouter, address indexed newRouter);

    // ============ 修饰符 ============

    /// @notice 仅在指定状态下可执行
    modifier onlyStatus(MarketStatus _status) {
        require(status == _status, "MarketBase_V2: Invalid status");
        _;
    }

    /// @notice 仅在多个状态之一下可执行
    modifier onlyStatusIn(MarketStatus _status1, MarketStatus _status2) {
        require(
            status == _status1 || status == _status2,
            "MarketBase_V2: Invalid status"
        );
        _;
    }

    // ============ 构造函数和初始化 ============

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 注意：不调用 _disableInitializers() 以允许在测试中直接实例化
        // initializer 修饰符已经足够防止重复初始化
    }

    /**
     * @notice 初始化函数（替代构造函数）
     * @param _outcomeCount 结果数量
     * @param _settlementToken 结算币种地址
     * @param _feeRecipient 费用接收地址
     * @param _feeRate 手续费率（基点）
     * @param _disputePeriod 争议期（秒）
     * @param _liquidityProvider 流动性提供者地址
     * @param _uri ERC-1155 元数据 URI
     */
    function __MarketBase_init(
        uint256 _outcomeCount,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _liquidityProvider,
        string memory _uri
    ) internal onlyInitializing {
        __ERC1155_init(_uri);
        __Ownable_init(msg.sender);
        __Pausable_init();

        require(_outcomeCount >= 2, "MarketBase_V2: Invalid outcome count");
        require(_settlementToken != address(0), "MarketBase_V2: Invalid token");
        require(_feeRecipient != address(0), "MarketBase_V2: Invalid fee recipient");
        require(_feeRate <= 1000, "MarketBase_V2: Fee rate too high"); // 最大 10%
        require(_liquidityProvider != address(0), "MarketBase_V2: Invalid liquidity provider");

        outcomeCount = _outcomeCount;
        settlementToken = IERC20(_settlementToken);
        feeRecipient = _feeRecipient;
        feeRate = _feeRate;
        disputePeriod = _disputePeriod;
        liquidityProvider = ILiquidityProvider(_liquidityProvider);
        status = MarketStatus.Open;
    }

    // ============ 核心函数 ============

    /**
     * @notice 下注
     * @param outcomeId 结果ID（0 到 outcomeCount-1）
     * @param amount 金额（稳定币，不含手续费）
     * @return shares 获得的份额（position token 数量）
     * @dev 1. 首次下注时从 Vault 借出初始流动性
     *      2. 计算手续费（考虑折扣）
     *      3. 调用子合约的定价函数计算 shares
     *      4. 转账 + mint token
     */
    function placeBet(uint256 outcomeId, uint256 amount)
        external
        override
        onlyStatus(MarketStatus.Open)
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        return _placeBetWithSlippage(outcomeId, amount, 10000); // 默认无滑点限制
    }

    /**
     * @notice 下注（带滑点保护）
     * @param outcomeId 结果ID
     * @param amount 金额（稳定币，不含手续费）
     * @param maxSlippageBps 最大滑点（基点，例如 500 = 5%）
     * @return shares 获得的份额
     * @dev 滑点计算：
     *      effectivePrice = amount / shares
     *      expectedPrice = getPrice(outcomeId) (交易前价格)
     *      slippage = (effectivePrice - expectedPrice) / expectedPrice
     */
    function placeBetWithSlippage(uint256 outcomeId, uint256 amount, uint256 maxSlippageBps)
        external
        onlyStatus(MarketStatus.Open)
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        require(maxSlippageBps <= 10000, "MarketBase_V2: Invalid slippage limit");
        return _placeBetWithSlippage(outcomeId, amount, maxSlippageBps);
    }

    // ============ 代理下注函数（Router 使用）============

    /**
     * @notice 代理下注（由受信任的 Router 调用）
     * @param user 实际下注用户地址
     * @param outcomeId 结果ID
     * @param amount 金额
     * @return shares 获得的份额
     * @dev 仅允许 trustedRouter 调用
     *      资金从 Router 转入（Router 已从用户收取）
     *      Position token mint 给实际用户
     */
    function placeBetFor(address user, uint256 outcomeId, uint256 amount)
        external
        onlyStatus(MarketStatus.Open)
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        require(msg.sender == trustedRouter, "MarketBase_V2: Not trusted router");
        return _placeBetForWithSlippage(user, outcomeId, amount, 10000);
    }

    /**
     * @notice 代理下注（带滑点保护）
     * @param user 实际下注用户地址
     * @param outcomeId 结果ID
     * @param amount 金额
     * @param maxSlippageBps 最大滑点（基点）
     * @return shares 获得的份额
     */
    function placeBetForWithSlippage(address user, uint256 outcomeId, uint256 amount, uint256 maxSlippageBps)
        external
        onlyStatus(MarketStatus.Open)
        whenNotPaused
        nonReentrant
        returns (uint256 shares)
    {
        require(msg.sender == trustedRouter, "MarketBase_V2: Not trusted router");
        require(maxSlippageBps <= 10000, "MarketBase_V2: Invalid slippage limit");
        return _placeBetForWithSlippage(user, outcomeId, amount, maxSlippageBps);
    }

    /**
     * @notice 内部代理下注实现
     * @param user 实际下注用户
     * @param outcomeId 结果ID
     * @param amount 金额
     * @param maxSlippageBps 最大滑点
     */
    function _placeBetForWithSlippage(address user, uint256 outcomeId, uint256 amount, uint256 maxSlippageBps)
        internal
        returns (uint256 shares)
    {
        require(user != address(0), "MarketBase_V2: Invalid user");
        require(outcomeId < outcomeCount, "MarketBase_V2: Invalid outcome");
        require(amount > 0, "MarketBase_V2: Zero amount");

        // 时间检查
        require(kickoffTime == 0 || block.timestamp < kickoffTime, "MarketBase_V2: Betting closed");

        // 首次下注时从 Vault 借出流动性
        if (!liquidityBorrowed) {
            _borrowInitialLiquidity();
        }

        // 1. 计算手续费（使用实际用户的折扣）
        uint256 fee = calculateFee(user, amount);
        uint256 netAmount = amount - fee;

        // 2. 调用定价函数
        shares = _calculateShares(outcomeId, netAmount);
        require(shares > 0, "MarketBase_V2: Zero shares");

        // 3. 滑点检查
        if (maxSlippageBps < 10000) {
            _checkSlippage(netAmount, shares, maxSlippageBps);
        }

        // 4. 从 Router 转账（Router 已持有用户的资金）
        settlementToken.safeTransferFrom(msg.sender, address(this), netAmount);
        if (fee > 0) {
            settlementToken.safeTransferFrom(msg.sender, address(this), fee);
            settlementToken.approve(feeRecipient, fee);
            // 费用追踪使用实际用户地址
            IFeeRouter(feeRecipient).routeFee(address(settlementToken), user, fee, amount);
        }

        // 5. 更新流动性
        totalLiquidity += netAmount;

        // 6. Mint position token 给实际用户
        _mint(user, outcomeId, shares, "");

        emit BetPlaced(user, outcomeId, amount, shares, fee);
    }

    /**
     * @notice 内部下注实现（带滑点保护）
     */
    function _placeBetWithSlippage(uint256 outcomeId, uint256 amount, uint256 maxSlippageBps)
        internal
        returns (uint256 shares)
    {
        // 强制要求：市场必须配置 trustedRouter 才能接受下注
        require(trustedRouter != address(0), "MarketBase_V2: Router not configured");
        require(outcomeId < outcomeCount, "MarketBase_V2: Invalid outcome");
        require(amount > 0, "MarketBase_V2: Zero amount");

        // 时间检查：如果已过开球时间，拒绝下注（但不改变市场状态）
        require(kickoffTime == 0 || block.timestamp < kickoffTime, "MarketBase_V2: Betting closed, kickoff time reached");

        // 首次下注时从 Vault 借出流动性
        if (!liquidityBorrowed) {
            _borrowInitialLiquidity();
        }

        // 1. 计算手续费
        uint256 fee = calculateFee(msg.sender, amount);
        uint256 netAmount = amount - fee;

        // 2. 调用定价函数（由子合约实现）
        shares = _calculateShares(outcomeId, netAmount);
        require(shares > 0, "MarketBase_V2: Zero shares");

        // 3. 滑点检查
        if (maxSlippageBps < 10000) {
            _checkSlippage(netAmount, shares, maxSlippageBps);
        }

        // 4. 转账
        settlementToken.safeTransferFrom(msg.sender, address(this), netAmount);
        if (fee > 0) {
            // 先将手续费转给合约自己，然后调用 FeeRouter.routeFee()
            settlementToken.safeTransferFrom(msg.sender, address(this), fee);

            // 授权 FeeRouter 提取手续费
            settlementToken.approve(feeRecipient, fee);

            // 调用 FeeRouter 处理返佣和分配（传递下注总金额用于追踪交易量）
            IFeeRouter(feeRecipient).routeFee(address(settlementToken), msg.sender, fee, amount);
        }

        // 5. 更新流动性（用户下注金额）
        totalLiquidity += netAmount;

        // 6. Mint position token
        _mint(msg.sender, outcomeId, shares, "");

        emit BetPlaced(msg.sender, outcomeId, amount, shares, fee);
    }

    /**
     * @notice 检查滑点
     * @param amount 支付金额
     * @param shares 获得份额
     * @param maxSlippageBps 最大滑点（基点）
     */
    function _checkSlippage(uint256 amount, uint256 shares, uint256 maxSlippageBps) internal pure {
        // 有效价格 = amount / shares（用户支付了多少才得到1个share）
        // 如果有效价格过高，说明滑点过大
        // 最小可接受 shares = amount / (1 + maxSlippage)
        uint256 minAcceptableShares = (amount * 10000) / (10000 + maxSlippageBps);
        require(shares >= minAcceptableShares, "MarketBase_V2: Slippage too high");
    }

    /**
     * @notice 锁盘（管理员/Keeper 调用）
     * @dev 比赛开始时调用，禁止新的下注
     */
    function lock()
        external
        override
        onlyOwner
        onlyStatus(MarketStatus.Open)
    {
        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }

    /**
     * @notice 更新开赛时间（仅 owner）
     * @param newKickoffTime 新的开赛时间戳
     * @dev 只有 owner 可以修改开赛时间
     */
    function updateKickoffTime(uint256 newKickoffTime) external onlyOwner {
        require(newKickoffTime > block.timestamp, "MarketBase_V2: Kickoff time must be in future");

        uint256 oldKickoffTime = kickoffTime;
        kickoffTime = newKickoffTime;

        emit KickoffTimeUpdated(oldKickoffTime, newKickoffTime, block.timestamp);
    }

    /**
     * @notice 查询距离开赛的剩余时间
     * @return timeUntilKickoff 距离开球的剩余时间（秒），如果已过开球返回 0
     * @return canBet 是否可以下注
     */
    function getTimeUntilKickoff() external view returns (uint256 timeUntilKickoff, bool canBet) {
        if (kickoffTime == 0) {
            return (0, true); // 没有设置开赛时间，可以一直下注
        }

        if (block.timestamp >= kickoffTime) {
            return (0, false); // 已过开赛时间，不能下注
        }

        return (kickoffTime - block.timestamp, true); // 返回剩余时间和可下注状态
    }

    /**
     * @notice 查询市场是否已到达"锁定"状态（基于时间）
     * @return _isLocked 是否已锁定（当前时间 >= 开赛时间）
     * @dev 这是一个查询函数，用于判断当前区块时间是否已到达或超过开赛时间
     *      不会改变合约状态，仅用于前端显示和判断
     */
    function isLocked() external view returns (bool _isLocked) {
        // 如果未设置开赛时间，永不锁定
        if (kickoffTime == 0) {
            return false;
        }

        // 当前时间 >= 开赛时间，视为锁定
        return block.timestamp >= kickoffTime;
    }

    /**
     * @notice 结算（预言机上报结果）
     * @param winningOutcomeId 获胜结果ID
     * @dev 1. 需在 Locked 状态
     *      2. 记录获胜结果
     *      3. 进入争议期
     */
    function resolve(uint256 winningOutcomeId)
        external
        override
        onlyOwner
        onlyStatus(MarketStatus.Locked)
    {
        require(winningOutcomeId < outcomeCount, "MarketBase_V2: Invalid outcome");

        winningOutcome = winningOutcomeId;
        status = MarketStatus.Resolved;

        emit Resolved(winningOutcomeId, block.timestamp);
    }

    /**
     * @notice 终结（争议期结束后）
     * @dev 1. 需在 Resolved 状态
     *      2. 争议期已过
     *      3. 归还流动性给 Vault
     */
    function finalize()
        external
        override
        onlyOwner
        onlyStatus(MarketStatus.Resolved)
    {
        require(
            block.timestamp >= lockTimestamp + disputePeriod,
            "MarketBase_V2: Dispute period not ended"
        );

        status = MarketStatus.Finalized;

        // 归还流动性给 Vault（如果尚未归还）
        // 注意：finalize时只归还本金，收益部分留给赢家分配
        if (liquidityBorrowed && !liquidityRepaid) {
            _repayPrincipalOnly();
        }

        emit Finalized(block.timestamp);
    }

    /**
     * @notice 取消市场（比赛取消/无效）
     * @param reason 取消原因
     * @dev 1. 仅允许从 Open 或 Locked 状态取消
     *      2. 归还 Vault 本金
     *      3. 用户可通过 refund() 领取退款
     */
    function cancel(string calldata reason)
        external
        override
        onlyOwner
        nonReentrant
    {
        require(
            status == MarketStatus.Open || status == MarketStatus.Locked,
            "MarketBase_V2: Cannot cancel in current status"
        );

        status = MarketStatus.Cancelled;

        // 归还 Vault 本金（如果已借出且未归还）
        if (liquidityBorrowed && !liquidityRepaid) {
            _repayPrincipalOnly();
        }

        emit Cancelled(reason, block.timestamp);
    }

    /**
     * @notice 退款（用户领取退款，仅 Cancelled 状态）
     * @param outcomeId 结果ID
     * @param shares 份额
     * @return amount 退款金额
     * @dev 按用户投入比例退款：amount = shares * distributableLiquidity / totalAllShares
     */
    function refund(uint256 outcomeId, uint256 shares)
        external
        override
        onlyStatus(MarketStatus.Cancelled)
        nonReentrant
        returns (uint256 amount)
    {
        require(shares > 0, "MarketBase_V2: Zero shares");
        require(
            balanceOf(msg.sender, outcomeId) >= shares,
            "MarketBase_V2: Insufficient balance"
        );

        // 计算所有 outcome 的总 shares
        uint256 totalAllShares = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            totalAllShares += totalSupply(i);
        }
        require(totalAllShares > 0, "MarketBase_V2: No shares in market");

        // 计算可分配流动性（已扣除 Vault 本金）
        uint256 distributableLiquidity;
        if (liquidityBorrowed && liquidityRepaid) {
            // 本金已归还，使用当前余额
            distributableLiquidity = settlementToken.balanceOf(address(this));
        } else if (liquidityBorrowed && !liquidityRepaid) {
            // 本金未归还（异常情况），扣除借款金额
            distributableLiquidity = totalLiquidity > borrowedAmount
                ? totalLiquidity - borrowedAmount
                : 0;
        } else {
            // 未从 Vault 借款
            distributableLiquidity = totalLiquidity;
        }

        // 按比例计算退款金额
        amount = (shares * distributableLiquidity) / totalAllShares;
        require(amount > 0, "MarketBase_V2: Zero refund amount");

        // 更新状态（CEI 模式）
        totalLiquidity -= amount;

        // 销毁份额
        _burn(msg.sender, outcomeId, shares);

        // 转账
        settlementToken.safeTransfer(msg.sender, amount);

        emit Refunded(msg.sender, outcomeId, shares, amount);

        // 检查是否所有用户都已退款，归还剩余流动性给 Vault
        bool allRefunded = true;
        for (uint256 i = 0; i < outcomeCount; i++) {
            if (totalSupply(i) > 0) {
                allRefunded = false;
                break;
            }
        }
        if (allRefunded && liquidityBorrowed && !liquidityRepaid) {
            _repayToVault();
        }
    }

    /**
     * @notice 赎回（用户领取奖金）
     * @param outcomeId 结果ID
     * @param shares 赎回份额
     * @return payout 赔付金额
     * @dev 1. 仅在 Resolved/Finalized 状态
     *      2. 只有获胜 outcome 可赎回
     *      3. 赔付比例 = shares / totalSupply(outcomeId) * totalLiquidity
     */
    function redeem(uint256 outcomeId, uint256 shares)
        external
        virtual
        override
        onlyStatusIn(MarketStatus.Resolved, MarketStatus.Finalized)
        nonReentrant
        returns (uint256 payout)
    {
        require(shares > 0, "MarketBase_V2: Zero shares");
        require(
            balanceOf(msg.sender, outcomeId) >= shares,
            "MarketBase_V2: Insufficient balance"
        );

        // 检测是否为 Push 退款场景
        bool isPushRefund = _isPushOutcome(winningOutcome);

        if (!isPushRefund) {
            // 常规赢家赔付逻辑：仅允许中奖结果赎回
            require(outcomeId == winningOutcome, "MarketBase_V2: Not winning outcome");
        }

        // 1. 计算赔付
        if (isPushRefund) {
            // Push 退款：所有用户按 1:1 比例退回本金
            payout = _calculatePushRefund(outcomeId, shares);
        } else {
            // 常规赔付：按获胜份额比例分配总流动性
            payout = _calculateNormalPayout(shares);
        }

        require(payout > 0, "MarketBase_V2: Zero payout");

        // 2. 更新状态（遵循 CEI 模式）
        totalLiquidity -= payout;

        // 3. 销毁 position token
        _burn(msg.sender, outcomeId, shares);

        // 4. 转账
        settlementToken.safeTransfer(msg.sender, payout);

        emit Redeemed(msg.sender, outcomeId, shares, payout);

        // 5. 如果所有用户都赎回完毕，归还剩余流动性给 Vault
        if (isPushRefund) {
            // Push 场景：检查所有 outcome 的总份额是否为 0
            bool allRedeemed = true;
            for (uint256 i = 0; i < outcomeCount; i++) {
                if (totalSupply(i) > 0) {
                    allRedeemed = false;
                    break;
                }
            }
            if (allRedeemed && !liquidityRepaid) {
                _repayToVault();
            }
        } else {
            // 常规场景：检查获胜 outcome 份额是否为 0
            if (totalSupply(winningOutcome) == 0 && !liquidityRepaid) {
                _repayToVault();
            }
        }
    }

    /**
     * @dev 判断是否为 Push 退款结果（outcomeId == 2 且市场支持 Push）
     */
    function _isPushOutcome(uint256 outcome) internal view returns (bool) {
        // Push 通常定义为 outcomeId == 2，且市场至少有 3 个结果
        return outcome == 2 && outcomeCount >= 3;
    }

    /**
     * @dev 计算 Push 退款金额（1:1 退回用户投入本金）
     * @param outcomeId 用户持有的 outcome
     * @param shares 用户持有的份额
     * @return refund 退款金额
     */
    function _calculatePushRefund(uint256 outcomeId, uint256 shares) internal view returns (uint256 refund) {
        // Push 退款逻辑：
        // 在 Push 场景下，AMM 中所有 outcome 的价值应该相等（因为没有赢家）
        // 由于市场使用 ERC1155，shares 代表用户持有的头寸数量
        // 在 CPMM 中，1 share ≈ 1 USDC 的价值（初始状态）

        uint256 totalOutcomeShares = totalSupply(outcomeId);
        require(totalOutcomeShares > 0, "MarketBase_V2: No shares for outcome");

        // 计算所有 outcome 的总 shares
        uint256 totalAllShares = 0;
        for (uint256 i = 0; i < outcomeCount; i++) {
            totalAllShares += totalSupply(i);
        }
        require(totalAllShares > 0, "MarketBase_V2: No shares in market");

        // 计算可分配流动性（与常规逻辑相同）
        uint256 distributableLiquidity;
        if (liquidityBorrowed && !liquidityRepaid) {
            distributableLiquidity = totalLiquidity > borrowedAmount
                ? totalLiquidity - borrowedAmount
                : 0;
        } else if (liquidityBorrowed && liquidityRepaid) {
            uint256 currentBalance = settlementToken.balanceOf(address(this));
            distributableLiquidity = currentBalance;
        } else {
            distributableLiquidity = totalLiquidity;
        }

        // Push 退款：按用户份额占总份额的比例退回
        // 这确保了所有用户按其持仓比例获得退款，总和等于 totalLiquidity
        refund = (shares * distributableLiquidity) / totalAllShares;

        require(refund <= distributableLiquidity, "MarketBase_V2: Insufficient liquidity");
    }

    /**
     * @dev 计算常规赢家赔付金额（按获胜份额比例分配总流动性）
     * @param shares 用户持有的获胜份额
     * @return payout 赔付金额
     */
    function _calculateNormalPayout(uint256 shares) internal view returns (uint256 payout) {
        uint256 totalWinningShares = totalSupply(winningOutcome);
        require(totalWinningShares > 0, "MarketBase_V2: No winning shares");

        // 计算可分配给用户的流动性
        uint256 distributableLiquidity;
        if (liquidityBorrowed && !liquidityRepaid) {
            // 如果还未归还Vault本金，需要保留借款金额
            distributableLiquidity = totalLiquidity > borrowedAmount
                ? totalLiquidity - borrowedAmount
                : 0;
        } else if (liquidityBorrowed && liquidityRepaid) {
            // 如果已归还本金（通过finalize），可分配的是当前实际余额
            // 因为totalLiquidity没有减去已归还的本金，所以用实际余额
            uint256 currentBalance = settlementToken.balanceOf(address(this));
            distributableLiquidity = currentBalance;
        } else {
            // 没有从Vault借款的情况
            distributableLiquidity = totalLiquidity;
        }

        payout = (shares * distributableLiquidity) / totalWinningShares;
        require(payout <= distributableLiquidity, "MarketBase_V2: Insufficient liquidity");
    }

    // ============ Vault 集成函数 ============

    /**
     * @notice 从 Vault 借出初始流动性
     * @dev 由 placeBet() 在首次下注时自动调用
     *      子合约必须实现 _getInitialBorrowAmount() 返回需要借出的金额
     *      如果返回 0（Parimutuel 模式），跳过借款但标记为已借（避免重复调用）
     */
    function _borrowInitialLiquidity() internal virtual {
        require(!liquidityBorrowed, "MarketBase_V2: Already borrowed");

        uint256 amount = _getInitialBorrowAmount();

        // Parimutuel 模式：amount = 0，不需要初始流动性
        if (amount == 0) {
            liquidityBorrowed = true; // 标记为已借，避免重复调用
            emit LiquidityBorrowed(0, block.timestamp); // 记录事件（金额为 0）
            return;
        }

        // CPMM 模式：从流动性提供者借出（带失败保护）
        try liquidityProvider.borrow(amount) {
            // 借款成功
            borrowedAmount = amount;
            totalLiquidity = amount; // 初始流动性仅来自 Vault
            liquidityBorrowed = true;

            emit LiquidityBorrowed(amount, block.timestamp);
        } catch Error(string memory reason) {
            // 借款失败：降级为 Parimutuel 模式
            emit BorrowFailed(amount, reason);

            liquidityBorrowed = true; // 标记为已尝试借款，避免重复调用
            emit LiquidityBorrowed(0, block.timestamp); // 记录事件（金额为 0）

            // 继续执行，用户资金仍可正常下注（纯 Parimutuel 模式）
        } catch (bytes memory lowLevelData) {
            // 低级别错误（如 revert 无 reason）
            emit BorrowFailed(amount, "Low-level borrow failed");

            liquidityBorrowed = true; // 标记为已尝试借款
            emit LiquidityBorrowed(0, block.timestamp);
        }
    }

    /**
     * @notice 只归还本金给 Vault（用于 finalize）
     * @dev finalize时调用，只归还本金，收益留给赢家
     */
    function _repayPrincipalOnly() internal virtual {
        require(liquidityBorrowed, "MarketBase_V2: Not borrowed");
        require(!liquidityRepaid, "MarketBase_V2: Already repaid");

        uint256 currentBalance = settlementToken.balanceOf(address(this));

        // 只归还本金，不归还收益
        uint256 principal = currentBalance < borrowedAmount ? currentBalance : borrowedAmount;

        if (principal > 0) {
            // 授权流动性提供者扣款
            settlementToken.approve(address(liquidityProvider), principal);

            // 归还给流动性提供者（revenue = 0）
            liquidityProvider.repay(principal, 0);
        }

        liquidityRepaid = true;

        emit LiquidityRepaid(principal, 0, block.timestamp);
    }

    /**
     * @notice 归还流动性给 Vault（本金+收益）
     * @dev 由 redeem() 在最后一个用户赎回时调用
     *      归还剩余的全部余额（本金+收益）
     */
    function _repayToVault() internal virtual {
        require(liquidityBorrowed, "MarketBase_V2: Not borrowed");
        require(!liquidityRepaid, "MarketBase_V2: Already repaid");

        uint256 currentBalance = settlementToken.balanceOf(address(this));

        // 计算实际可归还的本金和收益
        // 如果余额不足borrowedAmount，说明部分资金已被用户赎回，只归还实际余额
        uint256 principal = currentBalance < borrowedAmount ? currentBalance : borrowedAmount;
        uint256 revenue = currentBalance > borrowedAmount ? currentBalance - borrowedAmount : 0;

        // 只有在有资金可归还时才执行
        if (principal > 0 || revenue > 0) {
            uint256 totalRepayment = principal + revenue;

            // 授权流动性提供者扣款
            settlementToken.approve(address(liquidityProvider), totalRepayment);

            // 归还给流动性提供者
            liquidityProvider.repay(principal, revenue);
        }

        liquidityRepaid = true;

        emit LiquidityRepaid(principal, revenue, block.timestamp);
    }

    /**
     * @notice 获取初始借款金额（由子合约实现）
     * @dev 不同市场类型需要不同的初始流动性
     *      例如：WDL 可能需要 100k，OU 可能需要 50k
     */
    function _getInitialBorrowAmount() internal view virtual returns (uint256);

    // ============ 紧急提款 ============

    /**
     * @notice 紧急提取用户资金（仅管理员，极端情况）
     * @param user 用户地址
     * @param outcomeId 结果ID
     * @param shares 份额
     * @dev 紧急情况下使用（如市场故障、预言机失败等）
     *      计算用户应得金额并直接转账
     *      注意：这会绕过正常的赎回流程
     */
    function emergencyWithdrawUser(address user, uint256 outcomeId, uint256 shares)
        external
        onlyOwner
        nonReentrant
    {
        require(shares > 0, "MarketBase_V2: Zero shares");
        require(
            balanceOf(user, outcomeId) >= shares,
            "MarketBase_V2: Insufficient balance"
        );

        // 计算应退金额（简化版：按总流动性比例）
        uint256 totalShares = totalSupply(outcomeId);
        require(totalShares > 0, "MarketBase_V2: No shares");

        uint256 refundAmount = (shares * totalLiquidity) / totalShares;
        require(refundAmount > 0, "MarketBase_V2: Zero refund");
        require(refundAmount <= totalLiquidity, "MarketBase_V2: Insufficient liquidity");

        // 更新状态
        totalLiquidity -= refundAmount;

        // 销毁份额
        _burn(user, outcomeId, shares);

        // 转账
        settlementToken.safeTransfer(user, refundAmount);

        emit EmergencyUserWithdrawal(user, outcomeId, shares, refundAmount, msg.sender);
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取用户持仓
     */
    function getUserPosition(address user, uint256 outcomeId)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(user, outcomeId);
    }

    /**
     * @notice 计算手续费（考虑折扣）
     * @param user 用户地址
     * @param amount 金额
     * @return fee 手续费
     */
    function calculateFee(address user, uint256 amount)
        public
        view
        override
        returns (uint256 fee)
    {
        // Phase 0: 无折扣
        if (address(discountOracle) == address(0)) {
            return (amount * feeRate) / 10000;
        }

        // Phase 1: 应用折扣
        uint256 discount = discountOracle.getDiscount(user);
        require(discount <= 2000, "MarketBase_V2: Discount too high"); // 最大 20%

        return (amount * feeRate * (10000 - discount)) / 100_000_000;
    }

    // ============ 管理函数 ============

    /**
     * @notice 设置折扣预言机
     */
    function setDiscountOracle(address _discountOracle) external onlyOwner {
        emit DiscountOracleUpdated(address(discountOracle), _discountOracle);
        discountOracle = IFeeDiscountOracle(_discountOracle);
    }

    /**
     * @notice 设置结果预言机
     */
    function setResultOracle(address _resultOracle) external onlyOwner {
        require(_resultOracle != address(0), "MarketBase_V2: Invalid oracle");
        resultOracle = IResultOracle(_resultOracle);
        emit ResultOracleUpdated(_resultOracle);
    }

    /**
     * @notice 更新手续费率
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "MarketBase_V2: Fee rate too high");
        emit FeeRateUpdated(feeRate, _feeRate);
        feeRate = _feeRate;
    }

    /**
     * @notice 更新费用接收地址
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "MarketBase_V2: Invalid recipient");
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice 设置受信任的投注路由
     * @param _router 路由合约地址（可以为 address(0) 以禁用）
     */
    function setTrustedRouter(address _router) external onlyOwner {
        emit TrustedRouterUpdated(trustedRouter, _router);
        trustedRouter = _router;
    }

    /**
     * @notice 暂停/恢复市场
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 废弃函数（V2 不再支持）============

    /**
     * @notice 添加流动性（V2 已废弃）
     * @dev V2 版本使用 LiquidityVault，不再支持直接添加流动性
     *      此函数仅为保持 IMarket 接口兼容性
     */
    function addLiquidity(uint256, uint256[] calldata) external pure override {
        revert("MarketBase_V2: Use LiquidityVault instead");
    }

    // ============ 抽象函数（子合约必须实现）============

    /**
     * @notice 计算份额（由子合约实现）
     * @param outcomeId 结果ID
     * @param netAmount 净金额（已扣除手续费）
     * @return shares 获得的份额
     */
    function _calculateShares(uint256 outcomeId, uint256 netAmount)
        internal
        virtual
        returns (uint256 shares);
}
