// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/templates/WDL_Template_V2.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/AH_Template.sol";
import "../src/interfaces/IAH_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../src/liquidity/LiquidityVault.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateMarkets
 * @notice 批量创建测试市场脚本
 * @dev 通过 Factory.recordMarket() 注册市场，确保 Subgraph 正确索引
 *
 * 架构说明：
 *   - 当前模板合约使用 constructor 而非 initialize()
 *   - 因此无法使用 Factory.createMarket() 的 Clone 模式
 *   - 采用 "部署 + 注册" 模式：
 *     1. 使用 `new` 部署完整市场合约
 *     2. 调用 factory.recordMarket() 注册并发出 MarketCreated 事件
 *     3. Subgraph 监听该事件进行索引
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
 *      PRIVATE_KEY=0x... forge script script/CreateMarkets.s.sol:CreateMarkets \
 *        --rpc-url http://localhost:8545 --broadcast
 *
 * 配置参数：
 *   - NUM_WDL_MARKETS: WDL 市场数量（默认 3）
 *   - NUM_OU_MARKETS: OU 市场数量（默认 4）
 *   - NUM_AH_MARKETS: AH 市场数量（默认 3）
 *   - NUM_ODDEVEN_MARKETS: 单双号市场数量（默认 0，已弃用）
 *   - CREATE_DIFFERENT_STATES: 是否创建不同状态的市场（默认 false）
 *
 * 未来优化方向：
 *   - 将模板合约改为 Proxy 模式（constructor → initialize）
 *   - 使用 factory.createMarket() + Clone 模式（节省 ~95% 部署 Gas）
 */
contract CreateMarkets is Script {
    // 市场配置
    struct MarketConfig {
        string matchId;
        string team1;
        string team2;
        uint256 lockTimeOffset; // 距离现在的秒数
        uint256 ouLine;         // 大小球线（仅 OU 使用）
        int256 handicap;        // 让球数（仅 AH 使用，千分位）
    }

    // 默认地址（Anvil 最新部署 - 2025-11-06）
    address constant DEFAULT_FACTORY = 0x5e6CB7E728E1C320855587E1D9C6F7972ebdD6D5;
    address constant DEFAULT_VAULT = 0x22a9B82A6c3D2BFB68F324B2e8367f346Dd6f32a;
    address constant DEFAULT_USDC = 0x1343248Cbd4e291C6979e70a138f4c774e902561;
    address constant DEFAULT_FEE_ROUTER = 0x0a17FabeA4633ce714F1Fa4a2dcA62C3bAc4758d;
    address constant DEFAULT_CPMM = 0x547382C0D1b23f707918D3c83A77317B71Aa8470;

    // 预定义的赛事数据
    MarketConfig[] private wdlConfigs;
    MarketConfig[] private ouConfigs;
    MarketConfig[] private ahConfigs;
    MarketConfig[] private oddEvenConfigs;

    function setUp() public {
        // WDL 市场配置 (3个)
        wdlConfigs.push(MarketConfig("EPL_2025_MUN_vs_LIV", "Manchester United", "Liverpool", 3 days, 0, 0));
        wdlConfigs.push(MarketConfig("EPL_2025_ARS_vs_CHE", "Arsenal", "Chelsea", 4 days, 0, 0));
        wdlConfigs.push(MarketConfig("EPL_2025_MCI_vs_TOT", "Manchester City", "Tottenham", 5 days, 0, 0));

        // OU 市场配置 (4个) - 线必须是0.5的倍数（500, 1500, 2500等）
        ouConfigs.push(MarketConfig("EPL_OU_CHE_vs_NEW", "Chelsea", "Newcastle", 3 days, 2500, 0)); // 2.5球
        ouConfigs.push(MarketConfig("EPL_OU_AVL_vs_BRI", "Aston Villa", "Brighton", 4 days, 2500, 0)); // 2.5球
        ouConfigs.push(MarketConfig("EPL_OU_WHU_vs_WOL", "West Ham", "Wolves", 5 days, 1500, 0)); // 1.5球
        ouConfigs.push(MarketConfig("SER_OU_INT_vs_MIL", "Inter Milan", "AC Milan", 6 days, 3500, 0)); // 3.5球

        // AH 让球市场配置 (3个)
        ahConfigs.push(MarketConfig("EPL_AH_LIV_vs_BUR", "Liverpool", "Burnley", 3 days, 0, -1500)); // 主队让1.5球
        ahConfigs.push(MarketConfig("EPL_AH_MCI_vs_SOU", "Manchester City", "Southampton", 4 days, 0, -1000)); // 主队让1球
        ahConfigs.push(MarketConfig("LAL_AH_BAR_vs_GET", "Barcelona", "Getafe", 5 days, 0, -500)); // 主队让0.5球

        // 单双号市场配置 (保留但不使用)
        oddEvenConfigs.push(MarketConfig("EPL_OE_LEI_vs_FUL", "Leicester", "Fulham", 3 hours, 0, 0));
        oddEvenConfigs.push(MarketConfig("EPL_OE_BOU_vs_EVE", "Bournemouth", "Everton", 4 hours, 0, 0));
        oddEvenConfigs.push(MarketConfig("EPL_OE_CRY_vs_BRE", "Crystal Palace", "Brentford", 1 days, 0, 0));
        oddEvenConfigs.push(MarketConfig("BUN_OE_BAY_vs_DOR", "Bayern Munich", "Dortmund", 2 days, 0, 0));
        oddEvenConfigs.push(MarketConfig("BUN_OE_RBL_vs_LEV", "RB Leipzig", "Leverkusen", 3 days, 0, 0));
        oddEvenConfigs.push(MarketConfig("LIG_OE_PSG_vs_MAR", "PSG", "Marseille", 4 days, 0, 0));
        oddEvenConfigs.push(MarketConfig("LIG_OE_LYO_vs_MON", "Lyon", "Monaco", 5 days, 0, 0));
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Batch Create Markets");
        console.log("========================================");
        console.log("Mode: Deploy + Register (not Clone)");
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

        // 使用Deploy脚本输出的Template IDs
        bytes32 wdlTemplateId = 0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc;
        bytes32 ouTemplateId = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
        bytes32 ahTemplateId = bytes32(0); // AH未注册，暂时不用Factory
        bytes32 oddEvenTemplateId = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

        console.log("Using Template IDs:");
        console.log("  WDL:", vm.toString(wdlTemplateId));
        console.log("  OU:", vm.toString(ouTemplateId));
        console.log("  AH:", vm.toString(ahTemplateId));
        console.log("  OddEven:", vm.toString(oddEvenTemplateId));

        // 读取配置
        uint256 numWdl = vm.envOr("NUM_WDL_MARKETS", uint256(3));
        uint256 numOu = vm.envOr("NUM_OU_MARKETS", uint256(4));
        uint256 numAh = vm.envOr("NUM_AH_MARKETS", uint256(3));
        uint256 numOddEven = vm.envOr("NUM_ODDEVEN_MARKETS", uint256(0));
        bool createDifferentStates = vm.envOr("CREATE_DIFFERENT_STATES", false);

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
                console.log(i + 1, config.matchId);
                console.log("Address:", market);
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
                console.log(i + 1, config.matchId);
                console.log("Address:", market);
                console.log("OU Line:", config.ouLine);
            }
        }

        // ========================================
        // 3. 创建 AH 让球市场
        // ========================================
        if (numAh > 0) {
            console.log("\n========================================");
            console.log("Creating AH Markets (", numAh, ")");
            console.log("========================================");

            for (uint256 i = 0; i < numAh && i < ahConfigs.length; i++) {
                MarketConfig memory config = ahConfigs[i];
                address market = createAhMarket(
                    factory,
                    ahTemplateId,
                    config,
                    usdcAddr,
                    feeRouterAddr,
                    cpmmAddr
                );
                console.log(i + 1, config.matchId);
                console.log("Address:", market);
                console.log("Handicap:", config.handicap);
            }
        }

        // ========================================
        // 4. 创建 OddEven 市场（不同状态）
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
                        console.log(i + 1, config.matchId, "(LOCKED)");
                    } else if (i == 3) {
                        // 第4个市场：Resolved - Odd
                        OddEven_Template(market).lock();
                        OddEven_Template(market).resolve(0);
                        console.log(i + 1, config.matchId, "(RESOLVED: ODD)");
                    } else if (i == 4) {
                        // 第5个市场：Resolved - Even
                        OddEven_Template(market).lock();
                        OddEven_Template(market).resolve(1);
                        console.log(i + 1, config.matchId, "(RESOLVED: EVEN)");
                    } else {
                        console.log(i + 1, config.matchId, "(OPEN)");
                    }
                } else {
                    console.log(i + 1, config.matchId);
                }

                console.log("Address:", market);
            }
        }

        vm.stopBroadcast();

        // ========================================
        // 5. 输出摘要
        // ========================================
        console.log("\n========================================");
        console.log("  Markets Created Summary");
        console.log("========================================");
        console.log("Total Markets:", factory.getMarketCount());
        console.log("  - WDL:", numWdl);
        console.log("  - OU:", numOu);
        console.log("  - AH:", numAh);
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
     * @dev 采用 Factory.createMarket() + Clone 模式：
     *      1. 编码 initialize() 参数
     *      2. factory.createMarket(templateId, initData) - 自动 Clone + initialize + 发出事件
     *      3. vault.authorizeMarket() - 授权市场从 Vault 借款
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
        // 步骤 1: 编码 initialize() 参数
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,address,string)",
            config.matchId,           // matchId
            config.team1,             // homeTeam
            config.team2,             // awayTeam
            block.timestamp + config.lockTimeOffset,  // kickoffTime
            usdc,                     // settlementToken
            feeRouter,                // feeRecipient
            200,                      // feeRate (2%)
            2 hours,                  // disputePeriod
            cpmm,                     // pricingEngine
            vaultAddr,                // vault
            string(abi.encodePacked("https://api.pitchone.io/metadata/wdl/", config.matchId)) // uri
        );

        // 步骤 2: 调用 Factory.createMarket()（自动 Clone + initialize）
        address market = factory.createMarket(templateId, initData);

        // 步骤 3: 授权市场从 Vault 借款
        vault.authorizeMarket(market);

        return market;
    }

    /**
     * @notice 创建 OU 市场
     * @dev 采用 Factory.createMarket() + Clone 模式
     */
    function createOuMarket(
        MarketFactory_v2 factory,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm
    ) internal returns (address) {
        // 步骤 1: 编码 initialize() 参数（注意 OU_Template 有 _owner 参数）
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint256,address,address,uint256,uint256,address,string,address)",
            config.matchId,           // matchId
            config.team1,             // homeTeam
            config.team2,             // awayTeam
            block.timestamp + config.lockTimeOffset,  // kickoffTime
            config.ouLine,            // line
            usdc,                     // settlementToken
            feeRouter,                // feeRecipient
            200,                      // feeRate (2%)
            2 hours,                  // disputePeriod
            cpmm,                     // pricingEngine
            string(abi.encodePacked("https://api.pitchone.io/metadata/ou/", config.matchId)), // uri
            msg.sender                // owner
        );

        // 步骤 2: 调用 Factory.createMarket()（自动 Clone + initialize）
        address market = factory.createMarket(templateId, initData);

        return market;
    }

    /**
     * @notice 创建 AH 让球市场
     * @dev 采用 Factory.createMarket() + Clone 模式
     */
    function createAhMarket(
        MarketFactory_v2 factory,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm
    ) internal returns (address) {
        // 步骤 1: 根据让球数判断盘口类型
        IAH_Template.HandicapType hType;
        if (config.handicap % 1000 == 0) {
            hType = IAH_Template.HandicapType.WHOLE; // 整球盘（如-1.0）
        } else {
            hType = IAH_Template.HandicapType.HALF;  // 半球盘（如-0.5, -1.5）
        }

        // 步骤 2: 编码 initialize() 参数（注意 AH_Template 有 _handicap, _handicapType, _owner）
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,int256,uint8,address,address,uint256,uint256,address,string,address)",
            config.matchId,           // matchId
            config.team1,             // homeTeam
            config.team2,             // awayTeam
            block.timestamp + config.lockTimeOffset,  // kickoffTime
            config.handicap,          // handicap
            uint8(hType),             // handicapType (转换为 uint8)
            usdc,                     // settlementToken
            feeRouter,                // feeRecipient
            200,                      // feeRate (2%)
            2 hours,                  // disputePeriod
            cpmm,                     // pricingEngine
            string(abi.encodePacked("https://api.pitchone.io/metadata/ah/", config.matchId)), // uri
            msg.sender                // owner
        );

        // 步骤 3: 调用 Factory.createMarket()（自动 Clone + initialize）
        address market = factory.createMarket(templateId, initData);

        return market;
    }

    /**
     * @notice 创建 OddEven 市场
     * @dev 采用 Factory.createMarket() + Clone 模式
     */
    function createOddEvenMarket(
        MarketFactory_v2 factory,
        bytes32 templateId,
        MarketConfig memory config,
        address usdc,
        address feeRouter,
        address cpmm
    ) internal returns (address) {
        // 步骤 1: 编码 initialize() 参数（注意 OddEven_Template 有 _owner 参数）
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,address,address,uint256,uint256,address,string,address)",
            config.matchId,           // matchId
            config.team1,             // homeTeam
            config.team2,             // awayTeam
            block.timestamp + config.lockTimeOffset,  // kickoffTime
            usdc,                     // settlementToken
            feeRouter,                // feeRecipient
            200,                      // feeRate (2%)
            2 hours,                  // disputePeriod
            cpmm,                     // pricingEngine
            string(abi.encodePacked("https://api.pitchone.io/metadata/oddeven/", config.matchId)), // uri
            msg.sender                // owner
        );

        // 步骤 2: 调用 Factory.createMarket()（自动 Clone + initialize）
        address market = factory.createMarket(templateId, initData);

        return market;
    }
}
