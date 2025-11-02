// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";
import "../pricing/LinkedLinesController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title OU_MultiLine
 * @notice 大小球（Over/Under）多线市场模板
 * @dev 支持同一场比赛的多条盘口线（如 2.0、2.5、3.0 球）
 *      使用 LinkedLinesController 进行联动定价，防止套利
 *
 * 与单线版本的主要区别：
 * - 支持多条盘口线（lines[]）
 * - 每条线独立的 outcome IDs
 * - 集成 LinkedLinesController 进行价格联动
 * - 每条线独立结算，但共享流动性池
 *
 * Outcome ID 编码：
 * - outcomeId = lineIndex * 3 + direction
 * - direction: 0 = OVER, 1 = UNDER, 2 = PUSH
 *
 * 示例（3条线：2.0、2.5、3.0）：
 * - outcomeId 0 = 2.0球 OVER
 * - outcomeId 1 = 2.0球 UNDER
 * - outcomeId 2 = 2.0球 PUSH
 * - outcomeId 3 = 2.5球 OVER
 * - outcomeId 4 = 2.5球 UNDER
 * - outcomeId 5 = 2.5球 PUSH (不可能)
 * - outcomeId 6 = 3.0球 OVER
 * - outcomeId 7 = 3.0球 UNDER
 * - outcomeId 8 = 3.0球 PUSH
 */
contract OU_MultiLine is MarketBase {
    using SafeERC20 for IERC20;

    // ============ 常量 ============

    /// @notice 每条线的结果数量 (Over/Under/Push)
    uint256 private constant OUTCOMES_PER_LINE = 3;

    /// @notice Outcome 方向
    uint256 public constant OVER = 0;
    uint256 public constant UNDER = 1;
    uint256 public constant PUSH = 2;

    /// @notice 盘口精度（千分位，例如 2.5 = 2500）
    uint256 private constant LINE_PRECISION = 1000;

    // ============ 状态变量 ============

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 联动控制器
    LinkedLinesController public linkedLinesController;

    /// @notice 线组 ID
    bytes32 public groupId;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public immutable kickoffTime; // 开球时间

    /// @notice 盘口线数组（千分位表示）
    uint256[] private lines;

    /// @notice 线索引映射（line => lineIndex）
    mapping(uint256 => uint256) public lineToIndex;

    /// @notice 线是否为半球盘
    mapping(uint256 => bool) public isHalfLine;

    // ============ 事件 ============

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint256[] lines,
        bytes32 groupId,
        address pricingEngine,
        address linkedLinesController
    );

    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);
    event LinkedLinesControllerUpdated(address indexed oldController, address indexed newController);

    // ============ 错误 ============

    error InvalidLineIndex(uint256 lineIndex);
    error CannotBetOnPush();
    error InvalidLine(uint256 line);
    error LineNotFound(uint256 line);
    error NoLinesProvided();
    error LinesNotSorted();

    // ============ 构造函数 ============

    struct ConstructorParams {
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
        string uri;
    }

    /**
     * @notice 构造函数
     * @param params 构造参数结构体
     */
    constructor(ConstructorParams memory params)
        MarketBase(
            params.lines.length * OUTCOMES_PER_LINE,
            params.settlementToken,
            params.feeRecipient,
            params.feeRate,
            params.disputePeriod,
            params.uri
        )
    {
        require(bytes(params.matchId).length > 0, "OU_ML: Invalid match ID");
        require(bytes(params.homeTeam).length > 0, "OU_ML: Invalid home team");
        require(bytes(params.awayTeam).length > 0, "OU_ML: Invalid away team");
        require(params.kickoffTime > block.timestamp, "OU_ML: Kickoff time in past");
        if (params.lines.length == 0) revert NoLinesProvided();
        require(params.pricingEngine != address(0), "OU_ML: Invalid pricing engine");
        require(params.linkedLinesController != address(0), "OU_ML: Invalid controller");

        // 验证线数组从小到大排序
        for (uint256 i = 1; i < params.lines.length; i++) {
            if (params.lines[i] <= params.lines[i - 1]) {
                revert LinesNotSorted();
            }
            if (params.lines[i] == 0 || params.lines[i] > 20000) {
                revert InvalidLine(params.lines[i]);
            }
        }

        matchId = params.matchId;
        homeTeam = params.homeTeam;
        awayTeam = params.awayTeam;
        kickoffTime = params.kickoffTime;
        lines = params.lines;

        // 构建线索引映射和判断盘口类型
        for (uint256 i = 0; i < params.lines.length; i++) {
            lineToIndex[params.lines[i]] = i;
            isHalfLine[params.lines[i]] = (params.lines[i] % LINE_PRECISION) != 0;
        }

        pricingEngine = IPricingEngine(params.pricingEngine);
        linkedLinesController = LinkedLinesController(params.linkedLinesController);

        // 生成线组 ID
        groupId = keccak256(abi.encodePacked(params.matchId, block.timestamp, address(this)));

        emit MarketCreated(
            params.matchId,
            params.homeTeam,
            params.awayTeam,
            params.kickoffTime,
            params.lines,
            groupId,
            params.pricingEngine,
            params.linkedLinesController
        );
    }

    // ============ 实现抽象函数 ============

    /**
     * @notice 计算份额（调用定价引擎）
     * @param outcomeId 结果ID（编码为 lineIndex * 3 + direction）
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        view
        override
        returns (uint256 shares)
    {
        // 解码 outcomeId
        (uint256 lineIndex, uint256 direction) = _decodeOutcomeId(outcomeId);

        if (lineIndex >= lines.length) {
            revert InvalidLineIndex(lineIndex);
        }

        // Push 不允许下注
        if (direction == PUSH) {
            revert CannotBetOnPush();
        }

        // 构建储备数组（仅包含 Over 和 Under）
        uint256 overOutcomeId = _encodeOutcomeId(lineIndex, OVER);
        uint256 underOutcomeId = _encodeOutcomeId(lineIndex, UNDER);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[overOutcomeId];
        reserves[1] = outcomeLiquidity[underOutcomeId];

        // 如果储备为 0，初始化为最小值（使用与 settlement token 相同的单位）
        uint256 minReserve = 10 ** IERC20Metadata(address(settlementToken)).decimals();
        if (reserves[0] == 0) reserves[0] = minReserve;
        if (reserves[1] == 0) reserves[1] = minReserve;

        // 调用定价引擎（direction 是 0 或 1）
        shares = pricingEngine.calculateShares(direction, amount, reserves);

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 多线市场可能有多个获胜结果（不同线的 OVER/UNDER/PUSH）
     *      这里返回第一条线的获胜结果
     *      实际结算时需要检查每条线的结果
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        view
        override
        returns (uint256 winningOutcomeId)
    {
        // 计算总进球数
        uint256 totalGoals = uint256(facts.homeGoals) + uint256(facts.awayGoals);
        uint256 totalGoalsScaled = totalGoals * LINE_PRECISION;

        // 返回第一条线的获胜结果（用于 winningOutcome 状态变量）
        // 注意：多线市场中，每条线都需要单独判断
        uint256 line = lines[0];
        uint256 direction = _calculateLineWinner(line, totalGoalsScaled);

        return _encodeOutcomeId(0, direction);
    }

    // ============ 内部辅助函数 ============

    /**
     * @notice 编码 outcomeId
     * @param lineIndex 线索引
     * @param direction 方向（OVER/UNDER/PUSH）
     * @return outcomeId 编码后的 outcome ID
     */
    function _encodeOutcomeId(uint256 lineIndex, uint256 direction) internal pure returns (uint256 outcomeId) {
        return lineIndex * OUTCOMES_PER_LINE + direction;
    }

    /**
     * @notice 解码 outcomeId
     * @param outcomeId 编码的 outcome ID
     * @return lineIndex 线索引
     * @return direction 方向（OVER/UNDER/PUSH）
     */
    function _decodeOutcomeId(uint256 outcomeId) internal pure returns (uint256 lineIndex, uint256 direction) {
        lineIndex = outcomeId / OUTCOMES_PER_LINE;
        direction = outcomeId % OUTCOMES_PER_LINE;
        return (lineIndex, direction);
    }

    /**
     * @notice 计算单条线的获胜结果
     * @param line 盘口线
     * @param totalGoalsScaled 总进球数（千分位表示）
     * @return direction 获胜方向（OVER/UNDER/PUSH）
     */
    function _calculateLineWinner(uint256 line, uint256 totalGoalsScaled) internal view returns (uint256 direction) {
        bool _isHalfLine = isHalfLine[line];

        // 半球盘：直接比较
        if (_isHalfLine) {
            return totalGoalsScaled > line ? OVER : UNDER;
        }

        // 整数盘：需要处理 Push
        if (totalGoalsScaled > line) {
            return OVER;
        } else if (totalGoalsScaled < line) {
            return UNDER;
        } else {
            return PUSH;
        }
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
        require(direction < 2, "OU_ML: Push has no price");

        // 构建储备数组
        uint256 overOutcomeId = _encodeOutcomeId(lineIndex, OVER);
        uint256 underOutcomeId = _encodeOutcomeId(lineIndex, UNDER);

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = outcomeLiquidity[overOutcomeId];
        reserves[1] = outcomeLiquidity[underOutcomeId];

        // 如果储备为 0，初始化为最小值（使用与 settlement token 相同的单位）
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
        require(direction < 2, "OU_ML: Invalid direction");

        linePrices = new uint256[](lines.length);
        uint256 minReserve = 10 ** IERC20Metadata(address(settlementToken)).decimals();

        for (uint256 i = 0; i < lines.length; i++) {
            uint256 overOutcomeId = _encodeOutcomeId(i, OVER);
            uint256 underOutcomeId = _encodeOutcomeId(i, UNDER);

            uint256[] memory reserves = new uint256[](2);
            reserves[0] = outcomeLiquidity[overOutcomeId];
            reserves[1] = outcomeLiquidity[underOutcomeId];

            // 如果储备为 0，初始化为最小值（使用与 settlement token 相同的单位）
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

    // ============ 兑付逻辑说明 ============

    /**
     * @dev 多线市场的兑付逻辑
     *
     * V1 实现（当前版本）：
     * - 使用 MarketBase 的标准兑付逻辑
     * - winningOutcome 存储第一条线的获胜结果作为默认值
     * - 所有用户按标准流程兑付
     *
     * V2 完整实现（未来扩展）：
     * - 为每条线独立跟踪获胜结果
     * - 支持每条线独立结算和兑付
     * - 支持整数线的 Push 退款
     * - 需要重写 redeem() 函数，根据 outcomeId 解码线索引并查询该线的结果
     *
     * 注意：当前版本已支持多线下注和价格查询，满足基本功能需求
     *      完整的多线独立结算需要更复杂的状态管理和 Gas 优化
     */

    // ============ 管理函数 ============

    /**
     * @notice 更新定价引擎
     */
    function setPricingEngine(address _pricingEngine)
        external
        onlyOwner
        onlyStatus(MarketStatus.Open)
    {
        require(_pricingEngine != address(0), "OU_ML: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 更新联动控制器
     */
    function setLinkedLinesController(address _controller)
        external
        onlyOwner
        onlyStatus(MarketStatus.Open)
    {
        require(_controller != address(0), "OU_ML: Invalid controller");
        emit LinkedLinesControllerUpdated(address(linkedLinesController), _controller);
        linkedLinesController = LinkedLinesController(_controller);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     */
    function autoLock() external {
        require(block.timestamp >= kickoffTime - 5 minutes, "OU_ML: Too early to lock");
        require(status == MarketStatus.Open, "OU_ML: Market not open");

        status = MarketStatus.Locked;
        lockTimestamp = block.timestamp;
        emit Locked(block.timestamp);
    }
}
