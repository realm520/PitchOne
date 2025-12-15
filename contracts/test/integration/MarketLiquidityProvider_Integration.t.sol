// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/templates/WDL_Template_V2.sol";
import "../../src/liquidity/ERC4626LiquidityProvider.sol";
import "../../src/mocks/MockLiquidityProvider.sol";
import "../../src/pricing/SimpleCPMM.sol";
import "../../src/core/FeeRouter.sol";
import "../../src/core/ReferralRegistry.sol";
import "../mocks/MockERC20.sol";

/**
 * @title MarketLiquidityProvider_Integration (简化版)
 * @notice 测试 Market 与 LiquidityProvider 的核心集成
 * @dev 专注测试:
 *      1. LP 存入流动性到 Provider
 *      2. Market 从 Provider 借出流动性
 *      3. 用户下注流程
 *      4. Provider 状态验证
 *      5. LP 存取款操作
 *      6. 接口抽象验证
 *
 * 不包含: 市场结算、预言机集成(WDL_Template_V2 尚未实现)
 */
contract MarketLiquidityProvider_IntegrationTest is Test {
    // ============ 合约实例 ============
    MockERC20 public usdc;
    ERC4626LiquidityProvider public erc4626Provider;
    MockLiquidityProvider public mockProvider;
    SimpleCPMM public pricingEngine;
    FeeRouter public feeRouter;
    ReferralRegistry public referralRegistry;

    WDL_Template_V2 public market1; // 使用 ERC4626Provider
    WDL_Template_V2 public market2; // 使用 MockProvider

    // ============ 测试账户 ============
    address public owner;
    address public lpProvider1;
    address public lpProvider2;
    address public user1;
    address public user2;
    address public user3;
    address public treasury;

    // ============ 常量 ============
    uint256 constant VIRTUAL_RESERVE_INIT = 100_000 * 1e6; // 100k USDC - Virtual reserve for AMM mode
    uint256 constant INITIAL_LP_DEPOSIT = 1_000_000 * 1e6; // 1M USDC
    uint256 constant BET_AMOUNT_LARGE = 50_000 * 1e6; // 50k USDC
    uint256 constant BET_AMOUNT_MEDIUM = 20_000 * 1e6; // 20k USDC
    uint256 constant BET_AMOUNT_SMALL = 10_000 * 1e6; // 10k USDC
    uint256 constant FEE_RATE = 200; // 2%
    uint256 constant DISPUTE_PERIOD = 2 hours;

    // WDL Outcomes
    uint256 constant WIN = 0;
    uint256 constant DRAW = 1;
    uint256 constant LOSS = 2;

    // ============ 事件 ============
    event LiquidityBorrowed(address indexed market, uint256 amount, uint256 timestamp);
    event LiquidityRepaid(address indexed market, uint256 principal, uint256 revenue, uint256 timestamp);
    event BetPlaced(address indexed user, uint256 indexed outcomeId, uint256 amount, uint256 shares, uint256 fee);

    function setUp() public {
        // 1. 创建账户
        owner = address(this);
        lpProvider1 = makeAddr("lpProvider1");
        lpProvider2 = makeAddr("lpProvider2");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        treasury = makeAddr("treasury");

        // 2. 部署基础设施
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // 部署两种 LiquidityProvider
        erc4626Provider = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "PitchOne LP Token",
            "pLP"
        );
        mockProvider = new MockLiquidityProvider(IERC20(address(usdc)));

        // 部署定价引擎
        pricingEngine = new SimpleCPMM(100_000 * 10**6);

        // 部署 ReferralRegistry 和 FeeRouter
        referralRegistry = new ReferralRegistry(owner);
        FeeRouter.FeeRecipients memory recipients = FeeRouter.FeeRecipients({
            lpVault: address(erc4626Provider),
            promoPool: treasury,
            insuranceFund: treasury,
            treasury: treasury
        });
        feeRouter = new FeeRouter(recipients, address(referralRegistry));

        // Authorize FeeRouter to call ReferralRegistry (critical for accrueReferralReward)
        referralRegistry.setAuthorizedCaller(address(feeRouter), true);

        // 3. 初始化流动性
        _setupERC4626Provider();
        _setupMockProvider();

        // 4. 创建市场
        _createMarket1WithERC4626Provider();
        _createMarket2WithMockProvider();

        // 5. 给用户分配 USDC 并授权
        _setupUsers();

        // 6. 给测试合约（trustedRouter）铸造 USDC 并授权
        _setupTestContract();
    }

    function _setupERC4626Provider() internal {
        usdc.mint(lpProvider1, INITIAL_LP_DEPOSIT);
        vm.startPrank(lpProvider1);
        usdc.approve(address(erc4626Provider), INITIAL_LP_DEPOSIT);
        erc4626Provider.deposit(INITIAL_LP_DEPOSIT, lpProvider1);
        vm.stopPrank();

        assertEq(erc4626Provider.totalAssets(), INITIAL_LP_DEPOSIT);
        assertGt(erc4626Provider.balanceOf(lpProvider1), 0);
    }

    function _setupMockProvider() internal {
        usdc.mint(lpProvider2, INITIAL_LP_DEPOSIT);
        vm.startPrank(lpProvider2);
        usdc.approve(address(mockProvider), INITIAL_LP_DEPOSIT);
        mockProvider.deposit(INITIAL_LP_DEPOSIT);
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(mockProvider)), INITIAL_LP_DEPOSIT);
    }

    function _createMarket1WithERC4626Provider() internal {
        market1 = new WDL_Template_V2();
        market1.initialize(
            "EPL_2024_MUN_vs_MCI_1",
            "Manchester United",
            "Manchester City",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            address(erc4626Provider),
            "",
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        erc4626Provider.authorizeMarket(address(market1));

        // 设置 trustedRouter（必需，否则无法下注）
        market1.setTrustedRouter(address(this));
    }

    function _createMarket2WithMockProvider() internal {
        market2 = new WDL_Template_V2();
        market2.initialize(
            "EPL_2024_CHE_vs_ARS_2",
            "Chelsea",
            "Arsenal",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            address(mockProvider),
            "",
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        mockProvider.authorizeMarket(address(market2));

        // 设置 trustedRouter（必需，否则无法下注）
        market2.setTrustedRouter(address(this));
    }

    function _setupUsers() internal {
        address[3] memory users = [user1, user2, user3];
        for (uint256 i = 0; i < users.length; i++) {
            usdc.mint(users[i], 200_000 * 1e6);

            vm.startPrank(users[i]);
            usdc.approve(address(market1), type(uint256).max);
            usdc.approve(address(market2), type(uint256).max);
            vm.stopPrank();
        }
    }

    function _setupTestContract() internal {
        // 给测试合约（trustedRouter）铸造足够的 USDC
        // 用于执行 placeBetFor() 时转账
        usdc.mint(address(this), 10_000_000 * 1e6); // 10M USDC

        // 授权给所有市场
        usdc.approve(address(market1), type(uint256).max);
        usdc.approve(address(market2), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    测试 1: 基础下注与流动性借出
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试用户下注时 Market 从 ERC4626Provider 借出流动性
    function test_BasicBetting_WithERC4626Provider() public {
        // 记录初始状态
        uint256 providerTotalAssetsBefore = erc4626Provider.totalAssets();
        uint256 providerAvailableBefore = erc4626Provider.availableLiquidity();

        // User1 下注
        uint256 shares = market1.placeBetFor(user1, WIN, BET_AMOUNT_MEDIUM);

        // 验证下注成功
        assertGt(shares, 0, "Should receive shares");
        assertEq(market1.balanceOf(user1, WIN), shares, "Share balance mismatch");

        // 验证 Provider 状态
        // 注意: ERC4626Provider 在首次下注时会借出初始流动性
        assertTrue(erc4626Provider.totalBorrowed() > 0, "Should have borrowed liquidity");
        assertLt(
            erc4626Provider.availableLiquidity(),
            providerAvailableBefore,
            "Available liquidity should decrease"
        );

        // 验证总资产（可能因手续费收入而略有增加）
        // LP Vault 会收到部分手续费（40% of fee），所以 totalAssets >= initial
        assertGe(
            erc4626Provider.totalAssets(),
            providerTotalAssetsBefore,
            "Total assets should remain same or increase from fees"
        );
    }

    /// @notice 测试用户下注时 Market 从 MockProvider 借出流动性
    function test_BasicBetting_WithMockProvider() public {
        uint256 mockProviderBalanceBefore = usdc.balanceOf(address(mockProvider));
        uint256 shares = market2.placeBetFor(user1, WIN, BET_AMOUNT_MEDIUM);

        assertGt(shares, 0);
        assertTrue(mockProvider.totalBorrowed() > 0, "Should have borrowed liquidity");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 2: 多用户下注场景
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试多个用户对不同结果下注
    function test_MultiUser_DifferentOutcomes() public {
        // 记录初始利用率
        uint256 utilizationBefore = erc4626Provider.utilizationRate();

        // 三个用户下注不同结果
        market1.placeBetFor(user1, WIN, BET_AMOUNT_LARGE);
        market1.placeBetFor(user2, DRAW, BET_AMOUNT_MEDIUM);
        market1.placeBetFor(user3, LOSS, BET_AMOUNT_SMALL);

        // 验证 Provider 利用率
        uint256 utilizationAfter = erc4626Provider.utilizationRate();

        // 利用率应该保持在合理范围内(因为只借出一次初始流动性)
        assertLt(utilizationAfter, 9000, "Utilization should be less than MAX (90%)");

        // 验证市场总流动性
        uint256 totalLiquidity = market1.totalLiquidity();
        assertGt(totalLiquidity, 0, "Market should have liquidity");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 3: Provider 利用率和限制
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试 Provider 利用率查询
    function test_Provider_UtilizationTracking() public {
        // 初始利用率应该为 0
        assertEq(erc4626Provider.utilizationRate(), 0, "Initial utilization should be 0");

        // 下注后触发借款
        market1.placeBetFor(user1, WIN, BET_AMOUNT_MEDIUM);

        // 验证利用率更新
        uint256 utilization = erc4626Provider.utilizationRate();
        assertGt(utilization, 0, "Utilization should increase after borrowing");
        assertLt(utilization, 9000, "Utilization should be within limit");

        // 验证借款信息
        (uint256 borrowed, uint256 limit, uint256 available) =
            erc4626Provider.getMarketBorrowInfo(address(market1));

        assertGt(borrowed, 0, "Market should have borrowed amount");
        // Limit 是 totalAssets 的 50%，而 totalAssets 可能因手续费而略有增加
        uint256 currentTotalAssets = erc4626Provider.totalAssets();
        assertEq(limit, (currentTotalAssets * 5000) / 10000, "Limit should be 50% of total");
        assertGt(available, 0, "Should have available borrow capacity");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 4: LP 存款和提款
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试 LP 在市场运行期间存款
    function test_LP_Deposit_DuringMarketOperation() public {
        // 市场接受下注
        market1.placeBetFor(user1, WIN, BET_AMOUNT_MEDIUM);

        uint256 totalAssetsBefore = erc4626Provider.totalAssets();

        // 新 LP 存入资金
        address newLP = makeAddr("newLP");
        uint256 newDeposit = 500_000 * 1e6;
        usdc.mint(newLP, newDeposit);

        vm.startPrank(newLP);
        usdc.approve(address(erc4626Provider), newDeposit);
        uint256 sharesReceived = erc4626Provider.deposit(newDeposit, newLP);
        vm.stopPrank();

        // 验证存款成功
        assertGt(sharesReceived, 0, "Should receive shares");
        assertEq(
            erc4626Provider.totalAssets(),
            totalAssetsBefore + newDeposit,
            "Total assets should increase"
        );
    }

    /// @notice 测试 LP 提款
    function test_LP_Withdraw_WhenLiquidityAvailable() public {
        // 确保有可用流动性
        uint256 availableLiquidity = erc4626Provider.availableLiquidity();
        assertTrue(availableLiquidity > 0, "Should have available liquidity");

        // LP1 提款
        uint256 withdrawAmount = 100_000 * 1e6;

        if (availableLiquidity >= withdrawAmount) {
            uint256 balanceBefore = usdc.balanceOf(lpProvider1);

            vm.prank(lpProvider1);
            uint256 sharesBurned = erc4626Provider.withdraw(
                withdrawAmount,
                lpProvider1,
                lpProvider1
            );

            assertGt(sharesBurned, 0, "Should burn shares");
            assertEq(
                usdc.balanceOf(lpProvider1),
                balanceBefore + withdrawAmount,
                "Should receive withdrawn USDC"
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                    测试 5: 多市场共享 Provider
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试多个市场共享同一个 Provider
    function test_MultipleMarkets_SharedProvider() public {
        // 创建第三个市场,使用同一个 ERC4626Provider
        WDL_Template_V2 market3 = new WDL_Template_V2();
        market3.initialize(
            "EPL_2024_LIV_vs_TOT",
            "Liverpool",
            "Tottenham",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            address(erc4626Provider),
            "",
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        erc4626Provider.authorizeMarket(address(market3));

        // 设置 trustedRouter（必需，否则无法下注）
        market3.setTrustedRouter(address(this));

        // 测试合约授权新市场
        usdc.approve(address(market3), type(uint256).max);

        // Market1 和 Market3 都接受下注
        market1.placeBetFor(user1, WIN, BET_AMOUNT_SMALL);
        market3.placeBetFor(user1, DRAW, BET_AMOUNT_SMALL);

        // 验证 Provider 状态
        uint256 utilization = erc4626Provider.utilizationRate();
        assertGt(utilization, 0, "Utilization should be > 0");
        assertLt(utilization, 9000, "Utilization should be < 90%");

        // 验证授权市场列表
        address[] memory markets = erc4626Provider.getAuthorizedMarkets();
        assertEq(markets.length, 2, "Should have 2 authorized markets");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 6: Provider 暂停功能
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试 Provider 暂停和恢复
    function test_Provider_PauseAndUnpause() public {
        // 暂停 Provider
        erc4626Provider.pause();

        // 新 LP 无法存款
        address newLP = makeAddr("pauseTestLP");
        usdc.mint(newLP, 100_000 * 1e6);

        vm.startPrank(newLP);
        usdc.approve(address(erc4626Provider), 100_000 * 1e6);
        vm.expectRevert();
        erc4626Provider.deposit(100_000 * 1e6, newLP);
        vm.stopPrank();

        // 恢复 Provider
        erc4626Provider.unpause();

        // 验证恢复后可以存款
        vm.startPrank(newLP);
        uint256 shares = erc4626Provider.deposit(100_000 * 1e6, newLP);
        vm.stopPrank();

        assertGt(shares, 0, "Should be able to deposit after unpause");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 7: 接口抽象验证
    //////////////////////////////////////////////////////////////*/

    /// @notice 验证两种 Provider 实现都符合 ILiquidityProvider 接口
    function test_Interface_Abstraction() public {
        // 类型检查
        assertEq(erc4626Provider.providerType(), "ERC4626");
        assertEq(mockProvider.providerType(), "Mock");

        // 接口方法都可用
        assertEq(erc4626Provider.asset(), address(usdc));
        assertEq(mockProvider.asset(), address(usdc));

        assertGt(erc4626Provider.availableLiquidity(), 0);
        assertGt(mockProvider.availableLiquidity(), 0);

        assertGt(erc4626Provider.totalLiquidity(), 0);
        assertGt(mockProvider.totalLiquidity(), 0);

        // 授权市场功能
        assertTrue(erc4626Provider.isAuthorizedMarket(address(market1)));
        assertTrue(mockProvider.isAuthorizedMarket(address(market2)));

        assertFalse(erc4626Provider.isAuthorizedMarket(address(market2)));
        assertFalse(mockProvider.isAuthorizedMarket(address(market1)));
    }

    /*//////////////////////////////////////////////////////////////
                    测试 8: Provider 授权管理
    //////////////////////////////////////////////////////////////*/

    /// @notice 测试市场授权和撤销
    function test_Provider_MarketAuthorization() public {
        // 创建新市场(未授权)
        WDL_Template_V2 newMarket = new WDL_Template_V2();
        newMarket.initialize(
            "TEST_MARKET",
            "Team A",
            "Team B",
            block.timestamp + 1 days,
            address(usdc),
            address(feeRouter),
            FEE_RATE,
            DISPUTE_PERIOD,
            address(pricingEngine),
            address(erc4626Provider),
            "",
            VIRTUAL_RESERVE_INIT  // virtualReservePerSide
        );

        // 验证未授权时无法下注
        assertFalse(erc4626Provider.isAuthorizedMarket(address(newMarket)));

        // 授权市场
        erc4626Provider.authorizeMarket(address(newMarket));
        assertTrue(erc4626Provider.isAuthorizedMarket(address(newMarket)));

        // 设置 trustedRouter（必需，否则无法下注）
        newMarket.setTrustedRouter(address(this));

        // 测试合约授权新市场并下注
        usdc.approve(address(newMarket), type(uint256).max);
        uint256 shares = newMarket.placeBetFor(user1, WIN, BET_AMOUNT_SMALL);

        assertGt(shares, 0, "Should be able to bet after authorization");
    }

    /*//////////////////////////////////////////////////////////////
                    测试 9: LP 收益验证
    //////////////////////////////////////////////////////////////*/

    /// @notice 验证 LP 的 share value 会随着收益增加
    function test_LP_ShareValue_Tracking() public {
        // 记录初始 share value
        uint256 initialShares = erc4626Provider.balanceOf(lpProvider1);
        uint256 initialAssets = erc4626Provider.convertToAssets(initialShares);

        // 多次下注产生手续费
        market1.placeBetFor(user1, WIN, BET_AMOUNT_LARGE);
        market1.placeBetFor(user2, DRAW, BET_AMOUNT_MEDIUM);
        market1.placeBetFor(user3, LOSS, BET_AMOUNT_SMALL);

        // 验证 LP 持有的 shares 对应的资产价值
        uint256 currentShares = erc4626Provider.balanceOf(lpProvider1);
        uint256 currentAssets = erc4626Provider.convertToAssets(currentShares);

        // Share 数量不变
        assertEq(currentShares, initialShares, "Share count should not change");

        // 资产价值应该至少保持(可能因为手续费增加)
        assertGe(currentAssets, initialAssets, "Share value should not decrease");
    }
}
