import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: [
    "@pitchone/contracts",
    "@pitchone/ui",
    "@pitchone/web3",
    "@pitchone/utils",
  ],
  webpack: (config) => {
    config.externals.push("pino-pretty", "lokijs", "encoding");
    return config;
  },
  // 添加 rewrites 来代理 Subgraph 请求，解决 CORS 问题
  async rewrites() {
    const graphNodeUrl = process.env.GRAPH_NODE_URL || 'http://localhost:8010';
    return [
      {
        source: '/api/subgraph/:path*',
        destination: `${graphNodeUrl}/:path*`,
      },
    ];
  },
};

export default nextConfig;
