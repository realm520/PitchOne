// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../src/templates/OU_Template.sol";
import "../src/templates/OddEven_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title TestFullLifecycle
 * @notice Test complete market lifecycle: Bet -> Lock -> Resolve -> Redeem
 * @dev Tests on already deployed markets from CreateTestMarkets.s.sol
 */
contract TestFullLifecycle is Script {
    // Deployed contracts
    address constant USDC = 0x2a810409872AfC346F9B5b26571Fd6eC42EA4849;

    // Markets created by CreateTestMarkets.s.sol
    address constant WDL_MARKET_1 = 0x976fcd02f7C4773dd89C309fBF55D5923B4c98a1;
    address constant WDL_MARKET_2 = 0x32EEce76C2C2e8758584A83Ee2F522D4788feA0f;
    address constant OU_MARKET_1 = 0xFD6F7A6a5c21A3f503EBaE7a473639974379c351;
    address constant OU_MARKET_2 = 0x40a42Baf86Fc821f972Ad2aC878729063CeEF403;
    address constant ODDEVEN_MARKET_1 = 0x870526b7973b56163a6997bB7C886F5E4EA53638;
    address constant ODDEVEN_MARKET_2 = 0xB377a2EeD7566Ac9fCb0BA673604F9BF875e2Bab;

    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerPrivateKey);

        // Use second Anvil test account for betting
        uint256 user1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        address user1 = vm.addr(user1PrivateKey);

        // Use third Anvil test account
        uint256 user2PrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        address user2 = vm.addr(user2PrivateKey);

        console.log("========================================");
        console.log("  Full Market Lifecycle Test");
        console.log("========================================");
        console.log("Deployer:", deployer);
        console.log("User1:", user1);
        console.log("User2:", user2);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ========================================
        // Phase 1: User Betting
        // ========================================
        console.log("Phase 1: User Betting");
        console.log("----------------------------------------");

        testWDLBetting(user1, user2, deployerPrivateKey);
        testOUBetting(user1, user2, deployerPrivateKey);
        testOddEvenBetting(user1, user2, deployerPrivateKey);

        vm.stopBroadcast();

        // ========================================
        // Phase 2: Query Odds and Positions
        // ========================================
        console.log("\nPhase 2: Query Market State");
        console.log("----------------------------------------");

        queryMarketState(WDL_MARKET_1, "WDL Market 1");
        queryMarketState(OU_MARKET_1, "OU Market 1");

        // ========================================
        // Phase 3: Lock Markets
        // ========================================
        console.log("\nPhase 3: Lock Markets");
        console.log("----------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        lockMarket(WDL_MARKET_1, "WDL Market 1");
        lockMarket(OU_MARKET_1, "OU Market 1");
        lockMarket(ODDEVEN_MARKET_1, "OddEven Market 1");

        vm.stopBroadcast();

        // ========================================
        // Phase 4: Resolve Markets
        // ========================================
        console.log("\nPhase 4: Resolve Markets");
        console.log("----------------------------------------");

        vm.startBroadcast(deployerPrivateKey);

        resolveMarket(WDL_MARKET_1, 0, "WDL Market 1 (Home Win)");
        resolveMarket(OU_MARKET_1, 0, "OU Market 1 (Over)");
        resolveMarket(ODDEVEN_MARKET_1, 1, "OddEven Market 1 (Even)");

        vm.stopBroadcast();

        // ========================================
        // Phase 5: User Redemptions
        // ========================================
        console.log("\nPhase 5: User Redemptions");
        console.log("----------------------------------------");

        vm.startBroadcast(user1PrivateKey);
        redeemWinnings(WDL_MARKET_1, user1, 0, "User1 WDL");
        vm.stopBroadcast();

        vm.startBroadcast(user2PrivateKey);
        redeemWinnings(OU_MARKET_1, user2, 0, "User2 OU");
        vm.stopBroadcast();

        // ========================================
        // Summary
        // ========================================
        console.log("\n========================================");
        console.log("  Test Complete!");
        console.log("========================================");
        console.log("\nCheck Subgraph for indexed data:");
        console.log("  http://localhost:8010/subgraphs/id/QmfCkyzR5wQ2uTCM5xEtjDyytF1qudkbPYkD8FRXUZre8q");
        console.log("\nQuery example:");
        console.log('  {"query": "{ markets { id state totalVolume uniqueBettors } }"}');
        console.log("========================================");
    }

    function testWDLBetting(address user1, address user2, uint256 deployerPK) internal {
        WDL_Template market = WDL_Template(WDL_MARKET_1);

        console.log("Testing WDL Market:");
        console.log("  Market:", address(market));

        // User1 bets 100 USDC on Home Win (outcome 0)
        uint256 bet1Amount = 100 * 10 ** 6;
        MockERC20(USDC).mint(user1, bet1Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        MockERC20(USDC).approve(address(market), bet1Amount);
        market.placeBet(0, bet1Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User1 bet 100 USDC on Home Win");

        // User2 bets 150 USDC on Away Win (outcome 2)
        uint256 bet2Amount = 150 * 10 ** 6;
        MockERC20(USDC).mint(user2, bet2Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);
        MockERC20(USDC).approve(address(market), bet2Amount);
        market.placeBet(2, bet2Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User2 bet 150 USDC on Away Win");
    }

    function testOUBetting(address user1, address user2, uint256 deployerPK) internal {
        OU_Template market = OU_Template(OU_MARKET_1);

        console.log("\nTesting OU Market:");
        console.log("  Market:", address(market));

        // User1 bets 200 USDC on Under (outcome 1)
        uint256 bet1Amount = 200 * 10 ** 6;
        MockERC20(USDC).mint(user1, bet1Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        MockERC20(USDC).approve(address(market), bet1Amount);
        market.placeBet(1, bet1Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User1 bet 200 USDC on Under");

        // User2 bets 100 USDC on Over (outcome 0)
        uint256 bet2Amount = 100 * 10 ** 6;
        MockERC20(USDC).mint(user2, bet2Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);
        MockERC20(USDC).approve(address(market), bet2Amount);
        market.placeBet(0, bet2Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User2 bet 100 USDC on Over");
    }

    function testOddEvenBetting(address user1, address user2, uint256 deployerPK) internal {
        OddEven_Template market = OddEven_Template(ODDEVEN_MARKET_1);

        console.log("\nTesting OddEven Market:");
        console.log("  Market:", address(market));

        // User1 bets 50 USDC on Odd (outcome 0)
        uint256 bet1Amount = 50 * 10 ** 6;
        MockERC20(USDC).mint(user1, bet1Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        MockERC20(USDC).approve(address(market), bet1Amount);
        market.placeBet(0, bet1Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User1 bet 50 USDC on Odd");

        // User2 bets 75 USDC on Even (outcome 1)
        uint256 bet2Amount = 75 * 10 ** 6;
        MockERC20(USDC).mint(user2, bet2Amount);

        vm.stopBroadcast();
        vm.startBroadcast(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);
        MockERC20(USDC).approve(address(market), bet2Amount);
        market.placeBet(1, bet2Amount);
        vm.stopBroadcast();
        vm.startBroadcast(deployerPK);

        console.log("  User2 bet 75 USDC on Even");
    }

    function queryMarketState(address marketAddr, string memory name) internal view {
        WDL_Template market = WDL_Template(marketAddr);

        console.log("\n", name, ":");
        console.log("  Address:", marketAddr);
        console.log("  Status:", uint256(market.status()));

        // Query USDC balance of market (total liquidity)
        uint256 balance = MockERC20(USDC).balanceOf(marketAddr);
        console.log("  Total Liquidity:", balance / 10 ** 6, "USDC");
    }

    function lockMarket(address marketAddr, string memory name) internal {
        WDL_Template market = WDL_Template(marketAddr);

        console.log("\nLocking", name);
        console.log("  Market:", marketAddr);

        // Warp time to after kickoff
        vm.warp(block.timestamp + 8 days);

        try market.lock() {
            console.log("  Status: Locked");
        } catch Error(string memory reason) {
            console.log("  Lock failed:", reason);
        }
    }

    function resolveMarket(address marketAddr, uint256 outcome, string memory name) internal {
        WDL_Template market = WDL_Template(marketAddr);

        console.log("\nResolving", name);
        console.log("  Market:", marketAddr);
        console.log("  Winning Outcome:", outcome);

        try market.resolve(outcome) {
            console.log("  Status: Resolved");
        } catch Error(string memory reason) {
            console.log("  Resolve failed:", reason);
        }
    }

    function redeemWinnings(address marketAddr, address user, uint256 outcome, string memory label) internal {
        WDL_Template market = WDL_Template(marketAddr);

        console.log("\n", label, "redeeming:");
        console.log("  Market:", marketAddr);
        console.log("  User:", user);

        // Get user's shares for winning outcome
        uint256 shares = market.balanceOf(user, outcome);
        console.log("  Shares held:", shares);

        if (shares == 0) {
            console.log("  No shares to redeem");
            return;
        }

        uint256 balanceBefore = MockERC20(USDC).balanceOf(user);

        try market.redeem(outcome, shares) {
            uint256 balanceAfter = MockERC20(USDC).balanceOf(user);
            uint256 winnings = balanceAfter - balanceBefore;
            console.log("  Redeemed:", winnings / 10 ** 6, "USDC");
        } catch Error(string memory reason) {
            console.log("  Redeem failed:", reason);
        }
    }
}
