'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, GLOBAL_STATS_QUERY, RECENT_ORDERS_QUERY, MARKET_STATS_QUERY } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState, Button } from '@pitchone/ui';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import Link from 'next/link';

// 统计卡片组件
function StatCard({ title, value, subtitle, trend }: {
  title: string;
  value: string;
  subtitle?: string;
  trend?: { value: string; positive: boolean };
}) {
  return (
    <Card className="p-6">
      <div className="flex flex-col space-y-2">
        <p className="text-sm font-medium text-gray-500 dark:text-gray-400">{title}</p>
        <div className="flex items-baseline space-x-2">
          <h3 className="text-3xl font-bold text-gray-900 dark:text-white">{value}</h3>
          {trend && (
            <span className={`text-sm font-medium ${trend.positive ? 'text-green-600' : 'text-red-600'}`}>
              {trend.positive ? '↑' : '↓'} {trend.value}
            </span>
          )}
        </div>
        {subtitle && (
          <p className="text-xs text-gray-500 dark:text-gray-400">{subtitle}</p>
        )}
      </div>
    </Card>
  );
}

// 市场状态分布组件
function MarketStatusChart({ markets }: { markets: any[] }) {
  const statusCounts = markets.reduce((acc, market) => {
    acc[market.status] = (acc[market.status] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const data = Object.entries(statusCounts).map(([status, count]) => ({
    name: status === 'Open' ? '开盘中' : status === 'Locked' ? '已锁盘' : status === 'Resolved' ? '已结算' : status,
    value: count,
  }));

  const COLORS = ['#3b82f6', '#f59e0b', '#10b981', '#ef4444'];

  return (
    <Card className="p-6">
      <h3 className="text-lg font-semibold mb-4">市场状态分布</h3>
      <ResponsiveContainer width="100%" height={300}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip />
        </PieChart>
      </ResponsiveContainer>
    </Card>
  );
}

// 交易量趋势图表组件
function VolumeChart({ markets }: { markets: any[] }) {
  // 按日期聚合交易量（最近7天）
  const volumeByDate = markets.reduce((acc, market) => {
    const date = new Date(Number(market.createdAt) * 1000).toLocaleDateString('zh-CN');
    acc[date] = (acc[date] || 0) + Number(market.totalVolume || 0);
    return acc;
  }, {} as Record<string, number>);

  const data = Object.entries(volumeByDate)
    .sort((a, b) => new Date(a[0]).getTime() - new Date(b[0]).getTime())
    .slice(-7) // 最近7天
    .map(([date, volume]) => ({
      date: date.split('/').slice(1).join('/'), // 去掉年份
      volume: volume / 1e6, // 转换为 USDC（6 decimals）
    }));

  return (
    <Card className="p-6">
      <h3 className="text-lg font-semibold mb-4">交易量趋势（最近7天）</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip
            formatter={(value: number) => [`${value.toFixed(2)} USDC`, '交易量']}
          />
          <Bar dataKey="volume" fill="#3b82f6" />
        </BarChart>
      </ResponsiveContainer>
    </Card>
  );
}

// 最近订单列表组件
function RecentOrdersList({ orders }: { orders: any[] }) {
  return (
    <Card className="p-6">
      <h3 className="text-lg font-semibold mb-4">最近订单</h3>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b dark:border-gray-700">
            <tr className="text-left">
              <th className="pb-2 font-medium text-gray-500 dark:text-gray-400">时间</th>
              <th className="pb-2 font-medium text-gray-500 dark:text-gray-400">市场</th>
              <th className="pb-2 font-medium text-gray-500 dark:text-gray-400">用户</th>
              <th className="pb-2 font-medium text-gray-500 dark:text-gray-400">金额</th>
              <th className="pb-2 font-medium text-gray-500 dark:text-gray-400">结果</th>
            </tr>
          </thead>
          <tbody className="divide-y dark:divide-gray-700">
            {orders.map((order) => (
              <tr key={order.id} className="hover:bg-gray-50 dark:hover:bg-gray-800">
                <td className="py-3 text-gray-600 dark:text-gray-300">
                  {formatDistanceToNow(new Date(Number(order.timestamp) * 1000), {
                    addSuffix: true,
                    locale: zhCN
                  })}
                </td>
                <td className="py-3">
                  <div className="text-gray-900 dark:text-white font-medium">
                    {order.market.homeTeam} vs {order.market.awayTeam}
                  </div>
                  <div className="text-xs text-gray-500">{order.market.event}</div>
                </td>
                <td className="py-3 font-mono text-xs text-gray-600 dark:text-gray-300">
                  {order.user.slice(0, 6)}...{order.user.slice(-4)}
                </td>
                <td className="py-3 font-semibold text-gray-900 dark:text-white">
                  {(Number(order.amount) / 1e6).toFixed(2)} USDC
                </td>
                <td className="py-3">
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                    Outcome {order.outcome}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

export default function AdminDashboard() {
  // 获取全局统计数据
  const { data: globalStats, isLoading: statsLoading, error: statsError } = useQuery({
    queryKey: ['globalStats'],
    queryFn: async () => {
      const data: any = await graphqlClient.request(GLOBAL_STATS_QUERY);
      return data.globalStats;
    },
  });

  // 获取市场统计数据
  const { data: marketStats, isLoading: marketsLoading } = useQuery({
    queryKey: ['marketStats'],
    queryFn: async () => {
      const data: any = await graphqlClient.request(MARKET_STATS_QUERY);
      return data.markets;
    },
  });

  // 获取最近订单
  const { data: recentOrders, isLoading: ordersLoading } = useQuery({
    queryKey: ['recentOrders'],
    queryFn: async () => {
      const data: any = await graphqlClient.request(RECENT_ORDERS_QUERY, { first: 10 });
      return data.orders;
    },
  });

  // 加载状态
  if (statsLoading || marketsLoading || ordersLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" text="加载数据中..." />
      </div>
    );
  }

  // 错误状态
  if (statsError) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <ErrorState
          title="数据加载失败"
          message={statsError instanceof Error ? statsError.message : '无法连接到 Subgraph'}
          onRetry={() => window.location.reload()}
        />
      </div>
    );
  }

  // 计算统计数据
  const totalVolume = globalStats?.totalVolume
    ? (Number(globalStats.totalVolume) / 1e6).toFixed(2)
    : '0.00';

  const totalFees = globalStats?.totalFees
    ? (Number(globalStats.totalFees) / 1e6).toFixed(2)
    : '0.00';

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                运营数据看板
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                实时监控平台运营数据和市场状态
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Link href="/markets">
                <Button variant="outline">
                  市场管理
                </Button>
              </Link>
              <Link href="/oracles">
                <Button variant="outline">
                  Oracle 提案
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 统计卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="总交易量"
            value={`${totalVolume} USDC`}
            subtitle="累计平台交易额"
          />
          <StatCard
            title="活跃市场"
            value={globalStats?.totalMarkets || '0'}
            subtitle="已创建的市场数量"
          />
          <StatCard
            title="总用户数"
            value={globalStats?.totalUsers || '0'}
            subtitle="参与下注的用户"
          />
          <StatCard
            title="手续费收入"
            value={`${totalFees} USDC`}
            subtitle="累计手续费收入"
          />
        </div>

        {/* 图表 */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {marketStats && <VolumeChart markets={marketStats} />}
          {marketStats && <MarketStatusChart markets={marketStats} />}
        </div>

        {/* 最近订单 */}
        {recentOrders && recentOrders.length > 0 && (
          <RecentOrdersList orders={recentOrders} />
        )}
      </div>
    </div>
  );
}
