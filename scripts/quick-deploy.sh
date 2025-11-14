#!/bin/bash
# PitchOne 本地环境一键部署脚本
# 用法: ./scripts/quick-deploy.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACTS_DIR="$PROJECT_ROOT/contracts"
SUBGRAPH_DIR="$PROJECT_ROOT/subgraph"

# 默认配置
PRIVATE_KEY="${PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"
RPC_URL="${RPC_URL:-http://localhost:8545}"
NUM_BETTORS="${NUM_BETTORS:-5}"
MIN_BET_AMOUNT="${MIN_BET_AMOUNT:-10}"
MAX_BET_AMOUNT="${MAX_BET_AMOUNT:-100}"
BETS_PER_USER="${BETS_PER_USER:-2}"
OUTCOME_DISTRIBUTION="${OUTCOME_DISTRIBUTION:-balanced}"

echo ""
echo "========================================="
echo "  PitchOne 本地环境一键部署"
echo "========================================="
echo ""
echo "配置信息："
echo "  - RPC URL: $RPC_URL"
echo "  - 市场数量: 15 (5种类型 × 3)"
echo "  - 投注用户: $NUM_BETTORS"
echo "  - 每用户投注: $BETS_PER_USER 次/市场"
echo "  - 投注金额: $MIN_BET_AMOUNT-$MAX_BET_AMOUNT USDC"
echo ""

# 检查 Anvil 是否运行
if ! cast block-number --rpc-url "$RPC_URL" > /dev/null 2>&1; then
    echo -e "${RED}❌ 错误: Anvil 未运行！${NC}"
    echo ""
    echo "请先启动 Anvil："
    echo "  cd $CONTRACTS_DIR"
    echo "  anvil --host 0.0.0.0"
    echo ""
    exit 1
fi

# 步骤 1: 部署合约
echo -e "${YELLOW}[1/4] 部署核心合约...${NC}"
cd "$CONTRACTS_DIR"
PRIVATE_KEY="$PRIVATE_KEY" forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --silent 2>&1 | grep -E "(Deployed|Script ran successfully)" || true

# 验证部署
if [ ! -f "$CONTRACTS_DIR/deployments/localhost.json" ]; then
    echo -e "${RED}❌ 部署失败: deployments/localhost.json 未生成${NC}"
    exit 1
fi

FACTORY_ADDRESS=$(jq -r '.contracts.factory' "$CONTRACTS_DIR/deployments/localhost.json")
echo -e "${GREEN}✅ 合约部署成功${NC}"
echo "   Factory: $FACTORY_ADDRESS"

# 步骤 2: 创建测试市场
echo ""
echo -e "${YELLOW}[2/4] 创建测试市场...${NC}"
PRIVATE_KEY="$PRIVATE_KEY" forge script script/CreateMarkets_NoMultiLine.s.sol:CreateMarkets_NoMultiLine \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --silent 2>&1 | grep -E "(Created|markets authorized|Success)" || true

# 验证市场数量
MARKET_COUNT=$(cast --to-dec $(cast call "$FACTORY_ADDRESS" "getMarketCount()" --rpc-url "$RPC_URL" 2>/dev/null))
if [ "$MARKET_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ 市场创建失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 市场创建成功: $MARKET_COUNT 个${NC}"

# 步骤 3: 模拟投注
echo ""
echo -e "${YELLOW}[3/4] 模拟投注数据...${NC}"
NUM_BETTORS="$NUM_BETTORS" \
MIN_BET_AMOUNT="$MIN_BET_AMOUNT" \
MAX_BET_AMOUNT="$MAX_BET_AMOUNT" \
BETS_PER_USER="$BETS_PER_USER" \
OUTCOME_DISTRIBUTION="$OUTCOME_DISTRIBUTION" \
forge script script/SimulateBets.s.sol:SimulateBets \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --silent 2>&1 | grep -E "(Bet Simulation|Total Bets|Total Volume|Success Rate)" || true

echo -e "${GREEN}✅ 投注模拟完成${NC}"

# 步骤 4: 自动更新 Subgraph 配置
echo ""
echo -e "${YELLOW}[4/5] 更新 Subgraph 配置...${NC}"
cd "$SUBGRAPH_DIR"

if [ -f "$SUBGRAPH_DIR/update-subgraph-config.sh" ]; then
    bash "$SUBGRAPH_DIR/update-subgraph-config.sh"
else
    echo -e "${YELLOW}⚠️  警告: update-subgraph-config.sh 不存在，跳过自动配置${NC}"
fi

# 步骤 5: 部署 Subgraph
echo ""
echo -e "${YELLOW}[5/5] 部署 Subgraph...${NC}"
cd "$SUBGRAPH_DIR"

# 检查 Docker 是否运行
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ 错误: Docker 未运行！${NC}"
    echo "请先启动 Docker 服务"
    exit 1
fi

# 使用 reset-subgraph.sh 部署
if [ -f "$SUBGRAPH_DIR/reset-subgraph.sh" ]; then
    bash "$SUBGRAPH_DIR/reset-subgraph.sh" > /tmp/subgraph-deploy.log 2>&1 &
    DEPLOY_PID=$!

    # 等待部署完成（最多 60 秒）
    for i in {1..60}; do
        if ! kill -0 $DEPLOY_PID 2>/dev/null; then
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""

    # 等待 Graph Node 索引
    echo -e "${YELLOW}等待 Subgraph 同步...${NC}"
    sleep 5

    # 验证 Subgraph 是否可访问
    if curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"query": "{ _meta { block { number } } }"}' \
        http://localhost:8010/subgraphs/name/pitchone-local > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Subgraph 部署成功${NC}"
    else
        echo -e "${YELLOW}⚠️  Subgraph 部署可能需要更多时间，请稍后检查${NC}"
    fi
else
    echo -e "${RED}❌ 未找到 reset-subgraph.sh 脚本${NC}"
    exit 1
fi

# 最终验证
echo ""
echo "========================================="
echo -e "${GREEN}  ✅ 部署完成！${NC}"
echo "========================================="
echo ""
echo "📊 数据统计："

# 查询全局统计
STATS=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    --data '{"query": "{ globalStats(id: \"global\") { totalMarkets totalUsers totalVolume totalFees } }"}' \
    http://localhost:8010/subgraphs/name/pitchone-local 2>/dev/null)

if [ $? -eq 0 ] && echo "$STATS" | jq -e '.data.globalStats' > /dev/null 2>&1; then
    TOTAL_MARKETS=$(echo "$STATS" | jq -r '.data.globalStats.totalMarkets')
    TOTAL_USERS=$(echo "$STATS" | jq -r '.data.globalStats.totalUsers')
    TOTAL_VOLUME=$(echo "$STATS" | jq -r '.data.globalStats.totalVolume')
    TOTAL_FEES=$(echo "$STATS" | jq -r '.data.globalStats.totalFees')

    echo "  - 总市场数: $TOTAL_MARKETS"
    echo "  - 总用户数: $TOTAL_USERS"
    echo "  - 总交易量: $TOTAL_VOLUME USDC"
    echo "  - 总手续费: $TOTAL_FEES USDC"
else
    echo -e "${YELLOW}  (Subgraph 尚未完全同步，请稍后查询)${NC}"
fi

echo ""
echo "🔗 访问链接："
echo "  - GraphQL Playground:"
echo "    http://localhost:8010/subgraphs/name/pitchone-local/graphql"
echo ""
echo "  - Graph Node Admin:"
echo "    http://localhost:8020"
echo ""
echo "📝 验证命令："
echo "  curl -X POST -H 'Content-Type: application/json' \\"
echo "    --data '{\"query\": \"{ markets(first: 5) { id homeTeam awayTeam totalVolume } }\"}' \\"
echo "    http://localhost:8010/subgraphs/name/pitchone-local | jq ."
echo ""
echo "📚 完整 SOP 文档："
echo "  $SUBGRAPH_DIR/SOP_LOCAL_DEPLOYMENT.md"
echo ""
