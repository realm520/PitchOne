// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title OddEven_Template
 * @notice 进球数单双市场模板
 * @dev 二向市场：奇数（Odd）、偶数（Even）
 *      判断总进球数（主队 + 客队）是奇数还是偶数
 *      使用 CPMM 定价引擎进行二向定价
 *
 * Outcome IDs:
 * - 0: 奇数 (Odd) - 总进球数为奇数（1, 3, 5, 7...）
 * - 1: 偶数 (Even) - 总进球数为偶数（0, 2, 4, 6...）
 *
 * 示例：
 * - 曼联 vs 曼城，最终比分 2:1
 *   - 总进球 = 3（奇数）→ outcomeId 0 获胜
 * - 曼联 vs 曼城，最终比分 1:1
 *   - 总进球 = 2（偶数）→ outcomeId 1 获胜
 * - 曼联 vs 曼城，最终比分 0:0
 *   - 总进球 = 0（偶数）→ outcomeId 1 获胜
 */
contract OddEven_Template is MarketBase {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice 市场固定为 2 个结果 (Odd/Even)
    uint256 private constant OUTCOME_COUNT = 2;

    /// @notice Outcome IDs
    uint256 public constant ODD = 0;
    uint256 public constant EVEN = 1;

    /// @notice Outcome 名称
    string[2] public outcomeNames = ["Odd", "Even"];

    // ============ 状态变量 ============

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public kickoffTime; // 开球时间

    /// @notice 虚拟储备（用于 CPMM 定价）
    /// @dev 独立于 outcomeLiquidity，根据 CPMM 公式更新
    mapping(uint256 => uint256) public virtualReserves;

    // ============ 事件 ============

    /// @notice 市场创建事件
    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
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
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _pricingEngine,
        string memory _uri,
        address _owner
    ) public initializer {
        require(bytes(_matchId).length > 0, "OddEven: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "OddEven: Invalid home team");
        require(bytes(_awayTeam).length > 0, "OddEven: Invalid away team");
        require(_kickoffTime > block.timestamp, "OddEven: Kickoff time in past");
        require(_pricingEngine != address(0), "OddEven: Invalid pricing engine");

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

        pricingEngine = IPricingEngine(_pricingEngine);

        // 初始化虚拟储备（100,000 * 10^decimals）
        uint256 initialReserve = 100_000 * (10 ** IERC20Metadata(_settlementToken).decimals());
        virtualReserves[ODD] = initialReserve;
        virtualReserves[EVEN] = initialReserve;

        emit MarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _pricingEngine
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID（0=Odd, 1=Even）
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     * @dev 覆盖 MarketBase 的抽象函数
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        override
        returns (uint256 shares)
    {
        require(outcomeId < OUTCOME_COUNT, "OddEven: Invalid outcome ID");

        // 使用虚拟储备（而非 outcomeLiquidity）
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = virtualReserves[ODD];
        reserves[1] = virtualReserves[EVEN];

        // 调用定价引擎计算份额
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        // 更新虚拟储备（根据 CPMM 公式）
        // 买入 outcome i：r_i 减少，r_other 增加
        uint256 otherOutcome = 1 - outcomeId;

        // k = r_0 * r_1 (保持不变)
        uint256 k = reserves[0] * reserves[1];

        // 新的对手盘储备：r_other' = r_other + amount
        uint256 r_other_new = reserves[otherOutcome] + amount;

        // 新的目标储备：r_target' = k / r_other'
        uint256 r_target_new = k / r_other_new;

        // 更新虚拟储备
        virtualReserves[outcomeId] = r_target_new;
        virtualReserves[otherOutcome] = r_other_new;

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 单双逻辑：
     *      - 总进球 % 2 == 1 → 0 (Odd)
     *      - 总进球 % 2 == 0 → 1 (Even)
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        pure
        override
        returns (uint256 winningOutcomeId)
    {
        // 计算总进球数（主队 + 客队）
        uint256 totalGoals = uint256(facts.homeGoals) + uint256(facts.awayGoals);

        // 判断奇偶
        return (totalGoals % 2 == 1) ? ODD : EVEN;
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID (0=Odd, 1=Even)
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < 2, "OddEven: Invalid outcome");

        // 使用虚拟储备
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = virtualReserves[ODD];
        reserves[1] = virtualReserves[EVEN];

        price = pricingEngine.getPrice(outcomeId, reserves);
        return price;
    }

    /**
     * @notice 获取所有可下注结果的当前价格
     * @return prices 价格数组（基点，包含 Odd 和 Even）
     */
    function getAllPrices() external view returns (uint256[2] memory prices) {
        // 使用虚拟储备
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = virtualReserves[ODD];
        reserves[1] = virtualReserves[EVEN];

        prices[0] = pricingEngine.getPrice(ODD, reserves);
        prices[1] = pricingEngine.getPrice(EVEN, reserves);

        return prices;
    }

    /**
     * @notice 获取市场信息
     * @return _matchId 比赛ID
     * @return _homeTeam 主队
     * @return _awayTeam 客队
     * @return _kickoffTime 开球时间
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
            MarketStatus _status
        )
    {
        return (matchId, homeTeam, awayTeam, kickoffTime, status);
    }

    /**
     * @notice 检查是否应该锁盘
     * @return _shouldLock 是否应该锁盘
     * @dev 开球时间前 5 分钟锁盘
     */
    function shouldLock() external view returns (bool _shouldLock) {
        return block.timestamp >= kickoffTime - 5 minutes && status == MarketStatus.Open;
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
        require(_pricingEngine != address(0), "OddEven: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     * @dev 开球时间到达时自动锁盘
     */
    function autoLock() external {
        require(block.timestamp >= kickoffTime - 5 minutes, "OddEven: Too early to lock");
        require(status == MarketStatus.Open, "OddEven: Market not open");

        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }
}
