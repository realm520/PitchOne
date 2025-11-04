import type { NextConfig } from "next";
import path from "path";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: [
    "@pitchone/contracts",
    "@pitchone/ui",
    "@pitchone/web3",
    "@pitchone/utils",
  ],
  // Turbopack 配置
  turbopack: {
    root: path.resolve(__dirname, "../../"),
  },
  // Webpack 配置（仅在非 Turbopack 模式下使用）
  webpack: (config) => {
    config.externals.push("pino-pretty", "lokijs", "encoding");
    return config;
  },
  // 添加 rewrites 来代理 Subgraph 请求，解决 CORS 问题
  async rewrites() {
    return [
      {
        source: '/api/subgraph/:path*',
        destination: 'http://localhost:8010/:path*',
      },
    ];
  },
};

export default nextConfig;
