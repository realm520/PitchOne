# 更新日志 (Changelog)

所有重要的项目变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### 新增 (Added)
- Campaign.sol: 活动工厂合约，支持预算管理和参与追踪
- Quest.sol: 任务系统合约，支持 5 种任务类型（首次下注、连续下注、推荐、交易量、连胜）
- Subgraph Schema: 16 个新实体用于 Campaign/Quest 数据索引
- 事件字典: 10 个 Campaign/Quest 事件的完整文档（689 行）
- GraphQL 查询文档: 40+ 查询示例（700+ 行）

### 修改 (Changed)
- MarketBase.calculateFee(): 优化精度计算，从两次除法改为单次除法
- RewardsDistributor._claim(): 优化线性释放计算精度
- RewardsDistributor.getClaimable(): 优化可领取金额计算精度
- MarketTemplateRegistry: 使用 abi.encode 替代 abi.encodePacked 防止哈希碰撞

### 安全 (Security)
- FeeRouter: 添加 ReentrancyGuard 防止重入攻击
- UMAOptimisticOracleAdapter: 添加 ReentrancyGuard 防止重入攻击
- Slither 静态分析: 中高危问题从 9 个降至 0 个（剩余 4 个为误报）

### 测试 (Tests)
- 新增 Campaign 单元测试: 26 个测试用例
- 新增 Quest 单元测试: 32 个测试用例
- 新增 Campaign/Quest 集成测试: 12 个测试用例
- 总测试数: 从 344 增加到 491 (+43%)
- 测试通过率: 保持 100%

---

## [0.2.0] - 2025-11-02

### 技术债务清理

#### 修复 (Fixed)
- **精度损失问题** (3 个):
  - MarketBase.calculateFee() - 单次除法优化
  - RewardsDistributor._claim() - 线性释放精度修复
  - RewardsDistributor.getClaimable() - 查询精度修复

- **重入攻击风险** (3 个):
  - FeeRouter.routeFee() - 添加 nonReentrant 修饰符
  - FeeRouter.batchRouteFee() - 添加 nonReentrant 修饰符
  - UMAOptimisticOracleAdapter.proposeResult() - 添加 nonReentrant 修饰符

- **哈希碰撞风险** (2 个):
  - MarketTemplateRegistry.registerTemplate() - abi.encode 替换
  - MarketTemplateRegistry.calculateTemplateId() - abi.encode 替换

#### 性能 (Performance)
- MarketBase.calculateFee(): +50 gas (+3.3%)
- RewardsDistributor._claim(): +100 gas (+0.05%)
- FeeRouter.routeFee(): +2,000 gas (+0.67%)
- UMAOptimisticOracleAdapter.proposeResult(): +2,000 gas (+0.44%)

**总体评估**: Gas 增量可接受，安全性显著提升

#### 文档 (Documentation)
- 添加技术债务清理报告 (TECH_DEBT_CLEANUP_2025-11-02.md)
- 更新项目任务追踪文档
- 更新 Subgraph 事件字典

---

## [0.1.0] - 2025-11-26

### 新增 (Added)
- ParamController: 参数治理合约，支持 Timelock 和验证器
- LinkedLinesController: OU/AH 多线联动控制器
- OU_MultiLine: 大小球多线模板（支持 2.0/2.5/3.0 等多条线）

### 测试 (Tests)
- ParamController: 35 个测试用例，90.10% 行覆盖率
- LinkedLinesController: 19 个测试用例
- OU_MultiLine: 23 个测试用例

---

## [0.0.1] - 2025-11-03 (M0 脚手架)

### 新增 (Added)
- 核心合约骨架:
  - MarketBase: 市场基础合约
  - MarketTemplateRegistry: 模板注册表
  - FeeRouter: 费用路由合约
  - RewardsDistributor: 奖励分发合约（Merkle Tree）
  - ReferralRegistry: 推荐关系注册表
  - SimpleCPMM: 恒定乘积做市商
  - UMAOptimisticOracleAdapter: UMA 预言机适配器
  - WDL_Template: 胜平负模板
  - OU_Template: 大小球模板（含 Push 退款）
  - MockOracle: 测试预言机

### 基础设施 (Infrastructure)
- Foundry 测试框架配置
- Slither 静态分析集成
- 初始测试覆盖: 344 个测试，100% 通过率

### 文档 (Documentation)
- 10 份技术设计文档
- 事件字典骨架
- 项目任务追踪文档

---

## 版本规则

- **主版本号 (Major)**: 不兼容的 API 变更
- **次版本号 (Minor)**: 向后兼容的功能新增
- **修订号 (Patch)**: 向后兼容的问题修复

### 变更类型

- **Added**: 新增功能
- **Changed**: 现有功能变更
- **Deprecated**: 即将废弃的功能
- **Removed**: 已移除的功能
- **Fixed**: 缺陷修复
- **Security**: 安全性修复

---

[Unreleased]: https://github.com/pitchone/contracts/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/pitchone/contracts/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/pitchone/contracts/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/pitchone/contracts/releases/tag/v0.0.1
