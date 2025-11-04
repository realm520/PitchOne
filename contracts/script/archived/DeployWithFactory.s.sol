// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployWithFactory
 * @notice 使用 MarketFactory 部署测试市场，实现完全动态索引
 * @dev 这个脚本演示了标准的市场部署流程：
 *      1. 部署基础设施（USDC, FeeRouter, CPMM等）
 *      2. 部署 MarketFactory
 *      3. 通过 Factory 创建市场（触发 MarketCreated 事件）
 *      4. Subgraph 监听事件，自动索引新市场
 */
contract DeployWithFactory is Script {
    MarketFactory public factory;
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // 比赛数据
    string[10] public leagues = [
        "EPL", "LaLiga", "SerieA", "Bundesliga", "Ligue1",
        "UCL", "UEL", "PremierLeague", "Championship", "FA_Cup"
    ];

    string[20] public teams = [
        "Manchester United", "Manchester City", "Liverpool", "Arsenal",
        "Chelsea", "Tottenham", "Newcastle", "Brighton",
        "Barcelona", "Real Madrid", "Atletico Madrid", "Sevilla",
        "Juventus", "Inter Milan", "AC Milan", "Roma",
        "Bayern Munich", "Dortmund", "RB Leipzig", "Leverkusen"
    ];

    function run() public {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Factory-Based Markets Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署基础设施
        console.log("\n1. Deploying infrastructure...");
        usdc = new MockERC20("USDC", "USDC", 6);
        console.log("   USDC:", address(usdc));

        referralRegistry = new ReferralRegistry(deployer);
        console.log("   ReferralRegistry:", address(referralRegistry));

        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: payable(deployer),
            promoPool: payable(deployer),
            insuranceFund: payable(deployer),
            treasury: payable(deployer)
        });
        feeRouter = new FeeRouter(recipients, address(referralRegistry));
        feeRouter.setFeeSplit(6000, 2000, 1000, 1000);
        console.log("   FeeRouter:", address(feeRouter));

        cpmm = new SimpleCPMM();
        console.log("   SimpleCPMM:", address(cpmm));

        // 2. 部署 MarketFactory
        console.log("\n2. Deploying MarketFactory...");
        factory = new MarketFactory();
        console.log("   MarketFactory:", address(factory));

        // 3. 通过 Factory 创建 10 个 WDL 市场
        console.log("\n3. Creating 10 WDL markets via Factory...");
        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_2024_",
                vm.toString(i)
            ));

            address wdl = factory.createWDLMarket(
                matchId,
                teams[i * 2],
                teams[i * 2 + 1],
                block.timestamp + (i + 1) * 12 hours,
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". WDL:", wdl);
            console.log("      Match:", teams[i * 2], "vs", teams[i * 2 + 1]);

            // 添加流动性
            uint256 liquidity = 1000e6;
            usdc.mint(deployer, liquidity);
            usdc.approve(wdl, liquidity);

            uint256[] memory weights = new uint256[](3);
            weights[0] = 1; // 主胜
            weights[1] = 1; // 平局
            weights[2] = 1; // 客胜
            WDL_Template(wdl).addLiquidity(liquidity, weights);
        }

        // 4. 通过 Factory 创建 10 个 OU 单线市场
        console.log("\n4. Creating 10 OU markets via Factory...");
        uint256[10] memory lines;
        lines[0] = 2500; lines[1] = 1500; lines[2] = 3500; lines[3] = 2500; lines[4] = 1500;
        lines[5] = 3500; lines[6] = 2500; lines[7] = 4500; lines[8] = 2500; lines[9] = 3500;

        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_OU_2024_",
                vm.toString(i)
            ));

            address ou = factory.createOUMarket(
                matchId,
                teams[(i + 10) % 20],
                teams[(i + 11) % 20],
                block.timestamp + (i + 11) * 12 hours,
                lines[i],
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". OU:", ou);
            console.log("      Match:", teams[(i + 10) % 20], "vs", teams[(i + 11) % 20]);
            console.log("      Line:", lines[i]);

            // 添加流动性
            uint256 liquidity = 1000e6;
            usdc.mint(deployer, liquidity);
            usdc.approve(ou, liquidity);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 1; // 大球
            weights[1] = 1; // 小球
            OU_Template(ou).addLiquidity(liquidity, weights);
        }

        // 5. 通过 Factory 创建 10 个 OddEven 市场
        console.log("\n5. Creating 10 OddEven markets via Factory...");
        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_OE_2024_",
                vm.toString(i)
            ));

            address oe = factory.createOddEvenMarket(
                matchId,
                teams[(i + 5) % 20],
                teams[(i + 15) % 20],
                block.timestamp + (i + 21) * 12 hours,
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". OddEven:", oe);
            console.log("      Match:", teams[(i + 5) % 20], "vs", teams[(i + 15) % 20]);

            // 添加流动性
            uint256 liquidity = 1000e6;
            usdc.mint(deployer, liquidity);
            usdc.approve(oe, liquidity);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 1; // 奇数
            weights[1] = 1; // 偶数
            OddEven_Template(oe).addLiquidity(liquidity, weights);
        }

        vm.stopBroadcast();

        // 6. 输出摘要
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("MarketFactory:", address(factory));
        console.log("USDC:", address(usdc));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("\nMarkets Created:");
        console.log("  - 10 WDL markets");
        console.log("  - 10 OU single-line markets");
        console.log("  - 10 OddEven markets");
        console.log("\nTotal: 30 markets");
        console.log("Total Liquidity: 30,000 USDC");
        console.log("\nFactory Address (for Subgraph):", address(factory));
        console.log("========================================");
        console.log("\nNext Steps:");
        console.log("1. Update subgraph-dynamic.yaml with Factory address:");
        console.log("   address:", address(factory));
        console.log("2. Redeploy Subgraph: graph deploy ...");
        console.log("3. Subgraph will automatically index all 30 markets");
        console.log("========================================");
    }
}
