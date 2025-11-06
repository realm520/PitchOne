'use client';

/**
 * 管理员功能 Hooks
 * 用于 admin 后台的合约写操作
 */

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { parseUnits, type Address, type Hex } from 'viem';
import {
  MarketBaseABI,
  MarketTemplateRegistryABI,
  ParamControllerABI,
  CampaignABI,
  QuestABI,
  RewardsDistributorABI,
  getContractAddresses
} from '@pitchone/contracts';

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
      abi: MarketBaseABI,
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
 * 创建市场 Hook
 * 通过 MarketTemplateRegistry 创建新市场
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
   * @param templateId 模板 ID (bytes32)
   * @param initData 初始化数据 (编码后的参数)
   */
  const createMarket = async (templateId: Hex, initData: Hex) => {
    if (!addresses) throw new Error('Chain not supported');

    console.log('[useCreateMarket] 创建市场:', {
      factory: addresses.marketTemplateRegistry,
      templateId,
      initData
    });

    return writeContract({
      address: addresses.marketTemplateRegistry,
      abi: MarketTemplateRegistryABI,
      functionName: 'createMarket',
      args: [templateId, initData],
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
      abi: MarketBaseABI,
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

    const budgetInWei = parseUnits(budget, 6); // USDC 6 位小数

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

    const rewardInWei = parseUnits(reward, 6); // USDC 6 位小数

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

    const amountInWei = parseUnits(totalAmount, 6); // USDC 6 位小数

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
