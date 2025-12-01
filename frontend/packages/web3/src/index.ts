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

// Constants (Decimals)
export {
  TOKEN_DECIMALS,
  BUSINESS_DECIMALS,
  USDC_SCALE,
  formatUSDCFromWei,
} from './constants';

// Outcome Constants
export {
  WDL_OUTCOMES,
  WDL_OUTCOME_NAMES,
  OU_OUTCOMES,
  OU_OUTCOME_NAMES,
  AH_OUTCOMES,
  AH_OUTCOME_NAMES,
  ODDEVEN_OUTCOMES,
  ODDEVEN_OUTCOME_NAMES,
  SCORE_OUTCOMES,
  formatScoreOutcome,
  PLAYER_PROPS_OUTCOMES,
  PLAYER_PROPS_OU_NAMES,
  PLAYER_PROPS_YN_NAMES,
  getOutcomeName,
} from './outcome-constants';

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
  useQuote,
  useIsMarketLocked,
} from './contract-hooks';

// Contract Interaction Hooks (Admin)
export {
  useLockMarket,
  useResolveMarket,
  useFinalizeMarket,
  useCreateMarket,
  useAuthorizeMarket,
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

// Basket (Parlay) Hooks
export {
  useParlayQuote,
  useParlayDetails,
  useUserParlays,
  useCanSettle,
  usePoolStatus,
  useCreateParlay,
  useSettleParlay,
  useBatchSettleParlays,
  ParlayStatus,
  type ParlayLeg,
  type Parlay,
  type ParlayQuote,
} from './basket-hooks';

// Referral Hooks
export {
  useBindReferral,
  useGetReferrer,
  useReferrerStatsOnChain,
  useIsReferralValid,
  useReferralParams,
  useBoundAt,
  useReferrerStats,
  useReferrals,
  useReferralRewards,
  useReferralLeaderboard,
  type ReferrerStats,
  type ReferralParams,
} from './referral-hooks';

// ParamController 治理 Hooks
export {
  useTimelockDelay,
  useReadParam,
  useReadParams,
  useTryGetParam,
  useReadProposal,
  useProposalCount,
  useIsParamRegistered,
  useProposeChange,
  useExecuteProposal,
  useCancelProposal,
  useRegisterParam,
  paramNameToKey,
  type Proposal,
  type ParamDefinition,
} from './param-controller-hooks';
