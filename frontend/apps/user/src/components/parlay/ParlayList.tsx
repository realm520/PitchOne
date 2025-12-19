'use client';

import { useUserParlays, useAccount } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, EmptyState } from '@pitchone/ui';
import { ParlayCard } from './ParlayCard';

export interface ParlayListProps {
  userAddress?: `0x${string}`;
  limit?: number;
}

/**
 * 串关列表组件
 * 展示用户的所有串关
 */
export function ParlayList({ userAddress, limit }: ParlayListProps) {
  const { address } = useAccount();
  const targetAddress = userAddress || address;

  const { parlayIds, isLoading, isError, error } = useUserParlays(targetAddress);

  // 应用数量限制
  const displayedParlayIds = limit ? parlayIds.slice(0, limit) : parlayIds;

  if (isLoading) {
    return (
      <Card className="w-full">
        <div className="flex items-center justify-center py-12">
          <LoadingSpinner />
          <span className="ml-3 text-gray-400">加载串关列表...</span>
        </div>
      </Card>
    );
  }

  if (isError) {
    return (
      <Card className="w-full">
        <ErrorState
          message={error?.message || '加载串关列表失败'}
          onRetry={() => window.location.reload()}
        />
      </Card>
    );
  }

  if (parlayIds.length === 0) {
    return (
      <Card className="w-full">
        <EmptyState
          title="暂无串关"
          description="你还没有创建任何串关，去市场页面创建你的第一个串关吧！"
        />
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-white">
          我的串关 ({parlayIds.length})
        </h2>
        {limit && parlayIds.length > limit && (
          <span className="text-sm text-gray-400">
            显示最近 {limit} 条
          </span>
        )}
      </div>

      {/* 串关卡片列表 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {displayedParlayIds.map((parlayId) => (
          <ParlayCard key={parlayId} parlayId={parlayId} />
        ))}
      </div>

      {/* 查看更多提示 */}
      {limit && parlayIds.length > limit && (
        <div className="text-center">
          <a
            href="/portfolio?tab=parlays"
            className="text-zinc-400 hover:text-white text-sm font-semibold"
          >
            查看全部 {parlayIds.length} 个串关 →
          </a>
        </div>
      )}
    </div>
  );
}
