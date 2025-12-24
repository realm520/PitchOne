# 项目文档索引

PitchOne 去中心化链上体育预测平台的完整技术文档。

## 📁 目录结构

```
docs/
├── design/              # 设计文档（架构、技术栈、实现方案）
├── test/               # 测试文档（测试报告、验证、技术债清理）
├── security/           # 安全文档（审计报告、安全扫描）
├── operation/          # 运营文档（部署、操作手册、变更日志）
├── README.md           # 本文件
├── marketing.md        # 市场营销文档
├── tech_marketing.md   # 技术营销文档
└── PARIMUTUEL_DEPLOYMENT_GUIDE.md  # Parimutuel 部署指南
```

## 📖 主要文档

### 🔥 最新报告
- **[📊 实现状态报告 (2025-11-11)](IMPLEMENTATION_STATUS_REPORT_2025-11-11.md)** - 完整的项目实现状态和质量报告
  - 19+ 个核心合约，1032 个测试，100% 通过率
  - 20,305+ 行核心代码 + 19,660+ 行测试
  - 详细的模块完成度分析和技术指标
- **[Parimutuel 部署指南](PARIMUTUEL_DEPLOYMENT_GUIDE.md)** - Parimutuel 模式部署与集成指南

### 快速开始
- **[项目初始化指南](operation/项目初始化指南.md)** - 开发环境搭建

### 设计文档 ([design/](design/))

**核心设计**:
- [01_MarketBase.md](design/01_MarketBase.md) - 市场基础合约设计
- [02_AMM_LinkedLines.md](design/02_AMM_LinkedLines.md) - AMM 和联动定价
- [03_ResultOracle_OO.md](design/03_ResultOracle_OO.md) - 预言机设计
- [04_Parlay_CorrelationGuard.md](design/04_Parlay_CorrelationGuard.md) - 串关系统
- [05_FeeRouter_Vault.md](design/05_FeeRouter_Vault.md) - 费用路由
- [06_Rewards_Referral_Campaign.md](design/06_Rewards_Referral_Campaign.md) - 奖励系统
- [07_ParamController_Governance.md](design/07_ParamController_Governance.md) - 参数治理
- [08_Offchain_Indexer_Keeper_RewardsBuilder.md](design/08_Offchain_Indexer_Keeper_RewardsBuilder.md) - 链下服务
- [09_Subgraph_Data_Analytics.md](design/09_Subgraph_Data_Analytics.md) - 数据索引
- [10_DevOps_Security_Runbook.md](design/10_DevOps_Security_Runbook.md) - 运维手册

**架构与技术**:
- [architect.md](design/architect.md) - 整体架构设计
- [blueprint.md](design/blueprint.md) - 项目蓝图
- [tech_stack.md](design/tech_stack.md) - 技术栈选型
- [project_mind.md](design/project_mind.md) - 项目思维导图

**实现文档**:
- [indexer-implementation.md](design/indexer-implementation.md) - Indexer 实现细节
- [OU_TEMPLATE_IMPLEMENTATION.md](design/OU_TEMPLATE_IMPLEMENTATION.md) - OU 模板实现
- [UMA_OO_INTEGRATION.md](design/UMA_OO_INTEGRATION.md) - UMA OO 集成指南
- [MARKET_TYPES_OVERVIEW.md](design/MARKET_TYPES_OVERVIEW.md) - 市场类型概览
- [M3_DEVELOPMENT_PLAN.md](design/M3_DEVELOPMENT_PLAN.md) - M3 开发计划
- [FRONTEND_RESTRUCTURE_PLAN.md](design/FRONTEND_RESTRUCTURE_PLAN.md) - 前端重构计划

### 测试文档 ([test/](test/))

- [E2E_TEST_SUMMARY.md](test/E2E_TEST_SUMMARY.md) - 端到端测试总结
- [TECH_DEBT_CLEANUP_2025-11-02.md](test/TECH_DEBT_CLEANUP_2025-11-02.md) - 技术债清理记录
- [verification/](test/verification/) - 验证文档目录
  - [demo-success.md](test/verification/demo-success.md) - 本地演示成功报告

### 安全文档 ([security/](security/))

- [audit-report.md](security/audit-report.md) - Slither 安全审计报告

### 运营文档 ([operation/](operation/))

**操作手册**:
- [operation.md](operation/operation.md) - 运营指南
- [项目初始化指南.md](operation/项目初始化指南.md) - 环境初始化
- [keeper-guide.md](operation/keeper-guide.md) - Keeper 服务操作指南

**部署文档**:
- [deployment/](operation/deployment/) - 部署脚本和说明
  - scripts-guide.md - 脚本使用指南

**变更记录**:
- [CHANGELOG.md](operation/CHANGELOG.md) - 项目变更日志
- [ADMIN_DASHBOARD_COMPLETE.md](operation/ADMIN_DASHBOARD_COMPLETE.md) - 管理后台完成报告
- [FRONTEND_MIGRATION_COMPLETE.md](operation/FRONTEND_MIGRATION_COMPLETE.md) - 前端迁移完成报告

### 接口文档

- [合约接口](../contracts/src/interfaces/) - 合约接口定义
- [Subgraph Schema](../subgraph/schema.graphql) - GraphQL Schema

## 🎯 按角色查阅

### 智能合约开发者
1. [design/01_MarketBase.md](design/01_MarketBase.md) - 了解市场合约设计
2. [design/02_AMM_LinkedLines.md](design/02_AMM_LinkedLines.md) - 定价引擎实现
3. [合约接口](../contracts/src/interfaces/) - 接口定义
4. [security/audit-report.md](security/audit-report.md) - 安全审计结果

### 后端开发者
1. [design/08_Offchain_Indexer_Keeper_RewardsBuilder.md](design/08_Offchain_Indexer_Keeper_RewardsBuilder.md) - 链下服务架构
2. [design/indexer-implementation.md](design/indexer-implementation.md) - Indexer 实现
3. [operation/keeper-guide.md](operation/keeper-guide.md) - Keeper 操作指南
4. [design/09_Subgraph_Data_Analytics.md](design/09_Subgraph_Data_Analytics.md) - 数据索引

### 前端开发者
1. [design/FRONTEND_RESTRUCTURE_PLAN.md](design/FRONTEND_RESTRUCTURE_PLAN.md) - 前端架构
2. [合约接口](../contracts/src/interfaces/) - 合约接口定义
3. [operation/FRONTEND_MIGRATION_COMPLETE.md](operation/FRONTEND_MIGRATION_COMPLETE.md) - 前端迁移完成
4. [design/MARKET_TYPES_OVERVIEW.md](design/MARKET_TYPES_OVERVIEW.md) - 市场类型说明

### 运维人员
1. [operation/项目初始化指南.md](operation/项目初始化指南.md) - 环境搭建
2. [operation/deployment/](operation/deployment/) - 部署文档
3. [design/10_DevOps_Security_Runbook.md](design/10_DevOps_Security_Runbook.md) - 运维手册
4. [operation/CHANGELOG.md](operation/CHANGELOG.md) - 变更日志

### 测试工程师
1. [IMPLEMENTATION_STATUS_REPORT_2025-11-11.md](IMPLEMENTATION_STATUS_REPORT_2025-11-11.md) - 最新完整测试报告
2. [test/E2E_TEST_SUMMARY.md](test/E2E_TEST_SUMMARY.md) - 端到端测试总结
3. [test/verification/](test/verification/) - 验证文档
4. [test/TECH_DEBT_CLEANUP_2025-11-02.md](test/TECH_DEBT_CLEANUP_2025-11-02.md) - 技术债清理

### 项目经理/产品经理
1. [IMPLEMENTATION_STATUS_REPORT_2025-11-11.md](IMPLEMENTATION_STATUS_REPORT_2025-11-11.md) - 项目完整状态报告
2. [design/blueprint.md](design/blueprint.md) - 项目蓝图
4. [marketing.md](marketing.md) - 市场策略

## 📊 项目状态

- **核心开发**: 🎉 **100% 完成**
- **合约完成度**: 100% (19+ 核心合约)
- **测试状态**: 1032/1032 测试通过 ✅ (100% 通过率)
- **市场模板**: 7/7 (WDL, OU, OU_MultiLine, AH, OddEven, Score, PlayerProps)
- **定价引擎**: 4/4 (SimpleCPMM + LMSR + LinkedLines + Parimutuel)
- **Subgraph**: v0.3.0 完整部署 ✅
- **安全扫描**: 0 高危/中危问题
- **代码量**: 20,305+ 行核心代码 + 19,660+ 行测试

详见 [📊 实现状态报告 (2025-11-11)](IMPLEMENTATION_STATUS_REPORT_2025-11-11.md)。

## 🔍 快速搜索

### 常见主题

- **市场模板**: `design/MARKET_TYPES_OVERVIEW.md`
- **定价引擎**: `design/02_AMM_LinkedLines.md`
- **预言机**: `design/03_ResultOracle_OO.md` + `design/UMA_OO_INTEGRATION.md`
- **串关系统**: `design/04_Parlay_CorrelationGuard.md`
- **奖励系统**: `design/06_Rewards_Referral_Campaign.md`
- **数据索引**: `design/09_Subgraph_Data_Analytics.md`
- **安全审计**: `security/audit-report.md`
- **部署指南**: `operation/deployment/scripts-guide.md`

### 技术栈

- **智能合约**: Solidity + Foundry
- **后端**: Go (Indexer + Keeper)
- **前端**: Next.js 15 + React 19 + wagmi 2
- **数据**: The Graph + PostgreSQL
- **基础设施**: Docker + K8s

详见 [design/tech_stack.md](design/tech_stack.md)。

## 📝 文档贡献

文档遵循以下原则：
- 使用 Markdown 格式
- 中文为主，代码和技术术语使用英文
- 保持目录结构清晰
- 及时更新过时内容

---

**最后更新**: 2025-12-24
**维护**: PitchOne 开发团队
