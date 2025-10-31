# SettleTask Implementation Guide

## 概述

SettleTask 是 Keeper 服务的核心组件之一，负责在足球比赛结束后自动获取比赛结果并通过 UMA Optimistic Oracle 提交到链上。本文档详细说明了 SettleTask 的实现架构、配置方法和使用指南。

### 实现状态

**✅ 已完成的核心功能（v1.0.0）**：
- ✅ Sportradar API 集成（含速率限制）
- ✅ Mock Provider（测试/开发环境）
- ✅ Worker Pool 并发处理
- ✅ Scheduler 集成和任务注册
- ✅ 结构化日志记录（zap）
- ✅ 优雅的错误处理和重试
- ✅ 数据库事务和状态更新
- ✅ Web3 交易签名和确认
- ✅ 完整的单元测试和集成测试

**🔄 计划中的功能**：
- ⏳ Prometheus 指标导出
- ⏳ 自定义告警系统（Telegram/Email/PagerDuty）
- ⏳ 高级 Nonce Manager（当前通过并发度控制避免冲突）
- ⏳ 分布式锁（多 Keeper 实例协调）
- ⏳ 结果缓存（避免重复 API 调用）
- ⏳ Gas 价格预测和动态调整

## 核心架构

### 1. 数据源集成

SettleTask 使用可插拔的数据源架构，通过 `ResultProvider` 接口支持多种数据源：

```go
type ResultProvider interface {
    GetMatchResult(ctx context.Context, eventID string) (*MatchResult, error)
}
```

#### 支持的数据源

**Sportradar API（生产环境）**
- 官方体育数据提供商，支持全球主流足球赛事
- 实时比赛数据和最终比分
- 内置速率限制（免费版：1 请求/秒）
- 自动重试和错误处理

**Mock Provider（测试/开发环境）**
- 可配置的模拟数据源
- 支持自定义比赛结果
- 可模拟 API 延迟和错误场景
- 无需外部 API 依赖

### 2. Worker Pool 并发处理

为提高处理效率，SettleTask 实现了 Worker Pool 模式：

```
┌─────────────┐
│ SettleTask  │
│   Execute() │
└──────┬──────┘
       │
       ├──> getMarketsToSettle()  // 查询需要结算的市场
       │
       └──> processMarketsParallel()
            │
            ├──> Worker 1 ──┐
            ├──> Worker 2 ──┤ 并发处理
            └──> Worker N ──┘
```

**特性**：
- 可配置的并发度（通过 `MaxConcurrent` 参数）
- 任务队列和结果收集
- 优雅的错误处理（单个市场失败不影响其他市场）
- 详细的日志记录（每个 Worker 独立跟踪）

### 3. 核心流程

```mermaid
sequenceDiagram
    participant S as Scheduler
    participant ST as SettleTask
    participant DS as DataSource
    participant BC as Blockchain
    participant DB as Database

    S->>ST: Execute() 定时触发
    ST->>DB: getMarketsToSettle()
    DB-->>ST: 返回 Locked 状态市场列表

    loop 并发处理每个市场
        ST->>DS: fetchMatchResult(eventID)
        DS-->>ST: 返回比赛结果
        ST->>BC: proposeResult() via UMA OO
        BC-->>ST: 交易哈希
        ST->>BC: 等待交易确认
        BC-->>ST: Receipt
        ST->>DB: updateMarketStatus()
    end

    ST-->>S: 完成
```

## 环境配置

### 必需环境变量

```bash
# Ethereum RPC 端点
export RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"

# 部署账户私钥（用于提交预言机结果）
export PRIVATE_KEY="0x..."

# 数据库连接
export DATABASE_URL="postgresql://user:password@localhost:5432/sportsbook?sslmode=disable"
```

### 可选环境变量

```bash
# Sportradar API Key（生产环境必需）
export SPORTRADAR_API_KEY="your_api_key_here"

# Sportradar Base URL（可选，默认使用试用版 API）
export SPORTRADAR_BASE_URL="https://api.sportradar.com/soccer/trial/v4/en"
```

**数据源选择逻辑**：
- 如果设置了 `SPORTRADAR_API_KEY`：使用 Sportradar 客户端
- 否则：使用 Mock Provider（开发/测试模式）

### Keeper 配置参数

在 `Config` 结构中配置以下参数：

```go
type Config struct {
    // 基础配置
    ChainID          int64  // 链 ID
    RPCEndpoint      string // RPC 端点
    PrivateKey       string // 私钥
    DatabaseURL      string // 数据库连接串

    // Gas 配置
    GasLimit         uint64 // Gas 限制（默认 500000）
    MaxGasPrice      string // 最大 Gas 价格（Gwei，默认 "100"）

    // 任务调度配置
    TaskInterval     int    // 任务执行间隔（秒，默认 60）
    FinalizeDelay    int    // 比赛结束到结算的延迟（秒，默认 7200 = 2小时）

    // 并发配置
    MaxConcurrent    int    // 最大并发数（默认 10）

    // 重试配置
    RetryAttempts    int    // 重试次数（默认 3）
    RetryDelay       int    // 重试延迟（秒，默认 5）

    // 监控配置
    HealthCheckPort  int    // 健康检查端口（默认 8081）
    MetricsPort      int    // Prometheus 指标端口（默认 9091）
    AlertsEnabled    bool   // 是否启用告警
}
```

### 配置示例

**开发环境**（使用 Mock 数据源）：
```yaml
chain_id: 31337  # Anvil 本地链
rpc_endpoint: "http://localhost:8545"
private_key: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
database_url: "postgresql://p1:p1@localhost/p1?sslmode=disable"
gas_limit: 500000
max_gas_price: "100"
task_interval: 60
finalize_delay: 300     # 5分钟（测试用）
max_concurrent: 3
retry_attempts: 3
retry_delay: 5
health_check_port: 8081
metrics_port: 9091
alerts_enabled: false
```

**生产环境**（使用 Sportradar）：
```yaml
chain_id: 1  # Ethereum 主网
rpc_endpoint: "https://mainnet.infura.io/v3/YOUR_KEY"
private_key: "${KEEPER_PRIVATE_KEY}"  # 从环境变量读取
database_url: "${DATABASE_URL}"
gas_limit: 500000
max_gas_price: "50"
task_interval: 60
finalize_delay: 7200    # 2小时
max_concurrent: 10
retry_attempts: 5
retry_delay: 10
health_check_port: 8081
metrics_port: 9091
alerts_enabled: true
```

## 部署指南

### 1. 获取 Sportradar API Key

1. 访问 [Sportradar Developer Portal](https://developer.sportradar.com/)
2. 注册账号并创建应用
3. 选择 Soccer API（足球 API）
4. 获取 API Key（免费版限制：1 请求/秒，1000 请求/月）

### 2. 数据库准备

确保数据库 Schema 包含以下表和字段：

```sql
CREATE TABLE markets (
    market_address VARCHAR(42) PRIMARY KEY,
    event_id VARCHAR(255) NOT NULL,
    match_start BIGINT NOT NULL,
    match_end BIGINT,
    oracle_address VARCHAR(42) NOT NULL,
    status VARCHAR(20) NOT NULL,  -- Open, Locked, Proposed, Resolved, Finalized
    settle_tx_hash VARCHAR(66),
    home_goals INT,
    away_goals INT,
    settled_at BIGINT,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

CREATE INDEX idx_markets_status ON markets(status);
CREATE INDEX idx_markets_match_end ON markets(match_end);
```

### 3. 启动 Keeper 服务

```bash
# 设置环境变量
export SPORTRADAR_API_KEY="your_api_key"
export RPC_URL="https://mainnet.infura.io/v3/YOUR_KEY"
export PRIVATE_KEY="0x..."
export DATABASE_URL="postgresql://..."

# 构建并启动
cd backend
go build -o bin/keeper ./cmd/keeper
./bin/keeper --config config.yaml
```

### 4. 验证运行状态

```bash
# 健康检查（当前返回基本状态）
curl http://localhost:8081/health
# 示例响应：
# {
#   "healthy": true,
#   "version": "0.1.0",
#   "database": "ok",
#   "web3": "ok"
# }

# 查看日志（主要验证方式）
tail -f logs/keeper.log

# 或使用 systemd
journalctl -u keeper -f

# 或使用 Docker
docker logs -f keeper

# 查看任务执行日志
journalctl -u keeper -f | grep '"msg":"executing settle task"'

# 监控 Worker Pool 活动
journalctl -u keeper -f | grep '"worker_id"'
```

**注意**：
- 健康检查端口（8081）提供基本健康状态
- Prometheus 指标端口（9091）当前为占位实现
- 主要通过结构化日志来监控系统状态
- 未来版本将实现完整的 Prometheus 指标导出

## 监控和告警

### 当前实现状态

**✅ 已实现**：
- 结构化日志记录（使用 zap）
- 详细的执行过程追踪（Worker Pool、市场结算、交易确认）
- 错误日志和堆栈跟踪
- 任务级别的日志隔离（每个 Worker 独立跟踪）

**⚠️ 计划中**（未来实现）：
- Prometheus 指标导出
- 自定义告警系统集成
- 性能指标仪表盘

### 关键日志示例

SettleTask 当前记录以下结构化日志：

**执行日志**：
```json
{"level":"info","msg":"executing settle task"}
{"level":"info","msg":"found markets to settle","count":5}
{"level":"info","msg":"starting worker pool for parallel settlement","num_workers":3,"num_markets":5}
```

**Worker 日志**：
```json
{"level":"debug","msg":"worker started","worker_id":0}
{"level":"debug","msg":"worker processing market","worker_id":0,"market":"0x...","event_id":"sr:match:12345"}
{"level":"info","msg":"worker settlement succeeded","worker_id":0,"market":"0x..."}
{"level":"error","msg":"worker settlement failed","worker_id":1,"market":"0x...","error":"..."}
{"level":"debug","msg":"worker finished","worker_id":0,"processed":2}
```

**数据源日志**：
```json
{"level":"debug","msg":"fetching match result from Sportradar","event_id":"sr:match:12345"}
{"level":"info","msg":"match result fetched","event_id":"sr:match:12345","home_goals":2,"away_goals":1,"fetch_duration":"150ms"}
{"level":"info","msg":"Sportradar API request completed","event_id":"sr:match:12345","duration":"152ms","status":"closed","match_status":"ended"}
```

**链上交易日志**：
```json
{"level":"info","msg":"propose transaction sent","market":"0x...","txHash":"0x...","nonce":42,"gasPrice":"5000000000"}
{"level":"info","msg":"propose transaction confirmed","market":"0x...","txHash":"0x...","blockNumber":12345678,"gasUsed":150000}
```

**数据库更新日志**：
```json
{"level":"debug","msg":"updated market status in database","market":"0x...","status":"Proposed","txHash":"0x..."}
{"level":"error","msg":"failed to update market status in database","market":"0x...","error":"no market found with address 0x..."}
```

### 未来的指标规划

当实现 Prometheus 集成时，将导出以下指标：

**执行指标**（计划）：
- `settle_task_executed_total`: 总执行次数
- `settle_task_markets_found`: 发现的待结算市场数
- `settle_task_markets_succeeded`: 成功结算的市场数
- `settle_task_markets_failed`: 失败的市场数
- `settle_task_duration_seconds`: 执行耗时

**数据源指标**（计划）：
- `sportradar_api_calls_total`: API 调用总数
- `sportradar_api_errors_total`: API 错误总数
- `sportradar_api_duration_seconds`: API 响应时间

**链上指标**（计划）：
- `propose_tx_sent_total`: 提交的预言机提案数
- `propose_tx_confirmed_total`: 确认的提案数
- `propose_tx_failed_total`: 失败的提案数
- `propose_gas_used`: Gas 消耗

### 日志级别和调试

当前可以通过设置 `LOG_LEVEL` 环境变量调整日志级别：

```bash
# 调试模式（详细日志）
export LOG_LEVEL=debug
./bin/keeper --config config.yaml

# 生产模式（仅重要信息）
export LOG_LEVEL=info  # 默认
./bin/keeper --config config.yaml
```

**日志级别说明**：
- `debug`: 包含 Worker 详细追踪、API 请求细节、数据库操作
- `info`: 任务执行、市场结算、交易确认等关键事件
- `warn`: 任务重试、非致命错误
- `error`: 严重错误、需要人工介入的问题

### 未来的告警规则示例（Prometheus）

当实现 Prometheus 集成时，可使用以下告警规则：

```yaml
# Prometheus 告警规则（计划中）
groups:
  - name: settle_task
    rules:
      - alert: SettleTaskHighFailureRate
        expr: rate(settle_task_markets_failed[5m]) / rate(settle_task_markets_found[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "SettleTask failure rate > 10%"

      - alert: SportradarAPIDown
        expr: rate(sportradar_api_errors_total[5m]) > 0.5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Sportradar API error rate > 50%"

      - alert: SettleTaskStuck
        expr: time() - settle_task_last_execution_timestamp > 300
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "SettleTask has not executed for 5+ minutes"
```

## 故障排查

### 常见问题

#### 1. Sportradar API 返回 401 Unauthorized

**原因**：API Key 无效或未设置

**解决方案**：
```bash
# 检查环境变量
echo $SPORTRADAR_API_KEY

# 验证 API Key
curl "https://api.sportradar.com/soccer/trial/v4/en/sport_events/sr:match:12345/summary.json?api_key=$SPORTRADAR_API_KEY"
```

#### 2. Rate Limit 错误（429 Too Many Requests）

**原因**：超过 Sportradar 免费版限制（1 请求/秒）

**解决方案**：
- 减少 `MaxConcurrent` 配置（降低并发度）
- 升级 Sportradar 套餐
- 实现更智能的请求批处理

#### 3. 交易失败（Gas 不足或 Nonce 冲突）

**原因**：
- Gas 价格设置过低，交易未被打包
- 并发提交导致 Nonce 冲突

**解决方案**：
```yaml
# 调整 Gas 配置
max_gas_price: "100"  # 提高最大 Gas 价格

# 降低并发度
max_concurrent: 3     # 减少同时提交的交易数
```

#### 4. 数据库连接池耗尽

**原因**：Worker Pool 并发度过高

**解决方案**：
```go
// 调整数据库连接池配置
db.SetMaxOpenConns(25)   // 最大连接数
db.SetMaxIdleConns(5)    // 最大空闲连接数
db.SetConnMaxLifetime(5 * time.Minute)
```

### 日志查看和分析

**实时查看日志**：
```bash
# Docker 容器
docker logs -f keeper

# Kubernetes
kubectl logs -f deployment/keeper

# systemd 服务
journalctl -u keeper -f

# 本地运行
tail -f logs/keeper.log
```

**日志过滤**：
```bash
# 仅查看错误日志
journalctl -u keeper -f | grep '"level":"error"'

# 查看特定市场的结算日志
journalctl -u keeper -f | grep '"market":"0x..."'

# 查看 Worker Pool 活动
journalctl -u keeper -f | grep '"worker_id"'
```

## 测试指南

### 单元测试

```bash
# 运行所有 SettleTask 测试
go test ./internal/keeper -run TestSettleTask -v

# 运行特定测试
go test ./internal/keeper -run TestSettleTask_FetchMatchResult -v

# 查看覆盖率
go test ./internal/keeper -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### 集成测试

使用本地 Anvil 链进行集成测试：

```bash
# 终端 1：启动 Anvil
anvil

# 终端 2：部署测试合约
cd contracts
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# 终端 3：启动 Keeper（测试模式）
cd backend
export RPC_URL="http://localhost:8545"
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export DATABASE_URL="postgresql://p1:p1@localhost/p1?sslmode=disable"
go run ./cmd/keeper --config test_config.yaml
```

### Mock 数据源测试

```go
// 在测试中使用 Mock Provider
mockProvider := datasource.NewMockResultProvider()

// 配置特定赛事的结果
mockProvider.AddResult("sr:match:12345", &datasource.MatchResult{
    HomeGoals: 2,
    AwayGoals: 1,
    ExtraTime: false,
    HomeWin:   true,
    AwayWin:   false,
    Draw:      false,
})

// 模拟 API 延迟
mockProvider.SetDelay(500 * time.Millisecond)

// 模拟 API 错误
mockProvider.SetError(fmt.Errorf("API temporarily unavailable"))

// 创建 SettleTask 使用 Mock
task := NewSettleTask(keeper, mockProvider)
```

## 性能优化

### 1. 并发度调优

根据以下因素调整 `MaxConcurrent`：

- **数据库连接池大小**：确保 `MaxConcurrent <= db.MaxOpenConns`
- **RPC 节点限制**：避免超过 RPC 提供商的速率限制
- **Sportradar API 限制**：免费版 1 请求/秒
- **系统资源**：CPU 和内存容量

**推荐配置**：
```yaml
# 开发环境
max_concurrent: 3

# 生产环境（付费 Sportradar）
max_concurrent: 10

# 生产环境（免费 Sportradar）
max_concurrent: 1  # 严格遵守 1 req/s 限制
```

### 2. 数据库查询优化

确保以下索引存在：
```sql
CREATE INDEX idx_markets_status_match_end ON markets(status, match_end);
```

### 3. 缓存策略

考虑实现以下缓存：
- 比赛结果缓存（避免重复 API 调用）
- Gas 价格缓存（减少 RPC 调用）
- 市场状态缓存（降低数据库负载）

## 扩展和定制

### 添加新的数据源

实现 `ResultProvider` 接口：

```go
type CustomProvider struct {
    // 自定义字段
}

func (p *CustomProvider) GetMatchResult(ctx context.Context, eventID string) (*MatchResult, error) {
    // 实现获取比赛结果逻辑
    return &MatchResult{
        HomeGoals: ...,
        AwayGoals: ...,
        // ...
    }, nil
}

// 在 Keeper 初始化中注册
dataSource = &CustomProvider{...}
```

### 自定义告警（未来扩展）

当前通过结构化日志记录所有重要事件。未来可以添加告警系统集成：

```go
// 在 processMarketsParallel() 中添加告警逻辑
if len(errors) > 0 {
    // 发送告警到 Telegram/Email/Webhook
    alertSystem.SendAlert(Alert{
        Severity: "warning",
        Message:  fmt.Sprintf("Settlement failed for %d markets", len(errors)),
        Details:  errors,
    })
}

// 在 fetchMatchResult() 中添加 API 错误告警
if err != nil && isRateLimitError(err) {
    alertSystem.SendAlert(Alert{
        Severity: "critical",
        Message:  "Sportradar API rate limit exceeded",
        Details:  err,
    })
}
```

**推荐的告警集成方案**：
1. **Telegram Bot**：即时通知到运维团队
2. **PagerDuty**：自动化事件响应
3. **Slack Webhook**：团队协作通知
4. **Email（SMTP）**：批量报告和摘要

## 最佳实践

1. **监控告警**：配置 Prometheus + Grafana + Alertmanager
2. **日志聚合**：使用 ELK 或 Loki 收集和分析日志
3. **密钥管理**：使用 HashiCorp Vault 或 AWS Secrets Manager
4. **冗余部署**：运行多个 Keeper 实例（带分布式锁）
5. **灾难恢复**：定期备份数据库，测试恢复流程
6. **成本控制**：监控 Gas 消耗，使用 Gas 价格预测工具

## 参考资料

- [Sportradar API 文档](https://developer.sportradar.com/soccer/reference)
- [UMA Optimistic Oracle 文档](https://docs.uma.xyz/protocol/concepts/optimistic-oracle)
- [Go Context 最佳实践](https://go.dev/blog/context)
- [Worker Pool 模式详解](https://gobyexample.com/worker-pools)

## 测试验证

### 测试结果（2025-10-31）

所有核心功能测试通过 ✅：

```bash
# 运行测试
go test ./internal/keeper -v -timeout 3m

# 测试结果摘要
=== RUN   TestSettleTask_GetMarketsToSettle
--- PASS: TestSettleTask_GetMarketsToSettle (0.01s)

=== RUN   TestSettleTask_SettleMarket
--- PASS: TestSettleTask_SettleMarket (2.06s)
    --- PASS: TestSettleTask_SettleMarket/handles_invalid_market_address (0.01s)
    --- PASS: TestSettleTask_SettleMarket/handles_invalid_oracle_address (0.01s)
    --- PASS: TestSettleTask_SettleMarket/handles_connection_errors_gracefully (2.03s)

=== RUN   TestSettleTask_Execute
--- PASS: TestSettleTask_Execute (0.01s)

=== RUN   TestSettleTask_FetchMatchResult
--- PASS: TestSettleTask_FetchMatchResult (0.01s)

=== RUN   TestSettleTask_UpdateMarketStatus
--- PASS: TestSettleTask_UpdateMarketStatus (0.01s)

# 所有 Keeper 测试
PASS
ok  	github.com/pitchone/sportsbook/internal/keeper	14.850s
```

**测试覆盖**：
- ✅ 数据源集成（Sportradar + Mock）
- ✅ Worker Pool 并发处理
- ✅ 市场查询和筛选
- ✅ 比赛结果获取
- ✅ 链上交易提交和确认
- ✅ 数据库状态更新
- ✅ 错误处理和边界情况
- ✅ Scheduler 集成

### 已知限制

1. **Nonce 管理**：当前通过 `MaxConcurrent` 限制并发度来避免 Nonce 冲突，未实现高级 Nonce Manager
2. **指标导出**：Prometheus 指标接口为占位实现，未导出实际指标
3. **告警系统**：依赖日志记录，未集成 Telegram/Email/PagerDuty 等告警通道
4. **结果缓存**：每次都从数据源获取，未实现结果缓存
5. **Gas 优化**：使用固定 Gas 价格上限，未实现动态 Gas 价格预测

这些限制在当前版本不影响核心功能，可在未来版本中逐步优化。

## 版本历史

- **v1.0.0** (2025-10-31)
  - ✅ 初始实现
  - ✅ Sportradar 集成（含速率限制）
  - ✅ Worker Pool 并发处理（可配置并发度）
  - ✅ Mock Provider 测试支持
  - ✅ Scheduler 集成和任务注册
  - ✅ 结构化日志记录（zap）
  - ✅ 完整的单元测试和集成测试
  - ✅ 错误处理和重试机制
  - ✅ 数据库事务管理
