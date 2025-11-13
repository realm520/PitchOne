#!/bin/bash

# PitchOne 完整测试流程
# 功能：部署合约 -> 创建市场 -> 模拟投注

set -e

echo "========================================"
echo "  PitchOne 完整测试流程"
echo "========================================"
echo ""

RPC_URL="http://localhost:8545"
PRIVATE_KEY="${PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

cd /home/harry/code/PitchOne/contracts

# 1. 部署所有合约
echo "步骤 1/3: 部署合约..."
echo "----------------------------------------"
PRIVATE_KEY=$PRIVATE_KEY forge script script/Deploy.s.sol:Deploy \
    --rpc-url $RPC_URL \
    --broadcast
echo ""

# 2. 创建所有类型的测试市场
echo "步骤 2/3: 创建测试市场（7 种类型，21 个市场）..."
echo "----------------------------------------"
PRIVATE_KEY=$PRIVATE_KEY forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
    --rpc-url $RPC_URL \
    --broadcast
echo ""

# 3. 模拟多用户投注
echo "步骤 3/3: 模拟多用户投注..."
echo "----------------------------------------"
NUM_BETTORS=5 \
MIN_BET_AMOUNT=10 \
MAX_BET_AMOUNT=100 \
BETS_PER_USER=2 \
OUTCOME_DISTRIBUTION=balanced \
forge script script/SimulateBets.s.sol:SimulateBets \
    --rpc-url $RPC_URL \
    --broadcast
echo ""

echo "========================================"
echo "  测试流程完成！"
echo "========================================"
echo ""
echo "📊 验证结果："
echo "  查询市场数量："
echo "    cast call 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 'getMarketCount()' --rpc-url $RPC_URL"
echo ""
echo "  查询 Vault 总资产："
echo "    cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 'totalAssets()' --rpc-url $RPC_URL"
echo ""
echo "💡 下一步："
echo "  如需重新索引 Subgraph，请运行："
echo "    cd ../subgraph && ./reset-subgraph.sh"
echo ""
