// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/ReferralRegistry.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title SetupReferrals
 * @notice 为测试用户建立推荐关系
 * @dev 使用 Anvil 默认账户，账户 #0 作为推荐人，其他账户作为被推荐人
 *
 * 使用方法：
 *   forge script script/SetupReferrals.s.sol:SetupReferrals --rpc-url http://localhost:8545 --broadcast
 *
 * 推荐关系结构：
 *   账户 #0 (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) - 推荐人
 *   账户 #1-9 - 被推荐人（绑定到账户 #0）
 */
contract SetupReferrals is Script {
    // Deployment JSON 路径
    string constant DEPLOYMENT_FILE = "deployments/localhost.json";

    // Anvil 默认账户私钥（10个）
    uint256[] private testPrivateKeys = [
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, // #0 - 推荐人
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d, // #1
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a, // #2
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6, // #3
        0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a, // #4
        0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba, // #5
        0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e, // #6
        0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356, // #7
        0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97, // #8
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6  // #9
    ];

    function run() external {
        console.log("\n========================================");
        console.log("  Setup Referral Relationships");
        console.log("========================================\n");

        // 读取部署配置文件
        string memory deploymentJson = vm.readFile(DEPLOYMENT_FILE);
        address registryAddr = vm.parseJsonAddress(deploymentJson, ".shared.referralRegistry");

        ReferralRegistry registry = ReferralRegistry(registryAddr);

        // 账户 #0 作为推荐人
        address referrer = vm.addr(testPrivateKeys[0]);

        console.log("Configuration:");
        console.log("  ReferralRegistry:", registryAddr);
        console.log("  Referrer (Account #0):", referrer);
        console.log("");

        uint256 successCount = 0;
        uint256 failCount = 0;

        // 为账户 #1-9 绑定推荐关系
        for (uint256 i = 1; i < testPrivateKeys.length; i++) {
            address referee = vm.addr(testPrivateKeys[i]);

            // 检查是否已经绑定
            address existingReferrer = registry.referrer(referee);
            if (existingReferrer != address(0)) {
                console.log("  Account #%d (%s) already bound to %s", i, referee, existingReferrer);
                continue;
            }

            // 使用被推荐人的私钥进行绑定
            vm.startBroadcast(testPrivateKeys[i]);

            try registry.bind(referrer, 0) {
                console.log("  [SUCCESS] Account #%d (%s) bound to referrer", i, referee);
                successCount++;
            } catch Error(string memory reason) {
                console.log("  [FAILED] Account #%d (%s): %s", i, referee, reason);
                failCount++;
            } catch {
                console.log("  [FAILED] Account #%d (%s): Unknown error", i, referee);
                failCount++;
            }

            vm.stopBroadcast();
        }

        console.log("\n========================================");
        console.log("  Summary");
        console.log("========================================");
        console.log("  Successful Bindings:", successCount);
        console.log("  Failed Bindings:", failCount);
        console.log("  Total Attempted:", successCount + failCount);

        // 验证绑定结果
        console.log("\n========================================");
        console.log("  Verification");
        console.log("========================================");

        (uint256 referralCount, uint256 totalRewards) = registry.getReferrerStats(referrer);
        console.log("  Referrer Stats:");
        console.log("    Referral Count:", referralCount);
        console.log("    Total Rewards:", totalRewards);

        console.log("");
    }
}
