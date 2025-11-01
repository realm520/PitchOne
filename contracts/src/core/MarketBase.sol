// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IMarket.sol";
import "../interfaces/IFeeDiscountOracle.sol";
import "../interfaces/IResultOracle.sol";

/**
 * @title MarketBase
 * @notice 市场合约基类，实现核心状态机和下注/赎回逻辑
 * @dev 使用 ERC-1155 管理 position tokens，每个 outcomeId 对应一个 token ID
 *      继承 ERC1155Supply 以支持 totalSupply 追踪
 *      支持 Phase 1 折扣接口预留（Phase 0 设为 address(0)）
 */
abstract contract MarketBase is IMarket, ERC1155Supply, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ 状态变量 ============

    /// @notice 市场当前状态
    MarketStatus public override status;

    /// @notice 结果数量（如 WDL = 3，OU = 2）
    uint256 public immutable override outcomeCount;

    /// @notice 获胜结果ID（仅在 Resolved/Finalized 后有效）
    uint256 public override winningOutcome;

    /// @notice 结算币种（稳定币地址）
    IERC20 public immutable settlementToken;

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
    uint256 public immutable disputePeriod;

    /// @notice 总流动性（所有 outcome 的总金额）
    uint256 public totalLiquidity;

    /// @notice 每个 outcome 的流动性
    mapping(uint256 => uint256) public outcomeLiquidity;

    // ============ 修饰符 ============

    /// @notice 仅在指定状态下可执行
    modifier onlyStatus(MarketStatus _status) {
        require(status == _status, "MarketBase: Invalid status");
        _;
    }

    /// @notice 仅在多个状态之一下可执行
    modifier onlyStatusIn(MarketStatus _status1, MarketStatus _status2) {
        require(
            status == _status1 || status == _status2,
            "MarketBase: Invalid status"
        );
        _;
    }

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _outcomeCount 结果数量
     * @param _settlementToken 结算币种地址
     * @param _feeRecipient 费用接收地址
     * @param _feeRate 手续费率（基点）
     * @param _disputePeriod 争议期（秒）
     * @param _uri ERC-1155 元数据 URI
     */
    constructor(
        uint256 _outcomeCount,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        string memory _uri
    ) ERC1155(_uri) Ownable(msg.sender) {
        require(_outcomeCount >= 2, "MarketBase: Invalid outcome count");
        require(_settlementToken != address(0), "MarketBase: Invalid token");
        require(_feeRecipient != address(0), "MarketBase: Invalid fee recipient");
        require(_feeRate <= 1000, "MarketBase: Fee rate too high"); // 最大 10%

        outcomeCount = _outcomeCount;
        settlementToken = IERC20(_settlementToken);
        feeRecipient = _feeRecipient;
        feeRate = _feeRate;
        disputePeriod = _disputePeriod;
        status = MarketStatus.Open;
    }

    // ============ 核心函数 ============

    /**
     * @notice 下注
     * @param outcomeId 结果ID（0 到 outcomeCount-1）
     * @param amount 金额（稳定币，不含手续费）
     * @return shares 获得的份额（position token 数量）
     * @dev 1. 用户需先 approve 本合约
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
        require(outcomeId < outcomeCount, "MarketBase: Invalid outcome");
        require(amount > 0, "MarketBase: Zero amount");

        // 1. 计算手续费
        uint256 fee = calculateFee(msg.sender, amount);
        uint256 netAmount = amount - fee;

        // 2. 调用定价函数（由子合约实现）
        shares = _calculateShares(outcomeId, netAmount);
        require(shares > 0, "MarketBase: Zero shares");

        // 3. 转账
        settlementToken.safeTransferFrom(msg.sender, address(this), netAmount);
        if (fee > 0) {
            settlementToken.safeTransferFrom(msg.sender, feeRecipient, fee);
        }

        // 4. 更新状态
        outcomeLiquidity[outcomeId] += netAmount;
        totalLiquidity += netAmount;

        // 5. Mint position token
        _mint(msg.sender, outcomeId, shares, "");

        emit BetPlaced(msg.sender, outcomeId, amount, shares, fee);
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
        require(winningOutcomeId < outcomeCount, "MarketBase: Invalid outcome");

        winningOutcome = winningOutcomeId;
        status = MarketStatus.Resolved;

        emit Resolved(winningOutcomeId, block.timestamp);
    }

    /**
     * @notice 终结（争议期结束后）
     * @dev 1. 需在 Resolved 状态
     *      2. 争议期已过
     *      3. 状态变为 Finalized，不可更改
     */
    function finalize()
        external
        override
        onlyOwner
        onlyStatus(MarketStatus.Resolved)
    {
        require(
            block.timestamp >= lockTimestamp + disputePeriod,
            "MarketBase: Dispute period not ended"
        );

        status = MarketStatus.Finalized;
        emit Finalized(block.timestamp);
    }

    /**
     * @notice 赎回（用户领取奖金）
     * @param outcomeId 结果ID
     * @param shares 赎回份额
     * @return payout 赔付金额
     * @dev 1. 仅在 Resolved/Finalized 状态
     *      2. 只有获胜 outcome 可赎回
     *      3. 赔付比例 = shares / totalSupply(outcomeId) * totalLiquidity
     *      4. 按比例分配，防止早赎回耗尽流动性
     *      5. 可被子合约重写以处理特殊场景(如 OU/AH 的 Push 退款)
     */
    function redeem(uint256 outcomeId, uint256 shares)
        external
        virtual
        override
        onlyStatusIn(MarketStatus.Resolved, MarketStatus.Finalized)
        nonReentrant
        returns (uint256 payout)
    {
        require(outcomeId == winningOutcome, "MarketBase: Not winning outcome");
        require(shares > 0, "MarketBase: Zero shares");
        require(
            balanceOf(msg.sender, outcomeId) >= shares,
            "MarketBase: Insufficient balance"
        );

        // 1. 计算赔付（按比例分配）
        // payout = shares * totalLiquidity / totalSupply(winningOutcome)
        // 使用 ERC1155 内置的 totalSupply 追踪
        uint256 totalWinningShares = totalSupply(winningOutcome);
        require(totalWinningShares > 0, "MarketBase: No winning shares");

        // 防止除法精度损失，先乘后除
        payout = (shares * totalLiquidity) / totalWinningShares;
        require(payout > 0, "MarketBase: Zero payout");
        require(payout <= totalLiquidity, "MarketBase: Insufficient liquidity");

        // 2. 更新状态（遵循 CEI 模式）
        totalLiquidity -= payout;

        // 3. 销毁 position token（外部调用）
        _burn(msg.sender, outcomeId, shares);

        // 4. 转账
        settlementToken.safeTransfer(msg.sender, payout);

        emit Redeemed(msg.sender, outcomeId, shares, payout);
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
     * @dev Phase 0: discountOracle == address(0)，使用固定费率
     *      Phase 1: 查询 P1 持仓/锁仓，应用折扣（0-20%）
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

        // Phase 1: 应用折扣（优化为单次计算避免精度损失）
        uint256 discount = discountOracle.getDiscount(user);
        require(discount <= 2000, "MarketBase: Discount too high"); // 最大 20%

        // 计算折扣后的有效费率
        uint256 effectiveFeeRate = (feeRate * (10000 - discount)) / 10000;
        return (amount * effectiveFeeRate) / 10000;
    }

    // ============ 管理函数 ============

    /**
     * @notice 设置折扣预言机（Phase 1 启用）
     * @param _discountOracle 预言机地址
     */
    function setDiscountOracle(address _discountOracle) external onlyOwner {
        emit DiscountOracleUpdated(address(discountOracle), _discountOracle);
        discountOracle = IFeeDiscountOracle(_discountOracle);
    }

    /**
     * @notice 设置结果预言机
     * @param _resultOracle 预言机地址
     * @dev 必须在市场创建后、开始交易前设置
     */
    function setResultOracle(address _resultOracle) external onlyOwner {
        require(_resultOracle != address(0), "MarketBase: Invalid oracle");
        resultOracle = IResultOracle(_resultOracle);
        emit ResultOracleUpdated(_resultOracle);
    }

    /**
     * @notice 从预言机获取结果并结算
     * @dev 由预言机或 Keeper 调用
     *      1. 检查预言机已设置且结果已终结
     *      2. 获取 MatchFacts 并计算获胜结果
     *      3. 调用内部 resolve 函数
     */
    function resolveFromOracle() external onlyOwner onlyStatus(MarketStatus.Locked) {
        require(address(resultOracle) != address(0), "MarketBase: Oracle not set");

        // 获取结果
        (IResultOracle.MatchFacts memory facts, bool finalized) = resultOracle.getResult(
            bytes32(uint256(uint160(address(this)))) // 使用合约地址作为 marketId
        );
        require(finalized, "MarketBase: Result not finalized");

        // 计算获胜结果
        uint256 winningOutcomeId = _calculateWinner(facts);
        require(winningOutcomeId < outcomeCount, "MarketBase: Invalid outcome");

        // 更新状态
        winningOutcome = winningOutcomeId;
        status = MarketStatus.Resolved;

        // 获取结果哈希用于事件
        bytes32 resultHash = resultOracle.getResultHash(
            bytes32(uint256(uint160(address(this))))
        );

        emit Resolved(winningOutcomeId, block.timestamp);
        emit ResolvedWithOracle(winningOutcomeId, resultHash, block.timestamp);
    }

    /**
     * @notice 更新手续费率
     */
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= 1000, "MarketBase: Fee rate too high");
        feeRate = _feeRate;
    }

    /**
     * @notice 更新费用接收地址
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "MarketBase: Invalid address");
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice 暂停/恢复（紧急情况）
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ 抽象函数（由子合约实现）============

    /**
     * @notice 计算份额（定价函数）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     * @dev 由 WDL_Template, OU_Template 等子合约实现不同的定价逻辑
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        virtual
        returns (uint256 shares);

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 由 WDL_Template, OU_Template 等子合约实现不同的计算逻辑
     *      WDL: homeGoals vs awayGoals → 0(主胜)/1(平)/2(客胜)
     *      OU: totalGoals vs line → 0(Over)/1(Under)
     *      AH: adjustedScore vs line → 0(主胜)/1(平)/2(客胜)
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        view
        virtual
        returns (uint256 winningOutcomeId);
}
