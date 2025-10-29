# FeeRouter 与 Vault（ERC-4626）详细设计

## 1. 概述
- FeeRouter 将手续费按权重分配至 LP Vault / Promo / Insurance / Treasury；
- Vault 采用 ERC-4626，LP 存入/赎回获得份额。

## 2. 数据与状态
- FeeRouter：`splits = {lp,promo,insurance,treasury}`（bps）
- Vault：`totalAssets/totalShares`；策略仅由治理调度，不对外暴露风险。

## 3. 接口
- FeeRouter：`setSplits(...)`（治理）、`route(marketId, amount)`（Market 调用）
- Vault：`deposit/withdraw/preview` 标准接口。

## 4. 事件
- `FeeRouted(marketId,toLP,toPromo,toInsurance,toTreasury)`
- Vault：`Deposit/Withdraw`。

## 5. 参数与安全
- 分账总和=10000bps；任何修改经 Timelock；
- 保险金库启用条件：极端事件补偿，需多签/提案。

## 6. 测试与运维
- 费路由正确性、极端小数；
- Vault 资产与份额守恒；APR 与费用入账对齐监控。
