// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ICorrelationGuard.sol";
import "../interfaces/IMarket.sol";

/**
 * @title CorrelationGuard
 * @notice 相关性守卫合约 - 检测串关中的相关性并应用惩罚或阻断
 * @dev 用于防止高度相关的组合下注，保护平台免受套利
 *
 * 功能：
 * - 检查串关腿之间的相关性
 * - 应用赔率惩罚或完全阻断
 * - 支持批量设置相关性规则
 * - 支持三种策略：ALLOW_ALL, PENALTY, STRICT_BLOCK
 */
contract CorrelationGuard is ICorrelationGuard, Ownable, AccessControl {
    // ============================================================================
    // 角色定义
    // ============================================================================

    /// @notice 规则管理员角色（可批量更新相关性规则）
    bytes32 public constant RULE_MANAGER_ROLE = keccak256("RULE_MANAGER_ROLE");

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 当前相关性策略
    CorrelationPolicy public policy;

    /// @notice 相关性规则映射：matchId1 => matchId2 => (penaltyBps, isBlocked)
    /// @dev 使用有序对存储（matchId1 < matchId2）
    mapping(bytes32 => mapping(bytes32 => CorrelationRule)) private correlationRules;

    /// @notice 市场地址到比赛ID的映射
    mapping(address => bytes32) private marketToMatchId;

    /// @notice 默认同场惩罚（基点）
    uint256 public defaultSameMatchPenalty;

    /// @notice 最大允许的惩罚值（基点，100% = 10000）
    uint256 public constant MAX_PENALTY_BPS = 10000;

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param initialPolicy 初始策略
     * @param _defaultSameMatchPenalty 默认同场惩罚（基点）
     */
    constructor(CorrelationPolicy initialPolicy, uint256 _defaultSameMatchPenalty)
        Ownable(msg.sender)
    {
        if (_defaultSameMatchPenalty > MAX_PENALTY_BPS) {
            revert InvalidPenalty(_defaultSameMatchPenalty);
        }

        policy = initialPolicy;
        defaultSameMatchPenalty = _defaultSameMatchPenalty;

        // 授予 deployer RULE_MANAGER_ROLE
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RULE_MANAGER_ROLE, msg.sender);

        emit PolicyUpdated(CorrelationPolicy.ALLOW_ALL, initialPolicy);
        emit DefaultPenaltyUpdated(_defaultSameMatchPenalty);
    }

    // ============================================================================
    // 只读函数
    // ============================================================================

    /// @inheritdoc ICorrelationGuard
    function getPolicy() external view override returns (CorrelationPolicy) {
        return policy;
    }

    /// @inheritdoc ICorrelationGuard
    function checkBlocked(ParlayLeg[] calldata legs)
        external
        view
        override
        returns (bool isBlocked, string memory reason)
    {
        // ALLOW_ALL 策略不阻断
        if (policy == CorrelationPolicy.ALLOW_ALL) {
            return (false, "");
        }

        // 至少需要 2 个腿
        if (legs.length < 2) {
            return (false, "");
        }

        // 检查每对腿
        for (uint256 i = 0; i < legs.length; i++) {
            for (uint256 j = i + 1; j < legs.length; j++) {
                bytes32 matchId1 = getMatchId(legs[i].market);
                bytes32 matchId2 = getMatchId(legs[j].market);

                // 获取相关性规则
                (uint256 penaltyBps, bool blocked) = _getRule(matchId1, matchId2);

                if (blocked && policy == CorrelationPolicy.STRICT_BLOCK) {
                    return (
                        true,
                        string(
                            abi.encodePacked(
                                "Blocked: correlation between leg ",
                                _uint2str(i),
                                " and leg ",
                                _uint2str(j)
                            )
                        )
                    );
                }

                // 同场检查
                if (matchId1 == matchId2) {
                    if (policy == CorrelationPolicy.STRICT_BLOCK) {
                        return (true, "Blocked: same match correlation");
                    }
                }
            }
        }

        return (false, "");
    }

    /// @inheritdoc ICorrelationGuard
    function calculatePenalty(ParlayLeg[] calldata legs)
        external
        view
        override
        returns (uint256 totalPenaltyBps, uint256[] memory details)
    {
        // ALLOW_ALL 或 STRICT_BLOCK 策略不计算惩罚
        if (policy != CorrelationPolicy.PENALTY) {
            details = new uint256[](0);
            return (0, details);
        }

        if (legs.length < 2) {
            details = new uint256[](0);
            return (0, details);
        }

        // 计算每对腿之间的惩罚
        uint256 pairCount = (legs.length * (legs.length - 1)) / 2;
        details = new uint256[](pairCount);
        uint256 detailIndex = 0;
        totalPenaltyBps = 0;

        for (uint256 i = 0; i < legs.length; i++) {
            for (uint256 j = i + 1; j < legs.length; j++) {
                bytes32 matchId1 = getMatchId(legs[i].market);
                bytes32 matchId2 = getMatchId(legs[j].market);

                (uint256 penaltyBps,) = _getRule(matchId1, matchId2);

                // 同场使用默认惩罚
                if (matchId1 == matchId2 && penaltyBps == 0) {
                    penaltyBps = defaultSameMatchPenalty;
                }

                details[detailIndex] = penaltyBps;
                detailIndex++;

                // 累加惩罚（简单累加，不超过 100%）
                totalPenaltyBps += penaltyBps;
                if (totalPenaltyBps > MAX_PENALTY_BPS) {
                    totalPenaltyBps = MAX_PENALTY_BPS;
                }
            }
        }

        return (totalPenaltyBps, details);
    }

    /// @inheritdoc ICorrelationGuard
    function getCorrelationRule(bytes32 matchId1, bytes32 matchId2)
        external
        view
        override
        returns (uint256 penaltyBps, bool isBlocked)
    {
        return _getRule(matchId1, matchId2);
    }

    /// @inheritdoc ICorrelationGuard
    function getMatchId(address market) public view override returns (bytes32) {
        bytes32 matchId = marketToMatchId[market];

        // 如果未注册，尝试从市场合约读取 matchId
        if (matchId == bytes32(0)) {
            // 尝试调用 market.matchId() 获取 string，然后哈希
            try this._extractMatchId(market) returns (bytes32 extracted) {
                return extracted;
            } catch {
                // 如果失败，使用市场地址作为 matchId
                return keccak256(abi.encodePacked(market));
            }
        }

        return matchId;
    }

    /**
     * @notice 外部辅助函数：从市场合约提取 matchId
     * @dev 必须是 external 才能使用 try/catch
     */
    function _extractMatchId(address market) external view returns (bytes32) {
        // 调用市场合约的 matchId() 函数
        // 假设返回 string
        (bool success, bytes memory data) =
            market.staticcall(abi.encodeWithSignature("matchId()"));

        if (success && data.length > 0) {
            string memory matchIdStr = abi.decode(data, (string));
            return keccak256(abi.encodePacked(matchIdStr));
        }

        revert("Failed to extract matchId");
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /// @inheritdoc ICorrelationGuard
    function setPolicy(CorrelationPolicy newPolicy) external override onlyOwner {
        CorrelationPolicy oldPolicy = policy;
        policy = newPolicy;
        emit PolicyUpdated(oldPolicy, newPolicy);
    }

    /// @inheritdoc ICorrelationGuard
    function setCorrelationRule(
        bytes32 matchId1,
        bytes32 matchId2,
        uint256 penaltyBps,
        bool isBlocked
    ) external override onlyRole(RULE_MANAGER_ROLE) {
        if (penaltyBps > MAX_PENALTY_BPS) {
            revert InvalidPenalty(penaltyBps);
        }

        // 使用有序对存储
        (bytes32 min, bytes32 max) = matchId1 < matchId2 ? (matchId1, matchId2) : (matchId2, matchId1);

        correlationRules[min][max] = CorrelationRule({
            matchId1: min,
            matchId2: max,
            penaltyBps: penaltyBps,
            isBlocked: isBlocked
        });

        emit CorrelationRuleSet(min, max, penaltyBps, isBlocked);
    }

    /// @inheritdoc ICorrelationGuard
    function batchSetRules(CorrelationRule[] calldata rules)
        external
        override
        onlyRole(RULE_MANAGER_ROLE)
    {
        for (uint256 i = 0; i < rules.length; i++) {
            CorrelationRule calldata rule = rules[i];

            if (rule.penaltyBps > MAX_PENALTY_BPS) {
                revert InvalidPenalty(rule.penaltyBps);
            }

            // 使用有序对存储
            (bytes32 min, bytes32 max) = rule.matchId1 < rule.matchId2
                ? (rule.matchId1, rule.matchId2)
                : (rule.matchId2, rule.matchId1);

            correlationRules[min][max] = CorrelationRule({
                matchId1: min,
                matchId2: max,
                penaltyBps: rule.penaltyBps,
                isBlocked: rule.isBlocked
            });

            emit CorrelationRuleSet(min, max, rule.penaltyBps, rule.isBlocked);
        }
    }

    /// @inheritdoc ICorrelationGuard
    function setDefaultSameMatchPenalty(uint256 penaltyBps) external override onlyOwner {
        if (penaltyBps > MAX_PENALTY_BPS) {
            revert InvalidPenalty(penaltyBps);
        }

        defaultSameMatchPenalty = penaltyBps;
        emit DefaultPenaltyUpdated(penaltyBps);
    }

    /**
     * @notice 注册市场的 matchId（可选）
     * @param market 市场地址
     * @param matchId 比赛ID
     * @dev 仅 owner 或 RULE_MANAGER 可调用
     */
    function registerMarket(address market, bytes32 matchId)
        external
        onlyRole(RULE_MANAGER_ROLE)
    {
        marketToMatchId[market] = matchId;
    }

    /**
     * @notice 批量注册市场
     * @param markets 市场地址数组
     * @param matchIds 比赛ID数组
     */
    function batchRegisterMarkets(address[] calldata markets, bytes32[] calldata matchIds)
        external
        onlyRole(RULE_MANAGER_ROLE)
    {
        require(markets.length == matchIds.length, "Length mismatch");

        for (uint256 i = 0; i < markets.length; i++) {
            marketToMatchId[markets[i]] = matchIds[i];
        }
    }

    // ============================================================================
    // 内部辅助函数
    // ============================================================================

    /**
     * @notice 获取相关性规则（内部）
     * @param matchId1 比赛1 ID
     * @param matchId2 比赛2 ID
     * @return penaltyBps 惩罚基点
     * @return isBlocked 是否阻断
     */
    function _getRule(bytes32 matchId1, bytes32 matchId2)
        private
        view
        returns (uint256 penaltyBps, bool isBlocked)
    {
        // 使用有序对查询
        (bytes32 min, bytes32 max) = matchId1 < matchId2 ? (matchId1, matchId2) : (matchId2, matchId1);

        CorrelationRule memory rule = correlationRules[min][max];

        return (rule.penaltyBps, rule.isBlocked);
    }

    /**
     * @notice 将 uint256 转换为 string
     * @param _i 数字
     * @return str 字符串
     */
    function _uint2str(uint256 _i) private pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        str = string(bstr);
    }
}
