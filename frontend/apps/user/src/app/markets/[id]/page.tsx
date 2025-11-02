'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { formatEther, parseEther } from 'viem';
import { useAccount } from 'wagmi';
import { useMarket, useUserOrders, MarketStatus } from '@pitchone/web3';
import {
  Container,
  Card,
  Badge,
  Button,
  Input,
  LoadingSpinner,
  EmptyState,
  ErrorState,
  Modal,
} from '@pitchone/ui';

export default function MarketDetailPage() {
  const params = useParams();
  const marketId = params.id as string;
  const { address, isConnected } = useAccount();

  const [selectedOutcome, setSelectedOutcome] = useState<number | null>(null);
  const [betAmount, setBetAmount] = useState('');
  const [showBetModal, setShowBetModal] = useState(false);
  const [isPlacingBet, setIsPlacingBet] = useState(false);

  const { data: market, isLoading, error } = useMarket(marketId);
  const { data: orders } = useUserOrders(address, marketId);

  const formatDate = (timestamp: string) => {
    const date = new Date(parseInt(timestamp) * 1000);
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusBadge = (status: MarketStatus) => {
    const variants = {
      [MarketStatus.Open]: { variant: 'success' as const, label: '进行中' },
      [MarketStatus.Locked]: { variant: 'warning' as const, label: '已锁盘' },
      [MarketStatus.Resolved]: { variant: 'info' as const, label: '已结算' },
      [MarketStatus.Finalized]: { variant: 'default' as const, label: '已完成' },
    };
    const config = variants[status];
    return <Badge variant={config.variant} dot>{config.label}</Badge>;
  };

  // Mock outcome data (in real app, this would come from contract)
  const outcomes = [
    { id: 0, name: '主胜', odds: '2.15', color: 'from-green-600 to-green-800' },
    { id: 1, name: '平局', odds: '3.40', color: 'from-yellow-600 to-yellow-800' },
    { id: 2, name: '客胜', odds: '2.85', color: 'from-blue-600 to-blue-800' },
  ];

  const calculatePayout = () => {
    if (!betAmount || selectedOutcome === null) return '0.00';
    const amount = parseFloat(betAmount);
    const odds = parseFloat(outcomes[selectedOutcome].odds);
    return (amount * odds).toFixed(2);
  };

  const handlePlaceBet = async () => {
    if (!isConnected || selectedOutcome === null || !betAmount) return;

    setIsPlacingBet(true);
    try {
      // TODO: Call contract placeBet function
      await new Promise((resolve) => setTimeout(resolve, 2000)); // Simulate transaction
      alert(`下注成功！结果：${outcomes[selectedOutcome].name}，金额：${betAmount} USDC`);
      setShowBetModal(false);
      setBetAmount('');
      setSelectedOutcome(null);
    } catch (error) {
      console.error('Place bet error:', error);
      alert('下注失败，请重试');
    } finally {
      setIsPlacingBet(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <LoadingSpinner size="lg" text="加载市场详情..." />
      </div>
    );
  }

  if (error || !market) {
    return (
      <div className="min-h-screen bg-dark-bg flex items-center justify-center">
        <ErrorState message="无法加载市场数据，市场可能不存在或网络连接有问题" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-dark-bg py-8">
      <Container size="xl">
        {/* Market Header */}
        <Card className="mb-6" variant="neon" padding="lg">
          <div className="flex items-start justify-between mb-4">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-3xl font-bold text-white">
                  {market.homeTeam} vs {market.awayTeam}
                </h1>
                {getStatusBadge(market.status)}
              </div>
              <p className="text-gray-400">{market.event}</p>
              <p className="text-sm text-gray-500 mt-1">
                开赛时间: {formatDate(market.kickoffTime)}
              </p>
            </div>
            <Badge variant="neon" size="lg">WDL</Badge>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-dark-border">
            <div>
              <p className="text-sm text-gray-500 mb-1">总投注量</p>
              <p className="text-xl font-bold text-neon-blue">12,450 USDC</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">流动性</p>
              <p className="text-xl font-bold text-neon-green">50,000 USDC</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 mb-1">订单数</p>
              <p className="text-xl font-bold text-neon-purple">342</p>
            </div>
          </div>
        </Card>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Outcomes */}
          <div className="lg:col-span-2">
            <h2 className="text-2xl font-bold text-white mb-4">投注选项</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {outcomes.map((outcome) => (
                <Card
                  key={outcome.id}
                  hoverable
                  variant={selectedOutcome === outcome.id ? 'neon' : 'default'}
                  padding="lg"
                  onClick={() => {
                    if (market.status === MarketStatus.Open) {
                      setSelectedOutcome(outcome.id);
                      setShowBetModal(true);
                    }
                  }}
                  className="cursor-pointer"
                >
                  <div className={`w-full h-2 rounded-full bg-gradient-to-r ${outcome.color} mb-4`} />
                  <h3 className="text-xl font-bold text-white mb-2">{outcome.name}</h3>
                  <div className="flex items-baseline gap-2">
                    <span className="text-3xl font-bold text-neon">{outcome.odds}</span>
                    <span className="text-sm text-gray-500">赔率</span>
                  </div>
                </Card>
              ))}
            </div>

            {/* Orders History */}
            <div className="mt-8">
              <h2 className="text-2xl font-bold text-white mb-4">我的订单</h2>
              {!isConnected ? (
                <Card padding="lg">
                  <EmptyState
                    icon={
                      <svg className="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                      </svg>
                    }
                    title="请先连接钱包"
                    description="连接钱包后即可查看您的订单历史"
                  />
                </Card>
              ) : !orders || orders.length === 0 ? (
                <Card padding="lg">
                  <EmptyState
                    title="暂无订单"
                    description="您还没有在这个市场下注过"
                  />
                </Card>
              ) : (
                <Card padding="none">
                  <div className="overflow-x-auto">
                    <table className="w-full">
                      <thead className="bg-dark-card border-b border-dark-border">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">时间</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">选项</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">金额</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-400 uppercase">预期收益</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-dark-border">
                        {orders.map((order) => (
                          <tr key={order.id} className="hover:bg-dark-card/50 transition-colors">
                            <td className="px-6 py-4 text-sm text-gray-400">{formatDate(order.timestamp)}</td>
                            <td className="px-6 py-4">
                              <Badge variant="info">结果 {order.outcome}</Badge>
                            </td>
                            <td className="px-6 py-4 text-sm font-medium text-white">{formatEther(BigInt(order.amount))} USDC</td>
                            <td className="px-6 py-4 text-sm font-medium text-neon-green">+{formatEther(BigInt(order.payout || order.amount))} USDC</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </Card>
              )}
            </div>
          </div>

          {/* Sidebar - Quick Stats */}
          <div className="lg:col-span-1">
            <Card variant="glass" padding="lg" className="sticky top-24">
              <h3 className="text-lg font-bold text-white mb-4">市场信息</h3>
              <div className="space-y-4">
                <div>
                  <p className="text-sm text-gray-500 mb-1">市场 ID</p>
                  <p className="text-xs font-mono text-gray-400 break-all">{market.id}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">状态</p>
                  {getStatusBadge(market.status)}
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">手续费率</p>
                  <p className="text-sm text-white">2%</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">最小下注</p>
                  <p className="text-sm text-white">1 USDC</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 mb-1">最大下注</p>
                  <p className="text-sm text-white">10,000 USDC</p>
                </div>
              </div>
            </Card>
          </div>
        </div>
      </Container>

      {/* Bet Modal */}
      <Modal
        isOpen={showBetModal}
        onClose={() => {
          setShowBetModal(false);
          setBetAmount('');
        }}
        title="确认下注"
        size="md"
      >
        {selectedOutcome !== null && (
          <div className="space-y-6">
            {/* Selected Outcome */}
            <div className="p-4 bg-dark-bg rounded-lg border border-dark-border">
              <p className="text-sm text-gray-500 mb-1">选择结果</p>
              <div className="flex items-center justify-between">
                <p className="text-xl font-bold text-white">{outcomes[selectedOutcome].name}</p>
                <Badge variant="neon" size="lg">{outcomes[selectedOutcome].odds}x</Badge>
              </div>
            </div>

            {/* Amount Input */}
            <Input
              type="number"
              label="下注金额 (USDC)"
              placeholder="输入金额"
              value={betAmount}
              onChange={(e) => setBetAmount(e.target.value)}
              min="1"
              max="10000"
              fullWidth
            />

            {/* Expected Payout */}
            {betAmount && (
              <div className="p-4 bg-gradient-to-r from-neon-blue/10 to-neon-purple/10 rounded-lg border border-neon-blue/30">
                <p className="text-sm text-gray-400 mb-1">预期收益</p>
                <p className="text-3xl font-bold text-neon">{calculatePayout()} USDC</p>
                <p className="text-xs text-gray-500 mt-1">净盈利: {(parseFloat(calculatePayout()) - parseFloat(betAmount)).toFixed(2)} USDC</p>
              </div>
            )}

            {/* Actions */}
            <div className="flex gap-3">
              <Button
                variant="secondary"
                fullWidth
                onClick={() => {
                  setShowBetModal(false);
                  setBetAmount('');
                }}
                disabled={isPlacingBet}
              >
                取消
              </Button>
              <Button
                variant="neon"
                fullWidth
                onClick={handlePlaceBet}
                disabled={!betAmount || parseFloat(betAmount) < 1 || isPlacingBet}
                isLoading={isPlacingBet}
              >
                {isPlacingBet ? '处理中...' : '确认下注'}
              </Button>
            </div>

            {!isConnected && (
              <p className="text-sm text-yellow-500 text-center">⚠️ 请先连接钱包</p>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
