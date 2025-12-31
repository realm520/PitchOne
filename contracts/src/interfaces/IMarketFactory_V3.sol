// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMarketFactory_V3
 * @notice MarketFactory_V3 的最小接口
 * @dev 供 Market_V3 检查 Keeper 权限，BettingRouter_V3 验证市场注册
 */
interface IMarketFactory_V3 {
    /**
     * @notice 检查地址是否为 Keeper
     * @param account 待检查的地址
     * @return 是否为 Keeper
     */
    function isKeeper(address account) external view returns (bool);

    /**
     * @notice 检查地址是否为已注册的市场
     * @param market 待检查的市场地址
     * @return 是否为已注册市场
     */
    function isMarket(address market) external view returns (bool);
}
