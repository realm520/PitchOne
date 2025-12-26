'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAccount, useCreateMarket, type CreateMarketParams } from '@pitchone/web3';
import { getContractAddresses } from '@pitchone/contracts';
import { Card, Button, LoadingSpinner } from '@pitchone/ui';
import { toast } from 'sonner';

// 市场模板类型（从 addresses 中读取 templateIds）
const MARKET_TEMPLATES = [
  {
    id: 'wdl',
    name: '胜平负 (WDL)',
    description: '主胜 / 平局 / 客胜',
  },
  {
    id: 'wdlPari',
    name: '胜平负彩池模式 (WDL Pari)',
    description: '主胜 / 平局 / 客胜 (Parimutuel)',
  },
  {
    id: 'ou',
    name: '大小球 (O/U)',
    description: '总进球数大于/小于盘口',
  },
  {
    id: 'ah',
    name: '让球 (AH)',
    description: '亚洲让球盘',
  },
  {
    id: 'oddEven',
    name: '单双',
    description: '总进球数单数/双数',
  },
  {
    id: 'score',
    name: '精确比分',
    description: '预测精确比分结果',
  },
  {
    id: 'scorePari',
    name: '精确比分彩池模式',
    description: '预测精确比分结果 (Parimutuel)',
  },
];

// 解析合约错误信息
function parseContractError(error: Error): string {
  const message = error.message || '';

  // 用户拒绝交易
  if (message.includes('User rejected') || message.includes('user rejected')) {
    return '用户取消了交易';
  }

  // Gas 不足
  if (message.includes('insufficient funds') || message.includes('gas required exceeds')) {
    return 'Gas 费用不足';
  }

  // 权限不足
  if (message.includes('AccessControlUnauthorizedAccount') || message.includes('0xe2517d3f')) {
    return '权限不足：当前账户没有创建市场的权限';
  }

  // 返回原始错误信息（截断过长的部分）
  const cleanMessage = message.replace(/\s+/g, ' ').trim();
  return cleanMessage.length > 200 ? cleanMessage.slice(0, 200) + '...' : cleanMessage;
}

export default function ManualCreateMarketPage() {
  const router = useRouter();
  const { chainId, isConnected } = useAccount();
  const { createMarket, isPending, isConfirming, isSuccess, error, hash } = useCreateMarket();

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [selectedTemplate, setSelectedTemplate] = useState('wdl');

  // 表单状态
  const [formData, setFormData] = useState({
    matchId: '',
    homeTeam: '',
    awayTeam: '',
    league: '',
    kickoffTime: '',
  });

  // 获取合约地址
  const addresses = chainId ? getContractAddresses(chainId) : null;

  // 生成 matchId
  const generateMatchId = () => {
    const league = formData.league.toUpperCase().replace(/\s+/g, '_') || 'CUSTOM';
    const home = formData.homeTeam.toUpperCase().replace(/\s+/g, '_').slice(0, 3) || 'HOM';
    const away = formData.awayTeam.toUpperCase().replace(/\s+/g, '_').slice(0, 3) || 'AWY';
    const templateSuffix = selectedTemplate.toUpperCase();
    const timestamp = Date.now();
    return `${league}_${home}_vs_${away}_${templateSuffix}_${timestamp}`;
  };

  // 更新表单数据
  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  // 提交创建市场
  const handleSubmit = async () => {
    if (isSubmitting || isPending || isConfirming) {
      return;
    }

    if (!isConnected || !addresses) {
      toast.error('请先连接钱包');
      return;
    }

    // 验证表单
    if (!formData.homeTeam || !formData.awayTeam || !formData.kickoffTime) {
      toast.error('请填写完整的赛事信息');
      return;
    }

    // 验证开赛时间
    const kickoffDate = new Date(formData.kickoffTime);
    if (isNaN(kickoffDate.getTime())) {
      toast.error('请输入有效的开赛时间');
      return;
    }

    try {
      setIsSubmitting(true);

      // 获取模板 ID
      const templateId = addresses.templateIds?.[selectedTemplate as keyof typeof addresses.templateIds];
      if (!templateId) {
        throw new Error(`未找到模板: ${selectedTemplate}。请检查合约地址配置是否包含该模板。`);
      }

      // 生成或使用自定义 matchId
      const matchId = formData.matchId || generateMatchId();

      // 计算开球时间戳
      const kickoffTimestamp = BigInt(Math.floor(kickoffDate.getTime() / 1000));

      const params: CreateMarketParams = {
        templateId: templateId as `0x${string}`,
        matchId: matchId,
        kickoffTime: kickoffTimestamp,
        mapperInitData: '0x' as `0x${string}`,
        initialLiquidity: 0n,
        outcomeRules: [],
      };

      // 打印参数（BigInt 需要转换为字符串才能 JSON 序列化）
      const paramsForLog = {
        templateId: params.templateId,
        matchId: params.matchId,
        kickoffTime: params.kickoffTime.toString(),
        mapperInitData: params.mapperInitData,
        initialLiquidity: params.initialLiquidity.toString(),
        outcomeRules: params.outcomeRules,
      };
      await createMarket(params);
    } catch (err) {
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

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                手动创建市场
              </h1>
              <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                填写赛事信息并选择玩法模板
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
        {/* 赛事信息表单 */}
        <Card className="p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            赛事信息
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* 主队 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                主队名称 <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                value={formData.homeTeam}
                onChange={(e) => handleInputChange('homeTeam', e.target.value)}
                placeholder="如: Manchester United"
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 客队 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                客队名称 <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                value={formData.awayTeam}
                onChange={(e) => handleInputChange('awayTeam', e.target.value)}
                placeholder="如: Liverpool"
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 联赛 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                联赛名称
              </label>
              <input
                type="text"
                value={formData.league}
                onChange={(e) => handleInputChange('league', e.target.value)}
                placeholder="如: Premier League"
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 开赛时间 */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                开赛时间 <span className="text-red-500">*</span>
              </label>
              <input
                type="datetime-local"
                value={formData.kickoffTime}
                onChange={(e) => handleInputChange('kickoffTime', e.target.value)}
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* 自定义 Match ID */}
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                自定义 Match ID（可选）
              </label>
              <input
                type="text"
                value={formData.matchId}
                onChange={(e) => handleInputChange('matchId', e.target.value)}
                placeholder="留空将自动生成"
                className="w-full px-4 py-2 border dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              {!formData.matchId && formData.homeTeam && formData.awayTeam && (
                <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                  将自动生成: {generateMatchId()}
                </p>
              )}
            </div>
          </div>
        </Card>

        {/* 选择玩法模板 */}
        <Card className="p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            选择玩法
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {MARKET_TEMPLATES.map((template) => (
              <button
                key={template.id}
                onClick={() => setSelectedTemplate(template.id)}
                className={`p-4 border-2 rounded-lg text-left transition-all ${selectedTemplate === template.id
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

        {/* 合约信息显示 */}
        {addresses && (
          <Card className="p-6 mb-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              合约信息
            </h2>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500 dark:text-gray-400">Factory:</span>
                <span className="font-mono text-gray-900 dark:text-white">
                  {addresses.factory?.slice(0, 10)}...{addresses.factory?.slice(-8)}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500 dark:text-gray-400">Template ID:</span>
                <span className="font-mono text-gray-900 dark:text-white">
                  {addresses.templateIds?.[selectedTemplate as keyof typeof addresses.templateIds]?.slice(0, 10)}...
                </span>
              </div>
            </div>
          </Card>
        )}

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
