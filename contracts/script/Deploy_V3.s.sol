// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// V3 核心合约
import "../src/core/Market_V3.sol";
import "../src/core/MarketFactory_v3.sol";
import "../src/core/MarketFactory_V4.sol";
import "../src/core/BettingRouter_V3.sol";

// 定价策略
import "../src/pricing/CPMMStrategy.sol";
import "../src/pricing/LMSRStrategy.sol";
import "../src/pricing/ParimutuelStrategy.sol";

// 赛果映射器
import "../src/mappers/WDL_Mapper.sol";
import "../src/mappers/OU_Mapper.sol";
import "../src/mappers/AH_Mapper.sol";
import "../src/mappers/OddEven_Mapper.sol";
import "../src/mappers/Score_Mapper.sol";

// 流动性
import "../src/liquidity/LiquidityVault_V3.sol";

// 核心基础设施
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/governance/ParamController.sol";

// Mock
import "../test/mocks/MockERC20.sol";

/**
 * @title Deploy_V3
 * @notice V3 架构独立部署脚本
 * @dev 仅部署 V3 相关合约，不包含 V2 模板
 *
 * 支持的网络：
 *   - anvil: 本地测试链
 *   - eth: 以太坊主网
 *   - arb: Arbitrum One
 *   - base: Base 主网
 *   - bsc: BNB Smart Chain
 *
 * 使用方法：
 *   1. Anvil 本地测试：
 *      PRIVATE_KEY=0x... forge script script/Deploy_V3.s.sol:Deploy_V3 \
 *        --rpc-url http://localhost:8545 --broadcast
 *
 *   2. 主网部署：
 *      forge script script/Deploy_V3.s.sol:Deploy_V3 \
 *        --rpc-url $RPC_URL --broadcast --verify
 *
 * 环境变量：
 *   - PRIVATE_KEY: 部署账户私钥（必需）
 *   - USDC_ADDRESS: USDC 代币地址（主网必需，测试网可选）
 *   - INITIAL_LP_AMOUNT: 初始 LP 金额（默认 1,000,000 USDC）
 */
contract Deploy_V3 is Script {
    // 部署配置
    struct DeployConfig {
        address usdc;              // USDC 地址（0x0 表示需要部署 Mock）
        uint256 initialLpAmount;   // 初始 LP 金额
        address lpVault;           // LP 金库接收地址
        address promoPool;         // 推广池接收地址
        address insuranceFund;     // 保险基金接收地址
        address treasury;          // 财库接收地址
    }

    // 部署结果
    struct DeployedContracts {
        // 基础代币
        address usdc;

        // 共享基础设施
        address feeRouter;
        address referralRegistry;
        address paramController;

        // V3 核心合约
        address factoryV3;              // MarketFactory_v3
        address marketImplementation;   // Market_V3 实现
        bytes32 marketTemplateId;       // Market_V3 模板 ID

        address factoryV4;              // MarketFactory_V4
        address bettingRouter;          // BettingRouter_V3
        address liquidityVault;         // LiquidityVault_V3

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

        // V3 模板 ID (用于 Factory V4)
        bytes32 wdlTemplateId;
        bytes32 ouTemplateId;
        bytes32 ahTemplateId;
        bytes32 oddEvenTemplateId;
        bytes32 scoreTemplateId;
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
        console.log("  PitchOne V3 Architecture Deployment");
        console.log("========================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1 ether, "ETH");

        // 获取部署配置
        DeployConfig memory config = getDeployConfig(deployer);
        console.log("\n");

        vm.startBroadcast(deployerPrivateKey);

        DeployedContracts memory deployed;

        // ========================================
        // 1. 部署或使用现有 USDC
        // ========================================
        console.log("Step 1: USDC Configuration");
        console.log("----------------------------------------");

        if (config.usdc == address(0)) {
            MockERC20 mockUsdc = new MockERC20("USD Coin", "USDC", 6);
            deployed.usdc = address(mockUsdc);
            console.log("Deployed Mock USDC:", deployed.usdc);
        } else {
            deployed.usdc = config.usdc;
            console.log("Using existing USDC:", deployed.usdc);
        }

        uint8 usdcDecimals = getTokenDecimals(deployed.usdc);
        uint256 usdcUnit = 10 ** usdcDecimals;

        // ========================================
        // 2. 部署共享基础设施
        // ========================================
        console.log("\nStep 2: Deploy Shared Infrastructure");
        console.log("----------------------------------------");

        // LiquidityVault_V3
        LiquidityVault_V3 liquidityVault = new LiquidityVault_V3(
            IERC20(deployed.usdc),
            "PitchOne LP V3",
            "pLP-V3"
        );
        deployed.liquidityVault = address(liquidityVault);
        console.log("LiquidityVault_V3:", address(liquidityVault));

        // ReferralRegistry
        ReferralRegistry referralRegistry = new ReferralRegistry(deployer);
        deployed.referralRegistry = address(referralRegistry);
        console.log("ReferralRegistry:", address(referralRegistry));

        // FeeRouter
        FeeRouter feeRouter = new FeeRouter(
            FeeRouter.FeeRecipients({
                lpVault: config.lpVault != address(0) ? config.lpVault : address(liquidityVault),
                promoPool: config.promoPool != address(0) ? config.promoPool : deployer,
                insuranceFund: config.insuranceFund != address(0) ? config.insuranceFund : deployer,
                treasury: config.treasury != address(0) ? config.treasury : deployer
            }),
            address(referralRegistry)
        );
        deployed.feeRouter = address(feeRouter);
        console.log("FeeRouter:", address(feeRouter));

        referralRegistry.setAuthorizedCaller(address(feeRouter), true);

        // ParamController
        uint256 timelockDelay = block.chainid == 31337 ? 1 hours : 2 days;
        ParamController paramController = new ParamController(deployer, timelockDelay);
        deployed.paramController = address(paramController);
        console.log("ParamController:", address(paramController));

        // ========================================
        // 3. 部署 MarketFactory_v3 和 Market_V3 实现
        // ========================================
        console.log("\nStep 3: Deploy MarketFactory_v3 and Market_V3");
        console.log("----------------------------------------");

        MarketFactory_v3 factoryV3 = new MarketFactory_v3();
        deployed.factoryV3 = address(factoryV3);
        console.log("MarketFactory_v3:", address(factoryV3));

        Market_V3 marketImpl = new Market_V3(address(factoryV3));
        deployed.marketImplementation = address(marketImpl);
        console.log("Market_V3 Implementation:", address(marketImpl));

        bytes32 marketV3TemplateId = factoryV3.registerTemplate(
            "Market_V3",
            "1.0.0",
            address(marketImpl)
        );
        deployed.marketTemplateId = marketV3TemplateId;
        console.log("Market_V3 Template ID:", vm.toString(marketV3TemplateId));

        // ========================================
        // 4. 部署定价策略
        // ========================================
        console.log("\nStep 4: Deploy Pricing Strategies");
        console.log("----------------------------------------");

        CPMMStrategy cpmmStrategy = new CPMMStrategy();
        deployed.cpmmStrategy = address(cpmmStrategy);
        console.log("CPMMStrategy:", address(cpmmStrategy));

        LMSRStrategy lmsrStrategy = new LMSRStrategy();
        deployed.lmsrStrategy = address(lmsrStrategy);
        console.log("LMSRStrategy:", address(lmsrStrategy));

        ParimutuelStrategy parimutuelStrategy = new ParimutuelStrategy();
        deployed.parimutuelStrategy = address(parimutuelStrategy);
        console.log("ParimutuelStrategy:", address(parimutuelStrategy));

        // ========================================
        // 5. 部署赛果映射器
        // ========================================
        console.log("\nStep 5: Deploy Result Mappers");
        console.log("----------------------------------------");

        WDL_Mapper wdlMapper = new WDL_Mapper();
        deployed.wdlMapper = address(wdlMapper);
        console.log("WDL_Mapper:", address(wdlMapper));

        OU_Mapper ouMapper = new OU_Mapper(2500); // 默认 2.5 球盘口
        deployed.ouMapper = address(ouMapper);
        console.log("OU_Mapper (line=2.5):", address(ouMapper));

        AH_Mapper ahMapper = new AH_Mapper(-500); // 默认 -0.5 让球
        deployed.ahMapper = address(ahMapper);
        console.log("AH_Mapper (handicap=-0.5):", address(ahMapper));

        OddEven_Mapper oddEvenMapper = new OddEven_Mapper();
        deployed.oddEvenMapper = address(oddEvenMapper);
        console.log("OddEven_Mapper:", address(oddEvenMapper));

        Score_Mapper scoreMapper = new Score_Mapper(5); // 最大 5 球
        deployed.scoreMapper = address(scoreMapper);
        console.log("Score_Mapper (maxGoals=5):", address(scoreMapper));

        // ========================================
        // 6. 部署 MarketFactory_V4
        // ========================================
        console.log("\nStep 6: Deploy MarketFactory_V4");
        console.log("----------------------------------------");

        MarketFactory_V4 factoryV4 = new MarketFactory_V4(
            address(marketImpl),
            deployed.usdc,
            deployer
        );
        deployed.factoryV4 = address(factoryV4);
        console.log("MarketFactory_V4:", address(factoryV4));

        // ========================================
        // 7. 部署 BettingRouter_V3
        // ========================================
        console.log("\nStep 7: Deploy BettingRouter_V3");
        console.log("----------------------------------------");

        BettingRouter_V3 router = new BettingRouter_V3(
            address(factoryV4),
            200,     // 2% 默认费率
            deployer // 默认费用接收地址
        );
        deployed.bettingRouter = address(router);
        console.log("BettingRouter_V3:", address(router));

        // 添加 USDC 到支持的代币列表
        router.addToken(
            deployed.usdc,
            200,     // 2% 费率
            deployer, // 费用接收地址
            1e6,     // 最小下注 1 USDC
            0        // 无最大限制
        );
        console.log("Added USDC to supported tokens");

        // 配置 Factory V4
        factoryV4.setRouter(address(router));
        factoryV4.setKeeper(deployer); // 测试环境使用 deployer
        factoryV4.setOracle(deployer); // 测试环境使用 deployer
        console.log("Factory V4 configured");

        // ========================================
        // 8. 注册定价策略和映射器
        // ========================================
        console.log("\nStep 8: Register Strategies and Mappers");
        console.log("----------------------------------------");

        factoryV4.registerStrategy("CPMM", address(cpmmStrategy));
        factoryV4.registerStrategy("LMSR", address(lmsrStrategy));
        factoryV4.registerStrategy("PARIMUTUEL", address(parimutuelStrategy));
        console.log("Registered 3 pricing strategies");

        factoryV4.registerMapper(address(wdlMapper));
        factoryV4.registerMapper(address(ouMapper));
        factoryV4.registerMapper(address(ahMapper));
        factoryV4.registerMapper(address(oddEvenMapper));
        factoryV4.registerMapper(address(scoreMapper));
        console.log("Registered 5 result mappers");

        // ========================================
        // 9. 注册 V3 市场模板
        // ========================================
        console.log("\nStep 9: Register V3 Market Templates");
        console.log("----------------------------------------");

        _registerV3Templates(
            deployed,
            factoryV4,
            cpmmStrategy,
            lmsrStrategy,
            wdlMapper,
            ouMapper,
            ahMapper,
            oddEvenMapper,
            scoreMapper
        );

        // ========================================
        // 10. 初始化 LP（仅测试网）
        // ========================================
        if (config.usdc == address(0) && config.initialLpAmount > 0) {
            console.log("\nStep 10: Initialize LP (Testnet Only)");
            console.log("----------------------------------------");

            MockERC20 mockUsdc = MockERC20(deployed.usdc);
            mockUsdc.mint(deployer, config.initialLpAmount);
            console.log("Minted USDC:", config.initialLpAmount / usdcUnit, "USDC");

            IERC20(deployed.usdc).approve(address(liquidityVault), config.initialLpAmount);
            liquidityVault.deposit(config.initialLpAmount, deployer);
            console.log("Deposited to LiquidityVault_V3:", config.initialLpAmount / usdcUnit, "USDC");
        }

        vm.stopBroadcast();

        // ========================================
        // 11. 输出部署摘要
        // ========================================
        _printDeploySummary(deployed);

        // ========================================
        // 12. 生成部署配置文件 (JSON)
        // ========================================
        _writeDeploymentJson(deployer, deployed, config);

        return deployed;
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
        deployed.wdlTemplateId = wdlTemplateIdV3;
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
        deployed.ouTemplateId = ouTemplateIdV3;
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
        deployed.ahTemplateId = ahTemplateIdV3;
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
        deployed.oddEvenTemplateId = oddEvenTemplateIdV3;
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
        deployed.scoreTemplateId = scoreTemplateIdV3;
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

        return DeployConfig({
            usdc: usdc,
            initialLpAmount: initialLpAmount,
            lpVault: vm.envOr("LP_VAULT_ADDRESS", address(0)),
            promoPool: vm.envOr("PROMO_POOL_ADDRESS", address(0)),
            insuranceFund: vm.envOr("INSURANCE_FUND_ADDRESS", address(0)),
            treasury: vm.envOr("TREASURY_ADDRESS", address(0))
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
        DeployedContracts memory deployed
    ) internal view {
        console.log("\n========================================");
        console.log("  V3 Deployment Summary");
        console.log("========================================");

        console.log("\n--- Base Token ---");
        console.log("  USDC:", deployed.usdc);

        console.log("\n--- Shared Infrastructure ---");
        console.log("  FeeRouter:", deployed.feeRouter);
        console.log("  ReferralRegistry:", deployed.referralRegistry);
        console.log("  ParamController:", deployed.paramController);
        console.log("  LiquidityVault_V3:", deployed.liquidityVault);

        console.log("\n--- Core Contracts ---");
        console.log("  MarketFactory_v3:", deployed.factoryV3);
        console.log("  Market_V3 Implementation:", deployed.marketImplementation);
        console.log("  MarketFactory_V4:", deployed.factoryV4);
        console.log("  BettingRouter_V3:", deployed.bettingRouter);

        console.log("\n--- Pricing Strategies ---");
        console.log("  CPMMStrategy:", deployed.cpmmStrategy);
        console.log("  LMSRStrategy:", deployed.lmsrStrategy);
        console.log("  ParimutuelStrategy:", deployed.parimutuelStrategy);

        console.log("\n--- Result Mappers ---");
        console.log("  WDL_Mapper:", deployed.wdlMapper);
        console.log("  OU_Mapper:", deployed.ouMapper);
        console.log("  AH_Mapper:", deployed.ahMapper);
        console.log("  OddEven_Mapper:", deployed.oddEvenMapper);
        console.log("  Score_Mapper:", deployed.scoreMapper);

        console.log("\n--- Template IDs ---");
        console.log("  WDL:", vm.toString(deployed.wdlTemplateId));
        console.log("  OU:", vm.toString(deployed.ouTemplateId));
        console.log("  AH:", vm.toString(deployed.ahTemplateId));
        console.log("  OddEven:", vm.toString(deployed.oddEvenTemplateId));
        console.log("  Score:", vm.toString(deployed.scoreTemplateId));

        console.log("\n========================================");
        console.log("  Next Steps");
        console.log("========================================");
        console.log("1. Update subgraph/subgraph.yaml with:");
        console.log("   - Factory V4:", deployed.factoryV4);
        console.log("   - FeeRouter:", deployed.feeRouter);
        console.log("2. Run CreateAllMarketTypes_V3.s.sol to create test markets");
        console.log("3. Run SimulateBets_V3.s.sol to generate test data");
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
            networkName = "localhost_v3";
        } else if (block.chainid == 1) {
            networkName = "mainnet_v3";
        } else if (block.chainid == 42161) {
            networkName = "arbitrum_v3";
        } else if (block.chainid == 8453) {
            networkName = "base_v3";
        } else if (block.chainid == 56) {
            networkName = "bsc_v3";
        } else {
            networkName = string.concat(vm.toString(block.chainid), "_v3");
        }

        // 构建 contracts 对象
        string memory contracts = "contracts";
        vm.serializeAddress(contracts, "usdc", deployed.usdc);
        vm.serializeAddress(contracts, "feeRouter", deployed.feeRouter);
        vm.serializeAddress(contracts, "referralRegistry", deployed.referralRegistry);
        vm.serializeAddress(contracts, "paramController", deployed.paramController);
        vm.serializeAddress(contracts, "liquidityVault", deployed.liquidityVault);
        vm.serializeAddress(contracts, "factoryV3", deployed.factoryV3);
        vm.serializeAddress(contracts, "marketImplementation", deployed.marketImplementation);
        vm.serializeAddress(contracts, "factory", deployed.factoryV4);
        string memory contractsJson = vm.serializeAddress(contracts, "bettingRouter", deployed.bettingRouter);

        // 构建 strategies 对象
        string memory strategies = "strategies";
        vm.serializeAddress(strategies, "cpmm", deployed.cpmmStrategy);
        vm.serializeAddress(strategies, "lmsr", deployed.lmsrStrategy);
        string memory strategiesJson = vm.serializeAddress(strategies, "parimutuel", deployed.parimutuelStrategy);

        // 构建 mappers 对象
        string memory mappers = "mappers";
        vm.serializeAddress(mappers, "wdl", deployed.wdlMapper);
        vm.serializeAddress(mappers, "ou", deployed.ouMapper);
        vm.serializeAddress(mappers, "ah", deployed.ahMapper);
        vm.serializeAddress(mappers, "oddEven", deployed.oddEvenMapper);
        string memory mappersJson = vm.serializeAddress(mappers, "score", deployed.scoreMapper);

        // 构建 templateIds 对象
        string memory templateIds = "templateIds";
        vm.serializeBytes32(templateIds, "market", deployed.marketTemplateId);
        vm.serializeBytes32(templateIds, "wdl", deployed.wdlTemplateId);
        vm.serializeBytes32(templateIds, "ou", deployed.ouTemplateId);
        vm.serializeBytes32(templateIds, "ah", deployed.ahTemplateId);
        vm.serializeBytes32(templateIds, "oddEven", deployed.oddEvenTemplateId);
        string memory templateIdsJson = vm.serializeBytes32(templateIds, "score", deployed.scoreTemplateId);

        // 构建根对象
        string memory root = "root";
        vm.serializeString(root, "network", networkName);
        vm.serializeUint(root, "chainId", block.chainid);
        vm.serializeUint(root, "deployedAt", block.number);
        vm.serializeAddress(root, "deployer", deployer);
        vm.serializeString(root, "contracts", contractsJson);
        vm.serializeString(root, "strategies", strategiesJson);
        vm.serializeString(root, "mappers", mappersJson);
        string memory finalJson = vm.serializeString(root, "templateIds", templateIdsJson);

        string memory outputPath = string.concat("deployments/", networkName, ".json");
        vm.writeJson(finalJson, outputPath);

        console.log("\n========================================");
        console.log("  Deployment Config Generated");
        console.log("========================================");
        console.log("Output:", outputPath);
        console.log("========================================\n");
    }
}
