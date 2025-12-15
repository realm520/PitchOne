// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {ParamController} from "../src/governance/ParamController.sol";

/**
 * @title TestParamController
 * @notice 部署、初始化并测试 ParamController 合约的完整流程
 *
 * 功能：
 * 1. 部署 ParamController 合约
 * 2. 注册 13 个核心参数
 * 3. 授予测试账户权限（PROPOSER_ROLE, EXECUTOR_ROLE）
 * 4. 创建测试提案
 * 5. 执行提案（需要等待 Timelock）
 *
 * 使用方法：
 * forge script script/TestParamController.s.sol:TestParamController \
 *   --rpc-url $RPC_URL \
 *   --private-key $PRIVATE_KEY \
 *   --broadcast -vvvv
 */
contract TestParamController is Script {
    ParamController public paramController;

    // Timelock 延迟（测试环境使用较短时间）
    uint256 public constant TIMELOCK_DELAY = 1 hours;  // 生产环境建议 2 days

    // 参数键（使用 keccak256 计算）
    bytes32 public constant FEE_RATE = keccak256("FEE_RATE");
    bytes32 public constant LP_SHARE = keccak256("LP_SHARE");
    bytes32 public constant PROMO_SHARE = keccak256("PROMO_SHARE");
    bytes32 public constant INSURANCE_SHARE = keccak256("INSURANCE_SHARE");
    bytes32 public constant TREASURY_SHARE = keccak256("TREASURY_SHARE");
    bytes32 public constant MIN_BET = keccak256("MIN_BET");
    bytes32 public constant MAX_BET = keccak256("MAX_BET");
    bytes32 public constant MAX_USER_EXPOSURE = keccak256("MAX_USER_EXPOSURE");
    bytes32 public constant OU_LINK_COEFF_2_0_TO_2_5 = keccak256("OU_LINK_COEFF_2_0_TO_2_5");
    bytes32 public constant SPREAD_GUARD_BPS = keccak256("SPREAD_GUARD_BPS");
    bytes32 public constant REFERRAL_RATE_TIER1 = keccak256("REFERRAL_RATE_TIER1");
    bytes32 public constant REFERRAL_RATE_TIER2 = keccak256("REFERRAL_RATE_TIER2");
    bytes32 public constant MAX_REFERRAL_DEPTH = keccak256("MAX_REFERRAL_DEPTH");

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("========================================");
        console2.log("ParamController Deploy and Test Script");
        console2.log("========================================");
        console2.log("Deployer:", deployer);
        console2.log("Timelock Delay:", TIMELOCK_DELAY);
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ParamController
        console2.log("1. Deploying ParamController...");
        paramController = new ParamController(
            deployer,  // admin (Safe multisig address, using deployer for testing)
            TIMELOCK_DELAY
        );
        console2.log("   ParamController deployed at:", address(paramController));
        console2.log("");

        // 2. Register all core parameters
        console2.log("2. Registering core parameters...");
        _registerAllParams();
        console2.log("   13 parameters registered");
        console2.log("");

        // 3. Grant permissions (test environment)
        console2.log("3. Granting test account permissions...");
        // In production, these roles should be granted to Safe multisig
        console2.log("   PROPOSER_ROLE granted to:", deployer);
        console2.log("   EXECUTOR_ROLE granted to:", deployer);
        console2.log("   GUARDIAN_ROLE granted to:", deployer);
        console2.log("");

        // 4. Verify parameter values
        console2.log("4. Verifying parameter values...");
        _verifyParams();
        console2.log("");

        // 5. Create test proposal
        console2.log("5. Creating test proposal...");
        bytes32 proposalId = _createTestProposal();
        console2.log("   Proposal ID:", vm.toString(proposalId));
        console2.log("");

        // 6. Query proposal info
        console2.log("6. Querying proposal info...");
        _printProposal(proposalId);

        vm.stopBroadcast();

        console2.log("");
        console2.log("========================================");
        console2.log("Deployment Complete!");
        console2.log("========================================");
        console2.log("");
        console2.log("Next Steps:");
        console2.log("");
        console2.log("1. Wait for Timelock delay (", TIMELOCK_DELAY / 3600, "hours)");
        console2.log("");
        console2.log("2. Execute proposal:");
        console2.log("   cast send", address(paramController));
        console2.log("   'executeProposal(bytes32)' ", vm.toString(proposalId));
        console2.log("   --rpc-url $RPC_URL --private-key $PRIVATE_KEY");
        console2.log("");
        console2.log("3. Verify parameter change:");
        console2.log("   cast call", address(paramController));
        console2.log("   'getParam(bytes32)' ", vm.toString(FEE_RATE));
        console2.log("   --rpc-url $RPC_URL");
        console2.log("");
        console2.log("========================================");
        console2.log("");
        console2.log("Contract Address (update frontend config):");
        console2.log("ParamController:", address(paramController));
        console2.log("");
    }

    /**
     * @notice Register all core parameters
     */
    function _registerAllParams() internal {
        // 费用参数
        paramController.registerParam(FEE_RATE, 200, address(0));  // 2%
        paramController.registerParam(LP_SHARE, 6000, address(0));  // 60%
        paramController.registerParam(PROMO_SHARE, 2000, address(0));  // 20%
        paramController.registerParam(INSURANCE_SHARE, 1000, address(0));  // 10%
        paramController.registerParam(TREASURY_SHARE, 1000, address(0));  // 10%

        // 限额参数
        paramController.registerParam(MIN_BET, 1_000_000, address(0));  // 1 USDC
        paramController.registerParam(MAX_BET, 10_000_000_000, address(0));  // 10,000 USDC
        paramController.registerParam(MAX_USER_EXPOSURE, 50_000_000_000, address(0));  // 50,000 USDC

        // 联动定价参数
        paramController.registerParam(OU_LINK_COEFF_2_0_TO_2_5, 8500, address(0));  // 0.85
        paramController.registerParam(SPREAD_GUARD_BPS, 500, address(0));  // 5%

        // 推荐返佣参数
        paramController.registerParam(REFERRAL_RATE_TIER1, 2000, address(0));  // 20%
        paramController.registerParam(REFERRAL_RATE_TIER2, 1000, address(0));  // 10%
        paramController.registerParam(MAX_REFERRAL_DEPTH, 2, address(0));  // 2 层

        console2.log("   [FEE] FEE_RATE:", paramController.getParam(FEE_RATE));
        console2.log("   [FEE] LP_SHARE:", paramController.getParam(LP_SHARE));
        console2.log("   [LIMIT] MIN_BET:", paramController.getParam(MIN_BET));
        console2.log("   [LIMIT] MAX_BET:", paramController.getParam(MAX_BET));
        console2.log("   [REFERRAL] REFERRAL_RATE_TIER1:", paramController.getParam(REFERRAL_RATE_TIER1));
    }

    /**
     * @notice Verify parameter values
     */
    function _verifyParams() internal view {
        require(paramController.getParam(FEE_RATE) == 200, "FEE_RATE verification failed");
        require(paramController.getParam(LP_SHARE) == 6000, "LP_SHARE verification failed");
        require(paramController.getParam(MIN_BET) == 1_000_000, "MIN_BET verification failed");
        require(paramController.getParam(MAX_BET) == 10_000_000_000, "MAX_BET verification failed");
        require(paramController.getParam(REFERRAL_RATE_TIER1) == 2000, "REFERRAL_RATE_TIER1 verification failed");

        console2.log("   All parameters verified");
    }

    /**
     * @notice Create test proposal (reduce fee rate)
     */
    function _createTestProposal() internal returns (bytes32) {
        uint256 newFeeRate = 150;  // Reduce from 2% to 1.5%
        string memory reason = "Test proposal: Reduce fee rate to attract more users";

        bytes32 proposalId = paramController.proposeChange(
            FEE_RATE,
            newFeeRate,
            reason
        );

        console2.log("   Parameter: FEE_RATE");
        console2.log("   Old Value:", paramController.getParam(FEE_RATE), "bp (2%)");
        console2.log("   New Value:", newFeeRate, "bp (1.5%)");
        console2.log("   Reason:", reason);

        return proposalId;
    }

    /**
     * @notice Print proposal information
     */
    function _printProposal(bytes32 proposalId) internal view {
        (
            bytes32 key,
            uint256 oldValue,
            uint256 newValue,
            uint256 eta,
            bool executed,
            bool cancelled,
            address proposer,
            string memory reason
        ) = paramController.proposals(proposalId);

        console2.log("   Key:", vm.toString(key));
        console2.log("   Old Value:", oldValue);
        console2.log("   New Value:", newValue);
        console2.log("   ETA:", eta);
        console2.log("   ETA (readable):", vm.toString(eta));
        console2.log("   Executed:", executed);
        console2.log("   Cancelled:", cancelled);
        console2.log("   Proposer:", proposer);
        console2.log("   Reason:", reason);
    }
}
