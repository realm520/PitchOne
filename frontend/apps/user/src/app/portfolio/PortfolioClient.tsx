'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { formatUnits } from 'viem';
import {
  useAccount,
  useUserPositions,
  MarketStatus,
  TOKEN_DECIMALS,
  getOutcomeName as getOutcomeNameFromConstants,
  type Position,
} from '@pitchone/web3';
import {
  Container,
  Card,
  Badge,
  Button,
  LoadingSpinner,
  EmptyState,
  ErrorState,
} from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import PortfoliaHeader from './PortfolioHeader';
import UnLogin from './un-login';
import MyTickets from './MyTickets';

type TabType = 'active' | 'settled' | 'all';

export function PortfolioClient() {
  const { t, translateTeam } = useTranslation();
  const { address, isConnected } = useAccount();
  const [mounted, setMounted] = useState(false);
  const [activeTab, setActiveTab] = useState<TabType>('active');

  const { data: positions, isLoading, error } = useUserPositions(address);

  useEffect(() => {
    setMounted(true);
  }, []);

  // 调试日志：查看实际加载的预测数据
  useEffect(() => {
    if (positions && positions.length > 0) {
      console.log('[Portfolio] 加载的预测数据:', positions);
      console.log('[Portfolio] 第一个预测详情:', {
        id: positions[0].id,
        balance: positions[0].balance,
        totalInvested: positions[0].totalInvested,
        averageCost: positions[0].averageCost,
        market: positions[0].market,
      });
    }
  }, [positions]);

  // 计算统计数据
  const stats = (() => {
    if (!positions || positions.length === 0) {
      return {
        totalBetAmount: 0,
        totalMarkets: 0,
        totalBets: 0,
        totalProfit: 0,
      };
    }

    // 总投注额：所有头寸的 totalInvested 之和
    const totalBetAmount = positions.reduce((sum, pos) => {
      const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;
      return sum + invested;
    }, 0);

    // 投注市场数：去重的市场数量
    const uniqueMarkets = new Set(positions.map((pos) => pos.market.id));
    const totalMarkets = uniqueMarkets.size;

    // 总投注次数：头寸数量
    const totalBets = positions.length;

    // 盈利金额：已结算且赢得的头寸的收益 - 已结算且输掉的投注额
    const totalProfit = positions.reduce((sum, pos) => {
      const invested = pos.totalInvested ? parseFloat(pos.totalInvested) : 0;

      // 只计算已结算的市场
      if (pos.market.state === MarketStatus.Resolved || pos.market.state === MarketStatus.Finalized) {
        if (pos.market.winnerOutcome !== undefined && pos.market.winnerOutcome === pos.outcome) {
          // 赢了：预期收益 - 投入
          const expectedPayout = calculateExpectedPayout(pos);
          return sum + (expectedPayout - invested);
        } else {
          // 输了：损失全部投入
          return sum - invested;
        }
      }
      return sum;
    }, 0);

    return {
      totalBetAmount,
      totalMarkets,
      totalBets,
      totalProfit,
    };
  })();

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };


  const calculateExpectedPayout = (position: Position) => {
    try {
      // 预期收益 = 持有份额（假设赢了的话，1 share = 1 USDC）
      // balance 存储的是 USDC 单位（6 位小数），不是 ETH（18 位小数）
      if (!position.balance || position.balance === '0') {
        // 如果 balance 为 0，尝试使用 totalInvested 估算（假设赔率约 2.0）
        if (position.totalInvested) {
          const invested = parseFloat(position.totalInvested);
          return invested * 1.8; // 估算 80% 收益
        }
        return 0;
      }

      // 将 balance（USDC）转换为标准单位
      const balanceInUSDC = BigInt(position.balance);
      const shares = parseFloat(formatUnits(balanceInUSDC, TOKEN_DECIMALS.USDC));

      console.log('[Portfolio] 预测收益计算:', {
        positionId: position.id,
        balance: position.balance,
        shares,
        totalInvested: position.totalInvested,
      });

      return shares;
    } catch (error) {
      console.error('[Portfolio] 计算预期收益失败:', error, position);
      return 0;
    }
  };

  const getStatusBadge = (status: MarketStatus) => {
    const variants = {
      [MarketStatus.Open]: { variant: 'success' as const, label: t('portfolio.status.open') },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: t('portfolio.status.locked') },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: t('portfolio.status.resolved') },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: t('portfolio.status.finalized') },
    };
    const config = variants[status];
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  const filteredPositions = positions?.filter((pos) => {
    if (activeTab === 'active') {
      return pos.market.state === MarketStatus.Open || pos.market.state === MarketStatus.Locked;
    }
    if (activeTab === 'settled') {
      return pos.market.state === MarketStatus.Resolved || pos.market.state === MarketStatus.Finalized;
    }
    return true;
  });

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="lg">
        {/* Header */}
        {!isConnected || !mounted ? (
          <UnLogin />
        ) : (
          <div className='flex flex-col gap-6'>
            <PortfoliaHeader />
            <MyTickets />
          </div>
        )}
      </Container>
    </div>
  );
}
