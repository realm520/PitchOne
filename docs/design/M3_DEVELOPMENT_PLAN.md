# M3 阶段开发计划

**日期**: 2025-11-08
**里程碑**: M3 - 扩玩法与可插槽
**预计周期**: Week 8-12 (2025-12-17 ~ 2026-01-19)
**总预估点数**: 90 点

---

## 📊 当前项目状态（Week 7 结束）

### ✅ 已完成部分
1. **核心合约**: 15/19 (79%)
2. **测试覆盖**: 554 个测试，100% 通过率
3. **市场模板**: 5/7 (71%)
   - ✅ WDL_Template (51 测试)
   - ✅ OU_Template 单线 (47 测试)
   - ✅ OU_MultiLine 多线 (23 测试)
   - ✅ AH_Template (28 测试)
   - ✅ OddEven_Template (34 测试)
   - ⏳ ScoreTemplate (精确比分) - **M3 待开发**
   - ⏳ PlayerProps_Template (球员道具) - **M3 待开发**
4. **定价引擎**:
   - ✅ SimpleCPMM (23 测试, 97.5% 覆盖率)
   - ✅ LinkedLinesController (19 测试, 92.45% 覆盖率)
   - ⏳ LMSR - **M3 待开发**
5. **串关系统**:
   - ✅ Basket.sol (538 行, 25 测试, 100% 通过) - **已完成！**
   - ✅ CorrelationGuard.sol (387 行, 25 测试, 100% 通过) - **已完成！**
6. **M2 运营闭环**: 100% 完成
   - Campaign, Quest, CreditToken, Coupon, PayoutScaler
7. **Subgraph**: M2 完整部署成功 (v0.4.0-m2)

### ⏳ M3 待完成部分
1. **LMSR 定价引擎** - 30 点
2. **ScoreTemplate 精确比分市场** - 25 点
3. **PlayerProps_Template 球员道具市场** - 15 点
4. **Basket/CorrelationGuard Subgraph Mapping** - 10 点
5. **集成测试与端到端验证** - 8 点
6. **CLOB 插槽评估（选配）** - 2 点

---

## 🎯 M3 核心目标

### 1. 扩展市场玩法（核心）
- 实现 **LMSR 定价引擎**，支持多结果市场（>3 个结果）
- 实现 **精确比分市场**（如 0-0, 1-0, 2-1 等，约 25-50 个结果）
- 实现 **球员道具市场**（如进球数 >1.5, 助攻数 OU, 射门次数等）

### 2. 串关系统完善
- ✅ Basket 和 CorrelationGuard 合约已完成（50 测试，100% 通过）
- 🔄 添加 Subgraph Mapping 支持（索引串关事件）
- 🔄 添加与市场模板的端到端集成测试

### 3. CLOB 插槽评估（选配）
- 评估中心化订单簿（CLOB）的必要性
- 设计插槽接口（如果需要）

---

## 📋 详细任务分解

### 任务 1: LMSR 定价引擎 (30 点, Week 8-9)

#### 背景
- LMSR (Logarithmic Market Scoring Rule) 是适用于多结果市场的做市算法
- 相比 CPMM，LMSR 在处理 >3 个结果时更高效且价格更稳定
- 精确比分市场（25-50 个结果）必须使用 LMSR

#### 实现范围
1. **核心合约**: `contracts/src/pricing/LMSR.sol`
   - 成本函数: `C(q) = b * ln(Σ exp(q_i / b))`
   - 价格函数: `p_i = exp(q_i / b) / Σ exp(q_j / b)`
   - 报价函数: `quote(outcome, amount)`
   - 交易执行: `executeTrade(outcome, amount)`
   - 参数: `b` (流动性参数)

2. **数值稳定性处理**
   - 使用 LogExpMath 库（来自 Balancer 或 PRBMath）
   - 避免指数溢出（使用 log-sum-exp 技巧）
   - 处理极端概率（如 0.01% 或 99.99%）

3. **接口设计**
   ```solidity
   interface ILMSR {
       function quote(uint256 outcome, uint256 amount) external view returns (uint256 cost, uint256 newPrice);
       function executeTrade(uint256 outcome, uint256 amount) external returns (uint256 cost);
       function getCurrentPrice(uint256 outcome) external view returns (uint256 price);
       function setLiquidityParameter(uint256 newB) external; // onlyOwner
   }
   ```

4. **测试计划** (≥25 个测试)
   - 单元测试:
     - 价格函数正确性（与理论值对比）
     - 成本函数单调性
     - 无套利性质（跨结果组合）
     - 极端值处理（0.01%, 99.99%）
   - 集成测试:
     - 与 MarketBase 集成
     - 多用户并发交易
     - 大额交易滑点
   - 不变量测试 (Echidna):
     - `Σ p_i = 1` (概率总和为 1)
     - `C(q)` 单调递增
     - 买入后卖出不会获利（考虑费用）

5. **Gas 优化**
   - 批量计算概率（避免重复 exp 计算）
   - 缓存中间结果
   - 使用汇编优化关键路径

#### 交付物
- ✅ `contracts/src/pricing/LMSR.sol` (≈500 行)
- ✅ `contracts/test/unit/LMSR.t.sol` (≥25 测试)
- ✅ `contracts/docs/LMSR_Usage.md` (技术文档)
- ✅ Gas 报告和对比分析

---

### 任务 2: ScoreTemplate 精确比分市场 (25 点, Week 9-10)

#### 背景
- 精确比分是博彩平台的核心玩法之一
- 典型结果数量: 25-50 个（如 0-0 到 5-5，以及 Other）
- 必须使用 LMSR 定价（SimpleCPMM 不适用）

#### 实现范围
1. **核心合约**: `contracts/src/templates/ScoreTemplate.sol`
   - 继承 `MarketBase`
   - 集成 `LMSR` 定价引擎
   - Outcome ID 编码: `homeGoals * 10 + awayGoals` (如 21 = 2-1)
   - 特殊结果: `999 = Other` (其他比分)

2. **结果编码方案**
   ```solidity
   // 示例: 0-0 到 5-5 + Other
   uint256[] public validOutcomes = [
       0,   // 0-0
       1,   // 0-1
       2,   // 0-2
       ...
       55,  // 5-5
       999  // Other
   ];

   function encodeScore(uint8 home, uint8 away) returns (uint256) {
       return home * 10 + away;
   }
   ```

3. **初始化参数**
   - 最大比分范围 (如 0-5)
   - LMSR 流动性参数 `b`
   - 初始概率分布（从链下获取或使用默认）
   - 费率配置

4. **结算逻辑**
   - 从 Oracle 获取最终比分
   - 映射到 Outcome ID
   - 如果比分超出范围，结算为 `Other`
   - 支持加时/点球比分（可选）

5. **测试计划** (≥30 个测试)
   - 初始化测试:
     - 有效的概率分布
     - Outcome ID 编码正确性
   - 下注测试:
     - 多用户下注不同比分
     - 价格变化符合 LMSR 预期
     - 滑点保护生效
   - 结算测试:
     - 标准比分结算 (如 2-1)
     - Other 比分结算 (如 6-0)
     - 多用户兑付
   - 边界测试:
     - 极端概率下注
     - 大额下注

6. **事件定义**
   ```solidity
   event ScoreMarketCreated(
       address indexed market,
       string matchId,
       uint256[] validOutcomes,
       uint256 liquidityB
   );

   event ScoreBetPlaced(
       address indexed user,
       uint256 homeGoals,
       uint256 awayGoals,
       uint256 amount,
       uint256 shares
   );
   ```

#### 交付物
- ✅ `contracts/src/templates/ScoreTemplate.sol` (≈600 行)
- ✅ `contracts/test/unit/ScoreTemplate.t.sol` (≥30 测试)
- ✅ 结算脚本 (forge script)
- ✅ 文档更新 (EVENT_DICTIONARY.md)

---

### 任务 3: PlayerProps_Template 球员道具市场 (15 点, Week 10-11)

#### 背景
- 球员道具是增长最快的博彩品类之一
- 典型玩法: 进球数 OU, 助攻数 OU, 射门次数 OU, 黄牌 Yes/No
- 可使用 SimpleCPMM (二/三向市场)

#### 实现范围
1. **核心合约**: `contracts/src/templates/PlayerProps_Template.sol`
   - 继承 `MarketBase`
   - 支持多种道具类型 (enum PropType)
   - 集成 SimpleCPMM 或 LMSR（根据结果数量）

2. **道具类型定义**
   ```solidity
   enum PropType {
       GOALS_OU,        // 进球数大小球 (二向)
       ASSISTS_OU,      // 助攻数大小球 (二向)
       SHOTS_OU,        // 射门次数大小球 (二向)
       YELLOW_CARD,     // 黄牌 Yes/No (二向)
       ANYTIME_SCORER,  // 任意时间进球 Yes/No (二向)
       FIRST_SCORER     // 首位进球者 (多向, 需 LMSR)
   }
   ```

3. **市场参数**
   - 球员 ID / 名字
   - 道具类型
   - 盘口线（如 0.5, 1.5 等）
   - 比赛引用 (matchId)

4. **结算逻辑**
   - 从 Oracle 获取球员统计数据
   - 映射到结果 (Over/Under, Yes/No)
   - 支持球员未上场的情况（退款或特殊处理）

5. **测试计划** (≥20 个测试)
   - 各道具类型的创建和下注
   - 结算逻辑正确性
   - 球员未上场的处理
   - 多球员组合市场

#### 交付物
- ✅ `contracts/src/templates/PlayerProps_Template.sol` (≈400 行)
- ✅ `contracts/test/unit/PlayerProps.t.sol` (≥20 测试)
- ✅ 文档更新

---

### 任务 4: Basket/CorrelationGuard Subgraph Mapping (10 点, Week 11)

#### 背景
- Basket 和 CorrelationGuard 合约已完成（50 测试，100% 通过）
- 需要 Subgraph 支持来索引串关数据，供前端查询

#### 实现范围
1. **Schema 扩展** (`subgraph/schema.graphql`)
   ```graphql
   type Parlay @entity {
     id: ID!
     parlayId: BigInt!
     user: User!
     legs: [ParlayLeg!]! @derivedFrom(field: "parlay")
     stake: BigDecimal!
     potentialPayout: BigDecimal!
     combinedOdds: BigInt!  # 基点
     penaltyBps: BigInt!
     status: ParlayStatus!
     createdAt: BigInt!
     settledAt: BigInt
     payout: BigDecimal
   }

   type ParlayLeg @entity {
     id: ID!
     parlay: Parlay!
     market: Market!
     outcomeId: BigInt!
     legIndex: Int!
   }

   enum ParlayStatus {
     Pending
     Won
     Lost
     Cancelled
   }

   type CorrelationRule @entity {
     id: ID!
     matchId1: Bytes!
     matchId2: Bytes!
     penaltyBps: Int!
     isBlocked: Boolean!
     updatedAt: BigInt!
   }
   ```

2. **Mapping 实现** (`subgraph/src/basket.ts`)
   - `handleParlayCreated`: 创建 Parlay 和 ParlayLeg 实体
   - `handleParlaySettled`: 更新 Parlay 状态和赔付
   - `handleCorrelationGuardUpdated`: 更新相关性守卫
   - `handleCorrelationRuleSet`: 更新相关性规则

3. **Helper 函数**
   - `getParlayStatusString(status: i32): string`
   - `createParlayId(parlayId: BigInt): string`

4. **配置更新** (`subgraph/subgraph.yaml`)
   ```yaml
   - kind: ethereum/contract
     name: Basket
     network: localhost
     source:
       address: "0x..."
       abi: Basket
       startBlock: 0
     mapping:
       kind: ethereum/events
       apiVersion: 0.0.7
       language: wasm/assemblyscript
       entities:
         - Parlay
         - ParlayLeg
       abis:
         - name: Basket
           file: ./abis/Basket.json
       eventHandlers:
         - event: ParlayCreated(uint256,address,tuple[],uint256,uint256,uint256,uint256)
           handler: handleParlayCreated
         - event: ParlaySettled(uint256,address,uint8,uint256)
           handler: handleParlaySettled
       file: ./src/basket.ts
   ```

5. **查询示例**
   ```graphql
   # 查询用户的所有串关
   query UserParlays($user: Bytes!) {
     parlays(
       where: { user: $user }
       orderBy: createdAt
       orderDirection: desc
     ) {
       id
       stake
       potentialPayout
       combinedOdds
       status
       legs {
         market { id, event }
         outcomeId
       }
     }
   }

   # 查询待结算的串关
   query PendingParlays {
     parlays(where: { status: Pending }) {
       id
       user
       createdAt
     }
   }
   ```

#### 测试计划
- 部署 Basket 到本地 Anvil
- 创建测试串关
- 验证 Subgraph 索引正确
- 运行 GraphQL 查询测试

#### 交付物
- ✅ Schema 扩展 (5 个新实体)
- ✅ `subgraph/src/basket.ts` (≈250 行)
- ✅ `subgraph/src/correlation.ts` (≈150 行)
- ✅ subgraph.yaml 配置
- ✅ 本地部署和验证

---

### 任务 5: 集成测试与端到端验证 (8 点, Week 11-12)

#### 测试范围
1. **串关 + 市场集成测试**
   - 创建多个市场（WDL, OU, AH）
   - 创建串关组合（2-5 腿）
   - 模拟市场结算
   - 验证串关结算和赔付

2. **LMSR + ScoreTemplate 集成测试**
   - 创建精确比分市场
   - 多用户下注不同比分
   - 模拟比分结算
   - 验证赔付正确性

3. **端到端流程测试**
   - Anvil 本地链
   - 部署所有合约
   - Keeper 自动化（锁盘、结算）
   - Indexer 事件订阅
   - Subgraph 数据验证

4. **性能测试**
   - 大额交易 Gas 消耗
   - 批量结算性能
   - Subgraph 索引速度

#### 交付物
- ✅ `contracts/test/integration/ParlayE2E.t.sol`
- ✅ `contracts/test/integration/ScoreMarketE2E.t.sol`
- ✅ 端到端测试脚本
- ✅ 性能报告

---

### 任务 6: CLOB 插槽评估（选配, 2 点, Week 12）

#### 评估维度
1. **业务需求**
   - AMM 流动性是否满足大额交易？
   - 是否需要限价单功能？
   - 专业用户的占比和需求

2. **技术可行性**
   - 链上 CLOB 的 Gas 成本
   - 订单簿深度和更新频率
   - MEV 风险和公平性

3. **插槽设计**
   - 接口定义 `IOrderbook`
   - 与 AMM 的流动性聚合
   - 订单匹配逻辑（链上 vs 链下）

4. **实现路径**
   - 方案 A: 纯链上 CLOB（高 Gas）
   - 方案 B: 链下订单簿 + 链上结算（需中心化组件）
   - 方案 C: 集成第三方 CLOB 协议（如 dYdX, Vertex）

#### 交付物
- ✅ `docs/design/CLOB_Evaluation.md` (评估报告)
- ✅ 接口设计草案（如果决定实现）

---

## 📅 时间规划

| Week | 日期 | 主要任务 | 预估点数 | 交付物 |
|------|------|---------|---------|--------|
| Week 8 | 12/17-12/23 | LMSR 引擎开发 (Part 1) | 15 | LMSR.sol 核心实现 + 基础测试 |
| Week 9 | 12/24-12/30 | LMSR 引擎完成 + ScoreTemplate 开发 (Part 1) | 15+10 | LMSR 完整测试 + ScoreTemplate 核心 |
| Week 10 | 12/31-01/06 | ScoreTemplate 完成 + PlayerProps 开发 | 15+10 | ScoreTemplate 测试 + PlayerProps 实现 |
| Week 11 | 01/07-01/13 | PlayerProps 完成 + Subgraph Mapping + 集成测试 | 5+10+8 | 所有模板完成 + Subgraph 部署 |
| Week 12 | 01/14-01/19 | CLOB 评估 + 文档完善 + M3 收尾 | 2 | M3 完成报告 |

---

## 🎯 成功标准

### 合约层
- ✅ LMSR 定价引擎完成，≥25 测试，覆盖率 ≥90%
- ✅ ScoreTemplate 完成，≥30 测试，覆盖率 ≥85%
- ✅ PlayerProps_Template 完成，≥20 测试
- ✅ 所有测试 100% 通过
- ✅ Slither 扫描 0 中高危问题

### Subgraph 层
- ✅ Basket/CorrelationGuard Mapping 完成
- ✅ 本地部署成功，索引健康
- ✅ GraphQL 查询测试通过

### 集成测试
- ✅ 端到端流程打通（创建 → 下注 → 锁盘 → 结算 → 兑付）
- ✅ 性能测试通过（Gas 优化，索引速度）

### 文档
- ✅ 技术文档完整 (LMSR_Usage.md, ScoreTemplate_Usage.md)
- ✅ EVENT_DICTIONARY.md 更新
- ✅ M3 完成总结报告

---

## 🔗 相关资源

### 参考实现
- **LMSR**:
  - [Gnosis Conditional Tokens](https://github.com/gnosis/conditional-tokens-contracts)
  - [Augur v2 LMSR](https://github.com/AugurProject/augur-core)
- **数值库**:
  - [PRBMath](https://github.com/PaulRBerg/prb-math) - 高精度数学库
  - [Balancer LogExpMath](https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol)

### 学术论文
- Hanson, R. (2003). "Combinatorial Information Market Design"
- Chen, Y., & Pennock, D. M. (2007). "A utility framework for bounded-loss market makers"

### 内部文档
- `docs/design/02_AMM_LinkedLines.md` - AMM 设计文档
- `docs/design/04_Parlay_CorrelationGuard.md` - 串关设计文档
- `docs/模块接口事件参数/EVENT_DICTIONARY.md` - 事件字典

---

## 📝 风险与缓解

### 技术风险
1. **LMSR 数值稳定性问题**
   - 风险: 指数溢出、精度损失
   - 缓解: 使用 LogExpMath 库，添加边界检查

2. **精确比分市场的高 Gas 成本**
   - 风险: 25-50 个结果导致状态更新昂贵
   - 缓解: 批量操作优化，使用紧凑存储

3. **串关系统的复杂性**
   - 风险: 多市场结算的边界情况
   - 缓解: 已有 50 个测试覆盖，添加更多集成测试

### 进度风险
1. **LMSR 实现难度超预期**
   - 缓解: Week 8 优先完成 LMSR，留出缓冲时间

2. **Subgraph 索引性能问题**
   - 缓解: 先实现基础功能，性能优化为后续迭代

---

## ✨ M3 后的规划

### M4 (可选扩展)
1. **Promoter SBT + Staking** (10 点)
2. **前端完整实现** (20 点)
3. **测试网部署和审计准备** (15 点)
4. **Bug Bounty 和社区测试** (10 点)

### 长期优化
1. Gas 优化（目标: -30%）
2. 动态参数调整（ML 驱动）
3. 跨链部署（L2 扩展）

---

**编制者**: Claude Code
**版本**: v1.0
**最后更新**: 2025-11-08
