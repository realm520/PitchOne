# Keeper 集成测试完整指南

## 📋 目录

- [测试概述](#测试概述)
- [环境准备](#环境准备)
- [运行测试](#运行测试)
- [测试场景](#测试场景)
- [故障排查](#故障排查)
- [CI/CD 集成](#cicd-集成)
- [扩展测试](#扩展测试)

---

## 测试概述

### 测试目标

Keeper 集成测试验证以下核心功能：
1. **锁盘流程** - 自动锁定到达 kickoff 时间的市场
2. **结算流程** - 提交比赛结果到预言机（待实现）
3. **错误恢复** - 处理数据库和 RPC 故障
4. **并发处理** - 同时处理多个市场
5. **幂等性** - 避免重复操作

### 测试架构

```
┌─────────────────────────────────────────────────┐
│         Integration Test Process                │
├─────────────────────────────────────────────────┤
│                                                 │
│  1. Start Anvil (Local Blockchain)             │
│  2. Deploy Contracts (Foundry Script)          │
│  3. Setup Database (PostgreSQL)                │
│  4. Start Keeper Service (Go Process)          │
│  5. Manipulate Time (evm_increaseTime)         │
│  6. Verify State (On-chain + Database)         │
│  7. Cleanup                                     │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 测试覆盖

| 测试类别 | 测试数量 | 状态 |
|---------|---------|------|
| 锁盘流程 | 3 | ✅ 完成 |
| 结算流程 | 2 | ⏳ 部分完成 |
| 错误恢复 | 2 | ✅ 完成 |
| **总计** | **7** | **71% 完成** |

---

## 环境准备

### 必需组件

1. **Anvil** - 本地以太坊测试网络
   ```bash
   # 安装 Foundry (包含 Anvil)
   curl -L https://foundry.paradigm.xyz | bash
   foundryup

   # 启动 Anvil
   anvil
   ```

2. **PostgreSQL** - 数据库
   ```bash
   # 使用 Docker Compose
   cd /path/to/PitchOne
   make up

   # 或手动启动 PostgreSQL
   # 确保数据库 'p1' 存在，用户 'p1' 密码 'p1'
   ```

3. **Go 1.21+** - 编程语言
   ```bash
   go version  # 应该 >= 1.21
   ```

4. **Foundry** - 合约部署工具
   ```bash
   forge --version
   ```

### 环境变量

创建 `.env.test` 文件（可选）：
```bash
# Database
DATABASE_URL=postgresql://p1:p1@localhost/p1?sslmode=disable

# Blockchain
RPC_URL=http://localhost:8545
CHAIN_ID=31337

# Keeper Config
TASK_INTERVAL=1
LOCK_LEAD_TIME=3
```

### 部署默认合约

集成测试需要以下合约：
- USDC (模拟稳定币)
- FeeRouter (费用路由)
- SimpleCPMM (CPMM 定价引擎)

```bash
cd ../contracts
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

**固定地址**（阶段 3.7 部署）：
- USDC: `0x36C02dA8a0983159322a80FFE9F24b1acfF8B570`
- FeeRouter: `0x4c5859f0F772848b2D91F1D83E2Fe57935348029`
- SimpleCPMM: `0x1291Be112d480055DaFd8a610b7d1e203891C274`

---

## 运行测试

### 快速启动

使用自动化脚本（推荐）：
```bash
cd backend

# 运行所有锁盘测试
./scripts/run_lock_integration_test.sh

# 该脚本会自动检查：
# ✅ Anvil 是否运行
# ✅ 数据库是否可访问
# ✅ 默认合约是否部署
```

### 使用 Makefile

```bash
cd backend

# 查看所有可用目标
make -f Makefile.integration help

# 运行所有集成测试
make -f Makefile.integration test-integration

# 运行特定类别的测试
make -f Makefile.integration test-integration-lock
make -f Makefile.integration test-integration-settle
make -f Makefile.integration test-integration-error

# 生成覆盖率报告
make -f Makefile.integration test-integration-coverage

# 预检查环境
make -f Makefile.integration test-integration-preflight
```

### 手动运行

```bash
cd backend

# 运行所有集成测试
go test -v -timeout 15m ./internal/keeper -run TestIntegration

# 运行单个测试
go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow$

# 运行特定测试组
go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow
go test -v -timeout 10m ./internal/keeper -run TestIntegration_SettleFlow
go test -v -timeout 5m ./internal/keeper -run TestIntegration_ErrorRecovery

# 带覆盖率
go test -v -timeout 15m -coverprofile=coverage.out ./internal/keeper -run TestIntegration
go tool cover -html=coverage.out -o coverage.html
```

### 调试模式

启用详细日志：
```bash
# 设置日志级别
export KEEPER_LOG_LEVEL=debug

# 运行测试并保存日志
go test -v -timeout 15m ./internal/keeper -run TestIntegration 2>&1 | tee test.log
```

查看 Keeper 日志：
```bash
# 测试会在 /tmp 创建日志文件
tail -f /tmp/keeper_test_*.log
```

---

## 测试场景

### 1. 锁盘流程测试 (TestIntegration_LockFlow)

**测试目标**：验证单个市场的完整锁盘流程

**测试步骤**：
1. 启动 Anvil 和数据库
2. 部署市场合约（kickoff = now + 5s）
3. 将市场插入数据库（状态: Open）
4. 启动 Keeper 服务
5. 推进区块链时间到 kickoff
6. 等待 Keeper 执行锁盘（最多 30 秒）
7. 验证：
   - ✅ 链上状态 = Locked (status=1)
   - ✅ 数据库状态 = "Locked"
   - ✅ `lock_tx_hash` 已设置
   - ✅ `locked_at` 时间戳合理

**预期结果**：✅ PASS

**失败排查**：
- 如果超时未锁定 → 检查 Keeper 日志，确认 LockTask 是否运行
- 如果链上未锁定 → 检查私钥是否正确，Gas 是否足够
- 如果数据库未更新 → 检查 Keeper 的数据库连接

**运行命令**：
```bash
go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow$
```

---

### 2. 多市场并发测试 (TestIntegration_LockFlow_MultipleMarkets)

**测试目标**：验证 Keeper 同时处理多个市场

**测试步骤**：
1. 部署 3 个市场：
   - 市场 A: kickoff = now + 5s
   - 市场 B: kickoff = now + 10s
   - 市场 C: kickoff = now + 15s
2. 启动 Keeper
3. 推进时间到 now + 15s
4. 验证所有市场都被正确锁定

**预期结果**：✅ PASS

**失败排查**：
- 如果某些市场未锁定 → 检查并发限制 (`max_concurrent`)
- 如果锁定顺序错误 → 检查 Keeper 的任务调度逻辑

**运行命令**：
```bash
go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow_MultipleMarkets
```

---

### 3. 幂等性测试 (TestIntegration_LockFlow_Idempotency)

**测试目标**：验证已锁定的市场不会被重复锁定

**测试步骤**：
1. 部署并锁定一个市场
2. 记录初始状态（lock_tx_hash, locked_at）
3. 等待 5 秒
4. 验证状态没有变化

**预期结果**：✅ PASS

**失败排查**：
- 如果状态改变 → LockTask 没有正确检查市场状态
- 如果出现重复交易 → Nonce 管理有问题

**运行命令**：
```bash
go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow_Idempotency
```

---

### 4. 结算流程测试 (TestIntegration_SettleFlow)

**测试目标**：验证完整的结算流程（部分实现）

**测试步骤**：
1. 部署并锁定市场
2. 推进时间到比赛结束
3. 模拟外部预言机提交结果（2-1）
4. 验证 Keeper 提交结果到 UMA（待实现）
5. 验证数据库状态 = "Proposed"（待实现）

**当前状态**：⏳ 部分完成
- ✅ 市场锁定
- ✅ 时间推进
- ✅ 结果模拟
- ⏳ Keeper 提交结果（SettleTask 待实现）

**运行命令**：
```bash
go test -v -timeout 10m ./internal/keeper -run TestIntegration_SettleFlow$
```

---

### 5. 结算时机测试 (TestIntegration_SettleFlow_Timing)

**测试目标**：验证 Keeper 遵守时间约束

**测试规则**：
- ❌ 比赛结束前不应结算
- ✅ 比赛结束后应结算

**运行命令**：
```bash
go test -v -timeout 10m ./internal/keeper -run TestIntegration_SettleFlow_Timing
```

---

### 6. 数据库故障恢复 (TestIntegration_ErrorRecovery_DatabaseFailure)

**测试目标**：验证数据库不可用时的行为

**测试步骤**：
1. 创建 Keeper，使用无效的数据库 URL
2. 验证 Keeper 启动失败
3. 确认错误信息清晰

**预期结果**：✅ PASS - Keeper 快速失败并报错

**运行命令**：
```bash
go test -v -timeout 5m ./internal/keeper -run TestIntegration_ErrorRecovery_DatabaseFailure
```

---

### 7. RPC 故障恢复 (TestIntegration_ErrorRecovery_RPCFailure)

**测试目标**：验证 RPC 不可用时的行为

**测试步骤**：
1. 创建 Keeper，使用无效的 RPC URL
2. 验证 Keeper 启动失败
3. 确认错误信息清晰

**预期结果**：✅ PASS - Keeper 快速失败并报错

**运行命令**：
```bash
go test -v -timeout 5m ./internal/keeper -run TestIntegration_ErrorRecovery_RPCFailure
```

---

## 故障排查

### 常见问题

#### 1. Anvil 未运行

**症状**：
```
Failed to connect to anvil at http://localhost:8545
```

**解决方案**：
```bash
# 检查 Anvil 是否运行
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8545

# 如果没有运行，启动 Anvil
anvil
```

---

#### 2. 数据库连接失败

**症状**：
```
Failed to connect to database: connection refused
```

**解决方案**：
```bash
# 检查数据库是否运行
psql "postgresql://p1:p1@localhost/p1?sslmode=disable" -c "SELECT 1"

# 如果失败，启动数据库
make up

# 或检查连接字符串
export DATABASE_URL=postgresql://p1:p1@localhost/p1?sslmode=disable
```

---

#### 3. 合约未部署

**症状**：
```
Failed to call status(): execution reverted
```

**解决方案**：
```bash
cd ../contracts

# 检查 USDC 合约
cast code 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570 --rpc-url http://localhost:8545

# 如果为空，重新部署
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

---

#### 4. 测试超时

**症状**：
```
panic: test timed out after 10m
```

**可能原因**：
- Keeper 未启动
- 数据库连接慢
- 区块链同步慢

**解决方案**：
```bash
# 增加超时时间
go test -v -timeout 20m ./internal/keeper -run TestIntegration

# 查看 Keeper 日志
export KEEPER_LOG_LEVEL=debug
go test -v ./internal/keeper -run TestIntegration 2>&1 | grep "keeper"
```

---

#### 5. Nonce 冲突

**症状**：
```
nonce too low
```

**解决方案**：
```bash
# 重启 Anvil（会重置所有状态）
pkill anvil
anvil

# 清理测试数据
psql "postgresql://p1:p1@localhost/p1?sslmode=disable" <<EOF
DELETE FROM markets WHERE event_id LIKE 'TEST_%';
DELETE FROM keeper_tasks WHERE task_name LIKE 'TEST_%';
EOF
```

---

#### 6. 编译错误

**症状**：
```
cannot find package "github.com/..."
```

**解决方案**：
```bash
# 更新依赖
go mod tidy
go mod download

# 重新编译
go build ./...
```

---

## CI/CD 集成

### GitHub Actions 示例

创建 `.github/workflows/integration-tests.yml`：

```yaml
name: Integration Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  integration-tests:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: p1
          POSTGRES_PASSWORD: p1
          POSTGRES_DB: p1
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Start Anvil
        run: |
          anvil --port 8545 &
          sleep 5

      - name: Deploy Contracts
        run: |
          cd contracts
          forge script script/Deploy.s.sol:Deploy \
            --rpc-url http://localhost:8545 \
            --broadcast --silent

      - name: Run Database Migrations
        run: |
          cd backend
          psql $DATABASE_URL -f pkg/db/schema.sql
        env:
          DATABASE_URL: postgresql://p1:p1@localhost:5432/p1?sslmode=disable

      - name: Run Integration Tests
        run: |
          cd backend
          make -f Makefile.integration test-integration-coverage
        env:
          DATABASE_URL: postgresql://p1:p1@localhost:5432/p1?sslmode=disable

      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage_integration.out
          flags: integration
```

---

## 扩展测试

### 添加新测试

1. **创建测试文件**
   ```bash
   cd backend/internal/keeper
   touch my_new_test_integration_test.go
   ```

2. **编写测试**
   ```go
   package keeper_test

   import (
       "testing"
       "github.com/stretchr/testify/require"
       "github.com/pitchone/sportsbook/internal/keeper/testutil"
   )

   func TestIntegration_MyNewFeature(t *testing.T) {
       if testing.Short() {
           t.Skip("skipping integration test")
       }

       // Setup
       anvil, _ := testutil.StartAnvil(context.Background())
       defer anvil.Stop()

       // Test logic...

       // Assertions
       require.NoError(t, err)
   }
   ```

3. **运行测试**
   ```bash
   go test -v ./internal/keeper -run TestIntegration_MyNewFeature
   ```

### 性能测试

添加基准测试：
```go
func BenchmarkIntegration_LockFlow(b *testing.B) {
    // Setup once
    anvil, _ := testutil.StartAnvil(context.Background())
    defer anvil.Stop()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        // Run test
    }
}
```

运行：
```bash
go test -bench=BenchmarkIntegration -benchmem ./internal/keeper
```

---

## 最佳实践

### 1. 测试隔离

- ✅ 每个测试使用独立的市场
- ✅ 使用 `CleanupTestData()` 清理
- ✅ 使用 EVM 快照隔离状态

### 2. 时间控制

- ✅ 使用 `AdvanceToTime()` 而非 `time.Sleep()`
- ✅ 验证时间戳的相对关系，而非绝对值
- ✅ 考虑时区和区块时间差异

### 3. 错误处理

- ✅ 使用 `require` 立即失败
- ✅ 使用 `assert` 继续测试
- ✅ 提供清晰的错误消息

### 4. 日志记录

- ✅ 使用 `t.Log()` 记录关键步骤
- ✅ 使用 `t.Logf()` 格式化输出
- ✅ 保存日志文件用于调试

### 5. 资源清理

- ✅ 使用 `defer` 确保清理
- ✅ 关闭所有打开的连接
- ✅ 停止后台进程

---

## 附录

### A. 测试文件结构

```
backend/
├── internal/keeper/
│   ├── lock_integration_test.go      # 锁盘流程测试
│   ├── settle_integration_test.go    # 结算流程测试
│   └── testutil/                     # 测试辅助工具
│       ├── anvil.go                  # Anvil 管理
│       ├── time_control.go           # 时间控制
│       ├── database.go               # 数据库操作
│       ├── contracts.go              # 合约交互
│       └── assertions.go             # 自定义断言
├── scripts/
│   └── run_lock_integration_test.sh  # 自动化脚本
├── Makefile.integration              # Make 目标
└── docs/
    ├── INTEGRATION_TEST_GUIDE.md     # 本文档
    └── STAGE_4_2_INTEGRATION_TESTS_SUMMARY.md
```

### B. 环境变量参考

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DATABASE_URL` | `postgresql://p1:p1@localhost/p1?sslmode=disable` | 数据库连接 |
| `RPC_URL` | `http://localhost:8545` | Anvil RPC |
| `CHAIN_ID` | `31337` | Anvil Chain ID |
| `KEEPER_LOG_LEVEL` | `info` | 日志级别 |
| `TASK_INTERVAL` | `1` | 任务间隔（秒） |
| `LOCK_LEAD_TIME` | `3` | 提前锁盘时间（秒） |

### C. 有用的命令

```bash
# 查看所有测试
go test -list . ./internal/keeper

# 只编译不运行
go test -c ./internal/keeper

# 运行特定测试并生成 CPU profile
go test -cpuprofile=cpu.prof -run TestIntegration_LockFlow ./internal/keeper

# 分析 profile
go tool pprof cpu.prof

# 查看测试覆盖率（按函数）
go test -coverprofile=coverage.out ./internal/keeper
go tool cover -func=coverage.out

# 交互式覆盖率（浏览器）
go tool cover -html=coverage.out
```

---

## 联系和支持

- **文档**: `docs/` 目录
- **问题追踪**: GitHub Issues
- **讨论**: GitHub Discussions

---

**最后更新**: 2025-10-30
**版本**: v1.0
**作者**: PitchOne Team
