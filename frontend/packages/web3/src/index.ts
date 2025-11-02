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

// Contract Interaction Hooks
export {
  useApproveUSDC,
  useUSDCAllowance,
  useUSDCBalance,
  usePlaceBet,
  useRedeem,
  usePositionBalance,
  useMarketStatus,
  useOutcomeCount,
  useOutcomeLiquidity,
} from './contract-hooks';

// Event Listening Hooks
export {
  useWatchBetPlaced,
  useWatchMarketLocked,
  useWatchResultProposed,
  useWatchPositionRedeemed,
  useMarketEvents,
  useAutoRefresh,
  type BetPlacedEvent,
  type MarketLockedEvent,
  type ResultProposedEvent,
  type PositionRedeemedEvent,
} from './event-hooks';

// Multicall Optimization Hooks
export {
  useMarketFullData,
  useMultipleMarketsData,
  useUserUSDCDataForMarkets,
  type MarketFullData,
} from './multicall-hooks';
