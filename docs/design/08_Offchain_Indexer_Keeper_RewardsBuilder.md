# 链下服务：Indexer / Keeper / Rewards Builder 详细设计（Go）

## 1. 概述
- **Indexer**：订阅链上事件 → Postgres/Timescale；幂等重放；
- **Keeper**：编排锁盘/预言机上报/争议/发布周度 root；
- **Rewards Builder**：聚合返佣/任务 → 计算 `scaleBps` → 生成 Merkle → 上链 root。

## 2. 数据与流程
- **订阅**：`BetPlaced/Locked/Resolved/Referral/Rewards/Basket` 等；
- **重放策略**：`fromBlock → toBlock`，处理 reorg（finalityBlocks），事件去重（txHash+logIndex）。
- **任务编排**：cron/条件触发，失败重试指数退避，幂等写入。

## 3. 配置与接口
- gRPC/HTTP 只读接口：市场快照、聚合指标、签名组装；
- 队列：NATS/Kafka（可选）；配置中心：环境变量 + 数据库参数表。

## 4. 监控与报警
- 事件延迟、订阅滞后、Keeper 失败率、Merkle 发布成功率；
- OTel Trace + Prom Metrics + Grafana 仪表盘。

## 5. 测试/运维
- 集成测试（anvil + seed）；断网/重启/重放演练；数据库迁移（migrate/rollback）。
