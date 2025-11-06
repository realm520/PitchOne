#!/bin/bash
# PitchOne 快速启动脚本

set -e

echo "=========================================="
echo "  PitchOne 快速部署脚本"
echo "=========================================="
echo ""

# 检查环境变量
if [ -z "$PRIVATE_KEY" ]; then
    echo "⚠️  警告: PRIVATE_KEY 未设置，使用 Anvil 默认私钥"
    export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
fi

RPC_URL=${RPC_URL:-http://localhost:8545}

echo "配置信息:"
echo "  RPC URL: $RPC_URL"
echo "  账户: $(cast wallet address $PRIVATE_KEY 2>/dev/null || echo "无法解析")"
echo ""

# 第一步：部署系统
echo "=========================================="
echo "  步骤 1/3: 部署系统合约"
echo "=========================================="
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $RPC_URL \
    --broadcast \
    --slow

if [ $? -ne 0 ]; then
    echo "❌ 部署失败"
    exit 1
fi

echo "✅ 系统部署完成"
echo ""

# 第二步：创建市场
echo "=========================================="
echo "  步骤 2/3: 创建测试市场"
echo "=========================================="
forge script script/CreateMarkets.s.sol:CreateMarkets \
    --rpc-url $RPC_URL \
    --broadcast \
    --slow

if [ $? -ne 0 ]; then
    echo "❌ 市场创建失败"
    exit 1
fi

echo "✅ 市场创建完成"
echo ""

# 第三步：模拟下注
echo "=========================================="
echo "  步骤 3/3: 模拟用户下注"
echo "=========================================="
forge script script/SimulateBets.s.sol:SimulateBets \
    --rpc-url $RPC_URL \
    --broadcast \
    --slow

if [ $? -ne 0 ]; then
    echo "❌ 模拟下注失败"
    exit 1
fi

echo "✅ 模拟下注完成"
echo ""

# 完成
echo "=========================================="
echo "  🎉 部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "  1. 更新 subgraph/subgraph.yaml 中的合约地址"
echo "  2. 部署 Subgraph: cd ../subgraph && ./deploy-local.sh"
echo "  3. 启动前端: cd ../frontend && pnpm dev"
echo ""
