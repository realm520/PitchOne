// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MarketConfig
 * @notice 统一的市场配置库，定义所有市场的默认参数和配置模板
 * @dev 将共同参数提取为默认值，每个市场只需指定差异化参数
 */
library MarketConfig {
    // ============ 部署地址常量 ============
    address public constant FACTORY = 0xF85895D097B2C25946BB95C4d11E2F3c035F8f0C;
    address public constant USDC = 0xDf951d2061b12922BFbF22cb17B17f3b39183570;
    address public constant VAULT = 0x67baFF31318638F497f4c4894Cd73918563942c8;
    address public constant FEE_ROUTER = 0x2b639Cc84e1Ad3aA92D4Ee7d2755A6ABEf300D72;
    address public constant SIMPLE_CPMM = 0x6533158b042775e2FdFeF3cA1a782EFDbB8EB9b1;
    address public constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    // ============ Template IDs ============
    bytes32 public constant WDL_TEMPLATE_ID = 0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc;
    bytes32 public constant OU_TEMPLATE_ID = 0xe67f7459aae2aac2006ad1a632fdc210987272f30ee3c19e06f269c8ca6ddab3;
    bytes32 public constant OU_MULTILINE_TEMPLATE_ID = 0xa9798a26825135172b018de8fbdb5b83d020c306bdf806095ca7f9c127f0fae1;
    bytes32 public constant AH_TEMPLATE_ID = 0x46369e63a26fb5fac75d4b12fa68444dbdb66451018df0754d91a002ce6c9ed3;
    bytes32 public constant ODDEVEN_TEMPLATE_ID = 0x19f060b034dda7e3c77551a040d04d36852227b98032ee3737738fa9528c99cb;
    bytes32 public constant SCORE_TEMPLATE_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 public constant PLAYERPROPS_TEMPLATE_ID = 0x54c152168f7e17883823ba6f159b58151878f27a60e3dcaa19d23908ddd44c6e;

    // ============ 默认配置参数 ============
    uint256 public constant DEFAULT_FEE_RATE = 200;           // 2% 费用率
    uint256 public constant DEFAULT_DISPUTE_PERIOD = 2 hours; // 2小时争议期

    // ============ 核心配置结构体 ============

    /**
     * @notice 基础市场配置（所有市场共同）
     */
    struct BaseConfig {
        string matchId;           // 赛事ID
        string homeTeam;          // 主队名称
        string awayTeam;          // 客队名称
        uint256 kickoffTime;      // 开赛时间
        address settlementToken;  // 结算代币
        address feeRecipient;     // 费用接收地址
        uint256 feeRate;          // 费用率 (basis points, 200 = 2%)
        uint256 disputePeriod;    // 争议期
        address pricingEngine;    // 定价引擎
        address owner;            // 所有者
    }

    /**
     * @notice 创建默认的基础配置
     * @param matchId 赛事ID
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param daysOffset 从现在开始的天数偏移
     * @return 基础配置结构体
     */
    function createBaseConfig(
        string memory matchId,
        string memory homeTeam,
        string memory awayTeam,
        uint256 daysOffset
    ) internal view returns (BaseConfig memory) {
        return BaseConfig({
            matchId: matchId,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            kickoffTime: block.timestamp + daysOffset * 1 days,
            settlementToken: USDC,
            feeRecipient: FEE_ROUTER,
            feeRate: DEFAULT_FEE_RATE,
            disputePeriod: DEFAULT_DISPUTE_PERIOD,
            pricingEngine: SIMPLE_CPMM,
            owner: OWNER
        });
    }

    /**
     * @notice 生成市场URI
     * @param homeTeam 主队名称
     * @param awayTeam 客队名称
     * @param suffix URI后缀（如 "WDL", "O/U"）
     * @return 完整的URI字符串
     */
    function generateURI(
        string memory homeTeam,
        string memory awayTeam,
        string memory suffix
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(homeTeam, " vs ", awayTeam, " ", suffix));
    }

    // ============ 特定市场配置 ============

    /**
     * @notice OU市场的线配置（常用盘口线）
     */
    function getCommonOULines() internal pure returns (uint256[] memory) {
        uint256[] memory lines = new uint256[](7);
        lines[0] = 500;   // 0.5
        lines[1] = 1500;  // 1.5
        lines[2] = 2500;  // 2.5
        lines[3] = 3500;  // 3.5
        lines[4] = 4500;  // 4.5
        lines[5] = 5500;  // 5.5
        lines[6] = 6500;  // 6.5
        return lines;
    }

    /**
     * @notice AH市场的常用让球数
     */
    function getCommonHandicaps() internal pure returns (int256[] memory) {
        int256[] memory handicaps = new int256[](11);
        handicaps[0] = -2500;  // -2.5
        handicaps[1] = -2000;  // -2.0
        handicaps[2] = -1500;  // -1.5
        handicaps[3] = -1000;  // -1.0
        handicaps[4] = -500;   // -0.5
        handicaps[5] = 0;      // 0.0
        handicaps[6] = 500;    // +0.5
        handicaps[7] = 1000;   // +1.0
        handicaps[8] = 1500;   // +1.5
        handicaps[9] = 2000;   // +2.0
        handicaps[10] = 2500;  // +2.5
        return handicaps;
    }

    /**
     * @notice Score市场的均匀概率分布
     * @param numOutcomes 结果数量
     * @return 概率数组（总和=10000）
     */
    function getUniformProbabilities(uint256 numOutcomes) internal pure returns (uint256[] memory) {
        uint256[] memory probs = new uint256[](numOutcomes);
        uint256 baseProb = 10000 / numOutcomes;
        uint256 remainder = 10000 % numOutcomes;

        for (uint256 i = 0; i < numOutcomes; i++) {
            probs[i] = baseProb;
        }
        // 将余数加到最后一个元素
        probs[numOutcomes - 1] += remainder;

        return probs;
    }

    /**
     * @notice PlayerProps市场的默认初始储备
     * @param usdcUnit USDC精度单位
     * @return 储备数组
     */
    function getDefaultPlayerPropsReserves(uint256 usdcUnit) internal pure returns (uint256[] memory) {
        uint256[] memory reserves = new uint256[](2);
        reserves[0] = 100000 * usdcUnit; // 100k USDC for Over
        reserves[1] = 100000 * usdcUnit; // 100k USDC for Under
        return reserves;
    }

    /**
     * @notice Score市场的默认LMSR参数
     * @return liquidityB参数（WAD单位）
     */
    function getDefaultLMSRLiquidity() internal pure returns (uint256) {
        return 1000 * 1e18; // 1000 in WAD
    }
}
