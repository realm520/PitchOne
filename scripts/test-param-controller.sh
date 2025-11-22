#!/bin/bash

#===============================================
# ParamController 参数管理测试脚本（使用已部署合约）
#===============================================
# 功能：
# 1. 从部署文件读取 ParamController 地址
# 2. 注册核心参数（如未注册）
# 3. 创建测试提案
# 4. 快进时间并执行提案
# 5. 验证参数变更
#===============================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
RPC_URL="http://127.0.0.1:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # Anvil 默认账户
CONTRACTS_DIR="$(cd "$(dirname "$0")/../contracts" && pwd)"
FRONTEND_DIR="$(cd "$(dirname "$0")/../frontend" && pwd)"
ADDRESSES_FILE="$FRONTEND_DIR/packages/contracts/src/addresses/index.ts"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}ParamController 参数管理测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

#===============================================
# 1. 读取 ParamController 地址
#===============================================
echo -e "${YELLOW}[1/5] 读取 ParamController 地址...${NC}"

if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}   ✗ 前端地址配置文件不存在: $ADDRESSES_FILE${NC}"
    echo "   请先运行 deploy-parimutuel-full.sh 部署合约"
    exit 1
fi

# 从前端配置文件提取 ParamController 地址
PARAM_CONTROLLER=$(grep "paramController:" "$ADDRESSES_FILE" | grep -oP "0x[a-fA-F0-9]{40}" | head -1)

if [ -z "$PARAM_CONTROLLER" ] || [ "$PARAM_CONTROLLER" == "0x0000000000000000000000000000000000000000" ]; then
    echo -e "${RED}   ✗ ParamController 未部署或地址无效${NC}"
    echo "   地址: ${PARAM_CONTROLLER:-未找到}"
    echo ""
    echo "   请先运行 deploy-parimutuel-full.sh 部署合约："
    echo "   ./scripts/deploy-parimutuel-full.sh"
    exit 1
fi

echo -e "${GREEN}   ✓ ParamController 地址: $PARAM_CONTROLLER${NC}"
echo ""

#===============================================
# 2. 检查参数是否已注册
#===============================================
echo -e "${YELLOW}[2/5] 检查参数注册状态...${NC}"

# 计算 FEE_RATE 的 bytes32 key
FEE_RATE_KEY="$(echo -n "FEE_RATE" | cast keccak)"

# 检查参数是否已注册
IS_REGISTERED=$(cast call $PARAM_CONTROLLER "isParamRegistered(bytes32)" $FEE_RATE_KEY --rpc-url $RPC_URL)

if [ "$IS_REGISTERED" == "0x0000000000000000000000000000000000000000000000000000000000000001" ]; then
    echo -e "${GREEN}   ✓ 参数已注册，跳过注册步骤${NC}"
    SKIP_REGISTER=true
else
    echo -e "${YELLOW}   参数未注册，将执行注册${NC}"
    SKIP_REGISTER=false
fi
echo ""

#===============================================
# 3. 注册核心参数（如需要）
#===============================================
if [ "$SKIP_REGISTER" = false ]; then
    echo -e "${YELLOW}[3/5] 注册核心参数...${NC}"
    cd "$CONTRACTS_DIR"

    # 创建临时注册脚本
    cat > /tmp/RegisterParams.s.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/governance/ParamController.sol";

contract RegisterParams is Script {
    function run() external {
        address paramControllerAddr = vm.envAddress("PARAM_CONTROLLER");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ParamController controller = ParamController(paramControllerAddr);

        // 注册 13 个核心参数
        controller.registerParam(keccak256("FEE_RATE"), 200, address(0));  // 2%
        controller.registerParam(keccak256("LP_SHARE"), 6000, address(0));  // 60%
        controller.registerParam(keccak256("PROMO_SHARE"), 2000, address(0));  // 20%
        controller.registerParam(keccak256("INSURANCE_SHARE"), 1000, address(0));  // 10%
        controller.registerParam(keccak256("TREASURY_SHARE"), 1000, address(0));  // 10%
        controller.registerParam(keccak256("MIN_BET"), 1_000_000, address(0));  // 1 USDC
        controller.registerParam(keccak256("MAX_BET"), 10_000_000_000, address(0));  // 10,000 USDC
        controller.registerParam(keccak256("MAX_USER_EXPOSURE"), 50_000_000_000, address(0));  // 50,000 USDC
        controller.registerParam(keccak256("OU_LINK_COEFF_2_0_TO_2_5"), 8500, address(0));  // 0.85
        controller.registerParam(keccak256("SPREAD_GUARD_BPS"), 500, address(0));  // 5%
        controller.registerParam(keccak256("REFERRAL_RATE_TIER1"), 2000, address(0));  // 20%
        controller.registerParam(keccak256("REFERRAL_RATE_TIER2"), 1000, address(0));  // 10%
        controller.registerParam(keccak256("MAX_REFERRAL_DEPTH"), 2, address(0));  // 2 层

        vm.stopBroadcast();
    }
}
EOF

    # 运行注册脚本
    if PARAM_CONTROLLER=$PARAM_CONTROLLER PRIVATE_KEY=$PRIVATE_KEY \
       forge script /tmp/RegisterParams.s.sol:RegisterParams \
       --rpc-url $RPC_URL \
       --broadcast \
       --silent 2>&1; then
        echo -e "${GREEN}   ✓ 参数注册成功${NC}"
    else
        echo -e "${RED}   ✗ 参数注册失败${NC}"
        exit 1
    fi

    # 清理临时文件
    rm /tmp/RegisterParams.s.sol

    echo ""
else
    echo -e "${YELLOW}[3/5] 跳过参数注册（已注册）${NC}"
    echo ""
fi

#===============================================
# 4. 创建测试提案
#===============================================
echo -e "${YELLOW}[4/5] 创建测试提案（FEE_RATE: 200 → 150）...${NC}"

# 查询当前 FEE_RATE 值
CURRENT_FEE_RATE=$(cast call $PARAM_CONTROLLER "getParam(bytes32)" $FEE_RATE_KEY --rpc-url $RPC_URL)
CURRENT_FEE_RATE_DEC=$((16#${CURRENT_FEE_RATE#0x}))

echo "   当前 FEE_RATE: $CURRENT_FEE_RATE_DEC bp"

# 创建提案
PROPOSAL_TX=$(cast send $PARAM_CONTROLLER \
    "proposeChange(bytes32,uint256,string)" \
    $FEE_RATE_KEY \
    150 \
    "Test proposal: Reduce fee rate to 1.5%" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --json)

if [ $? -ne 0 ]; then
    echo -e "${RED}   ✗ 创建提案失败${NC}"
    exit 1
fi

# 提取提案 ID（从事件日志）
PROPOSAL_ID=$(cast logs --from-block latest --to-block latest \
    --address $PARAM_CONTROLLER \
    "ProposalCreated(bytes32,bytes32,uint256,uint256,uint256,address,string)" \
    --rpc-url $RPC_URL | grep -oP 'topics: \[\K[^]]+' | head -2 | tail -1 | tr -d ' "')

if [ -z "$PROPOSAL_ID" ]; then
    echo -e "${RED}   ✗ 无法获取提案 ID${NC}"
    exit 1
fi

echo -e "${GREEN}   ✓ 提案已创建${NC}"
echo "   提案 ID: $PROPOSAL_ID"
echo ""

#===============================================
# 5. 执行提案测试流程
#===============================================
echo -e "${YELLOW}[5/5] 测试提案执行流程...${NC}"

# 获取 Timelock 延迟
TIMELOCK_DELAY=$(cast call $PARAM_CONTROLLER "timelockDelay()" --rpc-url $RPC_URL)
TIMELOCK_DELAY_DEC=$((16#${TIMELOCK_DELAY#0x}))

echo "   Timelock 延迟: $TIMELOCK_DELAY_DEC 秒 ($((TIMELOCK_DELAY_DEC / 3600)) 小时)"

# 快进时间
echo "   快进 $((TIMELOCK_DELAY_DEC + 60)) 秒..."
cast rpc evm_increaseTime $((TIMELOCK_DELAY_DEC + 60)) --rpc-url $RPC_URL &>/dev/null
cast rpc evm_mine --rpc-url $RPC_URL &>/dev/null

echo -e "${GREEN}   ✓ 时间已快进${NC}"

# 执行提案
echo "   执行提案..."
EXECUTE_TX=$(cast send $PARAM_CONTROLLER \
    "executeProposal(bytes32)" $PROPOSAL_ID \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --json | jq -r '.status')

if [ "$EXECUTE_TX" != "0x1" ]; then
    echo -e "${RED}   ✗ 提案执行失败${NC}"
    exit 1
fi

echo -e "${GREEN}   ✓ 提案已执行${NC}"

# 验证参数变更
NEW_FEE_RATE=$(cast call $PARAM_CONTROLLER "getParam(bytes32)" $FEE_RATE_KEY --rpc-url $RPC_URL)
NEW_FEE_RATE_DEC=$((16#${NEW_FEE_RATE#0x}))

echo "   FEE_RATE 新值: $NEW_FEE_RATE_DEC bp"

if [ "$NEW_FEE_RATE_DEC" -eq 150 ]; then
    echo -e "${GREEN}   ✓ 参数变更验证成功！${NC}"
else
    echo -e "${RED}   ✗ 参数变更验证失败（期望: 150, 实际: $NEW_FEE_RATE_DEC）${NC}"
    exit 1
fi

echo ""

#===============================================
# 测试完成
#===============================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ ParamController 测试完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "测试结果:"
echo "  • ParamController 地址: $PARAM_CONTROLLER"
echo "  • 测试提案 ID: $PROPOSAL_ID"
echo "  • FEE_RATE: $CURRENT_FEE_RATE_DEC bp → $NEW_FEE_RATE_DEC bp"
echo ""
echo "下一步:"
echo "  1. 启动前端: cd frontend && pnpm --filter @pitchone/admin dev"
echo "  2. 访问治理页面: http://localhost:3000/params"
echo "  3. 连接钱包并查看链上参数和提案"
echo ""
echo -e "${BLUE}========================================${NC}"
