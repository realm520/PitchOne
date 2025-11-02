// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IParamController} from "../interfaces/IParamController.sol";
import {SimpleCPMM} from "./SimpleCPMM.sol";

/**
 * @title LinkedLinesController
 * @notice 管理 OU/AH 多线市场的联动定价控制器
 * @dev 通过联动系数确保相邻盘口线之间的价格一致性，防止套利
 *
 * 核心概念：
 * 1. 联动系数：相邻线之间的价格关联度（如 OU 2.0 vs 2.5）
 * 2. 价格平滑：通过调整储备量维持合理的价格关系
 * 3. 防套利：检测并限制跨线套利机会
 *
 * 示例：
 * - OU 2.0球（OVER 概率 70%）和 OU 2.5球（OVER 概率 60%）应该保持合理的价差
 * - 如果 2.0 OVER 价格过低，可能被套利
 * - LinkedLinesController 通过联动系数动态调整储备量
 */
contract LinkedLinesController is AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice 管理员角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice 操作员角色（可以更新价格）
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 线配置
    struct LineConfig {
        uint256 line;              // 盘口线（如 2500 表示 2.5 球）
        bool isActive;             // 是否激活
        address cpmm;              // 对应的 CPMM 合约地址
        uint256 baseReserve0;      // 基础储备量 0
        uint256 baseReserve1;      // 基础储备量 1
    }

    /// @notice 联动配置
    struct LinkConfig {
        uint256 lowerLine;         // 较低的线
        uint256 upperLine;         // 较高的线
        uint256 coefficient;       // 联动系数（基点，10000 = 100%）
        uint256 minSpread;         // 最小价差（基点）
        uint256 maxSpread;         // 最大价差（基点）
    }

    /// @notice 市场线组（一组相关联的盘口线）
    struct MarketLineGroup {
        bytes32 groupId;           // 组 ID
        uint256[] lines;           // 线数组（从小到大排序）
        mapping(uint256 => LineConfig) lineConfigs;  // 线配置
        bool isActive;             // 是否激活
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice ParamController 地址
    IParamController public paramController;

    /// @notice 市场线组存储
    mapping(bytes32 => MarketLineGroup) private marketLineGroups;

    /// @notice 所有线组 ID
    bytes32[] public allGroupIds;

    /// @notice 联动配置存储
    mapping(bytes32 => LinkConfig) public linkConfigs;

    /// @notice 默认联动系数（80%）
    uint256 public constant DEFAULT_LINK_COEFFICIENT = 8000;

    /// @notice 默认最小价差（0.5%）
    uint256 public constant DEFAULT_MIN_SPREAD = 50;

    /// @notice 默认最大价差（5%）
    uint256 public constant DEFAULT_MAX_SPREAD = 500;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LineGroupCreated(bytes32 indexed groupId, uint256[] lines);
    event LineConfigured(bytes32 indexed groupId, uint256 line, address cpmm, uint256 reserve0, uint256 reserve1);
    event LinkConfigured(bytes32 indexed linkId, uint256 lowerLine, uint256 upperLine, uint256 coefficient);
    event ReservesAdjusted(
        bytes32 indexed groupId,
        uint256 line,
        uint256 oldReserve0,
        uint256 oldReserve1,
        uint256 newReserve0,
        uint256 newReserve1
    );
    event ArbitrageDetected(bytes32 indexed groupId, uint256 line1, uint256 line2, uint256 profitBps);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LineGroupNotFound(bytes32 groupId);
    error LineNotFound(bytes32 groupId, uint256 line);
    error InvalidLineOrder();
    error InvalidCoefficient(uint256 coefficient);
    error InvalidSpread(uint256 minSpread, uint256 maxSpread);
    error SpreadOutOfRange(uint256 actualSpread, uint256 minSpread, uint256 maxSpread);
    error ArbitrageOpportunityDetected(uint256 line1, uint256 line2, uint256 profitBps);
    error LineAlreadyExists(bytes32 groupId, uint256 line);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address admin, address _paramController) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, admin);

        paramController = IParamController(_paramController);
    }

    /*//////////////////////////////////////////////////////////////
                          LINE GROUP MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 创建线组
     * @param groupId 组 ID（如 keccak256("OU_MATCH_123")）
     * @param lines 线数组（必须从小到大排序）
     */
    function createLineGroup(bytes32 groupId, uint256[] calldata lines) external onlyRole(ADMIN_ROLE) {
        require(lines.length >= 2, "At least 2 lines required");
        require(!marketLineGroups[groupId].isActive, "Group already exists");

        // 验证线是否从小到大排序
        for (uint256 i = 1; i < lines.length; i++) {
            if (lines[i] <= lines[i - 1]) {
                revert InvalidLineOrder();
            }
        }

        MarketLineGroup storage group = marketLineGroups[groupId];
        group.groupId = groupId;
        group.lines = lines;
        group.isActive = true;

        allGroupIds.push(groupId);

        emit LineGroupCreated(groupId, lines);
    }

    /**
     * @notice 配置单条线
     * @param groupId 组 ID
     * @param line 线值
     * @param cpmm CPMM 合约地址
     * @param baseReserve0 基础储备量 0
     * @param baseReserve1 基础储备量 1
     */
    function configureLine(
        bytes32 groupId,
        uint256 line,
        address cpmm,
        uint256 baseReserve0,
        uint256 baseReserve1
    ) external onlyRole(ADMIN_ROLE) {
        MarketLineGroup storage group = marketLineGroups[groupId];
        if (!group.isActive) {
            revert LineGroupNotFound(groupId);
        }

        // 验证线是否在组中
        bool found = false;
        for (uint256 i = 0; i < group.lines.length; i++) {
            if (group.lines[i] == line) {
                found = true;
                break;
            }
        }
        if (!found) {
            revert LineNotFound(groupId, line);
        }

        group.lineConfigs[line] = LineConfig({
            line: line,
            isActive: true,
            cpmm: cpmm,
            baseReserve0: baseReserve0,
            baseReserve1: baseReserve1
        });

        emit LineConfigured(groupId, line, cpmm, baseReserve0, baseReserve1);
    }

    /**
     * @notice 配置联动关系
     * @param groupId 组 ID
     * @param lowerLine 较低的线
     * @param upperLine 较高的线
     * @param coefficient 联动系数（基点）
     * @param minSpread 最小价差（基点）
     * @param maxSpread 最大价差（基点）
     */
    function configureLink(
        bytes32 groupId,
        uint256 lowerLine,
        uint256 upperLine,
        uint256 coefficient,
        uint256 minSpread,
        uint256 maxSpread
    ) external onlyRole(ADMIN_ROLE) {
        if (lowerLine >= upperLine) {
            revert InvalidLineOrder();
        }
        if (coefficient < 5000 || coefficient > 10000) {
            revert InvalidCoefficient(coefficient);
        }
        if (minSpread >= maxSpread) {
            revert InvalidSpread(minSpread, maxSpread);
        }

        bytes32 linkId = keccak256(abi.encodePacked(groupId, lowerLine, upperLine));

        linkConfigs[linkId] = LinkConfig({
            lowerLine: lowerLine,
            upperLine: upperLine,
            coefficient: coefficient,
            minSpread: minSpread,
            maxSpread: maxSpread
        });

        emit LinkConfigured(linkId, lowerLine, upperLine, coefficient);
    }

    /*//////////////////////////////////////////////////////////////
                          PRICE CALCULATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 计算联动后的价格
     * @param groupId 组 ID
     * @param line 线值
     * @param outcome 结果方向（0 或 1）
     * @param reserves 当前储备量（由调用者提供）
     * @return price 价格（基点）
     */
    function getLinkedPrice(
        bytes32 groupId,
        uint256 line,
        uint256 outcome,
        uint256[] calldata reserves
    ) external view returns (uint256 price) {
        MarketLineGroup storage group = marketLineGroups[groupId];
        if (!group.isActive) {
            revert LineGroupNotFound(groupId);
        }

        LineConfig storage config = group.lineConfigs[line];
        if (!config.isActive) {
            revert LineNotFound(groupId, line);
        }

        // 使用提供的储备量计算价格
        SimpleCPMM cpmm = SimpleCPMM(config.cpmm);
        price = cpmm.getPrice(outcome, reserves);
    }

    /**
     * @notice 批量获取所有线的价格
     * @param groupId 组 ID
     * @param outcome 结果方向
     * @param allReserves 所有线的储备量数组（每个元素是 [reserve0, reserve1]）
     * @return lines 线数组
     * @return prices 价格数组
     */
    function getAllLinkedPrices(bytes32 groupId, uint256 outcome, uint256[][] calldata allReserves)
        external
        view
        returns (uint256[] memory lines, uint256[] memory prices)
    {
        MarketLineGroup storage group = marketLineGroups[groupId];
        if (!group.isActive) {
            revert LineGroupNotFound(groupId);
        }

        lines = group.lines;
        prices = new uint256[](lines.length);

        require(allReserves.length == lines.length, "Reserves length mismatch");

        for (uint256 i = 0; i < lines.length; i++) {
            LineConfig storage config = group.lineConfigs[lines[i]];
            if (config.isActive) {
                SimpleCPMM cpmm = SimpleCPMM(config.cpmm);
                prices[i] = cpmm.getPrice(outcome, allReserves[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ARBITRAGE DETECTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 检测套利机会（简化版）
     * @param groupId 组 ID
     * @param allReserves 所有线的储备量数组（每个元素是 [reserve0, reserve1]）
     * @return hasArbitrage 是否存在套利机会
     * @return line1 套利线1
     * @return line2 套利线2
     * @return profitBps 套利利润（基点）
     */
    function detectArbitrage(bytes32 groupId, uint256[][] calldata allReserves)
        external
        view
        returns (bool hasArbitrage, uint256 line1, uint256 line2, uint256 profitBps)
    {
        MarketLineGroup storage group = marketLineGroups[groupId];
        if (!group.isActive) {
            revert LineGroupNotFound(groupId);
        }

        require(allReserves.length == group.lines.length, "Reserves length mismatch");

        // 检查相邻线之间的价差 - 简化实现避免 stack too deep
        for (uint256 i = 0; i < group.lines.length - 1;) {
            line1 = group.lines[i];
            line2 = group.lines[i + 1];

            LineConfig storage cfg1 = group.lineConfigs[line1];
            LineConfig storage cfg2 = group.lineConfigs[line2];

            if (cfg1.isActive && cfg2.isActive) {
                uint256 p1 = SimpleCPMM(cfg1.cpmm).getPrice(0, allReserves[i]);
                uint256 p2 = SimpleCPMM(cfg2.cpmm).getPrice(0, allReserves[i + 1]);

                // 如果高线 OVER 价格 >= 低线 OVER 价格，存在套利
                if (p2 >= p1) {
                    return (true, line1, line2, p2 > p1 ? p2 - p1 : 0);
                }

                // 检查价差范围
                LinkConfig storage link = linkConfigs[keccak256(abi.encodePacked(groupId, line1, line2))];
                if (link.lowerLine != 0 && p1 > p2) {
                    uint256 spread = ((p1 - p2) * 10000) / p1;
                    if (spread < link.minSpread || spread > link.maxSpread) {
                        return (true, line1, line2, spread);
                    }
                }
            }

            unchecked {
                ++i;
            }
        }

        return (false, 0, 0, 0);
    }

    /*//////////////////////////////////////////////////////////////
                          RESERVE ADJUSTMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 调整储备量以维持价格一致性
     * @param groupId 组 ID
     * @param line 线值
     * @param newReserve0 新储备量 0
     * @param newReserve1 新储备量 1
     */
    function adjustReserves(
        bytes32 groupId,
        uint256 line,
        uint256 newReserve0,
        uint256 newReserve1
    ) external onlyRole(OPERATOR_ROLE) {
        MarketLineGroup storage group = marketLineGroups[groupId];
        if (!group.isActive) {
            revert LineGroupNotFound(groupId);
        }

        LineConfig storage config = group.lineConfigs[line];
        if (!config.isActive) {
            revert LineNotFound(groupId, line);
        }

        uint256 oldReserve0 = config.baseReserve0;
        uint256 oldReserve1 = config.baseReserve1;

        config.baseReserve0 = newReserve0;
        config.baseReserve1 = newReserve1;

        emit ReservesAdjusted(groupId, line, oldReserve0, oldReserve1, newReserve0, newReserve1);
    }

    /*//////////////////////////////////////////////////////////////
                          QUERY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取线组信息
     * @param groupId 组 ID
     * @return lines 线数组
     * @return isActive 是否激活
     */
    function getLineGroup(bytes32 groupId) external view returns (uint256[] memory lines, bool isActive) {
        MarketLineGroup storage group = marketLineGroups[groupId];
        return (group.lines, group.isActive);
    }

    /**
     * @notice 获取线配置
     * @param groupId 组 ID
     * @param line 线值
     * @return config 线配置
     */
    function getLineConfig(bytes32 groupId, uint256 line) external view returns (LineConfig memory config) {
        MarketLineGroup storage group = marketLineGroups[groupId];
        return group.lineConfigs[line];
    }

    /**
     * @notice 获取所有线组 ID
     * @return groupIds 线组 ID 数组
     */
    function getAllGroupIds() external view returns (bytes32[] memory groupIds) {
        return allGroupIds;
    }

    /**
     * @notice 计算联动系数（从 ParamController 读取）
     * @param line1 线1
     * @param line2 线2
     * @return coefficient 联动系数
     */
    function getLinkCoefficient(uint256 line1, uint256 line2) public view returns (uint256 coefficient) {
        bytes32 key = keccak256(abi.encodePacked("LINK_COEFF_", line1, "_", line2));
        coefficient = paramController.tryGetParam(key, DEFAULT_LINK_COEFFICIENT);
    }
}
