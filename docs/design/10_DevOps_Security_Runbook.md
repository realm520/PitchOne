# DevOps / Security / Runbook 详细设计

## 1. CI/CD
- GH Actions：Solidity（Foundry/coverage/Slither/Echidna）、Go（unit/integration）、Docker/Helm 部署到 `dev→testnet→staging→prod`。

## 2. IaC & 环境
- Terraform 管理节点与仓库；Helm chart 管理服务；按环境分层 values。

## 3. 秘钥与权限
- Vault/KMS 统一管理；部署使用临时会话密钥；合约权限用 Safe 多签 + Timelock。

## 4. 可观测
- OTel Trace、Prom 指标、Grafana 仪表盘模板；Tenderly/Forta 警报。

## 5. 安全策略
- 变更门禁（测试/覆盖率/不变量/静态分析必须通过）；外审与漏洞赏金；
- 紧急暂停：仅停新建，不影响兑付；回滚流程与灰度策略。

## 6. Runbook（演练）
- 锁盘失败、无人上报、争议风暴、预算透支、价格异常、reorg 重放；
- 每季度灾备演练与权限复核。
