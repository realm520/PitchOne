# PitchOne VPS Docker 部署指南

本文档介绍如何在云 VPS 上部署 PitchOne 的后端服务（Backend + Subgraph + PostgreSQL）。

## 服务架构

```
                    ┌─────────────────────────────────────────────────────┐
                    │                      VPS                              │
                    │                                                       │
    Internet ──────►│  ┌─────────┐                                         │
                    │  │  Nginx  │ :80/:443                                │
                    │  └────┬────┘                                         │
                    │       │                                               │
                    │  ┌────┴────┬────────────────┐                        │
                    │  │         │                 │                        │
                    │  ▼         ▼                 ▼                        │
                    │ /api/*  /subgraphs/*     /ws/*                       │
                    │  │         │                 │                        │
                    │  ▼         ▼                 ▼                        │
                    │ ┌────────┐ ┌──────────┐  ┌──────────┐                │
                    │ │Backend │ │Graph Node│  │Graph Node│                │
                    │ │  API   │ │  (HTTP)  │  │   (WS)   │                │
                    │ └───┬────┘ └────┬─────┘  └────┬─────┘                │
                    │     │           │              │                      │
                    │     ▼           ▼              │                      │
                    │ ┌────────┐ ┌────────┐         │                      │
                    │ │Postgres│ │Graph PG│◄────────┘                      │
                    │ └────────┘ └───┬────┘                                │
                    │                │                                      │
                    │                ▼                                      │
                    │            ┌──────┐                                  │
                    │            │ IPFS │                                  │
                    │            └──────┘                                  │
                    │                                                       │
                    │ ┌────────┐                                           │
                    │ │Keeper  │ (后台任务)                                │
                    │ └────────┘                                           │
                    └─────────────────────────────────────────────────────┘
```

## 快速开始

### 1. 准备 VPS

**最低配置要求**：
- CPU: 2 核
- 内存: 4 GB（推荐 8 GB）
- 存储: 40 GB SSD
- 操作系统: Ubuntu 22.04 LTS

**推荐云服务商**：
- AWS Lightsail / EC2
- DigitalOcean
- Vultr
- Linode
- 阿里云 / 腾讯云

### 2. 初始化 VPS

SSH 登录到 VPS 后执行：

```bash
# 下载并执行初始化脚本
curl -fsSL https://raw.githubusercontent.com/your-repo/PitchOne/main/deploy/scripts/init-vps.sh | sudo bash

# 或者手动执行
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-plugin git
sudo systemctl enable docker
sudo systemctl start docker
```

### 3. 克隆项目

```bash
# 进入项目目录
cd /opt/pitchone

# 克隆代码
git clone https://github.com/your-repo/PitchOne.git .
```

### 4. 配置环境变量

```bash
# 复制环境变量模板
cp .env.prod.example .env.prod

# 编辑配置（必须填写所有 REQUIRED 项）
vim .env.prod
```

**必须配置的变量**：

| 变量 | 说明 | 示例 |
|------|------|------|
| `POSTGRES_PASSWORD` | Backend 数据库密码 | `your_secure_password` |
| `GRAPH_POSTGRES_PASSWORD` | Graph Node 数据库密码 | `another_password` |
| `ETHEREUM_RPC_URL` | 区块链 RPC 端点 | `https://base-sepolia.g.alchemy.com/v2/xxx` |
| `KEEPER_PRIVATE_KEY` | Keeper 操作者私钥 | `0x...` |
| `FACTORY_ADDRESS` | 已部署的 Factory 合约地址 | `0x...` |

### 5. 启动服务

```bash
# 使用部署脚本
./deploy/scripts/deploy.sh

# 或手动启动
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

### 6. 部署 Subgraph

服务启动后，需要单独部署 Subgraph：

```bash
# 进入 subgraph 目录
cd subgraph

# 更新 subgraph.yaml 中的合约地址
# 确保 Factory 和 FeeRouter 地址正确

# 部署
./deploy/scripts/deploy.sh --subgraph
```

### 7. 验证部署

```bash
# 健康检查
./deploy/scripts/deploy.sh --health

# 查看服务状态
./deploy/scripts/deploy.sh --status

# 测试 API
curl http://localhost/api/health

# 测试 GraphQL
curl -X POST \
  -H "Content-Type: application/json" \
  --data '{"query": "{ markets { id status } }"}' \
  http://localhost/subgraphs/name/pitchone-sportsbook
```

## SSL 证书配置

### 使用 Let's Encrypt（推荐）

```bash
# 1. 停止 Nginx（释放 80 端口）
docker compose -f docker-compose.prod.yml stop nginx

# 2. 获取证书
sudo certbot certonly --standalone -d your-domain.com

# 3. 复制证书
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem deploy/nginx/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem deploy/nginx/ssl/

# 4. 启用 HTTPS 配置
vim deploy/nginx/conf.d/default.conf
# 取消 HTTPS server 块的注释

# 5. 重启 Nginx
docker compose -f docker-compose.prod.yml up -d nginx
```

### 自动续期

```bash
# 添加 cron 任务
sudo crontab -e

# 添加以下行（每月 1 号凌晨 3 点续期）
0 3 1 * * certbot renew --quiet && docker compose -f /opt/pitchone/docker-compose.prod.yml restart nginx
```

## 运维命令

### 查看日志

```bash
# 所有服务日志
docker compose -f docker-compose.prod.yml logs -f

# 特定服务日志
docker compose -f docker-compose.prod.yml logs -f backend-api
docker compose -f docker-compose.prod.yml logs -f graph-node
docker compose -f docker-compose.prod.yml logs -f backend-keeper
```

### 重启服务

```bash
# 重启所有服务
docker compose -f docker-compose.prod.yml restart

# 重启特定服务
docker compose -f docker-compose.prod.yml restart backend-api
```

### 更新部署

```bash
# 拉取最新代码并重新部署
./deploy/scripts/deploy.sh --pull

# 强制重新构建镜像
./deploy/scripts/deploy.sh --rebuild
```

### 数据备份

```bash
# 备份 PostgreSQL
docker exec pitchone-postgres pg_dump -U pitchone pitchone > backup_$(date +%Y%m%d).sql

# 备份 Graph Node 数据库
docker exec pitchone-graph-postgres pg_dump -U graph-node graph-node > graph_backup_$(date +%Y%m%d).sql
```

### 清理数据（谨慎操作）

```bash
# 停止服务
docker compose -f docker-compose.prod.yml down

# 删除所有数据卷（会丢失所有数据！）
docker compose -f docker-compose.prod.yml down -v

# 重新启动
docker compose -f docker-compose.prod.yml up -d
```

## 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 80 | Nginx | HTTP 入口 |
| 443 | Nginx | HTTPS 入口 |
| 8080 | Backend API | 内部 API 端口 |
| 8081 | Backend Keeper | Keeper 健康检查 |
| 9090 | Backend Keeper | Prometheus 指标 |
| 8000 | Graph Node | GraphQL HTTP |
| 8001 | Graph Node | GraphQL WebSocket |
| 8020 | Graph Node | Admin API |
| 8030 | Graph Node | 索引状态 |

## API 端点

### 公开端点

| 路径 | 说明 |
|------|------|
| `/api/*` | Backend API |
| `/subgraphs/name/pitchone-sportsbook` | GraphQL 查询 |
| `/ws/*` | GraphQL 订阅（WebSocket）|
| `/health` | 健康检查 |

### 管理端点（需要限制访问）

| 路径 | 说明 |
|------|------|
| `/graph-admin/*` | Graph Node 管理 |
| `/graph-status/*` | 索引状态 |

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker compose -f docker-compose.prod.yml logs --tail=100

# 检查容器状态
docker ps -a

# 检查端口占用
sudo netstat -tlnp | grep -E '80|443|8080'
```

### Graph Node 无法连接 RPC

1. 检查 `ETHEREUM_RPC_URL` 是否正确
2. 确认 RPC 端点可访问：
   ```bash
   curl -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
     YOUR_RPC_URL
   ```

### Subgraph 索引失败

```bash
# 查看索引状态
curl http://localhost/graph-status/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ indexingStatusForCurrentVersion(subgraphName: \"pitchone-sportsbook\") { synced health fatalError { message } } }"}'
```

### 数据库连接失败

```bash
# 检查数据库是否运行
docker exec pitchone-postgres pg_isready -U pitchone

# 手动连接测试
docker exec -it pitchone-postgres psql -U pitchone -d pitchone
```

## 监控建议

### 基础监控

- 使用 `htop` 监控 CPU/内存
- 使用 `docker stats` 监控容器资源

### 进阶监控

推荐部署 Prometheus + Grafana 监控栈：

```yaml
# 可选：添加到 docker-compose.prod.yml
prometheus:
  image: prom/prometheus
  volumes:
    - ./deploy/prometheus:/etc/prometheus
  ports:
    - "9091:9090"

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
```

## 安全建议

1. **防火墙**：仅开放 80/443 端口
2. **SSH**：禁用密码登录，仅使用密钥
3. **定期更新**：定期更新系统和 Docker 镜像
4. **备份**：设置自动备份策略
5. **监控**：设置告警通知
6. **限制管理端点**：在 Nginx 配置中限制 `/graph-admin/*` 的访问 IP
