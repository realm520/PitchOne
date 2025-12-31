.PHONY: help build build-cli build-api test run-keeper run-rewards run-api run-cli db-init generate-bindings

help:
	@echo "PitchOne Backend Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  generate-bindings - Generate Go bindings from contract ABIs"
	@echo "  build            - Build all binaries"
	@echo "  build-cli        - Build CLI tool only"
	@echo "  build-api        - Build API server only"
	@echo "  test             - Run tests"
	@echo "  run-keeper       - Run Keeper service"
	@echo "  run-rewards      - Run Rewards CLI tool"
	@echo "  run-api          - Run API server"
	@echo "  run-cli          - Run CLI tool (use ARGS for arguments)"
	@echo "  db-init          - Initialize database schema"

build:
	@echo "Building binaries..."
	@mkdir -p bin
	@go build -o bin/keeper ./cmd/keeper
	@go build -o bin/rewards ./cmd/rewards
	@go build -o bin/api ./cmd/api
	@go build -o bin/p1cli ./cmd/cli
	@echo "Build complete: bin/"

build-cli:
	@echo "Building CLI..."
	@mkdir -p bin
	@go build -o bin/p1cli ./cmd/cli
	@echo "CLI built: bin/p1cli"

build-api:
	@echo "Building API server..."
	@mkdir -p bin
	@go build -o bin/api ./cmd/api
	@echo "API server built: bin/api"

run-api:
	@echo "Starting API server..."
	@go run ./cmd/api

run-cli:
	@go run ./cmd/cli $(ARGS)

test:
	@echo "Running tests..."
	@go test ./... -v

run-keeper:
	@echo "Starting Keeper..."
	@go run ./cmd/keeper

run-rewards:
	@echo "Running Rewards CLI..."
	@go run ./cmd/rewards $(ARGS)

db-init:
	@echo "Initializing database..."
	@psql $(DATABASE_URL) -f pkg/db/init.sql
	@echo "Database initialized"

generate-bindings:
	@echo "Generating Go bindings from contract ABIs..."
	@mkdir -p pkg/bindings
	@jq '.abi' ../contracts/out/MarketBase.sol/MarketBase.json > /tmp/MarketBase.abi
	@abigen --abi /tmp/MarketBase.abi --pkg bindings --type MarketBase --out pkg/bindings/market_base.go
	@jq '.abi' ../contracts/out/WDL_Template.sol/WDL_Template.json > /tmp/WDL_Template.abi
	@jq -r '.bytecode.object' ../contracts/out/WDL_Template.sol/WDL_Template.json > /tmp/WDL_Template.bin
	@abigen --abi /tmp/WDL_Template.abi --bin /tmp/WDL_Template.bin --pkg bindings --type WDLTemplate --out pkg/bindings/wdl_template.go
	@jq '.abi' ../contracts/out/MockOracle.sol/MockOracle.json > /tmp/MockOracle.abi
	@jq -r '.bytecode.object' ../contracts/out/MockOracle.sol/MockOracle.json > /tmp/MockOracle.bin
	@abigen --abi /tmp/MockOracle.abi --bin /tmp/MockOracle.bin --pkg bindings --type MockOracle --out pkg/bindings/mock_oracle.go
	@echo "Bindings generated: pkg/bindings/"
	@ls -lh pkg/bindings/*.go
