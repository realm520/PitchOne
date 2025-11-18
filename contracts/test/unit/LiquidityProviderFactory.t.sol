// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/liquidity/LiquidityProviderFactory.sol";
import "../../src/liquidity/ERC4626LiquidityProvider.sol";
import "../../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../mocks/MockERC20.sol";

/**
 * @title LiquidityProviderFactoryTest
 * @notice 流动性提供者工厂测试
 */
contract LiquidityProviderFactoryTest is Test {
    LiquidityProviderFactory public factory;
    MockERC20 public usdc;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public deployer1 = makeAddr("deployer1");
    address public deployer2 = makeAddr("deployer2");

    event ProviderTypeRegistered(string indexed providerType, address implementation);
    event ProviderDeployed(
        address indexed provider, string indexed providerType, address indexed deployer, uint256 index
    );
    event DeployerAuthorized(address indexed deployer, bool authorized);

    function setUp() public {
        usdc = new MockERC20("USD Coin", "USDC", 6);

        vm.prank(owner);
        factory = new LiquidityProviderFactory();
    }

    // ============ 基础测试 ============

    function test_Constructor() public view {
        assertEq(factory.owner(), owner);
    }

    // ============ Provider 类型注册测试 ============

    function test_RegisterProviderType() public {
        // 部署一个 ERC4626Provider 作为实现模板
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Test LP Token",
            "tLP"
        );

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit ProviderTypeRegistered("ERC4626", address(impl));

        factory.registerProviderType("ERC4626", address(impl));

        assertEq(factory.providerImplementations("ERC4626"), address(impl));
        assertTrue(factory.isProviderTypeRegistered("ERC4626"));
    }

    function test_RegisterProviderType_Revert_NonOwner() public {
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Test LP Token",
            "tLP"
        );

        vm.prank(user1);
        vm.expectRevert();
        factory.registerProviderType("ERC4626", address(impl));
    }

    function test_RegisterProviderType_Revert_EmptyType() public {
        vm.prank(owner);
        vm.expectRevert("Invalid provider type");
        factory.registerProviderType("", address(0x123));
    }

    function test_RegisterProviderType_Revert_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid implementation address");
        factory.registerProviderType("ERC4626", address(0));
    }

    function test_RegisterProviderType_Revert_AlreadyRegistered() public {
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Test LP Token",
            "tLP"
        );

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(impl));

        vm.expectRevert("Provider type already registered");
        factory.registerProviderType("ERC4626", address(impl));
        vm.stopPrank();
    }

    // ============ Deployer 授权测试 ============

    function test_AuthorizeDeployer() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, true);
        emit DeployerAuthorized(deployer1, true);

        factory.authorizeDeployer(deployer1);

        assertTrue(factory.isAuthorizedDeployer(deployer1));
    }

    function test_AuthorizeDeployer_Revert_NonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        factory.authorizeDeployer(deployer1);
    }

    function test_RevokeDeployer() public {
        vm.startPrank(owner);
        factory.authorizeDeployer(deployer1);

        vm.expectEmit(true, false, false, true);
        emit DeployerAuthorized(deployer1, false);

        factory.revokeDeployer(deployer1);
        vm.stopPrank();

        assertFalse(factory.isAuthorizedDeployer(deployer1));
    }

    // ============ Provider 部署测试 (ERC4626) ============

    function test_DeployERC4626Provider() public {
        // 注册类型
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );

        vm.prank(owner);
        factory.registerProviderType("ERC4626", address(impl));

        // 授权 deployer
        vm.prank(owner);
        factory.authorizeDeployer(deployer1);

        // 部署 Provider
        vm.prank(deployer1);
        vm.expectEmit(false, false, true, false);
        emit ProviderDeployed(address(0), "ERC4626", deployer1, 0);

        address providerAddr =
            factory.deployProvider("ERC4626", abi.encode(address(usdc), "My LP Token", "mLP"));

        // 验证
        assertTrue(providerAddr != address(0));
        assertEq(factory.getProviderCount(), 1);
        assertEq(factory.getProvider(0), providerAddr);

        // 验证部署的 Provider 属性
        ERC4626LiquidityProvider provider = ERC4626LiquidityProvider(providerAddr);
        assertEq(provider.asset(), address(usdc));
        assertEq(provider.name(), "My LP Token");
        assertEq(provider.symbol(), "mLP");
        assertEq(provider.providerType(), "ERC4626");
    }

    function test_DeployERC4626Provider_Revert_UnauthorizedDeployer() public {
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );

        vm.prank(owner);
        factory.registerProviderType("ERC4626", address(impl));

        vm.prank(user1);
        vm.expectRevert("Unauthorized deployer");
        factory.deployProvider("ERC4626", abi.encode(address(usdc), "My LP Token", "mLP"));
    }

    function test_DeployERC4626Provider_Revert_UnregisteredType() public {
        vm.prank(owner);
        factory.authorizeDeployer(deployer1);

        vm.prank(deployer1);
        vm.expectRevert("Provider type not registered");
        factory.deployProvider("NonExistent", abi.encode(address(usdc)));
    }

    // ============ Provider 部署测试 (Parimutuel) ============

    function test_DeployParimutuelProvider() public {
        // 注册类型
        ParimutuelLiquidityProvider impl = new ParimutuelLiquidityProvider(IERC20(address(usdc)));

        vm.prank(owner);
        factory.registerProviderType("Parimutuel", address(impl));

        // 授权 deployer
        vm.prank(owner);
        factory.authorizeDeployer(deployer1);

        // 部署 Provider
        vm.prank(deployer1);
        address providerAddr = factory.deployProvider("Parimutuel", abi.encode(address(usdc)));

        // 验证
        assertTrue(providerAddr != address(0));
        assertEq(factory.getProviderCount(), 1);

        ParimutuelLiquidityProvider provider = ParimutuelLiquidityProvider(providerAddr);
        assertEq(provider.asset(), address(usdc));
        assertEq(provider.providerType(), "Parimutuel");
    }

    // ============ 多 Provider 部署测试 ============

    function test_DeployMultipleProviders() public {
        // 注册两种类型
        ERC4626LiquidityProvider erc4626Impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );
        ParimutuelLiquidityProvider parimutuelImpl = new ParimutuelLiquidityProvider(IERC20(address(usdc)));

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(erc4626Impl));
        factory.registerProviderType("Parimutuel", address(parimutuelImpl));
        factory.authorizeDeployer(deployer1);
        factory.authorizeDeployer(deployer2);
        vm.stopPrank();

        // Deployer1 部署 ERC4626
        vm.prank(deployer1);
        address provider1 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP1", "LP1"));

        // Deployer2 部署 Parimutuel
        vm.prank(deployer2);
        address provider2 = factory.deployProvider("Parimutuel", abi.encode(address(usdc)));

        // Deployer1 再部署一个 ERC4626
        vm.prank(deployer1);
        address provider3 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP2", "LP2"));

        // 验证
        assertEq(factory.getProviderCount(), 3);
        assertEq(factory.getProvider(0), provider1);
        assertEq(factory.getProvider(1), provider2);
        assertEq(factory.getProvider(2), provider3);

        assertEq(ERC4626LiquidityProvider(provider1).providerType(), "ERC4626");
        assertEq(ParimutuelLiquidityProvider(provider2).providerType(), "Parimutuel");
        assertEq(ERC4626LiquidityProvider(provider3).providerType(), "ERC4626");
    }

    // ============ 查询测试 ============

    function test_GetProvidersByType() public {
        // 注册类型
        ERC4626LiquidityProvider erc4626Impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );
        ParimutuelLiquidityProvider parimutuelImpl = new ParimutuelLiquidityProvider(IERC20(address(usdc)));

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(erc4626Impl));
        factory.registerProviderType("Parimutuel", address(parimutuelImpl));
        factory.authorizeDeployer(deployer1);
        vm.stopPrank();

        // 部署多个 Provider
        vm.startPrank(deployer1);
        address provider1 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP1", "LP1"));
        address provider2 = factory.deployProvider("Parimutuel", abi.encode(address(usdc)));
        address provider3 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP2", "LP2"));
        vm.stopPrank();

        // 查询 ERC4626 类型的 Providers
        address[] memory erc4626Providers = factory.getProvidersByType("ERC4626");
        assertEq(erc4626Providers.length, 2);
        assertEq(erc4626Providers[0], provider1);
        assertEq(erc4626Providers[1], provider3);

        // 查询 Parimutuel 类型的 Providers
        address[] memory parimutuelProviders = factory.getProvidersByType("Parimutuel");
        assertEq(parimutuelProviders.length, 1);
        assertEq(parimutuelProviders[0], provider2);
    }

    function test_GetProvidersByDeployer() public {
        // 注册类型
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(impl));
        factory.authorizeDeployer(deployer1);
        factory.authorizeDeployer(deployer2);
        vm.stopPrank();

        // Deployer1 部署两个
        vm.startPrank(deployer1);
        address provider1 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP1", "LP1"));
        address provider2 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP2", "LP2"));
        vm.stopPrank();

        // Deployer2 部署一个
        vm.prank(deployer2);
        address provider3 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP3", "LP3"));

        // 查询 deployer1 的 Providers
        address[] memory deployer1Providers = factory.getProvidersByDeployer(deployer1);
        assertEq(deployer1Providers.length, 2);
        assertEq(deployer1Providers[0], provider1);
        assertEq(deployer1Providers[1], provider2);

        // 查询 deployer2 的 Providers
        address[] memory deployer2Providers = factory.getProvidersByDeployer(deployer2);
        assertEq(deployer2Providers.length, 1);
        assertEq(deployer2Providers[0], provider3);
    }

    function test_GetAllProviders() public {
        // 注册类型
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(impl));
        factory.authorizeDeployer(deployer1);
        vm.stopPrank();

        // 部署 3 个 Providers
        vm.startPrank(deployer1);
        address provider1 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP1", "LP1"));
        address provider2 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP2", "LP2"));
        address provider3 = factory.deployProvider("ERC4626", abi.encode(address(usdc), "LP3", "LP3"));
        vm.stopPrank();

        // 查询所有 Providers
        address[] memory allProviders = factory.getAllProviders();
        assertEq(allProviders.length, 3);
        assertEq(allProviders[0], provider1);
        assertEq(allProviders[1], provider2);
        assertEq(allProviders[2], provider3);
    }

    function test_GetProviderInfo() public {
        // 注册类型
        ERC4626LiquidityProvider impl = new ERC4626LiquidityProvider(
            IERC20(address(usdc)),
            "Template LP",
            "TLP"
        );

        vm.startPrank(owner);
        factory.registerProviderType("ERC4626", address(impl));
        factory.authorizeDeployer(deployer1);
        vm.stopPrank();

        // 部署 Provider
        vm.prank(deployer1);
        address providerAddr = factory.deployProvider("ERC4626", abi.encode(address(usdc), "My LP", "MLP"));

        // 查询信息
        (string memory providerType, address deployer, uint256 deployedAt) = factory.getProviderInfo(providerAddr);

        assertEq(providerType, "ERC4626");
        assertEq(deployer, deployer1);
        assertEq(deployedAt, block.timestamp);
    }

    function test_GetProviderInfo_Revert_NonExistent() public {
        vm.expectRevert("Provider not found");
        factory.getProviderInfo(address(0x123));
    }

    // ============ 边界测试 ============

    function test_GetProvider_Revert_OutOfBounds() public {
        vm.expectRevert("Index out of bounds");
        factory.getProvider(0);
    }

    function test_EmptyQueries() public {
        // 未部署任何 Provider 时的查询
        assertEq(factory.getProviderCount(), 0);
        assertEq(factory.getAllProviders().length, 0);
        assertEq(factory.getProvidersByType("ERC4626").length, 0);
        assertEq(factory.getProvidersByDeployer(deployer1).length, 0);
    }
}
