// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// V3 核心合约
import "../src/core/Market_V3.sol";
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
        address factory;                // MarketFactory_V4
        address marketImplementation;   // Market_V3 实现
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

        // Parimutuel 模板 ID
        bytes32 wdlPariTemplateId;
        bytes32 scorePariTemplateId;
        bytes32 firstGoalscorerTemplateId;
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
        // 3. 部署 MarketFactory_V4（使用临时 implementation）
        // ========================================
        console.log("\nStep 3: Deploy MarketFactory_V4");
        console.log("----------------------------------------");

        // 先用 deployer 作为临时 implementation（后面会更新）
        MarketFactory_V4 factoryV4 = new MarketFactory_V4(
            deployer,  // 临时 implementation，后面更新
            deployed.usdc,
            deployer
        );
        deployed.factory = address(factoryV4);
        console.log("MarketFactory_V4:", address(factoryV4));

        // ========================================
        // 4. 部署 Market_V3 实现（使用 Factory V4 地址）
        // ========================================
        console.log("\nStep 4: Deploy Market_V3 Implementation");
        console.log("----------------------------------------");

        Market_V3 marketImpl = new Market_V3(address(factoryV4));
        deployed.marketImplementation = address(marketImpl);
        console.log("Market_V3 Implementation:", address(marketImpl));

        // 更新 Factory 的 implementation
        factoryV4.setImplementation(address(marketImpl));
        console.log("Updated Factory implementation to Market_V3");

        // ========================================
        // 5. 部署定价策略
        // ========================================
        console.log("\nStep 5: Deploy Pricing Strategies");
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
        // 6. 部署赛果映射器
        // ========================================
        console.log("\nStep 6: Deploy Result Mappers");
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
            usdcUnit,     // 最小下注 1 代币单位
            0        // 无最大限制
        );
        console.log("Added USDC to supported tokens (min bet: 1 token unit)");

        // 配置 Factory V4
        factoryV4.setRouter(address(router));
        factoryV4.setKeeper(deployer); // 测试环境使用 deployer
        factoryV4.setOracle(deployer); // 测试环境使用 deployer
        factoryV4.setVault(address(liquidityVault)); // 设置默认 Vault
        console.log("Factory V4 configured (Router, Keeper, Oracle, Vault)");

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
            parimutuelStrategy,
            wdlMapper,
            ouMapper,
            ahMapper,
            oddEvenMapper,
            scoreMapper,
            usdcUnit
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
        // 11. 生成部署配置文件 (JSON)
        // ========================================
        _writeDeploymentJson(deployer, deployed, config);

        // ========================================
        // 12. 生成部署摘要文件 (TXT)
        // ========================================
        string memory summaryPath = _writeSummaryFile(deployer, deployed, config, usdcDecimals);

        // 简短提示
        console.log("\n");
        console.log("========================================");
        console.log("  DEPLOYMENT COMPLETE!");
        console.log("========================================");
        console.log("Summary: ", summaryPath);
        console.log("JSON:    deployments/localhost_v3.json");
        console.log("========================================");

        return deployed;
    }

    function _registerV3Templates(
        DeployedContracts memory deployed,
        MarketFactory_V4 factoryV4,
        CPMMStrategy cpmmStrategy,
        LMSRStrategy lmsrStrategy,
        ParimutuelStrategy parimutuelStrategy,
        WDL_Mapper wdlMapper,
        OU_Mapper ouMapper,
        AH_Mapper ahMapper,
        OddEven_Mapper oddEvenMapper,
        Score_Mapper scoreMapper,
        uint256 tokenUnit
    ) internal {
        // 动态计算初始流动性（基于代币精度）
        // 注意：测试环境使用较小的流动性以适配 Vault 容量
        uint256 cpmmLiquidity = 10_000 * tokenUnit;  // 10k 代币（测试环境）
        uint256 lmsrLiquidity = 5_000 * tokenUnit;   // 5k 代币（LMSR 需要较少）
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
            cpmmLiquidity
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
            cpmmLiquidity
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
            cpmmLiquidity
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
            cpmmLiquidity
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
            lmsrLiquidity
        );
        deployed.scoreTemplateId = scoreTemplateIdV3;
        console.log("Score Template ID:", vm.toString(scoreTemplateIdV3));

        // ========================================
        // Parimutuel 模板（彩池模式，不需要初始流动性）
        // ========================================

        // WDL_Pari 模板（胜平负彩池模式）
        bytes32 wdlPariTemplateId = keccak256("WDL_Pari_V3");
        factoryV4.registerTemplate(
            wdlPariTemplateId,
            "WDL_Pari",
            "PARIMUTUEL",
            address(parimutuelStrategy),
            address(wdlMapper),
            wdlOutcomes,  // 复用 WDL 的 outcomes
            0             // Parimutuel 不需要初始流动性
        );
        deployed.wdlPariTemplateId = wdlPariTemplateId;
        console.log("WDL_Pari Template ID:", vm.toString(wdlPariTemplateId));

        // Score_Pari 模板（精确比分彩池模式，传统足彩）
        bytes32 scorePariTemplateId = keccak256("Score_Pari_V3");
        factoryV4.registerTemplate(
            scorePariTemplateId,
            "Score_Pari",
            "PARIMUTUEL",
            address(parimutuelStrategy),
            address(scoreMapper),
            scoreOutcomes,  // 复用 Score 的 outcomes
            0               // Parimutuel 不需要初始流动性
        );
        deployed.scorePariTemplateId = scorePariTemplateId;
        console.log("Score_Pari Template ID:", vm.toString(scorePariTemplateId));

        // FirstGoalscorer 模板（首位进球者，多结果彩池）
        // 假设有 20 个球员选项 + 1 个 "无进球/其他" 选项
        IMarket_V3.OutcomeRule[] memory fgsOutcomes = new IMarket_V3.OutcomeRule[](21);
        for (uint256 i = 0; i < 20; i++) {
            fgsOutcomes[i] = IMarket_V3.OutcomeRule({
                name: string(abi.encodePacked("Player ", vm.toString(i + 1))),
                payoutType: IPricingStrategy.PayoutType.WINNER
            });
        }
        fgsOutcomes[20] = IMarket_V3.OutcomeRule({
            name: "No Goal / Other",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        bytes32 fgsTemplateId = keccak256("FirstGoalscorer_V3");
        factoryV4.registerTemplate(
            fgsTemplateId,
            "FirstGoalscorer",
            "PARIMUTUEL",
            address(parimutuelStrategy),
            address(0),     // 首位进球者不需要赛果映射器（直接由预言机指定结果）
            fgsOutcomes,
            0               // Parimutuel 不需要初始流动性
        );
        deployed.firstGoalscorerTemplateId = fgsTemplateId;
        console.log("FirstGoalscorer Template ID:", vm.toString(fgsTemplateId));
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
     * @notice 将部署摘要写入文件
     */
    function _writeSummaryFile(
        address deployer,
        DeployedContracts memory deployed,
        DeployConfig memory config,
        uint8 usdcDecimals
    ) internal returns (string memory) {
        uint256 usdcUnit = 10 ** usdcDecimals;

        // 构建摘要内容
        string memory summary = string.concat(
            "################################################################################\n",
            "##                         V3 DEPLOYMENT SUMMARY                              ##\n",
            "################################################################################\n\n",
            "Deployed at block: ", vm.toString(block.number), "\n",
            "Deployer: ", vm.toString(deployer), "\n\n"
        );

        // USDC 信息
        summary = string.concat(
            summary,
            "[USDC Token]\n",
            "  Address:           ", vm.toString(deployed.usdc), "\n",
            "  Decimals:          ", vm.toString(usdcDecimals), "\n",
            "  Is Mock:           ", config.usdc == address(0) ? "Yes" : "No", "\n\n"
        );

        // Vault 信息
        LiquidityVault_V3 vault = LiquidityVault_V3(deployed.liquidityVault);
        uint256 totalAssets = vault.totalAssets();
        uint256 totalShares = vault.totalSupply();
        summary = string.concat(
            summary,
            "[LiquidityVault_V3]\n",
            "  Address:           ", vm.toString(deployed.liquidityVault), "\n",
            "  Total Assets:      ", vm.toString(totalAssets / usdcUnit), " USDC\n",
            "  Total Shares:      ", vm.toString(totalShares / usdcUnit), " pLP-V3\n",
            "  Initial Deposit:   ", vm.toString(config.initialLpAmount / usdcUnit), " USDC\n\n"
        );

        // 共享基础设施
        summary = string.concat(
            summary,
            "[Shared Infrastructure]\n",
            "  FeeRouter:         ", vm.toString(deployed.feeRouter), "\n",
            "  ReferralRegistry:  ", vm.toString(deployed.referralRegistry), "\n",
            "  ParamController:   ", vm.toString(deployed.paramController), "\n\n"
        );

        // 核心合约
        summary = string.concat(
            summary,
            "[Core Contracts]\n",
            "  MarketFactory_V4:  ", vm.toString(deployed.factory), "\n",
            "  Market_V3 Impl:    ", vm.toString(deployed.marketImplementation), "\n",
            "  BettingRouter_V3:  ", vm.toString(deployed.bettingRouter), "\n\n"
        );

        // 定价策略
        summary = string.concat(
            summary,
            "[Pricing Strategies]\n",
            "  CPMMStrategy:      ", vm.toString(deployed.cpmmStrategy), "\n",
            "  LMSRStrategy:      ", vm.toString(deployed.lmsrStrategy), "\n",
            "  ParimutuelStrategy:", vm.toString(deployed.parimutuelStrategy), "\n\n"
        );

        // 赛果映射器
        summary = string.concat(
            summary,
            "[Result Mappers]\n",
            "  WDL_Mapper:        ", vm.toString(deployed.wdlMapper), "\n",
            "  OU_Mapper:         ", vm.toString(deployed.ouMapper), "\n",
            "  AH_Mapper:         ", vm.toString(deployed.ahMapper), "\n",
            "  OddEven_Mapper:    ", vm.toString(deployed.oddEvenMapper), "\n",
            "  Score_Mapper:      ", vm.toString(deployed.scoreMapper), "\n\n"
        );

        // 模板 ID - CPMM
        summary = string.concat(
            summary,
            "[Template IDs - CPMM]\n",
            "  WDL:               ", vm.toString(deployed.wdlTemplateId), "\n",
            "  OU:                ", vm.toString(deployed.ouTemplateId), "\n",
            "  AH:                ", vm.toString(deployed.ahTemplateId), "\n",
            "  OddEven:           ", vm.toString(deployed.oddEvenTemplateId), "\n\n"
        );

        // 模板 ID - LMSR
        summary = string.concat(
            summary,
            "[Template IDs - LMSR]\n",
            "  Score:             ", vm.toString(deployed.scoreTemplateId), "\n\n"
        );

        // 模板 ID - Parimutuel
        summary = string.concat(
            summary,
            "[Template IDs - Parimutuel]\n",
            "  WDL_Pari:          ", vm.toString(deployed.wdlPariTemplateId), "\n",
            "  Score_Pari:        ", vm.toString(deployed.scorePariTemplateId), "\n",
            "  FirstGoalscorer:   ", vm.toString(deployed.firstGoalscorerTemplateId), "\n\n"
        );

        // 统计
        summary = string.concat(
            summary,
            "[Deployment Stats]\n",
            "  Total Contracts:    19\n",
            "    - Infrastructure: 4 (USDC, FeeRouter, ReferralRegistry, ParamController)\n",
            "    - Core:           4 (Vault, Factory_V4, Market_V3 Impl, Router)\n",
            "    - Strategies:     3 (CPMM, LMSR, Parimutuel)\n",
            "    - Mappers:        5 (WDL, OU, AH, OddEven, Score)\n",
            "    - Templates:      8 (4 CPMM + 1 LMSR + 3 Parimutuel)\n\n"
        );

        // 下一步
        summary = string.concat(
            summary,
            "================================================================================\n",
            "                              NEXT STEPS\n",
            "================================================================================\n",
            "1. Update subgraph/subgraph.yaml with:\n",
            "   - Factory V4: ", vm.toString(deployed.factory), "\n",
            "   - FeeRouter:  ", vm.toString(deployed.feeRouter), "\n\n",
            "2. Create test markets:\n",
            "   PRIVATE_KEY=0x... forge script script/CreateAllMarketTypes_V3.s.sol \\\n",
            "     --rpc-url http://localhost:8545 --broadcast\n\n",
            "3. Simulate bets:\n",
            "   PRIVATE_KEY=0x... forge script script/SimulateBets_V3.s.sol \\\n",
            "     --rpc-url http://localhost:8545 --broadcast\n",
            "################################################################################\n"
        );

        // 写入文件
        string memory outputPath = "deployments/deploy_summary_v3.txt";
        vm.writeFile(outputPath, summary);

        return outputPath;
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
        vm.serializeAddress(contracts, "factory", deployed.factory);
        vm.serializeAddress(contracts, "marketImplementation", deployed.marketImplementation);
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
        vm.serializeBytes32(templateIds, "wdl", deployed.wdlTemplateId);
        vm.serializeBytes32(templateIds, "ou", deployed.ouTemplateId);
        vm.serializeBytes32(templateIds, "ah", deployed.ahTemplateId);
        vm.serializeBytes32(templateIds, "oddEven", deployed.oddEvenTemplateId);
        vm.serializeBytes32(templateIds, "score", deployed.scoreTemplateId);
        // Parimutuel 模板 ID
        vm.serializeBytes32(templateIds, "wdlPari", deployed.wdlPariTemplateId);
        vm.serializeBytes32(templateIds, "scorePari", deployed.scorePariTemplateId);
        string memory templateIdsJson = vm.serializeBytes32(templateIds, "firstGoalscorer", deployed.firstGoalscorerTemplateId);

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
