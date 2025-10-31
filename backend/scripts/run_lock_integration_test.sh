#!/bin/bash

# Script to run Keeper lock integration test
# This script:
# 1. Ensures Anvil is running
# 2. Ensures database is accessible
# 3. Runs the integration test

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACTS_DIR="$PROJECT_ROOT/../contracts"

echo "======================================="
echo "Keeper Lock Integration Test Runner"
echo "======================================="

# Check if Anvil is running
echo "Checking if Anvil is running on port 8545..."
if ! curl -s -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
     http://localhost:8545 > /dev/null 2>&1; then
    echo "❌ Anvil is not running on port 8545"
    echo "   Please start Anvil first:"
    echo "   make chain (from project root)"
    echo "   OR"
    echo "   anvil (from terminal)"
    exit 1
fi
echo "✅ Anvil is running"

# Check if database is accessible
echo "Checking database connection..."
if ! psql "postgresql://p1:p1@localhost/p1?sslmode=disable" -c "SELECT 1" > /dev/null 2>&1; then
    echo "❌ Database is not accessible"
    echo "   Please ensure PostgreSQL is running and database 'p1' exists"
    echo "   Run: make up (from project root)"
    exit 1
fi
echo "✅ Database is accessible"

# Deploy default contracts if not already deployed
echo "Checking if default contracts are deployed..."
cd "$CONTRACTS_DIR"

# Check USDC contract
USDC_ADDR="0x36C02dA8a0983159322a80FFE9F24b1acfF8B570"
if ! cast code "$USDC_ADDR" --rpc-url http://localhost:8545 2>&1 | grep -q "0x"; then
    echo "Deploying default contracts..."
    forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast --silent || {
        echo "❌ Failed to deploy contracts"
        exit 1
    }
else
    echo "✅ Default contracts already deployed"
fi

# Run the integration test
echo ""
echo "======================================="
echo "Running TestIntegration_LockFlow"
echo "======================================="
cd "$PROJECT_ROOT"

go test -v -timeout 10m ./internal/keeper -run TestIntegration_LockFlow$ 2>&1 | tee /tmp/lock_integration_test.log

# Check test result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Integration test PASSED"
    exit 0
else
    echo ""
    echo "❌ Integration test FAILED"
    echo "Check /tmp/lock_integration_test.log for details"
    exit 1
fi
