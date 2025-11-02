'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ConnectButton, useAccount } from '@pitchone/web3';

export function HomeClient() {
  const { address, isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <main className="relative flex min-h-screen flex-col items-center justify-center p-8 md:p-24 overflow-hidden">
      {/* 背景霓虹效果 */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-20 left-20 w-96 h-96 bg-neon-blue/10 rounded-full blur-3xl animate-pulse-slow"></div>
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-neon-purple/10 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: '1s' }}></div>
      </div>

      <div className="z-10 w-full max-w-6xl">
        {/* Hero Section */}
        <div className="text-center mb-16 animate-fade-in">
          <h1 className="text-6xl md:text-7xl font-bold mb-6">
            <span className="text-neon">Pitch</span>
            <span className="text-neon-purple">One</span>
            <span className="ml-4">⚽</span>
          </h1>
          <p className="text-xl md:text-2xl text-gray-400 mb-4">
            去中心化链上足球博彩平台
          </p>
          <p className="text-sm md:text-base text-gray-500 max-w-2xl mx-auto">
            全链透明 · 非托管资产 · 自动化结算 · 乐观式预言机
          </p>
        </div>

        {/* Connect Wallet */}
        <div className="flex justify-center mb-16 animate-slide-up">
          <ConnectButton />
        </div>

        {/* Status */}
        {mounted && isConnected && address && (
          <div className="text-center mb-12 animate-fade-in">
            <div className="inline-block px-6 py-3 bg-glass rounded-full border border-neon-green">
              <p className="text-sm text-neon-green font-mono">
                ✓ 已连接: {address.slice(0, 6)}...{address.slice(-4)}
              </p>
            </div>
          </div>
        )}

        {/* Feature Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
          <Link href="/markets" className="card-neon group cursor-pointer animate-slide-up" style={{ animationDelay: '0.1s' }}>
            <div className="text-4xl mb-4">📊</div>
            <h3 className="text-xl font-semibold mb-2 group-hover:text-neon transition-colors">市场列表</h3>
            <p className="text-gray-400 text-sm">浏览所有可下注的足球赛事市场</p>
          </Link>

          <Link href="/portfolio" className="card-neon group cursor-pointer animate-slide-up" style={{ animationDelay: '0.2s' }}>
            <div className="text-4xl mb-4">💼</div>
            <h3 className="text-xl font-semibold mb-2 group-hover:text-neon-purple transition-colors">我的头寸</h3>
            <p className="text-gray-400 text-sm">查看持仓、历史订单和盈亏统计</p>
          </Link>

          <Link href="/parlay" className="card-neon group cursor-pointer animate-slide-up" style={{ animationDelay: '0.3s' }}>
            <div className="text-4xl mb-4">🎯</div>
            <h3 className="text-xl font-semibold mb-2 group-hover:text-neon-green transition-colors">串关下注</h3>
            <p className="text-gray-400 text-sm">组合多场赛事，获取更高赔率</p>
          </Link>
        </div>

        {/* Tech Stack Info */}
        <div className="mt-16 text-center text-sm text-gray-600">
          <p>
            Powered by <span className="text-neon-blue">Next.js 15</span> ·{' '}
            <span className="text-neon-purple">wagmi v2</span> ·{' '}
            <span className="text-neon-green">The Graph</span>
          </p>
        </div>
      </div>
    </main>
  );
}
