// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OU_MultiLine.sol";
import "../src/templates/AH_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/templates/ScoreTemplate.sol";
import "../src/templates/PlayerProps_Template.sol";
import "../src/liquidity/LiquidityVault.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/pricing/LMSR.sol";
import "../src/pricing/LinkedLinesController.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title Deploy
 * @notice 统一部署脚本，支持多网络部署
 * @dev 支持的网络：
 *   - anvil: 本地测试链
 *   - eth: 以太坊主网
 *   - arb: Arbitrum One
 *   - base: Base 主网
 *   - bsc: BNB Smart Chain
 *
 * 使用方法：
 *   1. Anvil 本地测试：
 *      forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
 *
 *   2. 主网部署（需要设置 RPC_URL 和 PRIVATE_KEY）：
 *      forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
 *
 * 环境变量：
 *   - PRIVATE_KEY: 部署账户私钥（必需）
 *   - USDC_ADDRESS: USDC 代币地址（主网必需，测试网可选）
 *   - INITIAL_LP_AMOUNT: 初始 LP 金额（默认 1,000,000 USDC）
 */
contract Deploy is Script {
    // 部署配置
    struct DeployConfig {
        address usdc;           // USDC 地址（0x0 表示需要部署 Mock）
        uint256 initialLpAmount; // 初始 LP 金额
        address lpVault;        // LP 金库接收地址
        address promoPool;      // 推广池接收地址
        address insuranceFund;  // 保险基金接收地址
        address treasury;       // 财库接收地址
    }

    // 部署结果
    struct DeployedContracts {
        address usdc;
        address vault;
        address cpmm;
        address feeRouter;
        address referralRegistry;
        address factory;
        address wdlTemplate;
        address ouTemplate;
        address ouMultiLineTemplate;
        address ahTemplate;
        address oddEvenTemplate;
        address scoreTemplate;
        address playerPropsTemplate;
        bytes32 wdlTemplateId;
        bytes32 ouTemplateId;
        bytes32 ouMultiLineTemplateId;
        bytes32 ahTemplateId;
        bytes32 oddEvenTemplateId;
        bytes32 scoreTemplateId;
        bytes32 playerPropsTemplateId;
    }

    // 网络配置（主网 USDC 地址）
    mapping(uint256 => address) public usdcAddresses;

    function setUp() public {
        // Ethereum Mainnet
        usdcAddresses[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        // Arbitrum One
        usdcAddresses[42161] = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        // Base
        usdcAddresses[8453] = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        // BSC
        usdcAddresses[56] = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    }

    function run() external returns (DeployedContracts memory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  PitchOne System Deployment");
        console.log("========================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        console.log("\n");

        // 获取部署配置
        DeployConfig memory config = getDeployConfig(deployer);

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 1. 部署或使用现有 USDC
        // ========================================
        console.log("Step 1: USDC Configuration");
        console.log("----------------------------------------");

        address usdc;
        if (config.usdc == address(0)) {
            // 测试网：部署 Mock USDC
            MockERC20 mockUsdc = new MockERC20("USD Coin", "USDC", 6);
            usdc = address(mockUsdc);
            console.log("Deployed Mock USDC:", usdc);
        } else {
            // 主网：使用现有 USDC
            usdc = config.usdc;
            console.log("Using existing USDC:", usdc);
        }

        // ========================================
        // 2. 部署基础设施合约
        // ========================================
        console.log("\nStep 2: Deploy Infrastructure");
        console.log("----------------------------------------");

        // Deploy LiquidityVault
        LiquidityVault vault = new LiquidityVault(
            IERC20(usdc),
            "PitchOne Liquidity",
            "pLP"
        );
        console.log("LiquidityVault:", address(vault));

        // Deploy SimpleCPMM
        SimpleCPMM cpmm = new SimpleCPMM();
        console.log("SimpleCPMM:", address(cpmm));

        // Deploy ReferralRegistry
        ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
        console.log("ReferralRegistry:", address(referralRegistry));

        // Deploy FeeRouter
        FeeRouter feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: config.lpVault != address(0) ? config.lpVault : address(vault),
                promoPool: config.promoPool != address(0) ? config.promoPool : deployer,
                insuranceFund: config.insuranceFund != address(0) ? config.insuranceFund : deployer,
                treasury: config.treasury != address(0) ? config.treasury : deployer
            }),
            address(referralRegistry)
        );
        console.log("FeeRouter:", address(feeRouter));

        // ========================================
        // 3. 部署 MarketFactory
        // ========================================
        console.log("\nStep 3: Deploy MarketFactory");
        console.log("----------------------------------------");

        MarketFactory_v2 factory = new MarketFactory_v2();
        console.log("MarketFactory_v2:", address(factory));

        // ========================================
        // 4. 部署并注册市场模板（Clone 模式）
        // ========================================
        console.log("\nStep 4: Deploy Market Templates (Clone Mode)");
        console.log("----------------------------------------");

        // WDL Template V2 - 部署未初始化的实现合约
        WDL_Template_V2 wdlTemplate = new WDL_Template_V2();
        bytes32 wdlTemplateId = factory.registerTemplate("WDL", "V2", address(wdlTemplate));
        console.log("WDL_Template_V2 Implementation:", address(wdlTemplate));
        console.log("WDL Template ID:", vm.toString(wdlTemplateId));

        // OU Template - 部署未初始化的实现合约
        OU_Template ouTemplate = new OU_Template();
        bytes32 ouTemplateId = factory.registerTemplate("OU", "1.0.0", address(ouTemplate));
        console.log("OU_Template Implementation:", address(ouTemplate));
        console.log("OU Template ID:", vm.toString(ouTemplateId));

        // OddEven Template - 部署未初始化的实现合约
        OddEven_Template oddEvenTemplate = new OddEven_Template();
        bytes32 oddEvenTemplateId = factory.registerTemplate("OddEven", "1.0.0", address(oddEvenTemplate));
        console.log("OddEven_Template Implementation:", address(oddEvenTemplate));
        console.log("OddEven Template ID:", vm.toString(oddEvenTemplateId));

        // OU_MultiLine Template - 部署未初始化的实现合约
        OU_MultiLine ouMultiLineTemplate = new OU_MultiLine();
        bytes32 ouMultiLineTemplateId = factory.registerTemplate("OU_MultiLine", "1.0.0", address(ouMultiLineTemplate));
        console.log("OU_MultiLine_Template Implementation:", address(ouMultiLineTemplate));
        console.log("OU_MultiLine Template ID:", vm.toString(ouMultiLineTemplateId));

        // AH Template - 部署未初始化的实现合约
        AH_Template ahTemplate = new AH_Template();
        bytes32 ahTemplateId = factory.registerTemplate("AH", "1.0.0", address(ahTemplate));
        console.log("AH_Template Implementation:", address(ahTemplate));
        console.log("AH Template ID:", vm.toString(ahTemplateId));

        // ScoreTemplate - 部署未初始化的实现合约
        ScoreTemplate scoreTemplate = new ScoreTemplate();
        bytes32 scoreTemplateId = factory.registerTemplate("Score", "1.0.0", address(scoreTemplate));
        console.log("ScoreTemplate Implementation:", address(scoreTemplate));
        console.log("Score Template ID:", vm.toString(scoreTemplateId));

        // PlayerProps Template - 部署未初始化的实现合约
        PlayerProps_Template playerPropsTemplate = new PlayerProps_Template();
        bytes32 playerPropsTemplateId = factory.registerTemplate("PlayerProps", "1.0.0", address(playerPropsTemplate));
        console.log("PlayerProps_Template Implementation:", address(playerPropsTemplate));
        console.log("PlayerProps Template ID:", vm.toString(playerPropsTemplateId));

        console.log("\nAll 7 Market Templates Registered!");
        console.log("\nNote: LMSR and LinkedLinesController will be deployed per-market as needed");

        // ========================================
        // 5. 初始化 LP（仅测试网）
        // ========================================
        if (config.usdc == address(0) && config.initialLpAmount > 0) {
            console.log("\nStep 5: Initialize LP (Testnet Only)");
            console.log("----------------------------------------");

            MockERC20 mockUsdc = MockERC20(usdc);
            mockUsdc.mint(deployer, config.initialLpAmount);
            console.log("Minted USDC:", config.initialLpAmount / 1e6, "USDC");

            IERC20(usdc).approve(address(vault), config.initialLpAmount);
            vault.deposit(config.initialLpAmount, deployer);
            console.log("Deposited to Vault:", config.initialLpAmount / 1e6, "USDC");
            console.log("LP Shares received:", vault.balanceOf(deployer) / 1e6);
        }

        vm.stopBroadcast();

        // ========================================
        // 6. 输出部署摘要
        // ========================================
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");
        console.log("\nCore Contracts:");
        console.log("  USDC:", usdc);
        console.log("  LiquidityVault:", address(vault));
        console.log("  SimpleCPMM:", address(cpmm));
        console.log("  FeeRouter:", address(feeRouter));
        console.log("  ReferralRegistry:", address(referralRegistry));
        console.log("  MarketFactory_v2:", address(factory));

        console.log("\nMarket Templates (7 types):");
        console.log("  1. WDL_Template_V2:", address(wdlTemplate));
        console.log("  2. OU_Template:", address(ouTemplate));
        console.log("  3. OU_MultiLine_Template:", address(ouMultiLineTemplate));
        console.log("  4. AH_Template:", address(ahTemplate));
        console.log("  5. OddEven_Template:", address(oddEvenTemplate));
        console.log("  6. ScoreTemplate:", address(scoreTemplate));
        console.log("  7. PlayerProps_Template:", address(playerPropsTemplate));

        console.log("\nTemplate IDs (for CreateAllMarketTypes.s.sol):");
        console.log("  WDL:", vm.toString(wdlTemplateId));
        console.log("  OU:", vm.toString(ouTemplateId));
        console.log("  OU_MultiLine:", vm.toString(ouMultiLineTemplateId));
        console.log("  AH:", vm.toString(ahTemplateId));
        console.log("  OddEven:", vm.toString(oddEvenTemplateId));
        console.log("  Score:", vm.toString(scoreTemplateId));
        console.log("  PlayerProps:", vm.toString(playerPropsTemplateId));

        if (config.usdc == address(0)) {
            console.log("\nVault Status:");
            console.log("  Total Assets:", vault.totalAssets() / 1e6, "USDC");
            console.log("  Available Liquidity:", vault.availableLiquidity() / 1e6, "USDC");
        }

        console.log("\n========================================");
        console.log("  Next Steps:");
        console.log("========================================");
        console.log("1. Update subgraph/subgraph.yaml:");
        console.log("   - Factory address:", address(factory));
        console.log("   - FeeRouter address:", address(feeRouter));
        console.log("2. Run CreateAllMarketTypes.s.sol to create 36 test markets");
        console.log("   (All 7 market types, 3+ markets each)");
        console.log("3. Run SimulateBets.s.sol to generate test data");
        console.log("========================================\n");

        return DeployedContracts({
            usdc: usdc,
            vault: address(vault),
            cpmm: address(cpmm),
            feeRouter: address(feeRouter),
            referralRegistry: address(referralRegistry),
            factory: address(factory),
            wdlTemplate: address(wdlTemplate),
            ouTemplate: address(ouTemplate),
            ouMultiLineTemplate: address(ouMultiLineTemplate),
            ahTemplate: address(ahTemplate),
            oddEvenTemplate: address(oddEvenTemplate),
            scoreTemplate: address(scoreTemplate),
            playerPropsTemplate: address(playerPropsTemplate),
            wdlTemplateId: wdlTemplateId,
            ouTemplateId: ouTemplateId,
            ouMultiLineTemplateId: ouMultiLineTemplateId,
            ahTemplateId: ahTemplateId,
            oddEvenTemplateId: oddEvenTemplateId,
            scoreTemplateId: scoreTemplateId,
            playerPropsTemplateId: playerPropsTemplateId
        });
    }

    /**
     * @notice 获取部署配置
     * @dev 优先从环境变量读取，否则使用默认值
     */
    function getDeployConfig(address deployer) internal view returns (DeployConfig memory) {
        // 尝试从环境变量读取 USDC 地址
        address usdcFromEnv = vm.envOr("USDC_ADDRESS", address(0));

        // 如果未设置，尝试使用网络预设值
        address usdc = usdcFromEnv != address(0)
            ? usdcFromEnv
            : usdcAddresses[block.chainid];

        // 读取初始 LP 金额（默认 1M USDC，仅测试网使用）
        uint256 initialLpAmount = vm.envOr("INITIAL_LP_AMOUNT", uint256(1_000_000 * 1e6));
        if (usdc != address(0)) {
            // 主网不自动初始化 LP
            initialLpAmount = 0;
        }

        // 读取费用接收地址（可选）
        address lpVault = vm.envOr("LP_VAULT_ADDRESS", address(0));
        address promoPool = vm.envOr("PROMO_POOL_ADDRESS", address(0));
        address insuranceFund = vm.envOr("INSURANCE_FUND_ADDRESS", address(0));
        address treasury = vm.envOr("TREASURY_ADDRESS", address(0));

        return DeployConfig({
            usdc: usdc,
            initialLpAmount: initialLpAmount,
            lpVault: lpVault,
            promoPool: promoPool,
            insuranceFund: insuranceFund,
            treasury: treasury
        });
    }
}
