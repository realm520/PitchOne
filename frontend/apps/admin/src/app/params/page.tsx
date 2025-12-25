'use client';

import { Card, Badge, Button } from '@pitchone/ui';
import { formatDistanceToNow, format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import Link from 'next/link';
import { useState, useMemo, useEffect } from 'react';
import { toast } from 'sonner';
import {
  useAccount,
  ConnectButton,
  useReadParams,
  useTimelockDelay,
  paramNameToKey,
  useProposeChange,
  useExecuteProposal,
  useCancelProposal,
  useProposals,
  type Proposal,
} from '@pitchone/web3';
import type { Hex } from 'viem';
import {
  PARAM_DEFINITIONS,
  CATEGORY_LABELS,
  ALL_PARAM_KEYS,
  formatParamValue,
  type ParamDefinition,
  type ParamCategoryType,
} from '@/lib/param-config';

// 参数卡片组件
function ParamCard({ param, value }: { param: ParamDefinition; value?: bigint }) {
  const category = CATEGORY_LABELS[param.category];
  const displayValue = value !== undefined ? value : param.defaultValue;

  return (
    <Card className="p-5 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
              {param.name}
            </h3>
            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${category.color}`}>
              {category.label}
            </span>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-2">
            {param.description}
          </p>
        </div>
      </div>

      <div className="space-y-2">
        <div className="flex items-baseline justify-between">
          <span className="text-xs text-gray-500 dark:text-gray-400">当前值</span>
          <span className="text-lg font-bold text-gray-900 dark:text-white">
            {formatParamValue(displayValue, param.divisor, param.decimals, param.unit)}
          </span>
        </div>

        {param.validator && (
          <div className="flex items-center justify-between">
            <span className="text-xs text-gray-500 dark:text-gray-400">验证范围</span>
            <span className="text-xs font-mono text-gray-600 dark:text-gray-300">
              {param.validator}
            </span>
          </div>
        )}

        <div className="pt-2 border-t dark:border-gray-700">
          <span className="text-xs font-mono text-gray-400 dark:text-gray-500">
            {param.key}
          </span>
        </div>
      </div>
    </Card>
  );
}

// 提案状态
const getProposalStatus = (proposal: Proposal) => {
  if (proposal.executed) {
    return {
      label: '已执行',
      color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      variant: 'success' as const
    };
  }
  if (proposal.cancelled) {
    return {
      label: '已取消',
      color: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
      variant: 'secondary' as const
    };
  }
  return {
    label: '待执行',
    color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
    variant: 'warning' as const
  };
};

// 提案行组件
function ProposalRow({
  proposalId,
  proposal,
  onExecute,
  onCancel,
  isExecuting,
  isCancelling,
}: {
  proposalId: Hex;
  proposal: Proposal;
  onExecute: (id: Hex) => void;
  onCancel: (id: Hex) => void;
  isExecuting: boolean;
  isCancelling: boolean;
}) {
  const status = getProposalStatus(proposal);
  const isPending = !proposal.executed && !proposal.cancelled;
  const canExecute = isPending && Date.now() >= Number(proposal.eta) * 1000;

  // 查找参数名称
  const paramDef = PARAM_DEFINITIONS.find(p => paramNameToKey(p.key) === proposal.key);
  const paramName = paramDef?.name || '未知参数';

  return (
    <tr className="hover:bg-gray-50 dark:hover:bg-gray-800 border-b dark:border-gray-700">
      <td className="py-4 px-4">
        <div className="flex flex-col">
          <span className="font-medium text-gray-900 dark:text-white">
            {paramName}
          </span>
          <span className="text-xs font-mono text-gray-500 dark:text-gray-400 mt-1">
            {proposal.key.slice(0, 10)}...
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-600 dark:text-gray-300">
            {proposal.oldValue.toString()}
          </span>
          <span className="text-gray-400">→</span>
          <span className="text-sm font-semibold text-blue-600 dark:text-blue-400">
            {proposal.newValue.toString()}
          </span>
        </div>
      </td>
      <td className="py-4 px-4">
        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${status.color}`}>
          {status.label}
        </span>
      </td>
      <td className="py-4 px-4">
        <span className="font-mono text-xs text-gray-600 dark:text-gray-300">
          {proposal.proposer.slice(0, 6)}...{proposal.proposer.slice(-4)}
        </span>
      </td>
      <td className="py-4 px-4">
        <div className="flex flex-col">
          {isPending && (
            <span className="text-xs text-orange-600 dark:text-orange-400">
              ETA: {formatDistanceToNow(Number(proposal.eta) * 1000, { addSuffix: true, locale: zhCN })}
            </span>
          )}
          {proposal.executed && (
            <span className="text-xs text-green-600 dark:text-green-400">
              已执行
            </span>
          )}
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="text-xs text-gray-600 dark:text-gray-300 max-w-xs truncate">
          {proposal.reason}
        </div>
      </td>
      <td className="py-4 px-4">
        <div className="flex gap-2">
          {canExecute && (
            <Button
              size="sm"
              variant="primary"
              onClick={() => onExecute(proposalId)}
              disabled={isExecuting}
            >
              {isExecuting ? '执行中...' : '执行'}
            </Button>
          )}
          {isPending && (
            <Button
              size="sm"
              variant="neon"
              onClick={() => onCancel(proposalId)}
              disabled={isCancelling}
            >
              {isCancelling ? '取消中...' : '取消'}
            </Button>
          )}
        </div>
      </td>
    </tr>
  );
}

export default function ParamsPage() {
  const { address, isConnected } = useAccount();
  const [selectedCategory, setSelectedCategory] = useState<ParamCategoryType | 'all'>('all');
  const [showCreateModal, setShowCreateModal] = useState(false);

  // 读取 Timelock 延迟
  const { timelockDelay } = useTimelockDelay();

  // 批量读取所有参数值
  const paramKeys = useMemo(
    () => PARAM_DEFINITIONS.map(p => p.key),
    []
  );
  const { values: paramValues, refetch: refetchParams } = useReadParams(paramKeys);

  // 提案操作 hooks
  const { executeProposal, isPending: isExecuting, isSuccess: executeSuccess } = useExecuteProposal();
  const { cancelProposal, isPending: isCancelling, isSuccess: cancelSuccess } = useCancelProposal();
  const { proposeChange, isPending: isProposing, isSuccess: proposeSuccess, isConfirming: isConfirmingPropose } = useProposeChange();

  // 按类别筛选参数
  const filteredParams = useMemo(() => {
    return PARAM_DEFINITIONS.filter(param =>
      selectedCategory === 'all' || param.category === selectedCategory
    );
  }, [selectedCategory]);

  // 从链上读取提案列表
  const { proposals, isLoading: isLoadingProposals, refetch: refetchProposals } = useProposals();

  // 监听交易成功后刷新提案列表
  useEffect(() => {
    if (proposeSuccess) {
      console.log('[ParamsPage] 提案创建成功，刷新列表');
      refetchProposals();
    }
  }, [proposeSuccess, refetchProposals]);

  useEffect(() => {
    if (executeSuccess) {
      console.log('[ParamsPage] 提案执行成功，刷新列表');
      refetchProposals();
      refetchParams();
    }
  }, [executeSuccess, refetchProposals, refetchParams]);

  useEffect(() => {
    if (cancelSuccess) {
      console.log('[ParamsPage] 提案取消成功，刷新列表');
      refetchProposals();
    }
  }, [cancelSuccess, refetchProposals]);

  const handleExecuteProposal = async (proposalId: Hex) => {
    try {
      await executeProposal(proposalId);
      // 刷新通过 useEffect 监听 executeSuccess 自动处理
    } catch (error) {
      console.error('执行提案失败:', error);
    }
  };

  const handleCancelProposal = async (proposalId: Hex) => {
    try {
      await cancelProposal(proposalId);
      // 刷新通过 useEffect 监听 cancelSuccess 自动处理
    } catch (error) {
      console.error('取消提案失败:', error);
    }
  };

  // 创建提案处理
  const [selectedParam, setSelectedParam] = useState<ParamDefinition | null>(null);
  const [newValueInput, setNewValueInput] = useState('');
  const [reason, setReason] = useState('');

  const handleCreateProposal = async () => {
    if (!selectedParam || !newValueInput || !reason) {
      toast.warning('请填写完整信息');
      return;
    }

    try {
      // 根据单位转换输入值
      let newValue: bigint;
      if (selectedParam.unit === 'bp') {
        // 百分比 -> bp (2.5% -> 250)
        newValue = BigInt(Math.round(parseFloat(newValueInput) * 100));
      } else if (selectedParam.unit === 'USDC') {
        // USDC -> wei (100 USDC -> 100_000_000)
        newValue = BigInt(Math.round(parseFloat(newValueInput) * 1_000_000));
      } else {
        // 其他类型直接转换
        newValue = BigInt(newValueInput);
      }

      console.log('[handleCreateProposal] 创建提案:', {
        param: selectedParam.key,
        newValue,
        reason,
      });

      await proposeChange(selectedParam.key, newValue, reason);

      // 成功后重置表单并关闭模态框
      setShowCreateModal(false);
      setSelectedParam(null);
      setNewValueInput('');
      setReason('');

      // 刷新通过 useEffect 监听 proposeSuccess 自动处理
      toast.success('提案已提交，等待确认...');
    } catch (error: any) {
      toast.error(`创建提案失败: ${error.cause || error.message || error}`);
    }
  };

  // 当选择参数时，自动填充当前值
  const handleParamSelect = (paramKey: string) => {
    const param = PARAM_DEFINITIONS.find(p => p.key === paramKey);
    if (!param) return;

    setSelectedParam(param);

    // 获取当前值
    const paramIndex = PARAM_DEFINITIONS.findIndex(p => p.key === paramKey);
    const currentValue = paramValues?.[paramIndex] || param.defaultValue;

    // 根据单位格式化当前值
    if (param.unit === 'bp') {
      setNewValueInput((Number(currentValue) / 100).toString());
    } else if (param.unit === 'USDC') {
      setNewValueInput((Number(currentValue) / 1_000_000).toString());
    } else {
      setNewValueInput(currentValue.toString());
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                参数配置管理
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                管理平台参数和 Timelock 提案
                {timelockDelay && ` · Timelock 延迟: ${Number(timelockDelay) / 86400} 天`}
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/">
                <Button variant="neon">
                  返回看板
                </Button>
              </Link>
              {isConnected ? (
                <>
                  <Button
                    variant="primary"
                    onClick={() => setShowCreateModal(true)}
                  >
                    创建提案
                  </Button>
                  <ConnectButton showBalance={false} />
                </>
              ) : (
                <ConnectButton showBalance={false} />
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Web3 连接提示 */}
        {!isConnected && (
          <Card className="p-6 mb-8 bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800">
            <div className="flex items-start">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-blue-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <h3 className="text-sm font-medium text-blue-800 dark:text-blue-200">
                  请连接钱包
                </h3>
                <div className="mt-2 text-sm text-blue-700 dark:text-blue-300">
                  <p>
                    连接 Web3 钱包以查看实时参数值和创建治理提案。
                    需要 PROPOSER_ROLE 权限才能创建提案。
                  </p>
                </div>
              </div>
            </div>
          </Card>
        )}

        {/* 参数列表部分 */}
        <div className="mb-12">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              参数列表
            </h2>

            {/* 类别筛选 */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => setSelectedCategory('all')}
                className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${selectedCategory === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                  }`}
              >
                全部 ({PARAM_DEFINITIONS.length})
              </button>
              {Object.entries(CATEGORY_LABELS).map(([key, { label }]) => {
                const count = PARAM_DEFINITIONS.filter(p => p.category === key).length;
                return (
                  <button
                    key={key}
                    onClick={() => setSelectedCategory(key as ParamCategoryType)}
                    className={`px-3 py-1 rounded-lg text-sm font-medium transition-colors ${selectedCategory === key
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                      }`}
                  >
                    {label} ({count})
                  </button>
                );
              })}
            </div>
          </div>

          {/* 参数网格 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredParams.map((param, index) => (
              <ParamCard
                key={param.key}
                param={param}
                value={paramValues?.[index]}
              />
            ))}
          </div>
        </div>

        {/* 提案列表部分 */}
        <div>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              变更提案
            </h2>
          </div>

          {/* 提案表格 */}
          {isLoadingProposals ? (
            <Card className="p-12 text-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                正在加载提案列表...
              </p>
            </Card>
          ) : proposals.length > 0 ? (
            <Card className="overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 dark:bg-gray-700/50 border-b dark:border-gray-700">
                    <tr>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        参数
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        变更
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        状态
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        提案者
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        时间
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        理由
                      </th>
                      <th className="py-3 px-4 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                        操作
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {proposals.map(({ id, proposal }) => (
                      <ProposalRow
                        key={id}
                        proposalId={id}
                        proposal={proposal}
                        onExecute={handleExecuteProposal}
                        onCancel={handleCancelProposal}
                        isExecuting={isExecuting}
                        isCancelling={isCancelling}
                      />
                    ))}
                  </tbody>
                </table>
              </div>
            </Card>
          ) : (
            <Card className="p-12 text-center">
              <div className="text-gray-400 dark:text-gray-500 mb-4">
                <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                暂无提案
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                还没有创建任何参数变更提案
              </p>
            </Card>
          )}
        </div>
      </div>

      {/* 创建提案模态框 */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black/50 dark:bg-black/70 flex items-center justify-center z-50 p-4">
          <Card className="w-full bg-white max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="p-2">
              {/* 标题 */}
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                  创建参数变更提案
                </h2>
                <button
                  onClick={() => setShowCreateModal(false)}
                  className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {/* 表单 */}
              <div className="space-y-3">
                {/* 参数选择 */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    选择参数
                  </label>
                  <select
                    value={selectedParam?.key || ''}
                    onChange={(e) => handleParamSelect(e.target.value)}
                    className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">-- 请选择参数 --</option>
                    {PARAM_DEFINITIONS.map((param) => {
                      const category = CATEGORY_LABELS[param.category];
                      return (
                        <option key={param.key} value={param.key}>
                          [{category.label}] {param.name}
                        </option>
                      );
                    })}
                  </select>
                  {selectedParam && (
                    <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                      {selectedParam.description}
                    </p>
                  )}
                </div>

                {/* 当前值显示 */}
                {selectedParam && (
                  <div className="p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                        当前值
                      </span>
                      <span className="text-lg font-bold text-gray-900 dark:text-white">
                        {(() => {
                          const paramIndex = PARAM_DEFINITIONS.findIndex(p => p.key === selectedParam.key);
                          const currentValue = paramValues?.[paramIndex] || selectedParam.defaultValue;
                          return formatParamValue(currentValue, selectedParam.divisor, selectedParam.decimals, selectedParam.unit);
                        })()}
                      </span>
                    </div>
                    {selectedParam.validator && (
                      <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                        验证范围: {selectedParam.validator}
                      </div>
                    )}
                  </div>
                )}

                {/* 新值输入 */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    新值
                    {selectedParam && (
                      <span className="ml-2 text-xs text-gray-500">
                        ({selectedParam.unit === 'bp' ? '百分比，如 2.5 表示 2.5%' : selectedParam.unit === 'USDC' ? 'USDC 数量' : '整数'})
                      </span>
                    )}
                  </label>
                  <input
                    type="text"
                    value={newValueInput}
                    onChange={(e) => setNewValueInput(e.target.value)}
                    placeholder={selectedParam?.unit === 'bp' ? '例如: 2.5' : selectedParam?.unit === 'USDC' ? '例如: 10000' : '例如: 2'}
                    className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    disabled={!selectedParam}
                  />
                  {selectedParam && newValueInput && (
                    <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                      将变更为:{' '}
                      <span className="font-semibold text-blue-600 dark:text-blue-400">
                        {(() => {
                          try {
                            if (selectedParam.unit === 'bp') {
                              return `${parseFloat(newValueInput).toFixed(2)}%`;
                            } else if (selectedParam.unit === 'USDC') {
                              return `${parseFloat(newValueInput).toLocaleString()} USDC`;
                            } else {
                              return newValueInput;
                            }
                          } catch {
                            return '无效值';
                          }
                        })()}
                      </span>
                    </p>
                  )}
                </div>

                {/* 变更理由 */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    变更理由
                  </label>
                  <textarea
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    placeholder="请说明参数变更的原因和目的..."
                    rows={4}
                    className="w-full px-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                  />
                  <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                    变更理由将公开显示在提案列表中，建议详细说明变更原因
                  </p>
                </div>

                {/* Timelock 提示 */}
                {timelockDelay && (
                  <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                    <div className="flex items-start">
                      <svg className="w-5 h-5 text-yellow-600 dark:text-yellow-400 mr-3 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
                      </svg>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-yellow-800 dark:text-yellow-200">
                          Timelock 延迟
                        </p>
                        <p className="mt-1 text-xs text-yellow-700 dark:text-yellow-300">
                          提案创建后需要等待 <strong>{Number(timelockDelay) / 86400} 天</strong> 才能执行，
                          给社区足够时间审查和反应。
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* 操作按钮 */}
                <div className="flex items-center justify-end gap-3 pt-4 border-t dark:border-gray-700">
                  <Button
                    variant="neon"
                    onClick={() => setShowCreateModal(false)}
                    disabled={isProposing}
                  >
                    取消
                  </Button>
                  <Button
                    variant="primary"
                    onClick={handleCreateProposal}
                    disabled={isProposing || !selectedParam || !newValueInput || !reason}
                  >
                    {isProposing ? '创建中...' : '创建提案'}
                  </Button>
                </div>
              </div>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
}
