// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/liquidity/LiquidityVault.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateMarkets
 * @notice 批量创建测试市场脚本
 * @dev 通过 Factory 创建市场，避免 Subgraph 数据丢失
 *
 * 使用方法：
 *   1. 确保已经运行 Deploy.s.sol 部署了系统
 *   2. 设置环境变量（或使用默认值）：
 *      export FACTORY_ADDRESS=0x...
 *      export VAULT_ADDRESS=0x...
 *      export USDC_ADDRESS=0x...
 *      export WDL_TEMPLATE_ID=0x...
 *      export OU_TEMPLATE_ID=0x...
 *      export ODDEVEN_TEMPLATE_ID=0x...
 *   3. 运行脚本：
 *      forge script script/CreateMarkets.s.sol:CreateMarkets --rpc-url http://localhost:8545 --broadcast
 *
 * 配置参数：
 *   - NUM_WDL_MARKETS: WDL 市场数量（默认 3）
 *   - NUM_OU_MARKETS: OU 市场数量（默认 3）
 *   - NUM_ODDEVEN_MARKETS: 单双号市场数量（默认 5）
 *   - CREATE_DIFFERENT_STATES: 是否创建不同状态的市场（默认 true）
 */
contract CreateMarkets is Script {
    // 市场配置
    struct MarketConfig {
        string matchId;
        string team1;
        string team2;
        uint256 lockTimeOffset; // 距离现在的秒数
        uint256 ouLine;         // 大小球线（仅 OU 使用）
    }

    // 默认地址（Anvil 最新部署）
    address constant DEFAULT_FACTORY = 0x22753E4264FDDc6181dc7cce468904A80a363E44;
    address constant DEFAULT_VAULT = 0xd8E1E7009802c914b0d39B31Fc1759A865b727B1;
    address constant DEFAULT_USDC = 0xc96304e3c037f81dA488ed9dEa1D8F2a48278a75;
    address constant DEFAULT_FEE_ROUTER = 0x871ACbEabBaf8Bed65c22ba7132beCFaBf8c27B5;
    address constant DEFAULT_CPMM = 0x997CE91aBb📍75Bf56e035fB85c5dEB8F1b45;

    // 预定义的赛事数据
    MarketConfig[] private wdlConfigs;
    MarketConfig[] private ouConfigs;
    MarketConfig[] private oddEvenConfigs;

    function setUp() public {
        // WDL 市场配置
        wdlConfigs.push(MarketConfig("EPL_2025_MUN_vs_LIV", "Manchester United", "Liverpool", 3 days, 0));
        wdlConfigs.push(MarketConfig("EPL_2025_ARS_vs_CHE", "Arsenal", "Chelsea", 4 days, 0));
        wdlConfigs.push(MarketConfig("EPL_2025_MCI_vs_TOT", "Manchester City", "Tottenham", 5 days, 0));
        wdlConfigs.push(MarketConfig("LAL_2025_BAR_vs_RMA", "Barcelona", "Real Madrid", 6 days, 0));
        wdlConfigs.push(MarketConfig("LAL_2025_ATM_vs_SEV", "Atletico Madrid", "Sevilla", 7 days, 0));

        // OU 市场配置
        ouConfigs.push(MarketConfig("EPL_OU_CHE_vs_NEW", "Chelsea", "Newcastle", 3 days, 2500));
        ouConfigs.push(MarketConfig("EPL_OU_AVL_vs_BRI", "Aston Villa", "Brighton", 4 days, 2500));
        ouConfigs.push(MarketConfig("EPL_OU_WHU_vs_WOL", "West Ham", "Wolves", 5 days, 2000));
        ouConfigs.push(MarketConfig("SER_OU_INT_vs_MIL", "Inter Milan", "AC Milan", 6 days, 2500));
        ouConfigs.push(MarketConfig("SER_OU_NAP_vs_JUV", "Napoli", "Juventus", 7 days, 3000));

        // 单双号市场配置
        oddEvenConfigs.push(MarketConfig("EPL_OE_LEI_vs_FUL", "Leicester", "Fulham", 3 hours, 0));
        oddEvenConfigs.push(MarketConfig("EPL_OE_BOU_vs_EVE", "Bournemouth", "Everton", 4 hours, 0));
        oddEvenConfigs.push(MarketConfig("EPL_OE_CRY_vs_BRE", "Crystal Palace", "Brentford", 1 days, 0));
        oddEvenConfigs.push(MarketConfig("BUN_OE_BAY_vs_DOR", "Bayern Munich", "Dortmund", 2 days, 0));
        oddEvenConfigs.push(MarketConfig("BUN_OE_RBL_vs_LEV", "RB Leipzig", "Leverkusen", 3 days, 0));
        oddEvenConfigs.push(MarketConfig("LIG_OE_PSG_vs_MAR", "PSG", "Marseille", 4 days, 0));
        oddEvenConfigs.push(MarketConfig("LIG_OE_LYO_vs_MON", "Lyon", "Monaco", 5 days, 0));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Batch Create Markets via Factory");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("\n");

        // 读取合约地址
        address factoryAddr = vm.envOr("FACTORY_ADDRESS", DEFAULT_FACTORY);
        address vaultAddr = vm.envOr("VAULT_ADDRESS", DEFAULT_VAULT);
        address usdcAddr = vm.envOr("USDC_ADDRESS", DEFAULT_USDC);
        address feeRouterAddr = vm.envOr("FEE_ROUTER_ADDRESS", DEFAULT_FEE_ROUTER);
        address cpmmAddr = vm.envOr("CPMM_ADDRESS", DEFAULT_CPMM);

        console.log("Factory:", factoryAddr);
        console.log("Vault:", vaultAddr);
        console.log("USDC:", usdcAddr);
        console.log("FeeRouter:", feeRouterAddr);
        console.log("CPMM:", cpmmAddr);
        console.log("");

        MarketFactory_v2 factory = MarketFactory_v2(factoryAddr);
        LiquidityVault vault = LiquidityVault(vaultAddr);
        MockERC20 usdc = MockERC20(usdcAddr);

        // 读取模板 ID
        bytes32 wdlTemplateId = vm.envOr("WDL_TEMPLATE_ID", bytes32(0));
        bytes32 ouTemplateId = vm.envOr("OU_TEMPLATE_ID", bytes32(0));
        bytes32 oddEvenTemplateId = vm.envOr("ODDEVEN_TEMPLATE_ID", bytes32(0));

        // 如果未设置，尝试从 Factory 获取
        if (wdlTemplateId == bytes32(0)) {
            wdlTemplateId = factory.getTemplateId("WDL", "V2");
            console.log("Auto-detected WDL Template ID:", vm.toString(wdlTemplateId));
        }
        if (ouTemplateId == bytes32(0)) {
            ouTemplateId = factory.getTemplateId("OU", "1.0.0");
            console.log("Auto-detected OU Template ID:", vm.toString(ouTemplateId));
        }
        if (oddEvenTemplateId == bytes32(0)) {
            oddEvenTemplateId = factory.getTemplateId("OddEven", "1.0.0");
            console.log("Auto-detected OddEven Template ID:", vm.toString(oddEvenTemplateId));
        }

        // 读取配置
        uint256 numWdl = vm.envOr("NUM_WDL_MARKETS", uint256(3));
        uint256 numOu = vm.envOr("NUM_OU_MARKETS", uint256(3));
        uint256 numOddEven = vm.envOr("NUM_ODDEVEN_MARKETS", uint256(5));
        bool createDifferentStates = vm.envOr("CREATE_DIFFERENT_STATES", true);

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 1. 创建 WDL 市场
        // ========================================
        if (numWdl > 0 && wdlTemplateId != bytes32(0)) {
            console.log("\n========================================");
            console.log("Creating WDL Markets (", numWdl, ")");
            console.log("========================================");

            for (uint256 i = 0; i < numWdl && i < wdlConfigs.length; i++) {
                MarketConfig memory config = wdlConfigs[i];
                address market = createWdlMarket(
                    factory,
                    vault,
                    wdlTemplateId,
                    config,
                    usdcAddr,
                    feeRouterAddr,
                    cpmmAddr,
                    vaultAddr
                );
                console.log("  ", i + 1, ".", config.matchId);
                console.log("      Address:", market);
                console.log("      Teams:", config.team1, "vs", config.team2);
            }
        }

        // ========================================
        // 2. 创建 OU 市场
        // ========================================
        if (numOu > 0 && ouTemplateId != bytes32(0)) {
            console.log("\n========================================");
            console.log("Creating OU Markets (", numOu, ")");
            console.log("========================================");

            for (uint256 i = 0; i < numOu && i < ouConfigs.length; i++) {
                MarketConfig memory config = ouConfigs[i];
                address market = createOuMarket(
                    factory,
                    ouTemplateId,
                    config,
                    usdcAddr,
                    feeRouterAddr,
                    cpmmAddr
                );
                console.log("  ", i + 1, ".", config.matchId);
                console.log("      Address:", market);
                console.log("      O/U Line:", config.ouLine / 1000, ".", config.ouLine % 1000);
            }
        }

        // ========================================
        // 3. 创建 OddEven 市场（不同状态）
        // ========================================
        if (numOddEven > 0 && oddEvenTemplateId != bytes32(0)) {
            console.log("\n========================================");
            console.log("Creating OddEven Markets (", numOddEven, ")");
            console.log("========================================");

            for (uint256 i = 0; i < numOddEven && i < oddEvenConfigs.length; i++) {
                MarketConfig memory config = oddEvenConfigs[i];
                address market = createOddEvenMarket(
                    factory,
                    oddEvenTemplateId,
                    config,
                    usdcAddr,
                    feeRouterAddr,
                    cpmmAddr
                );

                // 根据索引设置不同状态
                if (createDifferentStates) {
                    if (i == 2) {
                        // 第3个市场：Locked
                        OddEven_Template(market).lock();
                        console.log("  ", i + 1, ".", config.matchId, "(LOCKED)");
                    } else if (i == 3) {
                        // 第4个市场：Resolved - Odd
                        OddEven_Template(market).lock();
                        OddEven_Template(market).resolve(0);
                        console.log("  ", i + 1, ".", config.matchId, "(RESOLVED: ODD)");
                    } else if (i == 4) {
                        // 第5个市场：Resolved - Even
                        OddEven_Template(market).lock();
                        OddEven_Template(market).resolve(1);
                        console.log("  ", i + 1, ".", config.matchId, "(RESOLVED: EVEN)");
                    } else {
                        console.log("  ", i + 1, ".", config.matchId, "(OPEN)");
                    }
                } else {
                    console.log("  ", i + 1, ".", config.matchId);
                }

                console.log("      Address:", market);
            }
        }

        vm.stopBroadcast();

        // ========================================
        // 4. 输出摘要
        // ========================================
        console.log("\n========================================");
        console.log("  Markets Created Summary");
        console.log("========================================");
        console.log("Total Markets:", factory.getMarketCount());
        console.log("  - WDL:", numWdl);
        console.log("  - OU:", numOu);
        console.log("  - OddEven:", numOddEven);
        if (createDifferentStates && numOddEven >= 3) {
            console.log("    - Open:", numOddEven - 3);
            console.log("    - Locked: 1");
            console.log("    - Resolved: 2");
        }
        console.log("\nNext Step:");
        console.log("  Run SimulateBets.s.sol to generate test betting data");
        console.log("========================================\n");
    }

    /**
     * @notice 创建 WDL 市场
     */
    function createWdlMarket(
        MarketFactory_v2 factory,
        LiquidityVault vault,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm,
        address vaultAddr
    ) internal returns (address) {
        WDL_Template_V2 market = new WDL_Template_V2(
            config.matchId,
            config.team1,
            config.team2,
            block.timestamp + config.lockTimeOffset,
            usdc,
            feeRouter,
            200, // 2% fee
            2 hours,
            cpmm,
            vaultAddr,
            string(abi.encodePacked("https://api.pitchone.io/metadata/wdl/", config.matchId))
        );

        // 授权市场从 Vault 借款
        vault.authorizeMarket(address(market));

        // 注册到 Factory
        factory.recordMarket(address(market), templateId);

        return address(market);
    }

    /**
     * @notice 创建 OU 市场
     */
    function createOuMarket(
        MarketFactory_v2 factory,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm
    ) internal returns (address) {
        OU_Template market = new OU_Template(
            config.matchId,
            config.team1,
            config.team2,
            block.timestamp + config.lockTimeOffset,
            config.ouLine,
            usdc,
            feeRouter,
            200,
            2 hours,
            cpmm,
            string(abi.encodePacked("https://api.pitchone.io/metadata/ou/", config.matchId))
        );

        // 注册到 Factory
        factory.recordMarket(address(market), templateId);

        return address(market);
    }

    /**
     * @notice 创建 OddEven 市场
     */
    function createOddEvenMarket(
        MarketFactory_v2 factory,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm
    ) internal returns (address) {
        OddEven_Template market = new OddEven_Template(
            config.matchId,
            config.team1,
            config.team2,
            block.timestamp + config.lockTimeOffset,
            usdc,
            feeRouter,
            200,
            2 hours,
            cpmm,
            string(abi.encodePacked("https://api.pitchone.io/metadata/oddeven/", config.matchId))
        );

        // 注册到 Factory
        factory.recordMarket(address(market), templateId);

        return address(market);
    }
}
