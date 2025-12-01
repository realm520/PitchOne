// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase_V2.sol";
import "../interfaces/IPricingEngine.sol";
import "../pricing/LinkedLinesController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title OU_MultiLine_V2
 * @notice 大小球（Over/Under）多线市场模板 V2 - 仅支持半球盘
 * @dev 继承 MarketBase_V2，集成 LiquidityVault
 *
 * 核心改进：
 * - 使用虚拟储备定价（SimpleCPMM）
 * - 从 Vault 借出初始流动性
 * - 市场结算后归还流动性+收益
 * - 支持滑点保护
 *
 * 与 V1 的主要区别：
 * - 支持同一场比赛的多条半球盘盘口线（如 2.5、3.5、4.5 球）
 * - 使用 LinkedLinesController 进行联动定价，防止套利
 * - 每条线独立的 outcome IDs
 * - 每条线独立结算，但共享流动性池
 *
 * 设计说明：
 * - 只允许半球盘（如 2.5、3.5），避免 AMM 环境下的 Push 退款问题
 * - 每个结果都有明确的赢/输，简化结算逻辑
 *
 * Outcome ID 编码：
 * - outcomeId = lineIndex * 2 + direction
 * - direction: 0 = OVER, 1 = UNDER
 *
 * 示例（3条半球盘线：2.5、3.5、4.5）：
 * - outcomeId 0 = 2.5球 OVER
 * - outcomeId 1 = 2.5球 UNDER
 * - outcomeId 2 = 3.5球 OVER
 * - outcomeId 3 = 3.5球 UNDER
 * - outcomeId 4 = 4.5球 OVER
 * - outcomeId 5 = 4.5球 UNDER
 */
contract OU_MultiLine_V2 is MarketBase_V2 {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice 每条线的结果数量 (Over/Under)
    uint256 private constant OUTCOMES_PER_LINE = 2;

    /// @notice Outcome 方向
    uint256 public constant OVER = 0;
    uint256 public constant UNDER = 1;

    /// @notice 盘口精度（千分位，例如 2.5 = 2500）
    uint256 private constant LINE_PRECISION = 1000;

    // ============ 状态变量 ============

    /// @notice 默认初始借款金额（从 Vault 借出，动态计算）
    uint256 private defaultBorrowAmount;

    /// @notice 虚拟储备初始值（动态计算）
    uint256 private virtualReserveInit;

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 联动控制器
    LinkedLinesController public linkedLinesController;

    /// @notice 线组 ID
    bytes32 public groupId;

    /// @notice 虚拟储备（由定价引擎管理）
    mapping(uint256 => uint256) public virtualReserves;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    // kickoffTime 继承自 MarketBase_V2

    /// @notice 盘口线数组（千分位表示）
    uint256[] private lines;

    /// @notice 线索引映射（line => lineIndex）
    mapping(uint256 => uint256) public lineToIndex;

    // ============ 事件 ============

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256[] lines,
        bytes32 groupId,
        address pricingEngine,
        address linkedLinesController,
        address vault
    );

    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);
    event LinkedLinesControllerUpdated(address indexed oldController, address indexed newController);
    event VirtualReservesUpdated(uint256 indexed outcomeId, uint256 newReserve);

    // ============ 错误 ============

    error InvalidLineIndex(uint256 lineIndex);
    error InvalidLine(uint256 line);
    error LineNotFound(uint256 line);
    error NoLinesProvided();
    error LinesNotSorted();
    error OnlyHalfLinesAllowed(uint256 line);

    // ============ 构造函数和初始化 ============

    struct InitializeParams {
        string matchId;
        string homeTeam;
        string awayTeam;
        uint256 kickoffTime;
        uint256[] lines;
        address settlementToken;
        address feeRecipient;
        uint256 feeRate;
        uint256 disputePeriod;
        address pricingEngine;
        address linkedLinesController;
        address vault;
        string uri;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 注意：不调用 _disableInitializers() 以允许在测试中直接实例化
        // initializer 修饰符已经足够防止重复初始化
    }

    /**
     * @notice 初始化函数
     * @param params 初始化参数结构体
     */
    function initialize(InitializeParams memory params) external initializer {
        require(bytes(params.matchId).length > 0, "OU_ML_V2: Invalid match ID");
        require(bytes(params.homeTeam).length > 0, "OU_ML_V2: Invalid home team");
        require(bytes(params.awayTeam).length > 0, "OU_ML_V2: Invalid away team");
        require(params.kickoffTime > block.timestamp, "OU_ML_V2: Kickoff time in past");
        if (params.lines.length == 0) revert NoLinesProvided();
        require(params.pricingEngine != address(0), "OU_ML_V2: Invalid pricing engine");
        require(params.linkedLinesController != address(0), "OU_ML_V2: Invalid controller");

        // 验证线数组从小到大排序，并确保所有线都是半球盘
        for (uint256 i = 0; i < params.lines.length; i++) {
            // 检查是否为半球盘
            if (params.lines[i] % LINE_PRECISION == 0) {
                revert OnlyHalfLinesAllowed(params.lines[i]);
            }

            // 检查有效范围
            if (params.lines[i] == 0 || params.lines[i] > 20000) {
                revert InvalidLine(params.lines[i]);
            }

            // 检查排序（从第二个元素开始）
            if (i > 0 && params.lines[i] <= params.lines[i - 1]) {
                revert LinesNotSorted();
            }
        }

        // 初始化父合约
        __MarketBase_init(
            params.lines.length * OUTCOMES_PER_LINE,
            params.settlementToken,
            params.feeRecipient,
            params.feeRate,
            params.disputePeriod,
            params.vault,
            params.uri
        );

        // 计算动态代币精度参数
        uint8 decimals = IERC20Metadata(params.settlementToken).decimals();
        uint256 tokenUnit = 10 ** decimals;
        defaultBorrowAmount = 100_000 * tokenUnit;
        virtualReserveInit = 50_000 * tokenUnit;

        // 设置状态变量
        matchId = params.matchId;
        homeTeam = params.homeTeam;
        awayTeam = params.awayTeam;
        kickoffTime = params.kickoffTime;
        lines = params.lines;

        // 构建线索引映射
        for (uint256 i = 0; i < params.lines.length; i++) {
            lineToIndex[params.lines[i]] = i;
        }

        pricingEngine = IPricingEngine(params.pricingEngine);
        linkedLinesController = LinkedLinesController(params.linkedLinesController);

        // 生成线组 ID
        groupId = keccak256(abi.encodePacked(params.matchId, block.timestamp, address(this)));

        // 初始化虚拟储备（所有 outcomes 均等）
        for (uint256 i = 0; i < params.lines.length * OUTCOMES_PER_LINE; i++) {
            virtualReserves[i] = virtualReserveInit;
        }

        emit MarketCreated(
            params.matchId,
            params.homeTeam,
            params.awayTeam,
            params.kickoffTime,
            params.lines,
            groupId,
            params.pricingEngine,
            params.linkedLinesController,
            params.vault
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID（编码为 lineIndex * 2 + direction）
     * @param netAmount 净金额（已扣除手续费）
     * @return shares 获得的份额
     */
    function _calculateShares(uint256 outcomeId, uint256 netAmount)
        internal
        override
        returns (uint256 shares)
    {
        // 解码 outcomeId
        (uint256 lineIndex, uint256 direction) = _decodeOutcomeId(outcomeId);

        if (lineIndex >= lines.length) {
            revert InvalidLineIndex(lineIndex);
        }

        // 验证方向（只允许 OVER 或 UNDER）
        require(direction < 2, "OU_ML_V2: Invalid direction");

        // 构建储备数组（仅包含 Over 和 Under）
        uint256 overOutcomeId = _encodeOutcomeId(lineIndex, OVER);
        uint256 underOutcomeId = _encodeOutcomeId(lineIndex, UNDER);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = virtualReserves[overOutcomeId];
        reserves[1] = virtualReserves[underOutcomeId];

        // 如果储备为 0，初始化为最小值
        uint256 minReserve = 10 ** IERC20Metadata(address(settlementToken)).decimals();
        if (reserves[0] == 0) reserves[0] = minReserve;
        if (reserves[1] == 0) reserves[1] = minReserve;

        // 1. 调用定价引擎计算份额（direction 是 0 或 1）
        shares = pricingEngine.calculateShares(direction, netAmount, reserves);

        // 2. 调用定价引擎更新储备（由引擎决定更新逻辑）
        uint256[] memory newReserves = pricingEngine.updateReserves(
            direction,
            netAmount,
            shares,
            reserves
        );

        // 3. 将更新后的储备写回映射
        virtualReserves[overOutcomeId] = newReserves[0];
        virtualReserves[underOutcomeId] = newReserves[1];

        emit VirtualReservesUpdated(overOutcomeId, virtualReserves[overOutcomeId]);
        emit VirtualReservesUpdated(underOutcomeId, virtualReserves[underOutcomeId]);

        return shares;
    }

    /**
     * @notice 获取初始借款金额
     * @return 需要从 Vault 借出的金额
     */
    function _getInitialBorrowAmount() internal view override returns (uint256) {
        return defaultBorrowAmount;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 多线市场有多个获胜结果（不同线的 OVER/UNDER）
     *      这里返回第一条线的获胜结果作为默认值
     *      实际结算时需要检查每条线的结果
     */
    function calculateWinner(IResultOracle.MatchFacts memory facts)
        external
        view
        returns (uint256 winningOutcomeId)
    {
        // 计算总进球数（千分位表示）
        uint256 totalGoals = uint256(facts.homeGoals) + uint256(facts.awayGoals);
        uint256 totalGoalsScaled = totalGoals * LINE_PRECISION;

        // 返回第一条线的获胜结果
        // 半球盘：直接比较
        uint256 line = lines[0];
        uint256 direction = (totalGoalsScaled > line) ? OVER : UNDER;

        return _encodeOutcomeId(0, direction);
    }

    // ============ 内部辅助函数 ============

    /**
     * @notice 编码 outcomeId
     * @param lineIndex 线索引
     * @param direction 方向（OVER/UNDER）
     * @return outcomeId 编码后的 outcome ID
     */
    function _encodeOutcomeId(uint256 lineIndex, uint256 direction) internal pure returns (uint256 outcomeId) {
        return lineIndex * OUTCOMES_PER_LINE + direction;
    }

    /**
     * @notice 解码 outcomeId
     * @param outcomeId 编码的 outcome ID
     * @return lineIndex 线索引
     * @return direction 方向（OVER/UNDER）
     */
    function _decodeOutcomeId(uint256 outcomeId) internal pure returns (uint256 lineIndex, uint256 direction) {
        lineIndex = outcomeId / OUTCOMES_PER_LINE;
        direction = outcomeId % OUTCOMES_PER_LINE;
        return (lineIndex, direction);
    }

    /**
     * @notice 计算单条线的获胜结果
     * @param line 盘口线（必须是半球盘）
     * @param totalGoalsScaled 总进球数（千分位表示）
     * @return direction 获胜方向（OVER/UNDER）
     */
    function _calculateLineWinner(uint256 line, uint256 totalGoalsScaled) internal pure returns (uint256 direction) {
        // 半球盘：直接比较
        return totalGoalsScaled > line ? OVER : UNDER;
    }

    // ============ 只读函数 ============

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        (uint256 lineIndex, uint256 direction) = _decodeOutcomeId(outcomeId);

        if (lineIndex >= lines.length) {
            revert InvalidLineIndex(lineIndex);
        }
        require(direction < 2, "OU_ML_V2: Invalid direction");

        // 构建储备数组
        uint256 overOutcomeId = _encodeOutcomeId(lineIndex, OVER);
        uint256 underOutcomeId = _encodeOutcomeId(lineIndex, UNDER);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = virtualReserves[overOutcomeId];
        reserves[1] = virtualReserves[underOutcomeId];

        // 如果储备为 0，初始化为最小值
        uint256 minReserve = 10 ** IERC20Metadata(address(settlementToken)).decimals();
        if (reserves[0] == 0) reserves[0] = minReserve;
        if (reserves[1] == 0) reserves[1] = minReserve;

        price = pricingEngine.getPrice(direction, reserves);
        return price;
    }

    /**
     * @notice 获取所有线的当前价格
     * @param direction 方向（OVER=0 或 UNDER=1）
     * @return linePrices 每条线的价格数组
     */
    function getAllLinePrices(uint256 direction) external view returns (uint256[] memory linePrices) {
        require(direction < 2, "OU_ML_V2: Invalid direction");

        linePrices = new uint256[](lines.length);
        uint256 minReserve = 10 ** IERC20Metadata(address(settlementToken)).decimals();

        for (uint256 i = 0; i < lines.length; i++) {
            uint256 overOutcomeId = _encodeOutcomeId(i, OVER);
            uint256 underOutcomeId = _encodeOutcomeId(i, UNDER);

            uint256[] memory reserves = new uint256[](2);
            reserves[0] = virtualReserves[overOutcomeId];
            reserves[1] = virtualReserves[underOutcomeId];

            // 如果储备为 0，初始化为最小值
            if (reserves[0] == 0) reserves[0] = minReserve;
            if (reserves[1] == 0) reserves[1] = minReserve;

            linePrices[i] = pricingEngine.getPrice(direction, reserves);
        }

        return linePrices;
    }

    /**
     * @notice 获取市场信息
     */
    function getMarketInfo()
        external
        view
        returns (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            uint256[] memory _lines,
            bytes32 _groupId,
            MarketStatus _status
        )
    {
        return (matchId, homeTeam, awayTeam, kickoffTime, lines, groupId, status);
    }

    /**
     * @notice 获取盘口线数组
     */
    function getLines() external view returns (uint256[] memory) {
        return lines;
    }

    /**
     * @notice 获取虚拟储备
     */
    function getVirtualReserves(uint256 outcomeId) external view returns (uint256) {
        return virtualReserves[outcomeId];
    }

    /**
     * @notice 检查是否应该锁盘
     */
    function shouldLock() external view returns (bool _shouldLock) {
        return block.timestamp >= kickoffTime - 5 minutes && status == MarketStatus.Open;
    }

    /**
     * @notice 解码 outcomeId（外部可调用）
     */
    function decodeOutcomeId(uint256 outcomeId) external pure returns (uint256 lineIndex, uint256 direction) {
        return _decodeOutcomeId(outcomeId);
    }

    /**
     * @notice 编码 outcomeId（外部可调用）
     */
    function encodeOutcomeId(uint256 lineIndex, uint256 direction) external pure returns (uint256 outcomeId) {
        return _encodeOutcomeId(lineIndex, direction);
    }

    // ============ 管理函数 ============

    /**
     * @notice 更新定价引擎
     */
    function setPricingEngine(address _pricingEngine) external onlyOwner {
        require(_pricingEngine != address(0), "OU_ML_V2: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 更新联动控制器
     */
    function setLinkedLinesController(address _controller) external onlyOwner {
        require(_controller != address(0), "OU_ML_V2: Invalid controller");
        emit LinkedLinesControllerUpdated(address(linkedLinesController), _controller);
        linkedLinesController = LinkedLinesController(_controller);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     */
    // autoLock() 继承自 MarketBase_V2
}
