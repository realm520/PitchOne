import { http, createConfig } from 'wagmi';
import { anvil, sepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// WalletConnect Project ID (需要从 https://cloud.walletconnect.com 获取)
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

// 配置支持的链
export const chains = [anvil, sepolia] as const;

// 创建 wagmi 配置
export const config = createConfig({
  chains,
  connectors: [
    injected(),
    walletConnect({ projectId }),
  ],
  transports: {
    [anvil.id]: http('http://127.0.0.1:8545'),
    [sepolia.id]: http(),
  },
  ssr: true, // 支持 Next.js SSR
});

// 导出类型
export type Config = typeof config;
