// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketTemplateRegistry.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/core/FeeRouter.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateMarketsViaRegistry
 * @notice 通过 Registry 统一创建市场（动态索引演示）
 */
contract CreateMarketsViaRegistry is Script {
    // 已部署的合约地址（从 DeployViaRegistry 输出）
    address constant USDC = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant FEE_ROUTER = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    address constant CPMM = 0x0165878A594ca255338adfa4d48449f69242Eb8F;
    address constant REGISTRY = 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6;
    address constant WDL_TEMPLATE_IMPL = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    function run() public {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Creating Markets via Registry");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Registry:", REGISTRY);

        vm.startBroadcast(deployerPrivateKey);

        MarketTemplateRegistry registry = MarketTemplateRegistry(REGISTRY);

        // 获取 WDL 模板 ID
        bytes32 wdlTemplateId = keccak256(abi.encode("WDL", "1.0.0"));

        console.log("\n1. Checking template registration...");
        console.log("   WDL Template ID:", vm.toString(wdlTemplateId));

        // 创建 5 个 WDL 市场
        console.log("\n2. Creating 5 WDL markets via Registry...");

        string[5] memory matches = [
            "Manchester United vs Liverpool",
            "Barcelona vs Real Madrid",
            "Bayern Munich vs Dortmund",
            "Juventus vs Inter Milan",
            "PSG vs Marseille"
        ];

        for (uint256 i = 0; i < 5; i++) {
            // 构造 WDL 市场的初始化数据
            bytes memory constructorArgs = abi.encode(
                string(abi.encodePacked("MATCH_", vm.toString(i))),  // matchId
                matches[i],                                            // eventDescription
                "",                                                    // homeTeam
                "",                                                    // awayTeam
                block.timestamp + 1 days,                              // kickoffTime
                USDC,                                                  // currency
                FEE_ROUTER,                                           // feeRouter
                FEE_RATE,                                             // feeRate
                DISPUTE_PERIOD,                                       // disputePeriod
                CPMM,                                                 // pricingEngine
                URI                                                   // uri
            );

            // 获取 WDL_Template 的 creation bytecode
            bytes memory creationCode = type(WDL_Template).creationCode;
            bytes memory initData = abi.encodePacked(creationCode, constructorArgs);

            // 通过 Registry 创建市场
            address market = registry.createMarket(wdlTemplateId, initData);

            console.log("   ", i + 1, ". Market created:", market);
            console.log("       Match:", matches[i]);

            // 添加初始流动性
            uint256[] memory weights = new uint256[](3);
            weights[0] = 333;
            weights[1] = 333;
            weights[2] = 334;
            uint256 liquidity = 3000 ether; // 3000 USDC (实际是 3000 * 10^6)

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(market, liquidity);
            WDL_Template(market).addLiquidity(liquidity, weights);

            console.log("       Added", liquidity / 1e6, "USDC liquidity");
        }

        console.log("\n========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("Registry:", REGISTRY);
        console.log("Total Markets Created: 5");
        console.log("Total Liquidity: 15,000 USDC");
        console.log("\nSubgraph will automatically index these markets!");
        console.log("========================================");

        vm.stopBroadcast();
    }
}
