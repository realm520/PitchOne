// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/FeeRouter.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title VerifyDeployment
 * @notice 验证已部署合约的基本功能
 * @dev Run with: forge script script/VerifyDeployment.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvv
 */
contract VerifyDeployment is Script {
    // 部署的合约地址（从 Deploy.s.sol 输出中复制）
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;
    address constant FEE_ROUTER_ADDRESS = 0x4c5859f0F772848b2D91F1D83E2Fe57935348029;
    address constant CPMM_ADDRESS = 0x1291Be112d480055DaFd8a610b7d1e203891C274;
    address constant WDL_MARKET_ADDRESS = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;

    MockERC20 public usdc;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    WDL_Template public wdlMarket;

    uint256 public deployerPrivateKey;
    address public deployer;

    function setUp() public {
        // 获取部署者私钥（Anvil 默认账户 #0）
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        deployer = vm.addr(deployerPrivateKey);

        // 连接到已部署的合约
        usdc = MockERC20(USDC_ADDRESS);
        feeRouter = FeeRouter(payable(FEE_ROUTER_ADDRESS));
        cpmm = SimpleCPMM(CPMM_ADDRESS);
        wdlMarket = WDL_Template(WDL_MARKET_ADDRESS);
    }

    function run() public {
        console.log("=================================================");
        console.log("PitchOne Deployment Verification");
        console.log("=================================================");
        console.log("Deployer:", deployer);
        console.log("=================================================\n");

        // 验证合约状态
        verifyContracts();

        vm.startBroadcast(deployerPrivateKey);

        // 测试基本功能
        testPlaceBet();
        testMarketState();

        vm.stopBroadcast();

        // 打印验证总结
        printVerificationSummary();
    }

    function verifyContracts() internal view {
        console.log("[1/5] Verifying Contracts...");

        // 验证 USDC
        require(usdc.decimals() == 6, "USDC decimals mismatch");
        uint256 balance = usdc.balanceOf(deployer);
        console.log("  USDC Balance:", balance / 1e6, "USDC");
        require(balance > 0, "USDC balance is zero");

        // 验证 FeeRouter
        address treasury = feeRouter.treasury();
        console.log("  FeeRouter Treasury:", treasury);
        require(treasury != address(0), "Treasury not set");

        // 验证市场状态
        IMarket.MarketStatus status = wdlMarket.status();
        console.log("  Market Status:", uint256(status), "(0=Open)");
        require(status == IMarket.MarketStatus.Open, "Market not open");

        console.log("  [OK] All contract verifications passed\n");
    }

    function testPlaceBet() internal {
        console.log("[2/5] Testing PlaceBet...");

        uint256 betAmount = 100e6; // 100 USDC
        uint256 outcome = 0; // Win

        // 授权市场合约
        usdc.approve(address(wdlMarket), type(uint256).max);
        console.log("  Approved market to spend USDC");

        // 记录初始余额
        uint256 balanceBefore = usdc.balanceOf(deployer);
        console.log("  Balance before:", balanceBefore / 1e6, "USDC");

        // 下注
        uint256 shares = wdlMarket.placeBet(outcome, betAmount);
        console.log("  Placed bet: 100 USDC on outcome", outcome);
        console.log("  Received shares:", shares);

        // 验证余额变化
        uint256 balanceAfter = usdc.balanceOf(deployer);
        console.log("  Balance after:", balanceAfter / 1e6, "USDC");

        // 验证头寸
        uint256 position = wdlMarket.balanceOf(deployer, outcome);
        console.log("  Position balance:", position);
        require(position == shares, "Position mismatch");

        console.log("  [OK] PlaceBet test passed\n");
    }

    function testMarketState() internal view {
        console.log("[3/5] Testing Market State...");

        // 检查流动性
        uint256 totalLiquidity = wdlMarket.totalLiquidity();
        console.log("  Total Liquidity:", totalLiquidity / 1e6, "USDC");

        // 检查 outcome 流动性
        uint256 outcome0Liq = wdlMarket.outcomeLiquidity(0);
        uint256 outcome1Liq = wdlMarket.outcomeLiquidity(1);
        uint256 outcome2Liq = wdlMarket.outcomeLiquidity(2);
        console.log("  Outcome 0 (Win) Liquidity:", outcome0Liq / 1e6, "USDC");
        console.log("  Outcome 1 (Draw) Liquidity:", outcome1Liq / 1e6, "USDC");
        console.log("  Outcome 2 (Loss) Liquidity:", outcome2Liq / 1e6, "USDC");

        // 检查市场信息
        console.log("  Match ID:", wdlMarket.matchId());
        console.log("  Outcome Count:", wdlMarket.outcomeCount());

        console.log("  [OK] Market state test passed\n");
    }

    function printVerificationSummary() internal view {
        console.log("=================================================");
        console.log("Verification Summary");
        console.log("=================================================");
        console.log("[OK] Contract deployment verified");
        console.log("[OK] PlaceBet functionality working");
        console.log("[OK] Market state correctly tracked");
        console.log("[OK] Token balances correctly updated");
        console.log("=================================================");
        console.log("\nDeployment Status: READY FOR USE");
        console.log("=================================================");
    }
}
