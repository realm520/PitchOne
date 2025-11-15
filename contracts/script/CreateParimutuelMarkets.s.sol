// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateParimutuelMarkets
 * @notice 创建 Parimutuel 模式的市场（零虚拟储备）
 * @dev 通过 Factory 创建 3 个 OddEven 市场，全部使用 Parimutuel 定价
 */
contract CreateParimutuelMarkets is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Create Parimutuel Markets");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("\n");

        // 读取已部署的合约地址
        address factoryAddr = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
        address usdcAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        address vaultAddr = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        address parimutuelAddr = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        address feeRouterAddr = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
        bytes32 oddEvenTemplateId = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

        MarketFactory_v2 factory = MarketFactory_v2(factoryAddr);
        MockERC20 usdc = MockERC20(usdcAddr);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Creating 3 Parimutuel Markets (OddEven type)...\n");

        // 创建 3 个 Parimutuel 市场
        string[3] memory matchIds = ["EPL_2024_MUN_vs_MCI_PM", "EPL_2024_ARS_vs_CHE_PM", "EPL_2024_LIV_vs_TOT_PM"];
        string[3] memory teamAs = ["Manchester United", "Arsenal", "Liverpool"];
        string[3] memory teamBs = ["Manchester City", "Chelsea", "Tottenham"];

        for (uint256 i = 0; i < 3; i++) {
            // 准备初始化数据
            bytes memory initData = abi.encodeWithSelector(
                OddEven_Template_V2.initialize.selector,
                matchIds[i],                        // matchId
                teamAs[i],                          // teamA
                teamBs[i],                          // teamB
                block.timestamp + 7 days,           // lockTime
                usdcAddr,                           // usdc
                feeRouterAddr,                      // feeRecipient
                200,                                // feeBps (2%)
                2 hours,                            // cooldown
                parimutuelAddr,                     // pricingEngine ← 使用 Parimutuel
                vaultAddr,                          // vault (占位符，不实际借款)
                "",                                 // oracleDetails
                0                                   // virtualReservePerSide ← 零虚拟储备 = Parimutuel 模式
            );

            // 通过 Factory 创建市场
            address market = factory.createMarket(oddEvenTemplateId, initData);

            console.log("Market", i + 1, "created:", market);
            console.log("  Match:", matchIds[i]);
            console.log("  Pricing: Parimutuel (zero virtual reserves)");
            console.log("  Teams:", teamAs[i], "vs", teamBs[i]);
            console.log("");
        }

        vm.stopBroadcast();

        console.log("========================================");
        console.log("  All 3 Parimutuel Markets Created!");
        console.log("========================================");
        console.log("\nNext steps:");
        console.log("1. Simulate bets on these markets");
        console.log("2. Reset Subgraph to index new markets");
        console.log("3. Verify in frontend\n");
    }
}
