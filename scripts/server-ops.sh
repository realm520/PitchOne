#!/bin/bash
# PitchOne 服务器运维脚本
# 用法: ./scripts/server-ops.sh <command>
#
# 支持的命令:
#   pull              拉取最新代码
#   frontend-build    构建前端
#   frontend-restart  重启前端服务 (pm2)
#   subgraph-rebuild  重建 Subgraph
#   contracts-deploy  重新部署合约
#   anvil-restart     重启 Anvil
#   ngrok-restart     重启 ngrok 隧道
#   status            查看服务状态
#   frontend-update   拉代码 + 构建 + 重启前端
#   subgraph-update   拉代码 + 重建 Subgraph
#   full-reset        完整重置（合约+Subgraph+前端）

set -e

# 服务器配置
# SSH Host 别名（需在 ~/.ssh/config 中配置 pitchone-server）
SSH_HOST="pitchone-server"
PROJECT_PATH="/home/harry/code/PitchOne"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# SSH 命令封装（加载用户环境：nvm + npm-global + foundry）
ssh_cmd() {
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_HOST" "export NVM_DIR=~/.nvm; source \$NVM_DIR/nvm.sh 2>/dev/null; export PATH=~/.foundry/bin:~/.npm-global/bin:\$PATH; $@"
}

# 显示帮助
show_help() {
    echo "PitchOne 服务器运维脚本"
    echo ""
    echo "用法: ./scripts/server-ops.sh <command>"
    echo ""
    echo "单独命令:"
    echo "  pull              拉取最新代码"
    echo "  frontend-build    构建前端"
    echo "  frontend-restart  重启前端服务 (pm2)"
    echo "  subgraph-rebuild  重建 Subgraph"
    echo "  contracts-deploy  重新部署合约"
    echo "  anvil-restart     重启 Anvil"
    echo "  ngrok-url         查看 ngrok URL"
    echo "  status            查看服务状态"
    echo ""
    echo "聚合命令:"
    echo "  frontend-update   拉代码 + 构建 + 重启前端"
    echo "  subgraph-update   拉代码 + 重建 Subgraph"
    echo "  full-reset        完整重置（合约+Subgraph+前端）"
    echo ""
    echo "示例:"
    echo "  ./scripts/server-ops.sh status"
    echo "  ./scripts/server-ops.sh frontend-update"
    echo "  make remote-status"
    echo ""
}

# 拉取代码
cmd_pull() {
    print_info "拉取最新代码..."
    ssh_cmd "cd $PROJECT_PATH && git pull origin main"
    print_success "代码拉取完成"
}

# 构建前端
cmd_frontend_build() {
    print_info "构建前端..."
    ssh_cmd "cd $PROJECT_PATH/frontend && pnpm install && pnpm build"
    print_success "前端构建完成"
}

# 重启前端 (pm2 生产模式)
cmd_frontend_restart() {
    print_info "重启前端服务 (生产模式)..."
    ssh_cmd "pm2 delete pitchone-user pitchone-admin 2>/dev/null || true"
    ssh_cmd "lsof -ti:3000 -ti:3001 | xargs kill -9 2>/dev/null || true"
    sleep 2
    ssh_cmd "cd $PROJECT_PATH/frontend && pm2 start pnpm --name pitchone-user -- start:user"
    ssh_cmd "cd $PROJECT_PATH/frontend && pm2 start pnpm --name pitchone-admin -- start:admin"
    print_success "前端服务已重启 (生产模式)"
}

# 重建 Subgraph
cmd_subgraph_rebuild() {
    print_info "重建 Subgraph..."
    ssh_cmd "cd $PROJECT_PATH/subgraph && ./deploy.sh -c -u -y"
    print_success "Subgraph 重建完成"
}

# 重新部署合约
cmd_contracts_deploy() {
    print_info "重新部署合约..."
    cmd_pull
    ssh_cmd "cd $PROJECT_PATH && ./scripts/quick-deploy.sh"
    print_success "合约部署完成"
}

# 重启 Anvil
cmd_anvil_restart() {
    print_info "重启 Anvil..."
    # 使用 -f 强制后台，避免 SSH 等待
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_HOST" "pkill anvil 2>/dev/null || true"
    sleep 2
    ssh -f -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$SSH_HOST" "cd $PROJECT_PATH/contracts && nohup anvil --host 0.0.0.0 > /tmp/anvil.log 2>&1 &"
    sleep 3
    # 验证 Anvil 是否启动
    if ssh_cmd "curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' http://localhost:8545 > /dev/null 2>&1"; then
        print_success "Anvil 已重启"
    else
        print_error "Anvil 启动失败"
        return 1
    fi
}

# 查看 ngrok URL（不重启，避免域名变化）
cmd_ngrok_url() {
    print_info "当前 ngrok 隧道 URL："
    ssh_cmd "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys,json; tunnels=json.load(sys.stdin)['tunnels']; [print(f'  {t[\\\"name\\\"]}: {t[\\\"public_url\\\"]}') for t in tunnels]\" 2>/dev/null || echo '  ngrok 未运行'"
}

# 查看状态
cmd_status() {
    print_info "服务状态:"
    echo ""
    ssh_cmd "
        echo '=== Anvil ==='
        curl -s -X POST -H 'Content-Type: application/json' --data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' http://localhost:8545 2>/dev/null | grep -o '\"result\":\"[^\"]*\"' || echo 'Not running'

        echo ''
        echo '=== Graph Node ==='
        curl -s http://localhost:8010/subgraphs/name/pitchone-sportsbook -X POST -H 'Content-Type: application/json' --data '{\"query\":\"{_meta{block{number}}}\"}' 2>/dev/null | head -c 100 || echo 'Not running'

        echo ''
        echo '=== Docker Containers ==='
        docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | grep -E 'graph|ipfs|ngrok' || echo 'No containers'

        echo ''
        echo '=== PM2 Services ==='
        pm2 list 2>/dev/null || echo 'PM2 not configured'

        echo ''
        echo '=== Ports ==='
        netstat -tlnp 2>/dev/null | grep -E ':3000|:3001|:8545|:8010' || ss -tlnp 2>/dev/null | grep -E ':3000|:3001|:8545|:8010' || echo 'No ports info'

        echo ''
        echo '=== ngrok Tunnels ==='
        curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '\"public_url\":\"[^\"]*\"' | head -5 || echo 'ngrok not running'
    "
    echo ""
}

# 聚合：前端更新
cmd_frontend_update() {
    print_info "开始前端更新..."
    cmd_pull
    cmd_frontend_build
    cmd_frontend_restart
    print_success "前端更新完成！"
}

# 聚合：Subgraph 更新
cmd_subgraph_update() {
    print_info "开始 Subgraph 更新..."
    cmd_pull
    cmd_subgraph_rebuild
    print_success "Subgraph 更新完成！"
}

# 聚合：完整重置
cmd_full_reset() {
    print_info "开始完整重置..."
    echo ""
    cmd_pull
    echo ""
    cmd_anvil_restart
    echo ""
    # 直接调用 quick-deploy.sh（已包含合约部署 + Subgraph 部署）
    print_info "部署合约和 Subgraph..."
    ssh_cmd "cd $PROJECT_PATH && ./scripts/quick-deploy.sh"
    print_success "合约和 Subgraph 部署完成"
    echo ""
    cmd_frontend_build
    echo ""
    cmd_frontend_restart
    echo ""
    print_success "完整重置完成！"
    echo ""
    cmd_status
}

# 主逻辑
case "${1:-help}" in
    pull)              cmd_pull ;;
    frontend-build)    cmd_frontend_build ;;
    frontend-restart)  cmd_frontend_restart ;;
    subgraph-rebuild)  cmd_subgraph_rebuild ;;
    contracts-deploy)  cmd_contracts_deploy ;;
    anvil-restart)     cmd_anvil_restart ;;
    ngrok-url)         cmd_ngrok_url ;;
    status)            cmd_status ;;
    frontend-update)   cmd_frontend_update ;;
    subgraph-update)   cmd_subgraph_update ;;
    full-reset)        cmd_full_reset ;;
    help|--help|-h)    show_help ;;
    *)
        print_error "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
