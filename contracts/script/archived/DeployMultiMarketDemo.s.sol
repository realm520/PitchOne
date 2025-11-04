// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployMultiMarketDemo
 * @notice 部署多个市场并模拟多用户下注的演示脚本
 */
contract DeployMultiMarketDemo is Script {
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;

    // 测试账户（Anvil 默认账户）
    address constant USER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Account #0
    address constant USER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Account #1
    address constant USER3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Account #2
    address constant USER4 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Account #3

    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Multi-Market Demo Deployment");
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

        // 2. 创建多个市场
        console.log("\n2. Creating markets...");

        WDL_Template market1 = new WDL_Template(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            block.timestamp + 24 hours,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   Market 1 (MUN vs MCI):", address(market1));

        WDL_Template market2 = new WDL_Template(
            "EPL_2024_LIV_vs_ARS",
            "Liverpool",
            "Arsenal",
            block.timestamp + 48 hours,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   Market 2 (LIV vs ARS):", address(market2));

        WDL_Template market3 = new WDL_Template(
            "EPL_2024_CHE_vs_TOT",
            "Chelsea",
            "Tottenham",
            block.timestamp + 72 hours,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   Market 3 (CHE vs TOT):", address(market3));

        // 3. 给测试账户铸造 USDC
        console.log("\n3. Minting USDC for test users...");
        usdc.mint(USER1, 10000e6); // 10,000 USDC
        usdc.mint(USER2, 10000e6);
        usdc.mint(USER3, 10000e6);
        usdc.mint(USER4, 10000e6);
        console.log("   Minted 10,000 USDC to each user");

        vm.stopBroadcast();

        // 4. 模拟多用户下注
        console.log("\n4. Simulating user bets...");

        // USER1 下注
        vm.startBroadcast(deployerPrivateKey); // 使用 deployer = USER1
        usdc.approve(address(market1), 1000e6);
        market1.placeBet(0, 1000e6); // 主胜
        console.log("   USER1 bet 1000 USDC on MUN (outcome 0)");

        usdc.approve(address(market2), 500e6);
        market2.placeBet(2, 500e6); // 客胜
        console.log("   USER1 bet 500 USDC on ARS (outcome 2)");
        vm.stopBroadcast();

        // USER2 下注
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d); // USER2 private key
        usdc.approve(address(market1), 1500e6);
        market1.placeBet(1, 1500e6); // 平局
        console.log("   USER2 bet 1500 USDC on Draw (outcome 1)");

        usdc.approve(address(market3), 800e6);
        market3.placeBet(0, 800e6); // 主胜
        console.log("   USER2 bet 800 USDC on CHE (outcome 0)");
        vm.stopBroadcast();

        // USER3 下注
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a); // USER3 private key
        usdc.approve(address(market1), 2000e6);
        market1.placeBet(2, 2000e6); // 客胜
        console.log("   USER3 bet 2000 USDC on MCI (outcome 2)");

        usdc.approve(address(market2), 1200e6);
        market2.placeBet(1, 1200e6); // 平局
        console.log("   USER3 bet 1200 USDC on Draw (outcome 1)");
        vm.stopBroadcast();

        // USER4 下注
        vm.startBroadcast(0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6); // USER4 private key
        usdc.approve(address(market2), 600e6);
        market2.placeBet(0, 600e6); // 主胜
        console.log("   USER4 bet 600 USDC on LIV (outcome 0)");

        usdc.approve(address(market3), 1000e6);
        market3.placeBet(2, 1000e6); // 客胜
        console.log("   USER4 bet 1000 USDC on TOT (outcome 2)");
        vm.stopBroadcast();

        // 5. 输出摘要
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("USDC:", address(usdc));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("\nMarkets:");
        console.log("  1. MUN vs MCI:", address(market1));
        console.log("  2. LIV vs ARS:", address(market2));
        console.log("  3. CHE vs TOT:", address(market3));
        console.log("\nTotal Bets: 8");
        console.log("Total Volume: 8600 USDC");
        console.log("========================================");
    }
}
