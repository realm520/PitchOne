# Forge 部署和测试脚本

本目录包含 PitchOne 项目的核心 Forge 脚本，用于部署、测试和管理智能合约。

---

## 📁 脚本清单

### 1. DeployToAnvil.s.sol
**用途**: 部署完整系统到 Anvil 本地测试链

**部署内容**:
- USDC Mock Token
- FeeRouter (费用路由)
- ReferralRegistry (推荐关系注册表)
- SimpleCPMM (AMM 定价引擎)
- MarketFactory_v2 (市场工厂)
- 3 个市场模板：WDL (胜平负)、OU (大小球)、OddEven (奇偶进球)

**使用方法**:
```bash
forge script script/DeployToAnvil.s.sol:DeployToAnvil \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**输出**: 打印所有部署的合约地址和 Template IDs

---

### 2. CreateTestMarkets.s.sol
**用途**: 创建测试市场并添加初始流动性

**创建内容**:
- 2 个 WDL 市场 (曼联vs利物浦, 巴萨vs皇马)
- 2 个 OU 市场 (切尔西vs阿森纳 O/U 2.5, 皇马vs马竞 O/U 1.5)
- 2 个 OddEven 市场 (热刺vs纽卡, 塞维利亚vs瓦伦西亚)

**每个市场的初始流动性**:
- WDL: 3000 USDC
- OU: 2000 USDC
- OddEven: 2000 USDC

**使用方法**:
```bash
forge script script/CreateTestMarkets.s.sol:CreateTestMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**前置条件**: 必须先运行 `DeployToAnvil.s.sol`

---

### 3. TestFullLifecycle.s.sol
**用途**: 测试完整的市场生命周期

**测试流程**:
1. **Phase 1: 用户下注**
   - User1 和 User2 对 3 个市场进行下注
   - 测试不同的下注金额和方向

2. **Phase 2: 查询市场状态**
   - 查询市场流动性
   - 验证市场状态

3. **Phase 3: 市场锁盘**
   - 模拟时间推进至开赛时间
   - 调用 `lock()` 锁定市场

4. **Phase 4: 预言机结算**
   - 调用 `resolve(outcome)` 结算市场
   - 设置获胜结果

5. **Phase 5: 用户赎回**
   - 获胜用户赎回奖金
   - 验证赎回金额

**使用方法**:
```bash
forge script script/TestFullLifecycle.s.sol:TestFullLifecycle \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**前置条件**: 必须先运行 `CreateTestMarkets.s.sol`

**测试账户**:
- Deployer: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` (Anvil #0)
- User1: `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (Anvil #1)
- User2: `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` (Anvil #2)

---

### 4. TestLiquidity.s.sol
**用途**: 测试流动性管理功能

**测试内容**:
1. 查询初始市场流动性
2. 添加额外流动性 (1000 USDC)
3. 查询 LP shares
4. 验证流动性变化

**使用方法**:
```bash
forge script script/TestLiquidity.s.sol:TestLiquidity \
  --rpc-url http://localhost:8545 \
  --broadcast \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**前置条件**: 必须先运行 `CreateTestMarkets.s.sol`

---

## 🚀 快速开始

### 完整测试流程

```bash
# 1. 启动 Anvil 本地链
anvil

# 2. 在新终端中部署系统
forge script script/DeployToAnvil.s.sol:DeployToAnvil \
  --rpc-url http://localhost:8545 --broadcast

# 3. 创建测试市场
forge script script/CreateTestMarkets.s.sol:CreateTestMarkets \
  --rpc-url http://localhost:8545 --broadcast

# 4. 运行完整生命周期测试
forge script script/TestFullLifecycle.s.sol:TestFullLifecycle \
  --rpc-url http://localhost:8545 --broadcast

# 5. 测试流动性管理
forge script script/TestLiquidity.s.sol:TestLiquidity \
  --rpc-url http://localhost:8545 --broadcast
```

---

## 📝 脚本依赖关系

```
DeployToAnvil.s.sol (独立运行)
    ↓
CreateTestMarkets.s.sol (依赖 DeployToAnvil)
    ↓
    ├─ TestFullLifecycle.s.sol (依赖 CreateTestMarkets)
    └─ TestLiquidity.s.sol (依赖 CreateTestMarkets)
```

---

## 🗂️ 归档脚本

过时的脚本已移动到 `archived/` 目录。这些脚本包含旧的部署方法或已被新脚本替代的功能。

**归档脚本数量**: 18 个

如需使用归档脚本，请参考 `archived/` 目录中的文件。

---

## 🔧 默认配置

所有脚本使用以下默认配置（Anvil 测试链）:

- **RPC URL**: `http://localhost:8545`
- **Chain ID**: `31337`
- **Deployer Private Key**: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
  - Address: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
  - 这是 Anvil 默认账户 #0

---

## 📊 测试结果验证

### 查询链上数据

```bash
# 查询市场状态
cast call <MARKET_ADDRESS> "status()(uint8)" --rpc-url http://localhost:8545

# 查询用户 USDC 余额
cast call <USDC_ADDRESS> "balanceOf(address)(uint256)" <USER_ADDRESS> --rpc-url http://localhost:8545

# 查询当前区块高度
cast block-number --rpc-url http://localhost:8545
```

### Subgraph 查询

```bash
# 查询市场数据
curl -X POST http://localhost:8010/subgraphs/id/<SUBGRAPH_HASH> \
  -H "Content-Type: application/json" \
  -d '{"query": "{ markets { id templateId state } }"}'
```

---

## ⚠️ 注意事项

1. **Anvil 账户**: 脚本使用 Anvil 默认测试账户，**切勿在主网使用这些私钥**
2. **Gas 费用**: Anvil 链上 gas 费用为 0，主网/测试网部署需要真实 ETH
3. **OU 市场限制**: OU 市场只支持半球线（如 1.5, 2.5, 3.5），不支持整数线
4. **Subgraph 延迟**: Subgraph 索引可能有 5-10 秒延迟

---

## 📚 相关文档

- [测试报告](../../TEST_REPORT.md) - 完整功能测试报告
- [项目文档](../../docs/intro.md) - 项目架构和设计文档
- [Foundry Book](https://book.getfoundry.sh/) - Forge 脚本文档

---

**最后更新**: 2025-11-03
**维护者**: 0xH4rry <realm520@gmail.com>
