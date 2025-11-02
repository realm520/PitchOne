// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ParamController
 * @notice 集中管理平台所有可配置参数的治理合约
 * @dev 通过角色控制和 Timelock 机制确保参数变更的安全性和透明性
 *
 * 核心功能：
 * - 参数注册与查询
 * - 提案创建与执行（Timelock 延迟）
 * - 参数验证与依赖检查
 * - 紧急暂停机制
 *
 * 角色权限：
 * - PROPOSER_ROLE: 可以创建参数变更提案
 * - EXECUTOR_ROLE: 可以执行已过 Timelock 的提案
 * - GUARDIAN_ROLE: 可以紧急暂停参数变更
 * - DEFAULT_ADMIN_ROLE: 可以管理角色和初始化参数
 */
contract ParamController is AccessControl, Pausable {
    /// @notice 提案者角色（通常为 Safe 多签）
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    /// @notice 执行者角色（通常为 Timelock 合约）
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @notice 守护者角色（可紧急暂停）
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Timelock 延迟时间（默认 2 天）
    uint256 public timelockDelay;

    /// @notice 最小 Timelock 延迟（1 小时）
    uint256 public constant MIN_TIMELOCK_DELAY = 1 hours;

    /// @notice 最大 Timelock 延迟（7 天）
    uint256 public constant MAX_TIMELOCK_DELAY = 7 days;

    /// @notice 参数提案结构
    struct Proposal {
        bytes32 key;           // 参数键
        uint256 oldValue;      // 旧值
        uint256 newValue;      // 新值
        uint256 eta;           // 预计执行时间（Estimated Time of Arrival）
        bool executed;         // 是否已执行
        bool cancelled;        // 是否已取消
        address proposer;      // 提案者
        string reason;         // 变更理由
    }

    /// @notice 参数存储 (key => value)
    mapping(bytes32 => uint256) private params;

    /// @notice 参数是否已注册
    mapping(bytes32 => bool) public isParamRegistered;

    /// @notice 参数验证器 (key => validator contract)
    mapping(bytes32 => address) public validators;

    /// @notice 提案存储 (proposalId => Proposal)
    mapping(bytes32 => Proposal) public proposals;

    /// @notice 提案计数器
    uint256 public proposalCount;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ParamRegistered(bytes32 indexed key, uint256 initialValue, address indexed validator);
    event ProposalCreated(
        bytes32 indexed proposalId,
        bytes32 indexed key,
        uint256 oldValue,
        uint256 newValue,
        uint256 eta,
        address indexed proposer,
        string reason
    );
    event ProposalExecuted(bytes32 indexed proposalId, bytes32 indexed key, uint256 oldValue, uint256 newValue);
    event ProposalCancelled(bytes32 indexed proposalId, address indexed canceller);
    event ParamChanged(bytes32 indexed key, uint256 oldValue, uint256 newValue, uint256 timestamp);
    event TimelockDelayUpdated(uint256 oldDelay, uint256 newDelay);
    event ValidatorUpdated(bytes32 indexed key, address oldValidator, address newValidator);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ParamNotRegistered(bytes32 key);
    error ParamAlreadyRegistered(bytes32 key);
    error InvalidValue(bytes32 key, uint256 value, string reason);
    error ProposalNotFound(bytes32 proposalId);
    error ProposalAlreadyExecuted(bytes32 proposalId);
    error ProposalAlreadyCancelled(bytes32 proposalId);
    error TimelockNotExpired(bytes32 proposalId, uint256 eta, uint256 current);
    error InvalidTimelockDelay(uint256 delay);
    error ValidationFailed(bytes32 key, uint256 value);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 构造函数
     * @param admin 管理员地址（通常为 Safe 多签）
     * @param _timelockDelay Timelock 延迟时间
     */
    constructor(address admin, uint256 _timelockDelay) {
        if (_timelockDelay < MIN_TIMELOCK_DELAY || _timelockDelay > MAX_TIMELOCK_DELAY) {
            revert InvalidTimelockDelay(_timelockDelay);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PROPOSER_ROLE, admin);
        _grantRole(EXECUTOR_ROLE, admin);
        _grantRole(GUARDIAN_ROLE, admin);

        timelockDelay = _timelockDelay;
    }

    /*//////////////////////////////////////////////////////////////
                            PARAM REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 注册新参数
     * @param key 参数键
     * @param initialValue 初始值
     * @param validator 验证器合约地址（0 表示无验证器）
     */
    function registerParam(
        bytes32 key,
        uint256 initialValue,
        address validator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (isParamRegistered[key]) {
            revert ParamAlreadyRegistered(key);
        }

        // 如果有验证器，先验证初始值
        if (validator != address(0)) {
            _validateParam(key, initialValue, validator);
        }

        params[key] = initialValue;
        isParamRegistered[key] = true;
        validators[key] = validator;

        emit ParamRegistered(key, initialValue, validator);
    }

    /**
     * @notice 批量注册参数
     * @param keys 参数键数组
     * @param initialValues 初始值数组
     * @param _validators 验证器数组
     */
    function registerParamsBatch(
        bytes32[] calldata keys,
        uint256[] calldata initialValues,
        address[] calldata _validators
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(keys.length == initialValues.length && keys.length == _validators.length, "Length mismatch");

        for (uint256 i = 0; i < keys.length; i++) {
            if (isParamRegistered[keys[i]]) {
                revert ParamAlreadyRegistered(keys[i]);
            }

            if (_validators[i] != address(0)) {
                _validateParam(keys[i], initialValues[i], _validators[i]);
            }

            params[keys[i]] = initialValues[i];
            isParamRegistered[keys[i]] = true;
            validators[keys[i]] = _validators[i];

            emit ParamRegistered(keys[i], initialValues[i], _validators[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PARAM QUERIES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 查询参数值
     * @param key 参数键
     * @return value 参数值
     */
    function getParam(bytes32 key) external view returns (uint256) {
        if (!isParamRegistered[key]) {
            revert ParamNotRegistered(key);
        }
        return params[key];
    }

    /**
     * @notice 批量查询参数值
     * @param keys 参数键数组
     * @return values 参数值数组
     */
    function getParams(bytes32[] calldata keys) external view returns (uint256[] memory values) {
        values = new uint256[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            if (!isParamRegistered[keys[i]]) {
                revert ParamNotRegistered(keys[i]);
            }
            values[i] = params[keys[i]];
        }
    }

    /**
     * @notice 尝试查询参数值（不存在则返回默认值）
     * @param key 参数键
     * @param defaultValue 默认值
     * @return value 参数值或默认值
     */
    function tryGetParam(bytes32 key, uint256 defaultValue) external view returns (uint256) {
        if (!isParamRegistered[key]) {
            return defaultValue;
        }
        return params[key];
    }

    /*//////////////////////////////////////////////////////////////
                          PROPOSAL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 创建参数变更提案
     * @param key 参数键
     * @param newValue 新值
     * @param reason 变更理由
     * @return proposalId 提案 ID
     */
    function proposeChange(
        bytes32 key,
        uint256 newValue,
        string calldata reason
    ) external onlyRole(PROPOSER_ROLE) whenNotPaused returns (bytes32) {
        if (!isParamRegistered[key]) {
            revert ParamNotRegistered(key);
        }

        uint256 oldValue = params[key];

        // 如果新值与旧值相同，直接返回
        require(oldValue != newValue, "New value same as old");

        // 验证新值
        address validator = validators[key];
        if (validator != address(0)) {
            _validateParam(key, newValue, validator);
        }

        // 生成提案 ID
        bytes32 proposalId = keccak256(
            abi.encodePacked(key, oldValue, newValue, block.timestamp, proposalCount++)
        );

        uint256 eta = block.timestamp + timelockDelay;

        proposals[proposalId] = Proposal({
            key: key,
            oldValue: oldValue,
            newValue: newValue,
            eta: eta,
            executed: false,
            cancelled: false,
            proposer: msg.sender,
            reason: reason
        });

        emit ProposalCreated(proposalId, key, oldValue, newValue, eta, msg.sender, reason);

        return proposalId;
    }

    /**
     * @notice 执行提案
     * @param proposalId 提案 ID
     */
    function executeProposal(bytes32 proposalId) external onlyRole(EXECUTOR_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.eta == 0) {
            revert ProposalNotFound(proposalId);
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted(proposalId);
        }
        if (proposal.cancelled) {
            revert ProposalAlreadyCancelled(proposalId);
        }
        if (block.timestamp < proposal.eta) {
            revert TimelockNotExpired(proposalId, proposal.eta, block.timestamp);
        }

        // 标记为已执行
        proposal.executed = true;

        // 更新参数值
        uint256 oldValue = params[proposal.key];
        params[proposal.key] = proposal.newValue;

        emit ProposalExecuted(proposalId, proposal.key, oldValue, proposal.newValue);
        emit ParamChanged(proposal.key, oldValue, proposal.newValue, block.timestamp);
    }

    /**
     * @notice 取消提案
     * @param proposalId 提案 ID
     */
    function cancelProposal(bytes32 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.eta == 0) {
            revert ProposalNotFound(proposalId);
        }
        if (proposal.executed) {
            revert ProposalAlreadyExecuted(proposalId);
        }
        if (proposal.cancelled) {
            revert ProposalAlreadyCancelled(proposalId);
        }

        // 只有提案者或管理员可以取消
        require(
            msg.sender == proposal.proposer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not authorized to cancel"
        );

        proposal.cancelled = true;

        emit ProposalCancelled(proposalId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                          EMERGENCY CONTROLS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 紧急暂停参数变更
     */
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /**
     * @notice 恢复参数变更
     */
    function unpause() external onlyRole(GUARDIAN_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 更新 Timelock 延迟
     * @param newDelay 新的延迟时间
     */
    function updateTimelockDelay(uint256 newDelay) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newDelay < MIN_TIMELOCK_DELAY || newDelay > MAX_TIMELOCK_DELAY) {
            revert InvalidTimelockDelay(newDelay);
        }

        uint256 oldDelay = timelockDelay;
        timelockDelay = newDelay;

        emit TimelockDelayUpdated(oldDelay, newDelay);
    }

    /**
     * @notice 更新参数验证器
     * @param key 参数键
     * @param newValidator 新验证器地址
     */
    function updateValidator(bytes32 key, address newValidator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!isParamRegistered[key]) {
            revert ParamNotRegistered(key);
        }

        address oldValidator = validators[key];
        validators[key] = newValidator;

        emit ValidatorUpdated(key, oldValidator, newValidator);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice 验证参数值
     * @param key 参数键
     * @param value 参数值
     * @param validator 验证器地址
     */
    function _validateParam(bytes32 key, uint256 value, address validator) internal view {
        (bool success, bytes memory result) = validator.staticcall(
            abi.encodeWithSignature("validate(bytes32,uint256)", key, value)
        );

        if (!success || !abi.decode(result, (bool))) {
            revert ValidationFailed(key, value);
        }
    }
}
