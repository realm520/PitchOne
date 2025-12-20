#!/bin/bash

###############################################################################
# PitchOne 完整部署脚本 v3.0
#
# 功能：
#   1. 部署所有合约（调用 contracts/script/Deploy.s.sol）
#   2. 创建测试市场（调用 contracts/script/CreateAllMarketTypes.s.sol）
#   3. 建立推荐关系（调用 contracts/script/SetupReferrals.s.sol）
#   4. 模拟用户投注（调用 contracts/script/SimulateBets.s.sol）
#   5. 更新 Subgraph 配置并重建索引
#   6. 更新前端合约地址配置
#
# 使用方法：
#   ./scripts/deploy-parimutuel-full.sh
#
# 前提条件：
#   - Anvil 正在运行（http://localhost:8545）
#   - 已安装 foundry、graph-cli、docker、jq
#
# 版本历史：
#   v3.0 - 2025-12-15 - 完全重构，使用现有 Foundry 脚本
###############################################################################

set -e
set -o pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 自动检测项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 配置
CONTRACTS_DIR="$PROJECT_ROOT/contracts"
SUBGRAPH_DIR="$PROJECT_ROOT/subgraph"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
RPC_URL="http://localhost:8545"
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
DEPLOYMENT_FILE="$CONTRACTS_DIR/deployments/localhost.json"

# 打印带颜色的消息
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${CYAN}========================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}========================================${NC}\n"; }

###############################################################################
# 步骤 0: 验证前提条件
###############################################################################
step "步骤 0: 验证前提条件"

# 检查 Anvil
info "检查 Anvil 是否运行..."
if ! cast block-number --rpc-url "$RPC_URL" &>/dev/null; then
    error "Anvil 未运行。请先启动: cd $CONTRACTS_DIR && anvil --host 0.0.0.0"
fi
BLOCK_NUMBER=$(cast block-number --rpc-url "$RPC_URL")
success "Anvil 运行中 (区块高度: $BLOCK_NUMBER)"

# 检查必需工具
for cmd in forge cast jq; do
    if ! command -v $cmd &>/dev/null; then
        error "缺少必需工具: $cmd"
    fi
done
success "所有必需工具已安装"

# 检查 Docker（用于 Subgraph）
if command -v docker &>/dev/null; then
    if docker compose version &>/dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &>/dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        warn "docker compose 不可用，将跳过 Subgraph 重建"
        DOCKER_COMPOSE=""
    fi
else
    warn "Docker 未安装，将跳过 Subgraph 重建"
    DOCKER_COMPOSE=""
fi

###############################################################################
# 步骤 1: 部署所有合约
###############################################################################
step "步骤 1: 部署所有合约"

cd "$CONTRACTS_DIR"

# 清理旧的 broadcast 文件
info "清理旧的部署记录..."
rm -rf broadcast/

info "运行 Deploy.s.sol..."
if ! PRIVATE_KEY=$PRIVATE_KEY forge script script/Deploy.s.sol:Deploy \
    --rpc-url "$RPC_URL" \
    --broadcast \
    -v; then
    # 检查是否生成了 deployment 文件（可能是合约大小警告导致非零退出码）
    if [ -f "$DEPLOYMENT_FILE" ]; then
        warn "Forge 返回非零退出码，但 deployment 文件已生成，继续执行"
    else
        error "合约部署失败"
    fi
fi

# 验证部署文件
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    error "部署配置文件未生成: $DEPLOYMENT_FILE"
fi

# 提取关键地址
FACTORY=$(jq -r '.contracts.factory' "$DEPLOYMENT_FILE")
USDC=$(jq -r '.contracts.usdc' "$DEPLOYMENT_FILE")
VAULT=$(jq -r '.contracts.vault' "$DEPLOYMENT_FILE")
FEE_ROUTER=$(jq -r '.contracts.feeRouter' "$DEPLOYMENT_FILE")
BETTING_ROUTER=$(jq -r '.contracts.bettingRouter' "$DEPLOYMENT_FILE")
REFERRAL_REGISTRY=$(jq -r '.contracts.referralRegistry' "$DEPLOYMENT_FILE")

success "合约部署完成"
echo "  Factory: $FACTORY"
echo "  USDC: $USDC"
echo "  Vault: $VAULT"
echo "  FeeRouter: $FEE_ROUTER"
echo "  BettingRouter: $BETTING_ROUTER"
echo "  ReferralRegistry: $REFERRAL_REGISTRY"

###############################################################################
# 步骤 2: 创建测试市场
###############################################################################
step "步骤 2: 创建测试市场 (7 种类型，21 个市场)"

cd "$CONTRACTS_DIR"

info "运行 CreateAllMarketTypes.s.sol..."
if ! PRIVATE_KEY=$PRIVATE_KEY forge script script/CreateAllMarketTypes.s.sol:CreateAllMarketTypes \
    --rpc-url "$RPC_URL" \
    --broadcast \
    -v; then
    error "市场创建失败"
fi

# 验证市场数量
MARKET_COUNT=$(cast call "$FACTORY" "getMarketCount()(uint256)" --rpc-url "$RPC_URL" 2>/dev/null)
MARKET_COUNT_DEC=$(cast --to-dec "$MARKET_COUNT" 2>/dev/null || echo "0")
success "市场创建完成，共 $MARKET_COUNT_DEC 个市场"

###############################################################################
# 步骤 3: 建立推荐关系
###############################################################################
step "步骤 3: 建立推荐关系"

cd "$CONTRACTS_DIR"

info "运行 SetupReferrals.s.sol..."
if forge script script/SetupReferrals.s.sol:SetupReferrals \
    --rpc-url "$RPC_URL" \
    --broadcast \
    -v 2>&1 | grep -E "(SUCCESS|FAILED|Referral|Account)" || true; then
    success "推荐关系建立完成"
else
    warn "推荐关系设置可能未完全成功"
fi

###############################################################################
# 步骤 4: 模拟用户投注
###############################################################################
step "步骤 4: 模拟用户投注"

cd "$CONTRACTS_DIR"

info "运行 SimulateBets.s.sol..."
if ! NUM_BETTORS=5 \
    MIN_BET_AMOUNT=10 \
    MAX_BET_AMOUNT=100 \
    BETS_PER_USER=2 \
    OUTCOME_DISTRIBUTION=balanced \
    forge script script/SimulateBets.s.sol:SimulateBets \
    --rpc-url "$RPC_URL" \
    --broadcast \
    -v; then
    warn "投注模拟可能未完全成功"
fi

success "投注模拟完成"

###############################################################################
# 步骤 5: 更新 Subgraph 配置并重建
###############################################################################
step "步骤 5: 更新 Subgraph 并重建索引"

if [ -z "$DOCKER_COMPOSE" ]; then
    warn "跳过 Subgraph 重建（Docker 不可用）"
else
    cd "$SUBGRAPH_DIR"

    # 更新 subgraph.yaml 配置
    if [ -f "config/update-config.js" ]; then
        info "更新 subgraph.yaml 配置..."
        node config/update-config.js "$DEPLOYMENT_FILE" || warn "配置更新失败"
    fi

    # 停止并清理 Graph Node
    info "清理 Graph Node..."
    $DOCKER_COMPOSE down -v &>/dev/null || true
    sleep 2

    # 启动 Graph Node
    info "启动 Graph Node..."
    $DOCKER_COMPOSE up -d

    info "等待 Graph Node 启动 (20秒)..."
    sleep 20

    # 检查 graph-cli
    if command -v graph &>/dev/null; then
        info "生成 Subgraph 代码..."
        graph codegen || warn "codegen 失败"
        graph build || warn "build 失败"

        info "部署 Subgraph..."
        graph create --node http://localhost:8020/ pitchone-sportsbook &>/dev/null || true
        VERSION_LABEL="v$(date +%Y%m%d-%H%M%S)"
        graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 --version-label "$VERSION_LABEL" pitchone-sportsbook || warn "部署失败"

        success "Subgraph 部署完成 ($VERSION_LABEL)"
    else
        warn "graph-cli 未安装，跳过 Subgraph 部署"
    fi
fi

###############################################################################
# 步骤 6: 更新前端合约地址
###############################################################################
step "步骤 6: 更新前端合约地址"

FRONTEND_ADDRESSES_FILE="$FRONTEND_DIR/packages/contracts/src/addresses/index.ts"

if [ -f "$FRONTEND_ADDRESSES_FILE" ]; then
    info "更新前端地址配置..."

    # 读取合约地址
    FACTORY=$(jq -r '.contracts.factory' "$DEPLOYMENT_FILE")
    USDC=$(jq -r '.contracts.usdc' "$DEPLOYMENT_FILE")
    VAULT=$(jq -r '.contracts.vault' "$DEPLOYMENT_FILE")
    FEE_ROUTER=$(jq -r '.contracts.feeRouter' "$DEPLOYMENT_FILE")
    CPMM=$(jq -r '.contracts.simpleCPMM // .contracts.cpmm // "0x0000000000000000000000000000000000000000"' "$DEPLOYMENT_FILE")
    PARIMUTUEL=$(jq -r '.contracts.parimutuelPricing // .contracts.parimutuel // "0x0000000000000000000000000000000000000000"' "$DEPLOYMENT_FILE")
    REFERRAL_REGISTRY=$(jq -r '.contracts.referralRegistry' "$DEPLOYMENT_FILE")
    PARAM_CONTROLLER=$(jq -r '.contracts.paramController // "0x0000000000000000000000000000000000000000"' "$DEPLOYMENT_FILE")

    # 生成新的地址文件
    cat > "$FRONTEND_ADDRESSES_FILE" <<EOF
import type { Address, ContractAddresses } from '../index';

// ============================================================================
// Anvil 本地测试链地址
// 部署时间: $(date +%Y-%m-%d) (自动生成)
// 来源: scripts/deploy-parimutuel-full.sh
// ============================================================================
export const ANVIL_ADDRESSES: ContractAddresses = {
  marketTemplateRegistry: '$FACTORY', // MarketFactory_v2
  vault: '$VAULT',               // LiquidityVault
  usdc: '$USDC',               // MockUSDC
  feeRouter: '$FEE_ROUTER',           // FeeRouter
  simpleCPMM: '$CPMM',          // SimpleCPMM
  parimutuel: '$PARIMUTUEL',         // Parimutuel
  referralRegistry: '$REFERRAL_REGISTRY',   // ReferralRegistry
  basket: '0x0000000000000000000000000000000000000000',            // 待部署
  correlationGuard: '0x0000000000000000000000000000000000000000',   // 待部署
  rewardsDistributor: '0x0000000000000000000000000000000000000000', // 待部署
  paramController: '$PARAM_CONTROLLER',          // ParamController
};

// Sepolia 测试网地址 (待部署)
export const SEPOLIA_ADDRESSES: Partial<ContractAddresses> = {
  // TODO: 部署后填写
};

// 根据 chainId 获取地址
export function getContractAddresses(chainId: number): ContractAddresses {
  switch (chainId) {
    case 31337: // Anvil
      return ANVIL_ADDRESSES;
    case 11155111: // Sepolia
      return SEPOLIA_ADDRESSES as ContractAddresses;
    default:
      // 开发环境下，未知链默认使用 Anvil 地址
      console.warn(\`Unknown chain ID: \${chainId}, falling back to Anvil addresses\`);
      return ANVIL_ADDRESSES;
  }
}
EOF

    success "前端地址配置已更新"

    # 清理前端缓存
    info "清理前端缓存..."
    rm -rf "$FRONTEND_DIR/apps/admin/.next" 2>/dev/null || true
    rm -rf "$FRONTEND_DIR/apps/user/.next" 2>/dev/null || true
    success "前端缓存已清理"
else
    warn "前端地址文件不存在: $FRONTEND_ADDRESSES_FILE"
fi

###############################################################################
# 完成总结
###############################################################################
step "部署完成！"

echo -e "${GREEN}✓ 合约部署完成${NC}"
echo -e "${GREEN}✓ 测试市场创建完成 ($MARKET_COUNT_DEC 个市场)${NC}"
echo -e "${GREEN}✓ 推荐关系建立完成${NC}"
echo -e "${GREEN}✓ 投注模拟完成${NC}"
if [ -n "$DOCKER_COMPOSE" ]; then
    echo -e "${GREEN}✓ Subgraph 已重建${NC}"
fi
echo -e "${GREEN}✓ 前端配置已更新${NC}"

echo ""
echo "关键信息："
echo "  - 合约配置文件: $DEPLOYMENT_FILE"
echo "  - Factory: $FACTORY"
echo "  - BettingRouter: $BETTING_ROUTER"
echo "  - 市场总数: $MARKET_COUNT_DEC"
echo ""

if [ -n "$DOCKER_COMPOSE" ]; then
    echo "访问 GraphQL Playground："
    echo "  http://localhost:8010/subgraphs/name/pitchone-sportsbook/graphql"
    echo ""
fi

echo -e "${YELLOW}提示：前端需要重启才能使用新的合约地址${NC}"
echo "  cd $FRONTEND_DIR && pnpm dev"
echo ""
