# PitchOne 团队开发指南

## 环境说明

- **后端开发者**：本地运行完整环境（Anvil + Docker + 后端服务）
- **前端开发者**：本地仅运行前端，连接远程服务

**远程服务器**：
- 地址：42.60.109.87
- SSH 端口：10021
- 用户：harry

---

## 快速开始

### 前端开发者

```bash
# 1. 首次设置
cd frontend
cp .env.remote.example .env.remote
# 编辑 .env.remote，填入 ngrok URL（找后端要）

# 2. 安装依赖
pnpm install

# 3. 启动开发（连接远程服务）
pnpm web

# 4. 修改了 subgraph 或合约后
git push origin main
make remote-subgraph   # 触发服务器更新
```

### 后端开发者

```bash
# 启动本地完整环境
make dev

# 查看服务器状态
make remote-status
```

---

## 命令速查表

### 本地开发命令

| 命令 | 说明 | 适用角色 |
|------|------|----------|
| `make dev` | 启动本地完整环境（Anvil + 前端） | 后端 |
| `make web` | 启动前端（连接远程服务） | 前端 |
| `pnpm dev` | 启动前端（连接本地服务） | 后端 |
| `pnpm web` | 启动前端（连接远程服务） | 前端 |
| `pnpm web:user` | 仅启动 user 应用（远程模式） | 前端 |
| `pnpm web:admin` | 仅启动 admin 应用（远程模式） | 前端 |

### 远程操作命令

| 命令 | 说明 |
|------|------|
| `make remote-status` | 查看服务器所有服务状态 |
| `make remote-pull` | 拉取服务器最新代码 |
| `make remote-frontend` | 更新前端（拉代码+构建+重启） |
| `make remote-subgraph` | 更新 Subgraph（拉代码+重建） |
| `make remote-contracts` | 重新部署合约 |
| `make remote-full-reset` | 完整重置所有服务 |

### 服务器脚本（直接调用）

```bash
./scripts/server-ops.sh <command>
```

| 命令 | 说明 |
|------|------|
| `pull` | 拉取最新代码 |
| `frontend-build` | 构建前端 |
| `frontend-restart` | 重启前端（PM2） |
| `subgraph-rebuild` | 重建 Subgraph |
| `contracts-deploy` | 部署合约 |
| `anvil-restart` | 重启 Anvil |
| `ngrok-restart` | 重启 ngrok 隧道 |
| `status` | 查看服务状态 |
| `frontend-update` | 拉代码 + 构建 + 重启前端 |
| `subgraph-update` | 拉代码 + 重建 Subgraph |
| `full-reset` | 完整重置所有服务 |

---

## 环境变量说明

### 远程开发模式 (.env.remote)

位置：`frontend/.env.remote`

```bash
# Anvil RPC（ngrok 隧道 URL）
NEXT_PUBLIC_ANVIL_RPC_URL=https://xxx.ngrok-free.app

# Subgraph GraphQL（ngrok 或直接 IP）
NEXT_PUBLIC_SUBGRAPH_URL=https://xxx.ngrok-free.app
# 或
NEXT_PUBLIC_SUBGRAPH_URL=http://42.60.109.87:8010/subgraphs/name/pitchone-sportsbook

# API 代理目标（服务端环境变量）
GRAPH_NODE_URL=http://42.60.109.87:8010/subgraphs/name/pitchone-sportsbook
```

---

## ngrok URL 获取

**方式 1**：访问服务器 ngrok 控制台
```
http://42.60.109.87:4040
```

**方式 2**：SSH 登录后执行
```bash
curl http://localhost:4040/api/tunnels
```

**方式 3**：使用运维脚本
```bash
make remote-status
```

**当前隧道**：
- `user-app` → 端口 3000（前端用户端）
- `admin-app` → 端口 3001（前端管理端）
- `anvil-rpc` → 端口 8545（区块链 RPC）
- `subgraph` → 端口 8010（GraphQL API）

---

## 典型工作流程

### 场景 1：前端日常开发

```bash
# 1. 拉取最新代码
git pull origin main

# 2. 启动开发（连接远程服务）
pnpm web

# 3. 开发完成后提交
git add . && git commit -m "feat: xxx"
git push origin main
```

### 场景 2：修改了 Subgraph Schema

```bash
# 1. 修改 subgraph/schema.graphql 等文件
# 2. 提交代码
git add . && git commit -m "feat(subgraph): update schema"
git push origin main

# 3. 触发服务器更新
make remote-subgraph

# 4. 等待更新完成，然后刷新前端查看效果
```

### 场景 3：修改了智能合约

```bash
# 1. 修改 contracts/src/*.sol 等文件
# 2. 本地测试
cd contracts && forge test

# 3. 提交代码
git add . && git commit -m "feat(contracts): xxx"
git push origin main

# 4. 完整重置服务器（重新部署合约 + Subgraph）
make remote-full-reset
```

### 场景 4：服务器服务异常

```bash
# 查看状态
make remote-status

# 针对性重启
make remote-frontend    # 仅前端
# 或
make remote-subgraph    # 仅 Subgraph
# 或
make remote-full-reset  # 完整重置
```

---

## 常见问题

### Q: 钱包能连接但没有数据？

**原因**：Subgraph URL 配置错误

**解决**：
1. 检查 `.env.remote` 中的 `NEXT_PUBLIC_SUBGRAPH_URL` 是否正确
2. 确认服务器上 Subgraph 正在运行：`make remote-status`
3. 如果 8010 端口不可达，使用 ngrok 隧道 URL

### Q: ngrok URL 失效了？

**原因**：ngrok 重启后 URL 会变化

**解决**：
1. 执行 `make remote-status` 查看新 URL
2. 或访问 `http://42.60.109.87:4040` 查看 ngrok 控制台
3. 更新 `.env.remote` 中的 URL

### Q: 修改了合约/subgraph 代码怎么更新？

```bash
# 1. 提交代码
git push origin main

# 2. 触发更新
make remote-subgraph   # Subgraph 更新
# 或
make remote-contracts  # 合约重新部署
# 或
make remote-full-reset # 完整重置
```

### Q: 服务器上的服务挂了？

```bash
# 查看状态
make remote-status

# 完整重置
make remote-full-reset

# 或针对性重启
./scripts/server-ops.sh anvil-restart     # 重启 Anvil
./scripts/server-ops.sh frontend-restart  # 重启前端
./scripts/server-ops.sh ngrok-restart     # 重启 ngrok
```

### Q: 如何查看服务器日志？

```bash
# SSH 登录服务器
ssh -p 10021 harry@42.60.109.87

# 查看 PM2 日志
pm2 logs

# 查看 Anvil 日志
tail -f /tmp/anvil.log

# 查看 Docker 日志
docker logs -f graph-node
```

---

## 服务器架构

```
┌─────────────────────────────────────────────────────────┐
│                    PitchOne Server                      │
│                   42.60.109.87:10021                    │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
    ┌───▼────┐         ┌────▼────┐        ┌────▼─────┐
    │ Anvil  │         │ Frontend │       │ Subgraph  │
    │ :8545  │         │:3000/3001│       │  :8010    │
    └────────┘         └─────────┘        └───────────┘
                                                │
                                          ┌─────▼──────┐
                                          │Docker Stack│
                                          │ Graph Node │
                                          │ PostgreSQL │
                                          │    IPFS    │
                                          └────────────┘

    ┌─ ngrok 隧道 ────────────────────────────┐
    │ :3000 → user-app.ngrok-free.app         │
    │ :3001 → admin-app.ngrok-free.app        │
    │ :8545 → anvil-rpc.ngrok-free.app        │
    │ :8010 → subgraph.ngrok-free.app         │
    └─────────────────────────────────────────┘
```

---

## SSH 免密配置

为了使用远程命令，需要配置 SSH 免密登录：

```bash
# 1. 生成 SSH 密钥（如果没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 复制公钥到服务器
ssh-copy-id -p 10021 harry@42.60.109.87

# 3. 测试连接
ssh -p 10021 harry@42.60.109.87 "echo 'SSH OK'"
```

---

## 文件结构

```
PitchOne/
├── frontend/
│   ├── .env.remote.example    # 远程开发环境变量模板
│   ├── .env.remote            # 远程开发环境变量（需创建）
│   └── package.json           # 包含 web 命令
├── scripts/
│   └── server-ops.sh          # 服务器运维脚本
├── Makefile                   # 顶级 Make 命令
├── ecosystem.config.js        # PM2 配置
├── ngrok.yml                  # ngrok 隧道配置
└── docs/
    └── DEVELOPMENT_GUIDE.md   # 本文档
```
