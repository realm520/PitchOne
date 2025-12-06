// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template_V2.sol";
import "../src/templates/OU_MultiLine_V2.sol";
import "../src/templates/AH_Template_V2.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../src/templates/ScoreTemplate_V2.sol";
import "../src/templates/PlayerProps_Template_V2.sol";
import "../src/liquidity/LiquidityVault.sol"; // Deprecated - use ERC4626LiquidityProvider
import "../src/liquidity/ERC4626LiquidityProvider.sol";
import "../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../src/liquidity/LiquidityProviderFactory.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/governance/ParamController.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/pricing/LMSR.sol";
import "../src/pricing/ParimutuelPricing.sol";
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
        address vault; // Deprecated - kept for backward compatibility
        address erc4626Provider; // New: ERC4626LiquidityProvider
        address parimutuelProvider; // New: ParimutuelLiquidityProvider
        address providerFactory; // New: LiquidityProviderFactory
        address cpmm;
        address parimutuel;
        address feeRouter;
        address referralRegistry;
        address factory;
        address paramController; // ParamController for governance
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
        console.log("Balance:", deployer.balance / 1 ether, "ETH");
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

        // 获取 USDC 精度
        uint8 usdcDecimals = getTokenDecimals(usdc);
        uint256 usdcUnit = 10 ** usdcDecimals;

        // ========================================
        // 2. 部署流动性提供者基础设施
        // ========================================
        console.log("\nStep 2: Deploy Liquidity Provider Infrastructure");
        console.log("----------------------------------------");

        // Deploy LiquidityProviderFactory
        LiquidityProviderFactory providerFactory = new LiquidityProviderFactory();
        console.log("LiquidityProviderFactory:", address(providerFactory));

        // Deploy ERC4626LiquidityProvider 作为默认 Provider
        ERC4626LiquidityProvider erc4626Provider = new ERC4626LiquidityProvider(
            IERC20(usdc),
            "PitchOne Liquidity",
            "pLP"
        );
        console.log("ERC4626LiquidityProvider (default):", address(erc4626Provider));

        // Deploy ParimutuelLiquidityProvider 作为备用 Provider
        ParimutuelLiquidityProvider parimutuelProvider = new ParimutuelLiquidityProvider(
            IERC20(usdc)
        );
        console.log("ParimutuelLiquidityProvider:", address(parimutuelProvider));

        // 注册 Provider 类型到 Factory
        providerFactory.registerProviderType("ERC4626", address(erc4626Provider));
        providerFactory.registerProviderType("Parimutuel", address(parimutuelProvider));
        console.log("Registered 2 Provider types to Factory");

        // Deploy deprecated LiquidityVault for backward compatibility
        LiquidityVault vault = new LiquidityVault(
            IERC20(usdc),
            "PitchOne Liquidity (Deprecated)",
            "pLP-old"
        );
        console.log("LiquidityVault (Deprecated):", address(vault));

        // Deploy SimpleCPMM (默认储备: 100,000 USDC)
        SimpleCPMM cpmm = new SimpleCPMM(100_000 * 10**6);
        console.log("SimpleCPMM:", address(cpmm));

        // Deploy ParimutuelPricing (零虚拟储备模式)
        ParimutuelPricing parimutuel = new ParimutuelPricing();
        console.log("ParimutuelPricing:", address(parimutuel));

        // Deploy ReferralRegistry
        ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
        console.log("ReferralRegistry:", address(referralRegistry));

        // Deploy FeeRouter (使用新的 ERC4626Provider)
        FeeRouter feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: config.lpVault != address(0) ? config.lpVault : address(erc4626Provider),
                promoPool: config.promoPool != address(0) ? config.promoPool : deployer,
                insuranceFund: config.insuranceFund != address(0) ? config.insuranceFund : deployer,
                treasury: config.treasury != address(0) ? config.treasury : deployer
            }),
            address(referralRegistry)
        );
        console.log("FeeRouter:", address(feeRouter));

        // 授权 FeeRouter 调用 ReferralRegistry
        referralRegistry.setAuthorizedCaller(address(feeRouter), true);
        console.log("Authorized FeeRouter to call ReferralRegistry");

        // ========================================
        // 2.5. 部署 ParamController (治理合约)
        // ========================================
        console.log("\nStep 2.5: Deploy ParamController");
        console.log("----------------------------------------");

        // Timelock 延迟：测试环境 1 小时，生产环境建议 2 天
        uint256 timelockDelay = block.chainid == 31337 ? 1 hours : 2 days;

        ParamController paramController = new ParamController(
            deployer,  // admin (Safe multisig in production)
            timelockDelay
        );
        console.log("ParamController:", address(paramController));
        console.log("Timelock Delay:", timelockDelay / 3600, "hours");

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

        // OU Template V2 - 部署未初始化的实现合约
        OU_Template_V2 ouTemplate = new OU_Template_V2();
        bytes32 ouTemplateId = factory.registerTemplate("OU", "V2", address(ouTemplate));
        console.log("OU_Template_V2 Implementation:", address(ouTemplate));
        console.log("OU Template ID:", vm.toString(ouTemplateId));

        // OddEven Template V2 - 部署未初始化的实现合约
        OddEven_Template_V2 oddEvenTemplate = new OddEven_Template_V2();
        bytes32 oddEvenTemplateId = factory.registerTemplate("OddEven", "V2", address(oddEvenTemplate));
        console.log("OddEven_Template_V2 Implementation:", address(oddEvenTemplate));
        console.log("OddEven Template ID:", vm.toString(oddEvenTemplateId));

        // OU_MultiLine Template V2 - 部署未初始化的实现合约
        OU_MultiLine_V2 ouMultiLineTemplate = new OU_MultiLine_V2();
        bytes32 ouMultiLineTemplateId = factory.registerTemplate("OU_MultiLine", "V2", address(ouMultiLineTemplate));
        console.log("OU_MultiLine_V2 Implementation:", address(ouMultiLineTemplate));
        console.log("OU_MultiLine Template ID:", vm.toString(ouMultiLineTemplateId));

        // AH Template V2 - 部署未初始化的实现合约
        AH_Template_V2 ahTemplate = new AH_Template_V2();
        bytes32 ahTemplateId = factory.registerTemplate("AH", "V2", address(ahTemplate));
        console.log("AH_Template_V2 Implementation:", address(ahTemplate));
        console.log("AH Template ID:", vm.toString(ahTemplateId));

        // ScoreTemplate V2 - 暂时跳过部署（合约大小超过 24KB 限制）
        // TODO: 优化 ScoreTemplate_V2 大小后重新启用
        // ScoreTemplate_V2 scoreTemplate = new ScoreTemplate_V2();
        // bytes32 scoreTemplateId = factory.registerTemplate("Score", "V2", address(scoreTemplate));
        address scoreTemplate = address(0);
        bytes32 scoreTemplateId = bytes32(0);
        console.log("ScoreTemplate_V2: SKIPPED (exceeds 24KB limit)");

        // PlayerProps Template V2 - 部署未初始化的实现合约
        PlayerProps_Template_V2 playerPropsTemplate = new PlayerProps_Template_V2();
        bytes32 playerPropsTemplateId = factory.registerTemplate("PlayerProps", "V2", address(playerPropsTemplate));
        console.log("PlayerProps_Template Implementation:", address(playerPropsTemplate));
        console.log("PlayerProps Template ID:", vm.toString(playerPropsTemplateId));

        console.log("\n6 out of 7 Market Templates Registered!");
        console.log("(ScoreTemplate_V2 temporarily skipped due to 24KB size limit)");
        console.log("\nNote: LMSR and LinkedLinesController will be deployed per-market as needed");

        // ========================================
        // 5. 初始化 LP（仅测试网）
        // ========================================
        if (config.usdc == address(0) && config.initialLpAmount > 0) {
            console.log("\nStep 5: Initialize LP (Testnet Only)");
            console.log("----------------------------------------");

            MockERC20 mockUsdc = MockERC20(usdc);
            mockUsdc.mint(deployer, config.initialLpAmount);
            console.log("Minted USDC:", config.initialLpAmount / usdcUnit, "USDC");

            // 存入 ERC4626Provider
            IERC20(usdc).approve(address(erc4626Provider), config.initialLpAmount);
            erc4626Provider.deposit(config.initialLpAmount, deployer);
            console.log("Deposited to ERC4626Provider:", config.initialLpAmount / usdcUnit, "USDC");
            console.log("LP Shares received:", erc4626Provider.balanceOf(deployer) / usdcUnit);

            console.log("\nProvider Status:");
            console.log("  Total Liquidity:", erc4626Provider.totalLiquidity() / usdcUnit, "USDC");
            console.log("  Available Liquidity:", erc4626Provider.availableLiquidity() / usdcUnit, "USDC");
            console.log("  Utilization Rate:", erc4626Provider.utilizationRate() / 100, "%");
        }

        vm.stopBroadcast();

        // ========================================
        // 6. 输出部署摘要
        // ========================================
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");
        console.log("\nLiquidity Provider Contracts:");
        console.log("  LiquidityProviderFactory:", address(providerFactory));
        console.log("  ERC4626LiquidityProvider (default):", address(erc4626Provider));
        console.log("  ParimutuelLiquidityProvider:", address(parimutuelProvider));
        console.log("  LiquidityVault (Deprecated):", address(vault));

        console.log("\nCore Contracts:");
        console.log("  USDC:", usdc);
        console.log("  SimpleCPMM:", address(cpmm));
        console.log("  ParimutuelPricing:", address(parimutuel));
        console.log("  FeeRouter:", address(feeRouter));
        console.log("  ReferralRegistry:", address(referralRegistry));
        console.log("  MarketFactory_v2:", address(factory));

        console.log("\nMarket Templates (6 out of 7 deployed):");
        console.log("  1. WDL_Template_V2:", address(wdlTemplate));
        console.log("  2. OU_Template:", address(ouTemplate));
        console.log("  3. OU_MultiLine_Template:", address(ouMultiLineTemplate));
        console.log("  4. AH_Template:", address(ahTemplate));
        console.log("  5. OddEven_Template:", address(oddEvenTemplate));
        console.log("  6. ScoreTemplate: SKIPPED (24KB limit)");
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
            console.log("\nERC4626Provider Status:");
            console.log("  Total Assets:", erc4626Provider.totalAssets() / usdcUnit, "USDC");
            console.log("  Available Liquidity:", erc4626Provider.availableLiquidity() / usdcUnit, "USDC");
            console.log("  Utilization Rate:", erc4626Provider.utilizationRate() / 100, "%");
        }

        console.log("\n========================================");
        console.log("  Next Steps:");
        console.log("========================================");
        console.log("1. Update subgraph/subgraph.yaml:");
        console.log("   - Factory address:", address(factory));
        console.log("   - FeeRouter address:", address(feeRouter));
        console.log("2. Run CreateAllMarketTypes.s.sol to create test markets");
        console.log("   (6 out of 7 market types, 3 markets each = 18 total)");
        console.log("3. Run SimulateBets.s.sol to generate test data");
        console.log("========================================\n");

        return DeployedContracts({
            usdc: usdc,
            vault: address(vault), // Deprecated
            erc4626Provider: address(erc4626Provider),
            parimutuelProvider: address(parimutuelProvider),
            providerFactory: address(providerFactory),
            cpmm: address(cpmm),
            parimutuel: address(parimutuel),
            feeRouter: address(feeRouter),
            referralRegistry: address(referralRegistry),
            factory: address(factory),
            paramController: address(paramController),
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
        uint256 initialLpAmount;
        if (usdc != address(0)) {
            // 主网不自动初始化 LP
            initialLpAmount = 0;
        } else {
            // 测试网：USDC 精度默认为 6
            uint8 decimals = 6;
            // 1M USDC 足够支持 21 个市场（每个市场借 10k USDC，总需求 210k）
            initialLpAmount = vm.envOr("INITIAL_LP_AMOUNT", uint256(1_000_000 * (10 ** decimals)));
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

    /**
     * @notice 获取 ERC20 代币的精度
     * @param token 代币地址
     * @return 代币精度（decimals）
     */
    function getTokenDecimals(address token) internal view returns (uint8) {
        // 调用 decimals() 方法，如果失败则直接 revert
        return MockERC20(token).decimals();
    }
}
