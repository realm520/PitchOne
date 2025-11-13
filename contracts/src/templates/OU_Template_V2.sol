// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase_V2.sol";
import "../interfaces/IPricingEngine.sol";

/**
 * @title OU_Template_V2
 * @notice 大小球（Over/Under）市场模板 V2 - 单线版本
 * @dev 继承 MarketBase_V2，集成 LiquidityVault
 *
 * 核心改进：
 * - 使用虚拟储备定价（SimpleCPMM）
 * - 从 Vault 借出初始流动性
 * - 市场结算后归还流动性+收益
 * - 支持滑点保护
 *
 * 二向市场：大球（Over）、小球（Under）
 * 仅支持半球盘，避免 AMM 环境下的退款问题
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
 */
contract OU_Template_V2 is MarketBase_V2 {
    // ============ 常量 ============

    /// @notice OU 市场固定为 2 个结果 (Over/Under)
    uint256 private constant OUTCOME_COUNT = 2;

    /// @notice 默认初始借款金额（从 Vault 借出）
    uint256 private constant DEFAULT_BORROW_AMOUNT = 100_000 * 1e6; // 100k USDC

    /// @notice 虚拟储备初始值（与 SimpleCPMM.VIRTUAL_RESERVE_INIT 保持一致）
    uint256 private constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100k USDC

    /// @notice Outcome IDs
    uint256 public constant OVER = 0;
    uint256 public constant UNDER = 1;

    /// @notice 盘口精度（千分位，例如 2.5 = 2500）
    uint256 private constant LINE_PRECISION = 1000;

    /// @notice Outcome 名称
    string[2] public outcomeNames = ["Over", "Under"];

    // ============ 状态变量 ============

    /// @notice 定价引擎（SimpleCPMM）
    IPricingEngine public pricingEngine;

    /// @notice 虚拟储备（由定价引擎管理）
    uint256[] public virtualReserves;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public kickoffTime;         // 开球时间

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
        address pricingEngine,
        address vault
    );

    /// @notice 定价引擎更新事件
    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);

    /// @notice 虚拟储备更新事件
    event VirtualReservesUpdated(uint256[] reserves);

    // ============ 构造函数和初始化 ============

    /// @custom:oz-upgrades-unsafe-allow constructor
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
     * @param _settlementToken 结算币种地址
     * @param _feeRecipient 费用接收地址
     * @param _feeRate 手续费率（基点）
     * @param _disputePeriod 争议期（秒）
     * @param _pricingEngine 定价引擎地址
     * @param _vault Vault 地址
     * @param _uri ERC-1155 元数据 URI
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
        address _vault,
        string memory _uri
    ) external initializer {
        // 验证参数
        require(bytes(_matchId).length > 0, "OU_V2: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "OU_V2: Invalid home team");
        require(bytes(_awayTeam).length > 0, "OU_V2: Invalid away team");
        require(_kickoffTime > block.timestamp, "OU_V2: Kickoff time in past");
        require(_line > 0 && _line <= 20000, "OU_V2: Invalid line"); // 最大20.0球
        require(_line % LINE_PRECISION != 0, "OU_V2: Only half lines allowed"); // 必须是半球盘
        require(_pricingEngine != address(0), "OU_V2: Invalid pricing engine");

        // 初始化父合约
        __MarketBase_init(
            OUTCOME_COUNT,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _vault,
            _uri
        );

        // 设置状态变量
        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        line = _line;
        pricingEngine = IPricingEngine(_pricingEngine);

        // 初始化虚拟储备（Over 和 Under 均等）
        virtualReserves = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            virtualReserves[i] = VIRTUAL_RESERVE_INIT;
        }

        emit MarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _line,
            _pricingEngine,
            _vault
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（使用虚拟储备定价）
     * @param outcomeId 结果ID（0=Over, 1=Under）
     * @param netAmount 净金额（已扣除手续费）
     * @return shares 获得的份额
     */
    function _calculateShares(uint256 outcomeId, uint256 netAmount)
        internal
        override
        returns (uint256 shares)
    {
        require(outcomeId < OUTCOME_COUNT, "OU_V2: Invalid outcome ID");

        // 调用定价引擎计算份额
        shares = pricingEngine.calculateShares(outcomeId, netAmount, virtualReserves);

        // 更新虚拟储备：
        // 买入 → 目标储备减少，对手盘储备增加
        virtualReserves[outcomeId] -= shares;

        // 对手盘储备增加买入金额
        uint256 opponentId = outcomeId == OVER ? UNDER : OVER;
        virtualReserves[opponentId] += netAmount;

        emit VirtualReservesUpdated(virtualReserves);

        return shares;
    }

    /**
     * @notice 获取初始借款金额
     * @return 需要从 Vault 借出的金额
     */
    function _getInitialBorrowAmount() internal pure override returns (uint256) {
        return DEFAULT_BORROW_AMOUNT;
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
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < OUTCOME_COUNT, "OU_V2: Invalid outcome");
        return pricingEngine.getPrice(outcomeId, virtualReserves);
    }

    /**
     * @notice 获取所有可下注结果的当前价格
     * @return prices 价格数组（基点，仅包含 Over 和 Under）
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        prices = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            prices[i] = pricingEngine.getPrice(i, virtualReserves);
        }
        return prices;
    }

    /**
     * @notice 获取虚拟储备
     */
    function getVirtualReserves() external view returns (uint256[] memory) {
        return virtualReserves;
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
     */
    function setPricingEngine(address _pricingEngine) external onlyOwner {
        require(_pricingEngine != address(0), "OU_V2: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     * @dev 开球时间到达时自动锁盘
     */
    function autoLock() external {
        require(block.timestamp >= kickoffTime - 5 minutes, "OU_V2: Too early to lock");
        require(status == MarketStatus.Open, "OU_V2: Market not open");

        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }
}
