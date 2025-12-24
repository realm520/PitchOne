·# 完整部署脚本使用指南

## 概述

`deploy-parimutuel-full.sh` 是一个一键式部署脚本，包含以下功能：

1. 检查并启动 Anvil 测试链
2. 部署所有核心合约
3. 创建 7 种类型的测试市场（每种 3 个，共 21 个）
4. **建立推荐关系**（账户 #0 作为推荐人，其他账户为被推荐人）
5. **模拟下注**（包含推荐返佣测试）
6. **验证推荐返佣结果**

## 快速开始

```bash
# 1. 确保在 contracts 目录
cd /home/harry/code/PitchOne/contracts

# 2. 运行完整部署脚本
./deploy-parimutuel-full.sh
```

## 测试账户

脚本使用 Anvil 的默认账户进行测试。所有私钥保存在 `.test-accounts` 文件中（已加入 .gitignore）。

**推荐关系结构**：
- **推荐人**：账户 #0 (0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
- **被推荐人**：账户 #1-9（全部绑定到账户 #0）

## 环境变量配置

可以通过环境变量自定义参数：

```bash
# 下注用户数（默认 5）
export NUM_BETTORS=10

# 下注金额范围（默认 10-100 USDC）
export MIN_BET_AMOUNT=20
export MAX_BET_AMOUNT=200

# 每个用户下注次数（默认 2）
export BETS_PER_USER=5

# 下注分布策略（默认 balanced）
# 可选值：balanced, skewed, random
export OUTCOME_DISTRIBUTION=skewed

# 然后运行脚本
./deploy-parimutuel-full.sh
```

## 手动步骤拆解

如果需要分步执行，可以按以下顺序手动运行：

### 1. 启动 Anvil
```bash
anvil --host 0.0.0.0
```

### 2. 部署合约
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/Deploy.s.sol:Deploy \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 3. 创建测试市场
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 4. 建立推荐关系
```bash
forge script script/SetupReferrals.s.sol:SetupReferrals \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 5. 模拟下注
```bash
NUM_BETTORS=5 \
MIN_BET_AMOUNT=10 \
MAX_BET_AMOUNT=100 \
BETS_PER_USER=2 \
OUTCOME_DISTRIBUTION=balanced \
forge script script/SimulateBets.s.sol:SimulateBets \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### 6. 验证推荐返佣
```bash
# 读取合约地址
REFERRAL_REGISTRY=$(jq -r '.contracts.referralRegistry' deployments/localhost.json)
USDC=$(jq -r '.contracts.usdc' deployments/localhost.json)
REFERRER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# 查询推荐人统计
cast call $REFERRAL_REGISTRY "getReferrerStats(address)" $REFERRER --rpc-url http://localhost:8545

# 查询推荐人 USDC 余额
cast call $USDC "balanceOf(address)" $REFERRER --rpc-url http://localhost:8545
```

## 返佣验证

脚本执行完成后，会显示推荐人的返佣统计：

```
========================================
  推荐返佣验证
========================================
  推荐人地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

推荐人统计：
  推荐人数: 5
  累计返佣: 0.16 USDC

推荐人当前余额：
  USDC 余额: 1000000.16 USDC

✓ 推荐返佣功能正常！推荐人已收到 0.16 USDC 返佣
```

## 返佣计算公式

- **手续费**：下注金额 × 2% (200 bps)
- **推荐返佣**：手续费 × 8% (800 bps)
- **示例**：用户下注 100 USDC
  - 手续费 = 100 × 2% = 2 USDC
  - 推荐返佣 = 2 × 8% = 0.16 USDC

## Subgraph 查询

脚本执行后，可以访问 GraphQL Playground 查询推荐数据：

**URL**: http://localhost:8010/subgraphs/name/pitchone-sportsbook/graphql

**查询示例**：
```graphql
{
  referrals(first: 10) {
    id
    referrer {
      id
      totalReferralRewards
      referralCount
    }
    referee {
      id
      totalVolume
      totalBets
    }
    commissionEarned
    timestamp
  }
}
```

## 常见问题

### 1. 推荐返佣为 0

**可能原因**：
- 被推荐人尚未下注
- 下注金额太小，手续费返佣被四舍五入为 0
- 推荐关系未正确建立

**解决方法**：
```bash
# 检查推荐关系
cast call $REFERRAL_REGISTRY "referrer(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --rpc-url http://localhost:8545

# 增加下注金额
export MIN_BET_AMOUNT=50
export MAX_BET_AMOUNT=200
./deploy-parimutuel-full.sh
```

### 2. Anvil 端口被占用

```bash
# 查找占用进程
lsof -i :8545

# 杀死进程
pkill anvil

# 重新运行脚本
./deploy-parimutuel-full.sh
```

### 3. 脚本执行失败

```bash
# 查看详细错误信息（移除 --silent 参数）
# 编辑脚本，将所有 --silent 改为 -vv

# 或者手动执行各个步骤，查看详细输出
```

## 注意事项

1. **安全警告**：`.test-accounts` 中的私钥仅用于本地测试，**绝对不要**在生产环境使用！
2. **数据清理**：重启 Anvil 会清空所有链上数据，需要重新部署
3. **权限问题**：如果脚本无执行权限，运行 `chmod +x deploy-parimutuel-full.sh`
4. **依赖工具**：需要安装 `jq` 命令行工具（用于解析 JSON）

## 相关脚本

- `script/SetupReferrals.s.sol` - 建立推荐关系的 Solidity 脚本
- `script/SimulateBets.s.sol` - 模拟下注的 Solidity 脚本
- `.test-accounts` - 测试账户私钥文件（不提交到 Git）
