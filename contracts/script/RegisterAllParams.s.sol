// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/governance/ParamController.sol";
import "../src/governance/ParamKeys.sol";

/**
 * @title RegisterAllParams
 * @notice 注册 ParamController 中所有缺失的参数
 * @dev 使用方法：
 *      PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
 *      forge script script/RegisterAllParams.s.sol:RegisterAllParams \
 *      --rpc-url http://localhost:8545 \
 *      --broadcast
 */
contract RegisterAllParams is Script {
    // ParamController 地址（从前端 addresses/index.ts 获取）
    // 注意：每次重新部署后需要更新此地址
    address constant PARAM_CONTROLLER = 0xd9abC93F81394Bd161a1b24B03518e0a570bDEAd;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ParamController paramController = ParamController(PARAM_CONTROLLER);

        console.log("=== Registering All Parameters ===");
        console.log("ParamController:", PARAM_CONTROLLER);

        // 获取所有参数键和默认值
        bytes32[] memory keys = ParamKeys.getAllKeys();
        uint256[] memory values = ParamKeys.getDefaultValues();

        uint256 registered = 0;
        uint256 skipped = 0;

        for (uint256 i = 0; i < keys.length; i++) {
            // 检查是否已注册
            if (paramController.isParamRegistered(keys[i])) {
                console.log("  [SKIP] Already registered:", i);
                skipped++;
                continue;
            }

            // 注册参数（无验证器）
            paramController.registerParam(keys[i], values[i], address(0));
            console.log("  [OK] Registered param index:", i, "value:", values[i]);
            registered++;
        }

        vm.stopBroadcast();

        console.log("");
        console.log("=== Summary ===");
        console.log("Total params:", keys.length);
        console.log("Registered:", registered);
        console.log("Skipped (already registered):", skipped);
    }
}
