// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {OU_MultiLine} from "../src/templates/OU_MultiLine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AddPushLiquidity
 * @notice 为 OU_MultiLine 市场的整数盘退款选项补充流动性
 */
contract AddPushLiquidity is Script {
    // PSG vs Lyon OU_MultiLine 市场地址
    address constant MARKET = 0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00;

    // USDC 地址（从市场合约查询）
    address constant USDC = 0xf5059a5D33d5853360D16C683c16e67980206f36;

    function run() public {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deployer:", deployer);
        console.log("Market:", MARKET);

        vm.startBroadcast(deployerPrivateKey);

        OU_MultiLine market = OU_MultiLine(MARKET);
        IERC20 usdc = IERC20(USDC);

        // 检查当前流动性状态
        console.log("\n=== Before Adding Liquidity ===");
        for (uint256 i = 0; i < 9; i++) {
            console.log("Outcome", i, "liquidity:", market.outcomeLiquidity(i));
        }

        // 准备权重数组：只给退款选项（outcome 2 和 8）分配流动性
        uint256[] memory weights = new uint256[](9);
        weights[0] = 0; // 2.0球 大（已有流动性）
        weights[1] = 0; // 2.0球 小（已有流动性）
        weights[2] = 1; // 2.0球 退款（补充流动性）
        weights[3] = 0; // 2.5球 大（已有流动性）
        weights[4] = 0; // 2.5球 小（已有流动性）
        weights[5] = 0; // 2.5球 退款（半球盘，不需要）
        weights[6] = 0; // 3.0球 大（已有流动性）
        weights[7] = 0; // 3.0球 小（已有流动性）
        weights[8] = 1; // 3.0球 退款（补充流动性）

        // 添加 600 USDC：300 给 2.0球退款，300 给 3.0球退款
        uint256 additionalLiquidity = 600e6;

        // Approve
        usdc.approve(address(market), additionalLiquidity);
        console.log("\n=== Approved", additionalLiquidity / 1e6, "USDC ===");

        // Add liquidity
        market.addLiquidity(additionalLiquidity, weights);
        console.log("Added liquidity for PUSH outcomes");

        // 检查新的流动性状态
        console.log("\n=== After Adding Liquidity ===");
        for (uint256 i = 0; i < 9; i++) {
            console.log("Outcome", i, "liquidity:", market.outcomeLiquidity(i));
        }

        console.log("\n=== Total Liquidity ===");
        console.log("Total:", market.totalLiquidity());

        vm.stopBroadcast();
    }
}
