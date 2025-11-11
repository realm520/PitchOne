# Rewards Scheduler Service

**自动化周度奖励分发服务** - 定时聚合奖励、生成 Merkle 树并发布到链上。

---

## 🎯 功能

- ⏰ **定时任务**：每周日 23:59 自动执行奖励聚合和发布
- 🔍 **健康检查**：每天检查是否有失败的任务
- 🛡️ **错误恢复**：Panic 恢复机制，避免服务崩溃
- 📊 **完整日志**：详细记录每个步骤的执行情况
- 🧪 **测试模式**：支持立即执行一次（用于测试）

---

## 🚀 快速开始

### 1. 配置环境变量

```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/pitchone"
export RPC_URL="https://sepolia.infura.io/v3/YOUR-API-KEY"
export REWARDS_DISTRIBUTOR_ADDR="0x..."  # RewardsDistributor 合约地址
export PRIVATE_KEY="0x..."  # 签名私钥（⚠️ 生产环境使用 KMS）
```

### 2. 测试模式（立即执行一次）

```bash
cd backend
go run ./cmd/scheduler --test
```

输出示例：
```
🧪 Test mode: running weekly rewards task once
✅ Connected to database
✅ Connected to blockchain
🕒 Starting weekly rewards task for week 45
📊 Aggregating rewards for week 45...
✅ Aggregated 123 reward entries in 1.2s
🌳 Building Merkle tree...
✅ Merkle Root: 0x7c8b9e...
   Recipients: 123
   Total Amount: 12345000000
   Scale: 10000 bps (100.00%)
✅ Distribution saved to database
📤 Publishing to blockchain...
✅ Transaction sent: 0xabcd1234...
⏳ Waiting for confirmation...
✅ Transaction confirmed in block 5123456
   Gas used: 124523
✅ Root verified on-chain
🎉 Weekly rewards for week 45 completed successfully!
✅ Test run completed successfully
```

### 3. 生产模式（后台运行）

```bash
# 使用默认 Cron 表达式（每周日 23:59）
go run ./cmd/scheduler

# 自定义 Cron 表达式（每分钟执行一次，用于开发测试）
go run ./cmd/scheduler --cron "0 * * * * *"

# 仅聚合数据，不发布到链上
unset RPC_URL REWARDS_DISTRIBUTOR_ADDR PRIVATE_KEY
go run ./cmd/scheduler
```

### 4. 使用 Docker 运行

```bash
docker build -t pitchone-scheduler -f backend/cmd/scheduler/Dockerfile .
docker run -d \
  --name scheduler \
  -e DATABASE_URL="postgresql://..." \
  -e RPC_URL="https://..." \
  -e REWARDS_DISTRIBUTOR_ADDR="0x..." \
  -e PRIVATE_KEY="0x..." \
  pitchone-scheduler
```

---

## 📝 命令行参数

| 参数 | 环境变量 | 默认值 | 说明 |
|------|---------|--------|------|
| `--db` | `DATABASE_URL` | - | Postgres 连接串（必需） |
| `--rpc-url` | `RPC_URL` | - | Ethereum RPC URL |
| `--distributor` | `REWARDS_DISTRIBUTOR_ADDR` | - | RewardsDistributor 合约地址 |
| `--private-key` | `PRIVATE_KEY` | - | 签名私钥 |
| `--test` | - | false | 测试模式：立即执行一次后退出 |
| `--cron` | - | `0 59 23 * * 0` | Cron 表达式（秒 分 时 日 月 周） |

---

## ⏰ Cron 表达式说明

格式：`秒 分 时 日 月 周`

常用示例：
```bash
# 每周日 23:59:00（生产环境推荐）
--cron "0 59 23 * * 0"

# 每天凌晨 2:00:00
--cron "0 0 2 * * *"

# 每小时执行一次（开发测试）
--cron "0 0 * * * *"

# 每分钟执行一次（快速测试）
--cron "0 * * * * *"

# 每 10 秒执行一次（调试）
--cron "*/10 * * * * *"
```

---

## 🔄 工作流程

```
定时触发 (每周日 23:59)
    ↓
1. 检查上周是否已发布
   - 已发布 → 跳过
   - 未发布 → 继续
    ↓
2. 聚合本周奖励数据
   - 推荐返佣（8% 手续费）
   - 交易奖励（交易量 × 0.1%）
   - Quest 完成奖励
   - Campaign 参与奖励
    ↓
3. 生成 Merkle 树
   - 构建平衡二叉树
   - 生成每个用户的 Proof
    ↓
4. 保存到数据库
   - reward_distributions 表
    ↓
5. 发布到链上（可选）
   - 调用 RewardsDistributor.publishRoot()
   - 等待 3 个区块确认
   - 验证链上数据
    ↓
6. 记录成功日志
   - TODO: 发送 Slack/Discord 通知
```

---

## 📊 监控与告警

### 日志级别

```
🕒  开始任务
📊  聚合数据
🌳  构建 Merkle 树
✅  操作成功
⚠️   警告信息
❌  错误/失败
🎉  任务完成
```

### 健康检查

每天 00:05 自动检查最近 4 周是否有未发布的周：

```
🔍 Checking for failed tasks...
⚠️  Week 42 appears to be missing - consider manual intervention
```

### 失败处理

1. **Panic 恢复**：服务不会崩溃，会记录错误并继续运行
2. **错误日志**：所有错误都会记录到 stdout
3. **TODO**：集成 Slack/Discord 告警

---

## 🧪 测试

### 单元测试

```bash
cd backend
go test ./cmd/scheduler/... -v
```

### 集成测试

```bash
# 1. 启动本地测试环境
docker-compose up -d postgres
anvil

# 2. 部署合约
cd contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# 3. 运行 Scheduler 测试模式
cd ../backend
export DATABASE_URL="postgresql://localhost/pitchone_test"
export RPC_URL="http://localhost:8545"
export REWARDS_DISTRIBUTOR_ADDR="0x..."  # 从部署输出获取
go run ./cmd/scheduler --test
```

---

## 🐛 故障排查

### 问题1：数据库连接失败

```
❌ Failed to connect to database: dial tcp: connection refused
```

**解决方案**：
```bash
# 检查数据库是否运行
docker-compose ps

# 检查连接串格式
echo $DATABASE_URL
# 应该是: postgresql://user:pass@host:port/database
```

### 问题2：周已发布，跳过

```
⚠️  Week 45 already processed (root: 0x7c8b...), skipping
```

**原因**：该周已经发布过，防止重复发布。

**如需重新发布**（谨慎操作）：
```sql
DELETE FROM reward_distributions WHERE week = 45;
```

### 问题3：交易失败

```
❌ Transaction failed: insufficient funds for gas
```

**解决方案**：
```bash
# 检查账户余额
cast balance 0xYourAddress --rpc-url $RPC_URL

# 调整 Gas Price（在 publisher.go 中配置）
```

### 问题4：Root 验证失败

```
❌ Root mismatch! Expected 0xabc..., got 0xdef...
```

**原因**：链上数据与本地计算不一致，可能是并发发布或合约 Bug。

**解决方案**：
```bash
# 检查链上数据
cast call $DISTRIBUTOR "weeklyRewards(uint256)(bytes32,uint256,uint256,uint256,uint256)" 45 --rpc-url $RPC_URL
```

---

## 🔐 安全建议

### 1. 私钥管理

**❌ 不要硬编码私钥！**

**生产环境推荐方案**：

#### 方案 A：AWS KMS
```go
import "github.com/aws/aws-sdk-go/service/kms"

func getPrivateKeyFromKMS() (string, error) {
    // 从 KMS 解密私钥
}
```

#### 方案 B：HashiCorp Vault
```bash
vault kv get secret/ethereum/rewards-signer
```

#### 方案 C：环境变量 + Secret Manager
```bash
# Kubernetes Secret
kubectl create secret generic rewards-signer \
  --from-literal=private-key=0x...
```

### 2. 权限控制

- 使用**专用账户**签名交易（不要用部署账户）
- 该账户**仅授权** `PUBLISHER_ROLE`
- 定期轮换私钥

### 3. 监控告警

```bash
# 推荐监控指标
- 任务执行成功率
- 每周聚合的奖励总额
- Merkle 树生成耗时
- 链上交易 Gas 消耗
- 数据库查询性能
```

---

## 📦 部署

### Systemd 服务（Linux）

创建 `/etc/systemd/system/pitchone-scheduler.service`：

```ini
[Unit]
Description=PitchOne Rewards Scheduler
After=network.target postgresql.service

[Service]
Type=simple
User=pitchone
WorkingDirectory=/opt/pitchone
ExecStart=/opt/pitchone/scheduler
Restart=always
RestartSec=10

Environment="DATABASE_URL=postgresql://..."
Environment="RPC_URL=https://..."
Environment="REWARDS_DISTRIBUTOR_ADDR=0x..."
EnvironmentFile=/etc/pitchone/scheduler.env

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable pitchone-scheduler
sudo systemctl start pitchone-scheduler

# 查看日志
sudo journalctl -u pitchone-scheduler -f
```

### Docker Compose

参见 `docker-compose.yml`（稍后创建）

### Kubernetes CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: rewards-scheduler
spec:
  schedule: "59 23 * * 0"  # 每周日 23:59
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scheduler
            image: pitchone/scheduler:latest
            env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
            - name: PRIVATE_KEY
              valueFrom:
                secretKeyRef:
                  name: rewards-signer
                  key: private-key
          restartPolicy: OnFailure
```

---

## 📈 下一步优化

- [ ] 集成 Slack/Discord 告警通知
- [ ] 添加 Prometheus 监控指标
- [ ] 实现自动预算检查和缩放（从 PayoutScaler 合约读取）
- [ ] 支持多链部署
- [ ] 添加 Grafana 仪表盘
- [ ] 实现重试机制（交易失败时自动重试 3 次）
- [ ] 支持 Merkle Proof API（供前端查询）

---

## 🤝 贡献

由 Claude Code 协助开发 🤖

项目地址：[PitchOne Sportsbook](https://github.com/pitchone/sportsbook)
