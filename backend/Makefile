.PHONY: help build test run-indexer run-keeper run-rewards db-migrate db-rollback generate-bindings

help:
	@echo "PitchOne Backend Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  generate-bindings - Generate Go bindings from contract ABIs"
	@echo "  build            - Build all binaries"
	@echo "  test             - Run tests"
	@echo "  run-indexer      - Run Indexer service"
	@echo "  run-keeper       - Run Keeper service"
	@echo "  run-rewards      - Run Rewards service"
	@echo "  db-migrate       - Apply database migrations"
	@echo "  db-rollback      - Rollback last migration"

build:
	@echo "Building binaries..."
	@mkdir -p bin
	@go build -o bin/indexer ./cmd/indexer
	@go build -o bin/keeper ./cmd/keeper
	@go build -o bin/rewards ./cmd/rewards
	@echo "Build complete: bin/"

test:
	@echo "Running tests..."
	@go test ./... -v

run-indexer:
	@echo "Starting Indexer..."
	@go run ./cmd/indexer

run-keeper:
	@echo "Starting Keeper..."
	@go run ./cmd/keeper

run-rewards:
	@echo "Starting Rewards Builder..."
	@go run ./cmd/rewards

db-migrate:
	@echo "Applying database migrations..."
	@psql -U p1 -d p1 -f pkg/db/migrations/001_initial_schema.up.sql
	@echo "Migration complete"

db-rollback:
	@echo "Rolling back last migration..."
	@psql -U p1 -d p1 -f pkg/db/migrations/001_initial_schema.down.sql
	@echo "Rollback complete"

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
