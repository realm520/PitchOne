// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title CompleteLifecycle
 * @notice 完成已存在市场的生命周期（锁盘 -> 结算 -> 终结 -> 赎回）
 * @dev 分步执行，每步单独广播
 */
contract CompleteLifecycle is Script {
    address constant MARKET_ADDRESS = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;
    address constant USDC_ADDRESS = 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570;

    WDL_Template public market;
    MockERC20 public usdc;

    uint256 public deployerPrivateKey;
    address public deployer;

    function setUp() public {
        deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        deployer = vm.addr(deployerPrivateKey);

        market = WDL_Template(MARKET_ADDRESS);
        usdc = MockERC20(USDC_ADDRESS);
    }

    function run() public {
        console.log("=== Complete Market Lifecycle ===");
        console.log("Market:", address(market));
        console.log("Current Status:", uint256(market.status()));
        console.log("");

        // 根据当前状态决定从哪一步开始
        IMarket.MarketStatus currentStatus = market.status();

        if (currentStatus == IMarket.MarketStatus.Open) {
            console.log("Step 1: Lock Market");
            lockMarket();
        }

        if (currentStatus <= IMarket.MarketStatus.Locked) {
            console.log("Step 2: Resolve Market");
            resolveMarket();
        }

        // 注意：finalize 需要等待争议期，所以单独处理
        console.log("\n=== Next Steps ===");
        console.log("Run the following commands manually:");
        console.log("1. Wait 2 hours or fast-forward time:");
        console.log("   cast rpc anvil_increaseTime 7200 --rpc-url http://127.0.0.1:8545");
        console.log("   cast rpc anvil_mine 1 --rpc-url http://127.0.0.1:8545");
        console.log("");
        console.log("2. Finalize market:");
        console.log("   forge script script/FinalizeMarket.s.sol --rpc-url http://127.0.0.1:8545 --broadcast");
        console.log("");
        console.log("3. Redeem winnings:");
        console.log("   forge script script/RedeemWinnings.s.sol --rpc-url http://127.0.0.1:8545 --broadcast");
    }

    function lockMarket() internal {
        vm.startBroadcast(deployerPrivateKey);

        uint256 kickoff = market.kickoffTime();
        console.log("  Kickoff Time:", kickoff);
        console.log("  Current Time:", block.timestamp);

        if (block.timestamp < kickoff) {
            console.log("  Waiting for kickoff time...");
            console.log("  Need to fast-forward", (kickoff - block.timestamp), "seconds");
            console.log("\n  Run this command first:");
            console.log("  cast rpc anvil_increaseTime", (kickoff - block.timestamp), "--rpc-url http://127.0.0.1:8545");
            console.log("  cast rpc anvil_mine 1 --rpc-url http://127.0.0.1:8545");
            vm.stopBroadcast();
            return;
        }

        market.autoLock();
        console.log("  [OK] Market locked");
        console.log("  Lock Timestamp:", market.lockTimestamp());

        vm.stopBroadcast();
    }

    function resolveMarket() internal {
        vm.startBroadcast(deployerPrivateKey);

        // 结算为 WIN (outcome 0)
        market.resolve(0);
        console.log("  [OK] Market resolved");
        console.log("  Winning Outcome:", market.winningOutcome());

        vm.stopBroadcast();
    }
}
