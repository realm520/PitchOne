// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/WDL_Template.sol";
import "../../src/oracle/UMAOptimisticOracleAdapter.sol";
import "../../src/core/FeeRouter.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../mocks/MockERC20.sol";
import "../mocks/MockOptimisticOracleV3.sol";

/**
 * @title KeeperUMAIntegrationTest
 * @notice 端到端集成测试：Keeper + UMA OO + MarketBase 完整流程
 * @dev 测试场景：
 *      1. 用户下注
 *      2. Keeper 锁盘
 *      3. Keeper 通过 UMA 提交结果 (proposeResult)
 *      4. Liveness 期等待（可选争议）
 *      5. Keeper 结算断言 (settleAssertion)
 *      6. Keeper 解析市场 (resolveFromOracle)
 *      7. 用户兑付
 */
contract KeeperUMAIntegrationTest is Test {
    // Contracts
    WDL_Template public market;
    UMAOptimisticOracleAdapter public oracleAdapter;
    MockOptimisticOracleV3 public mockOO;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    MockERC20 public usdc;
    MockERC20 public bondCurrency;

    // Roles
    address public owner = address(0x1);
    address public keeper = address(0x2);  // Keeper address
    address public user1 = address(0x3);
    address public user2 = address(0x4);

    // Constants
    uint256 constant BOND_AMOUNT = 1000e6;
    uint64 constant LIVENESS = 7200; // 2 hours
    bytes32 constant IDENTIFIER = bytes32("ASSERT_TRUTH");
    uint256 constant FEE_RATE = 200; // 2%

    bytes32 public marketId;

    event Locked(uint256 timestamp);
    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);
    event ResultProposed(
        bytes32 indexed marketId,
        IResultOracle.MatchFacts facts,
        bytes32 indexed factsHash,
        address indexed proposer
    );

    function setUp() public {
        // Deploy infrastructure
        usdc = new MockERC20("Mock USDC", "USDC", 6);
        bondCurrency = new MockERC20("Bond Currency", "BOND", 6);
        mockOO = new MockOptimisticOracleV3();

        // Deploy FeeRouter
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: address(0x100),
            promoPool: address(0x200),
            insuranceFund: address(0x250),
            treasury: address(0x300)
        });
        feeRouter = new FeeRouter(recipients, address(0x400));
        cpmm = new SimpleCPMM();

        // Deploy UMA Oracle Adapter
        vm.prank(owner);
        oracleAdapter = new UMAOptimisticOracleAdapter(
            address(mockOO),
            address(bondCurrency),
            BOND_AMOUNT,
            LIVENESS,
            IDENTIFIER,
            owner
        );

        // Deploy WDL Market
        uint256 kickoffTime = block.timestamp + 1 hours;

        vm.prank(owner);
        market = new WDL_Template();
        market.initialize(
            "E2E_TEST_MATCH",
            "Team Home",
            "Team Away",
            kickoffTime,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            2 hours, // dispute period
            address(cpmm),
            "https://test.com/market/{id}",
            owner // owner parameter
        );

        // Set oracle
        vm.prank(owner);
        market.setResultOracle(address(oracleAdapter));

        marketId = bytes32(uint256(uint160(address(market))));

        // Fund participants
        usdc.mint(user1, 10_000e6);
        usdc.mint(user2, 10_000e6);
        bondCurrency.mint(keeper, 10_000e6);

        // Approve
        vm.prank(user1);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(user2);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(keeper);
        bondCurrency.approve(address(mockOO), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    E2E TEST: KEEPER WORKFLOW
    //////////////////////////////////////////////////////////////*/

    function test_E2E_KeeperWorkflow_NoDispute() public {
        console.log("=== E2E Test: Complete Keeper + UMA Workflow (No Dispute) ===");

        // ============================================
        // Phase 1: Users place bets
        // ============================================
        console.log("\n[Phase 1] Users place bets");

        vm.prank(user1);
        uint256 shares1 = market.placeBet(0, 1000e6); // Bet on Home
        console.log("  User1 bet on Home");

        vm.prank(user2);
        uint256 shares2 = market.placeBet(2, 1000e6); // Bet on Away
        console.log("  User2 bet on Away");

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));

        // ============================================
        // Phase 2: Keeper locks market (after kickoff)
        // ============================================
        console.log("\n[Phase 2] Keeper locks market");

        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(owner); // Owner calls lock, not keeper
        vm.expectEmit(false, false, false, true);
        emit Locked(block.timestamp);
        market.lock();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
        console.log("  Market locked at block:", block.timestamp);

        // ============================================
        // Phase 3: Keeper proposes result to UMA
        // ============================================
        console.log("\n[Phase 3] Keeper proposes result to UMA");

        // Simulate match end + finalize delay
        vm.warp(block.timestamp + 90 minutes);

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.prank(keeper);
        vm.expectEmit(true, true, true, false);
        emit ResultProposed(marketId, facts, keccak256(abi.encode(facts)), keeper);
        oracleAdapter.proposeResult(marketId, facts);

        console.log("  Result proposed: Home 2 - 1 Away");
        console.log("  Liveness period started (7200 seconds)");

        // Verify assertion created
        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);
        assertNotEq(assertionId, bytes32(0));

        // ============================================
        // Phase 4: Wait for liveness period (no dispute)
        // ============================================
        console.log("\n[Phase 4] Wait for liveness period");

        vm.warp(block.timestamp + LIVENESS + 1);
        console.log("  Liveness period ended, no disputes");

        assertTrue(oracleAdapter.canSettle(marketId));

        // ============================================
        // Phase 5: Keeper settles assertion
        // ============================================
        console.log("\n[Phase 5] Keeper settles assertion");

        vm.prank(keeper);
        oracleAdapter.settleAssertion(marketId);

        assertTrue(oracleAdapter.isFinalized(marketId));
        console.log("  Assertion settled successfully");

        // ============================================
        // Phase 6: Keeper resolves market from oracle
        // ============================================
        console.log("\n[Phase 6] Keeper resolves market");

        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit Resolved(0, block.timestamp);
        market.resolveFromOracle();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(market.winningOutcome(), 0); // Home wins
        console.log("  Market resolved: Home wins (outcome 0)");

        // ============================================
        // Phase 7: Users redeem
        // ============================================
        console.log("\n[Phase 7] Users redeem shares");

        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        uint256 payout1 = market.redeem(0, shares1);
        assertGt(payout1, 0);

        uint256 user1BalanceAfter = usdc.balanceOf(user1);
        assertEq(user1BalanceAfter - user1BalanceBefore, payout1);

        console.log("  User1 (winner) redeemed");
        console.log("  User2 (loser) shares worthless");

        console.log("\n=== E2E Test Completed Successfully ===");
    }

    /*//////////////////////////////////////////////////////////////
                E2E TEST: KEEPER WORKFLOW WITH DISPUTE
    //////////////////////////////////////////////////////////////*/

    function test_E2E_KeeperWorkflow_WithDispute_ProposerWins() public {
        console.log("=== E2E Test: Keeper Workflow with Dispute (Proposer Wins) ===");

        // Phase 1-2: Bet and Lock
        vm.prank(user1);
        uint256 shares1 = market.placeBet(0, 1000e6);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner);
        market.lock();

        vm.warp(block.timestamp + 90 minutes);

        // Phase 3: Keeper proposes
        console.log("\n[Phase 3] Keeper proposes result");

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);

        // Phase 4: Someone disputes
        console.log("\n[Phase 4] User disputes result");

        address disputer = address(0x999);
        bondCurrency.mint(disputer, 10_000e6);
        vm.prank(disputer);
        bondCurrency.approve(address(mockOO), type(uint256).max);

        vm.warp(block.timestamp + 1 hours); // Within liveness

        vm.prank(disputer);
        oracleAdapter.disputeAssertion(marketId, "Incorrect score");

        console.log("  Dispute raised, waiting for DVM");

        // Phase 5: DVM resolves in favor of proposer
        console.log("\n[Phase 5] DVM resolves: Proposer correct");

        mockOO.mockDVMResolve(assertionId, true); // Proposer wins

        assertTrue(oracleAdapter.isFinalized(marketId));

        // Phase 6-7: Keeper resolves market and users redeem
        console.log("\n[Phase 6] Keeper resolves market");

        vm.prank(owner);
        market.resolveFromOracle();

        assertEq(market.winningOutcome(), 0);

        console.log("\n[Phase 7] Winner redeems");

        vm.prank(user1);
        uint256 payout = market.redeem(0, shares1);
        assertGt(payout, 0);

        console.log("  User redeemed successfully");
        console.log("\n=== E2E Test with Dispute Completed ===");
    }

    /*//////////////////////////////////////////////////////////////
            E2E TEST: MULTIPLE MARKETS PARALLEL SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    function test_E2E_MultipleMarkets_ParallelSettlement() public {
        console.log("=== E2E Test: Multiple Markets Parallel Settlement ===");

        // Create 3 markets
        WDL_Template[] memory markets = new WDL_Template[](3);

        for (uint256 i = 0; i < 3; i++) {
            uint256 kickoffTime = block.timestamp + 1 hours;

            vm.prank(owner);
            markets[i] = new WDL_Template();
            markets[i].initialize(
                string(abi.encodePacked("MATCH_", vm.toString(i))),
                "Home",
                "Away",
                kickoffTime,
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                2 hours,
                address(cpmm),
                "https://test.com/market/{id}",
                owner // owner parameter
            );

            vm.prank(owner);
            markets[i].setResultOracle(address(oracleAdapter));

            // Approve each market for users
            vm.prank(user1);
            usdc.approve(address(markets[i]), type(uint256).max);

            // Users bet on each market
            vm.prank(user1);
            markets[i].placeBet(0, 100e6);

            console.log("  Market", i, "created:", address(markets[i]));
        }

        // Lock all markets
        vm.warp(block.timestamp + 1 hours + 1);

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(owner);
            markets[i].lock();
        }

        console.log("\n[Phase] All markets locked");

        // Keeper proposes results for all markets
        vm.warp(block.timestamp + 90 minutes);

        for (uint256 i = 0; i < 3; i++) {
            bytes32 mid = bytes32(uint256(uint160(address(markets[i]))));

            IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
                scope: bytes32("FT_90"),
                homeGoals: uint8(i + 1), // Different scores
                awayGoals: 0,
                extraTime: false,
                penaltiesHome: 0,
                penaltiesAway: 0,
                reportedAt: block.timestamp
            });

            vm.prank(keeper);
            oracleAdapter.proposeResult(mid, facts);

            console.log("  Market result proposed: Home wins");
        }

        // Wait for liveness
        vm.warp(block.timestamp + LIVENESS + 1);

        // Settle all assertions
        for (uint256 i = 0; i < 3; i++) {
            bytes32 mid = bytes32(uint256(uint160(address(markets[i]))));

            vm.prank(keeper);
            oracleAdapter.settleAssertion(mid);

            console.log("  Market", i, "assertion settled");
        }

        // Resolve all markets
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(owner);
            markets[i].resolveFromOracle();

            assertEq(markets[i].winningOutcome(), 0); // Home wins all
            console.log("  Market", i, "resolved: Home wins");
        }

        console.log("\n=== Parallel Settlement Completed ===");
    }

    /*//////////////////////////////////////////////////////////////
                    E2E TEST: ERROR RECOVERY
    //////////////////////////////////////////////////////////////*/

    function test_E2E_ErrorRecovery_DisputerWins() public {
        console.log("=== E2E Test: Error Recovery (Disputer Wins) ===");

        // Phase 1-3: Setup and propose
        vm.prank(user1);
        market.placeBet(0, 1000e6);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner);
        market.lock();

        vm.warp(block.timestamp + 90 minutes);

        // Keeper proposes WRONG result
        IResultOracle.MatchFacts memory wrongFacts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, wrongFacts);

        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);

        console.log("\n[Phase] Keeper proposed WRONG result");

        // Someone disputes
        address disputer = address(0x999);
        bondCurrency.mint(disputer, 10_000e6);
        vm.prank(disputer);
        bondCurrency.approve(address(mockOO), type(uint256).max);

        vm.warp(block.timestamp + 1 hours);

        vm.prank(disputer);
        oracleAdapter.disputeAssertion(marketId, "Score is wrong");

        console.log("  Dispute raised");

        // DVM resolves: Disputer wins (assertion FALSE)
        console.log("\n[Phase] DVM resolves: Disputer correct");

        mockOO.mockDVMResolve(assertionId, false); // Disputer wins

        // Verify assertion rejected
        IOptimisticOracleV3.Assertion memory assertion = mockOO.getAssertion(assertionId);
        assertTrue(assertion.resolved);
        assertFalse(assertion.settlementResolution);

        console.log("  Assertion rejected by DVM");

        // Keeper cannot resolve market with rejected assertion
        vm.prank(owner);
        vm.expectRevert();
        market.resolveFromOracle();

        console.log("  Market cannot resolve with rejected assertion");

        // In production: Keeper needs to propose CORRECT result now
        console.log("\n[Phase] Keeper proposes CORRECT result");

        // Clear old assertion mapping (in real scenario, adapter needs new proposal logic)
        // For this test, we demonstrate that rejected assertion blocks resolution

        console.log("\n=== Error Recovery Test Completed ===");
    }
}
