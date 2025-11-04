// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateTestMarkets
 * @notice Create test markets on Anvil deployment
 * @dev Uses Factory.recordMarket() for better Subgraph indexing
 */
contract CreateTestMarkets is Script {
    // Deployed contract addresses (from DeployToAnvil output)
    address constant USDC = 0x2a810409872AfC346F9B5b26571Fd6eC42EA4849;
    address constant FEE_ROUTER = 0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8;
    address constant CPMM = 0x40918Ba7f132E0aCba2CE4de4c4baF9BD2D7D849;
    address constant FACTORY = 0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55;

    // Template IDs (deterministic - same across deployments)
    bytes32 constant WDL_TEMPLATE_ID = 0x7334184f034ef6984c34eb62c58e3516a2f6130b338d0c0c6ed9cbf862c0a052;
    bytes32 constant OU_TEMPLATE_ID = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
    bytes32 constant ODDEVEN_TEMPLATE_ID = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.pitchone.io/metadata/{id}";

    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("  Creating Test Markets on Anvil");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Factory:", FACTORY);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);

        // Create 2 markets of each type (6 markets total)
        console.log("1. Creating WDL markets...");
        createWDLMarkets(factory, deployer, 2);

        console.log("\n2. Creating OU markets...");
        createOUMarkets(factory, deployer, 2);

        console.log("\n3. Creating OddEven markets...");
        createOddEvenMarkets(factory, deployer, 2);

        console.log("\n========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("Total Markets Created: 6");
        console.log("  - 2 WDL markets (Win/Draw/Lose)");
        console.log("  - 2 OU markets (Over/Under)");
        console.log("  - 2 OddEven markets (Odd/Even goals)");
        console.log("");
        console.log("Check Subgraph at:");
        console.log("  http://localhost:8000/subgraphs/name/sportsbook-local/graphql");
        console.log("========================================");

        vm.stopBroadcast();
    }

    function createWDLMarkets(MarketFactory_v2 factory, address deployer, uint256 count) internal {
        string[5] memory matches = [
            "EPL: Manchester United vs Liverpool",
            "La Liga: Barcelona vs Real Madrid",
            "Bundesliga: Bayern Munich vs Dortmund",
            "Serie A: Juventus vs Inter Milan",
            "Ligue 1: PSG vs Marseille"
        ];

        for (uint256 i = 0; i < count && i < matches.length; i++) {
            // Step 1: Deploy market directly
            WDL_Template market = new WDL_Template(
                string(abi.encodePacked("WDL_2024_", vm.toString(i))),
                "Home Team",
                "Away Team",
                block.timestamp + 7 days,
                USDC,
                FEE_ROUTER,
                FEE_RATE,
                DISPUTE_PERIOD,
                CPMM,
                URI
            );

            // Step 2: Register with Factory
            factory.recordMarket(address(market), WDL_TEMPLATE_ID);

            console.log("   ", i + 1, ". Market:", address(market));
            console.log("       Event:", matches[i]);

            // Step 3: Add initial liquidity
            uint256[] memory weights = new uint256[](3);
            weights[0] = 333;  // Home win
            weights[1] = 333;  // Draw
            weights[2] = 334;  // Away win
            uint256 liquidity = 3000 * 10 ** 6; // 3000 USDC

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Liquidity: 3000 USDC");
        }
    }

    function createOUMarkets(MarketFactory_v2 factory, address deployer, uint256 count) internal {
        string[5] memory matches = [
            "EPL: Chelsea vs Arsenal (O/U 2.5)",
            "La Liga: Real Madrid vs Atletico (O/U 1.5)",
            "Serie A: Inter vs AC Milan (O/U 2.5)",
            "Ligue 1: PSG vs Lyon (O/U 3.5)",
            "Bundesliga: Leipzig vs Leverkusen (O/U 3.5)"
        ];

        uint256[5] memory lines = [uint256(2500), 1500, 2500, 3500, 3500];

        for (uint256 i = 0; i < count && i < matches.length; i++) {
            OU_Template market = new OU_Template(
                string(abi.encodePacked("OU_2024_", vm.toString(i))),
                "Home Team",
                "Away Team",
                block.timestamp + 7 days,
                lines[i], // line in thousandths (2.5 goals = 2500)
                USDC,
                FEE_ROUTER,
                FEE_RATE,
                DISPUTE_PERIOD,
                CPMM,
                URI
            );

            factory.recordMarket(address(market), OU_TEMPLATE_ID);

            console.log("   ", i + 1, ". Market:", address(market));
            console.log("       Event:", matches[i]);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 500;  // Over
            weights[1] = 500;  // Under
            uint256 liquidity = 2000 * 10 ** 6; // 2000 USDC

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Liquidity: 2000 USDC");
        }
    }

    function createOddEvenMarkets(MarketFactory_v2 factory, address deployer, uint256 count) internal {
        string[5] memory matches = [
            "EPL: Tottenham vs Newcastle",
            "La Liga: Sevilla vs Valencia",
            "Serie A: Napoli vs Lazio",
            "Ligue 1: Monaco vs Nice",
            "Bundesliga: Freiburg vs Hoffenheim"
        ];

        for (uint256 i = 0; i < count && i < matches.length; i++) {
            OddEven_Template market = new OddEven_Template(
                string(abi.encodePacked("ODDEVEN_2024_", vm.toString(i))),
                "Home Team",
                "Away Team",
                block.timestamp + 7 days,
                USDC,
                FEE_ROUTER,
                FEE_RATE,
                DISPUTE_PERIOD,
                CPMM,
                URI
            );

            factory.recordMarket(address(market), ODDEVEN_TEMPLATE_ID);

            console.log("   ", i + 1, ". Market:", address(market));
            console.log("       Event:", matches[i]);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 500;  // Odd goals
            weights[1] = 500;  // Even goals
            uint256 liquidity = 2000 * 10 ** 6; // 2000 USDC

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Liquidity: 2000 USDC");
        }
    }
}
