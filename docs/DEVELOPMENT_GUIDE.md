# PitchOne 团队开发指南

## 角色分工

- **后端开发**：本地完整环境（Anvil + Docker + 后端）
- **前端开发**：本地前端 + 远程服务

## 快速开始

### 前端开发者

```bash
cd frontend
pnpm install
pnpm web    # 启动（连远程服务）
```

### 后端开发者

```bash
make dev            # 本地完整环境
make remote-status  # 查看服务器状态
```

## 命令速查

### 本地

| 命令 | 说明 |
|------|------|
| `pnpm dev` | 前端（连本地） |
| `pnpm web` | 前端（连远程） |
| `make dev` | 完整环境 |

### 远程

| 命令 | 说明 |
|------|------|
| `make remote-status` | 查看状态 |
| `make remote-frontend` | 更新前端 |
| `make remote-subgraph` | 更新 Subgraph |
| `make remote-contracts` | 部署合约 |
| `make remote-full-reset` | 完整重置 |

## 固定域名

| 服务 | 域名 |
|------|------|
| 用户端 | https://pitchone-user.ngrok-free.app |
| 管理后台 | https://pitchone-admin.ngrok-free.app |
| Anvil RPC | https://pitchone-rpc.ngrok-free.app |
| Subgraph | https://pitchone-graph.ngrok-free.app |

## 环境变量 (.env.web)

```bash
NEXT_PUBLIC_ANVIL_RPC_URL=https://pitchone-rpc.ngrok-free.app
NEXT_PUBLIC_SUBGRAPH_URL=https://pitchone-graph.ngrok-free.app/subgraphs/name/pitchone-sportsbook
```

## 常见问题

**Q: 没数据？** → 检查 `.env.web` 的 URL

**Q: 改了合约/subgraph？** → `git push` 后执行 `make remote-subgraph`

**Q: 服务挂了？** → `make remote-full-reset`
