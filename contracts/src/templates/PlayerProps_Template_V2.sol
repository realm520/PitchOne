// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase_V2.sol";
import "../interfaces/IPricingEngine.sol";
import "../pricing/SimpleCPMM.sol";
import "../pricing/LMSR.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title PlayerProps_Template_V2
 * @notice 球员道具市场模板 V2
 * @dev 继承 MarketBase_V2，集成 LiquidityVault
 *
 * 核心改进：
 * - 从 Vault 借出初始流动性
 * - 市场结算后归还流动性+收益
 * - 支持滑点保护
 *
 * 支持球员个人数据相关的投注玩法
 *
 * 支持的道具类型：
 * 1. GOALS_OU      - 进球数大小（O/U）- 二/三向市场（SimpleCPMM）
 * 2. ASSISTS_OU    - 助攻数大小（O/U）- 二/三向市场（SimpleCPMM）
 * 3. SHOTS_OU      - 射门次数大小（O/U）- 二/三向市场（SimpleCPMM）
 * 4. YELLOW_CARD   - 黄牌 Yes/No - 二向市场（SimpleCPMM）
 * 5. RED_CARD      - 红牌 Yes/No - 二向市场（SimpleCPMM）
 * 6. ANYTIME_SCORER - 任意时间进球 Yes/No - 二向市场（SimpleCPMM）
 * 7. FIRST_SCORER  - 首位进球者 - 多向市场（LMSR）
 *
 * Outcome IDs:
 * - O/U 市场（半球盘，如 0.5, 1.5）:
 *   0: Over, 1: Under
 * - O/U 市场（整球盘，如 1.0, 2.0）:
 *   0: Over, 1: Push, 2: Under
 * - Yes/No 市场:
 *   0: Yes, 1: No
 * - 首位进球者（LMSR）:
 *   0 ~ (playerCount-1): 各球员索引
 *   playerCount: 无进球 (No Scorer)
 */
contract PlayerProps_Template_V2 is MarketBase_V2 {
    // ============ 枚举 ============

    /// @notice 道具类型
    enum PropType {
        GOALS_OU,        // 进球数大小
        ASSISTS_OU,      // 助攻数大小
        SHOTS_OU,        // 射门次数大小
        YELLOW_CARD,     // 黄牌 Yes/No
        RED_CARD,        // 红牌 Yes/No
        ANYTIME_SCORER,  // 任意时间进球 Yes/No
        FIRST_SCORER     // 首位进球者（多向）
    }

    // ============ 常量 ============

    /// @notice Outcome 固定值
    uint256 private constant OUTCOME_OVER = 0;
    uint256 private constant OUTCOME_PUSH = 1;
    uint256 private constant OUTCOME_UNDER = 2;
    uint256 private constant OUTCOME_YES = 0;
    uint256 private constant OUTCOME_NO = 1;

    // ============ 状态变量 ============

    /// @notice 默认初始借款金额（从 Vault 借出，动态计算）
    uint256 private defaultBorrowAmount;

    /// @notice 虚拟储备初始值（SimpleCPMM 使用，动态计算）
    uint256 private virtualReserveInit;

    /// @notice 定价引擎（SimpleCPMM 或 LMSR）
    IPricingEngine public pricingEngine;

    /// @notice 虚拟储备（SimpleCPMM 使用）
    mapping(uint256 => uint256) public virtualReserves;

    /// @notice 比赛信息
    string public matchId;       // 比赛ID（如 "EPL_2024_MUN_vs_MCI"）
    // kickoffTime 继承自 MarketBase_V2

    /// @notice 球员信息
    string public playerId;      // 球员ID（如 "player_haaland"）
    string public playerName;    // 球员姓名（如 "Erling Haaland"）

    /// @notice 道具配置
    PropType public propType;    // 道具类型
    uint256 public line;         // 盘口线（仅 O/U 使用，WAD 精度 1e18）

    /// @notice 首位进球者市场专用
    string[] public playerIds;   // 所有候选球员 ID（仅 FIRST_SCORER 使用）
    string[] public playerNames; // 所有候选球员名称（仅 FIRST_SCORER 使用）

    // ============ 事件 ============

    /// @notice 市场创建事件
    event PlayerPropsMarketCreated(
        string indexed matchId,
        string indexed playerId,
        PropType indexed propType,
        uint256 line,
        uint256 outcomeCount,
        address vault
    );

    /// @notice 下注事件
    event PlayerPropsBetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        string outcomeName,
        uint256 amount,
        uint256 shares
    );

    /// @notice 结算事件
    event PlayerPropsResolved(
        string indexed playerId,
        PropType indexed propType,
        uint256 indexed winningOutcomeId,
        uint256 actualValue
    );

    /// @notice 虚拟储备更新事件
    event VirtualReservesUpdated(uint256 indexed outcomeId, uint256 newReserve);

    // ============ 初始化 ============

    /// @notice 初始化数据结构
    struct PlayerPropsInitData {
        string matchId;
        string playerId;
        string playerName;
        PropType propType;
        uint256 line;               // O/U 盘口线（WAD），其他类型为 0
        uint256 kickoffTime;
        address settlementToken;    // 结算代币地址
        address feeRecipient;       // 费用接收地址
        uint256 feeRate;            // 手续费率（基点）
        uint256 disputePeriod;      // 争议期（秒）
        address vault;              // Vault 地址
        string uri;                 // ERC-1155 元数据 URI
        address pricingEngineAddr;  // SimpleCPMM 或 LMSR 地址
        uint256[] initialReserves;  // SimpleCPMM 初始储备 或 LMSR 初始份额
        string[] playerIds;         // FIRST_SCORER 候选球员 ID（其他类型为空）
        string[] playerNames;       // FIRST_SCORER 候选球员名称（其他类型为空）
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 注意：不调用 _disableInitializers() 以允许在测试中直接实例化
        // initializer 修饰符已经足够防止重复初始化
    }

    /**
     * @notice 初始化球员道具市场
     * @param data 初始化数据
     */
    function initialize(PlayerPropsInitData memory data) external initializer {
        // 验证参数
        require(bytes(data.matchId).length > 0, "PlayerProps_V2: Invalid match ID");
        require(bytes(data.playerId).length > 0 || data.propType == PropType.FIRST_SCORER,
            "PlayerProps_V2: Invalid player ID");
        require(data.kickoffTime > block.timestamp, "PlayerProps_V2: Kickoff time in past");
        require(data.pricingEngineAddr != address(0), "PlayerProps_V2: Invalid pricing engine");

        // 验证道具类型特定参数
        if (_isOUType(data.propType)) {
            require(data.line > 0, "PlayerProps_V2: Invalid line for O/U");
        }
        if (data.propType == PropType.FIRST_SCORER) {
            require(data.playerIds.length >= 2, "PlayerProps_V2: Need at least 2 players");
            require(data.playerIds.length == data.playerNames.length, "PlayerProps_V2: Mismatched player arrays");
        }

        // 设置基本信息
        matchId = data.matchId;
        playerId = data.playerId;
        playerName = data.playerName;
        propType = data.propType;
        line = data.line;
        kickoffTime = data.kickoffTime;
        pricingEngine = IPricingEngine(data.pricingEngineAddr);

        // 首位进球者市场特殊处理
        if (data.propType == PropType.FIRST_SCORER) {
            playerIds = data.playerIds;
            playerNames = data.playerNames;
        }

        // 确定 outcomeCount
        uint256 _outcomeCount = _getOutcomeCount(data.propType, data.line, data.playerIds.length);

        // 初始化 MarketBase_V2
        __MarketBase_init(
            _outcomeCount,
            data.settlementToken,
            data.feeRecipient,
            data.feeRate,
            data.disputePeriod,
            data.vault,
            data.uri
        );

        // 计算动态代币精度参数
        uint8 decimals = IERC20Metadata(data.settlementToken).decimals();
        uint256 tokenUnit = 10 ** decimals;
        defaultBorrowAmount = 100_000 * tokenUnit;
        virtualReserveInit = 100_000 * tokenUnit;

        // 初始化定价引擎
        if (_isLMSRType(data.propType)) {
            // LMSR 初始化
            LMSR(data.pricingEngineAddr).initializeQuantities(data.initialReserves);
        } else {
            // SimpleCPMM 初始化虚拟储备
            if (data.initialReserves.length == _outcomeCount) {
                for (uint256 i = 0; i < _outcomeCount; i++) {
                    virtualReserves[i] = data.initialReserves[i];
                }
            } else {
                // 使用默认值
                for (uint256 i = 0; i < _outcomeCount; i++) {
                    virtualReserves[i] = virtualReserveInit;
                }
            }
        }

        emit PlayerPropsMarketCreated(data.matchId, data.playerId, data.propType, data.line, _outcomeCount, data.vault);
    }

    // ============ 核心功能 ============

    /**
     * @notice 计算用户下注获得的份额
     * @param outcomeId 结果ID
     * @param amount 下注金额（USDC，6 decimals）
     * @return shares 用户获得的份额（WAD 精度）
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        override
        returns (uint256 shares)
    {
        require(outcomeId < outcomeCount, "PlayerProps_V2: Invalid outcome");

        // 单位转换：USDC 6 decimals → WAD 18 decimals
        uint256 decimals = IERC20Metadata(address(settlementToken)).decimals();
        uint256 amountWAD = (amount * 1e18) / (10 ** decimals);

        if (_isLMSRType(propType)) {
            // LMSR 定价
            uint256[] memory reserves = new uint256[](0); // LMSR 不使用此参数

            // 1. 调用 LMSR 计算 shares
            shares = pricingEngine.calculateShares(outcomeId, amountWAD, reserves);

            // 2. 调用定价引擎更新储备（LMSR 内部更新 quantityShares）
            pricingEngine.updateReserves(outcomeId, amountWAD, shares, reserves);
        } else {
            // SimpleCPMM 定价
            uint256[] memory reserves = new uint256[](outcomeCount);
            for (uint256 i = 0; i < outcomeCount; i++) {
                reserves[i] = virtualReserves[i];
            }

            // 1. 调用定价引擎计算份额
            shares = pricingEngine.calculateShares(outcomeId, amountWAD, reserves);

            // 2. 调用定价引擎更新储备（由引擎决定更新逻辑）
            uint256[] memory newReserves = pricingEngine.updateReserves(
                outcomeId,
                amountWAD,
                shares,
                reserves
            );

            // 3. 将更新后的储备写回数组
            for (uint256 i = 0; i < outcomeCount; i++) {
                virtualReserves[i] = newReserves[i];
                emit VirtualReservesUpdated(i, virtualReserves[i]);
            }
        }

        // 发出下注事件
        emit PlayerPropsBetPlaced(
            msg.sender,
            outcomeId,
            _getOutcomeName(outcomeId),
            amount,
            shares
        );

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
     * @notice 计算获胜结果
     * @param facts 比赛结果数据（包含球员数据）
     * @return winningOutcomeId 获胜的 Outcome ID
     */
    function calculateWinner(IResultOracle.MatchFacts memory facts)
        external
        view
        returns (uint256 winningOutcomeId)
    {
        // 查找当前球员的统计数据
        IResultOracle.PlayerStats memory stats = _findPlayerStats(facts.playerStats);

        uint256 actualValue;

        if (propType == PropType.GOALS_OU) {
            actualValue = stats.goals;
            return _resolveOUMarket(actualValue);
        } else if (propType == PropType.ASSISTS_OU) {
            actualValue = stats.assists;
            return _resolveOUMarket(actualValue);
        } else if (propType == PropType.SHOTS_OU) {
            actualValue = stats.shots;
            return _resolveOUMarket(actualValue);
        } else if (propType == PropType.YELLOW_CARD) {
            return stats.yellowCard ? OUTCOME_YES : OUTCOME_NO;
        } else if (propType == PropType.RED_CARD) {
            return stats.redCard ? OUTCOME_YES : OUTCOME_NO;
        } else if (propType == PropType.ANYTIME_SCORER) {
            return stats.goals > 0 ? OUTCOME_YES : OUTCOME_NO;
        } else if (propType == PropType.FIRST_SCORER) {
            // 查找首位进球者
            return _findFirstScorer(facts.playerStats);
        }

        revert("PlayerProps_V2: Unknown prop type");
    }

    /**
     * @notice 从球员统计数组中查找当前球员的数据
     * @param allStats 所有球员统计数据
     * @return stats 当前球员的统计数据
     */
    function _findPlayerStats(IResultOracle.PlayerStats[] memory allStats)
        internal
        view
        returns (IResultOracle.PlayerStats memory stats)
    {
        for (uint256 i = 0; i < allStats.length; i++) {
            if (_compareStrings(allStats[i].playerId, playerId)) {
                return allStats[i];
            }
        }
        // 如果未找到球员数据，返回空统计（所有值为 0/false）
        return IResultOracle.PlayerStats({
            playerId: playerId,
            goals: 0,
            assists: 0,
            shots: 0,
            shotsOnTarget: 0,
            yellowCard: false,
            redCard: false,
            isFirstScorer: false,
            minuteFirstGoal: 0
        });
    }

    /**
     * @notice 查找首位进球者（FIRST_SCORER 市场专用）
     * @param allStats 所有球员统计数据
     * @return outcomeId 首位进球者的 Outcome ID
     */
    function _findFirstScorer(IResultOracle.PlayerStats[] memory allStats)
        internal
        view
        returns (uint256 outcomeId)
    {
        uint8 minMinute = 255; // 最早进球时间
        uint256 scorerIndex = playerIds.length; // 默认为 "No Scorer"

        for (uint256 i = 0; i < allStats.length; i++) {
            if (allStats[i].isFirstScorer) {
                // 查找该球员在 playerIds 中的索引
                for (uint256 j = 0; j < playerIds.length; j++) {
                    if (_compareStrings(allStats[i].playerId, playerIds[j])) {
                        // 如果有多个球员同时进球，取最早的
                        if (allStats[i].minuteFirstGoal < minMinute) {
                            minMinute = allStats[i].minuteFirstGoal;
                            scorerIndex = j;
                        }
                        break;
                    }
                }
            }
        }

        return scorerIndex;
    }

    /**
     * @notice 比较两个字符串是否相等
     */
    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /**
     * @notice 解决 O/U 市场的获胜结果
     * @param actualValue 实际值（WAD 精度）
     * @return winningOutcomeId 获胜 Outcome ID
     */
    function _resolveOUMarket(uint256 actualValue) internal view returns (uint256) {
        uint256 actualValueWAD = actualValue * 1e18; // 转为 WAD 精度

        if (actualValueWAD > line) {
            return OUTCOME_OVER; // 0
        } else if (actualValueWAD < line) {
            // 检查是否为整数盘口
            if (_isWholeNumberLine(line)) {
                return OUTCOME_UNDER; // 2（三向市场）
            } else {
                return OUTCOME_UNDER; // 1（二向市场）
            }
        } else {
            // 整数盘口，走水
            require(_isWholeNumberLine(line), "PlayerProps_V2: Unexpected Push");
            return OUTCOME_PUSH; // 1
        }
    }

    // ============ 查询功能 ============

    /**
     * @notice 获取当前价格
     * @param outcomeId 结果ID
     * @return price 价格（基点，0-10000）
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        require(outcomeId < outcomeCount, "PlayerProps_V2: Invalid outcome");

        if (_isLMSRType(propType)) {
            uint256[] memory reserves = new uint256[](0);
            return pricingEngine.getPrice(outcomeId, reserves);
        } else {
            uint256[] memory reserves = new uint256[](outcomeCount);
            for (uint256 i = 0; i < outcomeCount; i++) {
                reserves[i] = virtualReserves[i];
            }
            return pricingEngine.getPrice(outcomeId, reserves);
        }
    }

    /**
     * @notice 获取所有结果的价格
     * @return prices 价格数组（基点）
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        prices = new uint256[](outcomeCount);

        if (_isLMSRType(propType)) {
            return LMSR(address(pricingEngine)).getAllPrices();
        } else {
            uint256[] memory reserves = new uint256[](outcomeCount);
            for (uint256 i = 0; i < outcomeCount; i++) {
                reserves[i] = virtualReserves[i];
            }
            for (uint256 i = 0; i < outcomeCount; i++) {
                prices[i] = pricingEngine.getPrice(i, reserves);
            }
        }
    }

    /**
     * @notice 获取虚拟储备
     */
    function getVirtualReserve(uint256 outcomeId) external view returns (uint256) {
        return virtualReserves[outcomeId];
    }

    // ============ 辅助函数 ============

    /**
     * @notice 判断是否为 O/U 类型
     */
    function _isOUType(PropType _propType) internal pure returns (bool) {
        return _propType == PropType.GOALS_OU ||
               _propType == PropType.ASSISTS_OU ||
               _propType == PropType.SHOTS_OU;
    }

    /**
     * @notice 判断是否使用 LMSR
     */
    function _isLMSRType(PropType _propType) internal pure returns (bool) {
        return _propType == PropType.FIRST_SCORER;
    }

    /**
     * @notice 判断是否为整数盘口线
     */
    function _isWholeNumberLine(uint256 _line) internal pure returns (bool) {
        return _line % 1e18 == 0;
    }

    /**
     * @notice 获取 outcomeCount
     */
    function _getOutcomeCount(PropType _propType, uint256 _line, uint256 playerCount)
        internal
        pure
        returns (uint256)
    {
        if (_propType == PropType.FIRST_SCORER) {
            return playerCount + 1; // N 个球员 + 无进球
        } else if (_isOUType(_propType)) {
            return _isWholeNumberLine(_line) ? 3 : 2; // 整数盘口 3 向，半球盘 2 向
        } else {
            return 2; // Yes/No
        }
    }

    /**
     * @notice 获取道具类型名称
     */
    function _getPropTypeName(PropType _propType) internal pure returns (string memory) {
        if (_propType == PropType.GOALS_OU) return "Goals O/U";
        if (_propType == PropType.ASSISTS_OU) return "Assists O/U";
        if (_propType == PropType.SHOTS_OU) return "Shots O/U";
        if (_propType == PropType.YELLOW_CARD) return "Yellow Card";
        if (_propType == PropType.RED_CARD) return "Red Card";
        if (_propType == PropType.ANYTIME_SCORER) return "Anytime Scorer";
        if (_propType == PropType.FIRST_SCORER) return "First Scorer";
        return "Unknown";
    }

    /**
     * @notice 获取结果名称
     */
    function _getOutcomeName(uint256 outcomeId) internal view returns (string memory) {
        if (propType == PropType.FIRST_SCORER) {
            if (outcomeId < playerIds.length) {
                return playerNames[outcomeId];
            } else {
                return "No Scorer";
            }
        } else if (_isOUType(propType)) {
            if (outcomeCount == 2) {
                return outcomeId == 0 ? "Over" : "Under";
            } else {
                if (outcomeId == 0) return "Over";
                if (outcomeId == 1) return "Push";
                return "Under";
            }
        } else {
            return outcomeId == 0 ? "Yes" : "No";
        }
    }

    // ============ 管理函数 ============

    /**
     * @notice 自动锁盘（Keeper 调用）
     */
    // autoLock() 继承自 MarketBase_V2
}
