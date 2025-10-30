# Keeper Service

Keeper 服务是 PitchOne 博彩平台的链下自动化服务，负责执行定时任务：

- **锁盘任务（Lock Task）**：在比赛开始前锁定市场，停止下注
- **结算任务（Settle Task）**：比赛结束后，向预言机提交结果并触发结算

## 功能特性

- ✅ 任务调度系统（Scheduler）
- ✅ 自动重试机制（指数退避）
- ✅ 优雅关闭（Graceful Shutdown）
- ✅ 配置文件 + 环境变量支持
- ✅ 结构化日志（zap）
- 🚧 健康检查端点（TODO）
- 🚧 Prometheus 指标（TODO）
- 🚧 告警系统（TODO）

## 快速开始

### 1. 配置

复制示例配置文件：

```bash
cd backend
cp config.example.yaml config.yaml
```

编辑 `config.yaml` 并填入你的值：

```yaml
keeper:
  chain_id: 31337  # 本地测试链
  rpc_endpoint: "http://localhost:8545"
  private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
  database_url: "postgresql://p1:p1@localhost:5432/p1?sslmode=disable"
```

### 2. 构建

```bash
# 方式 1：使用 go build
go build -o bin/keeper ./cmd/keeper

# 方式 2：使用启动脚本（会自动构建）
./scripts/run_keeper.sh
```

### 3. 运行

```bash
# 直接运行二进制
./bin/keeper

# 或使用启动脚本
./scripts/run_keeper.sh
```

### 4. 使用环境变量（可选）

你可以完全使用环境变量而不创建配置文件：

```bash
export SPORTSBOOK_KEEPER_CHAIN_ID=31337
export SPORTSBOOK_KEEPER_RPC_ENDPOINT="http://localhost:8545"
export SPORTSBOOK_KEEPER_PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export SPORTSBOOK_KEEPER_DATABASE_URL="postgresql://p1:p1@localhost:5432/p1?sslmode=disable"

./bin/keeper
```

## 配置参数

### 必需配置

| 参数 | 环境变量 | 说明 |
|------|----------|------|
| `keeper.chain_id` | `SPORTSBOOK_KEEPER_CHAIN_ID` | 链 ID（1=主网, 31337=本地） |
| `keeper.rpc_endpoint` | `SPORTSBOOK_KEEPER_RPC_ENDPOINT` | 以太坊 RPC 端点 |
| `keeper.private_key` | `SPORTSBOOK_KEEPER_PRIVATE_KEY` | Keeper 操作员私钥（带 0x 前缀） |
| `keeper.database_url` | `SPORTSBOOK_KEEPER_DATABASE_URL` | PostgreSQL 连接字符串 |

### 可选配置（带默认值）

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `keeper.gas_limit` | `500000` | Gas 限制 |
| `keeper.max_gas_price` | `100` | 最大 Gas 价格（Gwei） |
| `keeper.task_interval` | `60` | 任务执行间隔（秒） |
| `keeper.lock_lead_time` | `300` | 提前锁盘时间（秒，5 分钟） |
| `keeper.finalize_delay` | `7200` | 结算延迟（秒，2 小时） |
| `keeper.max_concurrent` | `10` | 最大并发操作数 |
| `keeper.retry_attempts` | `3` | 重试次数 |
| `keeper.retry_delay` | `5` | 重试延迟（秒） |
| `keeper.health_check_port` | `8080` | 健康检查端口 |
| `keeper.metrics_port` | `9090` | Prometheus 指标端口 |

## 任务说明

### 锁盘任务（Lock Task）

- **执行时机**：比赛开始前 N 分钟（由 `lock_lead_time` 配置）
- **操作**：
  1. 查询数据库中即将开始的市场
  2. 调用合约的 `lock()` 方法锁定市场
  3. 更新数据库状态为 `Locked`

### 结算任务（Settle Task）

- **执行时机**：比赛结束后 N 小时（由 `finalize_delay` 配置）
- **操作**：
  1. 查询数据库中已结束待结算的市场
  2. 从数据源获取比赛结果（目前使用 Mock 数据）
  3. 调用预言机的 `proposeResult()` 方法提交结果
  4. 等待交易确认并更新数据库状态为 `Proposed`

## 架构说明

```
main.go
├── 初始化日志（zap）
├── 加载配置（viper）
├── 创建 Keeper 实例
├── 创建 Scheduler
├── 注册任务
│   ├── Lock Task
│   └── Settle Task
├── 启动调度器
└── 等待信号（优雅关闭）
```

## 日志

日志使用 [zap](https://github.com/uber-go/zap) 结构化日志库：

```json
{
  "level": "info",
  "ts": 1698765432.123,
  "caller": "keeper/scheduler.go:48",
  "msg": "registering task",
  "name": "lock",
  "interval": "1m0s"
}
```

日志级别：`debug`, `info`, `warn`, `error`

## 开发

### 运行测试

```bash
# 运行所有测试
go test ./...

# 运行特定测试
go test -v ./internal/keeper -run TestSettleTask

# 运行测试并查看覆盖率
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### 代码格式化

```bash
go fmt ./...
```

## 故障排查

### 1. "failed to connect to database"

- 检查 PostgreSQL 是否运行：`psql -U p1 -d p1 -c "SELECT 1"`
- 检查连接字符串是否正确
- 检查网络连接和防火墙

### 2. "failed to connect to RPC"

- 检查 RPC 端点是否可访问：`curl http://localhost:8545`
- 如果使用 Anvil，确保已启动：`anvil`

### 3. "invalid private key"

- 确保私钥格式正确（带 0x 前缀）
- 确保私钥对应的账户有足够的 ETH 支付 Gas

### 4. "transaction failed"

- 检查账户余额是否足够
- 检查 Gas 价格设置是否合理
- 查看交易哈希并在区块浏览器中检查失败原因

## 生产部署

### Docker

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o keeper ./cmd/keeper

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/keeper /usr/local/bin/
CMD ["keeper"]
```

### Kubernetes

参考 `deploy/k8s/keeper-deployment.yaml`（TODO）

### 监控

- 健康检查：`GET http://localhost:8080/health`（TODO）
- Prometheus 指标：`GET http://localhost:9090/metrics`（TODO）

## 待实现功能

- [ ] 健康检查端点
- [ ] Prometheus 指标导出
- [ ] 告警系统集成
- [ ] 真实数据源集成（替换 Mock）
- [ ] 争议窗口监控和处理
- [ ] 周度 Merkle 根发布任务
- [ ] 速率限制和节流
- [ ] 交易池监控和 Gas 优化
