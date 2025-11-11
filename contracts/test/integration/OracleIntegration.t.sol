// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../../src/templates/WDL_Template.sol";
import "../../src/oracle/MockOracle.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../mocks/MockERC20.sol";

/**
 * @title OracleIntegrationTest
 * @notice 测试 WDL_Template 与 MockOracle 的集成
 * @dev 测试完整流程：创建市场 → 下注 → 锁盘 → 预言机提交结果 → 结算 → 兑付
 */
contract OracleIntegrationTest is Test {
    WDL_Template public market;
    MockOracle public oracle;
    SimpleCPMM public pricingEngine;
    MockERC20 public usdc;

    address public owner;
    address public treasury;
    address public alice;
    address public bob;
    address public charlie;

    uint256 constant INITIAL_BALANCE = 100000e6; // 10万 USDC
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;

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

        // 部署 WDL 市场
        market = new WDL_Template();
        market.initialize(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            block.timestamp + 1 days, // 1天后开球
            address(usdc),
            treasury,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            "",
            owner // owner parameter
        );

        // 设置预言机
        market.setResultOracle(address(oracle));

        // 给用户分配 USDC
        usdc.mint(alice, INITIAL_BALANCE);
        usdc.mint(bob, INITIAL_BALANCE);
        usdc.mint(charlie, INITIAL_BALANCE);

        // 用户授权市场合约
        vm.prank(alice);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(bob);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(charlie);
        usdc.approve(address(market), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                      完整流程测试 - 主队胜
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试完整流程：主队胜利场景
    function test_FullFlow_HomeWin() public {
        // 1. 用户下注
        vm.prank(alice);
        uint256 aliceShares = market.placeBet(0, 10000e6); // 下注主胜 1万 USDC

        vm.prank(bob);
        uint256 bobShares = market.placeBet(1, 5000e6); // 下注平局 5千 USDC

        vm.prank(charlie);
        uint256 charlieShares = market.placeBet(2, 5000e6); // 下注客胜 5千 USDC

        assertGt(aliceShares, 0, "Alice should have shares");
        assertGt(bobShares, 0, "Bob should have shares");
        assertGt(charlieShares, 0, "Charlie should have shares");

        // 验证状态
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));

        // 2. 锁盘（时间快进到开球时间）
        vm.warp(block.timestamp + 1 days);
        market.lock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));

        // 3. 预言机提交结果（主队 2:1 客队）
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 4. 市场从预言机获取结果并结算
        market.resolveFromOracle();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved));
        assertEq(market.winningOutcome(), 0, "Home should win");

        // 5. 争议期后终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized));

        // 6. Alice（主胜）兑付
        uint256 aliceBalanceBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 payout = market.redeem(0, aliceShares);

        assertGt(payout, 0, "Alice should receive payout");
        assertEq(usdc.balanceOf(alice), aliceBalanceBefore + payout, "Balance mismatch");

        // 7. Bob 和 Charlie 无法兑付（输家）
        vm.prank(bob);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(1, bobShares);

        vm.prank(charlie);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(2, charlieShares);
    }

    /*//////////////////////////////////////////////////////////////
                      完整流程测试 - 平局
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试完整流程：平局场景
    function test_FullFlow_Draw() public {
        // 下注
        vm.prank(alice);
        market.placeBet(0, 10000e6);

        vm.prank(bob);
        uint256 bobShares = market.placeBet(1, 5000e6);

        vm.prank(charlie);
        market.placeBet(2, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机提交平局结果 (1:1)
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 1,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        market.resolveFromOracle();
        assertEq(market.winningOutcome(), 1, "Should be draw");

        // 终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // Bob（平局）兑付成功
        vm.prank(bob);
        uint256 payout = market.redeem(1, bobShares);
        assertGt(payout, 0);
    }

    /*//////////////////////////////////////////////////////////////
                      完整流程测试 - 客队胜
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试完整流程：客队胜利场景
    function test_FullFlow_AwayWin() public {
        // 下注
        vm.prank(alice);
        market.placeBet(0, 10000e6);

        vm.prank(bob);
        market.placeBet(1, 5000e6);

        vm.prank(charlie);
        uint256 charlieShares = market.placeBet(2, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机提交客队胜结果 (0:2)
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 0,
            awayGoals: 2,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        market.resolveFromOracle();
        assertEq(market.winningOutcome(), 2, "Away should win");

        // 终结
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // Charlie（客胜）兑付成功
        vm.prank(charlie);
        uint256 payout = market.redeem(2, charlieShares);
        assertGt(payout, 0);
    }

    /*//////////////////////////////////////////////////////////////
                      加时赛和点球大战测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试加时赛场景（FT_120）
    function test_FullFlow_ExtraTime_HomeWin() public {
        // 下注
        vm.prank(alice);
        uint256 aliceShares = market.placeBet(0, 10000e6);

        vm.prank(bob);
        market.placeBet(1, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机提交加时赛结果（主队3:2客队，含加时）
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_120"),
            homeGoals: 3,
            awayGoals: 2,
            extraTime: true,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        market.resolveFromOracle();
        assertEq(market.winningOutcome(), 0, "Home should win after extra time");

        // 终结并兑付
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(alice);
        uint256 payout = market.redeem(0, aliceShares);
        assertGt(payout, 0);
    }

    /// @notice 测试点球大战场景（主队点球胜）
    function test_FullFlow_Penalties_HomeWin() public {
        // 下注
        vm.prank(alice);
        uint256 aliceShares = market.placeBet(0, 10000e6);

        vm.prank(bob);
        market.placeBet(1, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机提交点球大战结果（常规+加时 2:2，点球 5:4 主胜）
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("Penalties"),
            homeGoals: 2,
            awayGoals: 2,
            extraTime: true,
            penaltiesHome: 5,
            penaltiesAway: 4,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        market.resolveFromOracle();
        assertEq(market.winningOutcome(), 0, "Home should win on penalties");

        // 终结并兑付
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(alice);
        uint256 payout = market.redeem(0, aliceShares);
        assertGt(payout, 0);
    }

    /// @notice 测试点球大战场景（客队点球胜）
    function test_FullFlow_Penalties_AwayWin() public {
        // 下注
        vm.prank(alice);
        market.placeBet(0, 10000e6);

        vm.prank(charlie);
        uint256 charlieShares = market.placeBet(2, 5000e6);

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机提交点球大战结果（常规+加时 1:1，点球 3:4 客胜）
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("Penalties"),
            homeGoals: 1,
            awayGoals: 1,
            extraTime: true,
            penaltiesHome: 3,
            penaltiesAway: 4,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 结算
        market.resolveFromOracle();
        assertEq(market.winningOutcome(), 2, "Away should win on penalties");

        // 终结并兑付
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        vm.prank(charlie);
        uint256 payout = market.redeem(2, charlieShares);
        assertGt(payout, 0);
    }

    /*//////////////////////////////////////////////////////////////
                          错误条件测试
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试预言机未设置时无法结算
    function test_ResolveFromOracle_RevertWhen_OracleNotSet() public {
        // 创建新市场但不设置预言机
        WDL_Template newMarket = new WDL_Template();
        newMarket.initialize(
            "TEST",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            treasury,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            "",
            owner // owner parameter
        );

        // 锁盘
        vm.warp(block.timestamp + 1 days);
        newMarket.lock();

        // 尝试结算（应该失败）
        vm.expectRevert("MarketBase: Oracle not set");
        newMarket.resolveFromOracle();
    }

    /// @notice 测试结果未终结时无法结算
    function test_ResolveFromOracle_RevertWhen_NotFinalized() public {
        // 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 预言机未提交结果，直接尝试结算
        vm.expectRevert();
        market.resolveFromOracle();
    }

    /// @notice 测试只能在 Locked 状态结算
    function test_ResolveFromOracle_RevertWhen_NotLocked() public {
        // 提交预言机结果
        bytes32 marketId = bytes32(uint256(uint160(address(market))));
        IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
            scope: bytes32("FT_90"),
            homeGoals: 2,
            awayGoals: 1,
            extraTime: false,
            penaltiesHome: 0,
            penaltiesAway: 0,
            reportedAt: block.timestamp,
            playerStats: new IResultOracle.PlayerStats[](0)
        });
        oracle.proposeResult(marketId, facts);

        // 尝试在 Open 状态结算（应该失败）
        vm.expectRevert("MarketBase: Invalid status");
        market.resolveFromOracle();
    }
}
