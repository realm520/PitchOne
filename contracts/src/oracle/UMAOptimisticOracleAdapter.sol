// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IResultOracle} from "../interfaces/IResultOracle.sol";
import {IOptimisticOracleV3} from "../interfaces/IOptimisticOracleV3.sol";

/**
 * @title UMAOptimisticOracleAdapter
 * @notice 将 UMA Optimistic Oracle V3 适配为 IResultOracle 接口
 * @dev 核心功能：
 *      1. 接收比赛结果提议（MatchFacts）并转换为 UMA 断言
 *      2. 管理质押和争议流程
 *      3. 提供统一的结果查询接口
 *      4. 支持自动化结算和回调
 *
 * 乐观式流程：
 *   Propose → Liveness Period (争议窗口) → Settle → Finalize
 *
 * 争议流程：
 *   Propose → Dispute → DVM 仲裁 → Settle → Finalize
 *
 * @author PitchOne Team
 */
contract UMAOptimisticOracleAdapter is IResultOracle, Ownable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice UMA Optimistic Oracle V3 合约地址
    IOptimisticOracleV3 public immutable optimisticOracle;

    /// @notice 质押币种（通常是 USDC）
    IERC20 public immutable bondCurrency;

    /// @notice 质押金额
    uint256 public immutable bondAmount;

    /// @notice 有效期（争议窗口，默认 2 小时）
    uint64 public immutable liveness;

    /// @notice DVM 标识符（用于争议仲裁）
    bytes32 public immutable identifier;

    /// @notice marketId => assertionId 映射
    mapping(bytes32 marketId => bytes32 assertionId) public marketAssertions;

    /// @notice assertionId => marketId 反向映射
    mapping(bytes32 assertionId => bytes32 marketId) public assertionMarkets;

    /// @notice marketId => MatchFacts 存储
    mapping(bytes32 marketId => MatchFacts) private _proposedResults;

    /// @notice marketId => 最终结果
    mapping(bytes32 marketId => MatchFacts) private _finalizedResults;

    /// @notice marketId => 是否已最终确认
    mapping(bytes32 marketId => bool) private _finalized;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error AssertionAlreadyExists(bytes32 marketId, bytes32 assertionId);
    error NoAssertionFound(bytes32 marketId);
    error AssertionNotSettled(bytes32 assertionId);
    error InvalidMatchFacts(string reason);
    error InsufficientBondAllowance(uint256 required, uint256 current);
    error ResultNotFinalized(bytes32 marketId);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 断言创建成功
    event AssertionCreated(
        bytes32 indexed marketId,
        bytes32 indexed assertionId,
        address indexed proposer,
        MatchFacts facts,
        uint256 bondAmount
    );

    /// @notice 断言被结算
    event AssertionSettledSuccessfully(
        bytes32 indexed marketId,
        bytes32 indexed assertionId,
        bool accepted
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param _optimisticOracle UMA OOV3 合约地址
     * @param _bondCurrency 质押币种
     * @param _bondAmount 质押金额
     * @param _liveness 有效期（秒，默认 7200 = 2小时）
     * @param _identifier DVM 标识符
     * @param initialOwner 初始 Owner 地址
     */
    constructor(
        address _optimisticOracle,
        address _bondCurrency,
        uint256 _bondAmount,
        uint64 _liveness,
        bytes32 _identifier,
        address initialOwner
    ) Ownable(initialOwner) {
        if (_optimisticOracle == address(0)) revert InvalidMatchFacts("Zero oracle address");
        if (_bondCurrency == address(0)) revert InvalidMatchFacts("Zero currency address");
        if (_bondAmount == 0) revert InvalidMatchFacts("Zero bond amount");
        if (_liveness < 60) revert InvalidMatchFacts("Liveness too short");

        optimisticOracle = IOptimisticOracleV3(_optimisticOracle);
        bondCurrency = IERC20(_bondCurrency);
        bondAmount = _bondAmount;
        liveness = _liveness;
        identifier = _identifier;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS (IResultOracle)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 提议比赛结果
     * @dev 调用者必须预先授权 bondAmount 的 bondCurrency 给 UMA OOV3
     * @param marketId 市场ID
     * @param facts 比赛结果数据
     */
    function proposeResult(bytes32 marketId, MatchFacts calldata facts)
        external
        override
    {
        // 1. 检查是否已存在断言
        if (marketAssertions[marketId] != bytes32(0)) {
            revert AssertionAlreadyExists(marketId, marketAssertions[marketId]);
        }

        // 2. 验证结果数据合法性
        _validateMatchFacts(facts);

        // 3. 检查调用者的质押授权
        uint256 currentAllowance = bondCurrency.allowance(msg.sender, address(optimisticOracle));
        if (currentAllowance < bondAmount) {
            revert InsufficientBondAllowance(bondAmount, currentAllowance);
        }

        // 4. 编码断言声明（将 MatchFacts 编码为 bytes）
        bytes memory claim = abi.encode(facts);

        // 5. 调用 UMA OOV3 创建断言
        bytes32 assertionId = optimisticOracle.assertTruth(
            claim,
            msg.sender,            // asserter
            address(this),         // callbackRecipient（接收回调）
            address(0),            // escalationManager（使用 DVM）
            liveness,              // liveness period
            address(bondCurrency), // currency
            bondAmount,            // bond
            identifier,            // identifier
            bytes32(0)            // domainId (not used)
        );

        // 6. 保存映射关系
        marketAssertions[marketId] = assertionId;
        assertionMarkets[assertionId] = marketId;
        _proposedResults[marketId] = facts;

        // 7. 发出事件
        emit ResultProposed(marketId, facts, keccak256(abi.encode(facts)), msg.sender);
        emit AssertionCreated(marketId, assertionId, msg.sender, facts, bondAmount);
    }

    /**
     * @notice 获取市场结果
     * @param marketId 市场ID
     * @return facts 比赛结果数据
     * @return finalized 是否已最终确认
     * @dev 返回逻辑：
     *      1. 如果已通过 settleAssertion() 手动结算 → 返回 _finalizedResults
     *      2. 如果 DVM 已解决争议 (assertion.resolved) → 返回提议的结果 + finalized=true
     *      3. 否则 → 返回提议的结果 + finalized=false
     */
    function getResult(bytes32 marketId)
        external
        view
        override
        returns (MatchFacts memory facts, bool finalized)
    {
        // 如果已手动结算，返回最终结果
        if (_finalized[marketId]) {
            return (_finalizedResults[marketId], true);
        }

        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            revert NoAssertionFound(marketId);
        }

        // 检查 assertion 是否已由 DVM 解决
        IOptimisticOracleV3.Assertion memory assertion = optimisticOracle.getAssertion(assertionId);

        if (assertion.resolved && assertion.settlementResolution) {
            // DVM 已解决且断言被接受 → 返回提议的结果
            return (_proposedResults[marketId], true);
        }

        // 返回提议的结果（尚未最终确认）
        return (_proposedResults[marketId], false);
    }

    /**
     * @notice 检查结果是否已最终确认
     * @param marketId 市场ID
     * @return 是否已确认
     * @dev 检查两种情况：
     *      1. 通过 settleAssertion() 手动结算
     *      2. DVM 自动解决争议（assertion.resolved == true）
     */
    function isFinalized(bytes32 marketId) external view override returns (bool) {
        // 如果已手动结算，返回 true
        if (_finalized[marketId]) {
            return true;
        }

        // 检查 assertion 是否已由 DVM 解决
        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            return false;
        }

        IOptimisticOracleV3.Assertion memory assertion = optimisticOracle.getAssertion(assertionId);
        return assertion.resolved;
    }

    /**
     * @notice 获取结果哈希
     * @param marketId 市场ID
     * @return 结果哈希
     */
    function getResultHash(bytes32 marketId) external view override returns (bytes32) {
        if (_finalized[marketId]) {
            return keccak256(abi.encode(_finalizedResults[marketId]));
        }

        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId != bytes32(0)) {
            return keccak256(abi.encode(_proposedResults[marketId]));
        }

        return bytes32(0);
    }

    /*//////////////////////////////////////////////////////////////
                        SETTLEMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 结算断言（任何人都可以调用）
     * @dev 在 liveness 期过后或争议解决后调用
     * @param marketId 市场ID
     */
    function settleAssertion(bytes32 marketId) external {
        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            revert NoAssertionFound(marketId);
        }

        // 调用 UMA OOV3 结算
        bool assertionAccepted = optimisticOracle.settleAndGetAssertionResult(assertionId);

        // 获取断言数据
        IOptimisticOracleV3.Assertion memory assertion = optimisticOracle.getAssertion(assertionId);

        if (!assertion.resolved) {
            revert AssertionNotSettled(assertionId);
        }

        // 保存最终结果
        if (assertionAccepted) {
            // 断言被接受 → 使用提议的结果
            _finalizedResults[marketId] = _proposedResults[marketId];
        } else {
            // 断言被拒绝 → 结果无效（不应发生，因为我们不处理争议失败的情况）
            // 在实际场景中，争议成功意味着结果错误，需要重新提议
            revert InvalidMatchFacts("Assertion rejected by dispute");
        }

        _finalized[marketId] = true;

        // 发出事件
        emit AssertionSettledSuccessfully(marketId, assertionId, assertionAccepted);
        emit ResultFinalized(marketId, keccak256(abi.encode(_finalizedResults[marketId])), assertionAccepted);
    }

    /*//////////////////////////////////////////////////////////////
                          DISPUTE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 争议断言（任何人都可以调用，需要质押）
     * @dev 调用者必须预先授权 bondAmount 的 bondCurrency 给 UMA OOV3
     * @param marketId 市场ID
     * @param reason 争议原因（链下存储）
     */
    function disputeAssertion(bytes32 marketId, string calldata reason) external {
        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            revert NoAssertionFound(marketId);
        }

        // 检查争议者的质押授权
        uint256 currentAllowance = bondCurrency.allowance(msg.sender, address(optimisticOracle));
        if (currentAllowance < bondAmount) {
            revert InsufficientBondAllowance(bondAmount, currentAllowance);
        }

        // 调用 UMA OOV3 争议
        optimisticOracle.disputeAssertion(assertionId, msg.sender);

        // 发出事件
        bytes32 factsHash = keccak256(abi.encode(_proposedResults[marketId]));
        emit ResultDisputed(marketId, factsHash, msg.sender, reason);
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取断言详情
     * @param marketId 市场ID
     * @return 断言数据
     */
    function getAssertionDetails(bytes32 marketId)
        external
        view
        returns (IOptimisticOracleV3.Assertion memory)
    {
        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            revert NoAssertionFound(marketId);
        }

        return optimisticOracle.getAssertion(assertionId);
    }

    /**
     * @notice 检查断言是否可以结算
     * @param marketId 市场ID
     * @return 是否可以结算
     */
    function canSettle(bytes32 marketId) external view returns (bool) {
        bytes32 assertionId = marketAssertions[marketId];
        if (assertionId == bytes32(0)) {
            return false;
        }

        IOptimisticOracleV3.Assertion memory assertion = optimisticOracle.getAssertion(assertionId);

        // 如果已解决，返回 false（已结算）
        if (assertion.resolved) {
            return false;
        }

        // 如果被争议，等待 DVM 仲裁（由 DVM 自动解决）
        if (assertion.disputed) {
            return false; // DVM 解决后会自动标记为 resolved
        }

        // 如果未被争议且过了 liveness 期，可以结算
        return block.timestamp >= assertion.expirationTime;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 验证 MatchFacts 数据合法性
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

        // 验证进球数合理性
        if (facts.homeGoals > 50 || facts.awayGoals > 50) {
            revert InvalidMatchFacts("Goals exceed limit");
        }

        // 验证点球数据一致性
        if (facts.scope == bytes32("Penalties")) {
            if (!facts.extraTime) {
                revert InvalidMatchFacts("Penalties require extraTime");
            }
            if (facts.penaltiesHome == 0 && facts.penaltiesAway == 0) {
                revert InvalidMatchFacts("Penalties data missing");
            }
        } else {
            if (facts.penaltiesHome != 0 || facts.penaltiesAway != 0) {
                revert InvalidMatchFacts("Unexpected penalties data");
            }
        }

        // 验证时间戳合理性
        if (facts.reportedAt > block.timestamp) {
            revert InvalidMatchFacts("Future timestamp");
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 紧急提取质押币（仅限 Owner，用于合约升级）
     * @dev 仅在没有活跃断言时使用
     * @param recipient 接收地址
     * @param amount 提取金额
     */
    function emergencyWithdraw(address recipient, uint256 amount) external onlyOwner {
        bondCurrency.safeTransfer(recipient, amount);
    }
}
