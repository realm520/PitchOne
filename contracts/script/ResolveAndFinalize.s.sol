// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/Market_V3.sol";

contract ResolveAndFinalize is Script {
    // 刚创建的市场地址
    address constant MARKET1 = 0xfd655BEB8852b7CBF1654D11C37ff6fE3FdBc28B;
    address constant MARKET2 = 0xa54F7cE47e5ebDd6C1c536d040F3CEdBd2DE371B;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        Market_V3 market1 = Market_V3(MARKET1);
        Market_V3 market2 = Market_V3(MARKET2);

        // === Market 1: 曼联 vs 利物浦 ===
        // 下注的是 outcome 0 (主队胜)
        // 设置比分 2-1 让主队获胜
        console.log("=== Market 1: MAN UTD vs LIVERPOOL ===");
        console.log("Current status:", uint256(market1.status()));

        // 1. 锁定市场
        if (market1.status() == IMarket_V3.MarketStatus.Open) {
            console.log("Locking Market 1...");
            market1.lock();
            console.log("Market 1 locked");
        }

        // 2. 结算市场 - 比分 2:1 (主队胜)
        // rawResult 格式：homeScore, awayScore (各占 1 byte)
        bytes memory result1 = abi.encode(uint8(2), uint8(1));
        console.log("Resolving Market 1 with score 2-1 (Home Win)...");
        market1.resolve(result1);
        console.log("Market 1 resolved");

        // 3. 终结市场
        console.log("Finalizing Market 1...");
        market1.finalize(10000); // 100% scale
        console.log("Market 1 finalized");

        // === Market 2: 切尔西 vs 阿森纳 ===
        // 下注的是 outcome 1 (平局)
        // 设置比分 1-1 让平局获胜
        console.log("\n=== Market 2: CHELSEA vs ARSENAL ===");
        console.log("Current status:", uint256(market2.status()));

        // 1. 锁定市场
        if (market2.status() == IMarket_V3.MarketStatus.Open) {
            console.log("Locking Market 2...");
            market2.lock();
            console.log("Market 2 locked");
        }

        // 2. 结算市场 - 比分 1:1 (平局)
        bytes memory result2 = abi.encode(uint8(1), uint8(1));
        console.log("Resolving Market 2 with score 1-1 (Draw)...");
        market2.resolve(result2);
        console.log("Market 2 resolved");

        // 3. 终结市场
        console.log("Finalizing Market 2...");
        market2.finalize(10000); // 100% scale
        console.log("Market 2 finalized");

        vm.stopBroadcast();

        console.log("\n=== Summary ===");
        console.log("Market 1 (MAN UTD vs LIVERPOOL): Score 2-1, Home Win (Outcome 0)");
        console.log("Market 2 (CHELSEA vs ARSENAL): Score 1-1, Draw (Outcome 1)");
        console.log("Both bets should be winning!");
    }
}
