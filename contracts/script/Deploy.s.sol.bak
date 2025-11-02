// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/FeeRouter.sol";
import "../src/pricing/SimpleCPMM.sol";
import "../src/templates/WDL_Template.sol";
import "../test/mocks/MockERC20.sol";

/**
 * @title Deploy
 * @notice Deployment script for PitchOne contracts
 * @dev Run with: forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vvvv
 */
contract Deploy is Script {
    // Deployment addresses (will be set after deployment)
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;
    WDL_Template public wdlMarket;

    // Configuration
    address public treasury;
    address public keeper;

    // Market parameters
    string public matchId = "EPL_2025_MUN_vs_LIV";
    string public homeTeam = "Manchester United";
    string public awayTeam = "Liverpool";
    uint256 public kickoffTime;

    function setUp() public {
        // Set treasury and keeper addresses
        treasury = vm.envOr("TREASURY_ADDRESS", address(0x1));
        keeper = vm.envOr("KEEPER_ADDRESS", address(0x2));

        // Set kickoff time to 1 hour from now
        kickoffTime = block.timestamp + 1 hours;
    }

    function run() public {
        // Get private key from environment or use Anvil default
        uint256 deployerPrivateKey;
        try vm.envUint("PRIVATE_KEY") returns (uint256 pk) {
            deployerPrivateKey = pk;
        } catch {
            // Anvil default private key (account #0)
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=================================================");
        console.log("PitchOne Deployment Script");
        console.log("=================================================");
        console.log("Deployer:", deployer);
        console.log("Treasury:", treasury);
        console.log("Keeper:", keeper);
        console.log("Chain ID:", block.chainid);
        console.log("=================================================");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy Mock USDC (only for testnets)
        console.log("\n[1/4] Deploying Mock USDC...");
        usdc = new MockERC20("USD Coin", "USDC", 6);
        console.log("Mock USDC deployed at:", address(usdc));

        // Mint initial USDC to deployer for testing
        usdc.mint(deployer, 1_000_000e6); // 1M USDC
        console.log("Minted 1,000,000 USDC to deployer");

        // Step 2: Deploy FeeRouter
        console.log("\n[2/4] Deploying FeeRouter...");
        feeRouter = new FeeRouter(treasury);
        console.log("FeeRouter deployed at:", address(feeRouter));

        // Step 3: Deploy SimpleCPMM
        console.log("\n[3/4] Deploying SimpleCPMM...");
        cpmm = new SimpleCPMM();
        console.log("SimpleCPMM deployed at:", address(cpmm));

        // Step 4: Deploy WDL Market Template
        console.log("\n[4/4] Deploying WDL Market...");
        wdlMarket = new WDL_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            address(usdc),         // settlement token
            address(feeRouter),    // fee recipient
            200,                   // 2% fee rate (in basis points)
            2 hours,               // dispute period
            address(cpmm),         // pricing engine
            ""                     // uri (empty for now)
        );
        console.log("WDL Market deployed at:", address(wdlMarket));

        vm.stopBroadcast();

        // Print deployment summary
        printDeploymentSummary();
    }

    function printDeploymentSummary() internal view {
        console.log("\n=================================================");
        console.log("Deployment Summary");
        console.log("=================================================");
        console.log("Mock USDC:      ", address(usdc));
        console.log("FeeRouter:      ", address(feeRouter));
        console.log("SimpleCPMM:     ", address(cpmm));
        console.log("WDL Market:     ", address(wdlMarket));
        console.log("=================================================");
        console.log("Market Details:");
        console.log("  Match ID:     ", matchId);
        console.log("  Home Team:    ", homeTeam);
        console.log("  Away Team:    ", awayTeam);
        console.log("  Kickoff Time: ", kickoffTime);
        console.log("=================================================");
        console.log("\nNext steps:");
        console.log("1. Save these addresses to .env or deployment config");
        console.log("2. Users can start placing bets via placeBet()");
        console.log("3. Run demo script: forge script script/DemoFlow.s.sol");
        console.log("4. Verify contracts on block explorer");
        console.log("=================================================");
    }
}
