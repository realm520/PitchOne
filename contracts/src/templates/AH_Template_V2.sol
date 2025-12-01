// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../core/MarketBase_V2.sol";
import "../interfaces/IPricingEngine.sol";
import "../interfaces/IAH_Template.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title AH_Template_V2
 * @notice 让球（Asian Handicap）市场模板 V2 - 单线版本
 * @dev 继承 MarketBase_V2，集成 LiquidityVault
 *
 * 核心改进：
 * - 使用虚拟储备定价（SimpleCPMM）
 * - 从 Vault 借出初始流动性
 * - 市场结算后归还流动性+收益
 * - 支持滑点保护
 *
 * 让球盘根据类型分为：
 *      - 半球盘（-0.5）：二向市场（主队赢盘/客队赢盘）
 *      - 整球盘（-1.0）：三向市场（主队赢盘/客队赢盘/退款）
 *      - 1/4球盘（-0.25）：未来版本实现（半输半赢机制）
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
 */
contract AH_Template_V2 is MarketBase_V2, IAH_Template {
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

    /// @notice 默认初始借款金额（从 Vault 借出）- 根据代币精度动态计算
    uint256 private defaultBorrowAmount;

    /// @notice 虚拟储备初始值（与 SimpleCPMM 保持一致）- 根据代币精度动态计算
    uint256 private virtualReserveInit;

    /// @notice 定价引擎（SimpleCPMM）
    IPricingEngine public pricingEngine;

    /// @notice 虚拟储备（由定价引擎管理）
    uint256[] public virtualReserves;

    /// @notice 比赛信息
    string public matchId;              // 比赛ID
    string public homeTeam;             // 主队
    string public awayTeam;             // 客队
    // kickoffTime 继承自 MarketBase_V2

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
    // 事件
    // ============================================================================

    /// @notice 虚拟储备更新事件
    event VirtualReservesUpdated(uint256[] reserves);

    /// @notice 定价引擎更新事件
    event PricingEngineUpdated(address indexed oldEngine, address indexed newEngine);

    // ============================================================================
    // 构造函数和初始化
    // ============================================================================

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
     * @param _handicap 让球数（千分位，如 -500 = -0.5）
     * @param _handicapType 让球类型
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
        int256 _handicap,
        HandicapType _handicapType,
        address _settlementToken,
        address _feeRecipient,
        uint256 _feeRate,
        uint256 _disputePeriod,
        address _pricingEngine,
        address _vault,
        string memory _uri
    ) external initializer {
        // 验证参数
        require(bytes(_matchId).length > 0, "AH_V2: Empty match ID");
        require(bytes(_homeTeam).length > 0, "AH_V2: Empty home team");
        require(bytes(_awayTeam).length > 0, "AH_V2: Empty away team");
        require(_kickoffTime > block.timestamp, "AH_V2: Kickoff time in past");
        require(_pricingEngine != address(0), "AH_V2: Invalid pricing engine");

        // 验证让球数（必须是 0.25 的倍数）
        _validateHandicap(_handicap, _handicapType);

        // 初始化父合约
        __MarketBase_init(
            _handicapType == HandicapType.HALF
                ? HALF_HANDICAP_OUTCOME_COUNT
                : WHOLE_HANDICAP_OUTCOME_COUNT,
            _settlementToken,
            _feeRecipient,
            _feeRate,
            _disputePeriod,
            _vault,
            _uri
        );

        // 获取代币精度并计算相关值
        uint8 decimals = IERC20Metadata(_settlementToken).decimals();
        uint256 tokenUnit = 10 ** decimals;
        defaultBorrowAmount = 100_000 * tokenUnit;  // 100k tokens
        virtualReserveInit = 100_000 * tokenUnit;   // 100k tokens

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
        uint256 outcomeCountForPricing = _handicapType == HandicapType.HALF ? 2 : 2;
        virtualReserves = new uint256[](outcomeCountForPricing);
        for (uint256 i = 0; i < outcomeCountForPricing; i++) {
            virtualReserves[i] = virtualReserveInit;
        }

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
    // 实现抽象函数
    // ============================================================================

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
        // 验证下注结果
        if (handicapType == HandicapType.HALF && outcomeId == PUSH) {
            revert CannotBetOnPush();
        }

        // 1/4 球盘暂不支持
        if (handicapType == HandicapType.QUARTER) {
            revert InvalidHandicapType(handicapType);
        }

        // 整球盘的 Push 为 1:1
        if (handicapType == HandicapType.WHOLE && outcomeId == PUSH) {
            return netAmount;
        }

        // 1. 调用定价引擎计算份额
        shares = pricingEngine.calculateShares(outcomeId, netAmount, virtualReserves);

        // 2. 调用定价引擎更新储备（由引擎决定更新逻辑）
        virtualReserves = pricingEngine.updateReserves(
            outcomeId,
            netAmount,
            shares,
            virtualReserves
        );

        emit VirtualReservesUpdated(virtualReserves);

        return shares;
    }

    /**
     * @notice 获取初始借款金额
     * @return 需要从 Vault 借出的金额
     */
    function _getInitialBorrowAmount() internal view override returns (uint256) {
        return defaultBorrowAmount;
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
                revert("AH_V2: Impossible tie for half handicap");
            } else {
                // 整球盘平手 → 退款
                return PUSH;
            }
        }
    }

    // ============================================================================
    // 只读函数
    // ============================================================================

    /**
     * @notice 获取当前价格（隐含概率）
     * @param outcomeId 结果ID (0=Home Cover, 1=Away Cover, 2=Push)
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getCurrentPrice(uint256 outcomeId) external view returns (uint256 price) {
        // Push 不参与定价
        if (outcomeId == PUSH) {
            return 0;
        }

        require(outcomeId < 2, "AH_V2: Invalid outcome for pricing");
        return pricingEngine.getPrice(outcomeId, virtualReserves);
    }

    /**
     * @notice 获取所有可下注结果的当前价格
     * @return prices 价格数组（基点，仅包含 Home Cover 和 Away Cover）
     */
    function getAllPrices() external view returns (uint256[] memory prices) {
        prices = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
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
     * @return _handicap 让球数（千分位）
     * @return _handicapType 让球类型
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
            int256 _handicap,
            HandicapType _handicapType,
            MarketStatus _status
        )
    {
        return (matchId, homeTeam, awayTeam, kickoffTime, handicap, handicapType, status);
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
     * @notice 获取让球数的小数表示
     * @return integer 整数部分
     * @return decimal 小数部分（千分位）
     * @return isNegative 是否为负数（主队让球）
     * @dev 例如：-0.5球 → (0, 500, true)，+1.5球 → (1, 500, false)
     */
    function getHandicapDisplay() external view returns (uint256 integer, uint256 decimal, bool isNegative) {
        isNegative = handicap < 0;
        uint256 absHandicap = isNegative ? uint256(-handicap) : uint256(handicap);
        integer = absHandicap / HANDICAP_PRECISION;
        decimal = absHandicap % HANDICAP_PRECISION;
        return (integer, decimal, isNegative);
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 更新定价引擎
     * @param _pricingEngine 新的定价引擎地址
     */
    function setPricingEngine(address _pricingEngine) external onlyOwner {
        require(_pricingEngine != address(0), "AH_V2: Invalid pricing engine");
        emit PricingEngineUpdated(address(pricingEngine), _pricingEngine);
        pricingEngine = IPricingEngine(_pricingEngine);
    }

    /**
     * @notice 自动锁盘（Keeper 调用）
     * @dev 开球时间到达时自动锁盘
     */
    // autoLock() 继承自 MarketBase_V2

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
            // 暂不支持
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
}
