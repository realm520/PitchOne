#!/bin/bash

# PitchOne Subgraph 测试查询脚本
# 用于验证 Subgraph 部署是否成功

GRAPHQL_ENDPOINT="http://localhost:8010/subgraphs/name/pitchone-local"

echo "========================================="
echo "PitchOne Subgraph 测试查询"
echo "========================================="
echo ""

# 1. 元数据查询
echo "1. 查询元数据 (_meta)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ _meta { block { number } hasIndexingErrors deployment } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 2. 全局统计
echo "2. 查询全局统计 (globalStats)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ globalStats(id: \"global\") { id totalMarkets totalVolume totalFees totalUsers } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 3. 市场列表
echo "3. 查询市场列表 (markets)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ markets(first: 10) { id matchId state totalVolume feeAccrued createdAt } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 4. 用户列表
echo "4. 查询用户列表 (users)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ users(first: 10) { id totalBetAmount firstSeenAt lastSeenAt } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 5. 订单列表
echo "5. 查询订单列表 (orders)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ orders(first: 10, orderBy: timestamp, orderDirection: desc) { id user amount outcome timestamp } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 6. 头寸列表
echo "6. 查询头寸列表 (positions)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ positions(first: 10, where: { balance_gt: \"0\" }) { id owner outcome balance market { id } } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 7. 预言机提案
echo "7. 查询预言机提案 (oracleProposals)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ oracleProposals(first: 10) { id proposer result disputed proposedAt } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

# 8. 费用分配
echo "8. 查询费用分配 (feeDistributions)..."
curl -s -X POST -H "Content-Type: application/json" \
  --data '{"query": "{ feeDistributions(first: 10, orderBy: timestamp, orderDirection: desc) { id recipient amount category timestamp } }"}' \
  $GRAPHQL_ENDPOINT | jq '.'
echo ""

echo "========================================="
echo "测试完成!"
echo "========================================="
