// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_v2.sol";
import "../src/interfaces/IMarket.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title SimulateBets
 * @notice 模拟多用户多市场下注，生成测试数据
 * @dev 支持多种模拟参数配置
 *
 * 使用方法：
 *   1. 确保已运行 Deploy.s.sol 和 CreateMarkets.s.sol，并生成了 deployments/localhost.json
 *   2. 脚本会自动从 deployments/localhost.json 读取 Factory 和 USDC 地址
 *   3. 设置环境变量（可选）：
 *      export NUM_BETTORS=10          # 下注用户数量
 *      export MIN_BET_AMOUNT=5        # 最小下注金额（USDC）
 *      export MAX_BET_AMOUNT=50       # 最大下注金额（USDC）
 *      export BETS_PER_USER=3         # 每个用户平均下注次数
 *      export OUTCOME_DISTRIBUTION=balanced  # 结果分布：balanced/skewed/random
 *   4. 运行脚本：
 *      forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast
 *
 * 模拟参数说明：
 *   - NUM_BETTORS: 参与下注的用户数量（默认 10）
 *   - MIN/MAX_BET_AMOUNT: 单次下注金额范围（默认 5-50 USDC）
 *   - BETS_PER_USER: 每个用户平均下注次数（默认 3）
 *   - OUTCOME_DISTRIBUTION:
 *     - balanced: 各选项均匀分布
 *     - skewed: 热门选项占比高（70%/20%/10%）
 *     - random: 完全随机分布
 *   - SKIP_LOCKED_MARKETS: 跳过已锁定的市场（默认 true）
 */
contract SimulateBets is Script {
    // Deployment JSON 路径
    string constant DEPLOYMENT_FILE = "deployments/localhost.json";

    // Anvil 默认账户私钥（10个）
    uint256[] private testPrivateKeys = [
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80, // #0
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

    // 下注统计
    struct BettingStats {
        uint256 totalBets;
        uint256 totalVolume;
        uint256 successfulBets;
        uint256 failedBets;
        uint256 skippedMarkets;
    }

    function run() external {
        console.log("\n========================================");
        console.log("  Simulate Multi-User Betting");
        console.log("========================================\n");

        // 读取部署配置文件
        string memory deploymentJson = vm.readFile(DEPLOYMENT_FILE);
        address factoryAddr = vm.parseJsonAddress(deploymentJson, ".contracts.factory");
        address usdcAddr = vm.parseJsonAddress(deploymentJson, ".contracts.usdc");
        uint256 numBettors = vm.envOr("NUM_BETTORS", uint256(10));
        uint256 minBetAmount = vm.envOr("MIN_BET_AMOUNT", uint256(5)) * 1e6;
        uint256 maxBetAmount = vm.envOr("MAX_BET_AMOUNT", uint256(50)) * 1e6;
        uint256 betsPerUser = vm.envOr("BETS_PER_USER", uint256(3));
        bool skipLocked = vm.envOr("SKIP_LOCKED_MARKETS", true);

        string memory distribution = vm.envOr("OUTCOME_DISTRIBUTION", string("balanced"));

        // 限制用户数量
        if (numBettors > testPrivateKeys.length) {
            numBettors = testPrivateKeys.length;
            console.log("Warning: NUM_BETTORS limited to", testPrivateKeys.length);
        }

        console.log("Configuration:");
        console.log("  Factory:", factoryAddr);
        console.log("  USDC:", usdcAddr);
        console.log("  Bettors:", numBettors);
        console.log("  Min Bet Amount (USDC):", minBetAmount / 1e6);
        console.log("  Max Bet Amount (USDC):", maxBetAmount / 1e6);
        console.log("  Bets per User:", betsPerUser);
        console.log("  Distribution:", distribution);
        console.log("  Skip Locked:", skipLocked);
        console.log("");

        MarketFactory_v2 factory = MarketFactory_v2(factoryAddr);
        MockERC20 usdc = MockERC20(usdcAddr);

        // 获取所有市场
        uint256 marketCount = factory.getMarketCount();
        console.log("Total Markets:", marketCount);
        console.log("");

        if (marketCount == 0) {
            console.log("No markets found. Please run CreateMarkets.s.sol first.");
            return;
        }

        // 构建可用市场列表
        address[] memory availableMarkets = new address[](marketCount);
        uint256 availableCount = 0;

        for (uint256 i = 0; i < marketCount; i++) {
            address marketAddr = factory.getMarket(i);
            IMarket market = IMarket(marketAddr);

            try market.status() returns (IMarket.MarketStatus status) {
                if (status == IMarket.MarketStatus.Open || !skipLocked) {
                    availableMarkets[availableCount] = marketAddr;
                    availableCount++;
                }
            } catch {}
        }

        console.log("Available Markets:", availableCount);
        if (availableCount == 0) {
            console.log("No available markets for betting.");
            return;
        }
        console.log("");

        // 开始模拟下注
        BettingStats memory stats;

        console.log("========================================");
        console.log("Simulating Bets...");
        console.log("========================================\n");

        // 为每个用户模拟下注
        for (uint256 u = 0; u < numBettors; u++) {
            uint256 privateKey = testPrivateKeys[u];
            address bettor = vm.addr(privateKey);

            console.log("User #", u + 1, "-", bettor);

            vm.startBroadcast(privateKey);

            // 每个用户下注 betsPerUser 次
            uint256 userBets = 0;
            uint256 userVolume = 0;

            for (uint256 b = 0; b < betsPerUser; b++) {
                // 随机选择市场
                uint256 marketIndex = uint256(keccak256(abi.encodePacked(bettor, b, block.timestamp))) % availableCount;
                address marketAddr = availableMarkets[marketIndex];
                IMarket market = IMarket(marketAddr);

                // 检查市场状态
                IMarket.MarketStatus status;
                try market.status() returns (IMarket.MarketStatus _status) {
                    status = _status;
                } catch {
                    stats.skippedMarkets++;
                    continue;
                }

                if (status != IMarket.MarketStatus.Open) {
                    if (skipLocked) {
                        stats.skippedMarkets++;
                        continue;
                    }
                }

                // 获取结果数量
                uint256 outcomeCount;
                try market.outcomeCount() returns (uint256 _count) {
                    outcomeCount = _count;
                } catch {
                    stats.skippedMarkets++;
                    continue;
                }

                // 选择下注选项
                uint256 outcomeId = selectOutcome(
                    distribution,
                    outcomeCount,
                    bettor,
                    b
                );

                // 生成下注金额
                uint256 betAmount = minBetAmount + (
                    uint256(keccak256(abi.encodePacked(bettor, marketAddr, b))) % (maxBetAmount - minBetAmount)
                );

                // Mint USDC
                usdc.mint(bettor, betAmount);

                // Approve
                usdc.approve(marketAddr, betAmount);

                // 下注
                try market.placeBet(outcomeId, betAmount) returns (uint256 shares) {
                    stats.totalBets++;
                    stats.successfulBets++;
                    stats.totalVolume += betAmount;
                    userBets++;
                    userVolume += betAmount;

                    console.log("  Bet placed successfully");
                    console.log("    Amount (USDC):", betAmount / 1e6);
                    console.log("    Outcome:", outcomeId);
                    console.log("    Shares:", shares / 1e18);
                } catch Error(string memory reason) {
                    stats.totalBets++;
                    stats.failedBets++;
                    console.log("  Bet FAILED:", reason);
                } catch {
                    stats.totalBets++;
                    stats.failedBets++;
                    console.log("  Bet FAILED: Unknown error");
                }
            }

            console.log("  Total bets:", userBets);
            console.log("  Total volume (USDC):", userVolume / 1e6);
            console.log("");

            vm.stopBroadcast();
        }

        // ========================================
        // 输出统计摘要
        // ========================================
        console.log("========================================");
        console.log("  Betting Simulation Summary");
        console.log("========================================");
        console.log("Total Bets:", stats.totalBets);
        console.log("  - Successful:", stats.successfulBets);
        console.log("  - Failed:", stats.failedBets);
        console.log("  - Success Rate:", stats.successfulBets * 100 / stats.totalBets, "%");
        console.log("Total Volume:", stats.totalVolume / 1e6, "USDC");
        console.log("Average Bet Size:", stats.totalVolume / stats.successfulBets / 1e6, "USDC");
        console.log("Skipped Markets:", stats.skippedMarkets);
        console.log("\nDistribution Strategy:", distribution);
        console.log("Active Bettors:", numBettors);
        console.log("========================================\n");
    }

    /**
     * @notice 根据分布策略选择下注选项
     */
    function selectOutcome(
        string memory distribution,
        uint256 outcomeCount,
        address bettor,
        uint256 nonce
    ) internal pure returns (uint256) {
        bytes32 distHash = keccak256(bytes(distribution));
        uint256 rand = uint256(keccak256(abi.encodePacked(bettor, nonce)));

        if (distHash == keccak256(bytes("balanced"))) {
            // 均匀分布
            return rand % outcomeCount;
        } else if (distHash == keccak256(bytes("skewed"))) {
            // 倾斜分布（热门选项）
            uint256 r = rand % 100;
            if (outcomeCount == 2) {
                // 二选一：70% vs 30%
                return r < 70 ? 0 : 1;
            } else if (outcomeCount == 3) {
                // 三选一：60% vs 25% vs 15%
                if (r < 60) return 0;
                if (r < 85) return 1;
                return 2;
            } else {
                // 多选项：第一个占50%，其余平分
                return r < 50 ? 0 : (1 + (rand % (outcomeCount - 1)));
            }
        } else {
            // random: 完全随机
            return rand % outcomeCount;
        }
    }
}
