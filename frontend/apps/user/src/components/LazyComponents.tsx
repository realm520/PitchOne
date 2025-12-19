'use client';

import dynamic from 'next/dynamic';
import { LoadingFallback } from './LoadingFallback';

// Chart components lazy loading
export const LazyPriceTrendChart = dynamic(
  () => import('./charts/PriceTrendChart').then((mod) => ({ default: mod.PriceTrendChart })),
  {
    loading: () => <LoadingFallback type="chart" height="300px" />,
    ssr: false,
  }
);

export const LazyVolumeChart = dynamic(
  () => import('./charts/VolumeChart').then((mod) => ({ default: mod.VolumeChart })),
  {
    loading: () => <LoadingFallback type="chart" height="300px" />,
    ssr: false,
  }
);

export const LazyDepthChart = dynamic(
  () => import('./charts/DepthChart').then((mod) => ({ default: mod.DepthChart })),
  {
    loading: () => <LoadingFallback type="chart" height="300px" />,
    ssr: false,
  }
);

// Live activity component lazy loading
export const LazyLiveActivity = dynamic(
  () => import('./LiveActivity').then((mod) => ({ default: mod.LiveActivity })),
  {
    loading: () => <LoadingFallback type="activity" height="200px" />,
    ssr: false,
  }
);
