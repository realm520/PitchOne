'use client';

import dynamic from 'next/dynamic';
import { LoadingSpinner } from '@pitchone/ui';

/**
 * 懒加载组件包装器
 * 提供统一的加载状态
 */

// 图表组件懒加载
export const LazyPriceTrendChart = dynamic(
  () => import('./charts/PriceTrendChart').then((mod) => ({ default: mod.PriceTrendChart })),
  {
    loading: () => (
      <div className="h-[300px] flex items-center justify-center">
        <LoadingSpinner text="加载图表..." />
      </div>
    ),
    ssr: false, // 图表组件不需要服务端渲染
  }
);

export const LazyVolumeChart = dynamic(
  () => import('./charts/VolumeChart').then((mod) => ({ default: mod.VolumeChart })),
  {
    loading: () => (
      <div className="h-[300px] flex items-center justify-center">
        <LoadingSpinner text="加载图表..." />
      </div>
    ),
    ssr: false,
  }
);

export const LazyDepthChart = dynamic(
  () => import('./charts/DepthChart').then((mod) => ({ default: mod.DepthChart })),
  {
    loading: () => (
      <div className="h-[300px] flex items-center justify-center">
        <LoadingSpinner text="加载图表..." />
      </div>
    ),
    ssr: false,
  }
);

// 实时活动组件懒加载
export const LazyLiveActivity = dynamic(() => import('./LiveActivity').then((mod) => ({ default: mod.LiveActivity })), {
  loading: () => (
    <div className="h-[200px] flex items-center justify-center">
      <LoadingSpinner text="加载活动流..." />
    </div>
  ),
  ssr: false,
});
