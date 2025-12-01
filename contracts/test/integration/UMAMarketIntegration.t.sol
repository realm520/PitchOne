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
 * @title UMAMarketIntegrationTest
 * @notice 集成测试：MarketBase + UMA Optimistic Oracle Adapter
 * @dev 测试完整的市场生命周期：创建 → 下注 → 锁盘 → 提议结果 → 结算 → 兑付
 */
contract UMAMarketIntegrationTest is Test {
    // Contracts
    WDL_Template public market;
    UMAOptimisticOracleAdapter public oracleAdapter;
    MockOptimisticOracleV3 public mockOO;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    MockERC20 public usdc;
    MockERC20 public bondCurrency;

    // Participants
    address public owner = address(0x1);
    address public keeper = address(0x2);
    address public user1 = address(0x3);
    address public user2 = address(0x4);
    address public disputer = address(0x5);

    // Constants
    uint256 constant BOND_AMOUNT = 1000e6;
    uint64 constant LIVENESS = 7200; // 2 hours
    bytes32 constant IDENTIFIER = bytes32("ASSERT_TRUTH");
    uint256 constant FEE_RATE = 0; // 0% - 避免需要 FeeRouter 和 ReferralRegistry 复杂配置

    bytes32 public marketId;

    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);
    event ResolvedWithOracle(uint256 indexed winningOutcome, bytes32 indexed resultHash, uint256 timestamp);

    function setUp() public {
        // Deploy infrastructure
        usdc = new MockERC20("Mock USDC", "USDC", 6);
        bondCurrency = new MockERC20("Bond Currency", "BOND", 6);
        mockOO = new MockOptimisticOracleV3();

        // Deploy FeeRouter with mock recipients
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: address(0x100),
            promoPool: address(0x200),
            insuranceFund: address(0x250),
            treasury: address(0x300)
        });
        feeRouter = new FeeRouter(recipients, address(0x400)); // Mock referral registry
        cpmm = new SimpleCPMM(100_000 * 10**6);

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
            "TEST_MATCH_001",
            "Team A",
            "Team B",
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

        // Market ID is the market address
        marketId = bytes32(uint256(uint160(address(market))));

        // Fund participants
        usdc.mint(user1, 10_000e6);
        usdc.mint(user2, 10_000e6);
        bondCurrency.mint(keeper, 10_000e6);
        bondCurrency.mint(disputer, 10_000e6);

        // Approve
        vm.prank(user1);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(user2);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(keeper);
        bondCurrency.approve(address(mockOO), type(uint256).max);

        vm.prank(disputer);
        bondCurrency.approve(address(mockOO), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                        HAPPY PATH: NO DISPUTE
    //////////////////////////////////////////////////////////////*/

    function test_FullLifecycle_NoDispute() public {
        console.log("=== Test: Full Market Lifecycle (No Dispute) ===");

        // Phase 1: Users place bets
        console.log("\n1. Users place bets");
        vm.prank(user1);
        uint256 shares1 = market.placeBet(0, 1000e6); // Bet on Home (outcome 0)
        assertGt(shares1, 0, "User1 should receive shares");

        vm.prank(user2);
        uint256 shares2 = market.placeBet(2, 1000e6); // Bet on Away (outcome 2)
        assertGt(shares2, 0, "User2 should receive shares");

        console.log("   User1 shares (Home):", shares1);
        console.log("   User2 shares (Away):", shares2);

        // Phase 2: Lock market
        console.log("\n2. Lock market");
        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner);
        market.lock();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked), "Market should be locked");

        // Phase 3: Keeper proposes result (Home wins: 2-1)
        console.log("\n3. Keeper proposes result: Home 2 - 1 Away");

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        // Verify assertion was created
        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);
        assertNotEq(assertionId, bytes32(0), "Assertion should be created");

        // Phase 4: Wait for liveness period
        console.log("\n4. Wait for liveness period (", LIVENESS, "seconds)");
        vm.warp(block.timestamp + LIVENESS + 1);

        // Phase 5: Settle assertion
        console.log("\n5. Settle assertion");
        oracleAdapter.settleAssertion(marketId);

        // Verify oracle result is finalized
        assertTrue(oracleAdapter.isFinalized(marketId), "Result should be finalized");

        // Phase 6: Resolve market from oracle
        console.log("\n6. Resolve market from oracle");
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit Resolved(0, block.timestamp); // Home wins (outcome 0)

        market.resolveFromOracle();

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved), "Market should be resolved");
        assertEq(market.winningOutcome(), 0, "Home should win (outcome 0)");

        // Phase 7: Winners redeem their shares
        console.log("\n7. Winners redeem shares");

        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        uint256 payout1 = market.redeem(0, shares1); // User1 wins
        assertGt(payout1, 0, "User1 should receive payout");

        uint256 user1BalanceAfter = usdc.balanceOf(user1);
        assertEq(user1BalanceAfter - user1BalanceBefore, payout1, "Balance should increase by payout");

        console.log("   User1 payout:", payout1 / 1e6, "USDC");

        // User2 loses (bet on Away) - losing shares become worthless, cannot redeem
        console.log("   User2 lost bet on Away (shares become worthless)");

        console.log("\n=== Test Completed Successfully ===");
    }

    /*//////////////////////////////////////////////////////////////
                        DISPUTE SCENARIO
    //////////////////////////////////////////////////////////////*/

    function test_FullLifecycle_WithDispute_ProposerWins() public {
        console.log("=== Test: Market Lifecycle with Dispute (Proposer Wins) ===");

        // Phase 1-2: Place bets and lock (same as above)
        vm.prank(user1);
        market.placeBet(0, 1000e6);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner);
        market.lock();

        // Phase 3: Keeper proposes result
        console.log("\n1. Keeper proposes result: Home 2 - 1 Away");

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);

        // Phase 4: Disputer challenges the result
        console.log("\n2. Disputer challenges result (within liveness period)");
        vm.warp(block.timestamp + 1 hours); // Still within liveness

        vm.prank(disputer);
        oracleAdapter.disputeAssertion(marketId, "Result is incorrect");

        // Verify dispute
        IOptimisticOracleV3.Assertion memory assertion = mockOO.getAssertion(assertionId);
        assertTrue(assertion.disputed, "Assertion should be disputed");

        // Phase 5: DVM resolves in favor of proposer (assertion is correct)
        console.log("\n3. DVM resolves: Proposer is correct");
        mockOO.mockDVMResolve(assertionId, true); // true = assertion is correct

        // Phase 6: Settle assertion
        console.log("\n4. Settle assertion after DVM resolution");
        assertTrue(oracleAdapter.canSettle(marketId) == false, "Should be auto-settled by DVM");

        // The assertion is already settled by DVM
        assertTrue(oracleAdapter.isFinalized(marketId), "Result should be finalized");

        // Phase 7: Resolve market
        console.log("\n5. Resolve market");
        vm.prank(owner);
        market.resolveFromOracle();

        assertEq(market.winningOutcome(), 0, "Home should win despite dispute");

        console.log("\n=== Test Completed: Dispute Resolved, Proposer Wins ===");
    }

    function test_FullLifecycle_WithDispute_DisputerWins() public {
        console.log("=== Test: Market Lifecycle with Dispute (Disputer Wins) ===");

        // Phase 1-3: Same setup
        vm.prank(user1);
        market.placeBet(0, 1000e6);

        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(owner);
        market.lock();

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        bytes32 assertionId = oracleAdapter.marketAssertions(marketId);

        // Phase 4: Dispute
        vm.warp(block.timestamp + 1 hours);
        vm.prank(disputer);
        oracleAdapter.disputeAssertion(marketId, "Result is wrong");

        // Phase 5: DVM resolves in favor of disputer (assertion is FALSE)
        console.log("\n1. DVM resolves: Disputer is correct, assertion is false");
        mockOO.mockDVMResolve(assertionId, false); // false = assertion is incorrect

        // Phase 6: Try to settle - should fail because assertion was rejected
        console.log("\n2. Attempt to settle rejected assertion");
        vm.expectRevert(); // Should revert because assertion was rejected
        oracleAdapter.settleAssertion(marketId);

        // In production, a new proposal would be needed with correct result
        console.log("\n=== Test Completed: Dispute Won, Assertion Rejected ===");
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function test_RevertIf_ResolveBeforeFinalized() public {
        // Propose result but don't wait for liveness
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(owner);
        market.lock();

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        // Try to resolve immediately (should fail - not finalized)
        vm.prank(owner);
        vm.expectRevert();
        market.resolveFromOracle();
    }

    function test_RevertIf_DisputeAfterLiveness() public {
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(owner);
        market.lock();

        vm.prank(keeper);
        oracleAdapter.proposeResult(marketId, facts);

        // Wait past liveness period
        vm.warp(block.timestamp + LIVENESS + 1);

        // Try to dispute (should fail - liveness expired)
        vm.prank(disputer);
        vm.expectRevert();
        oracleAdapter.disputeAssertion(marketId, "Too late");
    }

    function test_CannotProposeWithoutBondAllowance() public {
        // Revoke bond approval
        vm.prank(keeper);
        bondCurrency.approve(address(mockOO), 0);

        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });

        vm.prank(owner);
        market.lock();

        vm.prank(keeper);
        vm.expectRevert();
        oracleAdapter.proposeResult(marketId, facts);
    }
}
