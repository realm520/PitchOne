# ParamController 使用指南

## 概述

ParamController 是平台的治理基础设施合约，集中管理所有可配置参数。

## 快速开始

### 1. 部署 ParamController

```solidity
// 部署参数控制器
ParamController controller = new ParamController(
    admin,           // 管理员地址（Safe 多签）
    2 days          // Timelock 延迟（2天）
);
```

### 2. 注册参数

```solidity
// 注册单个参数
controller.registerParam(
    keccak256("FEE_RATE"),  // 参数键
    200,                     // 初始值（2%）
    address(0)              // 验证器地址（无验证器）
);

// 批量注册参数
bytes32[] memory keys = new bytes32[](3);
keys[0] = keccak256("MIN_BET");
keys[1] = keccak256("MAX_BET");
keys[2] = keccak256("LP_SHARE");

uint256[] memory values = new uint256[](3);
values[0] = 1e6;      // 1 USDC
values[1] = 10000e6;  // 10,000 USDC
values[2] = 6000;     // 60%

address[] memory validators = new address[](3);
// 全部无验证器

controller.registerParamsBatch(keys, values, validators);
```

### 3. 查询参数

```solidity
// 查询单个参数
uint256 feeRate = controller.getParam(keccak256("FEE_RATE"));

// 批量查询
bytes32[] memory keys = new bytes32[](2);
keys[0] = keccak256("MIN_BET");
keys[1] = keccak256("MAX_BET");
uint256[] memory values = controller.getParams(keys);

// 安全查询（不存在返回默认值）
uint256 value = controller.tryGetParam(keccak256("UNKNOWN"), 100);
```

### 4. 创建变更提案

```solidity
// 提案降低手续费
bytes32 proposalId = controller.proposeChange(
    keccak256("FEE_RATE"),  // 参数键
    150,                     // 新值（1.5%）
    "Lower fee to attract more users"  // 变更理由
);

// 事件: ProposalCreated(proposalId, ...)
```

### 5. 执行提案（Timelock 后）

```solidity
// 等待 Timelock 延迟（2天）后执行
vm.warp(block.timestamp + 2 days);

controller.executeProposal(proposalId);

// 参数已更新
uint256 newFeeRate = controller.getParam(keccak256("FEE_RATE")); // 150
```

### 6. 取消提案

```solidity
// 提案者或管理员可以取消提案
controller.cancelProposal(proposalId);
```

## 在其他合约中集成

### FeeRouter 示例

```solidity
contract FeeRouter {
    IParamController public paramController;

    constructor(address _paramController) {
        paramController = IParamController(_paramController);
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        uint256 feeRate = paramController.getParam(keccak256("FEE_RATE"));
        return amount * feeRate / 10000;
    }

    function routeFees(uint256 totalFee) external {
        uint256 lpShare = paramController.getParam(keccak256("LP_SHARE"));
        uint256 promoShare = paramController.getParam(keccak256("PROMO_SHARE"));
        uint256 insuranceShare = paramController.getParam(keccak256("INSURANCE_SHARE"));
        uint256 treasuryShare = paramController.getParam(keccak256("TREASURY_SHARE"));

        // 按比例分配费用
        lpVault.transfer(totalFee * lpShare / 10000);
        promoPool.transfer(totalFee * promoShare / 10000);
        insuranceFund.transfer(totalFee * insuranceShare / 10000);
        treasury.transfer(totalFee * treasuryShare / 10000);
    }
}
```

### LinkedLinesController 示例

```solidity
contract LinkedLinesController {
    IParamController public paramController;

    function calculateLinkedPrice(uint256 line1, uint256 line2)
        public view returns (uint256)
    {
        bytes32 key = keccak256(
            abi.encodePacked("OU_LINK_COEFF_", line1, "_", line2)
        );
        uint256 coeff = paramController.getParam(key);

        // 使用联动系数计算价格
        return basePrice * coeff / 10000;
    }
}
```

## 常用参数定义

### 费用参数

```solidity
bytes32 public constant FEE_RATE = keccak256("FEE_RATE");           // 基础费率（bp）
bytes32 public constant LP_SHARE = keccak256("LP_SHARE");           // LP 分成（bp）
bytes32 public constant PROMO_SHARE = keccak256("PROMO_SHARE");     // 推广池分成（bp）
bytes32 public constant INSURANCE_SHARE = keccak256("INSURANCE_SHARE"); // 保险金分成（bp）
bytes32 public constant TREASURY_SHARE = keccak256("TREASURY_SHARE");   // 国库分成（bp）
```

### 限额参数

```solidity
bytes32 public constant MIN_BET = keccak256("MIN_BET");                 // 最小下注
bytes32 public constant MAX_BET = keccak256("MAX_BET");                 // 最大下注
bytes32 public constant MAX_USER_EXPOSURE = keccak256("MAX_USER_EXPOSURE");   // 单用户敞口
bytes32 public constant MAX_MARKET_EXPOSURE = keccak256("MAX_MARKET_EXPOSURE"); // 单市场敞口
```

### 联动定价参数

```solidity
bytes32 public constant OU_LINK_COEFF_2_0_TO_2_5 = keccak256("OU_LINK_COEFF_2_0_TO_2_5");
bytes32 public constant AH_LINK_COEFF = keccak256("AH_LINK_COEFF");
bytes32 public constant SPREAD_GUARD_BPS = keccak256("SPREAD_GUARD_BPS");
```

### 推荐返佣参数

```solidity
bytes32 public constant REFERRAL_RATE_TIER1 = keccak256("REFERRAL_RATE_TIER1");
bytes32 public constant REFERRAL_RATE_TIER2 = keccak256("REFERRAL_RATE_TIER2");
bytes32 public constant MAX_REFERRAL_DEPTH = keccak256("MAX_REFERRAL_DEPTH");
```

## 参数验证器

### 创建验证器

```solidity
contract FeeRateValidator {
    uint256 public constant MIN_FEE = 10;   // 0.1%
    uint256 public constant MAX_FEE = 500;  // 5%

    function validate(bytes32 key, uint256 value) external pure returns (bool) {
        if (key == keccak256("FEE_RATE")) {
            return value >= MIN_FEE && value <= MAX_FEE;
        }
        return true;
    }
}
```

### 注册带验证器的参数

```solidity
FeeRateValidator validator = new FeeRateValidator();

controller.registerParam(
    keccak256("FEE_RATE"),
    200,                    // 2% (在 0.1%-5% 范围内)
    address(validator)
);

// 尝试注册超出范围的值会失败
controller.registerParam(
    keccak256("FEE_RATE"),
    1000,  // 10% - 会失败
    address(validator)
);
// 抛出 ValidationFailed 错误
```

## 紧急控制

### 暂停参数变更

```solidity
// Guardian 可以紧急暂停
controller.pause();

// 暂停后，无法创建或执行提案
controller.proposeChange(...); // 会失败

// Guardian 恢复
controller.unpause();
```

## 角色权限

- **DEFAULT_ADMIN_ROLE**: 管理员（管理角色、注册参数）
- **PROPOSER_ROLE**: 提案者（创建参数变更提案）
- **EXECUTOR_ROLE**: 执行者（执行已过 Timelock 的提案）
- **GUARDIAN_ROLE**: 守护者（紧急暂停）

## 最佳实践

1. **使用 Safe 多签**作为管理员和提案者
2. **设置合理的 Timelock**（建议 2-7 天）
3. **为关键参数添加验证器**（费率、限额等）
4. **批量操作**时使用 `registerParamsBatch()` 和 `getParams()`
5. **监控提案**创建和执行事件
6. **定期审查**参数设置是否合理
7. **文档化**所有参数的含义和范围

## 事件监听

```javascript
// 监听提案创建
controller.on("ProposalCreated", (proposalId, key, oldValue, newValue, eta, proposer, reason) => {
    console.log(`New proposal ${proposalId}:`);
    console.log(`  ${key}: ${oldValue} → ${newValue}`);
    console.log(`  ETA: ${new Date(eta * 1000)}`);
    console.log(`  Reason: ${reason}`);
});

// 监听参数变更
controller.on("ParamChanged", (key, oldValue, newValue, timestamp) => {
    console.log(`Param ${key} changed: ${oldValue} → ${newValue}`);
});
```

## 测试覆盖

- **行覆盖率**: 90.10%
- **语句覆盖率**: 92.55%
- **分支覆盖率**: 69.23%
- **函数覆盖率**: 100.00%
- **测试数量**: 35 个

## 安全考虑

1. ✅ 所有参数变更都有 Timelock 延迟
2. ✅ 支持参数验证器
3. ✅ 紧急暂停机制
4. ✅ 角色权限分离
5. ✅ 提案可以被取消
6. ✅ 完整的事件日志

## 下一步

- [ ] 集成到 FeeRouter
- [ ] 集成到 LinkedLinesController
- [ ] 集成到 ReferralRegistry
- [ ] 部署到测试网
- [ ] 外部审计
