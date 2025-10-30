# PitchOne 项目文档

本目录包含 PitchOne 去中心化链上足球博彩平台的所有技术文档。

## 📁 文档结构

```
docs/
├── README.md                    # 本文件 - 文档导航索引
│
├── 项目概览
│   ├── intro.md                 # 项目介绍（面向技术受众）
│   ├── project_mind.md          # 架构思维导图
│   ├── progress.md              # 开发进度追踪
│   └── 任务追踪.md               # 详细任务清单
│
├── design/                      # 📐 技术设计文档
│   ├── 01_整体架构设计.md
│   ├── 02_市场合约设计.md
│   ├── 03_定价引擎设计.md
│   ├── 04_预言机设计.md
│   ├── 05_串关(Parlay)设计.md
│   ├── 06_费用路由设计.md
│   ├── 07_推荐与奖励设计.md
│   ├── 08_活动与任务设计.md
│   ├── 09_治理与参数控制设计.md
│   └── 10_链下服务设计.md
│
├── 模块接口事件参数/           # 📋 接口规范
│   ├── EVENT_DICTIONARY.md      # 事件字典（所有合约事件）
│   └── SUBGRAPH_SCHEMA.graphql  # Subgraph Schema 定义
│
├── deployment/                  # 🚀 部署文档
│   └── scripts-guide.md         # 部署和演示脚本使用指南
│
├── security/                    # 🔒 安全文档
│   └── audit-report.md          # Slither 安全审计报告
│
├── operations/                  # ⚙️ 运营指南
│   └── keeper-guide.md          # Keeper 服务权限和操作指南
│
└── verification/                # ✅ 验证报告
    └── demo-success.md          # 本地演示成功验证报告
```

## 📚 快速导航

### 新手入门
1. 📖 [项目介绍](intro.md) - 了解项目背景、技术栈和核心特性
2. 🗺️ [架构思维导图](project_mind.md) - 快速理解整体架构
3. 🚀 [部署脚本指南](deployment/scripts-guide.md) - 本地部署和演示

### 合约开发
1. 📐 [整体架构设计](design/01_整体架构设计.md) - 系统架构概览
2. 📐 [市场合约设计](design/02_市场合约设计.md) - 核心市场逻辑
3. 📐 [定价引擎设计](design/03_定价引擎设计.md) - AMM/LMSR 定价机制
4. 📋 [事件字典](模块接口事件参数/EVENT_DICTIONARY.md) - 所有合约事件规范

### 链下服务开发
1. 📐 [链下服务设计](design/10_链下服务设计.md) - Indexer/Keeper/Rewards 架构
2. 📋 [Subgraph Schema](模块接口事件参数/SUBGRAPH_SCHEMA.graphql) - 数据层定义
3. ⚙️ [Keeper 操作指南](operations/keeper-guide.md) - Keeper 服务运行指南

### 质量保证
1. 🔒 [安全审计报告](security/audit-report.md) - Slither 静态分析结果
2. ✅ [演示验证报告](verification/demo-success.md) - 完整流程验证
3. 📊 [开发进度追踪](progress.md) - 当前进度和质量指标

### 高级主题
1. 📐 [串关(Parlay)设计](design/05_串关(Parlay)设计.md) - 组合下注和相关性控制
2. 📐 [预言机设计](design/04_预言机设计.md) - UMA OO 乐观式结算
3. 📐 [治理与参数控制](design/09_治理与参数控制设计.md) - 链上治理机制
4. 📐 [推荐与奖励设计](design/07_推荐与奖励设计.md) - 增长激励机制

## 🔍 按角色查找文档

### 智能合约开发者
- [市场合约设计](design/02_市场合约设计.md)
- [定价引擎设计](design/03_定价引擎设计.md)
- [事件字典](模块接口事件参数/EVENT_DICTIONARY.md)
- [安全审计报告](security/audit-report.md)
- [部署脚本指南](deployment/scripts-guide.md)

### 后端开发者
- [链下服务设计](design/10_链下服务设计.md)
- [Subgraph Schema](模块接口事件参数/SUBGRAPH_SCHEMA.graphql)
- [Keeper 操作指南](operations/keeper-guide.md)
- [事件字典](模块接口事件参数/EVENT_DICTIONARY.md)

### 前端开发者
- [项目介绍](intro.md)
- [Subgraph Schema](模块接口事件参数/SUBGRAPH_SCHEMA.graphql)
- [部署脚本指南](deployment/scripts-guide.md)
- [演示验证报告](verification/demo-success.md)

### 产品经理 / 项目管理
- [项目介绍](intro.md)
- [架构思维导图](project_mind.md)
- [开发进度追踪](progress.md)
- [任务追踪](任务追踪.md)

### 安全审计员
- [整体架构设计](design/01_整体架构设计.md)
- [安全审计报告](security/audit-report.md)
- [事件字典](模块接口事件参数/EVENT_DICTIONARY.md)
- 所有 design/ 目录下的设计文档

## 📝 文档更新记录

### 2025-10-29
- ✅ **文档重组**: 将所有文档集中到 `docs/` 目录
- ✅ **新增分类**: 创建 deployment, security, operations, verification 子目录
- ✅ **路径迁移**:
  - `contracts/SECURITY_AUDIT.md` → `docs/security/audit-report.md`
  - `contracts/KEEPER_GUIDE.md` → `docs/operations/keeper-guide.md`
  - `contracts/DEMO_SUCCESS.md` → `docs/verification/demo-success.md`
  - `contracts/script/README.md` → `docs/deployment/scripts-guide.md`
- ✅ **新增文档**: 创建 `docs/README.md` (本文件)

### Week 1-2 (完成)
- ✅ 核心合约设计文档（02-03-06）
- ✅ 安全审计报告
- ✅ Keeper 操作指南
- ✅ 演示验证报告
- ✅ 部署脚本指南

### Week 3-4 (规划中)
- ⏳ 预言机详细设计
- ⏳ 运营监控指南
- ⏳ 测试网部署指南

## 🤝 贡献指南

### 文档维护原则
1. **集中管理**: 所有项目文档必须放在 `docs/` 目录下
2. **分类清晰**: 按功能分类放入相应子目录
3. **命名规范**: 使用清晰描述性的文件名（kebab-case）
4. **交叉引用**: 文档间引用使用相对路径
5. **及时更新**: 代码变更时同步更新相关文档

### 新增文档流程
1. 确定文档类型和所属分类
2. 在对应子目录创建文档
3. 更新本 README.md 的文档结构和导航
4. 在 `progress.md` 中记录文档产出

### 文档审查清单
- [ ] 文档放在正确的分类目录下
- [ ] 文件名符合命名规范
- [ ] 在 README.md 中添加了导航链接
- [ ] 交叉引用的路径正确
- [ ] 内容完整、格式规范
- [ ] 在 progress.md 中记录

## 📞 联系方式

如有文档相关问题，请通过以下方式反馈：
- 📧 提交 Issue
- 💬 项目讨论群
- 📝 Pull Request

---

**最后更新**: 2025-10-29
**维护者**: PitchOne 开发团队
