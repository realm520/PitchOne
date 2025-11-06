# PitchOne 部署脚本使用指南

本目录包含 PitchOne 合约系统的核心部署脚本，简化为3个关键脚本以提高可维护性。

## 📋 脚本概览

### 1. Deploy.s.sol - 系统部署脚本
**用途**: 部署完整的 PitchOne 合约系统到任意网络

**支持的网络**:
- Anvil 本地测试链
- Ethereum 主网
- Arbitrum One
- Base 主网
- BNB Smart Chain

**部署的合约**:
- MockERC20 (USDC，仅测试网)
- LiquidityVault (流动性金库)
- SimpleCPMM (AMM 定价引擎)
- ReferralRegistry (推荐注册表)
- FeeRouter (费用路由)
- MarketFactory_v2 (市场工厂)
- WDL_Template_V2 (胜平负模板)
- OU_Template (大小球模板)
- OddEven_Template (单双号模板)

**使用方法**:

```bash
# 1. Anvil 本地测试 (自动部署 Mock USDC 并初始化 1M LP)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2. 主网部署 (需要真实 USDC 地址)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify

# 3. 自定义配置
export USDC_ADDRESS=0x...                # 使用现有 USDC（可选）
export INITIAL_LP_AMOUNT=5000000         # 初始 LP 金额（默认 1M USDC，仅测试网）
export LP_VAULT_ADDRESS=0x...            # LP 金库接收地址（可选）
export PROMO_POOL_ADDRESS=0x...          # 推广池接收地址（可选）
export INSURANCE_FUND_ADDRESS=0x...      # 保险基金接收地址（可选）
export TREASURY_ADDRESS=0x...            # 财库接收地址（可选）

forge script script/Deploy.s.sol:Deploy \
  --rpc-url $RPC_URL \
  --broadcast
```

---

### 2. CreateMarkets.s.sol - 批量创建市场
**用途**: 通过 Factory 批量创建测试市场，确保 Subgraph 正确索引

**⚠️ 重要**: 所有市场必须通过 Factory 创建，直接部署合约会导致 Subgraph 数据丢失！

**使用方法**:

```bash
# 1. 使用默认配置（3个WDL + 3个OU + 5个OddEven）
forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2. 自定义市场数量
export NUM_WDL_MARKETS=5
export NUM_OU_MARKETS=5
export NUM_ODDEVEN_MARKETS=10
export CREATE_DIFFERENT_STATES=true

forge script script/CreateMarkets.s.sol:CreateMarkets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

### 3. SimulateBets.s.sol - 模拟用户下注
**用途**: 模拟多用户多市场下注，生成测试数据

**模拟参数**:
- **NUM_BETTORS**: 用户数量（默认 10）
- **MIN_BET_AMOUNT**: 最小下注金额（默认 5 USDC）
- **MAX_BET_AMOUNT**: 最大下注金额（默认 50 USDC）
- **BETS_PER_USER**: 每用户下注次数（默认 3）
- **OUTCOME_DISTRIBUTION**: `balanced` / `skewed` / `random`

**使用方法**:

```bash
# 1. 使用默认配置
forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast

# 2. 大规模模拟
export NUM_BETTORS=10
export BETS_PER_USER=10
export OUTCOME_DISTRIBUTION=skewed

forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

## 🚀 完整部署流程

```bash
# 1. 部署系统
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 2. 创建测试市场
forge script script/CreateMarkets.s.sol:CreateMarkets --rpc-url http://localhost:8545 --broadcast

# 3. 生成测试数据
forge script script/SimulateBets.s.sol:SimulateBets --rpc-url http://localhost:8545 --broadcast

# 4. 更新 Subgraph 配置并部署
cd ../subgraph
# 更新 subgraph.yaml 中的 Factory 和 FeeRouter 地址
graph codegen && graph build
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 sportsbook-local
```

---

**最后更新**: 2025-11-06
