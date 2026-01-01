#!/bin/bash
# ============================================================================
# PitchOne VPS 初始化脚本
#
# 功能：在全新 VPS 上安装 Docker 和必要工具
# 支持：Ubuntu 20.04/22.04/24.04, Debian 11/12
#
# 使用方法：
#   curl -fsSL https://raw.githubusercontent.com/your-repo/PitchOne/main/deploy/scripts/init-vps.sh | bash
#   或
#   chmod +x init-vps.sh && ./init-vps.sh
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    log_info "检测到操作系统: $OS $VERSION"
}

# 更新系统
update_system() {
    log_info "更新系统包..."
    apt-get update -y
    apt-get upgrade -y
}

# 安装基础工具
install_basics() {
    log_info "安装基础工具..."
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        wget \
        unzip \
        htop \
        vim \
        jq \
        make \
        ufw
}

# 安装 Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log_warning "Docker 已安装，跳过..."
        docker --version
        return
    fi

    log_info "安装 Docker..."

    # 添加 Docker GPG 密钥
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # 添加 Docker 仓库
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$OS \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 安装 Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker
    systemctl start docker
    systemctl enable docker

    log_success "Docker 安装完成"
    docker --version
}

# 配置非 root 用户使用 Docker
configure_docker_user() {
    # 获取实际用户（如果通过 sudo 运行）
    ACTUAL_USER=${SUDO_USER:-$USER}

    if [ "$ACTUAL_USER" != "root" ]; then
        log_info "将用户 $ACTUAL_USER 添加到 docker 组..."
        usermod -aG docker $ACTUAL_USER
        log_warning "请注销并重新登录以使 docker 组生效"
    fi
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."

    # 启用 UFW
    ufw --force enable

    # 允许 SSH
    ufw allow ssh

    # 允许 HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    # 显示状态
    ufw status

    log_success "防火墙配置完成"
}

# 配置 swap（如果内存较小）
configure_swap() {
    # 检查现有 swap
    SWAP_SIZE=$(free -m | awk '/Swap/ {print $2}')

    if [ "$SWAP_SIZE" -lt 1024 ]; then
        log_info "配置 2GB swap..."

        # 创建 swap 文件
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile

        # 持久化
        echo '/swapfile none swap sw 0 0' >> /etc/fstab

        log_success "Swap 配置完成"
    else
        log_info "Swap 已配置 (${SWAP_SIZE}MB)，跳过..."
    fi
}

# 创建项目目录
create_project_dirs() {
    log_info "创建项目目录..."

    PROJECT_DIR="/opt/pitchone"
    mkdir -p $PROJECT_DIR
    mkdir -p $PROJECT_DIR/ssl
    mkdir -p $PROJECT_DIR/logs
    mkdir -p $PROJECT_DIR/backups

    # 如果有非 root 用户，设置权限
    ACTUAL_USER=${SUDO_USER:-$USER}
    if [ "$ACTUAL_USER" != "root" ]; then
        chown -R $ACTUAL_USER:$ACTUAL_USER $PROJECT_DIR
    fi

    log_success "项目目录创建完成: $PROJECT_DIR"
}

# 安装 certbot（用于 SSL 证书）
install_certbot() {
    if command -v certbot &> /dev/null; then
        log_warning "Certbot 已安装，跳过..."
        return
    fi

    log_info "安装 Certbot..."
    apt-get install -y certbot
    log_success "Certbot 安装完成"
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo "============================================"
    echo -e "${GREEN}VPS 初始化完成！${NC}"
    echo "============================================"
    echo ""
    echo "后续步骤："
    echo ""
    echo "1. 克隆项目代码："
    echo "   cd /opt/pitchone"
    echo "   git clone https://github.com/your-repo/PitchOne.git ."
    echo ""
    echo "2. 配置环境变量："
    echo "   cp .env.prod.example .env.prod"
    echo "   vim .env.prod"
    echo ""
    echo "3. 获取 SSL 证书（可选）："
    echo "   certbot certonly --standalone -d your-domain.com"
    echo "   cp /etc/letsencrypt/live/your-domain.com/* deploy/nginx/ssl/"
    echo ""
    echo "4. 启动服务："
    echo "   docker compose -f docker-compose.prod.yml --env-file .env.prod up -d"
    echo ""
    echo "5. 查看日志："
    echo "   docker compose -f docker-compose.prod.yml logs -f"
    echo ""
    echo "============================================"
}

# 主函数
main() {
    echo "============================================"
    echo "  PitchOne VPS 初始化脚本"
    echo "============================================"
    echo ""

    check_root
    detect_os
    update_system
    install_basics
    install_docker
    configure_docker_user
    configure_swap
    configure_firewall
    create_project_dirs
    install_certbot
    show_next_steps
}

main "$@"
