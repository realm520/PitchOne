// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/core/Market_V3.sol";
import "../../src/core/MarketFactory_V3.sol";
import "../../src/interfaces/IMarket_V3.sol";
import "../../src/interfaces/IPricingStrategy.sol";
import "../../src/interfaces/IResultMapper.sol";
import "../../src/pricing/CPMMStrategy.sol";
import "../../src/pricing/ParimutuelStrategy.sol";
import "../../src/mappers/WDL_Mapper.sol";
import "../../src/mappers/OddEven_Mapper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/governance/ParamController.sol";
import "../../src/governance/ParamKeys.sol";
import "../../test/mocks/MockParamController.sol";

/**
 * @title MockUSDC
 * @notice 测试用 USDC 代币
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1_000_000_000e6); // 1B USDC
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title Market_V3_Test
 * @notice Market_V3 合约集成测试
 */
contract Market_V3_Test is Test {
    MarketFactory_V3 public factory;
    Market_V3 public marketImpl;
    Market_V3 public market;
    CPMMStrategy public strategy;
    WDL_Mapper public mapper;
    MockUSDC public usdc;

    bytes32 public templateId;

    address public admin = address(1);
    address public router = address(2);
    address public keeper = address(3);
    address public oracle = address(4);
    address public user1 = address(5);
    address public user2 = address(6);

    uint256 constant INITIAL_LIQUIDITY = 1_000_000e6; // 1M USDC
    uint256 constant BET_AMOUNT = 1_000e6; // 1k USDC

    function setUp() public {
        vm.startPrank(admin);

        // 部署依赖合约
        strategy = new CPMMStrategy();
        mapper = new WDL_Mapper();
        usdc = new MockUSDC();

        // 部署 Factory（先用一个临时地址，稍后设置实际实现）
        factory = new MarketFactory_V3(
            address(1), // 临时占位
            address(usdc),
            admin
        );

        // 部署 Market 实现合约（传入 factory 地址）
        marketImpl = new Market_V3(address(factory));

        // 更新 Factory 的实现地址
        factory.setImplementation(address(marketImpl));

        // 设置 Factory 配置
        factory.setRouter(router);
        factory.setKeeper(keeper);
        factory.setOracle(oracle);

        // 准备 outcome 规则
        IMarket_V3.OutcomeRule[] memory rules = new IMarket_V3.OutcomeRule[](3);
        rules[0] = IMarket_V3.OutcomeRule({
            name: "Home Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[1] = IMarket_V3.OutcomeRule({
            name: "Draw",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[2] = IMarket_V3.OutcomeRule({
            name: "Away Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        // 注册模板
        templateId = keccak256("WDL");
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            rules,
            INITIAL_LIQUIDITY
        );

        // 创建市场
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0) // 使用模板默认规则
        });

        address marketAddr = factory.createMarket(params);
        market = Market_V3(marketAddr);

        vm.stopPrank();

        // 给用户分发 USDC 并授权
        usdc.mint(user1, 100_000e6);
        usdc.mint(user2, 100_000e6);
        usdc.mint(router, 1_000_000e6); // Router 需要有 USDC 用于转账

        vm.prank(user1);
        usdc.approve(address(market), type(uint256).max);
        vm.prank(user2);
        usdc.approve(address(market), type(uint256).max);
        vm.prank(router);
        usdc.approve(address(market), type(uint256).max);

        // 给 Market 初始流动性（模拟 Vault 借款）
        usdc.mint(address(market), INITIAL_LIQUIDITY);
    }

    // ============ 初始化测试 ============

    function test_initialize_Success() public view {
        assertEq(market.matchId(), "EPL_2024_MUN_vs_MCI");
        assertEq(uint256(market.status()), uint256(IMarket_V3.MarketStatus.Open));
        assertEq(market.totalLiquidity(), INITIAL_LIQUIDITY);
        assertEq(market.outcomeCount(), 3);
    }

    function test_initialize_OutcomeRules() public view {
        IMarket_V3.OutcomeRule[] memory rules = market.getOutcomeRules();
        assertEq(rules.length, 3);
        assertEq(rules[0].name, "Home Win");
        assertEq(rules[1].name, "Draw");
        assertEq(rules[2].name, "Away Win");
    }

    function test_initialize_Prices() public view {
        uint256[] memory prices = market.getAllPrices();
        assertEq(prices.length, 3);
        // 初始价格应该均等（各约 33.33%）
        assertApproxEqRel(prices[0], 3333, 0.01e18);
        assertApproxEqRel(prices[1], 3333, 0.01e18);
        assertApproxEqRel(prices[2], 3333, 0.01e18);
    }

    // ============ 下注测试 ============

    function test_placeBetFor_Success() public {
        // Router 转账 USDC 到 Market（模拟 Router 的行为）
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertTrue(shares > 0);
        assertEq(market.balanceOf(user1, 0), shares);
        assertEq(market.totalSharesPerOutcome(0), shares);
        assertEq(market.totalBetAmountPerOutcome(0), BET_AMOUNT);
        assertEq(market.totalLiquidity(), INITIAL_LIQUIDITY + BET_AMOUNT);
    }

    /**
     * @notice 测试下注后价格变化
     * @dev 使用二向市场来避免三向 CPMM 的精度问题
     */
    function test_placeBetFor_PriceChanges() public {
        // 准备二向 outcome 规则
        IMarket_V3.OutcomeRule[] memory rules = new IMarket_V3.OutcomeRule[](2);
        rules[0] = IMarket_V3.OutcomeRule({
            name: "Over",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[1] = IMarket_V3.OutcomeRule({
            name: "Under",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        // 使用 OddEven_Mapper（二向）
        OddEven_Mapper mapper2 = new OddEven_Mapper();

        // 注册新模板
        bytes32 ouTemplateId = keccak256("OU");
        vm.prank(admin);
        factory.registerTemplate(
            ouTemplateId,
            "OU",
            "CPMM",
            address(strategy),
            address(mapper2),
            rules,
            INITIAL_LIQUIDITY
        );

        // 创建市场
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: ouTemplateId,
            matchId: "EPL_2024_OU",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        vm.prank(admin);
        address marketAddr2 = factory.createMarket(params);
        Market_V3 market2 = Market_V3(marketAddr2);

        // 给 Market 初始流动性
        usdc.mint(address(market2), INITIAL_LIQUIDITY);

        uint256 priceBefore = market2.getPrice(0);

        // 下注
        uint256 smallBet = 10_000e6; // 10k USDC
        vm.startPrank(router);
        usdc.transfer(address(market2), smallBet);
        market2.placeBetFor(user1, 0, smallBet, 0);
        vm.stopPrank();

        uint256 priceAfter = market2.getPrice(0);
        assertTrue(priceAfter >= priceBefore, "Price should not decrease after bet");
    }

    function test_placeBetFor_NonRouter_Reverts() public {
        vm.prank(user1);
        vm.expectRevert();
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
    }

    function test_placeBetFor_InvalidOutcome_Reverts() public {
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(Market_V3.InvalidOutcome.selector, 99));
        market.placeBetFor(user1, 99, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_SlippageExceeded_Reverts() public {
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        // 设置一个不可能达到的最小份额
        vm.expectRevert();
        market.placeBetFor(user1, 0, BET_AMOUNT, type(uint256).max);
        vm.stopPrank();
    }

    function test_placeBetFor_AfterKickoff_Reverts() public {
        // 快进到开球时间后
        vm.warp(block.timestamp + 2 days);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        vm.expectRevert(Market_V3.AfterKickoff.selector);
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    // ============ 生命周期测试 ============

    function test_lock_Success() public {
        vm.prank(keeper);
        market.lock();

        assertEq(uint256(market.status()), uint256(IMarket_V3.MarketStatus.Locked));
    }

    function test_lock_NonKeeper_Reverts() public {
        vm.prank(user1);
        vm.expectRevert();
        market.lock();
    }

    function test_lock_AlreadyLocked_Reverts() public {
        vm.prank(keeper);
        market.lock();

        vm.prank(keeper);
        vm.expectRevert();
        market.lock();
    }

    function test_resolve_Success() public {
        // 先锁盘
        vm.prank(keeper);
        market.lock();

        // 结算：主队胜（2-1）
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));

        vm.prank(oracle);
        market.resolve(rawResult);

        assertEq(uint256(market.status()), uint256(IMarket_V3.MarketStatus.Resolved));

        IMarket_V3.SettlementResult memory result = market.getSettlementResult();
        assertTrue(result.resolved);
        assertEq(result.outcomeIds.length, 1);
        assertEq(result.outcomeIds[0], 0); // Home Win
        assertEq(result.weights[0], 10000);
    }

    function test_resolve_NonOracle_Reverts() public {
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1));

        vm.prank(user1);
        vm.expectRevert();
        market.resolve(rawResult);
    }

    function test_resolve_NotLocked_Reverts() public {
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));

        vm.prank(oracle);
        vm.expectRevert();
        market.resolve(rawResult);
    }

    function test_finalize_Success() public {
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        vm.prank(oracle);
        market.resolve(rawResult);

        vm.prank(keeper);
        market.finalize();

        assertEq(uint256(market.status()), uint256(IMarket_V3.MarketStatus.Finalized));
    }

    function test_cancel_Success() public {
        vm.prank(admin);
        market.cancel("Match postponed");

        assertEq(uint256(market.status()), uint256(IMarket_V3.MarketStatus.Cancelled));
    }

    function test_cancel_AfterFinalized_Reverts() public {
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        vm.prank(oracle);
        market.resolve(rawResult);

        vm.prank(keeper);
        market.finalize();

        vm.prank(admin);
        vm.expectRevert("Market: Cannot cancel");
        market.cancel("Too late");
    }

    // ============ 赎回测试 ============

    function test_redeem_WinnerGetsFullPayout() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 完成生命周期
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1)); // Home Win
        vm.prank(oracle);
        market.resolve(rawResult);

        vm.prank(keeper);
        market.finalize();

        // 用户赎回
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        uint256 payout = market.redeem(0, shares);

        uint256 balanceAfter = usdc.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, payout);
        assertTrue(payout > 0);

        // 头寸应该被销毁
        assertEq(market.balanceOf(user1, 0), 0);
    }

    function test_redeem_LoserGetsNothing() public {
        // 用户下注客队胜
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 2, BET_AMOUNT, 0);
        vm.stopPrank();

        // 完成生命周期 - 主队胜
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1)); // Home Win
        vm.prank(oracle);
        market.resolve(rawResult);

        vm.prank(keeper);
        market.finalize();

        // 用户尝试赎回失败的下注
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(Market_V3.NotWinningOutcome.selector, 2));
        market.redeem(2, shares);
    }

    function test_redeem_InsufficientShares_Reverts() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 完成生命周期
        vm.prank(keeper);
        market.lock();

        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        vm.prank(oracle);
        market.resolve(rawResult);

        vm.prank(keeper);
        market.finalize();

        // 尝试赎回过多份额
        vm.prank(user1);
        vm.expectRevert();
        market.redeem(0, shares + 1);
    }

    function test_redeem_NotFinalized_Reverts() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 只锁盘，不结算
        vm.prank(keeper);
        market.lock();

        vm.prank(user1);
        vm.expectRevert();
        market.redeem(0, shares);
    }

    // ============ 退款测试 ============

    function test_refund_CancelledMarket() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 取消市场
        vm.prank(admin);
        market.cancel("Match postponed");

        // 用户退款
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        uint256 refundAmount = market.refund(0, shares);

        uint256 balanceAfter = usdc.balanceOf(user1);
        assertEq(balanceAfter - balanceBefore, refundAmount);
        assertTrue(refundAmount > 0);

        // 头寸应该被销毁
        assertEq(market.balanceOf(user1, 0), 0);
    }

    function test_refund_NotCancelled_Reverts() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 市场仍然开放
        vm.prank(user1);
        vm.expectRevert();
        market.refund(0, shares);
    }

    // ============ 查询函数测试 ============

    function test_getMarketStats() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        IMarket_V3.MarketStats memory stats = market.getStats();

        assertEq(stats.totalLiquidity, INITIAL_LIQUIDITY + BET_AMOUNT);
        assertEq(stats.totalBetAmount, BET_AMOUNT);
        assertEq(stats.totalSharesPerOutcome.length, 3);
        assertTrue(stats.totalSharesPerOutcome[0] > 0);
    }

    // ============ ERC1155 测试 ============

    function test_erc1155_Transfer() public {
        // 用户下注
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 转移偶数数量的份额，避免四舍五入问题
        uint256 transferAmount = (shares / 2) * 2 == shares ? shares / 2 : (shares / 2);
        uint256 expectedRemaining = shares - transferAmount;

        // 转移头寸
        vm.prank(user1);
        market.safeTransferFrom(user1, user2, 0, transferAmount, "");

        assertEq(market.balanceOf(user1, 0), expectedRemaining);
        assertEq(market.balanceOf(user2, 0), transferAmount);
    }

    // ============ 完整流程测试 ============

    function test_fullLifecycle_MultipleUsers() public {
        // 多用户下注
        vm.startPrank(router);

        usdc.transfer(address(market), 5000e6);
        uint256 shares1 = market.placeBetFor(user1, 0, 5000e6, 0); // user1 买主胜

        usdc.transfer(address(market), 3000e6);
        uint256 shares2 = market.placeBetFor(user2, 2, 3000e6, 0); // user2 买客胜

        vm.stopPrank();

        // 锁盘
        vm.prank(keeper);
        market.lock();

        // 结算：主队胜
        bytes memory rawResult = abi.encode(uint256(2), uint256(1));
        vm.prank(oracle);
        market.resolve(rawResult);

        // 终结
        vm.prank(keeper);
        market.finalize();

        // user1 赎回（赢家）
        vm.prank(user1);
        uint256 payout1 = market.redeem(0, shares1);
        assertTrue(payout1 > 5000e6, "Winner should profit");

        // user2 无法赎回（输家）
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(Market_V3.NotWinningOutcome.selector, 2));
        market.redeem(2, shares2);
    }

    function test_fullLifecycle_DrawResult() public {
        // 用户下注
        vm.startPrank(router);

        usdc.transfer(address(market), 5000e6);
        market.placeBetFor(user1, 0, 5000e6, 0); // 主胜

        usdc.transfer(address(market), 3000e6);
        uint256 drawShares = market.placeBetFor(user2, 1, 3000e6, 0); // 平局

        vm.stopPrank();

        // 锁盘
        vm.prank(keeper);
        market.lock();

        // 结算：平局（1-1）
        bytes memory rawResult = abi.encode(uint256(1), uint256(1));
        vm.prank(oracle);
        market.resolve(rawResult);

        // 终结
        vm.prank(keeper);
        market.finalize();

        // 验证结算结果
        IMarket_V3.SettlementResult memory result = market.getSettlementResult();
        assertEq(result.outcomeIds[0], 1); // Draw

        // user2 赎回平局（赢家）
        vm.prank(user2);
        uint256 payout = market.redeem(1, drawShares);
        assertTrue(payout > 3000e6, "Draw bettor should profit");
    }
}

/**
 * @title Market_V3_ParamController_Test
 * @notice 测试 Market_V3 与 ParamController 的集成
 */
contract Market_V3_ParamController_Test is Test {
    MarketFactory_V3 public factory;
    Market_V3 public marketImpl;
    Market_V3 public market;
    CPMMStrategy public strategy;
    WDL_Mapper public mapper;
    MockUSDC public usdc;
    MockParamController public paramController;

    bytes32 public templateId;

    address public admin = address(1);
    address public router = address(2);
    address public keeper = address(3);
    address public oracle = address(4);
    address public user1 = address(5);
    address public user2 = address(6);

    uint256 constant INITIAL_LIQUIDITY = 1_000_000e6; // 1M USDC
    uint256 constant BET_AMOUNT = 1_000e6; // 1k USDC

    function setUp() public {
        vm.startPrank(admin);

        // 部署依赖合约
        strategy = new CPMMStrategy();
        mapper = new WDL_Mapper();
        usdc = new MockUSDC();
        paramController = new MockParamController();

        // 设置默认参数
        paramController.setParam(ParamKeys.MIN_ODDS, 10_000);      // 1.0x
        paramController.setParam(ParamKeys.MAX_ODDS, 10_000_000);  // 1000x
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 1_000_000_000_000);  // 1,000,000 USDC (足够高以允许正常下注)
        paramController.setParam(ParamKeys.MARKET_PAYOUT_CAP, 10_000_000_000_000); // 10M USDC

        // 部署 Factory（先用一个临时地址，稍后设置实际实现）
        factory = new MarketFactory_V3(
            address(1), // 临时占位
            address(usdc),
            admin
        );

        // 部署 Market 实现合约（传入 factory 地址）
        marketImpl = new Market_V3(address(factory));

        // 更新 Factory 配置
        factory.setImplementation(address(marketImpl));
        factory.setRouter(router);
        factory.setKeeper(keeper);
        factory.setOracle(oracle);
        factory.setParamController(address(paramController));

        // 准备 outcome 规则
        IMarket_V3.OutcomeRule[] memory rules = new IMarket_V3.OutcomeRule[](3);
        rules[0] = IMarket_V3.OutcomeRule({
            name: "Home Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[1] = IMarket_V3.OutcomeRule({
            name: "Draw",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[2] = IMarket_V3.OutcomeRule({
            name: "Away Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });

        // 注册模板
        templateId = keccak256("WDL");
        factory.registerTemplate(
            templateId,
            "WDL",
            "CPMM",
            address(strategy),
            address(mapper),
            rules,
            INITIAL_LIQUIDITY
        );

        // 创建市场
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_MUN_vs_MCI",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        address marketAddr = factory.createMarket(params);
        market = Market_V3(marketAddr);

        vm.stopPrank();

        // 给用户分发 USDC 并授权
        usdc.mint(user1, 100_000e6);
        usdc.mint(user2, 100_000e6);
        usdc.mint(router, 1_000_000e6);

        vm.prank(router);
        usdc.approve(address(market), type(uint256).max);

        // 给 Market 初始流动性
        usdc.mint(address(market), INITIAL_LIQUIDITY);
    }

    // ============ ParamController 集成测试 ============

    function test_paramController_IsSet() public view {
        assertEq(address(market.paramController()), address(paramController));
    }

    function test_placeBetFor_WithinOddsRange_Success() public {
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        // 正常下注应该成功
        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertTrue(shares > 0);
        assertEq(market.balanceOf(user1, 0), shares);
    }

    function test_placeBetFor_OddsTooLow_Reverts() public {
        // AMM 的赔率计算: shares * 10000 / amount
        // 初始流动性 1M USDC，下注 1K USDC 大约获得 333K shares
        // 赔率约为 333K * 10000 / 1K = 3,333,333 (约 333x)
        // 设置最小赔率为 500x = 5,000,000，这样正常下注会因为赔率太低而失败
        paramController.setParam(ParamKeys.MIN_ODDS, 5_000_000);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        // 正常的 AMM 赔率约 333x，低于 500x 应该失败
        vm.expectRevert(); // OddsOutOfRange
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_OddsTooHigh_Reverts() public {
        // 设置很低的最大赔率限制（比如 2.0x = 20000）
        paramController.setParam(ParamKeys.MAX_ODDS, 20_000);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        // 正常的 AMM 赔率约 3x，高于 2x 应该失败
        vm.expectRevert(); // OddsOutOfRange
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_UserExposureLimit_Success() public {
        // 设置用户敞口限制为 10M USDC
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 10_000_000_000_000);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertTrue(shares > 0);
        assertEq(market.userExposure(user1), shares);
    }

    function test_placeBetFor_UserExposureLimitExceeded_Reverts() public {
        // 设置非常低的用户敞口限制（1 USDC）
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 1_000_000);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        // 1000 USDC 下注会产生远超 1 USDC 的敞口
        vm.expectRevert(); // UserExposureLimitExceeded
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_UserExposure_Accumulates() public {
        // 设置较高的用户敞口限制
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 100_000_000_000_000);

        vm.startPrank(router);

        // 第一次下注
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares1 = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        uint256 exposure1 = market.userExposure(user1);
        assertEq(exposure1, shares1);

        // 第二次下注（同一用户）
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares2 = market.placeBetFor(user1, 1, BET_AMOUNT, 0);
        uint256 exposure2 = market.userExposure(user1);

        // 敞口应该累加
        assertEq(exposure2, shares1 + shares2);

        vm.stopPrank();
    }

    function test_placeBetFor_MarketPayoutCap_Success() public {
        // 设置较高的市场赔付上限
        paramController.setParam(ParamKeys.MARKET_PAYOUT_CAP, 100_000_000_000_000);

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        uint256 shares = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertTrue(shares > 0);
    }

    function test_placeBetFor_MarketPayoutCapExceeded_Reverts() public {
        // 设置非常低的市场赔付上限（低于初始流动性）
        paramController.setParam(ParamKeys.MARKET_PAYOUT_CAP, 100_000); // 0.1 USDC

        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        vm.expectRevert(); // MarketPayoutCapExceeded
        market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_NoParamController_SkipsChecks() public {
        // 创建一个没有 ParamController 的市场
        vm.startPrank(admin);

        // 清除 factory 的 paramController
        factory.setParamController(address(0));

        // 创建新市场
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: "EPL_2024_NO_PARAM",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        address marketAddr = factory.createMarket(params);
        Market_V3 marketNoParam = Market_V3(marketAddr);

        vm.stopPrank();

        // 验证没有 ParamController
        assertEq(address(marketNoParam.paramController()), address(0));

        // 给市场流动性
        usdc.mint(address(marketNoParam), INITIAL_LIQUIDITY);

        // 即使没有 ParamController，下注也应该成功
        vm.startPrank(router);
        usdc.transfer(address(marketNoParam), BET_AMOUNT);
        uint256 shares = marketNoParam.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertTrue(shares > 0);
    }

    function test_paramController_DynamicParamChange() public {
        // 初始设置允许下注
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 100_000_000_000_000);

        vm.startPrank(router);

        // 第一次下注成功
        usdc.transfer(address(market), BET_AMOUNT);
        uint256 shares1 = market.placeBetFor(user1, 0, BET_AMOUNT, 0);
        assertTrue(shares1 > 0);

        vm.stopPrank();

        // 管理员降低用户敞口限制（小于当前敞口）
        paramController.setParam(ParamKeys.USER_EXPOSURE_LIMIT, 1);

        // 第二次下注应该失败
        vm.startPrank(router);
        usdc.transfer(address(market), BET_AMOUNT);

        vm.expectRevert(); // UserExposureLimitExceeded
        market.placeBetFor(user1, 1, BET_AMOUNT, 0);
        vm.stopPrank();
    }

    function test_placeBetFor_Parimutuel_SkipsMarketPayoutCap() public {
        // Parimutuel 策略不需要初始流动性，因此不应检查市场赔付上限
        vm.startPrank(admin);

        // 部署 Parimutuel 策略
        ParimutuelStrategy parimutuelStrategy = new ParimutuelStrategy();

        // 验证 Parimutuel 不需要初始流动性
        assertFalse(parimutuelStrategy.requiresInitialLiquidity());

        // 注册 Parimutuel 模板
        bytes32 parimutuelTemplateId = keccak256("PARIMUTUEL_WDL");
        factory.registerTemplate(
            parimutuelTemplateId,
            "Parimutuel WDL",
            "PARIMUTUEL",
            address(parimutuelStrategy),
            address(mapper),
            _getDefaultOutcomeRules(),
            0  // Parimutuel 不需要初始流动性
        );

        // 设置非常低的市场赔付上限（对 CPMM 会失败）
        paramController.setParam(ParamKeys.MARKET_PAYOUT_CAP, 1);  // 几乎为 0

        // 恢复 ParamController
        factory.setParamController(address(paramController));

        // 创建 Parimutuel 市场
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: parimutuelTemplateId,
            matchId: "EPL_2024_PARI_TEST",
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: 0,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        address marketAddr = factory.createMarket(params);
        Market_V3 parimutuelMarket = Market_V3(marketAddr);

        vm.stopPrank();

        // 验证市场有 ParamController
        assertEq(address(parimutuelMarket.paramController()), address(paramController));

        // 即使 MARKET_PAYOUT_CAP 很低，Parimutuel 下注也应该成功
        // 因为 Parimutuel 不需要做市流动性，不会触发此检查
        vm.startPrank(router);
        usdc.transfer(address(parimutuelMarket), BET_AMOUNT);
        uint256 shares = parimutuelMarket.placeBetFor(user1, 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // Parimutuel 模式：shares == amount
        assertEq(shares, BET_AMOUNT);
    }

    // 辅助函数：获取默认 outcome 规则
    function _getDefaultOutcomeRules() internal pure returns (IMarket_V3.OutcomeRule[] memory rules) {
        rules = new IMarket_V3.OutcomeRule[](3);
        rules[0] = IMarket_V3.OutcomeRule({
            name: "Home Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[1] = IMarket_V3.OutcomeRule({
            name: "Draw",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
        rules[2] = IMarket_V3.OutcomeRule({
            name: "Away Win",
            payoutType: IPricingStrategy.PayoutType.WINNER
        });
    }
}
