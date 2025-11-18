// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../pricing/LMSR.sol";
import "../interfaces/IResultOracle.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// ============================================================================
// Custom Errors
// ============================================================================

error InvalidMatchId();
error InvalidTeamName();
error KickoffTimeInPast();
error InvalidScoreRange();
error InvalidOutcomeIndex();
error InvalidOutcomeId();
error ProbabilitiesLengthMismatch();
error ProbabilitiesSumInvalid();

/**
 * @title ScoreTemplate
 * @notice 精确比分市场模板
 * @dev 支持 25-50 个可能的比分结果，使用 LMSR 定价引擎
 *
 * Outcome ID 编码方案:
 * - 标准比分: outcomeId = homeGoals * 10 + awayGoals
 *   - 示例: 0-0 = 0, 1-0 = 10, 2-1 = 21, 3-2 = 32
 * - 特殊结果: 999 = Other (其他比分，超出范围)
 *
 * 支持的比分范围:
 * - 默认: 0-0 到 5-5 (36 个结果)
 * - 可配置: 最大支持 0-0 到 9-9
 * - 总是包含 "Other" 选项
 *
 * 示例市场:
 * - 曼联 vs 曼城
 * - outcomeId 0 = 0-0 (平局)
 * - outcomeId 10 = 1-0 (主队小胜)
 * - outcomeId 21 = 2-1 (主队胜)
 * - outcomeId 999 = Other (如 6-0, 7-1 等)
 *
 * @author PitchOne Team
 * @custom:security-contact security@pitchone.io
 */
contract ScoreTemplate is MarketBase {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice Other 结果的 Outcome ID
    uint256 public constant OTHER_OUTCOME_ID = 999;

    /// @notice 最小比分范围 (0-2, 即 0-0 到 2-2)
    uint8 public constant MIN_SCORE_RANGE = 2;

    /// @notice 最大比分范围 (0-9, 即 0-0 到 9-9)
    uint8 public constant MAX_SCORE_RANGE = 9;

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice LMSR 定价引擎
    LMSR public lmsrEngine;

    /// @notice 比赛信息
    string public matchId;      // 比赛ID（如 "EPL_2024_MUN_vs_MCI"）
    string public homeTeam;     // 主队
    string public awayTeam;     // 客队
    uint256 public kickoffTime; // 开球时间（Unix 时间戳）

    /// @notice 比分范围 (如 5 表示 0-0 到 5-5)
    uint8 public maxGoals;

    /// @notice 有效的 Outcome IDs (用于验证和迭代)
    uint256[] public validOutcomeIds;

    /// @notice Outcome ID 到数组索引的映射
    mapping(uint256 => uint256) public outcomeIdToIndex;

    /// @notice Outcome ID 是否有效
    mapping(uint256 => bool) public isValidOutcome;

    // ============================================================================
    // 事件
    // ============================================================================

    /// @notice 市场创建事件
    event ScoreMarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        uint8 maxGoals,
        uint256 outcomeCount,
        address lmsrEngine
    );

    /// @notice 比分下注事件
    event ScoreBetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint8 homeGoals,
        uint8 awayGoals,
        uint256 amount,
        uint256 shares
    );

    /// @notice LMSR 引擎更新事件
    event LMSREngineUpdated(address indexed oldEngine, address indexed newEngine);

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 禁用初始化器的构造函数
     */
    constructor() {
        // 允许在测试中直接实例化
    }

    /**
     * @notice 初始化函数
     * @param _matchId 比赛ID
     * @param _homeTeam 主队名称
     * @param _awayTeam 客队名称
     * @param _kickoffTime 开球时间
     * @param _maxGoals 最大进球数范围 (如 5 表示 0-0 到 5-5)
     * @param _settlementToken 结算币种
     * @param _feeRecipient 费用接收地址
     * @param _feeRate 手续费率（基点）
     * @param _disputePeriod 争议期（秒）
     * @param _liquidityB LMSR 流动性参数
     * @param _initialProbabilities 初始概率分布（基点，总和 = 10000）
     * @param _uri ERC-1155 元数据 URI
     * @param _owner 合约所有者
     */
    function initialize(
        string memory _matchId,
        string memory _homeTeam,
        string memory _awayTeam,
        uint256 _kickoffTime,
        uint8 _maxGoals,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        uint256 _liquidityB,
        uint256[] memory _initialProbabilities,
        string memory _uri,
        address _owner
    ) public initializer {
        if (bytes(_matchId).length == 0) revert InvalidMatchId();
        if (bytes(_homeTeam).length == 0) revert InvalidTeamName();
        if (bytes(_awayTeam).length == 0) revert InvalidTeamName();
        if (_kickoffTime <= block.timestamp) revert KickoffTimeInPast();
        if (_maxGoals < MIN_SCORE_RANGE || _maxGoals > MAX_SCORE_RANGE) {
            revert InvalidScoreRange();
        }

        // 计算结果数量: (maxGoals+1)^2 + 1 (Other)
        uint256 _outcomeCount = uint256(_maxGoals + 1) * uint256(_maxGoals + 1) + 1;

        // 初始化 MarketBase
        __MarketBase_init(
            _outcomeCount,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _uri,
            _owner
        );

        // 设置市场信息
        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        maxGoals = _maxGoals;

        // 构建有效的 Outcome IDs
        _buildOutcomeIds(_maxGoals);

        // 部署 LMSR 引擎
        lmsrEngine = new LMSR(_liquidityB, _outcomeCount);

        // 初始化 LMSR 持仓量
        uint256[] memory initialQuantities = _convertProbabilitiesToQuantities(
            _initialProbabilities,
            _liquidityB
        );
        lmsrEngine.initializeQuantities(initialQuantities);

        emit ScoreMarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _maxGoals,
            _outcomeCount,
            address(lmsrEngine)
        );
    }

    // ============================================================================
    // 实现抽象函数
    // ============================================================================

    /**
     * @notice 计算份额（调用 LMSR 引擎）
     * @param outcomeId 结果ID（MarketBase 使用索引 0 到 outcomeCount-1）
     * @param amount 净金额（已扣除手续费，USDC 6 decimals）
     * @return shares 获得的份额（WAD 精度 1e18）
     *
     * @dev 注意：
     *      - MarketBase 传入的 outcomeId 是索引 (0 到 outcomeCount-1)
     *      - 我们需要将其映射到实际的比分编码
     *      - amount: USDC 单位（6 decimals）
     *      - LMSR: 内部使用 WAD 精度（18 decimals）
     *      - shares: 返回 WAD 精度
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        override
        returns (uint256 shares)
    {
        // outcomeId 是索引，需要映射到实际的比分编码
        if (outcomeId >= validOutcomeIds.length) revert InvalidOutcomeIndex();
        uint256 actualOutcomeId = validOutcomeIds[outcomeId];

        // 将 USDC (6 decimals) 转换为 WAD (18 decimals)
        uint256 decimals = IERC20Metadata(address(settlementToken)).decimals();
        uint256 amountWAD = (amount * 1e18) / (10 ** decimals);

        // 调用 LMSR 计算 shares（使用索引）
        uint256[] memory reserves = new uint256[](0); // LMSR 不使用此参数
        shares = lmsrEngine.calculateShares(outcomeId, amountWAD, reserves);

        // 更新 LMSR 持仓量（使用索引）
        lmsrEngine.updateQuantity(outcomeId, shares);

        // 发出比分下注事件
        (uint8 homeGoals, uint8 awayGoals) = _decodeOutcomeId(actualOutcomeId);
        emit ScoreBetPlaced(msg.sender, actualOutcomeId, homeGoals, awayGoals, amount, shares);

        return shares;
    }

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID（索引，0 到 outcomeCount-1）
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getCurrentPrice(uint256 outcomeId)
        external
        view
        returns (uint256 price)
    {
        if (outcomeId >= validOutcomeIds.length) revert InvalidOutcomeId();

        uint256[] memory reserves = new uint256[](0);
        return lmsrEngine.getPrice(outcomeId, reserves);
    }

    /**
     * @notice 根据比分获取价格
     * @param homeGoals 主队进球数
     * @param awayGoals 客队进球数
     * @return price 价格（基点）
     */
    function getPriceByScore(uint8 homeGoals, uint8 awayGoals)
        external
        view
        returns (uint256 price)
    {
        uint256 actualOutcomeId = determineWinningOutcome(homeGoals, awayGoals);
        uint256 index = outcomeIdToIndex[actualOutcomeId];

        uint256[] memory reserves = new uint256[](0);
        return lmsrEngine.getPrice(index, reserves);
    }

    // ============================================================================
    // 比分编码/解码
    // ============================================================================

    /**
     * @notice 编码比分为 Outcome ID
     * @param homeGoals 主队进球数
     * @param awayGoals 客队进球数
     * @return outcomeId 结果ID
     */
    function encodeScore(uint8 homeGoals, uint8 awayGoals)
        public
        pure
        returns (uint256 outcomeId)
    {
        // 标准比分: homeGoals * 10 + awayGoals
        return uint256(homeGoals) * 10 + uint256(awayGoals);
    }

    /**
     * @notice 解码 Outcome ID 为比分
     * @param outcomeId 结果ID
     * @return homeGoals 主队进球数
     * @return awayGoals 客队进球数
     */
    function _decodeOutcomeId(uint256 outcomeId)
        internal
        pure
        returns (uint8 homeGoals, uint8 awayGoals)
    {
        if (outcomeId == OTHER_OUTCOME_ID) {
            return (255, 255); // 特殊标记
        }

        homeGoals = uint8(outcomeId / 10);
        awayGoals = uint8(outcomeId % 10);
    }

    /**
     * @notice 检查比分是否在范围内
     * @param homeGoals 主队进球数
     * @param awayGoals 客队进球数
     * @return 是否在范围内
     */
    function isScoreInRange(uint8 homeGoals, uint8 awayGoals)
        public
        view
        returns (bool)
    {
        return homeGoals <= maxGoals && awayGoals <= maxGoals;
    }

    // ============================================================================
    // 结算函数
    // ============================================================================

    /**
     * @notice 根据比赛结果计算获胜结果ID（实现抽象函数）
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 从 facts 中提取 homeGoals 和 awayGoals，确定获胜比分
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        view
        override
        returns (uint256 winningOutcomeId)
    {
        return determineWinningOutcome(facts.homeGoals, facts.awayGoals);
    }

    /**
     * @notice 根据最终比分确定获胜结果
     * @param finalHomeGoals 最终主队进球数
     * @param finalAwayGoals 最终客队进球数
     * @return outcomeId 获胜结果ID
     */
    function determineWinningOutcome(uint8 finalHomeGoals, uint8 finalAwayGoals)
        public
        view
        returns (uint256 outcomeId)
    {
        if (isScoreInRange(finalHomeGoals, finalAwayGoals)) {
            // 标准比分
            return encodeScore(finalHomeGoals, finalAwayGoals);
        } else {
            // 超出范围，归为 Other
            return OTHER_OUTCOME_ID;
        }
    }

    // ============================================================================
    // 内部辅助函数
    // ============================================================================

    /**
     * @notice 构建有效的 Outcome IDs
     * @param _maxGoals 最大进球数
     */
    function _buildOutcomeIds(uint8 _maxGoals) private {
        // 清空数组（如果重新初始化）
        delete validOutcomeIds;

        uint256 index = 0;

        // 添加所有标准比分
        for (uint8 h = 0; h <= _maxGoals; h++) {
            for (uint8 a = 0; a <= _maxGoals; a++) {
                uint256 outcomeId = encodeScore(h, a);
                validOutcomeIds.push(outcomeId);
                outcomeIdToIndex[outcomeId] = index;
                isValidOutcome[outcomeId] = true;
                index++;
            }
        }

        // 添加 Other
        validOutcomeIds.push(OTHER_OUTCOME_ID);
        outcomeIdToIndex[OTHER_OUTCOME_ID] = index;
        isValidOutcome[OTHER_OUTCOME_ID] = true;
    }

    /**
     * @notice 将概率分布转换为 LMSR 初始持仓量
     * @param probabilities 概率数组（基点，总和应该 ≈ 10000）
     * @param liquidityB 流动性参数
     * @return quantities 持仓量数组（WAD 精度）
     *
     * @dev 使用简化公式: q_i = b * ln(p_i * C)
     *      其中 C 是归一化常数，简化为: q_i 正比于 ln(p_i)
     */
    function _convertProbabilitiesToQuantities(
        uint256[] memory probabilities,
        uint256 liquidityB
    ) private view returns (uint256[] memory quantities) {
        uint256 count = validOutcomeIds.length;

        // 如果未提供概率，使用均匀分布
        if (probabilities.length == 0) {
            quantities = new uint256[](count);
            uint256 uniformQuantity = 100 * 1e18; // 每个结果 100 份额
            for (uint256 i = 0; i < count; i++) {
                quantities[i] = uniformQuantity;
            }
            return quantities;
        }

        if (probabilities.length != count) revert ProbabilitiesLengthMismatch();

        // 验证概率总和 ≈ 100%
        uint256 totalProb = 0;
        for (uint256 i = 0; i < count; i++) {
            totalProb += probabilities[i];
        }
        if (totalProb < 9900 || totalProb > 10100) revert ProbabilitiesSumInvalid();

        // 转换概率为持仓量
        // 简化方案：q_i = baseQuantity * (p_i / avgProb)
        quantities = new uint256[](count);
        uint256 baseQuantity = 100 * 1e18; // 基础份额
        uint256 avgProb = 10000 / count;    // 平均概率

        for (uint256 i = 0; i < count; i++) {
            // 防止 probabilities[i] = 0
            if (probabilities[i] == 0) {
                quantities[i] = baseQuantity / 10; // 最小份额
            } else {
                // q_i = baseQuantity * (p_i / avgProb)
                quantities[i] = (baseQuantity * probabilities[i]) / avgProb;
            }
        }

        return quantities;
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 更新 LMSR 流动性参数（仅 owner）
     * @param newB 新的流动性参数
     */
    function setLiquidityB(uint256 newB) external onlyOwner {
        lmsrEngine.setLiquidityB(newB);
    }

    /**
     * @notice 获取所有结果的价格
     * @return prices 价格数组（基点）
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        return lmsrEngine.getAllPrices();
    }

    /**
     * @notice 获取所有有效的 Outcome IDs
     * @return 有效结果ID数组
     */
    function getValidOutcomeIds() external view returns (uint256[] memory) {
        return validOutcomeIds;
    }

    /**
     * @notice 获取 LMSR 当前成本
     * @return cost 当前成本（WAD 精度）
     */
    function getCurrentCost() external view returns (uint256 cost) {
        return lmsrEngine.getCurrentCost();
    }

}
