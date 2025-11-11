# 创建所有市场类型实现指南

## 当前状态

已创建基础脚本 `CreateAllMarketTypes.s.sol`，目前支持：

| 市场类型 | 数量 | 状态 | 说明 |
|---------|------|------|------|
| WDL (胜平负) | 5 | ✅ 已实现 | 模板已注册，可直接创建 |
| OU (大小球单线) | 6 | ✅ 已实现 | 包含半球盘和整球盘 |
| OddEven (单双号) | 5 | ✅ 已实现 | 模板已注册，可直接创建 |
| OU_MultiLine (多线大小球) | 3 | ⏸️ 暂未实现 | 需要先注册模板 |
| AH (让球) | 5 | ⏸️ 暂未实现 | 需要先注册模板 |
| ScoreTemplate (精确比分) | 3 | ⏸️ 暂未实现 | 需要先注册模板 + 部署 LMSR |
| PlayerProps (球员道具) | 9 | ⏸️ 暂未实现 | 需要先注册模板 |

**当前可创建**: 16 个市场
**待实现**: 20 个市场
**总计目标**: 36 个市场

---

## 运行当前脚本

```bash
# 确保已运行 Deploy.s.sol 部署基础设施
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
  --rpc-url http://localhost:8545 --broadcast
```

---

## 完整实现步骤

### 第1步：更新 Deploy.s.sol 注册所有模板

需要在 `Deploy.s.sol` 中添加以下模板注册：

```solidity
// 添加导入
import "../src/templates/OU_MultiLine.sol";
import "../src/templates/AH_Template.sol";
import "../src/templates/ScoreTemplate.sol";
import "../src/templates/PlayerProps_Template.sol";
import "../src/pricing/LMSR.sol";
import "../src/pricing/LinkedLinesController.sol";

// 在 run() 函数中注册模板

// OU_MultiLine Template
OU_MultiLine ouMultiLineTemplate = new OU_MultiLine();
bytes32 ouMultiLineTemplateId = factory.registerTemplate("OU_MultiLine", "1.0.0", address(ouMultiLineTemplate));

// AH Template
AH_Template ahTemplate = new AH_Template();
bytes32 ahTemplateId = factory.registerTemplate("AH", "1.0.0", address(ahTemplate));

// ScoreTemplate (需要 LMSR)
LMSR lmsr = new LMSR();
ScoreTemplate scoreTemplate = new ScoreTemplate();
bytes32 scoreTemplateId = factory.registerTemplate("Score", "1.0.0", address(scoreTemplate));

// PlayerProps Template
PlayerProps_Template playerPropsTemplate = new PlayerProps_Template();
bytes32 playerPropsTemplateId = factory.registerTemplate("PlayerProps", "1.0.0", address(playerPropsTemplate));

// LinkedLinesController (for OU_MultiLine)
LinkedLinesController linkedLinesController = new LinkedLinesController(deployer);
```

### 第2步：更新 DeployedContracts 结构体

在 `Deploy.s.sol` 中添加新的合约地址字段：

```solidity
struct DeployedContracts {
    // ... 现有字段 ...
    address lmsr;
    address linkedLinesController;
    address ouMultiLineTemplate;
    address ahTemplate;
    address scoreTemplate;
    address playerPropsTemplate;
    bytes32 ouMultiLineTemplateId;
    bytes32 ahTemplateId;
    bytes32 scoreTemplateId;
    bytes32 playerPropsTemplateId;
}
```

### 第3步：更新 deployments/localhost.json

确保 JSON 文件包含所有模板 ID：

```json
{
  "contracts": {
    // ... 现有合约 ...
    "lmsr": "0x...",
    "linkedLinesController": "0x..."
  },
  "templates": {
    "wdl": "0x...",
    "ou": "0x...",
    "ouMultiLine": "0x...",
    "ah": "0x...",
    "oddEven": "0x...",
    "score": "0x...",
    "playerProps": "0x..."
  }
}
```

### 第4步：完善 CreateAllMarketTypes.s.sol

在脚本中实现剩余的市场创建函数：

#### 4.1 OU_MultiLine 市场

```solidity
function createOuMultiLineMarkets(
    MarketFactory_v2 factory,
    bytes32 templateId,
    address usdc,
    address feeRouter,
    address cpmm,
    address linkedLinesController
) internal returns (uint256) {
    // 3 个多线市场
    string[3] memory matchIds = [
        "EPL_ML_ARS_vs_MUN",
        "LAL_ML_BAR_vs_ATM",
        "BUN_ML_DOR_vs_RBL"
    ];

    // 每个市场的盘口线配置
    uint256[][3] memory allLines;

    // 市场1: 2.5, 3.5, 4.5
    uint256[] memory lines1 = new uint256[](3);
    lines1[0] = 2500; lines1[1] = 3500; lines1[2] = 4500;
    allLines[0] = lines1;

    // 市场2: 1.5, 2.5, 3.5
    uint256[] memory lines2 = new uint256[](3);
    lines2[0] = 1500; lines2[1] = 2500; lines2[2] = 3500;
    allLines[1] = lines2;

    // 市场3: 2.5, 3.5, 4.5, 5.5
    uint256[] memory lines3 = new uint256[](4);
    lines3[0] = 2500; lines3[1] = 3500; lines3[2] = 4500; lines3[3] = 5500;
    allLines[2] = lines3;

    for (uint256 i = 0; i < 3; i++) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint256[],address,address,uint256,uint256,address,address,string,address)",
            matchIds[i],
            homeTeams[i],
            awayTeams[i],
            block.timestamp + (i + 3) * 1 days,
            allLines[i],
            usdc,
            feeRouter,
            200,
            2 hours,
            cpmm,
            linkedLinesController,
            string(abi.encodePacked("https://api.pitchone.io/metadata/ou-ml/", matchIds[i])),
            msg.sender
        );

        address market = factory.createMarket(templateId, initData);
        console.log("   ", i + 1, matchIds[i], "->", market);
    }

    return 3;
}
```

#### 4.2 AH 让球市场

```solidity
function createAhMarkets(
    MarketFactory_v2 factory,
    bytes32 templateId,
    address usdc,
    address feeRouter,
    address cpmm
) internal returns (uint256) {
    // 5 个 AH 市场 (含半球盘和整球盘)
    string[5] memory matchIds = [
        "EPL_AH_LIV_vs_BUR",
        "EPL_AH_MCI_vs_SOU",
        "LAL_AH_BAR_vs_GET",
        "SER_AH_JUV_vs_NAP",
        "LIG_AH_LYO_vs_MON"
    ];
    int256[5] memory handicaps = [
        -1500, // -1.5 球 (半球盘)
        -1000, // -1.0 球 (整球盘)
        -500,  // -0.5 球 (半球盘)
        -2000, // -2.0 球 (整球盘)
        -2500  // -2.5 球 (半球盘)
    ];

    for (uint256 i = 0; i < 5; i++) {
        IAH_Template.HandicapType hType = (handicaps[i] % 1000 == 0)
            ? IAH_Template.HandicapType.WHOLE
            : IAH_Template.HandicapType.HALF;

        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,int256,uint8,address,address,uint256,uint256,address,string,address)",
            matchIds[i],
            homeTeams[i],
            awayTeams[i],
            block.timestamp + (i + 3) * 1 days,
            handicaps[i],
            uint8(hType),
            usdc,
            feeRouter,
            200,
            2 hours,
            cpmm,
            string(abi.encodePacked("https://api.pitchone.io/metadata/ah/", matchIds[i])),
            msg.sender
        );

        address market = factory.createMarket(templateId, initData);
        console.log("   ", i + 1, matchIds[i], handicaps[i]/1000, "->", market);
    }

    return 5;
}
```

#### 4.3 ScoreTemplate 市场

```solidity
function createScoreMarkets(
    MarketFactory_v2 factory,
    bytes32 templateId,
    address usdc,
    address feeRouter,
    address lmsr
) internal returns (uint256) {
    // 3 个精确比分市场
    string[3] memory matchIds = [
        "EPL_SC_CHE_vs_LIV",
        "LAL_SC_RMA_vs_SEV",
        "SER_SC_JUV_vs_INT"
    ];
    uint8[3] memory scoreRanges = [5, 4, 6]; // 0-5, 0-4, 0-6

    for (uint256 i = 0; i < 3; i++) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint256,uint8,address,address,uint256,uint256,address,uint256,string,address)",
            matchIds[i],
            homeTeams[i],
            awayTeams[i],
            block.timestamp + (i + 3) * 1 days,
            scoreRanges[i],
            usdc,
            feeRouter,
            200,
            2 hours,
            lmsr,
            10000 * 1e6, // liquidityB
            string(abi.encodePacked("https://api.pitchone.io/metadata/score/", matchIds[i])),
            msg.sender
        );

        address market = factory.createMarket(templateId, initData);
        console.log("   ", i + 1, matchIds[i], "range: 0-", scoreRanges[i], "->", market);
    }

    return 3;
}
```

#### 4.4 PlayerProps 市场

```solidity
function createPlayerPropsMarkets(
    MarketFactory_v2 factory,
    bytes32 templateId,
    address usdc,
    address feeRouter,
    address cpmm
) internal returns (uint256) {
    // 9 个球员道具市场，覆盖所有7种类型

    // PropType 枚举值
    uint8 GOALS_OU = 0;
    uint8 ASSISTS_OU = 1;
    uint8 SHOTS_OU = 2;
    uint8 YELLOW_CARD = 3;
    uint8 RED_CARD = 4;
    uint8 ANYTIME_SCORER = 5;

    string[9] memory matchIds = [
        "EPL_PP_HAALAND_GOALS_1_5",
        "EPL_PP_SALAH_GOALS_1_0",
        "EPL_PP_DEBRUYNE_ASSISTS",
        "EPL_PP_CASEMIRO_YELLOW",
        "LAL_PP_RAMOS_RED",
        "EPL_PP_KANE_SCORER",
        "SER_PP_VLAHOVIC_SHOTS",
        "LAL_PP_BENZEMA_GOALS",
        "BUN_PP_MUSIALA_GOALS"
    ];
    string[9] memory playerNames = [
        "Erling Haaland",
        "Mohamed Salah",
        "Kevin De Bruyne",
        "Casemiro",
        "Sergio Ramos",
        "Harry Kane",
        "Dusan Vlahovic",
        "Karim Benzema",
        "Jamal Musiala"
    ];
    uint8[9] memory propTypes = [
        GOALS_OU, GOALS_OU, ASSISTS_OU, YELLOW_CARD,
        RED_CARD, ANYTIME_SCORER, SHOTS_OU, GOALS_OU, GOALS_OU
    ];
    uint256[9] memory propLines = [
        1500, 1000, 500, 0, 0, 0, 2500, 500, 500
    ];

    for (uint256 i = 0; i < 9; i++) {
        bytes memory initData = abi.encodeWithSignature(
            "initialize(string,string,string,uint8,uint256,address,address,uint256,uint256,address,uint256,string,address)",
            matchIds[i],
            playerNames[i],
            "Match Info",
            propTypes[i],
            propLines[i],
            usdc,
            feeRouter,
            200,
            2 hours,
            cpmm,
            0, // liquidityB (not used for CPMM types)
            string(abi.encodePacked("https://api.pitchone.io/metadata/pp/", matchIds[i])),
            msg.sender
        );

        address market = factory.createMarket(templateId, initData);
        console.log("   ", i + 1, playerNames[i], "->", market);
    }

    return 9;
}
```

---

## 验证清单

部署完成后，验证以下内容：

- [ ] 所有 36 个市场成功创建
- [ ] Factory.getMarketCount() 返回正确数量
- [ ] 每个市场都被 Vault 授权（如适用）
- [ ] Subgraph 正确索引所有市场（检查 MarketCreated 事件）
- [ ] 可以通过 GraphQL 查询所有市场
- [ ] 每种市场类型至少有 3 个实例

---

## 注意事项

1. **LMSR 流动性参数**: ScoreTemplate 使用的 liquidityB 参数会影响价格敏感度，建议根据市场活跃度调整

2. **LinkedLinesController 配置**: OU_MultiLine 需要预先配置好联动参数，确保相邻线的价格联动正确

3. **PropType 细分**: PlayerProps 包含 7 种细分类型，确保每种至少创建 1 个示例

4. **半球盘 vs 整球盘**: OU 和 AH 都需要覆盖两种盘口类型，确保结算逻辑正确处理 Push 退款

5. **Gas 优化**: 如果批量创建市场，可以考虑分批部署以避免 Gas 限制

---

## 下一步

1. 更新 `Deploy.s.sol` 注册所有模板
2. 重新部署测试环境：`forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast`
3. 完善 `CreateAllMarketTypes.s.sol` 添加剩余市场创建函数
4. 运行脚本创建所有市场
5. 验证 Subgraph 正确索引
6. 运行 `SimulateBets.s.sol` 生成测试下注数据

---

**最后更新**: 2025-11-09
**脚本版本**: v1.0.0 (基础版，支持 WDL/OU/OddEven)
