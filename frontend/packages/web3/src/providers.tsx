'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { RainbowKitProvider, darkTheme, Theme } from '@rainbow-me/rainbowkit';
import merge from 'lodash.merge';
import '@rainbow-me/rainbowkit/styles.css';
import { config } from './wagmi';
import { ReactNode, useState } from 'react';

// 创建完整的项目主题 - 使用 merge 深度覆盖（纯黑白极简风）
const projectTheme = merge(darkTheme(), {
  colors: {
    // 强调色（用于主要按钮、选中状态）- 白色
    accentColor: '#ffffff',
    accentColorForeground: '#09090b',

    // 模态框
    modalBackground: '#18181b',
    modalBorder: '#3f3f46',
    modalText: '#fafafa',
    modalTextDim: '#71717a',
    modalTextSecondary: '#a1a1aa',
    modalBackdrop: 'rgba(0, 0, 0, 0.7)',

    // 操作按钮（钱包选择按钮等）
    actionButtonBorder: '#3f3f46',
    actionButtonBorderMobile: '#3f3f46',
    actionButtonSecondaryBackground: '#27272a',

    // 连接按钮
    connectButtonBackground: '#18181b',
    connectButtonBackgroundError: '#27272a',
    connectButtonInnerBackground: '#27272a',
    connectButtonText: '#fafafa',
    connectButtonTextError: '#a1a1aa',

    // 关闭按钮
    closeButton: '#a1a1aa',
    closeButtonBackground: '#27272a',

    // 菜单和选择
    menuItemBackground: '#27272a',
    selectedOptionBorder: '#ffffff',

    // 配置文件操作（断开连接等按钮）
    profileAction: '#27272a',
    profileActionHover: '#3f3f46',
    profileForeground: '#18181b',

    // 通用
    generalBorder: '#3f3f46',
    generalBorderDim: '#27272a',
    connectionIndicator: '#ffffff',
    standby: '#a1a1aa',
    error: '#71717a',

    // 下载卡片（钱包下载提示）
    downloadBottomCardBackground: '#18181b',
    downloadTopCardBackground: '#27272a',
  },
  radii: {
    actionButton: '8px',
    connectButton: '8px',
    menuButton: '8px',
    modal: '16px',
    modalMobile: '16px',
  },
  shadows: {
    connectButton: '0 4px 6px -1px rgba(0, 0, 0, 0.3)',
    dialog: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
    profileDetailsAction: '0 2px 4px rgba(0, 0, 0, 0.2)',
    selectedOption: '0 0 0 2px #ffffff',
    selectedWallet: '0 0 0 2px #ffffff',
    walletLogo: '0 2px 4px rgba(0, 0, 0, 0.2)',
  },
} as Theme);

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
        <RainbowKitProvider theme={projectTheme}>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
