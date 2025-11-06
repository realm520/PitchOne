'use client';

import { Providers as Web3Providers } from '@pitchone/web3';

export function Providers({ children }: { children: React.ReactNode }) {
  // 直接使用 @pitchone/web3 的 Providers，它已经包含了：
  // - WagmiProvider（Web3 连接）
  // - QueryClientProvider（React Query）
  // - RainbowKitProvider（钱包连接 UI）
  return (
    <Web3Providers>
      {children}
    </Web3Providers>
  );
}
