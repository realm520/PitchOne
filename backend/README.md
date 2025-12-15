# PitchOne Backend Services

去中心化体育预测平台的链下服务层，包含事件索引、自动化任务执行和奖励分发。

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    Backend Services                      │
├──────────────┬──────────────┬──────────────┬───────────┤
│   Indexer    │    Keeper    │   Rewards    │   Risk    │
│  (事件索引)   │  (自动化任务)  │  (奖励分发)   │ (风控工人)  │
└──────┬───────┴──────┬───────┴──────┬───────┴─────┬─────┘
       │              │              │             │
       v              v              v             v
┌──────────────────────────────────────────────────────────┐
│                  Shared Infrastructure                    │
├───────────────────┬───────────────────┬──────────────────┤
│   PostgreSQL      │   Ethereum Node   │   The Graph      │
│  (数据持久化)       │    (链上交互)       │  (Subgraph)     │
└───────────────────┴───────────────────┴──────────────────┘
```

## 服务组件

### 1. Indexer（事件索引器）

**职责**：订阅合约事件，解析并写入数据库

**目录**：`cmd/indexer/`

**核心功能**：
- 实时订阅合约事件（WebSocket）
- 历史事件回放和同步
- 事件解析和结构化存储
- 断点续传和容错处理

**启动命令**：
```bash
go run ./cmd/indexer --config config.yaml
```

### 2. Keeper（自动化任务执行器）

**职责**：执行定时任务和链上操作

**目录**：`cmd/keeper/`

**核心功能**：
- **LockTask**: 开赛前锁盘（禁止新下注）
- **SettleTask**: 赛后获取结果并提交预言机
- **Scheduler**: 任务调度和生命周期管理

**文档**：详见 [SettleTask 实现指南](docs/SETTLE_TASK_IMPLEMENTATION.md)

**启动命令**：
```bash
# 开发模式（使用 Mock 数据源）
go run ./cmd/keeper --config config.yaml

# 生产模式（使用 Sportradar）
export SPORTRADAR_API_KEY="your_api_key"
go run ./cmd/keeper --config config.yaml
```

### 3. Rewards Builder（奖励生成器）

**职责**：周度奖励聚合和 Merkle 树生成

**目录**：`cmd/rewards/`

**核心功能**：
- 推荐返佣计算
- 任务奖励聚合
- Merkle 树生成和 Root 发布
- Proof 生成供用户领取

**启动命令**：
```bash
go run ./cmd/rewards --config config.yaml --week 1
```

### 4. Risk Worker（风控工人，计划中）

**职责**：实时风险评估和参数调整

**核心功能**：
- OU/AH 联动参数计算
- 串关相关性矩阵更新
- 单地址敞口监控
- 自动参数调整

## 快速开始

### 前置要求

- Go 1.24+
- PostgreSQL 14+
- Docker & Docker Compose（可选）
- Ethereum RPC 节点（Infura/Alchemy 或本地 Anvil）

### 本地开发环境

#### 1. 启动基础设施

```bash
# 从项目根目录
cd PitchOne

# 启动数据库和其他基础设施
make up

# 查看服务状态
docker-compose ps
```

这会启动：
- PostgreSQL（端口 5432）
- TimescaleDB 扩展
- Grafana（端口 3000）
- Redis（端口 6379）

#### 2. 运行数据库迁移

```bash
# 创建 Schema 和表
make db-migrate

# 或手动运行
psql $DATABASE_URL -f migrations/001_initial_schema.sql
```

#### 3. 启动本地测试链

```bash
# 终端 1：启动 Anvil
make chain

# 终端 2：部署合约
cd contracts
make deploy-local
```

#### 4. 启动后端服务

```bash
cd backend

# 方式 1：使用 make（推荐）
make run-keeper

# 方式 2：直接运行
export DATABASE_URL="postgresql://p1:p1@localhost:5432/p1?sslmode=disable"
export RPC_URL="http://localhost:8545"
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
go run ./cmd/keeper --config configs/keeper.example.yaml
```

### 配置管理

#### 配置文件

```bash
# 复制示例配置
cp configs/keeper.example.yaml configs/keeper.yaml

# 编辑配置
vim configs/keeper.yaml
```

#### 环境变量

**必需**：
```bash
export RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0x..."
export DATABASE_URL="postgresql://user:password@localhost:5432/sportsbook"
```

**可选**（Keeper 相关）：
```bash
# Sportradar 数据源（生产环境）
export SPORTRADAR_API_KEY="your_api_key"
export SPORTRADAR_BASE_URL="https://api.sportradar.com/soccer/trial/v4/en"

# 日志级别
export LOG_LEVEL="debug"
```

**数据源选择逻辑**：
- 如果设置了 `SPORTRADAR_API_KEY`：使用 Sportradar API
- 否则：使用 Mock Provider（开发/测试模式）

## 测试

### 单元测试

```bash
# 运行所有测试
go test ./...

# 运行特定包的测试
go test ./internal/keeper -v

# 查看覆盖率
go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### 集成测试

```bash
# 确保 Anvil 和数据库已启动
make test-integration
```

### SettleTask 专项测试

```bash
# 运行所有 SettleTask 测试
go test ./internal/keeper -run TestSettleTask -v

# 测试数据源集成
go test ./internal/datasource -v
```

## 部署

### Docker 构建

```bash
# 构建 Keeper 镜像
docker build -t pitchone/keeper:latest -f Dockerfile.keeper .

# 运行容器
docker run -d \
  --name keeper \
  -e RPC_URL=$RPC_URL \
  -e PRIVATE_KEY=$PRIVATE_KEY \
  -e DATABASE_URL=$DATABASE_URL \
  -e SPORTRADAR_API_KEY=$SPORTRADAR_API_KEY \
  -p 8081:8081 \
  -p 9091:9091 \
  pitchone/keeper:latest
```

### Kubernetes 部署

```bash
# 应用配置
kubectl apply -f k8s/keeper-deployment.yaml
kubectl apply -f k8s/keeper-service.yaml

# 查看状态
kubectl get pods -l app=keeper
kubectl logs -f deployment/keeper
```

### 生产环境检查清单

- [ ] 已设置所有必需环境变量
- [ ] 已配置 Sportradar API Key（生产环境）
- [ ] 已调整 Gas 配置（`max_gas_price`）
- [ ] 已配置数据库连接池（`max_open_conns >= max_concurrent + 15`）
- [ ] 已设置监控和告警（Prometheus + Grafana + Alertmanager）
- [ ] 已配置日志聚合（ELK/Loki）
- [ ] 已测试灾难恢复流程
- [ ] 已配置密钥管理（Vault/Secrets Manager）
- [ ] 已启用冗余部署（多 Keeper 实例 + 分布式锁）

## 监控和运维

### 健康检查

```bash
# Keeper 健康检查
curl http://localhost:8081/health

# 响应示例
{
  "healthy": true,
  "version": "0.1.0",
  "database": "ok",
  "web3": "ok"
}
```

### Prometheus 指标

```bash
# 查看所有指标
curl http://localhost:9091/metrics

# 关键指标
settle_task_executed_total
settle_task_markets_succeeded
settle_task_markets_failed
sportradar_api_calls_total
propose_tx_confirmed_total
```

### 日志查看

```bash
# Docker 日志
docker logs -f keeper

# Kubernetes 日志
kubectl logs -f deployment/keeper

# 本地日志
tail -f logs/keeper.log
```

### Grafana 仪表盘

访问 http://localhost:3000（默认用户名/密码：admin/admin）

导入预配置的仪表盘：
- `grafana/dashboards/keeper-overview.json`
- `grafana/dashboards/settle-task-metrics.json`

## 故障排查

### 常见问题

#### Keeper 无法启动

**症状**：启动后立即退出

**排查步骤**：
```bash
# 检查配置文件
./bin/keeper --config config.yaml --validate

# 检查数据库连接
psql $DATABASE_URL -c "SELECT 1"

# 检查 RPC 连接
curl -X POST $RPC_URL \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

#### SettleTask 失败

**症状**：市场未结算或结算失败

**排查步骤**：
```bash
# 查看 Keeper 日志
grep "settle_task" logs/keeper.log

# 检查 Sportradar API
curl "https://api.sportradar.com/soccer/trial/v4/en/sport_events/sr:match:12345/summary.json?api_key=$SPORTRADAR_API_KEY"

# 查看数据库状态
psql $DATABASE_URL -c "SELECT market_address, status, match_end FROM markets WHERE status = 'Locked' LIMIT 10"
```

#### Gas 价格过高

**症状**：交易长时间未确认或失败

**解决方案**：
```yaml
# 调整配置
max_gas_price: "100"  # 提高到 100 Gwei
```

#### Nonce 冲突

**症状**：交易失败，错误信息包含 "nonce too low"

**解决方案**：
```yaml
# 降低并发度
max_concurrent: 3
```

更多故障排查指南：详见 [SettleTask 实现指南](docs/SETTLE_TASK_IMPLEMENTATION.md#故障排查)

## 项目结构

```
backend/
├── cmd/                          # 可执行程序入口
│   ├── indexer/                  # 事件索引器
│   ├── keeper/                   # 自动化任务执行器
│   └── rewards/                  # 奖励生成器
│
├── internal/                     # 内部包（不对外暴露）
│   ├── indexer/                  # Indexer 核心逻辑
│   ├── keeper/                   # Keeper 核心逻辑
│   │   ├── keeper.go             # Keeper 主体
│   │   ├── scheduler.go          # 任务调度器
│   │   ├── lock_task.go          # 锁盘任务
│   │   ├── settle_task.go        # 结算任务（含 Worker Pool）
│   │   ├── web3_client.go        # Web3 客户端
│   │   └── *_test.go             # 单元测试
│   ├── datasource/               # 数据源集成
│   │   └── sportradar.go         # Sportradar 客户端 + Mock
│   ├── rewards/                  # 奖励生成逻辑
│   └── common/                   # 共享工具
│
├── pkg/                          # 可对外使用的包
│   └── bindings/                 # 合约 Go Bindings
│
├── configs/                      # 配置文件
│   └── keeper.example.yaml       # Keeper 配置示例
│
├── docs/                         # 文档
│   └── SETTLE_TASK_IMPLEMENTATION.md  # SettleTask 详细文档
│
├── migrations/                   # 数据库迁移脚本
├── scripts/                      # 运维脚本
├── go.mod                        # Go 模块定义
└── go.sum                        # 依赖校验和
```

## 开发指南

### 代码规范

- 遵循 Go 官方代码风格
- 使用 `gofmt` 和 `golangci-lint` 进行格式化和检查
- 所有公开函数和类型必须有文档注释
- 关键操作必须记录日志（使用 `zap`）
- 所有错误必须被正确处理和传播

### 添加新任务

1. 在 `internal/keeper/` 创建新文件（如 `my_task.go`）
2. 实现 `Task` 接口：
   ```go
   type Task interface {
       Execute(ctx context.Context) error
   }
   ```
3. 在 `keeper.go` 的 `runTaskScheduler()` 中注册：
   ```go
   myTask := NewMyTask(k)
   scheduler.RegisterTask("my_task", myTask, interval)
   ```
4. 添加单元测试（`my_task_test.go`）

### 数据库迁移

```bash
# 创建新迁移
./scripts/create_migration.sh add_new_table

# 应用迁移
make db-migrate

# 回滚最后一次迁移
make db-rollback
```

## 性能优化

### Keeper 性能调优

- **并发度**：根据数据库连接池和 RPC 限制调整 `max_concurrent`
- **批处理**：合并多个小任务为批量操作
- **缓存**：使用 Redis 缓存热点数据（市场状态、Gas 价格）
- **索引**：确保数据库关键字段有索引（`status`, `match_end`）

### 资源监控

```bash
# CPU 和内存使用
docker stats keeper

# Go 运行时指标
curl http://localhost:9091/metrics | grep go_
```

## 安全考虑

- **私钥管理**：生产环境使用 Vault/Secrets Manager
- **权限控制**：Keeper 账户仅需提案权限，无需治理权限
- **速率限制**：防止 API 滥用和 DoS 攻击
- **输入验证**：严格验证所有外部输入（API 响应、数据库数据）
- **错误处理**：避免泄露敏感信息到日志或错误消息

## 贡献指南

1. Fork 项目
2. 创建特性分支（`git checkout -b feature/amazing-feature`）
3. 提交更改（`git commit -m 'Add amazing feature'`）
4. 推送到分支（`git push origin feature/amazing-feature`）
5. 创建 Pull Request

## 许可证

MIT License

## 联系方式

- 项目主页：https://github.com/pitchone/sportsbook
- 问题反馈：https://github.com/pitchone/sportsbook/issues
- 文档：https://docs.pitchone.io

## 相关资源

- [合约代码](../contracts/)
- [Subgraph](../subgraph/)
- [前端应用](../frontend/)
- [系统设计文档](../docs/design/)
- [接口与事件规范](../docs/模块接口事件参数/EVENT_DICTIONARY.md)
