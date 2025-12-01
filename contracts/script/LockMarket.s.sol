// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IMarket} from "../src/interfaces/IMarket.sol";

contract LockMarket is Script {
    function run() external {
        address marketAddress = vm.envOr("MARKET_ADDRESS", address(0xEa26F3615fd3A84eB5dD24a00E7B4bEc06D63206));
        
        vm.startBroadcast();
        
        IMarket market = IMarket(marketAddress);
        
        console.log("Locking market:", marketAddress);
        market.lock();
        console.log("Market locked successfully");
        
        vm.stopBroadcast();
    }
}
