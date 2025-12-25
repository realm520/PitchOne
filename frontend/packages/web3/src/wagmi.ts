import { http, createConfig, type CreateConnectorFn } from 'wagmi';
import { anvil, sepolia } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

// WalletConnect Project ID (需要从 https://cloud.walletconnect.com 获取)
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '2358a087a431594e05bce10f23628441';

// 配置支持的链
export const chains = [anvil, sepolia] as const;

// 根据环境决定 connectors（避免 SSR 时 WalletConnect 的 indexedDB 错误）
const getConnectors = (): CreateConnectorFn[] => {
  const connectors: CreateConnectorFn[] = [injected()];

  // 只在客户端添加 WalletConnect
  if (typeof window !== 'undefined') {
    connectors.push(walletConnect({ projectId }) as CreateConnectorFn);
  }

  return connectors;
};

// 获取 Anvil RPC URL（支持运行时配置）
function getAnvilRpcUrl(): string {
  // 优先使用环境变量（用于服务端或明确配置）
  if (process.env.NEXT_PUBLIC_ANVIL_RPC_URL) {
    return process.env.NEXT_PUBLIC_ANVIL_RPC_URL;
  }

  // 浏览器环境：使用代理路径（类似 Subgraph）
  if (typeof window !== 'undefined') {
    return `${window.location.origin}/api/rpc`;
  }

  // 服务端环境：直接访问
  return 'http://localhost:8545';
}

const anvilRpcUrl = getAnvilRpcUrl();

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
