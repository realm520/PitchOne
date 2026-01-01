#!/bin/bash
# ============================================================================
# PitchOne 部署脚本
#
# 功能：构建并部署所有服务到 Docker
#
# 使用方法：
#   ./deploy.sh              # 完整部署
#   ./deploy.sh --pull       # 拉取最新代码后部署
#   ./deploy.sh --rebuild    # 强制重新构建镜像
#   ./deploy.sh --subgraph   # 仅部署 Subgraph
#   ./deploy.sh --status     # 查看服务状态
#   ./deploy.sh --logs       # 查看日志
#   ./deploy.sh --stop       # 停止所有服务
# ============================================================================

set -e

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查必要文件
check_requirements() {
    log_info "检查必要文件..."

    if [ ! -f "$PROJECT_ROOT/.env.prod" ]; then
        log_error ".env.prod 文件不存在"
        log_info "请复制 .env.prod.example 到 .env.prod 并填写配置"
        exit 1
    fi

    if [ ! -f "$PROJECT_ROOT/docker-compose.prod.yml" ]; then
        log_error "docker-compose.prod.yml 文件不存在"
        exit 1
    fi

    # 检查必要的环境变量
    source "$PROJECT_ROOT/.env.prod"

    if [ -z "$POSTGRES_PASSWORD" ]; then
        log_error "POSTGRES_PASSWORD 未设置"
        exit 1
    fi

    if [ -z "$GRAPH_POSTGRES_PASSWORD" ]; then
        log_error "GRAPH_POSTGRES_PASSWORD 未设置"
        exit 1
    fi

    if [ -z "$ETHEREUM_RPC_URL" ]; then
        log_error "ETHEREUM_RPC_URL 未设置"
        exit 1
    fi

    log_success "配置检查通过"
}

# 拉取最新代码
pull_latest() {
    log_info "拉取最新代码..."
    cd "$PROJECT_ROOT"
    git pull origin main
    log_success "代码更新完成"
}

# 构建镜像
build_images() {
    local force_rebuild=$1
    log_info "构建 Docker 镜像..."

    cd "$PROJECT_ROOT"

    if [ "$force_rebuild" = "true" ]; then
        docker compose -f docker-compose.prod.yml --env-file .env.prod build --no-cache
    else
        docker compose -f docker-compose.prod.yml --env-file .env.prod build
    fi

    log_success "镜像构建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    cd "$PROJECT_ROOT"

    docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

    log_success "服务启动完成"
}

# 停止服务
stop_services() {
    log_info "停止服务..."
    cd "$PROJECT_ROOT"

    docker compose -f docker-compose.prod.yml --env-file .env.prod down

    log_success "服务已停止"
}

# 查看状态
show_status() {
    cd "$PROJECT_ROOT"
    echo ""
    log_info "服务状态："
    docker compose -f docker-compose.prod.yml --env-file .env.prod ps
    echo ""
    log_info "资源使用："
    docker stats --no-stream
}

# 查看日志
show_logs() {
    cd "$PROJECT_ROOT"
    docker compose -f docker-compose.prod.yml --env-file .env.prod logs -f --tail=100
}

# 部署 Subgraph
deploy_subgraph() {
    log_info "部署 Subgraph..."

    cd "$PROJECT_ROOT/subgraph"

    # 检查 Graph Node 是否运行
    if ! docker ps | grep -q "pitchone-graph-node"; then
        log_error "Graph Node 未运行，请先启动服务"
        exit 1
    fi

    # 等待 Graph Node 就绪
    log_info "等待 Graph Node 就绪..."
    sleep 5

    # 生成代码
    log_info "生成 Subgraph 代码..."
    npm run codegen || npx graph codegen

    # 构建
    log_info "构建 Subgraph..."
    npm run build || npx graph build

    # 创建 Subgraph（如果不存在）
    log_info "创建 Subgraph..."
    npx graph create --node http://localhost:8020/ pitchone-sportsbook || true

    # 部署
    log_info "部署 Subgraph..."
    npx graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 pitchone-sportsbook

    log_success "Subgraph 部署完成"
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    echo ""

    # 检查 Backend API
    if curl -s http://localhost/api/health > /dev/null 2>&1; then
        log_success "Backend API: 正常"
    else
        log_warning "Backend API: 异常或未就绪"
    fi

    # 检查 GraphQL
    if curl -s -X POST -H "Content-Type: application/json" \
        --data '{"query": "{ _meta { block { number } } }"}' \
        http://localhost/subgraphs/name/pitchone-sportsbook > /dev/null 2>&1; then
        log_success "GraphQL: 正常"
    else
        log_warning "GraphQL: 异常或未就绪"
    fi

    # 检查数据库
    if docker exec pitchone-postgres pg_isready -U pitchone > /dev/null 2>&1; then
        log_success "PostgreSQL: 正常"
    else
        log_warning "PostgreSQL: 异常"
    fi

    # 检查 Graph PostgreSQL
    if docker exec pitchone-graph-postgres pg_isready -U graph-node > /dev/null 2>&1; then
        log_success "Graph PostgreSQL: 正常"
    else
        log_warning "Graph PostgreSQL: 异常"
    fi

    echo ""
}

# 显示帮助
show_help() {
    echo "PitchOne 部署脚本"
    echo ""
    echo "使用方法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  (无)            完整部署（构建 + 启动）"
    echo "  --pull          拉取最新代码后部署"
    echo "  --rebuild       强制重新构建镜像"
    echo "  --subgraph      仅部署 Subgraph"
    echo "  --status        查看服务状态"
    echo "  --logs          查看服务日志"
    echo "  --stop          停止所有服务"
    echo "  --health        执行健康检查"
    echo "  --help          显示此帮助信息"
    echo ""
}

# 主函数
main() {
    case "$1" in
        --pull)
            check_requirements
            pull_latest
            build_images false
            start_services
            health_check
            ;;
        --rebuild)
            check_requirements
            build_images true
            start_services
            health_check
            ;;
        --subgraph)
            deploy_subgraph
            ;;
        --status)
            show_status
            ;;
        --logs)
            show_logs
            ;;
        --stop)
            stop_services
            ;;
        --health)
            health_check
            ;;
        --help)
            show_help
            ;;
        "")
            check_requirements
            build_images false
            start_services
            echo ""
            log_info "等待服务启动..."
            sleep 10
            health_check
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
