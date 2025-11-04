// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MarketTemplateRegistry.sol";
import "../templates/WDL_Template.sol";
import "../templates/OU_Template.sol";
import "../templates/OddEven_Template.sol";

/**
 * @title MarketFactory
 * @notice 市场工厂合约 - Registry 的扩展，提供简化的市场创建接口
 * @dev 继承 Registry，添加针对每种市场类型的具体创建函数
 *
 * 为什么需要这个合约？
 * - Registry 的 createMarket() 使用 assembly，需要传入 bytecode，太复杂
 * - 前端需要简单的接口来创建市场
 * - Subgraph 需要监听 MarketCreated 事件来动态索引
 *
 * 这个合约提供：
 * - createWDLMarket() - 创建胜平负市场
 * - createOUMarket() - 创建大小球市场
 * - createOddEvenMarket() - 创建单双市场
 * - 所有创建函数都会发出标准的 MarketCreated 事件
 */
contract MarketFactory is MarketTemplateRegistry {
    // ============ 常量 ============

    /// @notice WDL 模板 ID (keccak256(abi.encode("WDL", "1.0.0")))
    bytes32 public constant WDL_TEMPLATE_ID = keccak256(abi.encode("WDL", "1.0.0"));

    /// @notice OU 模板 ID (keccak256(abi.encode("OU", "1.0.0")))
    bytes32 public constant OU_TEMPLATE_ID = keccak256(abi.encode("OU", "1.0.0"));

    /// @notice OddEven 模板 ID (keccak256(abi.encode("OddEven", "1.0.0")))
    bytes32 public constant ODDEVEN_TEMPLATE_ID = keccak256(abi.encode("OddEven", "1.0.0"));

    // ============ 市场创建函数 ============

    /**
     * @notice 创建 WDL (胜平负) 市场
     * @param matchId 比赛 ID
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param kickoffTime 开赛时间
     * @param settlementToken 结算代币地址
     * @param feeRecipient 手续费接收地址
     * @param feeRate 手续费率（基点）
     * @param disputePeriod 争议期（秒）
     * @param pricingEngine 定价引擎地址
     * @param uri ERC-1155 元数据 URI
     * @return market 创建的市场地址
     */
    function createWDLMarket(
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 kickoffTime,
        address settlementToken,
        address feeRecipient,
        uint256 feeRate,
        uint256 disputePeriod,
        address pricingEngine,
        string memory uri
    ) external whenNotPaused returns (address market) {
        // 创建市场
        WDL_Template wdl = new WDL_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            settlementToken,
            feeRecipient,
            feeRate,
            disputePeriod,
            pricingEngine,
            uri
        );

        market = address(wdl);

        // 将市场所有权转移给调用者
        wdl.transferOwnership(msg.sender);

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = WDL_TEMPLATE_ID;

        // 更新模板计数（如果已注册）
        if (templates[WDL_TEMPLATE_ID].implementation != address(0)) {
            templates[WDL_TEMPLATE_ID].marketCount++;
        }

        // 发出事件（Subgraph 监听此事件进行动态索引）
        emit MarketCreated(market, WDL_TEMPLATE_ID, msg.sender);

        return market;
    }

    /**
     * @notice 创建 OU (大小球) 单线市场
     * @param matchId 比赛 ID
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param kickoffTime 开赛时间
     * @param line 盘口线（如 2.5 球 = 2500）
     * @param settlementToken 结算代币地址
     * @param feeRecipient 手续费接收地址
     * @param feeRate 手续费率（基点）
     * @param disputePeriod 争议期（秒）
     * @param pricingEngine 定价引擎地址
     * @param uri ERC-1155 元数据 URI
     * @return market 创建的市场地址
     */
    function createOUMarket(
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 kickoffTime,
        uint256 line,
        address settlementToken,
        address feeRecipient,
        uint256 feeRate,
        uint256 disputePeriod,
        address pricingEngine,
        string memory uri
    ) external whenNotPaused returns (address market) {
        // 创建市场
        OU_Template ou = new OU_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            line,
            settlementToken,
            feeRecipient,
            feeRate,
            disputePeriod,
            pricingEngine,
            uri
        );

        market = address(ou);

        // 将市场所有权转移给调用者
        ou.transferOwnership(msg.sender);

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = OU_TEMPLATE_ID;

        // 更新模板计数
        if (templates[OU_TEMPLATE_ID].implementation != address(0)) {
            templates[OU_TEMPLATE_ID].marketCount++;
        }

        // 发出事件
        emit MarketCreated(market, OU_TEMPLATE_ID, msg.sender);

        return market;
    }

    /**
     * @notice 创建 OddEven (单双) 市场
     * @param matchId 比赛 ID
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param kickoffTime 开赛时间
     * @param settlementToken 结算代币地址
     * @param feeRecipient 手续费接收地址
     * @param feeRate 手续费率（基点）
     * @param disputePeriod 争议期（秒）
     * @param pricingEngine 定价引擎地址
     * @param uri ERC-1155 元数据 URI
     * @return market 创建的市场地址
     */
    function createOddEvenMarket(
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 kickoffTime,
        address settlementToken,
        address feeRecipient,
        uint256 feeRate,
        uint256 disputePeriod,
        address pricingEngine,
        string memory uri
    ) external whenNotPaused returns (address market) {
        // 创建市场
        OddEven_Template oddEven = new OddEven_Template(
            matchId,
            homeTeam,
            awayTeam,
            kickoffTime,
            settlementToken,
            feeRecipient,
            feeRate,
            disputePeriod,
            pricingEngine,
            uri
        );

        market = address(oddEven);

        // 将市场所有权转移给调用者
        oddEven.transferOwnership(msg.sender);

        // 记录市场信息
        markets.push(market);
        isMarket[market] = true;
        marketTemplate[market] = ODDEVEN_TEMPLATE_ID;

        // 更新模板计数
        if (templates[ODDEVEN_TEMPLATE_ID].implementation != address(0)) {
            templates[ODDEVEN_TEMPLATE_ID].marketCount++;
        }

        // 发出事件
        emit MarketCreated(market, ODDEVEN_TEMPLATE_ID, msg.sender);

        return market;
    }

    // ============ 辅助函数 ============

    /**
     * @notice 批量创建市场（节省 gas）
     * @dev 暂未实现，未来可添加
     */
}
