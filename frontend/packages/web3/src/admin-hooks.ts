'use client';

/**
 * 管理员功能 Hooks
 * 用于 admin 后台的合约写操作
 */

import { useWriteContract, useWaitForTransactionReceipt, useReadContract, useAccount, usePublicClient } from 'wagmi';
import { parseUnits, type Address, type Hex, encodeAbiParameters, parseAbiParameters } from 'viem';
import { useState } from 'react';
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

// 已知的角色哈希映射
const ROLE_HASHES: Record<string, string> = {
  '0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab': 'KEEPER_ROLE',
  '0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2': 'ROUTER_ROLE',
  '0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929': 'ORACLE_ROLE',
  '0x0000000000000000000000000000000000000000000000000000000000000000': 'DEFAULT_ADMIN_ROLE',
};

/**
 * 解析合约错误，提取可读信息
 */
function parseRevertReason(errorData: string): string {
  // AccessControlUnauthorizedAccount(address account, bytes32 neededRole)
  // selector: 0xe2517d3f
  if (errorData.startsWith('0xe2517d3f')) {
    const data = errorData.slice(10); // 去掉 selector
    const account = '0x' + data.slice(24, 64); // address 在 32 bytes 的后 20 bytes
    const roleHash = '0x' + data.slice(64, 128);
    const roleName = ROLE_HASHES[roleHash.toLowerCase()] || roleHash.slice(0, 18) + '...';
    return `权限不足：账户 ${account.slice(0, 8)}...${account.slice(-6)} 没有 ${roleName} 权限`;
  }

  // 其他常见错误
  if (errorData.startsWith('0x08c379a0')) {
    // Error(string)
    try {
      const data = errorData.slice(10);
      const offset = parseInt(data.slice(0, 64), 16);
      const length = parseInt(data.slice(64, 128), 16);
      const message = Buffer.from(data.slice(128, 128 + length * 2), 'hex').toString('utf8');
      return message;
    } catch {
      return '合约执行失败';
    }
  }

  return `合约执行失败 (${errorData.slice(0, 10)})`;
}

/**
 * 从 viem/wagmi 错误对象中提取可读的错误信息
 */
function extractErrorMessage(err: any): string {
  console.log('[extractErrorMessage] 原始错误对象:', err);
  console.log('[extractErrorMessage] 错误类型:', err?.constructor?.name);
  console.log('[extractErrorMessage] 错误属性:', Object.keys(err || {}));

  // 用户拒绝交易
  if (err?.message?.includes('User rejected') || err?.message?.includes('user rejected')) {
    return '用户取消了交易';
  }

  // 1. 检查 viem ContractFunctionExecutionError 的 cause 链
  let current = err;
  while (current) {
    console.log('[extractErrorMessage] 检查层级:', current?.constructor?.name, current?.name);

    // 检查 data 字段（revert 数据）
    if (current?.data && typeof current.data === 'string' && current.data.startsWith('0x')) {
      console.log('[extractErrorMessage] 找到 revert data:', current.data);
      return parseRevertReason(current.data);
    }

    // 检查 shortMessage
    if (current?.shortMessage) {
      console.log('[extractErrorMessage] 找到 shortMessage:', current.shortMessage);

      // 检查是否包含 revert 数据的十六进制
      const hexMatch = current.shortMessage.match(/0x[a-fA-F0-9]{8,}/);
      if (hexMatch) {
        return parseRevertReason(hexMatch[0]);
      }

      // 如果 shortMessage 有意义，直接返回
      if (!current.shortMessage.includes('reverted') || current.shortMessage.length < 100) {
        return current.shortMessage;
      }
    }

    // 检查 metaMessages（viem 特有）
    if (current?.metaMessages && Array.isArray(current.metaMessages)) {
      for (const msg of current.metaMessages) {
        console.log('[extractErrorMessage] metaMessage:', msg);
        const hexMatch = msg.match(/0x[a-fA-F0-9]{8,}/);
        if (hexMatch) {
          return parseRevertReason(hexMatch[0]);
        }
      }
    }

    // 检查 details
    if (current?.details) {
      console.log('[extractErrorMessage] 找到 details:', current.details);
      const hexMatch = current.details.match(/0x[a-fA-F0-9]{8,}/);
      if (hexMatch) {
        return parseRevertReason(hexMatch[0]);
      }
    }

    current = current.cause;
  }

  // 2. 从错误 message 中提取
  if (err?.message) {
    // 查找 AccessControlUnauthorizedAccount
    if (err.message.includes('AccessControlUnauthorizedAccount') || err.message.includes('0xe2517d3f')) {
      const hexMatch = err.message.match(/0xe2517d3f[a-fA-F0-9]*/);
      if (hexMatch) {
        return parseRevertReason(hexMatch[0]);
      }
      // 尝试提取角色哈希
      const roleMatch = err.message.match(/0x[a-fA-F0-9]{64}/g);
      if (roleMatch && roleMatch.length > 0) {
        const roleHash = roleMatch[roleMatch.length - 1].toLowerCase();
        const roleName = ROLE_HASHES[roleHash] || '未知角色';
        return `权限不足：当前账户没有 ${roleName} 权限`;
      }
      return '权限不足：当前账户没有执行此操作的权限';
    }

    // 查找任何 0x 开头的错误数据
    const hexMatch = err.message.match(/0x[a-fA-F0-9]{8,}/);
    if (hexMatch) {
      return parseRevertReason(hexMatch[0]);
    }
  }

  // 3. 返回原始错误信息
  const message = err?.shortMessage || err?.message || '交易失败';
  return message.length > 200 ? message.slice(0, 200) + '...' : message;
}

// ============================================
// 市场管理 Hooks
// ============================================

/**
 * 锁盘市场 Hook
 * 调用 Market.lock() 方法锁定市场，禁止新下注
 * @param marketAddress 市场合约地址
 */
export function useLockMarket(marketAddress?: Address) {
  const publicClient = usePublicClient();
  const { address: accountAddress } = useAccount();
  const { writeContractAsync, isPending, error: writeError } = useWriteContract();

  // 使用 state 手动管理交易状态（避免 useWaitForTransactionReceipt 的 RPC 问题）
  const [hash, setHash] = useState<Hex | undefined>(undefined);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isReverted, setIsReverted] = useState(false);
  const [receipt, setReceipt] = useState<any>(null);
  const [revertError, setRevertError] = useState<Error | null>(null);

  // 重置状态
  const resetState = () => {
    setHash(undefined);
    setIsConfirming(false);
    setIsSuccess(false);
    setIsReverted(false);
    setReceipt(null);
    setRevertError(null);
  };

  // 手动轮询获取 receipt
  const waitForReceipt = async (txHash: Hex): Promise<any> => {
    if (!publicClient) throw new Error('Public client not available');

    console.log('[useLockMarket] 开始轮询 receipt:', txHash);

    // 最多等待 60 秒，每 2 秒轮询一次
    for (let i = 0; i < 30; i++) {
      try {
        const txReceipt = await publicClient.getTransactionReceipt({ hash: txHash });
        console.log('[useLockMarket] 获取到 receipt:', txReceipt);
        return txReceipt;
      } catch (err: any) {
        // 如果是 "transaction not found"，继续等待
        if (err?.message?.includes('could not be found') || err?.message?.includes('not found')) {
          console.log(`[useLockMarket] 交易未确认，等待中... (${i + 1}/30)`);
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          throw err;
        }
      }
    }
    throw new Error('等待交易确认超时');
  };

  const lockMarket = async () => {
    if (!marketAddress) throw new Error('Market address required');
    if (!publicClient) throw new Error('Public client not available');

    console.log('[useLockMarket] 锁盘市场:', { marketAddress });
    resetState();
    setIsConfirming(true);

    try {
      // 先模拟调用，检查是否会失败（必须指定 account 以检查权限）
      console.log('[useLockMarket] 模拟调用检查...', { account: accountAddress });
      try {
        await publicClient.simulateContract({
          address: marketAddress,
          abi: Market_V3_ABI,
          functionName: 'lock',
          args: [],
          account: accountAddress, // 必须指定账户以正确检查权限
        });
        console.log('[useLockMarket] 模拟调用成功');
      } catch (simError: any) {
        console.error('[useLockMarket] 模拟调用失败:', simError);
        setIsConfirming(false);
        const errorMessage = extractErrorMessage(simError);
        console.log('[useLockMarket] 模拟调用错误消息:', errorMessage);
        setRevertError(new Error(errorMessage));
        throw new Error(errorMessage);
      }

      // 发送交易
      const txHash = await writeContractAsync({
        address: marketAddress,
        abi: Market_V3_ABI,
        functionName: 'lock',
        args: [],
      });

      console.log('[useLockMarket] 交易已发送:', txHash);
      setHash(txHash);

      // 手动等待 receipt
      const txReceipt = await waitForReceipt(txHash);
      setReceipt(txReceipt);
      setIsConfirming(false);

      console.log('[useLockMarket] Receipt 详情:', {
        status: txReceipt.status,
        statusType: typeof txReceipt.status,
      });

      // 检查交易状态
      if (txReceipt.status === 'success') {
        setIsSuccess(true);
        console.log('[useLockMarket] 锁盘成功！');
      } else {
        setIsReverted(true);
        console.log('[useLockMarket] 交易 reverted');

        // 获取原始交易以提取 from 地址
        let fromAddress: `0x${string}` | undefined;
        try {
          const tx = await publicClient.getTransaction({ hash: txHash });
          fromAddress = tx.from;
          console.log('[useLockMarket] 交易发送者:', fromAddress);
        } catch (e) {
          console.log('[useLockMarket] 无法获取交易详情');
        }

        // 在 revert 区块重放交易获取错误原因
        try {
          const blockNumber = txReceipt.blockNumber ? BigInt(txReceipt.blockNumber) - 1n : undefined;
          console.log('[useLockMarket] 在区块', blockNumber?.toString(), '重放交易...');

          await publicClient.simulateContract({
            address: marketAddress,
            abi: Market_V3_ABI,
            functionName: 'lock',
            args: [],
            account: fromAddress,
            blockNumber,
          });
          // 如果成功，说明是区块间状态变化
          setRevertError(new Error('交易被链上拒绝（状态已改变）'));
        } catch (err: any) {
          console.log('[useLockMarket] 重放错误:', err);
          const errorMessage = extractErrorMessage(err);
          console.log('[useLockMarket] 解析后的错误:', errorMessage);
          setRevertError(new Error(errorMessage));
        }
      }

      return txHash;
    } catch (err: any) {
      console.error('[useLockMarket] 交易失败:', err);
      setIsConfirming(false);

      // 使用增强的错误解析
      const errorMessage = extractErrorMessage(err);
      console.log('[useLockMarket] 解析后的错误消息:', errorMessage);

      setRevertError(new Error(errorMessage));
      throw err;
    }
  };

  return {
    lockMarket,
    isPending,
    isConfirming,
    isSuccess,
    isReverted,
    error: writeError || revertError,
    hash,
    receipt,
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
  const publicClient = usePublicClient();
  const { address: accountAddress } = useAccount();
  const { writeContractAsync, isPending, error: writeError } = useWriteContract();

  // 使用 state 手动管理交易状态
  const [hash, setHash] = useState<Hex | undefined>(undefined);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isReverted, setIsReverted] = useState(false);
  const [revertError, setRevertError] = useState<Error | null>(null);

  const resetState = () => {
    setHash(undefined);
    setIsConfirming(false);
    setIsSuccess(false);
    setIsReverted(false);
    setRevertError(null);
  };

  const waitForReceipt = async (txHash: Hex): Promise<any> => {
    if (!publicClient) throw new Error('Public client not available');
    for (let i = 0; i < 30; i++) {
      try {
        return await publicClient.getTransactionReceipt({ hash: txHash });
      } catch (err: any) {
        if (err?.message?.includes('could not be found') || err?.message?.includes('not found')) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          throw err;
        }
      }
    }
    throw new Error('等待交易确认超时');
  };

  /**
   * 结算市场（通过比分）
   * @param homeScore 主队进球数
   * @param awayScore 客队进球数
   *
   * 大多数 Mapper（WDL、OU、AH、OddEven、Score）使用比分来计算获胜的 outcomeId
   * rawResult 格式：abi.encode(homeScore, awayScore)
   */
  const resolveMarket = async (homeScore: bigint, awayScore?: bigint) => {
    if (!marketAddress) throw new Error('Market address required');
    if (!publicClient) throw new Error('Public client not available');

    // 如果只传入一个参数，假设是直接的 outcomeId（用于 Identity_Mapper）
    // 如果传入两个参数，假设是比分（用于其他 Mapper）
    const isScoreMode = awayScore !== undefined;

    console.log('[useResolveMarket] 结算市场:', {
      marketAddress,
      mode: isScoreMode ? 'score' : 'outcomeId',
      homeScore,
      awayScore
    });
    resetState();
    setIsConfirming(true);

    // 编码 rawResult
    let rawResult: `0x${string}`;
    if (isScoreMode) {
      // 比分模式：abi.encode(homeScore, awayScore)
      rawResult = encodeAbiParameters(
        parseAbiParameters('uint256, uint256'),
        [homeScore, awayScore]
      );
    } else {
      // outcomeId 模式（用于 Identity_Mapper）：abi.encode(outcomeId)
      rawResult = encodeAbiParameters(
        parseAbiParameters('uint256'),
        [homeScore]
      );
    }
    console.log('[useResolveMarket] 编码后的 rawResult:', rawResult);

    try {
      // 先模拟调用（必须指定 account 以检查权限）
      console.log('[useResolveMarket] 模拟调用检查...', { account: accountAddress });
      try {
        await publicClient.simulateContract({
          address: marketAddress,
          abi: Market_V3_ABI,
          functionName: 'resolve',
          args: [rawResult],
          account: accountAddress, // 必须指定账户以正确检查权限
        });
        console.log('[useResolveMarket] 模拟调用成功');
      } catch (simError: any) {
        console.error('[useResolveMarket] 模拟调用失败:', simError);
        setIsConfirming(false);
        const errorMessage = extractErrorMessage(simError);
        setRevertError(new Error(errorMessage));
        throw new Error(errorMessage);
      }

      const txHash = await writeContractAsync({
        address: marketAddress,
        abi: Market_V3_ABI,
        functionName: 'resolve',
        args: [rawResult],
      });

      console.log('[useResolveMarket] 交易已发送:', txHash);
      setHash(txHash);

      const txReceipt = await waitForReceipt(txHash);
      setIsConfirming(false);

      if (txReceipt.status === 'success') {
        setIsSuccess(true);
        console.log('[useResolveMarket] 结算成功！');
      } else {
        setIsReverted(true);
        setRevertError(new Error('交易被链上拒绝'));
      }

      return txHash;
    } catch (err: any) {
      console.error('[useResolveMarket] 交易失败:', err);
      setIsConfirming(false);
      const errorMessage = extractErrorMessage(err);
      console.log('[useResolveMarket] 解析后的错误消息:', errorMessage);
      setRevertError(new Error(errorMessage));
      throw err;
    }
  };

  return {
    resolveMarket,
    isPending,
    isConfirming,
    isSuccess,
    isReverted,
    error: writeError || revertError,
    hash,
  };
}

/**
 * 终结市场 Hook
 * 调用 Market.finalize(scaleBps) 终结市场（争议期结束后）
 * @param marketAddress 市场合约地址
 */
export function useFinalizeMarket(marketAddress?: Address) {
  const publicClient = usePublicClient();
  const { address: accountAddress } = useAccount();
  const { writeContractAsync, isPending, error: writeError } = useWriteContract();

  // 使用 state 手动管理交易状态
  const [hash, setHash] = useState<Hex | undefined>(undefined);
  const [isConfirming, setIsConfirming] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isReverted, setIsReverted] = useState(false);
  const [revertError, setRevertError] = useState<Error | null>(null);

  const resetState = () => {
    setHash(undefined);
    setIsConfirming(false);
    setIsSuccess(false);
    setIsReverted(false);
    setRevertError(null);
  };

  const waitForReceipt = async (txHash: Hex): Promise<any> => {
    if (!publicClient) throw new Error('Public client not available');
    for (let i = 0; i < 30; i++) {
      try {
        return await publicClient.getTransactionReceipt({ hash: txHash });
      } catch (err: any) {
        if (err?.message?.includes('could not be found') || err?.message?.includes('not found')) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        } else {
          throw err;
        }
      }
    }
    throw new Error('等待交易确认超时');
  };

  /**
   * 终结市场
   * @param scaleBps 赔付缩放比例（基点，默认 10000 = 100%）
   *        - 0: 正常结算，超限时 revert
   *        - 1-10000: 按比例缩减赔付 + 储备金兜底
   */
  const finalizeMarket = async (scaleBps: bigint = 0n) => {
    if (!marketAddress) throw new Error('Market address required');
    if (!publicClient) throw new Error('Public client not available');

    console.log('[useFinalizeMarket] 终结市场:', { marketAddress, scaleBps });
    resetState();
    setIsConfirming(true);

    try {
      // 先模拟调用（必须指定 account 以检查权限）
      console.log('[useFinalizeMarket] 模拟调用检查...', { account: accountAddress });
      try {
        await publicClient.simulateContract({
          address: marketAddress,
          abi: Market_V3_ABI,
          functionName: 'finalize',
          args: [scaleBps],
          account: accountAddress, // 必须指定账户以正确检查权限
        });
        console.log('[useFinalizeMarket] 模拟调用成功');
      } catch (simError: any) {
        console.error('[useFinalizeMarket] 模拟调用失败:', simError);
        setIsConfirming(false);
        const errorMessage = extractErrorMessage(simError);
        setRevertError(new Error(errorMessage));
        throw new Error(errorMessage);
      }

      const txHash = await writeContractAsync({
        address: marketAddress,
        abi: Market_V3_ABI,
        functionName: 'finalize',
        args: [scaleBps],
      });

      console.log('[useFinalizeMarket] 交易已发送:', txHash);
      setHash(txHash);

      const txReceipt = await waitForReceipt(txHash);
      setIsConfirming(false);

      if (txReceipt.status === 'success') {
        setIsSuccess(true);
        console.log('[useFinalizeMarket] 终结成功！');
      } else {
        setIsReverted(true);
        setRevertError(new Error('交易被链上拒绝'));
      }

      return txHash;
    } catch (err: any) {
      console.error('[useFinalizeMarket] 交易失败:', err);
      setIsConfirming(false);
      const errorMessage = extractErrorMessage(err);
      console.log('[useFinalizeMarket] 解析后的错误消息:', errorMessage);
      setRevertError(new Error(errorMessage));
      throw err;
    }
  };

  return {
    finalizeMarket,
    isPending,
    isConfirming,
    isSuccess,
    isReverted,
    error: writeError || revertError,
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
