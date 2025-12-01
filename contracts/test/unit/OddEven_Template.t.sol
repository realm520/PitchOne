// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/OddEven_Template.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../../test/mocks/MockERC20.sol";
import "../../src/oracle/MockOracle.sol";

contract OddEven_TemplateTest is Test {
    OddEven_Template public market;
    SimpleCPMM public cpmm;
    MockERC20 public usdc;
    MockOracle public oracle;

    address public owner = address(this);
    address public feeRecipient = address(0x123);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    uint256 constant FEE_RATE = 0; // 0% - 避免需要 FeeRouter 复杂配置
    uint256 constant DISPUTE_PERIOD = 2 hours;
    string constant URI = "https://api.test.com/markets/{id}";

    // Outcome IDs
    uint256 constant ODD = 0;
    uint256 constant EVEN = 1;

    event MarketCreated(
        string indexed matchId,
        string homeTeam,
        string awayTeam,
        uint256 kickoffTime,
        address pricingEngine
    );

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        cpmm = new SimpleCPMM(100_000 * 10**6);
        oracle = new MockOracle(address(this));

        market = new OddEven_Template();
        market.initialize(
            "EPL_2024_MUN_vs_MCI",
            "Manchester United",
            "Manchester City",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );

        // 给用户铸造 USDC
        usdc.mint(user1, 10000e6);
        usdc.mint(user2, 10000e6);
    }

    function approveMarket(address user, uint256 amount) internal {
        vm.prank(user);
        usdc.approve(address(market), amount);
    }

    // ============ 构造函数测试 ============

    function test_Constructor_Success() public {
        assertEq(market.outcomeCount(), 2);
        assertEq(market.matchId(), "EPL_2024_MUN_vs_MCI");
        assertEq(market.homeTeam(), "Manchester United");
        assertEq(market.awayTeam(), "Manchester City");
        assertEq(market.kickoffTime(), block.timestamp + 1 days);
        assertEq(address(market.pricingEngine()), address(cpmm));
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Open));
    }

    function test_Constructor_EmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit MarketCreated(
            "EPL_2024_TEST",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(cpmm)
        );

        OddEven_Template newMarket = new OddEven_Template();
        newMarket.initialize(
            "EPL_2024_TEST",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidMatchId() public {
        OddEven_Template newMarket = new OddEven_Template();

        vm.expectRevert("OddEven: Invalid match ID");
        newMarket.initialize(
            "",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidHomeTeam() public {
        OddEven_Template newMarket = new OddEven_Template();

        vm.expectRevert("OddEven: Invalid home team");
        newMarket.initialize(
            "TEST",
            "",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidAwayTeam() public {
        OddEven_Template newMarket = new OddEven_Template();

        vm.expectRevert("OddEven: Invalid away team");
        newMarket.initialize(
            "TEST",
            "Team A",
            "",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_KickoffTimeInPast() public {
        OddEven_Template newMarket = new OddEven_Template();

        vm.expectRevert("OddEven: Kickoff time in past");
        newMarket.initialize(
            "TEST",
            "Team A",
            "Team B",
            block.timestamp - 1,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(cpmm),
            URI,
            address(this)
        );
    }

    function testRevert_Constructor_InvalidPricingEngine() public {
        OddEven_Template newMarket = new OddEven_Template();

        vm.expectRevert("OddEven: Invalid pricing engine");
        newMarket.initialize(
            "TEST",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            feeRecipient,
            FEE_RATE,
            DISPUTE_PERIOD,
            address(0),
            URI,
            address(this)
        );
    }

    // ============ 下注测试 ============

    function test_PlaceBet_Odd() public {
        uint256 betAmount = 1000e6;
        approveMarket(user1, betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(ODD, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, ODD), shares);
    }

    function test_PlaceBet_Even() public {
        uint256 betAmount = 1000e6;
        approveMarket(user1, betAmount);

        vm.prank(user1);
        uint256 shares = market.placeBet(EVEN, betAmount);

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, EVEN), shares);
    }

    function test_PlaceBet_MultipleBets() public {
        // User1 下注 Odd
        approveMarket(user1, 1000e6);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(ODD, 1000e6);

        // User2 下注 Even
        approveMarket(user2, 1500e6);
        vm.prank(user2);
        uint256 shares2 = market.placeBet(EVEN, 1500e6);

        assertGt(shares1, 0);
        assertGt(shares2, 0);
        assertEq(market.balanceOf(user1, ODD), shares1);
        assertEq(market.balanceOf(user2, EVEN), shares2);
    }

    function testRevert_PlaceBet_InvalidOutcome() public {
        uint256 betAmount = 1000e6;
        approveMarket(user1, betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid outcome");
        market.placeBet(2, betAmount); // outcome 2 不存在
    }

    function testRevert_PlaceBet_ZeroAmount() public {
        vm.expectRevert("MarketBase: Zero amount");
        vm.prank(user1);
        market.placeBet(ODD, 0);
    }

    function testRevert_PlaceBet_AfterLock() public {
        market.lock();

        uint256 betAmount = 1000e6;
        approveMarket(user1, betAmount);

        vm.prank(user1);
        vm.expectRevert("MarketBase: Invalid status");
        market.placeBet(ODD, betAmount);
    }

    // ============ 价格查询测试 ============

    function test_GetCurrentPrice_InitialState() public {
        uint256 oddPrice = market.getCurrentPrice(ODD);
        uint256 evenPrice = market.getCurrentPrice(EVEN);

        // 初始状态应该接近 50/50
        assertApproxEqAbs(oddPrice, 5000, 100); // 允许1%误差
        assertApproxEqAbs(evenPrice, 5000, 100);
    }

    function test_GetAllPrices() public {
        uint256[2] memory prices = market.getAllPrices();

        // 初始状态应该接近 50/50
        assertApproxEqAbs(prices[0], 5000, 100);
        assertApproxEqAbs(prices[1], 5000, 100);
    }

    function testRevert_GetCurrentPrice_InvalidOutcome() public {
        vm.expectRevert("OddEven: Invalid outcome");
        market.getCurrentPrice(2);
    }

    // ============ 市场信息测试 ============

    function test_GetMarketInfo() public {
        (
            string memory _matchId,
            string memory _homeTeam,
            string memory _awayTeam,
            uint256 _kickoffTime,
            IMarket.MarketStatus _status
        ) = market.getMarketInfo();

        assertEq(_matchId, "EPL_2024_MUN_vs_MCI");
        assertEq(_homeTeam, "Manchester United");
        assertEq(_awayTeam, "Manchester City");
        assertEq(_kickoffTime, block.timestamp + 1 days);
        assertEq(uint256(_status), uint256(IMarket.MarketStatus.Open));
    }

    // ============ 锁盘测试 ============

    function test_Lock_ManualByOwner() public {
        market.lock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
    }

    function test_AutoLock_BeforeKickoff() public {
        vm.warp(block.timestamp + 1 days - 4 minutes);
        market.autoLock();
        assertEq(uint256(market.status()), uint256(IMarket.MarketStatus.Locked));
    }

    function test_ShouldLock_ReturnsTrue() public {
        vm.warp(block.timestamp + 1 days - 4 minutes);
        assertTrue(market.shouldLock());
    }

    function test_ShouldLock_ReturnsFalse() public {
        assertFalse(market.shouldLock());
    }

    function testRevert_AutoLock_TooEarly() public {
        vm.expectRevert("OddEven: Too early to lock");
        market.autoLock();
    }

    function testRevert_AutoLock_AlreadyLocked() public {
        vm.warp(block.timestamp + 1 days - 4 minutes);
        market.autoLock();

        vm.expectRevert("OddEven: Market not open");
        market.autoLock();
    }

    function testRevert_Lock_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        market.lock();
    }

    function testRevert_Lock_AlreadyLocked() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid status");
        market.lock();
    }

    // ============ 结算测试 ============

    function test_Resolve_Odd() public {
        market.lock();
        market.resolve(ODD);
        assertEq(market.winningOutcome(), ODD);
    }

    function test_Resolve_Even() public {
        market.lock();
        market.resolve(EVEN);
        assertEq(market.winningOutcome(), EVEN);
    }

    function testRevert_Resolve_InvalidOutcome() public {
        market.lock();

        vm.expectRevert("MarketBase: Invalid outcome");
        market.resolve(2); // outcome 2 不存在
    }

    // ============ 兑付测试 ============

    function test_Redeem_WinningOutcome_Odd() public {
        // 下注
        approveMarket(user1, 1000e6);
        vm.prank(user1);
        uint256 shares = market.placeBet(ODD, 1000e6);

        // 锁盘、结算
        market.lock();
        market.resolve(ODD);

        // 争议期结束
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // 兑付
        vm.prank(user1);
        uint256 payout = market.redeem(ODD, shares);

        assertGt(payout, 0);
        assertEq(market.balanceOf(user1, ODD), 0);
    }

    function testRevert_Redeem_LosingOutcome() public {
        // 下注 Odd
        approveMarket(user1, 1000e6);
        vm.prank(user1);
        uint256 shares = market.placeBet(ODD, 1000e6);

        // 锁盘、结算为 Even
        market.lock();
        market.resolve(EVEN);

        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // 尝试兑付 Odd（输掉的一方）
        vm.prank(user1);
        vm.expectRevert("MarketBase: Not winning outcome");
        market.redeem(ODD, shares);
    }

    // ============ 完整生命周期测试 ============

    function test_FullLifecycle_OddWins() public {
        // 1. 下注
        approveMarket(user1, 1000e6);
        vm.prank(user1);
        uint256 shares1 = market.placeBet(ODD, 1000e6);

        approveMarket(user2, 800e6);
        vm.prank(user2);
        market.placeBet(EVEN, 800e6);

        // 2. 锁盘
        vm.warp(block.timestamp + 1 days);
        market.lock();

        // 3. 结算（Odd 赢）
        market.resolve(ODD);

        // 4. 完成
        vm.warp(block.timestamp + DISPUTE_PERIOD + 1);
        market.finalize();

        // 5. 兑付
        vm.prank(user1);
        uint256 payout = market.redeem(ODD, shares1);

        assertGt(payout, 980e6); // 应该大于原始投入（扣除2%手续费）
    }

    // ============ 管理函数测试 ============

    function test_SetPricingEngine() public {
        SimpleCPMM newCpmm = new SimpleCPMM(100_000 * 10**6);

        market.setPricingEngine(address(newCpmm));
        assertEq(address(market.pricingEngine()), address(newCpmm));
    }

    function testRevert_SetPricingEngine_AfterLock() public {
        market.lock();

        SimpleCPMM newCpmm = new SimpleCPMM(100_000 * 10**6);

        vm.expectRevert("MarketBase: Invalid status");
        market.setPricingEngine(address(newCpmm));
    }

    function testRevert_SetPricingEngine_InvalidAddress() public {
        vm.expectRevert("OddEven: Invalid pricing engine");
        market.setPricingEngine(address(0));
    }
}
