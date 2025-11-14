# PitchOne 自动化数据流文档

本文档说明如何实现完全自动化的合约地址数据流，从部署到 Subgraph 索引无需手动干预。

## 🎯 目标

确保每个步骤都能自动使用上一步产生的数据（特别是合约地址），消除手动复制粘贴的需求。

## 📋 数据流概览

```
Deploy.s.sol
  ↓
deployments/localhost.json (✅ 自动生成)
  ↓
  ├── CreateMarkets_NoMultiLine.s.sol (✅ 自动读取)
  ├── SimulateBets.s.sol (✅ 自动读取)
  └── update-subgraph-config.sh (✅ 自动读取)
       ↓
     subgraph.yaml (✅ 自动生成)
       ↓
     Graph Node 索引 (✅ 自动同步)
```

## ✅ 实现的自动化步骤

### 步骤 1: Deploy.s.sol → localhost.json

**实现方式**: Deploy 脚本自动生成 JSON 配置文件

**位置**: `contracts/deployments/localhost.json`

**包含数据**:
- 所有合约地址（usdc, vault, feeRouter, factory, cpmm, referralRegistry）
- 所有模板 ID（wdl, ou, ouMultiLine, ah, oddEven, score, playerProps）
- 所有实现地址
- 部署元数据（chainId, timestamp, deployedAt）

**示例**:
```json
{
  "contracts": {
    "factory": "0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154",
    "usdc": "0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00",
    ...
  },
  "templates": {
    "wdl": "0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc",
    ...
  }
}
```

---

### 步骤 2: localhost.json → CreateMarkets_NoMultiLine.s.sol

**实现方式**: Solidity 脚本使用 `vm.readFile()` 和 `vm.parseJson()` 读取配置

**关键代码** (`CreateMarkets_NoMultiLine.s.sol`):
```solidity
string constant DEPLOYMENT_FILE = "deployments/localhost.json";

function _loadDeploymentConfig() internal {
    string memory deploymentData = vm.readFile(DEPLOYMENT_FILE);

    // 自动读取合约地址
    FACTORY = vm.parseJsonAddress(deploymentData, ".contracts.factory");
    USDC = vm.parseJsonAddress(deploymentData, ".contracts.usdc");
    VAULT = vm.parseJsonAddress(deploymentData, ".contracts.vault");
    FEE_ROUTER = vm.parseJsonAddress(deploymentData, ".contracts.feeRouter");
    SIMPLE_CPMM = vm.parseJsonAddress(deploymentData, ".contracts.cpmm");

    // 自动读取 Template IDs
    WDL_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.wdl");
    OU_TEMPLATE_ID = vm.parseJsonBytes32(deploymentData, ".templates.ou");
    ...
}
```

**优势**:
- ✅ 无需手动更新地址
- ✅ 每次部署后自动使用最新地址
- ✅ 消除人为错误

---

### 步骤 3: localhost.json → SimulateBets.s.sol

**实现方式**: 与步骤 2 相同，使用 Foundry 的 JSON 解析功能

**关键代码** (`SimulateBets.s.sol`):
```solidity
string constant DEPLOYMENT_FILE = "deployments/localhost.json";

function _loadConfig() internal {
    string memory json = vm.readFile(DEPLOYMENT_FILE);
    factory = vm.parseJsonAddress(json, ".contracts.factory");
    usdc = vm.parseJsonAddress(json, ".contracts.usdc");
}
```

---

### 步骤 4: localhost.json → subgraph.yaml

**实现方式**: Bash 脚本从 JSON 提取地址，替换模板占位符

**脚本**: `subgraph/update-subgraph-config.sh`

**关键代码**:
```bash
#!/bin/bash

# 从 JSON 提取地址
FACTORY_ADDRESS=$(jq -r '.contracts.factory' deployments/localhost.json)
FEE_ROUTER_ADDRESS=$(jq -r '.contracts.feeRouter' deployments/localhost.json)

# 替换模板中的占位符
sed "s/{{FACTORY_ADDRESS}}/$FACTORY_ADDRESS/g; \
     s/{{FEE_ROUTER_ADDRESS}}/$FEE_ROUTER_ADDRESS/g" \
    subgraph.template.yaml > subgraph.yaml
```

**模板文件** (`subgraph.template.yaml`):
```yaml
dataSources:
  - kind: ethereum/contract
    name: MarketFactory
    network: localhost
    source:
      address: "{{FACTORY_ADDRESS}}"  # 占位符
      abi: MarketFactory_v2

  - kind: ethereum/contract
    name: FeeRouter
    network: localhost
    source:
      address: "{{FEE_ROUTER_ADDRESS}}"  # 占位符
      abi: FeeRouter
```

**使用方法**:
```bash
cd subgraph
./update-subgraph-config.sh

# 输出:
# 📋 从部署配置读取地址:
#   Factory:   0x5f3f...9154
#   FeeRouter: 0x1291...1274
# ✅ Subgraph 配置已更新: subgraph.yaml
# ✅ 验证成功: 地址已正确更新
```

---

### 步骤 5: 一键式自动化

**脚本**: `scripts/quick-deploy.sh`

**完整流程**:
```bash
# 1. 部署合约 → 生成 localhost.json
forge script Deploy.s.sol --broadcast

# 2. 创建市场（自动从 localhost.json 读取）
forge script CreateMarkets_NoMultiLine.s.sol --broadcast

# 3. 模拟投注（自动从 localhost.json 读取）
forge script SimulateBets.s.sol --broadcast

# 4. 更新 Subgraph 配置（自动从 localhost.json 读取）
./subgraph/update-subgraph-config.sh

# 5. 部署 Subgraph（使用自动生成的 subgraph.yaml）
cd subgraph && ./reset-subgraph.sh
```

**使用方法**:
```bash
# 确保 Anvil 运行
anvil --host 0.0.0.0

# 一键部署
./scripts/quick-deploy.sh
```

---

## 📊 数据流验证

### 1. 验证 localhost.json 生成

```bash
cat contracts/deployments/localhost.json | jq '.contracts'

# 预期输出:
# {
#   "usdc": "0x5eb3...",
#   "vault": "0x36C0...",
#   "factory": "0x5f3f...",
#   ...
# }
```

### 2. 验证脚本读取正确地址

```bash
cd contracts
PRIVATE_KEY=0xac0... \
  forge script script/CreateMarkets_NoMultiLine.s.sol:CreateMarkets_NoMultiLine \
  --rpc-url http://localhost:8545 \
  -vv

# 输出应包含:
# Using addresses from: deployments/localhost.json
#   Factory: 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154
#   Vault: 0x36C02dA8a0983159322a80FFE9F24b1acfF8B570
```

### 3. 验证 Subgraph 配置更新

```bash
cd subgraph
./update-subgraph-config.sh

# 检查生成的 subgraph.yaml
grep "address:" subgraph.yaml

# 应返回:
#       address: "0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154"
#       address: "0x1291Be112d480055DaFd8a610b7d1e203891C274"
```

### 4. 验证 Subgraph 索引

```bash
# 查询 Subgraph
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 5) { id } }"}' \
  http://localhost:8010/subgraphs/name/pitchone-local | jq .

# 应返回 15 个市场
```

---

## 🔄 完整重新部署流程

当需要完全重启环境时，数据会自动流转：

```bash
# 1. 重启 Anvil（清空所有链上数据）
pkill anvil
cd contracts && anvil --host 0.0.0.0 &

# 2. 运行一键部署（全自动）
cd /home/harry/code/PitchOne
./scripts/quick-deploy.sh

# 数据流自动执行:
# Deploy.s.sol → localhost.json ✅
# localhost.json → CreateMarkets_NoMultiLine.s.sol ✅
# localhost.json → SimulateBets.s.sol ✅
# localhost.json → subgraph.yaml ✅
# subgraph.yaml → Graph Node ✅
```

---

## 🛠️ 手动更新（仅用于调试）

如果需要手动更新某个步骤：

### 仅更新 Subgraph 配置

```bash
cd subgraph
./update-subgraph-config.sh
```

### 仅重新部署 Subgraph

```bash
cd subgraph
./reset-subgraph.sh
```

---

## 📁 文件清单

### 自动生成的文件（不要手动编辑）

- ✅ `contracts/deployments/localhost.json` - 自动生成
- ✅ `subgraph/subgraph.yaml` - 自动生成
- ❌ 不要直接编辑这些文件！

### 需要维护的文件

- ✅ `contracts/script/Deploy.s.sol` - 部署逻辑
- ✅ `contracts/script/CreateMarkets_NoMultiLine.s.sol` - 市场创建逻辑
- ✅ `contracts/script/SimulateBets.s.sol` - 投注模拟逻辑
- ✅ `subgraph/subgraph.template.yaml` - Subgraph 模板（含占位符）
- ✅ `subgraph/update-subgraph-config.sh` - 配置更新脚本
- ✅ `scripts/quick-deploy.sh` - 一键部署脚本

---

## ❌ 反模式（避免这些做法）

### ❌ 错误做法 1: 硬编码地址

```solidity
// ❌ 不要这样做
address constant FACTORY = 0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154;
```

**正确做法**:
```solidity
// ✅ 从 JSON 读取
address FACTORY;
function run() external {
    string memory json = vm.readFile("deployments/localhost.json");
    FACTORY = vm.parseJsonAddress(json, ".contracts.factory");
}
```

---

### ❌ 错误做法 2: 手动编辑 subgraph.yaml

```yaml
# ❌ 不要手动编辑 subgraph.yaml
source:
  address: "0x5f3f..."  # 每次重新部署都要改
```

**正确做法**:
```bash
# ✅ 使用自动化脚本
cd subgraph
./update-subgraph-config.sh  # 自动从 localhost.json 读取
```

---

### ❌ 错误做法 3: 复制粘贴地址

```bash
# ❌ 不要这样做
FACTORY="0x5f3f..."  # 从终端输出复制
```

**正确做法**:
```bash
# ✅ 使用 jq 自动提取
FACTORY=$(jq -r '.contracts.factory' deployments/localhost.json)
```

---

## 🎯 关键要点

1. **单一数据源**: `localhost.json` 是所有合约地址的唯一来源
2. **自动化优先**: 所有步骤都通过脚本自动化，避免手动操作
3. **模板化配置**: `subgraph.template.yaml` 使用占位符，运行时替换
4. **Foundry 集成**: 使用 `vm.readFile()` 和 `vm.parseJson()` 读取配置
5. **验证机制**: 每个步骤都有输出验证，确保正确性

---

## 📚 相关文档

- [完整 SOP 文档](./subgraph/SOP_LOCAL_DEPLOYMENT.md)
- [快速部署脚本](./scripts/quick-deploy.sh)
- [自动化流程图](./subgraph/DEPLOYMENT_FLOW.md)
- [合约部署说明](./contracts/README.md)

---

**最后更新**: 2025-11-14
**作者**: PitchOne Team
**状态**: ✅ 完全自动化实现
