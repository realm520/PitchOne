# PitchOne Backend Dockerfile
# 多阶段构建，生成轻量级生产镜像
# 注意：从项目根目录构建，使用 backend/ 子目录

# ============================================
# Stage 1: Builder
# ============================================
FROM golang:1.24-alpine AS builder

# 安装必要的构建工具
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# 复制依赖文件并下载（利用 Docker 缓存）
COPY backend/go.mod backend/go.sum ./
RUN go mod download

# 复制源代码
COPY backend/ .

# 构建二进制文件
# -ldflags="-s -w" 去除调试信息，减小二进制体积
# CGO_ENABLED=0 禁用 CGO，生成静态链接的二进制
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X main.version=dev" \
    -o /bin/api ./cmd/api

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w -X main.version=dev" \
    -o /bin/keeper ./cmd/keeper

# ============================================
# Stage 2: Runtime
# ============================================
FROM alpine:3.19

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl

# 创建非 root 用户
RUN addgroup -g 1000 pitchone && \
    adduser -u 1000 -G pitchone -s /bin/sh -D pitchone

# 复制二进制文件
COPY --from=builder /bin/api /bin/api
COPY --from=builder /bin/keeper /bin/keeper

# 复制配置文件（可选，生产环境通过环境变量配置）
# COPY config.yaml /app/config.yaml

# 设置工作目录
WORKDIR /app

# 切换到非 root 用户
USER pitchone

# 设置时区
ENV TZ=UTC

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${API_PORT:-8080}/health || exit 1

# 暴露端口
EXPOSE 8080 9090

# 默认启动 API（通过 Railway startCommand 覆盖）
CMD ["/bin/api"]
