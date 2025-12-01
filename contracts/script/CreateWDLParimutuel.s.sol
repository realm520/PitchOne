// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";

/**
 * @title CreateWDLParimutuel
 * @notice 创建 Parimutuel (奖池) 模式的 WDL 胜平负市场
 * @dev virtualReservePerSide = 0 表示 Parimutuel 模式
 */
contract CreateWDLParimutuel is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Create WDL Parimutuel Markets");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("\n");

        // 从 localhost.json 读取部署地址
        address factoryAddr = 0x08677Af0A7F54fE2a190bb1F75DE682fe596317e;
        address usdcAddr = 0x6858dF5365ffCbe31b5FE68D9E6ebB81321F7F86;
        address vaultAddr = 0x02121128f1Ed0AdA5Df3a87f42752fcE4Ad63e59;
        address parimutuelAddr = 0x897945A56464616a525C9e5F11a8D400a72a8f3A;
        address feeRouterAddr = 0x1E53bea57Dd5dDa7bFf1a1180a2f64a5c9e222f5;
        bytes32 wdlTemplateId = 0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc;

        MarketFactory_v2 factory = MarketFactory_v2(factoryAddr);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Creating 3 WDL Parimutuel Markets...\n");

        // 创建 3 个 Parimutuel WDL 市场
        string[3] memory matchIds = ["WDL_PM_MUN_vs_MCI", "WDL_PM_ARS_vs_CHE", "WDL_PM_LIV_vs_TOT"];
        string[3] memory homeTeams = ["Manchester United", "Arsenal", "Liverpool"];
        string[3] memory awayTeams = ["Manchester City", "Chelsea", "Tottenham"];

        for (uint256 i = 0; i < 3; i++) {
            // 准备初始化数据 - 注意 virtualReservePerSide = 0 表示 Parimutuel 模式
            bytes memory initData = abi.encodeWithSelector(
                WDL_Template_V2.initialize.selector,
                matchIds[i],                        // matchId
                homeTeams[i],                       // homeTeam
                awayTeams[i],                       // awayTeam
                block.timestamp + 7 days,           // kickoffTime
                usdcAddr,                           // settlementToken
                feeRouterAddr,                      // feeRecipient
                200,                                // feeRate (2%)
                2 hours,                            // disputePeriod
                parimutuelAddr,                     // pricingEngine - Parimutuel 定价
                vaultAddr,                          // vault
                "",                                 // uri
                0                                   // virtualReservePerSide = 0 = Parimutuel 模式
            );

            // 通过 Factory 创建市场
            address market = factory.createMarket(wdlTemplateId, initData);

            console.log("Market", i + 1, "created:", market);
            console.log("  Match:", matchIds[i]);
            console.log("  Type: WDL (Win/Draw/Loss)");
            console.log("  Pricing: Parimutuel (Pool Mode)");
            console.log("  Teams:", homeTeams[i], "vs", awayTeams[i]);
            console.log("");
        }

        vm.stopBroadcast();

        console.log("========================================");
        console.log("  All 3 WDL Parimutuel Markets Created!");
        console.log("========================================");
        console.log("\nPricing Model: Parimutuel (Pool)");
        console.log("- All bets go into a shared pool");
        console.log("- Winners split the pool proportionally");
        console.log("- No CPMM / virtual reserves");
        console.log("\nNext steps:");
        console.log("1. Reset Subgraph: cd subgraph && ./reset-subgraph.sh");
        console.log("2. Verify in frontend\n");
    }
}
