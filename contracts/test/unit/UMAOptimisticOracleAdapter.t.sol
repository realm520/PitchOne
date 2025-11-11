// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/oracle/UMAOptimisticOracleAdapter.sol";
import "../../src/interfaces/IResultOracle.sol";
import "../mocks/MockOptimisticOracleV3.sol";
import "../mocks/MockERC20.sol";

/**
 * @title UMAOptimisticOracleAdapterTest
 * @notice UMA OOV3 Adapter 单元测试
 */
contract UMAOptimisticOracleAdapterTest is Test {
    UMAOptimisticOracleAdapter public adapter;
    MockOptimisticOracleV3 public mockOO;
    MockERC20 public bondCurrency;

    address public owner = address(0x1);
    address public proposer = address(0x2);
    address public disputer = address(0x3);

    uint256 public constant BOND_AMOUNT = 1000e6; // 1000 USDC
    uint64 public constant LIVENESS = 7200; // 2 hours
    bytes32 public constant IDENTIFIER = bytes32("ASSERT_TRUTH");

    bytes32 public constant MARKET_ID = bytes32(uint256(1));

    IResultOracle.MatchFacts public sampleFacts;

    event ResultProposed(
        bytes32 indexed marketId,
        IResultOracle.MatchFacts facts,
        bytes32 indexed factsHash,
        address indexed proposer
    );

    event ResultDisputed(
        bytes32 indexed marketId,
        bytes32 indexed factsHash,
        address indexed disputer,
        string reason
    );

    event ResultFinalized(
        bytes32 indexed marketId,
        bytes32 indexed factsHash,
        bool accepted
    );

    function setUp() public {
        // Deploy mock contracts
        bondCurrency = new MockERC20("Mock USDC", "USDC", 6);
        mockOO = new MockOptimisticOracleV3();

        // Deploy adapter
        vm.prank(owner);
        adapter = new UMAOptimisticOracleAdapter(
            address(mockOO),
            address(bondCurrency),
            BOND_AMOUNT,
            LIVENESS,
            IDENTIFIER,
            owner
        );

        // Setup sample facts
        sampleFacts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        // Mint and approve bond currency
        bondCurrency.mint(proposer, BOND_AMOUNT * 10);
        bondCurrency.mint(disputer, BOND_AMOUNT * 10);

        vm.prank(proposer);
        bondCurrency.approve(address(mockOO), type(uint256).max);

        vm.prank(disputer);
        bondCurrency.approve(address(mockOO), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSE RESULT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ProposeResult_Success() public {
        vm.prank(proposer);
        vm.expectEmit(true, true, true, false);
        emit ResultProposed(MARKET_ID, sampleFacts, keccak256(abi.encode(sampleFacts)), proposer);

        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Verify assertion was created
        bytes32 assertionId = adapter.marketAssertions(MARKET_ID);
        assertNotEq(assertionId, bytes32(0), "Assertion ID should be set");

        // Verify reverse mapping
        assertEq(adapter.assertionMarkets(assertionId), MARKET_ID, "Reverse mapping should work");
    }

    function test_ProposeResult_RevertIf_DuplicateProposal() public {
        // First proposal
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Second proposal should fail
        vm.prank(proposer);
        vm.expectRevert();
        adapter.proposeResult(MARKET_ID, sampleFacts);
    }

    function test_ProposeResult_RevertIf_InvalidScope() public {
        sampleFacts.scope = bytes32("INVALID");

        vm.prank(proposer);
        vm.expectRevert(
            abi.encodeWithSelector(
                UMAOptimisticOracleAdapter.InvalidMatchFacts.selector,
                "Invalid scope"
            )
        );
        adapter.proposeResult(MARKET_ID, sampleFacts);
    }

    function test_ProposeResult_RevertIf_ExcessiveGoals() public {
        sampleFacts.homeGoals = 51;

        vm.prank(proposer);
        vm.expectRevert(
            abi.encodeWithSelector(
                UMAOptimisticOracleAdapter.InvalidMatchFacts.selector,
                "Goals exceed limit"
            )
        );
        adapter.proposeResult(MARKET_ID, sampleFacts);
    }

    function test_ProposeResult_RevertIf_FutureTimestamp() public {
        sampleFacts.reportedAt = block.timestamp + 1 days;

        vm.prank(proposer);
        vm.expectRevert(
            abi.encodeWithSelector(
                UMAOptimisticOracleAdapter.InvalidMatchFacts.selector,
                "Future timestamp"
            )
        );
        adapter.proposeResult(MARKET_ID, sampleFacts);
    }

    function test_ProposeResult_RevertIf_InsufficientAllowance() public {
        // Revoke approval
        vm.prank(proposer);
        bondCurrency.approve(address(mockOO), 0);

        vm.prank(proposer);
        vm.expectRevert();
        adapter.proposeResult(MARKET_ID, sampleFacts);
    }

    /*//////////////////////////////////////////////////////////////
                        GET RESULT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetResult_BeforeFinalization() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Get result (should return proposed result, not finalized)
        (IResultOracle.MatchFacts memory facts, bool finalized) = adapter.getResult(MARKET_ID);

        assertEq(facts.homeGoals, sampleFacts.homeGoals, "Home goals should match");
        assertEq(facts.awayGoals, sampleFacts.awayGoals, "Away goals should match");
        assertFalse(finalized, "Should not be finalized yet");
    }

    function test_GetResult_AfterFinalization() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Fast forward past liveness period
        vm.warp(block.timestamp + LIVENESS + 1);

        // Settle assertion
        adapter.settleAssertion(MARKET_ID);

        // Get result (should be finalized)
        (IResultOracle.MatchFacts memory facts, bool finalized) = adapter.getResult(MARKET_ID);

        assertEq(facts.homeGoals, sampleFacts.homeGoals, "Home goals should match");
        assertTrue(finalized, "Should be finalized");
    }

    function test_GetResult_RevertIf_NoAssertion() public {
        vm.expectRevert();
        adapter.getResult(MARKET_ID);
    }

    /*//////////////////////////////////////////////////////////////
                        SETTLEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SettleAssertion_Success_NoDispute() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Fast forward past liveness period
        vm.warp(block.timestamp + LIVENESS + 1);

        // Settle assertion
        vm.expectEmit(true, true, false, false);
        emit ResultFinalized(MARKET_ID, keccak256(abi.encode(sampleFacts)), true);

        adapter.settleAssertion(MARKET_ID);

        // Verify finalized
        assertTrue(adapter.isFinalized(MARKET_ID), "Should be finalized");

        // Verify result
        (IResultOracle.MatchFacts memory facts, bool finalized) = adapter.getResult(MARKET_ID);
        assertEq(facts.homeGoals, 2, "Result should be preserved");
        assertTrue(finalized, "Should be finalized");
    }

    function test_SettleAssertion_RevertIf_TooEarly() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Try to settle immediately (should fail)
        vm.expectRevert();
        adapter.settleAssertion(MARKET_ID);
    }

    function test_SettleAssertion_RevertIf_NoAssertion() public {
        vm.expectRevert();
        adapter.settleAssertion(MARKET_ID);
    }

    /*//////////////////////////////////////////////////////////////
                        DISPUTE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DisputeAssertion_Success() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Dispute assertion
        string memory reason = "Incorrect result";
        vm.prank(disputer);
        vm.expectEmit(true, true, true, false);
        emit ResultDisputed(MARKET_ID, keccak256(abi.encode(sampleFacts)), disputer, reason);

        adapter.disputeAssertion(MARKET_ID, reason);

        // Verify dispute in UMA OOV3
        bytes32 assertionId = adapter.marketAssertions(MARKET_ID);
        IOptimisticOracleV3.Assertion memory assertion = mockOO.getAssertion(assertionId);
        assertTrue(assertion.disputed, "Assertion should be disputed");
        assertEq(assertion.disputer, disputer, "Disputer should be recorded");
    }

    function test_DisputeAssertion_RevertIf_NoAssertion() public {
        vm.prank(disputer);
        vm.expectRevert();
        adapter.disputeAssertion(MARKET_ID, "No assertion");
    }

    function test_DisputeAssertion_RevertIf_AfterExpiration() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Fast forward past liveness period
        vm.warp(block.timestamp + LIVENESS + 1);

        // Try to dispute (should fail)
        vm.prank(disputer);
        vm.expectRevert();
        adapter.disputeAssertion(MARKET_ID, "Too late");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsFinalized() public {
        // Before proposal
        assertFalse(adapter.isFinalized(MARKET_ID), "Should not be finalized initially");

        // After proposal
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);
        assertFalse(adapter.isFinalized(MARKET_ID), "Should not be finalized after proposal");

        // After settlement
        vm.warp(block.timestamp + LIVENESS + 1);
        adapter.settleAssertion(MARKET_ID);
        assertTrue(adapter.isFinalized(MARKET_ID), "Should be finalized after settlement");
    }

    function test_GetResultHash() public {
        // Before proposal
        assertEq(adapter.getResultHash(MARKET_ID), bytes32(0), "Hash should be zero initially");

        // After proposal
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        bytes32 expectedHash = keccak256(abi.encode(sampleFacts));
        assertEq(adapter.getResultHash(MARKET_ID), expectedHash, "Hash should match after proposal");

        // After settlement (should remain the same)
        vm.warp(block.timestamp + LIVENESS + 1);
        adapter.settleAssertion(MARKET_ID);
        assertEq(adapter.getResultHash(MARKET_ID), expectedHash, "Hash should remain after settlement");
    }

    function test_CanSettle() public {
        // Before proposal
        assertFalse(adapter.canSettle(MARKET_ID), "Cannot settle without assertion");

        // After proposal, before liveness
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);
        assertFalse(adapter.canSettle(MARKET_ID), "Cannot settle during liveness");

        // After liveness
        vm.warp(block.timestamp + LIVENESS + 1);
        assertTrue(adapter.canSettle(MARKET_ID), "Can settle after liveness");

        // After settlement
        adapter.settleAssertion(MARKET_ID);
        assertFalse(adapter.canSettle(MARKET_ID), "Cannot settle again");
    }

    function test_CanSettle_AfterDispute() public {
        // Propose and dispute
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        vm.prank(disputer);
        adapter.disputeAssertion(MARKET_ID, "Test dispute");

        // Should not be settlable (waiting for DVM)
        vm.warp(block.timestamp + LIVENESS + 1);
        assertFalse(adapter.canSettle(MARKET_ID), "Cannot settle during DVM resolution");
    }

    function test_GetAssertionDetails() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Get assertion details
        IOptimisticOracleV3.Assertion memory assertion = adapter.getAssertionDetails(MARKET_ID);

        assertEq(assertion.asserter, proposer, "Asserter should match");
        assertEq(assertion.bond, BOND_AMOUNT, "Bond amount should match");
        assertEq(assertion.currency, address(bondCurrency), "Currency should match");
        assertFalse(assertion.resolved, "Should not be resolved");
        assertFalse(assertion.disputed, "Should not be disputed");
    }

    /*//////////////////////////////////////////////////////////////
                        PENALTY/SLASH SCENARIOS
    //////////////////////////////////////////////////////////////*/

    function test_Scenario_DisputeWins() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Dispute assertion
        vm.prank(disputer);
        adapter.disputeAssertion(MARKET_ID, "Result is wrong");

        // Mock DVM resolves in favor of disputer (assertion is false)
        bytes32 assertionId = adapter.marketAssertions(MARKET_ID);
        mockOO.mockDVMResolve(assertionId, false); // false = disputer wins

        // Verify assertion state
        IOptimisticOracleV3.Assertion memory assertion = mockOO.getAssertion(assertionId);
        assertTrue(assertion.resolved, "Should be resolved");
        assertFalse(assertion.settlementResolution, "Should be rejected (disputer wins)");
        assertEq(assertion.disputer, disputer, "Disputer should be recorded");
    }

    function test_Scenario_ProposerWinsDispute() public {
        // Propose result
        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, sampleFacts);

        // Dispute assertion
        vm.prank(disputer);
        adapter.disputeAssertion(MARKET_ID, "Result is wrong");

        // Mock DVM resolves in favor of proposer (assertion is true)
        bytes32 assertionId = adapter.marketAssertions(MARKET_ID);
        mockOO.mockDVMResolve(assertionId, true); // true = proposer wins

        // Verify assertion is resolved with correct result
        IOptimisticOracleV3.Assertion memory assertion = mockOO.getAssertion(assertionId);
        assertTrue(assertion.resolved, "Should be resolved");
        assertTrue(assertion.settlementResolution, "Should be accepted");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function testFuzz_ProposeResult_DifferentMatchFacts(
        uint8 homeGoals,
        uint8 awayGoals,
        bool extraTime
    ) public {
        vm.assume(homeGoals <= 50);
        vm.assume(awayGoals <= 50);

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: extraTime ? bytes32("FT_120") : bytes32("FT_90"),
            homeGoals: homeGoals,
            awayGoals: awayGoals,
            extraTime: extraTime,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(proposer);
        adapter.proposeResult(MARKET_ID, facts);

        (IResultOracle.MatchFacts memory retrieved,) = adapter.getResult(MARKET_ID);
        assertEq(retrieved.homeGoals, homeGoals, "Fuzz: home goals should match");
        assertEq(retrieved.awayGoals, awayGoals, "Fuzz: away goals should match");
    }

    function test_MultipleMarkets() public {
        bytes32 marketId1 = bytes32(uint256(1));
        bytes32 marketId2 = bytes32(uint256(2));

        IResultOracle.MatchFacts memory facts1 = sampleFacts;
        IResultOracle.MatchFacts memory facts2 = sampleFacts;
        facts2.homeGoals = 3;
        facts2.awayGoals = 3;

        // Propose two different results
        vm.prank(proposer);
        adapter.proposeResult(marketId1, facts1);

        vm.prank(proposer);
        adapter.proposeResult(marketId2, facts2);

        // Verify both are stored correctly
        (IResultOracle.MatchFacts memory retrieved1,) = adapter.getResult(marketId1);
        (IResultOracle.MatchFacts memory retrieved2,) = adapter.getResult(marketId2);

        assertEq(retrieved1.homeGoals, 2, "Market 1 result should be correct");
        assertEq(retrieved2.homeGoals, 3, "Market 2 result should be correct");
    }
}
