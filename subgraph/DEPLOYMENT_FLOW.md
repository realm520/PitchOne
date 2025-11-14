# PitchOne 本地部署流程图

本文档提供可视化的部署流程说明。

## 🔄 完整部署流程（时序图）

```mermaid
sequenceDiagram
    participant U as 用户
    participant A as Anvil 测试链
    participant D as Deploy.s.sol
    participant F as Factory 合约
    participant C as CreateMarkets_NoMultiLine.s.sol
    participant S as SimulateBets.s.sol
    participant G as Graph Node
    participant SG as Subgraph

    Note over U,SG: 步骤 1: 启动 Anvil
    U->>A: anvil --host 0.0.0.0
    A-->>U: 监听 localhost:8545

    Note over U,SG: 步骤 2: 部署核心合约
    U->>D: forge script Deploy.s.sol
    D->>A: 部署 USDC 合约
    D->>A: 部署 Vault 合约
    D->>A: 部署 FeeRouter 合约
    D->>A: 部署 Factory 合约
    D->>A: 部署 7 种市场模板
    D->>A: 注册模板到 Factory
    D-->>U: 生成 deployments/localhost.json

    Note over U,SG: 步骤 3: 创建测试市场
    U->>C: forge script CreateMarkets_NoMultiLine.s.sol
    C->>F: createMarket(WDL_TEMPLATE_ID, initData)
    F->>A: 部署 WDL 市场 × 3
    C->>F: createMarket(OU_TEMPLATE_ID, initData)
    F->>A: 部署 OU 市场 × 3
    C->>F: createMarket(AH_TEMPLATE_ID, initData)
    F->>A: 部署 AH 市场 × 3
    C->>F: createMarket(ODDEVEN_TEMPLATE_ID, initData)
    F->>A: 部署 OddEven 市场 × 3
    C->>F: createMarket(SCORE_TEMPLATE_ID, initData)
    F->>A: 部署 Score 市场 × 3
    C->>A: vault.authorizeMarket(市场地址) × 15
    C-->>U: 创建完成: 15 个市场

    Note over U,SG: 步骤 4: 模拟投注数据
    U->>S: forge script SimulateBets.s.sol
    S->>F: getMarketCount()
    F-->>S: 15
    loop 每个市场
        loop 每个用户 (5 个)
            loop 每次投注 (2 次)
                S->>A: usdc.mint(user, amount)
                S->>A: usdc.approve(market, amount)
                S->>A: market.placeBet(outcome, amount)
                A-->>S: BetPlaced 事件
            end
        end
    end
    S-->>U: 完成: 83 笔投注, 2,587 USDC

    Note over U,SG: 步骤 5: 部署 Subgraph
    U->>SG: 更新 subgraph.yaml (Factory/FeeRouter 地址)
    U->>SG: graph codegen
    SG-->>U: 生成 TypeScript 代码
    U->>SG: graph build
    SG-->>U: 编译完成
    U->>G: graph deploy
    G->>A: 订阅 Factory.MarketCreated 事件
    G->>A: 订阅 FeeRouter.FeeRouted 事件

    Note over U,SG: 步骤 6: 数据同步
    loop 索引历史区块
        A-->>G: 返回 MarketCreated 事件 × 15
        G->>SG: 创建 Market 实体 × 15
        A-->>G: 返回 BetPlaced 事件 × 83
        G->>SG: 创建 Order/Position 实体 × 83
        G->>SG: 更新 User 实体 × 5
        G->>SG: 更新 GlobalStats
    end
    G-->>U: 同步完成

    Note over U,SG: 步骤 7: 验证数据
    U->>SG: GraphQL 查询 markets
    SG-->>U: 返回 15 个市场
    U->>SG: GraphQL 查询 globalStats
    SG-->>U: 返回全局统计
```

## 📊 数据流向图

```mermaid
flowchart TB
    subgraph 链上合约
        USDC[USDC Token]
        Vault[Liquidity Vault]
        FeeRouter[Fee Router]
        Factory[Market Factory]

        subgraph 市场模板
            WDL[WDL Template]
            OU[OU Template]
            AH[AH Template]
            OddEven[OddEven Template]
            Score[Score Template]
        end

        subgraph 市场实例
            M1[Market 1: WDL]
            M2[Market 2: OU]
            M3[Market 3: AH]
            M_etc[... × 15]
        end
    end

    subgraph 链下索引
        GraphNode[Graph Node]
        PostgreSQL[(PostgreSQL)]
        IPFS[IPFS]
    end

    subgraph 前端应用
        Frontend[Next.js Frontend]
        GraphQL[GraphQL Client]
    end

    Factory -->|创建市场| M1
    Factory -->|创建市场| M2
    Factory -->|创建市场| M3
    Factory -->|创建市场| M_etc

    M1 -->|BetPlaced 事件| GraphNode
    M2 -->|BetPlaced 事件| GraphNode
    M3 -->|BetPlaced 事件| GraphNode
    FeeRouter -->|FeeRouted 事件| GraphNode

    GraphNode -->|写入| PostgreSQL
    GraphNode -->|存储 Manifest| IPFS

    Frontend -->|GraphQL 查询| GraphNode
    GraphNode -->|返回数据| Frontend

    style Factory fill:#ff6b6b
    style GraphNode fill:#4ecdc4
    style Frontend fill:#95e1d3
```

## 🔐 权限与依赖关系图

```mermaid
graph TD
    subgraph 核心基础设施
        A[Anvil 测试链<br/>localhost:8545]
        D[Docker<br/>Graph Node + PostgreSQL]
    end

    subgraph 合约层
        Deploy[Deploy.s.sol]
        Factory[MarketFactory]
        Markets[15 个市场实例]

        Deploy -->|部署| Factory
        Factory -->|授权| Markets
    end

    subgraph 数据层
        CreateMarkets[CreateMarkets_NoMultiLine.s.sol]
        SimulateBets[SimulateBets.s.sol]

        CreateMarkets -->|调用| Factory
        SimulateBets -->|读取| Factory
        SimulateBets -->|调用| Markets
    end

    subgraph Subgraph 层
        SubgraphYAML[subgraph.yaml<br/>配置 Factory 地址]
        Codegen[graph codegen]
        Build[graph build]
        DeployGraph[graph deploy]

        SubgraphYAML --> Codegen
        Codegen --> Build
        Build --> DeployGraph
    end

    subgraph 验证层
        Query[GraphQL 查询]
        Playground[GraphQL Playground<br/>localhost:8010]

        DeployGraph --> Query
        Query --> Playground
    end

    A -.->|提供 RPC| Deploy
    A -.->|提供 RPC| CreateMarkets
    A -.->|提供 RPC| SimulateBets
    A -.->|订阅事件| D
    D -.->|索引区块| DeployGraph

    style A fill:#ffe66d
    style D fill:#a8dadc
    style Factory fill:#ff6b6b
    style DeployGraph fill:#4ecdc4
```

## 🚀 快速部署决策树

```mermaid
flowchart TD
    Start([开始部署]) --> CheckAnvil{Anvil<br/>是否运行?}

    CheckAnvil -->|否| StartAnvil[启动 Anvil<br/>anvil --host 0.0.0.0]
    CheckAnvil -->|是| CheckDocker{Docker<br/>是否运行?}

    StartAnvil --> CheckDocker

    CheckDocker -->|否| StartDocker[启动 Docker<br/>systemctl start docker]
    CheckDocker -->|是| RunScript[运行快速部署脚本<br/>./scripts/quick-deploy.sh]

    StartDocker --> RunScript

    RunScript --> Step1[步骤 1: 部署合约]
    Step1 --> Check1{部署<br/>成功?}
    Check1 -->|否| Error1[检查错误日志<br/>查看 Foundry 输出]
    Check1 -->|是| Step2[步骤 2: 创建市场]

    Step2 --> Check2{市场数量<br/>= 15?}
    Check2 -->|否| Error2[检查 Factory 地址<br/>查看 localhost.json]
    Check2 -->|是| Step3[步骤 3: 模拟投注]

    Step3 --> Check3{投注<br/>成功?}
    Check3 -->|否| Error3[检查流动性<br/>查看 Vault 余额]
    Check3 -->|是| Step4[步骤 4: 部署 Subgraph]

    Step4 --> Check4{Subgraph<br/>部署成功?}
    Check4 -->|否| Error4[检查 Graph Node<br/>查看 Docker 日志]
    Check4 -->|是| Verify[步骤 5: 验证数据]

    Verify --> Query[GraphQL 查询<br/>markets/users/globalStats]
    Query --> Check5{数据<br/>完整?}

    Check5 -->|否| Debug[检查同步状态<br/>查看 _meta.block.number]
    Check5 -->|是| Success([🎉 部署成功!])

    Error1 --> Fix1[修复合约问题] --> RunScript
    Error2 --> Fix2[修复市场创建] --> Step2
    Error3 --> Fix3[增加流动性] --> Step3
    Error4 --> Fix4[重启 Graph Node] --> Step4
    Debug --> Wait[等待同步完成<br/>5-15 秒] --> Verify

    style Start fill:#95e1d3
    style Success fill:#6bcf7f
    style Error1 fill:#ff6b6b
    style Error2 fill:#ff6b6b
    style Error3 fill:#ff6b6b
    style Error4 fill:#ff6b6b
```

## 📋 检查清单

### 部署前检查

- [ ] Anvil 已启动并监听 `localhost:8545`
- [ ] Docker 已启动并运行正常
- [ ] 项目依赖已安装（`forge`, `graph-cli`, `jq`）
- [ ] `scripts/quick-deploy.sh` 有执行权限

### 部署后验证

- [ ] `deployments/localhost.json` 存在且包含所有合约地址
- [ ] Factory 合约的 `getMarketCount()` 返回 15
- [ ] Subgraph 可通过 `http://localhost:8010` 访问
- [ ] GraphQL 查询返回 15 个市场
- [ ] `globalStats.totalVolume` ≈ 2,587 USDC
- [ ] `globalStats.totalUsers` = 5

### 常见错误检查

- [ ] 端口冲突：8545 (Anvil), 8010/8020/8030 (Graph Node), 5001 (IPFS)
- [ ] 合约地址不匹配：`subgraph.yaml` 与 `localhost.json` 一致
- [ ] Subgraph 版本：确保使用最新的 schema 和 mapping
- [ ] 区块同步：`_meta.block.number` 达到当前区块高度

## 🔗 相关资源

- [完整 SOP 文档](./SOP_LOCAL_DEPLOYMENT.md)
- [快速部署脚本](../scripts/quick-deploy.sh)
- [Subgraph Schema](./schema.graphql)
- [合约部署说明](../contracts/README.md)

---

**最后更新**: 2025-11-14
**验证环境**: Anvil (Foundry), Graph Node v0.34.1, PostgreSQL 14
