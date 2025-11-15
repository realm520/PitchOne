// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/pricing/ParimutuelPricing.sol";
import "../src/templates/OddEven_Template_V2.sol";
import "../src/core/MarketTemplateRegistry.sol";
import "../test/mocks/MockERC20.sol";
import "../src/liquidity/LiquidityVault.sol";

/**
 * @title DeployParimutuel
 * @notice 部署 Parimutuel 定价引擎并创建测试市场
 *
 * 用法：
 *   PRIVATE_KEY=0x... forge script script/DeployParimutuel.s.sol:DeployParimutuel \
 *     --rpc-url http://localhost:8545 \
 *     --broadcast
 */
contract DeployParimutuel is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        console.log("=========================================");
        console.log("Parimutuel Pricing Deployment");
        console.log("=========================================");
        console.log("Deployer:", deployer);
        console.log("");

        // 1. 部署 ParimutuelPricing
        console.log("1. Deploying ParimutuelPricing...");
        ParimutuelPricing parimutuel = new ParimutuelPricing();
        console.log("   ParimutuelPricing:", address(parimutuel));
        console.log("");

        // 2. 部署测试 USDC（如果需要）
        console.log("2. Deploying Mock USDC...");
        MockERC20 usdc = new MockERC20("Mock USDC", "USDC", 6);
        console.log("   USDC:", address(usdc));
        console.log("");

        // 3. 部署 LiquidityVault
        console.log("3. Deploying LiquidityVault...");
        LiquidityVault vault = new LiquidityVault(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );
        console.log("   Vault:", address(vault));
        console.log("");

        // 4. 创建 Parimutuel 测试市场（虚拟储备为 0）
        console.log("4. Creating Parimutuel Market (Zero Virtual Reserves)...");

        OddEven_Template_V2 parimutuelMarket = new OddEven_Template_V2();
        parimutuelMarket.initialize(
            "TEST_PARIMUTUEL",      // matchId
            "Team A",                // homeTeam
            "Team B",                // awayTeam
            block.timestamp + 1 days, // kickoffTime
            address(usdc),           // settlementToken
            deployer,                // feeRecipient
            200,                     // feeRate (2%)
            2 hours,                 // disputePeriod
            address(parimutuel),     // pricingEngine
            address(vault),          // vault
            "",                      // uri
            0                        // virtualReservePerSide = 0 (Parimutuel 模式)
        );

        console.log("   Parimutuel Market:", address(parimutuelMarket));
        console.log("   Virtual Reserve Per Side: 0 (Parimutuel Mode)");
        console.log("");

        // 5. 创建 SimpleCPMM 对比市场（虚拟储备为 100,000 USDC）
        console.log("5. Creating SimpleCPMM Market for Comparison...");
        console.log("   (This requires SimpleCPMM to be deployed first)");
        console.log("");

        // 6. 授权市场到 Vault
        console.log("6. Authorizing markets to Vault...");
        vault.authorizeMarket(address(parimutuelMarket));
        console.log("   Parimutuel Market authorized");
        console.log("");

        // 7. Mint 一些 USDC 给部署者用于测试
        console.log("7. Minting test USDC...");
        usdc.mint(deployer, 10_000 * 10 ** 6); // 10,000 USDC
        console.log("   Minted 10,000 USDC to deployer");
        console.log("");

        vm.stopBroadcast();

        console.log("=========================================");
        console.log("Deployment Summary");
        console.log("=========================================");
        console.log("ParimutuelPricing:", address(parimutuel));
        console.log("USDC:", address(usdc));
        console.log("Vault:", address(vault));
        console.log("Parimutuel Market:", address(parimutuelMarket));
        console.log("");
        console.log("Next Steps:");
        console.log("1. Place bets to test Parimutuel pricing");
        console.log("2. Compare with SimpleCPMM market");
        console.log("3. Verify odds change dramatically with each bet");
    }
}
