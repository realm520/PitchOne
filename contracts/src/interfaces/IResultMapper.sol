// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IResultMapper
 * @notice 赛果映射接口 - 将原始比赛结果映射到触发的 outcome(s)
 * @dev 每种玩法类型实现一个 Mapper：WDL, OU, AH, Score, OddEven 等
 *
 * 设计原则：
 * - 无状态：所有映射逻辑基于传入的参数
 * - 支持半输半赢：通过 weights 数组返回多个 outcome
 * - 可扩展：新玩法只需新增 Mapper，无需修改 Market
 *
 * 示例：
 * - WDL (3-1): outcomeIds=[0], weights=[10000] (主胜)
 * - OU 2.5 (3球): outcomeIds=[0], weights=[10000] (大球)
 * - AH -0.75 (净胜1球): outcomeIds=[0,1], weights=[5000,5000] (半赢)
 */
interface IResultMapper {
    // ============ 核心映射 ============

    /**
     * @notice 将原始赛果映射到触发的 outcome(s)
     * @param rawResult 原始赛果数据（ABI 编码）
     * @return outcomeIds 触发的 outcome ID 列表
     * @return weights 每个 outcome 的权重（基点，总和 = 10000）
     *
     * @dev rawResult 编码格式由具体 Mapper 定义：
     *      - 足球 WDL/OU/AH: abi.encode(uint256 homeScore, uint256 awayScore)
     *      - 篮球: abi.encode(uint256 homeScore, uint256 awayScore)
     *      - 网球: abi.encode(uint256 homeSets, uint256 awaySets)
     *
     *      weights 说明：
     *      - 普通结果: [10000] (100% 赔付)
     *      - 半赢半输: [5000, 5000] (各 50% 赔付)
     *      - Push 退款: outcomeId 指向 Push outcome，weight = 10000
     */
    function mapResult(bytes calldata rawResult)
        external
        view
        returns (uint256[] memory outcomeIds, uint256[] memory weights);

    // ============ 元数据 ============

    /**
     * @notice 返回这个 Mapper 支持的 outcome 数量
     * @return 结果数量（如 WDL=3, OU=2 或 3）
     */
    function outcomeCount() external view returns (uint256);

    /**
     * @notice 返回 Mapper 类型标识
     * @return 类型名称，如 "WDL", "OU", "AH", "SCORE", "ODD_EVEN"
     */
    function mapperType() external pure returns (string memory);

    /**
     * @notice 返回 Mapper 版本
     * @return 版本号，如 "1.0.0"
     */
    function version() external pure returns (string memory);

    // ============ 参数查询 ============

    /**
     * @notice 获取 Mapper 初始化参数（如盘口线）
     * @return 参数数据（ABI 编码）
     * @dev 返回格式由 Mapper 定义：
     *      - WDL: bytes("") (无参数)
     *      - OU: abi.encode(int256 line) (如 2500 = 2.5)
     *      - AH: abi.encode(int256 line) (如 -750 = -0.75)
     */
    function getParams() external view returns (bytes memory);

    // ============ 辅助查询 ============

    /**
     * @notice 获取 outcome 名称
     * @param outcomeId 结果 ID
     * @return name outcome 名称
     */
    function getOutcomeName(uint256 outcomeId) external view returns (string memory name);

    /**
     * @notice 获取所有 outcome 名称
     * @return names outcome 名称数组
     */
    function getAllOutcomeNames() external view returns (string[] memory names);

    /**
     * @notice 预览给定赛果对应的结果（用于前端展示）
     * @param homeScore 主队得分
     * @param awayScore 客队得分
     * @return outcomeIds 预期触发的 outcome IDs
     * @return weights 预期权重
     * @dev 简化版的 mapResult，使用明确的参数
     */
    function previewResult(uint256 homeScore, uint256 awayScore)
        external
        view
        returns (uint256[] memory outcomeIds, uint256[] memory weights);
}
