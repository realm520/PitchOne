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
  useMarketOrders,
  useMarketAllOrders,
  MarketStatus,
  type Market,
  type Position,
  type Order,
} from './hooks';

// Contract Interaction Hooks (User)
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

// Contract Interaction Hooks (Admin)
export {
  useLockMarket,
  useCreateMarket,
  usePauseMarket,
  useParamControllerPropose,
  useParamControllerExecute,
  useParamControllerCancel,
  useParamProposal,
  useCreateCampaign,
  useCreateQuest,
  usePublishMerkleRoot,
} from './admin-hooks';

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
  useMarketOutcomes,
  type MarketFullData,
  type OutcomeData,
} from './multicall-hooks';
