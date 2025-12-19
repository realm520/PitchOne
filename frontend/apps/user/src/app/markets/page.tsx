'use client';

import { Suspense } from 'react';
import dynamic from 'next/dynamic';
import { LoadingFallback } from '../../components/LoadingFallback';

const MarketsContent = dynamic(
  () => import('./MarketsContent').then((mod) => ({ default: mod.MarketsContent })),
  {
    ssr: false,
    loading: () => <LoadingFallback type="market" height="100vh" />,
  }
);

export default function MarketsPage() {
  return (
    <Suspense fallback={<LoadingFallback type="market" height="100vh" />}>
      <MarketsContent />
    </Suspense>
  );
}
