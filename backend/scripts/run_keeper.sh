#!/bin/bash

# PitchOne Keeper Service Startup Script
# This script builds and runs the keeper service with proper environment setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${GREEN}=== PitchOne Keeper Service ===${NC}"
echo "Project root: $PROJECT_ROOT"

# Check if config file exists
if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    echo -e "${YELLOW}Warning: config.yaml not found. Copy config.example.yaml to config.yaml and fill in your values.${NC}"
    if [ ! -f "$PROJECT_ROOT/config.example.yaml" ]; then
        echo -e "${RED}Error: config.example.yaml also not found!${NC}"
        exit 1
    fi
    echo -e "${YELLOW}You can also use environment variables instead of config file.${NC}"
fi

# Check required environment variables if config file doesn't exist
if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    if [ -z "$SPORTSBOOK_KEEPER_PRIVATE_KEY" ]; then
        echo -e "${RED}Error: SPORTSBOOK_KEEPER_PRIVATE_KEY environment variable is required${NC}"
        exit 1
    fi
    if [ -z "$SPORTSBOOK_KEEPER_RPC_ENDPOINT" ]; then
        echo -e "${RED}Error: SPORTSBOOK_KEEPER_RPC_ENDPOINT environment variable is required${NC}"
        exit 1
    fi
    if [ -z "$SPORTSBOOK_KEEPER_DATABASE_URL" ]; then
        echo -e "${RED}Error: SPORTSBOOK_KEEPER_DATABASE_URL environment variable is required${NC}"
        exit 1
    fi
fi

# Build the keeper binary
echo -e "${GREEN}Building keeper...${NC}"
cd "$PROJECT_ROOT"
go build -o bin/keeper ./cmd/keeper

if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Run the keeper
echo -e "${GREEN}Starting keeper service...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""

./bin/keeper
