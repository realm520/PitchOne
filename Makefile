# PitchOne 开发命令
# 使用: make <command>
# 查看所有命令: make help

.PHONY: help dev dev-frontend web status sync-remote-addresses \
        remote-pull remote-status remote-frontend remote-subgraph remote-contracts remote-full-reset

# 默认目标
help:
	@echo "PitchOne 开发命令"
	@echo ""
	@echo "本地开发:"
	@echo "  make dev              启动本地完整环境（Anvil + 前端）"
	@echo "  make dev-frontend     仅启动前端（本地模式）"
	@echo "  make web              启动前端（远程模式，连接 ngrok）"
	@echo ""
	@echo "远程操作（需要 SSH 权限）:"
	@echo "  make remote-status        查看服务器状态"
	@echo "  make remote-pull          拉取服务器代码"
	@echo "  make remote-frontend      更新前端（拉代码+构建+重启）"
	@echo "  make remote-subgraph      更新 Subgraph（拉代码+重建）"
	@echo "  make remote-contracts     重新部署合约"
	@echo "  make remote-full-reset    完整重置所有服务"
	@echo ""
	@echo "其他:"
	@echo "  make install              安装依赖"
	@echo "  make build                构建前端"
	@echo "  make sync-remote-addresses  同步远端合约地址到本地"
	@echo ""

# ===================
# 本地开发
# ===================

# 启动本地完整环境
dev:
	@echo "启动本地完整环境..."
	@cd contracts && (anvil --host 0.0.0.0 &) && sleep 3
	@cd frontend && pnpm dev

# 仅启动前端（本地模式）
dev-frontend:
	cd frontend && pnpm dev

# 启动前端（远程模式）
web:
	cd frontend && pnpm web

# 安装依赖
install:
	cd frontend && pnpm install

# 构建前端
build:
	cd frontend && pnpm build

# 同步远端合约地址到本地（用于本地连接远端 Anvil 开发）
sync-remote-addresses:
	@cd frontend && pnpm sync-remote

# ===================
# 远程操作
# ===================

# 查看服务器状态
remote-status:
	@./scripts/server-ops.sh status

# 拉取服务器代码
remote-pull:
	@./scripts/server-ops.sh pull

# 更新前端
remote-frontend:
	@./scripts/server-ops.sh frontend-update

# 更新 Subgraph
remote-subgraph:
	@./scripts/server-ops.sh subgraph-update

# 重新部署合约
remote-contracts:
	@./scripts/server-ops.sh contracts-deploy

# 完整重置
remote-full-reset:
	@./scripts/server-ops.sh full-reset
