// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase_V2.sol";
import "../interfaces/IPricingEngine.sol";

/**
 * @title WDL_Template_V2
 * @notice 胜平负（Win/Draw/Loss）市场模板 V2
 * @dev 继承 MarketBase_V2，集成 LiquidityVault
 *
 * 核心改进：
 * - 使用虚拟储备定价（SimpleCPMM）
 * - 从 Vault 借出初始流动性
 * - 市场结算后归还流动性+收益
 * - 支持滑点保护
 *
 * Outcome IDs:
 * - 0: 主队胜 (Win)
 * - 1: 平局 (Draw)
 * - 2: 主队负 (Loss)
 */
contract WDL_Template_V2 is MarketBase_V2 {
    // ============ 常量 ============

    /// @notice WDL 市场固定为 3 个结果
    uint256 private constant OUTCOME_COUNT = 3;

    /// @notice 默认初始借款金额（从 Vault 借出）
    uint256 private constant DEFAULT_BORROW_AMOUNT = 100_000 * 1e6; // 100k USDC

    /// @notice 虚拟储备初始值（与 SimpleCPMM.VIRTUAL_RESERVE_INIT 保持一致）
    uint256 private constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100k USDC

    /// @notice Outcome 名称
    string[3] public outcomeNames = ["Win", "Draw", "Loss"];

    // ============ 状态变量 ============

    /// @notice 定价引擎（SimpleCPMM）
    IPricingEngine public pricingEngine;

    /// @notice 虚拟储备（由定价引擎管理）
    uint256[] public virtualReserves;

    /// @notice 比赛信息
    string public matchId;
    string public homeTeam;
    string public awayTeam;
    uint256 public kickoffTime;

    // ============ 事件 ============

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        address pricingEngine,
        address vault
    );

    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);

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
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _pricingEngine,
        address _vault,
        string memory _uri
    ) external initializer {
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

        // 验证参数
        require(bytes(_matchId).length > 0, "WDL_V2: Invalid match ID");
        require(bytes(_homeTeam).length > 0, "WDL_V2: Invalid home team");
        require(bytes(_awayTeam).length > 0, "WDL_V2: Invalid away team");
        require(_kickoffTime > block.timestamp, "WDL_V2: Kickoff time in past");
        require(_pricingEngine != address(0), "WDL_V2: Invalid pricing engine");

        // 设置状态变量
        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        pricingEngine = IPricingEngine(_pricingEngine);

        // 初始化虚拟储备（所有 outcome 均等）
        virtualReserves = new uint256[](OUTCOME_COUNT);
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            virtualReserves[i] = VIRTUAL_RESERVE_INIT;
        }

        emit MarketCreated(_matchId, _homeTeam, _awayTeam, _kickoffTime, _pricingEngine, _vault);
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（使用虚拟储备定价）
     * @param outcomeId 结果ID
     * @param netAmount 净金额（已扣除手续费）
     * @return shares 获得的份额
     */
    function _calculateShares(uint256 outcomeId, uint256 netAmount)
        internal
        override
        returns (uint256 shares)
    {
        // 调用定价引擎计算份额
        shares = pricingEngine.calculateShares(outcomeId, netAmount, virtualReserves);

        // 更新虚拟储备：
        // 买入 → 目标储备减少，对手盘储备增加
        virtualReserves[outcomeId] -= shares;

        // 对手盘储备均分买入金额
        uint256 opponentCount = OUTCOME_COUNT - 1;
        uint256 amountPerOpponent = netAmount / opponentCount;
        for (uint256 i = 0; i < OUTCOME_COUNT; i++) {
            if (i != outcomeId) {
                virtualReserves[i] += amountPerOpponent;
            }
        }

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

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格
     * @param outcomeId 结果ID
     * @return price 价格（基点，0-10000）
     */
    function getPrice(uint256 outcomeId) external view returns (uint256) {
        require(outcomeId < OUTCOME_COUNT, "WDL_V2: Invalid outcome");
        return pricingEngine.getPrice(outcomeId, virtualReserves);
    }

    /**
     * @notice 获取所有价格
     * @return prices 价格数组
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

    // ============ 管理函数 ============

    /**
     * @notice 更新定价引擎
     * @param _pricingEngine 新的定价引擎地址
     */
    function setPricingEngine(address _pricingEngine) external onlyOwner {
        require(_pricingEngine != address(0), "WDL_V2: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }
}
