// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/liquidity/LiquidityVault.sol";
import "../src/interfaces/IAH_Template.sol";
import "../src/pricing/LinkedLinesController.sol";
import "../src/templates/OU_MultiLine.sol";
import "../src/templates/PlayerProps_Template.sol";

/**
 * @title CreateAllMarketTypes
 * @notice 创建所有 7 种市场类型的测试市场
 * @dev 每种类型创建 3-5 个市场，确保所有市场都被授权到 Vault
 */
contract CreateAllMarketTypes is Script {
    // 从 deployments/localhost.json 读取的地址
    address constant FACTORY = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    address constant USDC = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant VAULT = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant FEE_ROUTER = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
    address constant SIMPLE_CPMM = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Template IDs
    bytes32 constant WDL_TEMPLATE_ID = 0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc;
    bytes32 constant OU_TEMPLATE_ID = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
    bytes32 constant OU_MULTILINE_TEMPLATE_ID = 0x69ba3dae7b66ebb64049fc9c8571fbcbdee40e6fcd6e08c4af73fc9f9b24faad;
    bytes32 constant AH_TEMPLATE_ID = 0x042c80233717c236ab1e837fcd85b710ad76f98d7388137da07154db2c58ccef;
    bytes32 constant ODDEVEN_TEMPLATE_ID = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;
    bytes32 constant SCORE_TEMPLATE_ID = 0xe6fe3ae76e2c116a886e641a6320e0324fb6596f3250d75d79b753f3f7276266;
    bytes32 constant PLAYERPROPS_TEMPLATE_ID = 0xec35ff5e222bed7eecf8134bb0a82de4133815bcd7d7083a09f6673b10d0e735;

    address[] public createdMarkets;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 获取 USDC 精度
        uint8 usdcDecimals = getTokenDecimals(USDC);
        uint256 usdcUnit = 10 ** usdcDecimals;

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);
        LiquidityVault vault = LiquidityVault(VAULT);

        console.log("\n========================================");
        console.log("  Creating All Market Types (7 types)");
        console.log("========================================\n");

        // 1. 创建 WDL 市场 (3 个)
        console.log("1. Creating WDL Markets (Win/Draw/Lose)...");
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_1", "Man Utd", "Man City", 1));
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_2", "Liverpool", "Chelsea", 2));
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_3", "Arsenal", "Tottenham", 3));
        console.log("   Created 3 WDL markets\n");

        // 2. 创建 OU 市场 (3 个) - 只允许半球盘
        console.log("2. Creating OU Markets (Over/Under)...");
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_1", "Chelsea", "Arsenal", 2500, 4));  // 2.5
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_2", "Newcastle", "Brighton", 3500, 5)); // 3.5
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_3", "West Ham", "Everton", 1500, 6));  // 1.5
        console.log("   Created 3 OU markets\n");

        // 3. 创建 OU_MultiLine 市场 - 将在后面创建
        console.log("3. OU_MultiLine Markets will be created after OddEven\n");

        // 4. 创建 AH 市场 (3 个) - 使用半球盘
        console.log("4. Creating AH Markets (Asian Handicap)...");
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_1", "Man City", "Tottenham", -500, 9));     // -0.5
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_2", "Liverpool", "Crystal Palace", 500, 10)); // +0.5
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_3", "Arsenal", "Bournemouth", -500, 11));  // -0.5
        console.log("   Created 3 AH markets\n");

        // 5. 创建 OddEven 市场 (3 个)
        console.log("5. Creating OddEven Markets...");
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_1", "Newcastle", "West Ham", 12));
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_2", "Southampton", "Leeds", 13));
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_3", "Nottm Forest", "Luton", 14));
        console.log("   Created 3 OddEven markets\n");

        // 6. 创建 Score 市场 (3 个)
        console.log("6. Creating Score Markets (Exact Score)...");
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_1", "Liverpool", "Brighton", 15, usdcUnit));
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_2", "Man Utd", "Aston Villa", 16, usdcUnit));
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_3", "Chelsea", "Wolves", 17, usdcUnit));
        console.log("   Created 3 Score markets\n");

        // 7. 创建 OU_MultiLine 市场 (3 个)
        console.log("7. Creating OU_MultiLine Markets...");
        createdMarkets.push(createOUMultiLineMarket(factory, "EPL_2024_OUML_1", "Fulham", "Brentford", 18));
        createdMarkets.push(createOUMultiLineMarket(factory, "EPL_2024_OUML_2", "Leicester", "Villa", 19));
        createdMarkets.push(createOUMultiLineMarket(factory, "EPL_2024_OUML_3", "Burnley", "Sheffield Utd", 20));
        console.log("   Created 3 OU_MultiLine markets\n");

        // 8. 创建 PlayerProps 市场 (3 个)
        console.log("8. Creating PlayerProps Markets...");
        createdMarkets.push(createPlayerPropsMarket(factory, "EPL_2024_PP_1", "Man City", "Chelsea", "Erling Haaland", 21, usdcUnit));
        createdMarkets.push(createPlayerPropsMarket(factory, "EPL_2024_PP_2", "Liverpool", "Arsenal", "Mohamed Salah", 22, usdcUnit));
        createdMarkets.push(createPlayerPropsMarket(factory, "EPL_2024_PP_3", "Tottenham", "Newcastle", "Harry Kane", 23, usdcUnit));
        console.log("   Created 3 PlayerProps markets\n");

        // 授权所有市场到 Vault
        console.log("9. Authorizing all markets in Vault...");
        for (uint i = 0; i < createdMarkets.length; i++) {
            vault.authorizeMarket(createdMarkets[i]);
        }
        console.log("   All markets authorized\n");

        vm.stopBroadcast();

        // 输出总结
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

    function createWDLMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
            matchId,
            homeTeam,
            awayTeam,
            block.timestamp + dayOffset * 1 days,
            USDC,
            FEE_ROUTER,
            200, // 2% fee
            2 hours,
            SIMPLE_CPMM,
            VAULT,
            string(abi.encodePacked(homeTeam, " vs ", awayTeam))
        );
        return factory.createMarket(WDL_TEMPLATE_ID, initData);
    }

    function createOUMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 line,
        uint256 dayOffset
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint256,address,address,uint256,uint256,address,string,address)",
            matchId,              // matchId
            homeTeam,             // homeTeam
            awayTeam,             // awayTeam
            block.timestamp + dayOffset * 1 days, // kickoffTime
            line,                 // line
            USDC,                 // settlementToken
            FEE_ROUTER,           // feeRecipient
            200,                  // feeRate
            2 hours,              // disputePeriod
            SIMPLE_CPMM,          // pricingEngine
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " O/U")), // uri
            OWNER                 // owner
        );
        return factory.createMarket(OU_TEMPLATE_ID, initData);
    }

    function createOUMultiLineMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        // 部署 LinkedLinesController
        LinkedLinesController controller = new LinkedLinesController(OWNER, address(0));

        uint256[] memory lines = new uint256[](3);
        lines[0] = 1500; // 1.5
        lines[1] = 2500; // 2.5
        lines[2] = 3500; // 3.5

        // 使用结构体编码
        OU_MultiLine.InitializeParams memory params = OU_MultiLine.InitializeParams({
            matchId: matchId,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            kickoffTime: block.timestamp + dayOffset * 1 days,
            lines: lines,
            settlementToken: USDC,
            feeRecipient: FEE_ROUTER,
            feeRate: 200,
            disputePeriod: 2 hours,
            pricingEngine: SIMPLE_CPMM,
            linkedLinesController: address(controller),
            uri: string(abi.encodePacked(homeTeam, " vs ", awayTeam, " O/U MultiLine")),
            owner: OWNER
        });

        bytes memory initData = abi.encodeWithSelector(
            OU_MultiLine.initialize.selector,
            params
        );
        return factory.createMarket(OU_MULTILINE_TEMPLATE_ID, initData);
    }

    function createAHMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        int256 handicap,
        uint256 dayOffset
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,int256,uint8,address,address,uint256,uint256,address,string,address)",
            matchId,              // matchId
            homeTeam,             // homeTeam
            awayTeam,             // awayTeam
            block.timestamp + dayOffset * 1 days, // kickoffTime
            handicap,             // handicap
            uint8(0),             // handicapType (HALF = 0)
            USDC,                 // settlementToken
            FEE_ROUTER,           // feeRecipient
            200,                  // feeRate
            2 hours,              // disputePeriod
            SIMPLE_CPMM,          // pricingEngine
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " AH")), // uri
            OWNER                 // owner
        );
        return factory.createMarket(AH_TEMPLATE_ID, initData);
    }

    function createOddEvenMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset
    ) internal returns (address) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,string,address)",
            matchId,              // matchId
            homeTeam,             // homeTeam
            awayTeam,             // awayTeam
            block.timestamp + dayOffset * 1 days, // kickoffTime
            USDC,                 // settlementToken
            FEE_ROUTER,           // feeRecipient
            200,                  // feeRate
            2 hours,              // disputePeriod
            SIMPLE_CPMM,          // pricingEngine
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " Odd/Even")), // uri
            OWNER                 // owner
        );
        return factory.createMarket(ODDEVEN_TEMPLATE_ID, initData);
    }

    function createScoreMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 dayOffset,
        uint256 usdcUnit
    ) internal returns (address) {
        // 创建初始概率数组 (37 个结果: 0-0 到 5-5 + Other)
        uint256[] memory probs = new uint256[](37);
        for (uint i = 0; i < 36; i++) {
            probs[i] = 270; // 36 * 270 = 9720
        }
        probs[36] = 280; // 调整使总和 = 10000

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint8,address,address,uint256,uint256,uint256,uint256[],string,address)",
            matchId,              // matchId
            homeTeam,             // homeTeam
            awayTeam,             // awayTeam
            block.timestamp + dayOffset * 1 days, // kickoffTime
            uint8(5),             // maxGoals (0-5)
            USDC,                 // settlementToken
            FEE_ROUTER,           // feeRecipient
            200,                  // feeRate
            2 hours,              // disputePeriod
            1000 * 1e18,          // liquidityB (LMSR parameter, 必须使用 WAD 单位)
            probs,                // initialProbabilities
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " Score")), // uri
            OWNER                 // owner
        );
        return factory.createMarket(SCORE_TEMPLATE_ID, initData);
    }

    function createPlayerPropsMarket(
        MarketFactory_v2 factory,
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        string memory playerName,
        uint256 dayOffset,
        uint256 usdcUnit
    ) internal returns (address) {
        // 创建初始储备数组（SimpleCPMM 二向市场）
        uint256[] memory initialReserves = new uint256[](2);
        initialReserves[0] = 100000 * usdcUnit; // 100k USDC for Over（使用动态精度）
        initialReserves[1] = 100000 * usdcUnit; // 100k USDC for Under（使用动态精度）

        // 空数组（FIRST_SCORER 专用）
        string[] memory emptyPlayerIds = new string[](0);
        string[] memory emptyPlayerNames = new string[](0);

        // 使用结构体编码
        PlayerProps_Template.PlayerPropsInitData memory data = PlayerProps_Template.PlayerPropsInitData({
            matchId: string(abi.encodePacked(homeTeam, "_vs_", awayTeam)),
            playerId: string(abi.encodePacked("player_", playerName)),
            playerName: playerName,
            propType: PlayerProps_Template.PropType.GOALS_OU,
            line: 500, // 0.5 goals (半球盘)
            kickoffTime: block.timestamp + dayOffset * 1 days,
            settlementToken: USDC,
            feeRecipient: FEE_ROUTER,
            feeRate: 200,
            disputePeriod: 2 hours,
            uri: string(abi.encodePacked(playerName, " Goals O/U 0.5")),
            owner: OWNER,
            pricingEngineAddr: SIMPLE_CPMM,
            initialReserves: initialReserves,
            playerIds: emptyPlayerIds,
            playerNames: emptyPlayerNames
        });

        bytes memory initData = abi.encodeWithSelector(
            PlayerProps_Template.initialize.selector,
            data
        );
        return factory.createMarket(PLAYERPROPS_TEMPLATE_ID, initData);
    }

    /**
     * @notice 获取 ERC20 代币的精度
     * @param token 代币地址
     * @return 代币精度（decimals）
     */
    function getTokenDecimals(address token) internal view returns (uint8) {
        // 使用低级别调用来获取 decimals
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );

        require(success && data.length >= 32, "Failed to get token decimals");
        return abi.decode(data, (uint8));
    }
}
