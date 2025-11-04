// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/governance/ParamController.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployBatchMarkets
 * @notice 批量部署测试市场：10 个 WDL + 10 个 OU + 10 个 OddEven
 */
contract DeployBatchMarkets is Script {
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;
    ParamController public paramController;

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
        console.log("Batch Markets Deployment");
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

        paramController = new ParamController(deployer, 1 days);
        console.log("   ParamController:", address(paramController));

        // 2. 部署 10 个 WDL 市场
        console.log("\n2. Deploying 10 WDL markets...");
        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_2024_",
                vm.toString(i)
            ));

            WDL_Template wdl = new WDL_Template(
                matchId,
                teams[i * 2],                    // 主队
                teams[i * 2 + 1],                // 客队
                block.timestamp + (i + 1) * 12 hours, // 不同时间
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". WDL:", address(wdl));
            console.log("      Match:", teams[i * 2], "vs", teams[i * 2 + 1]);

            // 添加流动性
            uint256 liquidity = 1000e6; // 1000 USDC per market
            usdc.mint(deployer, liquidity);
            usdc.approve(address(wdl), liquidity);

            uint256[] memory weights = new uint256[](3);
            weights[0] = 1; // 主胜
            weights[1] = 1; // 平局
            weights[2] = 1; // 客胜
            wdl.addLiquidity(liquidity, weights);
        }

        // 3. 部署 10 个 OU 单线市场
        console.log("\n3. Deploying 10 OU single-line markets...");
        uint256[10] memory lines;
        lines[0] = 2500; lines[1] = 1500; lines[2] = 3500; lines[3] = 2500; lines[4] = 1500;
        lines[5] = 3500; lines[6] = 2500; lines[7] = 4500; lines[8] = 2500; lines[9] = 3500;

        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_OU_2024_",
                vm.toString(i)
            ));

            OU_Template ou = new OU_Template(
                matchId,
                teams[(i + 10) % 20],            // 不同的队伍组合
                teams[(i + 11) % 20],
                block.timestamp + (i + 11) * 12 hours,
                lines[i],                         // 不同的盘口线
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". OU:", address(ou));
            console.log("      Match:", teams[(i + 10) % 20], "vs", teams[(i + 11) % 20]);
            console.log("      Line:", lines[i]);

            // 添加流动性
            uint256 liquidity = 1000e6;
            usdc.mint(deployer, liquidity);
            usdc.approve(address(ou), liquidity);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 1; // 大球
            weights[1] = 1; // 小球
            ou.addLiquidity(liquidity, weights);
        }

        // 4. 部署 10 个 OddEven 市场
        console.log("\n4. Deploying 10 OddEven markets...");
        for (uint256 i = 0; i < 10; i++) {
            string memory matchId = string(abi.encodePacked(
                leagues[i],
                "_OE_2024_",
                vm.toString(i)
            ));

            OddEven_Template oe = new OddEven_Template(
                matchId,
                teams[(i + 5) % 20],             // 又不同的队伍组合
                teams[(i + 15) % 20],
                block.timestamp + (i + 21) * 12 hours,
                address(usdc),
                address(feeRouter),
                FEE_RATE,
                DISPUTE_PERIOD,
                address(cpmm),
                URI
            );

            console.log("   ", i + 1, ". OddEven:", address(oe));
            console.log("      Match:", teams[(i + 5) % 20], "vs", teams[(i + 15) % 20]);

            // 添加流动性
            uint256 liquidity = 1000e6;
            usdc.mint(deployer, liquidity);
            usdc.approve(address(oe), liquidity);

            uint256[] memory weights = new uint256[](2);
            weights[0] = 1; // 奇数
            weights[1] = 1; // 偶数
            oe.addLiquidity(liquidity, weights);
        }

        vm.stopBroadcast();

        // 5. 输出摘要
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("USDC:", address(usdc));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("\nMarkets Deployed:");
        console.log("  - 10 WDL markets");
        console.log("  - 10 OU single-line markets");
        console.log("  - 10 OddEven markets");
        console.log("\nTotal: 30 markets");
        console.log("Total Liquidity: 30,000 USDC");
        console.log("========================================");
    }
}
