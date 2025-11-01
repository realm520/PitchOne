// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OU_Template
 * @notice 大小球（Over/Under）市场模板 - 单线版本
 * @dev 三向市场：大球（Over）、小球（Under）、退款（Push）
 *      使用 CPMM 定价引擎（仅 Over/Under 两向定价，Push 不参与）
 *
 * Outcome IDs:
 * - 0: 大球 (Over) - 总进球数 > line
 * - 1: 小球 (Under) - 总进球数 < line
 * - 2: 退款 (Push) - 总进球数 == line (仅整数盘)
 *
 * 示例：
 * - 曼联 vs 曼城，盘口 2.5 球 (半球盘)
 *   - outcomeId 0 = 大2.5球（总进球 ≥ 3）
 *   - outcomeId 1 = 小2.5球（总进球 ≤ 2）
 *
 * - 曼联 vs 曼城，盘口 2.0 球 (整数盘)
 *   - outcomeId 0 = 大2.0球（总进球 ≥ 3）
 *   - outcomeId 1 = 小2.0球（总进球 ≤ 1）
 *   - outcomeId 2 = Push（总进球 = 2，全额退款）
 *
 * 注意：
 * - line 使用千分位表示（2.5球 = 2500，3.0球 = 3000）
 * - 整数盘（如2.0球）在总进球等于盘口时退款 (outcome=2)
 * - Push 不参与 AMM 定价，兑付时按 1:1 退还本金
 * - M1阶段仅支持单线，M2阶段扩展到多线联动
 */
contract OU_Template is MarketBase {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice OU 市场固定为 3 个结果 (Over/Under/Push)
    uint256 private constant OUTCOME_COUNT = 3;

    /// @notice Outcome IDs
    uint256 public constant OVER = 0;
    uint256 public constant UNDER = 1;
    uint256 public constant PUSH = 2;

    /// @notice 盘口精度（千分位，例如 2.5 = 2500）
    uint256 private constant LINE_PRECISION = 1000;

    /// @notice Outcome 名称
    string[3] public outcomeNames = ["Over", "Under", "Push"];

    // ============ 状态变量 ============

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public immutable kickoffTime; // 开球时间

    /// @notice 盘口线（千分位表示）
    /// @dev 例如：2.5球 = 2500，3.0球 = 3000，0.5球 = 500
    uint256 public immutable line;

    /// @notice 盘口类型
    /// @dev true = 半球盘（如2.5），false = 整数盘（如2.0）
    bool public immutable isHalfLine;

    // ============ 事件 ============

    /// @notice 市场创建事件
    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256 line,
        bool isHalfLine,
        address pricingEngine
    );

    /// @notice 定价引擎更新事件
    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);

    // ============ 构造函数 ============

    /**
     * @notice 构造函数
     * @param _matchId 比赛ID
     * @param _homeTeam 主队名称
     * @param _awayTeam 客队名称
     * @param _kickoffTime 开球时间
     * @param _line 盘口线（千分位，如 2500 = 2.5球）
     * @param _settlementToken 结算币种
     * @param _feeRecipient 费用接收地址
     * @param _feeRate 手续费率（基点）
     * @param _disputePeriod 争议期（秒）
     * @param _pricingEngine 定价引擎地址
     * @param _uri ERC-1155 元数据 URI
     */
    constructor(
        string memory _matchId,
        string memory _homeTeam,
        string memory _awayTeam,
        uint256 _kickoffTime,
        uint256 _line,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _pricingEngine,
        string memory _uri
    )
        MarketBase(
            OUTCOME_COUNT,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _uri
        )
    {
        require(bytes(_matchId).length > 0, "OU: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "OU: Invalid home team");
        require(bytes(_awayTeam).length > 0, "OU: Invalid away team");
        require(_kickoffTime > block.timestamp, "OU: Kickoff time in past");
        require(_line > 0 && _line <= 20000, "OU: Invalid line"); // 最大20.0球
        require(_pricingEngine != address(0), "OU: Invalid pricing engine");

        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        line = _line;

        // 判断是否为半球盘（如2.5）还是整数盘（如2.0）
        isHalfLine = (_line % LINE_PRECISION) != 0;

        pricingEngine = IPricingEngine(_pricingEngine);

        emit MarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _line,
            isHalfLine,
            _pricingEngine
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID（0=Over, 1=Under, 2=Push）
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     * @dev 覆盖 MarketBase 的抽象函数
     *      注意：Push (outcome=2) 不允许下注，仅用于结算时退款
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        view
        override
        returns (uint256 shares)
    {
        // Push 不允许下注
        require(outcomeId != PUSH, "OU: Cannot bet on Push");

        // 构建储备数组（仅包含 Over 和 Under，定价引擎只需 2 个元素）
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[OVER];
        reserves[1] = outcomeLiquidity[UNDER];

        // 如果储备为 0，初始化为最小值
        if (reserves[0] == 0) reserves[0] = 1e18;
        if (reserves[1] == 0) reserves[1] = 1e18;

        // 调用定价引擎（仅 Over/Under 两向定价）
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev OU 逻辑：
     *      1. 半球盘（如2.5）：
     *         - 总进球 > line → 0 (Over)
     *         - 总进球 < line → 1 (Under)
     *         - 不可能出现 Push
     *
     *      2. 整数盘（如2.0）：
     *         - 总进球 > line → 0 (Over)
     *         - 总进球 < line → 1 (Under)
     *         - 总进球 == line → 2 (Push，全额退款)
     *
     *      Push 场景下，MarketBase.redeem() 会按 1:1 兑付本金
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        view
        override
        returns (uint256 winningOutcomeId)
    {
        // 计算总进球数（主队 + 客队）
        uint256 totalGoals = uint256(facts.homeGoals) + uint256(facts.awayGoals);

        // 转换为千分位表示（例如：3球 = 3000）
        uint256 totalGoalsScaled = totalGoals * LINE_PRECISION;

        // 半球盘：直接比较，不可能 Push
        if (isHalfLine) {
            return totalGoalsScaled > line ? OVER : UNDER;
        }

        // 整数盘：需要处理 Push 情况
        if (totalGoalsScaled > line) {
            return OVER;
        } else if (totalGoalsScaled < line) {
            return UNDER;
        } else {
            // 总进球等于盘口（如盘口2.0，实际2球） → Push
            return PUSH;
        }
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID (0=Over, 1=Under)
     * @return price 价格（基点，0-10000 表示 0%-100%）
     * @dev Push (outcome=2) 没有价格，调用会 revert
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < 2, "OU: Push has no price");

        // 构建储备数组（仅 Over 和 Under）
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[OVER];
        reserves[1] = outcomeLiquidity[UNDER];

        if (reserves[0] == 0) reserves[0] = 1e18;
        if (reserves[1] == 0) reserves[1] = 1e18;

        price = pricingEngine.getPrice(outcomeId, reserves);
        return price;
    }

    /**
     * @notice 获取所有可下注结果的当前价格
     * @return prices 价格数组（基点，仅包含 Over 和 Under）
     * @dev 返回数组长度为 2，Push 不参与定价
     */
    function getAllPrices() external view returns (uint256[2] memory prices) {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[OVER];
        reserves[1] = outcomeLiquidity[UNDER];

        if (reserves[0] == 0) reserves[0] = 1e18;
        if (reserves[1] == 0) reserves[1] = 1e18;

        prices[0] = pricingEngine.getPrice(OVER, reserves);
        prices[1] = pricingEngine.getPrice(UNDER, reserves);

        return prices;
    }

    /**
     * @notice 获取市场信息
     * @return _matchId 比赛ID
     * @return _homeTeam 主队
     * @return _awayTeam 客队
     * @return _kickoffTime 开球时间
     * @return _line 盘口线
     * @return _isHalfLine 是否为半球盘
     * @return _status 市场状态
     */
    function getMarketInfo()
        external
        view
        returns (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            uint256 _line,
            bool _isHalfLine,
            MarketStatus _status
        )
    {
        return (matchId, homeTeam, awayTeam, kickoffTime, line, isHalfLine, status);
    }

    /**
     * @notice 检查是否应该锁盘
     * @return _shouldLock 是否应该锁盘
     * @dev 开球时间前 5 分钟锁盘
     */
    function shouldLock() external view returns (bool _shouldLock) {
        return block.timestamp >= kickoffTime - 5 minutes && status == MarketStatus.Open;
    }

    /**
     * @notice 获取盘口的小数表示
     * @return integer 整数部分
     * @return decimal 小数部分（千分位）
     * @dev 例如：2.5球 → (2, 500)，3.0球 → (3, 0)
     */
    function getLineDisplay() external view returns (uint256 integer, uint256 decimal) {
        integer = line / LINE_PRECISION;
        decimal = line % LINE_PRECISION;
        return (integer, decimal);
    }

    // ============ Push 场景专用函数 ============

    /**
     * @notice Push 场景下的兑付函数
     * @param outcomeId 用户持有的 outcome ID (0=Over 或 1=Under,或 2=Push)
     * @param shares 份额数量
     * @return payout 退款金额
     * @dev Push 场景下,任何持有 Over 或 Under token 的用户都可以按 1:1 兑付
     *      不参与 totalLiquidity 池,直接退还投入金额(已扣手续费)
     */
    function redeem(uint256 outcomeId, uint256 shares)
        external
        override
        onlyStatusIn(MarketStatus.Resolved, MarketStatus.Finalized)
        nonReentrant
        returns (uint256 payout)
    {
        // 如果不是 Push 场景,使用标准兑付逻辑
        if (winningOutcome != PUSH) {
            require(outcomeId == winningOutcome, "MarketBase: Not winning outcome");
            require(shares > 0, "MarketBase: Zero shares");
            require(
                balanceOf(msg.sender, outcomeId) >= shares,
                "MarketBase: Insufficient balance"
            );

            // 计算赔付（按比例分配）
            uint256 totalWinningShares = totalSupply(winningOutcome);
            require(totalWinningShares > 0, "MarketBase: No winning shares");

            payout = (shares * totalLiquidity) / totalWinningShares;
            require(payout > 0, "MarketBase: Zero payout");
            require(payout <= totalLiquidity, "MarketBase: Insufficient liquidity");

            // 更新状态
            totalLiquidity -= payout;

            // 销毁 token
            _burn(msg.sender, outcomeId, shares);

            // 转账
            settlementToken.safeTransfer(msg.sender, payout);

            emit Redeemed(msg.sender, outcomeId, shares, payout);

            return payout;
        }

        // Push 场景:允许兑付 Over 或 Under token
        require(
            outcomeId == OVER || outcomeId == UNDER,
            "OU: Invalid outcome for Push refund"
        );
        require(shares > 0, "OU: Zero shares");
        require(
            balanceOf(msg.sender, outcomeId) >= shares,
            "OU: Insufficient balance"
        );

        // Push 退款:按 shares 占总 shares 的比例分配 totalLiquidity
        // 这样可以保证每个用户按投入比例拿回资金(考虑到 CPMM 定价)
        uint256 totalOutcomeShares = totalSupply(outcomeId);
        require(totalOutcomeShares > 0, "OU: No shares for this outcome");

        payout = (shares * totalLiquidity) / (totalSupply(OVER) + totalSupply(UNDER));
        require(payout > 0, "OU: Zero payout");
        require(payout <= totalLiquidity, "OU: Insufficient liquidity");

        // 更新状态
        totalLiquidity -= payout;

        // 销毁 token
        _burn(msg.sender, outcomeId, shares);

        // 转账
        settlementToken.safeTransfer(msg.sender, payout);

        emit Redeemed(msg.sender, outcomeId, shares, payout);

        return payout;
    }

    // ============ 管理函数 ============

    /**
     * @notice 更新定价引擎
     * @param _pricingEngine 新的定价引擎地址
     * @dev 只能在 Open 状态更新
     */
    function setPricingEngine(address _pricingEngine)
        external
        onlyOwner
        onlyStatus(MarketStatus.Open)
    {
        require(_pricingEngine != address(0), "OU: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     * @dev 开球时间到达时自动锁盘
     */
    function autoLock() external {
        require(block.timestamp >= kickoffTime - 5 minutes, "OU: Too early to lock");
        require(status == MarketStatus.Open, "OU: Market not open");

        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }
}
