'use client';

import { Suspense } from 'react';
import dynamic from 'next/dynamic';
import { LoadingSpinner } from '@pitchone/ui';

const PortfolioClient = dynamic(
  () => import('./PortfolioClient').then((mod) => ({ default: mod.PortfolioClient })),
  {
    ssr: false,
    loading: () => (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载头寸数据..." />
      </div>
    ),
  }
);

export default function PortfolioPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载头寸数据..." />
      </div>
    }>
      <PortfolioClient />
    </Suspense>
  );
}
