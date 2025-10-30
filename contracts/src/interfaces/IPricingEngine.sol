// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPricingEngine
 * @notice 定价引擎接口，用于计算下注获得的份额
 * @dev 不同的定价策略（CPMM, LMSR等）实现此接口
 */
interface IPricingEngine {
    /**
     * @notice 计算下注获得的份额
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @param reserves 各结果的流动性储备
     * @return shares 获得的份额
     */
    function calculateShares(
        uint256 outcomeId,
        uint256 amount,
        uint256[] memory reserves
    ) external view returns (uint256 shares);

    /**
     * @notice 计算当前价格（隐含概率）
     * @param outcomeId 结果ID
     * @param reserves 各结果的流动性储备
     * @return price 价格（基点，0-10000 表示 0%-100%）
     */
    function getPrice(uint256 outcomeId, uint256[] memory reserves)
        external
        view
        returns (uint256 price);
}
