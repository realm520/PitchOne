'use client';

import { useState, useEffect } from 'react';
import { useAccount } from '@pitchone/web3';
import { useBindReferral, useGetReferrer } from '@pitchone/web3';
import { type Address, isAddress } from 'viem';
import { Card, Button } from '@pitchone/ui';

/**
 * ReferralManualBinder 组件
 *
 * 功能：
 * 1. 提供手动输入推荐人地址的界面
 * 2. 验证地址格式和有效性
 * 3. 执行推荐关系绑定
 * 4. 显示绑定状态和反馈
 *
 * 使用场景：
 * - 用户没有通过推荐链接访问
 * - URL 参数丢失
 * - 用户主动想要绑定特定推荐人
 *
 * @example
 * ```tsx
 * import { ReferralManualBinder } from '@/components/referral/ReferralManualBinder';
 *
 * export default function ReferralPage() {
 *   return (
 *     <div>
 *       <ReferralManualBinder />
 *     </div>
 *   );
 * }
 * ```
 */
export function ReferralManualBinder() {
  const { address, isConnected } = useAccount();
  const { bindReferral, isPending, isConfirming, isSuccess, error } = useBindReferral();
  const { data: existingReferrer, isLoading: isLoadingReferrer, refetch } = useGetReferrer(address);

  const [referrerInput, setReferrerInput] = useState('');
  const [validationError, setValidationError] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);

  // 避免 hydration 错误
  useEffect(() => {
    setMounted(true);
  }, []);

  // 重置表单并刷新推荐人数据（绑定成功后）
  useEffect(() => {
    if (isSuccess) {
      setReferrerInput('');
      setValidationError(null);
      // 刷新推荐人数据
      refetch();
    }
  }, [isSuccess, refetch]);

  /**
   * 验证推荐人地址
   */
  const validateReferrer = (inputAddress: string): boolean => {
    // 清空之前的错误
    setValidationError(null);

    // 检查是否为空
    if (!inputAddress.trim()) {
      setValidationError('请输入推荐人地址');
      return false;
    }

    // 检查地址格式
    if (!isAddress(inputAddress)) {
      setValidationError('无效的以太坊地址格式');
      return false;
    }

    // 防止自我推荐
    if (address && inputAddress.toLowerCase() === address.toLowerCase()) {
      setValidationError('不能绑定自己为推荐人');
      return false;
    }

    return true;
  };

  /**
   * 处理绑定操作
   */
  const handleBind = async () => {
    if (!validateReferrer(referrerInput)) {
      return;
    }

    try {
      await bindReferral(referrerInput as Address, 0n);
    } catch (err) {
      console.error('[ReferralManualBinder] 绑定失败:', err);
    }
  };

  /**
   * 处理输入变化
   */
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setReferrerInput(e.target.value.trim());
    // 清除验证错误（用户开始输入时）
    if (validationError) {
      setValidationError(null);
    }
  };

  // 客户端挂载前，显示加载状态
  if (!mounted) {
    return null;
  }

  // 未连接钱包
  if (!isConnected) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <svg
            className="w-12 h-12 mx-auto mb-4 text-gray-500"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
          <p className="text-gray-400 text-sm">请先连接钱包以绑定推荐人</p>
        </div>
      </Card>
    );
  }

  // 加载推荐人状态
  if (isLoadingReferrer) {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <div className="w-12 h-12 mx-auto mb-4 animate-pulse bg-gray-700 rounded-full" />
          <p className="text-gray-400 text-sm">加载中...</p>
        </div>
      </Card>
    );
  }

  // 已绑定推荐人
  if (existingReferrer && existingReferrer !== '0x0000000000000000000000000000000000000000') {
    return (
      <Card padding="lg">
        <div className="text-center py-8">
          <div className="w-12 h-12 mx-auto mb-4 rounded-full bg-green-500/20 flex items-center justify-center">
            <svg className="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <p className="text-white font-medium mb-2">您已绑定推荐人</p>
          <p className="text-sm text-gray-400 mb-4">
            推荐人地址：
            <code className="ml-2 px-2 py-1 bg-dark-card border border-dark-border rounded text-neon-blue">
              {existingReferrer.slice(0, 6)}...{existingReferrer.slice(-4)}
            </code>
          </p>
          <p className="text-xs text-gray-500">
            推荐关系一旦绑定，无法更改
          </p>
        </div>
      </Card>
    );
  }

  // 显示手动绑定表单
  return (
    <Card padding="lg">
      {/* 标题 */}
      <div className="mb-6">
        <h3 className="text-lg font-bold text-white mb-2">绑定推荐人</h3>
        <p className="text-sm text-gray-400">
          如果您有推荐人，请输入其钱包地址进行绑定
        </p>
      </div>

      {/* 输入表单 */}
      <div className="space-y-4">
        <div>
          <label htmlFor="referrer-input" className="block text-sm font-medium text-gray-300 mb-2">
            推荐人地址
          </label>
          <input
            id="referrer-input"
            type="text"
            value={referrerInput}
            onChange={handleInputChange}
            placeholder="0x..."
            disabled={isPending || isConfirming}
            className={`w-full px-4 py-3 bg-dark-card border rounded-lg text-white text-sm focus:outline-none transition-colors ${
              validationError
                ? 'border-red-500 focus:border-red-500'
                : 'border-dark-border focus:border-neon-blue'
            } ${isPending || isConfirming ? 'opacity-50 cursor-not-allowed' : ''}`}
          />
          {validationError && (
            <p className="mt-2 text-sm text-red-500 flex items-center gap-1">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              {validationError}
            </p>
          )}
        </div>

        {/* 绑定按钮 */}
        <Button
          onClick={handleBind}
          variant="primary"
          size="lg"
          className="w-full"
          disabled={!referrerInput || isPending || isConfirming}
        >
          {isPending || isConfirming ? (
            <>
              <div className="w-5 h-5 mr-2 border-2 border-white border-t-transparent rounded-full animate-spin" />
              {isPending ? '等待确认...' : '绑定中...'}
            </>
          ) : (
            '绑定推荐人'
          )}
        </Button>

        {/* 错误提示 */}
        {error && (
          <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
            <div className="flex items-start gap-3">
              <svg className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
              <div className="flex-1">
                <p className="text-sm font-medium text-red-400">绑定失败</p>
                <p className="text-xs text-gray-400 mt-1">
                  {error.message || '未知错误，请重试'}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* 成功提示 */}
        {isSuccess && (
          <div className="p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
            <div className="flex items-start gap-3">
              <svg className="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
              <div className="flex-1">
                <p className="text-sm font-medium text-green-400">绑定成功！</p>
                <p className="text-xs text-gray-400 mt-1">
                  您已成功绑定推荐人，现在可以享受推荐奖励
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 提示信息 */}
      <div className="mt-6 p-4 bg-neon-blue/10 border border-neon-blue/30 rounded-lg">
        <div className="flex gap-3">
          <svg className="w-5 h-5 text-neon-blue flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div className="text-sm text-gray-300">
            <p className="font-medium mb-2">注意事项</p>
            <ul className="space-y-1 text-xs text-gray-400">
              <li>• 推荐关系一旦绑定，<strong className="text-neon-blue">无法更改</strong></li>
              <li>• 不能绑定自己为推荐人</li>
              <li>• 请确保推荐人地址正确无误</li>
              <li>• 绑定后，推荐人将获得您下注手续费的 8% 返佣</li>
            </ul>
          </div>
        </div>
      </div>

      {/* 跳过按钮 */}
      <div className="mt-4 text-center">
        <button
          onClick={() => setReferrerInput('')}
          className="text-sm text-gray-500 hover:text-gray-400 transition-colors"
        >
          暂时跳过
        </button>
      </div>
    </Card>
  );
}
