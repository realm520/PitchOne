// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";

/**
 * @title WDL_Template
 * @notice 胜平负（Win/Draw/Loss）市场模板
 * @dev 三向市场：主队胜、平局、主队负
 *      使用 CPMM 定价引擎
 *
 * Outcome IDs:
 * - 0: 主队胜 (Win)
 * - 1: 平局 (Draw)
 * - 2: 主队负 (Loss)
 *
 * 示例：
 * - 曼联 vs 曼城
 * - outcomeId 0 = 曼联胜
 * - outcomeId 1 = 平局
 * - outcomeId 2 = 曼城胜
 */
contract WDL_Template is MarketBase {
    // ============ 常量 ============

    /// @notice WDL 市场固定为 3 个结果
    uint256 private constant OUTCOME_COUNT = 3;

    /// @notice Outcome 名称（用于事件）
    string[3] public outcomeNames = ["Win", "Draw", "Loss"];

    // ============ 状态变量 ============

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 比赛信息
    string public matchId;      // 比赛ID（如 "EPL_2024_MUN_vs_MCI"）
    string public homeTeam;     // 主队
    string public awayTeam;     // 客队
    uint256 public immutable kickoffTime; // 开球时间（Unix 时间戳）

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
     * @notice 构造函数
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
     */
    constructor(
        string memory _matchId,
        string memory _homeTeam,
        string memory _awayTeam,
        uint256 _kickoffTime,
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
        require(bytes(_matchId).length > 0, "WDL: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "WDL: Invalid home team");
        require(bytes(_awayTeam).length > 0, "WDL: Invalid away team");
        require(_kickoffTime > block.timestamp, "WDL: Kickoff time in past");
        require(_pricingEngine != address(0), "WDL: Invalid pricing engine");

        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        pricingEngine = IPricingEngine(_pricingEngine);

        emit MarketCreated(_matchId, _homeTeam, _awayTeam, _kickoffTime, _pricingEngine);
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID
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
        // 构建储备数组
        uint256[] memory reserves = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            reserves[i] = outcomeLiquidity[i];
            // 如果储备为 0，初始化为最小值
            if (reserves[i] == 0) {
                reserves[i] = 1e18; // 1 token (假设 18 decimals)
            }
        }

        // 调用定价引擎
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev WDL 逻辑：
     *      - homeGoals > awayGoals → 0 (主队胜)
     *      - homeGoals == awayGoals → 1 (平局)
     *      - homeGoals < awayGoals → 2 (客队胜)
     *
     *      对于 FT_90/FT_120，使用常规时间+加时的进球数
     *      对于 Penalties，使用点球大战结果（常规90分钟平局的情况）
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        pure
        override
        returns (uint256 winningOutcomeId)
    {
        // 对于点球大战场景
        if (facts.scope == bytes32("Penalties")) {
            // 点球大战的胜者
            if (facts.penaltiesHome > facts.penaltiesAway) {
                return 0; // 主队胜
            } else if (facts.penaltiesHome < facts.penaltiesAway) {
                return 2; // 客队胜
            } else {
                // 点球大战平局？理论上不应该发生，但以常规时间为准
                return 1; // 平局
            }
        }

        // 常规场景（FT_90 或 FT_120）
        if (facts.homeGoals > facts.awayGoals) {
            return 0; // 主队胜
        } else if (facts.homeGoals < facts.awayGoals) {
            return 2; // 客队胜
        } else {
            return 1; // 平局
        }
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < OUTCOME_COUNT, "WDL: Invalid outcome ID");

        // 构建储备数组
        uint256[] memory reserves = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            reserves[i] = outcomeLiquidity[i];
            if (reserves[i] == 0) {
                reserves[i] = 1e18;
            }
        }

        price = pricingEngine.getPrice(outcomeId, reserves);
        return price;
    }

    /**
     * @notice 获取所有结果的当前价格
     * @return prices 价格数组（基点）
     */
    function getAllPrices() external view returns (uint256[OUTCOME_COUNT] memory prices) {
        uint256[] memory reserves = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            reserves[i] = outcomeLiquidity[i];
            if (reserves[i] == 0) {
                reserves[i] = 1e18;
            }
        }

        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            prices[i] = pricingEngine.getPrice(i, reserves);
        }

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
        require(_pricingEngine != address(0), "WDL: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     * @dev 开球时间到达时自动锁盘
     */
    function autoLock() external {
        require(block.timestamp >= kickoffTime - 5 minutes, "WDL: Too early to lock");
        require(status == MarketStatus.Open, "WDL: Market not open");

        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }
}
