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
 *      涵盖半球盘、整数盘、Push 退款等场景
 */
contract OU_IntegrationTest is Test {
    OU_Template public marketHalfLine;  // 半球盘市场 (2.5球)
    OU_Template public marketWholeLine; // 整数盘市场 (2.0球)
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
    uint256 constant PUSH = 2;

    function setUp() public {
        owner = address(this);
        treasury = makeAddr("treasury");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        // 部署 USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // 部署定价引擎
        pricingEngine = new SimpleCPMM();

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

        // 部署半球盘 OU 市场 (2.5球)
        marketHalfLine = new OU_Template(
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
            ""
        );

        // 部署整数盘 OU 市场 (2.0球)
        marketWholeLine = new OU_Template(
            "EPL_2024_CHE_vs_ARS",
            "Chelsea",
            "Arsenal",
            block.timestamp + 1 days,
            2000, // 2.0球
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            ""
        );

        // 设置预言机
        marketHalfLine.setResultOracle(address(oracle));
        marketWholeLine.setResultOracle(address(oracle));

        // 给用户分配 USDC
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);

        // 用户授权两个市场合约
        vm.startPrank(alice);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        usdc.approve(address(marketWholeLine), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        usdc.approve(address(marketWholeLine), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(charlie);
        usdc.approve(address(marketHalfLine), type(uint256).max);
        usdc.approve(address(marketWholeLine), type(uint256).max);
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
        assertTrue(marketHalfLine.isHalfLine(), "Should be half-line market");

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
            reportedAt: block.timestamp
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
            reportedAt: block.timestamp
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
                 完整流程测试 - 整数盘 Push 退款
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试整数盘(2.0球)完整流程：Push 退款场景
    /// @dev 比赛结果 1:1 (总进球2 == 2.0) → Push 退款
    function test_FullFlow_Push_WholeLine() public {
        // 1. 用户下注
        vm.prank(alice);
        uint256 aliceShares = marketWholeLine.placeBet(OVER, 10000e6); // 大球

        vm.prank(bob);
        uint256 bobShares = marketWholeLine.placeBet(UNDER, 8000e6); // 小球

        // 验证是整数盘
        assertFalse(marketWholeLine.isHalfLine(), "Should be whole-line market");

        // 2. 锁盘
        vm.warp(block.timestamp + 1 days);
        marketWholeLine.lock();

        // 3. 预言机提交 Push 结果 (1:1，总进球2 == 2.0)
        bytes32 marketId = bytes32(uint256(uint160(address(marketWholeLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });
        oracle.proposeResult(marketId, facts);

        // 4. 结算为 Push
        marketWholeLine.resolveFromOracle();
        assertEq(marketWholeLine.winningOutcome(), PUSH, "Should be Push");

        // 5. 终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketWholeLine.finalize();

        // 6. Alice 和 Bob 都能退款（持有 Over/Under token）
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 alicePayout = marketWholeLine.redeem(OVER, aliceShares);
        assertGt(alicePayout, 0, "Alice should receive refund");

        uint256 bobBalanceBefore = usdc.balanceOf(bob);
        vm.prank(bob);
        uint256 bobPayout = marketWholeLine.redeem(UNDER, bobShares);
        assertGt(bobPayout, 0, "Bob should receive refund");

        // 验证退款金额按比例分配
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + alicePayout);
        assertEq(usdc.balanceOf(bob), bobBalanceBefore + bobPayout);
    }

    /*//////////////////////////////////////////////////////////////
                 完整流程测试 - 整数盘大球胜
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试整数盘(2.0球)完整流程：大球胜利场景
    /// @dev 比赛结果 2:1 (总进球3 > 2.0)
    function test_FullFlow_Over_WholeLine() public {
        // 下注
        vm.prank(alice);
        uint256 aliceShares = marketWholeLine.placeBet(OVER, 10000e6);

        vm.prank(bob);
        marketWholeLine.placeBet(UNDER, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        marketWholeLine.lock();

        // 预言机提交大球结果 (2:1，总进球3 > 2.0)
        bytes32 marketId = bytes32(uint256(uint160(address(marketWholeLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        marketWholeLine.resolveFromOracle();
        assertEq(marketWholeLine.winningOutcome(), OVER, "Over should win");

        // 终结并兑付
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketWholeLine.finalize();

        vm.prank(alice);
        uint256 payout = marketWholeLine.redeem(OVER, aliceShares);
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
            reportedAt: block.timestamp
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

    /// @notice 测试无法下注 Push
    function test_CannotBetOnPush() public {
        vm.prank(alice);
        vm.expectRevert("OU: Cannot bet on Push");
        marketWholeLine.placeBet(PUSH, 1000e6);
    }

    /// @notice 测试 Push 场景按比例退款
    function test_PushRefund_ProportionalPayout() public {
        // Alice 下注 10000, Bob 下注 5000
        vm.prank(alice);
        uint256 aliceShares = marketWholeLine.placeBet(OVER, 10000e6);

        vm.prank(bob);
        uint256 bobShares = marketWholeLine.placeBet(UNDER, 5000e6);

        // 锁盘并结算为 Push
        vm.warp(block.timestamp + 1 days);
        marketWholeLine.lock();

        bytes32 marketId = bytes32(uint256(uint160(address(marketWholeLine))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp
        });
        oracle.proposeResult(marketId, facts);
        marketWholeLine.resolveFromOracle();

        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        marketWholeLine.finalize();

        // 兑付前记录余额
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        uint256 bobBalanceBefore = usdc.balanceOf(bob);

        // 兑付
        vm.prank(alice);
        uint256 alicePayout = marketWholeLine.redeem(OVER, aliceShares);

        vm.prank(bob);
        uint256 bobPayout = marketWholeLine.redeem(UNDER, bobShares);

        // 验证退款比例大致为 2:1 (考虑 AMM 定价和手续费)
        // Alice 投入更多,应该拿回更多
        assertGt(alicePayout, bobPayout, "Alice should get more refund");

        // 验证最终余额
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + alicePayout);
        assertEq(usdc.balanceOf(bob), bobBalanceBefore + bobPayout);
    }
}
