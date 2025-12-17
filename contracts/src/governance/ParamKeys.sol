// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ParamKeys
 * @notice 平台所有可配置参数的键值定义
 * @dev 统一管理参数键，避免分散定义导致的不一致
 *
 * 参数分类：
 * - 费用相关：手续费率、分成比例
 * - 投注限制：最小/最大投注金额、用户敞口、市场赔付上限
 * - 定价参数：最小/最大赔率
 * - 预言机参数：争议期时长
 */
library ParamKeys {
    /*//////////////////////////////////////////////////////////////
                              费用相关参数
    //////////////////////////////////////////////////////////////*/

    /// @notice 平台手续费率（基点，10000 = 100%）
    /// @dev 默认值: 200 (2.00%)
    bytes32 public constant FEE_RATE = keccak256("FEE_RATE");

    /// @notice 手续费的 LP 金库分成（基点，相对于手续费总额）
    /// @dev 默认值: 6000 (60.00%)
    bytes32 public constant FEE_LP_SHARE_BPS = keccak256("FEE_LP_SHARE_BPS");

    /// @notice 手续费的推广池分成（基点）
    /// @dev 默认值: 2000 (20.00%)
    bytes32 public constant FEE_PROMO_SHARE_BPS = keccak256("FEE_PROMO_SHARE_BPS");

    /// @notice 手续费的保险池分成（基点）
    /// @dev 默认值: 1000 (10.00%)
    bytes32 public constant FEE_INSURANCE_SHARE_BPS = keccak256("FEE_INSURANCE_SHARE_BPS");

    /// @notice 手续费的国库分成（基点）
    /// @dev 默认值: 1000 (10.00%)
    bytes32 public constant FEE_TREASURY_SHARE_BPS = keccak256("FEE_TREASURY_SHARE_BPS");

    /*//////////////////////////////////////////////////////////////
                              投注限制参数
    //////////////////////////////////////////////////////////////*/

    /// @notice USDC 市场最小投注金额（以 USDC 最小单位计，6 位小数）
    /// @dev 默认值: 1_000_000 (1.00 USDC)
    bytes32 public constant MIN_BET_AMOUNT = keccak256("MIN_BET_AMOUNT");

    /// @notice USDC 市场最大投注金额（以 USDC 最小单位计）
    /// @dev 默认值: 5_000_000 (5.00 USDC)
    /// @dev 注意：你的需求表中最大投注是 5 USDC，但这可能太低，可以按需调整
    bytes32 public constant MAX_BET_AMOUNT = keccak256("MAX_BET_AMOUNT");

    /// @notice 单个用户在单个 USDC 市场的最大敞口（以 USDC 最小单位计）
    /// @dev 默认值: 50_000_000_000 (50,000 USDC)
    bytes32 public constant USER_EXPOSURE_LIMIT = keccak256("USER_EXPOSURE_LIMIT");

    /// @notice 单个 USDC 市场的最大可赔付金额（以 USDC 最小单位计）
    /// @dev 默认值: 10_000_000_000_000 (10,000,000 USDC)
    bytes32 public constant MARKET_PAYOUT_CAP = keccak256("MARKET_PAYOUT_CAP");

    /*//////////////////////////////////////////////////////////////
                              定价参数
    //////////////////////////////////////////////////////////////*/

    /// @notice 单个市场的最大赔率（以 1e4 为基准，10000 = 1.0x）
    /// @dev 默认值: 10_000_000 (1000x)
    bytes32 public constant MAX_ODDS = keccak256("MAX_ODDS");

    /// @notice 单个市场的最小赔率（以 1e4 为基准，10000 = 1.0x）
    /// @dev 默认值: 10_000 (1.0x)
    bytes32 public constant MIN_ODDS = keccak256("MIN_ODDS");

    /*//////////////////////////////////////////////////////////////
                              预言机参数
    //////////////////////////////////////////////////////////////*/

    /// @notice 结算后争议期持续时长（秒）
    /// @dev 默认值: 7200 (2 小时)
    bytes32 public constant DISPUTE_WINDOW = keccak256("DISPUTE_WINDOW");

    /*//////////////////////////////////////////////////////////////
                              辅助函数
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取所有参数键
     * @return keys 参数键数组
     */
    function getAllKeys() internal pure returns (bytes32[] memory keys) {
        keys = new bytes32[](12);
        keys[0] = FEE_RATE;
        keys[1] = FEE_LP_SHARE_BPS;
        keys[2] = FEE_PROMO_SHARE_BPS;
        keys[3] = FEE_INSURANCE_SHARE_BPS;
        keys[4] = FEE_TREASURY_SHARE_BPS;
        keys[5] = MIN_BET_AMOUNT;
        keys[6] = MAX_BET_AMOUNT;
        keys[7] = USER_EXPOSURE_LIMIT;
        keys[8] = MARKET_PAYOUT_CAP;
        keys[9] = MAX_ODDS;
        keys[10] = MIN_ODDS;
        keys[11] = DISPUTE_WINDOW;
    }

    /**
     * @notice 获取所有参数的默认值
     * @return values 默认值数组（与 getAllKeys 对应）
     */
    function getDefaultValues() internal pure returns (uint256[] memory values) {
        values = new uint256[](12);
        values[0] = 200;                    // FEE_RATE: 2.00%
        values[1] = 6000;                   // FEE_LP_SHARE_BPS: 60.00%
        values[2] = 2000;                   // FEE_PROMO_SHARE_BPS: 20.00%
        values[3] = 1000;                   // FEE_INSURANCE_SHARE_BPS: 10.00%
        values[4] = 1000;                   // FEE_TREASURY_SHARE_BPS: 10.00%
        values[5] = 1_000_000;              // MIN_BET_AMOUNT: 1 USDC
        values[6] = 5_000_000;              // MAX_BET_AMOUNT: 5 USDC
        values[7] = 50_000_000_000;         // USER_EXPOSURE_LIMIT: 50,000 USDC
        values[8] = 10_000_000_000_000;     // MARKET_PAYOUT_CAP: 10,000,000 USDC
        values[9] = 10_000_000;             // MAX_ODDS: 1000x (以 1e4 为基准)
        values[10] = 10_000;                // MIN_ODDS: 1.0x (以 1e4 为基准)
        values[11] = 7200;                  // DISPUTE_WINDOW: 2 小时
    }

    /*//////////////////////////////////////////////////////////////
                              验证范围定义
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 获取参数的验证范围
     * @param key 参数键
     * @return min 最小值
     * @return max 最大值
     */
    function getValidRange(bytes32 key) internal pure returns (uint256 min, uint256 max) {
        if (key == FEE_RATE) {
            return (0, 1000);                    // 0-10%
        } else if (key == FEE_LP_SHARE_BPS) {
            return (0, 10000);                   // 0-100%
        } else if (key == FEE_PROMO_SHARE_BPS) {
            return (0, 10000);                   // 0-100%
        } else if (key == FEE_INSURANCE_SHARE_BPS) {
            return (0, 10000);                   // 0-100%
        } else if (key == FEE_TREASURY_SHARE_BPS) {
            return (0, 10000);                   // 0-100%
        } else if (key == MIN_BET_AMOUNT) {
            return (100_000, 100_000_000);       // 0.1 - 100 USDC
        } else if (key == MAX_BET_AMOUNT) {
            return (1_000_000, 1_000_000_000_000); // 1 - 1,000,000 USDC
        } else if (key == USER_EXPOSURE_LIMIT) {
            return (1_000_000, 1_000_000_000_000); // 1 - 1,000,000 USDC
        } else if (key == MARKET_PAYOUT_CAP) {
            return (1_000_000_000, 100_000_000_000_000); // 1,000 - 100,000,000 USDC
        } else if (key == MAX_ODDS) {
            return (10_100, 100_000_000);        // 1.01x - 10000x
        } else if (key == MIN_ODDS) {
            return (10_000, 10_100);             // 1.0x - 1.01x
        } else if (key == DISPUTE_WINDOW) {
            return (1800, 604800);               // 30 分钟 - 7 天
        }
        return (0, type(uint256).max);           // 默认无限制
    }
}
