# PitchOne —— 代币经济（Tokenomics）技术方案
版本：v1.0 · 日期：2025-10-29

## 1. 基本信息
- **代币名称**：PitchOne Token
- **符号（Ticker）**：**P1**
- **治理锁仓票权**：**veP1**（基于锁仓期限与数量的不可转让票权，建议 ERC-721 锁仓 NFT 可合并/拆分）
- **总量上限**：1,000,000,000 P1（硬顶，可由治理决定是否启封后续增发）
- **结算币种**：平台奖池与手续费继续以稳定币/主流资产计价，P1 仅作为**权利与激励**载体，不直接成为奖池抵押资产。

## 2. 代币用途（Utility）
1) **治理与参数调度（veP1）**：锁仓 P1 获得 veP1，用于对各联赛/玩法 **Gauge 权重投票**，决定每周激励的流向。  
2) **费用折扣与权限**：持仓/锁仓 P1 获得 5–20% 手续费折扣、提高单地址敞口上限、加速奖励释放等。  
3) **LP 流动性挖矿**：LP 对各市场池提供流动性，按 Gauge 权重领取每周 P1 排放（叠加真实交易费）。  
4) **预言机/仲裁**：上报者/挑战者需质押 P1，正确上报/挑战获得 P1 奖励；作恶将被 Slash。  
5) **增长推广 Boost**：推广返佣/任务奖励以稳定币为主，P1 作为 Boost/乘数，提高上限或加速释放。  
6) **创作者经济**：特定模板的“市场创建者”需抵押 P1 获得额度，达标后享创作者分成。

## 3. 排放与治理（ve(3,3) + Gauges + Bribe 可选）
- **veP1**：锁仓 1 周 ~ 2 年获取票权，权重随锁期衰减。  
- **Gauge**：每个“联赛×玩法”（如 EPL-WDL、UCL-OU）为一个 Gauge。  
- **周度排放**：由 EmissionsController 将当周排放 E_week 按各 Gauge 权重分配。  
- **Bribe（可选）**：第三方可以对某 Gauge 提供贿（P1 或稳定币），吸引投票。

## 4. 费用流与回购
- FeeRouter 将手续费分配至 LP / Promo / Insurance / Treasury。  
- **Buyback**：按周期使用 Treasury/Promo 的一部分费用回购 P1：50% 销毁（或注入 veP1 sink），50% 回流激励预算，降低净增发压力。

## 5. 参数建议（占位，均由 ParamController+Timelock 治理）
| 类别 | 参数 | 建议值 | 说明 |
|---|---|---|---|
| 排放 | weeklyEmission(E) | 0.25%/周（递减） | 首年偏高、逐季递降 |
| 投票 | maxVotePerGauge | 40% | 单 Gauge 上限 |
| 锁期 | min/max lock | 1 周 / 104 周 | ve 权重与锁期相关 |
| 折扣 | feeDiscountTiers | 5/10/15/20% | 按 P1/veP1 分层 |
| 预言机 | stakeMin/slashRate | 5k P1 / 5–20% | 误报率越高罚越重 |
| 回购 | buybackShare | 10–25% 费用 | 周/双周执行 |
| Bribe | allowedTokens | P1/USDC 等 | 可白名单 |

## 6. 初始分配（建议）
- 生态激励（Gauge/任务空投）：40%（线性 4–6 年）  
- LP/做市补贴储备：20%  
- 团队/顾问：15%（12 个月悬崖 + 36 个月线性）  
- 国库/战略：15%  
- 社区出售/流动性：10%

## 7. 合约模块与事件（与 PitchOne 现有架构拼接）
| 模块 | 职责 | 关键接口 | 事件 |
|---|---|---|---|
| **P1 (ERC20)** | 代币 | `mint/burn`（治理） | `Transfer/Mint/Burn` |
| **veP1 (ERC721)** | 锁仓票权 | `create_lock`/`increase_amount`/`increase_unlock_time`/`merge/split` | `LockChanged/Checkpoint` |
| **GaugeController** | Gauge 权重 | `voteForGauge`/`addGauge`/`weights` | `VoteCast/GaugeAdded/WeightsUpdated` |
| **EmissionsController** | 周度排放 | `checkpoint`/`distribute`/`setWeeklyEmission` | `EmissionDistributed` |
| **Gauge** | 奖励发放 | `notifyReward`/`getReward` | `RewardPaid` |
| **Bribe(可选)** | 贿奖励 | `notifyBribe`/`claimBribe` | `BribeAdded/BribeClaimed` |
| **OracleStaking** | 质押与惩罚 | `stake`/`unstake`/`slash` | `Staked/Slashed/Rewarded` |
| **Buyback** | 回购销毁 | `buyback`/`burn` | `Buyback` |

**集成点：**
- `FeeRouter` → `Buyback`（定期回购）  
- `RewardsDistributor` 支持 **P1** 的 Merkle 空投  
- `ParamController` 新增参数键：`E_week/feeDiscountTiers/buybackShare/stakeMin/slashRate/allowedBribeTokens/gaugeCaps...`

## 8. 路线图对齐
- **Phase 0（M0–M1）**：无代币冷启动（稳定币奖励+记录贡献度）  
- **Phase 1（M2）**：发布 **P1/veP1**、开最小 Gauge、折扣与小规模排放  
- **Phase 2（M3）**：扩玩法 Gauge、引入 Bribe、开启回购  
- **Phase 3**：创作者计划与 Oracle 全链质押/惩罚上线

## 9. 风控与反刷
- 有效用户规则（成交额×活跃天数、关系图谱去对倒）；
- 绝大多数 **P1** 激励为 **周度线性释放**，风险分低者可加速；
- Promo 池预算硬上限，`PayoutScaler` 统一缩放；
- Oracle 质押与罚没对称，异常率高逐步抬升质押要求。

## 10. KPI 观测
- 经济：GTV、LP APR、Emissions/Fees、Buyback 覆盖率；
- 治理：ve 锁仓率、投票参与度、Gauge 权重分散度；
- 风控：挑战率/误报率、返佣缩放比、可疑集群占比。

> 本文档将项目名更新为 **PitchOne**，代币命名统一为 **P1 / veP1**。
