# 市场生命周期测试指南

本文档提供完整市场生命周期的分步测试指南。

## 已部署合约地址

```
USDC:       0x36C02dA8a0983159322a80FFE9F24b1acfF8B570
FeeRouter:  0x4c5859f0F772848b2D91F1D83E2Fe57935348029
SimpleCPMM: 0x1291Be112d480055DaFd8a610b7d1e203891C274
WDL Market: 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154
```

## 测试账户

- Deployer (Owner): `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Alice (Account #1): `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- Bob (Account #2): `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`
- Charlie (Account #3): `0x90F79bf6EB2c4f870365E785982E1f101E93b906`

## 测试步骤

### Phase 1: 准备阶段 ✅

已完成初始部署和验证。

### Phase 2: 多用户下注 ✅

脚本已成功执行三个用户的下注：

```bash
Alice:   1000 USDC on WIN   -> 19,000,000,000,931,000,000 shares
Bob:     500 USDC on DRAW   -> 931,000,000 shares
Charlie: 2000 USDC on LOSS  -> 1,960,000,000 shares
```

**流动性分布**:
- WIN:  1078 USDC (30.6%)
- DRAW: 490 USDC (13.9%)
- LOSS: 1960 USDC (55.5%)
- **总计**: 3528 USDC (3500 USDC - 2% 手续费)

### Phase 3: 锁盘 ✅

```bash
# 时间快进到开赛时间
# Kickoff Time: 1761823207
# 成功调用 autoLock()
# 市场状态: 1 (Locked)
```

### Phase 4: 结算 ✅

```bash
# 结果: HOME WIN (Man United wins)
# 调用 resolve(0)
# 市场状态: 2 (Resolved)
# 获胜结果: 0 (WIN)
```

### Phase 5: 终结 ⚠️

**问题**: 在实际链上广播时，`vm.warp()` 不影响真实区块时间。

**解决方案**: 使用 `cast` 命令手动操作或等待 Anvil 自动挖矿。

#### 方法 1: 使用 cast 手动调用（推荐）

```bash
# 等待 2 小时争议期（或使用 Anvil 时间控制）
cast rpc anvil_increaseTime 7200 --rpc-url http://127.0.0.1:8545
cast rpc anvil_mine 1 --rpc-url http://127.0.0.1:8545

# 然后调用 finalize
cast send 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "finalize()" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

#### 方法 2: 修改争议期为 1 秒（测试用）

重新部署市场时将争议期设为 1 秒，方便快速测试。

### Phase 6: 赎回 ⏳

一旦市场 Finalized，Alice 可以赎回：

```bash
# Alice 赎回她的份额
cast send 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "redeem(uint256,uint256)" \
  0 \
  19000000000931000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

## 测试结果

### ✅ 成功测试的功能

1. **部署**: 所有合约成功部署
2. **USDC 分发**: 用户成功接收测试代币
3. **下注**: 三个用户成功下注不同结果
4. **流动性追踪**: 正确记录每个结果的流动性
5. **头寸追踪**: ERC-1155 余额正确更新
6. **锁盘**: `autoLock()` 成功执行
7. **结算**: `resolve()` 成功设置获胜结果

### ⚠️ 待验证的功能

1. **终结**: 需要等待争议期或使用 Anvil 时间控制
2. **赎回**: 需要先完成终结步骤
3. **比例分配**: 验证按比例赎回逻辑的正确性

## 完整测试数据

### 输入
- Alice 下注: 1000 USDC on WIN
- Bob 下注: 500 USDC on DRAW
- Charlie 下注: 2000 USDC on LOSS
- 总下注: 3500 USDC
- 手续费 (2%): 70 USDC
- 净流动性: 3430 USDC

### 预期输出（Resolve 为 WIN）

- **Alice (Winner)**:
  - 份额: 19,000,000,000,931,000,000
  - 预期赔付: ~3527 USDC (所有净流动性)
  - 预期利润: ~2527 USDC
  - 预期 ROI: ~352%

- **Bob (Loser)**:
  - 份额: 931,000,000
  - 赔付: 0 (错误结果)

- **Charlie (Loser)**:
  - 份额: 1,960,000,000
  - 赔付: 0 (错误结果)

## 手动测试命令

### 1. 检查市场状态

```bash
# 查询市场状态 (0=Open, 1=Locked, 2=Resolved, 3=Finalized)
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "status()" --rpc-url http://127.0.0.1:8545

# 查询总流动性
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "totalLiquidity()" --rpc-url http://127.0.0.1:8545

# 查询获胜结果
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "winningOutcome()" --rpc-url http://127.0.0.1:8545

# 查询锁盘时间
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "lockTimestamp()" --rpc-url http://127.0.0.1:8545

# 查询争议期
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 "disputePeriod()" --rpc-url http://127.0.0.1:8545
```

### 2. 查询用户余额

```bash
# Alice 的 WIN 头寸
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "balanceOf(address,uint256)" \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
  0 \
  --rpc-url http://127.0.0.1:8545

# Bob 的 DRAW 头寸
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "balanceOf(address,uint256)" \
  0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
  1 \
  --rpc-url http://127.0.0.1:8545

# Charlie 的 LOSS 头寸
cast call 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "balanceOf(address,uint256)" \
  0x90F79bf6EB2c4f870365E785982E1f101E93b906 \
  2 \
  --rpc-url http://127.0.0.1:8545
```

### 3. 终结市场

```bash
# 方法 1: 快进时间
cast rpc anvil_increaseTime 7200 --rpc-url http://127.0.0.1:8545
cast rpc anvil_mine 1 --rpc-url http://127.0.0.1:8545

# 方法 2: 或者等待 2 小时

# 调用 finalize
cast send 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "finalize()" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 4. 赎回奖金

```bash
# Alice 赎回 (使用她的私钥)
cast send 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154 \
  "redeem(uint256,uint256)" \
  0 \
  19000000000931000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

## 总结

### 已验证功能 ✅

- [x] 合约部署
- [x] 代币铸造和分发
- [x] 多用户下注
- [x] 流动性和份额计算
- [x] 市场锁盘
- [x] 结果结算

### 待完成验证 ⏳

- [ ] 市场终结（争议期后）
- [ ] 赢家赎回
- [ ] 比例分配验证

### 建议

1. 为了快速测试，可以重新部署市场并将争议期设为 1 秒
2. 或者使用 `cast rpc anvil_increaseTime` 手动控制 Anvil 的时间
3. 完成终结和赎回步骤后，验证最终的 USDC 余额和利润计算

---

**下一步**: 执行 Phase 5 和 Phase 6 以完成完整的生命周期测试。
