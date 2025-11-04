// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketTemplateRegistry.sol";
import "../src/templates/WDL_Template.sol";
import "../src/oracle/UMAOptimisticOracleAdapter.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../test/mocks/MockERC20.sol";
import "../test/mocks/MockOptimisticOracleV3.sol";

/**
 * @title DeployViaRegistry
 * @notice 通过 Registry 部署完整系统并创建市场
 * @dev 这会触发 MarketCreated 事件,让 Subgraph 正确索引
 *
 * 注意: 由于 Registry.createMarket() 使用 assembly 创建合约的设计限制,
 * 本脚本采用以下策略:
 * 1. 部署所有基础设施
 * 2. 部署 Registry 并注册 WDL_Template
 * 3. 直接部署市场 (使用 new)
 * 4. 手动在 Registry 中注册市场 (需要添加 registerExistingMarket 函数)
 *
 * 或者更简单的方法:
 * 1. 部署基础设施和 Registry
 * 2. 注册 WDL_Template 作为模板
 * 3. 直接部署市场实例
 * 4. Subgraph 监听市场地址的事件而不是 Registry 的 MarketCreated
 */
contract DeployViaRegistry is Script {
    // 已部署的合约
    MockERC20 public usdc;
    MockERC20 public bondCurrency;
    MockOptimisticOracleV3 public mockOO;
    UMAOptimisticOracleAdapter public oracleAdapter;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;
    SimpleCPMM public cpmm;

    // 新部署的合约
    MarketTemplateRegistry public registry;
    WDL_Template public wdlTemplate;
    WDL_Template public market;

    // 市场参数
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // UMA OO 参数
    uint256 constant BOND_AMOUNT = 1000e6;
    uint64 constant LIVENESS = 7200;
    bytes32 constant IDENTIFIER = bytes32("ASSERT_TRUTH");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying via Registry");
        console.log("========================================");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署依赖 (如果还没有)
        console.log("\n1. Deploying dependencies...");
        usdc = new MockERC20("USDC", "USDC", 6);
        console.log("   USDC:", address(usdc));

        bondCurrency = new MockERC20("Bond", "BOND", 6);
        console.log("   Bond Currency:", address(bondCurrency));

        mockOO = new MockOptimisticOracleV3();
        console.log("   Mock OO:", address(mockOO));

        // 部署 ReferralRegistry
        referralRegistry = new ReferralRegistry(deployer);
        console.log("   ReferralRegistry:", address(referralRegistry));

        // 部署 FeeRouter
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: payable(deployer),
            promoPool: payable(deployer),
            insuranceFund: payable(deployer),
            treasury: payable(deployer)
        });
        feeRouter = new FeeRouter(recipients, address(referralRegistry));
        console.log("   FeeRouter:", address(feeRouter));

        // 设置费用分配 (60% LP, 20% Promo, 10% Insurance, 10% Treasury)
        feeRouter.setFeeSplit(6000, 2000, 1000, 1000);

        // 部署定价引擎
        cpmm = new SimpleCPMM();
        console.log("   SimpleCPMM:", address(cpmm));

        // 2. 部署 UMA Adapter
        console.log("\n2. Deploying UMA Oracle Adapter...");
        oracleAdapter = new UMAOptimisticOracleAdapter(
            address(mockOO),
            address(bondCurrency),
            BOND_AMOUNT,
            LIVENESS,
            IDENTIFIER,
            deployer
        );
        console.log("   UMA Adapter:", address(oracleAdapter));

        // 3. 部署 Registry
        console.log("\n3. Deploying MarketTemplateRegistry...");
        registry = new MarketTemplateRegistry();
        console.log("   Registry:", address(registry));

        // 4. 部署 WDL Template (作为模板)
        console.log("\n4. Deploying WDL Template...");
        wdlTemplate = new WDL_Template(
            "TEMPLATE",
            "Template Home",
            "Template Away",
            block.timestamp + 365 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   WDL Template:", address(wdlTemplate));

        // 5. 注册模板
        console.log("\n5. Registering template...");
        bytes32 templateId = keccak256(abi.encodePacked("WDL", "1.0.0"));
        registry.registerTemplate("WDL", "1.0.0", address(wdlTemplate));
        console.log("   Template registered with ID:", vm.toString(templateId));

        // 6. 创建实际市场 (直接部署,而不是通过 Registry.createMarket)
        console.log("\n6. Creating market directly...");

        uint256 kickoffTime = block.timestamp + 24 hours;

        market = new WDL_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   Market created:", address(market));

        // 设置预言机
        market.setResultOracle(address(oracleAdapter));
        console.log("   Oracle set for market");

        // 7. Mint测试代币
        console.log("\n7. Minting test tokens...");
        usdc.mint(deployer, 1000000e6);
        bondCurrency.mint(address(oracleAdapter), 10000e6);
        console.log("   Tokens minted");

        vm.stopBroadcast();

        // 输出总结
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");
        console.log("USDC:", address(usdc));
        console.log("Bond Currency:", address(bondCurrency));
        console.log("Mock OO:", address(mockOO));
        console.log("UMA Adapter:", address(oracleAdapter));
        console.log("ReferralRegistry:", address(referralRegistry));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("Registry:", address(registry));
        console.log("WDL Template:", address(wdlTemplate));
        console.log("Market:", address(market));
        console.log("========================================");
        console.log("Template ID:", vm.toString(templateId));
        console.log("Kickoff Time:", kickoffTime);
        console.log("Liveness:", LIVENESS, "seconds");
        console.log("Bond Amount:", BOND_AMOUNT / 1e6, "USDC");
        console.log("========================================");
        console.log("\nNOTE: Market was deployed directly, not via Registry.createMarket()");
        console.log("Subgraph should monitor the market address directly for events.");
        console.log("========================================");
    }
}
