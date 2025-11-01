#!/bin/bash

# ============================================================================
# PitchOne Subgraph 本地部署脚本
# 用途: 启动 Graph Node 并部署 Subgraph 到本地环境
# ============================================================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# ============================================================================
# Step 1: 检查依赖
# ============================================================================

info "检查依赖..."

# 检查 Docker
if ! command -v docker &> /dev/null; then
    error "Docker 未安装,请先安装 Docker"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker compose &> /dev/null; then
    error "Docker Compose 未安装,请先安装 Docker Compose"
    exit 1
fi

# 检查 graph-cli
if ! command -v graph &> /dev/null; then
    error "Graph CLI 未安装,请运行: npm install -g @graphprotocol/graph-cli"
    exit 1
fi

success "所有依赖已就绪"

# ============================================================================
# Step 2: 启动 Graph Node 基础设施
# ============================================================================

info "启动 Graph Node 基础设施 (PostgreSQL + IPFS + Graph Node)..."

# 进入 subgraph 目录
cd "$(dirname "$0")"

# 停止旧容器并清理(可选)
if [ "$1" == "--clean" ]; then
    warn "清理模式: 删除旧容器和数据卷..."
    docker compose down -v
fi

# 启动服务
docker compose up -d

success "Graph Node 基础设施已启动"

# ============================================================================
# Step 3: 等待服务就绪
# ============================================================================

info "等待服务启动..."

# 等待 PostgreSQL
info "等待 PostgreSQL 就绪..."
for i in {1..30}; do
    if docker exec graph-postgres pg_isready -U graph-node &> /dev/null; then
        success "PostgreSQL 已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        error "PostgreSQL 启动超时"
        exit 1
    fi
    sleep 1
done

# 等待 IPFS
info "等待 IPFS 就绪..."
for i in {1..30}; do
    if curl -s http://localhost:5001/api/v0/version > /dev/null 2>&1; then
        success "IPFS 已就绪"
        break
    fi
    if [ $i -eq 30 ]; then
        error "IPFS 启动超时"
        exit 1
    fi
    sleep 1
done

# 等待 Graph Node
info "等待 Graph Node 就绪..."
for i in {1..60}; do
    if curl -s http://localhost:8020 > /dev/null 2>&1; then
        success "Graph Node 已就绪"
        break
    fi
    if [ $i -eq 60 ]; then
        error "Graph Node 启动超时,请检查日志: docker logs graph-node"
        exit 1
    fi
    sleep 2
done

# ============================================================================
# Step 4: 检查 Anvil 是否运行
# ============================================================================

info "检查本地 Anvil 节点..."

if ! curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    http://localhost:8545 > /dev/null 2>&1; then
    warn "本地 Anvil 节点未运行"
    warn "请在另一个终端运行: cd ../contracts && make chain"
    warn "或者: anvil"
    read -p "按回车键继续部署 Subgraph (假设稍后启动 Anvil)..."
else
    success "本地 Anvil 节点运行正常"
fi

# ============================================================================
# Step 5: 更新 subgraph.yaml 中的合约地址
# ============================================================================

info "检查 subgraph.yaml 配置..."

if grep -q "0x0000000000000000000000000000000000000000" subgraph.yaml; then
    warn "subgraph.yaml 中的合约地址为 0x0,需要更新为实际部署的合约地址"
    warn "请先部署合约,然后手动更新 subgraph.yaml 中的地址字段"
    warn "或者运行部署脚本: cd ../contracts && forge script script/DeployNewMarket.s.sol"

    read -p "是否继续部署(用于测试配置)? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "退出部署流程"
        exit 0
    fi
fi

# ============================================================================
# Step 6: 生成代码
# ============================================================================

info "运行 graph codegen..."
npm run codegen

success "代码生成完成"

# ============================================================================
# Step 7: 构建 Subgraph
# ============================================================================

info "构建 Subgraph..."
npm run build

success "Subgraph 构建完成"

# ============================================================================
# Step 8: 创建 Subgraph (如果不存在)
# ============================================================================

info "创建 Subgraph..."

# 尝试创建,如果已存在会失败(忽略错误)
npm run create-local 2>/dev/null || warn "Subgraph 已存在,跳过创建步骤"

# ============================================================================
# Step 9: 部署 Subgraph
# ============================================================================

info "部署 Subgraph 到本地 Graph Node..."

npm run deploy-local

success "Subgraph 部署成功!"

# ============================================================================
# Step 10: 验证部署
# ============================================================================

info "验证 Subgraph 部署状态..."

sleep 3

# 查询 GraphQL 端点
GRAPHQL_URL="http://localhost:8000/subgraphs/name/pitchone-local"

info "GraphQL 查询端点: $GRAPHQL_URL"

# 测试查询
info "测试 GraphQL 查询..."

QUERY='{"query": "{ _meta { block { number } } }"}'

if curl -s -X POST \
    -H "Content-Type: application/json" \
    --data "$QUERY" \
    "$GRAPHQL_URL" | jq . > /dev/null 2>&1; then
    success "GraphQL 查询成功!"
else
    warn "GraphQL 查询失败,但 Subgraph 可能仍在同步中"
fi

# ============================================================================
# 完成
# ============================================================================

echo ""
success "=========================================="
success "  本地 Graph Node 部署完成!"
success "=========================================="
echo ""
info "服务访问地址:"
echo "  - GraphQL API:      http://localhost:8000/subgraphs/name/pitchone-local"
echo "  - GraphQL Playground: http://localhost:8000/subgraphs/name/pitchone-local/graphql"
echo "  - Indexing Status:  http://localhost:8030/graphql"
echo "  - IPFS:             http://localhost:5001"
echo "  - Metrics:          http://localhost:8040/metrics"
echo ""
info "常用命令:"
echo "  - 查看 Graph Node 日志:  docker logs -f graph-node"
echo "  - 查看所有容器状态:      docker compose ps"
echo "  - 停止所有服务:          docker compose down"
echo "  - 重新部署 Subgraph:     npm run deploy-local"
echo ""
info "示例 GraphQL 查询:"
echo ""
echo 'curl -X POST -H "Content-Type: application/json" \'
echo '  --data '"'"'{"query": "{ globalStats { totalMarkets totalUsers totalVolume } }"}'"'"' \'
echo "  http://localhost:8000/subgraphs/name/pitchone-local"
echo ""
