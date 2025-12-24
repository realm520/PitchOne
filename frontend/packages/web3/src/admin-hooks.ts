'use client';

/**
 * 管理员功能 Hooks
 * 用于 admin 后台的合约写操作
 */

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { parseUnits, type Address, type Hex } from 'viem';
import {
  Market_V3_ABI,
  MarketFactory_V3_ABI,
  LiquidityVault_V3_ABI,
  ParamControllerABI,
  CampaignABI,
  QuestABI,
  RewardsDistributorABI,
  getContractAddresses
} from '@pitchone/contracts';
import { TOKEN_DECIMALS } from './constants';

// ============================================
// 市场管理 Hooks
// ============================================

/**
 * 锁盘市场 Hook
 * 调用 Market.lock() 方法锁定市场，禁止新下注
 * @param marketAddress 市场合约地址
 */
export function useLockMarket(marketAddress?: Address) {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  const lockMarket = async () => {
    if (!marketAddress) throw new Error('Market address required');

    console.log('[useLockMarket] 锁盘市场:', { marketAddress });

    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'lock',
      args: [],
    });
  };

  return {
    lockMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 创建市场参数类型
 */
export interface CreateMarketParams {
  templateId: Hex;           // 模板 ID (bytes32)
  matchId: string;           // 比赛 ID
  kickoffTime: bigint;       // 开球时间戳
  mapperInitData: Hex;       // Mapper 初始化数据
  initialLiquidity: bigint;  // 初始流动性
  outcomeRules: Array<{ name: string; payoutType: number }>; // outcome 规则
}

/**
 * 创建市场 Hook
 * 通过 MarketFactory_V3 创建新市场
 */
export function useCreateMarket() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 创建市场
   * @param params 创建市场参数
   */
  const createMarket = async (params: CreateMarketParams) => {
    if (!addresses) throw new Error('Chain not supported');

    // V3: 使用 factory 地址
    const factoryAddress = addresses.factory;

    console.log('[useCreateMarket] 创建市场:', {
      factory: factoryAddress,
      params
    });

    return writeContract({
      address: factoryAddress,
      abi: MarketFactory_V3_ABI,
      functionName: 'createMarket',
      args: [{
        templateId: params.templateId,
        matchId: params.matchId,
        kickoffTime: params.kickoffTime,
        mapperInitData: params.mapperInitData,
        initialLiquidity: params.initialLiquidity,
        outcomeRules: params.outcomeRules,
      }],
    });
  };

  return {
    createMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 授权市场从 Vault 借款 Hook
 * 调用 LiquidityVault.authorizeMarket()
 * 注意: WDL 市场创建后必须调用此方法
 */
export function useAuthorizeMarket() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 授权市场
   * @param marketAddress 市场合约地址
   */
  const authorizeMarket = async (marketAddress: Address) => {
    if (!addresses?.vault) throw new Error('Vault address required');

    console.log('[useAuthorizeMarket] 授权市场:', {
      vault: addresses.vault,
      marketAddress
    });

    return writeContract({
      address: addresses.vault,
      abi: LiquidityVault_V3_ABI,
      functionName: 'authorizeMarket',
      args: [marketAddress],
    });
  };

  return {
    authorizeMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 结算市场 Hook
 * 调用 Market.resolve(winningOutcomeId) 设置获胜结果
 * @param marketAddress 市场合约地址
 */
export function useResolveMarket(marketAddress?: Address) {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 结算市场
   * @param winningOutcomeId 获胜结果 ID (0, 1, 2 等)
   */
  const resolveMarket = async (winningOutcomeId: bigint) => {
    if (!marketAddress) throw new Error('Market address required');

    console.log('[useResolveMarket] 结算市场:', { marketAddress, winningOutcomeId });

    // V3: resolve 接受 winningOutcomes 数组和 weights 数组
    // 单结果市场简化为 [outcomeId], [10000] (100% 权重)
    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'resolve',
      args: [[winningOutcomeId], [10000n]],
    });
  };

  return {
    resolveMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 终结市场 Hook
 * 调用 Market.finalize() 终结市场（争议期结束后）
 * @param marketAddress 市场合约地址
 */
export function useFinalizeMarket(marketAddress?: Address) {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  const finalizeMarket = async () => {
    if (!marketAddress) throw new Error('Market address required');

    console.log('[useFinalizeMarket] 终结市场:', { marketAddress });

    // V3: finalize 功能已合并到 resolve 中，市场在 resolve 后自动进入 Resolved 状态
    // 保留此 hook 用于兼容性，实际调用 resolve 的最终确认（如果需要）
    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'finalize',
      args: [],
    });
  };

  return {
    finalizeMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 暂停市场 Hook
 * 调用 Market.pause() 紧急暂停市场
 * @param marketAddress 市场合约地址
 */
export function usePauseMarket(marketAddress?: Address) {
  const { chainId } = useAccount();
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  const pauseMarket = async () => {
    if (!marketAddress) throw new Error('Market address required');

    console.log('[usePauseMarket] 暂停市场:', { marketAddress });

    return writeContract({
      address: marketAddress,
      abi: Market_V3_ABI,
      functionName: 'pause',
      args: [],
    });
  };

  return {
    pauseMarket,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

// ============================================
// 参数治理 Hooks
// ============================================

/**
 * 创建参数变更提案 Hook
 * 调用 ParamController.proposeChange()
 */
export function useParamControllerPropose() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 创建参数变更提案
   * @param paramKey 参数键（如 "FEE_RATE"）
   * @param newValue 新值（编码后的 bytes）
   * @param reason 变更理由
   */
  const proposeChange = async (paramKey: string, newValue: Hex, reason: string) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    console.log('[useParamControllerPropose] 创建提案:', {
      paramController: addresses.paramController,
      paramKey,
      newValue,
      reason
    });

    return writeContract({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'proposeChange',
      args: [paramKey, newValue, reason],
    });
  };

  return {
    proposeChange,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 执行参数提案 Hook
 * 调用 ParamController.executeProposal()
 */
export function useParamControllerExecute() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 执行提案
   * @param proposalId 提案 ID
   */
  const executeProposal = async (proposalId: bigint) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    console.log('[useParamControllerExecute] 执行提案:', {
      paramController: addresses.paramController,
      proposalId
    });

    return writeContract({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'executeProposal',
      args: [proposalId],
    });
  };

  return {
    executeProposal,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 取消参数提案 Hook
 * 调用 ParamController.cancelProposal()
 */
export function useParamControllerCancel() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 取消提案
   * @param proposalId 提案 ID
   */
  const cancelProposal = async (proposalId: bigint) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    console.log('[useParamControllerCancel] 取消提案:', {
      paramController: addresses.paramController,
      proposalId
    });

    return writeContract({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'cancelProposal',
      args: [proposalId],
    });
  };

  return {
    cancelProposal,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 查询参数提案详情
 * @param proposalId 提案 ID
 */
export function useParamProposal(proposalId?: bigint) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  return useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'proposals',
    args: proposalId !== undefined ? [proposalId] : undefined,
    query: {
      enabled: !!addresses?.paramController && proposalId !== undefined,
    },
  });
}

// ============================================
// 活动与任务 Hooks
// ============================================

/**
 * 创建活动 Hook
 * 调用 Campaign.createCampaign()
 */
export function useCreateCampaign() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 创建活动
   * @param name 活动名称
   * @param budget 预算上限（USDC）
   * @param ruleHash 规则哈希（IPFS 或其他）
   */
  const createCampaign = async (name: string, budget: string, ruleHash: string) => {
    if (!addresses?.campaign) throw new Error('Campaign contract not deployed');

    const budgetInWei = parseUnits(budget, TOKEN_DECIMALS.USDC); // USDC 6 位小数

    console.log('[useCreateCampaign] 创建活动:', {
      campaign: addresses.campaign,
      name,
      budget,
      ruleHash
    });

    return writeContract({
      address: addresses.campaign,
      abi: CampaignABI,
      functionName: 'createCampaign',
      args: [name, budgetInWei, ruleHash],
    });
  };

  return {
    createCampaign,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

/**
 * 创建任务 Hook
 * 调用 Quest.createQuest()
 */
export function useCreateQuest() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 创建任务
   * @param questType 任务类型 (0: FIRST_BET, 1: CONSECUTIVE_BETS, 2: REFERRAL, 3: VOLUME, 4: WIN_STREAK)
   * @param target 目标值
   * @param reward 奖励金额（USDC）
   */
  const createQuest = async (questType: number, target: bigint, reward: string) => {
    if (!addresses?.quest) throw new Error('Quest contract not deployed');

    const rewardInWei = parseUnits(reward, TOKEN_DECIMALS.USDC); // USDC 6 位小数

    console.log('[useCreateQuest] 创建任务:', {
      quest: addresses.quest,
      questType,
      target,
      reward
    });

    return writeContract({
      address: addresses.quest,
      abi: QuestABI,
      functionName: 'createQuest',
      args: [questType, target, rewardInWei],
    });
  };

  return {
    createQuest,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}

// ============================================
// 奖励分发 Hooks
// ============================================

/**
 * 发布 Merkle Root Hook
 * 调用 RewardsDistributor.publishRoot()
 */
export function usePublishMerkleRoot() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const { writeContract, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  /**
   * 发布 Merkle Root
   * @param root Merkle 树根哈希
   * @param totalAmount 本周期总奖励金额
   */
  const publishRoot = async (root: Hex, totalAmount: string) => {
    if (!addresses?.rewardsDistributor) throw new Error('RewardsDistributor not deployed');

    const amountInWei = parseUnits(totalAmount, TOKEN_DECIMALS.USDC); // USDC 6 位小数

    console.log('[usePublishMerkleRoot] 发布 Merkle Root:', {
      rewardsDistributor: addresses.rewardsDistributor,
      root,
      totalAmount
    });

    return writeContract({
      address: addresses.rewardsDistributor,
      abi: RewardsDistributorABI,
      functionName: 'publishRoot',
      args: [root, amountInWei],
    });
  };

  return {
    publishRoot,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}
