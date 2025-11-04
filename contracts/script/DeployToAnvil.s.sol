// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployToAnvil
 * @notice 部署完整系统到 Anvil 本地链
 */
contract DeployToAnvil is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  PitchOne System Deployment");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("\n");

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 1. Deploy Infrastructure
        // ========================================
        console.log("Step 1: Deploy Infrastructure Contracts");
        console.log("----------------------------------------");

        // Deploy USDC (Mock)
        MockERC20 usdc = new MockERC20("USD Coin", "USDC", 6);
        console.log("USDC:", address(usdc));

        // Deploy ReferralRegistry
        ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
        console.log("ReferralRegistry:", address(referralRegistry));

        // Deploy FeeRouter
        FeeRouter feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: deployer,
                promoPool: deployer,
                insuranceFund: deployer,
                treasury: deployer
            }),
            address(referralRegistry)
        );
        console.log("FeeRouter:", address(feeRouter));

        // Deploy SimpleCPMM
        SimpleCPMM cpmm = new SimpleCPMM();
        console.log("SimpleCPMM:", address(cpmm));

        // ========================================
        // 2. Deploy MarketFactory_v2
        // ========================================
        console.log("\nStep 2: Deploy MarketFactory_v2");
        console.log("----------------------------------------");

        MarketFactory_v2 factory = new MarketFactory_v2();
        console.log("MarketFactory_v2:", address(factory));

        // ========================================
        // 3. 部署并注册市场模板
        // ========================================
        console.log("\nStep 3: Deploy and Register Market Templates");
        console.log("----------------------------------------");

        // WDL Template
        WDL_Template wdlTemplate = new WDL_Template(
            "TEMPLATE_WDL",
            "Template Home",
            "Template Away",
            block.timestamp + 365 days,
            address(usdc),
            address(feeRouter),
            200, // 2% fee
            2 hours,
            address(cpmm),
            "https://api.pitchone.io/metadata/wdl/{id}"
        );
        bytes32 wdlTemplateId = factory.registerTemplate("WDL", "1.0.0", address(wdlTemplate));
        console.log("WDL Template:", address(wdlTemplate));
        console.log("WDL Template ID:", vm.toString(wdlTemplateId));

        // OU Template
        OU_Template ouTemplate = new OU_Template(
            "TEMPLATE_OU",
            "Template Home",
            "Template Away",
            block.timestamp + 365 days,
            1500, // 1.5 goals
            address(usdc),
            address(feeRouter),
            200,
            2 hours,
            address(cpmm),
            "https://api.pitchone.io/metadata/ou/{id}"
        );
        bytes32 ouTemplateId = factory.registerTemplate("OU", "1.0.0", address(ouTemplate));
        console.log("OU Template:", address(ouTemplate));
        console.log("OU Template ID:", vm.toString(ouTemplateId));

        // OddEven Template
        OddEven_Template oddEvenTemplate = new OddEven_Template(
            "TEMPLATE_ODDEVEN",
            "Template Home",
            "Template Away",
            block.timestamp + 365 days,
            address(usdc),
            address(feeRouter),
            200,
            2 hours,
            address(cpmm),
            "https://api.pitchone.io/metadata/oddeven/{id}"
        );
        bytes32 oddEvenTemplateId = factory.registerTemplate("OddEven", "1.0.0", address(oddEvenTemplate));
        console.log("OddEven Template:", address(oddEvenTemplate));
        console.log("OddEven Template ID:", vm.toString(oddEvenTemplateId));

        vm.stopBroadcast();

        // ========================================
        // 4. Output Deployment Summary
        // ========================================
        console.log("\n========================================");
        console.log("  Deployment Complete!");
        console.log("========================================");
        console.log("\nKey Contract Addresses:");
        console.log("  USDC:", address(usdc));
        console.log("  FeeRouter:", address(feeRouter));
        console.log("  ReferralRegistry:", address(referralRegistry));
        console.log("  SimpleCPMM:", address(cpmm));
        console.log("  MarketFactory_v2:", address(factory));
        console.log("\nTemplate Addresses:");
        console.log("  WDL Template:", address(wdlTemplate));
        console.log("  OU Template:", address(ouTemplate));
        console.log("  OddEven Template:", address(oddEvenTemplate));
        console.log("\nTemplate IDs:");
        console.log("  WDL:", vm.toString(wdlTemplateId));
        console.log("  OU:", vm.toString(ouTemplateId));
        console.log("  OddEven:", vm.toString(oddEvenTemplateId));
        console.log("\nPlease Update Subgraph Config:");
        console.log("  Factory Address:", address(factory));
        console.log("  FeeRouter Address:", address(feeRouter));
        console.log("========================================\n");
    }
}
