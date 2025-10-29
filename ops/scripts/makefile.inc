up:
	docker compose -f infra/docker-compose.yml up -d
chain:
	anvil -p 8545 --block-time 1
contracts-deploy:
	forge script script/Deploy.s.sol:Deploy --rpc-url $$RPC_URL --broadcast -vvvv
backend:
	(cd backend && go run ./cmd/indexer &); (cd backend && go run ./cmd/keeper &); (cd backend && go run ./cmd/rewards &)
subgraph:
	(cd subgraph && echo "build placeholder")
