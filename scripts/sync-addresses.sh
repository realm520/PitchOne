#!/bin/bash
# 同步远程服务器合约地址到本地配置文件
# 用法: ./scripts/sync-addresses.sh [remote_json_path]
#
# 默认从 /home/harry/code/PitchOne/contracts/deployments/localhost_v3.json 同步

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SSH_HOST="pitchone-server"
REMOTE_JSON_PATH="${1:-/home/harry/code/PitchOne/contracts/deployments/localhost_v3.json}"

# 本地文件路径（相对于项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

LOCAL_JSON="$PROJECT_ROOT/contracts/deployments/localhost_v3.json"
SUBGRAPH_YAML="$PROJECT_ROOT/subgraph/subgraph.yaml"
ADDRESSES_TS="$PROJECT_ROOT/frontend/packages/contracts/src/addresses.ts"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  PitchOne 地址同步工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 从远程获取 JSON
echo -e "${YELLOW}[1/4] 从远程服务器获取合约地址...${NC}"
REMOTE_JSON=$(ssh "$SSH_HOST" "cat $REMOTE_JSON_PATH" 2>/dev/null)

if [ -z "$REMOTE_JSON" ]; then
    echo -e "${RED}错误: 无法从远程服务器获取地址文件${NC}"
    echo "请确保:"
    echo "  1. SSH 配置正确 (Host: $SSH_HOST)"
    echo "  2. 远程文件存在: $REMOTE_JSON_PATH"
    exit 1
fi

echo -e "${GREEN}成功获取远程地址${NC}"

# 解析地址
FACTORY=$(echo "$REMOTE_JSON" | jq -r '.contracts.factory')
USDC=$(echo "$REMOTE_JSON" | jq -r '.contracts.usdc')
VAULT=$(echo "$REMOTE_JSON" | jq -r '.contracts.liquidityVault')
ROUTER=$(echo "$REMOTE_JSON" | jq -r '.contracts.bettingRouter')
FEE_ROUTER=$(echo "$REMOTE_JSON" | jq -r '.contracts.feeRouter')
PARAM_CONTROLLER=$(echo "$REMOTE_JSON" | jq -r '.contracts.paramController')
REFERRAL_REGISTRY=$(echo "$REMOTE_JSON" | jq -r '.contracts.referralRegistry')
MARKET_IMPL=$(echo "$REMOTE_JSON" | jq -r '.contracts.marketImplementation')

# 策略
CPMM=$(echo "$REMOTE_JSON" | jq -r '.strategies.cpmm')
LMSR=$(echo "$REMOTE_JSON" | jq -r '.strategies.lmsr')
PARIMUTUEL=$(echo "$REMOTE_JSON" | jq -r '.strategies.parimutuel')

# 映射器
WDL_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.wdl')
OU_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.ou')
AH_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.ah')
ODDEEVEN_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.oddEven')
SCORE_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.score')
IDENTITY_MAPPER=$(echo "$REMOTE_JSON" | jq -r '.mappers.identity')

echo ""
echo "核心合约地址:"
echo "  Factory:    $FACTORY"
echo "  USDC:       $USDC"
echo "  Vault:      $VAULT"
echo "  Router:     $ROUTER"
echo ""

# 2. 更新本地 JSON
echo -e "${YELLOW}[2/4] 更新本地 localhost_v3.json...${NC}"
echo "$REMOTE_JSON" > "$LOCAL_JSON"
echo -e "${GREEN}已更新: $LOCAL_JSON${NC}"

# 3. 更新 subgraph.yaml
echo -e "${YELLOW}[3/4] 更新 subgraph/subgraph.yaml...${NC}"

# 使用 sed 替换地址（macOS 兼容）
sed -i '' "s|address: \"0x[a-fA-F0-9]\{40\}\"|address: \"$FACTORY\"|" "$SUBGRAPH_YAML" 2>/dev/null || true

# 更精确的替换（按数据源名称）
# MarketFactory
sed -i '' "/name: MarketFactory/,/startBlock:/{s|address: \"0x[a-fA-F0-9]\{40\}\"|address: \"$FACTORY\"|;}" "$SUBGRAPH_YAML"
# FeeRouter
sed -i '' "/name: FeeRouter/,/startBlock:/{s|address: \"0x[a-fA-F0-9]\{40\}\"|address: \"$FEE_ROUTER\"|;}" "$SUBGRAPH_YAML"
# LiquidityVault
sed -i '' "/name: LiquidityVault/,/startBlock:/{s|address: \"0x[a-fA-F0-9]\{40\}\"|address: \"$VAULT\"|;}" "$SUBGRAPH_YAML"
# ReferralRegistry
sed -i '' "/name: ReferralRegistry/,/startBlock:/{s|address: \"0x[a-fA-F0-9]\{40\}\"|address: \"$REFERRAL_REGISTRY\"|;}" "$SUBGRAPH_YAML"

echo -e "${GREEN}已更新: $SUBGRAPH_YAML${NC}"

# 4. 更新 addresses.ts
echo -e "${YELLOW}[4/4] 更新 frontend/packages/contracts/src/addresses.ts...${NC}"

# 使用 sed 替换（macOS 兼容）
sed -i '' "s|factory: '0x[a-fA-F0-9]\{40\}'|factory: '$FACTORY'|g" "$ADDRESSES_TS"
sed -i '' "s|vault: '0x[a-fA-F0-9]\{40\}'|vault: '$VAULT'|g" "$ADDRESSES_TS"
sed -i '' "s|bettingRouter: '0x[a-fA-F0-9]\{40\}'|bettingRouter: '$ROUTER'|g" "$ADDRESSES_TS"
sed -i '' "s|feeRouter: '0x[a-fA-F0-9]\{40\}'|feeRouter: '$FEE_ROUTER'|g" "$ADDRESSES_TS"
sed -i '' "s|referralRegistry: '0x[a-fA-F0-9]\{40\}'|referralRegistry: '$REFERRAL_REGISTRY'|g" "$ADDRESSES_TS"
sed -i '' "s|paramController: '0x[a-fA-F0-9]\{40\}'|paramController: '$PARAM_CONTROLLER'|g" "$ADDRESSES_TS"
sed -i '' "s|usdc: '0x[a-fA-F0-9]\{40\}'|usdc: '$USDC'|g" "$ADDRESSES_TS"
sed -i '' "s|marketImplementation: '0x[a-fA-F0-9]\{40\}'|marketImplementation: '$MARKET_IMPL'|g" "$ADDRESSES_TS"

# 策略
sed -i '' "s|cpmm: '0x[a-fA-F0-9]\{40\}'|cpmm: '$CPMM'|g" "$ADDRESSES_TS"
sed -i '' "s|lmsr: '0x[a-fA-F0-9]\{40\}'|lmsr: '$LMSR'|g" "$ADDRESSES_TS"
sed -i '' "s|parimutuel: '0x[a-fA-F0-9]\{40\}'|parimutuel: '$PARIMUTUEL'|g" "$ADDRESSES_TS"

# 映射器
sed -i '' "s|wdl: '0x[a-fA-F0-9]\{40\}'|wdl: '$WDL_MAPPER'|g" "$ADDRESSES_TS"
sed -i '' "s|ou: '0x[a-fA-F0-9]\{40\}'|ou: '$OU_MAPPER'|g" "$ADDRESSES_TS"
sed -i '' "s|ah: '0x[a-fA-F0-9]\{40\}'|ah: '$AH_MAPPER'|g" "$ADDRESSES_TS"
sed -i '' "s|oddEven: '0x[a-fA-F0-9]\{40\}'|oddEven: '$ODDEEVEN_MAPPER'|g" "$ADDRESSES_TS"
sed -i '' "s|score: '0x[a-fA-F0-9]\{40\}'|score: '$SCORE_MAPPER'|g" "$ADDRESSES_TS"
sed -i '' "s|identity: '0x[a-fA-F0-9]\{40\}'|identity: '$IDENTITY_MAPPER'|g" "$ADDRESSES_TS"

# marketTemplateRegistry 指向 factory
sed -i '' "s|marketTemplateRegistry: '0x[a-fA-F0-9]\{40\}'|marketTemplateRegistry: '$FACTORY'|g" "$ADDRESSES_TS"

echo -e "${GREEN}已更新: $ADDRESSES_TS${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  地址同步完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "已同步的文件:"
echo "  - contracts/deployments/localhost_v3.json"
echo "  - subgraph/subgraph.yaml"
echo "  - frontend/packages/contracts/src/addresses.ts"
echo ""
echo -e "${YELLOW}提示: 如果需要更新远程 Subgraph，请运行:${NC}"
echo "  make remote-subgraph"
