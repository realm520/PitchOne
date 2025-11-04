// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title FinalizeMarket
 * @notice 终结市场（在争议期结束后执行）
 * @dev Run with: forge script script/FinalizeMarket.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract FinalizeMarket is Script {
    address constant MARKET_ADDRESS = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;
    WDL_Template public market;
    uint256 public deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        market = WDL_Template(MARKET_ADDRESS);
    }

    function run() public {
        console.log("=== Finalize Market ===");
        console.log("Market:", address(market));
        console.log("Current Status:", uint256(market.status()));

        uint256 lockTime = market.lockTimestamp();
        uint256 disputePeriod = market.disputePeriod();
        uint256 requiredTime = lockTime + disputePeriod;

        console.log("Lock Time:", lockTime);
        console.log("Dispute Period:", disputePeriod / 3600, "hours");
        console.log("Required Time:", requiredTime);
        console.log("Current Time:", block.timestamp);

        if (block.timestamp < requiredTime) {
            console.log("ERROR: Dispute period not ended yet");
            console.log("Need to wait:", requiredTime - block.timestamp, "seconds");
            return;
        }

        vm.startBroadcast(deployerPrivateKey);
        market.finalize();
        console.log("[OK] Market finalized");
        console.log("Final Status:", uint256(market.status()));
        vm.stopBroadcast();
    }
}
