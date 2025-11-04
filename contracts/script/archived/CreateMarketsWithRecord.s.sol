// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateMarketsWithRecord
 * @notice 方案 A：通过 Factory.recordMarket() 创建市场
 * @dev 工作流:
 *      1. 直接 new Template(...) 创建市场
 *      2. 调用 factory.recordMarket() 注册
 *      3. Factory 发出 MarketCreated 事件
 *      4. Subgraph 自动索引
 */
contract CreateMarketsWithRecord is Script {
    // 已部署合约地址（从 DeployCompleteSystem 输出）
    address constant USDC = 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e;
    address constant FEE_ROUTER = 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82;
    address constant CPMM = 0x9A676e781A523b5d0C0e43731313A708CB607508;
    address constant FACTORY = 0x0B306BF915C4d645ff596e518fAf3F9669b97016;

    // 模板 ID（从部署输出）
    bytes32 constant WDL_TEMPLATE_ID = 0x7334184f034ef6984c34eb62c58e3516a2f6130b338d0c0c6ed9cbf862c0a052;
    bytes32 constant OU_TEMPLATE_ID = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
    bytes32 constant ODDEVEN_TEMPLATE_ID = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Creating Markets with Factory.recordMarket()");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("Factory:", FACTORY);

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_v2 factory = MarketFactory_v2(FACTORY);

        // 创建 5 个不同类型的市场
        console.log("\n1. Creating WDL markets...");
        createWDLMarkets(factory, deployer);

        console.log("\n2. Creating OU markets...");
        createOUMarkets(factory, deployer);

        console.log("\n3. Creating OddEven markets...");
        createOddEvenMarkets(factory, deployer);

        console.log("\n========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("Total Markets Created: 15");
        console.log("  - 5 WDL markets");
        console.log("  - 5 OU markets");
        console.log("  - 5 OddEven markets");
        console.log("");
        console.log("All markets registered in Factory!");
        console.log("Subgraph will automatically index these markets.");
        console.log("========================================");

        vm.stopBroadcast();
    }

    function createWDLMarkets(MarketFactory_v2 factory, address deployer) internal {
        string[5] memory matches = [
            "Manchester United vs Liverpool",
            "Barcelona vs Real Madrid",
            "Bayern Munich vs Dortmund",
            "Juventus vs Inter Milan",
            "PSG vs Marseille"
        ];

        for (uint256 i = 0; i < 5; i++) {
            // 步骤 1: 直接创建市场
            WDL_Template market = new WDL_Template(
                string(abi.encodePacked("WDL_", vm.toString(i))),
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

            // 步骤 2: 注册到 Factory
            factory.recordMarket(address(market), WDL_TEMPLATE_ID);

            console.log("   ", i + 1, ". Market:", address(market));
            console.log("       Match:", matches[i]);

            // 步骤 3: 添加流动性
            uint256[] memory weights = new uint256[](3);
            weights[0] = 333;
            weights[1] = 333;
            weights[2] = 334;
            uint256 liquidity = 3000 * 10 ** 6; // 3000 USDC

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Added liquidity: 3000 USDC");
        }
    }

    function createOUMarkets(MarketFactory_v2 factory, address deployer) internal {
        string[5] memory matches = [
            "Chelsea vs Arsenal (Over/Under 2.5)",
            "Liverpool vs Manchester City (O/U 3.5)",
            "Real Madrid vs Atletico (O/U 2.0)",
            "Inter vs AC Milan (O/U 2.5)",
            "PSG vs Lyon (O/U 3.0)"
        ];

        uint256[5] memory lines = [uint256(2500), 3500, 1500, 2500, 3500];

        for (uint256 i = 0; i < 5; i++) {
            OU_Template market = new OU_Template(
                string(abi.encodePacked("OU_", vm.toString(i))),
                "Home Team",
                "Away Team",
                block.timestamp + 7 days,
                lines[i],
                USDC,
                FEE_ROUTER,
                FEE_RATE,
                DISPUTE_PERIOD,
                CPMM,
                URI
            );

            factory.recordMarket(address(market), OU_TEMPLATE_ID);

            console.log("   ", i + 1, ". Market:", address(market));
            console.log("       Match:", matches[i]);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 500;
            weights[1] = 500;
            uint256 liquidity = 2000 * 10 ** 6;

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Added liquidity: 2000 USDC");
        }
    }

    function createOddEvenMarkets(MarketFactory_v2 factory, address deployer) internal {
        string[5] memory matches = [
            "Tottenham vs Newcastle",
            "Brighton vs Wolves",
            "Sevilla vs Valencia",
            "Napoli vs Lazio",
            "Monaco vs Nice"
        ];

        for (uint256 i = 0; i < 5; i++) {
            OddEven_Template market = new OddEven_Template(
                string(abi.encodePacked("ODDEVEN_", vm.toString(i))),
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
            console.log("       Match:", matches[i]);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 500;
            weights[1] = 500;
            uint256 liquidity = 2000 * 10 ** 6;

            MockERC20(USDC).mint(deployer, liquidity);
            MockERC20(USDC).approve(address(market), liquidity);
            market.addLiquidity(liquidity, weights);

            console.log("       Added liquidity: 2000 USDC");
        }
    }
}
