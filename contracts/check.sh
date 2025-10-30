#!/bin/bash
# PitchOne Week 1-2 验证脚本
# 用途: 快速验证所有交付物是否完整

set -e

echo "🔍 PitchOne Week 1-2 交付物验证"
echo "================================"
echo ""

# 检查 Foundry 安装
echo "✓ 检查 Foundry 工具链..."
if ! command -v forge &> /dev/null; then
    echo "❌ Forge 未安装，请运行: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi
echo "  Forge 版本: $(forge --version | head -n 1)"
echo ""

# 检查核心合约
echo "✓ 检查核心合约..."
contracts=(
    "src/core/MarketBase.sol"
    "src/core/FeeRouter.sol"
    "src/templates/WDL_Template.sol"
    "src/pricing/SimpleCPMM.sol"
)
for contract in "${contracts[@]}"; do
    if [ -f "$contract" ]; then
        echo "  ✓ $contract"
    else
        echo "  ❌ $contract 缺失"
        exit 1
    fi
done
echo ""

# 检查测试文件
echo "✓ 检查测试文件..."
tests=(
    "test/unit/SimpleCPMM.t.sol"
    "test/unit/WDL_Template.t.sol"
)
for test in "${tests[@]}"; do
    if [ -f "$test" ]; then
        echo "  ✓ $test"
    else
        echo "  ❌ $test 缺失"
        exit 1
    fi
done
echo ""

# 检查脚本
echo "✓ 检查部署脚本..."
scripts=(
    "script/Deploy.s.sol"
    "script/DemoFlow.s.sol"
    "script/README.md"
)
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✓ $script"
    else
        echo "  ❌ $script 缺失"
        exit 1
    fi
done
echo ""

# 检查文档
echo "✓ 检查文档..."
docs=(
    "SECURITY_AUDIT.md"
    "../docs/progress.md"
)
for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✓ $doc"
    else
        echo "  ❌ $doc 缺失"
        exit 1
    fi
done
echo ""

# 编译测试
echo "✓ 编译合约..."
if forge build > /dev/null 2>&1; then
    echo "  ✓ 编译成功"
else
    echo "  ❌ 编译失败，请运行 forge build 查看详情"
    exit 1
fi
echo ""

# 运行测试
echo "✓ 运行测试..."
test_output=$(forge test 2>&1)
if echo "$test_output" | grep -q "74 tests passed"; then
    echo "  ✓ 74 tests passed"
else
    echo "  ❌ 测试失败"
    echo "$test_output"
    exit 1
fi
echo ""

# 检查覆盖率（可选，因为需要 lcov）
if command -v lcov &> /dev/null; then
    echo "✓ 检查测试覆盖率..."
    coverage=$(forge coverage --report summary 2>&1 | grep "| Total" | awk '{print $4}')
    if [ ! -z "$coverage" ]; then
        echo "  ✓ 总覆盖率: $coverage"
    fi
    echo ""
fi

# 最终状态
echo "================================"
echo "🎉 Week 1-2 交付物验证通过！"
echo ""
echo "📊 统计:"
echo "  - 核心合约: ${#contracts[@]}"
echo "  - 测试文件: ${#tests[@]}"
echo "  - 部署脚本: ${#scripts[@]}"
echo "  - 文档: ${#docs[@]}"
echo "  - 测试通过: 74/74"
echo ""
echo "📝 下一步:"
echo "  1. 本地测试: anvil & forge script script/DemoFlow.s.sol:DemoFlow --rpc-url http://localhost:8545 --broadcast -vvvv"
echo "  2. 测试网部署: forge script script/Deploy.s.sol:Deploy --rpc-url \$RPC_URL --broadcast -vvvv"
echo "  3. 开始 Week 3-4: 预言机与结算模块"
echo ""
