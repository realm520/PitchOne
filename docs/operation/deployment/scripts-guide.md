# Deployment Scripts

本目录包含 PitchOne 项目的部署和演示脚本。

## 脚本列表

### 1. Deploy.s.sol - 部署脚本

**用途**: 自动化部署所有核心合约（MockERC20、FeeRouter、SimpleCPMM、WDL_Template）

**运行方式**:

```bash
# 本地 Anvil 测试链
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast -vvvv

# 测试网（需设置私钥）
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv

# 使用环境变量
export PRIVATE_KEY=0x...
export RPC_URL=https://sepolia.infura.io/v3/...
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast -vvvv
```

**部署的合约**:
- MockERC20 (USDC): 测试用稳定币，初始铸造 100 万枚
- FeeRouter: 费用路由合约
- SimpleCPMM: CPMM 定价引擎
- WDL_Template: 胜平负市场合约（曼联 vs 利物浦示例）

**配置参数**:
- 默认 Treasury 地址: 部署者地址
- 默认 Keeper 地址: 部署者地址
- 开球时间: 当前时间 + 7 天
- 手续费率: 200 基点（2%）
- 争议期: 2 小时

### 2. DemoFlow.s.sol - 完整流程演示

**用途**: 演示从部署到最终兑付的完整市场生命周期

**运行方式**:

```bash
# Terminal 1: 启动 Anvil
anvil

# Terminal 2: 运行演示（自动使用 Anvil 默认私钥）
forge script script/DemoFlow.s.sol:DemoFlow --rpc-url http://localhost:8545 --broadcast

# 注意: 脚本会自动检测环境，如果没有 PRIVATE_KEY 环境变量，会使用 Anvil 的默认测试私钥
```

**演示流程**:

1. **Phase 1: 部署合约**
   - 部署所有核心合约
   - 打印合约地址

2. **Phase 2: 用户下注**
   - Alice 下注 1000 USDC 支持主队赢（WIN）
   - Bob 下注 800 USDC 支持平局（DRAW）
   - Charlie 下注 500 USDC 支持客队赢（LOSS）

3. **Phase 3: 查看市场价格**
   - 显示三种结果的当前价格（基点表示）
   - 显示每种结果的流动性

4. **Phase 4: 锁盘**
   - 开球时间到达，Keeper 锁盘
   - 市场状态变为 Locked

5. **Phase 5: 结算**
   - 比赛结束，Keeper 提交结果（主队赢）
   - 市场状态变为 Resolved

6. **Phase 6: 终结**
   - 争议期结束，市场终结
   - 市场状态变为 Finalized

7. **Phase 7: 兑付**
   - Alice（猜对主队赢）兑换全部份额
   - 获得 1:1 赔付（简化版，未来会改为按比例分配）

**预期输出示例**:

```
=== Phase 1: Deploying Contracts ===
MockERC20 (USDC) deployed at: 0x...
FeeRouter deployed at: 0x...
SimpleCPMM deployed at: 0x...
WDL_Template deployed at: 0x...

=== Phase 2: Users Place Bets ===
Alice bets 1000 USDC on WIN
Bob bets 800 USDC on DRAW
Charlie bets 500 USDC on LOSS

=== Phase 3: Check Market Prices ===
Current market prices (in basis points):
  WIN:   4500
  DRAW:  3000
  LOSS:  2500

=== Phase 4: Lock Market ===
Market locked at kickoff time

=== Phase 5: Resolve Market ===
Market resolved with outcome: WIN (0)

=== Phase 6: Finalize Market ===
Market finalized after dispute period

=== Phase 7: Redeem Winnings ===
Alice redeemed 1000000000000000000000 shares
Alice payout: 1000000000
```

## 环境要求

- Foundry 工具链已安装
- 本地 Anvil 测试链运行（可选）
- 设置必要的环境变量（测试网部署时）

## 安全提示

⚠️ **警告**:
- Deploy.s.sol 和 DemoFlow.s.sol 中的私钥使用 `vm.envUint("PRIVATE_KEY")` 读取
- 切勿将真实私钥硬编码到脚本中
- 测试网部署前，确保私钥对应的账户有足够的测试币（ETH）

## 下一步

部署完成后，可以：
1. 使用 Foundry Cast 与合约交互
2. 编写前端集成测试
3. 部署到测试网（Sepolia/Goerli）
4. 进行 Week 3-4 的预言机集成开发
