'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { config } from './wagmi';
import { ReactNode, useState } from 'react';

interface ProvidersProps {
  children: ReactNode;
}

export function Providers({ children }: ProvidersProps) {
  // 创建 React Query client (每个组件实例创建一次)
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        // 默认缓存配置
        staleTime: 30 * 1000, // 30 秒 - 数据多久后被视为陈旧
        gcTime: 5 * 60 * 1000, // 5 分钟 - 未使用的缓存保留时间
        refetchOnWindowFocus: false, // 窗口聚焦时不自动重新获取
        refetchOnReconnect: true, // 网络重连时重新获取
        retry: 2, // 失败重试 2 次
        retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000), // 指数退避
      },
    },
  }));

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          theme={darkTheme({
            accentColor: '#00D4FF', // 霓虹蓝
            accentColorForeground: 'white',
            borderRadius: 'medium',
            fontStack: 'system',
          })}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
