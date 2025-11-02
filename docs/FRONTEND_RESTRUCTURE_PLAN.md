# 前端目录重构方案

## 目标结构

```
PitchOne/
├── frontend/              # 前端 Monorepo（新增）
│   ├── apps/
│   │   ├── user/         # 用户端 Next.js 应用
│   │   └── admin/        # 管理端 Next.js 应用
│   ├── packages/
│   │   ├── ui/           # 共享组件库
│   │   ├── web3/         # Web3 hooks 和配置
│   │   ├── utils/        # 工具函数
│   │   └── contracts/    # 合约 ABI 和类型（从 contracts/ 构建产物复制）
│   ├── package.json
│   ├── pnpm-workspace.yaml
│   ├── pnpm-lock.yaml
│   ├── .gitignore        # 前端专用 gitignore
│   └── turbo.json        # Turborepo 配置（可选）
│
├── backend/              # Go 后端服务（保持不变）
├── contracts/            # Solidity 合约（保持不变）
├── subgraph/             # The Graph 索引器（保持不变）
├── docs/                 # 文档（保持不变）
├── ops/                  # 运维脚本（保持不变）
├── .gitignore            # 根 gitignore（更新）
└── README.md
```

## 优点

### 1. 清晰的关注点分离
- 前端开发者只需进入 `frontend/` 目录
- 后端开发者关注 `backend/`、`contracts/`
- 避免不同技术栈的 node_modules、build 产物混在一起

### 2. 更好的 CI/CD 配置
```yaml
# .github/workflows/frontend.yml
on:
  push:
    paths:
      - 'frontend/**'  # 只在前端代码变更时触发

# .github/workflows/backend.yml
on:
  push:
    paths:
      - 'backend/**'
      - 'contracts/**'
```

### 3. 独立的依赖管理
- `frontend/` 有自己的 package.json 和 pnpm-lock.yaml
- 根目录保持干净，只有项目级别的配置（如 docker-compose.yml）

### 4. 更快的构建
- 前端构建只需要 `frontend/` 目录
- Docker 镜像更小（multi-stage build 只复制需要的部分）

### 5. 团队协作友好
- 前端 PR 只影响 `frontend/` 目录
- 减少合并冲突（不同团队在不同目录工作）

## 迁移步骤

### Step 1: 创建 frontend 目录并移动文件
```bash
# 创建 frontend 目录
mkdir -p frontend

# 移动 apps 和 packages
mv apps frontend/
mv packages frontend/

# 移动前端配置文件
mv package.json frontend/
mv pnpm-workspace.yaml frontend/
mv pnpm-lock.yaml frontend/
```

### Step 2: 更新 frontend/pnpm-workspace.yaml
```yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

### Step 3: 创建 frontend/.gitignore
```gitignore
# Dependencies
node_modules/
pnpm-lock.yaml

# Build outputs
.next/
.turbo/
dist/
build/
out/

# Environment files
.env.local
.env.*.local

# Debug
npm-debug.log*
pnpm-debug.log*

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# TypeScript
*.tsbuildinfo
```

### Step 4: 更新根目录 .gitignore
```gitignore
# 前端（已在 frontend/.gitignore 中定义）
frontend/node_modules/
frontend/.next/
frontend/dist/
frontend/.turbo/

# Go build artifacts
backend/bin/
backend/indexer
backend/keeper
backend/rewards

# Forge build artifacts
contracts/out/
contracts/cache/
contracts/broadcast/

# Subgraph
subgraph/build/
subgraph/generated/
subgraph/node_modules/

# 通用忽略
.env
.env.*
!.env.example
*.log
.DS_Store
._*
```

### Step 5: 更新 package.json 脚本
```json
{
  "name": "pitchone-frontend",
  "private": true,
  "scripts": {
    "dev": "pnpm --parallel --filter @pitchone/user --filter @pitchone/admin dev",
    "dev:user": "pnpm --filter @pitchone/user dev",
    "dev:admin": "pnpm --filter @pitchone/admin dev",
    "build": "pnpm --filter @pitchone/user build && pnpm --filter @pitchone/admin build",
    "build:user": "pnpm --filter @pitchone/user build",
    "build:admin": "pnpm --filter @pitchone/admin build"
  }
}
```

### Step 6: 更新 README.md
在根目录 README.md 中添加：
```markdown
## 项目结构

- `frontend/` - Next.js 前端应用（用户端 + 管理端）
- `backend/` - Go 后端服务
- `contracts/` - Solidity 智能合约
- `subgraph/` - The Graph 数据索引
- `docs/` - 项目文档
```

### Step 7: 测试迁移
```bash
cd frontend
pnpm install
pnpm dev:user
# 验证 http://localhost:3000 可访问
```

## 替代方案：保持当前结构但优化

如果不想大改，可以：

1. **完善 .gitignore**
```gitignore
# 添加到根目录 .gitignore
node_modules/
.next/
apps/*/.next/
packages/*/dist/
*.tsbuildinfo
```

2. **添加前端专用 Makefile**
```makefile
# Makefile.frontend
.PHONY: frontend-install frontend-dev frontend-build

frontend-install:
	pnpm install

frontend-dev:
	pnpm dev

frontend-build:
	pnpm build
```

3. **CI/CD 使用路径过滤**
```yaml
paths:
  - 'apps/**'
  - 'packages/**'
  - 'pnpm-workspace.yaml'
```

## 推荐方案

**我强烈推荐迁移到独立的 `frontend/` 目录**，因为：
- 项目已经是多技术栈（Go + Solidity + TypeScript），分离更合理
- 未来可能还会添加移动端（React Native）、桌面端（Electron）等
- 便于使用 Turborepo、Nx 等 Monorepo 工具优化前端构建
- Docker 部署时可以分层构建，减少镜像体积

## 时间成本

- 迁移操作：15-20 分钟
- 测试验证：10 分钟
- 总计：30 分钟内完成
