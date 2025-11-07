// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title OU_Template
 * @notice 大小球（Over/Under）市场模板 - 单线版本
 * @dev 二向市场：大球（Over）、小球（Under）
 *      仅支持半球盘，避免 AMM 环境下的退款问题
 *      使用 CPMM 定价引擎进行二向定价
 *
 * Outcome IDs:
 * - 0: 大球 (Over) - 总进球数 > line
 * - 1: 小球 (Under) - 总进球数 < line
 *
 * 示例：
 * - 曼联 vs 曼城，盘口 2.5 球
 *   - outcomeId 0 = 大2.5球（总进球 ≥ 3）
 *   - outcomeId 1 = 小2.5球（总进球 ≤ 2）
 *
 * 注意：
 * - line 使用千分位表示（2.5球 = 2500，3.5球 = 3500）
 * - 仅支持半球盘（如 2.5, 3.5, 1.5 等）
 * - 不支持整数盘，以避免 Push 退款的复杂性
 * - M1阶段仅支持单线，M2阶段扩展到多线联动
 */
contract OU_Template is MarketBase {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice OU 市场固定为 2 个结果 (Over/Under)
    uint256 private constant OUTCOME_COUNT = 2;

    /// @notice Outcome IDs
    uint256 public constant OVER = 0;
    uint256 public constant UNDER = 1;

    /// @notice 盘口精度（千分位，例如 2.5 = 2500）
    uint256 private constant LINE_PRECISION = 1000;

    /// @notice Outcome 名称
    string[2] public outcomeNames = ["Over", "Under"];

    // ============ 状态变量 ============

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public kickoffTime; // 开球时间

    /// @notice 盘口线（千分位表示）
    /// @dev 例如：2.5球 = 2500，3.5球 = 3500，0.5球 = 500
    /// @dev 必须是半球盘（line % LINE_PRECISION != 0）
    uint256 public line;

    // ============ 事件 ============

    /// @notice 市场创建事件
    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256 line,
        address pricingEngine
    );

    /// @notice 定价引擎更新事件
    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);

    // ============ 构造函数 ============

    /**
     * @notice 禁用初始化器的构造函数
     * @dev 防止实现合约被直接初始化
     */
    constructor() {
        // 注意：不调用 _disableInitializers() 以允许在测试中直接实例化
        // initializer 修饰符已经足够防止重复初始化
    }

    /**
     * @notice 初始化函数
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
     * @param _owner 合约所有者
     */
    function initialize(
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
        string memory _uri,
        address _owner
    ) public initializer {
        require(bytes(_matchId).length > 0, "OU: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "OU: Invalid home team");
        require(bytes(_awayTeam).length > 0, "OU: Invalid away team");
        require(_kickoffTime > block.timestamp, "OU: Kickoff time in past");
        require(_line > 0 && _line <= 20000, "OU: Invalid line"); // 最大20.0球
        require(_line % LINE_PRECISION != 0, "OU: Only half lines allowed"); // 必须是半球盘
        require(_pricingEngine != address(0), "OU: Invalid pricing engine");

        __MarketBase_init(
            OUTCOME_COUNT,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _uri,
            _owner
        );

        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        line = _line;

        pricingEngine = IPricingEngine(_pricingEngine);

        emit MarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _line,
            _pricingEngine
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID（0=Over, 1=Under）
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     * @dev 覆盖 MarketBase 的抽象函数
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        view
        override
        returns (uint256 shares)
    {
        require(outcomeId < OUTCOME_COUNT, "OU: Invalid outcome ID");

        // 构建储备数组
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[OVER];
        reserves[1] = outcomeLiquidity[UNDER];

        // 如果储备为 0，初始化为最小值
        if (reserves[0] == 0) reserves[0] = 1e18;
        if (reserves[1] == 0) reserves[1] = 1e18;

        // 调用定价引擎进行二向定价
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev OU 逻辑（仅半球盘）：
     *      - 总进球 > line → 0 (Over)
     *      - 总进球 < line → 1 (Under)
     *      - 由于是半球盘，总进球不可能等于 line
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

        // 半球盘：简单比较
        return totalGoalsScaled > line ? OVER : UNDER;
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID (0=Over, 1=Under)
     * @return price 价格（基点，0-10000 表示 0%-100%）
     * @dev 只支持 OVER 和 UNDER，其他 outcome 会 revert
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < OUTCOME_COUNT, "OU: Invalid outcome");

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
     * @return _line 盘口线（千分位，仅半球盘）
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
            MarketStatus _status
        )
    {
        return (matchId, homeTeam, awayTeam, kickoffTime, line, status);
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
