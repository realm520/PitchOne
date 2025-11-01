// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/OU_Template.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title DeployOUMarket
 * @notice 部署 OU (Over/Under) 市场示例
 * @dev 演示如何创建大小球市场(半球盘和整数盘)
 *
 * 使用方法:
 *   # 部署半球盘市场 (2.5球)
 *   forge script script/DeployOUMarket.s.sol:DeployOUMarket --sig "deployHalfLine()" --rpc-url $RPC_URL --broadcast -vvvv
 *
 *   # 部署整数盘市场 (2.0球)
 *   forge script script/DeployOUMarket.s.sol:DeployOUMarket --sig "deployIntegerLine()" --rpc-url $RPC_URL --broadcast -vvvv
 */
contract DeployOUMarket is Script {
    // 环境变量
    address public usdc;
    address public feeRouter;
    address public cpmm;
    address public referralRegistry;

    // 市场参数
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    function setUp() public {
        // 从环境变量或使用默认值
        usdc = vm.envOr("USDC_ADDRESS", address(0));
        feeRouter = vm.envOr("FEE_ROUTER_ADDRESS", address(0));
        cpmm = vm.envOr("CPMM_ADDRESS", address(0));
        referralRegistry = vm.envOr("REFERRAL_REGISTRY_ADDRESS", address(0));
    }

    /**
     * @notice 部署半球盘市场 (2.5球)
     */
    function deployHalfLine() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 kickoffTime = block.timestamp + 24 hours;
        uint256 line = 2500; // 2.5球

        vm.startBroadcast(deployerPrivateKey);

        // 如果依赖未部署,先部署
        _ensureDependencies();

        // 部署 OU 市场
        OU_Template market = new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            line,
            usdc,
            feeRouter,
            FEE_RATE,
            DISPUTE_PERIOD,
            cpmm,
            URI
        );

        vm.stopBroadcast();

        console.log("====================================");
        console.log("OU Market (Half-Line 2.5) Deployed:");
        console.log("====================================");
        console.log("Market Address:", address(market));
        console.log("Match:", HOME_TEAM, "vs", AWAY_TEAM);
        console.log("Line: 2.5 goals");
        console.log("Kickoff Time:", kickoffTime);
        console.log("Fee Rate: 2%");
        console.log("====================================");
    }

    /**
     * @notice 部署整数盘市场 (2.0球)
     */
    function deployIntegerLine() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 kickoffTime = block.timestamp + 24 hours;
        uint256 line = 2000; // 2.0球

        vm.startBroadcast(deployerPrivateKey);

        // 如果依赖未部署,先部署
        _ensureDependencies();

        // 部署 OU 市场
        OU_Template market = new OU_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            line,
            usdc,
            feeRouter,
            FEE_RATE,
            DISPUTE_PERIOD,
            cpmm,
            URI
        );

        vm.stopBroadcast();

        console.log("====================================");
        console.log("OU Market (Integer-Line 2.0) Deployed:");
        console.log("====================================");
        console.log("Market Address:", address(market));
        console.log("Match:", HOME_TEAM, "vs", AWAY_TEAM);
        console.log("Line: 2.0 goals (Push possible)");
        console.log("Kickoff Time:", kickoffTime);
        console.log("Fee Rate: 2%");
        console.log("====================================");
    }

    function _ensureDependencies() internal {
        // 部署 USDC (如果未设置)
        if (usdc == address(0)) {
            MockERC20 usdcToken = new MockERC20("USD Coin", "USDC", 6);
            usdc = address(usdcToken);
            console.log("USDC deployed at:", usdc);
        }

        // 部署 CPMM (如果未设置)
        if (cpmm == address(0)) {
            SimpleCPMM cpmmEngine = new SimpleCPMM();
            cpmm = address(cpmmEngine);
            console.log("CPMM deployed at:", cpmm);
        }

        // 部署 ReferralRegistry (如果未设置)
        if (referralRegistry == address(0)) {
            ReferralRegistry registry = new ReferralRegistry(msg.sender);
            referralRegistry = address(registry);
            console.log("ReferralRegistry deployed at:", referralRegistry);
        }

        // 部署 FeeRouter (如果未设置)
        if (feeRouter == address(0)) {
            FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
                lpVault: msg.sender,
                promoPool: msg.sender,
                insuranceFund: msg.sender,
                treasury: msg.sender
            });
            FeeRouter router = new FeeRouter(recipients, referralRegistry);
            feeRouter = address(router);
            console.log("FeeRouter deployed at:", feeRouter);
        }
    }
}
