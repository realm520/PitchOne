'use client';

import dynamic from 'next/dynamic';
import { ReactNode } from 'react';

// 动态导入 Providers，禁用 SSR 以避免 RainbowKit 的 localStorage 错误
const Web3Providers = dynamic(
  () => import('@pitchone/web3').then((mod) => mod.Providers),
  { ssr: false }
);

interface ClientProvidersProps {
  children: ReactNode;
}

export function ClientProviders({ children }: ClientProvidersProps) {
  return <Web3Providers>{children}</Web3Providers>;
}
