'use client';

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export interface DepthDataPoint {
  price: number;
  buyDepth: number;
  sellDepth: number;
}

interface DepthChartProps {
  data: DepthDataPoint[];
}

export function DepthChart({ data }: DepthChartProps) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={data} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
        <defs>
          <linearGradient id="buyGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="sellGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#2a2a3e" />
        <XAxis
          dataKey="price"
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
          label={{ value: '价格', position: 'insideBottom', offset: -5 }}
        />
        <YAxis
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
          label={{ value: '深度', angle: -90, position: 'insideLeft' }}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: '#1a1a2e',
            border: '1px solid #2a2a3e',
            borderRadius: '8px',
            color: '#fff',
          }}
          labelStyle={{ color: '#9ca3af' }}
          formatter={(value: number, name: string) => [
            `${value.toFixed(2)} USDC`,
            name === 'buyDepth' ? '买入深度' : '卖出深度'
          ]}
        />
        <Area
          type="step"
          dataKey="buyDepth"
          stroke="#10b981"
          strokeWidth={2}
          fill="url(#buyGradient)"
          name="买入深度"
        />
        <Area
          type="step"
          dataKey="sellDepth"
          stroke="#ef4444"
          strokeWidth={2}
          fill="url(#sellGradient)"
          name="卖出深度"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
