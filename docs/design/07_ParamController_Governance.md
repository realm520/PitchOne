# ParamController + Governance/Timelock 详细设计

## 1. 概述
- 所有可调参数统一纳入 ParamController，通过 Governor+Timelock 管控，支持灰度与回滚。

## 2. 数据与状态
- `params[key] = value`（bytes32/uint256 等）
- `queue(key,value,eta)` → `apply(key)`

## 3. 接口
- `queue(key,value,eta)`（Governor 调用）
- `apply(key)`（Timelock 到达 eta 自动/手工执行）
- `get(key)`（公开读取）

## 4. 事件
- `ParamQueued(key,value,eta)` · `ParamApplied(key,value)`。

## 5. 参数范式
- 费用、锁盘提前量、敞口、联动系数、相关性矩阵、scaleBps 等。

## 6. 权限与安全
- 关键参数（费用/金库/惩罚）仅 Governor；读接口公开；参数校验防越界。

## 7. 测试/运维
- 变更生效延迟校验；灰度开关、白名单；审计日志（链上事件 + offchain 审批单）。
