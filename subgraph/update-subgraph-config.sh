#!/bin/bash
# 自动从 deployments/localhost.json 更新 subgraph.yaml 中的合约地址
# 用法: ./update-subgraph-config.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_FILE="$SCRIPT_DIR/../contracts/deployments/localhost.json"
SUBGRAPH_YAML="$SCRIPT_DIR/subgraph.yaml"
TEMPLATE_FILE="$SCRIPT_DIR/subgraph.template.yaml"

echo -e "${YELLOW}🔄 更新 Subgraph 配置...${NC}"

# 检查 deployment 文件是否存在
if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo -e "${RED}❌ 错误: $DEPLOYMENT_FILE 不存在${NC}"
    echo "请先运行 Deploy.s.sol 部署合约"
    exit 1
fi

# 检查模板文件是否存在
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ 错误: $TEMPLATE_FILE 不存在${NC}"
    echo "请先创建模板文件"
    exit 1
fi

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ 错误: 需要安装 jq${NC}"
    echo "Ubuntu/Debian: sudo apt-get install jq"
    echo "Mac: brew install jq"
    exit 1
fi

# 从 JSON 读取地址
FACTORY_ADDRESS=$(jq -r '.contracts.factory' "$DEPLOYMENT_FILE")
FEE_ROUTER_ADDRESS=$(jq -r '.contracts.feeRouter' "$DEPLOYMENT_FILE")

# 验证地址
if [ "$FACTORY_ADDRESS" == "null" ] || [ -z "$FACTORY_ADDRESS" ]; then
    echo -e "${RED}❌ 错误: 无法从 $DEPLOYMENT_FILE 读取 Factory 地址${NC}"
    exit 1
fi

if [ "$FEE_ROUTER_ADDRESS" == "null" ] || [ -z "$FEE_ROUTER_ADDRESS" ]; then
    echo -e "${RED}❌ 错误: 无法从 $DEPLOYMENT_FILE 读取 FeeRouter 地址${NC}"
    exit 1
fi

echo "📋 从部署配置读取地址:"
echo "  Factory:   $FACTORY_ADDRESS"
echo "  FeeRouter: $FEE_ROUTER_ADDRESS"

# 备份原有的 subgraph.yaml
if [ -f "$SUBGRAPH_YAML" ]; then
    cp "$SUBGRAPH_YAML" "$SUBGRAPH_YAML.backup"
    echo -e "${GREEN}✅ 已备份原配置到 subgraph.yaml.backup${NC}"
fi

# 使用 sed 替换模板中的占位符
sed "s/{{FACTORY_ADDRESS}}/$FACTORY_ADDRESS/g; s/{{FEE_ROUTER_ADDRESS}}/$FEE_ROUTER_ADDRESS/g" \
    "$TEMPLATE_FILE" > "$SUBGRAPH_YAML"

echo -e "${GREEN}✅ Subgraph 配置已更新: $SUBGRAPH_YAML${NC}"

# 验证更新后的配置
UPDATED_FACTORY=$(grep -A 1 "name: MarketFactory" "$SUBGRAPH_YAML" | grep "address:" | sed 's/.*address: "\(.*\)"/\1/')
UPDATED_FEE_ROUTER=$(grep -A 1 "name: FeeRouter" "$SUBGRAPH_YAML" | grep "address:" | sed 's/.*address: "\(.*\)"/\1/')

if [ "$UPDATED_FACTORY" == "$FACTORY_ADDRESS" ] && [ "$UPDATED_FEE_ROUTER" == "$FEE_ROUTER_ADDRESS" ]; then
    echo -e "${GREEN}✅ 验证成功: 地址已正确更新${NC}"
else
    echo -e "${YELLOW}⚠️  警告: 地址验证失败，请手动检查${NC}"
fi
