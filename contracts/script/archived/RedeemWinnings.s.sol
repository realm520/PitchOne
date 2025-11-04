// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title RedeemWinnings
 * @notice 赎回获胜头寸
 * @dev Run with: forge script script/RedeemWinnings.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract RedeemWinnings is Script {
    address constant MARKET_ADDRESS = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;

    WDL_Template public market;
    MockERC20 public usdc;

    uint256 public deployerPrivateKey;
    address public deployer;

    function setUp() public {
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        deployer = vm.addr(deployerPrivateKey);
        market = WDL_Template(MARKET_ADDRESS);
        usdc = MockERC20(USDC_ADDRESS);
    }

    function run() public {
        console.log("=== Redeem Winnings ===");
        console.log("Market:", address(market));
        console.log("Deployer:", deployer);
        console.log("Status:", uint256(market.status()));
        console.log("Winning Outcome:", market.winningOutcome());

        uint256 winningOutcome = market.winningOutcome();
        uint256 shares = market.balanceOf(deployer, winningOutcome);

        console.log("\nBefore Redemption:");
        console.log("  Shares:", shares);
        console.log("  USDC Balance:", usdc.balanceOf(deployer) / 1e6, "USDC");
        console.log("  Total Liquidity:", market.totalLiquidity() / 1e6, "USDC");

        if (shares == 0) {
            console.log("ERROR: No winning shares to redeem");
            return;
        }

        vm.startBroadcast(deployerPrivateKey);

        uint256 balanceBefore = usdc.balanceOf(deployer);
        uint256 payout = market.redeem(winningOutcome, shares);
        uint256 balanceAfter = usdc.balanceOf(deployer);

        console.log("\nAfter Redemption:");
        console.log("  Payout:", payout / 1e6, "USDC");
        console.log("  USDC Balance:", balanceAfter / 1e6, "USDC");
        console.log("  Balance Change:", (balanceAfter - balanceBefore) / 1e6, "USDC");
        console.log("  Remaining Liquidity:", market.totalLiquidity() / 1e6, "USDC");

        vm.stopBroadcast();

        console.log("\n[OK] Redemption complete!");
    }
}
