# 访问控制与角色管理

本文档描述 PitchOne 合约系统的权限设计和角色管理操作。

## 1. 概述

系统使用 OpenZeppelin `AccessControl` 实现基于角色的访问控制（RBAC）。

### 1.1 核心合约权限模型

| 合约 | 权限模型 | 说明 |
|------|----------|------|
| `Market_V3` | AccessControl | 多角色精细控制 |
| `MarketFactory_V3` | AccessControl | 工厂管理权限 |
| `BettingRouter_V3` | Ownable | 单一 owner 管理 |

## 2. Market_V3 角色定义

```solidity
bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
```

### 2.1 角色职责

| 角色 | 职责 | 可调用函数 |
|------|------|-----------|
| `DEFAULT_ADMIN_ROLE` | 管理所有其他角色 | `grantRole()`, `revokeRole()` |
| `ROUTER_ROLE` | 代理用户下注 | `placeBetFor()` |
| `KEEPER_ROLE` | 自动化任务执行 | `lock()`, `finalize()` |
| `ORACLE_ROLE` | 上报赛果 | `resolve()` |
| `OPERATOR_ROLE` | 运营操作 | `fundFromVault()`, `cancel()`, `cancelResolved()` |
| `PAUSER_ROLE` | 紧急暂停 | `pause()`, `unpause()` |

### 2.2 角色层级

```
DEFAULT_ADMIN_ROLE (0x00)
    │
    ├── 管理 → ROUTER_ROLE
    ├── 管理 → KEEPER_ROLE
    ├── 管理 → ORACLE_ROLE
    ├── 管理 → OPERATOR_ROLE
    ├── 管理 → PAUSER_ROLE
    └── 管理 → DEFAULT_ADMIN_ROLE (自身)
```

## 3. 初始角色分配

### 3.1 MarketFactory_V3 初始化

```solidity
constructor(address _vault, address _settlementToken, address _admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(OPERATOR_ROLE, _admin);
}
```

### 3.2 Market_V3 初始化

```solidity
function initialize(MarketConfig calldata config) external {
    // 授予创建者管理权限
    _grantRole(DEFAULT_ADMIN_ROLE, config.admin);
    _grantRole(OPERATOR_ROLE, config.admin);
    _grantRole(PAUSER_ROLE, config.admin);

    // 授予工厂管理权限（用于后续设置 Router/Keeper/Oracle）
    _grantRole(DEFAULT_ADMIN_ROLE, factory);
}
```

### 3.3 工厂创建市场时的角色授权

```solidity
// MarketFactory_V3.createMarket() 中
if (trustedRouter != address(0)) {
    AccessControl(market).grantRole(ROUTER_ROLE, trustedRouter);
}
if (keeper != address(0)) {
    AccessControl(market).grantRole(KEEPER_ROLE, keeper);
}
if (oracle != address(0)) {
    AccessControl(market).grantRole(ORACLE_ROLE, oracle);
}
```

## 4. 角色管理操作

### 4.1 查询角色

```bash
# 查询地址是否有某角色
cast call $MARKET "hasRole(bytes32,address)(bool)" \
  $(cast keccak "KEEPER_ROLE") \
  $ADDRESS \
  --rpc-url $RPC_URL

# 查询角色的管理员角色
cast call $MARKET "getRoleAdmin(bytes32)(bytes32)" \
  $(cast keccak "KEEPER_ROLE") \
  --rpc-url $RPC_URL
```

### 4.2 授予角色

```bash
# 授予 KEEPER_ROLE（需要 DEFAULT_ADMIN_ROLE）
cast send $MARKET "grantRole(bytes32,address)" \
  $(cast keccak "KEEPER_ROLE") \
  $NEW_KEEPER \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 4.3 撤销角色

```bash
# 撤销 KEEPER_ROLE（需要 DEFAULT_ADMIN_ROLE）
cast send $MARKET "revokeRole(bytes32,address)" \
  $(cast keccak "KEEPER_ROLE") \
  $OLD_KEEPER \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 4.4 放弃自己的角色

```bash
# 放弃自己的 OPERATOR_ROLE
cast send $MARKET "renounceRole(bytes32,address)" \
  $(cast keccak "OPERATOR_ROLE") \
  $MY_ADDRESS \
  --private-key $MY_PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## 5. MarketFactory_V3 管理操作

### 5.1 设置全局 Router

```bash
# 设置 Router（影响新创建的市场）
cast send $FACTORY "setRouter(address)" \
  $ROUTER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 5.2 添加全局 Keeper

支持多个 Keeper，通过 Factory 的 `addKeeper`/`removeKeeper` 管理。

```bash
# 添加 Keeper
cast send $FACTORY "addKeeper(address)" \
  $KEEPER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL

# 移除 Keeper
cast send $FACTORY "removeKeeper(address)" \
  $KEEPER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL

# 查询所有 Keeper
cast call $FACTORY "getKeepers()" --rpc-url $RPC_URL

# 检查某地址是否为 Keeper
cast call $FACTORY "isKeeper(address)" $ADDRESS --rpc-url $RPC_URL
```

**注意**：Keeper 权限现在通过 Factory 全局管理，添加/移除 Keeper 会立即对所有市场生效。

### 5.3 设置全局 Oracle

```bash
cast send $FACTORY "setOracle(address)" \
  $ORACLE_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## 6. BettingRouter_V3 管理操作

Router 使用 `Ownable` 模式，只有 `owner` 可以管理。

### 6.1 添加支持的代币

```bash
cast send $ROUTER "addToken(address,uint256,address,uint256,uint256)" \
  $TOKEN_ADDRESS \
  200 \                    # 费率 2%（基点）
  $FEE_RECIPIENT \
  1000000 \                # 最小下注 1 USDC
  0 \                      # 最大下注无限制
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL
```

### 6.2 暂停/恢复

```bash
# 暂停
cast send $ROUTER "setPaused(bool)" true \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL

# 恢复
cast send $ROUTER "setPaused(bool)" false \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL
```

### 6.3 转移所有权

```bash
cast send $ROUTER "transferOwnership(address)" \
  $NEW_OWNER \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL
```

## 7. 批量操作脚本

### 7.1 更换 Keeper（所有市场）

**新版本**：Keeper 现在通过 Factory 全局管理，更换 Keeper 只需一步操作：

```bash
# 添加新 Keeper
cast send $FACTORY "addKeeper(address)" $NEW_KEEPER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL

# 移除旧 Keeper（可选）
cast send $FACTORY "removeKeeper(address)" $OLD_KEEPER_ADDRESS \
  --private-key $ADMIN_PRIVATE_KEY --rpc-url $RPC_URL
```

**优势**：
- 无需遍历所有市场单独授权
- 更改立即对所有市场（包括已创建的市场）生效
- 支持多个 Keeper 同时运行

**旧版本脚本**（仅供参考，已废弃）：

```solidity
// script/UpdateKeeper.s.sol (已废弃 - 现在使用 addKeeper/removeKeeper)
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_V3.sol";

contract UpdateKeeper is Script {
    function run() external {
        address factory = vm.envAddress("FACTORY");
        address newKeeper = vm.envAddress("NEW_KEEPER");
        uint256 adminKey = vm.envUint("ADMIN_PRIVATE_KEY");

        MarketFactory_V3 f = MarketFactory_V3(factory);

        vm.startBroadcast(adminKey);

        // 一步完成：添加新 Keeper，立即对所有市场生效
        f.addKeeper(newKeeper);

        vm.stopBroadcast();
    }
}
```

### 7.2 紧急暂停所有市场

```solidity
// script/EmergencyPause.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/MarketFactory_V3.sol";
import "../src/core/Market_V3.sol";

contract EmergencyPause is Script {
    function run() external {
        address factory = vm.envAddress("FACTORY");
        uint256 pauserKey = vm.envUint("PAUSER_PRIVATE_KEY");

        MarketFactory_V3 f = MarketFactory_V3(factory);
        uint256 count = f.marketCount();

        vm.startBroadcast(pauserKey);

        for (uint256 i = 0; i < count; i++) {
            address market = f.markets(i);
            Market_V3(market).pause();
        }

        vm.stopBroadcast();
    }
}
```

## 8. 安全最佳实践

### 8.1 使用多签钱包

建议将 `DEFAULT_ADMIN_ROLE` 授予多签钱包（如 Gnosis Safe）：

```bash
# 授予 Safe 管理员权限
cast send $MARKET "grantRole(bytes32,address)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  $SAFE_ADDRESS \
  --private-key $ADMIN_KEY

# 放弃 EOA 的管理员权限
cast send $MARKET "renounceRole(bytes32,address)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  $EOA_ADDRESS \
  --private-key $ADMIN_KEY
```

### 8.2 角色分离原则

| 环境 | 建议 |
|------|------|
| 开发/测试 | 单一地址持有所有角色 |
| 生产 | 每个角色使用独立地址，Admin 使用多签 |

### 8.3 定期审计

```bash
# 导出所有角色持有者（通过事件日志）
cast logs --from-block 0 \
  --address $MARKET \
  "RoleGranted(bytes32,address,address)" \
  --rpc-url $RPC_URL
```

## 9. 角色常量速查

```bash
# 计算角色哈希
cast keccak "ROUTER_ROLE"
# 0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2

cast keccak "KEEPER_ROLE"
# 0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab

cast keccak "ORACLE_ROLE"
# 0x68e79a7bf1e0bc45d0a330c573bc367f9cf464fd326078812f301165fbda4ef1

cast keccak "OPERATOR_ROLE"
# 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929

cast keccak "PAUSER_ROLE"
# 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a

# DEFAULT_ADMIN_ROLE
# 0x0000000000000000000000000000000000000000000000000000000000000000
```

## 10. 故障排查

### 10.1 "AccessControlUnauthorizedAccount" 错误

```bash
# 检查调用者是否有所需角色
cast call $MARKET "hasRole(bytes32,address)(bool)" \
  $ROLE_HASH $CALLER_ADDRESS --rpc-url $RPC_URL

# 检查谁是角色的管理员
cast call $MARKET "getRoleAdmin(bytes32)(bytes32)" \
  $ROLE_HASH --rpc-url $RPC_URL
```

### 10.2 无法授予角色

确认：
1. 调用者是否有目标角色的 `adminRole`
2. 目标角色的 `adminRole` 默认是 `DEFAULT_ADMIN_ROLE`

```bash
# 检查调用者是否有 DEFAULT_ADMIN_ROLE
cast call $MARKET "hasRole(bytes32,address)(bool)" \
  0x0000000000000000000000000000000000000000000000000000000000000000 \
  $CALLER \
  --rpc-url $RPC_URL
```
