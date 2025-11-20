// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFeeRouter
 * @notice 费用路由接口 - 处理手续费分配和推荐返佣
 */
interface IFeeRouter {
    /**
     * @notice 路由手续费
     * @param token 代币地址
     * @param from 来源地址（下注用户）
     * @param amount 手续费金额
     * @dev 自动处理推荐返佣 + 多池分配
     */
    function routeFee(address token, address from, uint256 amount) external;
}
