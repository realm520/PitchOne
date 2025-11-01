// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./ReferralRegistry.sol";

/**
 * @title FeeRouter
 * @notice 手续费路由合约，将手续费分配到不同的池子
 * @dev 完整版功能：
 *      - 多池分配：LP / Promo / Insurance / Treasury
 *      - 推荐返佣：集成 ReferralRegistry
 *      - 动态费率调整（治理控制）
 *      - 精确的基点计算（防止舍入误差）
 */
contract FeeRouter is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // ============================================================================
    // 数据结构
    // ============================================================================

    /**
     * @notice 费用分配配置
     * @param lpBps LP 金库份额（基点）
     * @param promoBps 推广/奖励池份额（基点）
     * @param insuranceBps 保险基金份额（基点）
     * @param treasuryBps 国库份额（基点）
     */
    struct FeeSplit {
        uint256 lpBps;
        uint256 promoBps;
        uint256 insuranceBps;
        uint256 treasuryBps;
    }

    /**
     * @notice 费用接收地址
     * @param lpVault LP 金库地址
     * @param promoPool 推广池地址（RewardsDistributor）
     * @param insuranceFund 保险基金地址
     * @param treasury 国库地址
     */
    struct FeeRecipients {
        address lpVault;
        address promoPool;
        address insuranceFund;
        address treasury;
    }

    // ============================================================================
    // 状态变量
    // ============================================================================

    /// @notice 费用分配比例
    FeeSplit public feeSplit;

    /// @notice 费用接收地址
    FeeRecipients public recipients;

    /// @notice 推荐注册表
    ReferralRegistry public referralRegistry;

    /// @notice 基点分母（100%）
    uint256 public constant BPS_DENOMINATOR = 10000;

    /// @notice 最大推荐返佣比例（20%）
    uint256 public constant MAX_REFERRAL_BPS = 2000;

    /// @notice 代币 -> 累计接收金额
    mapping(address => uint256) public totalFeesReceived;

    /// @notice 代币 -> 类别 -> 累计分配金额
    mapping(address => mapping(string => uint256)) public totalFeesDistributed;

    // ============================================================================
    // 事件
    // ============================================================================

    /**
     * @notice 手续费接收事件
     * @param token 代币地址
     * @param from 来源地址（市场合约）
     * @param amount 金额
     */
    event FeeReceived(
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /**
     * @notice 手续费路由事件（含推荐返佣）
     * @param token 代币地址
     * @param totalAmount 总金额
     * @param referrer 推荐人地址
     * @param referralAmount 推荐返佣金额
     * @param lpAmount LP 金库金额
     * @param promoAmount 推广池金额
     * @param insuranceAmount 保险基金金额
     * @param treasuryAmount 国库金额
     */
    event FeeRouted(
        address indexed token,
        uint256 totalAmount,
        address indexed referrer,
        uint256 referralAmount,
        uint256 lpAmount,
        uint256 promoAmount,
        uint256 insuranceAmount,
        uint256 treasuryAmount
    );

    /**
     * @notice 费用分配配置变更事件
     */
    event FeeSplitUpdated(
        uint256 lpBps,
        uint256 promoBps,
        uint256 insuranceBps,
        uint256 treasuryBps
    );

    /**
     * @notice 费用接收地址变更事件
     */
    event RecipientsUpdated(
        address lpVault,
        address promoPool,
        address insuranceFund,
        address treasury
    );

    /**
     * @notice 推荐注册表变更事件
     */
    event ReferralRegistryUpdated(address indexed newRegistry);

    // ============================================================================
    // 错误定义
    // ============================================================================

    error InvalidFeeSplit(uint256 total);
    error ZeroAddress(string param);
    error NoFeesToDistribute();
    error InvalidReferralBps(uint256 provided, uint256 max);

    // ============================================================================
    // 构造函数
    // ============================================================================

    /**
     * @param _recipients 费用接收地址
     * @param _referralRegistry 推荐注册表地址
     */
    constructor(
        FeeRecipients memory _recipients,
        address _referralRegistry
    ) Ownable(msg.sender) {
        _validateRecipients(_recipients);
        if (_referralRegistry == address(0)) revert ZeroAddress("referralRegistry");

        recipients = _recipients;
        referralRegistry = ReferralRegistry(_referralRegistry);

        // 默认分配：LP 40%, Promo 30%, Insurance 10%, Treasury 20%
        feeSplit = FeeSplit({
            lpBps: 4000,
            promoBps: 3000,
            insuranceBps: 1000,
            treasuryBps: 2000
        });

        emit RecipientsUpdated(
            _recipients.lpVault,
            _recipients.promoPool,
            _recipients.insuranceFund,
            _recipients.treasury
        );
        emit FeeSplitUpdated(4000, 3000, 1000, 2000);
    }

    // ============================================================================
    // 核心功能
    // ============================================================================

    /**
     * @notice 路由手续费（由市场合约调用）
     * @param token 代币地址
     * @param from 来源地址（下注用户）
     * @param amount 手续费金额
     * @dev 自动处理推荐返佣 + 多池分配
     */
    function routeFee(
        address token,
        address from,
        uint256 amount
    ) external whenNotPaused {
        if (amount == 0) return;

        // 接收代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        totalFeesReceived[token] += amount;
        emit FeeReceived(token, msg.sender, amount);

        // 处理推荐返佣
        (address referrer, uint256 referralAmount) = _processReferral(token, from, amount);

        // 剩余金额分配到各池
        uint256 remaining = amount - referralAmount;
        _distributeFees(token, remaining);

        emit FeeRouted(
            token,
            amount,
            referrer,
            referralAmount,
            (remaining * feeSplit.lpBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.promoBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.treasuryBps) / BPS_DENOMINATOR
        );
    }

    /**
     * @notice 批量路由手续费（优化 Gas）
     * @param token 代币地址
     * @param users 用户地址数组
     * @param amounts 金额数组
     */
    function batchRouteFee(
        address token,
        address[] calldata users,
        uint256[] calldata amounts
    ) external whenNotPaused {
        require(users.length == amounts.length, "Length mismatch");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // 一次性接收所有代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), totalAmount);
        totalFeesReceived[token] += totalAmount;

        // 逐个处理
        for (uint256 i = 0; i < users.length; i++) {
            if (amounts[i] == 0) continue;

            (address referrer, uint256 referralAmount) = _processReferral(
                token,
                users[i],
                amounts[i]
            );

            uint256 remaining = amounts[i] - referralAmount;
            _distributeFees(token, remaining);

            emit FeeRouted(
                token,
                amounts[i],
                referrer,
                referralAmount,
                (remaining * feeSplit.lpBps) / BPS_DENOMINATOR,
                (remaining * feeSplit.promoBps) / BPS_DENOMINATOR,
                (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR,
                (remaining * feeSplit.treasuryBps) / BPS_DENOMINATOR
            );
        }
    }

    /**
     * @notice 处理推荐返佣
     * @return referrer 推荐人地址
     * @return referralAmount 返佣金额
     */
    function _processReferral(
        address token,
        address user,
        uint256 amount
    ) internal returns (address referrer, uint256 referralAmount) {
        referrer = referralRegistry.referrer(user);

        if (referrer == address(0)) {
            return (address(0), 0);
        }

        // 检查推荐关系是否有效
        if (!referralRegistry.isReferralValid(user)) {
            return (address(0), 0);
        }

        // 计算返佣金额
        uint256 referralBps = referralRegistry.referralFeeBps();
        referralAmount = (amount * referralBps) / BPS_DENOMINATOR;

        if (referralAmount > 0) {
            // 转账给推荐人
            IERC20(token).safeTransfer(referrer, referralAmount);
            totalFeesDistributed[token]["referral"] += referralAmount;

            // 更新推荐注册表中的累计返佣
            referralRegistry.accrueReferralReward(referrer, user, referralAmount);
        }
    }

    /**
     * @notice 分配费用到各池
     */
    function _distributeFees(address token, uint256 amount) internal {
        IERC20 erc20 = IERC20(token);

        // LP 金库
        uint256 lpAmount = (amount * feeSplit.lpBps) / BPS_DENOMINATOR;
        if (lpAmount > 0) {
            erc20.safeTransfer(recipients.lpVault, lpAmount);
            totalFeesDistributed[token]["lp"] += lpAmount;
        }

        // 推广池
        uint256 promoAmount = (amount * feeSplit.promoBps) / BPS_DENOMINATOR;
        if (promoAmount > 0) {
            erc20.safeTransfer(recipients.promoPool, promoAmount);
            totalFeesDistributed[token]["promo"] += promoAmount;
        }

        // 保险基金
        uint256 insuranceAmount = (amount * feeSplit.insuranceBps) / BPS_DENOMINATOR;
        if (insuranceAmount > 0) {
            erc20.safeTransfer(recipients.insuranceFund, insuranceAmount);
            totalFeesDistributed[token]["insurance"] += insuranceAmount;
        }

        // 国库（剩余部分，避免舍入误差）
        uint256 treasuryAmount = amount - lpAmount - promoAmount - insuranceAmount;
        if (treasuryAmount > 0) {
            erc20.safeTransfer(recipients.treasury, treasuryAmount);
            totalFeesDistributed[token]["treasury"] += treasuryAmount;
        }
    }

    // ============================================================================
    // 查询功能
    // ============================================================================

    /**
     * @notice 查询某用户的推荐返佣比例
     */
    function getReferralBps(address user) external view returns (uint256) {
        if (referralRegistry.referrer(user) == address(0)) {
            return 0;
        }
        if (!referralRegistry.isReferralValid(user)) {
            return 0;
        }
        return referralRegistry.referralFeeBps();
    }

    /**
     * @notice 预览费用分配
     * @param amount 总金额
     * @param hasReferrer 是否有推荐人
     * @return referralAmount 推荐返佣
     * @return lpAmount LP 金库
     * @return promoAmount 推广池
     * @return insuranceAmount 保险基金
     * @return treasuryAmount 国库
     */
    function previewFeeSplit(
        uint256 amount,
        bool hasReferrer
    ) external view returns (
        uint256 referralAmount,
        uint256 lpAmount,
        uint256 promoAmount,
        uint256 insuranceAmount,
        uint256 treasuryAmount
    ) {
        if (hasReferrer) {
            uint256 referralBps = referralRegistry.referralFeeBps();
            referralAmount = (amount * referralBps) / BPS_DENOMINATOR;
        }

        uint256 remaining = amount - referralAmount;

        lpAmount = (remaining * feeSplit.lpBps) / BPS_DENOMINATOR;
        promoAmount = (remaining * feeSplit.promoBps) / BPS_DENOMINATOR;
        insuranceAmount = (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR;
        treasuryAmount = remaining - lpAmount - promoAmount - insuranceAmount;
    }

    /**
     * @notice 查询代币的费用统计
     */
    function getFeeStats(address token) external view returns (
        uint256 totalReceived,
        uint256 totalReferral,
        uint256 totalLP,
        uint256 totalPromo,
        uint256 totalInsurance,
        uint256 totalTreasury
    ) {
        totalReceived = totalFeesReceived[token];
        totalReferral = totalFeesDistributed[token]["referral"];
        totalLP = totalFeesDistributed[token]["lp"];
        totalPromo = totalFeesDistributed[token]["promo"];
        totalInsurance = totalFeesDistributed[token]["insurance"];
        totalTreasury = totalFeesDistributed[token]["treasury"];
    }

    // ============================================================================
    // 管理功能
    // ============================================================================

    /**
     * @notice 设置费用分配比例
     * @dev 总和必须等于 10000 (100%)
     */
    function setFeeSplit(
        uint256 _lpBps,
        uint256 _promoBps,
        uint256 _insuranceBps,
        uint256 _treasuryBps
    ) external onlyOwner {
        uint256 total = _lpBps + _promoBps + _insuranceBps + _treasuryBps;
        if (total != BPS_DENOMINATOR) {
            revert InvalidFeeSplit(total);
        }

        feeSplit = FeeSplit({
            lpBps: _lpBps,
            promoBps: _promoBps,
            insuranceBps: _insuranceBps,
            treasuryBps: _treasuryBps
        });

        emit FeeSplitUpdated(_lpBps, _promoBps, _insuranceBps, _treasuryBps);
    }

    /**
     * @notice 更新费用接收地址
     */
    function setRecipients(FeeRecipients memory _recipients) external onlyOwner {
        _validateRecipients(_recipients);
        recipients = _recipients;
        emit RecipientsUpdated(
            _recipients.lpVault,
            _recipients.promoPool,
            _recipients.insuranceFund,
            _recipients.treasury
        );
    }

    /**
     * @notice 更新推荐注册表
     */
    function setReferralRegistry(address _registry) external onlyOwner {
        if (_registry == address(0)) revert ZeroAddress("registry");
        referralRegistry = ReferralRegistry(_registry);
        emit ReferralRegistryUpdated(_registry);
    }

    /**
     * @notice 验证接收地址
     */
    function _validateRecipients(FeeRecipients memory _recipients) internal pure {
        if (_recipients.lpVault == address(0)) revert ZeroAddress("lpVault");
        if (_recipients.promoPool == address(0)) revert ZeroAddress("promoPool");
        if (_recipients.insuranceFund == address(0)) revert ZeroAddress("insuranceFund");
        if (_recipients.treasury == address(0)) revert ZeroAddress("treasury");
    }

    /**
     * @notice 紧急提取（安全保障）
     */
    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (to == address(0)) revert ZeroAddress("to");
        IERC20(token).safeTransfer(to, amount);
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
