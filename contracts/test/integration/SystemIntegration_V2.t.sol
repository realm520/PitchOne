// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/MarketFactory_v2.sol";
import "../../src/templates/WDL_Template_V2.sol";
import "../../src/liquidity/LiquidityVault.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../../src/core/FeeRouter.sol";
import "../mocks/MockERC20.sol";

/**
 * @title SystemIntegration_V2
 * @notice 集成测试 - 验证V2系统的端到端流程
 * @dev 测试场景：
 *      1. 完整市场生命周期（创建→下注→锁盘→结算→赎回）
 *      2. 多市场并发操作（共享Vault）
 *      3. Vault流动性管理
 *      4. 多用户交互
 *      5. 事件验证
 */
contract SystemIntegration_V2Test is Test {
    // ============ 合约实例 ============
    MockERC20 public usdc;
    LiquidityVault public vault;
    SimpleCPMM public cpmm;
    FeeRouter public feeRouter;
    MarketFactory_v2 public factory;

    // ============ 测试账户 ============
    address public owner;
    address public lpProvider;
    address public user1;
    address public user2;
    address public user3;
    address public feeRecipient;

    // ============ 常量 ============
    uint256 constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100k USDC - Virtual reserve for AMM mode
    uint256 constant INITIAL_LP_DEPOSIT = 1_000_000 * 1e6; // 1M USDC
    uint256 constant MARKET_BORROW_AMOUNT = 100_000 * 1e6; // 100k USDC
    uint256 constant BET_AMOUNT = 10_000 * 1e6; // 10k USDC
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 7200; // 2小时

    // ============ 事件 ============
    event MarketCreated(address indexed market, uint256 templateId, address creator);
    event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee);
    event Resolved(uint256 indexed winningOutcome, uint256 timestamp);
    event Redeemed(address indexed user, uint256 indexed outcomeId, uint256 shares, uint256 payout);

    function setUp() public {
        // 1. 创建账户
        owner = address(this);
        lpProvider = makeAddr("lpProvider");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        feeRecipient = makeAddr("feeRecipient");

        // 2. 部署基础设施
        usdc = new MockERC20("USDC", "USDC", 6);
        vault = new LiquidityVault(IERC20(address(usdc)), "PitchOne LP", "pLP");
        cpmm = new SimpleCPMM(100_000 * 10**6);

        // 创建FeeRouter（需要FeeRecipients结构体）
        FeeRouter.FeeRecipients memory feeRecipients = FeeRouter.FeeRecipients({
            lpVault: address(vault),
            promoPool: makeAddr("promoPool"),
            insuranceFund: makeAddr("insuranceFund"),
            treasury: makeAddr("treasury")
        });
        feeRouter = new FeeRouter(feeRecipients, makeAddr("referralRegistry"));

        // 3. 部署Factory（无参数构造函数）
        factory = new MarketFactory_v2();

        // 4. 注册WDL模板
        WDL_Template_V2 wdlImplementation = new WDL_Template_V2();
        wdlImplementation.initialize(
            "IMPL",
            "TeamA",
            "TeamB",
            block.timestamp + 1000,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "", // WDL_Template_V2 没有 owner 参数
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        bytes32 templateId = factory.registerTemplate("WDL", "V2", address(wdlImplementation));

        // 5. 初始化流动性
        usdc.mint(lpProvider, INITIAL_LP_DEPOSIT);
        vm.startPrank(lpProvider);
        usdc.approve(address(vault), INITIAL_LP_DEPOSIT);
        vault.deposit(INITIAL_LP_DEPOSIT, lpProvider);
        vm.stopPrank();

        // 7. 为用户分配资金
        usdc.mint(user1, BET_AMOUNT * 10);
        usdc.mint(user2, BET_AMOUNT * 10);
        usdc.mint(user3, BET_AMOUNT * 10);
    }

    // ============ 辅助函数 ============

    function skipTime(uint256 duration) internal {
        vm.warp(block.timestamp + duration);
    }

    function createWDLMarket(string memory matchId, uint256 kickoffTime)
        internal
        returns (WDL_Template_V2)
    {
        // 直接部署WDL_Template_V2实例（使用initialize模式）
        WDL_Template_V2 market = new WDL_Template_V2();
        market.initialize(
            matchId,
            "Manchester United",
            "Manchester City",
            kickoffTime,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            address(vault),
            "ipfs://test", // WDL_Template_V2 没有 owner 参数
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        // 授权市场从Vault借款
        vault.authorizeMarket(address(market));

        // 注册到Factory（用于Subgraph索引）
        bytes32 templateId = keccak256(abi.encode("WDL", "V2"));
        factory.recordMarket(address(market), templateId);

        return market;
    }

    // ============ 集成测试 ============

    /**
     * @notice 测试1：完整的市场生命周期
     * @dev 创建市场 → 多用户下注 → 锁盘 → 结算 → 赎回
     */
    function test_Integration_FullMarketLifecycle() public {
        // 1. 创建市场
        uint256 kickoffTime = block.timestamp + 3600;
        WDL_Template_V2 market = createWDLMarket("EPL_2024_MUN_vs_MCI", kickoffTime);

        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open), "Market should be Open");

        // 2. 用户下注（模拟真实市场）
        vm.startPrank(user1);
        usdc.approve(address(market), BET_AMOUNT * 3);
        uint256 shares1 = market.placeBet(0, BET_AMOUNT * 3); // 30k on Win
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(market), BET_AMOUNT * 2);
        uint256 shares2 = market.placeBet(1, BET_AMOUNT * 2); // 20k on Draw
        vm.stopPrank();

        vm.startPrank(user3);
        usdc.approve(address(market), BET_AMOUNT);
        uint256 shares3 = market.placeBet(2, BET_AMOUNT); // 10k on Loss
        vm.stopPrank();

        // 验证流动性
        assertTrue(market.liquidityBorrowed(), "Should have borrowed from Vault");
        assertGt(market.totalLiquidity(), MARKET_BORROW_AMOUNT, "Total liquidity should include bets");

        // 3. 锁盘（开赛前）
        skipTime(3500); // 接近开赛时间
        market.lock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked), "Market should be Locked");

        // 4. 结算（主队胜，outcome 0）
        skipTime(7200); // 比赛结束
        market.resolve(0);
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Resolved), "Market should be Resolved");
        assertEq(market.winningOutcome(), 0, "Outcome 0 should win");

        // 5. Finalize（归还Vault本金）
        skipTime(DISPUTE_PERIOD);
        market.finalize();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Finalized), "Market should be Finalized");
        assertTrue(market.liquidityRepaid(), "Should have repaid Vault");

        // 6. 赢家赎回
        uint256 user1BalanceBefore = usdc.balanceOf(user1);
        vm.prank(user1);
        uint256 payout = market.redeem(0, shares1);

        assertGt(payout, BET_AMOUNT * 3, "Payout should be greater than bet (won)");
        assertEq(usdc.balanceOf(user1), user1BalanceBefore + payout, "Balance should increase");
        assertEq(market.balanceOf(user1, 0), 0, "Shares should be burned");

        // 7. 输家无法赎回
        vm.prank(user2);
        vm.expectRevert("MarketBase_V2: Not winning outcome");
        market.redeem(1, shares2);

        vm.prank(user3);
        vm.expectRevert("MarketBase_V2: Not winning outcome");
        market.redeem(2, shares3);
    }

    /**
     * @notice 测试2：多市场并发操作（共享Vault）
     * @dev 创建3个市场，同时进行，验证Vault流动性管理
     */
    function test_Integration_MultipleMarketsSharedVault() public {
        // 1. 创建3个市场
        WDL_Template_V2 market1 = createWDLMarket("MATCH_1", block.timestamp + 3600);
        WDL_Template_V2 market2 = createWDLMarket("MATCH_2", block.timestamp + 7200);
        WDL_Template_V2 market3 = createWDLMarket("MATCH_3", block.timestamp + 10800);

        // 2. 验证Vault初始状态
        uint256 vaultTotalAssets = vault.totalAssets();
        assertEq(vaultTotalAssets, INITIAL_LP_DEPOSIT, "Vault should have LP deposit");

        // 3. 所有市场各有一笔下注（触发借款）
        vm.startPrank(user1);
        usdc.approve(address(market1), BET_AMOUNT);
        usdc.approve(address(market2), BET_AMOUNT);
        usdc.approve(address(market3), BET_AMOUNT);
        market1.placeBet(0, BET_AMOUNT);
        market2.placeBet(1, BET_AMOUNT);
        market3.placeBet(2, BET_AMOUNT);
        vm.stopPrank();

        // 4. 验证Vault借出金额
        uint256 totalBorrowed = vault.totalBorrowed();
        assertEq(totalBorrowed, MARKET_BORROW_AMOUNT * 3, "Should borrow for 3 markets");

        // 验证每个市场的借款记录
        assertEq(vault.borrowed(address(market1)), MARKET_BORROW_AMOUNT, "Market1 borrowed");
        assertEq(vault.borrowed(address(market2)), MARKET_BORROW_AMOUNT, "Market2 borrowed");
        assertEq(vault.borrowed(address(market3)), MARKET_BORROW_AMOUNT, "Market3 borrowed");

        // 5. 结算并归还 Market1
        skipTime(3600);
        market1.lock();
        market1.resolve(0);
        skipTime(DISPUTE_PERIOD);
        market1.finalize();

        // 验证Market1已归还
        assertEq(vault.borrowed(address(market1)), 0, "Market1 should repay");
        uint256 totalBorrowedAfter = vault.totalBorrowed();
        assertEq(totalBorrowedAfter, MARKET_BORROW_AMOUNT * 2, "Only 2 markets borrowed");

        // 6. 验证LP收益增加
        uint256 vaultAssetsAfter = vault.totalAssets();
        assertGe(vaultAssetsAfter, vaultTotalAssets, "Vault should have revenue from Market1");
    }

    /**
     * @notice 测试3：Vault利用率限制
     * @dev 当Vault接近最大利用率时，新市场应无法借款
     */
    function test_Integration_VaultUtilizationLimit() public {
        // 1. 计算最大可创建市场数量
        // MAX_UTILIZATION_BPS = 9000 (90%)
        // 可借出 = 1M * 90% = 900k
        // 每个市场借 100k，最多可创建9个市场

        WDL_Template_V2[] memory markets = new WDL_Template_V2[](9);

        // 2. 创建9个市场并下注（触发借款）
        for (uint256 i = 0; i < 9; i++) {
            markets[i] = createWDLMarket(
                string(abi.encodePacked("MATCH_", vm.toString(i))),
                block.timestamp + 1000
            );

            vm.startPrank(user1);
            usdc.approve(address(markets[i]), BET_AMOUNT);
            markets[i].placeBet(0, BET_AMOUNT);
            vm.stopPrank();
        }

        // 3. 验证已借出90%
        uint256 totalBorrowed = vault.totalBorrowed();
        assertEq(totalBorrowed, MARKET_BORROW_AMOUNT * 9, "Should borrow 900k");

        // 4. 创建第10个市场
        WDL_Template_V2 market10 = createWDLMarket("MATCH_10", block.timestamp + 1000);

        // 5. 尝试下注（应该失败，因为Vault无法借出更多）
        vm.startPrank(user1);
        usdc.approve(address(market10), BET_AMOUNT);
        vm.expectRevert(); // Vault.borrow() 会因超过MAX_UTILIZATION而revert
        market10.placeBet(0, BET_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice 测试4：大额下注对价格的影响
     * @dev 验证SimpleCPMM定价在大额交易下的行为
     */
    function test_Integration_LargeBetPriceImpact() public {
        WDL_Template_V2 market = createWDLMarket("MATCH_PRICE_IMPACT", block.timestamp + 3600);

        // 1. 记录初始价格
        uint256[] memory pricesBefore = market.getAllPrices();

        // 2. 大额下注（100k USDC on outcome 0）
        vm.startPrank(user1);
        usdc.mint(user1, 100_000 * 1e6);
        usdc.approve(address(market), 100_000 * 1e6);
        market.placeBet(0, 100_000 * 1e6);
        vm.stopPrank();

        // 3. 验证价格变化
        uint256[] memory pricesAfter = market.getAllPrices();

        // Outcome 0价格应该上涨（需求增加）
        assertGt(pricesAfter[0], pricesBefore[0], "Outcome 0 price should increase");

        // 对手盘价格应该下降
        assertLt(pricesAfter[1], pricesBefore[1], "Outcome 1 price should decrease");
        assertLt(pricesAfter[2], pricesBefore[2], "Outcome 2 price should decrease");

        // 所有价格之和应该 ≈ 10000 (100%)
        uint256 totalPrice = pricesAfter[0] + pricesAfter[1] + pricesAfter[2];
        assertApproxEqAbs(totalPrice, 10000, 100, "Total probability should be 100%");
    }

    /**
     * @notice 测试5：赎回时的收益分配
     * @dev 多个赢家按比例分配收益
     */
    function test_Integration_MultipleWinnersProportionalPayout() public {
        WDL_Template_V2 market = createWDLMarket("MATCH_MULTI_WINNERS", block.timestamp + 3600);

        // 1. 三个用户都下注outcome 0（都是赢家）
        vm.startPrank(user1);
        usdc.approve(address(market), BET_AMOUNT * 3);
        uint256 shares1 = market.placeBet(0, BET_AMOUNT * 3); // 30k
        vm.stopPrank();

        vm.startPrank(user2);
        usdc.approve(address(market), BET_AMOUNT * 2);
        uint256 shares2 = market.placeBet(0, BET_AMOUNT * 2); // 20k
        vm.stopPrank();

        vm.startPrank(user3);
        usdc.approve(address(market), BET_AMOUNT);
        uint256 shares3 = market.placeBet(0, BET_AMOUNT); // 10k
        vm.stopPrank();

        // 2. 结算
        skipTime(3600);
        market.lock();
        market.resolve(0);
        skipTime(DISPUTE_PERIOD);
        market.finalize();

        // 3. 赎回
        vm.prank(user1);
        uint256 payout1 = market.redeem(0, shares1);

        vm.prank(user2);
        uint256 payout2 = market.redeem(0, shares2);

        vm.prank(user3);
        uint256 payout3 = market.redeem(0, shares3);

        // 4. 验证比例（应该按份额比例分配）
        // 由于CPMM有滑点，份额不等于下注金额，需要按实际份额比例验证
        // payout1 / payout2 应该 ≈ shares1 / shares2
        uint256 expectedPayout2 = (payout1 * shares2) / shares1;
        uint256 expectedPayout3 = (payout1 * shares3) / shares1;

        assertApproxEqRel(payout2, expectedPayout2, 0.01e18, "Payout ratio should match share ratio 1:2");
        assertApproxEqRel(payout3, expectedPayout3, 0.01e18, "Payout ratio should match share ratio 1:3");

        // 验证总收益（应该等于净下注金额，扣除手续费）
        uint256 totalPayout = payout1 + payout2 + payout3;
        uint256 totalBets = BET_AMOUNT * 3 + BET_AMOUNT * 2 + BET_AMOUNT; // 30k + 20k + 10k = 60k
        uint256 netBets = totalBets * (10000 - FEE_RATE) / 10000; // 扣除2%手续费
        assertApproxEqAbs(totalPayout, netBets, 100, "Total payout should equal net bets");
    }

    /**
     * @notice 测试6：紧急情况下的暂停和恢复
     * @dev 验证暂停机制在系统级的工作
     */
    function test_Integration_EmergencyPauseSystem() public {
        WDL_Template_V2 market = createWDLMarket("MATCH_PAUSE", block.timestamp + 3600);

        // 1. 正常下注
        vm.startPrank(user1);
        usdc.approve(address(market), BET_AMOUNT);
        market.placeBet(0, BET_AMOUNT);
        vm.stopPrank();

        // 2. 暂停市场
        market.pause();

        // 3. 暂停期间无法下注
        vm.startPrank(user2);
        usdc.approve(address(market), BET_AMOUNT);
        vm.expectRevert();
        market.placeBet(1, BET_AMOUNT);
        vm.stopPrank();

        // 4. 恢复市场
        market.unpause();

        // 5. 恢复后可以下注
        vm.startPrank(user2);
        usdc.approve(address(market), BET_AMOUNT);
        market.placeBet(1, BET_AMOUNT);
        vm.stopPrank();
    }

    /**
     * @notice 测试7：Factory批量创建市场
     * @dev 验证快速创建多个市场的能力
     */
    function test_Integration_BatchMarketCreation() public {
        uint256 marketCount = 10;
        address[] memory markets = new address[](marketCount);

        // 1. 批量创建市场
        for (uint256 i = 0; i < marketCount; i++) {
            markets[i] = address(
                createWDLMarket(
                    string(abi.encodePacked("BATCH_", vm.toString(i))),
                    block.timestamp + (i + 1) * 3600
                )
            );
        }

        // 2. 验证所有市场已注册
        uint256 count = factory.getMarketCount();
        assertEq(count, marketCount, "Should have created all markets");

        // 3. 验证每个市场都是独立的合约
        for (uint256 i = 0; i < marketCount; i++) {
            assertTrue(factory.isMarket(markets[i]), "Should be registered market");
            assertGt(markets[i].code.length, 0, "Should have contract code");
        }
    }

    /**
     * @notice 测试8：虚拟储备在连续交易中的更新
     * @dev 验证CPMM在多次交易后的储备平衡
     */
    function test_Integration_VirtualReservesBalance() public {
        WDL_Template_V2 market = createWDLMarket("MATCH_RESERVES", block.timestamp + 3600);

        uint256 VIRTUAL_RESERVE_INIT = 100_000 * 1e6;

        // 1. 初始储备应该均等
        uint256[] memory reservesInit = market.getVirtualReserves();
        assertEq(reservesInit.length, 3, "Should have 3 reserves");
        for (uint256 i = 0; i < 3; i++) {
            assertEq(reservesInit[i], VIRTUAL_RESERVE_INIT, "Initial reserves should be equal");
        }

        // 2. 连续下注不同结果
        vm.startPrank(user1);
        usdc.approve(address(market), BET_AMOUNT * 3);
        market.placeBet(0, BET_AMOUNT);
        market.placeBet(1, BET_AMOUNT);
        market.placeBet(2, BET_AMOUNT);
        vm.stopPrank();

        // 3. 验证储备总体平衡（没有极端偏差）
        uint256[] memory reservesAfter = market.getVirtualReserves();
        uint256 minReserve = type(uint256).max;
        uint256 maxReserve = 0;

        for (uint256 i = 0; i < 3; i++) {
            if (reservesAfter[i] < minReserve) minReserve = reservesAfter[i];
            if (reservesAfter[i] > maxReserve) maxReserve = reservesAfter[i];
        }

        // 最大储备不应超过最小储备的2倍（相对平衡）
        assertLt(maxReserve, minReserve * 2, "Reserves should stay relatively balanced");
    }
}
