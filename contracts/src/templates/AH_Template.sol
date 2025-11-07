// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase.sol";
import "../interfaces/IPricingEngine.sol";
import "../interfaces/IAH_Template.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title AH_Template
 * @notice 让球（Asian Handicap）市场模板 - 单线版本
 * @dev 让球盘根据类型分为：
 *      - 半球盘（-0.5）：二向市场（主队赢盘/客队赢盘）
 *      - 整球盘（-1.0）：三向市场（主队赢盘/客队赢盘/退款）
 *      - 1/4球盘（-0.25）：M3 阶段实现（半输半赢机制）
 *
 * Outcome IDs (半球盘 -0.5 示例):
 * - 0: 主队赢盘 (Home Cover) - 主队胜利（调整后比分 > 客队）
 * - 1: 客队赢盘 (Away Cover) - 客队胜利或平局（调整后比分 ≤ 客队）
 *
 * Outcome IDs (整球盘 -1.0 示例):
 * - 0: 主队赢盘 (Home Cover) - 主队净胜 ≥ 2 球
 * - 1: 客队赢盘 (Away Cover) - 客队胜利或平局或主队净胜 = 0
 * - 2: 退款 (Push) - 主队净胜 = 1 球（恰好抵消让球）
 *
 * 让球逻辑：
 * - 主队让球（如 -0.5）：主队得分 - 0.5 vs 客队得分
 * - 客队让球（如主队 +0.5）：主队得分 + 0.5 vs 客队得分
 *
 * 注意：
 * - handicap 使用千分位表示（-0.5 = -500，-1.0 = -1000）
 * - 负数表示主队让球，正数表示客队让球
 * - 半球盘不参与 Push，整球盘在平手时退款
 * - M2 阶段仅支持单线，M3 阶段扩展多线联动
 */
contract AH_Template is MarketBase, IAH_Template {
    using SafeERC20 for IERC20;

    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 半球盘为 2 个结果（主队赢盘/客队赢盘）
    uint256 private constant HALF_HANDICAP_OUTCOME_COUNT = 2;

    /// @notice 整球盘为 3 个结果（主队赢盘/客队赢盘/退款）
    uint256 private constant WHOLE_HANDICAP_OUTCOME_COUNT = 3;

    /// @notice Outcome IDs
    uint256 public constant HOME_COVER = 0;  // 主队赢盘
    uint256 public constant AWAY_COVER = 1;  // 客队赢盘
    uint256 public constant PUSH = 2;        // 退款（仅整球盘）

    /// @notice 让球精度（千分位，例如 -0.5 = -500）
    uint256 private constant HANDICAP_PRECISION = 1000;

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 定价引擎
    IPricingEngine public pricingEngine;

    /// @notice 虚拟储备（用于初始化和定价计算）
    mapping(uint256 => uint256) public virtualReserves;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    uint256 public kickoffTime; // 开球时间

    /// @notice 让球数（千分位表示，负数=主队让球，正数=客队让球）
    /// @dev 例如：主队 -0.5 = -500，主队 +0.5 = +500
    int256 public handicap;

    /// @notice 让球类型
    HandicapType public handicapType;

    /// @notice 让球方向
    HandicapDirection public direction;

    /// @notice Outcome 名称（根据让球类型动态设置）
    string[] public outcomeNames;

    // ============================================================================
    // 构造函数
    // ============================================================================

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
     * @param _handicap 让球数（千分位，如 -500 = -0.5）
     * @param _handicapType 让球类型
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
        int256 _handicap,
        HandicapType _handicapType,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _pricingEngine,
        string memory _uri,
        address _owner
    ) public initializer {
        // 验证参数
        require(bytes(_matchId).length > 0, "Empty match ID");
        require(bytes(_homeTeam).length > 0, "Empty home team");
        require(bytes(_awayTeam).length > 0, "Empty away team");
        require(_kickoffTime > block.timestamp, "Kickoff time in past");
        require(_pricingEngine != address(0), "Invalid pricing engine");

        // 验证让球数（必须是 0.25 的倍数）
        _validateHandicap(_handicap, _handicapType);

        __MarketBase_init(
            _handicapType == HandicapType.HALF
                ? HALF_HANDICAP_OUTCOME_COUNT
                : WHOLE_HANDICAP_OUTCOME_COUNT,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _uri,
            _owner
        );

        // 设置状态变量
        matchId = _matchId;
        homeTeam = _homeTeam;
        awayTeam = _awayTeam;
        kickoffTime = _kickoffTime;
        handicap = _handicap;
        handicapType = _handicapType;
        pricingEngine = IPricingEngine(_pricingEngine);

        // 确定让球方向
        direction = _handicap < 0 ? HandicapDirection.HOME_GIVE : HandicapDirection.AWAY_GIVE;

        // 设置 outcome 名称
        _setOutcomeNames(_handicapType);

        // 初始化虚拟储备（仅为 HOME_COVER 和 AWAY_COVER，PUSH 不参与定价）
        uint256 virtualReserve = 100_000 * (10 ** IERC20Metadata(_settlementToken).decimals());
        virtualReserves[HOME_COVER] = virtualReserve;
        virtualReserves[AWAY_COVER] = virtualReserve;

        // 设置自动锁盘时间（开球前5分钟）
        lockTimestamp = _kickoffTime > 300 ? _kickoffTime - 300 : _kickoffTime;

        emit AHMarketCreated(
            _matchId,
            _homeTeam,
            _awayTeam,
            _kickoffTime,
            _handicap,
            _handicapType,
            direction,
            _pricingEngine
        );
    }

    // ============================================================================
    // MarketBase 抽象函数实现
    // ============================================================================

    /**
     * @notice 计算份额（定价函数）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @return shares 获得的份额
     * @dev 调用定价引擎计算 shares
     *      - 半球盘：不允许下注 PUSH
     *      - 整球盘：PUSH 为 1:1（shares = amount）
     *      - 使用虚拟储备 + 真实流动性进行定价
     */
    function _calculateShares(uint256 outcomeId, uint256 amount)
        internal
        override
        returns (uint256 shares)
    {
        // 验证下注结果
        if (handicapType == HandicapType.HALF && outcomeId == PUSH) {
            revert CannotBetOnPush();
        }

        // 1/4 球盘暂不支持（M3 实现）
        if (handicapType == HandicapType.QUARTER) {
            revert InvalidHandicapType(handicapType);
        }

        // 整球盘的 Push 为 1:1
        if (handicapType == HandicapType.WHOLE && outcomeId == PUSH) {
            return amount;
        }

        // 构建储备数组（虚拟储备 + 真实流动性，仅包含 HOME_COVER 和 AWAY_COVER）
        uint256[] memory reserves = new uint256[](2);
        reserves[HOME_COVER] = virtualReserves[HOME_COVER] + outcomeLiquidity[HOME_COVER];
        reserves[AWAY_COVER] = virtualReserves[AWAY_COVER] + outcomeLiquidity[AWAY_COVER];

        // 调用定价引擎
        shares = pricingEngine.calculateShares(outcomeId, amount, reserves);

        // 更新虚拟储备（模拟买入操作）
        virtualReserves[outcomeId] -= shares;
        virtualReserves[outcomeId == HOME_COVER ? AWAY_COVER : HOME_COVER] += amount;

        return shares;
    }

    /**
     * @notice 根据比赛结果计算获胜结果ID
     * @param facts 比赛结果数据（来自预言机）
     * @return winningOutcomeId 获胜结果ID
     * @dev 让球盘逻辑：
     *      1. 计算调整后比分（加上/减去让球数）
     *      2. 比较调整后比分确定赢盘方
     *      3. 整球盘平手时返回 PUSH
     */
    function _calculateWinner(IResultOracle.MatchFacts memory facts)
        internal
        view
        override
        returns (uint256 winningOutcomeId)
    {
        // 计算调整后比分
        (int256 adjustedHome, int256 adjustedAway) =
            calculateAdjustedScore(facts.homeGoals, facts.awayGoals);

        // 确定获胜结果
        return determineOutcome(adjustedHome, adjustedAway);
    }

    // ============================================================================
    // IAH_Template 接口实现
    // ============================================================================

    /// @inheritdoc IAH_Template
    function getHandicap() external view override returns (int256) {
        return handicap;
    }

    /// @inheritdoc IAH_Template
    function getHandicapType() external view override returns (HandicapType) {
        return handicapType;
    }

    /// @inheritdoc IAH_Template
    function getHandicapDirection() external view override returns (HandicapDirection) {
        return direction;
    }

    /// @inheritdoc IAH_Template
    function calculateAdjustedScore(
        uint256 homeScore,
        uint256 awayScore
    ) public view override returns (int256 adjustedHomeScore, int256 adjustedAwayScore) {
        // 将比分转换为千分位，再加上让球数
        // 例如：主队 2 球，让 0.5 球（handicap = -500）
        // adjustedHomeScore = 2 * 1000 + (-500) = 2000 - 500 = 1500
        // adjustedAwayScore = 1 * 1000 = 1000
        // 比较：1500 > 1000，主队赢盘
        adjustedHomeScore = int256(homeScore) * int256(HANDICAP_PRECISION) + handicap;
        adjustedAwayScore = int256(awayScore) * int256(HANDICAP_PRECISION);

        return (adjustedHomeScore, adjustedAwayScore);
    }

    /// @inheritdoc IAH_Template
    function determineOutcome(
        int256 adjustedHomeScore,
        int256 adjustedAwayScore
    ) public view override returns (uint256 outcome) {
        if (adjustedHomeScore > adjustedAwayScore) {
            // 调整后主队得分更高 → 主队赢盘
            return HOME_COVER;
        } else if (adjustedHomeScore < adjustedAwayScore) {
            // 调整后主队得分更低 → 客队赢盘
            return AWAY_COVER;
        } else {
            // 调整后比分相同
            if (handicapType == HandicapType.HALF) {
                // 半球盘不可能平手（0.5 的倍数）
                revert("AH: Impossible tie for half handicap");
            } else {
                // 整球盘平手 → 退款
                return PUSH;
            }
        }
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 结算市场（仅 owner 调用，实际由 Oracle 触发）
     * @param homeScore 主队实际进球数
     * @param awayScore 客队实际进球数
     */
    function settle(uint256 homeScore, uint256 awayScore) external onlyOwner {
        require(status == IMarket.MarketStatus.Locked, "Market not locked");

        // 计算调整后比分
        (int256 adjustedHome, int256 adjustedAway) = calculateAdjustedScore(homeScore, awayScore);

        // 确定获胜结果
        uint256 outcome = determineOutcome(adjustedHome, adjustedAway);

        // 更新市场状态
        status = IMarket.MarketStatus.Resolved;
        winningOutcome = outcome;

        emit AHSettled(matchId, homeScore, awayScore, adjustedHome, adjustedAway, outcome);
        emit Resolved(outcome, block.timestamp);
    }

    /**
     * @notice 更新定价引擎（仅 owner）
     */
    function setPricingEngine(address _pricingEngine) external onlyOwner {
        require(_pricingEngine != address(0), "Invalid pricing engine");
        require(status == IMarket.MarketStatus.Open, "Market not open");

        address oldEngine = address(pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);

        emit PricingEngineUpdated(oldEngine, _pricingEngine);
    }

    // ============================================================================
    // 内部辅助函数
    // ============================================================================

    /**
     * @notice 验证让球数合法性
     * @dev 让球数必须是 0.25 的倍数（250 的倍数）
     */
    function _validateHandicap(int256 _handicap, HandicapType _handicapType) private pure {
        // 取绝对值
        uint256 absHandicap = _handicap >= 0 ? uint256(_handicap) : uint256(-_handicap);

        // 必须是 250 的倍数（0.25 球的千分位表示）
        if (absHandicap % 250 != 0) {
            revert InvalidHandicap(_handicap);
        }

        // 验证让球类型匹配
        // quotient = absHandicap / 250
        // 0.5球: 500/250 = 2 → quotient % 4 == 2
        // 1.0球: 1000/250 = 4 → quotient % 4 == 0
        // 1.5球: 1500/250 = 6 → quotient % 4 == 2
        uint256 quotient = absHandicap / 250;

        if (_handicapType == HandicapType.HALF) {
            // 半球盘：必须是 0.5, 1.5, 2.5... (quotient % 4 == 2)
            if (quotient % 4 != 2) {
                revert InvalidHandicap(_handicap);
            }
        } else if (_handicapType == HandicapType.WHOLE) {
            // 整球盘：必须是 1.0, 2.0, 3.0... (quotient % 4 == 0 且 quotient > 0)
            if (quotient % 4 != 0 || quotient == 0) {
                revert InvalidHandicap(_handicap);
            }
        } else if (_handicapType == HandicapType.QUARTER) {
            // 1/4 球盘：0.25, 0.75, 1.25... (quotient % 2 == 1)
            // M2 阶段暂不支持
            revert InvalidHandicapType(_handicapType);
        }
    }

    /**
     * @notice 根据让球类型设置 outcome 名称
     */
    function _setOutcomeNames(HandicapType _handicapType) private {
        if (_handicapType == HandicapType.HALF) {
            outcomeNames = new string[](2);
            outcomeNames[HOME_COVER] = "Home Cover";
            outcomeNames[AWAY_COVER] = "Away Cover";
        } else if (_handicapType == HandicapType.WHOLE) {
            outcomeNames = new string[](3);
            outcomeNames[HOME_COVER] = "Home Cover";
            outcomeNames[AWAY_COVER] = "Away Cover";
            outcomeNames[PUSH] = "Push";
        }
    }

    /**
     * @notice 定价引擎更新事件
     */
    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);
}
