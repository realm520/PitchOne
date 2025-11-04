// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OU_MultiLine.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/pricing/LinkedLinesController.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/governance/ParamController.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployDiverseMarkets
 * @notice 部署多种类型的市场并模拟投注
 */
contract DeployDiverseMarkets is Script {
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;
    ParamController public paramController;
    LinkedLinesController public linkedLinesController;

    // 测试账户（Anvil 默认账户）
    address constant USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Account #0
    address constant USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Account #1
    address constant USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Account #2

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Diverse Markets Deployment");
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

        paramController = new ParamController(deployer, 1 days); // 1天timelock
        console.log("   ParamController:", address(paramController));

        linkedLinesController = new LinkedLinesController(deployer, address(paramController));
        console.log("   LinkedLinesController:", address(linkedLinesController));

        // 2. 创建多种类型的市场
        console.log("\n2. Creating diverse markets...");

        // 市场 1: 胜平负市场 - Barcelona vs Real Madrid
        WDL_Template wdlMarket = new WDL_Template(
            "LALIGA_2024_BAR_vs_RMA",
            "FC Barcelona",
            "Real Madrid",
            block.timestamp + 24 hours,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   WDL Market (BAR vs RMA):", address(wdlMarket));

        // 市场 2: 大小球单线 - Bayern vs Dortmund (2.5球)
        OU_Template ouSingleMarket = new OU_Template(
            "BUNDESLIGA_2024_BAY_vs_DOR",
            "Bayern Munich",
            "Borussia Dortmund",
            block.timestamp + 48 hours,
            2500, // 2.5 goals
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   OU Single-Line Market (BAY vs DOR, 2.5):", address(ouSingleMarket));

        // 市场 3: 大小球多线 - 暂时不需要
        // uint256[] memory lines = new uint256[](3);
        // lines[0] = 2500; // 2.5 goals
        // lines[1] = 3500; // 3.5 goals
        // lines[2] = 4500; // 4.5 goals
        //
        // OU_MultiLine.ConstructorParams memory ouMultiParams = OU_MultiLine.ConstructorParams({
        //     matchId: "LIGUE1_2024_PSG_vs_LYO",
        //     homeTeam: "Paris Saint-Germain",
        //     awayTeam: "Olympique Lyon",
        //     kickoffTime: block.timestamp + 72 hours,
        //     lines: lines,
        //     settlementToken: address(usdc),
        //     feeRecipient: address(feeRouter),
        //     feeRate: FEE_RATE,
        //     disputePeriod: DISPUTE_PERIOD,
        //     pricingEngine: address(cpmm),
        //     linkedLinesController: address(linkedLinesController),
        //     uri: URI
        // });
        // OU_MultiLine ouMultiMarket = new OU_MultiLine(ouMultiParams);
        // console.log("   OU Multi-Line Market (PSG vs LYO, 2.5/3.5/4.5):", address(ouMultiMarket));

        // 2.5. 铸造 USDC 给 deployer 用于添加流动性
        usdc.mint(deployer, 10000e6); // 10,000 USDC for liquidity
        console.log("\n   Minted 10,000 USDC to deployer for adding liquidity");

        // 2.6. 添加初始流动性
        console.log("\n2.6. Adding initial liquidity to markets...");

        uint256 initialLiquidity = 3000e6; // 3000 USDC per market

        // WDL 市场：均分给 3 个结果（主胜、平局、客胜）
        usdc.approve(address(wdlMarket), initialLiquidity);
        uint256[] memory wdlWeights = new uint256[](3);
        wdlWeights[0] = 1; // 主胜
        wdlWeights[1] = 1; // 平局
        wdlWeights[2] = 1; // 客胜
        wdlMarket.addLiquidity(initialLiquidity, wdlWeights);
        console.log("   Added 3000 USDC to WDL market (1000 per outcome)");

        // OU 单线市场（2.5球盘）：仅支持半球盘，只有大/小两个选项
        usdc.approve(address(ouSingleMarket), initialLiquidity);
        uint256[] memory ouWeights = new uint256[](2);
        ouWeights[0] = 1; // 大球
        ouWeights[1] = 1; // 小球
        ouSingleMarket.addLiquidity(initialLiquidity, ouWeights);
        console.log("   Added 3000 USDC to OU Single market (1500 per outcome)");

        // OU 多线市场 - 暂时不需要
        // usdc.approve(address(ouMultiMarket), initialLiquidity);
        // uint256[] memory ouMultiWeights = new uint256[](6); // 3 lines * 2 outcomes
        // ouMultiWeights[0] = 1; // 2.5球 大
        // ouMultiWeights[1] = 1; // 2.5球 小
        // ouMultiWeights[2] = 1; // 3.5球 大
        // ouMultiWeights[3] = 1; // 3.5球 小
        // ouMultiWeights[4] = 1; // 4.5球 大
        // ouMultiWeights[5] = 1; // 4.5球 小
        // ouMultiMarket.addLiquidity(initialLiquidity, ouMultiWeights);
        // console.log("   Added 3000 USDC to OU Multi market (500 per outcome)");

        // 3. 给测试账户铸造 USDC
        console.log("\n3. Minting USDC for test users...");
        usdc.mint(USER1, 10000e6); // 10,000 USDC
        usdc.mint(USER2, 10000e6);
        usdc.mint(USER3, 10000e6);
        console.log("   Minted 10,000 USDC to each user");

        vm.stopBroadcast();

        // 4. 模拟多用户下注
        console.log("\n4. Simulating user bets...");

        // USER1 下注
        vm.startBroadcast(deployerPrivateKey); // USER1
        console.log("\n   USER1 bets:");

        // WDL市场：巴萨主胜
        usdc.approve(address(wdlMarket), 1000e6);
        wdlMarket.placeBet(0, 1000e6); // 主胜
        console.log("     - 1000 USDC on Barcelona Win (WDL outcome 0)");

        // OU单线：大于2.5球
        usdc.approve(address(ouSingleMarket), 800e6);
        ouSingleMarket.placeBet(0, 800e6); // OVER
        console.log("     - 800 USDC on Over 2.5 goals (OU-Single outcome 0)");

        // OU多线 - 暂时不需要
        // usdc.approve(address(ouMultiMarket), 600e6);
        // ouMultiMarket.placeBet(2, 600e6);
        // console.log("     - 600 USDC on Over 3.5 goals (OU-Multi outcome 2)");

        vm.stopBroadcast();

        // USER2 下注
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d); // USER2
        console.log("\n   USER2 bets:");

        // WDL市场：平局
        usdc.approve(address(wdlMarket), 1500e6);
        wdlMarket.placeBet(1, 1500e6); // 平局
        console.log("     - 1500 USDC on Draw (WDL outcome 1)");

        // OU单线：小于2.5球
        usdc.approve(address(ouSingleMarket), 1200e6);
        ouSingleMarket.placeBet(1, 1200e6); // UNDER
        console.log("     - 1200 USDC on Under 2.5 goals (OU-Single outcome 1)");

        // OU多线 - 暂时不需要
        // usdc.approve(address(ouMultiMarket), 900e6);
        // ouMultiMarket.placeBet(5, 900e6);
        // console.log("     - 900 USDC on Under 4.5 goals (OU-Multi outcome 5)");

        vm.stopBroadcast();

        // USER3 下注
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a); // USER3
        console.log("\n   USER3 bets:");

        // WDL市场：皇马客胜
        usdc.approve(address(wdlMarket), 2000e6);
        wdlMarket.placeBet(2, 2000e6); // 客胜
        console.log("     - 2000 USDC on Real Madrid Win (WDL outcome 2)");

        // OU单线：大于2.5球
        usdc.approve(address(ouSingleMarket), 1000e6);
        ouSingleMarket.placeBet(0, 1000e6); // OVER
        console.log("     - 1000 USDC on Over 2.5 goals (OU-Single outcome 0)");

        // OU多线 - 暂时不需要
        // usdc.approve(address(ouMultiMarket), 700e6);
        // ouMultiMarket.placeBet(0, 700e6);
        // console.log("     - 700 USDC on Over 2.5 goals (OU-Multi outcome 0)");

        vm.stopBroadcast();

        // 5. 输出摘要
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("USDC:", address(usdc));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("LinkedLinesController:", address(linkedLinesController));
        console.log("\nMarkets:");
        console.log("  1. WDL: BAR vs RMA:", address(wdlMarket));
        console.log("  2. OU-Single: BAY vs DOR (2.5):", address(ouSingleMarket));
        // console.log("  3. OU-Multi: PSG vs LYO (2.5/3.5/4.5):", address(ouMultiMarket));
        console.log("\nTotal Bets: 6");
        console.log("Total Volume: 7500 USDC");
        console.log("========================================");
    }
}
