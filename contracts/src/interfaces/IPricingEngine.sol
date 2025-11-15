// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPricingEngine
 * @notice 定价引擎接口，用于计算下注获得的份额和管理储备更新
 * @dev 不同的定价策略（CPMM, Parimutuel, LMSR等）实现此接口
 *
 * 设计原则：
 * - 定价引擎负责所有定价逻辑和储备更新逻辑
 * - 市场模板只负责调用接口，不关心内部实现
 * - 符合策略模式（Strategy Pattern）和开闭原则
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
     * @notice 更新储备（在用户下注后调用）
     * @param outcomeId 结果ID
     * @param amount 净金额（已扣除手续费）
     * @param shares 用户获得的份额（由 calculateShares 计算）
     * @param reserves 当前储备
     * @return newReserves 更新后的储备
     *
     * @dev 不同定价引擎的储备更新逻辑：
     *      - SimpleCPMM: r_target -= shares, r_other += amount （pure）
     *      - Parimutuel: r_target += amount（累加实际投注）（pure）
     *      - LMSR: 更新内部 quantityShares 映射 （状态修改）
     *
     *      市场模板调用此函数后直接使用返回的 newReserves，
     *      无需关心内部逻辑。
     *
     *      注意:修饰符从 pure 改为 external (无修饰符)
     *      以支持 LMSR 等需要维护内部状态的引擎。
     *      Pure 实现仍然兼容。
     */
    function updateReserves(
        uint256 outcomeId,
        uint256 amount,
        uint256 shares,
        uint256[] memory reserves
    ) external returns (uint256[] memory newReserves);

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

    /**
     * @notice 获取初始储备配置
     * @param outcomeCount 结果数量（2 或 3）
     * @return initialReserves 初始储备数组
     *
     * @dev 不同定价引擎的初始储备：
     *      - SimpleCPMM: [100_000, 100_000] 或自定义值
     *      - Parimutuel: [0, 0]（零储备）
     *      - LMSR: 根据流动性参数 b 计算
     *
     *      这样市场模板在初始化时可以直接调用此方法，
     *      无需硬编码初始值。
     */
    function getInitialReserves(uint256 outcomeCount)
        external
        view
        returns (uint256[] memory initialReserves);
}
