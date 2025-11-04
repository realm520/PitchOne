// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title TestLiquidity
 * @notice Test liquidity management (add/remove)
 */
contract TestLiquidity is Script {
    address constant USDC = 0x2a810409872AfC346F9B5b26571Fd6eC42EA4849;
    address constant WDL_MARKET = 0x32EEce76C2C2e8758584A83Ee2F522D4788feA0f;

    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("  Liquidity Management Test");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Market:", WDL_MARKET);
        console.log("");

        WDL_Template market = WDL_Template(WDL_MARKET);

        vm.startBroadcast(deployerPrivateKey);

        // Query initial state
        uint256 initialBalance = MockERC20(USDC).balanceOf(WDL_MARKET);
        console.log("Initial market liquidity:", initialBalance / 10 ** 6, "USDC");

        // Add more liquidity
        console.log("\n1. Adding 1000 USDC liquidity...");
        uint256[] memory weights = new uint256[](3);
        weights[0] = 333;
        weights[1] = 333;
        weights[2] = 334;
        uint256 addAmount = 1000 * 10 ** 6;

        MockERC20(USDC).mint(deployer, addAmount);
        MockERC20(USDC).approve(WDL_MARKET, addAmount);
        market.addLiquidity(addAmount, weights);

        uint256 afterAddBalance = MockERC20(USDC).balanceOf(WDL_MARKET);
        console.log("   After add:", afterAddBalance / 10 ** 6, "USDC");
        console.log("   Increase:", (afterAddBalance - initialBalance) / 10 ** 6, "USDC");

        // Query LP shares
        uint256 lpShares = market.balanceOf(deployer, type(uint256).max);
        console.log("   LP shares owned:", lpShares);

        vm.stopBroadcast();

        console.log("\n========================================");
        console.log("  Liquidity Test Complete!");
        console.log("========================================");
    }
}
