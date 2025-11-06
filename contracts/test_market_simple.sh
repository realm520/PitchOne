#!/bin/bash

# 简单的市场创建和下注测试
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Anvil默认账户
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
USER1_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
USER1_ADDR="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# 合约地址
FACTORY="0x87006e75a5B6bE9D1bbF61AC8Cd84f05D9140589"
USDC="0x139e1D41943ee15dDe4DF876f9d0E7F85e26660A"
VAULT="0xAdE429ba898c34722e722415D722A70a297cE3a2"

RPC="http://localhost:8545"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  简单市场测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查Factory中的市场数量
echo -e "${GREEN}检查已创建的市场...${NC}"
MARKET_COUNT=$(cast call $FACTORY "getMarketCount()(uint256)" --rpc-url $RPC)
echo "市场数量: $MARKET_COUNT"

if [ "$MARKET_COUNT" -gt "0" ]; then
    # 获取第一个市场地址
    MARKET=$(cast call $FACTORY "getMarket(uint256)(address)" 0 --rpc-url $RPC)
    echo "市场地址: $MARKET"

    # 检查市场状态
    STATUS=$(cast call $MARKET "status()(uint8)" --rpc-url $RPC)
    echo "市场状态: $STATUS (0=Open, 1=Locked, 2=Resolved, 3=Finalized)"

    if [ "$STATUS" -eq "0" ]; then
        echo ""
        echo -e "${GREEN}用户下注测试...${NC}"

        # 给USER1铸造USDC
        echo "给User1铸造USDC..."
        cast send $USDC "mint(address,uint256)" $USER1_ADDR "100000000000" \
            --private-key $DEPLOYER_KEY --rpc-url $RPC > /dev/null 2>&1

        BALANCE=$(cast call $USDC "balanceOf(address)(uint256)" $USER1_ADDR --rpc-url $RPC)
        echo "User1 USDC余额: $(cast --to-unit $BALANCE 6)"

        # User1授权市场
        echo "User1授权市场..."
        cast send $USDC "approve(address,uint256)" $MARKET "10000000000" \
            --private-key $USER1_KEY --rpc-url $RPC > /dev/null 2>&1

        # User1下注 (outcome 0, 1000 USDC)
        echo "User1下注1000 USDC在outcome 0..."
        cast send $MARKET "placeBet(uint256,uint256)" 0 "1000000000" \
            --private-key $USER1_KEY --rpc-url $RPC > /dev/null 2>&1

        echo ""
        echo -e "${GREEN}✓ 下注成功！${NC}"

        # 检查市场总流动性
        TOTAL_LIQ=$(cast call $MARKET "totalLiquidity()(uint256)" --rpc-url $RPC)
        echo "市场总流动性: $(cast --to-unit $TOTAL_LIQ 6) USDC"

        # 检查User1的头寸
        SHARES=$(cast call $MARKET "balanceOf(address,uint256)(uint256)" $USER1_ADDR 0 --rpc-url $RPC)
        echo "User1持有的shares: $(cast --to-unit $SHARES 6)"
    else
        echo "⚠ 市场已不是Open状态，无法下注"
    fi
else
    echo "⚠ 没有找到已部署的市场，请先运行DeployV2ToAnvil脚本"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  测试完成${NC}"
echo -e "${BLUE}========================================${NC}"
