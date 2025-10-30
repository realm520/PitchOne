// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IResultOracle} from "../interfaces/IResultOracle.sol";

/**
 * @title MockOracle
 * @notice 简化的预言机实现，用于开发和测试阶段
 * @dev 核心特性：
 *      1. Owner 可直接提交结果（无争议机制）
 *      2. 支持标准化的 MatchFacts 结构
 *      3. 自动终结（提交即确认）
 *      4. 记录所有提交的证据哈希（可追溯）
 *
 * 安全措施：
 * - Owner 限制（应使用多签钱包）
 * - 一次性提交（不可修改）
 * - 事件完整记录
 *
 * 生产环境应使用 UMA Optimistic Oracle Adapter
 */
contract MockOracle is IResultOracle, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 市场结果存储
    mapping(bytes32 marketId => MatchFacts) private _results;

    /// @notice 市场是否已提交结果
    mapping(bytes32 marketId => bool) private _finalized;

    /// @notice 结果哈希存储（用于验证和索引）
    mapping(bytes32 marketId => bytes32) private _resultHashes;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ResultAlreadySubmitted(bytes32 marketId);
    error InvalidMatchFacts(string reason);
    error ResultNotFound(bytes32 marketId);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param initialOwner 初始 Owner 地址（建议使用多签）
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 提交比赛结果（仅 Owner）
     * @dev 提交后立即终结，不可修改
     * @param marketId 市场ID
     * @param facts 比赛结果数据
     */
    function proposeResult(bytes32 marketId, MatchFacts calldata facts)
        external
        override
        onlyOwner
    {
        // 1. 检查是否已提交
        if (_finalized[marketId]) {
            revert ResultAlreadySubmitted(marketId);
        }

        // 2. 验证结果数据合法性
        _validateMatchFacts(facts);

        // 3. 存储结果
        _results[marketId] = facts;
        _finalized[marketId] = true;

        // 4. 计算并存储结果哈希
        bytes32 factsHash = keccak256(abi.encode(facts));
        _resultHashes[marketId] = factsHash;

        // 5. 发出事件（提议和终结合并）
        emit ResultProposed(marketId, facts, factsHash, msg.sender);
        emit ResultFinalized(marketId, factsHash, true);
    }

    /**
     * @notice 获取市场结果
     * @param marketId 市场ID
     * @return facts 比赛结果数据
     * @return finalized 是否已终结（MockOracle中始终为true或抛出错误）
     */
    function getResult(bytes32 marketId)
        external
        view
        override
        returns (MatchFacts memory facts, bool finalized)
    {
        if (!_finalized[marketId]) {
            revert ResultNotFound(marketId);
        }

        return (_results[marketId], true);
    }

    /**
     * @notice 检查结果是否已终结
     * @param marketId 市场ID
     * @return 是否已终结
     */
    function isFinalized(bytes32 marketId) external view override returns (bool) {
        return _finalized[marketId];
    }

    /**
     * @notice 获取结果哈希
     * @param marketId 市场ID
     * @return 结果哈希（如果不存在则为bytes32(0)）
     */
    function getResultHash(bytes32 marketId) external view override returns (bytes32) {
        return _resultHashes[marketId];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 验证 MatchFacts 数据合法性
     * @dev 检查规则：
     *      1. scope 必须是有效值
     *      2. 进球数合理（<50）
     *      3. 点球数据一致性
     * @param facts 待验证的比赛结果
     */
    function _validateMatchFacts(MatchFacts calldata facts) internal view {
        // 验证 scope
        if (
            facts.scope != bytes32("FT_90") && facts.scope != bytes32("FT_120")
                && facts.scope != bytes32("Penalties")
        ) {
            revert InvalidMatchFacts("Invalid scope");
        }

        // 验证进球数合理性（防止输入错误）
        if (facts.homeGoals > 50 || facts.awayGoals > 50) {
            revert InvalidMatchFacts("Goals exceed limit");
        }

        // 验证点球数据一致性
        if (facts.scope == bytes32("Penalties")) {
            // 点球大战场景：必须有 extraTime，且点球数不为0
            if (!facts.extraTime) {
                revert InvalidMatchFacts("Penalties require extraTime");
            }
            if (facts.penaltiesHome == 0 && facts.penaltiesAway == 0) {
                revert InvalidMatchFacts("Penalties data missing");
            }
        } else {
            // 非点球场景：点球数必须为0
            if (facts.penaltiesHome != 0 || facts.penaltiesAway != 0) {
                revert InvalidMatchFacts("Unexpected penalties data");
            }
        }

        // 验证时间戳合理性（不能是未来时间）
        if (facts.reportedAt > block.timestamp) {
            revert InvalidMatchFacts("Future timestamp");
        }
    }

    /*//////////////////////////////////////////////////////////////
                          UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 批量提交结果（便于测试）
     * @param marketIds 市场ID数组
     * @param factsArray 结果数组
     */
    function batchProposeResults(
        bytes32[] calldata marketIds,
        MatchFacts[] calldata factsArray
    ) external onlyOwner {
        if (marketIds.length != factsArray.length) {
            revert InvalidMatchFacts("Length mismatch");
        }

        for (uint256 i = 0; i < marketIds.length; i++) {
            // 内部调用提交逻辑
            bytes32 marketId = marketIds[i];
            MatchFacts calldata facts = factsArray[i];

            // 检查是否已提交
            if (_finalized[marketId]) {
                revert ResultAlreadySubmitted(marketId);
            }

            // 验证结果数据
            _validateMatchFacts(facts);

            // 存储结果
            _results[marketId] = facts;
            _finalized[marketId] = true;

            // 计算并存储结果哈希
            bytes32 factsHash = keccak256(abi.encode(facts));
            _resultHashes[marketId] = factsHash;

            // 发出事件
            emit ResultProposed(marketId, facts, factsHash, msg.sender);
            emit ResultFinalized(marketId, factsHash, true);
        }
    }
}
