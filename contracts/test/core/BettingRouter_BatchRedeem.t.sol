// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BettingRouter_V3} from "../../src/core/BettingRouter_V3.sol";
import {IBettingRouter_V3} from "../../src/interfaces/IBettingRouter_V3.sol";
import {Market_V3} from "../../src/core/Market_V3.sol";
import {MarketFactory_V3} from "../../src/core/MarketFactory_V3.sol";
import {IMarket_V3} from "../../src/interfaces/IMarket_V3.sol";
import {IPricingStrategy} from "../../src/interfaces/IPricingStrategy.sol";
import {CPMMStrategy} from "../../src/pricing/CPMMStrategy.sol";
import {WDL_Mapper} from "../../src/mappers/WDL_Mapper.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title BettingRouter_BatchRedeem_Test
 * @notice 测试 BettingRouter_V3 的批量领取和退款功能
 */
contract BettingRouter_BatchRedeem_Test is Test {
    BettingRouter_V3 public router;
    MarketFactory_V3 public factory;
    Market_V3 public marketImpl;
    Market_V3 public market1;
    Market_V3 public market2;
    CPMMStrategy public strategy;
    WDL_Mapper public mapper;

    MockERC20 public usdc;

    address public admin = address(1);
    address public user1 = address(2);
    address public oracle = address(3);
    address public keeper = address(4);
    address public feeRecipient = address(5);

    bytes32 public templateId;

    uint256 constant INITIAL_LIQUIDITY = 1000000e6; // 1,000,000 USDC
    uint256 constant BET_AMOUNT = 100e6; // 100 USDC

    function setUp() public {
        vm.startPrank(admin);

        // 部署代币
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // 部署定价策略和映射器
        strategy = new CPMMStrategy();
        mapper = new WDL_Mapper();

        // 部署 Factory
        factory = new MarketFactory_V3(
            address(1), // 临时占位
            address(usdc),
            admin
        );

        // 部署 Market 实现
        marketImpl = new Market_V3(address(factory));
        factory.setImplementation(address(marketImpl));

        // 部署 Router (factory, defaultFeeRateBps, defaultFeeRecipient)
        router = new BettingRouter_V3(address(factory), 200, feeRecipient);

        // 设置 Router 支持的代币
        router.addToken(address(usdc), 200, feeRecipient, 1e6, 0); // 2% fee, min 1 USDC

        // 设置 Factory 配置
        factory.setRouter(address(router));
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
        templateId = keccak256("WDL_BATCH_TEST");
        factory.registerTemplate(
            templateId,
            "WDL_BATCH",
            "CPMM",
            address(strategy),
            address(mapper),
            rules,
            INITIAL_LIQUIDITY
        );

        // 创建两个市场
        market1 = _createMarket("MATCH_001");
        market2 = _createMarket("MATCH_002");

        vm.stopPrank();

        // 给用户 mint 代币
        usdc.mint(user1, 10000e6);
        usdc.mint(address(router), 1000000e6); // Router 需要 USDC
    }

    function _createMarket(string memory matchId) internal returns (Market_V3) {
        MarketFactory_V3.CreateMarketParams memory params = MarketFactory_V3.CreateMarketParams({
            templateId: templateId,
            matchId: matchId,
            kickoffTime: block.timestamp + 1 days,
            mapperInitData: "",
            initialLiquidity: INITIAL_LIQUIDITY,
            outcomeRules: new IMarket_V3.OutcomeRule[](0)
        });

        address marketAddr = factory.createMarket(params);
        Market_V3 market = Market_V3(marketAddr);

        // 转入初始流动性
        usdc.mint(address(market), INITIAL_LIQUIDITY);

        return market;
    }

    // ============ redeemFor 测试 ============

    function test_redeemFor_Success() public {
        // 1. 用户下注 (BettingRouter_V3.placeBet 需要 4 个参数)
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        vm.stopPrank();

        assertGt(shares, 0, "Should receive shares");

        // 2. 锁盘
        vm.warp(block.timestamp + 1 days);
        vm.prank(keeper);
        market1.lock();

        // 3. 结算（outcome 0 获胜）
        // rawResult: homeScore=1, awayScore=0 -> WDL_Mapper 映射到 outcome 0
        bytes memory rawResult = abi.encode(uint256(1), uint256(0));

        vm.prank(oracle);
        market1.resolve(rawResult);

        // 4. 终结市场
        vm.prank(keeper);
        market1.finalize(10000); // 100% scale

        // 5. 用户授权 Router
        vm.prank(user1);
        market1.setApprovalForAll(address(router), true);

        // 6. 使用 redeemFor 领取
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(address(router));
        uint256 payout = market1.redeemFor(user1, 0, shares);

        uint256 balanceAfter = usdc.balanceOf(user1);

        assertGt(payout, 0, "Should receive payout");
        assertEq(balanceAfter - balanceBefore, payout, "Balance should increase by payout");
        assertEq(market1.balanceOf(user1, 0), 0, "Shares should be burned");
    }

    function test_redeemFor_RevertWithoutApproval() public {
        // 1. 用户下注
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 2. 锁盘并结算
        vm.warp(block.timestamp + 1 days);
        vm.prank(keeper);
        market1.lock();

        bytes memory rawResult = abi.encode(uint256(1), uint256(0));

        vm.prank(oracle);
        market1.resolve(rawResult);

        vm.prank(keeper);
        market1.finalize(10000);

        // 3. 未授权的情况下尝试 redeemFor
        vm.prank(address(router));
        vm.expectRevert(abi.encodeWithSelector(Market_V3.NotAuthorized.selector, address(router)));
        market1.redeemFor(user1, 0, shares);
    }

    // ============ batchRedeem 测试 ============

    function test_batchRedeem_MultipleMarkets() public {
        // 1. 用户在两个市场下注
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT * 2);
        uint256 shares1 = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        uint256 shares2 = router.placeBet(address(market2), 1, BET_AMOUNT, 0);
        vm.stopPrank();

        // 2. 锁盘并结算两个市场
        vm.warp(block.timestamp + 1 days);

        vm.startPrank(keeper);
        market1.lock();
        market2.lock();
        vm.stopPrank();

        // Market1: outcome 0 获胜 (homeScore=1, awayScore=0)
        bytes memory rawResult1 = abi.encode(uint256(1), uint256(0));
        vm.prank(oracle);
        market1.resolve(rawResult1);

        // Market2: outcome 1 获胜 (homeScore=0, awayScore=0 = Draw)
        bytes memory rawResult2 = abi.encode(uint256(0), uint256(0));
        vm.prank(oracle);
        market2.resolve(rawResult2);

        vm.startPrank(keeper);
        market1.finalize(10000);
        market2.finalize(10000);
        vm.stopPrank();

        // 3. 用户授权 Router
        vm.startPrank(user1);
        market1.setApprovalForAll(address(router), true);
        market2.setApprovalForAll(address(router), true);

        // 4. 批量领取
        BettingRouter_V3.RedeemParams[] memory redeems = new BettingRouter_V3.RedeemParams[](2);
        redeems[0] = BettingRouter_V3.RedeemParams({
            market: address(market1),
            outcomeId: 0,
            shares: shares1
        });
        redeems[1] = BettingRouter_V3.RedeemParams({
            market: address(market2),
            outcomeId: 1,
            shares: shares2
        });

        uint256 balanceBefore = usdc.balanceOf(user1);
        uint256 totalPayout = router.batchRedeem(redeems);
        uint256 balanceAfter = usdc.balanceOf(user1);

        vm.stopPrank();

        assertGt(totalPayout, 0, "Should receive total payout");
        assertEq(balanceAfter - balanceBefore, totalPayout, "Balance should increase by total payout");
        assertEq(market1.balanceOf(user1, 0), 0, "Market1 shares should be burned");
        assertEq(market2.balanceOf(user1, 1), 0, "Market2 shares should be burned");
    }

    function test_batchRedeem_EmitsEvents() public {
        // 1. 设置：下注并结算
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        vm.prank(keeper);
        market1.lock();

        bytes memory rawResult = abi.encode(uint256(1), uint256(0));

        vm.prank(oracle);
        market1.resolve(rawResult);

        vm.prank(keeper);
        market1.finalize(10000);

        // 2. 批量领取并验证事件
        vm.startPrank(user1);
        market1.setApprovalForAll(address(router), true);

        BettingRouter_V3.RedeemParams[] memory redeems = new BettingRouter_V3.RedeemParams[](1);
        redeems[0] = BettingRouter_V3.RedeemParams({
            market: address(market1),
            outcomeId: 0,
            shares: shares
        });

        // 验证事件被触发
        vm.expectEmit(true, true, true, false);
        emit BettingRouter_V3.PayoutRedeemed(user1, address(market1), 0, shares, 0);

        vm.expectEmit(true, false, false, false);
        emit BettingRouter_V3.BatchRedeemed(user1, 1, 0);

        router.batchRedeem(redeems);
        vm.stopPrank();
    }

    // ============ refundFor 测试 ============

    function test_refundFor_Success() public {
        // 1. 用户下注
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT);
        uint256 shares = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        vm.stopPrank();

        // 2. 取消市场
        bytes32 OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
        vm.prank(admin);
        market1.grantRole(OPERATOR_ROLE, admin);

        vm.prank(admin);
        market1.cancel("Test cancellation");

        // 3. 用户授权 Router
        vm.prank(user1);
        market1.setApprovalForAll(address(router), true);

        // 4. 使用 refundFor 退款
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(address(router));
        uint256 refundAmount = market1.refundFor(user1, 0, shares);

        uint256 balanceAfter = usdc.balanceOf(user1);

        assertGt(refundAmount, 0, "Should receive refund");
        assertEq(balanceAfter - balanceBefore, refundAmount, "Balance should increase by refund");
        assertEq(market1.balanceOf(user1, 0), 0, "Shares should be burned");
    }

    // ============ batchRefund 测试 ============

    function test_batchRefund_MultipleMarkets() public {
        // 1. 用户在两个市场下注
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT * 2);
        uint256 shares1 = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        uint256 shares2 = router.placeBet(address(market2), 1, BET_AMOUNT, 0);
        vm.stopPrank();

        // 2. 取消两个市场
        bytes32 OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
        vm.startPrank(admin);
        market1.grantRole(OPERATOR_ROLE, admin);
        market2.grantRole(OPERATOR_ROLE, admin);
        market1.cancel("Test cancellation");
        market2.cancel("Test cancellation");
        vm.stopPrank();

        // 3. 用户授权并批量退款
        vm.startPrank(user1);
        market1.setApprovalForAll(address(router), true);
        market2.setApprovalForAll(address(router), true);

        BettingRouter_V3.RedeemParams[] memory refunds = new BettingRouter_V3.RedeemParams[](2);
        refunds[0] = BettingRouter_V3.RedeemParams({
            market: address(market1),
            outcomeId: 0,
            shares: shares1
        });
        refunds[1] = BettingRouter_V3.RedeemParams({
            market: address(market2),
            outcomeId: 1,
            shares: shares2
        });

        uint256 balanceBefore = usdc.balanceOf(user1);
        uint256 totalRefund = router.batchRefund(refunds);
        uint256 balanceAfter = usdc.balanceOf(user1);

        vm.stopPrank();

        assertGt(totalRefund, 0, "Should receive total refund");
        assertEq(balanceAfter - balanceBefore, totalRefund, "Balance should increase by total refund");
    }

    // ============ getRedeemablePositions 测试 ============

    function test_getRedeemablePositions() public {
        // 1. 用户下注
        vm.startPrank(user1);
        usdc.approve(address(router), BET_AMOUNT * 2);
        uint256 shares1 = router.placeBet(address(market1), 0, BET_AMOUNT, 0);
        uint256 shares2 = router.placeBet(address(market2), 1, BET_AMOUNT, 0);
        vm.stopPrank();

        // 2. 查询可领取头寸
        address[] memory markets = new address[](2);
        markets[0] = address(market1);
        markets[1] = address(market2);

        uint256[] memory outcomeIds = new uint256[](2);
        outcomeIds[0] = 0;
        outcomeIds[1] = 1;

        (uint256[] memory balances, IMarket_V3.MarketStatus[] memory statuses) = router.getRedeemablePositions(
            user1,
            markets,
            outcomeIds
        );

        assertEq(balances[0], shares1, "Should return correct shares for market1");
        assertEq(balances[1], shares2, "Should return correct shares for market2");
        assertEq(uint8(statuses[0]), uint8(IMarket_V3.MarketStatus.Open), "Market1 should be Open");
        assertEq(uint8(statuses[1]), uint8(IMarket_V3.MarketStatus.Open), "Market2 should be Open");
    }

    // ============ 边界情况测试 ============

    function test_batchRedeem_InvalidMarket() public {
        // 使用未注册的市场地址
        address fakeMarket = address(0x1234);

        BettingRouter_V3.RedeemParams[] memory redeems = new BettingRouter_V3.RedeemParams[](1);
        redeems[0] = BettingRouter_V3.RedeemParams({
            market: fakeMarket,
            outcomeId: 0,
            shares: 100
        });

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IBettingRouter_V3.InvalidMarket.selector, fakeMarket));
        router.batchRedeem(redeems);
    }

    function test_batchRedeem_EmptyArray() public {
        BettingRouter_V3.RedeemParams[] memory redeems = new BettingRouter_V3.RedeemParams[](0);

        vm.prank(user1);
        uint256 totalPayout = router.batchRedeem(redeems);

        assertEq(totalPayout, 0, "Empty batch should return 0");
    }

    function test_batchRefund_EmptyArray() public {
        BettingRouter_V3.RedeemParams[] memory refunds = new BettingRouter_V3.RedeemParams[](0);

        vm.prank(user1);
        uint256 totalRefund = router.batchRefund(refunds);

        assertEq(totalRefund, 0, "Empty batch should return 0");
    }
}
