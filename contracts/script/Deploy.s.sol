// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// V2 合约（保留向后兼容）
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template_V2.sol";
import "../src/templates/OU_MultiLine_V2.sol";
import "../src/templates/AH_Template_V2.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../src/templates/PlayerProps_Template_V2.sol";

// V3 核心合约
import "../src/core/Market_V3.sol";
import "../src/core/MarketFactory_v3.sol";
import "../src/core/MarketFactory_V4.sol";
import "../src/core/BettingRouter_V3.sol";

// 定价策略
import "../src/pricing/CPMMStrategy.sol";
import "../src/pricing/LMSRStrategy.sol";
import "../src/pricing/ParimutuelStrategy.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/pricing/LMSR.sol";
import "../src/pricing/ParimutuelPricing.sol";
import "../src/pricing/LinkedLinesController.sol";

// 赛果映射器
import "../src/mappers/WDL_Mapper.sol";
import "../src/mappers/OU_Mapper.sol";
import "../src/mappers/AH_Mapper.sol";
import "../src/mappers/OddEven_Mapper.sol";
import "../src/mappers/Score_Mapper.sol";

// 流动性
import "../src/liquidity/LiquidityVault.sol";
import "../src/liquidity/ERC4626LiquidityProvider.sol";
import "../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../src/liquidity/LiquidityProviderFactory.sol";

// 核心基础设施
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/core/BettingRouter.sol";
import "../src/governance/ParamController.sol";

// Mock
import "../test/mocks/MockERC20.sol";

/**
 * @title Deploy
 * @notice 统一部署脚本，支持 V2 和 V3 架构
 * @dev 支持的网络：
 *   - anvil: 本地测试链
 *   - eth: 以太坊主网
 *   - arb: Arbitrum One
 *   - base: Base 主网
 *   - bsc: BNB Smart Chain
 *
 * 使用方法：
 *   1. Anvil 本地测试（仅 V3）：
 *      DEPLOY_V2=false forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
 *
 *   2. Anvil 本地测试（仅 V2）：
 *      DEPLOY_V3=false forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
 *
 *   3. 主网部署（需要设置 RPC_URL 和 PRIVATE_KEY）：
 *      forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
 *
 * 环境变量：
 *   - PRIVATE_KEY: 部署账户私钥（必需）
 *   - USDC_ADDRESS: USDC 代币地址（主网必需，测试网可选）
 *   - INITIAL_LP_AMOUNT: 初始 LP 金额（默认 1,000,000 USDC）
 *   - DEPLOY_V2: 是否部署 V2 架构（默认 true）
 *   - DEPLOY_V3: 是否部署 V3 架构（默认 true）
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
        bool deployV2;          // 是否部署 V2 架构
        bool deployV3;          // 是否部署 V3 架构
    }

    // V2 部署结果
    struct DeployedContractsV2 {
        address usdc;
        address vault;
        address erc4626Provider;
        address parimutuelProvider;
        address providerFactory;
        address cpmm;
        address parimutuel;
        address feeRouter;
        address referralRegistry;
        address factory;
        address bettingRouter;
        address paramController;
        // V2 模板
        address wdlTemplate;
        address ouTemplate;
        address ouMultiLineTemplate;
        address ahTemplate;
        address oddEvenTemplate;
        address playerPropsTemplate;
        bytes32 wdlTemplateId;
        bytes32 ouTemplateId;
        bytes32 ouMultiLineTemplateId;
        bytes32 ahTemplateId;
        bytes32 oddEvenTemplateId;
        bytes32 playerPropsTemplateId;
    }

    // V3 部署结果
    struct DeployedContractsV3 {
        // 核心合约
        address factory;                // MarketFactory_v3
        address marketImplementation;
        bytes32 marketTemplateId;       // Market_V3 模板 ID
        address factoryV4;
        address bettingRouter;
        // 定价策略
        address cpmmStrategy;
        address lmsrStrategy;
        address parimutuelStrategy;
        // 赛果映射器
        address wdlMapper;
        address ouMapper;
        address ahMapper;
        address oddEvenMapper;
        address scoreMapper;
        // V3 模板 ID
        bytes32 wdlTemplateId;
        bytes32 ouTemplateId;
        bytes32 ahTemplateId;
        bytes32 oddEvenTemplateId;
        bytes32 scoreTemplateId;
    }

    // 完整部署结果
    struct DeployedContracts {
        DeployedContractsV2 v2;
        DeployedContractsV3 v3;
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

        // 获取部署配置
        DeployConfig memory config = getDeployConfig(deployer);
        console.log("Deploy V2:", config.deployV2 ? "Yes" : "No");
        console.log("Deploy V3:", config.deployV3 ? "Yes" : "No");
        console.log("\n");

        vm.startBroadcast(deployerPrivateKey);

        DeployedContracts memory deployed;

        // ========================================
        // 1. 部署或使用现有 USDC
        // ========================================
        console.log("Step 1: USDC Configuration");
        console.log("----------------------------------------");

        address usdc;
        if (config.usdc == address(0)) {
            MockERC20 mockUsdc = new MockERC20("USD Coin", "USDC", 6);
            usdc = address(mockUsdc);
            console.log("Deployed Mock USDC:", usdc);
        } else {
            usdc = config.usdc;
            console.log("Using existing USDC:", usdc);
        }
        deployed.v2.usdc = usdc;

        uint8 usdcDecimals = getTokenDecimals(usdc);
        uint256 usdcUnit = 10 ** usdcDecimals;

        // ========================================
        // 2. 部署 V2 架构（如果启用）
        // ========================================
        if (config.deployV2) {
            _deployV2(deployed, config, usdc, deployer);
        }

        // ========================================
        // 3. 部署 V3 架构（如果启用）
        // ========================================
        if (config.deployV3) {
            _deployV3(deployed, config, usdc, deployer);
        }

        // ========================================
        // 4. 初始化 LP（仅测试网）
        // ========================================
        if (config.usdc == address(0) && config.initialLpAmount > 0) {
            console.log("\nStep: Initialize LP (Testnet Only)");
            console.log("----------------------------------------");

            MockERC20 mockUsdc = MockERC20(usdc);
            mockUsdc.mint(deployer, config.initialLpAmount);
            console.log("Minted USDC:", config.initialLpAmount / usdcUnit, "USDC");

            if (config.deployV2 && deployed.v2.erc4626Provider != address(0)) {
                IERC20(usdc).approve(deployed.v2.erc4626Provider, config.initialLpAmount);
                ERC4626LiquidityProvider(deployed.v2.erc4626Provider).deposit(config.initialLpAmount, deployer);
                console.log("Deposited to ERC4626Provider:", config.initialLpAmount / usdcUnit, "USDC");
            }
        }

        vm.stopBroadcast();

        // ========================================
        // 5. 输出部署摘要
        // ========================================
        _printDeploySummary(deployed, config, usdcUnit);

        // ========================================
        // 6. 生成部署配置文件 (JSON)
        // ========================================
        _writeDeploymentJson(deployer, deployed, config);

        return deployed;
    }

    // ========================================
    // V2 部署逻辑（独立函数，便于后续删除）
    // ========================================
    function _deployV2(
        DeployedContracts memory deployed,
        DeployConfig memory config,
        address usdc,
        address deployer
    ) internal {
        console.log("\n========================================");
        console.log("  V2 Architecture Deployment");
        console.log("========================================");

        // 2.1 部署流动性基础设施
        console.log("\nStep 2.1: Deploy V2 Liquidity Infrastructure");
        console.log("----------------------------------------");

        LiquidityProviderFactory providerFactory = new LiquidityProviderFactory();
        deployed.v2.providerFactory = address(providerFactory);
        console.log("LiquidityProviderFactory:", address(providerFactory));

        ERC4626LiquidityProvider erc4626Provider = new ERC4626LiquidityProvider(
            IERC20(usdc),
            "PitchOne Liquidity",
            "pLP"
        );
        deployed.v2.erc4626Provider = address(erc4626Provider);
        console.log("ERC4626LiquidityProvider:", address(erc4626Provider));

        ParimutuelLiquidityProvider parimutuelProvider = new ParimutuelLiquidityProvider(
            IERC20(usdc)
        );
        deployed.v2.parimutuelProvider = address(parimutuelProvider);
        console.log("ParimutuelLiquidityProvider:", address(parimutuelProvider));

        providerFactory.registerProviderType("ERC4626", address(erc4626Provider));
        providerFactory.registerProviderType("Parimutuel", address(parimutuelProvider));

        LiquidityVault vault = new LiquidityVault(
            IERC20(usdc),
            "PitchOne Liquidity (Deprecated)",
            "pLP-old"
        );
        deployed.v2.vault = address(vault);
        console.log("LiquidityVault (Deprecated):", address(vault));

        // V2 定价引擎
        SimpleCPMM cpmm = new SimpleCPMM(100_000 * 10**6);
        deployed.v2.cpmm = address(cpmm);
        console.log("SimpleCPMM:", address(cpmm));

        ParimutuelPricing parimutuel = new ParimutuelPricing();
        deployed.v2.parimutuel = address(parimutuel);
        console.log("ParimutuelPricing:", address(parimutuel));

        // 2.2 部署核心基础设施
        console.log("\nStep 2.2: Deploy V2 Core Infrastructure");
        console.log("----------------------------------------");

        ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
        deployed.v2.referralRegistry = address(referralRegistry);
        console.log("ReferralRegistry:", address(referralRegistry));

        FeeRouter feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: config.lpVault != address(0) ? config.lpVault : address(erc4626Provider),
                promoPool: config.promoPool != address(0) ? config.promoPool : deployer,
                insuranceFund: config.insuranceFund != address(0) ? config.insuranceFund : deployer,
                treasury: config.treasury != address(0) ? config.treasury : deployer
            }),
            address(referralRegistry)
        );
        deployed.v2.feeRouter = address(feeRouter);
        console.log("FeeRouter:", address(feeRouter));

        referralRegistry.setAuthorizedCaller(address(feeRouter), true);

        // ParamController
        uint256 timelockDelay = block.chainid == 31337 ? 1 hours : 2 days;
        ParamController paramController = new ParamController(deployer, timelockDelay);
        deployed.v2.paramController = address(paramController);
        console.log("ParamController:", address(paramController));

        // 2.3 部署 V2 市场工厂和模板
        console.log("\nStep 2.3: Deploy V2 MarketFactory & Templates");
        console.log("----------------------------------------");

        MarketFactory_v2 factoryV2 = new MarketFactory_v2();
        deployed.v2.factory = address(factoryV2);
        console.log("MarketFactory_v2:", address(factoryV2));

        // V2 BettingRouter
        BettingRouter bettingRouterV1 = new BettingRouter(usdc, address(factoryV2));
        deployed.v2.bettingRouter = address(bettingRouterV1);
        console.log("BettingRouter (V1):", address(bettingRouterV1));

        // V2 模板
        WDL_Template_V2 wdlTemplate = new WDL_Template_V2();
        deployed.v2.wdlTemplateId = factoryV2.registerTemplate("WDL", "V2", address(wdlTemplate));
        deployed.v2.wdlTemplate = address(wdlTemplate);
        console.log("WDL_Template_V2:", address(wdlTemplate));

        OU_Template_V2 ouTemplate = new OU_Template_V2();
        deployed.v2.ouTemplateId = factoryV2.registerTemplate("OU", "V2", address(ouTemplate));
        deployed.v2.ouTemplate = address(ouTemplate);
        console.log("OU_Template_V2:", address(ouTemplate));

        OddEven_Template_V2 oddEvenTemplate = new OddEven_Template_V2();
        deployed.v2.oddEvenTemplateId = factoryV2.registerTemplate("OddEven", "V2", address(oddEvenTemplate));
        deployed.v2.oddEvenTemplate = address(oddEvenTemplate);
        console.log("OddEven_Template_V2:", address(oddEvenTemplate));

        OU_MultiLine_V2 ouMultiLineTemplate = new OU_MultiLine_V2();
        deployed.v2.ouMultiLineTemplateId = factoryV2.registerTemplate("OU_MultiLine", "V2", address(ouMultiLineTemplate));
        deployed.v2.ouMultiLineTemplate = address(ouMultiLineTemplate);
        console.log("OU_MultiLine_V2:", address(ouMultiLineTemplate));

        AH_Template_V2 ahTemplate = new AH_Template_V2();
        deployed.v2.ahTemplateId = factoryV2.registerTemplate("AH", "V2", address(ahTemplate));
        deployed.v2.ahTemplate = address(ahTemplate);
        console.log("AH_Template_V2:", address(ahTemplate));

        PlayerProps_Template_V2 playerPropsTemplate = new PlayerProps_Template_V2();
        deployed.v2.playerPropsTemplateId = factoryV2.registerTemplate("PlayerProps", "V2", address(playerPropsTemplate));
        deployed.v2.playerPropsTemplate = address(playerPropsTemplate);
        console.log("PlayerProps_Template_V2:", address(playerPropsTemplate));

        console.log("\n  V2 Architecture deployed successfully!");
    }

    // ========================================
    // V3 部署逻辑（独立函数）
    // ========================================
    function _deployV3(
        DeployedContracts memory deployed,
        DeployConfig memory config,
        address usdc,
        address deployer
    ) internal {
        console.log("\n========================================");
        console.log("  V3 Architecture Deployment");
        console.log("========================================");

        // 如果没有部署 V2，需要先部署共享基础设施
        address feeRouterAddr = deployed.v2.feeRouter;
        if (feeRouterAddr == address(0)) {
            console.log("\nStep 3.0: Deploy Shared Infrastructure (V3 standalone)");
            console.log("----------------------------------------");

            // 部署 ERC4626 Provider 用于 FeeRouter
            ERC4626LiquidityProvider erc4626Provider = new ERC4626LiquidityProvider(
                IERC20(usdc),
                "PitchOne Liquidity V3",
                "pLP-v3"
            );
            deployed.v2.erc4626Provider = address(erc4626Provider);
            console.log("ERC4626LiquidityProvider:", address(erc4626Provider));

            ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
            deployed.v2.referralRegistry = address(referralRegistry);
            console.log("ReferralRegistry:", address(referralRegistry));

            FeeRouter feeRouter = new FeeRouter(
                FeeRouter.FeeRecipients({
                    lpVault: config.lpVault != address(0) ? config.lpVault : address(erc4626Provider),
                    promoPool: config.promoPool != address(0) ? config.promoPool : deployer,
                    insuranceFund: config.insuranceFund != address(0) ? config.insuranceFund : deployer,
                    treasury: config.treasury != address(0) ? config.treasury : deployer
                }),
                address(referralRegistry)
            );
            deployed.v2.feeRouter = address(feeRouter);
            feeRouterAddr = address(feeRouter);
            console.log("FeeRouter:", address(feeRouter));

            referralRegistry.setAuthorizedCaller(address(feeRouter), true);

            uint256 timelockDelay = block.chainid == 31337 ? 1 hours : 2 days;
            ParamController paramController = new ParamController(deployer, timelockDelay);
            deployed.v2.paramController = address(paramController);
            console.log("ParamController:", address(paramController));
        }

        // 3.1 部署 MarketFactory_v3 和 Market_V3 实现合约
        console.log("\nStep 3.1: Deploy MarketFactory_v3 and Market_V3 Implementation");
        console.log("----------------------------------------");

        // 先部署 Factory
        MarketFactory_v3 factoryV3 = new MarketFactory_v3();
        deployed.v3.factory = address(factoryV3);
        console.log("MarketFactory_v3:", address(factoryV3));

        // 部署 Market_V3 实现，绑定 Factory 地址
        Market_V3 marketImpl = new Market_V3(address(factoryV3));
        deployed.v3.marketImplementation = address(marketImpl);
        console.log("Market_V3 Implementation:", address(marketImpl));

        // 在 Factory 中注册 Market_V3 模板
        bytes32 marketV3TemplateId = factoryV3.registerTemplate(
            "Market_V3",
            "1.0.0",
            address(marketImpl)
        );
        deployed.v3.marketTemplateId = marketV3TemplateId;
        console.log("Market_V3 Template ID:", vm.toString(marketV3TemplateId));

        // 3.2 部署定价策略
        console.log("\nStep 3.2: Deploy Pricing Strategies");
        console.log("----------------------------------------");

        CPMMStrategy cpmmStrategy = new CPMMStrategy();
        deployed.v3.cpmmStrategy = address(cpmmStrategy);
        console.log("CPMMStrategy:", address(cpmmStrategy));

        LMSRStrategy lmsrStrategy = new LMSRStrategy();
        deployed.v3.lmsrStrategy = address(lmsrStrategy);
        console.log("LMSRStrategy:", address(lmsrStrategy));

        ParimutuelStrategy parimutuelStrategy = new ParimutuelStrategy();
        deployed.v3.parimutuelStrategy = address(parimutuelStrategy);
        console.log("ParimutuelStrategy:", address(parimutuelStrategy));

        // 3.3 部署赛果映射器
        console.log("\nStep 3.3: Deploy Result Mappers");
        console.log("----------------------------------------");

        WDL_Mapper wdlMapper = new WDL_Mapper();
        deployed.v3.wdlMapper = address(wdlMapper);
        console.log("WDL_Mapper:", address(wdlMapper));

        OU_Mapper ouMapper = new OU_Mapper(2500); // 默认 2.5 球盘口（精度 1000）
        deployed.v3.ouMapper = address(ouMapper);
        console.log("OU_Mapper (line=2.5):", address(ouMapper));

        AH_Mapper ahMapper = new AH_Mapper(-500); // 默认 -0.5 让球（精度 1000）
        deployed.v3.ahMapper = address(ahMapper);
        console.log("AH_Mapper (handicap=-0.5):", address(ahMapper));

        OddEven_Mapper oddEvenMapper = new OddEven_Mapper();
        deployed.v3.oddEvenMapper = address(oddEvenMapper);
        console.log("OddEven_Mapper:", address(oddEvenMapper));

        Score_Mapper scoreMapper = new Score_Mapper(5); // 最大 5 球
        deployed.v3.scoreMapper = address(scoreMapper);
        console.log("Score_Mapper (maxGoals=5):", address(scoreMapper));

        // 3.4 部署 MarketFactory_V4
        console.log("\nStep 3.4: Deploy MarketFactory_V4");
        console.log("----------------------------------------");

        MarketFactory_V4 factoryV4 = new MarketFactory_V4(
            address(marketImpl),
            usdc,
            deployer
        );
        deployed.v3.factoryV4 = address(factoryV4);
        console.log("MarketFactory_V4:", address(factoryV4));

        // 3.5 部署 BettingRouter_V3（多代币支持）
        BettingRouter_V3 bettingRouter = new BettingRouter_V3(
            address(factoryV4),
            200,     // 2% 默认费率
            deployer // 默认费用接收地址
        );
        // 添加 USDC 到支持的代币列表
        bettingRouter.addToken(usdc, 200, deployer, 1e6, 0);
        deployed.v3.bettingRouter = address(bettingRouter);
        console.log("BettingRouter_V3:", address(bettingRouter));

        // 3.6 配置 Factory V4
        factoryV4.setRouter(address(bettingRouter));
        factoryV4.setKeeper(deployer); // 测试环境使用 deployer
        factoryV4.setOracle(deployer); // 测试环境使用 deployer
        console.log("Factory V4 configured");

        // 3.7 注册定价策略
        factoryV4.registerStrategy("CPMM", address(cpmmStrategy));
        factoryV4.registerStrategy("LMSR", address(lmsrStrategy));
        factoryV4.registerStrategy("PARIMUTUEL", address(parimutuelStrategy));
        console.log("Registered 3 pricing strategies");

        // 3.8 注册映射器
        factoryV4.registerMapper(address(wdlMapper));
        factoryV4.registerMapper(address(ouMapper));
        factoryV4.registerMapper(address(ahMapper));
        factoryV4.registerMapper(address(oddEvenMapper));
        factoryV4.registerMapper(address(scoreMapper));
        console.log("Registered 5 result mappers");

        // 3.9 注册 V3 市场模板
        console.log("\nStep 3.9: Register V3 Market Templates");
        console.log("----------------------------------------");

        _registerV3Templates(deployed, factoryV4, cpmmStrategy, lmsrStrategy, wdlMapper, ouMapper, ahMapper, oddEvenMapper, scoreMapper);

        console.log("\n  V3 Architecture deployed successfully!");
    }

    function _registerV3Templates(
        DeployedContracts memory deployed,
        MarketFactory_V4 factoryV4,
        CPMMStrategy cpmmStrategy,
        LMSRStrategy lmsrStrategy,
        WDL_Mapper wdlMapper,
        OU_Mapper ouMapper,
        AH_Mapper ahMapper,
        OddEven_Mapper oddEvenMapper,
        Score_Mapper scoreMapper
    ) internal {
        // WDL 模板（使用 CPMM，3 个结果）
        IMarket_V3.OutcomeRule[] memory wdlOutcomes = new IMarket_V3.OutcomeRule[](3);
        wdlOutcomes[0] = IMarket_V3.OutcomeRule({
            name: "Home Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        wdlOutcomes[1] = IMarket_V3.OutcomeRule({
            name: "Draw",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        wdlOutcomes[2] = IMarket_V3.OutcomeRule({
            name: "Away Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        bytes32 wdlTemplateIdV3 = keccak256("WDL_V3");
        factoryV4.registerTemplate(
            wdlTemplateIdV3,
            "WDL",
            "CPMM",
            address(cpmmStrategy),
            address(wdlMapper),
            wdlOutcomes,
            100_000 * 10**6 // 100k USDC 初始流动性
        );
        deployed.v3.wdlTemplateId = wdlTemplateIdV3;
        console.log("WDL Template ID:", vm.toString(wdlTemplateIdV3));

        // OU 模板（使用 CPMM，2 个结果）
        IMarket_V3.OutcomeRule[] memory ouOutcomes = new IMarket_V3.OutcomeRule[](2);
        ouOutcomes[0] = IMarket_V3.OutcomeRule({
            name: "Over",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        ouOutcomes[1] = IMarket_V3.OutcomeRule({
            name: "Under",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        bytes32 ouTemplateIdV3 = keccak256("OU_V3");
        factoryV4.registerTemplate(
            ouTemplateIdV3,
            "OU",
            "CPMM",
            address(cpmmStrategy),
            address(ouMapper),
            ouOutcomes,
            100_000 * 10**6
        );
        deployed.v3.ouTemplateId = ouTemplateIdV3;
        console.log("OU Template ID:", vm.toString(ouTemplateIdV3));

        // AH 模板（使用 CPMM，2 个结果）
        IMarket_V3.OutcomeRule[] memory ahOutcomes = new IMarket_V3.OutcomeRule[](2);
        ahOutcomes[0] = IMarket_V3.OutcomeRule({
            name: "Home -0.5",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        ahOutcomes[1] = IMarket_V3.OutcomeRule({
            name: "Away +0.5",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        bytes32 ahTemplateIdV3 = keccak256("AH_V3");
        factoryV4.registerTemplate(
            ahTemplateIdV3,
            "AH",
            "CPMM",
            address(cpmmStrategy),
            address(ahMapper),
            ahOutcomes,
            100_000 * 10**6
        );
        deployed.v3.ahTemplateId = ahTemplateIdV3;
        console.log("AH Template ID:", vm.toString(ahTemplateIdV3));

        // OddEven 模板（使用 CPMM，2 个结果）
        IMarket_V3.OutcomeRule[] memory oddEvenOutcomes = new IMarket_V3.OutcomeRule[](2);
        oddEvenOutcomes[0] = IMarket_V3.OutcomeRule({
            name: "Odd",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        oddEvenOutcomes[1] = IMarket_V3.OutcomeRule({
            name: "Even",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        bytes32 oddEvenTemplateIdV3 = keccak256("OddEven_V3");
        factoryV4.registerTemplate(
            oddEvenTemplateIdV3,
            "OddEven",
            "CPMM",
            address(cpmmStrategy),
            address(oddEvenMapper),
            oddEvenOutcomes,
            100_000 * 10**6
        );
        deployed.v3.oddEvenTemplateId = oddEvenTemplateIdV3;
        console.log("OddEven Template ID:", vm.toString(oddEvenTemplateIdV3));

        // Score 模板（使用 LMSR，36 个结果：0-5 x 0-5）
        IMarket_V3.OutcomeRule[] memory scoreOutcomes = new IMarket_V3.OutcomeRule[](36);
        uint256 idx = 0;
        for (uint256 h = 0; h <= 5; h++) {
            for (uint256 a = 0; a <= 5; a++) {
                scoreOutcomes[idx] = IMarket_V3.OutcomeRule({
                    name: string(abi.encodePacked(vm.toString(h), "-", vm.toString(a))),
                    payoutType: IPricingStrategy.PayoutType.WINNER
                });
                idx++;
            }
        }

        bytes32 scoreTemplateIdV3 = keccak256("Score_V3");
        factoryV4.registerTemplate(
            scoreTemplateIdV3,
            "Score",
            "LMSR",
            address(lmsrStrategy),
            address(scoreMapper),
            scoreOutcomes,
            50_000 * 10**6 // LMSR 需要较少初始流动性
        );
        deployed.v3.scoreTemplateId = scoreTemplateIdV3;
        console.log("Score Template ID:", vm.toString(scoreTemplateIdV3));
    }

    /**
     * @notice 获取部署配置
     */
    function getDeployConfig(address deployer) internal view returns (DeployConfig memory) {
        address usdcFromEnv = vm.envOr("USDC_ADDRESS", address(0));
        address usdc = usdcFromEnv != address(0) ? usdcFromEnv : usdcAddresses[block.chainid];

        uint256 initialLpAmount;
        if (usdc != address(0)) {
            initialLpAmount = 0;
        } else {
            uint8 decimals = 6;
            initialLpAmount = vm.envOr("INITIAL_LP_AMOUNT", uint256(1_000_000 * (10 ** decimals)));
        }

        bool deployV2 = vm.envOr("DEPLOY_V2", true);
        bool deployV3 = vm.envOr("DEPLOY_V3", true);

        return DeployConfig({
            usdc: usdc,
            initialLpAmount: initialLpAmount,
            lpVault: vm.envOr("LP_VAULT_ADDRESS", address(0)),
            promoPool: vm.envOr("PROMO_POOL_ADDRESS", address(0)),
            insuranceFund: vm.envOr("INSURANCE_FUND_ADDRESS", address(0)),
            treasury: vm.envOr("TREASURY_ADDRESS", address(0)),
            deployV2: deployV2,
            deployV3: deployV3
        });
    }

    /**
     * @notice 获取 ERC20 代币的精度
     */
    function getTokenDecimals(address token) internal view returns (uint8) {
        return MockERC20(token).decimals();
    }

    /**
     * @notice 打印部署摘要
     */
    function _printDeploySummary(
        DeployedContracts memory deployed,
        DeployConfig memory config,
        uint256 usdcUnit
    ) internal view {
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");

        console.log("\n--- Shared Contracts ---");
        console.log("  USDC:", deployed.v2.usdc);
        console.log("  FeeRouter:", deployed.v2.feeRouter);
        console.log("  ReferralRegistry:", deployed.v2.referralRegistry);
        console.log("  ParamController:", deployed.v2.paramController);
        console.log("  ERC4626LiquidityProvider:", deployed.v2.erc4626Provider);

        if (config.deployV2) {
            console.log("\n--- V2 Contracts ---");
            console.log("Core:");
            console.log("  MarketFactory_v2:", deployed.v2.factory);
            console.log("  BettingRouter (V1):", deployed.v2.bettingRouter);

            console.log("\nLiquidity:");
            console.log("  LiquidityProviderFactory:", deployed.v2.providerFactory);
            console.log("  ParimutuelLiquidityProvider:", deployed.v2.parimutuelProvider);

            console.log("\nV2 Templates:");
            console.log("  WDL_Template_V2:", deployed.v2.wdlTemplate);
            console.log("  OU_Template_V2:", deployed.v2.ouTemplate);
            console.log("  OU_MultiLine_V2:", deployed.v2.ouMultiLineTemplate);
            console.log("  AH_Template_V2:", deployed.v2.ahTemplate);
            console.log("  OddEven_Template_V2:", deployed.v2.oddEvenTemplate);
            console.log("  PlayerProps_Template_V2:", deployed.v2.playerPropsTemplate);
        }

        if (config.deployV3) {
            console.log("\n--- V3 Contracts ---");
            console.log("Core:");
            console.log("  Market_V3 Implementation:", deployed.v3.marketImplementation);
            console.log("  MarketFactory_V4:", deployed.v3.factoryV4);
            console.log("  BettingRouter_V3:", deployed.v3.bettingRouter);

            console.log("\nPricing Strategies:");
            console.log("  CPMMStrategy:", deployed.v3.cpmmStrategy);
            console.log("  LMSRStrategy:", deployed.v3.lmsrStrategy);
            console.log("  ParimutuelStrategy:", deployed.v3.parimutuelStrategy);

            console.log("\nResult Mappers:");
            console.log("  WDL_Mapper:", deployed.v3.wdlMapper);
            console.log("  OU_Mapper:", deployed.v3.ouMapper);
            console.log("  AH_Mapper:", deployed.v3.ahMapper);
            console.log("  OddEven_Mapper:", deployed.v3.oddEvenMapper);
            console.log("  Score_Mapper:", deployed.v3.scoreMapper);

            console.log("\nV3 Template IDs:");
            console.log("  WDL:", vm.toString(deployed.v3.wdlTemplateId));
            console.log("  OU:", vm.toString(deployed.v3.ouTemplateId));
            console.log("  AH:", vm.toString(deployed.v3.ahTemplateId));
            console.log("  OddEven:", vm.toString(deployed.v3.oddEvenTemplateId));
            console.log("  Score:", vm.toString(deployed.v3.scoreTemplateId));
        }

        console.log("\n========================================");
        console.log("  Next Steps");
        console.log("========================================");
        console.log("1. Update subgraph/subgraph.yaml with:");
        if (config.deployV2) {
            console.log("   - V2 Factory:", deployed.v2.factory);
        }
        console.log("   - FeeRouter:", deployed.v2.feeRouter);
        if (config.deployV3) {
            console.log("   - V4 Factory:", deployed.v3.factoryV4);
        }
        console.log("2. Run CreateAllMarketTypes.s.sol to create test markets");
        console.log("3. Run SimulateBets.s.sol to generate test data");
        console.log("========================================\n");
    }

    /**
     * @notice 生成部署配置 JSON 文件
     */
    function _writeDeploymentJson(
        address deployer,
        DeployedContracts memory deployed,
        DeployConfig memory config
    ) internal {
        string memory networkName;
        if (block.chainid == 31337) {
            networkName = "localhost";
        } else if (block.chainid == 1) {
            networkName = "mainnet";
        } else if (block.chainid == 42161) {
            networkName = "arbitrum";
        } else if (block.chainid == 8453) {
            networkName = "base";
        } else if (block.chainid == 56) {
            networkName = "bsc";
        } else {
            networkName = vm.toString(block.chainid);
        }

        // 构建 shared 对象（共享基础设施）
        string memory shared = "shared";
        vm.serializeAddress(shared, "usdc", deployed.v2.usdc);
        vm.serializeAddress(shared, "feeRouter", deployed.v2.feeRouter);
        vm.serializeAddress(shared, "referralRegistry", deployed.v2.referralRegistry);
        vm.serializeAddress(shared, "paramController", deployed.v2.paramController);
        string memory sharedJson = vm.serializeAddress(shared, "erc4626Provider", deployed.v2.erc4626Provider);

        string memory v2Json = "";
        if (config.deployV2) {
            // 构建 v2.contracts 对象
            string memory v2Contracts = "v2Contracts";
            vm.serializeAddress(v2Contracts, "factory", deployed.v2.factory);
            vm.serializeAddress(v2Contracts, "providerFactory", deployed.v2.providerFactory);
            vm.serializeAddress(v2Contracts, "parimutuelProvider", deployed.v2.parimutuelProvider);
            vm.serializeAddress(v2Contracts, "bettingRouter", deployed.v2.bettingRouter);
            vm.serializeAddress(v2Contracts, "vault", deployed.v2.vault);
            vm.serializeAddress(v2Contracts, "cpmm", deployed.v2.cpmm);
            string memory v2ContractsJson = vm.serializeAddress(v2Contracts, "parimutuel", deployed.v2.parimutuel);

            // 构建 v2.templates 对象
            string memory v2Templates = "v2Templates";
            vm.serializeAddress(v2Templates, "wdl", deployed.v2.wdlTemplate);
            vm.serializeAddress(v2Templates, "ou", deployed.v2.ouTemplate);
            vm.serializeAddress(v2Templates, "ouMultiLine", deployed.v2.ouMultiLineTemplate);
            vm.serializeAddress(v2Templates, "ah", deployed.v2.ahTemplate);
            vm.serializeAddress(v2Templates, "oddEven", deployed.v2.oddEvenTemplate);
            string memory v2TemplatesJson = vm.serializeAddress(v2Templates, "playerProps", deployed.v2.playerPropsTemplate);

            // 构建 v2.templateIds 对象
            string memory v2TemplateIds = "v2TemplateIds";
            vm.serializeBytes32(v2TemplateIds, "wdl", deployed.v2.wdlTemplateId);
            vm.serializeBytes32(v2TemplateIds, "ou", deployed.v2.ouTemplateId);
            vm.serializeBytes32(v2TemplateIds, "ouMultiLine", deployed.v2.ouMultiLineTemplateId);
            vm.serializeBytes32(v2TemplateIds, "ah", deployed.v2.ahTemplateId);
            vm.serializeBytes32(v2TemplateIds, "oddEven", deployed.v2.oddEvenTemplateId);
            string memory v2TemplateIdsJson = vm.serializeBytes32(v2TemplateIds, "playerProps", deployed.v2.playerPropsTemplateId);

            // 构建 v2 对象
            string memory v2 = "v2";
            vm.serializeString(v2, "contracts", v2ContractsJson);
            vm.serializeString(v2, "templates", v2TemplatesJson);
            v2Json = vm.serializeString(v2, "templateIds", v2TemplateIdsJson);
        }

        string memory v3Json = "";
        if (config.deployV3) {
            // 构建 v3.contracts 对象
            string memory v3Contracts = "v3Contracts";
            vm.serializeAddress(v3Contracts, "marketImplementation", deployed.v3.marketImplementation);
            vm.serializeAddress(v3Contracts, "factory", deployed.v3.factoryV4);
            string memory v3ContractsJson = vm.serializeAddress(v3Contracts, "bettingRouter", deployed.v3.bettingRouter);

            // 构建 v3.strategies 对象
            string memory v3Strategies = "v3Strategies";
            vm.serializeAddress(v3Strategies, "cpmm", deployed.v3.cpmmStrategy);
            vm.serializeAddress(v3Strategies, "lmsr", deployed.v3.lmsrStrategy);
            string memory v3StrategiesJson = vm.serializeAddress(v3Strategies, "parimutuel", deployed.v3.parimutuelStrategy);

            // 构建 v3.mappers 对象
            string memory v3Mappers = "v3Mappers";
            vm.serializeAddress(v3Mappers, "wdl", deployed.v3.wdlMapper);
            vm.serializeAddress(v3Mappers, "ou", deployed.v3.ouMapper);
            vm.serializeAddress(v3Mappers, "ah", deployed.v3.ahMapper);
            vm.serializeAddress(v3Mappers, "oddEven", deployed.v3.oddEvenMapper);
            string memory v3MappersJson = vm.serializeAddress(v3Mappers, "score", deployed.v3.scoreMapper);

            // 构建 v3.templateIds 对象
            string memory v3TemplateIds = "v3TemplateIds";
            vm.serializeBytes32(v3TemplateIds, "wdl", deployed.v3.wdlTemplateId);
            vm.serializeBytes32(v3TemplateIds, "ou", deployed.v3.ouTemplateId);
            vm.serializeBytes32(v3TemplateIds, "ah", deployed.v3.ahTemplateId);
            vm.serializeBytes32(v3TemplateIds, "oddEven", deployed.v3.oddEvenTemplateId);
            string memory v3TemplateIdsJson = vm.serializeBytes32(v3TemplateIds, "score", deployed.v3.scoreTemplateId);

            // 构建 v3 对象
            string memory v3 = "v3";
            vm.serializeString(v3, "contracts", v3ContractsJson);
            vm.serializeString(v3, "strategies", v3StrategiesJson);
            vm.serializeString(v3, "mappers", v3MappersJson);
            v3Json = vm.serializeString(v3, "templateIds", v3TemplateIdsJson);
        }

        // 构建根对象
        string memory root = "root";
        vm.serializeString(root, "network", networkName);
        vm.serializeUint(root, "chainId", block.chainid);
        vm.serializeUint(root, "deployedAt", block.number);
        vm.serializeAddress(root, "deployer", deployer);
        vm.serializeString(root, "shared", sharedJson);

        string memory finalJson;
        if (config.deployV2 && config.deployV3) {
            vm.serializeString(root, "v2", v2Json);
            finalJson = vm.serializeString(root, "v3", v3Json);
        } else if (config.deployV2) {
            finalJson = vm.serializeString(root, "v2", v2Json);
        } else if (config.deployV3) {
            finalJson = vm.serializeString(root, "v3", v3Json);
        } else {
            finalJson = vm.serializeString(root, "shared", sharedJson);
        }

        string memory outputPath = string.concat("deployments/", networkName, ".json");
        vm.writeJson(finalJson, outputPath);

        console.log("\n========================================");
        console.log("  Deployment Config Generated");
        console.log("========================================");
        console.log("Output:", outputPath);
        console.log("========================================\n");
    }
}
