// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ReferralRegistry.sol";
import "../interfaces/IParamController.sol";
import "../governance/ParamKeys.sol";

/**
 * @title FeeRouter
 * @notice 手续费路由合约，将手续费分配到不同的池子
 * @dev 完整版功能：
 *      - 多池分配：LP / Promo / Insurance / Treasury
 *      - 推荐返佣：集成 ReferralRegistry
 *      - 动态费率调整（治理控制）
 *      - 精确的基点计算（防止舍入误差）
 *      - 重入保护：使用 ReentrancyGuard
 */
contract FeeRouter is Ownable, Pausable, ReentrancyGuard {
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

    /// @notice 参数控制器（可选，用于读取全局费用分成参数）
    IParamController public paramController;

    /// @notice 是否使用 ParamController 的实时参数
    bool public useParamControllerForSplit;

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

    /**
     * @notice ParamController 变更事件
     */
    event ParamControllerUpdated(address indexed newController, bool useForSplit);

    /**
     * @notice 批量处理完成事件
     * @param token 代币地址
     * @param totalCount 总数量
     * @param successCount 成功数量
     * @param failedCount 失败数量
     * @param failedTotalAmount 失败总金额（已转入 Treasury）
     */
    event BatchProcessed(
        address indexed token,
        uint256 totalCount,
        uint256 successCount,
        uint256 failedCount,
        uint256 failedTotalAmount
    );

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
     * @param feeAmount 手续费金额
     * @param betAmount 用户下注总金额（用于追踪交易量）
     * @dev 自动处理推荐返佣 + 多池分配
     */
    function routeFee(
        address token,
        address from,
        uint256 feeAmount,
        uint256 betAmount
    ) external whenNotPaused nonReentrant {
        if (feeAmount == 0) return;

        // 更新用户交易量（用于推荐门槛检查）
        if (betAmount > 0) {
            referralRegistry.updateUserVolume(from, betAmount);
        }

        // 接收代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), feeAmount);
        totalFeesReceived[token] += feeAmount;
        emit FeeReceived(token, msg.sender, feeAmount);

        // 处理推荐返佣
        (address referrer, uint256 referralAmount) = _processReferral(token, from, feeAmount);

        // 剩余金额分配到各池
        uint256 remaining = feeAmount - referralAmount;
        _distributeFees(token, remaining);

        emit FeeRouted(
            token,
            feeAmount,
            referrer,
            referralAmount,
            (remaining * feeSplit.lpBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.promoBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.treasuryBps) / BPS_DENOMINATOR
        );
    }

    /**
     * @notice 批量路由手续费（优化 Gas + 事务性保证）
     * @param token 代币地址
     * @param users 用户地址数组
     * @param amounts 金额数组
     * @return successCount 成功处理的数量
     * @return failedIndices 失败的索引数组
     *
     * @dev 修复:
     *      1. 使用 try/catch 包裹每次分配,部分失败不影响其他
     *      2. 记录失败的索引,返回给调用者
     *      3. 失败的金额自动退还到 Treasury（安全兜底）
     *      4. 添加 BatchProcessed 事件记录批量操作结果
     */
    function batchRouteFee(
        address token,
        address[] calldata users,
        uint256[] calldata amounts
    ) external whenNotPaused nonReentrant returns (uint256 successCount, uint256[] memory failedIndices) {
        require(users.length == amounts.length, "Length mismatch");
        require(users.length <= 100, "Batch size too large"); // 防止 DOS

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        // 一次性接收所有代币
        IERC20(token).safeTransferFrom(msg.sender, address(this), totalAmount);
        totalFeesReceived[token] += totalAmount;

        // 初始化失败追踪数组（最坏情况：全部失败）
        uint256[] memory tempFailedIndices = new uint256[](users.length);
        uint256 failedCount = 0;
        uint256 failedTotalAmount = 0;

        // 逐个处理（使用 try/catch 捕获单个失败）
        for (uint256 i = 0; i < users.length; i++) {
            if (amounts[i] == 0) {
                successCount++;
                continue;
            }

            // 使用 try/catch 包裹整个处理流程
            try this._processSingleFee(token, users[i], amounts[i]) {
                successCount++;
            } catch {
                // 记录失败索引
                tempFailedIndices[failedCount] = i;
                failedCount++;
                failedTotalAmount += amounts[i];
            }
        }

        // 构造精确的失败索引数组
        failedIndices = new uint256[](failedCount);
        for (uint256 i = 0; i < failedCount; i++) {
            failedIndices[i] = tempFailedIndices[i];
        }

        // 处理失败金额：全部转入 Treasury 作为安全兜底
        if (failedTotalAmount > 0) {
            IERC20(token).safeTransfer(recipients.treasury, failedTotalAmount);
            totalFeesDistributed[token]["treasury"] += failedTotalAmount;
        }

        emit BatchProcessed(token, users.length, successCount, failedCount, failedTotalAmount);

        return (successCount, failedIndices);
    }

    /**
     * @notice 处理单笔费用（内部函数,供 batchRouteFee 调用）
     * @dev 必须是 external 才能被 try/catch 捕获
     */
    function _processSingleFee(
        address token,
        address user,
        uint256 amount
    ) external {
        require(msg.sender == address(this), "Only self-call");

        // 1. 处理推荐返佣
        (address referrer, uint256 referralAmount) = _processReferral(token, user, amount);

        // 2. 分配剩余费用
        uint256 remaining = amount - referralAmount;
        _distributeFees(token, remaining);

        // 3. 发出事件
        emit FeeRouted(
            token,
            amount,
            referrer,
            referralAmount,
            (remaining * feeSplit.lpBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.promoBps) / BPS_DENOMINATOR,
            (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR,
            remaining - (remaining * feeSplit.lpBps) / BPS_DENOMINATOR - (remaining * feeSplit.promoBps) / BPS_DENOMINATOR - (remaining * feeSplit.insuranceBps) / BPS_DENOMINATOR
        );
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
     * @notice 分配费用到各池（精确分配,无舍入误差）
     * @dev 修复: Treasury获得剩余全部金额,确保 sum(分配金额) == amount
     *      验证: 添加断言检查分配总和
     *      支持从 ParamController 实时读取分成比例
     */
    function _distributeFees(address token, uint256 amount) internal {
        if (amount == 0) return;

        IERC20 erc20 = IERC20(token);

        // 获取有效的分成配置（可能来自 ParamController）
        FeeSplit memory split = getEffectiveFeeSplit();

        // 1. 计算各池精确金额（向下取整）
        uint256 lpAmount = (amount * split.lpBps) / BPS_DENOMINATOR;
        uint256 promoAmount = (amount * split.promoBps) / BPS_DENOMINATOR;
        uint256 insuranceAmount = (amount * split.insuranceBps) / BPS_DENOMINATOR;

        // 2. Treasury获得剩余全部金额（吸收所有舍入误差）
        uint256 treasuryAmount = amount - lpAmount - promoAmount - insuranceAmount;

        // 3. 安全检查：确保分配总和等于原始金额
        assert(lpAmount + promoAmount + insuranceAmount + treasuryAmount == amount);

        // 4. 执行转账（批量优化）
        if (lpAmount > 0) {
            erc20.safeTransfer(recipients.lpVault, lpAmount);
            totalFeesDistributed[token]["lp"] += lpAmount;
        }

        if (promoAmount > 0) {
            erc20.safeTransfer(recipients.promoPool, promoAmount);
            totalFeesDistributed[token]["promo"] += promoAmount;
        }

        if (insuranceAmount > 0) {
            erc20.safeTransfer(recipients.insuranceFund, insuranceAmount);
            totalFeesDistributed[token]["insurance"] += insuranceAmount;
        }

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

        // 使用有效的分成配置
        FeeSplit memory split = getEffectiveFeeSplit();

        lpAmount = (remaining * split.lpBps) / BPS_DENOMINATOR;
        promoAmount = (remaining * split.promoBps) / BPS_DENOMINATOR;
        insuranceAmount = (remaining * split.insuranceBps) / BPS_DENOMINATOR;
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
     * @notice 设置参数控制器
     * @param _paramController ParamController 地址
     * @param _useForSplit 是否使用 ParamController 的实时分成参数
     */
    function setParamController(address _paramController, bool _useForSplit) external onlyOwner {
        paramController = IParamController(_paramController);
        useParamControllerForSplit = _useForSplit;
        emit ParamControllerUpdated(_paramController, _useForSplit);
    }

    /**
     * @notice 从 ParamController 同步费用分成配置
     * @dev 一次性同步，适用于不想实时读取的场景
     */
    function syncFeeSplitFromParams() external onlyOwner {
        require(address(paramController) != address(0), "FeeRouter: No param controller");

        uint256 lpBps = paramController.tryGetParam(ParamKeys.FEE_LP_SHARE_BPS, feeSplit.lpBps);
        uint256 promoBps = paramController.tryGetParam(ParamKeys.FEE_PROMO_SHARE_BPS, feeSplit.promoBps);
        uint256 insuranceBps = paramController.tryGetParam(ParamKeys.FEE_INSURANCE_SHARE_BPS, feeSplit.insuranceBps);
        uint256 treasuryBps = paramController.tryGetParam(ParamKeys.FEE_TREASURY_SHARE_BPS, feeSplit.treasuryBps);

        uint256 total = lpBps + promoBps + insuranceBps + treasuryBps;
        if (total != BPS_DENOMINATOR) {
            revert InvalidFeeSplit(total);
        }

        feeSplit = FeeSplit({
            lpBps: lpBps,
            promoBps: promoBps,
            insuranceBps: insuranceBps,
            treasuryBps: treasuryBps
        });

        emit FeeSplitUpdated(lpBps, promoBps, insuranceBps, treasuryBps);
    }

    /**
     * @notice 获取当前有效的费用分成配置
     * @dev 如果启用了实时读取，返回 ParamController 中的值
     */
    function getEffectiveFeeSplit() public view returns (FeeSplit memory split) {
        if (useParamControllerForSplit && address(paramController) != address(0)) {
            split.lpBps = paramController.tryGetParam(ParamKeys.FEE_LP_SHARE_BPS, feeSplit.lpBps);
            split.promoBps = paramController.tryGetParam(ParamKeys.FEE_PROMO_SHARE_BPS, feeSplit.promoBps);
            split.insuranceBps = paramController.tryGetParam(ParamKeys.FEE_INSURANCE_SHARE_BPS, feeSplit.insuranceBps);
            split.treasuryBps = paramController.tryGetParam(ParamKeys.FEE_TREASURY_SHARE_BPS, feeSplit.treasuryBps);
        } else {
            split = feeSplit;
        }
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
