'use client';

import { useParams } from 'next/navigation';
import dynamic from 'next/dynamic';
import { LoadingFallback } from '../../../components/LoadingFallback';

const MarketDetailClient = dynamic(
  () => import('./MarketDetailClient').then((mod) => ({ default: mod.MarketDetailClient })),
  {
    ssr: false,
    loading: () => <LoadingFallback type="marketDetail" height="100vh" />,
  }
);

export default function MarketDetailPage() {
  const params = useParams();
  const marketId = params.id as string;

  return <MarketDetailClient marketId={marketId} />;
}
