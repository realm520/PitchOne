// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./MarketConfig.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/liquidity/LiquidityVault.sol";
import "../src/interfaces/IAH_Template.sol";
import "../src/pricing/LinkedLinesController.sol";
import "../src/templates/OU_MultiLine_V2.sol";
import "../src/templates/PlayerProps_Template_V2.sol";

/**
 * @title CreateAllMarketTypes_V2
 * @notice 使用统一配置创建所有 7 种市场类型的测试市场
 * @dev 通过 MarketConfig 库管理默认配置，减少重复代码
 */
contract CreateAllMarketTypes_V2 is Script {
    using MarketConfig for *;

    address[] public createdMarkets;
    uint256 public usdcDecimals;
    uint256 public usdcUnit;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 获取 USDC 精度
        usdcDecimals = getTokenDecimals(MarketConfig.USDC);
        usdcUnit = 10 ** usdcDecimals;

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(MarketConfig.FACTORY);
        LiquidityVault vault = LiquidityVault(MarketConfig.VAULT);

        console.log("\n========================================");
        console.log("  Creating All Market Types (7 types)");
        console.log("  Using Unified Configuration");
        console.log("========================================\n");

        // 1. 创建 WDL 市场 (3 个)
        console.log("1. Creating WDL Markets (Win/Draw/Lose)...");
        createdMarkets.push(createWDLMarket(factory, "Man Utd", "Man City", 1));
        createdMarkets.push(createWDLMarket(factory, "Liverpool", "Chelsea", 2));
        createdMarkets.push(createWDLMarket(factory, "Arsenal", "Tottenham", 3));
        console.log("   Created 3 WDL markets\n");

        // 2. 创建 OU 市场 (3 个)
        console.log("2. Creating OU Markets (Over/Under)...");
        createdMarkets.push(createOUMarket(factory, "Chelsea", "Arsenal", 2500, 4));
        createdMarkets.push(createOUMarket(factory, "Newcastle", "Brighton", 3500, 5));
        createdMarkets.push(createOUMarket(factory, "West Ham", "Everton", 1500, 6));
        console.log("   Created 3 OU markets\n");

        // 3. 创建 AH 市场 (3 个)
        console.log("3. Creating AH Markets (Asian Handicap)...");
        createdMarkets.push(createAHMarket(factory, "Man City", "Tottenham", -500, 9));
        createdMarkets.push(createAHMarket(factory, "Liverpool", "Crystal Palace", 500, 10));
        createdMarkets.push(createAHMarket(factory, "Arsenal", "Bournemouth", -500, 11));
        console.log("   Created 3 AH markets\n");

        // 4. 创建 OddEven 市场 (3 个)
        console.log("4. Creating OddEven Markets...");
        createdMarkets.push(createOddEvenMarket(factory, "Newcastle", "West Ham", 12));
        createdMarkets.push(createOddEvenMarket(factory, "Southampton", "Leeds", 13));
        createdMarkets.push(createOddEvenMarket(factory, "Nottm Forest", "Luton", 14));
        console.log("   Created 3 OddEven markets\n");

        // 5. 创建 Score 市场 (3 个)
        console.log("5. Creating Score Markets (Exact Score)...");
        createdMarkets.push(createScoreMarket(factory, "Liverpool", "Brighton", 15));
        createdMarkets.push(createScoreMarket(factory, "Man Utd", "Aston Villa", 16));
        createdMarkets.push(createScoreMarket(factory, "Chelsea", "Wolves", 17));
        console.log("   Created 3 Score markets\n");

        // 6. 创建 OU_MultiLine 市场 (3 个)
        console.log("6. Creating OU_MultiLine Markets...");
        createdMarkets.push(createOUMultiLineMarket(factory, "Fulham", "Brentford", 18));
        createdMarkets.push(createOUMultiLineMarket(factory, "Leicester", "Villa", 19));
        createdMarkets.push(createOUMultiLineMarket(factory, "Burnley", "Sheffield Utd", 20));
        console.log("   Created 3 OU_MultiLine markets\n");

        // 7. 创建 PlayerProps 市场 (3 个)
        console.log("7. Creating PlayerProps Markets...");
        createdMarkets.push(createPlayerPropsMarket(factory, "Man City", "Chelsea", "Erling Haaland", 21));
        createdMarkets.push(createPlayerPropsMarket(factory, "Liverpool", "Arsenal", "Mohamed Salah", 22));
        createdMarkets.push(createPlayerPropsMarket(factory, "Tottenham", "Newcastle", "Harry Kane", 23));
        console.log("   Created 3 PlayerProps markets\n");

        // 授权所有市场到 Vault
        console.log("8. Authorizing all markets in Vault...");
        for (uint i = 0; i < createdMarkets.length; i++) {
            vault.authorizeMarket(createdMarkets[i]);
        }
        console.log("   All markets authorized\n");

        vm.stopBroadcast();

        // 输出总结
        printSummary();
    }

    /**
     * @notice 创建WDL市场（简化版 - 只需要队伍名和时间）
     */
    function createWDLMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam)),
            homeTeam,
            awayTeam,
            dayOffset
        );

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
            config.matchId,
            config.homeTeam,
            config.awayTeam,
            config.kickoffTime,
            config.settlementToken,
            config.feeRecipient,
            config.feeRate,
            config.disputePeriod,
            config.pricingEngine,
            MarketConfig.VAULT,
            MarketConfig.generateURI(homeTeam, awayTeam, "WDL")
        );
        return factory.createMarket(MarketConfig.WDL_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建OU市场（只需要额外指定盘口线）
     */
    function createOUMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        uint256 line,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_OU")),
            homeTeam,
            awayTeam,
            dayOffset
        );

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint256,address,address,uint256,uint256,address,string,address)",
            config.matchId,
            config.homeTeam,
            config.awayTeam,
            config.kickoffTime,
            line,
            config.settlementToken,
            config.feeRecipient,
            config.feeRate,
            config.disputePeriod,
            config.pricingEngine,
            MarketConfig.generateURI(homeTeam, awayTeam, "O/U"),
            config.owner
        );
        return factory.createMarket(MarketConfig.OU_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建AH市场（只需要额外指定让球数）
     */
    function createAHMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        int256 handicap,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_AH")),
            homeTeam,
            awayTeam,
            dayOffset
        );

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,int256,uint8,address,address,uint256,uint256,address,string,address)",
            config.matchId,
            config.homeTeam,
            config.awayTeam,
            config.kickoffTime,
            handicap,
            uint8(0), // HALF handicap type
            config.settlementToken,
            config.feeRecipient,
            config.feeRate,
            config.disputePeriod,
            config.pricingEngine,
            MarketConfig.generateURI(homeTeam, awayTeam, "AH"),
            config.owner
        );
        return factory.createMarket(MarketConfig.AH_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建OddEven市场（无额外参数）
     */
    function createOddEvenMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_OE")),
            homeTeam,
            awayTeam,
            dayOffset
        );

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,string,address)",
            config.matchId,
            config.homeTeam,
            config.awayTeam,
            config.kickoffTime,
            config.settlementToken,
            config.feeRecipient,
            config.feeRate,
            config.disputePeriod,
            config.pricingEngine,
            MarketConfig.generateURI(homeTeam, awayTeam, "Odd/Even"),
            config.owner
        );
        return factory.createMarket(MarketConfig.ODDEVEN_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建Score市场（使用默认LMSR参数和均匀概率）
     */
    function createScoreMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_SC")),
            homeTeam,
            awayTeam,
            dayOffset
        );

        uint8 maxGoals = 5;
        uint256 numOutcomes = (maxGoals + 1) * (maxGoals + 1) + 1; // 0-5 for each team + Other = 37
        uint256[] memory probs = MarketConfig.getUniformProbabilities(numOutcomes);

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint8,address,address,uint256,uint256,uint256,uint256[],string,address)",
            config.matchId,
            config.homeTeam,
            config.awayTeam,
            config.kickoffTime,
            maxGoals,
            config.settlementToken,
            config.feeRecipient,
            config.feeRate,
            config.disputePeriod,
            MarketConfig.getDefaultLMSRLiquidity(),
            probs,
            MarketConfig.generateURI(homeTeam, awayTeam, "Score"),
            config.owner
        );
        return factory.createMarket(MarketConfig.SCORE_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建OU_MultiLine市场（使用默认多线配置）
     */
    function createOUMultiLineMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam, "_OUML")),
            homeTeam,
            awayTeam,
            dayOffset
        );

        // 部署 LinkedLinesController
        LinkedLinesController controller = new LinkedLinesController(config.owner, address(0));

        // 使用常用的3条线：1.5, 2.5, 3.5
        uint256[] memory lines = new uint256[](3);
        lines[0] = 1500;
        lines[1] = 2500;
        lines[2] = 3500;

        OU_MultiLine_V2.InitializeParams memory params = OU_MultiLine_V2.InitializeParams({
            matchId: config.matchId,
            homeTeam: config.homeTeam,
            awayTeam: config.awayTeam,
            kickoffTime: config.kickoffTime,
            lines: lines,
            settlementToken: config.settlementToken,
            feeRecipient: config.feeRecipient,
            feeRate: config.feeRate,
            disputePeriod: config.disputePeriod,
            pricingEngine: config.pricingEngine,
            linkedLinesController: address(controller),
            vault: MarketConfig.VAULT,
            uri: MarketConfig.generateURI(homeTeam, awayTeam, "O/U MultiLine")
        });

        bytes memory initData = abi.encodeWithSelector(
            OU_MultiLine_V2.initialize.selector,
            params
        );
        return factory.createMarket(MarketConfig.OU_MULTILINE_TEMPLATE_ID, initData);
    }

    /**
     * @notice 创建PlayerProps市场（使用默认储备和球员进球数O/U）
     */
    function createPlayerPropsMarket(
        MarketFactory_v2 factory,
        string memory homeTeam,
        string memory awayTeam,
        string memory playerName,
        uint256 dayOffset
    ) internal returns (address) {
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            string(abi.encodePacked("EPL_2024_", homeTeam, "_vs_", awayTeam)),
            homeTeam,
            awayTeam,
            dayOffset
        );

        uint256[] memory initialReserves = MarketConfig.getDefaultPlayerPropsReserves(usdcUnit);
        string[] memory emptyPlayerIds = new string[](0);
        string[] memory emptyPlayerNames = new string[](0);

        PlayerProps_Template_V2.PlayerPropsInitData memory data = PlayerProps_Template_V2.PlayerPropsInitData({
            matchId: string(abi.encodePacked(homeTeam, "_vs_", awayTeam)),
            playerId: string(abi.encodePacked("player_", playerName)),
            playerName: playerName,
            propType: PlayerProps_Template_V2.PropType.GOALS_OU,
            line: 500, // 0.5 goals
            kickoffTime: config.kickoffTime,
            settlementToken: config.settlementToken,
            feeRecipient: config.feeRecipient,
            feeRate: config.feeRate,
            disputePeriod: config.disputePeriod,
            vault: MarketConfig.VAULT,
            uri: string(abi.encodePacked(playerName, " Goals O/U 0.5")),
            pricingEngineAddr: config.pricingEngine,
            initialReserves: initialReserves,
            playerIds: emptyPlayerIds,
            playerNames: emptyPlayerNames
        });

        bytes memory initData = abi.encodeWithSelector(
            PlayerProps_Template_V2.initialize.selector,
            data
        );
        return factory.createMarket(MarketConfig.PLAYERPROPS_TEMPLATE_ID, initData);
    }

    /**
     * @notice 输出创建总结
     */
    function printSummary() internal view {
        console.log("========================================");
        console.log("  Markets Created Successfully!");
        console.log("========================================");
        console.log("Total Markets Created:", createdMarkets.length);
        console.log("\nBreakdown by Type:");
        console.log("  - WDL: 3");
        console.log("  - OU: 3");
        console.log("  - AH: 3");
        console.log("  - OddEven: 3");
        console.log("  - Score: 3");
        console.log("  - OU_MultiLine: 3");
        console.log("  - PlayerProps: 3");
        console.log("  Total: 21 markets (7 types x 3 each)");
        console.log("\nAll markets:");
        for (uint i = 0; i < createdMarkets.length; i++) {
            console.log("  ", i + 1, ":", createdMarkets[i]);
        }
        console.log("========================================\n");
    }

    /**
     * @notice 获取 ERC20 代币的精度
     */
    function getTokenDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        require(success && data.length >= 32, "Failed to get token decimals");
        return abi.decode(data, (uint8));
    }
}
