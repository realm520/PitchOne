// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FeeRouter
 * @notice 手续费路由合约，将手续费分配到不同的池子
 * @dev Phase 0 简化版：仅支持单一接收地址
 *      Phase 1 完整版：LP / Promo / Insurance / Treasury 多池分配
 */
contract FeeRouter is Ownable {
    using SafeERC20 for IERC20;

    // ============ 事件 ============

    /// @notice 手续费接收事件
    event FeeReceived(address indexed token, address indexed from, uint256 amount);

    /// @notice 手续费分配事件
    event FeeDistributed(
        address indexed token,
        address indexed recipient,
        uint256 amount,
        string category
    );

    // ============ 状态变量 ============

    /// @notice Phase 0: 所有费用发往国库
    address public treasury;

    // ============ 构造函数 ============

    constructor(address _treasury) Ownable(msg.sender) {
        require(_treasury != address(0), "FeeRouter: Invalid treasury");
        treasury = _treasury;
    }

    // ============ 核心函数 ============

    /**
     * @notice 接收手续费（市场合约调用）
     * @dev Phase 0: 自动记录，不立即分配
     */
    receive() external payable {
        emit FeeReceived(address(0), msg.sender, msg.value);
    }

    /**
     * @notice 提取并分配手续费（管理员调用）
     * @param token 代币地址（address(0) 表示 ETH）
     * @dev Phase 0: 全部发往国库
     *      Phase 1: 按比例分配到 LP/Promo/Insurance/Treasury
     */
    function distributeFees(address token) external onlyOwner {
        uint256 amount;

        if (token == address(0)) {
            // ETH
            amount = address(this).balance;
            require(amount > 0, "FeeRouter: No ETH to distribute");
            (bool success, ) = treasury.call{value: amount}("");
            require(success, "FeeRouter: ETH transfer failed");
        } else {
            // ERC20
            IERC20 erc20 = IERC20(token);
            amount = erc20.balanceOf(address(this));
            require(amount > 0, "FeeRouter: No tokens to distribute");
            erc20.safeTransfer(treasury, amount);
        }

        emit FeeDistributed(token, treasury, amount, "treasury");
    }

    // ============ 管理函数 ============

    /**
     * @notice 更新国库地址
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "FeeRouter: Invalid treasury");
        treasury = _treasury;
    }

    /**
     * @notice 紧急提取（安全保障）
     */
    function emergencyWithdraw(address token, address to, uint256 amount)
        external
        onlyOwner
    {
        require(to != address(0), "FeeRouter: Invalid address");

        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "FeeRouter: ETH transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
