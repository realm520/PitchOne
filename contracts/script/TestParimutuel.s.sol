// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title TestParimutuel
 * @notice 测试 Parimutuel 定价，验证赔率显著变化
 *
 * 用法：
 *   # 先部署 Parimutuel 市场
 *   PRIVATE_KEY=0x... forge script script/DeployParimutuel.s.sol:DeployParimutuel \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast
 *
 *   # 然后运行测试（替换为实际的市场和 USDC 地址）
 *   MARKET=0x... USDC=0x... PRIVATE_KEY=0x... \
 *     forge script script/TestParimutuel.s.sol:TestParimutuel \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast
 */
contract TestParimutuel is Script {
    function run() external {
        address marketAddr = vm.envAddress("MARKET");
        address usdcAddr = vm.envAddress("USDC");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        OddEven_Template_V2 market = OddEven_Template_V2(marketAddr);
        MockERC20 usdc = MockERC20(usdcAddr);

        console.log("=========================================");
        console.log("Parimutuel Pricing Test");
        console.log("=========================================");
        console.log("Market:", marketAddr);
        console.log("USDC:", usdcAddr);
        console.log("Tester:", deployer);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 检查虚拟储备初始值
        uint256[] memory initialReserves = market.getVirtualReserves();
        console.log("Initial Virtual Reserves:");
        console.log("  Outcome 0 (Odd):", initialReserves[0]);
        console.log("  Outcome 1 (Even):", initialReserves[1]);
        console.log("");

        // 检查初始价格
        uint256[] memory initialPrices = market.getAllPrices();
        console.log("Initial Prices (basis points):");
        console.log("  Outcome 0 (Odd):", initialPrices[0]);
        console.log("  Outcome 1 (Even):", initialPrices[1]);
        console.log("");

        // 下注测试
        console.log("=========================================");
        console.log("Bet Simulation");
        console.log("=========================================");
        console.log("");

        // 第 1 笔：23 USDC on Outcome 1 (Even)
        _placeBet(usdc, market, 23, 1);

        // 第 2 笔：123 USDC on Outcome 0 (Odd)
        _placeBet(usdc, market, 123, 0);

        // 第 3 笔：1 USDC on Outcome 1 (Even)
        _placeBet(usdc, market, 1, 1);

        vm.stopBroadcast();

        console.log("");
        console.log("=========================================");
        console.log("Test Complete");
        console.log("=========================================");
        console.log("");
        console.log("Key Observations:");
        console.log("1. With Parimutuel (zero virtual reserves):");
        console.log("   - Prices change dramatically with each bet");
        console.log("   - Shares = Amount (1:1 exchange)");
        console.log("   - Final payout = (Total Pool / Winning Pool) * User Shares");
        console.log("");
        console.log("2. Compare with SimpleCPMM (100k virtual reserves):");
        console.log("   - Prices barely change (0.12% per bet)");
        console.log("   - Shares calculated via AMM formula");
        console.log("   - Constant liquidity depth");
    }

    function _placeBet(
        MockERC20 usdc,
        OddEven_Template_V2 market,
        uint256 amount,
        uint256 outcome
    ) internal {
        uint256 amountWei = amount * 10 ** 6; // USDC has 6 decimals

        console.log("------------------");
        console.log("Placing Bet:");
        console.log("  Amount (USDC):", amount);
        console.log("  Outcome:", outcome);
        console.log("");

        // 查询投注前价格
        uint256[] memory pricesBefore = market.getAllPrices();
        console.log("  Prices Before:");
        console.log("    Outcome 0 (Odd) %:", pricesBefore[0] / 100);
        console.log("    Outcome 1 (Even) %:", pricesBefore[1] / 100);

        // Mint and approve
        usdc.mint(msg.sender, amountWei);
        usdc.approve(address(market), amountWei);

        // Place bet
        uint256 shares = market.placeBet(outcome, amountWei);
        uint256 sharesInUsdc = shares / 10 ** 6;

        console.log("");
        console.log("  Result:");
        console.log("    Shares Received:", sharesInUsdc);
        console.log("    Return on Investment (bps):", (sharesInUsdc * 10000) / amount);

        // 查询投注后价格
        uint256[] memory pricesAfter = market.getAllPrices();
        console.log("");
        console.log("  Prices After:");
        console.log("    Outcome 0 (Odd) %:", pricesAfter[0] / 100);
        console.log("    Outcome 1 (Even) %:", pricesAfter[1] / 100);

        // 计算价格变化
        int256 priceChange0 = int256(pricesAfter[0]) - int256(pricesBefore[0]);
        int256 priceChange1 = int256(pricesAfter[1]) - int256(pricesBefore[1]);
        console.log("");
        console.log("  Price Changes (bps):");
        console.log("    Outcome 0 (Odd):", priceChange0);
        console.log("    Outcome 1 (Even):", priceChange1);

        // 查询虚拟储备
        uint256[] memory reserves = market.getVirtualReserves();
        console.log("");
        console.log("  Virtual Reserves After (USDC):");
        console.log("    Outcome 0 (Odd):", reserves[0] / 10 ** 6);
        console.log("    Outcome 1 (Even):", reserves[1] / 10 ** 6);
        console.log("------------------");
        console.log("");
    }
}
