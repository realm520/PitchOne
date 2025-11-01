// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOptimisticOracleV3
 * @notice UMA Optimistic Oracle V3 接口（简化版，仅包含我们需要的函数）
 * @dev 完整接口参考: https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol
 */
interface IOptimisticOracleV3 {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 断言数据结构
    struct Assertion {
        bool resolved;                  // 是否已解决
        bool disputed;                  // 是否被争议
        bool settlementResolution;      // 解决结果（true = 断言正确）
        address asserter;               // 断言者地址
        address disputer;               // 争议者地址
        address callbackRecipient;      // 回调接收者
        address currency;               // 质押币种
        uint64 expirationTime;          // 过期时间
        uint256 bond;                   // 质押金额
        bytes32 identifier;             // DVM 标识符
        bytes32 domainId;              // 域ID
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 断言被创建
    event AssertionMade(
        bytes32 indexed assertionId,
        bytes32 indexed domainId,
        bytes claim,
        address indexed asserter,
        address callbackRecipient,
        address escalationManager,
        address caller,
        uint64 expirationTime,
        address currency,
        uint256 bond,
        bytes32 identifier
    );

    /// @notice 断言被争议
    event AssertionDisputed(
        bytes32 indexed assertionId,
        address indexed caller,
        address indexed disputer
    );

    /// @notice 断言被结算
    event AssertionSettled(
        bytes32 indexed assertionId,
        address indexed bondRecipient,
        bool disputed,
        bool settlementResolution,
        address settleCaller
    );

    /*//////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 使用默认参数提交断言
     * @param claim 断言声明（编码后的数据）
     * @param asserter 断言者地址
     * @return assertionId 断言ID
     */
    function assertTruthWithDefaults(bytes calldata claim, address asserter)
        external
        returns (bytes32 assertionId);

    /**
     * @notice 提交完全自定义的断言
     * @param claim 断言声明
     * @param asserter 断言者地址
     * @param callbackRecipient 回调接收者地址
     * @param escalationManager 争议管理器地址（address(0) = 使用DVM）
     * @param liveness 有效期（秒）
     * @param currency 质押币种
     * @param bond 质押金额
     * @param identifier DVM 标识符
     * @param domainId 域ID
     * @return assertionId 断言ID
     */
    function assertTruth(
        bytes calldata claim,
        address asserter,
        address callbackRecipient,
        address escalationManager,
        uint64 liveness,
        address currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external returns (bytes32 assertionId);

    /**
     * @notice 争议断言
     * @param assertionId 断言ID
     * @param disputer 争议者地址
     */
    function disputeAssertion(bytes32 assertionId, address disputer) external;

    /**
     * @notice 结算断言
     * @param assertionId 断言ID
     */
    function settleAssertion(bytes32 assertionId) external;

    /**
     * @notice 结算断言并返回结果
     * @param assertionId 断言ID
     * @return 断言是否正确
     */
    function settleAndGetAssertionResult(bytes32 assertionId) external returns (bool);

    /**
     * @notice 获取断言数据
     * @param assertionId 断言ID
     * @return 断言数据
     */
    function getAssertion(bytes32 assertionId) external view returns (Assertion memory);

    /**
     * @notice 获取默认 DVM 标识符
     * @return 默认标识符
     */
    function defaultIdentifier() external view returns (bytes32);

    /**
     * @notice 获取最小质押金额
     * @param currency 币种地址
     * @return 最小质押金额
     */
    function getMinimumBond(address currency) external view returns (uint256);
}
