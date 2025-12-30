// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/core/MarketFactory_V3.sol";
import "../src/interfaces/IMarket_V3.sol";

/**
 * @title CreatePariMarkets
 * @notice 创建 5 个彩池模式（Parimutuel）市场
 * @dev 彩池模式特点：
 *      - 不需要初始流动性
 *      - 赔率完全由市场投注分布决定
 *      - 适合传统足彩玩法
 *
 * 使用方法：
 *   PRIVATE_KEY=0x... forge script script/CreatePariMarkets.s.sol:CreatePariMarkets \
 *     --rpc-url https://pitchone-rpc.ngrok-free.app --broadcast
 */
contract CreatePariMarkets is Script {
    // 从 localhost_v3.json 读取
    address constant FACTORY = 0xcC4c41415fc68B2fBf70102742A83cDe435e0Ca7;

    // 彩池模式模板 ID
    bytes32 constant WDL_PARI_TEMPLATE_ID = 0xef6f1330cf58b013258b8e3d5fd49f219361a51fb17cfc622a124addb42faba9;
    bytes32 constant SCORE_PARI_TEMPLATE_ID = 0x213a5ab57fbce6773e92530fea5eb10bd610aa9e6dbad2d98cf07f414d074123;
    bytes32 constant FIRST_GOALSCORER_TEMPLATE_ID = 0xf44ca50923fd3146c0ae29ba2693c48afd11abbeebce7c5c9a714f7a46e85b73;

    MarketFactory_V3 public factory;
    address[] public createdMarkets;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );

        factory = MarketFactory_V3(FACTORY);

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  Creating 5 Parimutuel Markets");
        console.log("========================================\n");
        console.log("Factory:", address(factory));

        // 创建 3 个 WDL_Pari 市场（胜平负彩池模式）
        console.log("\n1. Creating WDL_Pari Markets (3)...");
        _createWDLPariMarket("EPL_2425_R20_LIV_vs_MCI_PARI", block.timestamp + 3 days);
        _createWDLPariMarket("EPL_2425_R20_ARS_vs_CHE_PARI", block.timestamp + 4 days);
        _createWDLPariMarket("EPL_2425_R20_MUN_vs_TOT_PARI", block.timestamp + 5 days);

        // 创建 2 个 Score_Pari 市场（精确比分彩池模式）
        console.log("\n2. Creating Score_Pari Markets (2)...");
        _createScorePariMarket("LALIGA_2425_R20_RMA_vs_BAR_SCORE_PARI", block.timestamp + 6 days);
        _createScorePariMarket("LALIGA_2425_R20_ATM_vs_SEV_SCORE_PARI", block.timestamp + 7 days);

        vm.stopBroadcast();

        // 输出汇总
        console.log("\n========================================");
        console.log("  Summary: Created", createdMarkets.length, "markets");
        console.log("========================================");
        for (uint256 i = 0; i < createdMarkets.length; i++) {
            console.log("  ", i + 1, ":", createdMarkets[i]);
        }
    }

    function _createWDLPariMarket(string memory matchId, uint256 kickoff) internal {
        // 创建空的 outcomeRules 数组（使用模板默认值）
        IMarket_V3.OutcomeRule[] memory emptyRules = new IMarket_V3.OutcomeRule[](0);

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: WDL_PARI_TEMPLATE_ID,
            matchId: matchId,
            kickoffTime: kickoff,
            mapperInitData: "",        // 使用模板默认 mapper 配置
            initialLiquidity: 0,       // 彩池模式不需要初始流动性
            outcomeRules: emptyRules   // 使用模板默认 outcome 规则
        });

        address market = factory.createMarket(params);
        createdMarkets.push(market);
        console.log("   Created WDL_Pari:", market, "- ", matchId);
    }

    function _createScorePariMarket(string memory matchId, uint256 kickoff) internal {
        // 创建空的 outcomeRules 数组（使用模板默认值）
        IMarket_V3.OutcomeRule[] memory emptyRules = new IMarket_V3.OutcomeRule[](0);

        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: SCORE_PARI_TEMPLATE_ID,
            matchId: matchId,
            kickoffTime: kickoff,
            mapperInitData: "",        // 使用模板默认 mapper 配置
            initialLiquidity: 0,       // 彩池模式不需要初始流动性
            outcomeRules: emptyRules   // 使用模板默认 outcome 规则
        });

        address market = factory.createMarket(params);
        createdMarkets.push(market);
        console.log("   Created Score_Pari:", market, "- ", matchId);
    }
}
