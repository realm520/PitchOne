'use client';

import { useParams } from 'next/navigation';
import dynamic from 'next/dynamic';
import { LoadingSpinner } from '@pitchone/ui';

const MarketDetailClient = dynamic(
  () => import('./MarketDetailClient').then((mod) => ({ default: mod.MarketDetailClient })),
  {
    ssr: false,
    loading: () => (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载市场详情..." />
      </div>
    ),
  }
);

export default function MarketDetailPage() {
  const params = useParams();
  const marketId = params.id as string;

  return <MarketDetailClient marketId={marketId} />;
}
