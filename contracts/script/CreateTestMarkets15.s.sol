// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketTemplateRegistry.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CreateTestMarkets15
 * @notice 创建 15 个测试市场（3 种类型各 5 个），不重新注册模板
 */
contract CreateTestMarkets15 is Script {
    // 部署地址（从环境或之前部署中获取）
    address constant REGISTRY_ADDR = 0xF32D39ff9f6Aa7a7A64d7a4F00a54826Ef791a55;
    address constant USDC_ADDR = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant FEE_ROUTER_ADDR = 0x8A93d247134d91e0de6f96547cB0204e5BE8e5D8;

    // 模板 ID (从链上查询得到)
    bytes32 constant WDL_TEMPLATE_ID = 0x7334184f034ef6984c34eb62c58e3516a2f6130b338d0c0c6ed9cbf862c0a052;
    bytes32 constant OU_TEMPLATE_ID = 0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f;
    bytes32 constant ODDEVEN_TEMPLATE_ID = 0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b;

    // 10 个下注者的私钥
    uint256[] betterPrivateKeys = [
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a,
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
        0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a,
        0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba,
        0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e,
        0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356,
        0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97,
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6,
        0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897
    ];

    function run() external {
        // 使用 Anvil 默认账户 #0 的私钥
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        MarketTemplateRegistry registry = MarketTemplateRegistry(REGISTRY_ADDR);
        MockERC20 usdc = MockERC20(USDC_ADDR);

        console.log("Creating 15 test markets...");
        console.log("Registry:", address(registry));
        console.log("USDC:", address(usdc));

        // 创建 5 个 WDL 市场
        console.log("\n=== Creating 5 WDL Markets ===");
        for (uint256 i = 0; i < 5; i++) {
            string memory matchId = string(abi.encodePacked("WDL_TEST_", vm.toString(i)));
            string memory homeTeam = i % 2 == 0 ? "Team A" : "Team B";
            string memory awayTeam = i % 2 == 0 ? "Team C" : "Team D";

            address marketAddr = registry.createMarket(
                WDL_TEMPLATE_ID,
                abi.encode(
                    matchId,
                    homeTeam,
                    awayTeam,
                    block.timestamp + (i + 1) * 1 hours,
                    address(usdc),
                    FEE_ROUTER_ADDR,
                    200, // 2% fee
                    7200, // 2 hour dispute period
                    address(0), // pricing engine (will be set by template)
                    "https://pitchone.xyz/metadata/"
                )
            );

            console.log("  WDL Market", i, "created:", marketAddr);

            // 10 个地址下注
            placeBets(usdc, marketAddr, 3, deployerPrivateKey);

            // 锁定和结算部分市场
            if (i < 2) {
                WDL_Template(marketAddr).lock();
                console.log("    Locked");
            }
            if (i == 0 || i == 3) {
                WDL_Template(marketAddr).lock();
                WDL_Template(marketAddr).resolve(1); // 平局
                console.log("    Resolved (outcome: 1)");
            }
        }

        // 创建 5 个 OU 市场
        console.log("\n=== Creating 5 OU Markets ===");
        for (uint256 i = 0; i < 5; i++) {
            string memory matchId = string(abi.encodePacked("OU_TEST_", vm.toString(i)));
            string memory homeTeam = "Home Team";
            string memory awayTeam = "Away Team";

            address marketAddr = registry.createMarket(
                OU_TEMPLATE_ID,
                abi.encode(
                    matchId,
                    homeTeam,
                    awayTeam,
                    block.timestamp + (i + 1) * 1 hours,
                    2500, // 2.5 goals
                    true, // is half line
                    address(usdc),
                    FEE_ROUTER_ADDR,
                    200,
                    7200,
                    address(0),
                    "https://pitchone.xyz/metadata/"
                )
            );

            console.log("  OU Market", i, "created:", marketAddr);

            placeBets(usdc, marketAddr, 2, deployerPrivateKey);

            if (i == 1 || i == 4) {
                OU_Template(marketAddr).lock();
                console.log("    Locked");
            }
            if (i == 2) {
                OU_Template(marketAddr).lock();
                OU_Template(marketAddr).resolve(0); // Over
                console.log("    Resolved (outcome: 0)");
            }
        }

        // 创建 5 个 OddEven 市场
        console.log("\n=== Creating 5 OddEven Markets ===");
        for (uint256 i = 0; i < 5; i++) {
            string memory matchId = string(abi.encodePacked("ODDEVEN_TEST_", vm.toString(i)));

            address marketAddr = registry.createMarket(
                ODDEVEN_TEMPLATE_ID,
                abi.encode(
                    matchId,
                    "Home Team",
                    "Away Team",
                    block.timestamp + (i + 1) * 1 hours,
                    address(usdc),
                    FEE_ROUTER_ADDR,
                    200,
                    7200,
                    address(0),
                    "https://pitchone.xyz/metadata/"
                )
            );

            console.log("  OddEven Market", i, "created:", marketAddr);

            placeBets(usdc, marketAddr, 2, deployerPrivateKey);

            if (i == 0 || i == 3) {
                OddEven_Template(marketAddr).lock();
                console.log("    Locked");
            }
            if (i == 4) {
                OddEven_Template(marketAddr).lock();
                OddEven_Template(marketAddr).resolve(1); // Even
                console.log("    Resolved (outcome: 1)");
            }
        }

        vm.stopBroadcast();

        console.log("\n=== Summary ===");
        console.log("Total markets created: 15");
        console.log("WDL: 5 (2 locked, 2 resolved)");
        console.log("OU: 5 (2 locked, 1 resolved)");
        console.log("OddEven: 5 (2 locked, 1 resolved)");
    }

    function placeBets(
        MockERC20 usdc,
        address marketAddr,
        uint256 numOutcomes,
        uint256 deployerPK
    ) internal {
        console.log("   Placing bets from 10 addresses...");

        for (uint256 i = 0; i < 10; i++) {
            uint256 betterPK = betterPrivateKeys[i];
            address better = vm.addr(betterPK);

            // 随机选择结果
            uint256 outcome = uint256(keccak256(abi.encodePacked(better, i, marketAddr))) % numOutcomes;

            // 随机金额 50-500 USDC
            uint256 amount = 50e6 + (uint256(keccak256(abi.encodePacked(better, i, block.timestamp))) % 450e6);

            vm.stopBroadcast();
            vm.startBroadcast(betterPK);

            usdc.approve(marketAddr, amount);

            // 下注
            try WDL_Template(marketAddr).placeBet(outcome, amount) {
                // Success
            } catch {
                // Might fail if market is locked or other reason
            }

            vm.stopBroadcast();
            vm.startBroadcast(deployerPK);
        }
    }
}
