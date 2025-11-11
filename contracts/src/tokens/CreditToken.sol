// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title CreditToken
 * @notice 免手续费券系统（ERC-1155）
 * @dev 功能特性：
 *      - 多券种支持：不同面额、不同过期时间
 *      - 可交易性：基于 ERC-1155 标准
 *      - 使用次数限制：支持一次性/多次使用
 *      - 自动过期：基于区块时间戳
 *      - 批量发放：支持活动批量空投
 *      - 权限控制：MINTER_ROLE 发放权限
 */
contract CreditToken is ERC1155, AccessControl, Pausable {
    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 铸造者角色
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice 暂停者角色
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice 基点分母（100%）
    uint256 public constant BPS_DENOMINATOR = 10000;

    // ============================================================================
    // 数据结构
    // ============================================================================

    /**
     * @notice 券种配置
     * @param value 面额（以 USDC 6 decimals 计，如 1000000 = 1 USDC）
     * @param discountBps 折扣比例（基点，10000 = 100% 免手续费）
     * @param expiresAt 过期时间戳（0 = 永不过期）
     * @param maxUses 最大使用次数（0 = 无限制）
     * @param isActive 是否启用
     * @param metadata 元数据 URI
     */
    struct CreditType {
        uint256 value;
        uint256 discountBps;
        uint256 expiresAt;
        uint256 maxUses;
        bool isActive;
        string metadata;
    }

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 券种 ID -> 券种配置
    mapping(uint256 => CreditType) public creditTypes;

    /// @notice 用户 -> 券种 ID -> 已使用次数
    mapping(address => mapping(uint256 => uint256)) public usedCount;

    /// @notice 下一个券种 ID
    uint256 public nextCreditTypeId;

    /// @notice 总发行量（券种 ID -> 总量）
    mapping(uint256 => uint256) public totalSupply;

    /// @notice 总使用次数（券种 ID -> 使用次数）
    mapping(uint256 => uint256) public totalUsed;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 创建券种事件
     * @param creditTypeId 券种 ID
     * @param value 面额
     * @param discountBps 折扣比例（基点）
     * @param expiresAt 过期时间
     * @param maxUses 最大使用次数
     */
    event CreditTypeCreated(
        uint256 indexed creditTypeId,
        uint256 value,
        uint256 discountBps,
        uint256 expiresAt,
        uint256 maxUses
    );

    /**
     * @notice 券种状态更新事件
     * @param creditTypeId 券种 ID
     * @param isActive 是否启用
     */
    event CreditTypeStatusUpdated(uint256 indexed creditTypeId, bool isActive);

    /**
     * @notice 券使用事件
     * @param user 用户地址
     * @param creditTypeId 券种 ID
     * @param amount 使用数量
     * @param discountValue 折扣金额
     */
    event CreditUsed(
        address indexed user,
        uint256 indexed creditTypeId,
        uint256 amount,
        uint256 discountValue
    );

    /**
     * @notice 券批量发放事件
     * @param creditTypeId 券种 ID
     * @param recipients 接收者列表
     * @param amounts 数量列表
     * @param totalAmount 总数量
     */
    event CreditBatchMinted(
        uint256 indexed creditTypeId,
        address[] recipients,
        uint256[] amounts,
        uint256 totalAmount
    );

    // ============================================================================
    // 错误
    // ============================================================================

    error InvalidCreditType();
    error CreditExpired();
    error CreditNotActive();
    error InsufficientCredit();
    error MaxUsesExceeded();
    error InvalidDiscountBps();
    error InvalidArrayLength();
    error ZeroAddress();

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @notice 构造函数
     * @param uri 基础 URI
     */
    constructor(string memory uri) ERC1155(uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    // ============================================================================
    // 管理函数
    // ============================================================================

    /**
     * @notice 创建券种
     * @param value 面额
     * @param discountBps 折扣比例（基点，最大 10000）
     * @param expiresAt 过期时间戳（0 = 永不过期）
     * @param maxUses 最大使用次数（0 = 无限制）
     * @param metadata 元数据 URI
     * @return creditTypeId 券种 ID
     */
    function createCreditType(
        uint256 value,
        uint256 discountBps,
        uint256 expiresAt,
        uint256 maxUses,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256 creditTypeId) {
        if (discountBps > BPS_DENOMINATOR) revert InvalidDiscountBps();

        creditTypeId = nextCreditTypeId++;

        creditTypes[creditTypeId] = CreditType({
            value: value,
            discountBps: discountBps,
            expiresAt: expiresAt,
            maxUses: maxUses,
            isActive: true,
            metadata: metadata
        });

        emit CreditTypeCreated(creditTypeId, value, discountBps, expiresAt, maxUses);
    }

    /**
     * @notice 更新券种状态
     * @param creditTypeId 券种 ID
     * @param isActive 是否启用
     */
    function setCreditTypeStatus(
        uint256 creditTypeId,
        bool isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (creditTypeId >= nextCreditTypeId) revert InvalidCreditType();

        creditTypes[creditTypeId].isActive = isActive;
        emit CreditTypeStatusUpdated(creditTypeId, isActive);
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
     * @param creditTypeId 券种 ID
     * @param amount 数量
     */
    function mint(
        address to,
        uint256 creditTypeId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (to == address(0)) revert ZeroAddress();
        if (creditTypeId >= nextCreditTypeId) revert InvalidCreditType();
        if (!creditTypes[creditTypeId].isActive) revert CreditNotActive();

        _mint(to, creditTypeId, amount, "");
        totalSupply[creditTypeId] += amount;
    }

    /**
     * @notice 批量发放券（多个用户）
     * @param creditTypeId 券种 ID
     * @param recipients 接收者列表
     * @param amounts 数量列表
     */
    function batchMint(
        uint256 creditTypeId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        if (recipients.length != amounts.length) revert InvalidArrayLength();
        if (creditTypeId >= nextCreditTypeId) revert InvalidCreditType();
        if (!creditTypes[creditTypeId].isActive) revert CreditNotActive();

        uint256 totalAmount;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            _mint(recipients[i], creditTypeId, amounts[i], "");
            totalAmount += amounts[i];
        }

        totalSupply[creditTypeId] += totalAmount;
        emit CreditBatchMinted(creditTypeId, recipients, amounts, totalAmount);
    }

    // ============================================================================
    // 使用函数
    // ============================================================================

    /**
     * @notice 使用券抵扣手续费
     * @param user 用户地址
     * @param creditTypeId 券种 ID
     * @param amount 使用数量
     * @return discountValue 折扣金额
     * @dev 只能由 MINTER_ROLE 调用（通常是 Market 合约）
     */
    function useCredit(
        address user,
        uint256 creditTypeId,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused returns (uint256 discountValue) {
        if (creditTypeId >= nextCreditTypeId) revert InvalidCreditType();

        CreditType storage credit = creditTypes[creditTypeId];

        // 检查券是否启用
        if (!credit.isActive) revert CreditNotActive();

        // 检查是否过期
        if (credit.expiresAt > 0 && block.timestamp > credit.expiresAt) {
            revert CreditExpired();
        }

        // 检查用户余额
        if (balanceOf(user, creditTypeId) < amount) {
            revert InsufficientCredit();
        }

        // 检查使用次数限制
        if (credit.maxUses > 0) {
            if (usedCount[user][creditTypeId] + amount > credit.maxUses) {
                revert MaxUsesExceeded();
            }
            usedCount[user][creditTypeId] += amount;
        }

        // 销毁券
        _burn(user, creditTypeId, amount);

        // 计算折扣金额
        discountValue = (credit.value * credit.discountBps * amount) / BPS_DENOMINATOR;

        // 更新统计
        totalUsed[creditTypeId] += amount;

        emit CreditUsed(user, creditTypeId, amount, discountValue);
    }

    // ============================================================================
    // 查询函数
    // ============================================================================

    /**
     * @notice 获取用户可用的折扣金额
     * @param user 用户地址
     * @param creditTypeId 券种 ID
     * @return availableDiscount 可用折扣金额
     */
    function getAvailableDiscount(
        address user,
        uint256 creditTypeId
    ) external view returns (uint256 availableDiscount) {
        if (creditTypeId >= nextCreditTypeId) return 0;

        CreditType storage credit = creditTypes[creditTypeId];

        // 检查是否启用
        if (!credit.isActive) return 0;

        // 检查是否过期
        if (credit.expiresAt > 0 && block.timestamp > credit.expiresAt) {
            return 0;
        }

        uint256 balance = balanceOf(user, creditTypeId);
        if (balance == 0) return 0;

        // 检查使用次数限制
        if (credit.maxUses > 0) {
            uint256 remainingUses = credit.maxUses - usedCount[user][creditTypeId];
            if (remainingUses == 0) return 0;
            balance = balance > remainingUses ? remainingUses : balance;
        }

        availableDiscount = (credit.value * credit.discountBps * balance) / BPS_DENOMINATOR;
    }

    /**
     * @notice 检查券是否有效
     * @param creditTypeId 券种 ID
     * @return isValid 是否有效
     */
    function isCreditValid(uint256 creditTypeId) external view returns (bool isValid) {
        if (creditTypeId >= nextCreditTypeId) return false;

        CreditType storage credit = creditTypes[creditTypeId];

        if (!credit.isActive) return false;
        if (credit.expiresAt > 0 && block.timestamp > credit.expiresAt) return false;

        return true;
    }

    /**
     * @notice 获取用户的券余额和使用情况
     * @param user 用户地址
     * @param creditTypeId 券种 ID
     * @return balance 余额
     * @return used 已使用次数
     * @return maxUses 最大使用次数
     */
    function getCreditStatus(
        address user,
        uint256 creditTypeId
    ) external view returns (uint256 balance, uint256 used, uint256 maxUses) {
        balance = balanceOf(user, creditTypeId);
        used = usedCount[user][creditTypeId];
        maxUses = creditTypes[creditTypeId].maxUses;
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
     * @param creditTypeId 券种 ID
     * @return metadata URI
     */
    function uri(uint256 creditTypeId) public view override returns (string memory) {
        if (creditTypeId >= nextCreditTypeId) return "";

        string memory metadata = creditTypes[creditTypeId].metadata;
        if (bytes(metadata).length > 0) {
            return metadata;
        }

        return super.uri(creditTypeId);
    }
}
