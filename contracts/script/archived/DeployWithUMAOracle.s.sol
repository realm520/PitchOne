// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/templates/WDL_Template.sol";
import "../src/oracle/UMAOptimisticOracleAdapter.sol";
import "../src/core/FeeRouter.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../test/mocks/MockERC20.sol";
import "../test/mocks/MockOptimisticOracleV3.sol";

/**
 * @title DeployWithUMAOracle
 * @notice 部署集成 UMA Optimistic Oracle 的 WDL 市场
 * @dev 用于演示和测试 UMA OO 集成
 *
 * 使用方法:
 *   forge script script/DeployWithUMAOracle.s.sol:DeployWithUMAOracle --rpc-url $RPC_URL --broadcast -vvvv
 */
contract DeployWithUMAOracle is Script {
    // 部署的合约地址
    MockERC20 public usdc;
    MockERC20 public bondCurrency;
    MockOptimisticOracleV3 public mockOO;
    UMAOptimisticOracleAdapter public oracleAdapter;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    WDL_Template public market;

    // 市场参数
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.sportsbook.com/markets/{id}";

    // UMA OO 参数
    uint256 constant BOND_AMOUNT = 1000e6; // 1000 USDC
    uint64 constant LIVENESS = 7200; // 2 hours
    bytes32 constant IDENTIFIER = bytes32("ASSERT_TRUTH");

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("========================================");
        console.log("Deploying Market with UMA Oracle");
        console.log("========================================");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署依赖合约
        console.log("\n1. Deploying dependencies...");

        usdc = new MockERC20("Mock USDC", "USDC", 6);
        console.log("   USDC:", address(usdc));

        bondCurrency = new MockERC20("Bond Currency", "BOND", 6);
        console.log("   Bond Currency:", address(bondCurrency));

        mockOO = new MockOptimisticOracleV3();
        console.log("   Mock OO:", address(mockOO));

        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: address(0x100),
            promoPool: address(0x200),
            insuranceFund: address(0x250),
            treasury: address(0x300)
        });
        feeRouter = new FeeRouter(recipients, address(0x400));
        console.log("   FeeRouter:", address(feeRouter));

        cpmm = new SimpleCPMM();
        console.log("   SimpleCPMM:", address(cpmm));

        // 2. 部署 UMA Oracle Adapter
        console.log("\n2. Deploying UMA Oracle Adapter...");

        oracleAdapter = new UMAOptimisticOracleAdapter(
            address(mockOO),
            address(bondCurrency),
            BOND_AMOUNT,
            LIVENESS,
            IDENTIFIER,
            deployer
        );
        console.log("   UMA Adapter:", address(oracleAdapter));

        // 3. 部署 WDL 市场
        console.log("\n3. Deploying WDL Market...");

        uint256 kickoffTime = block.timestamp + 24 hours;

        market = new WDL_Template(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI
        );
        console.log("   Market:", address(market));

        // 4. 设置预言机
        console.log("\n4. Setting oracle...");
        market.setResultOracle(address(oracleAdapter));
        console.log("   Oracle set successfully");

        // 5. 准备初始资金（用于测试）
        console.log("\n5. Minting test tokens...");
        usdc.mint(deployer, 100_000e6); // 100k USDC
        bondCurrency.mint(deployer, 10_000e6); // 10k for bonds
        console.log("   Tokens minted");

        vm.stopBroadcast();

        // 打印部署摘要
        console.log("\n========================================");
        console.log("Deployment Summary");
        console.log("========================================");
        console.log("USDC:", address(usdc));
        console.log("Bond Currency:", address(bondCurrency));
        console.log("Mock OO:", address(mockOO));
        console.log("UMA Adapter:", address(oracleAdapter));
        console.log("FeeRouter:", address(feeRouter));
        console.log("SimpleCPMM:", address(cpmm));
        console.log("Market:", address(market));
        console.log("========================================");
        console.log("Kickoff Time:", kickoffTime);
        console.log("Liveness:", LIVENESS, "seconds");
        console.log("Bond Amount:", BOND_AMOUNT / 1e6, "USDC");
        console.log("========================================");
    }
}
