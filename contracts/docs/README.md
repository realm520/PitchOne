# PitchOne Contracts Documentation

## Overview

PitchOne 是去中心化链上体育预测平台的智能合约层，基于 Foundry 开发。

## Quick Start

```bash
# 编译
forge build

# 测试
forge test

# 部署到本地
anvil --host 0.0.0.0
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

## Core Scripts

| Script | Description |
|--------|-------------|
| `Deploy.s.sol` | 部署所有核心合约和模板 |
| `CreateAllMarketTypes.s.sol` | 创建 7 种类型的测试市场 |
| `SimulateBets.s.sol` | 模拟多用户下注 |
| `LockMarket.s.sol` | 锁定市场（开赛前） |
| `SetupReferrals.s.sol` | 设置推荐关系 |

---

## Architecture

### Core Contracts

```
src/
├── core/
│   ├── MarketBase_V2.sol       # 市场基础合约
│   ├── MarketFactory_v2.sol    # 市场工厂
│   ├── BettingRouter.sol       # 统一投注入口
│   └── MarketTemplateRegistry.sol
├── pricing/
│   ├── SimpleCPMM.sol          # 二/三向 AMM
│   ├── LMSR.sol                # 多结果市场
│   ├── ParimutuelPricing.sol   # 彩池定价
│   └── LinkedLinesController.sol # 多线联动
├── templates/                   # 7 种市场模板
├── liquidity/                   # 流动性提供者
├── governance/                  # ParamController
└── operations/                  # 运营工具
```

---

## BettingRouter

统一投注入口，用户只需授权一次即可投注所有市场。

### Core Functions

```solidity
// 单笔下注
function placeBet(address market, uint256 outcomeId, uint256 amount) external;

// 带滑点保护
function placeBetWithSlippage(address market, uint256 outcomeId, uint256 amount, uint256 maxSlippageBps) external;

// 批量下注
function placeBets(BetParams[] calldata bets) external;
```

### Market Configuration

**重要**：每个市场创建后必须设置 trustedRouter：

```solidity
market.setTrustedRouter(bettingRouterAddress);
```

### Security

- Factory 注册验证
- 市场状态检查
- Router 信任检查
- 暂停/紧急提款机制

---

## Pricing Engines

### IPricingEngine Interface

```solidity
interface IPricingEngine {
    function calculateShares(uint256 outcomeId, uint256 amount, uint256[] memory reserves) external view returns (uint256);
    function updateReserves(uint256 outcomeId, uint256 amount, uint256 shares, uint256[] memory reserves) external pure returns (uint256[] memory);
    function getPrice(uint256 outcomeId, uint256[] memory reserves) external view returns (uint256);
    function getInitialReserves(uint256 outcomeCount) external view returns (uint256[] memory);
}
```

### Implementations

| Engine | Use Case | Initial Reserves |
|--------|----------|------------------|
| SimpleCPMM | WDL/OU/AH 二/三向市场 | Configurable (e.g., 100k) |
| LMSR | 精确比分、球员道具 | Based on b parameter |
| ParimutuelPricing | 彩池模式 | Zero |

### Usage

```solidity
// CPMM 市场
SimpleCPMM cpmm = new SimpleCPMM(100_000 * 1e6);
market.initialize(..., address(cpmm), ...);

// Parimutuel 市场
ParimutuelPricing parimutuel = new ParimutuelPricing();
market.initialize(..., address(parimutuel), ...);
```

---

## Liquidity Providers

### ILiquidityProvider Interface

```solidity
interface ILiquidityProvider {
    function borrow(uint256 amount) external;
    function repay(uint256 principal, uint256 revenue) external;
    function availableLiquidity() external view returns (uint256);
    function authorizeMarket(address market) external;
}
```

### Implementations

| Provider | LP Shares | Best For |
|----------|-----------|----------|
| ERC4626LiquidityProvider | ERC-20 Shares | AMM 市场 |
| ParimutuelLiquidityProvider | Proportion | 彩池市场 |
| MockLiquidityProvider | None | Testing |

---

## LinkedLinesController

多线市场（OU 2.0/2.5/3.0）的联动定价控制器。

### Quick Start

```solidity
// 1. 创建线组
bytes32 groupId = keccak256("OU_MATCH_123");
uint256[] memory lines = [2000, 2500, 3000]; // 2.0, 2.5, 3.0 球
controller.createLineGroup(groupId, lines);

// 2. 配置联动
controller.configureLink(groupId, 2000, 2500, 8000, 50, 500);  // 80% 联动

// 3. 检测套利
(bool hasArbitrage, , , ) = controller.detectArbitrage(groupId, allReserves);
```

### Parameters

| Parameter | Range | Description |
|-----------|-------|-------------|
| linkCoefficient | 50-100% | 价格联动系数 |
| minSpread | 0.5-1% | 最小价差 |
| maxSpread | 3-5% | 最大价差 |

---

## Market Templates

| Template | Outcomes | Pricing |
|----------|----------|---------|
| WDL_Template_V2 | 3 (Win/Draw/Lose) | SimpleCPMM |
| OU_Template_V2 | 2 (Over/Under) | SimpleCPMM |
| AH_Template | 2-3 (Handicap) | SimpleCPMM |
| OddEven_Template_V2 | 2 (Odd/Even) | SimpleCPMM |
| OU_MultiLine_V2 | N×2 | LinkedLinesController |
| ScoreTemplate | 25-100 | LMSR |
| PlayerProps_Template_V2 | 2-N | SimpleCPMM/LMSR |

---

## ParamController

治理参数控制器，支持 Timelock + 多签。

```solidity
// 注册参数
paramController.registerParam(key, defaultValue, validator);

// 提案变更
paramController.proposeChange(key, newValue, reason);

// 执行（Timelock 后）
paramController.executeChange(proposalId);

// 紧急暂停
paramController.emergencyPause();
```

---

## Testing

```bash
# 全部测试
forge test

# 特定合约
forge test --match-contract BettingRouterTest -v

# 覆盖率
forge coverage
```

### Test Structure

```
test/
├── unit/           # 单元测试
├── integration/    # 集成测试
└── scripts/        # 测试脚本
    ├── TestMarketConfig.s.sol
    ├── TestParamController.s.sol
    └── TestParimutuel.s.sol
```

---

## Deployment Checklist

1. [ ] Deploy core contracts (`Deploy.s.sol`)
2. [ ] Set trustedRouter on all markets
3. [ ] Authorize markets to LiquidityProvider
4. [ ] Configure LinkedLinesController for multi-line markets
5. [ ] Register parameters in ParamController
6. [ ] Update Subgraph with new addresses

---

## Security Considerations

- All markets must be created via Factory
- trustedRouter must be set before betting
- LP authorization required for borrowing
- Role-based access control (Admin/Operator)
- Emergency pause mechanisms
- Slippage protection on bets

---

## Gas Optimization

- Clone pattern for market deployment
- Batch operations (placeBets)
- calldata over memory for arrays
- unchecked loops where safe
- Minimal storage reads

---

## Related Documentation

- [Architecture_V3.md](./Architecture_V3.md) - V3 架构设计
- [AccessControl.md](./AccessControl.md) - 角色与权限管理
- [CLAUDE.md](../CLAUDE.md) - Project overview and dev guide
- [Subgraph](../../subgraph/) - GraphQL indexing
- [Frontend](../../frontend/) - Web interface
