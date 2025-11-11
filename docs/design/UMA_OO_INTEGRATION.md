# UMA Optimistic Oracle 集成指南

## 概述

本项目使用 **UMA Optimistic Oracle V3 (OOV3)** 作为去中心化的比赛结果仲裁机制。UMA OO 提供了一个乐观式（optimistic）的结果提交和争议解决流程，大幅降低了链上交互成本，同时保持了去中心化的安全性。

### 为什么选择 UMA Optimistic Oracle？

1. **成本优化**：乐观式机制意味着大部分情况下（无争议）只需 2 次链上交互
2. **去中心化仲裁**：任何人都可以提交结果或发起争议，由 UMA DVM 最终仲裁
3. **经济激励对齐**：质押和惩罚机制确保提交正确结果的经济动机
4. **灵活可扩展**：支持任意复杂的数据结构和验证逻辑

---

## 架构设计

### 整体流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Match Lifecycle                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Market Open │────▶│ Market Locked│────▶│Match Finished│
└──────────────┘     └──────────────┘     └──────────────┘
      │                     │                      │
      │ Users bet           │ Match starts         │ Result available
      ▼                     ▼                      ▼
┌──────────────────────────────────────────────────────────────────┐
│                    UMA Optimistic Oracle Flow                     │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 1. Keeper Proposes│
                    │   proposeResult() │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ 2. Liveness Period│
                    │   (2 hours)       │
                    └──────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
        No Dispute                    Dispute Raised
                │                           │
                ▼                           ▼
        ┌──────────────┐           ┌──────────────┐
        │3. Auto-settle│           │ 3. DVM Vote  │
        │   (Accepted) │           │   (48 hours) │
        └──────────────┘           └──────────────┘
                │                           │
                │                    ┌──────┴──────┐
                │                    │             │
                │              Proposer Wins   Disputer Wins
                │                    │             │
                │                    ▼             ▼
                └───────────▶ ┌──────────┐  ┌──────────┐
                              │ Accepted │  │ Rejected │
                              └──────────┘  └──────────┘
                                    │             │
                                    ▼             │
                         ┌──────────────────┐    │
                         │4. Keeper Resolves│    │
                         │  Market          │    │
                         └──────────────────┘    │
                                    │             │
                                    ▼             │
                         ┌──────────────────┐    │
                         │5. Users Redeem   │    │
                         │   Winnings       │    │
                         └──────────────────┘    │
                                                  │
                                         Need Re-proposal
```

### 核心组件

#### 1. UMAOptimisticOracleAdapter.sol

**职责**：将 UMA OOV3 适配为项目的 `IResultOracle` 接口

**关键功能**：
- `proposeResult(marketId, facts)` - 提交比赛结果并创建 UMA 断言
- `disputeAssertion(marketId, reason)` - 对结果发起争议
- `settleAssertion(marketId)` - 结算 liveness 期结束后的断言
- `getResult(marketId)` - 获取结果（支持 pending/finalized 状态）
- `isFinalized(marketId)` - 检查结果是否已最终确认

**核心数据结构**：
```solidity
struct MatchFacts {
    bytes32 scope;         // 比赛范围: "FT_90" / "FT_120" / "Penalties"
    uint8 homeGoals;       // 主队进球数
    uint8 awayGoals;       // 客队进球数
    bool extraTime;        // 是否有加时赛
    uint8 penaltiesHome;   // 主队点球进球数（如适用）
    uint8 penaltiesAway;   // 客队点球进球数（如适用）
    uint256 reportedAt;    // 报告时间戳
}
```

#### 2. Keeper Service (settle_task_uma.go)

**职责**：自动化 UMA 流程的链下服务

**关键功能**：
- 监控已锁定且比赛结束的市场
- 从数据源（Sportradar）获取比赛结果
- 调用 `proposeResult()` 提交结果到 UMA
- （可选）调用 `settleAssertion()` 在 liveness 期结束后结算
- 调用 `resolveFromOracle()` 解析市场

**工作流程**：
```go
// 1. 查询待结算市场
markets := getMarketsToSettle(ctx)

// 2. 并行处理
for market := range markets {
    // 2.1 获取结果
    result := fetchMatchResult(market.EventID)

    // 2.2 提交到 UMA
    proposeResultToUMA(market, result)
}

// 3. 等待 liveness (2 hours)
// ... (可以是定时任务或事件监听)

// 4. 结算断言
for market := range proposedMarkets {
    settleAssertion(market)
}

// 5. 解析市场
for market := range settledMarkets {
    resolveFromOracle(market)
}
```

---

## 部署指南

### 1. 合约部署

#### Step 1: 部署 UMA Adapter

```bash
# 设置环境变量
export PRIVATE_KEY=0x...
export RPC_URL=https://...
export UMA_OO_ADDRESS=0x...  # UMA OOV3 合约地址（链特定）
export BOND_CURRENCY=0x...   # 质押币种（通常是 USDC）
export BOND_AMOUNT=1000000000  # 质押金额（1000 USDC，6 decimals）

# 运行部署脚本
forge script script/DeployWithUMAOracle.s.sol:DeployWithUMAOracle \
    --rpc-url $RPC_URL \
    --broadcast \
    -vvvv
```

**部署参数说明**：
- `BOND_AMOUNT`: 提交结果和争议都需要质押的金额（推荐 1000 USDC）
- `LIVENESS`: 争议窗口时长（推荐 7200 秒 = 2 小时）
- `IDENTIFIER`: DVM 标识符（使用 `ASSERT_TRUTH`）

#### Step 2: 设置市场预言机

```solidity
// 为市场设置 UMA Adapter 作为结果预言机
market.setResultOracle(address(umaAdapter));
```

### 2. Keeper 部署

#### Step 1: 生成 Go Bindings

```bash
# 编译合约
forge build

# 提取 ABI 和 Bytecode
cat ./out/UMAOptimisticOracleAdapter.sol/UMAOptimisticOracleAdapter.json | \
    jq '.abi' > /tmp/uma_adapter_abi.json

cat ./out/UMAOptimisticOracleAdapter.sol/UMAOptimisticOracleAdapter.json | \
    jq -r '.bytecode.object' > /tmp/uma_adapter_bin.txt

# 生成 Go bindings
abigen --abi /tmp/uma_adapter_abi.json \
       --bin /tmp/uma_adapter_bin.txt \
       --pkg bindings \
       --type UMAAdapter \
       --out backend/pkg/bindings/uma_adapter.go
```

#### Step 2: 配置 Keeper

```yaml
# backend/configs/keeper.yaml
keeper:
  # UMA 相关配置
  uma_mode: true  # 启用 UMA 模式

  # 任务调度
  tasks:
    settle_uma:
      cron: "*/10 * * * *"  # 每 10 分钟检查一次
      enabled: true

    lock:
      cron: "*/5 * * * *"   # 每 5 分钟检查锁盘
      enabled: true

  # Gas 配置
  gas_limit: 500000
  max_gas_price: 50000000000  # 50 Gwei

  # 并发配置
  max_concurrent: 3  # 最多同时处理 3 个市场
```

#### Step 3: 启动 Keeper

```bash
cd backend

# 方式 1: 直接运行
go run ./cmd/keeper

# 方式 2: 使用 Docker
docker-compose up keeper

# 方式 3: 使用 systemd (生产环境)
sudo systemctl start pitchone-keeper
```

---

## 使用示例

### 场景 1: 无争议的正常流程

```solidity
// 1. 用户下注
market.placeBet(0, 1000e6); // Bet 1000 USDC on Home win

// 2. Keeper 锁盘（开赛时）
market.lock();

// 3. 比赛结束，Keeper 提交结果
IResultOracle.MatchFacts memory facts = IResultOracle.MatchFacts({
    scope: bytes32("FT_90"),
    homeGoals: 2,
    awayGoals: 1,
    extraTime: false,
    penaltiesHome: 0,
    penaltiesAway: 0,
    reportedAt: block.timestamp
});

bytes32 marketId = bytes32(uint256(uint160(address(market))));
umaAdapter.proposeResult(marketId, facts);

// 4. 等待 liveness 期（2 小时）
// ... no disputes ...

// 5. Keeper 结算断言
umaAdapter.settleAssertion(marketId);

// 6. Keeper 解析市场
market.resolveFromOracle();

// 7. 用户兑付
market.redeem(0, shares);  // 赢家兑付
```

### 场景 2: 有争议的流程

```solidity
// 1-3. 同上，Keeper 提交结果
umaAdapter.proposeResult(marketId, facts);

// 4. 用户在 liveness 期内发起争议
umaAdapter.disputeAssertion(marketId, "Score is incorrect");

// 5. 等待 UMA DVM 投票（48 小时）
// ... DVM voting ...

// 6a. 如果提议者正确（DVM 批准断言）
//     → umaAdapter.isFinalized(marketId) 返回 true
//     → Keeper 可以调用 market.resolveFromOracle()

// 6b. 如果争议者正确（DVM 拒绝断言）
//     → umaAdapter.isFinalized(marketId) 返回 false
//     → 市场无法解析，需要重新提交正确结果
```

### 场景 3: 并行处理多个市场

```go
// Keeper 代码
markets := []MarketToSettle{market1, market2, market3}

// 使用 Worker Pool 并行提交
for _, market := range markets {
    go func(m *MarketToSettle) {
        result := fetchMatchResult(m.EventID)
        proposeResultToUMA(m, result)
    }(market)
}
```

---

## 安全考虑

### 1. 质押管理

**问题**：提交结果需要质押 BOND_AMOUNT 的 bondCurrency
**解决方案**：
- Keeper 账户需要预先持有足够的 bondCurrency（推荐至少 10,000 USDC）
- 实施自动充值机制
- 监控账户余额并在低于阈值时告警

```go
// 检查余额
balance := bondCurrency.BalanceOf(keeper.account)
if balance.Cmp(minBalance) < 0 {
    alert.Send("Keeper bond balance low: %s", balance.String())
}
```

### 2. 争议处理

**问题**：恶意争议可能导致结算延迟
**解决方案**：
- 使用高质量数据源（如 Sportradar）确保结果准确性
- 实施结果验证逻辑（多数据源交叉验证）
- 监控争议事件并及时人工介入

```solidity
// 监听争议事件
event ResultDisputed(
    bytes32 indexed marketId,
    bytes32 indexed factsHash,
    address indexed disputer,
    string reason
);

// Keeper 监控
if dispute detected {
    log.Warn("Dispute raised for market %s: %s", marketId, reason)
    notify.Admin("Manual review required")
}
```

### 3. DVM 投票结果处理

**问题**：DVM 可能拒绝提议的结果
**解决方案**：
- 实施自动重试机制（使用正确结果）
- 记录所有 DVM 决策用于数据分析
- 对于连续失败的提案，暂停自动化并人工介入

```go
// 处理 DVM 拒绝
if assertion.settlementResolution == false {
    log.Error("Assertion rejected by DVM for market %s", marketId)

    // 选项 1: 自动重试（如果有更准确的数据源）
    correctResult := fetchFromSecondarySource(eventID)
    proposeResult(marketId, correctResult)

    // 选项 2: 暂停自动化
    pauseAutomation(marketId)
    notifyAdmin("Manual intervention required")
}
```

### 4. Gas 价格优化

**问题**：高 Gas 价格可能导致成本过高
**解决方案**：
- 设置 `maxGasPrice` 上限
- 在 Gas 价格高峰期延迟非紧急操作
- 批量处理多个市场的结算

```go
// Gas 价格检查
gasPrice := getGasPrice()
if gasPrice.Cmp(maxGasPrice) > 0 {
    log.Warn("Gas price too high: %s, delaying settlement", gasPrice)
    return ErrGasPriceTooHigh
}
```

---

## 监控指标

### 关键指标

| 指标 | 描述 | 告警阈值 |
|------|------|---------|
| `proposal_success_rate` | 提案成功率 | < 95% |
| `dispute_rate` | 争议发生率 | > 5% |
| `settlement_latency` | 结算延迟（从比赛结束到市场解析） | > 3 hours |
| `keeper_balance` | Keeper 账户余额 | < 5000 USDC |
| `gas_cost_per_proposal` | 每次提案的 Gas 成本 | > 0.1 ETH |
| `dvm_rejection_rate` | DVM 拒绝率 | > 1% |

### Prometheus 指标示例

```go
// keeper/metrics.go
var (
    proposalTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "keeper_uma_proposals_total",
            Help: "Total number of UMA proposals submitted",
        },
        []string{"status"}, // success, failed
    )

    disputeTotal = prometheus.NewCounter(
        prometheus.CounterOpts{
            Name: "keeper_uma_disputes_total",
            Help: "Total number of disputes raised",
        },
    )

    settlementDuration = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name: "keeper_uma_settlement_duration_seconds",
            Help: "Time from match end to market resolution",
            Buckets: []float64{60, 300, 600, 1800, 3600, 7200},
        },
    )
)
```

---

## 故障排查

### 常见问题

#### 1. "Insufficient bond allowance"

**原因**：Keeper 账户没有授权足够的 bondCurrency 给 UMA OOV3 合约

**解决**：
```bash
# 手动授权
cast send $BOND_CURRENCY \
    "approve(address,uint256)" \
    $UMA_OO_ADDRESS \
    $(cast max-uint256) \
    --private-key $PRIVATE_KEY
```

#### 2. "Assertion already exists"

**原因**：该市场已经有活跃的断言

**解决**：
```solidity
// 检查是否已有断言
bytes32 existingAssertion = umaAdapter.marketAssertions(marketId);
if (existingAssertion != bytes32(0)) {
    // 等待该断言结算
    if (umaAdapter.canSettle(marketId)) {
        umaAdapter.settleAssertion(marketId);
    }
}
```

#### 3. "Result not finalized"

**原因**：尝试在结果最终确认前解析市场

**解决**：
```solidity
// 检查是否已最终确认
require(oracleAdapter.isFinalized(marketId), "Result not finalized");

// 或者等待
while (!oracleAdapter.isFinalized(marketId)) {
    sleep(60); // 等待 1 分钟
}
```

#### 4. "Liveness period not expired"

**原因**：尝试在 liveness 期结束前结算断言

**解决**：
```solidity
// 检查是否可以结算
if (umaAdapter.canSettle(marketId)) {
    umaAdapter.settleAssertion(marketId);
} else {
    // 等待 liveness 期结束
    Assertion memory assertion = umaAdapter.getAssertionDetails(marketId);
    uint256 waitTime = assertion.expirationTime - block.timestamp;
    log("Need to wait %d seconds", waitTime);
}
```

---

## 测试

### 单元测试

```bash
# 运行 UMA Adapter 单元测试
forge test --match-path "test/unit/UMAOptimisticOracleAdapter.t.sol" -vv

# 运行集成测试
forge test --match-path "test/integration/UMAMarketIntegration.t.sol" -vv

# 运行端到端测试
forge test --match-path "test/integration/KeeperUMAIntegration.t.sol" -vv
```

### 本地测试流程

```bash
# 1. 启动本地 Anvil 链
anvil

# 2. 部署合约
forge script script/DeployWithUMAOracle.s.sol --rpc-url http://localhost:8545 --broadcast

# 3. 启动 Keeper
cd backend && go run ./cmd/keeper

# 4. 模拟比赛结束
cast send $MARKET_ADDRESS "lock()" --private-key $PRIVATE_KEY

# 5. 观察 Keeper 自动提交结果
# ... logs ...

# 6. 加速时间（Anvil 专用）
cast rpc evm_increaseTime 7200  # 前进 2 小时

# 7. 观察 Keeper 自动结算
# ... logs ...
```

---

## 参考资料

### UMA 官方文档
- [UMA Optimistic Oracle V3 Overview](https://docs.uma.xyz/protocol-overview/how-does-umas-oracle-work)
- [OOV3 Integration Guide](https://docs.uma.xyz/developers/optimistic-oracle-v3)
- [Assertion Lifecycle](https://docs.uma.xyz/developers/optimistic-oracle-v3/assertion-lifecycle)

### 项目相关文档
- [合约架构设计](./design/03_ResultOracle_OO.md)
- [Keeper 实现指南](./operations/keeper-guide.md)
- [Keeper 配置示例](../backend/configs/keeper.example.yaml)

### 代码引用
- UMA Adapter 合约: [`contracts/src/oracle/UMAOptimisticOracleAdapter.sol`](../contracts/src/oracle/UMAOptimisticOracleAdapter.sol)
- Keeper UMA Task: [`backend/internal/keeper/settle_task_uma.go`](../backend/internal/keeper/settle_task_uma.go)
- Go Bindings: [`backend/pkg/bindings/uma_adapter.go`](../backend/pkg/bindings/uma_adapter.go)

---

## 附录

### A. UMA OOV3 合约地址（主网/测试网）

| 网络 | UMA OOV3 地址 | Bond Currency (USDC) |
|------|--------------|---------------------|
| Ethereum Mainnet | `0x...` | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| Sepolia Testnet | `0x...` | `0x...` |
| Polygon | `0x...` | `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174` |
| Arbitrum One | `0x...` | `0xaf88d065e77c8cC2239327C5EDb3A432268e5831` |

**注意**：请访问 [UMA Docs - Contract Addresses](https://docs.uma.xyz/resources/network-addresses) 获取最新地址。

### B. Gas 成本估算

| 操作 | Gas 消耗 | 成本估算 (30 Gwei) |
|------|---------|-------------------|
| `proposeResult()` | ~200,000 | ~0.006 ETH |
| `disputeAssertion()` | ~150,000 | ~0.0045 ETH |
| `settleAssertion()` | ~100,000 | ~0.003 ETH |
| `resolveFromOracle()` | ~80,000 | ~0.0024 ETH |

**总成本**（无争议流程）：约 0.012 ETH per market

### C. 经济模型

**质押要求**：
- 提议者：1000 USDC
- 争议者：1000 USDC

**激励机制**：
- 无争议：提议者取回 1000 USDC
- 争议（提议者胜）：提议者获得 2000 USDC（含争议者质押）
- 争议（争议者胜）：争议者获得 2000 USDC（含提议者质押）

**Keeper 运营成本**（每月，假设 1000 个市场）：
- Gas 成本：1000 × 0.012 ETH = 12 ETH
- 质押资金：1000 USDC（循环使用）
- 基础设施：约 $100-200（服务器、监控）

---

## 更新日志

- **2025-11-01**: 初始版本，完整 UMA OO 集成指南
- **待更新**: 主网部署后的实际地址和性能数据

