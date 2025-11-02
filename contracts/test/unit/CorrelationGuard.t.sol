// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/parlay/CorrelationGuard.sol";
import "../../src/interfaces/ICorrelationGuard.sol";

/**
 * @title CorrelationGuardTest
 * @notice Unit tests for CorrelationGuard contract
 */
contract CorrelationGuardTest is BaseTest {
    CorrelationGuard public guard;

    // Test data
    bytes32 constant MATCH_ID_1 = keccak256("EPL_2024_MUN_vs_MCI");
    bytes32 constant MATCH_ID_2 = keccak256("EPL_2024_LIV_vs_CHE");
    bytes32 constant MATCH_ID_3 = keccak256("EPL_2024_ARS_vs_TOT");

    uint256 constant DEFAULT_PENALTY = 2000; // 20%

    event PolicyUpdated(
        ICorrelationGuard.CorrelationPolicy indexed oldPolicy,
        ICorrelationGuard.CorrelationPolicy indexed newPolicy
    );

    event CorrelationRuleSet(
        bytes32 indexed matchId1,
        bytes32 indexed matchId2,
        uint256 penaltyBps,
        bool isBlocked
    );

    event DefaultPenaltyUpdated(uint256 sameMatchPenalty);

    function setUp() public override {
        super.setUp();

        // Deploy CorrelationGuard
        guard = new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            DEFAULT_PENALTY
        );

        vm.label(address(guard), "CorrelationGuard");
    }

    // ============================================================================
    // Constructor Tests
    // ============================================================================

    function test_Constructor_Success() public {
        assertEq(
            uint256(guard.getPolicy()),
            uint256(ICorrelationGuard.CorrelationPolicy.PENALTY),
            "Policy mismatch"
        );
        assertEq(guard.defaultSameMatchPenalty(), DEFAULT_PENALTY, "Default penalty mismatch");
    }

    function test_Constructor_RevertIf_InvalidPenalty() public {
        vm.expectRevert(abi.encodeWithSelector(ICorrelationGuard.InvalidPenalty.selector, 10001));
        new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            10001 // > MAX_PENALTY_BPS
        );
    }

    function test_Constructor_EmitsEvents() public {
        vm.expectEmit(true, true, false, false);
        emit PolicyUpdated(
            ICorrelationGuard.CorrelationPolicy.ALLOW_ALL,
            ICorrelationGuard.CorrelationPolicy.PENALTY
        );

        vm.expectEmit(false, false, false, true);
        emit DefaultPenaltyUpdated(DEFAULT_PENALTY);

        new CorrelationGuard(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            DEFAULT_PENALTY
        );
    }

    // ============================================================================
    // Policy Management Tests
    // ============================================================================

    function test_SetPolicy_Success() public {
        vm.expectEmit(true, true, false, false);
        emit PolicyUpdated(
            ICorrelationGuard.CorrelationPolicy.PENALTY,
            ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK
        );

        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK);

        assertEq(
            uint256(guard.getPolicy()),
            uint256(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK)
        );
    }

    function test_SetPolicy_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.ALLOW_ALL);
    }

    // ============================================================================
    // Correlation Rule Tests
    // ============================================================================

    function test_SetCorrelationRule_Success() public {
        uint256 penaltyBps = 1500; // 15%

        // Event should emit with ordered matchIds (min, max)
        bytes32 min = MATCH_ID_1 < MATCH_ID_2 ? MATCH_ID_1 : MATCH_ID_2;
        bytes32 max = MATCH_ID_1 < MATCH_ID_2 ? MATCH_ID_2 : MATCH_ID_1;

        vm.expectEmit(true, true, false, true);
        emit CorrelationRuleSet(min, max, penaltyBps, false);

        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, penaltyBps, false);

        (uint256 penalty, bool isBlocked) = guard.getCorrelationRule(MATCH_ID_1, MATCH_ID_2);
        assertEq(penalty, penaltyBps);
        assertFalse(isBlocked);
    }

    function test_SetCorrelationRule_OrderIndependent() public {
        uint256 penaltyBps = 1500;

        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, penaltyBps, false);

        // Query in reverse order should return same result
        (uint256 penalty, bool isBlocked) = guard.getCorrelationRule(MATCH_ID_2, MATCH_ID_1);
        assertEq(penalty, penaltyBps);
        assertFalse(isBlocked);
    }

    function test_SetCorrelationRule_Blocked() public {
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 0, true);

        (uint256 penalty, bool isBlocked) = guard.getCorrelationRule(MATCH_ID_1, MATCH_ID_2);
        assertEq(penalty, 0);
        assertTrue(isBlocked);
    }

    function test_SetCorrelationRule_RevertIf_InvalidPenalty() public {
        vm.expectRevert(abi.encodeWithSelector(ICorrelationGuard.InvalidPenalty.selector, 10001));
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 10001, false);
    }

    function test_SetCorrelationRule_RevertIf_NotAuthorized() public {
        vm.prank(user1);
        vm.expectRevert();
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 1500, false);
    }

    // ============================================================================
    // Batch Set Rules Tests
    // ============================================================================

    function test_BatchSetRules_Success() public {
        ICorrelationGuard.CorrelationRule[] memory rules =
            new ICorrelationGuard.CorrelationRule[](2);

        rules[0] = ICorrelationGuard.CorrelationRule({
            matchId1: MATCH_ID_1,
            matchId2: MATCH_ID_2,
            penaltyBps: 1500,
            isBlocked: false
        });

        rules[1] = ICorrelationGuard.CorrelationRule({
            matchId1: MATCH_ID_2,
            matchId2: MATCH_ID_3,
            penaltyBps: 2000,
            isBlocked: true
        });

        guard.batchSetRules(rules);

        (uint256 penalty1, bool blocked1) = guard.getCorrelationRule(MATCH_ID_1, MATCH_ID_2);
        assertEq(penalty1, 1500);
        assertFalse(blocked1);

        (uint256 penalty2, bool blocked2) = guard.getCorrelationRule(MATCH_ID_2, MATCH_ID_3);
        assertEq(penalty2, 2000);
        assertTrue(blocked2);
    }

    // ============================================================================
    // Check Blocked Tests
    // ============================================================================

    function test_CheckBlocked_AllowAll_NeverBlocks() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.ALLOW_ALL);

        // Set a blocking rule
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 0, true);

        // Create legs
        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        // Register markets
        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);

        (bool isBlocked, string memory reason) = guard.checkBlocked(legs);
        assertFalse(isBlocked);
        assertEq(reason, "");
    }

    function test_CheckBlocked_StrictBlock_BlocksCorrelated() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK);
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 0, true);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);

        (bool isBlocked, string memory reason) = guard.checkBlocked(legs);
        assertTrue(isBlocked);
        assertTrue(bytes(reason).length > 0);
    }

    function test_CheckBlocked_SameMatch_StrictBlock() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.STRICT_BLOCK);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        // Both markets have same matchId
        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_1);

        (bool isBlocked, string memory reason) = guard.checkBlocked(legs);
        assertTrue(isBlocked);
        assertEq(reason, "Blocked: same match correlation");
    }

    // ============================================================================
    // Calculate Penalty Tests
    // ============================================================================

    function test_CalculatePenalty_NoPenalty() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.PENALTY);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);

        // No rule set, so no penalty
        (uint256 totalPenalty, uint256[] memory details) = guard.calculatePenalty(legs);
        assertEq(totalPenalty, 0);
        assertEq(details.length, 1); // One pair
        assertEq(details[0], 0);
    }

    function test_CalculatePenalty_WithRule() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.PENALTY);
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 1500, false);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);

        (uint256 totalPenalty, uint256[] memory details) = guard.calculatePenalty(legs);
        assertEq(totalPenalty, 1500);
        assertEq(details.length, 1);
        assertEq(details[0], 1500);
    }

    function test_CalculatePenalty_SameMatch_UsesDefault() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.PENALTY);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](2);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});

        // Same match
        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_1);

        (uint256 totalPenalty,) = guard.calculatePenalty(legs);
        assertEq(totalPenalty, DEFAULT_PENALTY);
    }

    function test_CalculatePenalty_MultipleLegs() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.PENALTY);
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 1000, false);
        guard.setCorrelationRule(MATCH_ID_2, MATCH_ID_3, 1500, false);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](3);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});
        legs[2] = ICorrelationGuard.ParlayLeg({market: address(0x3), outcomeId: 2});

        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);
        guard.registerMarket(address(0x3), MATCH_ID_3);

        (uint256 totalPenalty, uint256[] memory details) = guard.calculatePenalty(legs);

        // 3 pairs: (1,2), (2,3), (1,3)
        assertEq(details.length, 3);
        assertEq(details[0], 1000); // Match 1-2
        assertEq(details[1], 0); // Match 1-3 (no rule)
        assertEq(details[2], 1500); // Match 2-3

        assertEq(totalPenalty, 1000 + 1500); // 2500
    }

    function test_CalculatePenalty_CappedAt100Percent() public {
        guard.setPolicy(ICorrelationGuard.CorrelationPolicy.PENALTY);
        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, 6000, false);
        guard.setCorrelationRule(MATCH_ID_2, MATCH_ID_3, 6000, false);

        ICorrelationGuard.ParlayLeg[] memory legs = new ICorrelationGuard.ParlayLeg[](3);
        legs[0] = ICorrelationGuard.ParlayLeg({market: address(0x1), outcomeId: 0});
        legs[1] = ICorrelationGuard.ParlayLeg({market: address(0x2), outcomeId: 1});
        legs[2] = ICorrelationGuard.ParlayLeg({market: address(0x3), outcomeId: 2});

        guard.registerMarket(address(0x1), MATCH_ID_1);
        guard.registerMarket(address(0x2), MATCH_ID_2);
        guard.registerMarket(address(0x3), MATCH_ID_3);

        (uint256 totalPenalty,) = guard.calculatePenalty(legs);

        // Should be capped at 10000 (100%)
        assertEq(totalPenalty, 10000);
    }

    // ============================================================================
    // Default Penalty Management Tests
    // ============================================================================

    function test_SetDefaultPenalty_Success() public {
        uint256 newPenalty = 3000;

        vm.expectEmit(false, false, false, true);
        emit DefaultPenaltyUpdated(newPenalty);

        guard.setDefaultSameMatchPenalty(newPenalty);
        assertEq(guard.defaultSameMatchPenalty(), newPenalty);
    }

    function test_SetDefaultPenalty_RevertIf_InvalidPenalty() public {
        vm.expectRevert(abi.encodeWithSelector(ICorrelationGuard.InvalidPenalty.selector, 10001));
        guard.setDefaultSameMatchPenalty(10001);
    }

    function test_SetDefaultPenalty_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        guard.setDefaultSameMatchPenalty(3000);
    }

    // ============================================================================
    // Market Registration Tests
    // ============================================================================

    function test_RegisterMarket_Success() public {
        guard.registerMarket(address(0x123), MATCH_ID_1);
        bytes32 matchId = guard.getMatchId(address(0x123));
        assertEq(matchId, MATCH_ID_1);
    }

    function test_BatchRegisterMarkets_Success() public {
        address[] memory markets = new address[](2);
        markets[0] = address(0x1);
        markets[1] = address(0x2);

        bytes32[] memory matchIds = new bytes32[](2);
        matchIds[0] = MATCH_ID_1;
        matchIds[1] = MATCH_ID_2;

        guard.batchRegisterMarkets(markets, matchIds);

        assertEq(guard.getMatchId(address(0x1)), MATCH_ID_1);
        assertEq(guard.getMatchId(address(0x2)), MATCH_ID_2);
    }

    // ============================================================================
    // Edge Cases and Fuzz Tests
    // ============================================================================

    function testFuzz_SetCorrelationRule(uint256 penaltyBps) public {
        vm.assume(penaltyBps <= 10000);

        guard.setCorrelationRule(MATCH_ID_1, MATCH_ID_2, penaltyBps, false);

        (uint256 penalty,) = guard.getCorrelationRule(MATCH_ID_1, MATCH_ID_2);
        assertEq(penalty, penaltyBps);
    }
}
