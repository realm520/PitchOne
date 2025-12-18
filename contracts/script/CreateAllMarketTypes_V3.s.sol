// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../src/core/MarketFactory_V3.sol";
import "../src/core/Market_V3.sol";
import "../src/interfaces/IMarket_V3.sol";
import "../src/interfaces/IPricingStrategy.sol";
import "../src/interfaces/IResultMapper.sol";
import "../src/liquidity/LiquidityVault_V3.sol";
import "../src/pricing/CPMMStrategy.sol";
import "../src/pricing/LMSRStrategy.sol";
import "../src/pricing/ParimutuelStrategy.sol";
import "../src/mappers/WDL_Mapper.sol";
import "../src/mappers/OU_Mapper.sol";
import "../src/mappers/AH_Mapper.sol";
import "../src/mappers/OddEven_Mapper.sol";
import "../src/mappers/Score_Mapper.sol";
// Identity_Mapper 已在 Deploy_V3.s.sol 中部署

/**
 * @title CreateAllMarketTypes_V3
 * @notice 创建 V3 架构的所有市场类型
 * @dev V3 架构特点：
 *      - 统一的 Market_V3 容器（使用 Clone 代理模式）
 *      - 可插拔的定价策略（CPMMStrategy / LMSRStrategy）
 *      - 可插拔的赛果映射器（WDL_Mapper / OU_Mapper / AH_Mapper 等）
 *
 * 重要：Market_V3 必须通过 MarketFactory_V3 创建，构造函数强制绑定 factory 地址
 *
 * 使用方法：
 *   1. 自动从 deployments/localhost.json 读取已部署的合约（推荐）：
 *      PRIVATE_KEY=0x... forge script script/CreateAllMarketTypes_V3.s.sol:CreateAllMarketTypes_V3 \
 *        --rpc-url http://localhost:8545 --broadcast
 *
 *   2. 手动指定合约地址（环境变量优先级高于 JSON 文件）：
 *      FACTORY=0x... USDC=0x... PRIVATE_KEY=0x... forge script ...
 *
 *   3. 全新部署（不使用 JSON 文件）：
 *      SKIP_JSON=true PRIVATE_KEY=0x... forge script ...
 */
contract CreateAllMarketTypes_V3 is Script {
    using Clones for address;

    // ============ 地址常量 ============

    // 默认地址（可通过环境变量覆盖）
    address constant DEFAULT_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil 默认账户

    // 部署文件路径（优先读取 V3 配置）
    string constant DEPLOYMENT_FILE_V3 = "deployments/localhost_v3.json";
    string constant DEPLOYMENT_FILE_V2 = "deployments/localhost.json";

    // 从环境变量或 JSON 文件读取的地址（运行时设置）
    address public USDC;
    address public VAULT;
    address public OWNER;

    // 是否已从 JSON 文件加载
    bool public loadedFromJson;

    // 初始流动性配置（以整数表示，运行时乘以 tokenUnit）
    // 注意：实际流动性由模板定义（Deploy_V3 注册时设置）
    // CPMM 模板: 5k, LMSR 模板: 5k
    // 15 个市场总需求约 75k，考虑 90% 利用率需要约 84k
    uint256 constant INITIAL_LIQUIDITY_AMOUNT = 5_000; // 5k per market (for calculation)
    uint256 constant INITIAL_VAULT_DEPOSIT_AMOUNT = 100_000; // 100k USDC

    // 运行时计算的实际金额（基于代币精度）
    uint256 public initialLiquidity;
    uint256 public initialVaultDeposit;
    uint256 public tokenUnit;

    // ============ 状态变量 ============

    address[] public createdMarkets;

    // 按类型分类的市场地址
    address[] public wdlMarkets;
    address[] public ouMarkets;
    address[] public ahMarkets;
    address[] public oddEvenMarkets;
    address[] public scoreMarkets;

    // Parimutuel（彩池）市场
    address[] public wdlPariMarkets;
    address[] public scorePariMarkets;
    address[] public firstGoalscorerMarkets;

    // 部署的合约（使用 V4 Factory）
    MarketFactory_V3 public factory;
    CPMMStrategy public cpmmStrategy;
    LMSRStrategy public lmsrStrategy;
    ParimutuelStrategy public parimutuelStrategy;
    address public marketV3Implementation;

    // 模板 ID（从 Deploy_V3 已注册的模板）- AMM 模式
    bytes32 public wdlTemplateId;
    bytes32 public ouTemplateId;
    bytes32 public ahTemplateId;
    bytes32 public oddEvenTemplateId;
    bytes32 public scoreTemplateId;

    // 模板 ID（从 Deploy_V3 已注册的模板）- Parimutuel（彩池）模式
    bytes32 public wdlPariTemplateId;
    bytes32 public scorePariTemplateId;
    bytes32 public firstGoalscorerTemplateId;

    // ============ 主函数 ============

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        // 检查是否跳过 JSON 文件加载
        bool skipJson = vm.envOr("SKIP_JSON", false);

        // 从环境变量读取地址
        address existingFactory = vm.envOr("FACTORY", address(0));
        address existingUsdc = vm.envOr("USDC", address(0));
        address existingVault = vm.envOr("VAULT", address(0));
        OWNER = vm.envOr("OWNER", DEFAULT_OWNER);

        // 如果环境变量未设置，尝试从 JSON 文件加载
        if (!skipJson && (existingFactory == address(0) || existingUsdc == address(0))) {
            _loadFromDeploymentFile();

            // 环境变量优先级高于 JSON 文件
            if (existingFactory != address(0)) {
                factory = MarketFactory_V3(existingFactory);
            }
            if (existingUsdc != address(0)) {
                USDC = existingUsdc;
            }
            if (existingVault != address(0)) {
                VAULT = existingVault;
            }
        } else {
            USDC = existingUsdc;
            VAULT = existingVault;
            if (existingFactory != address(0)) {
                factory = MarketFactory_V3(existingFactory);
            }
        }

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Creating V3 Markets (8 types)");
        console.log("  AMM: WDL, OU, AH, OddEven, Score");
        console.log("  Pari: WDL_Pari, Score_Pari, FGS");
        console.log("========================================\n");

        // loadedFromJson 信息已在 _loadFromDeploymentFile 中输出

        // 0. 如果 USDC 未设置，部署一个 Mock ERC20
        if (USDC == address(0)) {
            console.log("0. Deploying Mock USDC...");
            USDC = address(new MockERC20("Mock USDC", "USDC", 6));
            console.log("   Mock USDC:", USDC);
        } else {
            console.log("0. Using existing USDC:", USDC);
        }

        // 0.5. 初始化代币精度相关变量
        uint8 decimals = IERC20Metadata(USDC).decimals();
        tokenUnit = 10 ** decimals;
        initialLiquidity = INITIAL_LIQUIDITY_AMOUNT * tokenUnit;
        initialVaultDeposit = INITIAL_VAULT_DEPOSIT_AMOUNT * tokenUnit;
        console.log("   Token decimals:", decimals);
        console.log("   Initial liquidity per market:", INITIAL_LIQUIDITY_AMOUNT);
        console.log("   Initial vault deposit:", INITIAL_VAULT_DEPOSIT_AMOUNT);

        // 1. 检查 Factory V4（必须已部署）
        require(address(factory) != address(0), "Factory V4 not loaded, please run Deploy_V3 first");
        console.log("\n1. Using existing Factory V4:", address(factory));

        // 2. 检查 Market_V3 实现（从 Factory 读取）
        marketV3Implementation = factory.marketImplementation();
        require(marketV3Implementation != address(0), "Market implementation not found");
        console.log("\n2. Using Market_V3 Implementation:", marketV3Implementation);

        // 3. 检查模板 ID（从 JSON 或 Deploy_V3 已注册）
        require(wdlTemplateId != bytes32(0), "Template IDs not loaded, please check deployment file");
        console.log("\n3. Using existing Template IDs:");
        console.log("   [AMM Mode]");
        console.log("   WDL:", vm.toString(wdlTemplateId));
        console.log("   OU:", vm.toString(ouTemplateId));
        console.log("   AH:", vm.toString(ahTemplateId));
        console.log("   OddEven:", vm.toString(oddEvenTemplateId));
        console.log("   Score:", vm.toString(scoreTemplateId));
        console.log("   [Parimutuel Mode]");
        console.log("   WDL_Pari:", vm.toString(wdlPariTemplateId));
        console.log("   Score_Pari:", vm.toString(scorePariTemplateId));
        console.log("   FirstGoalscorer:", vm.toString(firstGoalscorerTemplateId));

        // 4. 定价策略（从 JSON 加载）
        console.log("\n4. Using Pricing Strategies:");
        console.log("   CPMMStrategy:", address(cpmmStrategy));
        console.log("   LMSRStrategy:", address(lmsrStrategy));
        console.log("   ParimutuelStrategy:", address(parimutuelStrategy));

        // 4.5. 部署或确保 V3 Vault 有足够流动性
        // 注意：V3 市场必须使用 V3 Vault，不兼容 V2 Vault
        _ensureVaultLiquidity();

        // 5. 创建 WDL 市场 (胜平负)
        console.log("\n5. Creating WDL Markets (Win/Draw/Loss)...");
        _createWDLMarkets();

        // 6. 创建 OU 市场 (大小球)
        console.log("\n6. Creating OU Markets (Over/Under)...");
        _createOUMarkets();

        // 7. 创建 AH 市场 (让球)
        console.log("\n7. Creating AH Markets (Asian Handicap)...");
        _createAHMarkets();

        // 8. 创建 OddEven 市场 (单双)
        console.log("\n8. Creating OddEven Markets...");
        _createOddEvenMarkets();

        // 9. 创建 Score 市场 (精确比分)
        console.log("\n9. Creating Score Markets (Correct Score)...");
        _createScoreMarkets();

        // ========================================
        // Parimutuel（彩池）市场 - 不需要初始流动性
        // ========================================

        // 10. 创建 WDL_Pari 市场（彩池模式胜平负）
        if (wdlPariTemplateId != bytes32(0)) {
            console.log("\n10. Creating WDL_Pari Markets (Parimutuel Mode)...");
            _createWDLPariMarkets();
        } else {
            console.log("\n10. Skipping WDL_Pari Markets (template not registered)");
        }

        // 11. 创建 Score_Pari 市场（彩池模式精确比分）
        if (scorePariTemplateId != bytes32(0)) {
            console.log("\n11. Creating Score_Pari Markets (Parimutuel Mode)...");
            _createScorePariMarkets();
        } else {
            console.log("\n11. Skipping Score_Pari Markets (template not registered)");
        }

        // 12. 创建 FirstGoalscorer 市场（首位进球者）
        if (firstGoalscorerTemplateId != bytes32(0)) {
            console.log("\n12. Creating FirstGoalscorer Markets (Parimutuel Mode)...");
            _createFirstGoalscorerMarkets();
        } else {
            console.log("\n12. Skipping FirstGoalscorer Markets (template not registered)");
        }

        vm.stopBroadcast();

        // 输出总结
        _printSummary();

        // 写入部署文件（JSON + TXT 摘要）
        _writeDeploymentFile();
        _writeSummaryFile();
    }

    // ============ 创建各类型市场 ============

    function _createWDLMarkets() internal {
        // WDL 使用 CPMM + WDL_Mapper（模板已预配置）
        // Match ID 格式: {联赛}_{赛季}_{轮次}_{主队}_vs_{客队}_{玩法}
        string[3] memory matches = [
            "EPL_2425_R20_MUN_vs_MCI_WDL",
            "EPL_2425_R20_LIV_vs_CHE_WDL",
            "EPL_2425_R20_ARS_vs_TOT_WDL"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createMarketV4(
                wdlTemplateId,
                matches[i],
                block.timestamp + (i + 1) * 1 days
            );

            createdMarkets.push(market);
            wdlMarkets.push(market);
            console.log("   Created WDL market:", market);
        }
    }

    function _createOUMarkets() internal {
        // OU 使用 CPMM + OU_Mapper（模板已预配置）
        // Match ID 格式: {联赛}_{赛季}_{轮次}_{主队}_vs_{客队}_{玩法}_{盘口}
        string[3] memory matches = [
            "EPL_2425_R20_MUN_vs_MCI_OU_2.5",
            "EPL_2425_R20_LIV_vs_CHE_OU_2.5",
            "EPL_2425_R20_ARS_vs_TOT_OU_2.5"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createMarketV4(
                ouTemplateId,
                matches[i],
                block.timestamp + (i + 4) * 1 days
            );

            createdMarkets.push(market);
            ouMarkets.push(market);
            console.log("   Created OU market:", market);
        }
    }

    function _createAHMarkets() internal {
        // AH 使用 CPMM + AH_Mapper（模板已预配置）
        // Match ID 格式: {联赛}_{赛季}_{轮次}_{主队}_vs_{客队}_{玩法}_{盘口}
        string[3] memory matches = [
            "EPL_2425_R20_MUN_vs_MCI_AH_-0.5",
            "EPL_2425_R20_LIV_vs_CHE_AH_-0.5",
            "EPL_2425_R20_ARS_vs_TOT_AH_-0.5"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createMarketV4(
                ahTemplateId,
                matches[i],
                block.timestamp + (i + 7) * 1 days
            );

            createdMarkets.push(market);
            ahMarkets.push(market);
            console.log("   Created AH market:", market);
        }
    }

    function _createOddEvenMarkets() internal {
        // OddEven 使用 CPMM + OddEven_Mapper（模板已预配置）
        // Match ID 格式: {联赛}_{赛季}_{轮次}_{主队}_vs_{客队}_{玩法}
        string[3] memory matches = [
            "EPL_2425_R20_MUN_vs_MCI_ODDEVEN",
            "EPL_2425_R20_LIV_vs_CHE_ODDEVEN",
            "EPL_2425_R20_ARS_vs_TOT_ODDEVEN"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createMarketV4(
                oddEvenTemplateId,
                matches[i],
                block.timestamp + (i + 10) * 1 days
            );

            createdMarkets.push(market);
            oddEvenMarkets.push(market);
            console.log("   Created OddEven market:", market);
        }
    }

    function _createScoreMarkets() internal {
        // Score 使用 LMSR + Score_Mapper（模板已预配置）
        // Match ID 格式: {联赛}_{赛季}_{轮次}_{主队}_vs_{客队}_{玩法}
        string[3] memory matches = [
            "EPL_2425_R20_MUN_vs_MCI_SCORE",
            "EPL_2425_R20_LIV_vs_CHE_SCORE",
            "EPL_2425_R20_ARS_vs_TOT_SCORE"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createMarketV4(
                scoreTemplateId,
                matches[i],
                block.timestamp + (i + 13) * 1 days
            );

            createdMarkets.push(market);
            scoreMarkets.push(market);
            console.log("   Created Score market:", market);
        }
    }

    // ============ Parimutuel（彩池）市场创建 ============

    /**
     * @notice 创建 WDL_Pari（彩池模式胜平负）市场
     * @dev Parimutuel 特点：
     *      - 不需要初始流动性
     *      - 赔率在结算时计算：odds = totalPool / winningPool
     *      - 所有投注进入池子，1:1 兑换份额
     */
    function _createWDLPariMarkets() internal {
        // WDL_Pari 使用 Parimutuel + WDL_Mapper
        // Match ID 后缀使用 _PARI 区分彩池模式
        string[3] memory matches = [
            "LALIGA_2425_R18_RMA_vs_BAR_WDL_PARI",
            "LALIGA_2425_R18_ATM_vs_SEV_WDL_PARI",
            "LALIGA_2425_R18_VAL_vs_VIL_WDL_PARI"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelMarket(
                wdlPariTemplateId,
                matches[i],
                block.timestamp + (i + 16) * 1 days
            );

            createdMarkets.push(market);
            wdlPariMarkets.push(market);
            console.log("   Created WDL_Pari market:", market);
        }
    }

    /**
     * @notice 创建 Score_Pari（彩池模式精确比分）市场
     * @dev 传统足彩玩法，适合 14 场胜负彩
     */
    function _createScorePariMarkets() internal {
        // Score_Pari 使用 Parimutuel + Score_Mapper
        string[3] memory matches = [
            "LALIGA_2425_R18_RMA_vs_BAR_SCORE_PARI",
            "LALIGA_2425_R18_ATM_vs_SEV_SCORE_PARI",
            "LALIGA_2425_R18_VAL_vs_VIL_SCORE_PARI"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelMarket(
                scorePariTemplateId,
                matches[i],
                block.timestamp + (i + 19) * 1 days
            );

            createdMarkets.push(market);
            scorePariMarkets.push(market);
            console.log("   Created Score_Pari market:", market);
        }
    }

    /**
     * @notice 创建 FirstGoalscorer（首位进球者）市场
     * @dev 高赔率玩法，球员道具彩池模式
     *      - 21 个选项：20 个球员 + 1 个 "无进球/其他"
     *      - 赔率完全由投注分布决定
     *      - Identity_Mapper 已在 Deploy_V3.s.sol Step 6 部署
     */
    function _createFirstGoalscorerMarkets() internal {
        // Identity_Mapper 已在 Deploy_V3.s.sol 中部署并注册到模板
        // 直接创建市场即可

        string[3] memory matches = [
            "LALIGA_2425_R18_RMA_vs_BAR_FGS",
            "LALIGA_2425_R18_ATM_vs_SEV_FGS",
            "LALIGA_2425_R18_VAL_vs_VIL_FGS"
        ];

        for (uint256 i = 0; i < 3; i++) {
            address market = _createParimutuelMarket(
                firstGoalscorerTemplateId,
                matches[i],
                block.timestamp + (i + 22) * 1 days
            );

            createdMarkets.push(market);
            firstGoalscorerMarkets.push(market);
            console.log("   Created FirstGoalscorer market:", market);
        }
    }

    // ============ 市场创建辅助函数 ============

    /**
     * @notice 使用 Factory V4 创建市场
     * @dev Factory V4 使用预注册的模板，包含 Strategy、Mapper、Outcomes 和 InitialLiquidity
     * @param templateId 模板 ID
     * @param matchId 比赛 ID
     * @param kickoffTime 开球时间
     */
    function _createMarketV4(
        bytes32 templateId,
        string memory matchId,
        uint256 kickoffTime
    ) internal returns (address market) {
        // 创建空的 outcome 规则数组（使用模板默认值）
        IMarket_V3.OutcomeRule[] memory emptyOutcomes;

        // 构建 CreateMarketParams（Factory V4 接口）
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: matchId,
            kickoffTime: kickoffTime,
            mapperInitData: "",  // 使用模板默认 Mapper
            initialLiquidity: 0, // 使用模板默认流动性
            outcomeRules: emptyOutcomes // 使用模板默认 outcomes
        });

        // 通过 Factory V4 创建市场
        market = factory.createMarket(params);

        // 如果配置了 Vault，授权市场并从 Vault 获取流动性
        if (VAULT != address(0)) {
            _authorizeAndFundMarket(market);
        }
    }

    /**
     * @notice 创建 Parimutuel（彩池）市场
     * @dev Parimutuel 市场特点：
     *      - 不需要初始流动性（initialLiquidity = 0）
     *      - 不需要从 Vault 借款
     *      - 赔率在结算时计算
     * @param templateId 模板 ID（必须是 Parimutuel 策略）
     * @param matchId 比赛 ID
     * @param kickoffTime 开球时间
     */
    function _createParimutuelMarket(
        bytes32 templateId,
        string memory matchId,
        uint256 kickoffTime
    ) internal returns (address market) {
        // 创建空的 outcome 规则数组（使用模板默认值）
        IMarket_V3.OutcomeRule[] memory emptyOutcomes;

        // 构建 CreateMarketParams
        // Parimutuel 不需要初始流动性
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: matchId,
            kickoffTime: kickoffTime,
            mapperInitData: "",  // 使用模板默认 Mapper
            initialLiquidity: 0, // Parimutuel 不需要初始流动性
            outcomeRules: emptyOutcomes // 使用模板默认 outcomes
        });

        // 通过 Factory V4 创建市场
        market = factory.createMarket(params);

        // Parimutuel 市场不需要从 Vault 借款
        // 但仍需要授权以便后续可能的结算操作
        if (VAULT != address(0)) {
            LiquidityVault_V3 vaultContract = LiquidityVault_V3(VAULT);
            // 授权但不借款（maxLiabilityBps = 0 表示只授权）
            try vaultContract.authorizeMarket(market, 0) {
                console.log("      Authorized Parimutuel market in Vault");
            } catch {
                // Parimutuel 市场不依赖 Vault，授权失败不影响功能
            }
        }
    }

    /**
     * @notice 部署或检查 V3 Vault，确保有足够流动性
     * @dev V3 Vault 特性：
     *      - 90% 最大利用率
     *      - 20% 单市场借款上限
     *      - 储备金机制
     */
    function _ensureVaultLiquidity() internal {
        console.log("\n4.5. Setting up LiquidityVault_V3...");

        // 如果 VAULT 未设置，部署新的 V3 Vault
        if (VAULT == address(0)) {
            console.log("   Deploying new LiquidityVault_V3...");
            LiquidityVault_V3 newVault = new LiquidityVault_V3(
                IERC20(USDC),
                "PitchOne LP V3",
                "pLP-V3"
            );
            VAULT = address(newVault);
            console.log("   LiquidityVault_V3:", VAULT);

            // Mint USDC 并存入 Vault
            console.log("   Minting", initialVaultDeposit / tokenUnit, "tokens for initial LP...");
            MockERC20(USDC).mint(OWNER, initialVaultDeposit);

            // 存入 Vault
            IERC20(USDC).approve(VAULT, initialVaultDeposit);
            newVault.deposit(initialVaultDeposit, OWNER);
            console.log("   Deposited", initialVaultDeposit / tokenUnit, "tokens to Vault");
            console.log("   Vault total assets:", newVault.totalAssets() / tokenUnit, "tokens");
        } else {
            // 使用现有 V3 Vault，检查流动性
            LiquidityVault_V3 vaultContract = LiquidityVault_V3(VAULT);
            uint256 currentAssets = vaultContract.totalAssets();

            console.log("   Using existing V3 Vault:", VAULT);
            console.log("   Current Vault assets:", currentAssets / tokenUnit, "tokens");

            // 考虑 90% 利用率限制：需要存入 = 借款需求 / 0.9
            // 15 markets × 100k = 1.5M，/0.9 ≈ 1.67M
            uint256 requiredBorrow = 15 * initialLiquidity;
            uint256 requiredLiquidity = (requiredBorrow * 10000) / 9000 + 1;
            console.log("   Required for 15 markets:", requiredLiquidity / tokenUnit, "tokens");

            if (currentAssets < requiredLiquidity) {
                uint256 needed = requiredLiquidity - currentAssets;
                console.log("   Need to deposit:", needed / tokenUnit, "tokens");

                // Mint 并存入
                try MockERC20(USDC).mint(OWNER, needed) {
                    console.log("   Minted", needed / tokenUnit, "tokens");
                    IERC20(USDC).approve(VAULT, needed);
                    vaultContract.deposit(needed, OWNER);
                    console.log("   Deposited", needed / tokenUnit, "tokens to Vault");
                } catch {
                    console.log("   Warning: Could not mint USDC, markets may not be funded");
                }
            } else {
                console.log("   Vault has sufficient liquidity");
            }
        }
    }

    /**
     * @notice 在 V3 Vault 中授权市场并从 Vault 获取初始流动性
     * @dev 流程：1. Vault.authorizeMarket(market, maxLiabilityBps) → 2. Market.fundFromVault()
     *      V3 Vault 使用 AccessControl，需要 OPERATOR_ROLE
     */
    function _authorizeAndFundMarket(address market) internal {
        LiquidityVault_V3 vaultContract = LiquidityVault_V3(VAULT);

        // 1. 在 V3 Vault 中授权市场（需要 OPERATOR_ROLE）
        // V3 接口：authorizeMarket(address market, uint256 maxLiabilityBps)
        // 使用默认的 5% 最大亏损限制 (500 bps)
        try vaultContract.authorizeMarket(market, 500) {
            console.log("      Authorized market in V3 Vault (maxLiability: 5%)");
        } catch {
            console.log("      Warning: Could not authorize market (already authorized or no permission)");
            return;
        }

        // 2. 调用市场的 fundFromVault() 从 Vault 借款
        try Market_V3(market).fundFromVault() {
            console.log("      Funded from Vault:", initialLiquidity / tokenUnit, "tokens");
        } catch Error(string memory reason) {
            console.log("      Warning: Could not fund from Vault:", reason);
        }
    }

    // ============ 辅助函数 ============

    /**
     * @notice 从部署文件加载已部署的合约地址
     * @dev 优先读取 localhost_v3.json，如果不存在则从 localhost.json 读取 USDC
     */
    function _loadFromDeploymentFile() internal {
        // 优先尝试读取 V3 配置文件
        try vm.readFile(DEPLOYMENT_FILE_V3) returns (string memory jsonContent) {
            console.log("Loading from V3 deployment file:", DEPLOYMENT_FILE_V3);
            _parseV3Config(jsonContent);
            loadedFromJson = true;
            return;
        } catch {
            console.log("V3 deployment file not found, trying V2 file...");
        }

        // 回退到 V2 配置文件（只读取 USDC 地址）
        try vm.readFile(DEPLOYMENT_FILE_V2) returns (string memory jsonContent) {
            console.log("Loading USDC from V2 deployment file:", DEPLOYMENT_FILE_V2);

            // 只解析 shared.usdc
            try vm.parseJsonAddress(jsonContent, ".shared.usdc") returns (address usdc) {
                if (usdc != address(0)) {
                    USDC = usdc;
                    console.log("   Loaded USDC:", USDC);
                }
            } catch {}

            // 注意：不从 V2 加载 Vault，接口不兼容
            console.log("   V3 Vault will be deployed (V2 Vault not compatible)");
            loadedFromJson = true;
        } catch {
            console.log("No deployment files found, will deploy fresh contracts");
        }
    }

    /**
     * @notice 解析 V3 配置文件（localhost_v3.json）
     * @dev Deploy_V3.s.sol 生成的配置结构
     */
    function _parseV3Config(string memory jsonContent) internal {
        // 解析 USDC
        try vm.parseJsonAddress(jsonContent, ".contracts.usdc") returns (address usdc) {
            if (usdc != address(0)) {
                USDC = usdc;
                console.log("   Loaded USDC:", USDC);
            }
        } catch {}

        // 解析 V3 Vault（liquidityVault）
        try vm.parseJsonAddress(jsonContent, ".contracts.liquidityVault") returns (address vault) {
            if (vault != address(0)) {
                VAULT = vault;
                console.log("   Loaded V3 Vault:", VAULT);
            }
        } catch {
            console.log("   V3 Vault not found, will deploy new one");
        }

        // 解析 Factory V4（注意：JSON 字段名是 "factory" 不是 "factoryV3"）
        try vm.parseJsonAddress(jsonContent, ".contracts.factory") returns (address factoryAddr) {
            if (factoryAddr != address(0)) {
                factory = MarketFactory_V3(factoryAddr);
                console.log("   Loaded Factory V4:", address(factory));
            }
        } catch {
            console.log("   Factory not found in JSON");
        }

        // 解析 Market_V3 Implementation
        try vm.parseJsonAddress(jsonContent, ".contracts.marketImplementation") returns (address impl) {
            if (impl != address(0)) {
                marketV3Implementation = impl;
                console.log("   Loaded Market_V3 Implementation:", marketV3Implementation);
            }
        } catch {}

        // 解析模板 ID（与 Deploy_V3 生成的字段名一致）
        try vm.parseJsonBytes32(jsonContent, ".templateIds.wdl") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                wdlTemplateId = templateId;
                console.log("   Loaded WDL Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.ou") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                ouTemplateId = templateId;
                console.log("   Loaded OU Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.ah") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                ahTemplateId = templateId;
                console.log("   Loaded AH Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.oddEven") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                oddEvenTemplateId = templateId;
                console.log("   Loaded OddEven Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.score") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                scoreTemplateId = templateId;
                console.log("   Loaded Score Template ID");
            }
        } catch {}

        // 解析定价策略
        try vm.parseJsonAddress(jsonContent, ".strategies.cpmm") returns (address cpmm) {
            if (cpmm != address(0)) {
                cpmmStrategy = CPMMStrategy(cpmm);
                console.log("   Loaded CPMMStrategy:", address(cpmmStrategy));
            }
        } catch {}

        try vm.parseJsonAddress(jsonContent, ".strategies.lmsr") returns (address lmsr) {
            if (lmsr != address(0)) {
                lmsrStrategy = LMSRStrategy(lmsr);
                console.log("   Loaded LMSRStrategy:", address(lmsrStrategy));
            }
        } catch {}

        try vm.parseJsonAddress(jsonContent, ".strategies.parimutuel") returns (address pari) {
            if (pari != address(0)) {
                parimutuelStrategy = ParimutuelStrategy(pari);
                console.log("   Loaded ParimutuelStrategy:", address(parimutuelStrategy));
            }
        } catch {}

        // 解析 Parimutuel 模板 ID
        try vm.parseJsonBytes32(jsonContent, ".templateIds.wdlPari") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                wdlPariTemplateId = templateId;
                console.log("   Loaded WDL_Pari Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.scorePari") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                scorePariTemplateId = templateId;
                console.log("   Loaded Score_Pari Template ID");
            }
        } catch {}

        try vm.parseJsonBytes32(jsonContent, ".templateIds.firstGoalscorer") returns (bytes32 templateId) {
            if (templateId != bytes32(0)) {
                firstGoalscorerTemplateId = templateId;
                console.log("   Loaded FirstGoalscorer Template ID");
            }
        } catch {}
    }

    function _printSummary() internal view {
        console.log("\n");
        console.log("================================================================================");
        console.log("                    V3 MARKETS CREATION SUMMARY");
        console.log("================================================================================");
        console.log("");

        // 1. 概览统计
        console.log("1. OVERVIEW");
        console.log("--------------------------------------------------------------------------------");
        console.log("   Total Markets Created:", createdMarkets.length);
        console.log("   Market Types: 8");
        console.log("     - AMM Mode: WDL, OU, AH, OddEven, Score (5 types)");
        console.log("     - Parimutuel Mode: WDL_Pari, Score_Pari, FirstGoalscorer (3 types)");
        console.log("   Markets per Type: 3");
        console.log("");

        // 2. 基础设施
        console.log("2. INFRASTRUCTURE");
        console.log("--------------------------------------------------------------------------------");
        console.log("   Factory V4:            ", address(factory));
        console.log("   Market Implementation: ", marketV3Implementation);
        console.log("   USDC Token:            ", USDC);
        console.log("   Liquidity Vault V3:    ", VAULT);
        console.log("");
        console.log("   Pricing Strategies:");
        console.log("     - CPMMStrategy:      ", address(cpmmStrategy));
        console.log("     - LMSRStrategy:      ", address(lmsrStrategy));
        console.log("     - ParimutuelStrategy:", address(parimutuelStrategy));
        console.log("");

        // 3. WDL 市场详情
        console.log("3. WDL MARKETS (Win/Draw/Loss) - CPMM Strategy");
        console.log("--------------------------------------------------------------------------------");
        _printMarketDetails(wdlMarkets, "WDL");
        console.log("");

        // 4. OU 市场详情
        console.log("4. OU MARKETS (Over/Under 2.5) - CPMM Strategy");
        console.log("--------------------------------------------------------------------------------");
        _printMarketDetails(ouMarkets, "OU");
        console.log("");

        // 5. AH 市场详情
        console.log("5. AH MARKETS (Asian Handicap -0.5) - CPMM Strategy");
        console.log("--------------------------------------------------------------------------------");
        _printMarketDetails(ahMarkets, "AH");
        console.log("");

        // 6. OddEven 市场详情
        console.log("6. ODDEVEN MARKETS (Odd/Even Goals) - CPMM Strategy");
        console.log("--------------------------------------------------------------------------------");
        _printMarketDetails(oddEvenMarkets, "OddEven");
        console.log("");

        // 7. Score 市场详情
        console.log("7. SCORE MARKETS (Correct Score) - LMSR Strategy");
        console.log("--------------------------------------------------------------------------------");
        _printScoreMarketDetails(scoreMarkets);
        console.log("");

        // ========================================
        // Parimutuel（彩池）市场
        // ========================================

        // 8. WDL_Pari 市场详情
        if (wdlPariMarkets.length > 0) {
            console.log("8. WDL_PARI MARKETS (Win/Draw/Loss) - Parimutuel Strategy");
            console.log("--------------------------------------------------------------------------------");
            _printParimutuelMarketDetails(wdlPariMarkets, "WDL_Pari");
            console.log("");
        }

        // 9. Score_Pari 市场详情
        if (scorePariMarkets.length > 0) {
            console.log("9. SCORE_PARI MARKETS (Correct Score) - Parimutuel Strategy");
            console.log("--------------------------------------------------------------------------------");
            _printParimutuelMarketDetails(scorePariMarkets, "Score_Pari");
            console.log("");
        }

        // 10. FirstGoalscorer 市场详情
        if (firstGoalscorerMarkets.length > 0) {
            console.log("10. FIRSTGOALSCORER MARKETS (First Goalscorer) - Parimutuel Strategy");
            console.log("--------------------------------------------------------------------------------");
            _printParimutuelMarketDetails(firstGoalscorerMarkets, "FirstGoalscorer");
            console.log("");
        }

        // 11. Vault 状态
        if (VAULT != address(0)) {
            console.log("11. VAULT STATUS");
            console.log("--------------------------------------------------------------------------------");
            LiquidityVault_V3 vaultContract = LiquidityVault_V3(VAULT);
            console.log("   Total Assets:     ", vaultContract.totalAssets() / tokenUnit, "USDC");
            console.log("   Total Borrowed:   ", vaultContract.totalBorrowed() / tokenUnit, "USDC");
            console.log("   Available:        ", (vaultContract.totalAssets() - vaultContract.totalBorrowed()) / tokenUnit, "USDC");
            console.log("");
        }

        // 12. 汇总表格
        console.log("12. MARKET SUMMARY TABLE");
        console.log("--------------------------------------------------------------------------------");
        console.log("   [AMM Mode - Requires Initial Liquidity]");
        console.log("   Type     | Count | Strategy | Outcomes | Initial Liquidity");
        console.log("   ---------|-------|----------|----------|------------------");
        console.log("   WDL      |   3   | CPMM     |    3     | 5,000 USDC");
        console.log("   OU       |   3   | CPMM     |    2     | 5,000 USDC");
        console.log("   AH       |   3   | CPMM     |    2     | 5,000 USDC");
        console.log("   OddEven  |   3   | CPMM     |    2     | 5,000 USDC");
        console.log("   Score    |   3   | LMSR     |   36     | 5,000 USDC");
        console.log("   ---------|-------|----------|----------|------------------");
        console.log("   Subtotal |  15   |    -     |    -     | 75,000 USDC");
        console.log("");
        console.log("   [Parimutuel Mode - No Initial Liquidity Required]");
        console.log("   Type          | Count | Strategy    | Outcomes | Initial Liquidity");
        console.log("   --------------|-------|-------------|----------|------------------");
        console.log("   WDL_Pari      |   3   | Parimutuel  |    3     | 0 (pool-based)");
        console.log("   Score_Pari    |   3   | Parimutuel  |   36     | 0 (pool-based)");
        console.log("   FirstGS       |   3   | Parimutuel  |   21     | 0 (pool-based)");
        console.log("   --------------|-------|-------------|----------|------------------");
        console.log("   Subtotal      |   9   |    -        |    -     | 0 USDC");
        console.log("");
        console.log("   ======================================================================");
        console.log("   TOTAL         |  24   |    -        |    -     | 75,000 USDC");
        console.log("");

        console.log("================================================================================");
        console.log("                         CREATION COMPLETE");
        console.log("================================================================================");
        console.log("");
    }

    /**
     * @notice 打印单个市场类型的详情（CPMM 策略）
     */
    function _printMarketDetails(address[] storage markets, string memory marketType) internal view {
        for (uint256 i = 0; i < markets.length; i++) {
            Market_V3 market = Market_V3(markets[i]);
            uint256 outcomes = market.outcomeCount();
            uint256 liquidity = market.totalLiquidity();

            console.log("   Market", i + 1, ":", markets[i]);
            console.log("     Match ID:        ", market.matchId());
            console.log("     Outcomes:        ", outcomes);
            console.log("     Liquidity:       ", liquidity / tokenUnit, "USDC");

            // 获取并显示价格/赔率
            uint256[] memory prices = market.getAllPrices();
            if (prices.length > 0) {
                console.log("     Initial Odds (basis points):");
                for (uint256 j = 0; j < prices.length && j < 5; j++) {
                    // 计算十进制赔率: odds = 10000 / price
                    uint256 decimalOdds = prices[j] > 0 ? (10000 * 100) / prices[j] : 0;
                    _printOutcomeOdds(marketType, j, prices[j], decimalOdds);
                }
            }
            if (i < markets.length - 1) console.log("");
        }
    }

    /**
     * @notice 打印 Score 市场详情（LMSR 策略，多 outcome）
     */
    function _printScoreMarketDetails(address[] storage markets) internal view {
        for (uint256 i = 0; i < markets.length; i++) {
            Market_V3 market = Market_V3(markets[i]);
            uint256 outcomes = market.outcomeCount();
            uint256 liquidity = market.totalLiquidity();

            console.log("   Market", i + 1, ":", markets[i]);
            console.log("     Match ID:        ", market.matchId());
            console.log("     Outcomes:        ", outcomes, "(correct scores 0-0 to 4-4 + Other)");
            console.log("     Liquidity:       ", liquidity / tokenUnit, "USDC");

            // LMSR 市场只显示前 5 个和最后一个 outcome 的价格
            uint256[] memory prices = market.getAllPrices();
            if (prices.length > 0) {
                console.log("     Sample Odds (basis points):");
                // 显示前 5 个
                for (uint256 j = 0; j < 5 && j < prices.length; j++) {
                    uint256 decimalOdds = prices[j] > 0 ? (10000 * 100) / prices[j] : 0;
                    _printScoreOutcomeOdds(j, prices[j], decimalOdds);
                }
                if (prices.length > 5) {
                    console.log("       ... (", prices.length - 5, "more outcomes)");
                }
            }
            if (i < markets.length - 1) console.log("");
        }
    }

    /**
     * @notice 打印单个 outcome 的赔率（根据市场类型）
     * @dev Foundry console.log 最多支持 4 个参数
     */
    function _printOutcomeOdds(string memory marketType, uint256 outcomeId, uint256 price, uint256 decimalOdds) internal pure {
        // 格式化赔率字符串: "X.XX"
        string memory oddsStr = _formatDecimalOdds(decimalOdds);
        string memory priceStr = _uint2str(price);

        // 根据市场类型显示 outcome 名称
        if (_strEq(marketType, "WDL")) {
            if (outcomeId == 0) console.log(string(abi.encodePacked("       Home Win:     ", priceStr, " bps -> ", oddsStr, "x")));
            else if (outcomeId == 1) console.log(string(abi.encodePacked("       Draw:         ", priceStr, " bps -> ", oddsStr, "x")));
            else if (outcomeId == 2) console.log(string(abi.encodePacked("       Away Win:     ", priceStr, " bps -> ", oddsStr, "x")));
        } else if (_strEq(marketType, "OU")) {
            if (outcomeId == 0) console.log(string(abi.encodePacked("       Over 2.5:     ", priceStr, " bps -> ", oddsStr, "x")));
            else if (outcomeId == 1) console.log(string(abi.encodePacked("       Under 2.5:    ", priceStr, " bps -> ", oddsStr, "x")));
        } else if (_strEq(marketType, "AH")) {
            if (outcomeId == 0) console.log(string(abi.encodePacked("       Home -0.5:    ", priceStr, " bps -> ", oddsStr, "x")));
            else if (outcomeId == 1) console.log(string(abi.encodePacked("       Away +0.5:    ", priceStr, " bps -> ", oddsStr, "x")));
        } else if (_strEq(marketType, "OddEven")) {
            if (outcomeId == 0) console.log(string(abi.encodePacked("       Odd Goals:    ", priceStr, " bps -> ", oddsStr, "x")));
            else if (outcomeId == 1) console.log(string(abi.encodePacked("       Even Goals:   ", priceStr, " bps -> ", oddsStr, "x")));
        } else {
            console.log(string(abi.encodePacked("       Outcome ", _uint2str(outcomeId), ":    ", priceStr, " bps -> ", oddsStr, "x")));
        }
    }

    /**
     * @notice 打印 Parimutuel 市场详情
     * @dev Parimutuel 市场初始没有赔率（赔率在结算时计算）
     */
    function _printParimutuelMarketDetails(address[] storage markets, string memory marketType) internal view {
        for (uint256 i = 0; i < markets.length; i++) {
            Market_V3 market = Market_V3(markets[i]);
            uint256 outcomes = market.outcomeCount();
            uint256 liquidity = market.totalLiquidity();

            console.log("   Market", i + 1, ":", markets[i]);
            console.log("     Match ID:        ", market.matchId());
            console.log("     Outcomes:        ", outcomes);
            console.log("     Current Pool:    ", liquidity / tokenUnit, "USDC (from bets)");
            console.log("     Mode:            Parimutuel (odds calculated at settlement)");

            // Parimutuel 市场显示当前投注分布而非固定赔率
            uint256[] memory prices = market.getAllPrices();
            if (prices.length > 0) {
                console.log("     Current Distribution (basis points):");
                uint256 maxDisplay = _strEq(marketType, "FirstGoalscorer") ? 5 : prices.length;
                for (uint256 j = 0; j < maxDisplay && j < prices.length; j++) {
                    _printParimutuelOutcome(marketType, j, prices[j]);
                }
                if (_strEq(marketType, "FirstGoalscorer") && prices.length > 5) {
                    console.log("       ... (", prices.length - 5, "more players)");
                }
            }
            if (i < markets.length - 1) console.log("");
        }
    }

    /**
     * @notice 打印 Parimutuel 市场的单个 outcome
     */
    function _printParimutuelOutcome(string memory marketType, uint256 outcomeId, uint256 price) internal pure {
        string memory priceStr = _uint2str(price);

        if (_strEq(marketType, "WDL_Pari")) {
            if (outcomeId == 0) console.log(string(abi.encodePacked("       Home Win:     ", priceStr, " bps")));
            else if (outcomeId == 1) console.log(string(abi.encodePacked("       Draw:         ", priceStr, " bps")));
            else if (outcomeId == 2) console.log(string(abi.encodePacked("       Away Win:     ", priceStr, " bps")));
        } else if (_strEq(marketType, "Score_Pari")) {
            uint256 homeGoals = outcomeId / 6;
            uint256 awayGoals = outcomeId % 6;
            console.log(string(abi.encodePacked("       Score ", _uint2str(homeGoals), "-", _uint2str(awayGoals), ":    ", priceStr, " bps")));
        } else if (_strEq(marketType, "FirstGoalscorer")) {
            if (outcomeId < 20) {
                console.log(string(abi.encodePacked("       Player ", _uint2str(outcomeId + 1), ":   ", priceStr, " bps")));
            } else {
                console.log(string(abi.encodePacked("       No Goal/Other: ", priceStr, " bps")));
            }
        } else {
            console.log(string(abi.encodePacked("       Outcome ", _uint2str(outcomeId), ": ", priceStr, " bps")));
        }
    }

    /**
     * @notice 打印 Score 市场的 outcome 赔率
     */
    function _printScoreOutcomeOdds(uint256 outcomeId, uint256 price, uint256 decimalOdds) internal pure {
        // Score outcome ID 编码: 前 25 个是 0-0 到 4-4
        uint256 homeGoals = outcomeId / 5;
        uint256 awayGoals = outcomeId % 5;
        string memory oddsStr = _formatDecimalOdds(decimalOdds);
        string memory priceStr = _uint2str(price);
        console.log(string(abi.encodePacked(
            "       Score ", _uint2str(homeGoals), "-", _uint2str(awayGoals), ":    ",
            priceStr, " bps -> ", oddsStr, "x"
        )));
    }

    /**
     * @notice 格式化十进制赔率为字符串 "X.XX"
     */
    function _formatDecimalOdds(uint256 decimalOdds) internal pure returns (string memory) {
        uint256 whole = decimalOdds / 100;
        uint256 decimal = decimalOdds % 100;

        // 构建字符串
        string memory wholeStr = _uint2str(whole);
        string memory decimalStr;
        if (decimal < 10) {
            decimalStr = string(abi.encodePacked("0", _uint2str(decimal)));
        } else {
            decimalStr = _uint2str(decimal);
        }

        return string(abi.encodePacked(wholeStr, ".", decimalStr));
    }

    /**
     * @notice 字符串比较辅助函数
     */
    function _strEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _writeDeploymentFile() internal {
        string memory outputPath = "deployments/markets_v3.json";

        // 构建 JSON 内容
        string memory json = "{\n";
        json = string(abi.encodePacked(json, '  "timestamp": ', _uint2str(block.timestamp), ',\n'));
        json = string(abi.encodePacked(json, '  "chainId": ', _uint2str(block.chainid), ',\n'));

        // 基础设施
        json = string(abi.encodePacked(json, '  "infrastructure": {\n'));
        json = string(abi.encodePacked(json, '    "factory": "', _addr2str(address(factory)), '",\n'));
        json = string(abi.encodePacked(json, '    "marketV3Implementation": "', _addr2str(marketV3Implementation), '",\n'));
        json = string(abi.encodePacked(json, '    "cpmmStrategy": "', _addr2str(address(cpmmStrategy)), '",\n'));
        json = string(abi.encodePacked(json, '    "lmsrStrategy": "', _addr2str(address(lmsrStrategy)), '",\n'));
        json = string(abi.encodePacked(json, '    "usdc": "', _addr2str(USDC), '",\n'));
        json = string(abi.encodePacked(json, '    "vault": "', _addr2str(VAULT), '",\n'));
        json = string(abi.encodePacked(json, '    "owner": "', _addr2str(OWNER), '"\n'));
        json = string(abi.encodePacked(json, '  },\n'));

        // WDL 市场
        json = string(abi.encodePacked(json, '  "wdlMarkets": [\n'));
        for (uint256 i = 0; i < wdlMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(wdlMarkets[i]), '"'));
            if (i < wdlMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // OU 市场
        json = string(abi.encodePacked(json, '  "ouMarkets": [\n'));
        for (uint256 i = 0; i < ouMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(ouMarkets[i]), '"'));
            if (i < ouMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // AH 市场
        json = string(abi.encodePacked(json, '  "ahMarkets": [\n'));
        for (uint256 i = 0; i < ahMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(ahMarkets[i]), '"'));
            if (i < ahMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // OddEven 市场
        json = string(abi.encodePacked(json, '  "oddEvenMarkets": [\n'));
        for (uint256 i = 0; i < oddEvenMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(oddEvenMarkets[i]), '"'));
            if (i < oddEvenMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // Score 市场
        json = string(abi.encodePacked(json, '  "scoreMarkets": [\n'));
        for (uint256 i = 0; i < scoreMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(scoreMarkets[i]), '"'));
            if (i < scoreMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // Parimutuel 市场
        // WDL_Pari 市场
        json = string(abi.encodePacked(json, '  "wdlPariMarkets": [\n'));
        for (uint256 i = 0; i < wdlPariMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(wdlPariMarkets[i]), '"'));
            if (i < wdlPariMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // Score_Pari 市场
        json = string(abi.encodePacked(json, '  "scorePariMarkets": [\n'));
        for (uint256 i = 0; i < scorePariMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(scorePariMarkets[i]), '"'));
            if (i < scorePariMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // FirstGoalscorer 市场
        json = string(abi.encodePacked(json, '  "firstGoalscorerMarkets": [\n'));
        for (uint256 i = 0; i < firstGoalscorerMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(firstGoalscorerMarkets[i]), '"'));
            if (i < firstGoalscorerMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ],\n'));

        // 所有市场
        json = string(abi.encodePacked(json, '  "allMarkets": [\n'));
        for (uint256 i = 0; i < createdMarkets.length; i++) {
            json = string(abi.encodePacked(json, '    "', _addr2str(createdMarkets[i]), '"'));
            if (i < createdMarkets.length - 1) json = string(abi.encodePacked(json, ','));
            json = string(abi.encodePacked(json, '\n'));
        }
        json = string(abi.encodePacked(json, '  ]\n'));

        json = string(abi.encodePacked(json, '}\n'));

        // 写入文件
        vm.writeFile(outputPath, json);
        console.log("\nDeployment file written to:", outputPath);
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _i % 10);
            bstr[k] = bytes1(temp);
            _i /= 10;
        }
        return string(bstr);
    }

    function _int2str(int256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        bool negative = _i < 0;
        uint256 absVal = negative ? uint256(-_i) : uint256(_i);
        string memory absStr = _uint2str(absVal);
        if (negative) {
            return string(abi.encodePacked("-", absStr));
        }
        return absStr;
    }

    function _addr2str(address _addr) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory data = abi.encodePacked(_addr);
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(data[i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }

    /**
     * @notice 生成摘要文件（TXT 格式）
     */
    function _writeSummaryFile() internal {
        string memory outputPath = "deployments/markets_summary_v3.txt";

        // 构建摘要内容
        string memory summary = string.concat(
            "################################################################################\n",
            "##                    V3 MARKETS CREATION SUMMARY                             ##\n",
            "################################################################################\n\n",
            "Created at block: ", _uint2str(block.number), "\n",
            "Timestamp: ", _uint2str(block.timestamp), "\n",
            "Chain ID: ", _uint2str(block.chainid), "\n\n"
        );

        // 1. 概览
        summary = string.concat(
            summary,
            "================================================================================\n",
            "1. OVERVIEW\n",
            "================================================================================\n",
            "Total Markets Created: ", _uint2str(createdMarkets.length), "\n",
            "Market Types: 8\n",
            "  - AMM Mode: WDL, OU, AH, OddEven, Score (5 types)\n",
            "  - Parimutuel Mode: WDL_Pari, Score_Pari, FirstGoalscorer (3 types)\n",
            "Markets per Type: 3\n\n"
        );

        // 2. 基础设施
        summary = string.concat(
            summary,
            "================================================================================\n",
            "2. INFRASTRUCTURE\n",
            "================================================================================\n",
            "Factory V4:             ", _addr2str(address(factory)), "\n",
            "Market Implementation:  ", _addr2str(marketV3Implementation), "\n",
            "USDC Token:             ", _addr2str(USDC), "\n",
            "Liquidity Vault V3:     ", _addr2str(VAULT), "\n\n",
            "Pricing Strategies:\n",
            "  - CPMMStrategy:       ", _addr2str(address(cpmmStrategy)), "\n",
            "  - LMSRStrategy:       ", _addr2str(address(lmsrStrategy)), "\n",
            "  - ParimutuelStrategy: ", _addr2str(address(parimutuelStrategy)), "\n\n"
        );

        // 3. WDL 市场
        summary = string.concat(
            summary,
            "================================================================================\n",
            "3. WDL MARKETS (Win/Draw/Loss) - CPMM Strategy\n",
            "================================================================================\n"
        );
        summary = _appendMarketList(summary, wdlMarkets);

        // 4. OU 市场
        summary = string.concat(
            summary,
            "\n================================================================================\n",
            "4. OU MARKETS (Over/Under 2.5) - CPMM Strategy\n",
            "================================================================================\n"
        );
        summary = _appendMarketList(summary, ouMarkets);

        // 5. AH 市场
        summary = string.concat(
            summary,
            "\n================================================================================\n",
            "5. AH MARKETS (Asian Handicap -0.5) - CPMM Strategy\n",
            "================================================================================\n"
        );
        summary = _appendMarketList(summary, ahMarkets);

        // 6. OddEven 市场
        summary = string.concat(
            summary,
            "\n================================================================================\n",
            "6. ODDEVEN MARKETS (Odd/Even Goals) - CPMM Strategy\n",
            "================================================================================\n"
        );
        summary = _appendMarketList(summary, oddEvenMarkets);

        // 7. Score 市场
        summary = string.concat(
            summary,
            "\n================================================================================\n",
            "7. SCORE MARKETS (Correct Score) - LMSR Strategy\n",
            "================================================================================\n"
        );
        summary = _appendMarketList(summary, scoreMarkets);

        // 8. WDL_Pari 市场
        if (wdlPariMarkets.length > 0) {
            summary = string.concat(
                summary,
                "\n================================================================================\n",
                "8. WDL_PARI MARKETS (Win/Draw/Loss) - Parimutuel Strategy\n",
                "================================================================================\n"
            );
            summary = _appendMarketList(summary, wdlPariMarkets);
        }

        // 9. Score_Pari 市场
        if (scorePariMarkets.length > 0) {
            summary = string.concat(
                summary,
                "\n================================================================================\n",
                "9. SCORE_PARI MARKETS (Correct Score) - Parimutuel Strategy\n",
                "================================================================================\n"
            );
            summary = _appendMarketList(summary, scorePariMarkets);
        }

        // 10. FirstGoalscorer 市场
        if (firstGoalscorerMarkets.length > 0) {
            summary = string.concat(
                summary,
                "\n================================================================================\n",
                "10. FIRSTGOALSCORER MARKETS - Parimutuel Strategy\n",
                "================================================================================\n"
            );
            summary = _appendMarketList(summary, firstGoalscorerMarkets);
        }

        // 11. Vault 状态
        if (VAULT != address(0)) {
            LiquidityVault_V3 vaultContract = LiquidityVault_V3(VAULT);
            uint256 totalAssets = vaultContract.totalAssets();
            uint256 totalBorrowed = vaultContract.totalBorrowed();
            uint256 available = totalAssets > totalBorrowed ? totalAssets - totalBorrowed : 0;

            summary = string.concat(
                summary,
                "\n================================================================================\n",
                "11. VAULT STATUS\n",
                "================================================================================\n",
                "Total Assets:   ", _uint2str(totalAssets / tokenUnit), " USDC\n",
                "Total Borrowed: ", _uint2str(totalBorrowed / tokenUnit), " USDC\n",
                "Available:      ", _uint2str(available / tokenUnit), " USDC\n"
            );
        }

        // 12. 汇总表格
        summary = string.concat(
            summary,
            "\n================================================================================\n",
            "12. MARKET SUMMARY TABLE\n",
            "================================================================================\n\n",
            "[AMM Mode - Requires Initial Liquidity]\n",
            "Type     | Count | Strategy | Outcomes | Initial Liquidity\n",
            "---------|-------|----------|----------|------------------\n",
            "WDL      |   3   | CPMM     |    3     | 5,000 USDC\n",
            "OU       |   3   | CPMM     |    2     | 5,000 USDC\n",
            "AH       |   3   | CPMM     |    2     | 5,000 USDC\n",
            "OddEven  |   3   | CPMM     |    2     | 5,000 USDC\n",
            "Score    |   3   | LMSR     |   36     | 5,000 USDC\n",
            "---------|-------|----------|----------|------------------\n",
            "Subtotal |  15   |    -     |    -     | 75,000 USDC\n\n",
            "[Parimutuel Mode - No Initial Liquidity Required]\n",
            "Type          | Count | Strategy    | Outcomes | Initial Liquidity\n",
            "--------------|-------|-------------|----------|------------------\n",
            "WDL_Pari      |   3   | Parimutuel  |    3     | 0 (pool-based)\n",
            "Score_Pari    |   3   | Parimutuel  |   36     | 0 (pool-based)\n",
            "FirstGS       |   3   | Parimutuel  |   21     | 0 (pool-based)\n",
            "--------------|-------|-------------|----------|------------------\n",
            "Subtotal      |   9   |    -        |    -     | 0 USDC\n\n",
            "======================================================================\n",
            "TOTAL         |  24   |    -        |    -     | 75,000 USDC\n"
        );

        // 结尾
        summary = string.concat(
            summary,
            "\n################################################################################\n",
            "##                         CREATION COMPLETE                                  ##\n",
            "################################################################################\n"
        );

        // 写入文件
        vm.writeFile(outputPath, summary);
        console.log("Summary file written to:", outputPath);
    }

    /**
     * @notice 将市场列表追加到摘要字符串
     */
    function _appendMarketList(string memory summary, address[] storage markets)
        internal
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < markets.length; i++) {
            Market_V3 market = Market_V3(markets[i]);
            summary = string.concat(
                summary,
                "Market ", _uint2str(i + 1), ": ", _addr2str(markets[i]), "\n",
                "  Match ID:   ", market.matchId(), "\n",
                "  Outcomes:   ", _uint2str(market.outcomeCount()), "\n",
                "  Liquidity:  ", _uint2str(market.totalLiquidity() / tokenUnit), " USDC\n"
            );
        }
        return summary;
    }
}

/**
 * @title MockERC20
 * @notice 简单的 Mock ERC20 代币（用于测试）
 */
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}
