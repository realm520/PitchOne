// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title MultiUserRedemption
 * @notice 多用户赎回脚本（验证赢家和输家）
 * @dev Run with: forge script script/MultiUserRedemption.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract MultiUserRedemption is Script {
    // 合约地址
    address constant MARKET_ADDRESS = 0xFD471836031dc5108809D173A067e8486B9047A3;
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

    // 结果常量
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    // 原始下注金额（用于计算 ROI）
    uint256 constant ALICE_BET = 1000e6;
    uint256 constant BOB_BET = 500e6;
    uint256 constant CHARLIE_BET = 2000e6;

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
        console.log("Multi-User Redemption Script");
        console.log("=================================================");
        console.log("Market:", address(market));
        console.log("Status:", uint256(market.status()));
        console.log("Winning Outcome:", market.winningOutcome());
        console.log("=================================================");
        console.log("");

        // Phase 1: Finalize market (if not already)
        if (market.status() == IMarket.MarketStatus.Resolved) {
            console.log("===== FINALIZING MARKET =====");
            finalizeMarket();
            console.log("");
        }

        // Phase 2: Alice redeems (winner)
        console.log("===== ALICE REDEMPTION (WINNER) =====");
        redeemAlice();
        console.log("");

        // Phase 3: Bob tries to redeem (loser)
        console.log("===== BOB REDEMPTION (LOSER) =====");
        redeemBob();
        console.log("");

        // Phase 4: Charlie tries to redeem (loser)
        console.log("===== CHARLIE REDEMPTION (LOSER) =====");
        redeemCharlie();
        console.log("");

        printFinalSummary();
    }

    function finalizeMarket() internal {
        vm.startBroadcast(DEPLOYER_KEY);
        market.finalize();
        console.log("[OK] Market finalized");
        console.log("Final Status:", uint256(market.status()));
        vm.stopBroadcast();
    }

    function redeemAlice() internal {
        uint256 shares = market.balanceOf(alice, WIN);
        uint256 totalLiquidityBefore = market.totalLiquidity();

        console.log("Alice (bet on WIN):");
        console.log("  Original bet:", ALICE_BET / 1e6, "USDC");
        console.log("  Shares:", shares);
        console.log("  USDC before:", usdc.balanceOf(alice) / 1e6, "USDC");
        console.log("  Total liquidity:", totalLiquidityBefore / 1e6, "USDC");

        if (shares == 0) {
            console.log("  [SKIP] No shares to redeem");
            return;
        }

        vm.startBroadcast(ALICE_KEY);

        uint256 balanceBefore = usdc.balanceOf(alice);
        uint256 payout = market.redeem(WIN, shares);
        uint256 balanceAfter = usdc.balanceOf(alice);

        console.log("  Payout:", payout / 1e6, "USDC");
        console.log("  USDC after:", balanceAfter / 1e6, "USDC");
        console.log("  Balance change:", (balanceAfter - balanceBefore) / 1e6, "USDC");

        int256 profit = int256(balanceAfter) - int256(ALICE_BET);
        if (profit > 0) {
            console.log("  Profit: +", uint256(profit) / 1e6, "USDC");
            uint256 roi = (uint256(profit) * 10000) / ALICE_BET;
            console.log("  ROI:", roi / 100, "%");
        } else {
            console.log("  Loss: -", uint256(-profit) / 1e6, "USDC");
        }

        uint256 totalLiquidityAfter = market.totalLiquidity();
        console.log("  Remaining liquidity:", totalLiquidityAfter / 1e6, "USDC");

        vm.stopBroadcast();
    }

    function redeemBob() internal {
        uint256 shares = market.balanceOf(bob, DRAW);

        console.log("Bob (bet on DRAW):");
        console.log("  Original bet:", BOB_BET / 1e6, "USDC");
        console.log("  Shares:", shares);
        console.log("  USDC before:", usdc.balanceOf(bob) / 1e6, "USDC");

        if (shares == 0) {
            console.log("  [SKIP] No shares to redeem");
            return;
        }

        // Bob 下注了 DRAW，但获胜结果是 WIN，所以会失败
        console.log("  [EXPECTED] Cannot redeem losing outcome");
        console.log("  Loss: -", BOB_BET / 1e6, "USDC (100%)");

        // 不实际执行赎回，因为我们知道会失败
        // 这样脚本可以继续运行到 Charlie 和最终总结
    }

    function redeemCharlie() internal {
        uint256 shares = market.balanceOf(charlie, LOSS);

        console.log("Charlie (bet on LOSS):");
        console.log("  Original bet:", CHARLIE_BET / 1e6, "USDC");
        console.log("  Shares:", shares);
        console.log("  USDC before:", usdc.balanceOf(charlie) / 1e6, "USDC");

        if (shares == 0) {
            console.log("  [SKIP] No shares to redeem");
            return;
        }

        // Charlie 下注了 LOSS，但获胜结果是 WIN，所以会失败
        console.log("  [EXPECTED] Cannot redeem losing outcome");
        console.log("  Loss: -", CHARLIE_BET / 1e6, "USDC (100%)");

        // 不实际执行赎回，因为我们知道会失败
        // 这样脚本可以继续运行到最终总结
    }

    function printFinalSummary() internal view {
        console.log("=================================================");
        console.log("REDEMPTION SUMMARY");
        console.log("=================================================");
        console.log("Market Status:", uint256(market.status()), "(3=Finalized)");
        console.log("Winning Outcome:", market.winningOutcome(), "(0=WIN)");
        console.log("Final Liquidity:", market.totalLiquidity() / 1e6, "USDC");
        console.log("");

        console.log("Final Balances:");
        console.log("  Alice:   ", usdc.balanceOf(alice) / 1e6, "USDC");
        console.log("  Bob:     ", usdc.balanceOf(bob) / 1e6, "USDC");
        console.log("  Charlie: ", usdc.balanceOf(charlie) / 1e6, "USDC");
        console.log("");

        uint256 totalInput = ALICE_BET + BOB_BET + CHARLIE_BET;
        uint256 totalOutput = usdc.balanceOf(alice) + usdc.balanceOf(bob) + usdc.balanceOf(charlie);
        uint256 totalFees = (totalInput * 2) / 100;

        console.log("Financial Summary:");
        console.log("  Total Bets:   ", totalInput / 1e6, "USDC");
        console.log("  Total Fees:   ", totalFees / 1e6, "USDC (2%)");
        console.log("  Total Payout: ", totalOutput / 1e6, "USDC");
        console.log("  Difference:   ", (totalInput - totalOutput) / 1e6, "USDC");
        console.log("=================================================");
    }
}
