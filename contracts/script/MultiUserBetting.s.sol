// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title MultiUserBetting
 * @notice 多用户下注脚本（Alice, Bob, Charlie）
 * @dev Run with: forge script script/MultiUserBetting.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract MultiUserBetting is Script {
    // 合约地址
    address constant MARKET_ADDRESS = 0xFD471836031dc5108809D173A067e8486B9047A3;  // 新部署的市场
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;

    WDL_Template public market;
    MockERC20 public usdc;

    // 账户私钥
    uint256 constant DEPLOYER_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant ALICE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant BOB_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    uint256 constant CHARLIE_KEY = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;

    // 账户地址
    address public deployer;
    address public alice;
    address public bob;
    address public charlie;

    // 下注金额
    uint256 constant ALICE_BET = 1000e6;    // 1,000 USDC
    uint256 constant BOB_BET = 500e6;       // 500 USDC
    uint256 constant CHARLIE_BET = 2000e6;  // 2,000 USDC

    // 结果常量
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    function setUp() public {
        market = WDL_Template(MARKET_ADDRESS);
        usdc = MockERC20(USDC_ADDRESS);

        deployer = vm.addr(DEPLOYER_KEY);
        alice = vm.addr(ALICE_KEY);
        bob = vm.addr(BOB_KEY);
        charlie = vm.addr(CHARLIE_KEY);
    }

    function run() public {
        console.log("=================================================");
        console.log("Multi-User Betting Script");
        console.log("=================================================");
        console.log("Market:   ", address(market));
        console.log("Match:    ", market.matchId());
        console.log("Deployer: ", deployer);
        console.log("Alice:    ", alice);
        console.log("Bob:      ", bob);
        console.log("Charlie:  ", charlie);
        console.log("=================================================");
        console.log("");

        // Phase 1: 铸造和分发 USDC
        console.log("===== PHASE 1: SETUP USERS =====");
        setupUsers();
        console.log("");

        // Phase 2: 多用户下注
        console.log("===== PHASE 2: MULTI-USER BETTING =====");
        placeBets();
        console.log("");

        printFinalSummary();
    }

    function setupUsers() internal {
        uint256 totalNeeded = ALICE_BET + BOB_BET + CHARLIE_BET;

        vm.startBroadcast(DEPLOYER_KEY);

        // 铸造 USDC 给部署者
        usdc.mint(deployer, totalNeeded);
        console.log("Minted", totalNeeded / 1e6, "USDC to deployer");
        console.log("Deployer balance:", usdc.balanceOf(deployer) / 1e6, "USDC");

        // 分发给 Alice
        usdc.transfer(alice, ALICE_BET);
        console.log("[OK] Transferred", ALICE_BET / 1e6, "USDC to Alice");
        console.log("    Alice balance:", usdc.balanceOf(alice) / 1e6, "USDC");

        // 分发给 Bob
        usdc.transfer(bob, BOB_BET);
        console.log("[OK] Transferred", BOB_BET / 1e6, "USDC to Bob");
        console.log("    Bob balance:", usdc.balanceOf(bob) / 1e6, "USDC");

        // 分发给 Charlie
        usdc.transfer(charlie, CHARLIE_BET);
        console.log("[OK] Transferred", CHARLIE_BET / 1e6, "USDC to Charlie");
        console.log("    Charlie balance:", usdc.balanceOf(charlie) / 1e6, "USDC");

        vm.stopBroadcast();
    }

    function placeBets() internal {
        // Alice 下注 WIN
        console.log("Alice bets", ALICE_BET / 1e6, "USDC on WIN...");
        vm.startBroadcast(ALICE_KEY);

        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        usdc.approve(address(market), ALICE_BET);
        uint256 aliceShares = market.placeBet(WIN, ALICE_BET);
        uint256 aliceBalanceAfter = usdc.balanceOf(alice);

        console.log("  Shares received:", aliceShares);
        console.log("  USDC spent:", (aliceBalanceBefore - aliceBalanceAfter) / 1e6, "USDC");
        console.log("  Remaining balance:", aliceBalanceAfter / 1e6, "USDC");

        vm.stopBroadcast();

        // Bob 下注 DRAW
        console.log("");
        console.log("Bob bets", BOB_BET / 1e6, "USDC on DRAW...");
        vm.startBroadcast(BOB_KEY);

        uint256 bobBalanceBefore = usdc.balanceOf(bob);
        usdc.approve(address(market), BOB_BET);
        uint256 bobShares = market.placeBet(DRAW, BOB_BET);
        uint256 bobBalanceAfter = usdc.balanceOf(bob);

        console.log("  Shares received:", bobShares);
        console.log("  USDC spent:", (bobBalanceBefore - bobBalanceAfter) / 1e6, "USDC");
        console.log("  Remaining balance:", bobBalanceAfter / 1e6, "USDC");

        vm.stopBroadcast();

        // Charlie 下注 LOSS
        console.log("");
        console.log("Charlie bets", CHARLIE_BET / 1e6, "USDC on LOSS...");
        vm.startBroadcast(CHARLIE_KEY);

        uint256 charlieBalanceBefore = usdc.balanceOf(charlie);
        usdc.approve(address(market), CHARLIE_BET);
        uint256 charlieShares = market.placeBet(LOSS, CHARLIE_BET);
        uint256 charlieBalanceAfter = usdc.balanceOf(charlie);

        console.log("  Shares received:", charlieShares);
        console.log("  USDC spent:", (charlieBalanceBefore - charlieBalanceAfter) / 1e6, "USDC");
        console.log("  Remaining balance:", charlieBalanceAfter / 1e6, "USDC");

        vm.stopBroadcast();
    }

    function printFinalSummary() internal view {
        console.log("=================================================");
        console.log("BETTING PHASE SUMMARY");
        console.log("=================================================");

        uint256 totalLiquidity = market.totalLiquidity();
        console.log("Total Liquidity:", totalLiquidity / 1e6, "USDC");
        console.log("");

        console.log("Outcome Liquidity:");
        console.log("  WIN:  ", market.outcomeLiquidity(WIN) / 1e6, "USDC");
        console.log("  DRAW: ", market.outcomeLiquidity(DRAW) / 1e6, "USDC");
        console.log("  LOSS: ", market.outcomeLiquidity(LOSS) / 1e6, "USDC");
        console.log("");

        console.log("User Positions:");
        console.log("  Alice (WIN):  ", market.balanceOf(alice, WIN), "shares");
        console.log("  Bob (DRAW):   ", market.balanceOf(bob, DRAW), "shares");
        console.log("  Charlie (LOSS):", market.balanceOf(charlie, LOSS), "shares");
        console.log("");

        console.log("Total Supply per Outcome:");
        console.log("  WIN:  ", market.totalSupply(WIN), "shares");
        console.log("  DRAW: ", market.totalSupply(DRAW), "shares");
        console.log("  LOSS: ", market.totalSupply(LOSS), "shares");
        console.log("=================================================");
        console.log("");

        console.log("Next steps:");
        console.log("1. Run verification queries (cast call commands)");
        console.log("2. Wait until kickoff time:", market.kickoffTime());
        console.log("3. Lock market: cast send", address(market), "autoLock()");
        console.log("4. Resolve market: cast send", address(market), "resolve(uint256) 0");
        console.log("=================================================");
    }
}
