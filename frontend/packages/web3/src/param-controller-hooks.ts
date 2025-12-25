'use client';

/**
 * ParamController 治理 Hooks
 * 用于参数管理和提案治理
 */

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount, usePublicClient } from 'wagmi';
import { type Address, type Hex, keccak256, toHex, encodeAbiParameters, parseAbiItem } from 'viem';
import { useState, useEffect, useCallback } from 'react';
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
    timelockDelay: data as bigint | undefined,
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
    values: data as bigint[] | undefined,
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

// 已知的角色哈希映射
const ROLE_HASHES: Record<string, string> = {
  '0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1': 'PROPOSER_ROLE',
  '0x0000000000000000000000000000000000000000000000000000000000000000': 'DEFAULT_ADMIN_ROLE',
};

/**
 * 解析合约错误，提取可读信息
 */
function parseContractError(err: any): string {
  // 用户拒绝交易
  if (err?.message?.includes('User rejected') || err?.message?.includes('user rejected')) {
    return '用户取消了交易';
  }

  // 遍历错误链查找 revert 数据
  let current = err;
  while (current) {
    // 检查 data 字段（revert 数据）
    if (current?.data && typeof current.data === 'string' && current.data.startsWith('0x')) {
      return parseRevertData(current.data);
    }

    // 检查 shortMessage
    if (current?.shortMessage) {
      const hexMatch = current.shortMessage.match(/0x[a-fA-F0-9]{8,}/);
      if (hexMatch) {
        return parseRevertData(hexMatch[0]);
      }
      if (!current.shortMessage.includes('reverted') || current.shortMessage.length < 100) {
        return current.shortMessage;
      }
    }

    // 检查 metaMessages
    if (current?.metaMessages && Array.isArray(current.metaMessages)) {
      for (const msg of current.metaMessages) {
        const hexMatch = msg.match(/0x[a-fA-F0-9]{8,}/);
        if (hexMatch) {
          return parseRevertData(hexMatch[0]);
        }
      }
    }
    console.log('curren+++++++:', JSON.stringify(current));
    current = current.cause;
  }

  // 检查 AccessControlUnauthorizedAccount
  if (err?.message?.includes('AccessControlUnauthorizedAccount') || err?.message?.includes('0xe2517d3f')) {
    return '权限不足：当前账户没有 PROPOSER_ROLE 权限，无法创建提案';
  }

  return err?.shortMessage || err?.message || '交易失败';
}

/**
 * 解析 revert 数据
 */
function parseRevertData(data: string): string {
  // AccessControlUnauthorizedAccount(address account, bytes32 neededRole)
  // selector: 0xe2517d3f
  if (data.startsWith('0xe2517d3f')) {
    const dataBody = data.slice(10);
    const account = '0x' + dataBody.slice(24, 64);
    const roleHash = '0x' + dataBody.slice(64, 128);
    const roleName = ROLE_HASHES[roleHash.toLowerCase()] || roleHash.slice(0, 18) + '...';
    return `权限不足：账户 ${account.slice(0, 8)}...${account.slice(-4)} 没有 ${roleName} 权限`;
  }

  // Error(string)
  if (data.startsWith('0x08c379a0')) {
    try {
      const dataBody = data.slice(10);
      const length = parseInt(dataBody.slice(64, 128), 16);
      const message = Buffer.from(dataBody.slice(128, 128 + length * 2), 'hex').toString('utf8');
      return message;
    } catch {
      return '合约执行失败';
    }
  }

  // ParamNotRegistered(bytes32 key) - selector 需要计算
  if (data.includes('ParamNotRegistered')) {
    return '参数未注册：该参数尚未在 ParamController 中注册';
  }

  return `合约执行失败 (${data.slice(0, 10)})`;
}

/**
 * 创建参数变更提案
 */
export function useProposeChange() {
  const { chainId, address: accountAddress } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const publicClient = usePublicClient();
  const { writeContractAsync, data: hash, isPending, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess,
    data: receipt,
    error: receiptError
  } = useWaitForTransactionReceipt({
    hash,
    chainId,
    query: {
      enabled: !!hash,
    }
  });

  const [simulateError, setSimulateError] = useState<Error | null>(null);

  // 检查交易是否 revert（status === 'reverted'）
  const isReverted = receipt?.status === 'reverted';

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
    if (!publicClient) throw new Error('Public client not available');

    setSimulateError(null);
    const key = typeof paramKey === 'string' ? paramNameToKey(paramKey) : paramKey;

    console.log('[useProposeChange] 创建参数变更提案:', {
      controller: addresses.paramController,
      key,
      newValue,
      reason,
    });

    // 先模拟调用，检查是否会失败
    try {
      console.log('[useProposeChange] 模拟调用检查...');
      await publicClient.simulateContract({
        address: addresses.paramController,
        abi: ParamControllerABI,
        functionName: 'proposeChange',
        args: [key, newValue, reason],
        account: accountAddress,
      });
      console.log('[useProposeChange] 模拟调用成功');
    } catch (simError: any) {
      throw simError;
    }

    // 发送交易
    return writeContractAsync({
      address: addresses.paramController,
      abi: ParamControllerABI,
      functionName: 'proposeChange',
      args: [key, newValue, reason],
    });
  };

  // 合并所有错误
  const error = simulateError || writeError || receiptError || (isReverted ? new Error('交易被链上拒绝') : null);

  return {
    proposeChange,
    isPending,
    isConfirming,
    isSuccess: isSuccess && !isReverted,
    isReverted,
    error,
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

/**
 * 检查当前用户是否有 PROPOSER_ROLE
 */
export function useHasProposerRole() {
  const { chainId, address } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // PROPOSER_ROLE = keccak256("PROPOSER_ROLE")
  const PROPOSER_ROLE = '0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1' as Hex;

  const { data, isError, isLoading, refetch } = useReadContract({
    address: addresses?.paramController,
    abi: ParamControllerABI,
    functionName: 'hasRole',
    args: address ? [PROPOSER_ROLE, address] : undefined,
    query: {
      enabled: !!addresses?.paramController && !!address,
    }
  });

  return {
    hasRole: data as boolean | undefined,
    isLoading,
    isError,
    refetch,
  };
}

// ============================================
// 提案列表 Hooks（通过事件查询）
// ============================================

/**
 * 提案列表项
 */
export interface ProposalListItem {
  id: Hex;
  proposal: Proposal;
}

/**
 * 读取所有提案列表（通过监听 ProposalCreated 事件）
 * 注意：这会查询从合约部署以来的所有事件，可能比较慢
 * 生产环境建议使用 Subgraph
 */
export function useProposals() {
  const { chainId } = useAccount();
  const addresses = chainId ? getContractAddresses(chainId) : null;
  const publicClient = usePublicClient();

  const [proposals, setProposals] = useState<ProposalListItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [fetchTrigger, setFetchTrigger] = useState(0);

  // 使用 ref 存储 publicClient 避免依赖变化
  const publicClientRef = { current: publicClient };
  publicClientRef.current = publicClient;

  const paramControllerAddress = addresses?.paramController;

  // 手动刷新函数
  const refetch = useCallback(() => {
    setFetchTrigger(prev => prev + 1);
  }, []);

  // 获取提案
  useEffect(() => {
    const fetchProposals = async () => {
      const client = publicClientRef.current;
      if (!paramControllerAddress || !client) {
        console.log('[useProposals] 跳过: paramController=', paramControllerAddress, 'client=', !!client);
        return;
      }

      setIsLoading(true);
      setError(null);

      try {
        console.log('[useProposals] 开始获取事件, paramController:', paramControllerAddress);

        // 获取 ProposalCreated 事件
        const logs = await client.getLogs({
          address: paramControllerAddress,
          event: parseAbiItem('event ProposalCreated(bytes32 indexed proposalId, bytes32 indexed key, uint256 oldValue, uint256 newValue, uint256 eta, address indexed proposer, string reason)'),
          fromBlock: 'earliest',
          toBlock: 'latest',
        });

        console.log('[useProposals] 获取到事件数量:', logs.length);

        if (logs.length === 0) {
          setProposals([]);
          setIsLoading(false);
          return;
        }

        // 批量读取每个提案的当前状态
        const proposalPromises = logs.map(async (log) => {
          const proposalId = log.args.proposalId as Hex;
          console.log('[useProposals] 读取提案:', proposalId);

          try {
            // 读取提案当前状态
            const data = await client.readContract({
              address: paramControllerAddress,
              abi: ParamControllerABI,
              functionName: 'proposals',
              args: [proposalId],
            });

            const tupleData = data as readonly [Hex, bigint, bigint, bigint, boolean, boolean, Address, string];
            const proposal: Proposal = {
              key: tupleData[0],
              oldValue: tupleData[1],
              newValue: tupleData[2],
              eta: tupleData[3],
              executed: tupleData[4],
              cancelled: tupleData[5],
              proposer: tupleData[6],
              reason: tupleData[7],
            };

            console.log('[useProposals] 提案详情:', proposalId, proposal);
            return { id: proposalId, proposal };
          } catch (err) {
            console.error('[useProposals] 读取提案失败:', proposalId, err);
            return null;
          }
        });

        const results = await Promise.all(proposalPromises);
        const validProposals = results.filter((p): p is ProposalListItem => p !== null);

        // 按 eta 倒序排序（最新的排在前面）
        validProposals.sort((a, b) => Number(b.proposal.eta) - Number(a.proposal.eta));

        console.log('[useProposals] 最终提案列表:', validProposals.length);
        setProposals(validProposals);
      } catch (err: any) {
        console.error('[useProposals] 获取提案列表失败:', err);
        setError(err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchProposals();
  }, [paramControllerAddress, fetchTrigger]);

  return {
    proposals,
    isLoading,
    error,
    refetch,
  };
}
