'use client';

import { useQuery } from '@tanstack/react-query';
import { graphqlClient, GLOBAL_STATS_QUERY, RECENT_ORDERS_QUERY, MARKET_STATS_QUERY, formatUSDCFromWei } from '@pitchone/web3';
import { Card, LoadingSpinner, ErrorState } from '@pitchone/ui';
import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

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
    acc[market.state] = (acc[market.state] || 0) + 1;
    return acc;
  }, {} as Record<string, number>);

  const STATUS_CONFIG = {
    Open: { label: '开盘中', color: '#3b82f6' },
    Locked: { label: '已锁盘', color: '#f59e0b' },
    Resolved: { label: '已结算', color: '#10b981' },
    Finalized: { label: '已完成', color: '#6b7280' },
  };

  const data = Object.entries(statusCounts).map(([state, count]) => ({
    name: STATUS_CONFIG[state as keyof typeof STATUS_CONFIG]?.label || state,
    value: count as number,
    state,
    color: STATUS_CONFIG[state as keyof typeof STATUS_CONFIG]?.color || '#6b7280',
  }));

  const totalMarkets = markets.length;

  return (
    <Card className="p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        市场状态分布
      </h3>
      <div className="flex items-center gap-8">
        {/* 饼图 */}
        <div className="flex-shrink-0">
          <ResponsiveContainer width={240} height={240}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={90}
                fill="#8884d8"
                dataKey="value"
                label={({ percent }) => `${(percent * 100).toFixed(0)}%`}
              >
                {data.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* 图例和统计 */}
        <div className="flex-1 space-y-3">
          {data.map((item, index) => (
            <div key={index} className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div
                  className="w-4 h-4 rounded-sm"
                  style={{ backgroundColor: item.color }}
                />
                <span className="text-sm text-gray-700 dark:text-gray-300">
                  {item.name}
                </span>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-sm font-semibold text-gray-900 dark:text-white">
                  {item.value} 个
                </span>
                <span className="text-sm text-gray-500 dark:text-gray-400 w-12 text-right">
                  {((item.value / totalMarkets) * 100).toFixed(1)}%
                </span>
              </div>
            </div>
          ))}
          <div className="pt-3 border-t dark:border-gray-700">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                市场总数
              </span>
              <span className="text-lg font-bold text-gray-900 dark:text-white">
                {totalMarkets}
              </span>
            </div>
          </div>
        </div>
      </div>
    </Card>
  );
}

// 交易量趋势图表组件
function VolumeChart({ markets }: { markets: any[] }) {
  // 按日期聚合交易量（最近14天）
  const today = new Date();
  const fourteenDaysAgo = new Date(today);
  fourteenDaysAgo.setDate(today.getDate() - 13); // 包含今天共14天

  // 生成最近14天的日期数组
  const dateRange = Array.from({ length: 14 }, (_, i) => {
    const date = new Date(fourteenDaysAgo);
    date.setDate(fourteenDaysAgo.getDate() + i);
    return date.toLocaleDateString('zh-CN');
  });

  // 按日期聚合交易量
  const volumeByDate = markets.reduce((acc, market) => {
    const date = new Date(Number(market.createdAt) * 1000).toLocaleDateString('zh-CN');
    acc[date] = (acc[date] || 0) + Number(market.totalVolume || 0);
    return acc;
  }, {} as Record<string, number>);

  // 填充所有日期（包括没有数据的日期）
  const data = dateRange.map((date) => ({
    date: date.split('/').slice(1).join('/'), // 去掉年份，显示为 MM/DD
    volume: volumeByDate[date] || 0, // USDC 数值已经转换过
    fullDate: date,
  }));

  // 计算趋势
  const totalVolume = data.reduce((sum, item) => sum + item.volume, 0);
  const avgVolume = totalVolume / data.length;
  const lastWeekVolume = data.slice(-7).reduce((sum, item) => sum + item.volume, 0);
  const prevWeekVolume = data.slice(0, 7).reduce((sum, item) => sum + item.volume, 0);
  const weeklyTrend = prevWeekVolume > 0
    ? ((lastWeekVolume - prevWeekVolume) / prevWeekVolume * 100).toFixed(1)
    : '0';

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          交易量趋势（最近14天）
        </h3>
        <div className="flex items-center gap-4 text-sm">
          <div className="text-gray-600 dark:text-gray-400">
            日均: <span className="font-semibold text-gray-900 dark:text-white">{avgVolume.toFixed(2)} USDC</span>
          </div>
          <div className={`font-semibold ${Number(weeklyTrend) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            周环比: {Number(weeklyTrend) >= 0 ? '+' : ''}{weeklyTrend}%
          </div>
        </div>
      </div>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" className="stroke-gray-200 dark:stroke-gray-700" />
          <XAxis
            dataKey="date"
            className="text-xs text-gray-600 dark:text-gray-400"
          />
          <YAxis className="text-xs text-gray-600 dark:text-gray-400" />
          <Tooltip
            formatter={(value: number) => [`${value.toFixed(2)} USDC`, '交易量']}
            contentStyle={{
              backgroundColor: 'rgba(255, 255, 255, 0.95)',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
            }}
          />
          <Bar dataKey="volume" fill="#3b82f6" radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </Card>
  );
}

// 最近订单列表组件
function RecentOrdersList({ orders }: { orders: any[] }) {
  if (!orders || orders.length === 0) {
    return (
      <Card className="p-12 text-center">
        <div className="text-gray-400 dark:text-gray-500 mb-2">
          <svg className="mx-auto h-12 w-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
          </svg>
        </div>
        <p className="text-sm text-gray-500 dark:text-gray-400">暂无订单数据</p>
      </Card>
    );
  }

  // order.amount 是原始 wei 值（BigInt），使用统一的精度转换函数
  const totalAmount = orders.reduce((sum, order) => sum + formatUSDCFromWei(order.amount), 0);
  const avgAmount = totalAmount / orders.length;

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          最近订单
        </h3>
        <div className="flex items-center gap-4 text-sm">
          <div className="text-gray-600 dark:text-gray-400">
            共 <span className="font-semibold text-gray-900 dark:text-white">{orders.length}</span> 笔
          </div>
          <div className="text-gray-600 dark:text-gray-400">
            均值: <span className="font-semibold text-gray-900 dark:text-white">{avgAmount.toFixed(2)} USDC</span>
          </div>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b dark:border-gray-700">
            <tr className="text-left">
              <th className="pb-3 px-2 font-medium text-xs text-gray-500 dark:text-gray-400 uppercase">时间</th>
              <th className="pb-3 px-2 font-medium text-xs text-gray-500 dark:text-gray-400 uppercase">市场</th>
              <th className="pb-3 px-2 font-medium text-xs text-gray-500 dark:text-gray-400 uppercase">用户</th>
              <th className="pb-3 px-2 font-medium text-xs text-gray-500 dark:text-gray-400 uppercase text-right">金额</th>
              <th className="pb-3 px-2 font-medium text-xs text-gray-500 dark:text-gray-400 uppercase">选择</th>
            </tr>
          </thead>
          <tbody className="divide-y dark:divide-gray-700">
            {orders.map((order) => {
              const marketStateColor =
                order.market.state === 'Open' ? 'text-blue-600 dark:text-blue-400' :
                  order.market.state === 'Locked' ? 'text-yellow-600 dark:text-yellow-400' :
                    order.market.state === 'Resolved' ? 'text-green-600 dark:text-green-400' :
                      'text-gray-600 dark:text-gray-400';

              return (
                <tr key={order.id} className="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                  <td className="py-3 px-2 text-gray-600 dark:text-gray-300">
                    {formatDistanceToNow(new Date(Number(order.timestamp) * 1000), {
                      addSuffix: true,
                      locale: zhCN
                    })}
                  </td>
                  <td className="py-3 px-2">
                    <div className="text-gray-900 dark:text-white font-medium">
                      {order.market.id.slice(0, 8)}...
                    </div>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                      <span className={marketStateColor}>●</span> {order.market.state}
                    </div>
                  </td>
                  <td className="py-3 px-2 font-mono text-xs text-gray-600 dark:text-gray-300">
                    {order.user.id.slice(0, 6)}...{order.user.id.slice(-4)}
                  </td>
                  <td className="py-3 px-2 text-right">
                    <span className="font-semibold text-gray-900 dark:text-white">
                      {formatUSDCFromWei(order.amount).toFixed(2)}
                    </span>
                    <span className="text-xs text-gray-500 dark:text-gray-400 ml-1">USDC</span>
                  </td>
                  <td className="py-3 px-2">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                      #{order.outcome}
                    </span>
                  </td>
                </tr>
              );
            })}
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
    ? Number(globalStats.totalVolume).toFixed(2)
    : '0.00';

  const totalFees = globalStats?.totalFees
    ? Number(globalStats.totalFees).toFixed(2)
    : '0.00';

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
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
