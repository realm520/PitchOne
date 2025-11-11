#!/bin/bash

# PitchOne Database Initialization Script
# 一键创建并初始化数据库（包含所有迁移）

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境变量
check_env() {
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is not set"
        echo "Example: export DATABASE_URL='postgresql://user:password@localhost:5432/pitchone'"
        exit 1
    fi
    log_success "DATABASE_URL is set"
}

# 解析 DATABASE_URL
parse_database_url() {
    # 从 postgresql://user:pass@host:port/dbname 提取各部分
    DB_URL_REGEX="postgresql://([^:]+):([^@]+)@([^:]+):([^/]+)/(.*)"

    if [[ $DATABASE_URL =~ $DB_URL_REGEX ]]; then
        DB_USER="${BASH_REMATCH[1]}"
        DB_PASS="${BASH_REMATCH[2]}"
        DB_HOST="${BASH_REMATCH[3]}"
        DB_PORT="${BASH_REMATCH[4]}"
        DB_NAME="${BASH_REMATCH[5]}"

        log_info "Database: $DB_NAME @ $DB_HOST:$DB_PORT"
    else
        log_error "Invalid DATABASE_URL format"
        exit 1
    fi
}

# 检查 PostgreSQL 是否可用
check_postgres() {
    log_info "Checking PostgreSQL connection..."

    if command -v pg_isready &> /dev/null; then
        if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" &> /dev/null; then
            log_success "PostgreSQL is ready"
        else
            log_error "PostgreSQL is not ready at $DB_HOST:$DB_PORT"
            exit 1
        fi
    else
        log_warn "pg_isready not found, skipping connection check"
    fi
}

# 创建数据库（如果不存在）
create_database() {
    log_info "Creating database if not exists..."

    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tc \
        "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c \
        "CREATE DATABASE $DB_NAME"

    log_success "Database '$DB_NAME' is ready"
}

# 运行迁移脚本
run_migrations() {
    log_info "Running database migrations..."

    MIGRATIONS_DIR="$(dirname "$0")/../pkg/db/migrations"

    if [ ! -d "$MIGRATIONS_DIR" ]; then
        log_error "Migrations directory not found: $MIGRATIONS_DIR"
        exit 1
    fi

    # 按顺序执行 .up.sql 文件
    for migration in $(ls "$MIGRATIONS_DIR"/*.up.sql | sort); do
        log_info "Applying: $(basename "$migration")"
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration"
    done

    log_success "All migrations applied successfully"
}

# 验证数据库 schema
verify_schema() {
    log_info "Verifying database schema..."

    # 检查关键表是否存在
    EXPECTED_TABLES=(
        "markets"
        "orders"
        "positions"
        "payouts"
        "keeper_tasks"
        "reward_distributions"
        "campaigns"
        "quests"
        "referrals"
        "parlays"
        "player_props_markets"
    )

    for table in "${EXPECTED_TABLES[@]}"; do
        if PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tc \
            "SELECT 1 FROM information_schema.tables WHERE table_name = '$table'" | grep -q 1; then
            log_success "Table '$table' exists"
        else
            log_error "Table '$table' is missing"
            exit 1
        fi
    done
}

# 显示数据库统计
show_stats() {
    log_info "Database statistics:"

    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
        LIMIT 10;
    "
}

# 显示迁移版本
show_versions() {
    log_info "Applied schema versions:"

    PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT version, description, applied_at
        FROM schema_version
        ORDER BY version;
    "
}

# 主流程
main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚀 PitchOne Database Initialization"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    check_env
    parse_database_url
    check_postgres
    create_database
    run_migrations
    verify_schema
    show_versions
    show_stats

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Database initialization completed successfully! ✨"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo "  1. Start the Indexer:  go run ./cmd/indexer"
    echo "  2. Start the Keeper:   go run ./cmd/keeper"
    echo "  3. Start the Scheduler: go run ./cmd/scheduler"
    echo ""
}

# 执行主流程
main
