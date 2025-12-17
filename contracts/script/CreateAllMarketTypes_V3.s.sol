// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../src/core/MarketFactory_V4.sol";
import "../src/core/Market_V3.sol";
import "../src/interfaces/IMarket_V3.sol";
import "../src/interfaces/IPricingStrategy.sol";
import "../src/interfaces/IResultMapper.sol";
import "../src/liquidity/LiquidityVault_V3.sol";
import "../src/pricing/CPMMStrategy.sol";
import "../src/pricing/LMSRStrategy.sol";
import "../src/mappers/WDL_Mapper.sol";
import "../src/mappers/OU_Mapper.sol";
import "../src/mappers/AH_Mapper.sol";
import "../src/mappers/OddEven_Mapper.sol";
import "../src/mappers/Score_Mapper.sol";

/**
 * @title CreateAllMarketTypes_V3
 * @notice 创建 V3 架构的所有市场类型
 * @dev V3 架构特点：
 *      - 统一的 Market_V3 容器（使用 Clone 代理模式）
 *      - 可插拔的定价策略（CPMMStrategy / LMSRStrategy）
 *      - 可插拔的赛果映射器（WDL_Mapper / OU_Mapper / AH_Mapper 等）
 *
 * 重要：Market_V3 必须通过 MarketFactory_v3 创建，构造函数强制绑定 factory 地址
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
    uint256 constant INITIAL_LIQUIDITY_AMOUNT = 10_000; // 10k per market
    uint256 constant INITIAL_VAULT_DEPOSIT_AMOUNT = 500_000; // 500k USDC

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

    // 部署的合约（使用 V4 Factory）
    MarketFactory_V4 public factory;
    CPMMStrategy public cpmmStrategy;
    LMSRStrategy public lmsrStrategy;
    address public marketV3Implementation;

    // 模板 ID（从 Deploy_V3 已注册的模板）
    bytes32 public wdlTemplateId;
    bytes32 public ouTemplateId;
    bytes32 public ahTemplateId;
    bytes32 public oddEvenTemplateId;
    bytes32 public scoreTemplateId;

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
                factory = MarketFactory_V4(existingFactory);
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
                factory = MarketFactory_V4(existingFactory);
            }
        }

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Creating V3 Markets (5 types)");
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
        console.log("   WDL:", vm.toString(wdlTemplateId));
        console.log("   OU:", vm.toString(ouTemplateId));
        console.log("   AH:", vm.toString(ahTemplateId));
        console.log("   OddEven:", vm.toString(oddEvenTemplateId));
        console.log("   Score:", vm.toString(scoreTemplateId));

        // 4. 定价策略（从 JSON 加载）
        console.log("\n4. Using Pricing Strategies:");
        console.log("   CPMMStrategy:", address(cpmmStrategy));
        console.log("   LMSRStrategy:", address(lmsrStrategy));

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

        vm.stopBroadcast();

        // 输出总结
        _printSummary();

        // 写入部署文件
        _writeDeploymentFile();
    }

    // ============ 创建各类型市场 ============

    function _createWDLMarkets() internal {
        // WDL 使用 CPMM + WDL_Mapper（模板已预配置）
        string[3] memory matches = ["MUN_vs_MCI", "LIV_vs_CHE", "ARS_vs_TOT"];

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
        string[3] memory matches = ["OU_MUN_vs_MCI", "OU_LIV_vs_CHE", "OU_ARS_vs_TOT"];

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
        string[3] memory matches = ["AH_MUN_vs_MCI", "AH_LIV_vs_CHE", "AH_ARS_vs_TOT"];

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
        string[3] memory matches = ["OE_MUN_vs_MCI", "OE_LIV_vs_CHE", "OE_ARS_vs_TOT"];

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
        string[3] memory matches = ["SC_MUN_vs_MCI", "SC_LIV_vs_CHE", "SC_ARS_vs_TOT"];

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
        MarketFactory_V4.CreateMarketParams memory params = MarketFactory_V4.CreateMarketParams({
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
            uint256 requiredBorrow = 15 * initialLiquidity; // 15 markets × 10k = 150k
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
                factory = MarketFactory_V4(factoryAddr);
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
    }

    function _printSummary() internal view {
        console.log("\n========================================");
        console.log("  V3 Markets Created Successfully!");
        console.log("========================================");
        console.log("Total Markets Created:", createdMarkets.length);
        console.log("\nBreakdown by Type:");
        console.log("  - WDL: 3");
        console.log("  - OU: 3");
        console.log("  - AH: 3");
        console.log("  - OddEven: 3");
        console.log("  - Score: 3");
        console.log("  Total: 15 markets (5 types x 3 each)");
        console.log("\nDeployed Contracts:");
        console.log("  - MarketFactory_V4:", address(factory));
        console.log("  - Market_V3 Implementation:", marketV3Implementation);
        console.log("  - CPMMStrategy:", address(cpmmStrategy));
        console.log("  - LMSRStrategy:", address(lmsrStrategy));
        console.log("\nAll markets (via Factory):");
        for (uint256 i = 0; i < createdMarkets.length; i++) {
            console.log("  ", i + 1, ":", createdMarkets[i]);
        }
        console.log("\nQuery all markets from Factory:");
        console.log("  factory.getMarketCount() =", factory.getMarketCount());
        console.log("========================================\n");
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
