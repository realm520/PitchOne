# LinkedLinesController 使用指南

## 概述

LinkedLinesController 是**OU（大小球）/AH（让球）多线市场的联动定价控制器**，通过联动系数和价差限制确保相邻盘口线之间的价格一致性，防止套利机会。

**核心功能**：
- 管理多条相关联的盘口线（如 OU 2.0、2.5、3.0 球）
- 维持相邻线之间的合理价差
- 检测并防止跨线套利
- 动态调整储备量以保持价格平滑

## 快速开始

### 1. 部署 LinkedLinesController

```solidity
// 先部署 ParamController
ParamController paramController = new ParamController(admin, 2 days);

// 部署 LinkedLinesController
LinkedLinesController controller = new LinkedLinesController(
    admin,                       // 管理员地址（Safe 多签）
    address(paramController)     // ParamController 地址
);

// 授予操作员角色（用于调整储备量）
controller.grantRole(controller.OPERATOR_ROLE(), operator);
```

### 2. 创建线组

```solidity
// 创建 OU 市场的线组（2.0、2.5、3.0 球）
bytes32 groupId = keccak256("OU_MATCH_123");
uint256[] memory lines = new uint256[](3);
lines[0] = 2000;  // 2.0 球
lines[1] = 2500;  // 2.5 球
lines[2] = 3000;  // 3.0 球

controller.createLineGroup(groupId, lines);
```

### 3. 配置每条线

```solidity
// 为每条线配置 CPMM 合约和初始储备量
controller.configureLine(
    groupId,
    2000,                  // 线值（2.0 球）
    address(cpmm20),       // 对应的 CPMM 合约
    1000e18,              // 基础储备量 0
    1000e18               // 基础储备量 1
);

controller.configureLine(groupId, 2500, address(cpmm25), 1000e18, 1000e18);
controller.configureLine(groupId, 3000, address(cpmm30), 1000e18, 1000e18);
```

### 4. 配置联动关系

```solidity
// 配置 2.0 球与 2.5 球之间的联动
controller.configureLink(
    groupId,
    2000,      // 较低的线
    2500,      // 较高的线
    8000,      // 联动系数（80%）
    50,        // 最小价差（0.5%）
    500        // 最大价差（5%）
);

// 配置 2.5 球与 3.0 球之间的联动
controller.configureLink(groupId, 2500, 3000, 8000, 50, 500);
```

### 5. 查询联动后的价格

```solidity
// 准备储备量参数
uint256[] memory reserves = new uint256[](2);
reserves[0] = 1000e18;
reserves[1] = 1000e18;

// 查询单条线的价格
uint256 price = controller.getLinkedPrice(
    groupId,
    2000,      // 线值
    0,         // 结果方向（0 = OVER, 1 = UNDER）
    reserves   // 当前储备量
);

// 批量查询所有线的价格
uint256[][] memory allReserves = new uint256[][](3);
// ... 准备所有线的储备量 ...

(uint256[] memory lines, uint256[] memory prices) =
    controller.getAllLinkedPrices(groupId, 0, allReserves);
```

### 6. 检测套利机会

```solidity
// 检测是否存在套利
(bool hasArbitrage, uint256 line1, uint256 line2, uint256 profitBps) =
    controller.detectArbitrage(groupId, allReserves);

if (hasArbitrage) {
    console.log("套利检测：线 %s 和 %s 之间存在套利，利润 %s bp", line1, line2, profitBps);

    // 调整储备量以消除套利
    controller.adjustReserves(groupId, line1, newReserve0, newReserve1);
}
```

## 核心概念

### 线组（Line Group）

线组是一组相关联的盘口线，例如：
- **OU 市场**：2.0、2.5、3.0 球
- **AH 市场**：-0.5、0、+0.5 球

每个线组包含：
- **groupId**：唯一标识符（如 `keccak256("OU_MATCH_123")`）
- **lines**：线数组（必须从小到大排序）
- **lineConfigs**：每条线的配置（CPMM 地址、储备量）

### 联动系数（Link Coefficient）

联动系数定义相邻线之间的价格关联度，取值范围 50%-100%（5000-10000 基点）。

**示例**：
- 如果 2.0 球 OVER 价格是 60%
- 联动系数 80%
- 则 2.5 球 OVER 价格应该约为 60% × 80% = 48%

### 价差限制（Spread Limits）

价差限制确保相邻线之间的价格差异在合理范围内：
- **minSpread**：最小价差（防止价格过于接近）
- **maxSpread**：最大价差（防止价格差异过大）

**示例**：
- minSpread = 50 (0.5%)
- maxSpread = 500 (5%)
- 如果 2.0 球 OVER 价格 52%，2.5 球 OVER 价格 50%
- 价差 = (52-50)/52 = 3.8%（在范围内）

### 套利检测逻辑

系统检测两种套利情况：

1. **价格反转**：高线 OVER 价格 ≥ 低线 OVER 价格
   - 例如：3.0 球 OVER 价格 60%，2.0 球 OVER 价格 55%（不合理！）

2. **价差超限**：相邻线价差 < minSpread 或 > maxSpread
   - 例如：价差 8%  > maxSpread 5%（套利空间过大）

## 使用场景

### 场景 1：创建 OU 多线市场

```solidity
// 曼联 vs 利物浦，提供 2.0、2.5、3.0 球大小盘
bytes32 groupId = keccak256("OU_MATCH_MANUTD_LIVERPOOL_20250115");

uint256[] memory lines = new uint256[](3);
lines[0] = 2000;
lines[1] = 2500;
lines[2] = 3000;

controller.createLineGroup(groupId, lines);

// 配置每条线（假设初始概率均为 50%）
for (uint256 i = 0; i < lines.length; i++) {
    SimpleCPMM cpmm = new SimpleCPMM();
    controller.configureLine(groupId, lines[i], address(cpmm), 1000e18, 1000e18);
}

// 配置联动关系
controller.configureLink(groupId, 2000, 2500, 8000, 50, 500);
controller.configureLink(groupId, 2500, 3000, 8000, 50, 500);
```

### 场景 2：动态调整价格

```solidity
// 场景：大量用户下注 2.0 球 OVER，导致价格失衡

// 1. 获取当前所有线的储备量
uint256[][] memory allReserves = new uint256[][](3);
for (uint256 i = 0; i < 3; i++) {
    SimpleCPMM cpmm = SimpleCPMM(controller.getLineConfig(groupId, lines[i]).cpmm);
    (allReserves[i][0], allReserves[i][1]) = cpmm.getReserves();
}

// 2. 检测套利
(bool hasArbitrage, uint256 line1, uint256 line2, uint256 profitBps) =
    controller.detectArbitrage(groupId, allReserves);

if (hasArbitrage) {
    // 3. 调整储备量（运营商操作）
    // 例如：增加 2.0 球的 UNDER 储备，降低 OVER 价格
    controller.adjustReserves(groupId, 2000, 1200e18, 800e18);
}
```

### 场景 3：AH 市场联动

```solidity
// 曼城 (-0.5) vs 纽卡斯尔 (+0.5)
bytes32 groupId = keccak256("AH_MATCH_MANCITY_NEWCASTLE_20250115");

uint256[] memory lines = new uint256[](3);
lines[0] = 9500;  // -0.5 球
lines[1] = 10000; // 0 球（平手盘）
lines[2] = 10500; // +0.5 球

controller.createLineGroup(groupId, lines);

// 配置联动（AH 市场联动系数通常更高，如 90%）
controller.configureLink(groupId, 9500, 10000, 9000, 50, 300);
controller.configureLink(groupId, 10000, 10500, 9000, 50, 300);
```

## 与 ParamController 集成

LinkedLinesController 可以从 ParamController 读取动态参数：

```solidity
// 注册联动系数参数
bytes32 key = keccak256(abi.encodePacked("LINK_COEFF_", 2000, "_", 2500));
paramController.registerParam(key, 8000, address(0));  // 默认 80%

// 运营期间可以通过治理调整
paramController.proposeChange(key, 8500, "调整 2.0-2.5 球联动系数为 85%");

// LinkedLinesController 会自动读取最新值
uint256 coefficient = controller.getLinkCoefficient(2000, 2500);  // 返回 8500
```

## 查询函数

### getLineGroup

```solidity
(uint256[] memory lines, bool isActive) = controller.getLineGroup(groupId);
```

### getLineConfig

```solidity
LinkedLinesController.LineConfig memory config = controller.getLineConfig(groupId, 2000);

console.log("线值:", config.line);
console.log("CPMM:", config.cpmm);
console.log("储备量 0:", config.baseReserve0);
console.log("储备量 1:", config.baseReserve1);
```

### getAllGroupIds

```solidity
bytes32[] memory allIds = controller.getAllGroupIds();

for (uint256 i = 0; i < allIds.length; i++) {
    (uint256[] memory lines, bool isActive) = controller.getLineGroup(allIds[i]);
    console.log("线组 %s 包含 %s 条线", allIds[i], lines.length);
}
```

## 角色权限

- **DEFAULT_ADMIN_ROLE**: 管理员（管理角色、创建线组、配置联动）
- **ADMIN_ROLE**: 管理员（创建线组、配置线和联动）
- **OPERATOR_ROLE**: 操作员（调整储备量）

## 最佳实践

1. **线组设计**
   - 每个赛事的每种玩法创建独立线组
   - 线值必须严格从小到大排序
   - 建议每个线组包含 2-5 条线

2. **联动配置**
   - OU 市场联动系数：70%-85%
   - AH 市场联动系数：85%-95%
   - minSpread：0.5%-1%
   - maxSpread：3%-5%

3. **储备量管理**
   - 定期检测套利（建议每 5 分钟）
   - 开赛前 1 小时停止调整
   - 记录所有调整操作（通过事件）

4. **价格计算**
   - 始终使用最新的储备量
   - 考虑滑点和手续费影响
   - 缓存价格以减少链上查询

5. **套利防范**
   - 启用实时套利检测
   - 设置合理的价差限制
   - 配合风控系统限制单用户敞口

## 事件监听

```javascript
// 监听线组创建
controller.on("LineGroupCreated", (groupId, lines) => {
    console.log(`新线组 ${groupId} 创建，包含 ${lines.length} 条线`);
});

// 监听储备量调整
controller.on("ReservesAdjusted", (groupId, line, oldReserve0, oldReserve1, newReserve0, newReserve1) => {
    console.log(`线 ${line} 储备量调整：(${oldReserve0}, ${oldReserve1}) → (${newReserve0}, ${newReserve1})`);
});

// 监听套利检测
controller.on("ArbitrageDetected", (groupId, line1, line2, profitBps) => {
    console.log(`⚠️  检测到套利：线 ${line1} 和 ${line2}，利润 ${profitBps} bp`);
});
```

## 测试覆盖

- **测试数量**: 19 个（全部通过）
- **覆盖范围**:
  - 线组管理：创建、查询
  - 线配置：单线配置、错误处理
  - 联动配置：系数验证、价差验证
  - 价格计算：单线价格、批量价格
  - 套利检测：无套利、价格反转
  - 储备量调整：权限控制
  - 参数查询：ParamController 集成

## 安全考虑

1. ✅ 角色权限分离（Admin / Operator）
2. ✅ 线值排序验证（防止配置错误）
3. ✅ 联动系数范围限制（50%-100%）
4. ✅ 价差范围验证（minSpread < maxSpread）
5. ✅ 储备量长度匹配检查
6. ✅ 完整的事件日志
7. ✅ 套利实时检测

## 性能优化

- 使用 `calldata` 传递储备量数组（节省 Gas）
- 内联简化套利检测逻辑（避免 Stack too deep）
- 使用 `unchecked` 优化循环计数器
- 批量操作减少链上调用次数

## 下一步

- [ ] 集成到 OU_Template（多线扩展）
- [ ] 集成到 AH_Template
- [ ] 添加自动化调整策略（Keeper）
- [ ] 部署到测试网
- [ ] 外部审计

## 相关文档

- [ParamController 使用指南](./ParamController_Usage.md)
- [SimpleCPMM 定价引擎](../src/pricing/SimpleCPMM.sol)
- [OU 市场设计文档](./design/02_AMM_LinkedLines.md)
