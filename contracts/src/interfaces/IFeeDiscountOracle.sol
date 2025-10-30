// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFeeDiscountOracle
 * @notice 费用折扣预言机接口
 * @dev Phase 0: 不使用（设为 address(0)）
 *      Phase 1: 部署 P1 持仓/锁仓为基础的折扣预言机
 */
interface IFeeDiscountOracle {
    /**
     * @notice 获取用户的费用折扣
     * @param user 用户地址
     * @return discount 折扣比例（基点，0-2000 表示 0%-20%）
     * @dev 示例：
     *      - 返回 0 = 无折扣
     *      - 返回 500 = 5% 折扣
     *      - 返回 2000 = 20% 折扣（最大）
     */
    function getDiscount(address user) external view returns (uint256 discount);
}
