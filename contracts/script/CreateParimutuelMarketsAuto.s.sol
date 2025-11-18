// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template_V2.sol";
import "../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateParimutuelMarketsAuto
 * @notice 自动从 localhost.json 读取配置并创建 Parimutuel 模式的市场
 * @dev 符合 AUTOMATED_DATA_FLOW.md 的自动化原则
 */
contract CreateParimutuelMarketsAuto is Script {
    string constant DEPLOYMENT_FILE = "deployments/localhost.json";

    // 从 JSON 读取的地址
    address FACTORY;
    address USDC;
    address PARIMUTUEL_PROVIDER;  // 使用 ParimutuelLiquidityProvider
    address FEE_ROUTER;
    address PARIMUTUEL;
    bytes32 WDL_TEMPLATE_ID;
    bytes32 OU_TEMPLATE_ID;
    bytes32 ODDEVEN_TEMPLATE_ID;

    address[] public createdMarkets;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        console.log("\n========================================");
        console.log("  Create Parimutuel Markets (Auto)");
        console.log("========================================");
        console.log("Reading config from:", DEPLOYMENT_FILE);
        console.log("\n");

        // 从 localhost.json 自动读取配置
        _loadDeploymentConfig();

        console.log("Loaded addresses:");
        console.log("  Factory:", FACTORY);
        console.log("  USDC:", USDC);
        console.log("  Parimutuel Provider:", PARIMUTUEL_PROVIDER);
        console.log("  FeeRouter:", FEE_ROUTER);
        console.log("  Parimutuel Engine:", PARIMUTUEL);
        console.log("  WDL Template ID:", vm.toString(WDL_TEMPLATE_ID));
        console.log("  OU Template ID:", vm.toString(OU_TEMPLATE_ID));
        console.log("  OddEven Template ID:", vm.toString(ODDEVEN_TEMPLATE_ID));
        console.log("\n");

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);

        vm.startBroadcast(deployerPrivateKey);

        console.log("Creating Parimutuel Markets (Zero Virtual Reserves)...\n");

        // 测试数据
        string[3] memory wdlMatchIds = ["EPL_2024_PM_WDL_1", "EPL_2024_PM_WDL_2", "EPL_2024_PM_WDL_3"];
        string[3] memory ouMatchIds = ["EPL_2024_PM_OU_1", "EPL_2024_PM_OU_2", "EPL_2024_PM_OU_3"];
        string[3] memory oeMatchIds = ["EPL_2024_PM_OE_1", "EPL_2024_PM_OE_2", "EPL_2024_PM_OE_3"];

        string[3] memory teamAs = ["Manchester United", "Arsenal", "Liverpool"];
        string[3] memory teamBs = ["Manchester City", "Chelsea", "Tottenham"];

        uint256[3] memory lines = [uint256(2500), uint256(3500), uint256(1500)]; // 2.5, 3.5, 1.5 球

        // 1. 创建 3 个 Parimutuel WDL 市场
        console.log("1. Creating WDL Markets (Win/Draw/Lose)...");
        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelWDLMarket(
                factory,
                wdlMatchIds[i],
                teamAs[i],
                teamBs[i]
            );

            createdMarkets.push(market);

            console.log("  WDL Market", i + 1, "created:", market);
            console.log("    Match:", wdlMatchIds[i]);
            console.log("    Teams:", teamAs[i], "vs", teamBs[i]);
            console.log("    Mode: Parimutuel (zero virtual reserves)");
            console.log("");
        }

        // 2. 创建 3 个 Parimutuel OU 市场
        console.log("2. Creating OU Markets (Over/Under)...");
        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelOUMarket(
                factory,
                ouMatchIds[i],
                teamAs[i],
                teamBs[i],
                lines[i]
            );

            createdMarkets.push(market);

            console.log("  OU Market", i + 1, "created:", market);
            console.log("    Match:", ouMatchIds[i]);
            console.log("    Teams:", teamAs[i], "vs", teamBs[i]);
            console.log("    Line:", lines[i]); // 如 2500 = 2.5 球
            console.log("    Mode: Parimutuel (zero virtual reserves)");
            console.log("");
        }

        // 3. 创建 3 个 Parimutuel OddEven 市场
        console.log("3. Creating OddEven Markets...");
        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelOddEvenMarket(
                factory,
                oeMatchIds[i],
                teamAs[i],
                teamBs[i]
            );

            createdMarkets.push(market);

            console.log("  OddEven Market", i + 1, "created:", market);
            console.log("    Match:", oeMatchIds[i]);
            console.log("    Teams:", teamAs[i], "vs", teamBs[i]);
            console.log("    Mode: Parimutuel (zero virtual reserves)");
            console.log("");
        }

        // 4. 授权所有市场到 ParimutuelLiquidityProvider
        console.log("4. Authorizing all markets to ParimutuelLiquidityProvider...");
        ParimutuelLiquidityProvider provider = ParimutuelLiquidityProvider(PARIMUTUEL_PROVIDER);
        for (uint256 i = 0; i < createdMarkets.length; i++) {
            provider.authorizeMarket(createdMarkets[i]);
            console.log("  Authorized market", i + 1, ":", createdMarkets[i]);
        }
        console.log("  All", createdMarkets.length, "markets authorized\n");

        vm.stopBroadcast();

        console.log("========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("Total Parimutuel Markets Created:", createdMarkets.length);
        console.log("\nBreakdown by Type:");
        console.log("  - WDL (Win/Draw/Lose): 3");
        console.log("  - OU (Over/Under): 3");
        console.log("  - OddEven: 3");
        console.log("  Total: 9 markets (3 types x 3 each)");
        console.log("\nMarket Addresses:");
        for (uint256 i = 0; i < createdMarkets.length; i++) {
            console.log("  ", i + 1, ":", createdMarkets[i]);
        }
        console.log("\n");
        console.log("Market Configuration:");
        console.log("  - Pricing Engine: ParimutuelPricing");
        console.log("  - Liquidity Provider: ParimutuelLiquidityProvider");
        console.log("  - Virtual Reserve: 0 (Pure Parimutuel Mode)");
        console.log("  - Fee Rate: 2%");
        console.log("  - Authorization: All markets authorized to ParimutuelLiquidityProvider");
        console.log("\n");
        console.log("Next steps:");
        console.log("1. Run SimulateBets.s.sol to place bets");
        console.log("2. Run reset-subgraph.sh to index markets");
        console.log("3. Verify in frontend\n");
    }

    /**
     * @dev 从 localhost.json 加载部署配置
     */
    function _loadDeploymentConfig() internal {
        string memory deploymentData = vm.readFile(DEPLOYMENT_FILE);

        // 读取合约地址
        FACTORY = vm.parseJsonAddress(deploymentData, ".contracts.factory");
        USDC = vm.parseJsonAddress(deploymentData, ".contracts.usdc");
        PARIMUTUEL_PROVIDER = vm.parseJsonAddress(deploymentData, ".contracts.parimutuelProvider");
        FEE_ROUTER = vm.parseJsonAddress(deploymentData, ".contracts.feeRouter");
        PARIMUTUEL = vm.parseJsonAddress(deploymentData, ".contracts.parimutuel");

        // 读取模板 ID
        WDL_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.wdl");
        OU_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ou");
        ODDEVEN_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.oddEven");
    }

    /**
     * @dev 创建 Parimutuel 模式的 OddEven 市场
     */
    function _createParimutuelOddEvenMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory teamA,
        string memory teamB
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            OddEven_Template_V2.initialize.selector,
            matchId,
            teamA,
            teamB,
            block.timestamp + 7 days,  // lockTime
            USDC,
            FEE_ROUTER,
            200,                       // feeBps (2%)
            2 hours,                   // cooldown
            PARIMUTUEL,                // pricingEngine ← 使用 Parimutuel
            PARIMUTUEL_PROVIDER,       // liquidityProvider ← 使用 ParimutuelLiquidityProvider
            "",                        // oracleDetails
            0                          // virtualReservePerSide ← 零虚拟储备 = Parimutuel 模式
        );

        return factory.createMarket(ODDEVEN_TEMPLATE_ID, initData);
    }

    /**
     * @dev 创建 Parimutuel 模式的 WDL 市场
     */
    function _createParimutuelWDLMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory teamA,
        string memory teamB
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            WDL_Template_V2.initialize.selector,
            matchId,
            teamA,
            teamB,
            block.timestamp + 7 days,  // lockTime
            USDC,
            FEE_ROUTER,
            200,                       // feeBps (2%)
            2 hours,                   // cooldown
            PARIMUTUEL,                // pricingEngine ← 使用 Parimutuel
            PARIMUTUEL_PROVIDER,       // liquidityProvider ← 使用 ParimutuelLiquidityProvider
            "",                        // oracleDetails
            0                          // virtualReservePerSide ← 零虚拟储备 = Parimutuel 模式
        );

        return factory.createMarket(WDL_TEMPLATE_ID, initData);
    }

    /**
     * @dev 创建 Parimutuel 模式的 OU 市场
     */
    function _createParimutuelOUMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory teamA,
        string memory teamB,
        uint256 line
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSelector(
            OU_Template_V2.initialize.selector,
            matchId,
            teamA,
            teamB,
            block.timestamp + 7 days,  // lockTime
            line,                      // line (如 2500 = 2.5 球)
            USDC,
            FEE_ROUTER,
            200,                       // feeBps (2%)
            2 hours,                   // cooldown
            PARIMUTUEL,                // pricingEngine ← 使用 Parimutuel
            PARIMUTUEL_PROVIDER,       // liquidityProvider ← 使用 ParimutuelLiquidityProvider
            "",                        // oracleDetails
            0                          // virtualReservePerSide ← 零虚拟储备 = Parimutuel 模式
        );

        return factory.createMarket(OU_TEMPLATE_ID, initData);
    }
}
