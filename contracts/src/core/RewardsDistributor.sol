// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RewardsDistributor
 * @notice 周度 Merkle 奖励分发合约
 * @dev 核心特性：
 *      - 周度 Merkle Root 发布（由 Keeper 触发）
 *      - 用户凭 Merkle Proof 领取奖励
 *      - 支持统一缩放比例（预算不足时）
 *      - 防重复领取机制
 *      - 批量领取支持
 *      - 线性释放机制（可选，T+7）
 */
contract RewardsDistributor is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ============================================================================
    // 数据结构
    // ============================================================================

    /**
     * @notice 周度奖励数据
     * @param merkleRoot Merkle 树根
     * @param totalAmount 总奖励金额（原始金额，未缩放）
     * @param scaleBps 缩放比例（基点，10000 = 100%）
     * @param publishedAt 发布时间戳
     * @param claimedAmount 已领取金额
     */
    struct WeeklyReward {
        bytes32 merkleRoot;
        uint256 totalAmount;
        uint256 scaleBps;
        uint256 publishedAt;
        uint256 claimedAmount;
    }

    /**
     * @notice 线性释放配置
     * @param enabled 是否启用线性释放
     * @param vestingDuration 释放周期（秒），默认7天
     */
    struct VestingConfig {
        bool enabled;
        uint256 vestingDuration;
    }

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 奖励代币（USDC 或其他 ERC20）
    IERC20 public immutable rewardToken;

    /// @notice 周编号 -> 奖励数据
    mapping(uint256 => WeeklyReward) public weeklyRewards;

    /// @notice 用户 -> 周编号 -> 已领取金额
    mapping(address => mapping(uint256 => uint256)) public claimed;

    /// @notice 当前周编号（自增）
    uint256 public currentWeek;

    /// @notice 线性释放配置
    VestingConfig public vestingConfig;

    /// @notice 授权发布者（Keeper 服务）
    mapping(address => bool) public isPublisher;

    /// @notice 紧急提款地址
    address public emergencyWithdrawAddress;

    // ============================================================================
    // 常量
    // ============================================================================

    /// @notice 基点分母（100%）
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice 最小缩放比例（10% = 1000 BPS）
    uint256 public constant MIN_SCALE_BPS = 1000;

    /// @notice 默认释放周期（7天）
    uint256 public constant DEFAULT_VESTING_DURATION = 7 days;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 奖励根发布事件
     * @param week 周编号
     * @param merkleRoot Merkle 树根
     * @param totalAmount 总奖励金额
     * @param scaleBps 缩放比例
     * @param publishedAt 发布时间戳
     */
    event RewardsRootPublished(
        uint256 indexed week,
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 scaleBps,
        uint256 publishedAt
    );

    /**
     * @notice 奖励领取事件
     * @param user 用户地址
     * @param week 周编号
     * @param amount 领取金额（已缩放）
     * @param claimedAt 领取时间戳
     */
    event RewardClaimed(
        address indexed user,
        uint256 indexed week,
        uint256 amount,
        uint256 claimedAt
    );

    /**
     * @notice 批量领取事件
     * @param user 用户地址
     * @param weekCount 领取周数
     * @param totalAmount 总领取金额
     */
    event BatchClaimed(
        address indexed user,
        uint256 weekCount,
        uint256 totalAmount
    );

    /**
     * @notice 发布者权限变更事件
     * @param publisher 发布者地址
     * @param enabled 是否启用
     */
    event PublisherUpdated(address indexed publisher, bool enabled);

    /**
     * @notice 线性释放配置变更事件
     * @param enabled 是否启用
     * @param duration 释放周期
     */
    event VestingConfigUpdated(bool enabled, uint256 duration);

    /**
     * @notice 紧急提款事件
     * @param to 接收地址
     * @param amount 提款金额
     */
    event EmergencyWithdraw(address indexed to, uint256 amount);

    // ============================================================================
    // 错误定义
    // ============================================================================

    error UnauthorizedPublisher();
    error InvalidMerkleRoot();
    error InvalidScaleBps(uint256 provided, uint256 min);
    error WeekAlreadyPublished(uint256 week);
    error WeekNotPublished(uint256 week);
    error InvalidProof();
    error AlreadyClaimed(address user, uint256 week);
    error InsufficientBalance(uint256 required, uint256 available);
    error InvalidVestingDuration(uint256 duration);
    error ZeroAddress();
    error EmptyWeeksArray();

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @param _rewardToken 奖励代币地址
     * @param _emergencyWithdrawAddress 紧急提款地址
     */
    constructor(address _rewardToken, address _emergencyWithdrawAddress) Ownable(msg.sender) {
        if (_rewardToken == address(0) || _emergencyWithdrawAddress == address(0)) {
            revert ZeroAddress();
        }

        rewardToken = IERC20(_rewardToken);
        emergencyWithdrawAddress = _emergencyWithdrawAddress;

        // 默认启用 7 天线性释放
        vestingConfig = VestingConfig({
            enabled: true,
            vestingDuration: DEFAULT_VESTING_DURATION
        });
    }

    // ============================================================================
    // 发布者功能
    // ============================================================================

    /**
     * @notice 发布周度奖励根
     * @param week 周编号
     * @param merkleRoot Merkle 树根
     * @param totalAmount 总奖励金额
     * @param scaleBps 缩放比例（10000 = 100%）
     */
    function publishRoot(
        uint256 week,
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 scaleBps
    ) external whenNotPaused {
        if (!isPublisher[msg.sender] && msg.sender != owner()) {
            revert UnauthorizedPublisher();
        }
        if (merkleRoot == bytes32(0)) {
            revert InvalidMerkleRoot();
        }
        if (scaleBps < MIN_SCALE_BPS || scaleBps > BPS_DENOMINATOR) {
            revert InvalidScaleBps(scaleBps, MIN_SCALE_BPS);
        }
        if (weeklyRewards[week].merkleRoot != bytes32(0)) {
            revert WeekAlreadyPublished(week);
        }

        weeklyRewards[week] = WeeklyReward({
            merkleRoot: merkleRoot,
            totalAmount: totalAmount,
            scaleBps: scaleBps,
            publishedAt: block.timestamp,
            claimedAmount: 0
        });

        if (week >= currentWeek) {
            currentWeek = week + 1;
        }

        emit RewardsRootPublished(week, merkleRoot, totalAmount, scaleBps, block.timestamp);
    }

    // ============================================================================
    // 用户领取功能
    // ============================================================================

    /**
     * @notice 领取单周奖励
     * @param week 周编号
     * @param amount 奖励金额（原始金额，未缩放）
     * @param proof Merkle 证明
     */
    function claim(
        uint256 week,
        uint256 amount,
        bytes32[] calldata proof
    ) external whenNotPaused {
        _claim(msg.sender, week, amount, proof);
    }

    /**
     * @notice 批量领取多周奖励
     * @param weekNumbers 周编号数组
     * @param amounts 奖励金额数组
     * @param proofs Merkle 证明数组（嵌套数组）
     */
    function batchClaim(
        uint256[] calldata weekNumbers,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external whenNotPaused {
        if (weekNumbers.length == 0) revert EmptyWeeksArray();
        require(weekNumbers.length == amounts.length && weekNumbers.length == proofs.length, "Length mismatch");

        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < weekNumbers.length; i++) {
            uint256 claimedAmount = _claim(msg.sender, weekNumbers[i], amounts[i], proofs[i]);
            totalClaimed += claimedAmount;
        }

        emit BatchClaimed(msg.sender, weekNumbers.length, totalClaimed);
    }

    /**
     * @notice 内部领取逻辑
     * @return claimedAmount 实际领取金额（已缩放）
     */
    function _claim(
        address user,
        uint256 week,
        uint256 amount,
        bytes32[] calldata proof
    ) internal returns (uint256 claimedAmount) {
        WeeklyReward storage weekReward = weeklyRewards[week];

        // 验证周已发布
        if (weekReward.merkleRoot == bytes32(0)) {
            revert WeekNotPublished(week);
        }

        // 验证未领取
        if (claimed[user][week] > 0) {
            revert AlreadyClaimed(user, week);
        }

        // 验证 Merkle Proof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, week, amount))));
        if (!MerkleProof.verify(proof, weekReward.merkleRoot, leaf)) {
            revert InvalidProof();
        }

        // 计算实际领取金额（应用缩放比例 + 线性释放，单次计算避免精度损失）
        if (vestingConfig.enabled) {
            uint256 elapsed = block.timestamp - weekReward.publishedAt;
            if (elapsed < vestingConfig.vestingDuration) {
                // 单次计算：amount * scaleBps * elapsed / (BPS_DENOMINATOR * vestingDuration)
                claimedAmount = (amount * weekReward.scaleBps * elapsed) / (BPS_DENOMINATOR * vestingConfig.vestingDuration);
            } else {
                // 完全释放
                claimedAmount = (amount * weekReward.scaleBps) / BPS_DENOMINATOR;
            }
        } else {
            // 无线性释放
            claimedAmount = (amount * weekReward.scaleBps) / BPS_DENOMINATOR;
        }

        // 检查合约余额
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance < claimedAmount) {
            revert InsufficientBalance(claimedAmount, balance);
        }

        // 记录领取
        claimed[user][week] = claimedAmount;
        weekReward.claimedAmount += claimedAmount;

        // 转账
        rewardToken.safeTransfer(user, claimedAmount);

        emit RewardClaimed(user, week, claimedAmount, block.timestamp);
    }

    // ============================================================================
    // 查询功能
    // ============================================================================

    /**
     * @notice 查询用户在指定周的可领取金额
     * @param user 用户地址
     * @param week 周编号
     * @param amount 原始奖励金额
     * @param proof Merkle 证明
     * @return claimable 可领取金额
     * @return alreadyClaimed 是否已领取
     */
    function getClaimable(
        address user,
        uint256 week,
        uint256 amount,
        bytes32[] calldata proof
    ) external view returns (uint256 claimable, bool alreadyClaimed) {
        WeeklyReward memory weekReward = weeklyRewards[week];

        // 检查是否已领取
        if (claimed[user][week] > 0) {
            return (0, true);
        }

        // 检查周是否发布
        if (weekReward.merkleRoot == bytes32(0)) {
            return (0, false);
        }

        // 验证 Merkle Proof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, week, amount))));
        if (!MerkleProof.verify(proof, weekReward.merkleRoot, leaf)) {
            return (0, false);
        }

        // 计算可领取金额（应用缩放比例 + 线性释放，单次计算避免精度损失）
        if (vestingConfig.enabled) {
            uint256 elapsed = block.timestamp - weekReward.publishedAt;
            if (elapsed < vestingConfig.vestingDuration) {
                // 单次计算：amount * scaleBps * elapsed / (BPS_DENOMINATOR * vestingDuration)
                claimable = (amount * weekReward.scaleBps * elapsed) / (BPS_DENOMINATOR * vestingConfig.vestingDuration);
            } else {
                // 完全释放
                claimable = (amount * weekReward.scaleBps) / BPS_DENOMINATOR;
            }
        } else {
            // 无线性释放
            claimable = (amount * weekReward.scaleBps) / BPS_DENOMINATOR;
        }

        return (claimable, false);
    }

    /**
     * @notice 查询周度统计信息
     * @param week 周编号
     */
    function getWeekStats(uint256 week) external view returns (
        bytes32 merkleRoot,
        uint256 totalAmount,
        uint256 scaleBps,
        uint256 claimedAmount,
        uint256 claimRate // 基点
    ) {
        WeeklyReward memory weekReward = weeklyRewards[week];
        merkleRoot = weekReward.merkleRoot;
        totalAmount = weekReward.totalAmount;
        scaleBps = weekReward.scaleBps;
        claimedAmount = weekReward.claimedAmount;

        if (totalAmount > 0) {
            claimRate = (claimedAmount * BPS_DENOMINATOR) / ((totalAmount * scaleBps) / BPS_DENOMINATOR);
        }
    }

    /**
     * @notice 批量查询用户领取记录
     * @param user 用户地址
     * @param weekNumbers 周编号数组
     * @return amounts 已领取金额数组
     */
    function getBatchClaimed(
        address user,
        uint256[] calldata weekNumbers
    ) external view returns (uint256[] memory amounts) {
        amounts = new uint256[](weekNumbers.length);
        for (uint256 i = 0; i < weekNumbers.length; i++) {
            amounts[i] = claimed[user][weekNumbers[i]];
        }
    }

    // ============================================================================
    // 管理功能
    // ============================================================================

    /**
     * @notice 设置发布者权限
     */
    function setPublisher(address publisher, bool enabled) external onlyOwner {
        if (publisher == address(0)) revert ZeroAddress();
        isPublisher[publisher] = enabled;
        emit PublisherUpdated(publisher, enabled);
    }

    /**
     * @notice 设置线性释放配置
     */
    function setVestingConfig(bool enabled, uint256 duration) external onlyOwner {
        if (enabled && duration == 0) {
            revert InvalidVestingDuration(duration);
        }
        vestingConfig = VestingConfig({enabled: enabled, vestingDuration: duration});
        emit VestingConfigUpdated(enabled, duration);
    }

    /**
     * @notice 设置紧急提款地址
     */
    function setEmergencyWithdrawAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert ZeroAddress();
        emergencyWithdrawAddress = _address;
    }

    /**
     * @notice 紧急提款（仅 Owner）
     */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance < amount) {
            revert InsufficientBalance(amount, balance);
        }
        rewardToken.safeTransfer(emergencyWithdrawAddress, amount);
        emit EmergencyWithdraw(emergencyWithdrawAddress, amount);
    }

    /**
     * @notice 暂停合约
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice 恢复合约
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
