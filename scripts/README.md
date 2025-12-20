# PitchOne 部署脚本

本目录包含用于本地开发环境快速部署的自动化脚本。

## 📁 脚本列表

### `quick-deploy.sh` - 一键部署脚本

自动执行完整的本地环境部署流程：
1. 部署核心合约
2. 创建测试市场
3. 模拟投注数据
4. 部署 Subgraph

**使用方法**：

```bash
# 前置条件：确保 Anvil 已运行
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0

# 在另一个终端运行部署脚本
cd /home/harry/code/PitchOne
./scripts/quick-deploy.sh
```

**环境变量配置**（可选）：

```bash
# 自定义配置
export NUM_BETTORS=10          # 投注用户数（默认: 5）
export MIN_BET_AMOUNT=20       # 最小投注额（默认: 10 USDC）
export MAX_BET_AMOUNT=200      # 最大投注额（默认: 100 USDC）
export BETS_PER_USER=3         # 每用户投注次数（默认: 2）
export OUTCOME_DISTRIBUTION=skewed  # 分布策略（默认: balanced）

# 运行部署
./scripts/quick-deploy.sh
```

**预期输出**：

```
=========================================
  PitchOne 本地环境一键部署
=========================================

[1/4] 部署核心合约...
✅ 合约部署成功
   Factory: 0x5f3f...9154

[2/4] 创建测试市场...
✅ 市场创建成功: 15 个

[3/4] 模拟投注数据...
✅ 投注模拟完成

[4/4] 部署 Subgraph...
✅ Subgraph 部署成功

=========================================
  ✅ 部署完成！
=========================================

📊 数据统计:
  - 总市场数: 15
  - 总用户数: 5
  - 总交易量: 2587.02 USDC
  - 总手续费: 51.74 USDC
```

## 📚 详细文档

完整的操作流程和故障排查，请参阅：

- **完整 SOP**: [../subgraph/SOP_LOCAL_DEPLOYMENT.md](../subgraph/SOP_LOCAL_DEPLOYMENT.md)
- **合约文档**: [../contracts/README.md](../contracts/README.md)
- **Subgraph 文档**: [../subgraph/README.md](../subgraph/README.md)

## 🔧 常见问题

### 1. 脚本报错 "Anvil 未运行"

**解决方法**：
```bash
# 启动 Anvil
cd /home/harry/code/PitchOne/contracts
anvil --host 0.0.0.0
```

### 2. Subgraph 部署失败

**解决方法**：
```bash
# 检查 Docker 状态
docker ps

# 如果 Graph Node 未运行，手动启动
cd /home/harry/code/PitchOne/subgraph
docker-compose up -d

# 重新运行部署脚本
cd /home/harry/code/PitchOne
./scripts/quick-deploy.sh
```

### 3. 市场创建失败

**可能原因**：
- OU_MultiLine 模板初始化失败（已知问题）
- 当前使用 `CreateMarkets_NoMultiLine.s.sol` 跳过该模板

**解决方法**：
- 脚本已自动使用不含 OU_MultiLine 的版本
- 如需完整 7 种模板，需等待 OU_MultiLine 修复

## 🎯 快速验证

部署完成后，使用以下命令验证：

```bash
# 查询市场数据
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 5) { id homeTeam awayTeam totalVolume } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-sportsbook | jq .

# 查询全局统计
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ globalStats(id: \"global\") { totalMarkets totalUsers totalVolume totalFees } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-sportsbook | jq .

# 访问 GraphQL Playground
open http://localhost:8010/subgraphs/name/pitchone-sportsbook/graphql
```

## 📝 更新记录

- **2025-11-14**: 初始版本，支持快速一键部署
  - 自动化合约部署 → 市场创建 → 投注模拟 → Subgraph 部署
  - 内置验证和错误处理
  - 支持环境变量自定义配置
