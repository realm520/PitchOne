// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Coupon
 * @notice 赔率加成券系统（ERC-1155）
 * @dev 功能特性：
 *      - 多券种支持：不同加成比例、不同使用场景
 *      - 可交易性：基于 ERC-1155 标准
 *      - 限制条件：最低下注额、特定玩法、特定赛事
 *      - 自动过期：基于区块时间戳
 *      - 使用次数限制：支持一次性/多次使用
 *      - 赔率上限保护：防止超高赔率风险
 */
contract Coupon is ERC1155, AccessControl, Pausable {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 铸造者角色
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice 暂停者角色
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice 基点分母（100%）
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice 最大加成比例（50%）
    uint256 public constant MAX_BOOST_BPS = 5000;

    // ============================================================================
    // 枚举
    // ============================================================================

    /**
     * @notice 券使用场景
     */
    enum UsageScope {
        ALL,        // 所有市场
        WDL_ONLY,   // 仅胜平负
        OU_ONLY,    // 仅大小球
        AH_ONLY,    // 仅让球
        PARLAY_ONLY // 仅串关
    }

    // ============================================================================
    // 数据结构
    // ============================================================================

    /**
     * @notice 券种配置
     * @param boostBps 加成比例（基点，如 500 = 5% 加成）
     * @param scope 使用场景
     * @param minBetAmount 最低下注额要求（0 = 无限制）
     * @param maxOdds 最大赔率限制（如 5e18 = 5.0，0 = 无限制）
     * @param expiresAt 过期时间戳（0 = 永不过期）
     * @param maxUses 最大使用次数（0 = 无限制）
     * @param isActive 是否启用
     * @param metadata 元数据 URI
     */
    struct CouponType {
        uint256 boostBps;
        UsageScope scope;
        uint256 minBetAmount;
        uint256 maxOdds;
        uint256 expiresAt;
        uint256 maxUses;
        bool isActive;
        string metadata;
    }

    /**
     * @notice 券使用记录
     * @param user 用户地址
     * @param couponTypeId 券种 ID
     * @param market 市场地址
     * @param betAmount 下注金额
     * @param originalOdds 原始赔率
     * @param boostedOdds 加成后赔率
     * @param timestamp 使用时间
     */
    struct CouponUsage {
        address user;
        uint256 couponTypeId;
        address market;
        uint256 betAmount;
        uint256 originalOdds;
        uint256 boostedOdds;
        uint256 timestamp;
    }

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 券种 ID -> 券种配置
    mapping(uint256 => CouponType) public couponTypes;

    /// @notice 用户 -> 券种 ID -> 已使用次数
    mapping(address => mapping(uint256 => uint256)) public usedCount;

    /// @notice 下一个券种 ID
    uint256 public nextCouponTypeId;

    /// @notice 总发行量（券种 ID -> 总量）
    mapping(uint256 => uint256) public totalSupply;

    /// @notice 总使用次数（券种 ID -> 使用次数）
    mapping(uint256 => uint256) public totalUsed;

    /// @notice 券使用历史记录
    CouponUsage[] public usageHistory;

    /// @notice 用户使用历史索引（用户 -> 使用记录 ID 列表）
    mapping(address => uint256[]) public userUsageHistory;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 创建券种事件
     * @param couponTypeId 券种 ID
     * @param boostBps 加成比例
     * @param scope 使用场景
     * @param minBetAmount 最低下注额
     * @param maxOdds 最大赔率限制
     * @param expiresAt 过期时间
     * @param maxUses 最大使用次数
     */
    event CouponTypeCreated(
        uint256 indexed couponTypeId,
        uint256 boostBps,
        UsageScope scope,
        uint256 minBetAmount,
        uint256 maxOdds,
        uint256 expiresAt,
        uint256 maxUses
    );

    /**
     * @notice 券种状态更新事件
     * @param couponTypeId 券种 ID
     * @param isActive 是否启用
     */
    event CouponTypeStatusUpdated(uint256 indexed couponTypeId, bool isActive);

    /**
     * @notice 券使用事件
     * @param user 用户地址
     * @param couponTypeId 券种 ID
     * @param market 市场地址
     * @param betAmount 下注金额
     * @param originalOdds 原始赔率
     * @param boostedOdds 加成后赔率
     * @param usageId 使用记录 ID
     */
    event CouponUsed(
        address indexed user,
        uint256 indexed couponTypeId,
        address indexed market,
        uint256 betAmount,
        uint256 originalOdds,
        uint256 boostedOdds,
        uint256 usageId
    );

    /**
     * @notice 券批量发放事件
     * @param couponTypeId 券种 ID
     * @param recipients 接收者列表
     * @param amounts 数量列表
     * @param totalAmount 总数量
     */
    event CouponBatchMinted(
        uint256 indexed couponTypeId,
        address[] recipients,
        uint256[] amounts,
        uint256 totalAmount
    );

    // ============================================================================
    // 错误
    // ============================================================================

    error InvalidCouponType();
    error CouponExpired();
    error CouponNotActive();
    error InsufficientCoupon();
    error MaxUsesExceeded();
    error InvalidBoostBps();
    error BetAmountTooLow();
    error OddsTooHigh();
    error InvalidScope();
    error InvalidArrayLength();
    error ZeroAddress();

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param baseUri 基础 URI
     */
    constructor(string memory baseUri) ERC1155(baseUri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 创建券种
     * @param boostBps 加成比例（基点，最大 5000 = 50%）
     * @param scope 使用场景
     * @param minBetAmount 最低下注额（0 = 无限制）
     * @param maxOdds 最大赔率限制（0 = 无限制）
     * @param expiresAt 过期时间戳（0 = 永不过期）
     * @param maxUses 最大使用次数（0 = 无限制）
     * @param metadata 元数据 URI
     * @return couponTypeId 券种 ID
     */
    function createCouponType(
        uint256 boostBps,
        UsageScope scope,
        uint256 minBetAmount,
        uint256 maxOdds,
        uint256 expiresAt,
        uint256 maxUses,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 couponTypeId) {
        if (boostBps > MAX_BOOST_BPS) revert InvalidBoostBps();
        if (uint8(scope) > uint8(UsageScope.PARLAY_ONLY)) revert InvalidScope();

        couponTypeId = nextCouponTypeId++;

        couponTypes[couponTypeId] = CouponType({
            boostBps: boostBps,
            scope: scope,
            minBetAmount: minBetAmount,
            maxOdds: maxOdds,
            expiresAt: expiresAt,
            maxUses: maxUses,
            isActive: true,
            metadata: metadata
        });

        emit CouponTypeCreated(
            couponTypeId,
            boostBps,
            scope,
            minBetAmount,
            maxOdds,
            expiresAt,
            maxUses
        );
    }

    /**
     * @notice 更新券种状态
     * @param couponTypeId 券种 ID
     * @param isActive 是否启用
     */
    function setCouponTypeStatus(
        uint256 couponTypeId,
        bool isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (couponTypeId >= nextCouponTypeId) revert InvalidCouponType();

        couponTypes[couponTypeId].isActive = isActive;
        emit CouponTypeStatusUpdated(couponTypeId, isActive);
    }

    /**
     * @notice 更新基础 URI
     * @param newUri 新的基础 URI
     */
    function setURI(string memory newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    // ============================================================================
    // 发放函数
    // ============================================================================

    /**
     * @notice 单个发放券
     * @param to 接收者地址
     * @param couponTypeId 券种 ID
     * @param amount 数量
     */
    function mint(
        address to,
        uint256 couponTypeId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (to == address(0)) revert ZeroAddress();
        if (couponTypeId >= nextCouponTypeId) revert InvalidCouponType();
        if (!couponTypes[couponTypeId].isActive) revert CouponNotActive();

        _mint(to, couponTypeId, amount, "");
        totalSupply[couponTypeId] += amount;
    }

    /**
     * @notice 批量发放券（多个用户）
     * @param couponTypeId 券种 ID
     * @param recipients 接收者列表
     * @param amounts 数量列表
     */
    function batchMint(
        uint256 couponTypeId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (recipients.length != amounts.length) revert InvalidArrayLength();
        if (couponTypeId >= nextCouponTypeId) revert InvalidCouponType();
        if (!couponTypes[couponTypeId].isActive) revert CouponNotActive();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            _mint(recipients[i], couponTypeId, amounts[i], "");
            totalAmount += amounts[i];
        }

        totalSupply[couponTypeId] += totalAmount;
        emit CouponBatchMinted(couponTypeId, recipients, amounts, totalAmount);
    }

    // ============================================================================
    // 使用函数
    // ============================================================================

    /**
     * @notice 使用券提升赔率
     * @param user 用户地址
     * @param couponTypeId 券种 ID
     * @param market 市场地址
     * @param betAmount 下注金额
     * @param originalOdds 原始赔率（18 decimals，如 2.5e18）
     * @param marketScope 市场类型（用于验证使用场景）
     * @return boostedOdds 加成后赔率
     * @dev 只能由 MINTER_ROLE 调用（通常是 Market 合约）
     */
    function useCoupon(
        address user,
        uint256 couponTypeId,
        address market,
        uint256 betAmount,
        uint256 originalOdds,
        UsageScope marketScope
    ) external onlyRole(MINTER_ROLE) whenNotPaused returns (uint256 boostedOdds) {
        if (couponTypeId >= nextCouponTypeId) revert InvalidCouponType();

        CouponType storage coupon = couponTypes[couponTypeId];

        // 检查券是否启用
        if (!coupon.isActive) revert CouponNotActive();

        // 检查是否过期
        if (coupon.expiresAt > 0 && block.timestamp > coupon.expiresAt) {
            revert CouponExpired();
        }

        // 检查用户余额
        if (balanceOf(user, couponTypeId) == 0) {
            revert InsufficientCoupon();
        }

        // 检查使用次数限制
        if (coupon.maxUses > 0) {
            if (usedCount[user][couponTypeId] >= coupon.maxUses) {
                revert MaxUsesExceeded();
            }
            usedCount[user][couponTypeId]++;
        }

        // 检查使用场景
        if (coupon.scope != UsageScope.ALL && coupon.scope != marketScope) {
            revert InvalidScope();
        }

        // 检查最低下注额
        if (coupon.minBetAmount > 0 && betAmount < coupon.minBetAmount) {
            revert BetAmountTooLow();
        }

        // 计算加成后赔率
        boostedOdds = originalOdds + (originalOdds * coupon.boostBps) / BPS_DENOMINATOR;

        // 检查赔率上限
        if (coupon.maxOdds > 0 && boostedOdds > coupon.maxOdds) {
            revert OddsTooHigh();
        }

        // 销毁券
        _burn(user, couponTypeId, 1);

        // 记录使用历史
        uint256 usageId = usageHistory.length;
        usageHistory.push(CouponUsage({
            user: user,
            couponTypeId: couponTypeId,
            market: market,
            betAmount: betAmount,
            originalOdds: originalOdds,
            boostedOdds: boostedOdds,
            timestamp: block.timestamp
        }));

        userUsageHistory[user].push(usageId);

        // 更新统计
        totalUsed[couponTypeId]++;

        emit CouponUsed(
            user,
            couponTypeId,
            market,
            betAmount,
            originalOdds,
            boostedOdds,
            usageId
        );
    }

    // ============================================================================
    // 查询函数
    // ============================================================================

    /**
     * @notice 预览加成后赔率
     * @param couponTypeId 券种 ID
     * @param originalOdds 原始赔率
     * @return boostedOdds 加成后赔率
     */
    function previewBoostedOdds(
        uint256 couponTypeId,
        uint256 originalOdds
    ) external view returns (uint256 boostedOdds) {
        if (couponTypeId >= nextCouponTypeId) return originalOdds;

        CouponType storage coupon = couponTypes[couponTypeId];
        boostedOdds = originalOdds + (originalOdds * coupon.boostBps) / BPS_DENOMINATOR;

        // 应用赔率上限
        if (coupon.maxOdds > 0 && boostedOdds > coupon.maxOdds) {
            boostedOdds = coupon.maxOdds;
        }
    }

    /**
     * @notice 检查券是否可用
     * @param user 用户地址
     * @param couponTypeId 券种 ID
     * @param betAmount 下注金额
     * @param marketScope 市场类型
     * @return isValid 是否可用
     */
    function isCouponValid(
        address user,
        uint256 couponTypeId,
        uint256 betAmount,
        UsageScope marketScope
    ) external view returns (bool isValid) {
        if (couponTypeId >= nextCouponTypeId) return false;

        CouponType storage coupon = couponTypes[couponTypeId];

        // 检查是否启用
        if (!coupon.isActive) return false;

        // 检查是否过期
        if (coupon.expiresAt > 0 && block.timestamp > coupon.expiresAt) return false;

        // 检查用户余额
        if (balanceOf(user, couponTypeId) == 0) return false;

        // 检查使用次数限制
        if (coupon.maxUses > 0 && usedCount[user][couponTypeId] >= coupon.maxUses) {
            return false;
        }

        // 检查使用场景
        if (coupon.scope != UsageScope.ALL && coupon.scope != marketScope) {
            return false;
        }

        // 检查最低下注额
        if (coupon.minBetAmount > 0 && betAmount < coupon.minBetAmount) {
            return false;
        }

        return true;
    }

    /**
     * @notice 获取用户的券状态
     * @param user 用户地址
     * @param couponTypeId 券种 ID
     * @return balance 余额
     * @return used 已使用次数
     * @return maxUses 最大使用次数
     */
    function getCouponStatus(
        address user,
        uint256 couponTypeId
    ) external view returns (uint256 balance, uint256 used, uint256 maxUses) {
        balance = balanceOf(user, couponTypeId);
        used = usedCount[user][couponTypeId];
        maxUses = couponTypes[couponTypeId].maxUses;
    }

    /**
     * @notice 获取用户使用历史
     * @param user 用户地址
     * @return usageIds 使用记录 ID 列表
     */
    function getUserUsageHistory(
        address user
    ) external view returns (uint256[] memory usageIds) {
        return userUsageHistory[user];
    }

    /**
     * @notice 获取使用记录详情
     * @param usageId 使用记录 ID
     * @return usage 使用记录
     */
    function getUsageDetail(
        uint256 usageId
    ) external view returns (CouponUsage memory usage) {
        require(usageId < usageHistory.length, "Invalid usage ID");
        return usageHistory[usageId];
    }

    // ============================================================================
    // 暂停功能
    // ============================================================================

    /**
     * @notice 暂停合约
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice 恢复合约
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // ============================================================================
    // 接口支持
    // ============================================================================

    /**
     * @notice 检查接口支持
     * @param interfaceId 接口 ID
     * @return 是否支持
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ============================================================================
    // 元数据
    // ============================================================================

    /**
     * @notice 获取券种元数据 URI
     * @param couponTypeId 券种 ID
     * @return metadata URI
     */
    function uri(uint256 couponTypeId) public view override returns (string memory) {
        if (couponTypeId >= nextCouponTypeId) return "";

        string memory metadata = couponTypes[couponTypeId].metadata;
        if (bytes(metadata).length > 0) {
            return metadata;
        }

        return super.uri(couponTypeId);
    }
}
