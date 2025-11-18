# Deploy.s.sol 更新说明 (Liquidity Provider 模块化集成)

## 变更概述

将部署脚本从旧的 `LiquidityVault` 迁移到新的模块化 Liquidity Provider 架构。

## 主要变更

### 1. 新增导入
```solidity
import "../src/liquidity/ERC4626LiquidityProvider.sol";
import "../src/liquidity/ParimutuelLiquidityProvider.sol";
import "../src/liquidity/LiquidityProviderFactory.sol";
```

### 2. 更新 DeployedContracts 结构体
新增字段:
- `address erc4626Provider` - ERC4626LiquidityProvider 合约地址
- `address parimutuelProvider` - ParimutuelLiquidityProvider 合约地址
- `address providerFactory` - LiquidityProviderFactory 合约地址
- `address vault` - 保留旧的 LiquidityVault (标记为 Deprecated)

### 3. 部署流程变更

**原流程 (Step 2)**:
```solidity
LiquidityVault vault = new LiquidityVault(...);
```

**新流程 (Step 2)**:
```solidity
// 1. 部署 Factory
LiquidityProviderFactory providerFactory = new LiquidityProviderFactory();

// 2. 部署 ERC4626Provider (默认)
ERC4626LiquidityProvider erc4626Provider = new ERC4626LiquidityProvider(...);

// 3. 部署 ParimutuelProvider (备用)
ParimutuelLiquidityProvider parimutuelProvider = new ParimutuelLiquidityProvider(...);

// 4. 注册 Provider 类型
providerFactory.registerProviderType("ERC4626", address(erc4626Provider));
providerFactory.registerProviderType("Parimutuel", address(parimutuelProvider));

// 5. 保留旧的 LiquidityVault (标记为 Deprecated)
LiquidityVault vault = new LiquidityVault(...);
```

### 4. FeeRouter 配置更新
**原配置**:
```solidity
lpVault: config.lpVault != address(0) ? config.lpVault : address(vault)
```

**新配置**:
```solidity
lpVault: config.lpVault != address(0) ? config.lpVault : address(erc4626Provider)
```

### 5. LP 初始化更新 (Step 5)
**原逻辑**:
```solidity
IERC20(usdc).approve(address(vault), config.initialLpAmount);
vault.deposit(config.initialLpAmount, deployer);
```

**新逻辑**:
```solidity
IERC20(usdc).approve(address(erc4626Provider), config.initialLpAmount);
erc4626Provider.deposit(config.initialLpAmount, deployer);

console.log("Provider Status:");
console.log("  Total Liquidity:", erc4626Provider.totalLiquidity() / usdcUnit, "USDC");
console.log("  Available Liquidity:", erc4626Provider.availableLiquidity() / usdcUnit, "USDC");
console.log("  Utilization Rate:", erc4626Provider.utilizationRate() / 100, "%");
```

### 6. 输出摘要更新
新增 Liquidity Provider Contracts 部分:
```
Liquidity Provider Contracts:
  LiquidityProviderFactory: <address>
  ERC4626LiquidityProvider (default): <address>
  ParimutuelLiquidityProvider: <address>
  LiquidityVault (Deprecated): <address>
```

## 向后兼容性

1. **旧的 LiquidityVault 仍然部署**: 标记为 "Deprecated",保留在返回结构体中,确保依赖旧 API 的代码仍然可以工作
2. **返回结构体扩展**: 添加新字段而非替换,保持向后兼容

## 部署后验证

部署完成后,应验证:
1. ERC4626Provider 总资产为 1,000,000 USDC (测试网)
2. 可用流动性为 1,000,000 USDC
3. 利用率为 0%
4. Factory 中注册了 2 种 Provider 类型
5. FeeRouter 的 lpVault 指向 ERC4626Provider

## 测试命令

```bash
# 部署到本地 Anvil
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 验证 ERC4626Provider 状态
cast call <ERC4626_PROVIDER_ADDRESS> "totalLiquidity()" --rpc-url http://localhost:8545
cast call <ERC4626_PROVIDER_ADDRESS> "availableLiquidity()" --rpc-url http://localhost:8545
cast call <ERC4626_PROVIDER_ADDRESS> "utilizationRate()" --rpc-url http://localhost:8545

# 验证 Factory 注册
cast call <FACTORY_ADDRESS> "isProviderTypeRegistered(string)" "ERC4626" --rpc-url http://localhost:8545
cast call <FACTORY_ADDRESS> "isProviderTypeRegistered(string)" "Parimutuel" --rpc-url http://localhost:8545
```

## 下一步

1. ✅ 部署脚本更新完成
2. ⏳ 更新 Subgraph 以索引 Provider 事件
3. ⏳ 更新前端以支持新的 Provider 架构
4. ⏳ 更新文档

## 相关文档

- [Liquidity Provider 使用指南](./LIQUIDITY_PROVIDER_GUIDE.md)
- [部署脚本](../script/Deploy.s.sol)
- [ERC4626LiquidityProvider 源码](../src/liquidity/ERC4626LiquidityProvider.sol)
- [ParimutuelLiquidityProvider 源码](../src/liquidity/ParimutuelLiquidityProvider.sol)
- [LiquidityProviderFactory 源码](../src/liquidity/LiquidityProviderFactory.sol)
