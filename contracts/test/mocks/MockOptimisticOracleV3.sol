// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IOptimisticOracleV3} from "../../src/interfaces/IOptimisticOracleV3.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MockOptimisticOracleV3
 * @notice UMA OOV3 的简化 Mock 实现，用于测试
 * @dev 实现核心断言流程，但简化了实际的质押和争议逻辑
 */
contract MockOptimisticOracleV3 is IOptimisticOracleV3 {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 断言计数器
    uint256 private _assertionCounter;

    /// @notice assertionId => Assertion
    mapping(bytes32 => Assertion) public assertions;

    /// @notice assertionId => claim data
    mapping(bytes32 => bytes) public assertionClaims;

    /// @notice 默认标识符
    bytes32 public constant override defaultIdentifier = bytes32("ASSERT_TRUTH");

    /// @notice 最小质押金额（简化为固定值）
    uint256 public constant MINIMUM_BOND = 1000e6; // 1000 USDC

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier assertionExists(bytes32 assertionId) {
        require(assertions[assertionId].asserter != address(0), "Assertion does not exist");
        _;
    }

    modifier assertionNotResolved(bytes32 assertionId) {
        require(!assertions[assertionId].resolved, "Assertion already resolved");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 使用默认参数提交断言
     */
    function assertTruthWithDefaults(bytes calldata claim, address asserter)
        external
        override
        returns (bytes32 assertionId)
    {
        // 使用默认参数调用完整版本
        return this.assertTruth(
            claim,
            asserter,
            address(0),              // callbackRecipient
            address(0),              // escalationManager
            7200,                    // 2 hours liveness
            address(0),              // currency (will be set to default)
            MINIMUM_BOND,            // bond
            defaultIdentifier,       // identifier
            bytes32(0)              // domainId
        );
    }

    /**
     * @notice 提交完全自定义的断言
     */
    function assertTruth(
        bytes calldata claim,
        address asserter,
        address callbackRecipient,
        address, // escalationManager (ignored in mock)
        uint64 liveness,
        address currency,
        uint256 bond,
        bytes32 identifier,
        bytes32 domainId
    ) external override returns (bytes32 assertionId) {
        // 生成断言ID
        _assertionCounter++;
        assertionId = keccak256(abi.encode(claim, asserter, _assertionCounter));

        // 创建断言
        uint64 expirationTime = uint64(block.timestamp) + liveness;

        assertions[assertionId] = Assertion({
            resolved: false,
            disputed: false,
            settlementResolution: false,
            asserter: asserter,
            disputer: address(0),
            callbackRecipient: callbackRecipient,
            currency: currency,
            expirationTime: expirationTime,
            bond: bond,
            identifier: identifier,
            domainId: domainId
        });

        assertionClaims[assertionId] = claim;

        // 模拟质押转账（简化，不实际转账）
        if (currency != address(0) && bond > 0) {
            IERC20(currency).transferFrom(asserter, address(this), bond);
        }

        // 发出事件
        emit AssertionMade(
            assertionId,
            domainId,
            claim,
            asserter,
            callbackRecipient,
            address(0), // escalationManager
            msg.sender,
            expirationTime,
            currency,
            bond,
            identifier
        );

        return assertionId;
    }

    /**
     * @notice 争议断言
     */
    function disputeAssertion(bytes32 assertionId, address disputer)
        external
        override
        assertionExists(assertionId)
        assertionNotResolved(assertionId)
    {
        Assertion storage assertion = assertions[assertionId];

        // 检查是否在有效期内
        require(block.timestamp < assertion.expirationTime, "Liveness period expired");

        // 标记为被争议
        assertion.disputed = true;
        assertion.disputer = disputer;

        // 模拟质押转账（简化）
        if (assertion.currency != address(0) && assertion.bond > 0) {
            IERC20(assertion.currency).transferFrom(disputer, address(this), assertion.bond);
        }

        // 发出事件
        emit AssertionDisputed(assertionId, msg.sender, disputer);
    }

    /**
     * @notice 结算断言
     */
    function settleAssertion(bytes32 assertionId)
        external
        override
        assertionExists(assertionId)
        assertionNotResolved(assertionId)
    {
        Assertion storage assertion = assertions[assertionId];

        // 检查是否可以结算
        if (!assertion.disputed) {
            // 未被争议：检查 liveness 期是否过期
            require(block.timestamp >= assertion.expirationTime, "Liveness period not expired");
            // 断言被接受
            assertion.settlementResolution = true;

            // 返还质押给断言者
            if (assertion.currency != address(0) && assertion.bond > 0) {
                IERC20(assertion.currency).transfer(assertion.asserter, assertion.bond);
            }
        } else {
            // 被争议：在实际 UMA 中由 DVM 仲裁
            // Mock 中简化为自动拒绝（可以通过辅助函数模拟DVM结果）
            assertion.settlementResolution = false;

            // 返还质押给争议者
            if (assertion.currency != address(0) && assertion.bond > 0) {
                IERC20(assertion.currency).transfer(assertion.disputer, assertion.bond * 2); // 争议者获得双倍
            }
        }

        assertion.resolved = true;

        // 发出事件
        emit AssertionSettled(
            assertionId,
            assertion.settlementResolution ? assertion.asserter : assertion.disputer,
            assertion.disputed,
            assertion.settlementResolution,
            msg.sender
        );
    }

    /**
     * @notice 结算断言并返回结果
     */
    function settleAndGetAssertionResult(bytes32 assertionId)
        external
        override
        returns (bool)
    {
        // 如果未解决，先结算
        if (!assertions[assertionId].resolved) {
            this.settleAssertion(assertionId);
        }

        return assertions[assertionId].settlementResolution;
    }

    /**
     * @notice 获取断言数据
     */
    function getAssertion(bytes32 assertionId)
        external
        view
        override
        returns (Assertion memory)
    {
        return assertions[assertionId];
    }

    /**
     * @notice 获取最小质押金额
     */
    function getMinimumBond(address) external pure override returns (uint256) {
        return MINIMUM_BOND;
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS (测试专用)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 模拟 DVM 仲裁结果（测试专用）
     * @param assertionId 断言ID
     * @param result DVM 仲裁结果（true = 断言正确）
     */
    function mockDVMResolve(bytes32 assertionId, bool result) external {
        Assertion storage assertion = assertions[assertionId];
        require(assertion.disputed, "Assertion not disputed");
        require(!assertion.resolved, "Already resolved");

        assertion.settlementResolution = result;
        assertion.resolved = true;

        // 发出事件
        emit AssertionSettled(
            assertionId,
            result ? assertion.asserter : assertion.disputer,
            true,
            result,
            msg.sender
        );
    }

    /**
     * @notice 快进时间（测试专用）
     * @dev 实际测试中使用 vm.warp，这里仅作占位
     */
    function fastForward(uint256) external pure {
        // Placeholder for test helpers
        revert("Use vm.warp in tests");
    }

    /**
     * @notice 获取断言声明数据
     * @param assertionId 断言ID
     * @return 声明数据
     */
    function getAssertionClaim(bytes32 assertionId) external view returns (bytes memory) {
        return assertionClaims[assertionId];
    }
}
