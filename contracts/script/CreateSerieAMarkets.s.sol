// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_V3.sol";
import "../src/core/Market_V3.sol";
import "../src/interfaces/IMarket_V3.sol";
import "../src/liquidity/LiquidityVault_V3.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title CreateSerieAMarkets
 * @notice 从 API-Football 缓存数据批量创建意甲 2025 赛季市场
 * @dev 前置要求:
 *      1. 运行 FetchSerieAFixtures.sh 获取比赛数据
 *      2. 确保 Deploy_V3 已执行，合约已部署
 *
 * 使用方法:
 *   1. 获取比赛数据:
 *      ./script/FetchSerieAFixtures.sh
 *
 *   2. 创建市场:
 *      PRIVATE_KEY=0x... forge script script/CreateSerieAMarkets.s.sol:CreateSerieAMarkets \
 *        --rpc-url http://localhost:8545 --broadcast
 *
 * 环境变量:
 *   - PRIVATE_KEY: 部署账户私钥（默认 Anvil 账户 0）
 *   - MAX_MARKETS: 最大创建市场数量（默认不限制）
 *   - BATCH_LOG_SIZE: 每多少个市场输出一次日志（默认 50）
 */
contract CreateSerieAMarkets is Script {
    // JSON 解析结构（字段必须按字母顺序排列！）
    struct FixtureJson {
        string awayTeam;
        string awayTeamCode;
        uint256 fixtureId;
        string homeTeam;
        string homeTeamCode;
        uint256 kickoffTime;
        string matchIdOU;
        string matchIdWDL;
        uint256 round;
        string status;
        string venue;
    }
    // ============ 配置常量 ============

    string constant DEPLOYMENT_FILE = "deployments/localhost_v3.json";
    string constant FIXTURES_FILE = "data/serie_a_2025.json";
    string constant OUTPUT_FILE = "deployments/serie_a_markets.json";

    // ============ 状态变量 ============

    // 从部署配置加载
    MarketFactory_V3 public factory;
    LiquidityVault_V3 public vault;
    address public usdc;
    bytes32 public wdlTemplateId;
    bytes32 public ouTemplateId;

    // 代币精度
    uint256 public tokenUnit;

    // 创建的市场地址
    address[] public wdlMarkets;
    address[] public ouMarkets;

    // 统计
    uint256 public skippedCount;
    uint256 public errorCount;

    // ============ 主函数 ============

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        uint256 maxMarkets = vm.envOr("MAX_MARKETS", type(uint256).max);
        uint256 batchLogSize = vm.envOr("BATCH_LOG_SIZE", uint256(50));

        console.log("\n========================================");
        console.log("  Serie A 2025 Markets Creation");
        console.log("========================================\n");

        // 1. 加载部署配置
        _loadDeploymentConfig();

        // 2. 读取比赛数据
        string memory fixturesJson = vm.readFile(FIXTURES_FILE);
        uint256 totalFixtures = vm.parseJsonUint(fixturesJson, ".totalFixtures");
        console.log("Loaded fixtures:", totalFixtures);

        // 3. 解析 fixtures 数组为结构体数组
        bytes memory fixturesRaw = vm.parseJson(fixturesJson, ".fixtures");
        FixtureJson[] memory fixtures = abi.decode(fixturesRaw, (FixtureJson[]));
        console.log("Parsed fixtures:", fixtures.length);

        // 4. 确保 Vault 有足够流动性
        _ensureVaultLiquidity(fixtures.length);

        vm.startBroadcast(deployerPrivateKey);

        // 5. 批量创建市场
        console.log("\nCreating markets...");

        uint256 created = 0;
        uint256 fixtureCount = fixtures.length;

        for (uint256 i = 0; i < fixtureCount && created < maxMarkets; i++) {
            FixtureJson memory fixture = fixtures[i];

            // 跳过已过期比赛（双重检查）
            if (fixture.kickoffTime <= block.timestamp) {
                skippedCount++;
                continue;
            }

            // 创建 WDL 市场
            if (created < maxMarkets) {
                address wdlMarket = _createMarket(
                    wdlTemplateId,
                    fixture.matchIdWDL,
                    fixture.kickoffTime
                );
                if (wdlMarket != address(0)) {
                    wdlMarkets.push(wdlMarket);
                    created++;
                }
            }

            // 创建 OU 市场
            if (created < maxMarkets) {
                address ouMarket = _createMarket(
                    ouTemplateId,
                    fixture.matchIdOU,
                    fixture.kickoffTime
                );
                if (ouMarket != address(0)) {
                    ouMarkets.push(ouMarket);
                    created++;
                }
            }

            // 批次日志
            if (created > 0 && created % batchLogSize == 0) {
                console.log("  Progress:", created, "markets created");
            }
        }

        vm.stopBroadcast();

        // 6. 输出统计
        _printSummary();

        // 7. 写入输出文件
        _writeOutputFile();
    }

    // ============ 内部函数 ============

    function _loadDeploymentConfig() internal {
        console.log("Loading deployment config from:", DEPLOYMENT_FILE);

        string memory json = vm.readFile(DEPLOYMENT_FILE);

        // Factory
        address factoryAddr = vm.parseJsonAddress(json, ".contracts.factory");
        require(factoryAddr != address(0), "Factory not found");
        factory = MarketFactory_V3(factoryAddr);
        console.log("  Factory:", factoryAddr);

        // Vault
        address vaultAddr = vm.parseJsonAddress(json, ".contracts.liquidityVault");
        require(vaultAddr != address(0), "Vault not found");
        vault = LiquidityVault_V3(vaultAddr);
        console.log("  Vault:", vaultAddr);

        // USDC
        usdc = vm.parseJsonAddress(json, ".contracts.usdc");
        require(usdc != address(0), "USDC not found");
        console.log("  USDC:", usdc);

        // 代币精度
        tokenUnit = 10 ** IERC20Metadata(usdc).decimals();

        // 模板 ID
        wdlTemplateId = vm.parseJsonBytes32(json, ".templateIds.wdl");
        require(wdlTemplateId != bytes32(0), "WDL template not found");
        console.log("  WDL Template:", vm.toString(wdlTemplateId));

        ouTemplateId = vm.parseJsonBytes32(json, ".templateIds.ou");
        require(ouTemplateId != bytes32(0), "OU template not found");
        console.log("  OU Template:", vm.toString(ouTemplateId));
    }

    function _ensureVaultLiquidity(uint256 fixtureCount) internal view {
        // 每个市场需要约 5k USDC，总需求 = fixtureCount * 2 * 5000
        uint256 requiredLiquidity = fixtureCount * 2 * 5_000 * tokenUnit;
        uint256 availableLiquidity = vault.totalAssets();

        console.log("\nLiquidity check:");
        console.log("  Required:", requiredLiquidity / tokenUnit, "USDC");
        console.log("  Available:", availableLiquidity / tokenUnit, "USDC");

        if (availableLiquidity < requiredLiquidity) {
            console.log("  WARNING: Insufficient liquidity, some markets may fail to fund");
        } else {
            console.log("  Status: OK");
        }
    }

    function _createMarket(
        bytes32 templateId,
        string memory matchId,
        uint256 kickoffTime
    ) internal returns (address market) {
        // 创建空的 outcome 规则数组（使用模板默认值）
        IMarket_V3.OutcomeRule[] memory emptyOutcomes;

        // 构建 CreateMarketParams
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: matchId,
            kickoffTime: kickoffTime,
            mapperInitData: "",
            initialLiquidity: 0,
            outcomeRules: emptyOutcomes
        });

        // 通过 Factory 创建市场
        try factory.createMarket(params) returns (address newMarket) {
            market = newMarket;

            // 授权并从 Vault 获取流动性
            try vault.authorizeMarket(market, 500) {
                try Market_V3(market).fundFromVault() {
                    // 成功
                } catch {
                    console.log("  Warning: Failed to fund market:", matchId);
                }
            } catch {
                console.log("  Warning: Failed to authorize market:", matchId);
            }
        } catch Error(string memory reason) {
            console.log("  Error creating market:", matchId);
            console.log("    Reason:", reason);
            errorCount++;
            return address(0);
        }
    }

    function _printSummary() internal view {
        console.log("\n========================================");
        console.log("  CREATION SUMMARY");
        console.log("========================================");
        console.log("WDL Markets Created:", wdlMarkets.length);
        console.log("OU Markets Created:", ouMarkets.length);
        console.log("Total Markets:", wdlMarkets.length + ouMarkets.length);
        console.log("Skipped (past fixtures):", skippedCount);
        console.log("Errors:", errorCount);
        console.log("========================================\n");
    }

    function _writeOutputFile() internal {
        // 构建 JSON 输出
        string memory json = "{\n";
        json = string.concat(json, '  "timestamp": ', vm.toString(block.timestamp), ',\n');
        json = string.concat(json, '  "network": "localhost",\n');
        json = string.concat(json, '  "league": "Serie A",\n');
        json = string.concat(json, '  "season": "2025",\n');
        json = string.concat(json, '  "wdlMarketsCount": ', vm.toString(wdlMarkets.length), ',\n');
        json = string.concat(json, '  "ouMarketsCount": ', vm.toString(ouMarkets.length), ',\n');

        // WDL 市场地址
        json = string.concat(json, '  "wdlMarkets": [\n');
        for (uint256 i = 0; i < wdlMarkets.length; i++) {
            json = string.concat(json, '    "', vm.toString(wdlMarkets[i]), '"');
            if (i < wdlMarkets.length - 1) {
                json = string.concat(json, ',');
            }
            json = string.concat(json, '\n');
        }
        json = string.concat(json, '  ],\n');

        // OU 市场地址
        json = string.concat(json, '  "ouMarkets": [\n');
        for (uint256 i = 0; i < ouMarkets.length; i++) {
            json = string.concat(json, '    "', vm.toString(ouMarkets[i]), '"');
            if (i < ouMarkets.length - 1) {
                json = string.concat(json, ',');
            }
            json = string.concat(json, '\n');
        }
        json = string.concat(json, '  ]\n');
        json = string.concat(json, '}\n');

        vm.writeFile(OUTPUT_FILE, json);
        console.log("Output written to:", OUTPUT_FILE);
    }
}
