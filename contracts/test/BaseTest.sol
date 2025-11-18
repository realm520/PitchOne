// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./mocks/MockERC20.sol";
import "../src/core/FeeRouter.sol";
import "../src/core/ReferralRegistry.sol";
import "../src/pricing/SimpleCPMM.sol";

/**
 * @title BaseTest
 * @notice Base test contract with common setup and utilities
 */
contract BaseTest is Test {
    // Test accounts
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public keeper;
    address public treasury;

    // Mock contracts
    MockERC20 public usdc;
    ReferralRegistry public referralRegistry;
    FeeRouter public feeRouter;
    SimpleCPMM public cpmm;

    // Constants
    uint256 public constant INITIAL_BALANCE = 100_000e6; // 100k USDC
    uint256 public constant DEFAULT_FEE_RATE = 200; // 2%
    uint256 public constant DEFAULT_DISPUTE_PERIOD = 24 hours;
    uint256 public constant VIRTUAL_RESERVE_INIT = 100_000e6; // 100k USDC - Default virtual reserve for AMM mode
    uint256 public constant PARIMUTUEL_RESERVE = 0; // 0 = Pure Parimutuel mode (no virtual reserves)

    function setUp() public virtual {
        // Setup accounts
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        keeper = makeAddr("keeper");
        treasury = makeAddr("treasury");

        // Deploy mock USDC (6 decimals)
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy ReferralRegistry
        referralRegistry = new ReferralRegistry(owner);

        // Deploy FeeRouter with proper initialization
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: treasury,        // 使用 treasury 作为所有接收地址
            promoPool: treasury,
            insuranceFund: treasury,
            treasury: treasury
        });
        feeRouter = new FeeRouter(recipients, address(referralRegistry));

        // Deploy SimpleCPMM
        cpmm = new SimpleCPMM(100_000 * 10**6);

        // Mint tokens to test users
        usdc.mint(user1, INITIAL_BALANCE);
        usdc.mint(user2, INITIAL_BALANCE);
        usdc.mint(user3, INITIAL_BALANCE);

        // Label addresses for better trace output
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(user3, "User3");
        vm.label(keeper, "Keeper");
        vm.label(treasury, "Treasury");
        vm.label(address(usdc), "USDC");
        vm.label(address(referralRegistry), "ReferralRegistry");
        vm.label(address(feeRouter), "FeeRouter");
        vm.label(address(cpmm), "CPMM");
    }

    // ============ Utility Functions ============

    /**
     * @notice Helper to approve market contract for user
     */
    function approveMarket(address user, address market, uint256 amount) public {
        vm.prank(user);
        usdc.approve(market, amount);
    }

    /**
     * @notice Helper to check approximate equality with custom delta (overload)
     */
    function assertApproxEqRelCustom(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta // e18 format (e.g., 0.01e18 = 1%)
    ) internal {
        uint256 delta = a > b ? a - b : b - a;
        uint256 maxDelta = (b * maxPercentDelta) / 1e18;

        if (delta > maxDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("    Expected", b);
            emit log_named_uint("      Actual", a);
            emit log_named_uint("   Max Delta", maxDelta);
            emit log_named_uint(" Actual Delta", delta);
            fail();
        }
    }

    /**
     * @notice Helper to simulate time passing
     */
    function skipTime(uint256 duration) public {
        vm.warp(block.timestamp + duration);
    }

    /**
     * @notice Helper to get current timestamp
     */
    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }
}
