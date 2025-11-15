// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/liquidity/LiquidityVault.sol";

/**
 * @title CreateMarkets_NoMultiLine
 * @notice 创建 5 种市场类型（跳过 OU_MultiLine 和 PlayerProps）
 * @dev 自动从 deployments/localhost.json 读取合约地址
 */
contract CreateMarkets_NoMultiLine is Script {
    // Deployment JSON 路径
    string constant DEPLOYMENT_FILE = "deployments/localhost.json";

    // 从 JSON 读取的地址
    address FACTORY;
    address USDC;
    address VAULT;
    address FEE_ROUTER;
    address SIMPLE_CPMM;
    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // Template IDs（从 localhost.json 读取）
    bytes32 WDL_TEMPLATE_ID;
    bytes32 OU_TEMPLATE_ID;
    bytes32 AH_TEMPLATE_ID;
    bytes32 ODDEVEN_TEMPLATE_ID;
    bytes32 SCORE_TEMPLATE_ID;

    address[] public createdMarkets;

    function run() external {
        // 读取部署配置
        _loadDeploymentConfig();

        // 获取 USDC 精度
        uint8 usdcDecimals = getTokenDecimals(USDC);
        uint256 usdcUnit = 10 ** usdcDecimals;

        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);
        LiquidityVault vault = LiquidityVault(VAULT);

        console.log("\n========================================");
        console.log("  Creating 15 Markets (5 types x 3 each)");
        console.log("========================================\n");
        console.log("Using addresses from:", DEPLOYMENT_FILE);
        console.log("  Factory:", FACTORY);
        console.log("  Vault:", VAULT);
        console.log("");

        // 1. WDL
        console.log("1. Creating WDL Markets...");
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_1", "Man Utd", "Man City", 1));
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_2", "Liverpool", "Chelsea", 2));
        createdMarkets.push(createWDLMarket(factory, "EPL_2024_WDL_3", "Arsenal", "Tottenham", 3));
        console.log("   Created 3 WDL markets\n");

        // 2. OU
        console.log("2. Creating OU Markets...");
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_1", "Chelsea", "Arsenal", 2500, 4));
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_2", "Newcastle", "Brighton", 3500, 5));
        createdMarkets.push(createOUMarket(factory, "EPL_2024_OU_3", "West Ham", "Everton", 1500, 6));
        console.log("   Created 3 OU markets\n");

        // 3. AH
        console.log("3. Creating AH Markets...");
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_1", "Man City", "Tottenham", -500, 7));
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_2", "Liverpool", "Crystal Palace", 500, 8));
        createdMarkets.push(createAHMarket(factory, "EPL_2024_AH_3", "Arsenal", "Bournemouth", -500, 9));
        console.log("   Created 3 AH markets\n");

        // 4. OddEven
        console.log("4. Creating OddEven Markets...");
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_1", "Newcastle", "West Ham", 10));
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_2", "Southampton", "Leeds", 11));
        createdMarkets.push(createOddEvenMarket(factory, "EPL_2024_OE_3", "Nottm Forest", "Luton", 12));
        console.log("   Created 3 OddEven markets\n");

        // 5. Score
        console.log("5. Creating Score Markets...");
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_1", "Liverpool", "Brighton", 13, usdcUnit));
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_2", "Man Utd", "Aston Villa", 14, usdcUnit));
        createdMarkets.push(createScoreMarket(factory, "EPL_2024_SC_3", "Chelsea", "Wolves", 15, usdcUnit));
        console.log("   Created 3 Score markets\n");

        // Authorize all markets
        console.log("6. Authorizing all markets...");
        for (uint i = 0; i < createdMarkets.length; i++) {
            vault.authorizeMarket(createdMarkets[i]);
        }
        console.log("   All markets authorized\n");

        vm.stopBroadcast();

        console.log("========================================");
        console.log("  Success! Created", createdMarkets.length, "markets");
        console.log("========================================\n");

        for (uint i = 0; i < createdMarkets.length; i++) {
            console.log("  ", i + 1, ":", createdMarkets[i]);
        }
    }

    /**
     * @notice 从 deployments/localhost.json 加载配置
     */
    function _loadDeploymentConfig() internal {
        string memory deploymentData = vm.readFile(DEPLOYMENT_FILE);

        // 读取合约地址
        FACTORY = vm.parseJsonAddress(deploymentData, ".contracts.factory");
        USDC = vm.parseJsonAddress(deploymentData, ".contracts.usdc");
        VAULT = vm.parseJsonAddress(deploymentData, ".contracts.vault");
        FEE_ROUTER = vm.parseJsonAddress(deploymentData, ".contracts.feeRouter");
        SIMPLE_CPMM = vm.parseJsonAddress(deploymentData, ".contracts.cpmm");

        // 读取 Template IDs
        WDL_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.wdl");
        OU_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ou");
        AH_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ah");
        ODDEVEN_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.oddEven");
        SCORE_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.score");
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
            matchId, homeTeam, awayTeam,
            block.timestamp + dayOffset * 1 days,
            USDC, FEE_ROUTER, 200, 2 hours, SIMPLE_CPMM, VAULT,
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
            matchId, homeTeam, awayTeam,
            block.timestamp + dayOffset * 1 days, line,
            USDC, FEE_ROUTER, 200, 2 hours, SIMPLE_CPMM,
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " O/U")), OWNER
        );
        return factory.createMarket(OU_TEMPLATE_ID, initData);
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
            matchId, homeTeam, awayTeam,
            block.timestamp + dayOffset * 1 days,
            handicap, uint8(0), USDC, FEE_ROUTER, 200, 2 hours, SIMPLE_CPMM,
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " AH")), OWNER
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
            matchId, homeTeam, awayTeam,
            block.timestamp + dayOffset * 1 days,
            USDC, FEE_ROUTER, 200, 2 hours, SIMPLE_CPMM,
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " Odd/Even")), OWNER
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
        uint256[] memory probs = new uint256[](37);
        for (uint i = 0; i < 36; i++) {
            probs[i] = 270;
        }
        probs[36] = 280;

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint8,address,address,uint256,uint256,uint256,uint256[],string,address)",
            matchId, homeTeam, awayTeam,
            block.timestamp + dayOffset * 1 days,
            uint8(5), USDC, FEE_ROUTER, 200, 2 hours, 1000 * usdcUnit, probs,
            string(abi.encodePacked(homeTeam, " vs ", awayTeam, " Score")), OWNER
        );
        return factory.createMarket(SCORE_TEMPLATE_ID, initData);
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
