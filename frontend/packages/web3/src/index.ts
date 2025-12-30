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

// Outcome Constants (i18n keys)
export {
  WDL_OUTCOMES,
  WDL_OUTCOME_KEYS,
  OU_OUTCOMES,
  OU_OUTCOME_KEYS,
  AH_OUTCOMES,
  AH_OUTCOME_KEYS,
  ODDEVEN_OUTCOMES,
  ODDEVEN_OUTCOME_KEYS,
  SCORE_OUTCOMES,
  formatScoreOutcome,
  isI18nKey,
  PLAYER_PROPS_OUTCOMES,
  PLAYER_PROPS_OU_KEYS,
  PLAYER_PROPS_YN_KEYS,
  getOutcomeKey,
  getOutcomeName, // deprecated, use getOutcomeKey
} from './outcome-constants';

// Custom Hooks
export {
  useMarkets,
  useMarketsCount,
  useMarketsPaginated,
  useMarket,
  useUserPositions,
  useUserPositionsPaginated,
  useUserStats,
  useUserOrders,
  useMarketOrders,
  useMarketAllOrders,
  useMarketOddsFromSubgraph,
  MarketStatus,
  type Market,
  type Position,
  type UserStats,
  type Order,
  type PaginationInfo,
  type PaginatedMarketsResult,
  type MarketWithOddsData,
  type OutcomeData,
} from './hooks';

// Contract Interaction Hooks (User)
export {
  useApproveUSDC,
  useUSDCAllowance,
  useUSDCBalance,
  usePlaceBet,
  useRedeem,
  useRefund,
  useRedeemBatch,
  usePositionBalance,
  useMarketStatus,
  useOutcomeCount,
  useMarketStats,      // V3: 替代 useOutcomeLiquidity
  useAllPrices,        // V3: 获取所有结果价格
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
  useUnpauseMarket,
  useCancelMarket,
  useParamControllerPropose,
  useParamControllerExecute,
  useParamControllerCancel,
  useParamProposal,
  useCreateCampaign,
  useCreateQuest,
  usePublishMerkleRoot,
  type CreateMarketParams,
} from './admin-hooks';

// Event Listening Hooks
export {
  useWatchBetPlaced,
  useWatchMarketLocked,
  useWatchMarketResolved,     // V3: 新名称
  useWatchPayoutClaimed,      // V3: 新名称
  useWatchResultProposed,     // V3: 兼容别名
  useWatchPositionRedeemed,   // V3: 兼容别名
  useMarketEvents,
  useAutoRefresh,
  type BetPlacedEvent,
  type MarketLockedEvent,
  type MarketResolvedEvent,   // V3: 新类型
  type PayoutClaimedEvent,    // V3: 新类型
} from './event-hooks';

// Multicall Optimization Hooks
export {
  useMarketFullData,
  useMultipleMarketsData,
  useUserUSDCDataForMarkets,
  useMarketOutcomes,
  type MarketFullData,
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
  useHasProposerRole,
  useProposeChange,
  useExecuteProposal,
  useCancelProposal,
  useRegisterParam,
  useProposals,
  paramNameToKey,
  type Proposal,
  type ParamDefinition,
  type ProposalListItem,
} from './param-controller-hooks';

// Odds Calculator (Subgraph-based)
export {
  calculateOddsFromSubgraph,
  formatOdds,
  type MarketOddsData,
  type OutcomeVolume,
  type OutcomeOdds,
} from './odds-calculator';
