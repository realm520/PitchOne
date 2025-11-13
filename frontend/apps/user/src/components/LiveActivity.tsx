'use client';

import { formatUnits } from 'viem';
import { Card, Badge } from '@pitchone/ui';
import type { BetPlacedEvent } from '@pitchone/web3';
import { TOKEN_DECIMALS } from '@pitchone/web3';

interface LiveActivityProps {
  events: BetPlacedEvent[];
  outcomeNames?: string[];
}

export function LiveActivity({ events, outcomeNames = [] }: LiveActivityProps) {
  if (events.length === 0) {
    return (
      <Card padding="lg">
        <div className="text-center text-gray-500 py-8">
          <svg
            className="w-12 h-12 mx-auto mb-3 opacity-50"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M13 10V3L4 14h7v7l9-11h-7z"
            />
          </svg>
          <p className="text-sm">等待实时交易...</p>
        </div>
      </Card>
    );
  }

  return (
    <Card padding="none">
      <div className="px-6 py-4 border-b border-dark-border">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-bold text-white flex items-center gap-2">
            <span className="relative flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
            </span>
            实时活动
          </h3>
          <Badge variant="success" size="sm">
            {events.length} 笔
          </Badge>
        </div>
      </div>

      <div className="max-h-96 overflow-y-auto">
        {events.map((event, index) => (
          <div
            key={`${event.transactionHash}-${index}`}
            className="px-6 py-4 border-b border-dark-border hover:bg-dark-card/50 transition-colors"
          >
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-br from-neon-blue to-neon-purple flex items-center justify-center text-white text-xs font-bold">
                  {event.user.slice(2, 4).toUpperCase()}
                </div>
                <div>
                  <p className="text-sm font-medium text-white">
                    {event.user.slice(0, 6)}...{event.user.slice(-4)}
                  </p>
                  <p className="text-xs text-gray-500">
                    {new Date(event.timestamp).toLocaleTimeString('zh-CN')}
                  </p>
                </div>
              </div>

              <div className="text-right">
                <p className="text-sm font-bold text-neon-green">
                  {formatUnits(event.amount, TOKEN_DECIMALS.USDC)} USDC
                </p>
                <p className="text-xs text-gray-500">
                  手续费: {formatUnits(event.fee, TOKEN_DECIMALS.USDC)} USDC
                </p>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <Badge variant="info" size="sm">
                {outcomeNames[Number(event.outcomeId)] || `结果 ${event.outcomeId}`}
              </Badge>
              <a
                href={`https://etherscan.io/tx/${event.transactionHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs text-neon-blue hover:text-neon-purple transition-colors"
              >
                查看交易 ↗
              </a>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}
