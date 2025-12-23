'use client';

import { useEffect, useState } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { useAccount } from '@pitchone/web3';
import { useBindReferral, useGetReferrer } from '@pitchone/web3';
import { type Address, isAddress } from 'viem';
import { Card } from '@pitchone/ui';

/**
 * ReferralBinder 组件
 *
 * 功能：
 * 1. 检测 URL 参数中的 `ref` 参数（推荐人地址）
 * 2. 自动触发绑定推荐人关系
 * 3. 显示绑定状态和结果
 * 4. 绑定成功后从 URL 中移除 ref 参数
 *
 * 使用方式：
 * 在应用的根布局中添加此组件，例如 /app/layout.tsx 或 /app/page.tsx
 *
 * @example
 * ```tsx
 * import { ReferralBinder } from '@/components/referral/ReferralBinder';
 *
 * export default function Layout({ children }) {
 *   return (
 *     <>
 *       <ReferralBinder />
 *       {children}
 *     </>
 *   );
 * }
 * ```
 */
export function ReferralBinder() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { address, isConnected } = useAccount();
  const { bindReferral, isPending, isConfirming, isSuccess, error } = useBindReferral();
  const { data: existingReferrer } = useGetReferrer(address);

  const [bindingStatus, setBindingStatus] = useState<'idle' | 'binding' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showNotification, setShowNotification] = useState(false);

  useEffect(() => {
    // 从 URL 参数中获取推荐人地址
    const refParam = searchParams?.get('ref');

    if (!refParam || !isConnected || !address) {
      return;
    }

    // 验证推荐人地址格式
    if (!isAddress(refParam)) {
      console.warn('[ReferralBinder] 无效的推荐人地址:', refParam);
      return;
    }

    // 检查用户是否已经绑定了推荐人
    if (existingReferrer && existingReferrer !== '0x0000000000000000000000000000000000000000') {
      console.log('[ReferralBinder] 用户已绑定推荐人:', existingReferrer);
      cleanupUrl();
      return;
    }

    // 防止自己推荐自己
    if (refParam.toLowerCase() === address.toLowerCase()) {
      console.warn('[ReferralBinder] 不能绑定自己为推荐人');
      setBindingStatus('error');
      setErrorMessage('不能绑定自己为推荐人');
      setShowNotification(true);
      cleanupUrl();
      return;
    }

    // 执行绑定
    handleBind(refParam as Address);
  }, [searchParams, isConnected, address, existingReferrer]);

  // 处理绑定成功
  useEffect(() => {
    if (isSuccess) {
      setBindingStatus('success');
      setShowNotification(true);
      cleanupUrl();

      // 3秒后隐藏通知
      setTimeout(() => {
        setShowNotification(false);
      }, 3000);
    }
  }, [isSuccess]);

  // 处理绑定失败
  useEffect(() => {
    if (error) {
      setBindingStatus('error');
      setErrorMessage(error.message || '绑定失败');
      setShowNotification(true);

      // 5秒后隐藏通知
      setTimeout(() => {
        setShowNotification(false);
      }, 5000);
    }
  }, [error]);

  /**
   * 执行推荐人绑定
   */
  const handleBind = async (referrerAddress: Address) => {
    try {
      setBindingStatus('binding');
      console.log('[ReferralBinder] 开始绑定推荐人:', referrerAddress);

      await bindReferral(referrerAddress, 0n); // 默认 campaignId = 0
    } catch (err) {
      console.error('[ReferralBinder] 绑定失败:', err);
    }
  };

  /**
   * 从 URL 中移除 ref 参数
   */
  const cleanupUrl = () => {
    const params = new URLSearchParams(searchParams?.toString());
    params.delete('ref');

    const newUrl = params.toString()
      ? `${window.location.pathname}?${params.toString()}`
      : window.location.pathname;

    router.replace(newUrl);
  };

  // 不显示任何 UI（仅后台处理）
  // 如果需要显示通知，可以返回一个 Toast/Notification 组件
  if (!showNotification) {
    return null;
  }

  return (
    <div className="fixed top-4 right-4 z-50 animate-slide-in">
      <Card padding="md" className="shadow-lg max-w-md">
        {bindingStatus === 'binding' && (
          <div className="flex items-center gap-3">
            <div className="w-5 h-5 border-2 border-accent border-t-transparent rounded-full animate-spin" />
            <div>
              <p className="text-sm font-medium text-white">绑定推荐人中...</p>
              <p className="text-xs text-gray-500">请确认钱包交易</p>
            </div>
          </div>
        )}

        {bindingStatus === 'success' && (
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-green-500/20 flex items-center justify-center">
              <svg className="w-6 h-6 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-medium text-white">绑定成功！</p>
              <p className="text-xs text-gray-500">您已成功绑定推荐人</p>
            </div>
          </div>
        )}

        {bindingStatus === 'error' && (
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center">
              <svg className="w-6 h-6 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <div>
              <p className="text-sm font-medium text-white">绑定失败</p>
              <p className="text-xs text-gray-500">{errorMessage}</p>
            </div>
          </div>
        )}
      </Card>
    </div>
  );
}
