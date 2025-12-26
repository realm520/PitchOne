// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_V3.sol";
import "../src/core/BettingRouter_V3.sol";
import "../src/interfaces/IMarket_V3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreateAndBet is Script {
    // 合约地址（从 addresses.ts 获取）
    address constant FACTORY = 0xcC4c41415fc68B2fBf70102742A83cDe435e0Ca7;
    address constant BETTING_ROUTER = 0x0fe4223AD99dF788A6Dcad148eB4086E6389cEB6;
    address constant USDC = 0x9385556B571ab92bf6dC9a0DbD75429Dd4d56F91;

    // WDL Parimutuel 模板 ID
    bytes32 constant WDL_PARI_TEMPLATE = 0xef6f1330cf58b013258b8e3d5fd49f219361a51fb17cfc622a124addb42faba9;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        MarketFactory_V3 factory = MarketFactory_V3(FACTORY);
        BettingRouter_V3 router = BettingRouter_V3(BETTING_ROUTER);
        IERC20 usdc = IERC20(USDC);

        // 计算两天后的时间戳
        uint256 twoDaysLater = block.timestamp + 2 days;

        // 空的 outcomeRules 数组
        IMarket_V3.OutcomeRule[] memory emptyRules = new IMarket_V3.OutcomeRule[](0);

        console.log("Creating Market 1...");
        // 创建第一个市场：曼联 vs 利物浦
        MarketFactory_V3.CreateMarketParams memory params1 = MarketFactory_V3.CreateMarketParams({
            templateId: WDL_PARI_TEMPLATE,
            matchId: "EPL_2024_MAN_UTD_vs_LIVERPOOL",
            kickoffTime: twoDaysLater,
            mapperInitData: bytes(""),
            initialLiquidity: 0,
            outcomeRules: emptyRules
        });
        address market1 = factory.createMarket(params1);
        console.log("Market 1 created:", market1);

        console.log("Creating Market 2...");
        // 创建第二个市场：切尔西 vs 阿森纳
        MarketFactory_V3.CreateMarketParams memory params2 = MarketFactory_V3.CreateMarketParams({
            templateId: WDL_PARI_TEMPLATE,
            matchId: "EPL_2024_CHELSEA_vs_ARSENAL",
            kickoffTime: twoDaysLater + 1 hours,
            mapperInitData: bytes(""),
            initialLiquidity: 0,
            outcomeRules: emptyRules
        });
        address market2 = factory.createMarket(params2);
        console.log("Market 2 created:", market2);

        // 批准 USDC 给 BettingRouter
        uint256 betAmount = 1e6; // 1 USDC
        console.log("Approving USDC...");
        usdc.approve(BETTING_ROUTER, betAmount * 2);

        // 在第一个市场下注 1 USDC（outcome 0 = 主队胜）
        console.log("Placing bet on Market 1...");
        router.placeBet(
            market1,
            0,          // outcome: 主队胜
            betAmount,  // 1 USDC
            0           // minShares
        );
        console.log("Bet placed on Market 1!");

        // 在第二个市场下注 1 USDC（outcome 1 = 平局）
        console.log("Placing bet on Market 2...");
        router.placeBet(
            market2,
            1,          // outcome: 平局
            betAmount,  // 1 USDC
            0           // minShares
        );
        console.log("Bet placed on Market 2!");

        vm.stopBroadcast();

        console.log("\n=== Summary ===");
        console.log("Market 1:", market1);
        console.log("Market 2:", market2);
        console.log("Bet amount per market: 1 USDC");
    }
}
