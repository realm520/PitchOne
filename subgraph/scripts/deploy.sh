#!/bin/bash

# 自动部署 Subgraph 到本地 Graph Node

set -e

cd "$(dirname "$0")/.."

echo "开始部署 PitchOne Subgraph..."

# 运行 codegen
echo "1. 运行 codegen..."
npm run codegen

# 构建
echo "2. 构建 Subgraph..."
npm run build

# 部署（使用自动版本号）
echo "3. 部署到本地 Graph Node..."
echo "v0.1.0" | npm run deploy-local

echo "✓ 部署完成!"
echo ""
echo "GraphQL Endpoint: http://localhost:8000/subgraphs/name/pitchone-local"
