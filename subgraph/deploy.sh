#!/bin/bash

# ============================================================================
# PitchOne Subgraph 部署脚本（统一版）
#
# 用法:
#   ./deploy.sh [选项]
#
# 选项:
#   --clean, -c       清理所有数据并重新开始（删除 Docker volumes）
#   --update, -u      从合约部署文件自动更新 subgraph.yaml 中的地址
#   --skip-checks     跳过依赖和健康检查
#   --yes, -y         跳过所有确认提示
#   --network <name>  指定网络（默认: localhost_v3）
#   --help, -h        显示帮助信息
#
# 示例:
#   ./deploy.sh                    # 标准部署（保留数据）
#   ./deploy.sh -c                 # 清理数据后部署
#   ./deploy.sh -c -u              # 清理 + 自动更新配置
#   ./deploy.sh -c -u -y           # 完全自动化（无交互）
# ============================================================================

set -e

# ============================================================================
# 颜色和输出函数
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✗${NC} $1"; }
header()  { echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"; }

# ============================================================================
# 默认配置
# ============================================================================
CLEAN=false
UPDATE_CONFIG=false
SKIP_CHECKS=false
AUTO_YES=false
NETWORK="localhost_v3"
SUBGRAPH_NAME="pitchone-sportsbook"
GRAPH_NODE_PORT=8010

# ============================================================================
# 解析命令行参数
# ============================================================================
show_help() {
    cat << EOF
PitchOne Subgraph 部署脚本

用法: ./deploy.sh [选项]

选项:
  --clean, -c       清理所有数据并重新开始（删除 Docker volumes）
  --update, -u      从合约部署文件自动更新 subgraph.yaml 中的地址
  --skip-checks     跳过依赖和健康检查
  --yes, -y         跳过所有确认提示
  --network <name>  指定网络（默认: localhost_v3）
  --help, -h        显示帮助信息

常用组合:
  ./deploy.sh                 标准部署（保留现有数据）
  ./deploy.sh -c              清理后重新部署
  ./deploy.sh -u              更新配置后部署
  ./deploy.sh -c -u -y        完全重置（自动化，无交互）

EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean|-c)
            CLEAN=true
            shift
            ;;
        --update|-u)
            UPDATE_CONFIG=true
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            ;;
        *)
            error "未知选项: $1"
            echo "使用 --help 查看帮助"
            exit 1
            ;;
    esac
done

# ============================================================================
# 进入脚本目录
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================================================
# 显示配置摘要
# ============================================================================
header "部署配置"
echo "  Subgraph 名称:  $SUBGRAPH_NAME"
echo "  网络:           $NETWORK"
echo "  清理数据:       $([ "$CLEAN" = true ] && echo "是" || echo "否")"
echo "  更新配置:       $([ "$UPDATE_CONFIG" = true ] && echo "是" || echo "否")"
echo "  跳过检查:       $([ "$SKIP_CHECKS" = true ] && echo "是" || echo "否")"
echo ""

# 确认操作
if [ "$AUTO_YES" = false ] && [ "$CLEAN" = true ]; then
    warn "将删除所有 Subgraph 数据！"
    read -p "确认继续? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "已取消"
        exit 0
    fi
fi

# ============================================================================
# Step 1: 检查依赖
# ============================================================================
if [ "$SKIP_CHECKS" = false ]; then
    header "检查依赖"

    # Docker
    if ! command -v docker &> /dev/null; then
        error "Docker 未安装"
        exit 1
    fi
    success "Docker 已安装"

    # Docker Compose
    if ! command -v docker compose &> /dev/null; then
        error "Docker Compose 未安装"
        exit 1
    fi
    success "Docker Compose 已安装"

    # Graph CLI
    if ! command -v graph &> /dev/null; then
        error "Graph CLI 未安装，请运行: npm install -g @graphprotocol/graph-cli"
        exit 1
    fi
    success "Graph CLI 已安装"
fi

# ============================================================================
# Step 2: 更新配置（如果启用）
# ============================================================================
if [ "$UPDATE_CONFIG" = true ]; then
    header "更新 Subgraph 配置"

    DEPLOYMENT_FILE="../contracts/deployments/${NETWORK}.json"

    if [ -f "$DEPLOYMENT_FILE" ]; then
        info "使用部署文件: $DEPLOYMENT_FILE"
        node config/update-config.js "$DEPLOYMENT_FILE"
        success "配置更新完成"
    else
        warn "部署文件不存在: $DEPLOYMENT_FILE"
        warn "跳过配置更新，使用现有 subgraph.yaml"
    fi
fi

# ============================================================================
# Step 3: 管理 Docker 容器
# ============================================================================
header "管理 Graph Node"

if [ "$CLEAN" = true ]; then
    info "停止并清理容器和数据..."
    docker compose down -v 2>/dev/null || true
    success "清理完成"
fi

# 检查容器状态
if docker compose ps --quiet 2>/dev/null | grep -q .; then
    info "Graph Node 容器已在运行"
else
    info "启动 Graph Node..."
    docker compose up -d
fi

# ============================================================================
# Step 4: 等待服务就绪
# ============================================================================
if [ "$SKIP_CHECKS" = false ]; then
    header "等待服务就绪"

    # PostgreSQL
    info "等待 PostgreSQL..."
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

    # IPFS
    info "等待 IPFS..."
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

    # Graph Node
    info "等待 Graph Node..."
    for i in {1..60}; do
        if curl -s http://localhost:8020 > /dev/null 2>&1; then
            success "Graph Node 已就绪"
            break
        fi
        if [ $i -eq 60 ]; then
            error "Graph Node 启动超时"
            echo "查看日志: docker logs graph-node"
            exit 1
        fi
        sleep 2
    done

    # Anvil（可选）
    info "检查本地链..."
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 > /dev/null 2>&1; then
        success "本地链运行正常"
    else
        warn "本地链未运行（cd contracts && anvil）"
    fi
else
    info "跳过健康检查，等待 15 秒..."
    sleep 15
fi

# ============================================================================
# Step 5: 生成和构建
# ============================================================================
header "生成 Subgraph 代码"

graph codegen
success "codegen 完成"

graph build
success "build 完成"

# ============================================================================
# Step 6: 创建和部署
# ============================================================================
header "部署 Subgraph"

# 创建（如果不存在）
graph create --node http://localhost:8020/ $SUBGRAPH_NAME 2>/dev/null || \
    info "Subgraph 已存在，跳过创建"

# 部署
VERSION_LABEL="v$(date +%Y%m%d-%H%M%S)"
info "版本标签: $VERSION_LABEL"

graph deploy \
    --node http://localhost:8020/ \
    --ipfs http://localhost:5001 \
    --version-label "$VERSION_LABEL" \
    $SUBGRAPH_NAME

success "部署完成"

# ============================================================================
# Step 7: 验证
# ============================================================================
header "验证部署"

sleep 3

GRAPHQL_URL="http://localhost:${GRAPH_NODE_PORT}/subgraphs/name/${SUBGRAPH_NAME}"

# 测试查询
if curl -s -X POST \
    -H "Content-Type: application/json" \
    --data '{"query": "{ _meta { block { number } } }"}' \
    "$GRAPHQL_URL" | grep -q "block"; then
    success "GraphQL 查询成功"
else
    warn "GraphQL 查询失败（可能仍在同步）"
fi

# ============================================================================
# 完成
# ============================================================================
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Subgraph 部署完成！${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
info "访问地址:"
echo "  GraphQL API:      $GRAPHQL_URL"
echo "  GraphQL Playground: ${GRAPHQL_URL}/graphql"
echo "  索引状态:         http://localhost:8030/graphql"
echo ""
info "常用命令:"
echo "  查看日志:    docker logs -f graph-node"
echo "  容器状态:    docker compose ps"
echo "  停止服务:    docker compose down"
echo ""
info "测试查询:"
echo "  curl -s -X POST -H 'Content-Type: application/json' \\"
echo "    -d '{\"query\": \"{ markets { id state } }\"}' \\"
echo "    $GRAPHQL_URL | jq ."
echo ""
