// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/FeeRouter.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DemoFlow
 * @notice Demonstration script showing complete market lifecycle
 * @dev Run with: forge script script/DemoFlow.s.sol:DemoFlow --rpc-url $RPC_URL --broadcast -vvvv
 *
 * This script demonstrates:
 * 1. Market creation and initialization
 * 2. Multiple users placing bets
 * 3. Price changes based on betting activity
 * 4. Market locking
 * 5. Result resolution
 * 6. Winners redeeming payouts
 */
contract DemoFlow is Script {
    // Contracts
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    WDL_Template public market;

    // Actors
    address public deployer;
    address public treasury;
    address public keeper;
    address public alice;
    address public bob;
    address public charlie;

    // Private key (set in setUp)
    uint256 public deployerPrivateKey;

    // Market parameters
    string public matchId = "EPL_2025_MUN_vs_LIV";
    string public homeTeam = "Manchester United";
    string public awayTeam = "Liverpool";
    uint256 public kickoffTime;

    // Bet amounts
    uint256 constant INITIAL_LIQUIDITY = 10_000e6; // 10,000 USDC
    uint256 constant ALICE_BET = 1000e6;          // 1,000 USDC
    uint256 constant BOB_BET = 500e6;             // 500 USDC
    uint256 constant CHARLIE_BET = 2000e6;        // 2,000 USDC

    // Outcome constants
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    function setUp() public {
        // Get private key from environment or use Anvil default
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
        } catch {
            // Anvil default private key (account #0)
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        deployer = vm.addr(deployerPrivateKey);

        // Create test accounts
        treasury = makeAddr("treasury");
        keeper = makeAddr("keeper");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Set kickoff time to 2 hours from now
        kickoffTime = block.timestamp + 2 hours;
    }

    function run() public {
        // Use the private key set in setUp()
        // (no need to read environment again)

        console.log("=================================================");
        console.log("PitchOne Demo Flow - Complete Market Lifecycle");
        console.log("=================================================");
        console.log("Block timestamp:", block.timestamp);
        console.log("Kickoff time:   ", kickoffTime);
        console.log("=================================================\n");

        vm.startBroadcast(deployerPrivateKey);

        // Phase 1: Deploy and Initialize
        console.log("===== PHASE 1: DEPLOYMENT =====");
        deployContracts();
        console.log("");

        // Phase 2: Users Place Bets
        console.log("===== PHASE 2: BETTING PHASE =====");
        setupUsersAndBet();
        console.log("");

        // Phase 3: Check Prices
        console.log("===== PHASE 3: PRICE CHECK =====");
        checkPrices();
        console.log("");

        // Phase 4: Lock Market
        console.log("===== PHASE 4: LOCK MARKET =====");
        lockMarket();
        console.log("");

        // Phase 5: Resolve Market (Home team wins)
        console.log("===== PHASE 5: RESOLVE MARKET =====");
        resolveMarket();
        console.log("");

        // Phase 6: Finalize Market
        console.log("===== PHASE 6: FINALIZE MARKET =====");
        finalizeMarket();
        console.log("");

        // Phase 7: Winners Redeem
        console.log("===== PHASE 7: REDEMPTION =====");
        redeemWinnings();
        console.log("");

        vm.stopBroadcast();

        printFinalSummary();
    }

    function deployContracts() internal {
        console.log("[1/4] Deploying Mock USDC...");
        usdc = new MockERC20("USD Coin", "USDC", 6);
        console.log("  USDC:", address(usdc));

        console.log("[2/4] Deploying FeeRouter...");
        feeRouter = new FeeRouter(treasury);
        console.log("  FeeRouter:", address(feeRouter));

        console.log("[3/4] Deploying SimpleCPMM...");
        cpmm = new SimpleCPMM();
        console.log("  CPMM:", address(cpmm));

        console.log("[4/4] Deploying WDL Market...");
        market = new WDL_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            address(usdc),         // settlement token
            address(feeRouter),    // fee recipient
            200,                   // 2% fee rate
            2 hours,               // dispute period
            address(cpmm),         // pricing engine
            ""                     // uri
        );
        console.log("  Market:", address(market));

        // Mint USDC to deployer for distribution to users
        usdc.mint(deployer, ALICE_BET + BOB_BET + CHARLIE_BET);
        console.log("Minted USDC to deployer for distribution");
        console.log("Market is ready for betting (liquidity will be built from bets)");
    }

    function setupUsersAndBet() internal {
        // Alice bets on HOME WIN (outcome 0)
        console.log("Alice bets 1,000 USDC on HOME WIN...");
        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);

        // Transfer USDC from deployer to alice (since we're using deployer's key)
        usdc.transfer(alice, ALICE_BET);

        // Simulate alice betting
        vm.stopBroadcast();
        uint256 aliceKey = uint256(keccak256(abi.encodePacked("alice")));
        vm.startBroadcast(aliceKey);

        usdc.approve(address(market), ALICE_BET);
        uint256 aliceShares = market.placeBet(WIN, ALICE_BET);
        console.log("  Alice received", aliceShares, "shares");

        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);

        // Bob bets on DRAW (outcome 1)
        console.log("Bob bets 500 USDC on DRAW...");
        usdc.transfer(bob, BOB_BET);

        vm.stopBroadcast();
        uint256 bobKey = uint256(keccak256(abi.encodePacked("bob")));
        vm.startBroadcast(bobKey);

        usdc.approve(address(market), BOB_BET);
        uint256 bobShares = market.placeBet(DRAW, BOB_BET);
        console.log("  Bob received", bobShares, "shares");

        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);

        // Charlie bets on AWAY LOSS (outcome 2)
        console.log("Charlie bets 2,000 USDC on AWAY LOSS...");
        usdc.transfer(charlie, CHARLIE_BET);

        vm.stopBroadcast();
        uint256 charlieKey = uint256(keccak256(abi.encodePacked("charlie")));
        vm.startBroadcast(charlieKey);

        usdc.approve(address(market), CHARLIE_BET);
        uint256 charlieShares = market.placeBet(LOSS, CHARLIE_BET);
        console.log("  Charlie received", charlieShares, "shares");

        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);
    }

    function checkPrices() internal view {
        uint256 winPrice = market.getCurrentPrice(WIN);
        uint256 drawPrice = market.getCurrentPrice(DRAW);
        uint256 lossPrice = market.getCurrentPrice(LOSS);

        console.log("Current market prices (in basis points):");
        console.log("  WIN:  ", winPrice);
        console.log("  DRAW: ", drawPrice);
        console.log("  LOSS: ", lossPrice);
        console.log("  Sum:  ", winPrice + drawPrice + lossPrice);
    }

    function lockMarket() internal {
        console.log("Fast-forwarding to kickoff time...");
        // Stop broadcast to allow vm.warp to work
        vm.stopBroadcast();
        vm.warp(kickoffTime);
        vm.startBroadcast(deployerPrivateKey);

        console.log("Keeper/Anyone calls autoLock()...");
        // Use autoLock() instead of lock() - this is the proper way
        // autoLock() can be called by anyone (including Keeper) when time condition is met
        market.autoLock();
        console.log("Market is now LOCKED - no more bets allowed");
    }

    function resolveMarket() internal {
        console.log("Match has ended. Final score: MUN 2-1 LIV (HOME WIN)");
        console.log("Proposing result: WIN (outcome 0)...");
        // No need to change broadcaster - deployer is the owner
        market.resolve(WIN);
        console.log("Result proposed: HOME WIN");
        console.log("Market is now RESOLVED");
    }

    function finalizeMarket() internal {
        console.log("Fast-forwarding past dispute period...");
        // Stop broadcast to allow vm.warp to work
        vm.stopBroadcast();
        vm.warp(block.timestamp + 2 hours + 1);
        vm.startBroadcast(deployerPrivateKey);

        console.log("Finalizing market...");
        market.finalize();
        console.log("Market is now FINALIZED");
    }

    function redeemWinnings() internal {
        console.log("Winners redeeming their payouts...");

        // Alice wins (she bet on WIN)
        uint256 aliceBalance = market.balanceOf(alice, WIN);
        console.log("\nAlice (Winner):");
        console.log("  Shares:", aliceBalance);

        vm.stopBroadcast();
        uint256 aliceKey = uint256(keccak256(abi.encodePacked("alice")));
        vm.startBroadcast(aliceKey);

        uint256 alicePayout = market.redeem(WIN, aliceBalance);
        console.log("  Payout:", alicePayout / 1e6);
        int256 aliceProfit = int256(alicePayout) - int256(ALICE_BET);
        console.log("  Profit (raw):", aliceProfit);

        vm.stopBroadcast();
        vm.startBroadcast(deployerPrivateKey);

        // Bob loses (he bet on DRAW)
        uint256 bobBalance = market.balanceOf(bob, DRAW);
        console.log("\nBob (Loser):");
        console.log("  Shares:", bobBalance);
        console.log("  Cannot redeem - bet on wrong outcome");

        // Charlie loses (he bet on LOSS)
        uint256 charlieBalance = market.balanceOf(charlie, LOSS);
        console.log("\nCharlie (Loser):");
        console.log("  Shares:", charlieBalance);
        console.log("  Cannot redeem - bet on wrong outcome");
    }

    function printFinalSummary() internal view {
        console.log("=================================================");
        console.log("FINAL SUMMARY");
        console.log("=================================================");
        console.log("Market:", address(market));
        console.log("Match:", matchId);
        console.log("Result: HOME WIN (", homeTeam, ")");
        console.log("=================================================");
        console.log("Total bets placed: ", (ALICE_BET + BOB_BET + CHARLIE_BET) / 1e6, "USDC");
        console.log("=================================================");
        console.log("Winners: Alice (bet on WIN)");
        console.log("Losers:  Bob (bet on DRAW), Charlie (bet on LOSS)");
        console.log("=================================================");
        console.log("\nDemo completed successfully!");
        console.log("Market lifecycle: Create -> Bet -> Lock -> Resolve -> Finalize -> Redeem");
        console.log("=================================================");
    }
}
