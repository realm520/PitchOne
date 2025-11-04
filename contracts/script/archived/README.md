# 归档脚本

这些脚本是过时的或已被新脚本替代的 Forge 部署/测试脚本。

**归档日期**: 2025-11-03

---

## 归档原因

这些脚本在开发过程中被使用，但现在已被更完整、更清晰的脚本所替代。它们被保留在这里作为历史记录和参考。

---

## 归档的脚本列表

1. **AddPushLiquidity.s.sol** - 功能已被 TestLiquidity.s.sol 替代
2. **CompleteLifecycle.s.sol** - 被 TestFullLifecycle.s.sol 替代
3. **CreateMarketsViaRegistry.s.sol** - 使用旧的 Registry 方法
4. **CreateMarketsWithRecord.s.sol** - 被 CreateTestMarkets.s.sol 替代
5. **DeployBatchMarkets.s.sol** - 过时的批量部署脚本
6. **DeployCompleteSystem.s.sol** - 被 DeployToAnvil.s.sol 替代
7. **DeployDiverseMarkets.s.sol** - 过时的演示脚本
8. **DeployMultiMarketDemo.s.sol** - 过时的演示脚本
9. **DeployNewMarket.s.sol** - 功能已整合到 CreateTestMarkets.s.sol
10. **DeployOUMarket.s.sol** - 功能已整合到 CreateTestMarkets.s.sol
11. **DeployViaRegistry.s.sol** - 使用旧的部署方法
12. **DeployWithFactory.s.sol** - 被 DeployToAnvil.s.sol 替代
13. **DeployWithUMAOracle.s.sol** - UMA 集成未完成（M2 计划）
14. **FinalizeMarket.s.sol** - 功能已整合到 TestFullLifecycle.s.sol
15. **MultiUserBetting.s.sol** - 功能已整合到 TestFullLifecycle.s.sol
16. **MultiUserRedemption.s.sol** - 功能已整合到 TestFullLifecycle.s.sol
17. **RedeemWinnings.s.sol** - 功能已整合到 TestFullLifecycle.s.sol
18. **TestMarketLifecycle.s.sol** - 被 TestFullLifecycle.s.sol 替代

---

## 使用建议

**不建议使用这些脚本**，除非你需要：
1. 查看旧的实现方法
2. 调试历史代码
3. 了解项目演进过程

如需部署和测试，请使用上级目录中的核心脚本：
- `DeployToAnvil.s.sol`
- `CreateTestMarkets.s.sol`
- `TestFullLifecycle.s.sol`
- `TestLiquidity.s.sol`

---

## 删除策略

这些文件将在以下情况下被永久删除：
- M2 阶段完成后（确认不再需要参考）
- 代码库达到稳定版本 v1.0
- 团队确认不再需要历史记录

在此之前，它们将保留在 `archived/` 目录中。

---

**归档者**: Claude Code
**日期**: 2025-11-03
