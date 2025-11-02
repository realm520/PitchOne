'use client';

import { ConnectButton, useAccount } from '@pitchone/web3';

export default function HomePage() {
  const { address, isConnected } = useAccount();

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold text-center mb-8">
          PitchOne ⚽
        </h1>
        <p className="text-center text-lg text-gray-600 dark:text-gray-400">
          去中心化链上足球博彩平台
        </p>

        <div className="mt-12 flex justify-center">
          <ConnectButton />
        </div>

        {isConnected && address && (
          <div className="mt-8 text-center">
            <p className="text-sm text-green-500">
              ✓ 已连接: {address.slice(0, 6)}...{address.slice(-4)}
            </p>
          </div>
        )}

        <div className="mt-8 text-center">
          <p className="text-sm text-gray-500">
            RainbowKit + wagmi 配置成功 ✓
          </p>
        </div>
      </div>
    </main>
  );
}
