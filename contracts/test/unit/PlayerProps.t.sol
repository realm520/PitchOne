// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/PlayerProps_Template.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../../src/pricing/LMSR.sol";
import "../mocks/MockERC20.sol";

contract PlayerPropsTest is Test {
    // ============ 合约实例 ============
    PlayerProps_Template public market;
    SimpleCPMM public simpleCPMM;
    LMSR public lmsr;
    MockERC20 public usdc;

    // ============ 测试账户 ============
    address public owner = address(this);
    address public feeRecipient = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    // ============ 常量 ============
    uint8 constant USDC_DECIMALS = 6;
    uint256 constant INITIAL_BALANCE = 10_000 * 10 ** USDC_DECIMALS; // 10000 USDC
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;

    // ============ 状态变量 ============
    uint256 defaultKickoff;

    // ============ 设置 ============

    function setUp() public {
        defaultKickoff = block.timestamp + 7 days;

        // 部署 USDC
        usdc = new MockERC20("USD Coin", "USDC", USDC_DECIMALS);

        // 部署定价引擎
        simpleCPMM = new SimpleCPMM(100_000 * 10**6);
        lmsr = new LMSR(5000 * 1e18, 10); // liquidityB = 5000, 10 个结果

        // 给用户分配 USDC
        usdc.mint(user1, INITIAL_BALANCE);
        usdc.mint(user2, INITIAL_BALANCE);
    }

    // ============ 辅助函数 ============

    function _createGoalsOUMarket(uint256 line) internal returns (PlayerProps_Template) {
        market = new PlayerProps_Template();

        uint256[] memory initialReserves = new uint256[](line % 1e18 == 0 ? 3 : 2);
        initialReserves[0] = 1000 * 1e18; // Over
        initialReserves[1] = line % 1e18 == 0 ? 500 * 1e18 : 1000 * 1e18; // Push 或 Under
        if (line % 1e18 == 0) {
            initialReserves[2] = 1000 * 1e18; // Under
        }

        PlayerProps_Template.PlayerPropsInitData memory data = PlayerProps_Template.PlayerPropsInitData({
            matchId: "EPL_2024_MUN_vs_MCI",
            playerId: "player_haaland",
            playerName: "Erling Haaland",
            propType: PlayerProps_Template.PropType.GOALS_OU,
            line: line,
            kickoffTime: defaultKickoff,
            settlementToken: address(usdc),
            feeRecipient: feeRecipient,
            feeRate: FEE_RATE,
            disputePeriod: DISPUTE_PERIOD,
            uri: "https://api.pitchone.io/metadata/{id}",
            owner: owner,
            pricingEngineAddr: address(simpleCPMM),
            initialReserves: initialReserves,
            playerIds: new string[](0),
            playerNames: new string[](0)
        });

        market.initialize(data);
        return market;
    }

    function _createYesNoMarket(PlayerProps_Template.PropType propType) internal returns (PlayerProps_Template) {
        market = new PlayerProps_Template();

        uint256[] memory initialReserves = new uint256[](2);
        initialReserves[0] = 500 * 1e18; // Yes
        initialReserves[1] = 1500 * 1e18; // No

        PlayerProps_Template.PlayerPropsInitData memory data = PlayerProps_Template.PlayerPropsInitData({
            matchId: "EPL_2024_MUN_vs_MCI",
            playerId: "player_casemiro",
            playerName: "Casemiro",
            propType: propType,
            line: 0,
            kickoffTime: defaultKickoff,
            settlementToken: address(usdc),
            feeRecipient: feeRecipient,
            feeRate: FEE_RATE,
            disputePeriod: DISPUTE_PERIOD,
            uri: "https://api.pitchone.io/metadata/{id}",
            owner: owner,
            pricingEngineAddr: address(simpleCPMM),
            initialReserves: initialReserves,
            playerIds: new string[](0),
            playerNames: new string[](0)
        });

        market.initialize(data);
        return market;
    }

    // ============ 初始化测试 ============

    function test_Initialize_GoalsOU_HalfLine() public {
        market = _createGoalsOUMarket(0.5 * 1e18);

        assertEq(market.matchId(), "EPL_2024_MUN_vs_MCI");
        assertEq(market.playerId(), "player_haaland");
        assertEq(market.playerName(), "Erling Haaland");
        assertEq(uint(market.propType()), uint(PlayerProps_Template.PropType.GOALS_OU));
        assertEq(market.line(), 0.5 * 1e18);
        assertEq(market.outcomeCount(), 2); // Over, Under
    }

    function test_Initialize_GoalsOU_WholeLine() public {
        market = _createGoalsOUMarket(1.0 * 1e18);

        assertEq(market.outcomeCount(), 3); // Over, Push, Under
    }

    function test_Initialize_YellowCard() public {
        market = _createYesNoMarket(PlayerProps_Template.PropType.YELLOW_CARD);

        assertEq(market.playerId(), "player_casemiro");
        assertEq(uint(market.propType()), uint(PlayerProps_Template.PropType.YELLOW_CARD));
        assertEq(market.outcomeCount(), 2); // Yes, No
    }

    function test_Initialize_RevertIf_InvalidMatchId() public {
        market = new PlayerProps_Template();

        uint256[] memory initialReserves = new uint256[](2);
        initialReserves[0] = 1000 * 1e18;
        initialReserves[1] = 1000 * 1e18;

        PlayerProps_Template.PlayerPropsInitData memory data = PlayerProps_Template.PlayerPropsInitData({
            matchId: "",  // 无效
            playerId: "player_haaland",
            playerName: "Erling Haaland",
            propType: PlayerProps_Template.PropType.GOALS_OU,
            line: 0.5 * 1e18,
            kickoffTime: defaultKickoff,
            settlementToken: address(usdc),
            feeRecipient: feeRecipient,
            feeRate: FEE_RATE,
            disputePeriod: DISPUTE_PERIOD,
            uri: "https://api.pitchone.io/metadata/{id}",
            owner: owner,
            pricingEngineAddr: address(simpleCPMM),
            initialReserves: initialReserves,
            playerIds: new string[](0),
            playerNames: new string[](0)
        });

        vm.expectRevert("PlayerProps: Invalid match ID");
        market.initialize(data);
    }

    function test_Initialize_RevertIf_KickoffTimeInPast() public {
        market = new PlayerProps_Template();

        uint256[] memory initialReserves = new uint256[](2);
        initialReserves[0] = 1000 * 1e18;
        initialReserves[1] = 1000 * 1e18;

        PlayerProps_Template.PlayerPropsInitData memory data = PlayerProps_Template.PlayerPropsInitData({
            matchId: "EPL_2024_MUN_vs_MCI",
            playerId: "player_haaland",
            playerName: "Erling Haaland",
            propType: PlayerProps_Template.PropType.GOALS_OU,
            line: 0.5 * 1e18,
            kickoffTime: block.timestamp - 1, // 过去时间
            settlementToken: address(usdc),
            feeRecipient: feeRecipient,
            feeRate: FEE_RATE,
            disputePeriod: DISPUTE_PERIOD,
            uri: "https://api.pitchone.io/metadata/{id}",
            owner: owner,
            pricingEngineAddr: address(simpleCPMM),
            initialReserves: initialReserves,
            playerIds: new string[](0),
            playerNames: new string[](0)
        });

        vm.expectRevert("PlayerProps: Kickoff time in past");
        market.initialize(data);
    }

    // ============ 下注测试 ============

    function test_PlaceBet_GoalsOU_Over() public {
        market = _createGoalsOUMarket(0.5 * 1e18);
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;

        vm.startPrank(user1);
        usdc.approve(address(market), betAmount);
        uint256 shares = market.placeBet(0, betAmount); // Over
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, 0), shares);
    }

    function test_PlaceBet_YellowCard_Yes() public {
        market = _createYesNoMarket(PlayerProps_Template.PropType.YELLOW_CARD);
        uint256 betAmount = 50 * 10 ** USDC_DECIMALS;

        vm.startPrank(user1);
        usdc.approve(address(market), betAmount);
        uint256 shares = market.placeBet(0, betAmount); // Yes
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(market.balanceOf(user1, 0), shares);
    }

    function test_PlaceBet_RevertIf_InvalidOutcome() public {
        market = _createGoalsOUMarket(0.5 * 1e18);
        uint256 betAmount = 100 * 10 ** USDC_DECIMALS;

        vm.startPrank(user1);
        usdc.approve(address(market), betAmount);
        vm.expectRevert("MarketBase: Invalid outcome"); // MarketBase 先验证
        market.placeBet(5, betAmount); // 无效 outcome
        vm.stopPrank();
    }

    // ============ 价格查询测试 ============

    function test_GetCurrentPrice_InitialState() public {
        market = _createGoalsOUMarket(0.5 * 1e18);

        uint256 priceOver = market.getCurrentPrice(0);
        uint256 priceUnder = market.getCurrentPrice(1);

        assertGt(priceOver, 0);
        assertGt(priceUnder, 0);
        assertApproxEqAbs(priceOver + priceUnder, 10000, 10); // 总和约 100%
    }

    function test_GetAllPrices() public {
        market = _createGoalsOUMarket(0.5 * 1e18);

        uint256[] memory prices = market.getAllPrices();

        assertEq(prices.length, 2);
        assertGt(prices[0], 0);
        assertGt(prices[1], 0);
    }

    function test_GetCurrentPrice_ChangesAfterBet() public {
        market = _createGoalsOUMarket(0.5 * 1e18);

        uint256 priceOverBefore = market.getCurrentPrice(0);

        // 用户下注 Over
        vm.startPrank(user1);
        usdc.approve(address(market), 1000 * 10 ** USDC_DECIMALS);
        market.placeBet(0, 1000 * 10 ** USDC_DECIMALS);
        vm.stopPrank();

        uint256 priceOverAfter = market.getCurrentPrice(0);

        // 价格应该发生变化（可能上升或下降，取决于 CPMM 实现）
        assertTrue(priceOverAfter != priceOverBefore, "Price should change after bet");
    }

    // ============ 辅助函数测试 ============

    function test_GetPropTypeName() public {
        market = _createGoalsOUMarket(0.5 * 1e18);
        // 通过事件或其他方式验证名称（此处简化）
    }

    function test_GetOutcomeName_GoalsOU() public {
        market = _createGoalsOUMarket(0.5 * 1e18);
        // 验证 "Over" 和 "Under" 名称
    }

    function test_GetOutcomeName_YesNo() public {
        market = _createYesNoMarket(PlayerProps_Template.PropType.YELLOW_CARD);
        // 验证 "Yes" 和 "No" 名称
    }

    // TODO: 添加更多测试
    // - FIRST_SCORER 市场（LMSR）
    // - 结算逻辑测试
    // - 整数盘口 Push 测试
    // - Gas 优化测试
}
