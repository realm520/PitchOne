// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateMultipleMarkets
 * @notice 创建多种类型的市场，并进行多个地址下注
 */
contract CreateMultipleMarkets is Script {
    // Deployed contract addresses
    address constant USDC = 0x2a810409872AfC346F9B5b26571Fd6eC42EA4849;
    address constant FEE_ROUTER = 0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8;
    address constant CPMM = 0x40918Ba7f132E0aCba2CE4de4c4baF9BD2D7D849;
    address constant FACTORY = 0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55;

    // Template IDs
    bytes32 constant WDL_TEMPLATE_ID = 0x7334184f034ef6984c34eb62c58e3516a2f6130b338d0c0c6ed9cbf862c0a052;
    bytes32 constant OU_TEMPLATE_ID = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
    bytes32 constant ODDEVEN_TEMPLATE_ID = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.pitchone.io/metadata/{id}";

    // 10个测试账户的私钥
    uint256[] betterPrivateKeys;

    struct MarketInfo {
        string matchId;
        string homeTeam;
        string awayTeam;
        uint256 kickoffTime;
        bool shouldLock;
        bool shouldResolve;
        uint256 winnerOutcome;
    }

    function setUp() public {
        // 初始化10个测试账户的私钥
        for (uint256 i = 1; i <= 10; i++) {
            betterPrivateKeys.push(uint256(keccak256(abi.encodePacked("test_user", i))));
        }
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("  Creating Multiple Markets with Bets");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);
        MockERC20 usdc = MockERC20(USDC);

        // 为每个下注者铸造 USDC
        console.log("Minting USDC for 10 betters...");
        for (uint256 i = 0; i < betterPrivateKeys.length; i++) {
            address better = vm.addr(betterPrivateKeys[i]);
            usdc.mint(better, 10000e6); // 10k USDC per better
        }
        console.log("");

        // 创建 WDL 市场（5个）
        console.log("=== Creating 5 WDL Markets ===");
        createWDLMarkets(factory, usdc, deployer, deployerPrivateKey);

        // 创建 OU 单线市场（5个）
        console.log("\n=== Creating 5 OU Single Line Markets ===");
        createOUMarkets(factory, usdc, deployer, deployerPrivateKey);

        // 创建 OddEven 市场（5个）
        console.log("\n=== Creating 5 OddEven Markets ===");
        createOddEvenMarkets(factory, usdc, deployer, deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("Total Markets Created: 15");
        console.log("  - 5 WDL markets (2 locked, 2 resolved)");
        console.log("  - 5 OU markets (1 locked, 2 resolved)");
        console.log("  - 5 OddEven markets (2 locked, 1 resolved)");
        console.log("Each market has 10 betters");
        console.log("========================================");

        vm.stopBroadcast();
    }

    function createWDLMarkets(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK
    ) internal {
        MarketInfo[5] memory markets = [
            MarketInfo({
                matchId: "EPL_2024_CHE_vs_ARS",
                homeTeam: "Chelsea",
                awayTeam: "Arsenal",
                kickoffTime: block.timestamp + 2 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_LIV_vs_MCI",
                homeTeam: "Liverpool",
                awayTeam: "Man City",
                kickoffTime: block.timestamp + 1 days,
                shouldLock: true,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_TOT_vs_MUN",
                homeTeam: "Tottenham",
                awayTeam: "Man Utd",
                kickoffTime: block.timestamp + 1 hours,
                shouldLock: true,
                shouldResolve: true,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_NEW_vs_WHU",
                homeTeam: "Newcastle",
                awayTeam: "West Ham",
                kickoffTime: block.timestamp + 30 minutes,
                shouldLock: true,
                shouldResolve: true,
                winnerOutcome: 1
            }),
            MarketInfo({
                matchId: "EPL_2024_BRE_vs_FUL",
                homeTeam: "Brentford",
                awayTeam: "Fulham",
                kickoffTime: block.timestamp + 3 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            })
        ];

        for (uint256 i = 0; i < markets.length; i++) {
            createAndBetWDL(factory, usdc, deployer, deployerPK, markets[i], i);
        }
    }

    function createAndBetWDL(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK,
        MarketInfo memory info,
        uint256 index
    ) internal {
        console.log("\n", index + 1, ". Creating WDL:", info.matchId);

        // 部署市场
        WDL_Template market = new WDL_Template(
            info.matchId,
            info.homeTeam,
            info.awayTeam,
            info.kickoffTime,
            USDC,
            FEE_ROUTER,
            FEE_RATE,
            DISPUTE_PERIOD,
            CPMM,
            URI
        );

        // 注册到工厂
        factory.recordMarket(address(market), WDL_TEMPLATE_ID);
        console.log("   Market:", address(market));

        // 添加初始流动性
        uint256[] memory weights = new uint256[](3);
        weights[0] = 333;  // Home
        weights[1] = 333;  // Draw
        weights[2] = 334;  // Away
        uint256 liquidity = 5000e6; // 5k USDC

        usdc.mint(deployer, liquidity);
        usdc.approve(address(market), liquidity);
        market.addLiquidity(liquidity, weights);
        console.log("   Liquidity: 5000 USDC");

        // 10个地址下注
        placeBets(usdc, address(market), 3, deployerPK);

        // 锁盘和结算
        if (info.shouldLock) {
            console.log("   Locking market...");
            market.lock();

            if (info.shouldResolve) {
                console.log("   Resolving with outcome:", info.winnerOutcome);
                market.resolve(info.winnerOutcome);
            }
        }
    }

    function createOUMarkets(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK
    ) internal {
        MarketInfo[5] memory markets = [
            MarketInfo({
                matchId: "EPL_2024_EVE_vs_AVL",
                homeTeam: "Everton",
                awayTeam: "Aston Villa",
                kickoffTime: block.timestamp + 2 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_WOL_vs_BOU",
                homeTeam: "Wolves",
                awayTeam: "Bournemouth",
                kickoffTime: block.timestamp + 1 days,
                shouldLock: true,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_CRY_vs_BHA",
                homeTeam: "Crystal Palace",
                awayTeam: "Brighton",
                kickoffTime: block.timestamp + 2 hours,
                shouldLock: true,
                shouldResolve: true,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_LEI_vs_NOT",
                homeTeam: "Leicester",
                awayTeam: "Nottingham",
                kickoffTime: block.timestamp + 1 hours,
                shouldLock: true,
                shouldResolve: true,
                winnerOutcome: 1
            }),
            MarketInfo({
                matchId: "EPL_2024_SOU_vs_IPS",
                homeTeam: "Southampton",
                awayTeam: "Ipswich",
                kickoffTime: block.timestamp + 4 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            })
        ];

        for (uint256 i = 0; i < markets.length; i++) {
            createAndBetOU(factory, usdc, deployer, deployerPK, markets[i], i);
        }
    }

    function createAndBetOU(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK,
        MarketInfo memory info,
        uint256 index
    ) internal {
        console.log("\n", index + 1, ". Creating OU:", info.matchId);

        OU_Template market = new OU_Template(
            info.matchId,
            info.homeTeam,
            info.awayTeam,
            info.kickoffTime,
            2500, // line: 2.5 goals
            USDC,
            FEE_ROUTER,
            FEE_RATE,
            DISPUTE_PERIOD,
            CPMM,
            URI
        );

        factory.recordMarket(address(market), OU_TEMPLATE_ID);
        console.log("   Market:", address(market));

        uint256[] memory weights = new uint256[](2);
        weights[0] = 500;  // Over
        weights[1] = 500;  // Under
        uint256 liquidity = 4000e6;

        usdc.mint(deployer, liquidity);
        usdc.approve(address(market), liquidity);
        market.addLiquidity(liquidity, weights);
        console.log("   Liquidity: 4000 USDC");

        placeBets(usdc, address(market), 2, deployerPK);

        if (info.shouldLock) {
            console.log("   Locking market...");
            market.lock();

            if (info.shouldResolve) {
                console.log("   Resolving with outcome:", info.winnerOutcome);
                market.resolve(info.winnerOutcome);
            }
        }
    }

    function createOddEvenMarkets(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK
    ) internal {
        MarketInfo[5] memory markets = [
            MarketInfo({
                matchId: "EPL_2024_ARS_vs_CHE_OE",
                homeTeam: "Arsenal",
                awayTeam: "Chelsea",
                kickoffTime: block.timestamp + 2 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_MCI_vs_LIV_OE",
                homeTeam: "Man City",
                awayTeam: "Liverpool",
                kickoffTime: block.timestamp + 5 hours,
                shouldLock: true,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_MUN_vs_TOT_OE",
                homeTeam: "Man Utd",
                awayTeam: "Tottenham",
                kickoffTime: block.timestamp + 3 days,
                shouldLock: true,
                shouldResolve: false,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_WHU_vs_NEW_OE",
                homeTeam: "West Ham",
                awayTeam: "Newcastle",
                kickoffTime: block.timestamp + 45 minutes,
                shouldLock: true,
                shouldResolve: true,
                winnerOutcome: 0
            }),
            MarketInfo({
                matchId: "EPL_2024_FUL_vs_BRE_OE",
                homeTeam: "Fulham",
                awayTeam: "Brentford",
                kickoffTime: block.timestamp + 6 days,
                shouldLock: false,
                shouldResolve: false,
                winnerOutcome: 0
            })
        ];

        for (uint256 i = 0; i < markets.length; i++) {
            createAndBetOddEven(factory, usdc, deployer, deployerPK, markets[i], i);
        }
    }

    function createAndBetOddEven(
        MarketFactory_v2 factory,
        MockERC20 usdc,
        address deployer,
        uint256 deployerPK,
        MarketInfo memory info,
        uint256 index
    ) internal {
        console.log("\n", index + 1, ". Creating OddEven:", info.matchId);

        OddEven_Template market = new OddEven_Template(
            info.matchId,
            info.homeTeam,
            info.awayTeam,
            info.kickoffTime,
            USDC,
            FEE_ROUTER,
            FEE_RATE,
            DISPUTE_PERIOD,
            CPMM,
            URI
        );

        factory.recordMarket(address(market), ODDEVEN_TEMPLATE_ID);
        console.log("   Market:", address(market));

        uint256[] memory weights = new uint256[](2);
        weights[0] = 500;  // Odd
        weights[1] = 500;  // Even
        uint256 liquidity = 4000e6;

        usdc.mint(deployer, liquidity);
        usdc.approve(address(market), liquidity);
        market.addLiquidity(liquidity, weights);
        console.log("   Liquidity: 4000 USDC");

        placeBets(usdc, address(market), 2, deployerPK);

        if (info.shouldLock) {
            console.log("   Locking market...");
            market.lock();

            if (info.shouldResolve) {
                console.log("   Resolving with outcome:", info.winnerOutcome);
                market.resolve(info.winnerOutcome);
            }
        }
    }

    function placeBets(
        MockERC20 usdc,
        address marketAddr,
        uint256 numOutcomes,
        uint256 deployerPK
    ) internal {
        console.log("   Placing bets from 10 addresses...");

        for (uint256 i = 0; i < 10; i++) {
            uint256 betterPK = betterPrivateKeys[i];
            address better = vm.addr(betterPK);

            // 随机选择结果
            uint256 outcome = uint256(keccak256(abi.encodePacked(better, i, marketAddr))) % numOutcomes;

            // 随机金额 50-500 USDC
            uint256 amount = 50e6 + (uint256(keccak256(abi.encodePacked(better, i, block.timestamp))) % 450e6);

            vm.stopBroadcast();
            vm.startBroadcast(betterPK);

            usdc.approve(marketAddr, amount);

            // 下注
            try WDL_Template(marketAddr).placeBet(outcome, amount) {
                // Success
            } catch {
                // Might fail if market is locked or other reason
            }

            vm.stopBroadcast();
            vm.startBroadcast(deployerPK);
        }
    }
}
