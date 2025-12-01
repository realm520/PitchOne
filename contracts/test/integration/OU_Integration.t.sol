// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/OU_Template.sol";
import "../../src/oracle/MockOracle.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../../src/core/FeeRouter.sol";
import "../../src/core/ReferralRegistry.sol";
import "../mocks/MockERC20.sol";

/**
 * @title OU_IntegrationTest
 * @notice 测试 OU_Template 与 MockOracle 的集成
 * @dev 测试完整流程：创建市场 → 下注 → 锁盘 → 预言机提交结果 → 结算 → 兑付
 *      只支持半球盘（无 Push）
 */
contract OU_IntegrationTest is Test {
    OU_Template public marketHalfLine;  // 半球盘市场 (2.5球)
    MockOracle public oracle;
    SimpleCPMM public pricingEngine;
    MockERC20 public usdc;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;

    address public owner;
    address public treasury;
    address public alice;
    address public bob;
    address public charlie;

    uint256 constant INITIAL_BALANCE = 100000e6; // 10万 USDC
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;

    // OU Outcomes
    uint256 constant OVER = 0;
    uint256 constant UNDER = 1;

    function setUp() public {
        owner = address(this);
        treasury = makeAddr("treasury");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // 部署 USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // 部署定价引擎
        pricingEngine = new SimpleCPMM(100_000 * 10**6);

        // 部署预言机
        oracle = new MockOracle(owner);

        // 部署 ReferralRegistry 和 FeeRouter
        referralRegistry = new ReferralRegistry(owner);
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: treasury,
            promoPool: treasury,
            insuranceFund: treasury,
            treasury: treasury
        });
        feeRouter = new FeeRouter(recipients, address(referralRegistry));

        // Authorize FeeRouter to call ReferralRegistry (critical for accrueReferralReward)
        referralRegistry.setAuthorizedCaller(address(feeRouter), true);

        // 部署半球盘 OU 市场 (2.5球)
        marketHalfLine = new OU_Template();
        marketHalfLine.initialize(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            block.timestamp + 1 days, // 1天后开球
            2500, // 2.5球
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            "",
            owner // owner parameter
        );

        // 设置预言机
        marketHalfLine.setResultOracle(address(oracle));

        // 给用户分配 USDC
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);

        // 用户授权市场合约
        vm.startPrank(alice);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(charlie);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                 完整流程测试 - 半球盘大球胜
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试半球盘(2.5球)完整流程：大球胜利场景
    /// @dev 比赛结果 3:1 (总进球4 > 2.5)
    function test_FullFlow_Over_HalfLine() public {
        // 1. 用户下注
        vm.prank(alice);
        uint256 aliceShares = marketHalfLine.placeBet(OVER, 10000e6); // 下注大球 1万 USDC

        vm.prank(bob);
        uint256 bobShares = marketHalfLine.placeBet(UNDER, 5000e6); // 下注小球 5千 USDC

        assertGt(aliceShares, 0, "Alice should have shares");
        assertGt(bobShares, 0, "Bob should have shares");

        // 验证状态
        assertEq(uint256(marketHalfLine.status()), uint256(IMarket.MarketStatus.Open));

        // 2. 锁盘（时间快进到开球时间）
        vm.warp(block.timestamp + 1 days);
        marketHalfLine.lock();
        assertEq(uint256(marketHalfLine.status()), uint256(IMarket.MarketStatus.Locked));

        // 3. 预言机提交结果（3:1，总进球4 > 2.5）
        bytes32 marketId = bytes32(uint256(uint160(address(marketHalfLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 3,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 4. 市场从预言机获取结果并结算
        marketHalfLine.resolveFromOracle();
        assertEq(uint256(marketHalfLine.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(marketHalfLine.winningOutcome(), OVER, "Over should win");

        // 5. 争议期后终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketHalfLine.finalize();
        assertEq(uint256(marketHalfLine.status()), uint256(IMarket.MarketStatus.Finalized));

        // 6. Alice（大球）兑付成功
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 payout = marketHalfLine.redeem(OVER, aliceShares);

        assertGt(payout, 0, "Alice should receive payout");
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + payout, "Balance mismatch");

        // 7. Bob（小球）无法兑付（输家）
        vm.prank(bob);
        vm.expectRevert("MarketBase: Not winning outcome");
        marketHalfLine.redeem(UNDER, bobShares);
    }

    /*//////////////////////////////////////////////////////////////
                 完整流程测试 - 半球盘小球胜
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试半球盘(2.5球)完整流程：小球胜利场景
    /// @dev 比赛结果 1:0 (总进球1 < 2.5)
    function test_FullFlow_Under_HalfLine() public {
        // 下注
        vm.prank(alice);
        marketHalfLine.placeBet(OVER, 10000e6);

        vm.prank(bob);
        uint256 bobShares = marketHalfLine.placeBet(UNDER, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        marketHalfLine.lock();

        // 预言机提交小球结果 (1:0，总进球1 < 2.5)
        bytes32 marketId = bytes32(uint256(uint160(address(marketHalfLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        marketHalfLine.resolveFromOracle();
        assertEq(marketHalfLine.winningOutcome(), UNDER, "Under should win");

        // 终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketHalfLine.finalize();

        // Bob（小球）兑付成功
        vm.prank(bob);
        uint256 payout = marketHalfLine.redeem(UNDER, bobShares);
        assertGt(payout, 0);
    }

    /*//////////////////////////////////////////////////////////////
                     多用户下注测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试多用户不同结果下注
    function test_MultiUser_DifferentOutcomes() public {
        // 三个用户下注不同金额
        vm.prank(alice);
        uint256 aliceShares = marketHalfLine.placeBet(OVER, 10000e6);

        vm.prank(bob);
        uint256 bobShares = marketHalfLine.placeBet(UNDER, 6000e6);

        vm.prank(charlie);
        uint256 charlieShares = marketHalfLine.placeBet(OVER, 4000e6);

        // 验证流动性
        uint256 totalLiquidity = marketHalfLine.totalLiquidity();
        assertGt(totalLiquidity, 0, "Should have liquidity");

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        marketHalfLine.lock();

        // 结算为大球胜 (3:0，总进球3 > 2.5)
        bytes32 marketId = bytes32(uint256(uint160(address(marketHalfLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 3,
            awayGoals: 0,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);
        marketHalfLine.resolveFromOracle();

        // 终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketHalfLine.finalize();

        // Alice 和 Charlie（大球赢家）兑付
        vm.prank(alice);
        uint256 alicePayout = marketHalfLine.redeem(OVER, aliceShares);

        vm.prank(charlie);
        uint256 charliePayout = marketHalfLine.redeem(OVER, charlieShares);

        assertGt(alicePayout, 0);
        assertGt(charliePayout, 0);

        // Bob（小球输家）无法兑付
        vm.prank(bob);
        vm.expectRevert("MarketBase: Not winning outcome");
        marketHalfLine.redeem(UNDER, bobShares);
    }

    /*//////////////////////////////////////////////////////////////
                      错误条件测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试无法下注无效的 outcome
    function test_CannotBetOnInvalidOutcome() public {
        vm.prank(alice);
        vm.expectRevert("MarketBase: Invalid outcome");
        marketHalfLine.placeBet(2, 1000e6); // Outcome 2 doesn't exist (only 0 and 1)
    }
}
