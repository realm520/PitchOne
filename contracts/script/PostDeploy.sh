#!/bin/bash
# PostDeploy.sh - 部署后自动化处理脚本
# 功能：
#   1. 验证部署文件
#   2. 更新 Subgraph 配置
#   3. 清理并重新部署 Subgraph
#   4. 更新前端配置（可选）

set -e  # 遇到错误立即退出

NETWORK=${1:-localhost}
DEPLOYMENT_FILE="deployments/${NETWORK}.json"

echo ""
echo "========================================"
echo "  PitchOne Post-Deployment Automation"
echo "========================================"
echo "Network: $NETWORK"
echo ""

# 1. 检查部署文件是否存在
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo "❌ Deployment file not found: $DEPLOYMENT_FILE"
    echo "   Please run Deploy.s.sol first to generate deployment data"
    exit 1
fi

echo "✅ Found deployment file: $DEPLOYMENT_FILE"
echo ""

# 读取部署信息
FACTORY=$(cat $DEPLOYMENT_FILE | jq -r '.contracts.factory')
BLOCK=$(cat $DEPLOYMENT_FILE | jq -r '.deployedAt')

echo "📋 Deployment Info:"
echo "  Factory: $FACTORY"
echo "  Start Block: $BLOCK"
echo ""

# 2. 更新 Subgraph 配置
echo "🔧 Step 1: Updating Subgraph configuration..."
cd ../subgraph
node config/update-config.js ../$DEPLOYMENT_FILE

if [ $? -ne 0 ]; then
    echo "❌ Failed to update Subgraph config"
    exit 1
fi
echo ""

# 3. 清理并重新部署 Subgraph
echo "🗑️  Step 2: Cleaning old Subgraph data..."
graph remove --node http://localhost:8020/ pitchone-sportsbook 2>/dev/null || echo "   (No existing subgraph to remove)"
graph create --node http://localhost:8020/ pitchone-sportsbook

if [ $? -ne 0 ]; then
    echo "❌ Failed to create Subgraph"
    exit 1
fi
echo ""

echo "🔨 Step 3: Building Subgraph..."
graph codegen
graph build

if [ $? -ne 0 ]; then
    echo "❌ Failed to build Subgraph"
    exit 1
fi
echo ""

echo "📤 Step 4: Deploying Subgraph..."
VERSION_LABEL="v$(date +%Y%m%d-%H%M%S)"
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook \
  --version-label "$VERSION_LABEL"

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy Subgraph"
    exit 1
fi
echo ""

# 4. 等待 Subgraph 同步
echo "⏳ Step 5: Waiting for Subgraph to sync..."
sleep 3

# 验证 Subgraph
SUBGRAPH_BLOCK=$(curl -s -X POST http://localhost:8010/subgraphs/name/pitchone-sportsbook \
  -H "Content-Type: application/json" \
  -d '{"query":"{ _meta { block { number } } }"}' | jq -r '.data._meta.block.number')

echo "  Subgraph synced to block: $SUBGRAPH_BLOCK"
echo ""

echo "========================================"
echo "  ✅ Post-Deployment Complete!"
echo "========================================"
echo "Summary:"
echo "  - Subgraph version: $VERSION_LABEL"
echo "  - Monitoring Factory: $FACTORY"
echo "  - Start block: $BLOCK"
echo "  - Current sync: Block $SUBGRAPH_BLOCK"
echo ""
echo "Next steps:"
echo "  1. Verify frontend connects to new contracts"
echo "  2. Run CreateMarkets.s.sol to create test markets"
echo "  3. Check Subgraph indexes new markets correctly"
echo "========================================"
echo ""
