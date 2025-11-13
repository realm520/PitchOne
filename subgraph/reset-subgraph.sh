#!/bin/bash

# 重置和重新部署 Subgraph

set -e

echo "========================================"
echo "  Subgraph 重置和重新部署"
echo "========================================"
echo ""

cd /home/harry/code/PitchOne/subgraph

# 1. 停止并清理 Graph Node
echo "1. 清理 Graph Node..."
docker-compose down -v
sleep 2
echo "  ✅ 清理完成"
echo ""

# 2. 启动 Graph Node
echo "2. 启动 Graph Node..."
docker-compose up -d
echo "  ⏳ 等待服务启动..."
sleep 15
echo "  ✅ Graph Node 已启动"
echo ""

# 3. 重新生成代码
echo "3. 生成 Subgraph 代码..."
graph codegen
graph build
echo "  ✅ 代码生成完成"
echo ""

# 4. 创建和部署 Subgraph
echo "4. 部署 Subgraph..."
graph create --node http://localhost:8020/ sportsbook-local 2>/dev/null || echo "  ⚠️  Subgraph 已存在，跳过创建"
graph deploy --node http://localhost:8020/ --ipfs http://localhost:5001 sportsbook-local
echo "  ✅ Subgraph 部署完成"
echo ""

echo "========================================"
echo "  Subgraph 信息"
echo "========================================"
echo "  GraphQL: http://localhost:8000/subgraphs/name/sportsbook-local"
echo "  GraphiQL: http://localhost:8000/subgraphs/name/sportsbook-local/graphql"
echo ""
echo "测试查询："
echo "  curl -X POST -H 'Content-Type: application/json' \\"
echo "    http://localhost:8000/subgraphs/name/sportsbook-local/graphql \\"
echo "    -d '{\"query\": \"{markets { id status }}\"}'  "
echo ""
