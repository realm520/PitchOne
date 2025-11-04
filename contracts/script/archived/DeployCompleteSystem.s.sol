// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployCompleteSystem
 * @notice 完整部署：基础设施 → 模板 → 注册 → 创建市场
 * @dev 工作流:
 *      1. 部署基础合约 (USDC, FeeRouter, CPMM)
 *      2. 部署 Factory
 *      3. 部署模板合约 (WDL, OU, OddEven)
 *      4. 自动注册模板到 Factory
 *      5. 通过 Factory 创建演示市场
 */
contract DeployCompleteSystem is Script {
    // 合约实例
    MarketFactory_v2 public factory;
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;

    // 模板实例（作为实现合约）
    WDL_Template public wdlTemplate;
    OU_Template public ouTemplate;
    OddEven_Template public oddEvenTemplate;

    // 模板 ID
    bytes32 public wdlTemplateId;
    bytes32 public ouTemplateId;
    bytes32 public oddEvenTemplateId;

    // 常量
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
        console.log("Complete System Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ============ 步骤 1: 部署基础设施 ============
        console.log("\n1. Deploying infrastructure...");
        usdc = new MockERC20("USDC", "USDC", 6);
        console.log("   USDC:", address(usdc));

        referralRegistry = new ReferralRegistry(deployer);
        console.log("   ReferralRegistry:", address(referralRegistry));

        feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: deployer,       // LP vault
                promoPool: deployer,     // Promo pool
                insuranceFund: deployer, // Insurance fund
                treasury: deployer       // Treasury
            }),
            address(referralRegistry)
        );
        console.log("   FeeRouter:", address(feeRouter));

        cpmm = new SimpleCPMM();
        console.log("   SimpleCPMM:", address(cpmm));

        // ============ 步骤 2: 部署 Factory ============
        console.log("\n2. Deploying MarketFactory_v2...");
        factory = new MarketFactory_v2();
        console.log("   Factory:", address(factory));

        // ============ 步骤 3: 部署并注册模板 ============
        console.log("\n3. Deploying and registering templates...");

        // 3.1 WDL 模板
        console.log("\n   3.1. WDL Template:");
        wdlTemplate = new WDL_Template(
            "TEMPLATE_WDL",      // matchId (模板用，不实际使用)
            "Template Home",     // homeTeam (占位符)
            "Template Away",     // awayTeam (占位符)
            block.timestamp + 365 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("       Implementation:", address(wdlTemplate));

        wdlTemplateId = factory.registerTemplate("WDL", "1.0.0", address(wdlTemplate));
        console.log("       Registered with ID:", vm.toString(wdlTemplateId));

        // 3.2 OU 模板
        console.log("\n   3.2. OU Template:");
        ouTemplate = new OU_Template(
            "TEMPLATE_OU",
            "Template Home",   // homeTeam (占位符)
            "Template Away",   // awayTeam (占位符)
            block.timestamp + 365 days,
            2500,              // 2.5 goals (line)
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("       Implementation:", address(ouTemplate));

        ouTemplateId = factory.registerTemplate("OU", "1.0.0", address(ouTemplate));
        console.log("       Registered with ID:", vm.toString(ouTemplateId));

        // 3.3 OddEven 模板
        console.log("\n   3.3. OddEven Template:");
        oddEvenTemplate = new OddEven_Template(
            "TEMPLATE_ODDEVEN",
            "Template Home",   // homeTeam (占位符)
            "Template Away",   // awayTeam (占位符)
            block.timestamp + 365 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("       Implementation:", address(oddEvenTemplate));

        oddEvenTemplateId = factory.registerTemplate("OddEven", "1.0.0", address(oddEvenTemplate));
        console.log("       Registered with ID:", vm.toString(oddEvenTemplateId));

        // ============ 步骤 4: 通过 Factory 创建市场 ============
        console.log("\n4. Creating markets via Factory...");

        // 注意: Clone 模式需要模板实现 initialize() 方法
        // 当前 WDL_Template 使用 constructor，需要适配
        // 这里先注释掉市场创建，等模板改造完成

        console.log("   (Skipped - templates need initialize() method for Clone pattern)");

        // ============ 总结 ============
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");
        console.log("Infrastructure:");
        console.log("  USDC:", address(usdc));
        console.log("  FeeRouter:", address(feeRouter));
        console.log("  SimpleCPMM:", address(cpmm));
        console.log("");
        console.log("Factory:");
        console.log("  MarketFactory_v2:", address(factory));
        console.log("");
        console.log("Templates (Implementations):");
        console.log("  WDL:", address(wdlTemplate));
        console.log("    Template ID:", vm.toString(wdlTemplateId));
        console.log("  OU:", address(ouTemplate));
        console.log("    Template ID:", vm.toString(ouTemplateId));
        console.log("  OddEven:", address(oddEvenTemplate));
        console.log("    Template ID:", vm.toString(oddEvenTemplateId));
        console.log("");
        console.log("Next Steps:");
        console.log("  1. Update subgraph.yaml with Factory address:", address(factory));
        console.log("  2. Redeploy Subgraph");
        console.log("  3. Call factory.createMarket() to create new markets");
        console.log("  4. Subgraph will automatically index!");
        console.log("========================================");

        vm.stopBroadcast();
    }
}
