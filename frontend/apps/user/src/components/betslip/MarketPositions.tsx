'use client';

import { useMemo, useEffect } from 'react';
import { ShieldCheck, BadgeCheck } from 'lucide-react';
import { useAccount, useUserPositions, Position } from '@pitchone/web3';
import { Card } from '@pitchone/ui';
import { useTranslation } from '@pitchone/i18n';
import { useBetSlipStore } from '../../lib/betslip-store';
import {
  getSelection,
  calculateOdds,
  calculateExpectedPayout,
  formatDate,
  formatUSDC,
  getOriginalPayment,
} from '../../app/portfolio/utils';

interface MarketPositionsProps {
  className?: string;
  // 可选：直接传入 marketId（用于详情页）
  marketId?: string;
}

export function MarketPositions({ className, marketId: propMarketId }: MarketPositionsProps) {
  const { t, translateTeam } = useTranslation();
  const { address } = useAccount();
  const { selectedMarket, refreshCounter } = useBetSlipStore();

  // 优先使用 props 传入的 marketId（详情页），否则使用 store 中选中的市场
  const targetMarketId = propMarketId || selectedMarket?.marketId;

  // 获取用户所有持仓
  const { data: positions, isLoading, refetch } = useUserPositions(address);

  // 监听刷新信号，下单后刷新持仓数据
  useEffect(() => {
    if (refreshCounter > 0) {
      refetch();
    }
  }, [refreshCounter, refetch]);

  // 过滤出当前市场的持仓
  const marketPositions = useMemo(() => {
    if (!positions || !targetMarketId) return [];
    return positions.filter(
      (p) => p.market.id.toLowerCase() === targetMarketId.toLowerCase()
    );
  }, [positions, targetMarketId]);

  // 如果没有选中市场且没有传入 marketId，不显示组件
  if (!targetMarketId) {
    return null;
  }

  return (
    <Card
      className={`p-0 bg-dark-card border border-dark-border ${className || ''}`}
    >
      {/* 标题 */}
      <div className="px-4 py-3 border-b border-dark-border">
        <h3 className="text-sm font-bold text-white tracking-wide uppercase">
          {t('marketPositions.title')}
        </h3>
      </div>

      <div className="p-4">
        {isLoading ? (
          <div className="text-center text-gray-500 py-4">
            {t('common.loading')}
          </div>
        ) : marketPositions.length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            {t('marketPositions.empty')}
          </div>
        ) : (
          <div className="space-y-3">
            {marketPositions.map((position) => (
              <PositionCard
                key={position.id}
                position={position}
                translateTeam={translateTeam}
                t={t}
              />
            ))}
          </div>
        )}
      </div>
    </Card>
  );
}

// 单个持仓卡片
interface PositionCardProps {
  position: Position;
  translateTeam: (team: string) => string;
  t: (key: string, params?: Record<string, string | number>) => string;
}

function PositionCard({ position, translateTeam, t }: PositionCardProps) {
  const homeTeam = position.market.homeTeam || 'Home';
  const awayTeam = position.market.awayTeam || 'Away';
  const selection = getSelection(position, translateTeam, t);
  const odds = calculateOdds(position);
  const payment = formatUSDC(getOriginalPayment(position));
  const payout = calculateExpectedPayout(position).toFixed(2);
  const date = formatDate(position.createdAt);

  return (
    <div className="border border-zinc-700 rounded-lg p-3">
      {/* 第一行：球队 logo 和比赛名 */}
      <div className="flex items-center gap-2 mb-3">
        <div className="flex items-center">
          <ShieldCheck className="w-6 h-6 text-accent" />
          <BadgeCheck className="w-6 h-6 text-gray-500 -ml-2" />
        </div>
        <span className="text-sm text-white font-medium">
          {translateTeam(homeTeam)} vs {translateTeam(awayTeam)}
        </span>
      </div>

      {/* 第二行：Selection 和 Odds */}
      <div className="flex items-center justify-between mb-2">
        <div className="text-sm">
          <span className="text-gray-400">{t('marketPositions.selection')}: </span>
          <span className="text-white font-medium">{selection}</span>
        </div>
        <div className="text-sm">
          <span className="text-gray-400">{t('marketPositions.odds')}: </span>
          <span className="text-white font-medium">{odds}</span>
        </div>
      </div>

      {/* 第三行：Payment 和 Payout */}
      <div className="flex items-center justify-between mb-2">
        <div className="text-sm">
          <span className="text-gray-400">{t('marketPositions.payment')}: </span>
          <span className="text-white font-medium">{payment} USDC</span>
        </div>
        <div className="text-sm">
          <span className="text-gray-400">{t('marketPositions.payout')}: </span>
          <span className="text-white font-medium">{payout} USDC</span>
        </div>
      </div>

      {/* 第四行：时间 */}
      <div className="text-right text-xs text-gray-500">
        at {date}
      </div>
    </div>
  );
}
