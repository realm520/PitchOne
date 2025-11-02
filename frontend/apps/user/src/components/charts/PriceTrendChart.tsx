'use client';

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export interface PriceTrendDataPoint {
  timestamp: number;
  price: number;
  label?: string;
}

interface PriceTrendChartProps {
  data: PriceTrendDataPoint[];
  outcomeName?: string;
  color?: string;
}

export function PriceTrendChart({ data, outcomeName = '价格', color = '#00D9FF' }: PriceTrendChartProps) {
  // 格式化数据
  const chartData = data.map(point => ({
    ...point,
    time: new Date(point.timestamp * 1000).toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit',
    }),
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={chartData} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#2a2a3e" />
        <XAxis
          dataKey="time"
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
        />
        <YAxis
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
          domain={['dataMin - 0.1', 'dataMax + 0.1']}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: '#1a1a2e',
            border: '1px solid #2a2a3e',
            borderRadius: '8px',
            color: '#fff',
          }}
          labelStyle={{ color: '#9ca3af' }}
          formatter={(value: number) => [`${value.toFixed(2)}x`, outcomeName]}
        />
        <Legend
          wrapperStyle={{ color: '#9ca3af', fontSize: '12px' }}
        />
        <Line
          type="monotone"
          dataKey="price"
          stroke={color}
          strokeWidth={2}
          dot={{ fill: color, r: 4 }}
          activeDot={{ r: 6 }}
          name={outcomeName}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}
