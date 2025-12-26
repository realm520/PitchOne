'use client';

import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Link from 'next/link';
import { useAccount, useCreateMarket, type CreateMarketParams } from '@pitchone/web3';
import { getContractAddresses } from '@pitchone/contracts';
import { Card, Button, Badge, LoadingSpinner } from '@pitchone/ui';
import { format } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import { toast } from 'sonner';

// 已知的错误选择器映射
const ERROR_SELECTORS: Record<string, string> = {
  '0xe2517d3f': 'AccessControlUnauthorizedAccount', // 权限不足
  '0x82b42900': 'Unauthorized',
  '0x8e4a23d6': 'InvalidAmount',
  '0x3ee5aeb5': 'InvalidAddress',
};

// 已知的角色哈希映射
const ROLE_HASHES: Record<string, string> = {
  '0xfc8737ab85eb45125971625a9ebdb75cc78e01d5c1fa80c4c6e5203f47bc4fab': 'KEEPER_ROLE',
  '0x7a05a596cb0ce7fdea8a1e1ec73be300bdb35097c944ce1897202f7a13122eb2': 'ROUTER_ROLE',
  '0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929': 'ORACLE_ROLE',
  '0x0000000000000000000000000000000000000000000000000000000000000000': 'DEFAULT_ADMIN_ROLE',
};

// 解析合约错误信息
function parseContractError(error: Error): string {
  const message = error.message || '';

  // 尝试从错误信息中提取 revert 原因
  const revertMatch = message.match(/reverted with the following reason:\s*(.+)/i);
  if (revertMatch) {
    return revertMatch[1];
  }

  // 检查是否是 AccessControlUnauthorizedAccount 错误
  if (message.includes('0xe2517d3f') || message.includes('AccessControlUnauthorizedAccount')) {
    // 尝试提取角色哈希
    const roleMatch = message.match(/0x[a-fA-F0-9]{64}/g);
    if (roleMatch && roleMatch.length > 0) {
      const roleHash = roleMatch[roleMatch.length - 1].toLowerCase();
      const roleName = ROLE_HASHES[roleHash] || '未知角色';
      return `权限不足：当前账户没有 ${roleName} 权限`;
    }
    return '权限不足：当前账户没有执行此操作的权限';
  }

  // 检查其他已知错误
  for (const [selector, name] of Object.entries(ERROR_SELECTORS)) {
    if (message.includes(selector)) {
      return `合约错误: ${name}`;
    }
  }

  // 用户拒绝交易
  if (message.includes('User rejected') || message.includes('user rejected')) {
    return '用户取消了交易';
  }

  // Gas 不足
  if (message.includes('insufficient funds') || message.includes('gas required exceeds')) {
    return 'Gas 费用不足';
  }

  // 返回原始错误信息（截断过长的部分）
  const cleanMessage = message.replace(/\s+/g, ' ').trim();
  return cleanMessage.length > 200 ? cleanMessage.slice(0, 200) + '...' : cleanMessage;
}

// 市场模板类型
const MARKET_TEMPLATES = [
  {
    id: 'WDL',
    name: '胜平负',
    description: '主胜 / 平局 / 客胜',
    templateId: '0xd3848d8e7c5941e95e6e0b351749b347dbeb1b308f305f28b95b1328a3e669dc' as `0x${string}`,
  },
  {
    id: 'OU',
    name: '大小球',
    description: '总进球数大于/小于盘口',
    templateId: '0x6441bdfa8f4495d4dd881afce0e761e3a05085b4330b9db35c684a348ef2697f' as `0x${string}`,
  },
  {
    id: 'OddEven',
    name: '单双',
    description: '总进球数单数/双数',
    templateId: '0xf1d71fd4a1d5c765ed93ae053cb712e5c2d053fc61d39d01a15c3aadf1da027b' as `0x${string}`,
  },
];

// 赛事信息（从 URL 参数获取）
interface MatchInfo {
  matchId: string;
  homeTeam: string;
  awayTeam: string;
  kickoffTime: number; // Unix timestamp
  league: string;
  season: string;
  round: string;
}

function CreateMarketForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { chainId, isConnected } = useAccount();
  const { createMarket, isPending, isConfirming, isSuccess, error, hash } = useCreateMarket();

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState('WDL');

  // 从 URL 参数解析赛事信息
  const matchInfo: MatchInfo = {
    matchId: searchParams.get('matchId') || '',
    homeTeam: searchParams.get('homeTeam') || '',
    awayTeam: searchParams.get('awayTeam') || '',
    kickoffTime: Number(searchParams.get('kickoffTime') || '0'),
    league: searchParams.get('league') || '',
    season: searchParams.get('season') || '',
    round: searchParams.get('round') || '',
  };

  // 检查是否有有效的赛事信息
  const hasValidMatch = matchInfo.matchId && matchInfo.homeTeam && matchInfo.awayTeam && matchInfo.kickoffTime > 0;

  // 获取合约地址
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 格式化开赛时间
  const kickoffDate = matchInfo.kickoffTime > 0
    ? new Date(matchInfo.kickoffTime * 1000)
    : null;

  // 提交创建市场
  const handleSubmit = async () => {
    if (isSubmitting || isPending || isConfirming) {
      return;
    }

    if (!isConnected || !addresses) {
      toast.error('请先连接钱包');
      return;
    }

    if (!hasValidMatch) {
      toast.error('缺少有效的赛事信息');
      return;
    }

    try {
      setIsSubmitting(true);

      const template = MARKET_TEMPLATES.find((t) => t.id === selectedTemplate);
      if (!template) {
        throw new Error('未找到模板');
      }

      const params: CreateMarketParams = {
        templateId: template.templateId,
        matchId: matchInfo.matchId,
        kickoffTime: BigInt(matchInfo.kickoffTime),
        mapperInitData: '0x' as `0x${string}`,
        initialLiquidity: 0n,
        outcomeRules: [],
      };

      console.log('创建市场:', params);
      await createMarket(params);
    } catch (err) {
      console.error('创建市场失败:', err);
      const errorMessage = err instanceof Error ? parseContractError(err) : '未知错误';
      toast.error('创建市场失败', {
        description: errorMessage,
        duration: 8000,
      });
      setIsSubmitting(false);
    }
  };

  // 监听交易状态
  useEffect(() => {
    if (isSuccess || error) {
      setIsSubmitting(false);
    }
  }, [isSuccess, error]);

  // 交易成功后显示 toast 并跳转
  useEffect(() => {
    if (isSuccess && hash) {
      toast.success('市场创建成功！', {
        description: `交易哈希: ${hash.slice(0, 10)}...${hash.slice(-8)}`,
      });
      const timer = setTimeout(() => {
        router.push('/markets');
      }, 2000);
      return () => clearTimeout(timer);
    }
  }, [isSuccess, hash, router]);

  // 监听 hook 返回的错误
  useEffect(() => {
    if (error) {
      const errorMessage = parseContractError(error);
      toast.error('交易失败', {
        description: errorMessage,
        duration: 10000,
      });
    }
  }, [error]);

  // 如果没有有效的赛事信息，显示错误
  if (!hasValidMatch) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <Card className="p-8 text-center max-w-md">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            缺少赛事信息
          </h2>
          <p className="text-gray-500 dark:text-gray-400 mb-6">
            请从赛事列表中选择一场赛事来创建市场
          </p>
          <Link href="/markets/create/sports">
            <Button variant="neon">返回赛事列表</Button>
          </Link>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                创建预测市场
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                确认赛事信息并选择玩法模板
              </p>
            </div>
            <Link href="/markets/create/sports" className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200">
              ← 返回赛事列表
            </Link>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* 赛事信息（只读显示） */}
        <Card className="p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            赛事信息
          </h2>

          {/* 对阵信息 */}
          <div className="flex items-center justify-center gap-6 py-6 mb-6 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {matchInfo.homeTeam}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400">主队</p>
            </div>
            <div className="text-2xl font-bold text-gray-400 dark:text-gray-500">VS</div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {matchInfo.awayTeam}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400">客队</p>
            </div>
          </div>

          {/* 赛事详情 */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">联赛</p>
              <p className="font-medium text-gray-900 dark:text-white">{matchInfo.league}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">赛季</p>
              <p className="font-medium text-gray-900 dark:text-white">{matchInfo.season}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">轮次</p>
              <p className="font-medium text-gray-900 dark:text-white">{matchInfo.round || '-'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">开赛时间</p>
              <p className="font-medium text-gray-900 dark:text-white">
                {kickoffDate ? format(kickoffDate, 'yyyy年M月d日 HH:mm', { locale: zhCN }) : '-'}
              </p>
            </div>
          </div>

          {/* 赛事 ID */}
          <div className="mt-4 p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">赛事 ID</p>
            <p className="text-sm font-mono text-gray-900 dark:text-white">
              {matchInfo.matchId}
            </p>
          </div>
        </Card>

        {/* 选择玩法模板 */}
        <Card className="p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            选择玩法
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {MARKET_TEMPLATES.map((template) => (
              <button
                key={template.id}
                onClick={() => setSelectedTemplate(template.id)}
                className={`p-4 border-2 rounded-lg text-left transition-all ${
                  selectedTemplate === template.id
                    ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                }`}
              >
                <h3 className="font-semibold text-gray-900 dark:text-white">
                  {template.name}
                </h3>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  {template.description}
                </p>
              </button>
            ))}
          </div>
        </Card>

        {/* 市场配置（固定值显示） */}
        <Card className="p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            市场配置
          </h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">定价模式</p>
              <Badge variant="default">奖金池模式</Badge>
            </div>
            <div>
              <p className="text-sm text-gray-500 dark:text-gray-400">市场类型</p>
              <Badge variant="default">Live Market</Badge>
            </div>
          </div>
        </Card>

        {/* 交易状态 */}
        {isPending && (
          <div className="mb-6 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <p className="text-sm text-yellow-800 dark:text-yellow-200">
              等待钱包确认...
            </p>
          </div>
        )}
        {isConfirming && (
          <div className="mb-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
            <div className="flex items-center gap-3">
              <LoadingSpinner size="sm" />
              <div>
                <p className="text-sm font-medium text-blue-800 dark:text-blue-200">
                  交易确认中...
                </p>
                {hash && (
                  <p className="text-xs text-blue-600 dark:text-blue-400">
                    交易哈希: {hash.slice(0, 10)}...
                  </p>
                )}
              </div>
            </div>
          </div>
        )}
        {isSuccess && (
          <div className="mb-6 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
            <p className="text-sm font-medium text-green-800 dark:text-green-200">
              市场创建成功！即将跳转...
            </p>
          </div>
        )}
        {error && (
          <div className="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <p className="text-sm font-medium text-red-800 dark:text-red-200">
              创建失败
            </p>
            <p className="text-xs text-red-600 dark:text-red-400 mt-1">
              {error.message}
            </p>
          </div>
        )}

        {/* 提交按钮 */}
        <div className="flex items-center justify-end gap-4">
          <Link href="/markets/create/sports">
            <Button variant="neon">取消</Button>
          </Link>
          <Button
            variant="neon"
            onClick={handleSubmit}
            disabled={!isConnected || isSubmitting || isPending || isConfirming || isSuccess}
          >
            {isSubmitting || isPending || isConfirming ? '创建中...' : '确认创建市场'}
          </Button>
        </div>
      </div>
    </div>
  );
}

export default function NewMarketPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
          <LoadingSpinner size="lg" text="加载中..." />
        </div>
      }
    >
      <CreateMarketForm />
    </Suspense>
  );
}
