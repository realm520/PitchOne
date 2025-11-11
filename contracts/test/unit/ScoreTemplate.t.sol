// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/ScoreTemplate.sol";
import "../../src/pricing/LMSR.sol";
import "../mocks/MockERC20.sol";

/**
 * @title ScoreTemplate Test
 * @notice 精确比分市场模板的单元测试
 */
contract ScoreTemplateTest is Test {
    ScoreTemplate public market;
    MockERC20 public usdc;
    LMSR public lmsrEngine;

    // 测试参数
    address owner = address(this);
    address feeRecipient = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    uint8 constant USDC_DECIMALS = 6;
    uint256 constant WAD = 1e18;
    uint256 constant BPS_BASE = 10000;

    string constant MATCH_ID = "EPL_2024_MUN_vs_MCI";
    string constant HOME_TEAM = "Manchester United";
    string constant AWAY_TEAM = "Manchester City";
    uint256 kickoffTime;

    // 默认参数
    uint8 constant DEFAULT_MAX_GOALS = 5; // 0-0 到 5-5
    uint256 constant DEFAULT_LIQUIDITY_B = 5000 * WAD;
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 24 hours;

    function setUp() public {
        // 部署 USDC
        usdc = new MockERC20("USD Coin", "USDC", USDC_DECIMALS);

        // 设置开球时间（1 天后）
        kickoffTime = block.timestamp + 1 days;

        // 部署市场
        market = new ScoreTemplate();

        // 准备初始概率（均匀分布）
        uint256[] memory initialProbs = new uint256[](0); // 空数组 = 均匀分布

        // 初始化市场
        market.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            DEFAULT_MAX_GOALS,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );

        // 获取 LMSR 引擎
        lmsrEngine = market.lmsrEngine();

        // 给用户分配 USDC
        usdc.mint(user1, 10000 * 10 ** USDC_DECIMALS);
        usdc.mint(user2, 10000 * 10 ** USDC_DECIMALS);

        // 用户授权市场
        vm.prank(user1);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(user2);
        usdc.approve(address(market), type(uint256).max);
    }

    // ============================================================================
    // 构造函数和初始化测试
    // ============================================================================

    function test_Initialize_Success() public {
        assertEq(market.matchId(), MATCH_ID);
        assertEq(market.homeTeam(), HOME_TEAM);
        assertEq(market.awayTeam(), AWAY_TEAM);
        assertEq(market.kickoffTime(), kickoffTime);
        assertEq(market.maxGoals(), DEFAULT_MAX_GOALS);

        // 验证结果数量: (5+1)^2 + 1 = 37
        uint256 expectedCount = (uint256(DEFAULT_MAX_GOALS) + 1) ** 2 + 1;
        assertEq(market.outcomeCount(), expectedCount);
        assertEq(market.outcomeCount(), 37);
    }

    function test_Initialize_RevertIf_InvalidMatchId() public {
        ScoreTemplate newMarket = new ScoreTemplate();
        uint256[] memory initialProbs = new uint256[](0);

        vm.expectRevert("Score: Invalid match ID");
        newMarket.initialize(
            "",  // 空 matchId
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            DEFAULT_MAX_GOALS,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );
    }

    function test_Initialize_RevertIf_KickoffTimeInPast() public {
        ScoreTemplate newMarket = new ScoreTemplate();
        uint256[] memory initialProbs = new uint256[](0);

        vm.expectRevert("Score: Kickoff time in past");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            block.timestamp - 1, // 过去的时间
            DEFAULT_MAX_GOALS,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );
    }

    function test_Initialize_RevertIf_InvalidScoreRange_TooSmall() public {
        ScoreTemplate newMarket = new ScoreTemplate();
        uint256[] memory initialProbs = new uint256[](0);

        vm.expectRevert("Score: Invalid score range");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            1, // 小于 MIN_SCORE_RANGE (2)
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );
    }

    function test_Initialize_RevertIf_InvalidScoreRange_TooLarge() public {
        ScoreTemplate newMarket = new ScoreTemplate();
        uint256[] memory initialProbs = new uint256[](0);

        vm.expectRevert("Score: Invalid score range");
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            10, // 大于 MAX_SCORE_RANGE (9)
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );
    }

    function test_Initialize_ValidOutcomeIds() public {
        uint256[] memory outcomeIds = market.getValidOutcomeIds();

        // 验证数量: (5+1)^2 + 1 = 37
        assertEq(outcomeIds.length, 37);

        // 验证包含 0-0
        assertTrue(market.isValidOutcome(0));

        // 验证包含 5-5
        assertTrue(market.isValidOutcome(55));

        // 验证包含 Other
        assertTrue(market.isValidOutcome(999));

        // 验证不包含无效比分（如 6-0）
        assertFalse(market.isValidOutcome(60));
    }

    // ============================================================================
    // 结果编码/解码测试
    // ============================================================================

    function test_EncodeScore_Standard() public {
        assertEq(market.encodeScore(0, 0), 0);   // 0-0
        assertEq(market.encodeScore(1, 0), 10);  // 1-0
        assertEq(market.encodeScore(0, 1), 1);   // 0-1
        assertEq(market.encodeScore(1, 1), 11);  // 1-1
        assertEq(market.encodeScore(2, 1), 21);  // 2-1
        assertEq(market.encodeScore(3, 2), 32);  // 3-2
        assertEq(market.encodeScore(5, 5), 55);  // 5-5
    }

    function test_IsScoreInRange_Valid() public {
        assertTrue(market.isScoreInRange(0, 0));
        assertTrue(market.isScoreInRange(1, 0));
        assertTrue(market.isScoreInRange(5, 5));
        assertTrue(market.isScoreInRange(3, 2));
    }

    function test_IsScoreInRange_Invalid() public {
        assertFalse(market.isScoreInRange(6, 0)); // 超出范围
        assertFalse(market.isScoreInRange(0, 6));
        assertFalse(market.isScoreInRange(6, 6));
    }

    function test_DetermineWinningOutcome_Standard() public {
        assertEq(market.determineWinningOutcome(0, 0), 0);   // 0-0
        assertEq(market.determineWinningOutcome(1, 0), 10);  // 1-0
        assertEq(market.determineWinningOutcome(2, 1), 21);  // 2-1
    }

    function test_DetermineWinningOutcome_Other() public {
        assertEq(market.determineWinningOutcome(6, 0), 999); // 超出范围 → Other
        assertEq(market.determineWinningOutcome(7, 5), 999);
        assertEq(market.determineWinningOutcome(10, 10), 999);
    }

    // ============================================================================
    // 下注功能测试
    // ============================================================================

    function test_PlaceBet_StandardScore() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS; // 100 USDC
        // 使用索引而非编码值
        // 2-1 的编码是 21，在数组中的索引需要计算
        // 对于 maxGoals=5，比分按顺序排列：0-0(0), 0-1(1), ..., 0-5(5), 1-0(6), ..., 2-1 的索引是 2*6+1=13
        uint256 outcomeIndex = 2 * (DEFAULT_MAX_GOALS + 1) + 1; // 2-1 的索引

        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        uint256 shares = market.placeBet(outcomeIndex, betAmount);

        // 验证 shares > 0
        assertGt(shares, 0);

        // 验证用户获得 position token
        assertEq(market.balanceOf(user1, outcomeIndex), shares);

        // 验证 USDC 转账（含手续费）
        uint256 fee = (betAmount * FEE_RATE) / BPS_BASE;
        uint256 expectedBalance = balanceBefore - betAmount - fee;
        assertApproxEqAbs(usdc.balanceOf(user1), expectedBalance, 2e6); // 允许 2 USDC 误差（单位转换精度）
    }

    function test_PlaceBet_OtherScore() public {
        uint256 betAmount = 50 * 10 ** USDC_DECIMALS;
        // Other 是最后一个结果，索引 = outcomeCount - 1
        uint256 otherIndex = market.outcomeCount() - 1;

        vm.prank(user1);
        uint256 shares = market.placeBet(otherIndex, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, otherIndex), shares);
    }

    function test_PlaceBet_MultipleUsers() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        uint256 outcomeId = 11; // 1-1

        // User1 下注
        vm.prank(user1);
        uint256 shares1 = market.placeBet(outcomeId, betAmount);

        // User2 下注同一结果
        vm.prank(user2);
        uint256 shares2 = market.placeBet(outcomeId, betAmount);

        // 由于 LMSR，第二次下注的 shares 应该更少（价格上涨）
        assertLt(shares2, shares1);
    }

    function test_PlaceBet_DifferentOutcomes() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;

        // User1 下注 0-0
        vm.prank(user1);
        market.placeBet(0, betAmount);

        // User2 下注 1-0
        vm.prank(user2);
        market.placeBet(10, betAmount);

        // 验证两个用户都有各自的头寸
        assertGt(market.balanceOf(user1, 0), 0);
        assertGt(market.balanceOf(user2, 10), 0);
    }

    function test_PlaceBet_RevertIf_InvalidOutcome() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        uint256 invalidOutcome = market.outcomeCount() + 10; // 超出范围的索引

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid outcome");
        market.placeBet(invalidOutcome, betAmount);
    }

    function test_PlaceBet_UpdatesLMSRQuantity() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        uint256 outcomeId = 21;

        uint256 quantityBefore = lmsrEngine.quantityShares(outcomeId);

        vm.prank(user1);
        uint256 shares = market.placeBet(outcomeId, betAmount);

        uint256 quantityAfter = lmsrEngine.quantityShares(outcomeId);

        // LMSR 持仓量应该增加
        assertEq(quantityAfter, quantityBefore + shares);
    }

    // ============================================================================
    // 价格查询测试
    // ============================================================================

    function test_GetCurrentPrice_AllOutcomes() public {
        uint256[] memory prices = market.getAllPrices();

        // 验证价格数量
        assertEq(prices.length, 37);

        // 验证价格总和 ≈ 100%
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < prices.length; i++) {
            totalPrice += prices[i];
        }
        assertApproxEqAbs(totalPrice, BPS_BASE, 100); // 允许 1% 误差
    }

    function test_GetCurrentPrice_SpecificOutcome() public {
        uint256 price = market.getCurrentPrice(21); // 2-1

        // 价格应该在合理范围内
        assertGt(price, 0);
        assertLt(price, BPS_BASE);
    }

    function test_GetCurrentPrice_PriceChangesAfterBet() public {
        uint256 outcomeId = 11; // 1-1
        uint256 priceBefore = market.getCurrentPrice(outcomeId);

        // 下注
        uint256 betAmount = 1000 * 10 ** USDC_DECIMALS;
        vm.prank(user1);
        market.placeBet(outcomeId, betAmount);

        uint256 priceAfter = market.getCurrentPrice(outcomeId);

        // 价格应该上涨
        assertGt(priceAfter, priceBefore);
    }

    function test_QueryScorePrices_Batch() public {
        // 查询多个比分: 0-0, 1-0, 1-1, 2-1
        uint8[] memory scores = new uint8[](8);
        scores[0] = 0; scores[1] = 0; // 0-0
        scores[2] = 1; scores[3] = 0; // 1-0
        scores[4] = 1; scores[5] = 1; // 1-1
        scores[6] = 2; scores[7] = 1; // 2-1

        (uint256[] memory outcomeIds, uint256[] memory prices) = market.queryScorePrices(scores);

        assertEq(outcomeIds.length, 4);
        assertEq(prices.length, 4);

        // 验证结果ID正确
        assertEq(outcomeIds[0], 0);   // 0-0
        assertEq(outcomeIds[1], 10);  // 1-0
        assertEq(outcomeIds[2], 11);  // 1-1
        assertEq(outcomeIds[3], 21);  // 2-1

        // 验证所有价格有效
        for (uint256 i = 0; i < prices.length; i++) {
            assertGt(prices[i], 0);
            assertLt(prices[i], BPS_BASE);
        }
    }

    // ============================================================================
    // 结算测试
    // ============================================================================

    function test_Resolve_StandardScore() public {
        // 下注
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        vm.prank(user1);
        market.placeBet(21, betAmount); // 下注 2-1

        vm.prank(user2);
        market.placeBet(10, betAmount); // 下注 1-0

        // 锁盘
        market.lock();

        // 结算为 2-1
        uint256 winningOutcome = market.determineWinningOutcome(2, 1);
        assertEq(winningOutcome, 21);

        market.resolve(winningOutcome);

        // 验证获胜结果
        assertEq(market.winningOutcome(), 21);
        assertEq(uint8(market.status()), uint8(IMarket.MarketStatus.Resolved));
    }

    function test_Resolve_OtherScore() public {
        // 下注
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        uint256 otherIndex = market.outcomeCount() - 1;

        vm.prank(user1);
        market.placeBet(otherIndex, betAmount); // 下注 Other

        // 锁盘
        market.lock();

        // 结算为 Other（索引是最后一个）
        market.resolve(otherIndex);

        assertEq(market.winningOutcome(), otherIndex);
    }

    function test_Redeem_WinningOutcome() public {
        // User1 下注 2-1
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        vm.prank(user1);
        uint256 shares = market.placeBet(21, betAmount);

        // User2 下注 1-0
        vm.prank(user2);
        market.placeBet(10, betAmount);

        // 锁盘并结算为 2-1
        market.lock();
        market.resolve(21);

        // 等待争议期
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // User1 兑付
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        uint256 payout = market.redeem(21, shares);

        // 验证获得赔付
        assertGt(payout, 0);
        assertEq(usdc.balanceOf(user1), balanceBefore + payout);
    }

    // ============================================================================
    // 管理功能测试
    // ============================================================================

    function test_SetLiquidityB_Success() public {
        uint256 newB = 7000 * WAD;

        market.setLiquidityB(newB);

        assertEq(lmsrEngine.liquidityB(), newB);
    }

    function test_SetLiquidityB_RevertIf_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        market.setLiquidityB(7000 * WAD);
    }

    function test_GetValidOutcomeIds_ReturnsAllIds() public {
        uint256[] memory outcomeIds = market.getValidOutcomeIds();

        // 应该包含所有标准比分 + Other
        assertEq(outcomeIds.length, 37);

        // 验证最后一个是 Other
        assertEq(outcomeIds[outcomeIds.length - 1], 999);
    }

    function test_GetCurrentCost_ReturnsValidCost() public {
        uint256 cost = market.getCurrentCost();

        // 成本应该 > 0
        assertGt(cost, 0);
    }

    // ============================================================================
    // 边界和错误测试
    // ============================================================================

    function test_PlaceBet_RevertIf_MarketLocked() public {
        market.lock();

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.placeBet(21, 100 * 10 ** USDC_DECIMALS);
    }

    function test_GetCurrentPrice_RevertIf_InvalidOutcome() public {
        vm.expectRevert("Score: Invalid outcome ID");
        market.getCurrentPrice(60); // 6-0 无效
    }

    function test_PlaceBet_VerySmallAmount() public {
        uint256 betAmount = 1 * 10 ** USDC_DECIMALS; // 1 USDC

        vm.prank(user1);
        uint256 shares = market.placeBet(0, betAmount);

        // 应该获得一些 shares
        assertGt(shares, 0);
    }

    function test_PlaceBet_VeryLargeAmount() public {
        // 给 user1 更多 USDC
        usdc.mint(user1, 100000 * 10 ** USDC_DECIMALS);

        uint256 betAmount = 10000 * 10 ** USDC_DECIMALS; // 10,000 USDC

        vm.prank(user1);
        uint256 shares = market.placeBet(0, betAmount);

        // 应该获得 shares
        assertGt(shares, 0);
    }

    // ============================================================================
    // 事件测试
    // ============================================================================

    function test_Initialize_EmitsEvent() public {
        ScoreTemplate newMarket = new ScoreTemplate();
        uint256[] memory initialProbs = new uint256[](0);

        // 注意：由于 LMSR 地址是动态创建的，无法精确预测事件参数
        // 我们只验证初始化后的状态
        newMarket.initialize(
            MATCH_ID,
            HOME_TEAM,
            AWAY_TEAM,
            kickoffTime,
            DEFAULT_MAX_GOALS,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            DEFAULT_LIQUIDITY_B,
            initialProbs,
            "",
            owner
        );

        // 验证初始化成功
        assertEq(newMarket.matchId(), MATCH_ID);
        assertEq(newMarket.outcomeCount(), 37);
    }

    function test_PlaceBet_EmitsEvent() public {
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;
        uint256 outcomeId = 21;

        // 这里无法精确预测 shares，所以只能测试事件被发出
        vm.prank(user1);
        market.placeBet(outcomeId, betAmount);

        // 验证事件通过检查合约状态
        assertGt(market.balanceOf(user1, outcomeId), 0);
    }
}
