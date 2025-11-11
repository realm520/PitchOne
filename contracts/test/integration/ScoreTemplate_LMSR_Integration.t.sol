// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../BaseTest.sol";
import "../../src/templates/ScoreTemplate.sol";
import "../../src/pricing/LMSR.sol";

/**
 * @title ScoreTemplate_LMSR_Integration
 * @notice LMSR定价引擎 + 精确比分市场 集成测试
 * @dev 测试场景：
 *      1. 精确比分市场创建与 LMSR 初始化
 *      2. 多结果下注流程（份额计算、成本计算）
 *      3. 赔率动态变化（买入后概率更新）
 *      4. 市场结算与用户赎回
 *      5. Gas 优化验证（多结果市场）
 */
contract ScoreTemplate_LMSR_IntegrationTest is BaseTest {
    ScoreTemplate public scoreMarket;
    LMSR public lmsrEngine;

    // 测试常量
    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;

    // LMSR 参数
    uint8 constant MAX_GOALS = 3; // 0-0 到 3-3 (4x4=16 比分 + 1 其他 = 17 结果)
    uint256 constant LIQUIDITY_B = 5000 * 1e18; // b = 5000 WAD

    event BetPlaced(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 amount,
        uint256 shares,
        uint256 fee
    );

    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);

    event Redeemed(
        address indexed user,
        uint256 indexed outcomeId,
        uint256 shares,
        uint256 payout
    );

    // ============================================================================
    // Helper Functions
    // ============================================================================

    /**
     * @notice 获取当前储备量（用于 LMSR getPrice 调用）
     */
    function _getCurrentReserves() internal view returns (uint256[] memory) {
        return lmsrEngine.getAllQuantities();
    }

    function setUp() public override {
        super.setUp();

        kickoffTime = block.timestamp + 1 days;

        // 部署 ScoreTemplate（内部会创建 LMSR）
        scoreMarket = new ScoreTemplate();

        uint256[] memory initialProbs = new uint256[](0); // 空数组 = 均匀分布

        scoreMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            MAX_GOALS,
            address(usdc),
            address(feeRouter),
            DEFAULT_FEE_RATE,
            DEFAULT_DISPUTE_PERIOD,
            LIQUIDITY_B,
            initialProbs,
            "https://api.test/score_market",
            owner
        );

        // 获取内部创建的 LMSR 引擎
        lmsrEngine = scoreMarket.lmsrEngine();

        vm.label(address(scoreMarket), "ScoreMarket");
        vm.label(address(lmsrEngine), "LMSR");

        // 给测试用户分配资金
        deal(address(usdc), user1, 100_000 * 1e6);
        deal(address(usdc), user2, 100_000 * 1e6);
        deal(address(usdc), user3, 100_000 * 1e6);

        // 用户授权
        vm.prank(user1);
        usdc.approve(address(scoreMarket), type(uint256).max);

        vm.prank(user2);
        usdc.approve(address(scoreMarket), type(uint256).max);

        vm.prank(user3);
        usdc.approve(address(scoreMarket), type(uint256).max);
    }

    // ============================================================================
    // 测试 1: 市场创建与 LMSR 初始化
    // ============================================================================
    function testIntegration_MarketCreation() public view {
        assertEq(scoreMarket.matchId(), MATCH_ID, "Match ID should match");
        assertEq(scoreMarket.homeTeam(), HOME_TEAM, "Home team should match");
        assertEq(scoreMarket.awayTeam(), AWAY_TEAM, "Away team should match");
        assertEq(scoreMarket.kickoffTime(), kickoffTime, "Kickoff time should match");
        assertEq(scoreMarket.maxGoals(), MAX_GOALS, "Max goals should match");

        // 验证结果数量: (maxGoals+1)^2 + 1 = 4x4 + 1 = 17
        uint256 expectedCount = (uint256(MAX_GOALS) + 1) ** 2 + 1;
        assertEq(scoreMarket.outcomeCount(), expectedCount, "Outcome count should be 17");

        // 验证 LMSR 已创建
        assertEq(address(lmsrEngine), address(scoreMarket.lmsrEngine()), "LMSR should be set");
        assertTrue(address(lmsrEngine) != address(0), "LMSR should not be zero address");
    }

    // ============================================================================
    // 测试 2: 下注流程 - 单一比分
    // ============================================================================
    function testIntegration_PlaceBet_SingleOutcome() public {
        uint256 betAmount = 10_000 * 1e6; // 10k USDC
        uint256 outcomeId = 5; // 索引 5 对应 1-1 比分（maxGoals=3: 0-0至3-3共16个标准比分）

        vm.startPrank(user1);

        // 记录初始价格
        uint256 priceBefore = lmsrEngine.getPrice(outcomeId, _getCurrentReserves());

        // 下注
        uint256 sharesBought = scoreMarket.placeBet(outcomeId, betAmount);

        // 记录结束价格
        uint256 priceAfter = lmsrEngine.getPrice(outcomeId, _getCurrentReserves());

        // 验证
        assertGt(sharesBought, 0, "Should receive shares");
        assertGt(priceAfter, priceBefore, "Price should increase after buying");

        // 验证用户持有的头寸
        uint256 userShares = scoreMarket.balanceOf(user1, outcomeId);
        assertEq(userShares, sharesBought, "User should hold the shares");

        vm.stopPrank();
    }

    // ============================================================================
    // 测试 3: 赔率动态变化
    // ============================================================================
    function testIntegration_Odds_DynamicChange() public {
        uint256 outcomeId = 5; // 索引 5 对应 1-1
        uint256 betAmount = 5_000 * 1e6;

        // 记录初始概率分布（需要包含 outcomeId=5）
        uint256[] memory reservesBefore = _getCurrentReserves();
        uint256 priceBefore_outcomeId = lmsrEngine.getPrice(outcomeId, reservesBefore);
        uint256 priceBefore_0 = lmsrEngine.getPrice(0, reservesBefore);

        // User1 下注 1-1
        vm.prank(user1);
        scoreMarket.placeBet(outcomeId, betAmount);

        // 记录下注后概率分布
        uint256[] memory reservesAfter = _getCurrentReserves();
        uint256 priceAfter_outcomeId = lmsrEngine.getPrice(outcomeId, reservesAfter);
        uint256 priceAfter_0 = lmsrEngine.getPrice(0, reservesAfter);

        // 验证: 1-1 概率上升
        assertGt(priceAfter_outcomeId, priceBefore_outcomeId, "Bet outcome price should increase");

        // 验证: 其他概率下降（使用 0-0 作为对比）
        assertLt(priceAfter_0, priceBefore_0, "Other outcome prices should decrease");
    }

    // ============================================================================
    // 测试 4: 多用户并发下注
    // ============================================================================
    function testIntegration_MultipleBets_ConcurrentUsers() public {
        uint256 betAmount = 5_000 * 1e6;

        // User1 下注 1-1（索引 5）
        vm.prank(user1);
        uint256 shares1 = scoreMarket.placeBet(5, betAmount);

        // User2 下注 2-1（索引 9）
        vm.prank(user2);
        uint256 shares2 = scoreMarket.placeBet(9, betAmount);

        // User3 下注 0-0（索引 0）
        vm.prank(user3);
        uint256 shares3 = scoreMarket.placeBet(0, betAmount);

        // 验证所有用户都获得了份额
        assertGt(shares1, 0, "User1 should receive shares");
        assertGt(shares2, 0, "User2 should receive shares");
        assertGt(shares3, 0, "User3 should receive shares");
    }

    // ============================================================================
    // 测试 5: 市场结算与赎回
    // ============================================================================
    function testIntegration_Settle_AndRedeem() public {
        uint256 betAmount = 10_000 * 1e6;
        uint256 winningOutcome = 5; // 1-1（索引 5）
        uint256 losingOutcome = 9;  // 2-1（索引 9）

        // User1 下注赢的结果
        vm.prank(user1);
        uint256 winningShares = scoreMarket.placeBet(winningOutcome, betAmount);

        // User2 下注输的结果
        vm.prank(user2);
        scoreMarket.placeBet(losingOutcome, betAmount);

        // 时间推进到赛后
        vm.warp(kickoffTime + 7200); // 赛后 2 小时

        // 锁盘
        vm.prank(owner);
        scoreMarket.lock();

        // 结算: 1-1
        vm.prank(owner);
        scoreMarket.resolve(winningOutcome);

        // User1 赎回赢得的份额
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        scoreMarket.redeem(winningOutcome, winningShares);

        uint256 balanceAfter = usdc.balanceOf(user1);
        uint256 payout = balanceAfter - balanceBefore;

        // 验证
        assertGt(payout, betAmount, "Winner should profit");

        // 验证输家无法赎回（应该 revert）
        uint256 user2Shares = scoreMarket.balanceOf(user2, losingOutcome);
        assertGt(user2Shares, 0, "User2 should have losing shares");

        vm.prank(user2);
        vm.expectRevert("MarketBase: Not winning outcome");
        scoreMarket.redeem(losingOutcome, user2Shares);
    }

    // ============================================================================
    // 测试 6: Gas 优化 - 多结果市场下注成本
    // ============================================================================
    function testIntegration_GasUsage_PlaceBet() public {
        uint256 betAmount = 10_000 * 1e6;
        uint256 outcomeId = 5; // 1-1（索引 5）

        vm.startPrank(user1);

        uint256 gasBefore = gasleft();
        scoreMarket.placeBet(outcomeId, betAmount);
        uint256 gasUsed = gasBefore - gasleft();

        // Gas 应合理（17个结果的LMSR市场，< 3M gas）
        // 注：LMSR 需要指数计算，Gas 消耗高于 CPMM
        assertLt(gasUsed, 3_000_000, "Gas usage should be < 3M for LMSR 17-outcome market");

        vm.stopPrank();
    }

    // ============================================================================
    // 测试 7: 比分编码
    // ============================================================================
    function testIntegration_ScoreEncoding() public view {
        // 测试常见比分编码（公式: homeGoals * 10 + awayGoals）
        assertEq(scoreMarket.encodeScore(0, 0), 0, "0-0 should encode to 0");
        assertEq(scoreMarket.encodeScore(1, 0), 10, "1-0 should encode to 10");
        assertEq(scoreMarket.encodeScore(1, 1), 11, "1-1 should encode to 11");
        assertEq(scoreMarket.encodeScore(2, 1), 21, "2-1 should encode to 21");
        assertEq(scoreMarket.encodeScore(3, 3), 33, "3-3 should encode to 33");
    }

    // ============================================================================
    // 测试 8: 完整生命周期
    // ============================================================================
    function testIntegration_FullLifecycle() public {
        uint256 betAmount = 5_000 * 1e6;
        uint256 winningScore = 5; // 1-1（索引 5）

        // 1. 多用户下注阶段
        vm.prank(user1);
        scoreMarket.placeBet(winningScore, betAmount);

        vm.prank(user2);
        scoreMarket.placeBet(winningScore, betAmount); // same as user1

        vm.prank(user3);
        scoreMarket.placeBet(9, betAmount); // 2-1（索引 9）

        // 2. 时间推进到赛后
        vm.warp(kickoffTime + 7200);

        // 3. 锁盘
        vm.prank(owner);
        scoreMarket.lock();

        // 4. 结算: 1-1
        vm.prank(owner);
        scoreMarket.resolve(winningScore);

        // 5. 赢家批量赎回
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        uint256 user2BalanceBefore = usdc.balanceOf(user2);

        uint256 user1Shares = scoreMarket.balanceOf(user1, winningScore);
        uint256 user2Shares = scoreMarket.balanceOf(user2, winningScore);

        vm.prank(user1);
        scoreMarket.redeem(winningScore, user1Shares);

        vm.prank(user2);
        scoreMarket.redeem(winningScore, user2Shares);

        uint256 user1Payout = usdc.balanceOf(user1) - user1BalanceBefore;
        uint256 user2Payout = usdc.balanceOf(user2) - user2BalanceBefore;

        // 验证: 两个赢家都获得收益
        assertGt(user1Payout, 0, "User1 should receive payout");
        assertGt(user2Payout, 0, "User2 should receive payout");

        // 验证: 收益应按份额比例分配
        uint256 payoutRatio = (user1Payout * 100) / user2Payout;
        assertGt(payoutRatio, 80, "Payout ratio should be close to 1:1");
        assertLt(payoutRatio, 120, "Payout ratio should be close to 1:1");

        // 验证输家无法赎回
        uint256 losingScore = 9; // 2-1（索引 9）
        uint256 user3Shares = scoreMarket.balanceOf(user3, losingScore);
        assertGt(user3Shares, 0, "User3 should have losing shares");

        vm.prank(user3);
        vm.expectRevert("MarketBase: Not winning outcome");
        scoreMarket.redeem(losingScore, user3Shares);
    }
}
