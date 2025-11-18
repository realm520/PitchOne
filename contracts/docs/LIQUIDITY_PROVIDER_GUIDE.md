# Liquidity Provider 模块使用指南

## 概述

本项目实现了模块化的流动性提供者架构,支持多种 Provider 类型为预测市场提供流动性。

## 核心组件

### 1. ILiquidityProvider 接口

所有 Provider 必须实现的标准接口,定义了核心借贷和查询功能。

**主要方法**:
- `borrow(uint256 amount)` - 市场借出流动性
- `repay(uint256 principal, uint256 revenue)` - 市场归还本金+收益
- `availableLiquidity()` - 查询可用流动性
- `totalLiquidity()` - 查询总流动性
- `utilizationRate()` - 查询当前利用率(基点)
- `authorizeMarket(address market)` - 授权市场
- `revokeMarket(address market)` - 撤销市场授权

### 2. ERC4626LiquidityProvider

基于 ERC-4626 标准的流动性提供者,LP 获得 Vault Shares。

**特性**:
- LP 存入 USDC,获得 ERC-20 代币化份额
- 自动收益分配(shares 价值增长)
- 利用率限制:最大 90%
- 单市场借款上限:50% 总资产
- 支持暂停/恢复功能

**部署参数**:
```solidity
new ERC4626LiquidityProvider(
    IERC20 asset,      // USDC 地址
    string memory name,   // Vault Shares 名称,如 "PitchOne LP Token"
    string memory symbol  // Vault Shares 符号,如 "pLP"
);
```

### 3. ParimutuelLiquidityProvider

彩池模式流动性提供者,适用于 Parimutuel 市场。

**特性**:
- 彩池贡献机制
- 收益按贡献比例分配
- 无 ERC-4626 Shares(简化实现)
- 支持多市场共享彩池

**部署参数**:
```solidity
new ParimutuelLiquidityProvider(
    IERC20 asset  // USDC 地址
);
```

### 4. MockLiquidityProvider

测试用 Provider,提供无限流动性。

**特性**:
- 无限流动性模式(默认)
- 简化的授权机制
- 用于单元测试和集成测试

### 5. LiquidityProviderFactory

统一管理 Provider 部署和追踪的工厂合约。

**核心功能**:
```solidity
// 1. 注册 Provider 类型(仅 owner)
factory.registerProviderType("ERC4626", implementationAddress);

// 2. 授权 Deployer(仅 owner)
factory.authorizeDeployer(deployerAddress);

// 3. 部署 Provider(需授权)
address provider = factory.deployProvider(
    "ERC4626",
    abi.encode(usdcAddress, "My LP Token", "MLP")
);

// 4. 查询
address[] memory allProviders = factory.getAllProviders();
address[] memory erc4626Providers = factory.getProvidersByType("ERC4626");
address[] memory myProviders = factory.getProvidersByDeployer(msg.sender);
```

## 使用流程

### 场景 1: 为市场创建 ERC4626 Provider

```solidity
// 1. 部署 USDC(如果测试环境)
MockERC20 usdc = new MockERC20("USDC", "USDC", 6);

// 2. 部署 Provider
ERC4626LiquidityProvider provider = new ERC4626LiquidityProvider(
    IERC20(address(usdc)),
    "PitchOne LP Token",
    "pLP"
);

// 3. LP 存入流动性
usdc.mint(lpProvider, 1_000_000 * 1e6); // 铸造 1M USDC
usdc.approve(address(provider), 1_000_000 * 1e6);
provider.deposit(1_000_000 * 1e6, lpProvider);

// 4. 授权市场
provider.authorizeMarket(marketAddress);

// 5. 市场创建时关联 Provider
market.initialize(
    // ... 其他参数
    address(provider),  // liquidityProvider
    // ...
);

// 6. 市场借出流动性(在 market.initialize() 内部调用)
provider.borrow(initialLiquidity);

// 7. 市场结算后还款
provider.repay(principal, revenue);

// 8. LP 提取收益
uint256 shares = provider.balanceOf(lpProvider);
provider.redeem(shares, lpProvider, lpProvider);
```

### 场景 2: 使用 Factory 部署多个 Provider

```solidity
// 1. 部署 Factory
LiquidityProviderFactory factory = new LiquidityProviderFactory();

// 2. 注册 Provider 类型
ERC4626LiquidityProvider erc4626Impl = new ERC4626LiquidityProvider(
    IERC20(address(usdc)),
    "Template",
    "TPL"
);
factory.registerProviderType("ERC4626", address(erc4626Impl));

// 3. 授权 Deployer
factory.authorizeDeployer(deployer);

// 4. 部署 Provider
address provider1 = factory.deployProvider(
    "ERC4626",
    abi.encode(address(usdc), "Market 1 LP", "M1LP")
);

address provider2 = factory.deployProvider(
    "ERC4626",
    abi.encode(address(usdc), "Market 2 LP", "M2LP")
);

// 5. 查询已部署的 Providers
address[] memory allProviders = factory.getAllProviders();
```

## 测试覆盖

| 组件                          | 单元测试 | 集成测试 | 状态 |
| ----------------------------- | -------- | -------- | ---- |
| ILiquidityProvider            | -        | -        | ✅    |
| ERC4626LiquidityProvider      | 36 个    | 11 个    | ✅    |
| ParimutuelLiquidityProvider   | 28 个    | -        | ✅    |
| MockLiquidityProvider         | -        | 11 个    | ✅    |
| LiquidityProviderFactory      | 21 个    | -        | ✅    |
| **总计**                       | **85 个**| **11 个**| **✅**|

## 合约文件

```
src/
├── interfaces/
│   └── ILiquidityProvider.sol        # 核心接口(174 行)
├── liquidity/
│   ├── ERC4626LiquidityProvider.sol  # ERC-4626 Provider(410 行)
│   ├── ParimutuelLiquidityProvider.sol # 彩池 Provider(273 行)
│   └── LiquidityProviderFactory.sol  # 工厂合约(277 行)
└── mocks/
    └── MockLiquidityProvider.sol     # 测试 Mock(277 行)

test/
├── unit/
│   ├── ERC4626LiquidityProvider.t.sol     # 36 个测试
│   ├── ParimutuelLiquidityProvider.t.sol  # 28 个测试
│   └── LiquidityProviderFactory.t.sol     # 21 个测试
└── integration/
    └── MarketLiquidityProvider_Integration.t.sol  # 11 个测试
```

## 关键设计决策

### 为什么使用接口抽象?

- **灵活性**: 支持多种流动性策略(AMM、Parimutuel、Hybrid)
- **扩展性**: 新增 Provider 类型无需修改市场合约
- **可测试性**: 使用 Mock 简化单元测试
- **未来扩展**: 可支持第三方协议集成(Aave、Compound 等)

### ERC4626 vs Parimutuel

| 特性           | ERC4626                      | Parimutuel               |
| -------------- | ---------------------------- | ------------------------ |
| LP 份额        | ERC-20 Shares                | 比例记录                 |
| 收益分配       | Share 价值增长               | 手动分配或 Merkle        |
| 流动性管理     | 借贷模型(borrow/repay)       | 彩池模型                 |
| 适用场景       | AMM 市场                     | 传统彩池市场             |
| 复杂度         | 高(需 ERC-4626 兼容)         | 低(简化实现)             |

### 为什么需要 Factory?

- **统一管理**: 集中追踪所有 Provider 实例
- **权限控制**: 限制谁可以部署 Provider
- **类型注册**: 管理支持的 Provider 类型
- **链上查询**: 方便前端和链下服务查询

## 后续扩展

### 1. 跨链 Provider

支持从其他链(如 Polygon、Arbitrum)借入流动性。

### 2. 第三方协议集成

集成 Aave、Compound 等借贷协议作为流动性来源。

### 3. 动态利率模型

根据市场供需自动调整利率。

### 4. 保险基金集成

部分收益进入保险基金,用于覆盖极端情况损失。

## 常见问题(FAQ)

### Q: 如何选择 Provider 类型?

- **AMM 市场**(WDL、OU、AH 等) → 使用 `ERC4626LiquidityProvider`
- **Parimutuel 市场** → 使用 `ParimutuelLiquidityProvider`
- **测试环境** → 使用 `MockLiquidityProvider`

### Q: LP 如何获得收益?

- **ERC4626**: Share 价值自动增长,提取时自动获得收益
- **Parimutuel**: 调用 `distributeRevenue()` 后,按比例分配

### Q: 单个 Provider 可以服务多个市场吗?

可以。Provider 支持同时授权和服务多个市场。

### Q: 如何限制市场的借款额度?

- ERC4626 有内置限制(单市场 50%,总利用率 90%)
- Parimutuel 可通过自定义逻辑实现

### Q: 市场必须使用 Provider 吗?

不是。市场可以选择不使用 Provider,直接管理自己的流动性(如 Parimutuel 模式)。

## 安全注意事项

1. **权限管理**: 只有可信的市场才能被授权
2. **利用率监控**: 避免过度借贷导致流动性枯竭
3. **收益验证**: 市场还款时验证收益金额合理性
4. **紧急暂停**: ERC4626 支持暂停功能,应对紧急情况
5. **审计建议**: 建议对所有 Provider 进行安全审计

## 参考资料

- [ERC-4626 标准](https://eips.ethereum.org/EIPS/eip-4626)
- [ILiquidityProvider 接口源码](../src/interfaces/ILiquidityProvider.sol)
- [测试用例](../test/unit/)
