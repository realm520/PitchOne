# Rewards Builder Service

周度奖励分发服务 - 聚合奖励数据，生成 Merkle 树，并发布到链上。

## 功能概述

Rewards Builder 负责：
1. **数据聚合**：从数据库聚合周度奖励数据（推荐返佣、交易奖励、活动奖励）
2. **Merkle 树生成**：为所有用户生成 Merkle 树和证明
3. **链上发布**：将 Merkle Root 发布到 RewardsDistributor 合约
4. **数据导出**：导出完整的分配数据和证明到 JSON 文件

## 架构

```
┌─────────────┐
│  Database   │ (Postgres)
│  - orders   │
│  - referrals│
└──────┬──────┘
       │
       ├─ Aggregator ────> mergeRewards()
       │                          │
       ├─ TradingRewards          │
       ├─ ReferralRewards         │
       └─ CampaignRewards         │
                                  │
                                  ▼
                          ┌──────────────┐
                          │ MerkleTree   │
                          │ - BuildTree  │
                          │ - GenProofs  │
                          └──────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │  Distribution │
                         │  - Root       │
                         │  - Proofs     │
                         │  - Metadata   │
                         └───────┬───────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ▼                ▼                ▼
        ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
        │   Database  │  │  JSON File  │  │   Ethereum  │
        │   Storage   │  │   Export    │  │   Contract  │
        └─────────────┘  └─────────────┘  └─────────────┘
```

## 使用方式

### 1. 配置环境变量

```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/pitchone"
export RPC_URL="https://eth-mainnet.alchemyapi.io/v2/YOUR-API-KEY"
export REWARDS_DISTRIBUTOR_ADDR="0x..."
export PRIVATE_KEY="0x..."  # 不要在生产环境硬编码！
```

### 2. Dry Run 模式（仅生成数据，不发布）

```bash
cd backend
go run ./cmd/rewards \
  --dry-run \
  --output dist-week-45.json
```

输出示例：
```
Connected to database successfully
Auto-detected previous week: 45
Building rewards distribution for week 45
Aggregated 123 reward entries
Merkle Root: 0x7c8b9e5e8c3e3b2b5b5f5e8e9b8b5e3e8c9b5f5e8e9b8b5e3e8c9b5f5e8e9b8b
Total Recipients: 123
Scale: 10000 bps (100.00%)
Checksum: a1b2c3d4e5f6...
Distribution saved to database
Distribution exported to dist-week-45.json
Dry run mode - skipping on-chain publication
✅ Dry run completed successfully
```

### 3. 发布到链上

```bash
go run ./cmd/rewards \
  --week 45 \
  --output dist-week-45.json
```

输出示例：
```
...
Publishing to chain...
Transaction sent: 0xabcd1234...
Waiting for confirmation...
✅ Transaction confirmed in block 18123456
Gas used: 124523
✅ Root verified on-chain: 0x7c8b9e5e8c3e3b2b...
🎉 Rewards distribution for week 45 completed successfully!
```

### 4. 指定特定周

```bash
go run ./cmd/rewards --week 42
```

### 5. 仅导出数据（不保存到数据库，不发布）

```bash
go run ./cmd/rewards \
  --dry-run \
  --output exports/week-45.json
```

## 命令行参数

| 参数 | 环境变量 | 默认值 | 说明 |
|------|---------|--------|------|
| `--db` | `DATABASE_URL` | - | Postgres 连接串（必需） |
| `--rpc-url` | `RPC_URL` | - | Ethereum RPC URL |
| `--distributor` | `REWARDS_DISTRIBUTOR_ADDR` | - | RewardsDistributor 合约地址 |
| `--private-key` | `PRIVATE_KEY` | - | 签名私钥 |
| `--week` | - | 当前周-1 | 要处理的周编号 |
| `--dry-run` | - | false | Dry run 模式 |
| `--output` | - | - | 导出 JSON 文件路径 |

## 输出格式

生成的 JSON 文件格式：

```json
{
  "week": 45,
  "root": "0x7c8b9e5e8c3e3b2b5b5f5e8e9b8b5e3e8c9b5f5e8e9b8b5e3e8c9b5f5e8e9b8b",
  "totalAmount": "1234567890000000",
  "recipients": 123,
  "scaleBps": 10000,
  "entries": [
    {
      "User": "0x1111111111111111111111111111111111111111",
      "Week": 45,
      "Amount": "1000000000"
    },
    ...
  ],
  "proofs": {
    "0x1111111111111111111111111111111111111111": [
      "0xabcd1234...",
      "0xef567890..."
    ],
    ...
  },
  "createdAt": 1699123456
}
```

## 数据库表结构

需要以下数据库表：

### reward_distributions
```sql
CREATE TABLE reward_distributions (
    week BIGINT PRIMARY KEY,
    merkle_root VARCHAR(66) NOT NULL,
    total_amount NUMERIC(78, 0) NOT NULL,
    recipients INT NOT NULL,
    scale_bps INT NOT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT
);
```

### orders (用于聚合)
已存在，由 Indexer 服务维护。

## 奖励聚合逻辑

### 1. 推荐返佣（Referral Rewards）
```sql
SELECT referrer, SUM(fee * 0.08) as total_rewards
FROM orders
WHERE referrer IS NOT NULL
  AND timestamp >= week_start
  AND timestamp < week_end
GROUP BY referrer
```

### 2. 交易奖励（Trading Rewards）
```sql
SELECT user_address, SUM(stake) * 0.001 as reward
FROM orders
WHERE timestamp >= week_start
  AND timestamp < week_end
GROUP BY user_address
HAVING SUM(stake) >= 1000 USDC
```

### 3. 活动奖励（Campaign Rewards）
TODO: 从活动表聚合

### 合并逻辑
所有奖励按用户地址合并，生成最终的 `totalRewards`。

## Merkle 树生成

### 算法
1. 为每个用户生成叶子节点：`keccak256(bytes.concat(keccak256(abi.encode(user, week, amount))))`
2. 按用户地址排序（确保确定性）
3. 构建平衡二叉树，父节点 = `keccak256(left, right)`（按哈希值排序）
4. 为每个用户生成 Merkle 证明路径

### 验证
用户在链上领取时，合约验证：
```solidity
bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, week, amount))));
require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
```

## 链上交互

### 发布 Root
调用 `RewardsDistributor.publishRoot(week, root, totalAmount, scaleBps)`

### Gas 估算
- 单次 publishRoot: ~120,000 Gas
- 建议 Gas Price: 根据网络情况调整
- 确认数: 建议等待3个区块确认

## 安全考虑

1. **私钥管理**：生产环境使用 AWS KMS / HashiCorp Vault
2. **Dry Run 优先**：先在测试网验证，再发布到主网
3. **双重验证**：发布后从链上查询验证 Root
4. **预算检查**：确保合约有足够余额支付奖励
5. **回滚保护**：周编号递增，不允许覆盖已发布的周

## 监控与告警

建议监控指标：
- 每周聚合的奖励总额
- 收益人数量
- Merkle 树生成耗时
- 链上交易成功率
- Gas 消耗

## 故障恢复

### 场景1：交易失败
```bash
# 查看错误日志
# 调整 Gas Price 后重试
go run ./cmd/rewards --week 45
```

### 场景2：数据不一致
```bash
# 从数据库重新加载分配数据
psql -d pitchone -c "SELECT * FROM reward_distributions WHERE week = 45"

# 与链上验证
cast call $DISTRIBUTOR "weeklyRewards(uint256)(bytes32,uint256,uint256,uint256,uint256)" 45
```

### 场景3：周已发布，需要更新
链上周数据一旦发布**不可修改**。如需更正，只能：
1. 在下一周补偿差额
2. 或通过治理多签撤回并重新发布

## 测试

### 单元测试
```bash
cd backend
go test ./internal/rewards/... -v
```

### 集成测试
```bash
# 1. 启动本地测试网（Anvil）
anvil

# 2. 部署合约
cd contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 3. 运行 Rewards Builder
cd backend
export DATABASE_URL="postgresql://localhost/pitchone_test"
export RPC_URL="http://localhost:8545"
export REWARDS_DISTRIBUTOR_ADDR="0x..."
go run ./cmd/rewards --dry-run
```

## 依赖

- Go 1.21+
- PostgreSQL 14+
- Ethereum Client (Geth / Anvil)

## 下一步优化

- [ ] 支持多种奖励代币
- [ ] 实现自动预算检查和缩放
- [ ] 添加 Prometheus 监控指标
- [ ] 支持活动奖励聚合
- [ ] 集成 Merkle Proof API（供前端查询）
- [ ] 实现定时任务（cron）自动运行
