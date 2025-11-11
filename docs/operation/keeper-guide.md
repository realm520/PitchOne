# Keeper 操作指南

## 概述

Keeper 是自动化机器人，负责在特定时间触发市场的关键操作。PitchOne 系统设计为**去中心化 + Keeper 辅助**的混合模式。

## Keeper 权限设计

### ✅ Keeper 可以调用的函数

#### 1. `autoLock()` - 自动锁盘
```solidity
// WDL_Template.sol:235
function autoLock() external {
    require(block.timestamp >= kickoffTime - 5 minutes, "WDL: Too early to lock");
    require(status == MarketStatus.Open, "WDL: Market not open");

    status = MarketStatus.Locked;
    lockTimestamp = block.timestamp;
    emit Locked(block.timestamp);
}
```

**特点**:
- ✅ **无权限限制** - 任何人都可以调用（包括 Keeper）
- ✅ **去中心化** - 如果 Keeper 失败，其他人也可以触发
- ⏰ **时间约束** - 只能在开球前 5 分钟到开球时间之间调用
- 📍 **状态约束** - 只能在 `Open` 状态调用

**使用场景**:
- Keeper 在开球前 5 分钟自动调用
- 如果 Keeper 宕机，用户或其他机器人可以手动触发

**Gas 估算**: ~25,000 gas

---

### ❌ Keeper 不能调用的函数（需要 Owner 权限）

#### 1. `lock()` - 手动锁盘
```solidity
// MarketBase.sol:158
function lock() external override onlyOwner onlyStatus(MarketStatus.Open)
```

**权限**: `onlyOwner` ❌
**用途**: Owner 紧急手动锁盘

#### 2. `resolve()` - 提交结果
```solidity
// MarketBase.sol:176
function resolve(uint256 winningOutcomeId) external override onlyOwner onlyStatus(MarketStatus.Locked)
```

**权限**: `onlyOwner` ❌
**用途**: Owner 提交比赛结果

#### 3. `finalize()` - 终结市场
```solidity
// MarketBase.sol:196
function finalize() external override onlyOwner onlyStatus(MarketStatus.Resolved)
```

**权限**: `onlyOwner` ❌
**用途**: Owner 在争议期后终结市场

---

## Keeper 工作流程

### Phase 1: 监控开球时间

```javascript
// Keeper 伪代码
async function monitorMarkets() {
  const markets = await getOpenMarkets();

  for (const market of markets) {
    const kickoffTime = await market.kickoffTime();
    const now = Date.now() / 1000;

    // 开球前 5 分钟触发锁盘
    if (now >= kickoffTime - 300 && now < kickoffTime) {
      try {
        await market.autoLock();
        console.log(`Market ${market.address} locked`);
      } catch (error) {
        console.error(`Failed to lock market ${market.address}:`, error);
      }
    }
  }
}
```

### Phase 2: 等待 Owner 提交结果

Keeper **不负责**提交结果，这是 Owner 的职责：
1. Owner 从预言机获取比赛结果
2. Owner 调用 `resolve(winningOutcomeId)`
3. 市场进入 `Resolved` 状态

### Phase 3: 监控争议期

```javascript
// Keeper 可以监控但不能触发
async function monitorDisputePeriod() {
  const markets = await getResolvedMarkets();

  for (const market of markets) {
    const lockTime = await market.lockTimestamp();
    const disputePeriod = await market.disputePeriod();
    const now = Date.now() / 1000;

    if (now >= lockTime + disputePeriod) {
      console.log(`Market ${market.address} ready to finalize (Owner action needed)`);
      // 可以发送通知给 Owner，但 Keeper 自己不能调用 finalize()
    }
  }
}
```

---

## 权限对比表

| 操作 | 函数 | Keeper | Owner | Anyone | 条件 |
|-----|------|--------|-------|--------|------|
| 自动锁盘 | `autoLock()` | ✅ | ✅ | ✅ | 开球前 5 分钟 |
| 手动锁盘 | `lock()` | ❌ | ✅ | ❌ | 无 |
| 提交结果 | `resolve()` | ❌ | ✅ | ❌ | Locked 状态 |
| 终结市场 | `finalize()` | ❌ | ✅ | ❌ | 争议期结束 |
| 下注 | `placeBet()` | ✅ | ✅ | ✅ | Open 状态 |
| 兑付 | `redeem()` | ✅ | ✅ | ✅ | Finalized 状态 |

---

## Week 3-4 改进建议

### 选项 1: 完全去中心化（推荐）
保持当前设计，`autoLock()` 任何人都可以调用，Keeper 只是其中一个调用者。

**优点**:
- 真正的去中心化
- Keeper 故障不影响系统
- 用户可以自己触发

**缺点**:
- 需要激励机制鼓励用户调用

### 选项 2: Keeper 专属
添加 `keeper` 角色，只有 Keeper 可以调用 `autoLock()`。

```solidity
address public keeper;

modifier onlyKeeper() {
    require(msg.sender == keeper, "Not keeper");
    _;
}

function autoLock() external onlyKeeper {
    // ...
}
```

**优点**:
- 明确的 Keeper 职责
- Gas 成本可预测

**缺点**:
- 中心化风险
- Keeper 单点故障

### 选项 3: 混合模式（平衡）
Keeper 优先，但在紧急情况下任何人都可以调用。

```solidity
address public keeper;
uint256 public constant EMERGENCY_DELAY = 10 minutes;

function autoLock() external {
    bool isKeeper = msg.sender == keeper;
    bool isEmergency = block.timestamp >= kickoffTime - 5 minutes + EMERGENCY_DELAY;

    require(isKeeper || isEmergency, "Not authorized yet");
    require(block.timestamp >= kickoffTime - 5 minutes, "Too early");
    // ...
}
```

**优点**:
- Keeper 正常情况下优先
- 紧急情况下任何人都可以调用
- 平衡效率和去中心化

---

## 实际部署建议

### Keeper 基础设施

1. **冗余部署**
   - 主 Keeper: 自建服务器
   - 备用 Keeper: Gelato/Chainlink Automation
   - 紧急后备: 任何人都可以调用

2. **监控告警**
   ```javascript
   // 如果距离锁盘时间还有 2 分钟但市场仍未锁定
   if (now >= kickoffTime - 120 && status === 'Open') {
     sendAlert('URGENT: Market not locked yet!');
   }
   ```

3. **Gas 价格策略**
   - 正常: 使用标准 gas 价格
   - 紧急: 开球前 1 分钟仍未锁定 → 提高 gas 价格

### 成本估算

- `autoLock()`: ~25,000 gas
- Gas 价格: 20 gwei (正常), 50 gwei (紧急)
- 每次成本: 0.0005 - 0.00125 ETH (~$1-2.5)
- 每天 100 场比赛: $100-250/day

---

## 测试命令

### 本地测试 Keeper 调用

```bash
# Terminal 1: 启动 Anvil
anvil

# Terminal 2: 部署合约
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# Terminal 3: 模拟 Keeper 调用
cast send $MARKET_ADDRESS "autoLock()" --rpc-url http://localhost:8545 --private-key $KEEPER_KEY

# 验证市场状态
cast call $MARKET_ADDRESS "status()" --rpc-url http://localhost:8545
# 返回 1 表示 Locked
```

### 测试时间条件

```bash
# 尝试提前锁盘（应该失败）
cast send $MARKET_ADDRESS "autoLock()" --rpc-url http://localhost:8545
# Error: "WDL: Too early to lock"

# 时间推进到开球前 5 分钟
cast rpc evm_increaseTime 7200  # 快进 2 小时

# 再次尝试（应该成功）
cast send $MARKET_ADDRESS "autoLock()" --rpc-url http://localhost:8545
```

---

## 总结

**Keeper 在 PitchOne 中的角色**:
- ✅ 可以触发 `autoLock()`（但不是唯一能触发的）
- ✅ 负责监控和及时触发
- ✅ 系统设计为即使 Keeper 失败，其他人也可以介入
- ❌ 不能提交结果、不能终结市场（这些是 Owner 的职责）

**设计哲学**: **去中心化优先，Keeper 辅助加速**

这是一个很好的平衡设计，既提高了效率，又保持了去中心化的特性！
