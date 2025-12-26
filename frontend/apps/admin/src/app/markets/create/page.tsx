'use client';

import Link from 'next/link';
import { Card } from '@pitchone/ui';

// 市场分类
const MARKET_CATEGORIES = [
  {
    id: 'sports',
    name: '体育赛事预测市场',
    description: '基于真实体育赛事创建预测市场，包括足球、篮球等多种运动',
    icon: '⚽',
    enabled: true,
    href: '/markets/create/sports',
  },
  {
    id: 'other',
    name: '创建其他预测市场',
    description: '创建加密货币、政治、娱乐等其他类型的预测市场',
    icon: '🔮',
    enabled: false,
    href: '#',
  },
];

export default function CreateMarketPage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                创建市场
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                选择市场类型开始创建预测市场
              </p>
            </div>
            <Link href="/markets" className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200">
              ← 返回列表
            </Link>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {MARKET_CATEGORIES.map((category) => (
            <Card
              key={category.id}
              className={`p-6 transition-all ${
                category.enabled
                  ? 'hover:shadow-lg hover:border-blue-500 cursor-pointer'
                  : 'opacity-60 cursor-not-allowed'
              }`}
            >
              {category.enabled ? (
                <Link href={category.href} className="block">
                  <div className="flex flex-col items-center text-center">
                    <div className="text-5xl mb-4">{category.icon}</div>
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                      {category.name}
                    </h2>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {category.description}
                    </p>
                    <div className="mt-4">
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                        选择此类型 →
                      </span>
                    </div>
                  </div>
                </Link>
              ) : (
                <div className="block">
                  <div className="flex flex-col items-center text-center">
                    <div className="text-5xl mb-4 grayscale">{category.icon}</div>
                    <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                      {category.name}
                    </h2>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      {category.description}
                    </p>
                    <div className="mt-4">
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400">
                        即将推出
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
