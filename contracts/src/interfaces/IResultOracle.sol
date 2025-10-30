// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IResultOracle
 * @notice 预言机接口，用于获取和提交比赛结果
 * @dev 支持多种预言机实现：MockOracle（测试）、UMA Optimistic Oracle（生产）
 *
 * 设计要点：
 * 1. 标准化 MatchFacts 结构，支持多种玩法（WDL、OU、AH、精确比分）
 * 2. 乐观式结算流程：Propose → Dispute Window → Finalize
 * 3. 事件标准化，便于链下服务索引和监控
 *
 * Week 3-4 实现：MockOracle（简化版，无争议机制）
 * Week 5-6 扩展：UMA OO Adapter（完整乐观式预言机）
 */
interface IResultOracle {
    /// @notice 比赛结果数据结构
    /// @dev 支持常规时间、加时赛、点球大战等多种场景
    struct MatchFacts {
        bytes32 scope;         // 结果范围: "FT_90" (90分钟) | "FT_120" (含加时) | "Penalties" (含点球)
        uint8 homeGoals;       // 主队进球数 (常规时间 + 加时，不含点球)
        uint8 awayGoals;       // 客队进球数 (常规时间 + 加时，不含点球)
        bool extraTime;        // 是否有加时赛
        uint8 penaltiesHome;   // 点球大战主队进球数 (0 if no penalties)
        uint8 penaltiesAway;   // 点球大战客队进球数 (0 if no penalties)
        uint256 reportedAt;    // 结果上报时间戳
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 结果被提议
    /// @param marketId 市场ID
    /// @param facts 比赛事实
    /// @param factsHash 事实结构体的哈希 (keccak256(abi.encode(facts)))
    /// @param proposer 提议人地址
    event ResultProposed(
        bytes32 indexed marketId,
        MatchFacts facts,
        bytes32 indexed factsHash,
        address indexed proposer
    );

    /// @notice 结果被争议
    /// @param marketId 市场ID
    /// @param factsHash 被争议的事实哈希
    /// @param disputer 争议人地址
    /// @param reason 争议原因（链下存储，链上仅记录事件）
    event ResultDisputed(
        bytes32 indexed marketId,
        bytes32 indexed factsHash,
        address indexed disputer,
        string reason
    );

    /// @notice 结果被最终确认
    /// @param marketId 市场ID
    /// @param factsHash 确认的事实哈希
    /// @param accepted 是否接受提议（true: 提议通过, false: 争议成功）
    event ResultFinalized(
        bytes32 indexed marketId,
        bytes32 indexed factsHash,
        bool accepted
    );

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 提议比赛结果
     * @dev 提议人需要质押一定数量的代币（UMA OO中），MockOracle中简化为Owner提交
     * @param marketId 市场ID
     * @param facts 比赛结果数据
     */
    function proposeResult(bytes32 marketId, MatchFacts calldata facts) external;

    /**
     * @notice 获取市场的结果
     * @param marketId 市场ID
     * @return facts 比赛结果数据
     * @return finalized 是否已最终确认
     */
    function getResult(bytes32 marketId)
        external
        view
        returns (MatchFacts memory facts, bool finalized);

    /**
     * @notice 检查结果是否已最终确认
     * @param marketId 市场ID
     * @return 是否已确认
     */
    function isFinalized(bytes32 marketId) external view returns (bool);

    /**
     * @notice 获取结果哈希
     * @dev 用于验证和索引
     * @param marketId 市场ID
     * @return 结果哈希（如果不存在则为bytes32(0)）
     */
    function getResultHash(bytes32 marketId) external view returns (bytes32);
}
