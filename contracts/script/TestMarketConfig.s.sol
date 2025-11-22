// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "./MarketConfig.sol";

/**
 * @title TestMarketConfig
 * @notice 测试 MarketConfig 库的功能
 */
contract TestMarketConfig is Script {
    using MarketConfig for *;

    function run() external view {
        console.log("\n========================================");
        console.log("  Testing MarketConfig Library");
        console.log("========================================\n");

        // 测试1: 创建基础配置
        console.log("Test 1: Creating Base Config");
        MarketConfig.BaseConfig memory config = MarketConfig.createBaseConfig(
            "TEST_MATCH_001",
            "Man Utd",
            "Man City",
            7  // 7 days offset
        );

        console.log("  Match ID:", config.matchId);
        console.log("  Home Team:", config.homeTeam);
        console.log("  Away Team:", config.awayTeam);
        console.log("  Kickoff Time:", config.kickoffTime);
        console.log("  Settlement Token:", config.settlementToken);
        console.log("  Fee Rate:", config.feeRate);
        console.log("  Dispute Period:", config.disputePeriod);
        console.log("");

        // 测试2: 生成URI
        console.log("Test 2: Generating URIs");
        string memory wdlUri = MarketConfig.generateURI("Man Utd", "Man City", "WDL");
        string memory ouUri = MarketConfig.generateURI("Liverpool", "Chelsea", "O/U");
        console.log("  WDL URI:", wdlUri);
        console.log("  OU URI:", ouUri);
        console.log("");

        // 测试3: 获取常用OU线
        console.log("Test 3: Common OU Lines");
        uint256[] memory ouLines = MarketConfig.getCommonOULines();
        for (uint i = 0; i < ouLines.length; i++) {
            console.log("  Line value:", ouLines[i]);
        }
        console.log("");

        // 测试4: 获取常用让球数
        console.log("Test 4: Common Handicaps");
        int256[] memory handicaps = MarketConfig.getCommonHandicaps();
        console.log("  Number of handicaps:", handicaps.length);
        console.log("");

        // 测试5: 生成均匀概率
        console.log("Test 5: Uniform Probabilities (37 outcomes)");
        uint256[] memory probs = MarketConfig.getUniformProbabilities(37);
        uint256 total = 0;
        for (uint i = 0; i < probs.length; i++) {
            total += probs[i];
        }
        console.log("  Number of outcomes:", probs.length);
        console.log("  Probability per outcome:", probs[0]);
        console.log("  Total probability:", total);
        require(total == 10000, "Total probability must equal 10000");
        console.log("  [OK] Probability validation passed");
        console.log("");

        // 测试6: 获取PlayerProps默认储备
        console.log("Test 6: Default PlayerProps Reserves");
        uint256 usdcUnit = 10 ** 6;  // USDC has 6 decimals
        uint256[] memory reserves = MarketConfig.getDefaultPlayerPropsReserves(usdcUnit);
        console.log("  Reserve 0 (Over):", reserves[0] / usdcUnit, "USDC");
        console.log("  Reserve 1 (Under):", reserves[1] / usdcUnit, "USDC");
        console.log("");

        // 测试7: 获取LMSR流动性参数
        console.log("Test 7: Default LMSR Liquidity");
        uint256 liquidityB = MarketConfig.getDefaultLMSRLiquidity();
        console.log("  Liquidity B:", liquidityB / 1e18, "WAD");
        console.log("");

        // 测试8: 验证常量
        console.log("Test 8: Contract Addresses");
        console.log("  Factory:", MarketConfig.FACTORY);
        console.log("  USDC:", MarketConfig.USDC);
        console.log("  Vault:", MarketConfig.VAULT);
        console.log("  FeeRouter:", MarketConfig.FEE_ROUTER);
        console.log("  SimpleCPMM:", MarketConfig.SIMPLE_CPMM);
        console.log("  Owner:", MarketConfig.OWNER);
        console.log("");

        console.log("========================================");
        console.log("  All Tests Passed! [OK]");
        console.log("========================================\n");
    }
}
