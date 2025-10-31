// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployNewMarket
 * @notice 部署新的 WDL 市场实例（重用现有基础设施）
 * @dev Run with: forge script script/DeployNewMarket.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract DeployNewMarket is Script {
    // 现有合约地址
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;
    address constant FEE_ROUTER_ADDRESS = 0x4c5859f0F772848b2D91F1D83E2Fe57935348029;
    address constant CPMM_ADDRESS = 0x1291Be112d480055DaFd8a610b7d1e203891C274;

    // 市场参数
    string public matchId = "EPL_2025_MUN_vs_LIV_TEST2";
    string public homeTeam = "Manchester United";
    string public awayTeam = "Liverpool";
    uint256 public kickoffTime;

    WDL_Template public wdlMarket;
    uint256 public deployerPrivateKey;

    function setUp() public {
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // 设置开球时间为当前时间 + 5 分钟（300 秒）
        // 这给我们足够时间完成所有下注操作
        kickoffTime = block.timestamp + 300;
    }

    function run() public {
        console.log("=================================================");
        console.log("Deploy New WDL Market");
        console.log("=================================================");
        console.log("Using existing infrastructure:");
        console.log("  USDC:      ", USDC_ADDRESS);
        console.log("  FeeRouter: ", FEE_ROUTER_ADDRESS);
        console.log("  CPMM:      ", CPMM_ADDRESS);
        console.log("");
        console.log("Current Time:  ", block.timestamp);
        console.log("Kickoff Time:  ", kickoffTime);
        console.log("Buffer:        ", kickoffTime - block.timestamp, "seconds");
        console.log("=================================================");

        vm.startBroadcast(deployerPrivateKey);

        // 部署新的 WDL 市场
        wdlMarket = new WDL_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            USDC_ADDRESS,           // settlement token
            FEE_ROUTER_ADDRESS,     // fee recipient
            200,                    // 2% fee rate (in basis points)
            2 hours,                // dispute period (7200 seconds)
            CPMM_ADDRESS,           // pricing engine
            ""                      // uri (empty for now)
        );

        console.log("");
        console.log("[OK] New WDL Market deployed at:", address(wdlMarket));
        console.log("");

        vm.stopBroadcast();

        printMarketInfo();
    }

    function printMarketInfo() internal view {
        console.log("=================================================");
        console.log("Market Configuration");
        console.log("=================================================");
        console.log("Match ID:      ", matchId);
        console.log("Home Team:     ", homeTeam);
        console.log("Away Team:     ", awayTeam);
        console.log("Kickoff Time:  ", kickoffTime);
        console.log("Status:        ", uint256(wdlMarket.status()), "(0=Open)");
        console.log("Dispute Period:", wdlMarket.disputePeriod() / 3600, "hours");
        console.log("Fee Rate:      ", wdlMarket.feeRate(), "bps (2%)");
        console.log("=================================================");
        console.log("");
        console.log("Next steps:");
        console.log("1. Save market address:", address(wdlMarket));
        console.log("2. Run MultiUserBetting.s.sol to place bets");
        console.log("3. Wait until kickoff time to lock market");
        console.log("=================================================");
    }
}
