// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/FeeRouter.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title TestMarketLifecycle
 * @notice 测试已部署合约的完整市场生命周期
 * @dev Run with: forge script script/TestMarketLifecycle.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract TestMarketLifecycle is Script {
    // 已部署的合约地址
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;
    address constant FEE_ROUTER_ADDRESS = 0x4c5859f0F772848b2D91F1D83E2Fe57935348029;
    address constant CPMM_ADDRESS = 0x1291Be112d480055DaFd8a610b7d1e203891C274;
    address constant WDL_MARKET_ADDRESS = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;

    MockERC20 public usdc;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    WDL_Template public market;

    // 账户
    uint256 public deployerPrivateKey;
    address public deployer;

    // 三个用户的私钥（从 Anvil 的账户 #1, #2, #3）
    uint256 constant ALICE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant BOB_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    uint256 constant CHARLIE_KEY = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    address public alice;
    address public bob;
    address public charlie;

    // 下注金额
    uint256 constant ALICE_BET = 1000e6;   // 1,000 USDC
    uint256 constant BOB_BET = 500e6;      // 500 USDC
    uint256 constant CHARLIE_BET = 2000e6; // 2,000 USDC

    // 结果常量
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    function setUp() public {
        // 部署者私钥（Anvil 账户 #0）
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        deployer = vm.addr(deployerPrivateKey);

        // 用户地址
        alice = vm.addr(ALICE_KEY);
        bob = vm.addr(BOB_KEY);
        charlie = vm.addr(CHARLIE_KEY);

        // 连接已部署的合约
        usdc = MockERC20(USDC_ADDRESS);
        feeRouter = FeeRouter(payable(FEE_ROUTER_ADDRESS));
        cpmm = SimpleCPMM(CPMM_ADDRESS);
        market = WDL_Template(WDL_MARKET_ADDRESS);
    }

    function run() public {
        console.log("=================================================");
        console.log("Complete Market Lifecycle Test");
        console.log("=================================================");
        console.log("Market:", address(market));
        console.log("Match:", market.matchId());
        console.log("Current Time:", block.timestamp);
        console.log("Kickoff Time:", market.kickoffTime());
        console.log("=================================================\n");

        // Phase 1: 准备用户资金
        console.log("===== PHASE 1: SETUP USERS =====");
        setupUsers();
        console.log("");

        // Phase 2: 多用户下注
        console.log("===== PHASE 2: MULTI-USER BETTING =====");
        placeBets();
        console.log("");

        // Phase 3: 检查价格和流动性
        console.log("===== PHASE 3: CHECK MARKET STATE =====");
        checkMarketState();
        console.log("");

        // Phase 4: 锁盘
        console.log("===== PHASE 4: LOCK MARKET =====");
        lockMarket();
        console.log("");

        // Phase 5: 结算
        console.log("===== PHASE 5: RESOLVE MARKET =====");
        resolveMarket();
        console.log("");

        // Phase 6: 终结
        console.log("===== PHASE 6: FINALIZE MARKET =====");
        finalizeMarket();
        console.log("");

        // Phase 7: 赎回
        console.log("===== PHASE 7: REDEMPTION =====");
        redeemWinnings();
        console.log("");

        printFinalSummary();
    }

    function setupUsers() internal {
        vm.startBroadcast(deployerPrivateKey);

        // 铸造 USDC 给部署者
        usdc.mint(deployer, ALICE_BET + BOB_BET + CHARLIE_BET);
        console.log("Minted", (ALICE_BET + BOB_BET + CHARLIE_BET) / 1e6, "USDC to deployer");

        // 分发给用户
        usdc.transfer(alice, ALICE_BET);
        console.log("Transferred", ALICE_BET / 1e6, "USDC to Alice");

        usdc.transfer(bob, BOB_BET);
        console.log("Transferred", BOB_BET / 1e6, "USDC to Bob");

        usdc.transfer(charlie, CHARLIE_BET);
        console.log("Transferred", CHARLIE_BET / 1e6, "USDC to Charlie");

        vm.stopBroadcast();
    }

    function placeBets() internal {
        // Alice 下注 WIN
        console.log("Alice bets", ALICE_BET / 1e6, "USDC on WIN...");
        vm.startBroadcast(ALICE_KEY);
        usdc.approve(address(market), ALICE_BET);
        uint256 aliceShares = market.placeBet(WIN, ALICE_BET);
        console.log("  Shares received:", aliceShares);
        vm.stopBroadcast();

        // Bob 下注 DRAW
        console.log("Bob bets", BOB_BET / 1e6, "USDC on DRAW...");
        vm.startBroadcast(BOB_KEY);
        usdc.approve(address(market), BOB_BET);
        uint256 bobShares = market.placeBet(DRAW, BOB_BET);
        console.log("  Shares received:", bobShares);
        vm.stopBroadcast();

        // Charlie 下注 LOSS
        console.log("Charlie bets", CHARLIE_BET / 1e6, "USDC on LOSS...");
        vm.startBroadcast(CHARLIE_KEY);
        usdc.approve(address(market), CHARLIE_BET);
        uint256 charlieShares = market.placeBet(LOSS, CHARLIE_BET);
        console.log("  Shares received:", charlieShares);
        vm.stopBroadcast();
    }

    function checkMarketState() internal view {
        uint256 totalLiq = market.totalLiquidity();
        console.log("Total Liquidity:", totalLiq / 1e6, "USDC");

        console.log("\nOutcome Liquidity:");
        console.log("  WIN:  ", market.outcomeLiquidity(WIN) / 1e6, "USDC");
        console.log("  DRAW: ", market.outcomeLiquidity(DRAW) / 1e6, "USDC");
        console.log("  LOSS: ", market.outcomeLiquidity(LOSS) / 1e6, "USDC");

        console.log("\nUser Positions:");
        console.log("  Alice (WIN):  ", market.balanceOf(alice, WIN));
        console.log("  Bob (DRAW):   ", market.balanceOf(bob, DRAW));
        console.log("  Charlie (LOSS):", market.balanceOf(charlie, LOSS));

        console.log("\nTotal Supply per Outcome:");
        console.log("  WIN:  ", market.totalSupply(WIN));
        console.log("  DRAW: ", market.totalSupply(DRAW));
        console.log("  LOSS: ", market.totalSupply(LOSS));
    }

    function lockMarket() internal {
        console.log("Fast-forwarding to kickoff time...");
        uint256 kickoff = market.kickoffTime();
        vm.warp(kickoff);
        console.log("Current time is now:", block.timestamp);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Calling autoLock()...");
        market.autoLock();
        console.log("Market Status:", uint256(market.status()), "(1=Locked)");
        vm.stopBroadcast();
    }

    function resolveMarket() internal {
        console.log("Match ended. Result: HOME WIN (Man United wins)");

        vm.startBroadcast(deployerPrivateKey);
        console.log("Calling resolve(WIN)...");
        market.resolve(WIN);
        console.log("Market Status:", uint256(market.status()), "(2=Resolved)");
        console.log("Winning Outcome:", market.winningOutcome());
        vm.stopBroadcast();
    }

    function finalizeMarket() internal {
        console.log("Fast-forwarding past dispute period (2 hours)...");

        // 获取锁盘时间戳
        uint256 lockTime = market.lockTimestamp();
        uint256 disputePeriod = market.disputePeriod();
        uint256 finalizeTime = lockTime + disputePeriod + 1;

        console.log("Lock Time:", lockTime);
        console.log("Dispute Period:", disputePeriod / 3600, "hours");
        console.log("Required Time:", finalizeTime);

        vm.warp(finalizeTime);
        console.log("Current time:", block.timestamp);

        vm.startBroadcast(deployerPrivateKey);
        console.log("Calling finalize()...");
        market.finalize();
        console.log("Market Status:", uint256(market.status()), "(3=Finalized)");
        vm.stopBroadcast();
    }

    function redeemWinnings() internal {
        uint256 totalLiquidityBefore = market.totalLiquidity();
        console.log("Total Liquidity before redemption:", totalLiquidityBefore / 1e6, "USDC");

        // Alice 是赢家（下注 WIN）
        uint256 aliceShares = market.balanceOf(alice, WIN);
        console.log("\nAlice (WINNER - bet on WIN):");
        console.log("  Shares:", aliceShares);
        console.log("  Original bet:", ALICE_BET / 1e6, "USDC");

        vm.startBroadcast(ALICE_KEY);
        uint256 alicePayout = market.redeem(WIN, aliceShares);
        console.log("  Payout:", alicePayout / 1e6, "USDC");

        int256 aliceProfit = int256(alicePayout) - int256(ALICE_BET);
        if (aliceProfit > 0) {
            console.log("  Profit: +", uint256(aliceProfit) / 1e6, "USDC");
        } else {
            console.log("  Loss: -", uint256(-aliceProfit) / 1e6, "USDC");
        }

        uint256 aliceROI = (alicePayout * 10000) / ALICE_BET;
        console.log("  ROI:", aliceROI / 100, "%");
        vm.stopBroadcast();

        // Bob 和 Charlie 是输家
        console.log("\nBob (LOSER - bet on DRAW):");
        console.log("  Shares:", market.balanceOf(bob, DRAW));
        console.log("  Cannot redeem (wrong outcome)");

        console.log("\nCharlie (LOSER - bet on LOSS):");
        console.log("  Shares:", market.balanceOf(charlie, LOSS));
        console.log("  Cannot redeem (wrong outcome)");

        uint256 totalLiquidityAfter = market.totalLiquidity();
        console.log("\nTotal Liquidity after redemption:", totalLiquidityAfter / 1e6, "USDC");
        console.log("Liquidity distributed:", (totalLiquidityBefore - totalLiquidityAfter) / 1e6, "USDC");
    }

    function printFinalSummary() internal view {
        console.log("=================================================");
        console.log("LIFECYCLE TEST SUMMARY");
        console.log("=================================================");
        console.log("Match:", market.matchId());
        console.log("Teams:", market.homeTeam(), "vs", market.awayTeam());
        console.log("Result: HOME WIN");
        console.log("=================================================");
        console.log("Total Bets: ", (ALICE_BET + BOB_BET + CHARLIE_BET) / 1e6, "USDC");
        console.log("Fee (2%):   ", ((ALICE_BET + BOB_BET + CHARLIE_BET) * 2 / 100) / 1e6, "USDC");
        console.log("=================================================");
        console.log("Participants:");
        console.log("  Alice:   Bet", ALICE_BET / 1e6, "USDC on WIN   -> WON");
        console.log("  Bob:     Bet", BOB_BET / 1e6, "USDC on DRAW  -> LOST");
        console.log("  Charlie: Bet", CHARLIE_BET / 1e6, "USDC on LOSS  -> LOST");
        console.log("=================================================");
        console.log("[OK] All lifecycle phases completed successfully!");
        console.log("Create -> Bet -> Lock -> Resolve -> Finalize -> Redeem");
        console.log("=================================================");
    }
}
