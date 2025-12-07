'use client';

import { Suspense } from 'react';
import dynamic from 'next/dynamic';
import { LoadingSpinner } from '@pitchone/ui';

const MarketsContent = dynamic(
  () => import('./markets/MarketsContent').then((mod) => ({ default: mod.MarketsContent })),
  {
    ssr: false,
    loading: () => (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载市场数据..." />
      </div>
    ),
  }
);

export default function HomePage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载市场数据..." />
      </div>
    }>
      <MarketsContent />
    </Suspense>
  );
}
