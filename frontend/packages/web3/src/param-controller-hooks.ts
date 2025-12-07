'use client';

/**
 * ParamController 治理 Hooks
 * 用于参数管理和提案治理
 */

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount } from 'wagmi';
import { type Address, type Hex, keccak256, toHex, encodeAbiParameters } from 'viem';
import { ParamControllerABI, getContractAddresses } from '@pitchone/contracts';

// ============================================
// 类型定义
// ============================================

export interface Proposal {
  key: Hex;
  oldValue: bigint;
  newValue: bigint;
  eta: bigint;
  executed: boolean;
  cancelled: boolean;
  proposer: Address;
  reason: string;
}

export interface ParamDefinition {
  key: Hex;
  name: string;
  value: bigint;
  validator?: Address;
  registered: boolean;
}

// ============================================
// 辅助函数
// ============================================

/**
 * 将参数名转换为 bytes32 key
 * @param paramName 参数名（如 "FEE_RATE"）
 * @returns bytes32 key
 */
export function paramNameToKey(paramName: string): Hex {
  return keccak256(toHex(paramName));
}

// ============================================
// 读取 Hooks
// ============================================

/**
 * 读取 Timelock 延迟
 */
export function useTimelockDelay() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isError, isLoading } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'timelockDelay',
    query: {
      enabled: !!addresses?.paramController,
    }
  });

  return {
    timelockDelay: data,
    isLoading,
    isError,
  };
}

/**
 * 读取单个参数值
 * @param paramKey 参数键（bytes32）或参数名（字符串）
 */
export function useReadParam(paramKey: Hex | string) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 如果是字符串，转换为 bytes32
  const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'getParam',
    args: [key],
    query: {
      enabled: !!addresses?.paramController,
    }
  });

  return {
    value: data,
    isLoading,
    isError,
    refetch,
  };
}

/**
 * 批量读取参数值
 * @param paramKeys 参数键数组（bytes32[] 或字符串数组）
 */
export function useReadParams(paramKeys: (Hex | string)[]) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 转换所有参数键为 bytes32
  const keys = paramKeys.map(key =>
    typeof key === 'string' ? paramNameToKey(key) : key
  ) as Hex[];

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'getParams',
    args: [keys],
    query: {
      enabled: !!addresses?.paramController && keys.length > 0,
    }
  });

  return {
    values: data,
    isLoading,
    isError,
    refetch,
  };
}

/**
 * 尝试读取参数值（不存在返回默认值）
 * @param paramKey 参数键（bytes32）或参数名（字符串）
 * @param defaultValue 默认值
 */
export function useTryGetParam(paramKey: Hex | string, defaultValue: bigint) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'tryGetParam',
    args: [key, defaultValue],
    query: {
      enabled: !!addresses?.paramController,
    }
  });

  return {
    value: data,
    isLoading,
    isError,
    refetch,
  };
}

/**
 * 读取提案信息
 * @param proposalId 提案 ID
 */
export function useReadProposal(proposalId?: Hex) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'proposals',
    args: proposalId ? [proposalId] : undefined,
    query: {
      enabled: !!addresses?.paramController && !!proposalId,
    }
  });

  // 将合约返回的元组转换为 Proposal 对象
  // data 是一个元组数组 [key, oldValue, newValue, eta, executed, cancelled, proposer, reason]
  const tupleData = data as readonly [Hex, bigint, bigint, bigint, boolean, boolean, Address, string] | undefined;
  const proposal = tupleData ? {
    key: tupleData[0],
    oldValue: tupleData[1],
    newValue: tupleData[2],
    eta: tupleData[3],
    executed: tupleData[4],
    cancelled: tupleData[5],
    proposer: tupleData[6],
    reason: tupleData[7],
  } as Proposal : null;

  return {
    proposal,
    isLoading,
    isError,
    refetch,
  };
}

/**
 * 读取提案计数
 */
export function useProposalCount() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'proposalCount',
    query: {
      enabled: !!addresses?.paramController,
    }
  });

  return {
    count: data,
    isLoading,
    isError,
    refetch,
  };
}

/**
 * 检查参数是否已注册
 * @param paramKey 参数键（bytes32）或参数名（字符串）
 */
export function useIsParamRegistered(paramKey: Hex | string) {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'isParamRegistered',
    args: [key],
    query: {
      enabled: !!addresses?.paramController,
    }
  });

  return {
    isRegistered: data,
    isLoading,
    isError,
    refetch,
  };
}

// ============================================
// 写入 Hooks
// ============================================

/**
 * 创建参数变更提案
 */
export function useProposeChange() {
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
   * 提交参数变更提案
   * @param paramKey 参数键（bytes32）或参数名（字符串）
   * @param newValue 新值
   * @param reason 变更理由
   */
  const proposeChange = async (
    paramKey: Hex | string,
    newValue: bigint,
    reason: string
  ) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

    console.log('[useProposeChange] 创建参数变更提案:', {
      controller: addresses.paramController,
      key,
      newValue,
      reason,
    });

    return writeContract({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'proposeChange',
      args: [key, newValue, reason],
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
 * 执行提案
 */
export function useExecuteProposal() {
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
   * 执行已过 Timelock 的提案
   * @param proposalId 提案 ID
   */
  const executeProposal = async (proposalId: Hex) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    console.log('[useExecuteProposal] 执行提案:', {
      controller: addresses.paramController,
      proposalId,
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
 * 取消提案
 */
export function useCancelProposal() {
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
   * 取消提案（需要是提案者或管理员）
   * @param proposalId 提案 ID
   */
  const cancelProposal = async (proposalId: Hex) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    console.log('[useCancelProposal] 取消提案:', {
      controller: addresses.paramController,
      proposalId,
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
 * 注册新参数（仅管理员）
 */
export function useRegisterParam() {
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
   * 注册新参数
   * @param paramKey 参数键（bytes32）或参数名（字符串）
   * @param initialValue 初始值
   * @param validator 验证器合约地址（0x0 表示无验证器）
   */
  const registerParam = async (
    paramKey: Hex | string,
    initialValue: bigint,
    validator: Address = '0x0000000000000000000000000000000000000000'
  ) => {
    if (!addresses?.paramController) throw new Error('ParamController not deployed');

    const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

    console.log('[useRegisterParam] 注册参数:', {
      controller: addresses.paramController,
      key,
      initialValue,
      validator,
    });

    return writeContract({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'registerParam',
      args: [key, initialValue, validator],
    });
  };

  return {
    registerParam,
    isPending,
    isConfirming,
    isSuccess,
    error: writeError || receiptError,
    hash,
  };
}
