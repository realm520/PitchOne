'use client';

import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export interface VolumeDataPoint {
  timestamp: number;
  volume: number;
  label?: string;
}

interface VolumeChartProps {
  data: VolumeDataPoint[];
  color?: string;
}

export function VolumeChart({ data, color = '#9D4EDD' }: VolumeChartProps) {
  // 格式化数据
  const chartData = data.map(point => ({
    ...point,
    time: new Date(point.timestamp * 1000).toLocaleString('zh-CN', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
    }),
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={chartData} margin={{ top: 5, right: 20, left: 0, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#2a2a3e" />
        <XAxis
          dataKey="time"
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
        />
        <YAxis
          stroke="#9ca3af"
          style={{ fontSize: '12px' }}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: '#1a1a2e',
            border: '1px solid #2a2a3e',
            borderRadius: '8px',
            color: '#fff',
          }}
          labelStyle={{ color: '#9ca3af' }}
          formatter={(value: number) => [`${value.toFixed(2)} USDC`, '交易量']}
        />
        <Legend
          wrapperStyle={{ color: '#9ca3af', fontSize: '12px' }}
        />
        <Bar
          dataKey="volume"
          fill={color}
          name="交易量"
          radius={[8, 8, 0, 0]}
        />
      </BarChart>
    </ResponsiveContainer>
  );
}
