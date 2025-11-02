// Wagmi 配置
export { config, chains, type Config } from './wagmi';

// Providers
export { Providers } from './providers';

// Re-export wagmi hooks for convenience
export {
  useAccount,
  useConnect,
  useDisconnect,
  useBalance,
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
  useBlockNumber,
  useChainId,
  useSwitchChain,
} from 'wagmi';

// Re-export RainbowKit
export { ConnectButton } from '@rainbow-me/rainbowkit';

// GraphQL Client and Queries
export { graphqlClient } from './graphql';
export * from './graphql';

// Custom Hooks
export {
  useMarkets,
  useMarket,
  useUserPositions,
  useUserOrders,
  MarketStatus,
  type Market,
  type Position,
  type Order,
} from './hooks';
