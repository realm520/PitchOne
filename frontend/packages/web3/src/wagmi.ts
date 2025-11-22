import { http, createConfig } from 'wagmi';
import { anvil, sepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// WalletConnect Project ID (需要从 https://cloud.walletconnect.com 获取)
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '2358a087a431594e05bce10f23628441';

// 配置支持的链
export const chains = [anvil, sepolia] as const;

// 根据环境决定 connectors（避免 SSR 时 WalletConnect 的 indexedDB 错误）
const getConnectors = () => {
  const connectors = [injected()];

  // 只在客户端添加 WalletConnect
  if (typeof window !== 'undefined') {
    connectors.push(walletConnect({ projectId }));
  }

  return connectors;
};

// Anvil RPC URL - 支持环境变量配置（用于 ngrok 等场景）
const anvilRpcUrl = process.env.NEXT_PUBLIC_ANVIL_RPC_URL || 'http://192.168.50.251:8545';

// 创建 wagmi 配置
export const config = createConfig({
  chains,
  connectors: getConnectors(),
  transports: {
    [anvil.id]: http(anvilRpcUrl),
    [sepolia.id]: http(),
  },
  ssr: false, // dApp 应用禁用 SSR（依赖客户端 Web3 provider）
});

// 导出类型
export type Config = typeof config;
