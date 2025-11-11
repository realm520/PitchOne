// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/growth/Campaign.sol";
import "../src/growth/Quest.sol";
import "../src/tokens/CreditToken.sol";
import "../src/tokens/Coupon.sol";
import "../src/growth/PayoutScaler.sol";

/**
 * @title DeployM2
 * @notice 部署 M2 运营闭环相关合约
 * @dev 部署 Campaign, Quest, CreditToken, Coupon, PayoutScaler
 *
 * 使用方法：
 *   1. Anvil 本地测试（需要先部署基础合约获取 USDC 地址）：
 *      forge script script/DeployM2.s.sol:DeployM2 --rpc-url http://localhost:8545 --broadcast
 *
 *   2. 主网部署：
 *      forge script script/DeployM2.s.sol:DeployM2 --rpc-url $RPC_URL --broadcast --verify
 *
 * 环境变量：
 *   - PRIVATE_KEY: 部署账户私钥（必需）
 *   - USDC_ADDRESS: USDC 代币地址（可选，默认从 deployments/localhost.json 读取）
 */
contract DeployM2 is Script {
    struct DeployedContracts {
        address campaign;
        address quest;
        address creditToken;
        address coupon;
        address payoutScaler;
    }

    function getUSDCAddress() internal view returns (address) {
        // 尝试从环境变量读取
        address usdcFromEnv = vm.envOr("USDC_ADDRESS", address(0));
        if (usdcFromEnv != address(0)) {
            return usdcFromEnv;
        }

        // 从部署文件读取（仅限本地测试）
        if (block.chainid == 31337) {
            // 这里需要手动设置或从 JSON 解析
            // 临时方案：返回测试地址，实际应该从 deployments/localhost.json 读取
            return address(0x2b639Cc84e1Ad3aA92D4Ee7d2755A6ABEf300D72);
        }

        revert("USDC_ADDRESS not set");
    }

    function run() external returns (DeployedContracts memory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("\n========================================");
        console.log("  PitchOne M2 Contracts Deployment");
        console.log("========================================");
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance / 1e18, "ETH");
        console.log("\n");

        // 获取 USDC 地址
        address usdc = getUSDCAddress();
        console.log("USDC Address:", usdc);

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // 1. 部署 Campaign
        // ========================================
        console.log("\nStep 1: Deploy Campaign");
        console.log("----------------------------------------");
        Campaign campaign = new Campaign(deployer);
        console.log("Campaign:", address(campaign));

        // ========================================
        // 2. 部署 Quest
        // ========================================
        console.log("\nStep 2: Deploy Quest");
        console.log("----------------------------------------");
        Quest quest = new Quest(deployer, address(campaign));
        console.log("Quest:", address(quest));

        // ========================================
        // 3. 部署 CreditToken
        // ========================================
        console.log("\nStep 3: Deploy CreditToken");
        console.log("----------------------------------------");
        CreditToken creditToken = new CreditToken("https://pitchone.io/api/credit/{id}.json");
        console.log("CreditToken:", address(creditToken));

        // ========================================
        // 4. 部署 Coupon
        // ========================================
        console.log("\nStep 4: Deploy Coupon");
        console.log("----------------------------------------");
        Coupon coupon = new Coupon("https://pitchone.io/api/coupon/{id}.json");
        console.log("Coupon:", address(coupon));

        // ========================================
        // 5. 部署 PayoutScaler
        // ========================================
        console.log("\nStep 5: Deploy PayoutScaler");
        console.log("----------------------------------------");
        PayoutScaler payoutScaler = new PayoutScaler(usdc, deployer);
        console.log("PayoutScaler:", address(payoutScaler));

        vm.stopBroadcast();

        // ========================================
        // 6. 输出部署摘要
        // ========================================
        console.log("\n========================================");
        console.log("  Deployment Summary");
        console.log("========================================");
        console.log("\nM2 Contracts:");
        console.log("  Campaign:", address(campaign));
        console.log("  Quest:", address(quest));
        console.log("  CreditToken:", address(creditToken));
        console.log("  Coupon:", address(coupon));
        console.log("  PayoutScaler:", address(payoutScaler));

        console.log("\n========================================");
        console.log("  Next Steps:");
        console.log("========================================");
        console.log("1. Update contracts/deployments/localhost.json with new addresses");
        console.log("2. Update subgraph/subgraph.yaml with new data sources");
        console.log("3. Run subgraph codegen and deploy");
        console.log("========================================\n");

        return DeployedContracts({
            campaign: address(campaign),
            quest: address(quest),
            creditToken: address(creditToken),
            coupon: address(coupon),
            payoutScaler: address(payoutScaler)
        });
    }
}
