// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ReferralRegistry
 * @notice 推荐关系注册表 - 管理用户推荐关系和返佣累计
 * @dev 核心特性：
 *      - 一次绑定，永久有效（不可更改）
 *      - 防止循环推荐（A→B→A）
 *      - 有效窗口机制（绑定后N天内有效）
 *      - 累计返佣记录（链下聚合，链上验证）
 */
contract ReferralRegistry is Ownable, Pausable {
    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 用户 -> 推荐人映射
    mapping(address => address) public referrer;

    /// @notice 推荐人 -> 被推荐人数量
    mapping(address => uint256) public referralCount;

    /// @notice 推荐人 -> 累计返佣金额（链下聚合，链上仅用于统计）
    mapping(address => uint256) public totalReferralRewards;

    /// @notice 用户绑定时间戳
    mapping(address => uint256) public boundAt;

    /// @notice 用户累计交易量（用于门槛检查）
    mapping(address => uint256) public userTotalVolume;

    /// @notice 有效窗口期（秒），默认365天
    uint256 public validityWindow = 365 days;

    /// @notice 最小有效交易量（用于防止刷量）
    uint256 public minValidVolume = 100e6; // 100 USDC (假设6位小数)

    /// @notice 推荐返佣比例（基点，默认800 = 8%）
    uint256 public referralFeeBps = 800;

    /// @notice 最大推荐层级（暂时仅支持1层）
    uint256 public constant MAX_REFERRAL_DEPTH = 1;

    /// @notice 授权调用者映射（允许调用 accrueReferralReward 的地址）
    mapping(address => bool) public authorizedCallers;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 推荐关系绑定事件
     * @param user 被推荐用户
     * @param referrer 推荐人
     * @param campaignId 活动ID（0表示常规推荐）
     * @param timestamp 绑定时间
     */
    event ReferralBound(
        address indexed user,
        address indexed referrer,
        uint256 indexed campaignId,
        uint256 timestamp
    );

    /**
     * @notice 推荐返佣累计事件
     * @param referrer 推荐人
     * @param user 被推荐用户
     * @param amount 返佣金额
     * @param timestamp 累计时间
     */
    event ReferralAccrued(
        address indexed referrer,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice 参数更新事件
     * @param param 参数名称
     * @param value 新值
     */
    event ParameterUpdated(string param, uint256 value);

    /**
     * @notice 授权调用者变更事件
     * @param caller 调用者地址
     * @param authorized 是否授权
     */
    event AuthorizedCallerUpdated(address indexed caller, bool authorized);

    /**
     * @notice 用户交易量更新事件
     * @param user 用户地址
     * @param amount 新增交易量
     * @param totalVolume 累计总交易量
     * @param timestamp 更新时间
     */
    event UserVolumeUpdated(
        address indexed user,
        uint256 amount,
        uint256 totalVolume,
        uint256 timestamp
    );

    // ============================================================================
    // 错误定义
    // ============================================================================

    error AlreadyBound(address user, address existingReferrer);
    error SelfReferral(address user);
    error CircularReferral(address user, address referrer);
    error InvalidReferrer(address referrer);
    error ReferralExpired(address user, uint256 boundAt, uint256 validUntil);
    error InvalidFeeBps(uint256 bps);
    error UnauthorizedCaller(address caller);

    // ============================================================================
    // 修饰符
    // ============================================================================

    /**
     * @notice 仅授权调用者可以调用
     */
    modifier onlyAuthorized() {
        if (!authorizedCallers[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    // ============================================================================
    // 构造函数
    // ============================================================================

    constructor(address initialOwner) Ownable(initialOwner) {}

    // ============================================================================
    // 核心功能
    // ============================================================================

    /**
     * @notice 绑定推荐关系
     * @param _referrer 推荐人地址
     * @param campaignId 活动ID（0表示常规推荐）
     * @dev 要求：
     *      - 用户尚未绑定推荐人
     *      - 推荐人不能是自己
     *      - 不能形成循环推荐
     *      - 合约未暂停
     */
    function bind(address _referrer, uint256 campaignId) external whenNotPaused {
        address user = msg.sender;

        // 检查是否已绑定
        if (referrer[user] != address(0)) {
            revert AlreadyBound(user, referrer[user]);
        }

        // 检查自我推荐
        if (_referrer == user) {
            revert SelfReferral(user);
        }

        // 检查推荐人有效性
        if (_referrer == address(0)) {
            revert InvalidReferrer(_referrer);
        }

        // 检查循环推荐（简化版：只检查一层）
        if (referrer[_referrer] == user) {
            revert CircularReferral(user, _referrer);
        }

        // 绑定推荐关系
        referrer[user] = _referrer;
        referralCount[_referrer]++;
        boundAt[user] = block.timestamp;

        emit ReferralBound(user, _referrer, campaignId, block.timestamp);
    }

    /**
     * @notice 记录推荐返佣累计（仅限授权合约调用）
     * @param _referrer 推荐人
     * @param user 被推荐用户
     * @param amount 返佣金额
     * @dev 通常由 FeeRouter 或其他授权合约调用
     */
    function accrueReferralReward(
        address _referrer,
        address user,
        uint256 amount
    ) external onlyAuthorized {
        if (_referrer == address(0)) return;

        totalReferralRewards[_referrer] += amount;

        emit ReferralAccrued(_referrer, user, amount, block.timestamp);
    }

    /**
     * @notice 更新用户累计交易量（仅限授权合约调用）
     * @param user 用户地址
     * @param amount 新增交易量
     * @dev 通常由 FeeRouter 或 Market 合约调用，用于追踪用户的累计下注金额
     */
    function updateUserVolume(address user, uint256 amount) external onlyAuthorized {
        if (user == address(0)) return;

        userTotalVolume[user] += amount;

        emit UserVolumeUpdated(user, amount, userTotalVolume[user], block.timestamp);
    }

    // ============================================================================
    // 查询功能
    // ============================================================================

    /**
     * @notice 获取用户的推荐人
     * @param user 用户地址
     * @return 推荐人地址（0x0表示无推荐人）
     */
    function getReferrer(address user) external view returns (address) {
        return referrer[user];
    }

    /**
     * @notice 检查推荐关系是否有效
     * @param user 用户地址
     * @return 是否有效
     */
    function isReferralValid(address user) public view returns (bool) {
        address _referrer = referrer[user];
        if (_referrer == address(0)) return false;

        // 检查有效期
        uint256 boundTime = boundAt[user];
        if (block.timestamp > boundTime + validityWindow) {
            return false;
        }

        // 检查最小交易量门槛
        if (userTotalVolume[user] < minValidVolume) {
            return false;
        }

        return true;
    }

    /**
     * @notice 获取推荐人的统计信息
     * @param _referrer 推荐人地址
     * @return count 推荐人数
     * @return rewards 累计返佣金额
     */
    function getReferrerStats(address _referrer)
        external
        view
        returns (uint256 count, uint256 rewards)
    {
        return (referralCount[_referrer], totalReferralRewards[_referrer]);
    }

    /**
     * @notice 批量查询推荐关系
     * @param users 用户地址数组
     * @return referrers 对应的推荐人数组
     */
    function getReferrersBatch(address[] calldata users)
        external
        view
        returns (address[] memory referrers)
    {
        referrers = new address[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            referrers[i] = referrer[users[i]];
        }
    }

    /**
     * @notice 获取用户累计交易量
     * @param user 用户地址
     * @return 累计交易量
     */
    function getUserVolume(address user) external view returns (uint256) {
        return userTotalVolume[user];
    }

    // ============================================================================
    // 管理功能
    // ============================================================================

    /**
     * @notice 更新有效窗口期
     * @param newWindow 新的窗口期（秒）
     */
    function setValidityWindow(uint256 newWindow) external onlyOwner {
        validityWindow = newWindow;
        emit ParameterUpdated("validityWindow", newWindow);
    }

    /**
     * @notice 更新最小有效交易量
     * @param newMinVolume 新的最小交易量
     */
    function setMinValidVolume(uint256 newMinVolume) external onlyOwner {
        minValidVolume = newMinVolume;
        emit ParameterUpdated("minValidVolume", newMinVolume);
    }

    /**
     * @notice 更新推荐返佣比例
     * @param newFeeBps 新的返佣比例（基点）
     */
    function setReferralFeeBps(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > 2000) {
            // 最大20%
            revert InvalidFeeBps(newFeeBps);
        }
        referralFeeBps = newFeeBps;
        emit ParameterUpdated("referralFeeBps", newFeeBps);
    }

    /**
     * @notice 设置授权调用者
     * @param caller 调用者地址
     * @param authorized 是否授权
     * @dev 通常用于授权 FeeRouter 等合约调用 accrueReferralReward
     */
    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        authorizedCallers[caller] = authorized;
        emit AuthorizedCallerUpdated(caller, authorized);
    }

    /**
     * @notice 暂停/恢复合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice 紧急解绑（仅限特殊情况，如欺诈）
     * @param user 用户地址
     * @dev 谨慎使用！会影响用户的推荐关系
     */
    function emergencyUnbind(address user) external onlyOwner {
        address _referrer = referrer[user];
        if (_referrer != address(0)) {
            referralCount[_referrer]--;
            delete referrer[user];
            delete boundAt[user];
        }
    }
}
