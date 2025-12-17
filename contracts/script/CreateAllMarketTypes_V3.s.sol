// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../src/core/MarketFactory_v3.sol";
import "../src/core/Market_V3.sol";
import "../src/interfaces/IMarket_V3.sol";
import "../src/interfaces/IPricingStrategy.sol";
import "../src/interfaces/IResultMapper.sol";
import "../src/liquidity/LiquidityVault.sol";
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

    // 部署文件路径
    string constant DEPLOYMENT_FILE = "deployments/localhost.json";

    // 从环境变量或 JSON 文件读取的地址（运行时设置）
    address public USDC;
    address public VAULT;
    address public OWNER;

    // 是否已从 JSON 文件加载
    bool public loadedFromJson;

    // 初始流动性（CPMM/LMSR 需要初始流动性来初始化储备）
    uint256 constant INITIAL_LIQUIDITY = 100_000 * 1e6; // 100k (假设 6 位精度)

    // ============ 状态变量 ============

    address[] public createdMarkets;

    // 按类型分类的市场地址
    address[] public wdlMarkets;
    address[] public ouMarkets;
    address[] public ahMarkets;
    address[] public oddEvenMarkets;
    address[] public scoreMarkets;

    // 部署的合约
    MarketFactory_v3 public factory;
    CPMMStrategy public cpmmStrategy;
    LMSRStrategy public lmsrStrategy;
    address public marketV3Implementation;

    // Market_V3 模板 ID（在注册时生成）
    bytes32 public marketV3TemplateId;

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
                factory = MarketFactory_v3(existingFactory);
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
                factory = MarketFactory_v3(existingFactory);
            }
        }

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Creating V3 Markets (5 types)");
        console.log("========================================\n");

        if (loadedFromJson) {
            console.log("Loaded addresses from:", DEPLOYMENT_FILE);
        }

        // 0. 如果 USDC 未设置，部署一个 Mock ERC20
        if (USDC == address(0)) {
            console.log("0. Deploying Mock USDC...");
            USDC = address(new MockERC20("Mock USDC", "USDC", 6));
            console.log("   Mock USDC:", USDC);
        } else {
            console.log("0. Using existing USDC:", USDC);
        }

        // 1. 部署或使用现有的 Factory
        if (address(factory) == address(0)) {
            console.log("\n1. Deploying MarketFactory_v3...");
            factory = new MarketFactory_v3();
            console.log("   MarketFactory_v3:", address(factory));
        } else {
            console.log("\n1. Using existing Factory:", address(factory));
        }

        // 2. 检查是否有现有的 Market_V3 实现，或部署新的
        if (marketV3Implementation == address(0)) {
            console.log("\n2. Deploying Market_V3 Implementation...");
            marketV3Implementation = address(new Market_V3(address(factory)));
            console.log("   Market_V3 Implementation:", marketV3Implementation);
        } else {
            console.log("\n2. Using existing Market_V3 Implementation:", marketV3Implementation);
        }

        // 3. 在 Factory 中注册 Market_V3 模板（如果尚未注册）
        if (marketV3TemplateId == bytes32(0)) {
            console.log("\n3. Registering Market_V3 template in Factory...");
            marketV3TemplateId = factory.registerTemplate(
                "Market_V3",
                "1.0.0",
                marketV3Implementation
            );
            console.log("   Template ID:", vm.toString(marketV3TemplateId));
        } else {
            console.log("\n3. Using existing Market_V3 template ID:", vm.toString(marketV3TemplateId));
        }

        // 4. 部署或使用现有的定价策略
        console.log("\n4. Setting up Pricing Strategies...");
        if (address(cpmmStrategy) == address(0)) {
            cpmmStrategy = new CPMMStrategy();
            console.log("   Deployed CPMMStrategy:", address(cpmmStrategy));
        } else {
            console.log("   Using existing CPMMStrategy:", address(cpmmStrategy));
        }
        if (address(lmsrStrategy) == address(0)) {
            lmsrStrategy = new LMSRStrategy();
            console.log("   Deployed LMSRStrategy:", address(lmsrStrategy));
        } else {
            console.log("   Using existing LMSRStrategy:", address(lmsrStrategy));
        }

        // 4.5. 确保 Vault 有足够流动性（如果配置了 Vault）
        if (VAULT != address(0)) {
            _ensureVaultLiquidity();
        }

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
        // WDL 使用 CPMM + WDL_Mapper
        string[3] memory matches = ["MUN_vs_MCI", "LIV_vs_CHE", "ARS_vs_TOT"];

        for (uint256 i = 0; i < 3; i++) {
            // 部署 WDL Mapper（无参数）
            WDL_Mapper mapper = new WDL_Mapper();

            // 构建 MarketConfig
            address market = _createMarket(
                string(abi.encodePacked("EPL_2024_WDL_", _uint2str(i + 1))),
                matches[i],
                mapper,
                3,  // WDL 有 3 个结果
                i + 1
            );

            createdMarkets.push(market);
            wdlMarkets.push(market);
            console.log("   Created WDL market:", market);
        }
    }

    function _createOUMarkets() internal {
        // OU 使用 CPMM + OU_Mapper
        int256[3] memory lines = [int256(2500), int256(3500), int256(1500)]; // 2.5, 3.5, 1.5

        for (uint256 i = 0; i < 3; i++) {
            // 部署 OU Mapper（带盘口线参数）
            OU_Mapper mapper = new OU_Mapper(lines[i]);

            // 构建 MarketConfig
            address market = _createMarket(
                string(abi.encodePacked("EPL_2024_OU_", _uint2str(i + 1))),
                string(abi.encodePacked("OU_", _uint2str(uint256(lines[i])))),
                mapper,
                3,  // OU 有 3 个结果（Over/Push/Under）
                i + 4
            );

            createdMarkets.push(market);
            ouMarkets.push(market);
            console.log("   Created OU market (line:", uint256(lines[i]), "):", market);
        }
    }

    function _createAHMarkets() internal {
        // AH 使用 CPMM + AH_Mapper
        int256[3] memory lines = [int256(-500), int256(500), int256(-1000)]; // -0.5, +0.5, -1.0

        for (uint256 i = 0; i < 3; i++) {
            // 部署 AH Mapper
            AH_Mapper mapper = new AH_Mapper(lines[i]);

            // 构建 MarketConfig
            address market = _createMarket(
                string(abi.encodePacked("EPL_2024_AH_", _uint2str(i + 1))),
                string(abi.encodePacked("AH_", _int2str(lines[i]))),
                mapper,
                3,  // AH 有 3 个结果
                i + 7
            );

            createdMarkets.push(market);
            ahMarkets.push(market);
            console.log("   Created AH market (line:", _int2str(lines[i]), "):", market);
        }
    }

    function _createOddEvenMarkets() internal {
        // OddEven 使用 CPMM + OddEven_Mapper

        for (uint256 i = 0; i < 3; i++) {
            // 部署 OddEven Mapper（无参数）
            OddEven_Mapper mapper = new OddEven_Mapper();

            // 构建 MarketConfig
            address market = _createMarket(
                string(abi.encodePacked("EPL_2024_OE_", _uint2str(i + 1))),
                string(abi.encodePacked("OddEven_", _uint2str(i + 1))),
                mapper,
                2,  // OddEven 只有 2 个结果
                i + 10
            );

            createdMarkets.push(market);
            oddEvenMarkets.push(market);
            console.log("   Created OddEven market:", market);
        }
    }

    function _createScoreMarkets() internal {
        // Score 使用 LMSR + Score_Mapper（适合多结果市场）

        for (uint256 i = 0; i < 3; i++) {
            // 部署 Score Mapper（maxGoals = 5，共 37 个结果）
            Score_Mapper mapper = new Score_Mapper(5);

            // 构建 MarketConfig（使用 LMSR）
            address market = _createScoreMarket(
                string(abi.encodePacked("EPL_2024_SC_", _uint2str(i + 1))),
                string(abi.encodePacked("Score_", _uint2str(i + 1))),
                mapper,
                i + 13
            );

            createdMarkets.push(market);
            scoreMarkets.push(market);
            console.log("   Created Score market:", market);
        }
    }

    // ============ 市场创建辅助函数 ============

    /**
     * @notice 创建使用 CPMM 策略的市场
     * @dev 必须通过 Factory 创建，因为 Market_V3 强制要求 msg.sender == factory
     */
    function _createMarket(
        string memory marketIdStr,
        string memory matchId,
        IResultMapper mapper,
        uint256 outcomeCount,
        uint256 dayOffset
    ) internal returns (address market) {
        // 构建 outcome 规则
        IMarket_V3.OutcomeRule[] memory outcomeRules = new IMarket_V3.OutcomeRule[](outcomeCount);
        string[] memory names = mapper.getAllOutcomeNames();

        for (uint256 i = 0; i < outcomeCount; i++) {
            outcomeRules[i] = IMarket_V3.OutcomeRule({
                name: names[i],
                payoutType: IPricingStrategy.PayoutType.WINNER
            });
        }

        // 构建 MarketConfig
        IMarket_V3.MarketConfig memory config = IMarket_V3.MarketConfig({
            marketId: keccak256(abi.encodePacked(marketIdStr)),
            matchId: matchId,
            kickoffTime: block.timestamp + dayOffset * 1 days,
            settlementToken: USDC,
            pricingStrategy: IPricingStrategy(address(cpmmStrategy)),
            resultMapper: mapper,
            vault: VAULT,
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: outcomeRules,
            uri: string(abi.encodePacked("ipfs://", marketIdStr)),
            admin: OWNER
        });

        // 通过 Factory 创建市场
        bytes memory initData = abi.encodeWithSelector(
            Market_V3.initialize.selector,
            config
        );
        market = factory.createMarket(marketV3TemplateId, initData);

        // 如果配置了 Vault，授权市场并从 Vault 获取流动性
        if (VAULT != address(0) && INITIAL_LIQUIDITY > 0) {
            _authorizeAndFundMarket(market);
        }
    }

    /**
     * @notice 创建使用 LMSR 策略的市场（用于多结果市场如精确比分）
     * @dev 必须通过 Factory 创建，因为 Market_V3 强制要求 msg.sender == factory
     */
    function _createScoreMarket(
        string memory marketIdStr,
        string memory matchId,
        Score_Mapper mapper,
        uint256 dayOffset
    ) internal returns (address market) {
        uint256 outcomeCount = mapper.totalOutcomes();

        // 构建 outcome 规则
        IMarket_V3.OutcomeRule[] memory outcomeRules = new IMarket_V3.OutcomeRule[](outcomeCount);
        string[] memory names = mapper.getAllOutcomeNames();

        for (uint256 i = 0; i < outcomeCount; i++) {
            outcomeRules[i] = IMarket_V3.OutcomeRule({
                name: names[i],
                payoutType: IPricingStrategy.PayoutType.WINNER
            });
        }

        // 构建 MarketConfig（使用 LMSR 策略）
        IMarket_V3.MarketConfig memory config = IMarket_V3.MarketConfig({
            marketId: keccak256(abi.encodePacked(marketIdStr)),
            matchId: matchId,
            kickoffTime: block.timestamp + dayOffset * 1 days,
            settlementToken: USDC,
            pricingStrategy: IPricingStrategy(address(lmsrStrategy)),
            resultMapper: IResultMapper(address(mapper)),
            vault: VAULT,
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: outcomeRules,
            uri: string(abi.encodePacked("ipfs://", marketIdStr)),
            admin: OWNER
        });

        // 通过 Factory 创建市场
        bytes memory initData = abi.encodeWithSelector(
            Market_V3.initialize.selector,
            config
        );
        market = factory.createMarket(marketV3TemplateId, initData);

        // 如果配置了 Vault，授权市场并从 Vault 获取流动性
        if (VAULT != address(0) && INITIAL_LIQUIDITY > 0) {
            _authorizeAndFundMarket(market);
        }
    }

    /**
     * @notice 确保 Vault 有足够流动性来为所有市场提供初始资金
     * @dev 15 个市场 × 100k USDC = 1.5M USDC 总需求
     *      V2 Vault 有 90% 利用率限制，所以需要存入 1.5M / 0.9 ≈ 1.67M
     */
    function _ensureVaultLiquidity() internal {
        // 考虑 90% 利用率限制：需要存入 = 借款需求 / 0.9
        uint256 requiredBorrow = 15 * INITIAL_LIQUIDITY; // 15 markets × 100k = 1.5M
        uint256 requiredLiquidity = (requiredBorrow * 10000) / 9000 + 1; // 额外 1 wei 确保足够
        LiquidityVault vaultContract = LiquidityVault(VAULT);
        uint256 currentAssets = vaultContract.totalAssets();

        console.log("\n4.5. Checking Vault liquidity...");
        console.log("   Current Vault assets:", currentAssets / 1e6, "USDC");
        console.log("   Required for 15 markets:", requiredLiquidity / 1e6, "USDC");

        if (currentAssets < requiredLiquidity) {
            uint256 needed = requiredLiquidity - currentAssets;
            console.log("   Need to deposit:", needed / 1e6, "USDC");

            // 先给广播账户 mint 足够的 USDC（测试环境）
            // 注意：在 startBroadcast 后，OWNER 是广播账户地址
            IERC20 usdcToken = IERC20(USDC);

            // 尝试 mint（如果 USDC 是 MockERC20）
            try MockERC20(USDC).mint(OWNER, needed) {
                console.log("   Minted", needed / 1e6, "USDC to deployer:", OWNER);
            } catch {
                // 如果不是 MockERC20，检查余额是否足够
                uint256 balance = usdcToken.balanceOf(OWNER);
                if (balance < needed) {
                    console.log("   Warning: Insufficient USDC balance. Need", needed / 1e6, ", have", balance / 1e6);
                    console.log("   Markets will be created but may not be funded from Vault");
                    return;
                }
            }

            // 存入 Vault（作为 LP 存入，接收者也是 OWNER）
            usdcToken.approve(VAULT, needed);
            vaultContract.deposit(needed, OWNER);
            console.log("   Deposited", needed / 1e6, "USDC to Vault");
            console.log("   New Vault assets:", vaultContract.totalAssets() / 1e6, "USDC");
        } else {
            console.log("   Vault has sufficient liquidity");
        }
    }

    /**
     * @notice 在 Vault 中授权市场并从 Vault 获取初始流动性
     * @dev 流程：1. Vault.authorizeMarket(market) → 2. Market.fundFromVault()
     */
    function _authorizeAndFundMarket(address market) internal {
        LiquidityVault vaultContract = LiquidityVault(VAULT);

        // 1. 在 Vault 中授权市场（需要 Vault owner 权限）
        try vaultContract.authorizeMarket(market) {
            console.log("      Authorized market in Vault");
        } catch {
            console.log("      Warning: Could not authorize market (already authorized or no permission)");
            return;
        }

        // 2. 调用市场的 fundFromVault() 从 Vault 借款
        try Market_V3(market).fundFromVault() {
            console.log("      Funded from Vault:", INITIAL_LIQUIDITY / 1e6, "USDC");
        } catch Error(string memory reason) {
            console.log("      Warning: Could not fund from Vault:", reason);
        }
    }

    // ============ 辅助函数 ============

    /**
     * @notice 从 deployments/localhost.json 加载已部署的合约地址
     * @dev 使用 vm.readFile 和 vm.parseJson
     */
    function _loadFromDeploymentFile() internal {
        // 检查文件是否存在
        try vm.readFile(DEPLOYMENT_FILE) returns (string memory jsonContent) {
            console.log("Loading addresses from deployment file...");

            // 解析 shared.usdc
            try vm.parseJsonAddress(jsonContent, ".shared.usdc") returns (address usdc) {
                if (usdc != address(0)) {
                    USDC = usdc;
                    console.log("   Loaded USDC:", USDC);
                }
            } catch {}

            // 解析 v2.contracts.vault（V2 的 Vault 也可用于 V3）
            try vm.parseJsonAddress(jsonContent, ".v2.contracts.vault") returns (address vault) {
                if (vault != address(0)) {
                    VAULT = vault;
                    console.log("   Loaded Vault:", VAULT);
                }
            } catch {}

            // 尝试加载 V3 特定的合约（如果 Deploy.s.sol 已经部署了 V3）
            // 注意：当前 localhost.json 可能还没有 v3 字段，这些是可选的
            try vm.parseJsonAddress(jsonContent, ".v3.factory") returns (address factoryAddr) {
                if (factoryAddr != address(0)) {
                    factory = MarketFactory_v3(factoryAddr);
                    console.log("   Loaded Factory:", address(factory));
                }
            } catch {}

            try vm.parseJsonAddress(jsonContent, ".v3.marketImplementation") returns (address impl) {
                if (impl != address(0)) {
                    marketV3Implementation = impl;
                    console.log("   Loaded Market_V3 Implementation:", marketV3Implementation);
                }
            } catch {}

            try vm.parseJsonBytes32(jsonContent, ".v3.marketTemplateId") returns (bytes32 templateId) {
                if (templateId != bytes32(0)) {
                    marketV3TemplateId = templateId;
                    console.log("   Loaded Market_V3 Template ID");
                }
            } catch {}

            try vm.parseJsonAddress(jsonContent, ".v3.cpmmStrategy") returns (address cpmm) {
                if (cpmm != address(0)) {
                    cpmmStrategy = CPMMStrategy(cpmm);
                    console.log("   Loaded CPMMStrategy:", address(cpmmStrategy));
                }
            } catch {}

            try vm.parseJsonAddress(jsonContent, ".v3.lmsrStrategy") returns (address lmsr) {
                if (lmsr != address(0)) {
                    lmsrStrategy = LMSRStrategy(lmsr);
                    console.log("   Loaded LMSRStrategy:", address(lmsrStrategy));
                }
            } catch {}

            loadedFromJson = true;
        } catch {
            console.log("Deployment file not found or invalid, will deploy fresh contracts");
        }
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
        console.log("  - MarketFactory_v3:", address(factory));
        console.log("  - Market_V3 Implementation:", marketV3Implementation);
        console.log("  - Market_V3 Template ID:", vm.toString(marketV3TemplateId));
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
        json = string(abi.encodePacked(json, '    "marketV3TemplateId": "', vm.toString(marketV3TemplateId), '",\n'));
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
