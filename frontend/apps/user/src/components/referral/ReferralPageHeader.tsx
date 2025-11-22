'use client';

import { useState, useEffect } from 'react';
import { useReferralParams } from '@pitchone/web3';

/**
 * ReferralPageHeader 组件
 *
 * 功能：
 * 1. 显示推荐中心页面标题和描述
 * 2. 动态显示从合约读取的返佣比例
 *
 * @example
 * ```tsx
 * import { ReferralPageHeader } from '@/components/referral/ReferralPageHeader';
 *
 * export default function ReferralPage() {
 *   return <ReferralPageHeader />;
 * }
 * ```
 */
export function ReferralPageHeader() {
  const { feeBps, isLoading } = useReferralParams();
  // 确保服务器端和客户端首次渲染一致，避免 hydration 错误
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const feePercentage = feeBps
    ? (Number(feeBps) / 100).toFixed(2)
    : '8.00'; // 默认值

  // 服务器端和客户端首次渲染都显示 loading 状态
  const showLoading = !isMounted || isLoading;

  return (
    <div className="mb-8">
      <h1 className="text-3xl font-bold text-white mb-2">推荐中心</h1>
      <p className="text-gray-400">
        分享您的推荐链接，邀请好友加入 PitchOne，获得{' '}
        {showLoading ? (
          <span className="inline-block w-8 h-4 bg-gray-600 animate-pulse rounded" />
        ) : (
          <span className="text-neon-green font-semibold">{feePercentage}%</span>
        )}{' '}
        返佣奖励
      </p>
    </div>
  );
}
